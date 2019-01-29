#!/bin/bash

set -euxo pipefail

: ${ENVFILE:=image-validation/testenvironment}
: ${STATE:=create_deployment}
: ${CENTOS_CLOUD_IMAGE_NAME=? required}
: ${CREATE_SCRIPT:=image-validation/scripts/create-deployment.sh}
: ${DELETE_SCRIPT:=image-validation/scripts/delete-deployment.sh}

readonly TEST_CONTAINER_NAME=gcloud-image-validator
readonly GCLOUD_IMAGE_NAME=google/cloud-sdk
readonly SAVED_CENTOS_CLOUD_IMAGE_NAME=$(cat image-validation/validated-image-name.txt)

docker-container-remove-exited() {
    declare desc="Remove Exited or Dead containers"

    local exited_containers=$(docker ps -a -f status=exited -f status=dead -q)

    if [[ -n "$exited_containers" ]]; then
        echo "Remove Exited or Dead docker containers"
        docker rm $exited_containers
    else
        echo "There is no Exited or Dead container"
    fi
}

docker-container-remove-stuck() {
    declare desc="Remove stuck $TEST_CONTAINER_NAME container from previous run"

    if [[ "$(docker inspect -f {{.State.Running}} $TEST_CONTAINER_NAME 2> /dev/null)" == "true" ]]; then
        echo "Delete the running $TEST_CONTAINER_NAME container"
        docker rm -f $TEST_CONTAINER_NAME
    else
        echo "There is no stuck container"
    fi
}

docker-image-refresh() {
    declare desc="Pull the latest $GCLOUD_IMAGE_NAME image"

    docker pull $GCLOUD_IMAGE_NAME
}

cloud-deployment() {
    declare desc="Apply Google Cloud SDK commands in $TEST_CONTAINER_NAME container"

    chmod +x $1

    docker run \
        -i \
        --rm \
        --name $TEST_CONTAINER_NAME \
        --env-file $ENVFILE \
        -v $(pwd):/project \
        -w /project \
        $GCLOUD_IMAGE_NAME ./$1
    RESULT=$?
}

cloud-image-check() {
    declare desc="Compare the latest ($CENTOS_CLOUD_IMAGE_NAME) and the saved ($SAVED_CENTOS_CLOUD_IMAGE_NAME) CentOS image IDs"

    if [[ "${CENTOS_CLOUD_IMAGE_NAME}" == "${SAVED_CENTOS_CLOUD_IMAGE_NAME}" ]]; then
        echo "The $CENTOS_CLOUD_IMAGE_NAME is the saved, no need to update"
        RESULT=1
    else
        echo "The $CENTOS_CLOUD_IMAGE_NAME is NOT the saved, need to update"
        RESULT=0
    fi
}

main() {
  case $STATE in
  create_deployment)
    docker-container-remove-stuck
    docker-container-remove-exited
    docker-image-refresh
    cloud-deployment $CREATE_SCRIPT
    exit $RESULT
    ;;
  delete_deployment)
    docker-container-remove-stuck
    docker-container-remove-exited
    docker-image-refresh
    cloud-deployment $DELETE_SCRIPT
    exit $RESULT
    ;;
  check_cloud_image)
    docker-container-remove-stuck
    docker-container-remove-exited
    docker-image-refresh
    cloud-image-check
    exit $RESULT
    ;;
  *)
    exit 1
  esac
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"