#!/bin/bash
set -e

echo "Deploying FastAPI application to RELEASE environment..."

# Delete existing resources to avoid conflicts
echo "Cleaning up existing resources in fastapi-helm-release namespace..."
kubectl delete -n fastapi-helm-release deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found

# Create namespace if it doesn't exist
kubectl create namespace fastapi-helm-release --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade the Helm chart
echo "Installing Helm chart for RELEASE environment..."
helm upgrade --install fastapi-release ./fastapi-helm \
  -f ./fastapi-helm/values-release.yaml \
  --namespace fastapi-helm-release \
  --create-namespace \
  --timeout 5m \
  --force \
  --debug

echo "Deployment to RELEASE environment complete!"
echo "Setting up port forwarding..."
echo "Run these commands to access the application:"
echo "kubectl port-forward -n fastapi-helm-release service/backend-service 8001:8000 --address 0.0.0.0"
echo "kubectl port-forward -n fastapi-helm-release service/frontend-service 5174:80 --address 0.0.0.0"
