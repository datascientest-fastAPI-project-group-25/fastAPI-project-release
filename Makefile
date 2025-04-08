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

ci-bootstrap:
	make init
	bun install
	bun test

ci-deploy:
	make helm-template
	make helm-deploy
