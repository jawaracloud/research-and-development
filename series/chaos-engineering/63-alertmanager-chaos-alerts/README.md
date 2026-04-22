# 63 — Alertmanager Chaos Alerts

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

Configure Prometheus Alertmanager to fire alerts when SLOs are breached during chaos experiments, enabling automated experiment abortion and team notification.

## Two types of chaos alerts

1. **Hypothesis breach**: SLO metric crossed a threshold *during* a chaos window
2. **Experiment failure**: `litmuschaos_experiment_verdict == 0`

## Step 1: Alert rules

`observability/chaos-alerts.yml`:

```yaml
groups:
  - name: chaos.slo
    rules:
      - alert: ChaosHypothesisBreached
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1m]))
            / sum(rate(http_requests_total[1m]))
          ) > 0.01
          AND ON()
          litmuschaos_awaited_experiments > 0
        for: 30s
        labels:
          severity: critical
          type: chaos
        annotations:
          summary: "SLO breach detected during chaos experiment"
          description: "Error rate {{ $value | humanizePercentage }} > 1% while chaos active"
          runbook: "https://wiki.example.com/runbooks/chaos-abort"

      - alert: ChaosExperimentFailed
        expr: litmuschaos_experiment_verdict{} == 0
        labels:
          severity: warning
          type: chaos
        annotations:
          summary: "Chaos experiment {{ $labels.chaosexperiment }} failed"
          engine: "{{ $labels.chaosengine_context }}"

      - alert: HighP99LatencyDuringChaos
        expr: |
          histogram_quantile(0.99,
            rate(http_request_duration_seconds_bucket[1m])) > 1.0
          AND ON()
          litmuschaos_awaited_experiments > 0
        for: 30s
        labels:
          severity: warning
        annotations:
          summary: "p99 > 1s during chaos window"
```

## Step 2: Alertmanager routing

`observability/alertmanager.yml`:

```yaml
route:
  group_by: [alertname, type]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 10m
  receiver: default
  routes:
    - match:
        type: chaos
        severity: critical
      receiver: chaos-pagerduty
      continue: true
    - match:
        type: chaos
      receiver: chaos-slack

receivers:
  - name: chaos-slack
    slack_configs:
      - api_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
        channel: "#chaos-engineering"
        title: "🔥 Chaos Alert: {{ .GroupLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"

  - name: chaos-pagerduty
    pagerduty_configs:
      - routing_key: "YOUR_ROUTING_KEY"
        severity: "{{ .Labels.severity }}"
```

## Step 3: Test the alert

```bash
# Trigger a fake alert via amtool
amtool alert add \
  alertname=ChaosExperimentFailed \
  chaosexperiment=pod-delete \
  severity=warning

# Or wait for real experiment to fail
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
