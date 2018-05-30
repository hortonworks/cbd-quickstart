#!/bin/bash

: ${LOG_LOCATION:="/var/log/cbd-quick-start.log"}

if [[ "$0" == "$BASH_SOURCE" ]]; then
    exec > >(tee $LOG_LOCATION | logger -t user-data -s 2>/dev/console) 2>&1
    
    set -o allexport
    set -o errexit
    set -o errtrace
    # set -o nounset
    set -o noclobber
fi

: ${TRACE:=""}
: ${DEBUG:=1}
: ${OS_USER:="cloudbreak"}
: ${CBD_DIR:="/var/lib/cloudbreak-deployment"}
: ${AWS_BIN_LOCATION:="/opt/aws/bin"}
: ${UPLOAD_LOGS:="NO"}
: ${INSTANCE_LOGICAL_NAME:=Cloudbreak}
: ${SECURITY_GROUP_NAME:=CloudbreakSecurityGroup}

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

    if [[  -d "${AWS_BIN_LOCATION}" ]]; then
        if [ $err -eq 0 ]; then
            debug "installation success"
            $AWS_BIN_LOCATION/cfn-signal -s true -e 0 \
                --id "CloudURL" \
                --data "https://$(get_aws_public_address)" \
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
    fi
}

init() {
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    yum clean all
    yum install -y epel-release
    yum install -y unzip docker bash-completion-extras iptables-services net-tools jq
    if yum list installed "firewalld" >/dev/null 2>&1; then
        systemctl stop firewalld
        systemctl disable firewalld
    fi
    iptables --flush INPUT && \
    iptables --flush FORWARD && \
    service iptables save
    sed -i 's/--selinux-enabled//g' /etc/sysconfig/docker
    sed -i 's/--log-driver=journald//g' /etc/sysconfig/docker
    chkconfig docker on
    getent passwd $OS_USER || adduser $OS_USER
    groupadd docker
    usermod -a -G docker $OS_USER
    service docker restart
}

custom_data() {
    source /tmp/.cbdprofile
    rm /tmp/.cbdprofile
}

get_aws_stack_name() {
    debug "retrive stack name"
    curl -s 169.254.169.254/latest/meta-data/security-groups/|sed "s/-${SECURITY_GROUP_NAME}.*//"
}

get_aws_region() {
    debug "retrive region"
    zone=$(curl -s 169.254.169.254/latest/meta-data/placement/availability-zone)
    echo ${zone:0:-1}
}

get_aws_cloudbreak_password() {
    debug "retrive Cloudbreak password"
    local stack_name=$(get_aws_stack_name)
    local region=$(get_aws_region)
    local meta_json=$(aws --region $region cloudformation describe-stack-resource --stack-name $stack_name --logical-resource-id $INSTANCE_LOGICAL_NAME 2>/dev/null | jq .StackResourceDetail.Metadata -r 2>/dev/null)
    echo $meta_json | jq -r ".cloudbreak.password" 2>/dev/null
}

get_aws_public_address() {
    debug "retrive publlic ip"
    public_ip=$(curl -4fs 169.254.169.254/latest/meta-data/public-hostname)
    if [[ -z "$public_ip" ]]; then
        public_ip=$(curl -4fs 169.254.169.254/latest/meta-data/public-ipv4)
    fi
    echo $public_ip
}

get_aws_metadata_profile() {
    debug "retrieving metadata"

    stack_name=$(get_aws_stack_name)
    region=$(get_aws_region)
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

    debug "source metadata to Profile be able to generated"
    source /tmp/.metadata-profile
    source /tmp/.metadata-cbdprofile
}


download_cbd() {
    set -x
    curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION}_$(uname)_x86_64.tgz | tar -xz -C /bin cbd
    mkdir $CBD_DIR
    cd $_
}

download_cb_cli() {
    curl -Ls https://s3-us-west-2.amazonaws.com/cb-cli/cb-cli_${CBD_VERSION}_$(uname)_x86_64.tgz | sudo tar -xz -C /bin cb
}

