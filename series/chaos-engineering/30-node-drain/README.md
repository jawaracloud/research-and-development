# 30 — Node Drain

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

A node drain experiment that cordons and drains a worker node, evicting all non-DaemonSet pods and testing whether the scheduler successfully reschedules them on remaining healthy nodes.

**Hypothesis**: When node `chaos-lab-worker` is drained, all `target-app` pods are rescheduled within 60 seconds and the service remains available throughout.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/node-drain \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-drain-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: node-drain
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: TARGET_NODE
              value: "chaos-lab-worker"
            - name: DRAIN_TIMEOUT
              value: "90"
        probe:
          - name: health-during-drain
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "10s"
              retry: 3
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Manual drain (for understanding)

```bash
# Cordon: mark node unschedulable (no new pods)
kubectl cordon chaos-lab-worker

# Drain: evict all pods
kubectl drain chaos-lab-worker \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=90s

# Watch pods reschedule
kubectl get pods -n default -o wide -w
# Pods should appear on chaos-lab-worker2

# Uncordon: restore schedulability
kubectl uncordon chaos-lab-worker
```

## PodDisruptionBudget Interaction

Node drain respects PodDisruptionBudgets. If draining would violate a PDB, the drain blocks:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: target-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: target-app
```

With this PDB and 3 replicas, you can only drain if 2+ replicas remain on other nodes.

## Insights this experiment reveals

- Are pods spread across nodes with `topologySpreadConstraints` or anti-affinity?
- Is the PDB configured with the right `minAvailable`?
- How long does rescheduling take? Is it within your recovery time objective?

---
*Part of the 100-Lesson Chaos Engineering Series.*
