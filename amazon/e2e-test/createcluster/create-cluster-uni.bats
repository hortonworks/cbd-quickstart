#!/usr/bin/env bats
#set -xe

: ${STACK_NAME:? required}
: ${CLUSTER_NAME:? required}
load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli
load ../helper/hdc/api

CLUSTER_FILE_NAME=$CLUSTER_NAME".clusterdescriptor.bash"
TAGS="$STACK_NAME $CLUSTER_NAME smoke functional hdc-cli"
INPUT_JSON_FILE="./${CLUSTER_NAME}.json"


function eph-createclusterdescriptor(){
  echo "STACK_NAME=${STACK_NAME}" > $CLUSTER_FILE_NAME
  echo "CLOUD_URL=${CLOUD_URL}" >> $CLUSTER_FILE_NAME
  echo "EMAIL=${EMAIL}" >> $CLUSTER_FILE_NAME
  echo "PASSWORD=${PASSWORD}" >> $CLUSTER_FILE_NAME
  echo "SSHKEY=${SSH_KEY_NAME}" >> $CLUSTER_FILE_NAME
  echo "SSH_KEY_NAME=${SSH_KEY_NAME}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_NAME=${CLUSTER_NAME}" >> $CLUSTER_FILE_NAME
  echo "CLOUD_VERSION=${CLOUD_VERSION}" >> $CLUSTER_FILE_NAME
  echo "CB_VERSION=${CB_VERSION}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_VPCID=${VPCID}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_SUBNETID=${SUBNETID}" >> $CLUSTER_FILE_NAME
  echo "DATALAKE_CLUSTER=${DATALAKE_CLUSTER}" >> $CLUSTER_FILE_NAME
  echo "INPUT_JSON_FILE=${INPUT_JSON_FILE}" >> $CLUSTER_FILE_NAME
}

function eph-createclusterjson(){
  cat common/cluster-templates/${TEMPLATE_FILE} | \
    sigil $(cat ${CLUSTER_FILE_NAME} | tr '\n' ' ' ) \
    CLUSTER_TYPE="$CLUSTER_TYPE" > ${INPUT_JSON_FILE}
}

function dl-createclusterdescriptor(){
  echo "STACK_NAME=${STACK_NAME}" > $CLUSTER_FILE_NAME
  echo "CLOUD_URL=${CLOUD_URL}" >> $CLUSTER_FILE_NAME
  echo "EMAIL=${EMAIL}" >> $CLUSTER_FILE_NAME
  echo "PASSWORD=${PASSWORD}" >> $CLUSTER_FILE_NAME
  echo "SSHKEY=${SSH_KEY_NAME}" >> $CLUSTER_FILE_NAME
  echo "SSH_KEY_NAME=${SSH_KEY_NAME}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_NAME=${CLUSTER_NAME}" >> $CLUSTER_FILE_NAME
  echo "CLOUD_VERSION=${CLOUD_VERSION}" >> $CLUSTER_FILE_NAME
  echo "CB_VERSION=${CB_VERSION}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_VPCID=${VPCID}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_SUBNETID=${SUBNETID}" >> $CLUSTER_FILE_NAME
  echo "SHARED_LDAP=${SHARED_LDAP}" >> $CLUSTER_FILE_NAME
  echo "SHARED_HIVE_METASTORE=${SHARED_HIVE_METASTORE}" >> $CLUSTER_FILE_NAME
  echo "RDS_DB_ADDRESS=${RDS_DB_ADDRESS}" >> $CLUSTER_FILE_NAME
  echo "RDS_DB_PORT=${RDS_DB_PORT}" >> $CLUSTER_FILE_NAME
  echo "RDS_DB_PASSWORD=${RDS_DB_PASSWORD}" >> $CLUSTER_FILE_NAME
  echo "INPUT_JSON_FILE=${INPUT_JSON_FILE}" >> $CLUSTER_FILE_NAME
}

