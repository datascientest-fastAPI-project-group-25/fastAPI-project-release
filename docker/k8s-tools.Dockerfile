# k8s-tools: Base image with Kubernetes CLI tools

FROM alpine:3.19

LABEL maintainer="DataScientest DevOps Team"
LABEL description="Base image with kubectl, helm, k3d, git, docker CLI for portable Kubernetes workflows"

# Build arguments for tool versions (default to latest stable)
ARG KUBECTL_VERSION
ARG HELM_VERSION
ARG K3D_VERSION

# Environment variables
ENV KUBECONFIG=/root/.kube/config \
    HELM_CACHE_HOME=/root/.cache/helm \
    K3D_DATA_DIR=/root/.config/k3d \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /workspace

# Install core packages
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    openssl \
    ca-certificates \
    docker-cli

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k3d
RUN wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create non-root user for security
RUN adduser -D -u 1000 k8s && \
    mkdir -p /home/k8s/.kube /home/k8s/.config/k3d && \
    chown -R k8s:k8s /home/k8s

USER k8s

VOLUME ["/home/k8s/.kube", "/home/k8s/.config/k3d", "/var/run/docker.sock"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD kubectl version --client || exit 1