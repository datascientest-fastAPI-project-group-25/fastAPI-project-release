# Container Strategy for Deployment, ArgoCD, and Testing

## Overview

This document consolidates the container-based approach for all deployment, GitOps, and testing tooling, ensuring consistent execution across local development, CI environments, and production.

---

## Container Architecture

### 1. Base Image (`k8s-tools`)

- Multi-arch support (amd64/arm64)
- Minimal size (~200MB)
- Tools:
  - kubectl
  - helm
  - k3d
  - git
- Non-root user
- Shared volume mounts for configs

### 2. ArgoCD Tools Image

- Extends `k8s-tools`
- Adds:
  - ArgoCD CLI
  - GitHub CLI
  - GPG, JWT tools
- Security:
  - SSH, GPG key support
  - Token-based auth
  - Secret mounts (`/root/.ssh`, `/root/.gnupg`, `/root/.config/argocd`)
- Auth helpers:
  - ArgoCD login script
  - GitHub login script
- Healthcheck:
  ```dockerfile
  HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD argocd version --client || exit 1
  ```
- Usage:
  - Local: mount kubeconfig, secrets, run CLI
  - CI: pass secrets as env vars, run sync commands

### 3. Test Image

- Extends `k8s-tools`
- Adds:
  - Bun runtime
  - kind (mock clusters)
  - TypeScript, ts-node, node-dev
- Mock cluster setup:
  - kind config with control-plane + worker nodes
  - Bun test hooks to create/teardown clusters
- Healthcheck:
  ```dockerfile
  HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD bun --version && kind version || exit 1
  ```
- Volumes:
  - `/workspace/tests`
  - `/workspace/coverage`
- CI integration:
  - Run Bun tests inside container
  - Mount workspace, pass env vars
- Debugging:
  - Node inspector on port 9229
  - K8s debug tools
- Resource requirements:
  - Min: 1 CPU, 2GB RAM
  - Recommended: 2 CPU, 4GB RAM

---

## Volume Mounts

- `/root/.kube` - kubeconfig
- `/root/.config/k3d` - k3d config
- `/var/run/docker.sock` - Docker socket
- `/root/.ssh`, `/root/.gnupg`, `/root/.config/argocd` - secrets
- `/workspace/tests`, `/workspace/coverage` - test data

---

## Network Configuration

- Host network mode for k3d
- Expose:
  - 8080 (ArgoCD UI)
  - 6443 (Kubernetes API)
  - 9229 (Node debug)

---

## Integration with TypeScript Tools

- Container interface for running commands
- Example: create k3d cluster, deploy with helm, sync with ArgoCD
- Mock clusters for tests

---

## Testing Strategy

- Unit tests: mock container interface
- Integration tests: run in container, real tool execution
- CI tests: multi-arch, containerized, automated

---

## Security Considerations

- Minimal images, non-root
- Secret management via env vars and mounts
- Regular updates and scanning

---

## Implementation Roadmap

1. Base image with k8s tools
2. Extend with ArgoCD CLI and auth
3. Extend with Bun, kind, test tools
4. Integrate with TypeScript commands
5. Automate in CI/CD

---

## Usage Examples

- Local dev: run containers with mounted configs
- CI: run containers with secrets as env vars
- Testing: run Bun tests inside test container

---

## Notes

This unified container strategy replaces previous separate specs for ArgoCD and test containers.