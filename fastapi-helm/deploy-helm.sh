#!/bin/bash

# Delete existing resources to avoid conflicts
echo "Cleaning up existing resources..."
kubectl delete -n fastapi-helm deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found

# Create namespace if it doesn't exist
kubectl create namespace fastapi-helm --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade the Helm chart
echo "Installing Helm chart..."
helm upgrade --install fastapi-release ./fastapi-helm \
  --namespace fastapi-helm \
  --create-namespace \
  --timeout 5m \
  --force \
  --debug

# Set up port forwarding for the services
echo "Setting up port forwarding..."
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:5173"

# You can uncomment these lines to automatically set up port forwarding
# kubectl port-forward -n fastapi-helm service/backend-service 8000:8000 --address 0.0.0.0 &
# kubectl port-forward -n fastapi-helm service/frontend-service 5173:80 --address 0.0.0.0 &
