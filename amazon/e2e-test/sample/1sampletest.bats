#!/usr/bin/env bats

PIPELOG=" run.log"

@test "cluster is in the scope0" {
    echo akarok mondani valamit >&2
    [[ "$CLUSTER_NAME" != "hive26" ]]
    [[ "$CLUSTER_NAME" == "" ]]
}

@test "cluster is in the scope1" {
    printf "ez nem megy" 1>&2
    [[ "$CLUSTER_NAME" != "" ]]
}

