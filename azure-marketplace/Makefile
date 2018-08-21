package:
	rm -rf package
	mkdir package
	zip package/ver ./* -i createUiDefinition.json mainTemplate.json vnet_existing.json vnet_new.json
	unzip -lv ./package/ver.zip

.PHONY:  package
