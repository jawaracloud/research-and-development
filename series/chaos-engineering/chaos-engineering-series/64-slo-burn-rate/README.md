# 64 — SLO Burn Rate

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

**Burn rate** measures how fast your error budget is being consumed relative to the rate at which it refills. During chaos experiments, burn rate spikes reveal the severity of the steady-state deviation.

## Core Concepts

Given a **99.9% availability SLO** over 30 days:

- Error budget = 0.1% × 30 days = **43.8 minutes**
- Budget refill rate = `0.001 / 2592000 = 3.86e-10` per second
- Burn rate 1.0 = consuming exactly as fast as refilling
- Burn rate 14.4 = burning 14.4× faster → budget exhausted in ~2h

## Burn Rate PromQL

```promql
# 1-hour burn rate
sum(rate(http_requests_total{status=~"5.."}[1h]))
/ sum(rate(http_requests_total[1h]))
/ 0.001   # budget = 1 - SLO = 0.001

# 6-hour burn rate (multi-window alerting)
sum(rate(http_requests_total{status=~"5.."}[6h]))
/ sum(rate(http_requests_total[6h]))
/ 0.001
```

## Multi-Window Burn Rate Alerts (Google SRE style)

```yaml
groups:
  - name: slo.burnrate
    rules:
      # Page: burn rate > 14.4 in 1h window (2% budget in 1h)
      - alert: HighBurnRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[1h]))
            / sum(rate(http_requests_total[1h]))
          ) / 0.001 > 14.4
          AND
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            / sum(rate(http_requests_total[5m]))
          ) / 0.001 > 14.4
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "SLO burning at {{ $value }}x rate"

      # Warn: burn rate > 6 in 6h window
      - alert: MediumBurnRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[6h]))
            / sum(rate(http_requests_total[6h]))
          ) / 0.001 > 6
        for: 15m
        labels:
          severity: warning
```

## Burn Rate During Chaos

Use burn rate to automatically abort experiments:

```yaml
# LitmusChaos promProbe — abort if burn rate > 14.4
probe:
  - name: burn-rate-guard
    type: promProbe
    mode: Continuous
    promProbe/inputs:
      endpoint: "http://prometheus:9090"
      query: |
        (sum(rate(http_requests_total{status=~"5.."}[5m]))
        / sum(rate(http_requests_total[5m]))) / 0.001
      comparator:
        criteria: "<"
        value: "14.4"
```

## Grafana Burn Rate Panel

```json
{
  "title": "SLO Burn Rate",
  "type": "gauge",
  "fieldConfig": {
    "defaults": {
      "thresholds": {
        "steps": [
          {"color": "green", "value": 0},
          {"color": "yellow", "value": 1},
          {"color": "orange", "value": 6},
          {"color": "red", "value": 14.4}
        ]
      }
    }
  }
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
