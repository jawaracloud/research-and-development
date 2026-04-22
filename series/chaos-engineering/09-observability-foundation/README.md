# 09 — Observability Foundation

> **Type:** Tutorial  
> **Phase:** Foundations

## What you're building

A Prometheus + Grafana observability stack configured specifically for chaos experiments — with dashboards and alerts that make it easy to observe steady-state deviation during chaos injection.

## Why observability is foundational

Without metrics, chaos experiments produce noise: _"something bad happened but we don't know what or when."_ With good observability:

- You can **prove** the steady-state hypothesis held (or failed)
- You can correlate chaos events with metric spikes on a timeline
- You can set automated abort thresholds

## Step 1: Prometheus configuration

`observability/prometheus.yml`:

```yaml
global:
  scrape_interval: 5s      # scrape every 5s for crisp chaos timelines
  evaluation_interval: 5s

rule_files:
  - "chaos-alerts.yml"

scrape_configs:
  - job_name: target-app
    static_configs:
      - targets: ["target-app:8080"]
    metrics_path: /metrics

  - job_name: litmus-chaos-exporter
    static_configs:
      - targets: ["chaos-exporter.litmus.svc.cluster.local:8080"]
```

## Step 2: Chaos-specific alert rules

`observability/chaos-alerts.yml`:

```yaml
groups:
  - name: chaos
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[1m]))
          / sum(rate(http_requests_total[1m])) > 0.01
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Error rate > 1% — SLO breach detected"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[1m])) > 0.5
        for: 30s
        labels:
          severity: warning
        annotations:
          summary: "p99 latency > 500ms"
```

## Step 3: Deploy the stack

```bash
# Via docker-compose (local)
docker compose up -d prometheus grafana

# Or via Helm (in-cluster)
helm install kube-prom prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set grafana.adminPassword=chaos123
```

## Step 4: Import the Chaos Dashboard

1. Open Grafana → `http://localhost:3000`
2. Go to **Dashboards → Import**
3. Use ID `13705` (Kubernetes Chaos Engineering Dashboard)

## Step 5: Verify metrics flowing

```bash
curl http://localhost:9090/api/v1/query \
  --data-urlencode 'query=http_requests_total' | jq '.data.result[] | .metric'
```

## Key metrics to watch during chaos

| Metric | Threshold |
|--------|-----------|
| `rate(http_requests_total{status=~"5.."}[1m])` | < 1% |
| `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[1m]))` | < 500 ms |
| `kube_deployment_status_replicas_available` | >= 2 |

---
*Part of the 100-Lesson Chaos Engineering Series.*
