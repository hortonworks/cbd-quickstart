export CENTOS_CLOUD_IMAGE_NAME=centos-7-v20180815

build: check-env
	@echo "Updated CBD version in GCP templates to $(VERSION)"
	sigil -f vm_template_config.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" > vm_template_config.yaml;
	sigil -f README.md.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" > README.md

list-latest-images:
	gcloud compute images list --project centos-cloud --filter='family:centos-7'

echo_version:
	$(info VERSION=$(VERSION))
	$(info CENTOS_CLOUD_IMAGE_NAME=$(CENTOS_CLOUD_IMAGE_NAME))

check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif
