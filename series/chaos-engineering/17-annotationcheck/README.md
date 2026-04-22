# 17 — Annotation Check (Opt-in Chaos)

> **Type:** How-To  
> **Phase:** Foundations

## Overview

By default, LitmusChaos can target *any* pod matching the `applabel` selector. **Annotation check** adds an opt-in gate: only pods that explicitly annotate themselves as chaos-ready will be affected.

This is critical for production safety — your chaos experiments cannot accidentally target services that haven't been hardened yet.

## Enabling Annotation Check

In your ChaosEngine:

```yaml
spec:
  annotationCheck: "true"   # default is "false"
```

## Annotating Your Workload

Add the annotation to the Deployment's pod template:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: target-app
spec:
  template:
    metadata:
      labels:
        app: target-app
      annotations:
        litmuschaos.io/chaos: "true"   # <-- opt-in annotation
```

Or patch an existing deployment:

```bash
kubectl patch deployment target-app -n default \
  -p '{"spec":{"template":{"metadata":{"annotations":{"litmuschaos.io/chaos":"true"}}}}}'
```

## What Happens Without the Annotation

With `annotationCheck: "true"`, if a matching pod does NOT have `litmuschaos.io/chaos: "true"`:
- The experiment **skips** that pod
- If no pods are eligible, the ChaosResult shows `Fail` with `failStep: "target pod selection"`

## Annotation-based Allowlisting Strategy

```
Team registers service for chaos:
  1. Service owner adds annotation to Deployment
  2. SRE reviews and approves
  3. Experiment is scheduled against that namespace

Result: Only intentionally chaos-ready services are targeted
```

## Verify Annotation

```bash
kubectl get pods -n default -o json \
  | jq '.items[] | .metadata.name, .metadata.annotations["litmuschaos.io/chaos"]'
# "target-app-abc123"
# "true"
# "other-service-xyz"
# null   ← will be skipped
```

## Combining with Label Selectors

For multi-team clusters, combine annotation check with namespace-scoped label selectors:

```yaml
spec:
  annotationCheck: "true"
  appinfo:
    appns: team-alpha      # only team-alpha namespace
    applabel: "tier=frontend"
    appkind: deployment
```

This ensures only `tier=frontend` pods in `team-alpha` that are annotated get targeted.

---
*Part of the 100-Lesson Chaos Engineering Series.*
