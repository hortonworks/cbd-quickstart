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
  TOKEN=$( curl -sX POST --insecure -w '%{redirect_url}' -H "Accept: application/x-www-form-urlencoded" --data-urlencode 'credentials={"username":"'$EMAIL'","password":"'$(escape-string-json $PASSWORD)'"}' "$CLOUD_URL/identity/oauth/authorize?response_type=token&client_id=cloudbreak_shell"  | cut -d'&' -f 2)
  echo ${TOKEN#*=}
}

function authorizationheader() {
  echo Authorization: Bearer $(getoauth2token )
}

function getevents() {
  curl -k -H "$(authorizationheader )" -H "Accept: application/json" "$CLOUD_URL/cb/api/v1/events"
}

function getblueprints() {
  curl -k -H "$(authorizationheader )" -H "Accept: application/json" "$CLOUD_URL/cb/api/v1/blueprints/account"
}

function getldap() {
  curl -k -H "$(authorizationheader )" -H "Accept: application/json" "$CLOUD_URL/cb/api/v1/ldap/$1"
}

function getpublicldap() {
  curl -k -H "$(authorizationheader )" -H "Accept: application/json" "$CLOUD_URL/cb/api/v1/ldap/account/$1"
}
