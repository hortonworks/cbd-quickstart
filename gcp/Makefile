GIT_FIRST_PARENT ?= $(shell git describe --tags --first-parent | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]-*([a-z]+\.)*[0-9]+).*/\1/p')
CENTOS_CLOUD_IMAGE_NAME ?= $(shell make get-latest-centos7-image-name)
VALIDATED_CENTOS_CLOUD_IMAGE_NAME ?= $(shell cat image-validation/validated-image-name.txt)
GIT_BRANCH ?= $(shell git rev-parse --symbolic-full-name --abbrev-ref HEAD)
GIT_BRANCH_NAME = $(shell echo $(GIT_BRANCH) | sed -e 's|origin/||g')

check-env:
ifndef VERSION
  VERSION=$(GIT_FIRST_PARENT)
endif
ifndef SSH_KEY
  SSH_STRING=$(shell echo '"You need to set the SSH_KEY environment variable"')
else
  SSH_STRING=$(shell echo '"$(SSH_KEY)"')
endif
ifndef GCP_ACCOUNT_EMAIL
  GCP_ACCOUNT_EMAIL=$(shell echo '"You need to set the GCP_ACCOUNT_EMAIL environment variable"')
endif

echo-env:
	$(info VERSION=$(VERSION))
	$(info VALIDATED_CENTOS_CLOUD_IMAGE_NAME=$(VALIDATED_CENTOS_CLOUD_IMAGE_NAME))
	$(info CENTOS_CLOUD_IMAGE_NAME=$(CENTOS_CLOUD_IMAGE_NAME))
	$(info SSH_KEY=$(SSH_STRING))
	$(info GCP_ACCOUNT_EMAIL=$(GCP_ACCOUNT_EMAIL))

build-validated: check-env
	@echo "Updated GCP templates based on validated environment"
	sigil -f vm_template_config.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(VALIDATED_CENTOS_CLOUD_IMAGE_NAME)" SSH_KEY=$(SSH_STRING) GCP_ACCOUNT_EMAIL=$(GCP_ACCOUNT_EMAIL) > vm_template_config.yaml;
	sigil -f README.md.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(VALIDATED_CENTOS_CLOUD_IMAGE_NAME)" SSH_KEY=$(SSH_STRING) GCP_ACCOUNT_EMAIL=$(GCP_ACCOUNT_EMAIL) > README.md

build: check-env
	@echo "Updated GCP templates based on actual environment"
	sigil -f vm_template_config.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" SSH_KEY=$(SSH_STRING) GCP_ACCOUNT_EMAIL=$(GCP_ACCOUNT_EMAIL) > vm_template_config.yaml;
	sigil -f README.md.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" SSH_KEY=$(SSH_STRING) GCP_ACCOUNT_EMAIL=$(GCP_ACCOUNT_EMAIL) > README.md

list-latest-images:
	gcloud compute images list --project centos-cloud --filter='family:centos-7' --sort-by='~creationTimestamp'

get-latest-centos7-image-name:
	@gcloud compute images list --project centos-cloud --filter='family:centos-7' --sort-by='~creationTimestamp' --format="json"| jq -r '.[0].name'

check-latest-centos7-image-name: check-env
	@echo "Compare the previously set and the latest Google Cloud CentOs 7 image ID"
	chmod +x image-validation/scripts/image-validation.sh;
	STATE=check_cloud_image CENTOS_CLOUD_IMAGE_NAME=$(CENTOS_CLOUD_IMAGE_NAME) image-validation/scripts/image-validation.sh

create-validation-deployment: build
	@echo "Create a new CBD Custom Deployment ($(GCP_DEPLOYMENT_NAME)) in Google Account"
	chmod +x image-validation/scripts/image-validation.sh;
	STATE=create_deployment image-validation/scripts/image-validation.sh

remove-validation-deployment:
	@echo "Delete the previously created CBD Custom Deployment ($(GCP_DEPLOYMENT_NAME)) from Google Account"
	chmod +x image-validation/scripts/image-validation.sh;
	STATE=delete_deployment image-validation/scripts/image-validation.sh

push-updated-template: check-env
	@echo "Update VERSION to $(VERSION) and GCP image ID to $(CENTOS_CLOUD_IMAGE_NAME)"
	sigil -f vm_template_config.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" SSH_KEY=... GCP_ACCOUNT_EMAIL=... > vm_template_config.yaml;
	sigil -f README.md.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" SSH_KEY=... GCP_ACCOUNT_EMAIL=... > README.md
	@echo $(CENTOS_CLOUD_IMAGE_NAME) > image-validation/validated-image-name.txt
	@if [ 0 != "$(git status -uno --porcelain | wc -l | xargs)" ]; then \
		echo "Push the updated files to $(GIT_BRANCH) branch" ; \
		git checkout $(GIT_BRANCH_NAME) ; \
		git merge --ff-only $(GIT_BRANCH) ; \
		git commit -am "Updated GCP Image ID in VM Template and README to $(CENTOS_CLOUD_IMAGE_NAME)" ; \
		git push origin HEAD:$(GIT_BRANCH_NAME) ; \
	fi