#!/bin/bash
set -e

echo "Deploying FastAPI application to PRODUCTION environment with fixes..."

# Delete existing resources to avoid conflicts
echo "Cleaning up existing resources in fastapi-helm-prod namespace..."
kubectl delete -n fastapi-helm-prod deployment,service,configmap,secret,statefulset,ingress,pvc --all --ignore-not-found

# Create namespace if it doesn't exist
kubectl create namespace fastapi-helm-prod --dry-run=client -o yaml | kubectl apply -f -

# Create a temporary values file with simplified backend configuration
echo "Creating temporary values file with simplified backend configuration..."
cat > ./fastapi-helm/values-prod-temp.yaml << EOF
# Production environment configuration with simplified backend
app:
  namespace: fastapi-helm-prod
  environment: production

backend:
  name: backend
  image: tybaloo/backend
  tag: latest
  replicas: 1  # Reduced to 1 for troubleshooting
  port: 8000
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  service:
    name: backend-service
    port: 8000
    type: ClusterIP

frontend:
  name: frontend
  image: tybaloo/frontend
  tag: latest
  replicas: 2
  port: 80
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
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
    size: 10Gi
  resources:
    requests:
      memory: "512Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "500m"

# ConfigMap values
configMap:
  secretKey: "your-production-secret-key"
  allowedOrigins: "https://app.yourdomain.com,https://api.yourdomain.com"
  debug: "true"  # Enable debug mode
  firstSuperuserPassword: "production-superpass"
  
# Production-specific configuration
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
          serviceName: backend-service
          servicePort: 8000
    - host: app.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
          serviceName: frontend-service
          servicePort: 80
  tls:
    - secretName: api-tls
      hosts:
        - api.yourdomain.com
    - secretName: app-tls
      hosts:
        - app.yourdomain.com
EOF

# Install/upgrade the Helm chart with the temporary values file
echo "Installing Helm chart for PRODUCTION environment with simplified configuration..."
helm upgrade --install fastapi-prod ./fastapi-helm \
  -f ./fastapi-helm/values-prod-temp.yaml \
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
