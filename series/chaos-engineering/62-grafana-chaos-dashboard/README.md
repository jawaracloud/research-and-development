# 62 — Grafana Chaos Dashboard

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Import and configure a production-ready Grafana dashboard that visualises chaos experiment status, SLO burn rate, and application metrics side-by-side — your single pane of glass for GameDay.

## Dashboard Panels

| Row | Panels |
|-----|--------|
| **Chaos Status** | Active experiments, experiment verdict history, pass/fail rate |
| **Application Health** | Error rate, p99 latency, request throughput |
| **Infrastructure** | CPU/memory usage per pod, pod restarts |
| **SLO Burn Rate** | 1h and 6h burn rate, budget remaining |

## Step 1: Import from Grafana Dashboard Hub

```bash
# Dashboard IDs to import:
# 13705 — Kubernetes Chaos Engineering
# 17781 — LitmusChaos Experiment Results
# 3119  — Node Exporter Full

kubectl port-forward svc/kube-prom-grafana 3000:80 -n monitoring
# Open http://localhost:3000 → Dashboards → Import → Enter ID
```

## Step 2: Custom chaos annotation panel

Add a panel with this PromQL to show chaos event markers:

```promql
litmuschaos_experiment_verdict
```

Panel type: **Stat** with threshold `0 = red (fail), 1 = green (pass)`

## Step 3: SLO error budget panel

```promql
# 1-hour burn rate
(
  sum(rate(http_requests_total{status=~"5.."}[1h]))
  / sum(rate(http_requests_total[1h]))
) / 0.001  # divide by error budget rate (99.9% SLO → 0.001)
```

Threshold: `>1 = burning faster than refill → RED`

## Step 4: Dashboard JSON provisioning

```yaml
# observability/grafana/provisioning/dashboards/chaos.yaml
apiVersion: 1
providers:
  - name: Chaos Dashboards
    type: file
    options:
      path: /etc/grafana/dashboards
```

Place exported dashboard JSON under `observability/grafana/dashboards/chaos-dashboard.json`.

## Step 5: Grafana alerts from the dashboard

```yaml
# Grafana alert rule
alert:
  name: ChaosExperimentFailed
  condition: $A == 0
  data:
    - refId: A
      expr: litmuschaos_experiment_verdict
  notifications:
    - uid: slack-webhook
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
