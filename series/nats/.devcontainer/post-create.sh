#!/usr/bin/env bash
set -euo pipefail

echo "==> NATS Series — Post-Create Setup"

# Install NATS CLI
NATS_CLI_VERSION="0.1.5"
curl -sf https://binaries.nats.dev/nats-io/natscli/nats@v${NATS_CLI_VERSION} | sh

# Install nats-server (for local single-node testing)
go install github.com/nats-io/nats-server/v2@latest

# Install nats-top
go install github.com/nats-io/nats-top@latest

# Install k6 for load testing
curl https://github.com/grafana/k6/releases/download/v0.52.0/k6-v0.52.0-linux-amd64.tar.gz \
  -L -o /tmp/k6.tar.gz
tar -xzf /tmp/k6.tar.gz -C /tmp
sudo mv /tmp/k6-v0.52.0-linux-amd64/k6 /usr/local/bin/

# Download Go dependencies
cd /workspaces/research-and-development/nats-series && go mod tidy 2>/dev/null || true

echo "✅ NATS Series dev environment ready"
echo "   nats --version: $(nats --version 2>/dev/null || echo 'installed')"
echo "   nats-server --version: $(nats-server --version 2>/dev/null || echo 'installed')"
