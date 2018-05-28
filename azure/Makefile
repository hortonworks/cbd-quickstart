export OS_IMAGE_SKU_VERSION=7.4.20180417

echo_version: check-env
	$(info VERSION=$(VERSION))
	$(info OS_IMAGE_SKU_VERSION=$(OS_IMAGE_SKU_VERSION))

build: check-env
	./create-template.sh
	sigil -f README.md.tmpl VERSION="$(VERSION)" OS_IMAGE_SKU_VERSION="$(OS_IMAGE_SKU_VERSION)" > README.md

build-as-snapshot:
	rm -rf build
	git tag snapshot
	make build
	git tag snapshot -d

package:
	rm -rf package
	mkdir package
	zip package/ver ./* -i createUiDefinition.json install-cbd.sh mainTemplate.json vnet_existing.json vnet_new.json
	unzip -lv ./package/ver.zip

list-latest-images:
	az vm image list --output table --all --offer CentOS --publisher OpenLogic --sku 7-CI

check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif

.PHONY: build package echo_version build-as-snapshot
