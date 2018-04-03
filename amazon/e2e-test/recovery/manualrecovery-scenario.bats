#!/usr/bin/env bats

load ../$CLUSTER_NAME".clusterdescriptor"
load ../helper/hdc/cli

BTS_TEMPFILE="result.json"
TAGS="$STACK_NAME $CLUSTER_NAME functional hdc-cli recovery"

@test "Validate describe instances command on a running cluster - running correctly, saving result [$TAGS]" {
    describe-cluster-instances > $BTS_TEMPFILE
}

#test "Validate repair cluster - check instance number [$TAGS]" {
#    instance_no=$( jq ' length ' $BTS_TEMPFILE )
#    [[ ${instance_no} -eq 5 ]]
#}

@test "Validate repair cluster - check cluster status - available [$TAGS]" {
    [[ $( describe-cluster | jq -r ".Status") == AVAILABLE ]]
}

@test "Validate repair cluster - check instance and host statuses - registered and healthy [$TAGS]" {
    [[ $(jq-cluster-instances-all-healthy-and-registered $BTS_TEMPFILE ) == true ]]
}

@test "Validate repair cluster - determine and kill a compute node [$TAGS]" {
    aws-select-and-kill-instance-which-is-a "compute"
}

@test "Validate repair cluster - wait for hdc noticing unhealthy node [$TAGS]" {
    tenminuteslater=$(($SECONDS+600))
    are_instances_healthy=true
    while [ $SECONDS -lt $tenminuteslater ] && [ $are_instances_healthy == true ]
    do
	sleep 30
	are_instances_healthy=$( describe-cluster-instances | jq-cluster-instances-all-healthy-and-registered )
    done
    [[ ${are_instances_healthy} == false ]]
}

@test "Validate repair cluster - check cluster status in describe [$TAGS]" { #todo: hat de ez igy nem csinal semmit...
    describe-cluster 
}

@test "Validate repair cluster - check clusters status in list [$TAGS]" { #todo: hat de ez igy nem csinal semmit...
    list-clusters
}

@test "Validate repair cluster - wait for hdc autorepair has not launched [$TAGS]" {
    threeminuteslater=$(($SECONDS+180))
    instance_no=$(jq ' length ' $BTS_TEMPFILE )
    current_instance_no=$(($instance_no - 1))

    while [ $SECONDS -lt $threeminuteslater ] && [ $instance_no -gt $current_instance_no ] 
    do
	sleep 30
	current_instance_no=$( describe-cluster-instances | jq -r '[ . [] | select(.HostStatus=="HEALTHY") ] | length')
    done
    [[ ${instance_no} -gt ${current_instance_no} ]] #expected: reach the time limit, no autorecovery here
}

@test "Validate repair cluster - check cluster status in describe - update is not in progress [$TAGS]" {
    [[ $( describe-cluster | jq -r '.Status=="UPDATE_IN_PROGRESS"') == false ]]
}

@test "Validate repair cluster - check clusters status in list - update is not in progress [$TAGS]" {
    [[ $(list-clusters | jq-list-cluster-in-status "UPDATE_IN_PROGRESS" ) == false ]]
}

@test "Validate repair cluster - compute node cannot repair [$TAGS]" {
    [[ $(./hdc repair-cluster --node-type compute $HDC_COMMON_ARGS 2>&1>/dev/null) == *"compute nodes cannot be replaced"* ]]
}

@test "Validate repair cluster - start compute node remove [$TAGS]" {
    ./hdc repair-cluster --node-type compute --remove-only true $HDC_COMMON_ARGS
}

@test "Validate repair cluster - check cluster status - update in progress [$TAGS]" {
    [[ $(describe-cluster | jq -r '.Status=="UPDATE_IN_PROGRESS"') == true ]]
}

@test "Validate repair cluster - wait for compute node is removed [$TAGS]" {
    tenminuteslater=$(($SECONDS+600))
    instance_no=$(jq ' length ' $BTS_TEMPFILE )
	current_instance_no=$(describe-cluster-instances | jq -r '[ . [] | select(.HostStatus=="HEALTHY") ] | length')
    while [ $SECONDS -lt $tenminuteslater ] && [ $instance_no -eq $current_instance_no ]
    do
	sleep 30
	current_instance_no=$(describe-cluster-instances | jq -r '[ . [] | select(.HostStatus=="HEALTHY") ] | length')
    done
    [[ ${instance_no} -gt ${current_instance_no} ]]
}

@test "Validate repair cluster - all nodes are healthy [$TAGS]" {
    are_instances_healthy=false
    while [ $are_instances_healthy == false ]
    do
	are_instances_healthy=$(describe-cluster-instances |jq-cluster-instances-all-healthy-and-registered )
    done
    [[ ${are_instances_healthy} == true ]]
}

@test "Validate repair cluster - check cluster status - available again [$TAGS]" {
    [[ $(describe-cluster | jq -r '.Status=="AVAILABLE"') == true ]]
}

@test "Validate repair cluster - check clusters status - available again [$TAGS]" {
    [[ $(list-clusters | jq-list-cluster-in-status "AVAILABLE" ) == true ]]
}
