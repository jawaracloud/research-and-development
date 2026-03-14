# 64 — Observability with Prometheus

> **Type:** Tutorial  
> **Phase:** Production & Operations

## What you're building

Integrate NATS with Prometheus using the **NATS Prometheus Exporter** (or Surveyor) and learn the most critical metrics to monitor.

## The Metrics Stack

1. **NATS Server:** Optional built-in exporter or JSON monitoring.
2. **NATS Surveyor:** Collects metrics from multiple servers and exports to Prometheus.
3. **Prometheus:** Scrapes and stores metrics.

## Step 1: Running NATS Surveyor

Surveyor subscribes to server advisories and system subjects to build a complete picture of the cluster.

```bash
docker run -d --name nats-surveyer \
  -p 7777:7777 \
  natsio/nats-surveyor:latest \
  -s nats://nats:4222
```

## Step 2: Prometheus Config

```yaml
scrape_configs:
  - job_name: 'nats'
    static_configs:
      - targets: ['nats-surveyor:7777']
```

## Step 3: Critical Metrics and Alerts

### Server Health
- `nats_server_connections`: Total active connections. Alert if it spikes unexpectedly.
- `nats_server_uptime`: Should be steady. Alert if it resets (indicating a crash).

### JetStream Health
- `nats_js_stream_messages`: Message count per stream.
- `nats_js_stream_bytes`: Storage used. Alert if approaching `MaxBytes`.
- `nats_js_consumer_num_pending`: Consumer lag. **Most important metric for EDA!**

### Errors
- `nats_server_slow_consumers`: Number of connections being dropped because they can't keep up.
- `nats_server_errors_total`: General server errors.

## Example Prometheus Query (Rate of Messages)

```promql
rate(nats_server_msgs_in_count[1m])
```

## Example Alert Rule

```yaml
groups:
- name: nats_alerts
  rules:
  - alert: HighConsumerLag
    expr: nats_js_consumer_num_pending > 50000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Consumer lag on {{ $labels.consumer }} is too high"
```

---
*Part of the 100-Lesson NATS Series.*
