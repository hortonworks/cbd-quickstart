
#!/bin/bash

set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${DEBUG:=1}
: ${DEPLOYER_LOCATION:="/var/lib/cloudbreak-deployment"}
: ${CBD_VERSION:=1.16.5}
: ${OS_USER:=cloudbreak}
: ${PUBLIC_IP:=192.168.99.100}

if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

trap '_trap_error $? $LINENO $BASH_LINENO "$BASH_COMMAND"' EXIT

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

permissive_iptables() {
  # need to install iptables-services, othervise the 'iptables save' command will not be available
  yum -y install iptables-services net-tools

  iptables --flush INPUT
  iptables --flush FORWARD
  service iptables save
}

modify_waagent() {
  if [ -f /etc/waagent.conf ]; then
    cp /etc/waagent.conf /etc/waagent.conf.bak
    sed -i 's/Provisioning.SshHostKeyPairType.*/Provisioning.SshHostKeyPairType=ecdsa/' /etc/waagent.conf
    sed -i 's/Provisioning.DecodeCustomData.*/Provisioning.DecodeCustomData=y/' /etc/waagent.conf
    sed -i 's/Provisioning.ExecuteCustomData.*/Provisioning.ExecuteCustomData=y/' /etc/waagent.conf
    diff /etc/waagent.conf /etc/waagent.conf.bak || :
  fi
}

disable_selinux() {
  setenforce 0
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
}

enable_ipforward() {
  sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
}

install_utils() {
  yum -y install unzip curl git wget bind-utils ntp tmux bash-completion
  curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq
}

install_docker() {
  curl -fsSL https://get.docker.com/ | sh
  sudo systemctl start docker
  sudo systemctl start docker
  sudo systemctl enable docker

  getent passwd $OS_USER || adduser $OS_USER
  getent passwd ec2-user && usermod -a -G docker ec2-user
  usermod -aG docker $OS_USER
}

configure_console() {
  export GRUB_CONFIG='/etc/default/grub'
  if [ -f "$GRUB_CONFIG" ] && grep "GRUB_CMDLINE_LINUX" "$GRUB_CONFIG" | grep -q "console=tty0"; then
    # we want ttyS0 as the default console output, the default RedHat AMI on AWS sets tty0 as well
    sed -i -e '/GRUB_CMDLINE_LINUX/ s/ console=tty0//g' "$GRUB_CONFIG"
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi
}

start_cloudbreak() {
  declare desc="initialize and start Cloudbreak"
  debug $desc
  mkdir -p $DEPLOYER_LOCATION
  cd $DEPLOYER_LOCATION

  echo "export CB_INSTANCE_UUID=$(uuidgen)" >> Profile
  echo "export UAA_DEFAULT_USER_PW=$(uuidgen)" >> Profile
  curl -Ls s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/cloudbreak/cloudbreak-deployer_${CBD_VERSION}_$(uname)_x86_64.tgz | tar -xz -C /bin cbd
  cbd generate
  cbd util cleanup || true
  cbd pull-parallel

  debug "starting Cloudbreak."
  cbd regenerate
  cbd_start_wait
  debug "cloudbreak started."
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

wait_for_docker() {
  declare desc="wait for docker ..."
  debug $desc

  while ! (docker info &>/dev/null); do echo -n .; sleep 1; done
}

main() {
    modify_waagent
    disable_selinux
    permissive_iptables
    enable_ipforward
    install_utils
    install_docker
    configure_console
    start_cloudbreak
    sync
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"