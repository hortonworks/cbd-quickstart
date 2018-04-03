#!/bin/bash

[[ "$TRACE" ]] && set -x

: ${MasterUsernameParameter:=dbadmin}
: ${MasterUserPassword:=Admin2016}

stack_name=cbr-common-${SHARED_PREFIX:-$USER}
templateFile=cbr-common.yml

sigil -f cbr-common.tmpl SHARED_PREFIX=${SHARED_PREFIX:-$USER} > $templateFile

aws cloudformation create-stack \
 --capabilities CAPABILITY_IAM \
 --parameters \
    ParameterKey=MasterUsernameParameter,ParameterValue="${MasterUsernameParameter}" \
    ParameterKey=MasterUserPassword,ParameterValue=${MasterUserPassword} \
 --stack-name "${stack_name}" \
 --tags \
    Key=Owner,Value=${OWNER:-$USER} \
    Key=owner,Value=${OWNER:-$USER} \
    Key=Name,Value="${stack_name}" \
    Key=SharedPrefix,Value=${SHARED_PREFIX:-$USER} \
 --disable-rollback \
 --template-body file://${templateFile}

