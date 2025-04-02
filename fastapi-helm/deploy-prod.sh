#!/bin/bash
set -e

echo "Deploying FastAPI application to PRODUCTION environment..."

# Delete existing resources to avoid conflicts
echo "Cleaning up existing resources in fastapi-helm-prod namespace..."
kubectl delete -n fastapi-helm-prod deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found

# Create namespace if it doesn't exist
kubectl create namespace fastapi-helm-prod --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade the Helm chart
echo "Installing Helm chart for PRODUCTION environment..."
helm upgrade --install fastapi-prod ./fastapi-helm \
  -f ./fastapi-helm/values-prod.yaml \
  --namespace fastapi-helm-prod \
  --create-namespace \
  --timeout 5m \
  --force \
  --debug

echo "Deployment to PRODUCTION environment complete!"
echo "Setting up port forwarding..."
echo "Run these commands to access the application:"
echo "kubectl port-forward -n fastapi-helm-prod service/backend-service 8002:8000 --address 0.0.0.0"
echo "kubectl port-forward -n fastapi-helm-prod service/frontend-service 5175:80 --address 0.0.0.0"
