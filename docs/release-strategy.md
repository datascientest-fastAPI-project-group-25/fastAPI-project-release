# Release Strategy Documentation

This document provides a comprehensive guide to the release strategy implemented in this repository, including how to set up and use ArgoCD and k3d for local development and testing.

## Table of Contents

1. [Overview](#overview)
2. [Branch Strategy](#branch-strategy)
3. [PR Automation](#pr-automation)
4. [Environment Setup](#environment-setup)
5. [ArgoCD Integration](#argocd-integration)
6. [Local Development with k3d](#local-development-with-k3d)
7. [Troubleshooting](#troubleshooting)

## Overview

Our release strategy follows a streamlined approach with feature/fix branches that merge directly into the main branch. The process is automated using GitHub Actions workflows that handle PR creation, testing, and deployment preparation.

### Key Components

- **PR Automation**: Automatically creates PRs when pushing to feature/fix branches
- **Helm and ArgoCD Testing**: Validates Helm charts and ArgoCD configurations
- **ArgoCD Integration**: Manages deployments to different environments
- **Local Development**: Uses k3d for local Kubernetes development and testing

## Branch Strategy

We follow a simple branch strategy:

1. **Main Branch (`main`)**: The primary branch that represents the production-ready code
2. **Feature Branches (`feat/*`)**: Used for developing new features
3. **Fix Branches (`fix/*`)**: Used for bug fixes

### Workflow

1. Create a feature or fix branch from `main`
2. Develop and test your changes locally
3. Push your branch to GitHub, which automatically creates a PR
4. The PR triggers tests and validation workflows
5. After review and approval, merge the PR to `main`
6. Changes to `main` trigger deployment to staging
7. After validation in staging, promote to production

## PR Automation

When you push a feature or fix branch to GitHub, our PR automation workflow automatically creates a PR if one doesn't exist.

### How to Use

1. Create a feature or fix branch:
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/your-fix-name
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Your commit message"
   ```

3. Push your branch to GitHub:
   ```bash
   git push -u origin feat/your-feature-name
   ```

4. The PR automation workflow will create a PR automatically

## Environment Setup

We use two environments for our deployment pipeline:

1. **Staging**: Pre-production environment for validation
2. **Production**: Live environment

### Configuration Files

- **Staging**: `config/helm/staging.yaml` and `config/argocd/staging.yaml`
- **Production**: `config/helm/production.yaml` and `config/argocd/production.yaml`

## ArgoCD Integration

ArgoCD is used for GitOps-based deployments to our Kubernetes clusters.

### Setting Up ArgoCD

#### Prerequisites

- kubectl
- argocd CLI
- GitHub CLI (gh)

#### Installation

1. Set up a Kubernetes cluster (see [Local Development with k3d](#local-development-with-k3d) for local setup)

2. Install ArgoCD:
   ```bash
   ./scripts/setup-local-k3d-argocd.sh
   ```

3. Set up ArgoCD API key and GitHub secrets:
   ```bash
   ./scripts/setup-argocd-github.sh
   ```

### Manual Deployment

To manually deploy using ArgoCD:

1. Login to ArgoCD:
   ```bash
   argocd login <argocd-server> --username admin --password <password>
   ```

2. Create an application:
   ```bash
   argocd app create <app-name> \
     --repo https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git \
     --path charts/fastapi \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace <namespace> \
     --values ../../config/helm/<environment>.yaml
   ```

3. Sync the application:
   ```bash
   argocd app sync <app-name>
   ```

## Local Development with k3d

k3d is a lightweight Kubernetes distribution that runs in Docker, perfect for local development and testing.

### Setting Up k3d

1. Install k3d:
   ```bash
   brew install k3d
   ```

2. Create a k3d cluster with ArgoCD:
   ```bash
   ./scripts/setup-local-k3d-argocd.sh
   ```

3. Verify the cluster is running:
   ```bash
   k3d cluster list
   kubectl get nodes
   ```

### Testing Locally

1. Port-forward ArgoCD server:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. Access ArgoCD UI at https://localhost:8080
   - Username: admin
   - Password: (retrieved during setup)

3. Deploy your application:
   ```bash
   argocd app create fastapi-test \
     --repo https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git \
     --path charts/fastapi \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace fastapi-test \
     --values ../../config/helm/playground.yaml
   ```

## Troubleshooting

### Common Issues

#### ArgoCD Login Issues

If you're having trouble logging in to ArgoCD:

```bash
# Reset admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$mivhwttXM0U5eBrZGtAG8.VSRL1l9cZNAmaSaqotIzXRBRwID1NT.",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
```
This resets the password to "admin".

#### k3d Cluster Creation Issues

If you're having trouble creating a k3d cluster:

```bash
# Check if there are any existing clusters
k3d cluster list

# Delete existing cluster if needed
k3d cluster delete <cluster-name>

# Try creating with a different port
k3d cluster create argocd-cluster --servers 1 --agents 1 --port 8082:80@loadbalancer
```

#### GitHub Actions Workflow Failures

If GitHub Actions workflows are failing:

1. Check the workflow logs for specific errors
2. Verify that the required secrets are set up correctly
3. Make sure your Helm charts are valid
4. Ensure that the ArgoCD configuration is correct

For more help, please open an issue on the repository.
