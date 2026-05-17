.PHONY: test smoke install

test:
	python3 -m py_compile bin/codex-discord-notifier
	python3 tests/test_notifier.py

smoke:
	bin/codex-discord-notifier --send-test --dry-run

install:
	./install.sh
