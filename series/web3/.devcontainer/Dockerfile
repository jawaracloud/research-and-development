# Web3 Ecosystem Series (Go + Rust)
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION=1.26rc1
ARG RUST_VERSION=1.84.0

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    git \
    curl \
    wget \
    ca-certificates \
    jq \
    less \
    vim \
    bash-completion \
    software-properties-common \
    libudev-dev \
    libssl-dev \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Go 1.26
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/amd64/;s/arm64/arm64/') && \
    curl -fsSL "https://dl.google.com/go/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV GOBIN="/go/bin"
ENV PATH="/go/bin:${PATH}"

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
ENV PATH="/root/.cargo/bin:${PATH}"

# Foundry (EVM tooling)
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Node.js (for Anchor and Web3.js fallback scripts)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Solana CLI
RUN sh -c "$(curl -sSfL https://release.solana.com/v1.18.11/install)"
ENV PATH="/root/.local/share/solana/install/active_release/bin:${PATH}"

# Anchor CLI
RUN cargo install --git https://github.com/coral-xyz/anchor avm --locked --force && \
    avm install latest && \
    avm use latest

# Kubo (IPFS Go Node)
RUN wget https://dist.ipfs.tech/kubo/v0.32.1/kubo_v0.32.1_linux-amd64.tar.gz && \
    tar -xvzf kubo_v0.32.1_linux-amd64.tar.gz && \
    cd kubo && ./install.sh && \
    cd .. && rm -rf kubo*

# Non-root user
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode --shell /bin/bash \
    && chown -R vscode:vscode /go

# Symlinks so vscode user can use root-installed tools
RUN ln -s /root/.foundry /home/vscode/.foundry && \
    ln -s /root/.cargo /home/vscode/.cargo && \
    ln -s /root/.rustup /home/vscode/.rustup && \
    chown -R vscode:vscode /home/vscode

USER vscode
ENV HOME=/home/vscode
ENV PATH="/home/vscode/.cargo/bin:/home/vscode/.foundry/bin:${PATH}"
RUN echo 'export PATH=$PATH:/usr/local/go/bin:/go/bin:~/.cargo/bin:~/.foundry/bin:~/.local/share/solana/install/active_release/bin' >> ~/.bashrc

# Shell prompt
RUN echo 'export PS1="\[\033[1;35m\][web3-dev]\[\033[0m\] \w $ "' >> /home/vscode/.bashrc

WORKDIR /workspace

# Verify
RUN go version && cargo --version && forge --version && solana --version && ipfs --version || true
