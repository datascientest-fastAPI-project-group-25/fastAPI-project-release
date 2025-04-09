# k8s-test: Extends k8s-tools with Bun, Node.js, TypeScript, and kind for testing

FROM k8s-tools:latest

LABEL maintainer="DataScientest DevOps Team"
LABEL description="Kubernetes tools image with Bun, Node.js, TypeScript, and kind for testing and CI"

USER root

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Install Node.js and npm, then global TypeScript tooling
RUN apk add --no-cache nodejs npm && \
    npm install -g typescript ts-node

# Install kind (Kubernetes in Docker)
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
    chmod +x ./kind && mv ./kind /usr/local/bin/kind

USER k8s

WORKDIR /workspace/tests

VOLUME ["/workspace/tests", "/workspace/coverage"]

ENV BUN_VERSION=latest \
    TEST_CLUSTER_NAME=test-cluster \
    NODE_ENV=test

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD bun --version && kind version || exit 1