#!/bin/bash

# This script sets up a local k3d cluster and installs ArgoCD on it

set -e

# Check if required tools are installed
check_tools() {
  echo "Checking required tools..."

  if ! command -v k3d &> /dev/null; then
    echo "❌ k3d is not installed. Please install it first."
    echo "You can install it with: brew install k3d"
    exit 1
  fi

  if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    echo "You can install it with: brew install kubectl"
    exit 1
  fi

  if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first."
    echo "You can install it with: brew install helm"
    exit 1
  fi

  echo "✅ All required tools are installed."
}

# Create a k3d cluster
create_cluster() {
  echo "Creating k3d cluster 'argocd-cluster'..."

  # Check if cluster already exists
  if k3d cluster list | grep -q "argocd-cluster"; then
    echo "Cluster 'argocd-cluster' already exists."

    # Check if the cluster is running
    if ! k3d cluster list | grep "argocd-cluster" | grep -q "1/1"; then
      echo "Starting cluster 'argocd-cluster'..."
      k3d cluster start argocd-cluster
    fi
  else
    # Create a new cluster
    # Try different ports in case of conflicts
    for port in 8081 8082 8083 8084 8085; do
      echo "Trying to create cluster with port $port..."
      if k3d cluster create argocd-cluster \
        --servers 1 \
        --agents 1 \
        --port "${port}:80@loadbalancer" \
        --wait; then
        # Store the port for later use
        echo $port > /tmp/argocd-cluster-port.txt
        break
      else
        echo "Failed to create cluster with port $port, trying next port..."
        # Clean up any partial cluster creation
        k3d cluster delete argocd-cluster 2>/dev/null || true
      fi
    done

    # Check if cluster was created successfully
    if ! k3d cluster list | grep -q "argocd-cluster"; then
      echo "❌ Failed to create cluster with any of the attempted ports."
      echo "Please check if you have any services running on ports 8081-8085."
      exit 1
    fi
  fi

  # Set kubectl context to the new cluster
  k3d kubeconfig merge argocd-cluster --kubeconfig-switch-context

  echo "✅ k3d cluster 'argocd-cluster' is ready."
}

# Install ArgoCD using Helm
install_argocd_helm() {
  echo "Installing ArgoCD using Helm..."

  # Add ArgoCD Helm repository
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update

  # Create argocd namespace
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

  # Install ArgoCD
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --set server.service.type=LoadBalancer \
    --wait

  echo "✅ ArgoCD installed successfully."
}

# Install ArgoCD using kubectl
install_argocd_kubectl() {
  echo "Installing ArgoCD using kubectl..."

  # Create argocd namespace
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

  # Apply ArgoCD manifests
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  # Patch ArgoCD server to use LoadBalancer
  kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

  # Wait for ArgoCD server to be ready
  echo "Waiting for ArgoCD server to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

  echo "✅ ArgoCD installed successfully."
}

# Get ArgoCD admin password
get_admin_password() {
  echo "Retrieving ArgoCD admin password..."

  # Wait for the secret to be created
  kubectl wait --for=condition=exists -n argocd secret/argocd-initial-admin-secret --timeout=60s

  # Get the password
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

  if [ -z "$ARGOCD_PASSWORD" ]; then
    echo "❌ Failed to retrieve ArgoCD admin password."
    exit 1
  fi

  echo "✅ ArgoCD admin password: $ARGOCD_PASSWORD"
}

# Get ArgoCD server URL
get_server_url() {
  echo "Getting ArgoCD server URL..."

  # Wait for the service to get an external IP
  echo "Waiting for ArgoCD server to get an external IP..."
  kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' --timeout=300s service/argocd-server -n argocd

  # Get the external IP
  ARGOCD_SERVER_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  ARGOCD_SERVER_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].port}')

  # Get the port we used for the cluster
  if [ -f /tmp/argocd-cluster-port.txt ]; then
    CLUSTER_PORT=$(cat /tmp/argocd-cluster-port.txt)
  else
    # Default to 8081 if we can't find the port file
    CLUSTER_PORT=8081
  fi

  if [ -z "$ARGOCD_SERVER_IP" ]; then
    echo "❌ Failed to get ArgoCD server IP."
    echo "Using localhost:$CLUSTER_PORT instead."
    ARGOCD_SERVER_URL="localhost:$CLUSTER_PORT"
  else
    ARGOCD_SERVER_URL="$ARGOCD_SERVER_IP:$ARGOCD_SERVER_PORT"
  fi

  echo "✅ ArgoCD server URL: $ARGOCD_SERVER_URL"
}

# Main function
main() {
  echo "=== Setting up local k3d cluster with ArgoCD ==="
  echo

  # Check required tools
  check_tools

  # Create k3d cluster
  create_cluster

  # Install ArgoCD
  read -p "Install ArgoCD using Helm or kubectl? (helm/kubectl): " install_method
  if [[ $install_method == "helm" ]]; then
    install_argocd_helm
  else
    install_argocd_kubectl
  fi

  # Get ArgoCD admin password
  get_admin_password

  # Get ArgoCD server URL
  get_server_url

  echo
  echo "=== Setup Complete ==="
  echo
  echo "ArgoCD is now running in your local k3d cluster."
  echo
  echo "To access the ArgoCD UI:"
  echo "  URL: https://$ARGOCD_SERVER_URL"
  echo "  Username: admin"
  echo "  Password: $ARGOCD_PASSWORD"
  echo
  echo "To login using the ArgoCD CLI:"
  echo "  argocd login $ARGOCD_SERVER_URL --username admin --password $ARGOCD_PASSWORD --insecure"
  echo
  echo "To generate an API key for CI/CD integration:"
  echo "  argocd account generate-token --account admin"
  echo
  echo "To set up GitHub secrets for ArgoCD integration:"
  echo "  ./scripts/setup-argocd-github.sh"
  echo
}

# Run the main function
main
