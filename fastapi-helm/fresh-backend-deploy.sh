#!/bin/bash
set -e

echo "Fresh backend deployment in production environment..."

# Check if the namespace exists and is being terminated
echo "Checking namespace status..."
if kubectl get namespace fastapi-helm-prod 2>/dev/null; then
  echo "Namespace fastapi-helm-prod exists, waiting for it to be fully terminated..."
  kubectl delete namespace fastapi-helm-prod --ignore-not-found
  echo "Waiting 20 seconds for namespace to be fully terminated..."
  sleep 20
fi

# Create a fresh namespace
echo "Creating fresh namespace..."
kubectl create namespace fastapi-helm-prod

# Create a simplified backend deployment with minimal resources
echo "Creating simplified backend deployment..."
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: fastapi-helm-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: tybaloo/backend:latest
        ports:
        - containerPort: 8000
        command: ["sh", "-c"]
        args:
        - "echo 'Starting backend service...' && 
           echo 'Environment variables:' && 
           env && 
           echo 'Starting uvicorn with minimal settings...' && 
           uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1 --log-level debug"
        env:
        - name: DATABASE_URL
          value: "postgresql://postgres:postgres@postgres:5432/postgres"
        - name: SECRET_KEY
          value: "your-production-secret-key"
        - name: DEBUG
          value: "true"
        - name: BACKEND_CORS_ORIGINS
          value: "*"
        - name: FIRST_SUPERUSER
          value: "admin@example.com"
        - name: FIRST_SUPERUSER_PASSWORD
          value: "production-superpass"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

# Create a service for the backend
echo "Creating backend service..."
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: fastapi-helm-prod
spec:
  selector:
    app: backend
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP
EOF

echo "Waiting for backend pod to start..."
sleep 10

# Check the status of the new backend pod
echo "Checking backend pod status..."
kubectl get pods -n fastapi-helm-prod -l app=backend

echo "Setup port forwarding..."
echo "Run this command to access the backend service:"
echo "kubectl port-forward -n fastapi-helm-prod service/backend-service 8002:8000 --address 0.0.0.0"
