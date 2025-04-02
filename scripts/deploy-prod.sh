#!/bin/bash

# Delete existing resources to avoid conflicts
echo "Cleaning up existing resources in fastapi-prod namespace..."
kubectl delete -n fastapi-prod deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found

# Create namespace if it doesn't exist
kubectl create namespace fastapi-prod --dry-run=client -o yaml | kubectl apply -f -

# Install/upgrade the Helm chart
echo "Installing Helm chart for PRODUCTION environment..."
helm upgrade --install fastapi-prod ./charts/fastapi \
  -f ./config/helm/production.yaml \
  --namespace fastapi-prod \
  --create-namespace \
  --timeout 5m \
  --force \
  --debug

echo "Deployment to PRODUCTION environment complete!"
echo "Setting up port forwarding..."
echo "Run these commands to access the application:"
echo "kubectl port-forward -n fastapi-prod service/backend-service 8000:8000 --address 0.0.0.0"
echo "kubectl port-forward -n fastapi-prod service/frontend-service 80:80 --address 0.0.0.0"