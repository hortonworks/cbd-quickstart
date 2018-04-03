#!/usr/bin/env bats
#set -xe

: ${STACK_NAME:? required}
: ${CLUSTER_NAME:? required}
load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

CLUSTER_FILE_NAME=$CLUSTER_NAME".clusterdescriptor.bash"
TAGS="$STACK_NAME $CLUSTER_NAME smoke functional hdc-cli"
INPUT_JSON_FILE="./${CLUSTER_NAME}.json"


function vpc-createclusterdescriptor(){
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
}

function vpc-createclusterjson(){
  cat common/cluster-templates/${TEMPLATE_FILE} | \
    sigil $(cat ${CLUSTER_FILE_NAME} | tr '\n' ' ' ) \
    CLUSTER_TYPE="$CLUSTER_TYPE" > ${INPUT_JSON_FILE}
}



function prepare() {
  cluster_type_template=$(jq ".\"$CLUSTER_NAME\".template" common/shortnames.json )
  case $cluster_type_template in
  '"vpccreate"')
    TEMPLATE_FILE=_vpcdatasci.tmplt
    vpc-createclusterdescriptor
    vpc-createclusterjson
    ;;
  *)
    echo "nono"
    ;;
  esac
}

@test "create cluster in vpc [$TAGS]" {
  aws cloudformation create-stack --region $REGION --stack-name test-infra --template-body file://$(realpath helper/infra-cf.template)
  aws cloudformation wait stack-create-complete --region $REGION --stack-name test-infra
  awsoutput=$(aws --region $REGION cloudformation describe-stacks --stack-name test-infra )
  VPCID=$(echo $awsoutput | jq '.Stacks[0].Outputs[] | select(.OutputKey=="VPC") | .OutputValue' )
  SUBNETID=$(echo $awsoutput | jq '.Stacks[0].Outputs[] | select(.OutputKey=="PublicSubnet") | .OutputValue' )
  prepare
  list-cluster-types 
  run create-cluster --cli-input-json ./${CLUSTER_NAME}.json
  echo $output >&2

  if [[ $status -ne 0 ]]
  then
    terminate-cluster
    mv $CLUSTER_FILE_NAME failed_$CLUSTER_FILE_NAME
    aws --region "${REGION}" cloudformation delete-stack --stack-name test-infra
    aws --region "${REGION}" cloudformation wait stack-delete-complete --stack-name test-infra
  fi


  [[ $status -eq 0 ]]
}

