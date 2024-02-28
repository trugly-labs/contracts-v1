# Makefile

include .env
export

SNAPSHOT_PATH = .forge-snapshots

gas:
	@for file in $(SNAPSHOT_PATH)/*; do \
		echo "===== $$file ====="; \
		cat "$$file"; \
		echo "\n"; \
	done

