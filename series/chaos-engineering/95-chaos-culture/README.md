# 95 — Chaos Engineering Culture

> **Type:** Explanation  
> **Phase:** Advanced Topics & GameDay

## Overview

The technical tooling of chaos engineering is only half the story. The other half is building an **organisational culture** where systematically breaking things is celebrated as how you build confidence — not feared as a sign of instability.

## Cultural Pillars

### 1. Blameless Post-Mortems

Chaos experiments will reveal failures. The reaction to failure must be learning, not blame:

```
BAD:  "Who wrote that fragile code?"
GOOD: "What did this failure teach us about our assumptions?"
```

### 2. Psychological Safety

Engineers need to feel safe to run experiments that might cause disruptions. This requires:
- Leadership buy-in (executives understand and support chaos)
- Defined blast radius controls (lesson 04) that prevent scope creep
- Clear abort criteria (nobody gets fired for aborting)

### 3. Failure as Learning

Track and celebrate what chaos experiments reveal:

```markdown
## This Month's Chaos Wins

- 🏆 Discovered db reconnect delay (now fixed)
- 🏆 Found that HPA was too slow — scaled limits tightened
- 🏆 Validated that our DR failover works in < 90s
```

### 4. Gradual Adoption

Don't go straight to production. Follow the Chaos Maturity Model (lesson 05):

```
1. Dev environment (no consequences)
2. Test/staging (some consequences)
3. Production canary (small blast radius)
4. Production full (full confidence + automation)
```

## Introducing Chaos to a Skeptical Team

```
Step 1: Start with education (lessons 01–05)
Step 2: Run a low-risk experiment (pod-delete on staging)
Step 3: Share the results — even "Pass" builds confidence
Step 4: Find something with "Fail" — instant buy-in
Step 5: Schedule GameDays as regular events (quarterly → weekly)
```

## Chaos Engineering Charter

Document your team's chaos engineering principles:

```markdown
# Chaos Engineering Charter

## We believe
- Failures are inevitable; our job is to find them first
- Every "Fail" verdict is a gift — it shows us something real

## We commit to
- Always defining a hypothesis before injecting failure
- Always having an abort procedure ready
- Always sharing findings with the team (blameless)

## We will NOT
- Run experiments without defined success criteria
- Inject chaos during business-critical events
- Blame individuals for weaknesses chaos reveals
```

## Measuring Culture Maturity

| Signal | Level |
|--------|-------|
| Engineers fear "breaking things" | Level 0 |
| SRE team runs chaos occasionally | Level 1 |
| Engineers self-service chaos experiments | Level 2 |
| Chaos is automatic in CI/CD | Level 3 |
| Business participates in GameDays | Level 4 |

---
*Part of the 100-Lesson Chaos Engineering Series.*
