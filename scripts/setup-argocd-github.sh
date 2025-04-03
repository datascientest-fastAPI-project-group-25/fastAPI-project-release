#!/bin/bash

# This script automates the process of setting up ArgoCD, getting the API key,
# and storing it as a GitHub secret for CI/CD integration.

# Usage: ./setup-argocd-github.sh [--skip-k8s-check]
#   --skip-k8s-check: Skip Kubernetes cluster check (for manual API key setup)
#
# This script can also be run using the Makefile:
#   make setup-github
#
# This script can also be run using the Makefile:
#   make setup-github

set -e

# Parse command line arguments
SKIP_K8S_CHECK=false
for arg in "$@"; do
  case $arg in
    --skip-k8s-check)
      SKIP_K8S_CHECK=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Check if required tools are installed
check_tools() {
  echo "Checking required tools..."

  if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
  fi

  if ! command -v argocd &> /dev/null; then
    echo "❌ argocd CLI is not installed. Please install it first."
    echo "You can install it with: brew install argocd"
    exit 1
  fi

  if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed. Please install it first."
    echo "You can install it with: brew install gh"
    exit 1
  fi

  echo "✅ All required tools are installed."
}

# Check if Kubernetes cluster is accessible
check_kubernetes_connection() {
  echo "Checking connection to Kubernetes cluster..."

  if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your cluster configuration."
    echo "Make sure your cluster is running and accessible."
    echo "You can check your current context with: kubectl config current-context"
    echo "You can list available contexts with: kubectl config get-contexts"
    exit 1
  fi

  echo "✅ Successfully connected to Kubernetes cluster."
}

# Check if user is logged in to GitHub
check_github_login() {
  echo "Checking GitHub login status..."

  if ! gh auth status &> /dev/null; then
    echo "❌ You are not logged in to GitHub. Please login first."
    echo "Run: gh auth login"
    exit 1
  fi

  echo "✅ You are logged in to GitHub."
}

# Check if ArgoCD is installed in the cluster
check_argocd_installed() {
  echo "Checking if ArgoCD is installed in the cluster..."

  if kubectl get namespace argocd &> /dev/null; then
    if kubectl get pods -n argocd | grep -q "argocd-server"; then
      echo "✅ ArgoCD is installed in the cluster."
      return 0
    fi
  fi

  echo "❌ ArgoCD is not installed in the cluster."
  return 1
}

# Install ArgoCD in the cluster
install_argocd() {
  echo "Installing ArgoCD in the cluster..."

  kubectl create namespace argocd
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  echo "Waiting for ArgoCD server to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

  echo "✅ ArgoCD installed successfully."
}

# Get the ArgoCD admin password
get_admin_password() {
  echo "Retrieving ArgoCD admin password..."

  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

  if [ -z "$ARGOCD_PASSWORD" ]; then
    echo "❌ Failed to retrieve ArgoCD admin password."
    exit 1
  fi

  echo "✅ ArgoCD admin password retrieved successfully."
}

# Port-forward ArgoCD server
port_forward_argocd() {
  echo "Port-forwarding ArgoCD server to localhost:8080..."

  # Kill any existing port-forward processes
  pkill -f "kubectl port-forward svc/argocd-server" || true

  # Start port-forwarding in the background
  kubectl port-forward svc/argocd-server -n argocd 8080:443 &
  PORT_FORWARD_PID=$!

  # Wait for port-forward to be ready
  sleep 5

  echo "✅ ArgoCD server port-forwarded to localhost:8080."
}

# Login to ArgoCD
login_argocd() {
  echo "Logging in to ArgoCD..."

  argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure

  if [ $? -ne 0 ]; then
    echo "❌ Failed to login to ArgoCD."
    exit 1
  fi

  echo "✅ Successfully logged in to ArgoCD."
}

