# FastAPI Project Release

Helm-based application delivery configuration for the **DataScientest Group 25
bootcamp team project**. This repository connects application image releases to
Kubernetes desired state. It is shared team work, not a claim that one contributor
built the application or the entire pipeline, or that an AWS deployment is live.

## Three-repository architecture

| Repository | Responsibility |
| --- | --- |
| [app](https://github.com/datascientest-fastAPI-project-group-25/fastAPI-project-app) | FastAPI/React source, tests and frontend/backend images in GHCR |
| **release (here)** | Helm templates, environment values and image-tag update automation |
| [infra](https://github.com/datascientest-fastAPI-project-group-25/fastAPI-project-infra) | Terraform/AWS/EKS, IAM/state, Kubernetes foundations and Argo CD setup |

```text
app image workflows -> GHCR frontend/backend images
                    -> app-release repository_dispatch
release workflow -> release/tag -> Helm value update -> reviewed desired state
Argo CD (defined in infra) -> Helm chart -> Deployments / Services / PostgreSQL
```

For Oluwatoyin Balogun's confirmed infrastructure contribution and commit evidence,
see the [infra contribution section](https://github.com/datascientest-fastAPI-project-group-25/fastAPI-project-infra#contribution-and-team-context).
No personal app or release-pipeline authorship is asserted here.

## What is actually in this tree

| Path | Purpose |
| --- | --- |
| [`charts/fastapi/Chart.yaml`](charts/fastapi/Chart.yaml) | Application chart; no chart dependencies declared |
| [`charts/fastapi/templates/`](charts/fastapi/templates/) | Backend/frontend Deployments, Services, PostgreSQL StatefulSet, ConfigMaps, optional Secret, ingress and HPA |
| [`charts/fastapi/values.yaml`](charts/fastapi/values.yaml) | Chart defaults |
| [`config/helm/`](config/helm/) | `values.yaml`, `values-stg.yaml`, `values-prod.yaml`; targets used by release tag-update automation |
| [`charts/fastapi/values-stg.yaml`](charts/fastapi/values-stg.yaml) / [`values-prod.yaml`](charts/fastapi/values-prod.yaml) | Additional chart-local environment values; do not assume they are synchronised with `config/helm/` |
| [`secrets/`](secrets/) | ExternalSecret manifests, requiring an external-secrets controller/store configuration |
| [App release trigger](.github/workflows/app-release-trigger.yml) | Handles `app-release` dispatch and creates a GitHub release |
| [Helm update workflow](.github/workflows/update-helm.yaml) / [update script](scripts/update_helm_values.sh) | Updates `config/helm/values-*.yaml`; production also updates chart metadata |
| [`scripts/src/commands/deploy/`](scripts/src/commands/deploy/) | Deployment/bootstrap helpers; not read-only validators |

Argo CD source configuration is in the **infra repository**. The old
`config/argocd/` files and shell-script paths from earlier documentation are not
present in this baseline.

## Validate locally without a cluster

```bash
git clone https://github.com/datascientest-fastAPI-project-group-25/fastAPI-project-release.git
cd fastAPI-project-release
```

Prerequisites: Helm for chart checks; Python 3 + PyYAML for plain YAML parsing;
Bun for the small platform unit test. The review used Helm 4.2.3, Python 3.13,
PyYAML 6.0.3 and Bun 1.3.4. These are the exercised tools, not a new project-wide
version policy. No kubeconfig, cloud credentials, image pulls or install scripts
are needed for these commands.

```bash
helm lint charts/fastapi -f config/helm/values.yaml
helm lint charts/fastapi -f config/helm/values-stg.yaml
helm lint charts/fastapi -f config/helm/values-prod.yaml

# Render without installing or exposing rendered configuration in terminal output.
helm template review charts/fastapi -f config/helm/values.yaml > /dev/null
helm template review charts/fastapi -f config/helm/values-stg.yaml > /dev/null
helm template review charts/fastapi -f config/helm/values-prod.yaml > /dev/null

# Inspected, dependency-free unit test; no deployment helper is executed.
bun test scripts/src/core/__tests__/platform.test.ts
```

```bash
python3 - <<'PY'
from pathlib import Path
import subprocess
import yaml
paths = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
files = [Path(p) for p in paths if p.endswith((".yml", ".yaml"))
         and not p.startswith("charts/fastapi/templates/") and not Path(p).is_symlink()]
for path in files:
    list(yaml.safe_load_all(path.read_text()))
print(f"Parsed {len(files)} YAML files (Helm templates excluded)")
PY
```

**Observed at `427ad5d`:** all three Helm lint/render combinations passed (lint
only suggested a chart icon); 18 plain YAML files parsed; the platform test passed
with 1 test and 0 failures. Helm templates are deliberately excluded from raw YAML
parsing and checked by Helm rendering instead.

These checks do **not** validate Kubernetes API schemas, controller reconciliation,
image availability, secrets, database migrations, application startup or a live
Argo CD sync. A renderable chart is not necessarily deployable.

## Known baseline integration gaps

- Infra's ApplicationSet selects `values.${environment}.yaml` relative to
  `charts/fastapi`; this tree uses hyphenated `values-stg.yaml`/`values-prod.yaml`,
  while automation updates `config/helm/`. Agree on a single values source and
  correct the ApplicationSet paths before enabling sync.
- Infra's Argo module creates `argocd-${environment}`, but its ApplicationSet
  template uses `argocd`. Reconcile those namespaces with the installed controller.
- Chart defaults include development credentials. Production values refer to
  external secrets, but those references alone do not prove a secret store or
  controller is configured. Review rendered workloads and their required app
  settings before any installation; never reuse example credentials.
- Historical public revisions contain secret-bearing configuration findings.
  Maintainers should assess rotation and history cleanup separately. This
  documentation change neither rotates credentials nor sanitises Git history.

## Deployment is a separate review gate

Before deployment, maintainers need a selected Kubernetes context, reviewed image
references and registry access, namespace/ingress/storage decisions, working secret
management, and an agreed Argo CD source/value-file mapping. Check rendered
manifests against the target Kubernetes API and exercise application health and
login/CRUD flows in an isolated environment first.

Do not run `make init`, deployment scripts, `helm install`, `kubectl apply`,
cleanup commands or Argo CD sync just to evaluate this repository. They may install
tools, create resources, change credentials or delete data. GitHub release/Helm
update workflows also contain automated merge paths: opening a README-only PR is
not permission to publish releases or merge configuration changes.

## Team documentation and contribution workflow

The following guides preserve the team's operational context. They include older
setup approaches; compare commands and paths with current source before use.

- [Release strategy](docs/release-strategy.md)
- [Release integration](docs/RELEASE_INTEGRATION.md)
- [Quick start](docs/quick-start.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Infrastructure setup](docs/infra-setup-guide.md)
- [Deployment automation](docs/deployment-automation.md)
- [External variables](docs/external-variables.md)
- [Tagging strategy](docs/tagging-strategy.md)
- [Earlier README](https://github.com/datascientest-fastAPI-project-group-25/fastAPI-project-release/blob/427ad5d495457835e62cb15b3b7ae59c06e7cbb5/README.md) — historical reference, not a validated runbook

Create a scoped branch from `main`, validate the affected files, and open a PR for
team review. Keep documentation changes separate from chart, workflow and secret
changes. No merge or deployment is implied by this README review.

For questions, use the [DataScientest Group 25 organisation](https://github.com/datascientest-fastAPI-project-group-25).
