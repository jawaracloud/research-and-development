# 31 — Node Taint

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that applies a taint to a Kubernetes node, testing whether pods without the matching toleration are properly evicted and rescheduled — validating your scheduler and toleration configuration.

**Hypothesis**: When a `NoExecute` taint is applied to a worker node, pods without the matching toleration are evicted within their `tolerationSeconds` window, and the service remains available.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/node-taint \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-taint-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: node-taint
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: TARGET_NODE
              value: "chaos-lab-worker"
            - name: TAINT_LABEL
              value: "chaos=active:NoExecute"
```

## Kubernetes Taint Effects

| Effect | Behaviour |
|--------|-----------|
| `NoSchedule` | No new pods scheduled; existing pods unaffected |
| `PreferNoSchedule` | Scheduler avoids the node; soft constraint |
| `NoExecute` | Existing pods without toleration are evicted |

## Manual taint / untaint

```bash
# Apply taint
kubectl taint node chaos-lab-worker chaos=active:NoExecute

# Watch evictions
kubectl get pods -n default -o wide -w

# Remove taint (LitmusChaos does this automatically at experiment end)
kubectl taint node chaos-lab-worker chaos=active:NoExecute-
```

## Adding tolerations to survive the taint

```yaml
spec:
  template:
    spec:
      tolerations:
        - key: "chaos"
          operator: "Equal"
          value: "active"
          effect: "NoExecute"
          tolerationSeconds: 60   # stay for 60s then evict
```

## Use cases

- Validate that node maintenance taints are handled gracefully
- Test that multi-zone deployments survive a zone's nodes being tainted
- Simulate spot/preemptible instance eviction (AWS/GCP)

---
*Part of the 100-Lesson Chaos Engineering Series.*
