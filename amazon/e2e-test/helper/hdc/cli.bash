HDC_COMMON_ARGS_WO_CLUSTER=" --server ${CLOUD_URL} --username ${EMAIL} --password ${PASSWORD} "
HDC_COMMON_ARGS=" --cluster-name ${CLUSTER_NAME} --server ${CLOUD_URL} --username ${EMAIL} --password ${PASSWORD} "
HDC_BIN="./hdc"

function describe-cluster() {
    $HDC_BIN describe-cluster "$@" $HDC_COMMON_ARGS
}

function describe-cluster-instances() {
    describe-cluster "instances" "$@" $HDC_COMMON_ARGS
}

function describe-smartsensesubscription() {
    $HDC_BIN describe-smartsensesubscription "$@" $HDC_COMMON_ARGS_WO_CLUSTER --output json | jq -r '.SubscriptionID'
}

function list-clusters() {
    $HDC_BIN list-clusters "$@" $HDC_COMMON_ARGS_WO_CLUSTER
}

function list-cluster-types() {
    $HDC_BIN list-cluster-types "$@" $HDC_COMMON_ARGS_WO_CLUSTER
}

function list-flexsubscriptions() {
    $HDC_BIN list-flexsubscriptions "$@" $HDC_COMMON_ARGS_WO_CLUSTER | jq -r '.[].'$1
}

function resize() {
    $HDC_BIN resize-cluster "$@" $HDC_COMMON_ARGS
}

function set-default-flexsubscription() {
    $HDC_BIN set-default-flexsubscription "$@" $HDC_COMMON_ARGS_WO_CLUSTER --subscription-name $1
}

function use-flexsubscription-for-controller() {
    $HDC_BIN use-flexsubscription-for-controller "$@" $HDC_COMMON_ARGS_WO_CLUSTER --subscription-name $1
}

function jq-cluster-instances-all-healthy-and-registered() {
  jq -r '[([.[].HostStatus=="HEALTHY" ] | all ) , ([.[].InstanceStatus=="REGISTERED" ] | all ) ] | all' $1
}

# $1 : expected status { AVAILABLE | UPDATE_IN_PROGRESS | .. }
function jq-list-cluster-in-status() {
  jq -r ".[] | select(.ClusterName==\"${CLUSTER_NAME}\") | .Status==\"${1}\""
}

# $1 : instance type { worker | compute }
function aws-select-and-kill-instance-which-is-a() {
  instance_id=$(jq -r ' [ .[] | select(.Type=="'$1'") | .InstanceId ][0] ' $BTS_TEMPFILE)
  aws --region $REGION ec2 terminate-instances --instance-ids $instance_id
}

function create-cluster() {
    $HDC_BIN create-cluster $@ $HDC_COMMON_ARGS_WO_CLUSTER --wait 1
}

function list-cluster-types() {
    $HDC_BIN list-cluster-types $@ $HDC_COMMON_ARGS_WO_CLUSTER 
}  

function terminate-cluster() {
    $HDC_BIN terminate-cluster $HDC_COMMON_ARGS $@
    #rm $CLUSTER_NAME".clusterdescriptor.bash"
}

function delete-flexsubscription() {
    $HDC_BIN delete-flexsubscription "$@" $HDC_COMMON_ARGS_WO_CLUSTER --subscription-name $1
}

function register-metastore() {
    $HDC_BIN register-metastore "$@" $HDC_COMMON_ARGS_WO_CLUSTER
}

function register-ldap() {
    $HDC_BIN register-ldap "$@" $HDC_COMMON_ARGS_WO_CLUSTER
}

function register-flexsubscription() {
    $HDC_BIN register-flexsubscription "$@" $HDC_COMMON_ARGS_WO_CLUSTER --subscription-name $1 --subscription-id $2
}

function validate-cli-skeleton() {
    $HDC_BIN create-cluster validate-cli-skeleton "$@" $HDC_COMMON_ARGS_WO_CLUSTER
}