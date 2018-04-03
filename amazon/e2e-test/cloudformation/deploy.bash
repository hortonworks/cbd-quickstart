#!/bin/bash

set -ex
source helper/rds-prep.bash

: ${DEFAULT_REGION:=$(aws configure get region)}
: ${REGION:=${DEFAULT_REGION:=eu-central-1}}

extension="stackdescriptor.bash"

deploy() {
  : ${WORKSPACE=.}
  : ${STACK_NAME:=test-basic-$(date | sed 's/ .*//')-$(date +%H%M)}
  : ${SSH_KEY_NAME:=seq-master}
  : ${EMAIL:=admin@hortonworks.com}
  : ${PASSWORD:=Admin123\!}
  : ${INSTANCE_TYPE:=m4.xlarge}

  : ${VPCID:=vpc-0e1dad6a}
  : ${SUBNETID:=subnet-13b03965}

  : ${RDS_DB_USER:=dbmaster}
  : ${RDS_DB_PASSWORD:=cl6nnAzT3R}
  : ${RDS_DB_NAME:=hdc}

  : ${PRODUCT_TELEM:=I Have Read and Opt In to SmartSense Telemetry}
  : ${UPLOAD_LOGS:=NO}

  : ${STACK_TYPE:=basic} #basic or advanced

  if [ -z $TEMPLATE_URL ] ; then
    TEMPLATE_URL=https://s3.amazonaws.com/hdc-cfn/hdcloud-${TEMPLATE_TYPE}-${RELEASE_TYPE}-${TEMPLATE_VERSION}.template
  else
    TEMPLATE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $3}')
    RELEASE_TYPE=$(echo $TEMPLATE_URL | awk -F - '{print $4}')
    TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F - '{print $5}')

    if [[ ${TEMPLATE_VERSION} =~ ^[0-9] ]]; then
        echo TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F $RELEASE_TYPE- '{gsub(/.template/,"",$2); print $2}')
    else
        echo TEMPLATE_VERSION=$(echo $TEMPLATE_URL | awk -F ${TEMPLATE_VERSION}- '{gsub(/.template/,"",$2); print $2}')
    fi
  fi

echo $TEMPLATE_VERSION > build_id

  PARAMETERS=ParameterKey=KeyName,ParameterValue="${SSH_KEY_NAME}"\ \
ParameterKey=AdminPassword,ParameterValue=$PASSWORD\ \
ParameterKey=RemoteLocation,ParameterValue=0.0.0.0/0\ \
ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE\ \
ParameterKey=EmailAddress,ParameterValue="${EMAIL}"

  if [ "$TEMPLATE_TYPE" != "basic" ]
  then
    create_rds

    PARAMETERS=$PARAMETERS\ \
ParameterKey=VPCID,ParameterValue="${VPCID}"\ \
ParameterKey=SubnetID,ParameterValue="${SUBNETID}"\ \
ParameterKey=RdsUrl,ParameterValue="${RDS_DB_ADDRESS}:${RDS_DB_PORT}"\ \
ParameterKey=RdsUsername,ParameterValue="${RDS_DB_USER}"\ \
ParameterKey=RdsPassword,ParameterValue="${RDS_DB_PASSWORD}"\ \
ParameterKey=RdsDatabase,ParameterValue="${RDS_DB_NAME}"
  fi
  
  if [ "$RELEASE_TYPE" == "GA" ]
  then
    PARAMETERS=$PARAMETERS\ ParameterKey=SmartSenseId,ParameterValue=""\ 
  fi
  
