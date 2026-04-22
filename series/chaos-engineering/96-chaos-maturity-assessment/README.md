# 96 — Chaos Maturity Assessment

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

This lesson provides a practical assessment framework for measuring your organisation's chaos engineering maturity and identifying the next improvement steps.

## Maturity Assessment Scorecard

Score each dimension 0–4 using the criteria below.

---

### Dimension 1: Tooling & Infrastructure

| Score | Criteria |
|-------|---------|
| 0 | No chaos tooling installed |
| 1 | LitmusChaos or Chaos Mesh installed in staging |
| 2 | Full chaos stack (LitmusChaos + Prometheus + Grafana) in staging |
| 3 | Chaos tools in production; scoped blast radius |
| 4 | Custom chaos tooling; ChaosCenter with RBAC |

---

### Dimension 2: Observability

| Score | Criteria |
|-------|---------|
| 0 | No metrics or alerting |
| 1 | Basic metrics; no chaos-specific dashboards |
| 2 | Chaos dashboard in Grafana; SLO tracking |
| 3 | Full logs + metrics + traces correlated; automated alerts |
| 4 | Chaos context propagation in OTel; automated reporting |

---

### Dimension 3: Experimentation

| Score | Criteria |
|-------|---------|
| 0 | Never run a chaos experiment |
| 1 | Occasional ad-hoc experiments in staging |
| 2 | Documented hypotheses; runbooks per experiment |
| 3 | Experiments in CI/CD pipeline; automated SLO gates |
| 4 | Continuous scheduled chaos; GameDays quarterly |

---

### Dimension 4: Culture

| Score | Criteria |
|-------|---------|
| 0 | "Breaking things is bad" — fear of failure |
| 1 | SRE team champions chaos; limited team awareness |
| 2 | Multiple teams run experiments; blameless post-mortems |
| 3 | Engineering-wide chaos culture; failure celebrated as learning |
| 4 | Business participates in GameDays; chaos in hiring interviews |

---

### Dimension 5: Process

| Score | Criteria |
|-------|---------|
| 0 | No defined process |
| 1 | Basic runbooks exist for 1–2 experiments |
| 2 | All experiments have runbooks; report template used |
| 3 | Chaos-as-code in Git; PR review for new experiments |
| 4 | Action items tracked in issue tracker; quarterly review |

---

## Score Interpretation

| Total (0–20) | Level | Description |
|-------------|-------|-------------|
| 0–5 | Level 1 | Getting started |
| 6–9 | Level 2 | Experimenting |
| 10–14 | Level 3 | Operationalising |
| 15–18 | Level 4 | Automating |
| 19–20 | Level 5 | Proactive resilience |

## Scoring Template

```yaml
# chaos-maturity-assessment.yaml
assessment_date: "2026-Q1"
team: "Platform Engineering"
scores:
  tooling:        2
  observability:  2
  experimentation: 1
  culture:        1
  process:        1
total:            7
level:            2   # Experimenting
next_goals:
  - "Add chaos experiments to CI pipeline (Experimentation → 2)"
  - "Create runbooks for top-3 experiments (Process → 2)"
  - "Host first GameDay (Culture → 2)"
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
