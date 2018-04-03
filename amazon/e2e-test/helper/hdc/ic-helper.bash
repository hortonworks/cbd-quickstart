: ${URL_IMAGECATALOG:="https://s3-eu-west-1.amazonaws.com/cloudbreak-info/cb-image-catalog.json"}

function assert() {
  if !  "$@"
  then
    echo $@ >&2
    exit 1
  fi
}

#$1 hdp version ( "HDP-2.6" )
#$2 ambari version ("2.5.0.0-1094" )
#$3 hdp repo version ("2.6.0.0-598" )
function jq_check_ic_versions() {
  jq ".cloudbreak[].ambari | select( .cb_versions[]==\"${RELEASE_TYPE}\" ) | select( .hdp[].repo.stack.repoid == \"$1\" ) | [ .version == \"$2\" , .hdp[].version ==  \"$3\" ] | all"
}

function get_imagecatalog() {
  curl -s ${URL_IMAGECATALOG} 
}