install_cbd() {
    echo "export PUBLIC_IP=$PUBLIC_IP" > Profile
    if [[ -n "$CB_TRAEFIK_HOST_ADDRESS" ]]; then
        echo "export CB_TRAEFIK_HOST_ADDRESS=$CB_TRAEFIK_HOST_ADDRESS" >> Profile
        echo "export DEFAULT_INBOUND_ACCESS_IP=$CB_TRAEFIK_HOST_ADDRESS" >> Profile
    fi
    if [[ -n "$AZURE_TENANT_ID" ]]; then
        echo "export AZURE_TENANT_ID=$AZURE_TENANT_ID" >> Profile
    fi
    if [[ -n "$AZURE_SUBSCRIPTION_ID" ]]; then
        echo "export AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID" >> Profile
    fi
    if [[ -n "$ULU_DEFAULT_SSH_KEY" ]]; then
        echo "export ULU_DEFAULT_SSH_KEY='$ULU_DEFAULT_SSH_KEY'" >> Profile
    fi
    echo "export UAA_DEFAULT_USER_EMAIL=$UAA_DEFAULT_USER_EMAIL" >> Profile
    echo "export UAA_DEFAULT_USER_PW=''" >> Profile
    echo "export UAA_DEFAULT_SECRET=$UAA_DEFAULT_SECRET" >> Profile
    echo "export CB_INSTANCE_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')" >> Profile
    echo "export CB_HOST_ADDRESS=http://localhost:8080" >> Profile
    echo "export ULU_SUBSCRIBE_TO_NOTIFICATIONS=false" >> Profile
    echo "export CB_DEFAULT_SUBSCRIPTION_ADDRESS=http://uluwatu.service.consul:3000/notifications" >> Profile

    debug "Starting Cloudbreak.."
    debug $(date +"%T")
    cbd generate
    cbd pull-parallel
    cbd_start_wait
    debug "Cloudbreak has been started."
    debug $(date +"%T")

    debug "Creating default user.."
    cp Profile Profile.tmp

    if [[ -d "${AWS_BIN_LOCATION}" ]]; then
        UAA_DEFAULT_USER_PW=$(get_aws_cloudbreak_password)
    fi

    echo "export UAA_DEFAULT_USER_PW='$(escape-string $UAA_DEFAULT_USER_PW \')'" >> Profile.tmp
    CBD_DEFAULT_PROFILE=tmp cbd util add-default-user
    rm -f Profile.tmp
    debug "Default user created.."

}

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
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

cbd_start_wait() {
    declare desc="waiting for Cloudbreak"
    debug $desc

    for t in $(seq 1 1 ${RETRY_START_COUNT:=5}); do
        debug "tries: $t"
        cbd start-wait && break
        service docker restart
        wait_for_docker
        cbd kill
        sleep ${RETRY_START_SLEEP:=5}
        if [[ t -eq ${RETRY_START_COUNT} ]]; then
          debug "Exiting due to exceeded retries.."
          exit 1
        fi
    done
}

wait_for_docker() {
  declare desc="wait for docker ..."
  debug $desc

  while ! (docker info &>/dev/null); do echo -n .; sleep 1; done
}

set_perm() {
    chown -R $OS_USER:$OS_USER $CBD_DIR
    whoami
}

aws_prepare_os_user() {
    mkdir -p /home/$OS_USER/.ssh
    cp /home/ec2-user/.ssh/authorized_keys /home/$OS_USER/.ssh/
    chown -R $OS_USER:$OS_USER /home/$OS_USER/.ssh
    service sshd reload
    echo "# This is generated by the Cloudbreak deployment's cloud-init script" >> /etc/sudoers.d/cloudbreak
    echo "cloudbreak ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/cloudbreak
}

main() {
    init

    if [[ -d "${AWS_BIN_LOCATION}" ]]; then
        get_aws_metadata_profile
        aws_prepare_os_user
        : ${WAIT_HANDLE_URL:? required}
    else
        custom_data
    fi

    download_cbd
    download_cb_cli
    set_perm
    su $OS_USER -c "install_cbd"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true
