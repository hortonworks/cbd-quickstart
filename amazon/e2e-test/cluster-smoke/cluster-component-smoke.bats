#!/usr/bin/env bats

load ../$STACK_NAME".stackdescriptor"
load ../$CLUSTER_NAME".clusterdescriptor"

TAGS="$STACK_NAME $CLUSTER_NAME smoke jmeter cluster"
#JMETERBIN="/Users/afarsang/prj/dev/apache-jmeter-3.2/bin/jmeter.sh -n "
JMETERBIN="docker run  -i --name jst$BASHPID --rm  -v $(pwd)/cluster-smoke:/jmetertest afarsang/jmeter_hive"
#OPENSSLBIN="/usr/local/Cellar/openssl/1.0.2k/bin/openssl"
OPENSSLBIN=openssl
JMXTEST="clustercomponenttest2.jmx"
JMETER_WD=/jmetertest/

#set -x

function sslkey() {
  rm -f cluster-smoke/gateway.pem cluster-smoke/gateway.jks
$OPENSSLBIN s_client -connect ${HOST}:443 -showcerts </dev/null | openssl x509 -outform PEM > cluster-smoke/gateway.pem
keytool -import -alias gateway -file  cluster-smoke/gateway.pem -keystore  cluster-smoke/gateway.jks -storepass 123456 -noprompt
}


