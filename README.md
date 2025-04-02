# FastAPI Project Release

This repository contains the Kubernetes manifests, Helm charts, and Argo CD configurations for deploying the FastAPI application.

## Repository Structure

```
.
├── charts/                    # Helm charts
│   └── fastapi/              # FastAPI application Helm chart
│       ├── Chart.yaml        # Chart metadata
│       ├── values.yaml       # Default values
│       └── templates/        # Helm templates
│           ├── _helpers.tpl
│           ├── backend-deployment.yaml
│           ├── configmap.yaml
│           ├── frontend-deployment.yaml
│           ├── ingress.yaml
│           ├── postgres-statefulset.yaml
│           └── services.yaml
├── config/                   # Environment-specific configurations
│   ├── argocd/              # Argo CD Application manifests
│   │   ├── staging.yaml     # Staging environment
│   │   └── production.yaml  # Production environment
│   └── helm/                # Environment-specific Helm values
│       ├── values.yaml      # Default values (development)
│       ├── staging.yaml     # Staging environment
│       └── production.yaml  # Production environment
└── manifests/               # Raw Kubernetes manifests (reference)
```

## Prerequisites

- Kubernetes cluster
- Argo CD installed
- GitHub Container Registry access
- Helm v3

## Environment Overview

### Development
- Branch: `main`
- Values: `config/helm/values.yaml`
- Features:
  - Debug mode enabled
  - Minimal resources
  - Local development optimized

### Staging
- Branch: `stg`
- Values: `config/helm/staging.yaml`
- Features:
  - Debugging enabled
  - Moderate resource limits
  - Automated deployments
  - Single replica per service

### Production
- Branch: `main`
- Values: `config/helm/production.yaml`
- Features:
  - Debugging disabled
  - High resource limits
  - Multiple replicas
  - Autoscaling enabled
  - Enhanced security
  - TLS enabled

## Deployment Process

1. Images are built and pushed to GitHub Container Registry (ghcr.io/datascientest-fastapi-project-group-25)
2. CI pipeline updates image tags in the appropriate values file
3. Argo CD detects changes and syncs the application

### Initial Setup

1. Install Argo CD:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. Configure GitHub Container Registry credentials:
   ```bash
   kubectl create secret docker-registry ghcr-secret \
     --docker-server=ghcr.io \
     --docker-username=<github-username> \
     --docker-password=<github-pat> \
     --namespace=fastapi-helm
   ```

3. Apply Argo CD applications:
   ```bash
   # For staging
   kubectl apply -f config/argocd/staging.yaml

   # For production
   kubectl apply -f config/argocd/production.yaml
   ```

## Configuration

### Image Tags
- Development: `dev-latest` or `dev-[commit-sha]`
- Staging: `staging-latest` or `staging-[commit-sha]`
- Production: `production-latest` or `production-[commit-sha]`

### Resource Configurations

#### Development
```yaml
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

#### Staging
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi
```

#### Production
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1024Mi
  requests:
    cpu: 500m
    memory: 512Mi
```

## Security Considerations

- All secrets should be managed through AWS Secrets Manager
- Debug mode is disabled in production
- Network policies restrict pod communication
- TLS is enabled for production ingress
- Pods run as non-root users
- Resource limits are enforced
- HPA ensures proper scaling

## Monitoring

- Kubernetes metrics
- Application health checks
- Resource utilization
- Autoscaling behavior
- Deployment status through Argo CD UI

## Contributing

1. Create a new branch from the target environment branch
2. Make changes to the appropriate values file
3. Create a pull request
4. After review and approval, changes will be deployed automatically

## Support

For issues or questions, please contact DataScientest Group 25:
- GitHub: [datascientest-fastapi-project-group-25](https://github.com/datascientest-fastapi-project-group-25)
