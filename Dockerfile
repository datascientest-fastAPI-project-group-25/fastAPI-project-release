FROM docker:dind

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    make \
    python3 \
    py3-pip \
    jq

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Set working directory
WORKDIR /app

# Copy the entire project
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Set environment variables
ENV ARGOCD_INSTALL_METHOD=kubectl
ENV DOCKER_HOST=tcp://docker:2375

# Expose ports
EXPOSE 8081-8085

# Default command
CMD ["bash"]