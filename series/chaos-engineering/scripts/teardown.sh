#!/usr/bin/env bash
# teardown.sh — Destroy the local kind chaos lab cluster
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-chaos-lab}"

echo "==> Deleting kind cluster: $CLUSTER_NAME"
kind delete cluster --name "$CLUSTER_NAME"
echo "✅  Cluster '$CLUSTER_NAME' deleted."
