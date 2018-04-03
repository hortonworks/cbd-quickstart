#!/bin/bash

TEST_DIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
TEMP_DIR=$TEST_DIR/tmp
DEPLOYER_LOCATION=$TEMP_DIR
AWS_BIN_LOCATION=$TEST_DIR

rm -rf $TEMP_DIR && mkdir -p -m a-rwx,u+wrx $TEMP_DIR

docker() {
    echo $@
}
cbd() {
    echo $@ >> $TEMP_DIR/output.log
}
curl() {
    echo $@
}
sleep() {
    echo @@
}

. $TEST_DIR/../start-cbd.sh

instancetypes=$(grep -o "[s|,]" <<<"$EPHEMERALS" | wc -l)
if [[ $instancetypes -ne 22 ]]; then
    echo "Instance count not match: $instancetypes"
    exit 1
fi
for i in {1..22}
do
   instancetype=$(echo $EPHEMERALS | cut -d"," -f $i)
   if [[ ! "$instancetype" =~ ^(.*):[0-9]{1,2}x[0-9]+$ ]]; then
       echo "Volume type not valid: $instancetype"
       exit 1
   fi
done

volumeparam=$(get-volume-params d2.xlarge)
if [[ $volumeparam != "3x2000" ]]; then
    echo "Volume param not match"
    exit 1
fi
diskcount=$(get-volume-count d2.xlarge)
if [[ $diskcount -ne 3 ]]; then
    echo "Disk count must be '3'"
    exit 1
fi
diskcount=$(get-volume-count m4.xlarge)
if [[ $diskcount -ne 2 ]]; then
    echo "Disk count must be '2'"
    exit 1
fi

disksize=$(get-volume-size d2.xlarge)
if [[ $disksize -ne 2000 ]]; then
    echo "Disk size must be '2000'"
    exit 1
fi
disksize=$(get-volume-size m4.xlarge)
if [[ $disksize -ne 100 ]]; then
    echo "Disk size must be '100'"
    exit 1
fi

disktype=$(get-volume-type d2.xlarge)
if [[ "$disktype" != "ephemeral" ]]; then
    echo "Disk type must be 'ephemeral'"
    exit 1
fi
disktype=$(get-volume-type m4.xlarge)
if [[ "$disktype" != "gp2" ]]; then
    echo "Disk type must be 'gp2'"
    exit 1
fi

cbd-start-wait
if [[ $TRIES_LEFT -ne 0 ]];then
    echo "Tried to call cbd-start-wait not ten times"
    exit 1
fi

CLUSTER_NAME=12345678901234567890123456789012345678901234567890
trim_cluster_name
length=$(echo -n $CLUSTER_NAME | wc -m)
if [[ length -ne 40 ]]; then
    echo "Length of cluster name must be 40"
    exit 1
fi

TERMS_OF_USE="I Have Read and Agree to Terms of Use"
check_terms_of_use

CREDENTIAL_ROLE_ARN=roleArn
KEYPAIR_NAME=keyPairName
USERNAME=userName
ADMIN_PASSWORD=adminPassword
CLOUDBREAK_ID=cloudbreakId
CBD_VERSION=cbdVersion
VPC_ID=vpcId
IGW_ID=igwId
REGION=region
CLUSTER_WAIT_HANDLE_URL=clusterWaitHandlerUrl
BUILD_CLUSTER=false

PRODUCT_TELEMETRY=productTelemetry
start_cloudbreak
smartsense=$(grep "export CB_SMARTSENSE_CONFIGURE=false" $TEMP_DIR/Profile)
if [[ -z $smartsense ]]; then
    echo "CB_SMARTSENSE_CONFIGURE must be false"
    exit 1
fi

PRODUCT_TELEMETRY="I Have Read and Opt In to SmartSense Telemetry"
start_cloudbreak
smartsense=$(grep "export CB_SMARTSENSE_CONFIGURE=true" $TEMP_DIR/Profile)
if [[ -z $smartsense ]]; then
    echo "CB_SMARTSENSE_CONFIGURE must be true"
    exit 1
fi

BUILD_CLUSTER=true
CLUSTER_SIZE=4
MASTER_INSTANCE_TYPE=masterInstanceType
INSTANCE_TYPE=instanceType
HDP_TYPE="HDP 2.4: Apache Hive 1.2.1, Apache Spark 1.6"
CLUSTER_NAME=clusterName
S3_ROLE=s3Role
REMOTE_LOCATION=remoteLocation
STACK_NAME_WAIT_HANDLE_URL=stackWaitHandlerUrl

start_cluster