# eBPF Series — Dev Container
# Base: Ubuntu 24.04 (Noble) — best eBPF kernel support (6.8+)
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG GO_VERSION=1.26rc1

# ── System deps ──────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    pkg-config \
    # Clang/LLVM for compiling eBPF C programs
    clang-18 \
    llvm-18 \
    llvm-18-dev \
    # eBPF userspace library
    libbpf-dev \
    # Kernel headers (for eBPF CO-RE / BTF)
    linux-headers-generic \
    linux-tools-generic \
    linux-tools-common \
    # bpftool (inspect BPF programs and maps)
    linux-tools-$(uname -r 2>/dev/null || echo "generic") \
    # Git, curl, utilities
    git \
    curl \
    wget \
    ca-certificates \
    jq \
    less \
    vim \
    bash-completion \
    # Required for bpf2go / cgo helpers
    libelf-dev \
    zlib1g-dev \
    # For network lessons
    iproute2 \
    tcpdump \
    iputils-ping \
    net-tools \
    # Process monitoring
    procps \
    strace \
    && rm -rf /var/lib/apt/lists/*

# ── Symlink clang-18 as default clang ────────────────────────────────────────
RUN ln -sf /usr/bin/clang-18 /usr/local/bin/clang \
    && ln -sf /usr/bin/llc-18 /usr/local/bin/llc \
    && ln -sf /usr/bin/llvm-strip-18 /usr/local/bin/llvm-strip

# ── bpftool (latest from source if package version is old) ───────────────────
RUN apt-get update && apt-get install -y --no-install-recommends bpftool \
    && rm -rf /var/lib/apt/lists/* \
    || true   # continue if not available in this kernel version

# ── Go 1.26 ──────────────────────────────────────────────────────────────────
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/amd64/;s/arm64/arm64/') && \
    curl -fsSL "https://dl.google.com/go/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
    -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV GOBIN="/go/bin"
ENV PATH="/go/bin:${PATH}"

# ── Go eBPF tools ─────────────────────────────────────────────────────────────
RUN go install github.com/cilium/ebpf/cmd/bpf2go@latest

# ── Non-root user ─────────────────────────────────────────────────────────────
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode \
    && chown -R vscode:vscode /go

USER vscode
ENV HOME=/home/vscode

# Shell prompt
RUN echo 'export PS1="\[\033[1;33m\][ebpf-dev]\[\033[0m\] \w $ "' >> /home/vscode/.bashrc

WORKDIR /workspace

# Verify
RUN go version && clang --version && bpf2go --help 2>&1 | head -3 || true