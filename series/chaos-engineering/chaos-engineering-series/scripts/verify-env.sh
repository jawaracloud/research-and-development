#!/usr/bin/env bash
# verify-env.sh — Check that all required tools are installed
set -euo pipefail

ERRORS=0

check() {
  local cmd="$1"
  local min_ver="$2"
  if command -v "$cmd" &>/dev/null; then
    echo "✅  $cmd found: $($cmd version 2>/dev/null | head -1 || $cmd --version 2>/dev/null | head -1)"
  else
    echo "❌  $cmd NOT found (required >= $min_ver)"
    ERRORS=$((ERRORS + 1))
  fi
}

check kubectl "1.28"
check helm "3.14"
check kind "0.22"
check go "1.23"
check k6 "0.50"
check docker "24"
check litmusctl "0.24"

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "❌  $ERRORS tool(s) missing. Run .devcontainer/post-create.sh to install."
  exit 1
else
  echo "✅  All tools present. You're ready to start the series!"
fi
