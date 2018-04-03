#!/usr/bin/env bats
#set -xe

: ${CLUSTER_NAME:=edwetl26-16}

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

CLUSTER_FILE_NAME=$CLUSTER_NAME".clusterdescriptor.bash"
TAGS="$STACK_NAME $CLUSTER_NAME smoke functional hdc-cli"

@test "create cluster without password [$TAGS]" {
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

  list-cluster-types 
  run create-cluster --cli-input-json $INPUT_JSON_FILE
  echo $output >&2

  if [[ $status -ne 0 ]]
  then
    mv $CLUSTER_FILE_NAME $CLUSTER_NAME_failed.clusterdescriptor.bash
  fi

  [[ $status -eq 0 ]]
}
