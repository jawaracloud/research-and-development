#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing chaos engineering toolchain..."

# kind - local K8s cluster
curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x /usr/local/bin/kind

# k6 - load testing
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install -y k6

# litmusctl - LitmusChaos CLI
curl -Lo /usr/local/bin/litmusctl \
  https://github.com/litmuschaos/litmusctl/releases/latest/download/litmusctl-linux-amd64
chmod +x /usr/local/bin/litmusctl

# chaos-mesh cli (chaos-mesh ctl)
curl -sSL https://mirrors.chaos-mesh.org/v2.6.3/install.sh | bash -s -- --local kind

# Go tools
go install github.com/onsi/ginkgo/v2/ginkgo@latest
go install github.com/onsi/gomega/...@latest

echo "==> Toolchain installed successfully."
