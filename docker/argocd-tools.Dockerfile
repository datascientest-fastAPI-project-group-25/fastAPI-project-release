# argocd-tools: Extends k8s-tools with ArgoCD CLI and GitHub CLI

FROM k8s-tools:latest

LABEL maintainer="DataScientest DevOps Team"
LABEL description="Kubernetes tools image with ArgoCD CLI and GitHub CLI for GitOps workflows"

USER root

# Install ArgoCD CLI
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd

# Install GitHub CLI
RUN apk add --no-cache gh openssh gnupg

# Create non-root user again (overridden by root above)
USER k8s

VOLUME ["/home/k8s/.ssh", "/home/k8s/.gnupg", "/home/k8s/.config/argocd"]

ENV ARGOCD_SERVER="" \
    ARGOCD_AUTH_TOKEN="" \
    GITHUB_TOKEN=""

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD argocd version --client || exit 1