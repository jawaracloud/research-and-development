# 04 — Blast Radius

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

**Blast radius** is the maximum potential impact of a chaos experiment — how many users, services, pods, or nodes could be affected if something goes wrong during the experiment.

Controlling blast radius is what separates responsible chaos engineering from reckless sabotage.

## The Blast Radius Spectrum

```
Smallest                                               Largest
    │                                                      │
    ▼                                                      ▼
 Single     Single    Namespace   Cluster    Region   Multi-region
 container  pod       of pods     node       AZ        outage
```

Start at the **leftmost point** for new experiments. Move right only when you have high confidence and good rollback mechanisms.

## Dimensions of Blast Radius

| Dimension | Control Mechanism |
|-----------|------------------|
| **Pod count** | `PODS_AFFECTED_PERC` in LitmusChaos |
| **Namespace** | Keep chaos in `staging` or dedicated namespace |
| **Cluster** | Use a dedicated chaos cluster, not prod |
| **Time** | `TOTAL_CHAOS_DURATION` — shorter = safer |
| **Traffic** | Run during off-peak hours |
| **Users** | Feature-flag affected endpoints off for users |

## LitmusChaos Blast-Radius Controls

```yaml
env:
  - name: PODS_AFFECTED_PERC
    value: "25"          # only 25% of matching pods
  - name: TOTAL_CHAOS_DURATION
    value: "30"          # 30 seconds max
  - name: CHAOS_INTERVAL
    value: "10"          # every 10 s within the window
  - name: FORCE
    value: "false"       # graceful delete, not SIGKILL
```

## Blast Radius Decision Matrix

| Confidence | Environment | Blast Radius |
|-----------|-------------|-------------|
| Low | Dev / staging | 1 pod, 30 s |
| Medium | Staging / shadow prod | 25% of pods, 60 s |
| High | Production (off-peak) | 50% of pods, 120 s |
| Expert | Production (anytime) | Full AZ, long duration |

## Abort Mechanisms

Always have a kill switch before starting:

1. **ChaosEngine `engineState: stop`** — pause/stop running experiments
2. **kubectl delete chaosengine** — immediate cleanup
3. **Automated abort via probe failure** — chaos guard (lesson 79)
4. **Feature flags** — disable affected features before injection

## The Golden Rule

> _"Always be able to stop the experiment faster than it can cause irreversible damage."_

---
*Part of the 100-Lesson Chaos Engineering Series.*
