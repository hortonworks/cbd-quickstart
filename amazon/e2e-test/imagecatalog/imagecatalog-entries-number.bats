#!/usr/bin/env bats

: ${EXPECTED_IC_CO:=2}

load ../helper/hdc/ic-helper

TAGS="imagecatalog static"

@test "Validate image catalog entry number for for given rc: $RELEASE_TYPE [$TAGS]" {
  if [[ "${RELEASE_TYPE}" == "TP" ||  "${RELEASE_TYPE}" == "GA" ]]
  then
    skip "This test only work with RC releases currently"
  fi

  ic_length_for_version=$(curl -s ${URL_IMAGECATALOG} | jq "[.cloudbreak[].ambari | select( .cb_versions[]==\"${RELEASE_TYPE}\" ) ] | length")
  echo Image catalog should have entries for given version. Expected: ${EXPECTED_IC_CO} Actual: ${ic_length_for_version} >&2
  [[ ${ic_length_for_version} -eq ${EXPECTED_IC_CO} ]]
  #assert [ ${ic_length_for_version} -eq ${EXPECTED_IC_CO} ]
}
