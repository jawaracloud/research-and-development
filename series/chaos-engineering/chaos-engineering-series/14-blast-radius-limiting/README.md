# 14 — Blast Radius Limiting

> **Type:** How-To  
> **Phase:** Foundations

## Overview

This lesson shows the concrete mechanisms in LitmusChaos and Chaos Mesh to limit blast radius — ensuring experiments affect only the intended targets.

## LitmusChaos Controls

### 1. PODS_AFFECTED_PERC

Limit the percentage of matching pods killed:

```yaml
env:
  - name: PODS_AFFECTED_PERC
    value: "25"    # only 25% of pods with applabel
```

### 2. TARGET_PODS

Target a specific pod by name (instead of random selection):

```yaml
env:
  - name: TARGET_PODS
    value: "target-app-abc123"
```

### 3. TOTAL_CHAOS_DURATION

Limit how long chaos injection runs:

```yaml
env:
  - name: TOTAL_CHAOS_DURATION
    value: "30"    # seconds; default 30
```

### 4. Node Selector

Restrict which nodes the chaos job runs on:

```yaml
spec:
  experiments:
    - name: pod-delete
      spec:
        components:
          nodeSelector:
            "chaos-experiments": "true"
```

Label your dedicated chaos node:
```bash
kubectl label node chaos-lab-worker chaos-experiments=true
```

### 5. Namespace Isolation

Run experiments only in a dedicated namespace:

```yaml
spec:
  appinfo:
    appns: "staging"          # only targets pods in staging
```

## Chaos Mesh Controls

### Selector

Fine-grained pod selection:

```yaml
spec:
  selector:
    namespaces: ["staging"]
    labelSelectors:
      "app": "target-app"
      "version": "canary"     # only canary pods
  mode: FixedNumber
  value: "1"                  # exactly 1 pod
```

### Mode Options

| Mode | Effect |
|------|--------|
| `One` | Randomly select 1 pod |
| `All` | All matching pods |
| `Fixed` | Exact count (`value: "2"`) |
| `FixedPercent` | Percentage (`value: "25"`) |
| `RandomMaxPercent` | Up to N% (`value: "50"`) |

## Time-based Limiting

Limit experiments to off-peak windows using ChaosSchedule (lesson 15) or cron-based Argo workflows (lesson 71).

```yaml
# Run chaos only between 02:00–04:00 UTC
schedule:
  cron: "0 2 * * *"
```

## Emergency Kill Switch

Always be ready to abort:

```bash
# Stop a LitmusChaos engine immediately
kubectl patch chaosengine first-pod-delete -n litmus \
  --type=merge -p '{"spec":{"engineState":"stop"}}'

# Delete the engine entirely
kubectl delete chaosengine first-pod-delete -n litmus
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
