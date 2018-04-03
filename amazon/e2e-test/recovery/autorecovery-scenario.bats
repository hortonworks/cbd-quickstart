#!/usr/bin/env bats

load ../$CLUSTER_NAME".clusterdescriptor"
load ../helper/hdc/cli

BTS_TEMPFILE="result.json"
TAGS="$CLUSTER_NAME $STACK_NAME functional recovery hdc-cli"

@test "Validate describe instances command on a running cluster - running correctly, saving result [$TAGS]" {
    describe-cluster-instances > $BTS_TEMPFILE
}

#test "Validate repair cluster - check instance number [$TAGS]" {
#    instance_no=$( jq ' length ' $BTS_TEMPFILE )
#    [ $instance_no -eq 5 ]
#}

@test "Validate repair cluster - check cluster status - available [$TAGS]" {
    [[ $( describe-cluster | jq -r ".Status") == AVAILABLE ]]
}

@test "Validate repair cluster - check instance and host statuses - registered and healthy [$TAGS]" {
    [[ $(jq-cluster-instances-all-healthy-and-registered $BTS_TEMPFILE ) == true ]]
}

@test "Validate repair cluster - determine and kill a worker node [$TAGS]" {
  aws-select-and-kill-instance-which-is-a "worker"
}

@test "Validate repair cluster - wait for hdc noticing [$TAGS]" {
    instance_no=$( jq ' length ' $BTS_TEMPFILE )
    tenminuteslater=$(($SECONDS+600))
    current_instance_no=$instance_no
    while [ $SECONDS -lt $tenminuteslater ] && [ $instance_no -eq $current_instance_no ] 
    do
	sleep 30
	current_instance_no=$( describe-cluster-instances | jq -r ' length ' )
    done
    [ $instance_no -gt $current_instance_no ] 
}

@test "Validate repair cluster - check cluster status [$TAGS]" {
    describe-cluster 
}


@test "Validate repair cluster - check clusters status [$TAGS]" {
    list-clusters 
}

@test "Validate repair cluster - wait for hdc autorepairing the cluster [$TAGS]" {
    tenminuteslater=$(($SECONDS+600))
    instance_no=$( jq ' length ' $BTS_TEMPFILE )
    current_instance_no=$(( $instance_no - 1 ))
    while [ $SECONDS -lt $tenminuteslater ] && [ $instance_no -gt $current_instance_no ] 
    do
	sleep 30
	current_instance_no=$( describe-cluster-instances | jq -r ' length ' )
    done
    [ $instance_no -eq $current_instance_no ]
}

@test "Validate repair cluster - check cluster status - update in progress [$TAGS]" {
    [[ $( describe-cluster | jq -r '.Status=="UPDATE_IN_PROGRESS"' ) == true ]]
}

@test "Validate repair cluster - check clusters status - update in progress [$TAGS]" {
    [[ $(list-clusters | jq-list-cluster-in-status "UPDATE_IN_PROGRESS" ) == true ]]
}

@test "Validate repair cluster - wait for healthy and registered new node [$TAGS]" {
    tenminuteslater=$(($SECONDS+600))
    are_instances_healthy=false
    while [ $SECONDS -lt $tenminuteslater ] && [ $are_instances_healthy == false ] 
    do
	sleep 30
	are_instances_healthy=$(describe-cluster-instances |jq-cluster-instances-all-healthy-and-registered )
    done
    [ $are_instances_healthy == true ]
}

@test "Validate repair cluster - check cluster status - available again [$TAGS]" {
    [[ $(describe-cluster | jq -r '.Status=="AVAILABLE"') == true ]]
}

@test "Validate repair cluster - check clusters status - available again [$TAGS]" {
    [[ $(list-clusters | jq-list-cluster-in-status "AVAILABLE" ) == true ]]

}
