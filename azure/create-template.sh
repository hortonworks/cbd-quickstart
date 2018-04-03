#!/bin/bash

: ${NEW_VERSION:?"need to set NEW_VERSION"}
: ${CBD_VERSION:?"need to set CBD_VERSION"}
: ${OS_IMAGE_SKU_VERSION:="latest"}

CBD_VERSION_UNDERSCORE=$(echo $NEW_VERSION | tr -d .)
echo "CBD_VERSION_UNDERSCORE: $CBD_VERSION_UNDERSCORE"

MANAGED_IMAGE_ID="/subscriptions/947dafa0-8a1d-4ac9-909b-c71a0fa03ea6/resourceGroups/cbd-images/providers/Microsoft.Compute/images/$CBD_VERSION_UNDERSCORE"
echo "MANAGED_IMAGE_ID: $MANAGED_IMAGE_ID"

sigil -f mainTemplate.tmpl CBD_VERSION="$CBD_VERSION" VERSION="$NEW_VERSION" MANAGED_IMAGE_ID="$MANAGED_IMAGE_ID" OS_IMAGE_SKU_VERSION= > mainTemplatePrivate.json;
sigil -f mainTemplate.tmpl CBD_VERSION="$CBD_VERSION" VERSION="$NEW_VERSION" MANAGED_IMAGE_ID="$MANAGED_IMAGE_ID" OS_IMAGE_SKU_VERSION="$OS_IMAGE_SKU_VERSION" > mainTemplate.json;