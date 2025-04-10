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

# WARNING: This target uses ARGOCD_SERVER and ARGOCD_PASSWORD environment variables for authentication.
# Storing sensitive data like passwords in environment variables is discouraged.
# Consider using a secret manager or Kubernetes secrets for better security.
argocd-login:
	docker run --rm -it -v $$KUBECONFIG:/root/.kube/config $(ARGOCD_TOOLS_IMAGE) argocd login $(ARGOCD_SERVER) --username admin --password $(ARGOCD_PASSWORD)

argocd-app-sync:
	docker run --rm -v $$KUBECONFIG:/root/.kube/config $(ARGOCD_TOOLS_IMAGE) argocd app sync $(ARGOCD_APP)

# === Update Helm image tags ===
.PHONY: update-image

update-image:
	@echo "==> Validating inputs and environment..."
	@if [ -z "$$TAG" ]; then \
		echo "Error: TAG is required"; \
		echo "Usage: make update-image TAG=yourtag ENV=environment"; \
		exit 1; \
	fi

	@if [ -z "$$ENV" ]; then \
		if echo "$$TAG" | grep -q '^v'; then \
			ENV=production; \
		else \
			ENV=staging; \
		fi; \
		echo "ENV not specified, defaulting to $$ENV based on tag format"; \
	fi

	@echo "==> Validating Helm values file..."
	@if [ ! -f "config/helm/$$ENV.yaml" ]; then \
		echo "Error: config/helm/$$ENV.yaml does not exist"; \
		echo "Available environments:"; \
		ls -1 config/helm/*.yaml 2>/dev/null || echo "No environment files found!"; \
		exit 1; \
	fi

	@echo "==> Checking current values..."
	@echo "Current backend tag: $$(yq e '.backend.tag' config/helm/$$ENV.yaml || echo 'Not set')"
	@echo "Current frontend tag: $$(yq e '.frontend.tag' config/helm/$$ENV.yaml || echo 'Not set')"

	@echo "==> Updating image tags to $$TAG..."
	@if ! yq e -i '.backend.tag = "$(TAG)"' config/helm/$$ENV.yaml; then \
		echo "Error: Failed to update backend tag"; \
		exit 1; \
	fi

	@if ! yq e -i '.frontend.tag = "$(TAG)"' config/helm/$$ENV.yaml; then \
		echo "Error: Failed to update frontend tag"; \
		echo "Warning: Backend tag may have been updated, manual verification required"; \
		exit 1; \
	fi

	@echo "==> Verifying updates..."
	@NEW_BACKEND_TAG=$$(yq e '.backend.tag' config/helm/$$ENV.yaml) && \
	NEW_FRONTEND_TAG=$$(yq e '.frontend.tag' config/helm/$$ENV.yaml) && \
	if [ "$$NEW_BACKEND_TAG" != "$(TAG)" ] || [ "$$NEW_FRONTEND_TAG" != "$(TAG)" ]; then \
		echo "Error: Tag verification failed!"; \
		echo "Expected: $(TAG)"; \
		echo "Got: backend=$$NEW_BACKEND_TAG, frontend=$$NEW_FRONTEND_TAG"; \
		exit 1; \
	fi

	@echo "✅ Image tags successfully updated for $$ENV environment"
