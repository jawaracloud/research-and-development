#!/usr/bin/env bash
# verify-env.sh — Check all required tools for the NATS series
set -euo pipefail

PASS=0
FAIL=0

check() {
  local name=$1; local cmd=$2
  if eval "$cmd" &>/dev/null; then
    echo "  ✅ $name"
    ((PASS++))
  else
    echo "  ❌ $name — NOT FOUND"
    ((FAIL++))
  fi
}

echo "==> NATS Series — Environment Verification"
check "Go 1.23+"        "go version | grep -E '1\.(2[3-9]|[3-9][0-9])'"
check "Docker"          "docker info"
check "Docker Compose"  "docker compose version"
check "nats CLI"        "nats --version"
check "nats-server"     "nats-server --version"
check "kubectl"         "kubectl version --client"
check "helm"            "helm version"

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "✅ All checks passed!" || { echo "❌ Fix missing tools before proceeding."; exit 1; }
