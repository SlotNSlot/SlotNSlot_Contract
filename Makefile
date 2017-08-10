# This Makefile is meant to be used by compile .sol files without truffle command
WORKSPACE=$(shell pwd)

ico:
	if [ ! -d "$(WORKSPACE)/compile/output" ]; then mkdir -p $(WORKSPACE)/compile/output; fi
	sed -e 's|$${__WORKSPACE__}|'"$(WORKSPACE)"'|g' $(WORKSPACE)/compile/config/ico.json | solc --allow-paths $(WORKSPACE) --standard-json > $(WORKSPACE)/compile/output/ico.json

clean:
	rm -rf $(WORKSPACE)/compile/build