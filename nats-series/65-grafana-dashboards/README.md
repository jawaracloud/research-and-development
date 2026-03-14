# 65 — Grafana Dashboards for NATS

> **Type:** Tutorial  
> **Phase:** Production & Operations

## What you're building

Set up the official NATS Grafana dashboards to visualize your cluster, streams, and consumers in real-time.

## Prerequisites

- Prometheus scraping NATS metrics (from Lesson 64).
- Grafana installed.

## Step 1: Import Dashboard

1. Open Grafana.
2. Go to **Dashboards** > **New** > **Import**.
3. Use ID **2279** (Official NATS Dashboard).
4. Select your Prometheus data source.

## Step 2: Key Dashboard Panels

### Cluster Overview
- Nodes online vs. offline.
- Total throughput (Msgs/sec and Bytes/sec).
- Memory usage across the cluster.

### JetStream Panel
- **Stream Inventory:** List of all streams and their size.
- **Consumer Progress:** Visualizing lag across all consumers. This helps identify "stuck" processors immediately.

### Client Details
- Number of active clients.
- Top talkers (clients by message volume).

## Step 3: Customizing for your App

Create a custom panel to track your specific business events:

1. **Query:** `sum(rate(nats_js_stream_msgs_in_count{stream="ORDERS"}[1m]))`
2. **Type:** Time series graph.
3. **Legend:** "Orders Per Second".

## Tips for Better Dashboards

- **Use Variables:** Add variables for `$cluster`, `$stream`, and `$consumer` so you can drill down into specific areas.
- **Heatmaps:** Great for visualizing processing latency distribution across workers.
- **Thresholds:** Set visual thresholds (Yellow at 80%, Red at 95%) on gauge panels for stream storage.

---
*Part of the 100-Lesson NATS Series.*
