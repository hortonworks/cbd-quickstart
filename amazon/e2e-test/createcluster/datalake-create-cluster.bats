#!/usr/bin/env bats
#set -xe

: ${CLUSTER_NAME:=datalake26-a}

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

TEMPLATE_FILE=_datalake.tmplt
CLUSTER_FILE_NAME=$CLUSTER_NAME".clusterdescriptor.bash"
TAGS="$STACK_NAME $CLUSTER_NAME smoke functional hdc-cli"
INPUT_JSON_FILE="./${CLUSTER_NAME}.json"


function createclusterdescriptor(){
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

function createclusterjson(){
  cat common/cluster-templates/${TEMPLATE_FILE} | \
    sigil $(cat ${CLUSTER_FILE_NAME} | tr '\n' ' ' ) \
    S3_STORAGE=testafstorage RDS_RANGER_USER=rangeruser > ${INPUT_JSON_FILE}
}

function createclusterjson_(){
  cat common/cluster-templates/${TEMPLATE_FILE} | \
    sigil \
    CLUSTER_NAME=$CLUSTER_NAME \
    SSHKEY=$TEST_KEY \
    CLUSTER_VPCID=$TEST_VPCID \
    CLUSTER_SUBNETID=$TEST_SUBNETID \
    SHARED_HIVE_METASTORE=$TEST_HIVE \
    RDS_DB_ADDRESS=$TEST_RDS_ADDR \
    RDS_DB_PORT=$TEST_RDS_PORT \
    RDS_RANGER_USER=$TEST_RANGER_DB_USER \
    RDS_DB_PASSWORD=$TEST_RANGER_DB_PASS \
    S3_STORAGE=$TEST_S3 \
    SHARED_LDAP=$TEST_LDAP > ${INPUT_JSON_FILE}
}


@test "create datalake cluster without password [$TAGS]" {
  createclusterdescriptor
  createclusterjson
  list-cluster-types 
  run create-cluster --cli-input-json ./${CLUSTER_NAME}.json
  echo $output >&2

  if [[ $status -ne 0 ]]
  then
    mv $CLUSTER_FILE_NAME $CLUSTER_NAME_failed.clusterdescriptor.bash
  fi

  [[ $status -eq 0 ]]
}

@test "create datalake cluster with wrong ldap [$TAGS negative]" {
skip
  TEST_KEY=$SSHKEY
  TEST_VPCID=$VPCID
  TEST_SUBNETID=$SUBNETID
  TEST_HIVE=$SHARED_HIVE_METASTORE
  TEST_RDS_ADDR=$RDS_DB_ADDRESS
  TEST_RDS_PORT=$RDS_DB_PORT
  TEST_RANGER_DB_USER=rangeruser
  TEST_RANGER_DB_PASS=$RDS_DB_PASSWORD
  TEST_S3=testafstorage
  TEST_LDAP=nemletezikezazldap
  CLUSTER_NAME=negldap
  createclusterjson_
  #createcluster
  #checkexitstatus
  run create-cluster --cli-input-json ./${CLUSTER_NAME}.json
  echo $output >&2

  if [[ $status -ne 0 ]]
  then
     echo baj lesz itt vazze >&2
  fi
  create_cluster_status=$status
  
  sleep 10
  run describe-cluster 

  if [[ $status -eq 0 ]]
  then
    #deleteclusterifneeded
    terminate-cluster 
  fi

  [[ $create_cluster_status -ne 0 ]] && [[ $status -ne 0 ]]
}
