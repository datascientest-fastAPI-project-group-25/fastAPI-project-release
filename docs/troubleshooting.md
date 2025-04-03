# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when using the release strategy, ArgoCD, and k3d.

## GitHub Actions Workflow Issues

### PR Automation Workflow Fails

**Issue**: The PR automation workflow fails when pushing a branch.

**Solution**:
1. Check if you have the correct branch naming convention (`feat/*` or `fix/*`)
2. Verify that the GitHub token has the necessary permissions
3. Create the PR manually if needed:
   ```bash
   gh pr create --title "Your PR title" --body "Your PR description" --base main
   ```

### Helm and ArgoCD Tests Workflow Fails

**Issue**: The Helm and ArgoCD tests workflow fails.

**Solution**:
1. Check if your Helm charts are valid:
   ```bash
   helm lint ./charts/fastapi -f ./config/helm/staging.yaml
   ```
2. Verify that the ArgoCD configuration is correct:
   ```bash
   kubectl apply --dry-run=client -f config/argocd/staging.yaml
   ```
3. Make sure all required files have newlines at the end
4. Check for YAML formatting issues

## ArgoCD Issues

### Cannot Login to ArgoCD

**Issue**: Unable to login to ArgoCD.

**Solution**:
1. Reset the admin password:
   ```bash
   kubectl -n argocd patch secret argocd-initial-admin-secret \
     -p '{"stringData": {"password": "admin"}}'
   ```
2. Restart the ArgoCD server:
   ```bash
   kubectl rollout restart deployment argocd-server -n argocd
   ```
3. Try logging in again with username `admin` and password `admin`

### Cannot Generate ArgoCD API Key

**Issue**: Unable to generate an ArgoCD API key.

**Solution**:
1. Update the ArgoCD configuration to enable API key generation:
   ```bash
   kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data": {"accounts.admin": "apiKey"}}'
   ```
2. Restart the ArgoCD server:
   ```bash
   kubectl rollout restart deployment argocd-server -n argocd
   ```
3. Try generating the API key again:
   ```bash
   argocd account generate-token --account admin
   ```

### Application Not Syncing

**Issue**: ArgoCD application is not syncing.

**Solution**:
1. Check the application status:
   ```bash
   argocd app get <app-name>
   ```
2. Check for sync errors:
   ```bash
   argocd app logs <app-name>
   ```
3. Force a sync:
   ```bash
   argocd app sync <app-name> --force
   ```

## k3d Issues

### Cluster Creation Fails

**Issue**: k3d cluster creation fails.

**Solution**:
1. Check if there are any existing clusters:
   ```bash
   k3d cluster list
   ```
2. Delete existing cluster if needed:
   ```bash
   k3d cluster delete <cluster-name>
   ```
3. Try creating with a different port:
   ```bash
   k3d cluster create argocd-cluster --servers 1 --agents 1 --port 8082:80@loadbalancer
   ```

### Port Conflict

**Issue**: Port conflict when creating a k3d cluster.

**Solution**:
1. Find which process is using the port:
   ```bash
   lsof -i :<port>
   ```
2. Stop the process or use a different port:
   ```bash
   k3d cluster create argocd-cluster --servers 1 --agents 1 --port <different-port>:80@loadbalancer
   ```

## Helm Chart Issues

### Helm Chart Validation Fails

**Issue**: Helm chart validation fails.

**Solution**:
1. Check the chart for syntax errors:
   ```bash
   helm lint ./charts/fastapi
   ```
2. Validate the values files:
   ```bash
   helm lint ./charts/fastapi -f ./config/helm/staging.yaml
   ```
3. Check for common issues:
   - Missing newlines at the end of files
   - Invalid YAML formatting
   - Type mismatches in values

### Chart Installation Fails

**Issue**: Helm chart installation fails.

**Solution**:
1. Check the chart dependencies:
   ```bash
   helm dependency update ./charts/fastapi
   ```
2. Validate the chart:
   ```bash
   helm template ./charts/fastapi -f ./config/helm/staging.yaml
   ```
3. Check for resource conflicts or missing resources

## Need More Help?

If you're still experiencing issues, please open an issue on the repository or contact the team for assistance.
