# 91 — GameDay Planning

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

A **GameDay** is an organised, time-boxed event where engineers deliberately break production-like systems to learn together, validate hypotheses, and build shared resilience knowledge.

## GameDay Roles

| Role | Responsibilities |
|------|----------------|
| **Game Master** | Facilitates, keeps time, ensures safety |
| **Chaos Operator** | Applies ChaosEngines, executes experiments |
| **Observability Lead** | Watches dashboards, calls out anomalies |
| **Journalist** | Takes notes, documents findings live |
| **Incident Commander** | Ready to abort; owns final call on production impact |

## 6-Week GameDay Preparation Timeline

```
Week 1:  Select target system; define GameDay scope
Week 2:  Document steady-state hypotheses (lesson 03)
Week 3:  Run individual experiments in staging (validate tooling)
Week 4:  Write chaos runbooks (lesson 76)
Week 5:  Dry run with full team; refine abort criteria
Week 6:  Full GameDay ✅
```

## GameDay Agenda (half-day format)

```
09:00  Briefing (30 min)
  - Review hypotheses
  - Review abort criteria
  - Assign roles
  - Open maintenance window

09:30  Baseline capture (15 min)
  - Verify all services healthy
  - Record baseline metrics
  - Start k6 background load

09:45  Experiment 1 — pod-delete (30 min)
  - Execute
  - Observe
  - Document

10:15  Experiment 2 — node-drain (30 min)
11:00  Experiment 3 — DB failover (30 min)
11:30  Debrief (30 min)
  - Review findings
  - Define action items
  - Close maintenance window

12:00  End
```

## Pre-GameDay Checklist

```
Infrastructure
- [ ] Staging cluster is a production mirror (same size, same config)
- [ ] Grafana chaos dashboard ready and shared
- [ ] Alertmanager silenced for chaos alerts
- [ ] PagerDuty maintenance window open

Communication
- [ ] #chaos-engineering Slack channel active
- [ ] Stakeholders notified of GameDay
- [ ] Abort criteria agreed by all participants

Tooling
- [ ] All chaos experiments tested individually
- [ ] k6 load test script running and producing expected metrics
- [ ] ChaosCenter accessible for all operators
```

## Abort Decision Framework

```
Severity 0 (Abort immediately):
  - Error rate > 5×SLO
  - Real customer impact detected
  - Data loss suspected

Severity 1 (Pause and discuss):
  - Experiment running longer than planned
  - Unexpected service degraded (not in scope)
  - Team unsure of actual state

Severity 2 (Continue with monitoring):
  - Hypothesis partially breached
  - Expected recovery, slower than predicted
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
