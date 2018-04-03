#!/usr/bin/env bats
#set -ex

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli
load ../helper/hdc/api

: ${TEST_EXPECTED_STATUS:=0}
: ${TEST_LDAP_NAME:=test_ldap}
: ${TEST_LDAP_S:=ldap}
: ${TEST_LDAP_HOST:=10.0.3.138}
: ${TEST_LDAP_PORT:=389}
: ${TEST_LDAP_DOMAIN:=ad.seq.com}
: ${TEST_LDAP_BIND_DN:="CN=Administrator,CN=Users,DC=ad,DC=seq,DC=com"}
: ${TEST_LDAP_BIND_PW:="Admin123!"}
: ${TEST_USER_SEARCH_BASE:="CN=Users,DC=ad,DC=seq,DC=com"}
: ${TEST_USER_SEARCH_FILTER:="CN"}
: ${TEST_USER_SEARCH_ATTR:="sAMAccountName"}
: ${TEST_GROUP_SEARCH_BASE:="CN=scopes,DC=ad,DC=seq,DC=com"}

TAGS="hdc-cli $STACK_NAME "

@test "register ldap [$TAGS]" {
  run register-ldap \
  --ldap-name ${TEST_LDAP_NAME} \
  --ldap-server ${TEST_LDAP_S}://${TEST_LDAP_HOST}:${TEST_LDAP_PORT} \
  --ldap-domain ${TEST_LDAP_DOMAIN} \
  --ldap-bind-dn ${TEST_LDAP_BIND_DN} \
  --ldap-bind-password ${TEST_LDAP_BIND_PW} \
  --ldap-directory-type LDAP \
  --ldap-user-search-base ${TEST_USER_SEARCH_BASE} \
  --ldap-user-name-attribute cn \
  --ldap-user-object-class person \
  --ldap-group-member-attribute member \
  --ldap-group-name-attribute cn \
  --ldap-group-object-class group \
  --ldap-group-search-base ${TEST_GROUP_SEARCH_BASE}

  echo $output >&2
  
  run getpublicldap ${TEST_LDAP_NAME} 

  if [[ $output =~ .*not\ found.* ]] 
  then
    echo "ldap record has not created" >&2
    return $(expr 1 - $TEST_EXPECTED_STATUS)
  else
    echo "ldap record has created" >&2
    echo "SHARED_LDAP=${TEST_LDAP_NAME}" >> $STACK_NAME".stackdescriptor.bash"
    return $TEST_EXPECTED_STATUS
  fi

  [ $status -eq ${TEST_EXPECTED_STATUS} ]
}
