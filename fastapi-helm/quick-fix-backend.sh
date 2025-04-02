#!/bin/bash
set -e

echo "Quick fix for backend deployment in production environment..."

# Force delete the backend deployment
echo "Force deleting backend deployment..."
kubectl delete deployment backend-deployment -n fastapi-helm-prod --force --grace-period=0 --ignore-not-found

# Wait for pods to be fully terminated
echo "Waiting for pods to be fully terminated..."
sleep 5

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
        envFrom:
        - configMapRef:
            name: fastapi-prod-config
        - secretRef:
            name: fastapi-prod-secret
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF

echo "Waiting for backend pod to start..."
sleep 10

# Check the status of the new backend pod
echo "Checking backend pod status..."
kubectl get pods -n fastapi-helm-prod -l app=backend

echo "Setup port forwarding..."
echo "Run this command to access the backend service:"
echo "kubectl port-forward -n fastapi-helm-prod service/backend-service 8002:8000 --address 0.0.0.0"
