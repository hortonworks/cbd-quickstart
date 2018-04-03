#!/usr/bin/env bats
#set -ex

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

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
: ${TEST_GROUP_SEARCH_BASE:="CN=Users,DC=ad,DC=seq,DC=com"}

TAGS="hdc-cli $STACK_NAME "

@test "register ldap [$TAGS]" {
  run register-ldap \
  --ldap-name ${TEST_LDAP_NAME} \
  --ldap-server ${TEST_LDAP_S}://${TEST_LDAP_HOST}:${TEST_LDAP_PORT} \
  --ldap-domain ${TEST_LDAP_DOMAIN} \
  --ldap-bind-dn ${TEST_LDAP_BIND_DN} \
  --ldap-bind-password ${TEST_LDAP_BIND_PW} \
  --ldap-user-search-base ${TEST_USER_SEARCH_BASE} \
  --ldap-user-search-filter ${TEST_USER_SEARCH_FILTER} \
  --ldap-user-search-attribute ${TEST_USER_SEARCH_ATTR} \
  --ldap-group-search-base ${TEST_GROUP_SEARCH_BASE}

  echo $output >&2
 
  if [ $status -eq 0 ] 
  then
    echo "SHARED_LDAP=${TEST_LDAP_NAME}" >> $STACK_NAME".stackdescriptor.bash"
  fi

  [ $status -eq ${TEST_EXPECTED_STATUS} ]
}
