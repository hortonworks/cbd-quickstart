#!/usr/bin/env bats

load ../$CLUSTER_NAME".clusterdescriptor"

@test "cluster is in the scope: $CLUSTER_NAME" {
    [[ "$CLUSTER_NAME" == "hive26" ]]
    [[ "$CLUSTER_NAME" != "" ]]
}

