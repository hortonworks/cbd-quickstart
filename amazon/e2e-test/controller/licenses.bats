#!/usr/bin/env bats

load ../$STACK_NAME".stackdescriptor"

if [[ $RELEASE_TYPE == "TP" ]]
then
 release_file="technical-preview"
hortonworks_license_date="2016-06-01"
notices_license_date="2017-01-18"
else
release_file="marketplace"
hortonworks_license_date="2017-03-20" 
notices_license_date="2017-01"
fi

license_path="/etc/hortonworks/"
EULA="${license_path}hdcloud-aws-eula-${release_file}-${hortonworks_license_date}.pdf"
SMARTSENSE="${license_path}hdcloud-aws-smartsense-${release_file}-${hortonworks_license_date}.pdf"
NOTICES="${license_path}hdcloud-aws-third-party-notices-${release_file}-${notices_license_date}.pdf"
JDKLICENSE="/usr/lib/jvm/java/OpenJDK_GPLv2_and_Classpath_Exception.pdf"

function file_checker() {
ssh -o StrictHostKeyChecking=no -i ${SSH_PRIV_KEY} cloudbreak@${CB_PUBLIC_IP} "[[ -e $1 ]]" 
}

function remoterun() {
ssh -o StrictHostKeyChecking=no -i ${SSH_PRIV_KEY} cloudbreak@${CB_PUBLIC_IP} " $1 " 
}

function assertbasic() {
  echo $1
  $2
} >&2

TAGS="$STACK_NAME functional"

@test "assert basic" {
    assertbasic "szoveg" "[ a == a ]"
}

function testup() {
    echo Expected : ${1} >&2
    echo Actual : >&2
    remoterun "ls -1 ${2} " >&2
    run remoterun "[[ -e ${1} ]]" 
    [[ $status -eq 0 ]]
}

@test "Verify the HDCloud $RELEASE_TYPE AWS EULA file exists [$TAGS]" {
    testup $EULA $license_path
#    echo Expected : ${EULA} >&2
#    echo Actual : >&2
#    remoterun "ls -1 ${license_path} " >&2
#    run remoterun "[[ -e ${EULA} ]]" 
#    [[ $status -eq 0 ]]
}

@test "Verify the Smartsense $RELEASE_TYPE license file exists [$TAGS]" {
    echo Expected : ${SMARTSENSE} >&2
    echo Actual : >&2
    remoterun "ls -1 ${license_path} " >&2
    run remoterun "[[ -e ${SMARTSENSE} ]]" 
    [[ $status -eq 0 ]]
}

@test "Verify the HDCloud $RELEASE_TYPE AWS Third Party Notices file exists [$TAGS]" {
    echo Expected : ${NOTICES} >&2
    echo Actual : >&2
    remoterun "ls -1 ${license_path} " >&2
    run remoterun "[[ -e ${NOTICES} ]]" 
    [[ $status -eq 0 ]]
}

@test "Verify the OpenJDK GPL license file exists [$TAGS]" {
    echo Expected : ${JDKLICENSE} >&2
    echo Actual : >&2
    remoterun "ls -1 ${license_path} " >&2
    run remoterun "[[ -e ${JDKLICENSE} ]]" 
    [[ $status -eq 0 ]]
}
