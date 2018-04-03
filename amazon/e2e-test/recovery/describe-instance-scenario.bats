#!/usr/bin/env bats

load ../$CLUSTER_NAME".clusterdescriptor"
load ../helper/hdc/cli

BTS_TEMPFILE="result.json"
CLUSTER_INSTANCE_NO=5 #TODO  : read it, cloud be better
TAGS="$STACK_NAME $CLUSTER_NAME functional describe hdc-cli"

# $1 key name
#arg could be a file, or read from stdin
function jq-cluster-instances-all-has-a-key() {
  jq ' map(has("'$1'")) | all ' $2
}

@test "Validate describe instances command on a running cluster - running correctly, saving result [$TAGS]" {
    describe-cluster-instances > $BTS_TEMPFILE 
}

@test "Validate describe instances command result - result contains all keys " {
    [[ $( jq-cluster-instances-all-has-a-key "InstanceId" $BTS_TEMPFILE ) = "true" ]]
    [[ $( jq-cluster-instances-all-has-a-key "PublicIP" $BTS_TEMPFILE ) = "true" ]]
    [[ $( jq-cluster-instances-all-has-a-key "PrivateIP" $BTS_TEMPFILE ) = "true" ]]
    [[ $( jq-cluster-instances-all-has-a-key "InstanceStatus" $BTS_TEMPFILE ) = "true" ]]
    [[ $( jq-cluster-instances-all-has-a-key "HostStatus" $BTS_TEMPFILE ) = "true" ]]
    [[ $( jq-cluster-instances-all-has-a-key "Type" $BTS_TEMPFILE ) = "true" ]]
    [[ $( jq-cluster-instances-all-has-a-key "InstanceId" $BTS_TEMPFILE ) = "true" ]]
}

@test "Validate describe instances command result - result contains instances [$TAGS]" {
    [[ $( jq ' length ' $BTS_TEMPFILE ) -eq $CLUSTER_INSTANCE_NO ]]
}
    
@test "Teardown - remove temporary file  [$TAGS]" {
    rm $BTS_TEMPFILE
}
