function escape-string-json() {
    declare desc="Escape json string"
    : ${1:=required}
    local in=$1
    out=`echo $in | sed -e 's/\\\\/\\\\\\\/g' -e 's/"/\\\"/g'`
    echo $out
}


function getoauth2token1() {
  curl -sX POST --insecure -w '%{redirect_url}' -H "Accept: application/x-www-form-urlencoded" --data-urlencode 'credentials={"username":"afarsang@hortonworks.com","password":"nemAdmin!"}' "https://ec2-35-157-239-138.eu-central-1.compute.amazonaws.com/identity/oauth/authorize?response_type=token&client_id=cloudbreak_shell"
}

function getoauth2token() {
  TOKEN=$( curl -sX POST --insecure -w '%{redirect_url}' -H "Accept: application/x-www-form-urlencoded" --data-urlencode 'credentials={"username":"'$2'","password":"'$(escape-string-json $3)'"}' "$1/identity/oauth/authorize?response_type=token&client_id=cloudbreak_shell"  | cut -d'&' -f 2)
  echo ${TOKEN#*=}
}

function authorizationheader() {
  echo Authorization: Bearer $(getoauth2token $1 $2 $3)
}

function getevents() {
  curl -k -H "$(authorizationheader $1 $2 $3)" -H "Accept: application/json" "$1/cb/api/v1/events"
}

function getblueprints() {
  curl -k -H "$(authorizationheader $1 $2 $3)" -H "Accept: application/json" "$1/cb/api/v1/blueprints/account"
}
