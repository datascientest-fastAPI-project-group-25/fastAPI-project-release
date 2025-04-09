# Project TODO

## Progress Summary
- [x] FastAPI Helm chart scaffolded under `charts/fastapi/`
- [x] ArgoCD application manifests created for dev, staging, prod
- [x] Environment-specific Helm values in `config/helm/` and nested folders
- [x] Deployment automation scripts implemented in `scripts/src/commands/deploy/`
- [x] CI/CD integration scripts for ArgoCD and GitHub secrets
- [x] Dockerfiles for various build/test environments
- [x] Documentation covering container, deployment, and release strategies

## Open Tasks

See [Infrastructure Setup Guide](docs/infra-setup-guide.md) for detailed Terraform instructions to prepare EKS, Redis, Secrets Manager, and External Secrets integration.
- [x] Consolidate Helm environment configs to avoid duplication
- [x] Unify ArgoCD environment configs (choose between `argocd/` and `config/argocd/`)
- [x] Remove or update `TEMP - Repository Structure.md`
- [x] Review placeholder URLs and replace with production-ready domains
- [x] Implement secret management best practices (see docs/infra-setup-guide.md for External Secrets configuration)
- [ ] Add more automated tests for deployment scripts
- [ ] Harden CI/CD pipeline with validation steps

## File Tree
```
.dockerignore
.gitignore
.windsurfrules
bun.lock
docker-compose.yml
Dockerfile
Makefile
package.json
README.md
TEMP - Repository Structure.md
argocd/
├── application-dev.yaml
├── application-prod.yaml
├── application-stg.yaml
└── application.yaml
charts/
└── fastapi/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── _helpers.tpl
        ├── backend-deployment.yaml
        ├── configmap.yaml
        ├── db-init-script-configmap.yaml
        ├── frontend-deployment.yaml
        ├── ingress.yaml
        ├── postgres-statefulset.yaml
        └── services.yaml
config/
├── argocd/
│   ├── production.yaml
│   └── staging.yaml
├── helm/
│   ├── dev.yaml
│   ├── production.yaml
│   ├── staging.yaml
│   ├── values.yaml
│   ├── prod/
│   │   └── values.yaml
│   └── stg/
│       └── values.yaml
docker/
├── argocd-tools.Dockerfile
├── k8s-test.Dockerfile
└── k8s-tools.Dockerfile
docs/
├── container-strategy.md
├── deployment-automation.md
├── dockerfile-spec.md
├── quick-start.md
├── release-strategy.md
└── troubleshooting.md
make/
├── bootstrap.mk
├── branch.mk
├── k8s.mk
└── utils.mk
scripts/
├── .gitignore
├── bun.lock
├── package.json
├── tsconfig.json
└── src/
    ├── commands/
    │   ├── cleanup.ts
    │   ├── branch/
    │   │   ├── create.ts
    │   │   ├── normalize.ts
    │   │   └── __tests__/
    │   │       └── normalizeBranchName.test.ts
    │   └── deploy/
    │       ├── dev.ts
    │       ├── prod.ts
    │       ├── setup-argocd-github.ts
    │       ├── setup-argocd-integration.ts
    │       ├── setup-argocd.ts
    │       └── setup-local-k3d-argocd.ts
    ├── core/
    │   ├── bootstrap.ts
    │   ├── platform.ts
    │   └── __tests__/
    │       └── platform.test.ts
    ├── types/
    │   └── bun-types.d.ts
    └── utils/
        ├── ci.ts
        ├── git.ts
        ├── logger.ts
        ├── prompt.ts
        ├── shell.ts
        └── __tests__/
            └── logger.test.ts
```

## Redundancies
- **Helm configs duplicated**: flat files (`dev.yaml`, `production.yaml`, `staging.yaml`) and nested `prod/values.yaml`, `stg/values.yaml`.
- **ArgoCD configs duplicated**: in `argocd/` and `config/argocd/`.
- **TEMP - Repository Structure.md**: appears outdated or redundant.

## Cleanup Suggestions
- Consolidate Helm environment configs into a single structure (either flat or nested).
- Choose a single location for ArgoCD environment configs.
- Remove or update temporary documentation files.
- Replace any remaining placeholder domains with production URLs.
- Add CI checks to enforce config consistency.