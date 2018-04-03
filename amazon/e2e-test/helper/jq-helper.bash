#!/bin/bash

function b {
	jq ' map(has("InstanceId")) | all '
}

function c11 {
	jq " map(has(\"${1}\")) | all "
}

function catresult {
	cat result.json
}
