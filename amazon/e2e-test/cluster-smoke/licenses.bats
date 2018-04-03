#!/usr/bin/env bats

load ../$STACK_NAME".stackdescriptor"
load ../$CLUSTER_NAME".clusterdescriptor"

if [[ $RELEASE_TYPE == "TP" ]]
then
 release_file="technical-preview"
hortonworks_license_date="2016-06-01"
notices_license_date="2017-01-18"
else
release_file="marketplace"
hortonworks_license_date="2016-10-06" 
notices_license_date="2017-01"
fi

license_path="/etc/hortonworks/"
EULA="${license_path}hdcloud-aws-eula-${release_file}-${hortonworks_license_date}.pdf"
SMARTSENSE="${license_path}hdcloud-aws-smartsense-${release_file}-${hortonworks_license_date}.pdf"
NOTICES="${license_path}hdcloud-aws-third-party-notices-${release_file}-${notices_license_date}.pdf"
JDKLICENSE="/usr/lib/jvm/java/OpenJDK_GPLv2_and_Classpath_Exception.pdf"

function remoterun() {
ssh -o StrictHostKeyChecking=no -i ${SSH_PRIV_KEY} cloudbreak@${CB_PUBLIC_IP} " $1 " 
}

TAGS="$STACK_NAME $CLUSTER_NAME functional"

function testup() {
    HOST=$3
    EXPECTEDFILENAME=$1
    LICENSEPATH=$2

    echo Expected : ${EXPECTEDFILENAME} >&2
    echo Actual : >&2
    remoterun "ls -1 ${LICENSEPATH} " >&2
    run remoterun "[[ -e ${EXPECTEDFILENAME} ]]" $HOST
    #[[ $status -eq 0 ]]
    echo $status
}

@test "Verify the HDCloud $RELEASE_TYPE AWS EULA file exists [$TAGS]" {
    #testup $EULA $license_path
    aresult=0
    for HOST in $(aws ec2 describe-instances --region $REGION --filters "Name=tag-key,Values=CloudbreakClusterName" "Name=tag-value,Values=$CLUSTER_NAME*" "Name=instance-state-name,Values=running" |jq '.Reservations[].Instances[].PublicIpAddress' -r | sort -u);
    do
	echo $HOST >&2
        result=$(testup $EULA $license_path $HOST ) 
        if [[ $result -ne 0 ]] ; then aresult=1 ; fi
    done
    return $aresult
}

@test "Verify the Smartsense $RELEASE_TYPE license file exists [$TAGS]" {
  skip
}

@test "Verify the $RELEASE_TYPE AWS Third Party Notices file exists [$TAGS]" {
  skip
}

@test "Verify the OpenJDK GPL license file exists [$TAGS]" {
  skip
}
