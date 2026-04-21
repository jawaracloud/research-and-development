# 93 — Post-GameDay Analysis

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

The post-GameDay analysis transforms raw observations into structured findings, prioritised action items, and institutional knowledge — the most valuable output of any GameDay.

## Analysis Framework (OODA Loop)

```
Observe → Orient → Decide → Act
```

1. **Observe**: What happened? (metrics, logs, traces)
2. **Orient**: Why did it happen? (root cause)
3. **Decide**: Is this a risk? Does it need fixing? Priority?
4. **Act**: Define the improvement and owner

## Step 1: Gather experiment evidence

```bash
# Export ChaosResults
kubectl get chaosresult -n litmus -o yaml > gameday-results.yaml

# Export Prometheus metrics range (during GameDay window)
curl "http://localhost:9090/api/v1/query_range" \
  --data-urlencode "query=sum(rate(http_requests_total{status=~'5..'}[1m]))/sum(rate(http_requests_total[1m]))" \
  --data-urlencode "start=2026-01-20T09:00:00Z" \
  --data-urlencode "end=2026-01-20T12:00:00Z" \
  --data-urlencode "step=15s" \
  > gameday-metrics.json

# Export Grafana dashboard snapshot
# Grafana → Share → Snapshot → Generate Link
```

## Step 2: Classify findings

Use this severity matrix:

| Severity | Criteria | Action |
|----------|---------|--------|
| P0 — Critical | SLO was breached; real users would be impacted | Fix within 1 week |
| P1 — High | Hypothesis failed; recovery slower than RTO | Fix within 1 sprint |
| P2 — Medium | Hypothesis passed with margin < 2× | Improvements welcome |
| P3 — Low | Hypothesis passed comfortably | No action needed; schedule re-run in 3 months |

## Step 3: Root cause analysis template

```markdown
## Finding: Database reconnect takes too long

### Observation
After PostgreSQL pod restart, target-app logged 23 seconds of
"connection refused" before first successful query.

### Root Cause
`db.SetConnMaxLifetime` was set to 5 minutes. The stale connection
was not retried until the pool timeout, at which point `database/sql`
tested the connection and created a new one.

### Impact
23 seconds × 10 concurrent users = 230 user-facing errors (0.8% error rate)

### Fix
Set `db.SetConnMaxLifetime(30 * time.Second)` to evict stale
connections faster and trigger reconnection sooner.

### Owner: @backend-team
### Due: 2026-01-27
```

## Step 4: Action item tracking

```markdown
## GameDay 2026-01-20 Action Items

| # | Finding | Severity | Owner | Due | Status |
|---|---------|----------|-------|-----|--------|
| 1 | DB reconnect delay | P1 | @alice | 2026-01-27 | [ ] |
| 2 | Missing PDB on order-svc | P1 | @bob | 2026-01-27 | [ ] |
| 3 | No anti-affinity on frontend | P2 | @charlie | 2026-02-03 | [ ] |
| 4 | HPA too slow (60s) | P2 | @alice | 2026-02-03 | [ ] |
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
