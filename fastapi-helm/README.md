# FastAPI Application Helm Chart

This Helm chart deploys a FastAPI application with PostgreSQL database and a frontend service on Kubernetes.

## Prerequisites

- Kubernetes cluster (e.g., k3s, minikube, or a cloud provider's Kubernetes service)
- Helm 3.x installed
- kubectl configured to communicate with your cluster

## Components

- **Backend**: FastAPI application
- **Frontend**: Web interface
- **Database**: PostgreSQL 12

## Installation

To install the chart with the release name `fastapi-release`:

```bash
# From the project root directory
./fastapi-helm/deploy-helm.sh
```

This script will:
1. Clean up any existing resources to avoid conflicts
2. Create the namespace if it doesn't exist
3. Install/upgrade the Helm chart
4. Set up port forwarding for the services

## Accessing the Application

After deployment, you can access the application at:

- Backend API: http://localhost:8000
- Frontend: http://localhost:5173

To manually set up port forwarding:

```bash
# For backend
kubectl port-forward -n fastapi-helm service/backend-service 8000:8000 --address 0.0.0.0

# For frontend (in a separate terminal)
kubectl port-forward -n fastapi-helm service/frontend-service 5173:80 --address 0.0.0.0
```

## Configuration

The default configuration values are defined in `values.yaml`. You can customize the deployment by modifying this file or by providing your own values file:

```bash
helm upgrade --install fastapi-release ./fastapi-helm \
  --namespace fastapi-helm \
  --create-namespace \
  --values ./fastapi-helm/values-custom.yaml
```

### Key Configuration Parameters

- **Images**: Configure the Docker images for backend, frontend, and database
- **Replicas**: Set the number of replicas for each component
- **Service Types**: Configure service types (ClusterIP, NodePort, LoadBalancer)
- **Environment Variables**: Set environment variables through ConfigMap and Secrets

## Uninstallation

To uninstall the release:

```bash
./fastapi-helm/cleanup-helm.sh
```

## Troubleshooting

If you encounter issues:

1. Check pod status:
   ```bash
   kubectl get pods -n fastapi-helm
   ```

2. View logs:
   ```bash
   # For backend
   kubectl logs -n fastapi-helm deployment/backend-deployment
   
   # For frontend
   kubectl logs -n fastapi-helm deployment/frontend-deployment
   
   # For database
   kubectl logs -n fastapi-helm statefulset/postgres
   ```

3. Check services:
   ```bash
   kubectl get services -n fastapi-helm
   ```

## Development

For development purposes, you can use the `values-dev.yaml` file which includes:
- Debug mode enabled
- More verbose logging
- Development-specific settings

```bash
helm upgrade --install fastapi-release ./fastapi-helm \
  --namespace fastapi-helm \
  --create-namespace \
  --values ./fastapi-helm/values-dev.yaml
```
What were accomplished in simple terms:

1. Containerization & Organization
Packaged your entire application (backend, frontend, and database) into a single Helm chart
Renamed from fastapi-app to fastapi-helm for better clarity
Created proper templates for all components
2. Problem Solving
Fixed PostgreSQL version issues by using version 12 instead of the latest
Corrected service naming from postgres-service to postgres
Resolved backend initialization problems with a Python-based connectivity check
Fixed backend stability by using a single worker configuration
3. Deployment Automation
Created scripts for easy deployment (deploy-helm.sh)
Added cleanup functionality (cleanup-helm.sh)
Implemented proper documentation in README.md
4. Production Readiness
Added proper health checks and startup probes
Set appropriate resource limits
Ensured all components can communicate with each other
Verified functionality through port forwarding

to visualize and manage your Helm charts and releases:

1. Kubernetes Dashboard
You can install the Kubernetes Dashboard to visualize your Kubernetes resources, including those created by Helm:

bash

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
After installation, you can access it by:

bash

kubectl proxy
Then visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

To connect to the Kubernetes Dashboard, you need to create a service account token. Here's how to do it:

First, create a service account and cluster role binding:
bash
CopyInsert
# Create a service account
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard

# Create a cluster role binding
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
Get the token for the service account:
bash
CopyInsert
# For newer Kubernetes versions (v1.24+)
kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h
Copy the token that's output from the command above.
In the Kubernetes Dashboard login screen:
Select the "Token" option
Paste the token you copied
Click "Sign in"