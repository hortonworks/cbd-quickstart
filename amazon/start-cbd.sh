#!/bin/bash

: ${TRACE:=""}
: ${DEBUG:=1}
: ${DEPLOYER_LOCATION:="/var/lib/cloudbreak-deployment"}
: ${AWS_BIN_LOCATION:="/opt/aws/bin"}
: ${LOG_LOCATION:="/var/log/cbd-quick-start.log"}
: ${UPLOAD_LOGS:="NO"}
: ${PSQL_IMAGE:=postgres:9.4.1}

: ${INSTANCE_LOGICAL_NAME:=Cloudbreak}
: ${SECURITY_GROUP_NAME:=CloudbreakSecurityGroup}

if [[ "$0" == "$BASH_SOURCE" ]]; then
    exec > >(tee $LOG_LOCATION | logger -t user-data -s 2>/dev/console) 2>&1
    
    set -o errexit
    set -o errtrace
    set -o nounset
    set -o noclobber
fi

if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

trap '_trap_error $? $LINENO $BASH_LINENO "$BASH_COMMAND"' EXIT

SIGNAL_REASON=""
_trap_error () {
    local err="${1:-}" line="${2:-}" _="${3:-}" badcommand="${4:-}"

    rm -f /tmp/.metadata-profile
    rm -f /tmp/.metadata-cbdprofile

    if [ $err -eq 0 ];then
        debug "installation success"
        $AWS_BIN_LOCATION/cfn-signal -s true -e 0 \
            --id "CloudURL" \
            --data "https://$(get_public_address)" \
            "${WAIT_HANDLE_URL}" || true
    else
        if ! [[ "${SIGNAL_REASON}" ]]; then
            SIGNAL_REASON="ERROR: command '${badcommand}' exited with status: ${err} line: ${line}"
        fi

        debug "installation failed: $SIGNAL_REASON"
        $AWS_BIN_LOCATION/cfn-signal \
            -s false \
            -e "${err}" \
            --id "cbd-init" \
            --reason "${SIGNAL_REASON}" \
            "${WAIT_HANDLE_URL}" || true
    fi

    if [[ "$UPLOAD_LOGS" == "YES" ]]; then
        save_log_files
    fi
}

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

save_log_files() {
    declare desc="saving log files"
    debug $desc

    : ${STACK_NAME:? required}
    : ${AWS_DEFAULT_REGION:? required}

    name="${STACK_NAME}-$(date +%s)"

    debug "creating bucket named: $name"

    set +e
    aws s3api create-bucket --bucket $name --create-bucket-configuration LocationConstraint=$AWS_DEFAULT_REGION
    aws s3 cp /var/log/ s3://$name --recursive --exclude '*'  --include 'cbd*' --include 'docker*' --include 'cfn-*' --include 'cloud*' --region $AWS_DEFAULT_REGION
    set -e
}

colorless() {
  sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | tr -d '\015'
}

wait_for_docker() {
  declare desc="wait for docker ..."
  debug $desc

  while ! (docker info &>/dev/null); do echo -n .; sleep 1; done
}