# Generate ArgoCD API key
generate_api_key() {
  echo "Generating ArgoCD API key..."

  API_KEY=$(argocd account generate-token --account admin)

  if [ -z "$API_KEY" ]; then
    echo "❌ Failed to generate ArgoCD API key."
    exit 1
  fi

  echo "✅ ArgoCD API key generated successfully."
}

# Store API key as GitHub secret
store_github_secret() {
  echo "Storing ArgoCD API key as GitHub secret..."

  # Get the repository name
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

  if [ -z "$REPO" ]; then
    echo "❌ Failed to get repository name."
    exit 1
  fi

  # Store the API key as a GitHub secret
  echo "$API_KEY" | gh secret set ARGOCD_AUTH_TOKEN -R "$REPO"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to store ArgoCD API key as GitHub secret."
    exit 1
  fi

  echo "✅ ArgoCD API key stored as GitHub secret 'ARGOCD_AUTH_TOKEN'."
}

# Store ArgoCD server URL as GitHub secret
store_server_url() {
  echo "Storing ArgoCD server URL as GitHub secret..."

  # Get the repository name
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

  # Get the ArgoCD server URL
  read -p "Enter the ArgoCD server URL (e.g., https://argocd.example.com): " ARGOCD_SERVER

  # Store the server URL as a GitHub secret
  echo "$ARGOCD_SERVER" | gh secret set ARGOCD_SERVER -R "$REPO"

  if [ $? -ne 0 ]; then
    echo "❌ Failed to store ArgoCD server URL as GitHub secret."
    exit 1
  fi

  echo "✅ ArgoCD server URL stored as GitHub secret 'ARGOCD_SERVER'."
}

# Clean up
cleanup() {
  echo "Cleaning up..."

  if [ -n "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID
    echo "✅ Port-forward process terminated."
  fi
}

# Main function
main() {
  echo "=== ArgoCD GitHub Integration Setup ==="
  echo

  # Check required tools
  check_tools

  # Check GitHub login
  check_github_login

  # Check if we should skip Kubernetes checks
  if [ "$SKIP_K8S_CHECK" = false ]; then
    # Check Kubernetes connection
    check_kubernetes_connection

    # Check if ArgoCD is installed
    if ! check_argocd_installed; then
      read -p "ArgoCD is not installed. Would you like to install it? (y/n): " install_choice
      if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
        install_argocd
      else
        echo "❌ ArgoCD is required for this setup. Exiting."
        exit 1
      fi
    fi

    # Get ArgoCD admin password
    get_admin_password

    # Port-forward ArgoCD server
    port_forward_argocd

    # Login to ArgoCD
    login_argocd

    # Generate API key
    generate_api_key
  else
    echo "Skipping Kubernetes cluster checks as requested."
    echo "You will need to manually provide the ArgoCD API key."

    # Prompt for API key
    read -p "Enter your ArgoCD API token: " API_KEY

    if [ -z "$API_KEY" ]; then
      echo "❌ API key cannot be empty."
      exit 1
    fi
  fi

  # Store API key as GitHub secret
  store_github_secret

  # Store ArgoCD server URL as GitHub secret
  store_server_url

  # Clean up
  if [ "$SKIP_K8S_CHECK" = false ]; then
    cleanup
  fi

  echo
  echo "=== Setup Complete ==="
  echo
  echo "ArgoCD API key and server URL have been stored as GitHub secrets."
  echo "You can now use these secrets in your GitHub Actions workflows."
  echo
  echo "To use the API key in a workflow, add the following to your workflow file:"
  echo
  echo "  env:"
  echo "    ARGOCD_SERVER: \${{ secrets.ARGOCD_SERVER }}"
  echo "    ARGOCD_AUTH_TOKEN: \${{ secrets.ARGOCD_AUTH_TOKEN }}"
  echo
  echo "Then you can use these environment variables with the ArgoCD CLI:"
  echo
  echo "  argocd app list --server \$ARGOCD_SERVER --auth-token \$ARGOCD_AUTH_TOKEN"
  echo
}

# Run the main function
main
