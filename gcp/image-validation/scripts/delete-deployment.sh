#!/bin/bash

set -euxo pipefail

: ${GCP_ACCOUNT_EMAIL:? required}
: ${GCP_ACCOUNT_FILE_PATH:? required}
: ${GCP_PROJECT:? required}
: ${GCP_DEPLOYMENT_NAME:? required}

gcloud auth activate-service-account \
     $GCP_ACCOUNT_EMAIL \
     --key-file=$GCP_ACCOUNT_FILE_PATH \
     --project=$GCP_PROJECT

gcloud deployment-manager deployments delete $GCP_DEPLOYMENT_NAME -q