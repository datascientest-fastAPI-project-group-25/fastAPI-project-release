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
	@if [ -z "$$TAG" ]; then \
		echo "Usage: make update-image TAG=yourtag ENV=environment"; exit 1; \
	fi; \
	if [ -z "$$ENV" ]; then \
		if echo "$$TAG" | grep -q '^v'; then \
			ENV=production; \
		else \
			ENV=staging; \
		fi; \
		echo "ENV not specified, defaulting to $$ENV based on tag format"; \
	fi; \
	if [ ! -f "config/helm/$$ENV.yaml" ]; then \
		echo "Error: config/helm/$$ENV.yaml does not exist"; exit 1; \
	fi; \
	echo "Updating image tag in config/helm/$$ENV.yaml to $$TAG"; \
	yq e -i '.backend.tag = "$(TAG)"' config/helm/$$ENV.yaml; \
	yq e -i '.frontend.tag = "$(TAG)"' config/helm/$$ENV.yaml; \
	echo "Image tags updated successfully for $$ENV environment"
