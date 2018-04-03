#!/usr/bin/env bats
#set -ex

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/api

: ${TEST_EXPECTED_STATUS:=0}
: ${TEST_LDAP_NAME:=test_ldap}

TAGS="hdc-cli $STACK_NAME "

@test "ldap is exists [$TAGS]" {
  run getpublicldap ${TEST_LDAP_NAME} 

  if [[ $output =~ .*not\ found.* ]] 
  then
    echo "ldap does not exist" >&2
    return $(expr 1 - $TEST_EXPECTED_STATUS)
  else
    echo "ldap does exist" >&2
    return $TEST_EXPECTED_STATUS
  fi

  [ $status -eq ${TEST_EXPECTED_STATUS} ]
}
