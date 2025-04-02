#!/bin/bash
set -e

echo "Fixing production environment deployment..."

# Check node resources
echo "Checking node resources..."
kubectl describe nodes

# Delete existing backend deployment
echo "Removing existing backend deployment..."
kubectl delete -n fastapi-helm-prod deployment/backend-deployment --ignore-not-found

# Apply the simplified backend deployment with reduced resource requirements
echo "Creating simplified backend deployment with reduced resource requirements..."
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
        command: ["uvicorn"]
        args:
        - "app.main:app"
        - "--host"
        - "0.0.0.0"
        - "--port"
        - "8000"
        - "--workers"
        - "1"
        - "--log-level"
        - "debug"
        envFrom:
        - configMapRef:
            name: fastapi-prod-config
        - secretRef:
            name: fastapi-prod-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF

echo "Waiting for backend pod to start..."
sleep 10

# Check the status of the new backend pod
echo "Checking backend pod status..."
kubectl get pods -n fastapi-helm-prod

# Describe the backend pod to check for events
echo "Describing backend pod..."
BACKEND_POD=$(kubectl get pods -n fastapi-helm-prod -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod -n fastapi-helm-prod $BACKEND_POD

# Check the logs of the new backend pod
echo "Checking backend pod logs..."
kubectl logs -n fastapi-helm-prod $BACKEND_POD

echo "Setup port forwarding..."
echo "Run these commands to access the application:"
echo "kubectl port-forward -n fastapi-helm-prod service/backend-service 8002:8000 --address 0.0.0.0"
echo "kubectl port-forward -n fastapi-helm-prod service/frontend-service 5175:80 --address 0.0.0.0"
