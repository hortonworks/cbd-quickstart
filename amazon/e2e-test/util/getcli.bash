#!/bin/bash

test -f ${STACK_NAME}.stackdescriptor.bash && source ${STACK_NAME}.stackdescriptor.bash
test -f ${STACK_NAME}.smartsense_descriptor.bash && source ${STACK_NAME}.smartsense_descriptor.bash
: ${TEMPLATE_VERSION:? required}

HDCCLI_TAR=hdc-cli_${TEMPLATE_VERSION}_$(uname)_x86_64.tgz
aws s3 cp "s3://hdc-cli/${HDCCLI_TAR}" .
tar -zxvf ${HDCCLI_TAR}

