# 67 — NATS Surveyor Deep Dive

> **Type:** Tutorial  
> **Phase:** Production & Operations

## What you're building

Configure and run **NATS Surveyor** as the primary observability agent for your cluster, visualizing real-time traffic and connection maps.

## What is Surveyor?

Surveyor is a standalone tool from the NATS team that:
1. Subscribes to **Server Advisories** `$SYS.ADVISORY.>`.
2. Scrapes `varz` and `jsz` endpoints automatically.
3. Exposes a **Prometheus** endpoint with aggregated data.
4. Generates a **Connection Map** (visualizing which clients are where).

## Step 1: Running Surveyor with Docker

```bash
docker run -d \
  --name surveyor \
  -p 7777:7777 \
  -p 8080:8080 \
  natsio/nats-surveyor:latest \
  -s nats://nats-1:4222,nats://nats-2:4222 \
  -creds /path/to/system.creds
```

## Step 2: The Service Map

Surveyor provides a JSON-based service map at `http://localhost:8080/map`. This can be visualized in custom apps or specific Grafana plugins to show:
- Active connections per instance.
- Message rates between accounts.
- Leaf node connection health.

## Step 3: Understanding Advisories

Surveyor's magic comes from listening to Advisories. These are JSON events published by the server when things happen:
- **Connect/Disconnect:** `_INBOX.<id>` messages.
- **Slow Consumer:** Alerts when a client is dropped.
- **JetStream:** Stream/Consumer state changes.

You can listen to these yourself to build custom automation:
```bash
nats sub "$SYS.ADVISORY.>"
```

## Step 4: Configuring Prometheus Scraping

Ensure your Prometheus setup includes the accounts you want to track:

```yaml
- job_name: 'surveyor'
  static_configs:
    - targets: ['surveyor:7777']
```

## When to use Surveyor vs. Native Exporter

| Feature | Surveyor | Native Exporter |
|---------|----------|-----------------|
| **Ease of Setup** | 1 agent for whole cluster | 1 sidecar per node |
| **Richness** | Includes health/advisories | Just server metrics |
| **Architecture** | External subscriber | HTTP Sidecar |
| **Recommendation** | **Use in Prod** | Use for dev/small installs |

---
*Part of the 100-Lesson NATS Series.*
