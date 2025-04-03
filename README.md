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
│           ├── services.yaml
│           └── db-init-script-configmap.yaml  # Database initialization and migrations
├── config/                   # Environment-specific configurations
│   ├── argocd/              # Argo CD Application manifests
│   │   ├── staging.yaml     # Staging environment
│   │   ├── production.yaml  # Production environment
│   │   └── playground.yaml  # Playground environment for PRs
│   └── helm/                # Environment-specific Helm values
│       ├── values.yaml      # Default values (development)
│       ├── staging.yaml     # Staging environment
│       ├── production.yaml  # Production environment
│       └── playground.yaml  # Playground environment for PRs
├── scripts/                  # Deployment and maintenance scripts
│   ├── deploy-dev.sh        # Development deployment script
│   ├── deploy-prod.sh       # Production deployment script
│   ├── cleanup.sh           # Environment cleanup script
│   ├── setup-argocd.sh      # ArgoCD setup script
│   └── setup-argocd-integration.sh # ArgoCD CI/CD integration script
└── .github/                 # GitHub Actions workflows
    └── workflows/
        ├── helm-deploy.yml  # Deployment workflow
        ├── helm-test.yml    # Testing workflow
        ├── pr-automation.yml # PR automation workflow
        ├── helm-argocd-test.yml # Helm and ArgoCD testing workflow
        └── argocd-integration.yml # ArgoCD integration workflow
```

## Prerequisites

- Kubernetes cluster
- Argo CD installed
- GitHub Container Registry access
- Helm v3

## Release Strategy

This project follows a streamlined release strategy with feature/fix branches that merge directly into the main branch:

1. **Development Workflow**:
   - Create feature/fix branches from main (`feat/*` or `fix/*`)
   - Push changes to GitHub to automatically create a PR
   - PR triggers tests and validation workflows
   - PR can be deployed to a playground environment for testing
   - After review and approval, merge to main

2. **Deployment Process**:
   - Main branch changes trigger deployment to staging
   - After validation in staging, promote to production
   - ArgoCD manages the deployment process

3. **Environments**:
   - **Playground**: Temporary environment for PR testing
   - **Staging**: Pre-production environment for validation
   - **Production**: Live environment

## Environment Overview

### Playground
- Branch: PR branch (`feat/*` or `fix/*`)
- Values: `config/helm/playground.yaml`
- Features:
  - Debug mode enabled
  - Minimal resources
  - Temporary deployment for PR testing
  - Automatically created and destroyed

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

## Deployment Methods

### Using Scripts

The repository includes several utility scripts to manage deployments:

```bash
# Deploy to development environment
./scripts/deploy-dev.sh

# Deploy to production environment
./scripts/deploy-prod.sh

# Clean up environments
./scripts/cleanup.sh dev    # Clean development environment
./scripts/cleanup.sh prod   # Clean production environment
./scripts/cleanup.sh all    # Clean all environments
```

### Using GitHub Actions

The project uses GitHub Actions for CI/CD with the following workflows:

1. **PR Automation (`pr-automation.yml`)**
   - Triggers on pushes to feature/* and fix/* branches
   - Automatically creates a PR if one doesn't exist
   - Adds appropriate labels and descriptions

2. **Helm and ArgoCD Tests (`helm-argocd-test.yml`)**
   - Triggers on PR creation and updates
   - Validates Helm charts and ArgoCD configurations
   - Runs chart-testing in a Kind cluster
   - Prepares deployment manifests for the playground environment

3. **Helm Chart Test (`helm-test.yml`)**
   - Triggers on pull requests and pushes to main
   - Validates Helm charts
   - Runs chart-testing
   - Tests chart installation in a Kind cluster

4. **Helm Chart Deploy (`helm-deploy.yml`)**
   - Deploys to development, staging, and production environments
   - Supports manual triggering with environment selection
   - Includes validation and verification steps
   - Manages environment-specific configurations

5. **ArgoCD Integration (`argocd-integration.yml`)**
   - Manually triggered workflow for ArgoCD integration
   - Configures ArgoCD applications for different environments
   - Manages deployment synchronization
   - Provides deployment status and URLs

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

3. Set up ArgoCD API key for CI/CD integration:
   ```bash
   # Run the setup script to configure ArgoCD and generate an API key
   ./scripts/setup-argocd.sh
   ```

4. Apply Argo CD applications:
   ```bash
   # For playground environment (PR testing)
   kubectl apply -f config/argocd/playground.yaml

   # For staging
   kubectl apply -f config/argocd/staging.yaml

   # For production
   kubectl apply -f config/argocd/production.yaml
   ```

### ArgoCD Integration

The repository includes scripts and workflows for ArgoCD integration:

1. **Manual Setup**:
   - Use `./scripts/setup-argocd.sh` to install and configure ArgoCD
   - Generate an API key for CI/CD integration
   - Store the API key as a GitHub secret (`ARGOCD_AUTH_TOKEN`)

2. **CI/CD Integration**:
   - The `argocd-integration.yml` workflow configures ArgoCD applications
   - PR branches can be deployed to the playground environment
   - Main branch changes trigger deployment to staging/production

3. **PR Deployments**:
   - When a PR is created, the `helm-argocd-test.yml` workflow prepares deployment manifests
   - ArgoCD can be configured to deploy these manifests to a playground environment
   - Each PR gets its own isolated environment for testing

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
