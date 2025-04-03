# Quick Start Guide

This guide provides a quick overview of how to use the release strategy implemented in this repository.

## Getting Started

### Prerequisites

- Git
- kubectl
- Helm
- k3d (for local development)
- ArgoCD CLI
- GitHub CLI (gh)

### Setting Up Your Environment

1. Clone the repository:
   ```bash
   git clone https://github.com/datascientest-fastapi-project-group-25/fastAPI-project-release.git
   cd fastAPI-project-release
   ```

2. Set up a local Kubernetes cluster with ArgoCD:
   ```bash
   ./scripts/setup-local-k3d-argocd.sh
   ```

3. Set up ArgoCD API key and GitHub secrets:
   ```bash
   ./scripts/setup-argocd-github.sh
   ```

### Development Workflow

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

4. A PR will be automatically created, and tests will run

5. After review and approval, merge the PR to `main`

### Accessing Your Deployment

1. Port-forward ArgoCD server:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. Access ArgoCD UI at https://localhost:8080
   - Username: admin
   - Password: (retrieved during setup)

3. View your application deployment

## Additional Resources

- [Full Release Strategy Documentation](./release-strategy.md)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/)
- [k3d Documentation](https://k3d.io/)
