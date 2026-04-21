# 78 — Continuous Chaos

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

**Continuous chaos** is the practice of running low-impact, frequently scheduled chaos experiments automatically — building resilience confidence through constant verification rather than periodic GameDays.

## Principles of Continuous Chaos

1. **Small blast radius** — only inject at 10–25% of pods
2. **Short duration** — 30–60 seconds maximum
3. **Automated gates** — probes and k6 thresholds abort automatically
4. **Business-hours exclusion** — don't run during high-traffic peaks
5. **SLO-bound** — if burn rate is elevated, skip the experiment

## Step 1: ChaosSchedule for continuous chaos

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosSchedule
metadata:
  name: continuous-chaos-prod
  namespace: litmus
spec:
  schedule:
    repeat:
      properties:
        minChaosInterval: "4h"   # at most every 4 hours
      workDays:
        includedDays: "Mon,Tue,Wed,Thu,Fri"
      workHours:
        includedHours: "2,3,4"   # 02:00–05:00 UTC off-peak
  engineTemplateSpec:
    appinfo:
      appns: production
      applabel: "tier=frontend"
      appkind: deployment
    experiments:
      - name: pod-delete
        spec:
          components:
            env:
              - name: TOTAL_CHAOS_DURATION
                value: "30"
              - name: PODS_AFFECTED_PERC
                value: "10"    # only 10% in production
          probe:
            - name: slo-guard
              type: promProbe
              mode: Continuous
              runProperties:
                probeTimeout: "10s"
                retry: 1
                interval: "5s"
              promProbe/inputs:
                endpoint: "http://prometheus.monitoring:9090"
                query: |
                  (sum(rate(http_requests_total{status=~"5.."}[5m]))
                  / sum(rate(http_requests_total[5m]))) / 0.001
                comparator:
                  criteria: "<"
                  value: "6"   # abort if burn rate > 6x
```

## Step 2: Pre-condition check (skip if already degraded)

```bash
#!/usr/bin/env bash
# pre-chaos-check.sh — run before applying any ChaosEngine

BURN_RATE=$(curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=(sum(rate(http_requests_total{status=~"5.."}[1h]))/sum(rate(http_requests_total[1h])))/0.001' \
  | jq -r '.data.result[0].value[1]')

if [ $(echo "$BURN_RATE > 2" | bc -l) -eq 1 ]; then
  echo "⚠️  Burn rate ${BURN_RATE}x elevated — skipping chaos this cycle"
  exit 0
fi

echo "✅ Burn rate ${BURN_RATE}x within bounds — proceeding with chaos"
kubectl apply -f "$1"
```

## Step 3: Tracking continuous chaos KPIs

Report these metrics weekly:

| KPI | Target |
|-----|--------|
| Experiments run | > 20/week |
| Pass rate | > 90% |
| MTTR (mean recovery time) | Trending down |
| New weaknesses found | Track per quarter |

---
*Part of the 100-Lesson Chaos Engineering Series.*
