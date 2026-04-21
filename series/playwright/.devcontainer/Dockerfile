# Playwright Series — Dev Container
# Base: official Playwright image (includes all browsers + Node.js 22)
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ARG DEBIAN_FRONTEND=noninteractive

# ── Extra system tools ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    curl \
    wget \
    jq \
    bash-completion \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# ── Java (required by Allure CLI) ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends default-jre \
    && rm -rf /var/lib/apt/lists/*

# ── Global npm tools ──────────────────────────────────────────────────────────
RUN npm install -g \
    typescript \
    ts-node \
    serve \
    @playwright/test \
    allure-commandline \
    http-server

# ── Non-root user ─────────────────────────────────────────────────────────────
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode \
    && chown -R vscode:vscode /home/vscode

USER vscode
ENV HOME=/home/vscode

WORKDIR /workspace

# Shell prompt
RUN echo 'export PS1="\[\033[1;34m\][playwright-dev]\[\033[0m\] \w $ "' >> /home/vscode/.bashrc

# Verify browsers are installed
RUN npx playwright --version
