#!/usr/bin/env bats
#set -ex

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

: ${TEST_RDS_NAME:=testrdshive}
: ${TEST_RDS_USERNAME:=hiveuser}
: ${TEST_RDS_TYPE:=HIVE} #DRUID
: ${TEST_HDP_VERSION:=2.6} #2.5 , 2.6, for druid 2.6 allowed
: ${TEST_DB_NAME:=hive}
: ${TEST_EXPECTED_STATUS:=0}

TAGS="hdc-cli $STACK_NAME "

@test "register hive metastore service [$TAGS]" {
  run register-metastore \
  --rds-name ${TEST_RDS_NAME} \
  --rds-url ${RDS_DB_ADDRESS}:${RDS_DB_PORT}/${TEST_DB_NAME} \
  --rds-username ${TEST_RDS_USERNAME} \
  --rds-password ${RDS_DB_PASSWORD} \
  --rds-type ${TEST_RDS_TYPE} \
  --hdp-version ${TEST_HDP_VERSION}

  if [ $status -eq 0 ] 
  then
    echo "SHARED_${TEST_RDS_TYPE}_METASTORE=${TEST_RDS_NAME}" >> $STACK_NAME".stackdescriptor.bash"
  fi

  echo $output >&2
  [ $status -eq ${TEST_EXPECTED_STATUS} ]
}
