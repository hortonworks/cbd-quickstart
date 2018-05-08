#!/bin/bash

set -ex

main() {
    local image_name_filter=$1
    echo "# this file is generted by: make get-latest-ami-mapping" > aws-mapping.yml
    echo "---" >> aws-mapping.yml
    for region in `aws ec2 describe-regions --output text | cut -f3`
    do
        echo "  $region:" >> aws-mapping.yml
        echo "    ami: \"$(aws ec2 --region $region describe-images --owners amazon --filters Name=name,Values="$image_name_filter" Name=architecture,Values=x86_64 Name=root-device-type,Values=ebs --query 'sort_by(Images, &Name)[-1].ImageId' --output text)\"" >> aws-mapping.yml
    done
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true