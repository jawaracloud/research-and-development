# 98 — Resilience Scoring

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

A **resilience score** is a single numeric indicator (0–100) that summarises how well a system withstands chaos experiments. It enables objective tracking of resilience improvement over time and across teams.

## Score Formula

```
Resilience Score =
  (Passed Experiments / Total Experiments) × W1
  + (1 - ErrorRateDuringChaos / SLOThreshold) × W2
  + (1 - MTTR / TargetRTO) × W3
```

Default weights: `W1=0.4, W2=0.4, W3=0.2`

## Step 1: Automated scorer (Go)

```go
package scoring

import (
    "context"
    "fmt"
    "time"

    v1 "github.com/prometheus/client_golang/api/prometheus/v1"
)

type ResilienceScore struct {
    PassRate   float64
    ErrorRatio float64 // error rate during chaos / SLO budget
    MTTRRatio  float64 // actual MTTR / target RTO
    Score      float64
}

func Calculate(pAPI v1.API) (ResilienceScore, error) {
    // Pass rate from LitmusChaos exporter
    passRate := queryScalar(pAPI,
        `increase(litmuschaos_passed_experiments[7d]) /
         clamp_min(increase(litmuschaos_passed_experiments[7d]) +
         increase(litmuschaos_failed_experiments[7d]), 1)`)

    // Error rate during chaos vs SLO (99.9% → budget = 0.001)
    errorDuringChaos := queryScalar(pAPI,
        `avg_over_time(
            (sum(rate(http_requests_total{status=~"5.."}[1m]))
            / sum(rate(http_requests_total[1m])))[7d:1m]
         )`)
    
    errorRatio := errorDuringChaos / 0.001 // normalised to budget

    // MTTR: average time to recover (pod restarts)
    // Approximated as avg(kube_pod_container_status_restarts_total change → Ready)
    mttrRatio := 0.8 // placeholder; instrument with real MTTR measurement

    score := (passRate * 0.4) + ((1 - errorRatio) * 0.4) + ((1 - mttrRatio) * 0.2)
    score = max(0, min(100, score*100))

    return ResilienceScore{
        PassRate:   passRate,
        ErrorRatio: errorRatio,
        MTTRRatio:  mttrRatio,
        Score:      score,
    }, nil
}
```

## Step 2: Prometheus recording rule

```yaml
groups:
  - name: resilience.score
    interval: 1h
    rules:
      - record: chaos:resilience_score:weekly
        expr: |
          0.4 * (
            increase(litmuschaos_passed_experiments[7d]) /
            clamp_min(
              increase(litmuschaos_passed_experiments[7d]) +
              increase(litmuschaos_failed_experiments[7d]), 1)
          ) * 100
```

## Step 3: Track improvement over time

| Quarter | Score | Key driver |
|---------|-------|-----------|
| Q1 2026 | 62 | Baseline |
| Q2 2026 | 74 | Added circuit breakers; PDBs |
| Q3 2026 | 88 | Continuous chaos + HPA tuning |
| Q4 2026 | 94 | Multi-cluster DR validated |

## Resilience Score Thresholds

| Score | Interpretation |
|-------|---------------|
| 0–50 | Critical — frequent SLO breaches under chaos |
| 51–70 | In progress — some resilience patterns in place |
| 71–85 | Good — most failure modes handled |
| 86–95 | Excellent — proactive patterns; occasional edge cases |
| 96–100 | Elite — near-zero impact from any tested failure mode |

---
*Part of the 100-Lesson Chaos Engineering Series.*
