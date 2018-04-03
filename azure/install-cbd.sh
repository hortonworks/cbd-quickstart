#!/bin/bash

exec > >(tee "/var/log/${BASH_SOURCE}.log") 2>&1
set -x

: ${CBD_VERSION:="snapshot"}
: ${CBD_DIR:="/var/lib/cloudbreak-deployment"}

init() {
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    yum clean all
    yum update -y
    yum install -y epel-release
    yum install -y docker bash-completion-extras iptables-services net-tools jq
    systemctl stop firewalld
    systemctl disable firewalld
    iptables --flush INPUT && \
    iptables --flush FORWARD && \
    service iptables save
    sed -i 's/--selinux-enabled//g' /etc/sysconfig/docker
    sed -i 's/--log-driver=journald//g' /etc/sysconfig/docker
    systemctl enable docker
    getent passwd $OS_USER || adduser $OS_USER
    groupadd docker
    usermod -a -G docker $OS_USER
    service docker start
}

custom_data() {
    set -o allexport
    source /tmp/.cbdprofile
    set +o allexport
    rm /tmp/.cbdprofile
}

download_cbd() {
    set -x
    curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION}_$(uname)_x86_64.tgz | tar -xz -C /bin cbd
    mkdir $CBD_DIR
    cd $_
}

install_cbd() {

    #export TRACE=1
    export DEBUG=1
    CREDENTIAL_NAME=defaultcredential

    echo "export PUBLIC_IP=$PUBLIC_IP" > Profile
    echo "export CB_TRAEFIK_HOST_ADDRESS=$CB_TRAEFIK_HOST_ADDRESS" >> Profile
    echo "export AZURE_TENANT_ID=$AZURE_TENANT_ID" >> Profile
    echo "export AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID" >> Profile
    echo "export UAA_DEFAULT_USER_EMAIL=$UAA_DEFAULT_USER_EMAIL" >> Profile
    echo "export UAA_DEFAULT_USER_PW=''" >> Profile
    echo "export UAA_DEFAULT_SECRET=$UAA_DEFAULT_SECRET" >> Profile
    echo "export CB_SMARTSENSE_CONFIGURE=$CB_SMARTSENSE_CONFIGURE" >> Profile
    echo "export CB_ENABLEDPLATFORMS=AZURE" >> Profile
    echo "export ULU_DEFAULT_SSH_KEY='$ULU_DEFAULT_SSH_KEY'" >> Profile
    echo "export CB_INSTANCE_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')" >> Profile
    echo "export CB_HOST_ADDRESS=http://localhost:8080" >> Profile
    echo "export ULU_SUBSCRIBE_TO_NOTIFICATIONS=false" >> Profile
    echo "export CB_DEFAULT_SUBSCRIPTION_ADDRESS=http://uluwatu.service.consul:3000/notifications" >> Profile
    echo "export DEFAULT_INBOUND_ACCESS_IP=$CB_TRAEFIK_HOST_ADDRESS" >> Profile

    if [[ ! "$CB_SMARTSENSE_ID" && "$CB_SMARTSENSE_CONFIGURE" == true ]]; then
      AZURE_SUBSCRIPTION_ID_NUMBER="$((0x$(sha1sum <<<"$AZURE_SUBSCRIPTION_ID")0))"
      CB_SMARTSENSE_ID="A-9990${AZURE_SUBSCRIPTION_ID_NUMBER:1:4}-C-${AZURE_SUBSCRIPTION_ID_NUMBER:5:8}"
    fi
    echo "export CB_SMARTSENSE_ID=${CB_SMARTSENSE_ID}" >> Profile

    debug "Starting Cloudbreak.."
    debug $(date +"%T")
    cbd generate
    cbd pull-parallel
    cbd_start_wait
    debug "Cloudbreak has been started."
    debug $(date +"%T")

    debug "Creating default user.."
    cat Profile > Profile.tmp
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

main() {
    custom_data
    init
    download_cbd
    set_perm
    export -f install_cbd
    export -f debug
    export -f escape-string
    export -f cbd_start_wait
    export -f wait_for_docker
    su $OS_USER -c "install_cbd"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true
