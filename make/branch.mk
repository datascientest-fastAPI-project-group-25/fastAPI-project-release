# === Branch Management ===
.PHONY: branch feat fix hotfix chore

branch:
	@bun run scripts/src/commands/branch/create.ts

feat:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		bun run scripts/src/commands/branch/create.ts feat "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		bun run scripts/src/commands/branch/create.ts feat; \
	fi

fix:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		bun run scripts/src/commands/branch/create.ts fix "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		bun run scripts/src/commands/branch/create.ts fix; \
	fi

hotfix:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		bun run scripts/src/commands/branch/create.ts hotfix "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		bun run scripts/src/commands/branch/create.ts hotfix; \
	fi

chore:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		bun run scripts/src/commands/branch/create.ts chore "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		bun run scripts/src/commands/branch/create.ts chore; \
	fi
