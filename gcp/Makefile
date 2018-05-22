build: check-env
	@echo "Updated CBD version in GCP templates to $(VERSION)"
	sigil -f vm_template_config.tmpl VERSION="$(VERSION)" > vm_template_config.yaml;
	sigil -f README.md.tmpl VERSION="$(VERSION)" > README.md

check-env:
ifndef VERSION
  $(error VERSION is a mandatory env variable)
endif