start_cloudbreak() {
    declare desc="initialize and start Cloudbreak"
    debug $desc

    cd $DEPLOYER_LOCATION

    echo "export CB_INSTANCE_UUID=$(uuidgen)" >> Profile
    echo "export CB_INSTANCE_PROVIDER=aws" >> Profile
    echo "export CB_INSTANCE_REGION=${AWS_DEFAULT_REGION}" >> Profile
    echo "export CB_SMARTSENSE_CLUSTER_NAME_PREFIX=hdcu" >> Profile
    echo "export CB_PRODUCT_ID=HDCLOUD-AWS" >> Profile
    echo "export CB_COMPONENT_ID=HDCLOUD-AWS-CONTROLLER" >> Profile
    echo "export CB_COMPONENT_CLUSTER_ID=HDCLOUD-AWS-HDP" >> Profile
    if ! [ "$CB_SMARTSENSE_ID" ] && [ "$CB_SMARTSENSE_CONFIGURE" == "true" ]; then
      CB_SMARTSENSE_ID="A-9990${AWS_ACCOUNT_ID:0:4}-C-${AWS_ACCOUNT_ID:4}"
    fi
    echo "export CB_SMARTSENSE_ID=${CB_SMARTSENSE_ID}" >> Profile

    if [[ "$GA" == true ]]; then
      echo "export HWX_DOC_LINK=http://docs.hortonworks.com/HDPDocuments/HDCloudAWS/HDCloudAWS-${CBD_VERSION%-*}/bk_hdcloud-aws/content/" >> Profile
    else
      echo "export HWX_DOC_LINK=https://hortonworks.github.io/hdp-aws/" >> Profile
    fi

    echo "export DEFAULT_INBOUND_ACCESS_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)" >> Profile

    CURRENT_VERSION=$(cbd --version | sed 's/Cloudbreak Deployer: //; s/-\([a-z0-9]\)\{7\}$//g')

    if [[ "$CBD_VERSION" != "$CURRENT_VERSION" ]]; then
      debug "Updating cbd to [$CBD_VERSION] from [$CURRENT_VERSION]"
      curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION}_$(uname)_x86_64.tgz | tar -xz -C /bin cbd
      cbd generate
      cbd util cleanup || true
      cbd pull-parallel
    else
      debug "cbd version is [$CURRENT_VERSION], update not needed."
    fi

    if [[ "$CBD_VERSION" != "snapshot" ]]; then
        HDC_CLI_VERSION=$(hdc --version | cut -f 3 -d " ")
        if [[ "$HDC_CLI_VERSION" =~ "$CBD_VERSION" ]]; then
            debug "hdc cli version is: $HDC_CLI_VERSION, update not needed"
        else
            debug "update hdc cli to version: $CBD_VERSION, old version: $HDC_CLI_VERSION"
            rm -f /var/lib/cloudbreak/hdc-cli/*
            for OS in "Darwin" "Linux" "Windows"; do
                curl -Lo "/var/lib/cloudbreak/hdc-cli/hdc-cli_${OS}_x86_64.tgz" "https://s3-eu-west-1.amazonaws.com/hdc-cli/hdc-cli_${CBD_VERSION}_${OS}_x86_64.tgz"
                cp "/var/lib/cloudbreak/hdc-cli/hdc-cli_${OS}_x86_64.tgz" "/var/lib/cloudbreak/hdc-cli/hdc-cli_${CBD_VERSION}_${OS}_x86_64.tgz"
            done
            tar -zxvf /var/lib/cloudbreak/hdc-cli/hdc-cli_Linux_x86_64.tgz
            mv -f hdc $(which hdc)
        fi
    fi

    debug "starting Cloudbreak."
    cbd regenerate
    cbd_start_wait
    debug "cloudbreak started."

    passwd=$(get_cloudbreak_password)

    debug "creating default user"
    cat Profile > Profile.tmp
    echo "export UAA_DEFAULT_USER_PW='$(escape-string $passwd \')'" >> Profile.tmp
    CBD_DEFAULT_PROFILE=tmp cbd util add-default-user
    rm -f Profile.tmp

    debug "distribute HDC cli config"
    cp -R /.hdc/ /home/cloudbreak
    cp -R /.hdc/ /root

    debug "deleting credential: aws-access"
    hdc delete-credential --password $passwd --credential-name aws-access 2>/dev/null || debug "unable to delete credential"
    debug "delete network: aws-network"
    hdc delete-network --password $passwd --network-name aws-network 2>/dev/null || debug "network not found"

    debug "creating credential aws-access for $KEYPAIR_NAME"
    hdc create-credential --password $passwd --credential-name aws-access --role-arn $CREDENTIAL_ROLE_ARN --ssh-key-url http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key --existing-ssh-key-pair $KEYPAIR_NAME

    debug "create network: aws-network"
    if [[ "$EXISTING_VPC" ]]; then
        hdc create-network-existing --password $passwd --network-name aws-network --vpc $VPC_ID --subnet $SUBNET_ID
    else
        hdc create-network --password $passwd --network-name aws-network --subnet-cidr 10.0.254.0/24 --vpc $VPC_ID --igw $IGW_ID
    fi
}

cbd_start_wait() {
    declare desc="waiting for Cloudbreak"
    debug $desc

    for t in $(seq 1 1 ${RETRY_START_COUNT:=10}); do
        debug "tries: $t"
        cbd start-wait && break
        service docker restart
        wait_for_docker
        cbd kill
        sleep ${RETRY_START_SLEEP:=5}
    done
}

create_cbd_per_boot_script() {
    declare desc="creating cbd per boot script"
    debug $desc

    rm -f /var/lib/cloud/scripts/per-boot/cbd-per-boot.sh
    cat > /var/lib/cloud/scripts/per-boot/cbd-per-boot.sh << ENDOF
#!/bin/bash
cd /var/lib/cloudbreak-deployment
echo "Restart cbd (kill-regenerate-start) to configure the new public domain name."
cbd restart
ENDOF

    chmod +x /var/lib/cloud/scripts/per-boot/cbd-per-boot.sh
}

escape-string() {
    declare desc="escape bash string by delimiter type"
    : ${2:=required}
    local in=$1
    local delimiter=$2

    if [[ $delimiter == "'" ]]; then
        out=`echo $in | sed -e "s/'/'\\\\\\''/g"`
    elif [[ $delimiter == '"' ]]; then
        out=`echo $in | sed -e 's/\\\\/\\\\\\\/g' -e 's/"/\\\"/g' -e 's/[$]/\$/g' -e "s/\\\`/\\\\\\\\\\\\\\\`/g" -e 's/!/\\\\!/g'`
    else
        out="$in"
    fi

    echo $out
}

get_stack_name() {
    declare desc="retrive stack name"

    curl -s 169.254.169.254/latest/meta-data/security-groups/|sed "s/-${SECURITY_GROUP_NAME}.*//"
}