function jmetertest() {
  expected=$1
  user=$2
  pass=$(echo $3 | tr -d '"')
  HDP_VERSION=$(jq .HDPVersion $INPUT_JSON_FILE )
  HDP_VERSION=${HDP_VERSION%\"}
  HDP_VERSION=${HDP_VERSION#\"}
  CLIPARAM="$CLIPARAM -Jcloudurl=$HOST -Jport=443 -Jclustername=$CLUSTER_NAME -Jurlinfix=/services   "
  CLIPARAM="$CLIPARAM -Jhdpversion=$HDP_VERSION"
  CLIPARAM="$CLIPARAM -Jadminuser=$user"
  CLIPARAM="$CLIPARAM -Jadminpass=$pass"
  CLIPARAM="$CLIPARAM -Jtspath=$JMETER_WD/gateway.jks -Jtspass=123456 "
  echo $CLIPARAM >&2
  echo $JMETERBIN -t $JMETER_WD/$JMXTEST $CLIPARAM -l $JMETER_WD/res.txt -j $JMETER_WD/jmeter.log >> $CLUSTER_NAME-jcli.txt
  $JMETERBIN -t $JMETER_WD/$JMXTEST $CLIPARAM -l $JMETER_WD/res.txt -j $JMETER_WD/jmeter.log 2>&1 | tee -a $CLUSTER_NAME-jcli.txt | grep "$expected"
}

#expected results ; error codes of grep: 0 found no error; 1 something something darkside...
AMBARI_EXPECTED=0
JOBHISTORY_EXPECTED=0
NAMENODE_EXPECTED=0
RESOURCEMAN_EXPECTED=0
SPARK_EXPECTED=0
ZEPPELIN_EXPECTED=0
ZEPPELINWS_EXPECTED=0
HIVE_EXPECTED=0

#set up test based on cluster type
CLUSTER_CONFIG=common/shortnames.json 
if [[ $(jq -r ".\"$CLUSTER_NAME\".spark" $CLUSTER_CONFIG ) = true  ]]
then
  SPARK_EXPECTED=1
fi
if [[ $(jq -r ".\"$CLUSTER_NAME\".zeppelin" $CLUSTER_CONFIG ) = true ]]
then
  ZEPPELIN_EXPECTED=1
  ZEPPELINWS_EXPECTED=1
fi

#set up test based on visibilty
if [ $(jq .HiveJDBCAccess $INPUT_JSON_FILE) != "true" ] 
then
  HIVE_EXPECTED=1
fi
if [ $(jq .WebAccess $INPUT_JSON_FILE) != "true" ] 
then
  AMBARI_EXPECTED=1
  ZEPPELIN_EXPECTED=1
  ZEPPELINWS_EXPECTED=1
fi
if [ $(jq .ClusterComponentAccess $INPUT_JSON_FILE) != "true" ] 
then
  JOBHISTORY_EXPECTED=1
  NAMENODE_EXPECTED=1
  RESOURCEMAN_EXPECTED=1
  SPARK_EXPECTED=1 HIVE_EXPECTED=1
fi


user=$(jq ".\"$CLUSTER_NAME\".user" common/shortnames.json | tr -d '"')
password=$(jq ".\"$CLUSTER_NAME\".password" common/shortnames.json | tr -d '"')
if [[ $user =~ null ]] 
then
  user=$(jq .ClusterAndAmbariUser $INPUT_JSON_FILE | tr -d '"')
  password=$(jq .ClusterAndAmbariPassword $INPUT_JSON_FILE | tr -d '"')
fi

noerr="Err:[ \t]*0[ \t]*(.*)$"
noerrzep="Err:[ \t]*1[ \t]*(6.*)$"

@test "Ambari smoke test [$TAGS ambari $AMBARI_EXPECTED]" {
  CLIPARAM="-Jt_ambari=1"
  adminuser=$(jq .ClusterAndAmbariUser $INPUT_JSON_FILE | tr -d '"')
  if [ -n $ADMINPASS ]
  then
    ADMINPASS=$(jq .ClusterAndAmbariPassword $INPUT_JSON_FILE)
  fi
  ADMINPASS=$(echo $ADMINPASS | tr -d '"')

  run jmetertest "$noerr" $adminuser $ADMINPASS
  cat cluster-smoke/res.txt >&2
  mv cluster-smoke/res.txt ambari.txt
  [[ $status -eq $AMBARI_EXPECTED ]]
}

@test "Jobhistory smoke test [$TAGS jobhistory $JOBHISTORY_EXPECTED]" {
  CLIPARAM="-Jt_jh=1"
  run jmetertest "$noerr" $user $password
  cat cluster-smoke/res.txt >&2
  mv cluster-smoke/res.txt jobhistory.txt
  [[ $status -eq $JOBHISTORY_EXPECTED ]]
}


@test "Namenode smoke test [$TAGS namenodei $NAMENODE_EXPECTED]" {
  CLIPARAM="-Jt_nn=1"
  run jmetertest "$noerr"  $user $password
  cat cluster-smoke/res.txt >&2
  mv cluster-smoke/res.txt namenode.txt
  [[ $status -eq $NAMENODE_EXPECTED ]]
}


@test "Resourceman smoke test [$TAGS resourcemanager $RESOURCEMAN_EXPECTED]" {
  CLIPARAM="-Jt_rm=1"
  run jmetertest "$noerr" $user $password
  cat cluster-smoke/res.txt >&2
  mv cluster-smoke/res.txt resourceman.txt
  [[ $status -eq $RESOURCEMAN_EXPECTED ]]
}

@test "Sparkhistory smoke test [$TAGS sparkhistory $SPARK_EXPECTED]" {
  CLIPARAM="-Jt_spark=1"
  run jmetertest "$noerr" $user $password
  cat cluster-smoke/res.txt >&2
  echo $output >&2
  mv cluster-smoke/res.txt spark.txt
  [[ $status -eq $SPARK_EXPECTED ]]
}

@test "Zeppelin smoke test [$TAGS zeppelin $ZEPPELIN_EXPECTED]" {
  CLIPARAM="-Jt_zeppelin=1"
  run jmetertest "$noerrzep" $user $password
  cat cluster-smoke/res.txt >&2
  echo $output >&2
  mv cluster-smoke/res.txt zeppelin.txt
  [[ $status -eq $ZEPPELIN_EXPECTED ]]
}

@test "Zeppelin_ws smoke test [$TAGS zeppelinws $ZEPPELINWS_EXPECTED]" {
  skip 
  CLIPARAM="-Jt_zeppelinws=1"
  run jmetertest "$noerr" $user $password
  cat cluster-smoke/res.txt >&2
  mv cluster-smoke/res.txt zeppelinws.txt
  [[ $status -eq $ZEPPELINWS_EXPECTED ]]
}

@test "Hive jdbc smoke test [$TAGS jdbc hive $HIVE_EXPECTED]" {
  CLIPARAM="-Jt_hive=1"
  sslkey
  run jmetertest "$noerr" $user $password
  cat cluster-smoke/res.txt >&2
  mv cluster-smoke/res.txt hive.txt
  [[ $status -eq $HIVE_EXPECTED ]]
}
