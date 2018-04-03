#!/bin/bash

#set -ex

: ${DEFAULT_REGION:=$(aws configure get region)}
: ${REGION:=${DEFAULT_REGION:=eu-central-1}}
: ${WORKSPACE=.}
: ${SSH_KEY_NAME:=seq-master}
: ${EMAIL:=admin@hortonworks.com}
: ${PASSWORD:="Admin:123"}

extension="smartsense_descriptor.bash"

function set_stack_name() {
  local STACK_NAME=autotesting-cli-$(date | sed 's/ .*//')-$(date +%H%M%S)
  echo "${STACK_NAME}"
}

function get_releasetype() {
  : ${TEMPLATE_URL:? required}

  local TEMPLATE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $3}')
  local RELEASE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $4}')
  local TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F - '{print $5}')

  echo "${RELEASE_TYPE}"
}

function usage_json_checker() {
  HOST=${CLOUD_URL#*//}

  ssh -xt -o StrictHostKeyChecking=no -i $MASTER_SSH_KEY $CLOUDBREAK_CLOUDBREAK_SSH_USER@$HOST "$(typeset -f); $1"
}

function create_stackdescriptor() {
  : ${STACK_NAME:=$1}

  echo "STACK_NAME=${STACK_NAME}" > ${STACK_NAME}.${extension}
  echo "EMAIL=${EMAIL}" >> ${STACK_NAME}.${extension}
  echo "PASSWORD=${PASSWORD}" >> ${STACK_NAME}.${extension}
  echo "SSHKEY=${SSH_KEY_NAME}" >> ${STACK_NAME}.${extension}
  echo "RELEASE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $4}')" >> ${STACK_NAME}.${extension}

  CLOUD_URL=$(aws cloudformation describe-stacks --region $REGION --stack-name $STACK_NAME | jq '.Stacks[0].Outputs[] | select(.OutputKey == "CloudController") | .OutputValue' -r | jq .CloudURL -r)
  echo "CLOUD_URL=${CLOUD_URL}" >> ${STACK_NAME}.${extension}

  CB_VERSION=$(curl -sk $CLOUD_URL/cb/info | grep -oP "(?<=\"version\":\")[^\"]*")
  echo "CB_VERSION=${CB_VERSION}" >> ${STACK_NAME}.${extension}
  echo "TEMPLATE_VERSION=${TEMPLATE_VERSION}" >> ${STACK_NAME}.${extension}
}

function create_ss_controller() {
  : ${PRODUCT_TELEMETRY:=${1:-''}}
  : ${CB_SMARTSENSE_ID:=${2:-''}}
  : ${STACK_TYPE:=basic} #basic or advanced
  : ${STACK_NAME:=$(set_stack_name)}

  if [ -n $TEMPLATE_URL ] ; then
    TEMPLATE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $3}')
    RELEASE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $4}')
    TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F - '{print $5}')

    if [[ ${TEMPLATE_VERSION} =~ ^[0-9] ]]; then
        echo TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F $RELEASE_TYPE- '{gsub(/.template/,"",$2); print $2}')
    else
        echo TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F ${TEMPLATE_VERSION}- '{gsub(/.template/,"",$2); print $2}')
    fi
  else
    TEMPLATE_URL=https://s3.amazonaws.com/hdc-cfn/hdcloud-"${TEMPLATE_TYPE}"-"${RELEASE_TYPE}"-"${TEMPLATE_VERSION}".template
  fi

  if [ "${RELEASE_TYPE}" == "GA" ]; then
    aws cloudformation create-stack \
      --stack-name "${STACK_NAME}" \
      --template-url "${TEMPLATE_URL}" \
      --parameters \
        ParameterKey=KeyName,ParameterValue="${SSH_KEY_NAME}" \
        ParameterKey=AdminPassword,ParameterValue=$PASSWORD \
        ParameterKey=RemoteLocation,ParameterValue=0.0.0.0/0 \
        ParameterKey=EmailAddress,ParameterValue="${EMAIL}" \
        ParameterKey=ProductTelemetry,ParameterValue="${PRODUCT_TELEMETRY}" \
        ParameterKey=SmartSenseId,ParameterValue="${CB_SMARTSENSE_ID}" \
      --region "${REGION}" \
      --disable-rollback \
      --capabilities CAPABILITY_IAM

      aws cloudformation wait stack-create-complete --region "${REGION}" --stack-name "${STACK_NAME}"
  else
    echo "SmartSense parameter and so FLEX is only available for GA releases currently"
  fi
}

function get_failure_event() {
  : ${STACK_NAME:=$1}

  aws cloudformation describe-stack-events --region "${REGION}" --stack-name "${STACK_NAME}" | jq '[.StackEvents[] | select(.ResourceStatus | contains("FAILED"))][-1]' | jq -r .ResourceStatusReason
}

function terminate_controller() {
  : ${STACK_NAME:=$1}

  aws cloudformation delete-stack --region "${REGION}" --stack-name "${STACK_NAME}"

  aws cloudformation wait stack-delete-complete --region "${REGION}" --stack-name "${STACK_NAME}"

  rm -f ../$STACK_NAME".stackdescriptor"
}