get_region() {
    declare desc="retrive region"

    zone=$(curl -s 169.254.169.254/latest/meta-data/placement/availability-zone)
    echo ${zone:0:-1}
}

get_cloudbreak_password() {
    declare desc="retrive Cloudbreak password"

    local stack_name=$(get_stack_name)
    local region=$(get_region)
    local meta_json=$(aws --region $region cloudformation describe-stack-resource --stack-name $stack_name --logical-resource-id $INSTANCE_LOGICAL_NAME 2>/dev/null | jq .StackResourceDetail.Metadata -r 2>/dev/null)
    echo $meta_json | jq -r ".cloudbreak.password" 2>/dev/null
}

get_public_address() {
    declare desc="retrive publlic ip"

    public_ip=$(curl -4fs 169.254.169.254/latest/meta-data/public-hostname)
    if [[ -z "$public_ip" ]]; then
        public_ip=$(curl -4fs 169.254.169.254/latest/meta-data/public-ipv4)
    fi
    echo $public_ip
}

get_metadata_profile() {
    declare desc="retrieving metadata"
    debug $desc

    stack_name=$(get_stack_name)
    debug "retrieving region"
    region=$(get_region)
    export AWS_DEFAULT_REGION=${region}

    debug "get profile attribute from cfn metadata of logical resource: $INSTANCE_LOGICAL_NAME"
    metadata=$(aws cloudformation describe-stack-resource \
        --stack-name $stack_name \
        --logical-resource-id $INSTANCE_LOGICAL_NAME \
        --query 'StackResourceDetail.Metadata' --out text)

    echo $metadata | jq '.profile' -r >> /tmp/.metadata-profile
    echo $metadata | jq '.cbdprofile' -r >> /tmp/.metadata-cbdprofile

    public_ip=$(curl -4fs 169.254.169.254/latest/meta-data/public-hostname)
    debug "public ip is: $public_ip"
    if [[ -n "$public_ip" ]]; then
        debug "using hostname"
        echo 'export PUBLIC_IP=$(curl -4fs 169.254.169.254/latest/meta-data/public-hostname)' >> /tmp/.metadata-cbdprofile
    else
        debug "using ip"
        echo 'export PUBLIC_IP=$(curl -4fs 169.254.169.254/latest/meta-data/public-ipv4)' >> /tmp/.metadata-cbdprofile
    fi
    echo "export CB_HOST_ADDRESS=http://localhost:8080" >> /tmp/.metadata-cbdprofile

    . /tmp/.metadata-profile

    if [[ "$EXISTING_VPC" ]]; then
        debug "using existing VPC: $EXISTING_VPC"
        IGW_ID=$(aws ec2 describe-internet-gateways --filter "Name=attachment.vpc-id,Values=$VPC_ID" | jq '.InternetGateways[].InternetGatewayId' -r)
        if [[ "$IGW_ID" ]]; then
            debug "described internet gateway: $IGW_ID"
            echo "export IGW_ID='$IGW_ID'" >> /tmp/.metadata-profile
            echo "export ULU_HWX_CLOUD_DEFAULT_IGW_ID='$IGW_ID'" >> /tmp/.metadata-cbdprofile
        fi
    fi

    . /tmp/.metadata-profile

    debug "fill Profile"
    cd $DEPLOYER_LOCATION
    rm -f Profile
    cat /tmp/.metadata-cbdprofile > Profile
}

