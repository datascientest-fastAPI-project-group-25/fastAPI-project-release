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
