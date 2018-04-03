#!/usr/bin/env bats
#set -xe

: ${CLUSTER_NAME:=eph-analytics26}
: ${CLUSTER_TYPE:="EDW-Analytics: Apache Hive 2 LLAP, Apache Zeppelin 0.7.0 Shared"}
: ${DATALAKE_CLUSTER:=datalake26-a}

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

TEMPLATE_FILE=_ephemeral.tmplt
CLUSTER_FILE_NAME=$CLUSTER_NAME".clusterdescriptor.bash"
TAGS="$STACK_NAME $CLUSTER_NAME ehpemeral smoke functional hdc-cli"
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

function prepare() {
  cluster_type_template=$(jq ".\"$CLUSTER_NAME\".template" common/shortnames.json )
  echo %%% $cluster_type_template
  case $cluster_type_template in
  '"ephemeral"')
    blueprint_no=$(jq ".\"$CLUSTER_NAME\".id" common/shortnames.json )
    echo %%% $blueprint_no >&2
    CLUSTER_TYPE=$(jq .[$blueprint_no].ClusterType common/blueprints.json )
    echo $CLUSTER_TYPE >&2
    eph-createclusterdescriptor
    eph-createclusterjson
    ;;
  "datalake")
    dl-cucc
    ;;
  esac
}

@test "create ephemeral cluster without password [$TAGS]" {
  #createclusterdescriptor
  #createclusterjson
  prepare
  list-cluster-types 
  run create-cluster --cli-input-json ./${CLUSTER_NAME}.json
  echo $output >&2

  if [[ $status -ne 0 ]]
  then
    mv $CLUSTER_FILE_NAME $CLUSTER_NAME_failed.clusterdescriptor.bash
  fi

  [[ $status -eq 0 ]]
}

