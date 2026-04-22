# 05 — The Chaos Maturity Model

> **Type:** Reference  
> **Phase:** Foundations

## Overview

The **Chaos Maturity Model** (CMM) describes five progressive levels of chaos engineering adoption. It helps organizations understand where they are today and what they need to invest in to level up.

## The Five Levels

### Level 0 — No Chaos
- No chaos experiments run
- All resilience knowledge is tacit (lives in engineers' heads)
- Incidents are purely reactive
- **Signal**: "We only learn about failures when customers complain"

### Level 1 — Manual Experiments
- Ad-hoc chaos run manually by SREs or platform teams
- No automation, no scheduling
- Experiments not version-controlled
- **Signal**: "We delete a pod occasionally to see what happens"

### Level 2 — Automated Experiments
- Experiments defined as code (YAML manifests, scripts)
- Stored in Git, run on demand via CLI or dashboard
- Basic hypothesis validation with probes
- **Signal**: "We run chaos before every major release"

### Level 3 — Integrated into CI/CD
- Chaos steps embedded in deployment pipelines
- Experiments auto-abort if SLOs breach
- Results feed back into deployment decisions
- **Signal**: "A chaos experiment is a pipeline gate"

### Level 4 — Continuous Chaos in Production
- Experiments run continuously in production during business hours
- Teams are notified of results, not outages
- Chaos is treated like any other metric
- **Signal**: "Chaos is boring — nothing ever fails"

### Level 5 — Automated Chaos-Driven Resilience
- Weaknesses discovered by chaos trigger automated remediation
- System self-heals based on chaos insights
- Chaos informs capacity planning, architecture decisions
- **Signal**: "The system gets better automatically from chaos"

## Maturity Level Assessment

| Question | L1 | L2 | L3 | L4 | L5 |
|----------|----|----|----|----|-----|
| Experiments in Git? | ❌ | ✅ | ✅ | ✅ | ✅ |
| Automated scheduling? | ❌ | ❌ | ✅ | ✅ | ✅ |
| CI/CD integration? | ❌ | ❌ | ✅ | ✅ | ✅ |
| Runs in production? | ❌ | ❌ | ❌ | ✅ | ✅ |
| Auto-remediation? | ❌ | ❌ | ❌ | ❌ | ✅ |

## Where to Start

Most organizations start at **Level 1** and target **Level 2** as their first milestone: get experiments into Git and add basic probe validation. This series will take you from Level 1 to Level 4 progressively.

---
*Part of the 100-Lesson Chaos Engineering Series.*
