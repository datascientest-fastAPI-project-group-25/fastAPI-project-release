# Deployment Automation & Argo CD Strategy

## 1. GitHub Release Best Practices

- **Create releases only for production-ready versions.**
- Use tags, commit history, and Argo CD history for staging/non-prod traceability.
- This keeps releases meaningful, aligns with semantic versioning, and avoids clutter.

---

## 2. Automated Helm Update Workflow

- A Makefile target `update-image` accepts `TAG` and `ENV` parameters.
- It updates the appropriate Helm values file (`config/helm/staging.yaml` or `config/helm/production.yaml`) with the new Docker image tag.
- A GitHub Actions workflow:
  - Can be triggered manually or on a schedule.
  - Calls the Makefile target.
  - Commits and pushes the updated Helm values.
  - **Creates a GitHub release only for production deployments.**

This ensures Helm values are automatically updated with the latest image tags immediately after new images are built and pushed, following tagging conventions and environment separation.

---

## 3. Argo CD Multi-Environment Deployment Plan

### Namespace Strategy
- Development: `argocd-dev`
- Staging: `argocd-stg`
- Production: `argocd-prod`

### Local Development Installation
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd-dev \
  --create-namespace \
  --values values-dev.yaml
```

### Promotion Process
- Test in `argocd-dev`
- Promote to `argocd-stg` via GitOps
- Approve and promote to `argocd-prod`

### Security
- RBAC roles: readonly, developer, admin, SRE
- Use sealed-secrets or AWS Secrets Manager
- Environment-specific service accounts

### Monitoring & Backup
- Enable metrics, Prometheus, Grafana
- Backup configs, app definitions, RBAC
- Test restore procedures regularly

### Resource Requirements
```yaml
server:
  requests:
    cpu: 200m
    memory: 256Mi
repo-server:
  requests:
    cpu: 100m
    memory: 256Mi
application-controller:
  requests:
    cpu: 200m
    memory: 256Mi
```

### Implementation Phases
1. **Local Dev:** Setup `argocd-dev`
2. **Staging:** Setup `argocd-stg`, test promotion
3. **Production:** Setup `argocd-prod`, enable backups and advanced security

---