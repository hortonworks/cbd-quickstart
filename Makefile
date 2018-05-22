export GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

generate-all: deps check-env generate-azure generate-gcp generate-aws

generate-azure: check-env
	@echo "Updating Azure templates to CBD version: $(VERSION)"
	make -C azure build

generate-aws: check-env
	@echo "Updating AWS templates to CBD version: $(VERSION)"
	make -C aws upload

generate-gcp: check-env
	@echo "Updating GCP templates to CBD version: $(VERSION)"
	make -C gcp build

push-updated-templates: check-env
	@echo "Updated CBD version in templates to $(VERSION)"
	git commit -am "Updated CBD versions in templates to $(VERSION)"
	git tag $(VERSION)
	git push origin HEAD:$(GIT_BRANCH) --tags

deps:
ifeq (, $(shell command -v sigil 2> /dev/null))
    $(shell curl -sL https://github.com/lalyos/sigil/releases/download/v0.4.1/sigil_0.4.1_$(shell uname)_x86_64.tgz | tar -xz -C /usr/local/bin)
endif
ifeq (, $(shell command -v uglifyjs 2> /dev/null))
    $(shell npm install uglify-js -g)
endif

check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif

echo_version:
	$(info GIT_BRANCH=$(GIT_BRANCH))
	$(info VERSION=$(VERSION))

.PHONY: push-updated-templates echo_version check-env generate-all generate-azure generate-aws generate-gcp deps