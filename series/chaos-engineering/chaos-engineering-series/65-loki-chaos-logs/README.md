# 65 — Loki Chaos Logs

> **Type:** Tutorial  
> **Phase:** Observability & Automation

## What you're building

Configure Grafana Loki to collect and correlate chaos experiment event logs with application error logs — giving you a unified log + metric view during GameDay.

## Step 1: Install Loki (via Helm)

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi
```

## Step 2: Configure Promtail to scrape chaos namespaces

`observability/promtail-config.yaml`:

```yaml
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
    # Add chaos label when pod has litmus annotation
    pipeline_stages:
      - match:
          selector: '{namespace="litmus"}'
          stages:
            - labels:
                chaos: "true"
```

## Step 3: Add Loki as Grafana data source

```bash
kubectl port-forward svc/loki 3100:3100 -n monitoring
```

In Grafana → Data Sources → Add → Loki:
- URL: `http://loki:3100`

## Step 4: Key LogQL queries

```logql
# All errors from target-app
{app="target-app"} |= "error"

# Errors DURING chaos experiments
{app="target-app"} |= "error"
|= "" # filter by time range aligned with chaos window

# LitmusChaos experiment events
{namespace="litmus"} | json | line_format "{{.chaosengine}} {{.verdict}}"

# Database connection errors
{app="target-app"} |~ "connection refused|dial tcp|EOF"
```

## Step 5: Grafana Explore — correlate metrics and logs

1. Open Grafana → **Explore**
2. Split view: left = Prometheus (error rate), right = Loki (error logs)
3. Select the same time range
4. Correlate metric spike ↔ log errors ↔ chaos event annotation

## Step 6: Alert on log patterns

```yaml
# Grafana Loki alert rule
- alert: DatabaseConnectionErrors
  expr: |
    count_over_time(
      {app="target-app"} |= "connection refused" [5m]
    ) > 10
  for: 1m
  annotations:
    summary: "High database connection error rate in logs"
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
