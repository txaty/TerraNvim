# Developer entry points. `make check` is the definition of done for a change.
STARTUP_RUNS ?= 5
STARTUP_WARN_MS ?= 30
STARTUP_FAIL_MS ?= 35

.PHONY: check fmt lint test startup

check: lint test startup

fmt:
	stylua lua scripts

lint:
	stylua --check lua scripts
	luacheck lua scripts

# default = settings' default packs, all = every pack, none = no packs.
test:
	scripts/smoke.sh default all none

startup:
	scripts/startup.sh $(STARTUP_RUNS) $(STARTUP_WARN_MS) $(STARTUP_FAIL_MS)
