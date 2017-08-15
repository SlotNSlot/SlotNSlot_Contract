# This Makefile is meant to be used by compile .sol files without truffle command
WORKSPACE=$(shell pwd)

.PHONY: ico multisig

define solc_build
	if [ ! -d "$(WORKSPACE)/compile/output" ]; then mkdir -p $(WORKSPACE)/compile/output; fi
	sed -e 's|$${__WORKSPACE__}|'"$(WORKSPACE)"'|g' $(WORKSPACE)/compile/config/$(1) | solc --allow-paths $(WORKSPACE) --standard-json > $(WORKSPACE)/compile/output/$(1)
endef

ico:
	$(call solc_build,ico.json)

multisig:
	$(call solc_build,multisig.json)

clean:
	rm -rf $(WORKSPACE)/compile/output