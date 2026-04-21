# 77 — Chaos Reports

> **Type:** How-To  
> **Phase:** Observability & Automation

## Overview

Chaos reports document the outcomes of experiments — findings, weaknesses discovered, and improvements made — creating an organisational knowledge base of system resilience.

## Report Types

| Type | Frequency | Audience |
|------|-----------|---------|
| Experiment report | Per experiment | Engineering |
| Weekly chaos digest | Weekly | Team leads |
| GameDay report | Per GameDay | Engineering + Management |
| Quarterly resilience review | Quarterly | Leadership |

## Experiment Report Template

```markdown
# Chaos Experiment Report
**Experiment**: pod-delete
**Date**: 2026-01-20
**Environment**: Staging
**Engineer**: @username

## Summary
| Metric | Target | Actual | Result |
|--------|--------|--------|--------|
| Error rate | < 1% | 0.3% | ✅ PASS |
| p99 latency | < 500ms | 420ms | ✅ PASS |
| Recovery time | < 30s | 18s | ✅ PASS |

## Verdict: ✅ PASS

## Timeline
| Time | Event |
|------|-------|
| 14:00 | Pre-chaos baseline verified |
| 14:05 | ChaosEngine applied |
| 14:05:10 | Pod `target-app-abc` deleted |
| 14:05:22 | Pod `target-app-abc` rescheduled |
| 14:05:35 | All probes passing again |
| 14:06 | ChaosEngine completed |

## Findings
- Kubernetes rescheduled the pod in 12 seconds (faster than 30s hypothesis)
- HPA did NOT scale out — CPU headroom was sufficient
- Error rate spike was 0.3% lasting ~8 seconds

## Improvement Actions
- [ ] Reduce `PodDisruptionBudget.minAvailable` from 2 to 1 to allow more experiments
- [ ] Add a dedicated chaos node pool with `chaos=true` label

## Evidence
- [Grafana snapshot](http://grafana.local/snapshot/abc123)
- [k6 report](./reports/k6-2026-01-20.html)
- ChaosResult: `kubectl get chaosresult -n litmus -o yaml`
```

## Automating Report Generation

```bash
#!/usr/bin/env bash
# generate-report.sh

DATE=$(date +%Y-%m-%d)
ENGINE=$1

VERDICT=$(kubectl get chaosresult "${ENGINE}-pod-delete" \
  -n litmus -o jsonpath='{.status.experimentStatus.verdict}')

PASS=$(kubectl get chaosresult "${ENGINE}-pod-delete" \
  -n litmus -o jsonpath='{.status.history.passedRuns}')
FAIL=$(kubectl get chaosresult "${ENGINE}-pod-delete" \
  -n litmus -o jsonpath='{.status.history.failedRuns}')

cat > "reports/experiment-${DATE}.md" <<EOF
# Chaos Experiment Report — ${DATE}
Verdict: **${VERDICT}**
Pass history: ${PASS} runs
Fail history: ${FAIL} runs
EOF

echo "Report generated: reports/experiment-${DATE}.md"
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
