#!/bin/bash

# Delete existing resources to avoid conflicts
echo "Cleaning up existing resources in fastapi-dev namespace..."
kubectl delete -n fastapi-dev deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found

# Create namespace if it doesn't exist
kubectl create namespace fastapi-dev --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade the Helm chart
echo "Installing Helm chart for DEVELOPMENT environment..."
helm upgrade --install fastapi-dev ./charts/fastapi \
  -f ./config/helm/staging.yaml \
  --namespace fastapi-dev \
  --create-namespace \
  --timeout 5m \
  --force \
  --debug

echo "Deployment to DEVELOPMENT environment complete!"
echo "Setting up port forwarding..."
echo "Run these commands to access the application:"
echo "kubectl port-forward -n fastapi-dev service/backend-service 8000:8000 --address 0.0.0.0"
echo "kubectl port-forward -n fastapi-dev service/frontend-service 5173:80 --address 0.0.0.0"