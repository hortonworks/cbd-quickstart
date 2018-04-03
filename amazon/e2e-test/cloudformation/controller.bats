#!/usr/bin/env bats

#set -xe

load ../helper/smartsense-stack-prep

AUTO_SMARTSENSE_ID="A-99903636-C-36363636"
TEST_SMARTSENSE_ID="A-00000000-C-00000000"
INVALID_SMARTSENSE_ID="D-000000-00"
PRODUCT_TELEMETRY_OPT='I Have Read and Opt In to SmartSense Telemetry'
PRODUCT_TELEMETRY_NO='I Do Not Opt In to SmartSense Telemetry'


@test "CFN validation error should be present for [$INVALID_SMARTSENSE_ID] SmartSense ID" {
    if [[ $(get_releasetype) != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    run create_ss_controller "${PRODUCT_TELEMETRY_OPT}" "${INVALID_SMARTSENSE_ID}"
    echo $output >&2

    [[ "$output" =~ "An error occurred (ValidationError) when calling the CreateStack operation: Parameter SmartSenseId failed to satisfy constraint: Should be empty or a valid SmartSense subscription id like 'A-00000000-C-00000000'!" && "$status" -ne 0 ]]
}

@test "CBD validation error should be present for [$PRODUCT_TELEMETRY_NO] Telemetry and [$TEST_SMARTSENSE_ID] SmartSense ID" {
    if [[ $(get_releasetype) != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    STACK_NAME=$(set_stack_name)

    run create_ss_controller "${PRODUCT_TELEMETRY_NO}" "${TEST_SMARTSENSE_ID}"
    echo $output >&2
    [[ "$output" =~ "Waiter StackCreateComplete failed: Waiter encountered a terminal failure state" ]]

    run get_failure_event "${STACK_NAME}"
    echo $output >&2
    [[ "$output" =~ "Failed to create resource. You must opt-in to SmartSense telemetry when entering your existing SmartSenseID!" ]]

    run terminate_controller "${STACK_NAME}"
    echo $output >&2
}

@test "HDC controller should be created successfully with [$PRODUCT_TELEMETRY_OPT] Telemetry and [$TEST_SMARTSENSE_ID] SmartSense ID" {
    if [[ $(get_releasetype) != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    STACK_NAME=$(set_stack_name)

    run create_ss_controller "${PRODUCT_TELEMETRY_OPT}" "${TEST_SMARTSENSE_ID}"
    echo $output >&2

    run terminate_controller "${STACK_NAME}"
    echo $output >&2
}

@test "HDC controller should be created successfully with [$PRODUCT_TELEMETRY_OPT] Telemetry and No SmartSense ID" {
    if [[ $(get_releasetype) != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    STACK_NAME=$(set_stack_name)

    run create_ss_controller "${PRODUCT_TELEMETRY_OPT}"
    echo $output >&2

    run terminate_controller "${STACK_NAME}"
    echo $output >&2
}

@test "HDC controller should be created successfully with No Telemetry and No SmartSense ID" {
    if [[ $(get_releasetype) != "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi

    STACK_NAME=$(set_stack_name)

    run create_ss_controller "${PRODUCT_TELEMETRY_NO}"
    echo $output >&2

    run terminate_controller "${STACK_NAME}"
    echo $output >&2
}

@test "checking release type for SmartSense and FLEX" {
    if [[ $(get_releasetype) == "GA" ]]; then
        echo "SmartSense parameter and so FLEX is only available for GA releases currently"
        skip "SmartSense parameter and so FLEX is only available for GA releases currently"
    fi
}