#!/usr/bin/env bats

load ../$CLUSTER_NAME".clusterdescriptor"
load ../helper/hdc/cli

: ${TEST_NODE_TYPE:=worker}
: ${TEST_RESIZE_NUMBER:=2}

BTS_TEMPFILE="result.json"
TAGS="$STACK_NAME $CLUSTER_NAME functional hdc-cli resize"

@test "resize describe cluster for number of instances [$TAGS]" {
    describe-cluster-instances > $BTS_TEMPFILE
}

@test "resize cluster - ${TEST_NODE_TYPE} nodes [$TAGS]" {
  resize --scaling-adjustment ${TEST_RESIZE_NUMBER} --node-type ${TEST_NODE_TYPE}
}

@test "resize check cluster status - update in progress [$TAGS]" {
    sleep 5 #could be too fast without this
    [[ $( describe-cluster | jq -r '.Status=="UPDATE_IN_PROGRESS"' ) == true ]]
}

@test "resize - check clusters status - update in progress [$TAGS]" {
    [[ $(list-clusters | jq-list-cluster-in-status "UPDATE_IN_PROGRESS" ) == true ]]
}


@test "resize - wait for available nodes [$TAGS]" {
    tenminuteslater=$(($SECONDS+600))
    are_available=false
    while [ $SECONDS -lt $tenminuteslater ] && [ $are_available == false ] 
    do
	sleep 30
	are_available=$(describe-cluster | jq -r '.Status=="AVAILABLE"')
    done
    [ $are_available == true ]
}

@test "resize - check clusters status - available again [$TAGS]" {
    [[ $(list-clusters | jq-list-cluster-in-status "AVAILABLE" ) == true ]]
}
  
@test "resize - validate instances number [$TAGS]" {
  instance_no=$( jq "map(select(.Type==\"${TEST_NODE_TYPE}\")) | length" $BTS_TEMPFILE )
  current_instance_no=$( describe-cluster-instances | jq -r "map(select(.Type==\"${TEST_NODE_TYPE}\")) | length" )
  [ $(( $instance_no + $TEST_RESIZE_NUMBER )) -eq $current_instance_no ]
}

@test "resize teardown [$TAGS]" {
  rm -f $BTS_TEMPFILE
}
