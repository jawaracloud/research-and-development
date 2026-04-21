# WebAssembly Series — Dev Container
# Base: Rust slim-bookworm for a small image with the official rustup setup
FROM rust:1.85-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    pkg-config \
    libssl-dev \
    # Git
    git \
    git-lfs \
    # Binaryen (wasm-opt)
    binaryen \
    # wabt (wat2wasm, wasm2wat)
    wabt \
    # curl / wget / ca-certs for downloads
    curl \
    wget \
    ca-certificates \
    # Debugging / tooling
    lldb \
    gdb \
    valgrind \
    # Process management
    procps \
    # Niceties
    bash-completion \
    less \
    vim \
    jq \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 22 LTS ───────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# ── Create a non-root user (vscode) ──────────────────────────────────────────
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode \
    && chown -R vscode:vscode /usr/local/cargo

USER vscode
ENV HOME=/home/vscode
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH="${CARGO_HOME}/bin:${PATH}"

# ── Rust targets ─────────────────────────────────────────────────────────────
RUN rustup target add wasm32-unknown-unknown \
    && rustup component add \
        rust-analyzer \
        clippy \
        rustfmt \
        llvm-tools-preview

# ── Rust CLI tools ────────────────────────────────────────────────────────────
# Pin versions for reproducibility. Bump when the series content requires newer.
RUN cargo install wasm-pack          --version "0.13.1"  --locked && \
    cargo install wasm-bindgen-cli   --version "0.2.100" --locked && \
    cargo install trunk              --version "0.21.4"  --locked && \
    cargo install cargo-leptos       --version "0.2.34"  --locked && \
    cargo install cargo-generate     --version "0.21.4"  --locked && \
    cargo install sqlx-cli           --version "0.8.3"   --locked \
        --no-default-features --features sqlite,postgres && \
    cargo install cargo-watch        --version "8.5.3"   --locked && \
    cargo install twiggy             --version "0.7.0"   --locked && \
    cargo install cargo-expand       --version "1.0.100" --locked && \
    cargo install cargo-nextest      --version "0.9.90"  --locked

# ── Playwright (E2E testing — lesson 83) ─────────────────────────────────────
USER root
RUN npm install -g playwright@latest \
    && npx playwright install-deps chromium \
    && npx playwright install chromium
USER vscode

# ── Shell setup ───────────────────────────────────────────────────────────────
RUN echo 'source /etc/bash_completion' >> /home/vscode/.bashrc && \
    echo 'export PS1="\[\033[1;35m\][wasm-dev]\[\033[0m\] \w $ "' >> /home/vscode/.bashrc

WORKDIR /workspace

# Verify core tools on build (fails loudly if something is missing)
RUN rustc --version && cargo --version && wasm-pack --version && trunk --version && cargo leptos --version
