#!/bin/bash

# This script helps set up ArgoCD and obtain an API key for CI/CD integration

# Check if argocd CLI is installed
if ! command -v argocd &> /dev/null; then
    echo "ArgoCD CLI is not installed. Please install it first."
    echo "Follow instructions at: https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

# Function to check if ArgoCD is installed in the cluster
check_argocd_installed() {
    if kubectl get namespace argocd &> /dev/null; then
        echo "ArgoCD namespace exists."
        if kubectl get pods -n argocd | grep -q "argocd-server"; then
            echo "ArgoCD is installed in the cluster."
            return 0
        fi
    fi
    echo "ArgoCD is not installed in the cluster."
    return 1
}

# Function to install ArgoCD
install_argocd() {
    echo "Installing ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "Waiting for ArgoCD server to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    echo "ArgoCD installed successfully."
}

# Function to get the ArgoCD admin password
get_admin_password() {
    echo "Retrieving ArgoCD admin password..."
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "Admin password: $ARGOCD_PASSWORD"
    return 0
}

# Function to port-forward ArgoCD server
port_forward_argocd() {
    echo "Port-forwarding ArgoCD server to localhost:8080..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &
    PORT_FORWARD_PID=$!
    echo "Port-forward process ID: $PORT_FORWARD_PID"
    
    # Wait for port-forward to be ready
    sleep 5
    
    return 0
}

# Function to login to ArgoCD
login_argocd() {
    local password=$1
    echo "Logging in to ArgoCD..."
    argocd login localhost:8080 --username admin --password "$password" --insecure
    
    if [ $? -eq 0 ]; then
        echo "Successfully logged in to ArgoCD."
        return 0
    else
        echo "Failed to login to ArgoCD."
        return 1
    fi
}

# Function to create an API key
create_api_key() {
    echo "Creating ArgoCD API key..."
    API_KEY=$(argocd account generate-token --account admin)
    
    if [ -n "$API_KEY" ]; then
        echo "API key created successfully."
        echo "API Key: $API_KEY"
        echo "Please save this API key securely. It will be used for CI/CD integration."
        echo "You should add this as a secret in your GitHub repository."
        return 0
    else
        echo "Failed to create API key."
        return 1
    fi
}

# Function to clean up
cleanup() {
    echo "Cleaning up..."
    if [ -n "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID
        echo "Port-forward process terminated."
    fi
}

# Main execution
echo "ArgoCD Setup Script"
echo "==================="

# Check if ArgoCD is installed
if ! check_argocd_installed; then
    read -p "ArgoCD is not installed. Would you like to install it? (y/n): " install_choice
    if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
        install_argocd
    else
        echo "Exiting as ArgoCD is required."
        exit 1
    fi
fi

# Get admin password
get_admin_password

# Port-forward ArgoCD server
port_forward_argocd

# Login to ArgoCD
login_argocd "$ARGOCD_PASSWORD"
if [ $? -ne 0 ]; then
    cleanup
    exit 1
fi

# Create API key
create_api_key

# Clean up
cleanup

echo "Setup completed successfully."