#ParameterKey=UploadLogs,ParameterValue="${UPLOAD_LOGS}"\ \
    
  aws cloudformation create-stack \
   --capabilities CAPABILITY_IAM \
   --parameters ${PARAMETERS} ParameterKey=ProductTelemetry,ParameterValue="I Have Read and Opt In to SmartSense Telemetry" \
   --region "${REGION}" \
   --stack-name "${STACK_NAME}" \
   --disable-rollback \
   --template-url $TEMPLATE_URL
  
  #aws cloudformation describe-stack-events --stack-name af-adv --region eu-west-1

  aws --region "${REGION}" cloudformation wait stack-create-complete --stack-name "${STACK_NAME}"

  echo "STACK_NAME=${STACK_NAME}" > ${STACK_NAME}.${extension}
  echo "EMAIL=${EMAIL}" >> ${STACK_NAME}.${extension}
  echo "PASSWORD=${PASSWORD}" >> ${STACK_NAME}.${extension}
  echo "SSHKEY=${SSH_KEY_NAME}" >> ${STACK_NAME}.${extension}
  if [ "$TEMPLATE_TYPE" != "basic" ]
  then
    echo "RDS_DB_ADDRESS=$RDS_DB_ADDRESS" >> ${STACK_NAME}.${extension}
    echo "RDS_DB_PORT=$RDS_DB_PORT" >> ${STACK_NAME}.${extension}
    echo "RDS_DB_NAME=$RDS_DB_NAME" >> ${STACK_NAME}.${extension}
    echo "RDS_DB_USER=$RDS_DB_USER" >> ${STACK_NAME}.${extension}
    echo "RDS_DB_PASSWORD=$RDS_DB_PASSWORD" >> ${STACK_NAME}.${extension}

    echo "VPCID=$VPCID" >> ${STACK_NAME}.${extension}
    echo "SUBNETID=$SUBNETID">> ${STACK_NAME}.${extension}
  fi
  CLOUD_URL=$(aws --region $REGION cloudformation describe-stacks --stack-name $STACK_NAME | jq '.Stacks[0].Outputs[] | select(.OutputKey == "CloudController") | .OutputValue' -r | sed -e 's/&quot;/"/g' | jq .CloudURL -r)
  echo "CLOUD_URL=${CLOUD_URL}" >> ${STACK_NAME}.${extension}
  HOST=${CLOUD_URL#*//}
  echo "HOST=${HOST}" >> ${STACK_NAME}.${extension}
  CB_INSTANCE_ID=$(aws --region $REGION cloudformation list-stack-resources --stack-name ${STACK_NAME}  | jq '.StackResourceSummaries[] | select(.ResourceType=="AWS::EC2::Instance").PhysicalResourceId')
  CB_PUBLIC_IP=$(aws --region $REGION ec2 describe-instances --instance-ids $(echo ${CB_INSTANCE_ID} | tr -d '"' ) | jq .Reservations[0].Instances[0].PublicIpAddress)
  CB_PUBLIC_IP=$(echo ${CB_PUBLIC_IP} | tr -d '"' )
  echo "CB_PUBLIC_IP=${CB_PUBLIC_IP}" >> ${STACK_NAME}.${extension}
  CB_VERSION=$(ssh -o StrictHostKeyChecking=no -i ${SSH_PRIV_KEY} cloudbreak@${CB_PUBLIC_IP} " cd /var/lib/cloudbreak-deployment ; cbd version | grep cloudbreak: |sed 's/.*://' " )
  CB_VERSION=$( echo $CB_VERSION | sed -r 's/\x1b\[[0-9;]*m?//g' ) #removing ascii escape
  echo "CB_VERSION=${CB_VERSION}" >> ${STACK_NAME}.${extension}
  echo "CLOUD_VERSION=$(curl -k $CLOUD_URL/cb/info | jq '.app.version' -r)" >> ${STACK_NAME}.${extension}
  
}

terminate() {
	: ${STACK_NAME:? required}
	aws --region "${REGION}" cloudformation delete-stack --stack-name "${STACK_NAME}"
	#aws --region "${REGION}" cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}"
}

main() {
  case "$1" in
    "deploy")
      deploy
      ;;
    "terminate")
      terminate
      ;;
    *)
	  exit 1
  esac
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
