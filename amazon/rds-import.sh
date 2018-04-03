#!/bin/bash

key_name=${KEY_NAME:=seq-master}
stack_name=cloudcontroller-${OWNER:-$USER}-$(date | sed 's/ .*//')-$(date +%H%M)
email=${OWNER:-$USER}@hortonworks.com

templateFile=build/cbd-advanced-rds-import-snapshot.template

set -x
make clean
#aws cloudformation describe-stacks --query 'Stacks[? Tags[? Key==`SharedPrefix`]].{stackname:StackName, prefix:Tags[? Key==`SharedPrefix`]|[0].Value}'

select prefix in $(aws cloudformation describe-stacks --query 'Stacks[? Tags[? Key==`SharedPrefix`]].{prefix:Tags[? Key==`SharedPrefix`]|[0].Value}' --out text ); do
    export SHARED_PREFIX=$prefix
    break
done

sigil -f cbd-advanced-import.tmpl  CBD_VERSION=snapshot RDS=tru VPC=true TP= SHARED_PREFIX=${SHARED_PREFIX}> $templateFile

aws cloudformation create-stack \
 --capabilities CAPABILITY_IAM \
 --parameters \
    ParameterKey=KeyName,ParameterValue="${key_name}" \
    ParameterKey=AdminPassword,ParameterValue=Admin2016 \
    ParameterKey=RemoteLocation,ParameterValue=0.0.0.0/0 \
    ParameterKey=EmailAddress,ParameterValue="${email}" \
    ParameterKey=RdsPassword,ParameterValue=Admin2016 \
 --stack-name "${stack_name}" \
 --tags \
    Key=Owner,Value=${OWNER:-$USER} \
    Key=Name,Value="${stack_name}" \
    Key=UsedSharedPrefix,Value="${SHARED_PREFIX}" \
 --disable-rollback \
 --template-body file://${templateFile}

