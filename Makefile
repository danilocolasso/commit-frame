LABEL := com.$(shell whoami).commit-frame
PLIST := $(HOME)/Library/LaunchAgents/$(LABEL).plist

# interactive wizard: configure, test render, optionally install the launchd agent.
# rerun it anytime to update the configs.
setup:
	@./setup.sh

# serve in the foreground (no launchd)
run:
	@./run.sh

start:
	@if launchctl print gui/$$(id -u)/$(LABEL) >/dev/null 2>&1; then \
		echo "already running ($(LABEL))"; \
	elif [ -f "$(PLIST)" ]; then \
		launchctl bootstrap gui/$$(id -u) "$(PLIST)" && echo "started ($(LABEL))"; \
	else \
		echo "no agent installed — run 'make setup' or './run.sh'"; \
	fi

stop:
	@if launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null; then \
		while launchctl print gui/$$(id -u)/$(LABEL) >/dev/null 2>&1; do sleep 0.2; done; \
		echo "stopped ($(LABEL))"; \
	elif pkill -f commit-frame/run.sh 2>/dev/null; then \
		echo "stopped (run.sh)"; \
	else \
		echo "not running"; \
	fi

.PHONY: setup run start stop
