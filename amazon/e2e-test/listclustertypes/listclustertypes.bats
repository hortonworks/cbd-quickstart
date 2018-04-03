#{ therebutnotexpected: (. - [[1,0],[2,0],[4,0],[5,0]] ) ,nottherebutexpected: ( [[1,0],[2,0],[4,0]] - . ) } | .therebutnotexpected==[] and .nottherebutexpected==[]

load ../$STACK_NAME".stackdescriptor"
load ../helper/hdc/cli

EXPECTED_BLUEPRINTS="common/blueprints.json"
TAGS="blueprints static $STACK_NAME"

@test "List cluster types - check available blueprints and hdp versions [$TAGS]" {
  EXPECTED_LIST=$( jq -r '.' $EXPECTED_BLUEPRINTS )
  CHECK_RESULT=$( list-cluster-types | jq --argjson expected "$EXPECTED_LIST" '{ therebutnotexpected: (. - $expected ) ,nottherebutexpected: ( $expected - . ) }' )
  echo $CHECK_RESULT >&2
  [ $(echo $CHECK_RESULT | jq -r '.therebutnotexpected==[] and .nottherebutexpected==[]') == true ]
}
