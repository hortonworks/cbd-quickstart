echo_version: check-env
	$(info VERSION=$(VERSION))

build: check-env
	./create-template.sh
	sigil -f README.md.tmpl VERSION="$(VERSION)" > README.md

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

check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif

.PHONY: build package echo_version build-as-snapshot
