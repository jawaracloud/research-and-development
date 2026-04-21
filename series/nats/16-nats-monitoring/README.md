# 16 — NATS Monitoring

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

Enable and use NATS's built-in HTTP monitoring endpoint to inspect server health, connections, subscriptions, and JetStream state — the essential observability tool for NATS operations.

## Step 1: Enable monitoring

Start nats-server with monitoring:

```bash
nats-server -m 8222 -js
```

Or in `nats-server.conf`:
```
http_port: 8222
```

## Step 2: Key Monitoring Endpoints

| Endpoint | Description |
|----------|------------|
| `/varz` | Server variables and stats |
| `/connz` | Client connections |
| `/subsz` | Subscriptions |
| `/routez` | Cluster routes |
| `/gatewayz` | Super-cluster gateways |
| `/leafz` | Leaf node connections |
| `/jsz` | JetStream stats |
| `/healthz` | Health check (returns 200 if healthy) |
| `/accstatz` | Account statistics |

## Step 3: Explore with curl + jq

```bash
# Server health
curl http://localhost:8222/healthz
# {"status":"ok"}

# Server stats
curl -s http://localhost:8222/varz | jq '{
  version: .version,
  uptime: .uptime,
  connections: .connections,
  total_connections: .total_connections,
  in_msgs: .in_msgs,
  out_msgs: .out_msgs,
  in_bytes: .in_bytes,
  out_bytes: .out_bytes
}'

# Active connections with details
curl -s http://localhost:8222/connz | jq '.connections[] | {name:.name, subs:.num_subscriptions, msgs_to:.in_msgs}'

# JetStream overview
curl -s http://localhost:8222/jsz | jq '{
  streams: .streams,
  consumers: .consumers,
  memory: .memory,
  storage: .storage
}'

# Per-stream details
curl -s "http://localhost:8222/jsz?streams=true" | jq '.stream_detail[].config.name'
```

## Step 4: nats-top (live monitoring)

```bash
# Install
go install github.com/nats-io/nats-top@latest

# Run
nats-top -s localhost:8222
```

Live table view of connections, messages/second, and bytes/second.

## Step 5: NATS CLI monitoring

```bash
nats server info
nats server report connections
nats server report accounts
nats server subscriptions
```

## Step 6: Prometheus + Grafana

NATS Surveyor exposes Prometheus metrics at `:7777/metrics`:

```bash
curl http://localhost:7777/metrics | grep nats_
# nats_core_bytes_sent_count
# nats_core_connected_clients_count
# nats_js_server_total_streams
# nats_js_server_total_consumers
# etc.
```

Import NATS Grafana dashboard ID **2279** for a complete UI.

---
*Part of the 100-Lesson NATS Series.*
