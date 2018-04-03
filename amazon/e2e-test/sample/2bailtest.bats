#!/usr/bin/env bats

PIPELOG=" run.log"

rutin1() {
  echo $BATS_TEST_NUMBER
  echo "Bail out!"
  return 1
}

@test "cluster is in the scope0" {
    return 1
}

rutin1

@test "cluster is in the scope1" {
    printf "ez nem megy" 1>&2
    [[ "$CLUSTER_NAME" == "" ]]
}

