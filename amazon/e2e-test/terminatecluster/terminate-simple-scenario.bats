#!/usr/bin/env bats

load ../$CLUSTER_NAME".clusterdescriptor"
load ../helper/hdc/cli

TAGS="$STACK_NAME $CLUSTER_NAME hdc-cli terminate functional"

@test "Terminate cluster [$TAGS]" {
    terminate-cluster
}

@test "Terminate cluster - check cluster status - delete in progress [$TAGS]" {
    [[ $( describe-cluster | jq -r ".Status") == DELETE_IN_PROGRESS ]]
#  "Status": "DELETE_IN_PROGRESS",
#  "StatusReason": "Terminating the cluster and its infrastructure."
#}
}

@test "Terminate - check clusters status in list - delete in progress [$TAGS]" { 
#→ ./hdc list-clusters $HDC_COMMON_ARGS_WO_CLUSTER | jq '.[] | select(.ClusterName=="hive26") '
#{
#  "ClusterName": "hive26",
#  "HDPVersion": "2.6",
#  "ClusterType": "EDW-ETL: Apache Hive 1.2.1, Apache Spark 2.1",
#  "Status": "DELETE_IN_PROGRESS",
#  "NodesStatus": "HEALTHY"
#}
    [[ $(list-clusters | jq -r ".[] | select(.ClusterName==\"${CLUSTER_NAME}\") | .Status " ) == DELETE_IN_PROGRESS ]]
}

@test "Terminate cluster - wait for finish [$TAGS]" {
    threeminuteslater=$(($SECONDS+180))
    stillexist=10 # anything which is greater than 0

    while [ $SECONDS -lt $threeminuteslater ] && [ $stillexist -gt 0 ] 
    do
	sleep 30
	stillexist=$( list-clusters | jq -r ".[] | select(.ClusterName==\"${CLUSTER_NAME}\") | length " )
    done
    [[ ${stillexist} -eq 0 ]] 
}

@test "Terminate cluster - check cluster status - not found [$TAGS]" {
    run describe-cluster 
    [[ $output == *"not found"* && $status -eq 1 ]]
}

@test "Terminate cluster - check cluster instances status in describe - not found [$TAGS]" { 
    run describe-cluster-instances
    [[ $output == *"not found"* && $status -eq 1 ]]
}

@test "Terminate - check clusters status in list - not in the list [$TAGS]" { 
    [[ $( list-clusters | jq -r ".[] | select(.ClusterName==\"${CLUSTER_NAME}\") | length " ) -eq 0 ]]
}

@test "Teardown - rm cluster descriptor [$TAGS]" {
    rm ${CLUSTER_NAME}.clusterdescriptor.bash
}

