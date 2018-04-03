GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG=$(shell git describe --exact-match --tags 2>/dev/null)
GIT_LAST_TAG=$(shell git describe --tags --abbrev=0)
UPLOAD_BUCKET ?= hdc-cfn
SIMPLE_TEMPLATE_BASE_NAME ?= hdcloud-basic
CUSTOM_TEMPLATE_BASE_NAME ?= hdcloud-advanced

ifeq ($(NEW_VERSION),)
	ifeq ($(GIT_TAG),)
		ifeq ($(GIT_BRANCH), master)
			VERSION=snapshot
			CBD_VERSION=snapshot
	  	else
			VERSION=$(GIT_BRANCH)-snapshot
			CBD_VERSION=$(GIT_LAST_TAG)
	  	endif
	else
		VERSION=$(GIT_TAG)
		CBD_VERSION=$(GIT_TAG)
	endif
else
	VERSION=$(NEW_VERSION)
	CBD_VERSION=$(NEW_VERSION)
endif

echo_version:
	$(info GIT_BRANCH=$(GIT_BRANCH))
	$(info GIT_TAG=$(GIT_TAG))
	$(info VERSION=$(VERSION))
	$(info CBD_VERSION=$(CBD_VERSION))

deps:
	curl -sL https://github.com/lalyos/sigil/releases/download/v0.4.1/sigil_0.4.1_$(shell uname)_x86_64.tgz | tar -xz -C /usr/local/bin
	curl -sL https://github.com/lalyos/atlas/releases/download/v0.0.5/atlas_0.0.5_$(shell uname)_x86_64.tgz | tar -xz -C /usr/local/bin/
	npm install uglify-js -g

prepare: get-latest-ami-mapping
	if ! git diff --exit-code > /dev/null; then \
		git commit -am "updated ami map to latest images"; \
	fi; \
	git tag $(NEW_VERSION); \
	git push origin HEAD:$(GIT_BRANCH) --tags; \

clean:
	rm -rf build
	mkdir -p build

build:
	$(eval VALIDATOR=$(shell uglifyjs --compress --mangle -- lambda/validate-parameters.js | sed 's/"/\\\\\\"/g' | sed 's/\\n/\\\\n/g'))

	mkdir -p build
	# Standard Tech Preview (not Marketplace GA) templates
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS= VPC= SSTP= GA= STAGING=true VALIDATOR="$(VALIDATOR)" > build/$(SIMPLE_TEMPLATE_BASE_NAME)-TP-$(VERSION).template
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS=tru VPC=true SSTP= GA= STAGING=true VALIDATOR="$(VALIDATOR)" > build/$(CUSTOM_TEMPLATE_BASE_NAME)-TP-$(VERSION).template
	
	# Tech Preview for Shared Services templates
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS= VPC= SSTP=true GA= STAGING=true VALIDATOR="$(VALIDATOR)" > build/$(SIMPLE_TEMPLATE_BASE_NAME)-shared-services-TP-$(VERSION).template
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS=true VPC=true SSTP=true GA= STAGING=true VALIDATOR="$(VALIDATOR)" > build/$(CUSTOM_TEMPLATE_BASE_NAME)-shared-services-TP-$(VERSION).template
	
	# GA-staging templates (GA candidate templates, but using the TP image catalog and the staging HCC)
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS= VPC= SSTP= GA=true STAGING=true VALIDATOR="$(VALIDATOR)" > build/$(SIMPLE_TEMPLATE_BASE_NAME)-GA-staging-$(VERSION).template
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS=true VPC=true SSTP= GA=true STAGING=true VALIDATOR="$(VALIDATOR)" > build/$(CUSTOM_TEMPLATE_BASE_NAME)-GA-staging-$(VERSION).template
	
	# GA-final templates (final GA candidate templates, using the marketplace image catalog and the production HCC)
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS= VPC= SSTP= GA=true STAGING= VALIDATOR="$(VALIDATOR)" > build/$(SIMPLE_TEMPLATE_BASE_NAME)-GA-final-$(VERSION).template
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(CBD_VERSION)" RDS=true VPC=true SSTP= GA=true STAGING= VALIDATOR="$(VALIDATOR)" > build/$(CUSTOM_TEMPLATE_BASE_NAME)-GA-final-$(VERSION).template
	
	@find build -name \*.template | xargs -n 1 -I@ bash -c 'echo "[json-syntax-check]  @" ; jq . @ >/dev/null'

