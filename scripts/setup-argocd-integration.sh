#!/bin/bash

# This script helps set up ArgoCD integration for CI/CD pipelines
# It should be run from a CI/CD environment with the necessary credentials

# Check if required environment variables are set
if [ -z "$ARGOCD_SERVER" ] || [ -z "$ARGOCD_AUTH_TOKEN" ]; then
    echo "Error: ARGOCD_SERVER and ARGOCD_AUTH_TOKEN environment variables must be set."
    echo "Please set these variables in your CI/CD environment secrets."
    exit 1
fi

# Check if argocd CLI is installed
if ! command -v argocd &> /dev/null; then
    echo "Installing ArgoCD CLI..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd-linux-amd64
    mv argocd-linux-amd64 /usr/local/bin/argocd
fi

# Extract PR number and branch name from GitHub environment
PR_NUMBER=${GITHUB_REF#refs/pull/}
PR_NUMBER=${PR_NUMBER%/merge}
BRANCH_NAME=${GITHUB_HEAD_REF}

if [ -z "$PR_NUMBER" ] || [ -z "$BRANCH_NAME" ]; then
    echo "Error: Could not determine PR number or branch name."
    echo "This script should be run in a GitHub Actions workflow triggered by a pull request."
    exit 1
fi

echo "Setting up ArgoCD integration for PR #$PR_NUMBER from branch $BRANCH_NAME"

# Login to ArgoCD
echo "Logging in to ArgoCD server..."
argocd login --insecure --server $ARGOCD_SERVER --auth-token $ARGOCD_AUTH_TOKEN

# Create a temporary application name for this PR
APP_NAME="fastapi-pr-$PR_NUMBER"
NAMESPACE="fastapi-pr-$PR_NUMBER"

# Check if application already exists
if argocd app get $APP_NAME &> /dev/null; then
    echo "Application $APP_NAME already exists. Updating configuration..."
    
    # Update the application to point to the PR branch
    argocd app set $APP_NAME --repo https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git \
        --path charts/fastapi \
        --revision $BRANCH_NAME \
        --helm-set "app.namespace=$NAMESPACE" \
        --values ../../config/helm/playground.yaml
else
    echo "Creating new application $APP_NAME for PR #$PR_NUMBER..."
    
    # Create a new application for this PR
    argocd app create $APP_NAME \
        --repo https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git \
        --path charts/fastapi \
        --revision $BRANCH_NAME \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace $NAMESPACE \
        --helm-set "app.namespace=$NAMESPACE" \
        --values ../../config/helm/playground.yaml \
        --sync-policy automated \
        --auto-prune \
        --self-heal
fi

# Trigger a sync
echo "Triggering sync for application $APP_NAME..."
argocd app sync $APP_NAME --prune

# Wait for sync to complete
echo "Waiting for sync to complete..."
argocd app wait $APP_NAME --health --timeout 300

# Get the application status
echo "Application status:"
argocd app get $APP_NAME

# Output the URL for accessing the application
echo "Application URL: https://pr-$PR_NUMBER.playground.example.com"
echo "Note: This URL will only work if DNS is properly configured."

echo "ArgoCD integration setup complete!"
