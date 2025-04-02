#!/bin/bash
set -e

echo "Resetting production environment deployment..."

# Delete the entire namespace to clean up all resources
echo "Deleting fastapi-helm-prod namespace..."
kubectl delete namespace fastapi-helm-prod --ignore-not-found

# Wait for namespace to be fully deleted
echo "Waiting for namespace to be fully deleted..."
sleep 10

# Create a fresh namespace
echo "Creating fresh namespace..."
kubectl create namespace fastapi-helm-prod

# Create a temporary values file with minimal resource requirements
echo "Creating temporary values file with minimal resource requirements..."
cat > ./fastapi-helm/values-prod-minimal.yaml << EOF
# Production environment configuration with minimal resources
app:
  namespace: fastapi-helm-prod
  environment: production

backend:
  name: backend
  image: tybaloo/backend
  tag: latest
  replicas: 1  # Single replica for troubleshooting
  port: 8000
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "128Mi"
      cpu: "100m"
  service:
    name: backend-service
    port: 8000
    type: ClusterIP

frontend:
  name: frontend
  image: tybaloo/frontend
  tag: latest
  replicas: 1  # Reduced to 1 for troubleshooting
  port: 80
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "128Mi"
      cpu: "100m"
  service:
    name: frontend-service
    port: 80
    type: ClusterIP

database:
  name: postgres
  image: postgres
  tag: "12"
  service:
    name: postgres
    port: 5432
  credentials:
    username: postgres
    password: postgres
    database: postgres
  storage:
    size: 1Gi  # Reduced size for troubleshooting
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

# ConfigMap values
configMap:
  secretKey: "your-production-secret-key"
  allowedOrigins: "https://app.yourdomain.com,https://api.yourdomain.com"
  debug: "true"  # Enable debug mode
  firstSuperuserPassword: "production-superpass"
  
# Disable ingress for troubleshooting
ingress:
  enabled: false
EOF

# Install the Helm chart with minimal resource requirements
echo "Installing Helm chart with minimal resource requirements..."
helm upgrade --install fastapi-prod ./fastapi-helm \
  -f ./fastapi-helm/values-prod-minimal.yaml \
  --namespace fastapi-helm-prod \
  --create-namespace \
  --timeout 5m \
  --force \
  --debug

echo "Waiting for pods to start..."
sleep 30

# Check the status of all pods
echo "Checking pod status..."
kubectl get pods -n fastapi-helm-prod

echo "Setup port forwarding..."
echo "Run these commands to access the application:"
echo "kubectl port-forward -n fastapi-helm-prod service/backend-service 8002:8000 --address 0.0.0.0"
echo "kubectl port-forward -n fastapi-helm-prod service/frontend-service 5175:80 --address 0.0.0.0"