upload: clean build
	bash -c "cd build; aws s3 cp .  s3://$(UPLOAD_BUCKET)/ --region us-east-1 --acl public-read --recursive"

build-as-snapshot: clean
	git tag snapshot
	make build
	git tag snapshot -d

cf-network:
	aws cloudformation create-stack \
  --template-body file://private-subnet.json \
  --parameters \
      ParameterKey=KeyName,ParameterValue=seq-master \
      ParameterKey=AvailabilityZone,ParameterValue=eu-central-1a \
  --tags Key=Owner,Value=${USER} \
  --stack-name cbd-subnet-test

cf-instance:
	aws cloudformation create-stack \
  --template-body file://cloudbreak-deployement-subnet.json \
  --parameters \
      ParameterKey=KeyName,ParameterValue=seq-master \
  --tags Key=Owner,Value=${USER} \
  --capabilities CAPABILITY_IAM \
  --stack-name cbd-xstack-ref

cf-basic-tp: build-as-snapshot
ifndef KEY_NAME
	$(error KEY_NAME is undefined)
endif

	aws cloudformation create-stack \
	--capabilities CAPABILITY_IAM \
	--stack-name hdc-test-stack-$(shell date +"%s") \
	--tags Key=Owner,Value=${USER} \
	--disable-rollback \
	--template-body file://./build/hdcloud-basic-TP-snapshot.template \
	--parameters ParameterKey=EmailAddress,ParameterValue=admin@example.com \
	ParameterKey=AdminPassword,ParameterValue=cloudbreak \
	ParameterKey=RemoteLocation,ParameterValue='0.0.0.0/0' \
	ParameterKey=InstanceType,ParameterValue=m4.large \
	ParameterKey=ProductTelemetry,ParameterValue="I Do Not Opt In to SmartSense Telemetry" \
	ParameterKey=SmartSenseId,ParameterValue="" \
	ParameterKey=KeyName,ParameterValue=$(KEY_NAME)

delete-stacks:
	aws cloudformation delete-stack --stack-name cbd-subnet-test
	aws cloudformation delete-stack --stack-name cbd-xstack-ref

list-cbd-img-versions:
	atlas -s sequenceiq/cbd/amazon-linux.image -f '{{.Version}} {{.Metadata.image_name}}'

get-latest-ami-mapping:
	sigil -f aws-mapping.tmpl > aws-mapping.yml

generate-minified-lambda:
	uglifyjs --compress --mangle -- lambda-hdp-link/stack-delete-wait.js

deploy-basic-controller: clean build
	STATE=deploy ./test-e2e/deploy_basic.sh

deploy-basic-ss-controller: clean build
	STATE=deploy_ss ./test-e2e/deploy_basic.sh

terminate-basic-controller:
	STATE=terminate STACK_NAME=${STACK_NAME} ./test-e2e/deploy_basic.sh

run-cli-tests:
	bats --tap -d ./test-e2e/bats-tests-cli.bats | tee ./test-e2e/cli_results.tap

run-controller-tests:
	bats --tap -d ./test-e2e/bats-tests-controller.bats | tee ./test-e2e/controller_results.tap

run-cluster-tests:
	bats --tap -d ./test-e2e/bats-tests-cluster.bats | tee ./test-e2e/cluster_results.tap

run-openedports-tests:
	bats --tap -d ./test-e2e/bats-tests-portvalidation.bats | tee ./test-e2e/ports_results.tap

run-recovery-tests:
	bats --tap -d ./test-e2e/autorecovery-scenario.bats ./test-e2e/describe-instance-scenario.bats ./test-e2e/manualrecovery-scenario.bats | tee ./test-e2e/recovery_results.tap

.PHONY: build
