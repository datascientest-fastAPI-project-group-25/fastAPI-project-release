# === Branch Management ===
.PHONY: branch feat fix

branch:
	bun run scripts/src/commands/branch/create.ts

feat:
	@if [ -z "$(NAME)" ]; then \
		bun run scripts/src/commands/branch/create.ts feat; \
	else \
		bun run scripts/src/commands/branch/create.ts feat "$(NAME)"; \
	fi

fix:
	@if [ -z "$(NAME)" ]; then \
		bun run scripts/src/commands/branch/create.ts fix; \
	else \
		bun run scripts/src/commands/branch/create.ts fix "$(NAME)"; \
	fi
