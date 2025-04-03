# Makefile for FastAPI Project Release

# Variables
HELM_CHART_DIR = charts/fastapi
STAGING_VALUES = config/helm/staging.yaml
PRODUCTION_VALUES = config/helm/production.yaml
NAMESPACE = fastapi-helm

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  help                 - Show this help message"
	@echo "  lint                 - Lint Helm charts"
	@echo "  template-staging     - Generate Kubernetes manifests for staging"
	@echo "  template-production  - Generate Kubernetes manifests for production"
	@echo "  setup-k3d           - Set up a local k3d cluster"
	@echo "  setup-argocd        - Set up ArgoCD in the local cluster"
	@echo "  setup-github        - Set up GitHub secrets for ArgoCD"
	@echo "  deploy-staging      - Deploy to staging environment"
	@echo "  deploy-production   - Deploy to production environment"
	@echo "  clean               - Clean up temporary files"
	@echo "  clean-k3d           - Delete the local k3d cluster"

# Lint Helm charts
.PHONY: lint
lint:
	helm lint $(HELM_CHART_DIR) -f $(STAGING_VALUES)
	helm lint $(HELM_CHART_DIR) -f $(PRODUCTION_VALUES)

# Generate Kubernetes manifests
.PHONY: template-staging
template-staging:
	helm template fastapi-staging $(HELM_CHART_DIR) -f $(STAGING_VALUES) > staging-manifests.yaml
	@echo "Manifests generated at staging-manifests.yaml"

.PHONY: template-production
template-production:
	helm template fastapi-production $(HELM_CHART_DIR) -f $(PRODUCTION_VALUES) > production-manifests.yaml
	@echo "Manifests generated at production-manifests.yaml"

# Set up local k3d cluster
.PHONY: setup-k3d
setup-k3d:
	./scripts/setup-local-k3d-argocd.sh

# Set up ArgoCD
.PHONY: setup-argocd
setup-argocd:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
	@echo "Waiting for ArgoCD server to be ready..."
	kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
	@echo "ArgoCD admin password:"
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

# Set up GitHub secrets for ArgoCD
.PHONY: setup-github
setup-github:
	./scripts/setup-argocd-github.sh

# Deploy to environments
.PHONY: deploy-staging
deploy-staging:
	kubectl create namespace $(NAMESPACE)-staging --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f config/argocd/staging.yaml

.PHONY: deploy-production
deploy-production:
	kubectl create namespace $(NAMESPACE)-production --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f config/argocd/production.yaml

# Clean up
.PHONY: clean
clean:
	rm -f staging-manifests.yaml production-manifests.yaml

.PHONY: clean-k3d
clean-k3d:
	k3d cluster delete argocd-cluster
