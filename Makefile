# === Portable, CI-ready Makefile ===

# First time setup:
# Run 'make init' to check and install required tools:
#   - bun (JavaScript/TypeScript runtime)
#   - git (Version control)
#   - docker (Container runtime)
#   - kubectl (Kubernetes CLI)
#   - k3d (Local Kubernetes)
#   - helm (Kubernetes package manager)

# Container images
K8S_TOOLS_IMAGE = fastapi/k8s-tools:latest
ARGOCD_TOOLS_IMAGE = fastapi/argocd-tools:latest
TEST_ENV_IMAGE = fastapi/k8s-test:latest

# Environment variables
NAMESPACE ?= fastapi
ENV ?= dev
BRANCH_NAME ?= 
NAME ?= 

# === Bootstrap Environment ===
.PHONY: init
init:
	bun run scripts/src/core/bootstrap.ts


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

# === Local Kubernetes with k3d ===
.PHONY: k3d-up k3d-down k3d-status

k3d-up:
	docker run --rm -v $$HOME/.k3d:/root/.k3d -v /var/run/docker.sock:/var/run/docker.sock $(K8S_TOOLS_IMAGE) k3d cluster create $(NAMESPACE)-cluster

k3d-down:
	docker run --rm -v $$HOME/.k3d:/root/.k3d -v /var/run/docker.sock:/var/run/docker.sock $(K8S_TOOLS_IMAGE) k3d cluster delete $(NAMESPACE)-cluster

k3d-status:
	docker run --rm -v $$HOME/.k3d:/root/.k3d -v /var/run/docker.sock:/var/run/docker.sock $(K8S_TOOLS_IMAGE) k3d cluster list

# === ArgoCD ===
.PHONY: argocd-install argocd-login argocd-app-sync

argocd-install:
	docker run --rm -v $$KUBECONFIG:/root/.kube/config $(ARGOCD_TOOLS_IMAGE) kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-login:
	docker run --rm -it -v $$KUBECONFIG:/root/.kube/config $(ARGOCD_TOOLS_IMAGE) argocd login $(ARGOCD_SERVER) --username admin --password $(ARGOCD_PASSWORD)

argocd-app-sync:
	docker run --rm -v $$KUBECONFIG:/root/.kube/config $(ARGOCD_TOOLS_IMAGE) argocd app sync $(ARGOCD_APP)

# === Helm ===
.PHONY: helm-template helm-deploy

helm-template:
	docker run --rm -v $$PWD:/work -w /work $(K8S_TOOLS_IMAGE) helm template fastapi charts/fastapi -n $(NAMESPACE) > manifests.yaml

helm-deploy:
	docker run --rm -v $$PWD:/work -w /work $(K8S_TOOLS_IMAGE) kubectl apply -f manifests.yaml -n $(NAMESPACE)

# === Cleanup ===
.PHONY: clean reset

clean:
	rm -f manifests.yaml

reset: k3d-down clean

# === CI Targets ===
.PHONY: ci-bootstrap ci-deploy

ci-bootstrap:
	make init
	bun install
	bun test

ci-deploy:
	make helm-template
	make helm-deploy

# === Usage ===
# make branch                # Interactive branch creation
# make feat NAME=feature-x   # Create feature branch
# make fix NAME=bugfix-y     # Create fix branch
# make init                  # Bootstrap environment
# make k3d-up                # Start local k3d cluster
# make argocd-install        # Install ArgoCD
# make helm-template         # Render Helm charts
# make helm-deploy           # Deploy manifests
# make clean                 # Remove generated files
# make reset                 # Teardown cluster and clean
# make ci-bootstrap          # CI: setup and test
# make ci-deploy             # CI: deploy