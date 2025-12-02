# BuildKit Builder Image
# A general-purpose CI/CD builder image with BuildKit for container builds
# and common tools needed for GitHub Actions workflows.
# Replaces Kaniko with the actively maintained BuildKit project.

# Stage 1: Get BuildKit binaries from official rootless image
FROM moby/buildkit:v0.18.2-rootless AS buildkit

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
    make \
    # Required for rootless buildkit
    shadow-uidmap

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

# Copy BuildKit binaries from official image
COPY --from=buildkit /usr/bin/buildctl /usr/local/bin/buildctl
COPY --from=buildkit /usr/bin/buildkitd /usr/local/bin/buildkitd
COPY --from=buildkit /usr/bin/buildctl-daemonless.sh /usr/local/bin/buildctl-daemonless.sh

# Make buildkit binaries executable
RUN chmod +x /usr/local/bin/buildctl \
    /usr/local/bin/buildkitd \
    /usr/local/bin/buildctl-daemonless.sh

# Create directories for buildkit
# Running as root, so use /root for home and /run/buildkit for socket
RUN mkdir -p /root/.local/share/buildkit \
    /root/.docker \
    /run/buildkit

# Set up git safe directory for GitHub Actions workspace
RUN git config --global --add safe.directory '*'

# Environment variables
# DOCKER_CONFIG points to where registry credentials are mounted
ENV DOCKER_CONFIG=/root/.docker
# --oci-worker-no-process-sandbox is required for containerized BuildKit
ENV BUILDKITD_FLAGS="--oci-worker-no-process-sandbox"
ENV HOME=/root

# Set working directory
WORKDIR /workspace

# Run as root - BuildKit daemonless mode works best as root in containers
# since rootless mode requires user namespaces which K8s often doesn't allow.
# Root can access workspace files created by ARC runner (UID 1001).
USER root

# Default entrypoint (can be overridden)
ENTRYPOINT ["/bin/sh", "-c"]