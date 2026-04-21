# 61 — Prometheus Chaos Metrics

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Configure Prometheus to scrape chaos-specific metrics from LitmusChaos's built-in exporter, enabling you to correlate steady-state deviations with experiment events on a single timeline.

## LitmusChaos Prometheus Exporter

LitmusChaos ships a `chaos-exporter` pod that exposes experiment metrics at `:8080/metrics`.

```bash
kubectl get pods -n litmus
# chaos-exporter-XXXXX   Running

kubectl port-forward svc/chaos-exporter 8080:8080 -n litmus &
curl http://localhost:8080/metrics | grep litmuschaos
```

## Key LitmusChaos Metrics

| Metric | Description |
|--------|------------|
| `litmuschaos_passed_experiments` | Cumulative passed experiments |
| `litmuschaos_failed_experiments` | Cumulative failed experiments |
| `litmuschaos_awaited_experiments` | Currently running experiments |
| `litmuschaos_experiment_verdict{chaosengine_context, chaosexperiment, chaosnamespace}` | Per-experiment verdict (0=fail, 1=pass) |
| `litmuschaos_experiment_start_epoch` | Unix timestamp of experiment start |

## Prometheus scrape config

`observability/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: litmus-chaos-exporter
    static_configs:
      - targets: ["chaos-exporter.litmus.svc.cluster.local:8080"]
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: litmus-exporter
```

## PromQL queries for chaos dashboards

```promql
# Experiment pass rate (last 24h)
sum(increase(litmuschaos_passed_experiments[24h]))
/ sum(increase(litmuschaos_passed_experiments[24h] + litmuschaos_failed_experiments[24h]))

# Which experiments are currently running?
litmuschaos_awaited_experiments > 0

# Alert: experiment failure
litmuschaos_experiment_verdict == 0

# Error rate during chaos windows
(
  sum(rate(http_requests_total{status=~"5.."}[1m]))
  / sum(rate(http_requests_total[1m]))
)
and on() (litmuschaos_awaited_experiments > 0)
```

## Chaos event annotation in Grafana

Add a Prometheus-based annotation:

```json
{
  "datasource": "Prometheus",
  "enable": true,
  "expr": "litmuschaos_awaited_experiments > 0",
  "step": "5s",
  "titleFormat": "Chaos Active",
  "tagKeys": "chaosengine_context,chaosexperiment"
}
```

This overlays vertical shading on every Grafana panel during chaos windows.

---
*Part of the 100-Lesson Chaos Engineering Series.*
