#!/usr/bin/env bash
set -euo pipefail
echo "==> Tearing down NATS lab..."
docker compose down -v
echo "✅ Done — all containers and volumes removed."