function dl-createclusterjson(){
  cat common/cluster-templates/${TEMPLATE_FILE} | \
    sigil $(cat ${CLUSTER_FILE_NAME} | tr '\n' ' ' ) \
    S3_STORAGE=testafstorage RDS_RANGER_USER=rangeruser > ${INPUT_JSON_FILE}
}

function reg-createclusterdescriptor(){
  echo "STACK_NAME=${STACK_NAME}" > $CLUSTER_FILE_NAME
  echo "CLOUD_URL=${CLOUD_URL}" >> $CLUSTER_FILE_NAME
  echo "EMAIL=${EMAIL}" >> $CLUSTER_FILE_NAME
  echo "PASSWORD=${PASSWORD}" >> $CLUSTER_FILE_NAME
  echo "SSHKEY=${SSH_KEY_NAME}" >> $CLUSTER_FILE_NAME
  echo "CLUSTER_NAME=${CLUSTER_NAME}" >> $CLUSTER_FILE_NAME
  echo "CLOUD_VERSION=${CLOUD_VERSION}" >> $CLUSTER_FILE_NAME
  echo "CB_VERSION=${CB_VERSION}" >> $CLUSTER_FILE_NAME

  INPUT_JSON_FILE=common/cluster-templates/${CLUSTER_NAME}-template.json
  echo "INPUT_JSON_FILE=${INPUT_JSON_FILE}" >> $CLUSTER_FILE_NAME
}

function reg-createclusterjson(){
  cp common/cluster-templates/${CLUSTER_NAME}-template.json ./${CLUSTER_NAME}.json
}


function prepare() {
  cluster_type_template=$(jq ".\"$CLUSTER_NAME\".template" common/shortnames.json )
  case $cluster_type_template in
  '"ephemeral"')
: ${CLUSTER_TYPE:="EDW-Analytics: Apache Hive 2 LLAP, Apache Zeppelin 0.7.0 Shared"}
: ${DATALAKE_CLUSTER:=datalake26-a}
    TEMPLATE_FILE=_ephemeral.tmplt
    blueprint_no=$(jq ".\"$CLUSTER_NAME\".id" common/shortnames.json )
    CLUSTER_TYPE=$(jq .[$blueprint_no].ClusterType common/blueprints.json )
    echo $CLUSTER_TYPE >&2
    eph-createclusterdescriptor
    eph-createclusterjson
    ;;
  '"datalake"')
    TEMPLATE_FILE=_datalake.tmplt
    dl-createclusterdescriptor
    dl-createclusterjson
    ;;
  *)
    reg-createclusterdescriptor
    reg-createclusterjson
    ;;
  esac
}

@test "create cluster without password [$TAGS]" {
  prepare
  list-cluster-types 
  run create-cluster --cli-input-json ./${CLUSTER_NAME}.json
  echo $output >&2

  if [[ $status -ne 0 ]]
  then
    getevents | jq ".[] | select(.clusterName==\"$CLUSTER_NAME\")" >&2
    adminuser=$(jq .ClusterAndAmbariUser $INPUT_JSON_FILE | tr -d '"')
    if [ -n $ADMINPASS ]
    then
      ADMINPASS=$(jq .ClusterAndAmbariPassword $INPUT_JSON_FILE)
    fi
    ADMINPASS=$(echo $ADMINPASS | tr -d '"')
    curl -v -k $CLOUD_URL/$CLUSTER_NAME/services/ambari/api/v1/clusters/$CLUSTER_NAME/alerts?format=groupedSummary -u $adminuser:$ADMINPASS | jq '.alerts_summary_grouped[] | select(.summary.CRITICAL.count>0 or .summary.WARNING.count >0 )' >&2

    terminate-cluster
    mv $CLUSTER_FILE_NAME failed_$CLUSTER_FILE_NAME
  fi

  [[ $status -eq 0 ]]
}

