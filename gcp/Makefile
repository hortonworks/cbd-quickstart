
check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif
ifndef CENTOS_CLOUD_IMAGE_NAME
  export CENTOS_CLOUD_IMAGE_NAME=centos-7-v20190116
endif

build: check-env
	@echo "Updated CBD version in GCP templates to $(VERSION)"
	sigil -f vm_template_config.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" > vm_template_config.yaml;
	sigil -f README.md.tmpl VERSION="$(VERSION)" CENTOS_CLOUD_IMAGE_NAME="$(CENTOS_CLOUD_IMAGE_NAME)" > README.md

list-latest-images:
	gcloud compute images list --project centos-cloud --filter='family:centos-7' --sort-by='~creationTimestamp'

get-latest-centos7-image-name:
	@gcloud compute images list --project centos-cloud --filter='family:centos-7' --sort-by='~creationTimestamp' --format="json"| jq -r '.[0].name'

echo_version:
	$(info VERSION=$(VERSION))
	$(info CENTOS_CLOUD_IMAGE_NAME=$(CENTOS_CLOUD_IMAGE_NAME))
