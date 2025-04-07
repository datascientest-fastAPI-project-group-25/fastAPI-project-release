# Makefile for FastAPI Project Release

# Variables
HELM_CHART_DIR = charts/fastapi
STAGING_VALUES = config/helm/staging.yaml
PRODUCTION_VALUES = config/helm/production.yaml
NAMESPACE = fastapi-helm

# Docker run command for containerized operations
DOCKER_IMAGE = fastapi-tools
DOCKER_RUN = docker run --rm -v $(PWD):/app -w /app $(DOCKER_IMAGE)

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  help                 - Show this help message"
	@echo "  build-image	      - Build the Docker tools image"
	@echo "  lint                 - Lint Helm charts"
	@echo "  template-staging     - Generate Kubernetes manifests for staging"
	@echo "  template-production  - Generate Kubernetes manifests for production"
	@echo "  setup-k3d            - Set up a local k3d cluster"
	@echo "  setup-k3d-docker     - Set up a local k3d cluster using Docker"
	@echo "  setup-argocd         - Set up ArgoCD in the local cluster"
	@echo "  setup-github         - Set up GitHub secrets for ArgoCD"
	@echo "  deploy-staging       - Deploy to staging environment"
	@echo "  deploy-production    - Deploy to production environment"
	@echo "  clean                - Clean up temporary files"
	@echo "  clean-k3d            - Delete the local k3d cluster"

# Build the Docker tools image
.PHONY: build-bild-image
build-image	 :
	docker build -t $(DOCKER_IMAGE) .

# Lint Helm charts
.PHONY: lint
lint: build-image
	$(DOCKER_RUN) helm lint $(HELM_CHART_DIR) -f $(STAGING_VALUES)
	$(DOCKER_RUN) helm lint $(HELM_CHART_DIR) -f $(PRODUCTION_VALUES)

# Generate Kubernetes manifests
.PHONY: template-staging
template-staging: build-image
	$(DOCKER_RUN) bash -c "helm template fastapi-staging $(HELM_CHART_DIR) -f $(STAGING_VALUES) > /app/staging-manifests.yaml"
	@echo "Manifests generated at staging-manifests.yaml"

.PHONY: template-production
template-production: build-image
	$(DOCKER_RUN) bash -c "helm template fastapi-production $(HELM_CHART_DIR) -f $(PRODUCTION_VALUES) > /app/production-manifests.yaml"
	@echo "Manifests generated at production-manifests.yaml"

# Set up local k3d cluster
.PHONY: setup-k3d
setup-k3d: build-image
	$(DOCKER_RUN) ./scripts/setup-local-k3d-argocd.sh

# Set up local k3d cluster using Docker
.PHONY: setup-k3d-docker
setup-k3d-docker:
	docker-compose up --build

# Set up ArgoCD
.PHONY: setup-argocd
setup-argocd: build-image
	$(DOCKER_RUN) bash -c "kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -"
	$(DOCKER_RUN) kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	$(DOCKER_RUN) kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
	@echo "Waiting for ArgoCD server to be ready..."
	$(DOCKER_RUN) kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
	@echo "ArgoCD admin password:"
	$(DOCKER_RUN) bash -c "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
	@echo ""

# Set up GitHub secrets for ArgoCD
.PHONY: setup-github
setup-github: build-image
	$(DOCKER_RUN) ./scripts/setup-argocd-github.sh

# Deploy to environments
.PHONY: deploy-staging
deploy-staging: build-image template-staging
	$(DOCKER_RUN) bash -c "kubectl create namespace $(NAMESPACE)-staging --dry-run=client -o yaml | kubectl apply -f -"
	$(DOCKER_RUN) kubectl apply -f config/argocd/staging.yaml
	$(DOCKER_RUN) kubectl apply -f /app/staging-manifests.yaml -n $(NAMESPACE)-staging
	@echo "Deployed to staging environment"

.PHONY: deploy-production
deploy-production: build-image template-production
	$(DOCKER_RUN) bash -c "kubectl create namespace $(NAMESPACE)-production --dry-run=client -o yaml | kubectl apply -f -"
	$(DOCKER_RUN) kubectl apply -f config/argocd/production.yaml
	$(DOCKER_RUN) kubectl apply -f /app/production-manifests.yaml -n $(NAMESPACE)-production
	@echo "Deployed to production environment"

# Clean up
.PHONY: clean
clean:
	rm -f staging-manifests.yaml production-manifests.yaml
	@echo "Cleaned up manifest files"

.PHONY: clean-k3d
clean-k3d: build-image
	$(DOCKER_RUN) k3d cluster delete argocd-cluster
