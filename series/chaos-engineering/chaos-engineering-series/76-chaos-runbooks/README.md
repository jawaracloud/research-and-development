# 76 — Chaos Runbooks

> **Type:** Reference  
> **Phase:** Observability & Automation

## Overview

A **chaos runbook** documents the pre-game checklist, execution steps, abort criteria, and post-game analysis for a specific chaos experiment — transforming ad-hoc experiments into repeatable, safe procedures.

## Runbook Template

```markdown
# Runbook: [Experiment Name]

## Metadata
- **Owner**: Platform Team
- **Cadence**: Weekly / On demand
- **Last Run**: 2026-01-15
- **Pass Rate**: 8/10

## Hypothesis
[State the steady-state hypothesis clearly]
"When X happens, Y continues within Z bounds"

## Blast Radius
- **Targets**: `target-app` Deployment, `default` namespace
- **Pods affected**: 50%
- **Duration**: 60 seconds

## Prerequisites
- [ ] Staging environment deployed and healthy
- [ ] PagerDuty maintenance window open
- [ ] Grafana chaos dashboard open (Tab 1)
- [ ] Jaeger tracing open (Tab 2)
- [ ] Team notified in #chaos-engineering
- [ ] Load test running: `k6 run load-test.js`

## Execution Steps
1. Verify pre-chaos steady state: `curl http://target-app:8080/health`
2. Apply ChaosEngine: `kubectl apply -f engines/pod-delete.yaml`
3. Monitor Grafana for error rate / latency spikes (Tab 1)
4. Monitor Jaeger for failed traces (Tab 2)

## Abort Criteria (stop immediately if any is true)
- Error rate > 5% (above hypothesis threshold × 5)
- p99 latency > 2000 ms
- ChaosResult verdict = Fail
- PagerDuty fires P1 alert
- Team decides to stop

## Abort Procedure
\`\`\`bash
kubectl patch chaosengine pod-delete-engine -n litmus \
  --type=merge -p '{"spec":{"engineState":"stop"}}'
\`\`\`

## Post-Game Analysis
### Observations
[Fill in after experiment]

### Findings
- [ ] Hypothesis: PASS / FAIL
- [ ] Unexpected behaviours: 
- [ ] New hypotheses created:

### Action Items
| Item | Owner | Due |
|------|-------|-----|
|      |       |     |

## References
- [SLO Dashboard](http://grafana.local/d/slo)
- [LitmusChaos Docs](https://litmuschaos.io/docs)
- [Related incident tickets](https://jira.example.com)
```

## Storing Runbooks as Code

```
chaos/
└── runbooks/
    ├── pod-delete.md
    ├── node-drain.md
    ├── db-failure.md
    └── network-partition.md
```

Commit runbooks alongside experiment manifests. Link from ChaosEngine annotations:

```yaml
metadata:
  annotations:
    chaos.example.com/runbook: "https://github.com/org/chaos/blob/main/runbooks/pod-delete.md"
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
