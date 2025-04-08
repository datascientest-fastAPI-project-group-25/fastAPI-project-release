# Base Dockerfile Specification

## Overview

This document specifies the requirements and implementation details for our `k8s-tools` base container image. This image serves as the foundation for all our Kubernetes-related operations, ensuring consistent tooling across all environments.

## Base Image Selection

**Image**: `alpine:3.19`
**Rationale**:
- Minimal footprint (~5MB base)
- Official security updates
- Multi-arch support (amd64/arm64)
- Broad compatibility

## Required Tools

### Core Tools
| Tool | Version | Installation Method | Verification |
|------|---------|-------------------|--------------|
| kubectl | Latest stable | Official install script | `kubectl version` |
| helm | Latest stable | Alpine package | `helm version` |
| k3d | Latest stable | Official install script | `k3d version` |
| git | Latest alpine | Alpine package | `git --version` |
| docker CLI | Latest stable | Alpine package | `docker --version` |

### Support Tools
- curl
- bash
- jq
- openssl
- ca-certificates

## Installation Layer Optimization

1. System Packages Layer:
```dockerfile
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    openssl \
    ca-certificates
```

2. Kubernetes Tools Layer:
```dockerfile
# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# k3d
RUN wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

## Security Considerations

### User Configuration
- Create non-root user: `k8s-tools`
- Set appropriate permissions for binary access
- Configure necessary group memberships

### File Permissions
- `/root/.kube`: 700
- `/root/.config/k3d`: 700
- Binary permissions: 755

### Volume Mounts
Specify standard mount points:
```dockerfile
VOLUME ["/root/.kube", "/root/.config/k3d", "/var/run/docker.sock"]
```

## Environment Configuration

### Environment Variables
```dockerfile
ENV KUBECONFIG=/root/.kube/config \
    HELM_CACHE_HOME=/root/.cache/helm \
    K3D_DATA_DIR=/root/.config/k3d \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### Working Directory
```dockerfile
WORKDIR /workspace
```

## Health Check

Include container health check:
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD kubectl version --client || exit 1
```

## Build Arguments

Support for tool version customization:
```dockerfile
ARG KUBECTL_VERSION=latest
ARG HELM_VERSION=latest
ARG K3D_VERSION=latest
```

## Multi-Stage Build

1. Builder Stage:
- Download and verify binaries
- Compile any necessary tools

2. Final Stage:
- Copy verified binaries
- Set up environment
- Configure permissions

## Testing Requirements

Dockerfile must include tests for:
1. Tool installation verification
2. Permission checks
3. Volume mount validation
4. Network connectivity

Test script location: `/usr/local/bin/test-tools`

## Documentation

Include detailed comments in Dockerfile for:
- Tool versions
- Security considerations
- Usage instructions
- Volume mount requirements

## CI Integration

### Build Matrix
- Platforms: linux/amd64, linux/arm64
- Alpine versions: 3.19, edge
- Tool version combinations

### Required Tests
1. Build verification
2. Tool functionality
3. Security scanning
4. Size optimization

## Implementation Notes

1. Image Size Target:
- Base: < 5MB
- Final: < 250MB

2. Build Time Target:
- Clean build: < 5 minutes
- Cached build: < 1 minute

3. Layer Optimization:
- Minimize layer count
- Optimize caching
- Clean up temporary files

## Usage Examples

### Local Development
```bash
docker run --rm -it \
  -v ~/.kube:/root/.kube \
  -v ~/.config/k3d:/root/.config/k3d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  k8s-tools:latest
```

### CI Environment
```bash
docker run --rm \
  -v ${GITHUB_WORKSPACE}/.kube:/root/.kube \
  -v ${GITHUB_WORKSPACE}/k3d:/root/.config/k3d \
  k8s-tools:latest \
  kubectl version