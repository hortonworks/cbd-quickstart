UPLOAD_BUCKET ?= cbd-quickstart
SIMPLE_TEMPLATE_BASE_NAME ?= cbd-quickstart
IMAGE_NAME_FILTER="amzn-ami-hvm-2018*"

echo_version:
	$(info VERSION=$(VERSION))
	$(info UPLOAD_BUCKET=$(UPLOAD_BUCKET))
	$(info SIMPLE_TEMPLATE_BASE_NAME=$(SIMPLE_TEMPLATE_BASE_NAME))
	$(info IMAGE_NAME_FILTER=$(IMAGE_NAME_FILTER))

clean:
	rm -rf build
	mkdir -p build

build:
	mkdir -p build
	@echo "Updating AWS template to CBD version: $(VERSION)"
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(VERSION)" > build/$(SIMPLE_TEMPLATE_BASE_NAME)-$(VERSION).template
	
	@find build -name \*.template | xargs -n 1 -I@ bash -c 'echo "[json-syntax-check]  @" ; jq . @ >/dev/null'

upload: check-env clean build
	@docker run --rm -t \
	    -e "AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID)" \
	    -e "AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY)" \
	    -e "AWS_DEFAULT_REGION=eu-central-1" \
	    -v $(shell pwd)/build:/data \
	    infrastructureascode/aws-cli:1.15.24 aws s3 cp --acl public-read /data/cbd-quickstart-$(VERSION).template s3://$(UPLOAD_BUCKET)/
	@sigil -f README.md.tmpl  VERSION="$(VERSION)" > README.md

generate-latest-ami-mappings:
	./generate-latest-ami-mappings.sh "$(IMAGE_NAME_FILTER)"

check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif
ifndef AWS_ACCESS_KEY_ID
  $(error AWS_ACCESS_KEY_ID is a mandatory env variable)
endif
ifndef AWS_SECRET_ACCESS_KEY
  $(error AWS_SECRET_ACCESS_KEY is a mandatory env variable)
endif

.PHONY: build upload generate-latest-ami-mappings