restore_motd() {
    declare desc="restoring motd"
    debug $desc

    /usr/sbin/update-motd --enable
    /usr/sbin/update-motd --force
}

check_single_db_connectivity() {
    declare desc="checking RDS for database connectivity"
    declare host=${1:?required} port=${2:?required} user=${3:?required} password=${4:?required} dbname=${5:?required}
    debug $desc

    set +e
    result=$(\
        docker run --rm \
            -e PGPASSWORD="${password}" \
            --entrypoint psql \
            ${PSQL_IMAGE} \
              -h ${host} \
              -p ${port} \
              -U ${user} \
              ${dbname} -c 'select 1' \
        2>&1 \
    )
    exitcode=$?
    set -e
    if [ $exitcode -ne 0 ];then
      SIGNAL_REASON="RDS connectivity issue: $result"
      exit $exitcode
    fi
}

check_rds() {
    declare desc="check RDS"
    debug $desc

    cd $DEPLOYER_LOCATION
    set +x
    . Profile
    if [[ "$TRACE" ]]; then
        set -x
    fi
    if [[ "$RDS_URL" ]]; then
        debug "using RDS: $RDS_URL"
        if [ $(docker images -q  ${PSQL_IMAGE} |wc -l) -eq 0 ]; then
            debug "pulling image: $PSQL_IMAGE"
            docker pull ${PSQL_IMAGE}
        fi

        debug "checking RDS connectivity"
        check_single_db_connectivity "${CB_DB_PORT_5432_TCP_ADDR}" "${CB_DB_PORT_5432_TCP_PORT}" "${CB_DB_ENV_USER}" "${CB_DB_ENV_PASS}" "${CB_DB_ENV_DB}"
    fi
}

update_credentials() {
    declare desc="updating existing credentials in the database with the new role"
    debug $desc

    if [[ "$RDS_URL" ]]; then
        name="c$(date +%s)"
        debug "creating new credential"
        passwd=$(get_cloudbreak_password)
        hdc create-credential --password $passwd --credential-name $name --role-arn $CREDENTIAL_ROLE_ARN --ssh-key-url http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key --existing-ssh-key-pair $KEYPAIR_NAME
        new_id=$(get_aws_access_cred_id $name)
        
        debug "updating stacks to new credential with id:$new_id"
        execute_sql_on_rds "UPDATE stack SET credential_id = $new_id"
    fi
}

get_aws_access_cred_id() {
    declare name=$1
    execute_sql_on_rds "SELECT id, 'cred-id' FROM credential WHERE name = '$name'" | grep -m 1 -e 'cred-id' | tr -dc '0-9'
}

execute_sql_on_rds() {
    declare sql=$1
    docker run --rm -e PGPASSWORD="${CB_DB_ENV_PASS}" --entrypoint psql ${PSQL_IMAGE} -h ${CB_DB_PORT_5432_TCP_ADDR} -p ${CB_DB_PORT_5432_TCP_PORT} -U ${CB_DB_ENV_USER} ${CB_DB_ENV_DB} -c "$sql"
}

main() {
    declare desc="main entry point"
    debug $desc

    restore_motd
    get_metadata_profile
    : ${CREDENTIAL_ROLE_ARN:? required}
    : ${KEYPAIR_NAME:? required}
    : ${BUILD_CLUSTER:? required}
    : ${CBD_VERSION:? required}
    : ${VPC_ID:? required}
    : ${EXISTING_VPC:=}
    : ${GA:? required}

    : ${WAIT_HANDLE_URL:? required}

    wait_for_docker
    check_rds
    create_cbd_per_boot_script
    start_cloudbreak
    update_credentials
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
