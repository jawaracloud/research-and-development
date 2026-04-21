#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NATS Series — Local Lab Setup
# Creates a 3-node NATS JetStream cluster and creates base streams.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "==> Starting NATS local lab..."

# Start all services
docker compose up -d

echo "==> Waiting for NATS cluster..."
sleep 8

# Create base streams used across lessons
nats stream add ORDERS \
  --server nats://localhost:4222 \
  --subjects "orders.>" \
  --retention limits \
  --max-msgs -1 \
  --max-age 7d \
  --replicas 1 \
  --storage file 2>/dev/null || true

nats stream add EVENTS \
  --server nats://localhost:4222 \
  --subjects "events.>" \
  --retention limits \
  --max-msgs -1 \
  --max-age 7d \
  --replicas 1 \
  --storage file 2>/dev/null || true

echo ""
echo "✅ NATS lab ready!"
echo "   NATS client:    nats://localhost:4222"
echo "   NATS monitor:   http://localhost:8222"
echo "   Prometheus:     http://localhost:9090"
echo "   Grafana:        http://localhost:3000 (admin / nats123)"
echo "   NATS Surveyor:  http://localhost:7777/metrics"
