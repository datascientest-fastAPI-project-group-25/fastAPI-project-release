# === Portable, CI-ready Makefile ===

# Container images
K8S_TOOLS_IMAGE = fastapi/k8s-tools:latest
ARGOCD_TOOLS_IMAGE = fastapi/argocd-tools:latest
TEST_ENV_IMAGE = fastapi/k8s-test:latest

# Environment variables
NAMESPACE ?= fastapi
ENV ?= dev
BRANCH_NAME ?=
NAME ?=

# Import makefiles
include make/utils.mk
include make/bootstrap.mk
include make/k8s.mk
include make/branch.mk

# === CI Targets ===
.PHONY: ci-bootstrap ci-deploy

# Initialize the project environment, install dependencies, and run tests for CI pipelines
ci-bootstrap:
	make init
	bun install
	bun test

# Render Helm templates and deploy the application as part of CI/CD pipeline
ci-deploy:
	make helm-template
	make helm-deploy
help:
	@echo ""
	@echo "🚀🚀🚀  Project Make Commands  🚀🚀🚀"
	@echo ""
	@echo "Run these awesome commands to boost your workflow! 💪✨"
	@echo ""
	@echo "===================== Setup & Bootstrap ====================="
	@echo "init                   Initialize project environment"
	@echo "install-bun            Install Bun runtime"
	@echo ""
	@echo "===================== Build & Test =========================="
	@echo "ci-bootstrap           Run init, install dependencies, and tests (CI)"
	@echo "ci-deploy              Render Helm templates and deploy (CI)"
	@echo ""
	@echo "===================== Deployment ============================"
	@echo "helm-template          Render Helm templates (if defined)"
	@echo "helm-deploy            Deploy Helm charts (if defined)"
	@echo ""
	@echo "===================== Kubernetes & Docker ==================="
	@echo "k3d-up                 Create local k3d Kubernetes cluster"
	@echo "k3d-down               Delete local k3d Kubernetes cluster"
	@echo "k3d-status             List local k3d clusters"
	@echo "argocd-install         Install ArgoCD into Kubernetes cluster"
	@echo "argocd-login           Log into ArgoCD server"
	@echo "argocd-app-sync        Sync an ArgoCD application"
	@echo ""
	@echo "===================== Utilities & Misc ======================"
	@echo "branch                 Create a new branch interactively"
	@echo "feat                   Create a new feature branch"
	@echo "fix                    Create a new fix/bugfix branch"
	@echo ""
	@echo "Keep rocking! 🤘"

update-image:
	@echo "Updating image tags for $(ENV) environment to $(TAG)"
	yq e -i '.backend.tag = "$(TAG)"' config/helm/$(ENV).yaml
	yq e -i '.frontend.tag = "$(TAG)"' config/helm/$(ENV).yaml
	@echo "Image tags updated successfully"
