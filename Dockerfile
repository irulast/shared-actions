FROM ghcr.io/actions/actions-runner:latest

USER root

# Install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    git-lfs \
    jq \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl + kubectx/kubens
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && curl -L https://github.com/ahmetb/kubectx/releases/latest/download/kubectx -o /usr/local/bin/kubectx \
    && curl -L https://github.com/ahmetb/kubectx/releases/latest/download/kubens -o /usr/local/bin/kubens \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

# Install Helm (for chart testing/validation)
ARG HELM_VERSION=3.14.0
RUN curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar xz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64

# Install flux CLI (optional, for manifest validation)
RUN curl -s https://fluxcd.io/install.sh | bash

# Pre-configure kubectl context (prevents errors)
RUN kubectl config set-context local-cluster --cluster=local \
    && kubectl config use-context local-cluster

USER runner

# Set working directory
WORKDIR /home/runner