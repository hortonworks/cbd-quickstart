#!/usr/bin/env bats
#set -xe

: ${CLUSTER_NAME:=autotest-edw26-flex}

load ../$STACK_NAME".smartsense_descriptor"
load ../helper/hdc/cli
load ../helper/smartsense-stack-prep

CLUSTER_FILE_NAME=$CLUSTER_NAME".clusterdescriptor.bash"
TAGS="$STACK_NAME $CLUSTER_NAME flex functional hdc-cli"

function get_ss_id() {
    cd /var/lib/cloudbreak-deployment/
    [[ $(cbd util get-usage latest | jq -r '.controller.smartSenseId') == 'A-00000000-C-00000000' ]] && echo true || echo false
}

function get_felx_id() {
    cd /var/lib/cloudbreak-deployment/
    [[ $(cbd util get-usage latest | jq -r ' .products[].components[] | select(.componentId=="HDCLOUD-AWS-HDP") | .instances[].flexSubscriptionId' | tail -1) == 'FLEX-0000000000' ]] && echo true || echo false
}

function get_peak_nodes() {
    cd /var/lib/cloudbreak-deployment/
    echo $(cbd util get-usage latest | jq -r '.products[].components[] | select(.componentId=="HDCLOUD-AWS-HDP") | .instances[].peakUsage' | tail -1)
}

function check_sftp_status() {
    docker exec -i cbreak_smartsense_1 bash -c "grep 'File uploaded successfully to sftp server:a-00000000-c-00000000_hdcu-' /var/log/hst/hst-server.log"
}

@test "describe SmartSense command should return [A-00000000-C-00000000] id" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run describe-smartsensesubscription
    echo $output >&2

    [[ "$output" =~ "A-00000000-C-00000000" ]]
}

@test "list FLEX subscriptions should return with no value" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run list-flexsubscriptions SubscriptionID | head -c1 | wc -c
    echo $output >&2

    [[ "$output" -eq 0 ]]
}

@test "register FLEX subscription validation error should appear for [FLEX-00000000000] id" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run register-flexsubscription default FLEX-00000000000
    echo $output >&2

    [[ "$output" =~ "status code: 400, message: The given Flex subscription id is not in FLEX-xxxxxxxxxx format!" && "$status" -ne 0 ]]
}

@test "register FLEX subscription should be successful for [FLEX-0000000000] id" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run register-flexsubscription default FLEX-0000000000 | head -c1 | wc -c
    echo $output >&2

    [[ "$output" -eq 0 ]]
}

@test "set FLEX subscription to default for cluster creation" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run set-default-flexsubscription default | head -c1 | wc -c
    echo $output >&2

    [[ "$output" -eq 0 ]]
}

@test "set FLEX subscription for controller" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run use-flexsubscription-for-controller default | head -c1 | wc -c
    echo $output >&2

    [[ "$output" -eq 0 ]]
}

@test "[FLEX-0000000000] FLEX subscription should should be listed" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run list-flexsubscriptions SubscriptionID
    echo $output >&2

    [[ "$output" =~ "FLEX-0000000000" ]]
}

@test "[FLEX-0000000000] FLEX subscription should be the default for cluster creation" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run list-flexsubscriptions IsDefault
    echo $output >&2

    [[ "$output" =~ "true" ]]
}

@test "[FLEX-0000000000] FLEX subscription should be the default for controller" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run list-flexsubscriptions UsedForController
    echo $output >&2

    [[ "$output" =~ "true" ]]
}

@test "create FLEX cluster [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    echo "STACK_NAME=${STACK_NAME}" > $CLUSTER_FILE_NAME
    echo "CLOUD_URL=${CLOUD_URL}" >> $CLUSTER_FILE_NAME
    echo "EMAIL=${EMAIL}" >> $CLUSTER_FILE_NAME
    echo "PASSWORD=${PASSWORD}" >> $CLUSTER_FILE_NAME
    echo "SSHKEY=${SSHKEY}" >> $CLUSTER_FILE_NAME
    echo "CLUSTER_NAME=${CLUSTER_NAME}" >> $CLUSTER_FILE_NAME
    echo "TEMPLATE_VERSION=${TEMPLATE_VERSION}" >> $CLUSTER_FILE_NAME
    echo "CB_VERSION=${CB_VERSION}" >> $CLUSTER_FILE_NAME

    INPUT_JSON_FILE=common/cluster-templates/${CLUSTER_NAME}-template.json
    echo "INPUT_JSON_FILE=${INPUT_JSON_FILE}" >> $CLUSTER_FILE_NAME

    list-cluster-types
    run create-cluster --cli-input-json $INPUT_JSON_FILE
    echo $output >&2

    load ../$CLUSTER_NAME".clusterdescriptor"
}

@test "Validate 'cbd util get-usage latest' SmartSense ID" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    [[ $(usage_json_checker get_ss_id) =~ "true" ]]
}

@test "Validate 'cbd util get-usage latest' FLEX ID" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    [[ $(usage_json_checker get_felx_id) =~ "true" ]]
}

@test "Validate 'cbd util get-usage latest' peak usage is 4" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    [[ $(usage_json_checker get_peak_nodes) =~ ^4 ]]
}

@test "Validate 'File uploaded successfully to sftp server' from cbreak_smartsense container" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    [[ $(usage_json_checker check_sftp_status) =~ "a-00000000-c-00000000" ]]
}

@test "resize cluster - worker nodes [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    resize --scaling-adjustment 2 --node-type worker
}

@test "resize - wait for available nodes [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    tenminuteslater=$(($SECONDS+600))
    are_available=false

    while [ $SECONDS -lt $tenminuteslater ] && [ $are_available == false ]
    do
	    sleep 30
	    are_available=$(describe-cluster | jq -r '.Status=="AVAILABLE"')
    done

    [[ $are_available == true ]]
}

@test "Validate 'cbd util get-usage latest' peak usage is 6" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    [[ $(usage_json_checker get_peak_nodes) =~ ^6 ]]
}

@test "Terminate cluster [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run terminate-cluster
}

@test "Terminate cluster - wait for finish [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    threeminuteslater=$(($SECONDS+180))
    stillexist=10 # anything which is greater than 0

    while [ $SECONDS -lt $threeminuteslater ] && [ $stillexist -gt 0 ]
    do
	    sleep 30
	    stillexist=$( list-clusters | jq -r ".[] | select(.ClusterName==\"${CLUSTER_NAME}\") | length " )
    done

    [[ ${stillexist} -eq 0 ]]
}

@test "Terminate - check clusters status in list - not in the list [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    [[ $(list-clusters | jq -r ".[] | select(.ClusterName==\"${CLUSTER_NAME}\") | length ") -eq 0 ]]
}

@test "Teardown - rm cluster descriptor [$TAGS]" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    rm ${CLUSTER_NAME}.clusterdescriptor.bash
}

@test "FLEX subscriptions should be deleted successful" {
    if [[ "${RELEASE_TYPE}" != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run delete-flexsubscription default | head -c1 | wc -c
    echo $output >&2

    [[ "$output" -eq 0 ]]
}

@test "checking release type for SmartSense and FLEX" {
    if [[ "${RELEASE_TYPE}" == "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi
}
