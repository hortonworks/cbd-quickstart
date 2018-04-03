#!/usr/bin/env bats

load ../helper/hdc/ic-helper

TAGS="imagecatalog static"

@test "Validate image catalog hdp and ambari versions for given rc: $RELEASE_TYPE [$TAGS]" {
  if [[ "${RELEASE_TYPE}" == "TP" ||  "${RELEASE_TYPE}" == "GA" ]]
  then
    skip "This test only work with RC releases currently"
  fi

  hdp26ok=$(get_imagecatalog | jq_check_ic_versions "HDP-2.6"  "2.5.0.0-1094" "2.6.0.0-598" )
  echo Image catalog should have entries for 2.6 version. $hdp26ok :: >&2

  hdp25ok=$(get_imagecatalog | jq_check_ic_versions "HDP-2.5"  "2.4.2.2-1" "2.5.0.1-265" )
  echo Image catalog should have entries for 2.5 version. $hdp25ok :: >&2

  [[ ${hdp26ok} == true && ${hdp25ok} == true ]]
}

