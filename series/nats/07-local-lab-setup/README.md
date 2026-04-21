# 07 — Local Lab Setup

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A local NATS development environment with a 3-node JetStream cluster, Prometheus, Grafana, and NATS Surveyor — everything needed to run all 100 lessons.

## Prerequisites

- Docker ≥ 24.0
- Docker Compose ≥ 2.24
- Go ≥ 1.23
- `nats` CLI

## Step 1: Verify tools

```bash
./scripts/verify-env.sh
```

## Step 2: Start the lab

```bash
./scripts/setup.sh
```

This starts:
| Service | Port | Purpose |
|---------|------|---------|
| NATS node 1 | 4222 | Client connections |
| NATS monitor | 8222 | HTTP monitoring |
| NATS node 2 | 4223 | Cluster node |
| NATS node 3 | 4224 | Cluster node |
| NATS Surveyor | 7777 | Prometheus metrics exporter |
| Prometheus | 9090 | Metrics storage |
| Grafana | 3000 | Dashboards |
| PostgreSQL | 5432 | Pattern examples |
| Redis | 6379 | Pattern examples |

## Step 3: Verify NATS is running

```bash
nats server check --server nats://localhost:4222
# Server OK
```

## Step 4: Verify the cluster

```bash
nats server ls --server nats://localhost:4222
# nats-1  nats-2  nats-3
```

## Step 5: Verify JetStream

```bash
nats account info --server nats://localhost:4222
# JetStream Account Information:
#   Memory: 0 B of 1.0 GB
#   Storage: 0 B of 10 GB
```

## Step 6: Access dashboards

```bash
# NATS monitoring
open http://localhost:8222

# Grafana (admin / nats123)
open http://localhost:3000

# Prometheus
open http://localhost:9090
```

## Step 7: Create context (for NATS CLI)

```bash
nats context add local \
  --server nats://localhost:4222 \
  --description "Local NATS Lab"

nats context select local
```

From now on, all `nats` CLI commands use `local` context automatically.

## Teardown

```bash
./scripts/teardown.sh
```

---
*Part of the 100-Lesson NATS Series.*
