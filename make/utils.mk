# === Utility Functions ===

# Common paths for tools
COMMON_PATHS := /usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:/usr/local/homebrew/bin:$(HOME)/.docker/bin:$(HOME)/.krew/bin:/Applications/Docker.app/Contents/Resources/bin:$(PATH)

# Check if a tool exists in common paths
define check_tool
$(shell PATH="$(COMMON_PATHS)" which $(1) 2>/dev/null)
endef

# Get current OS
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')

# === Tool Installation ===
.PHONY: install-bun

install-bun:
ifeq ($(OS),darwin)
	@if ! command -v bun >/dev/null 2>&1; then \
		echo "Installing Bun..."; \
		curl -fsSL https://bun.sh/install | bash; \
		echo "Please restart your terminal or run:"; \
		echo "source ~/.zshrc    # for zsh"; \
		echo "source ~/.bashrc   # for bash"; \
	else \
		echo "✓ Bun is already installed"; \
	fi
else ifeq ($(OS),linux)
	@if ! command -v bun >/dev/null 2>&1; then \
		echo "Installing Bun..."; \
		curl -fsSL https://bun.sh/install | bash; \
		echo "Please restart your terminal or run:"; \
		echo "source ~/.bashrc"; \
	else \
		echo "✓ Bun is already installed"; \
	fi
else
	@echo "Please install Bun manually from https://bun.sh/install"
	@exit 1
endif
