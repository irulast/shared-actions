# Kaniko Builder Image
# A general-purpose CI/CD builder image with Kaniko for container builds
# and common tools needed for GitHub Actions workflows.

# Stage 1: Get Kaniko executor from official image
FROM gcr.io/kaniko-project/executor:v1.24.0 AS kaniko

# Stage 2: Build the final image
FROM alpine:3.20

# Install essential tools
RUN apk add --no-cache \
    # Version control
    git \
    git-lfs \
    # Shell and utilities
    bash \
    coreutils \
    findutils \
    grep \
    sed \
    # Network tools
    curl \
    wget \
    ca-certificates \
    # JSON/YAML processing
    jq \
    yq \
    # Compression
    gzip \
    tar \
    unzip \
    zip \
    # Build essentials
    make

# Install kubectl
ARG KUBECTL_VERSION=1.31.0
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install Helm
ARG HELM_VERSION=3.16.3
RUN curl -L "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar xz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64

# Copy Kaniko executor from official image
COPY --from=kaniko /kaniko/executor /kaniko/executor
RUN chmod +x /kaniko/executor \
    && ln -s /kaniko/executor /usr/local/bin/executor

# Create kaniko directories (required by Kaniko)
RUN mkdir -p /kaniko/.docker

# Set up git safe directory for GitHub Actions workspace
RUN git config --global --add safe.directory '*'

# Set working directory
WORKDIR /workspace

# Default entrypoint (can be overridden)
ENTRYPOINT ["/bin/sh", "-c"]