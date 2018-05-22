UPLOAD_BUCKET ?= cbd-quickstart
SIMPLE_TEMPLATE_BASE_NAME ?= cbd-quickstart
IMAGE_NAME_FILTER="amzn-ami-hvm-2018*"

echo_version:
	$(info VERSION=$(VERSION))

clean:
	rm -rf build
	mkdir -p build

build:
	$(eval VALIDATOR=$(shell uglifyjs --compress --mangle -- lambda/validate-parameters.js | sed 's/"/\\\\\\"/g' | sed 's/\\n/\\\\n/g'))

	mkdir -p build
	@echo "Updating AWS template to CBD version: $(VERSION)"
	@sigil -f cbd-advanced.tmpl  CBD_VERSION="$(VERSION)" VALIDATOR="$(VALIDATOR)" > build/$(SIMPLE_TEMPLATE_BASE_NAME)-$(VERSION).template
	
	@find build -name \*.template | xargs -n 1 -I@ bash -c 'echo "[json-syntax-check]  @" ; jq . @ >/dev/null'

upload: clean build
	bash -c "aws s3 cp build/cbd-quickstart-$(VERSION).template s3://$(UPLOAD_BUCKET)/ --region eu-central-1 --acl public-read"
	@sigil -f README.md.tmpl  VERSION="$(VERSION)" > README.md

generate-latest-ami-mappings:
	./generate-latest-ami-mappings.sh "$(IMAGE_NAME_FILTER)"

.PHONY: build upload generate-latest-ami-mappings
