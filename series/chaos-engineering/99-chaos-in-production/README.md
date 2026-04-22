# 99 — Chaos in Production

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

Moving chaos from staging to production is the ultimate level of confidence. This lesson defines the safety criteria, blast radius strategy, and phased approach for production chaos.

## Production Chaos Readiness Criteria

Before any production chaos experiment:

```
✅ Resilience Score > 80 in staging
✅ All P1 action items from staging GameDays are resolved
✅ PodDisruptionBudgets defined for all services
✅ HPA configured for all stateless services
✅ Circuit breakers in place for all DB/external API calls
✅ Alertmanager alerts defined for experiment failures
✅ SLO burn rate dashboard active and reviewed daily
✅ Chaos experience: > 10 staging experiments with > 90% pass rate
✅ Team approval (all stakeholders sign off)
✅ PagerDuty maintenance window open
```

## Production Chaos Blast Radius Rules

| Parameter | Staging | Production Phase 1 | Production Phase 2 |
|-----------|---------|-------------------|-------------------|
| `PODS_AFFECTED_PERC` | 100% | 10% | 25% |
| `TOTAL_CHAOS_DURATION` | 60s | 30s | 60s |
| `CHAOS_INTERVAL` | 10s | 30s | 10s |
| Experiment window | Anytime | 02:00–04:00 UTC | Off-peak hours |
| Approval required | No | Yes (team lead) | Yes (manager) |

## Phased Production Rollout

### Phase 1 — Shadow mode (1 hour, monitoring only)

```bash
# Apply a very small blast radius first
# 5% of pods, 30s duration, continuous monitoring
kubectl apply -f chaos/production/shadow/pod-delete-5pct.yaml
```

### Phase 2 — Automated with gates

```yaml
# PromProbe → abort if burn rate > 6x
probe:
  - name: slo-burn-rate-guard
    type: promProbe
    mode: Continuous
    promProbe/inputs:
      query: "(sum(rate(http_requests_total{status=~'5..'}[5m]))/sum(rate(http_requests_total[5m])))/0.001"
      comparator:
        criteria: "<"
        value: "6"   # abort if consuming budget 6× faster than normal
```

### Phase 3 — Scheduled continuous chaos

```yaml
schedule:
  repeat:
    properties:
      minChaosInterval: "6h"
    workDays:
      includedDays: "Mon,Tue,Wed,Thu"
    workHours:
      includedHours: "2,3"
```

## Production Chaos Communication Plan

```
48h before: Email to stakeholders (Subject: Planned production chaos test)
1h before:  Slack #ops-announcements: "Production chaos in 1 hour"
During:     Chaos Operator posts updates every 10 min to #chaos-engineering
After:      Slack summary with pass/fail, metrics, and any observations
48h after:  Email report to management
```

## When NOT to run production chaos

```
❌ During product launches or high-traffic events
❌ When a service is already degraded (burn rate > 2x)
❌ During critical on-call shifts without the on-call engineer's consent
❌ When P1/P2 incidents are active
❌ On Fridays or before holidays
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
