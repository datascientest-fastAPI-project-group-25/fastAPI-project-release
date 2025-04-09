# === Bootstrap Environment ===
.PHONY: init

# Initialize project
init: install-bun
	@if [ -z "$(call check_tool,bun)" ]; then \
		echo "Please restart your terminal and run 'make init' again to use the newly installed Bun."; \
		exit 1; \
	fi
	@echo "Running initialization script..."
	@PATH="$(COMMON_PATHS)" bun run scripts/src/core/bootstrap.ts
