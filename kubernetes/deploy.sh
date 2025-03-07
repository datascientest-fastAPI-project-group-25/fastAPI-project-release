#!/bin/bash
set -e

echo "🚀 Starting deployment..."
kubectl create namespace fastapi-app --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f configMap.yml -f secret.yml
kubectl apply -f postgres-statefulset.yml
kubectl apply -f services.yml
kubectl apply -f backend-deployment.yml
kubectl apply -f frontend-deployment.yml
kubectl apply -f ingress.yml

echo "✅ Deployment complete!"
 
 