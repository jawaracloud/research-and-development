# 28 — Node CPU Hog

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

A node-level CPU stress experiment that saturates CPU on a Kubernetes worker node, simulating a noisy-neighbour or runaway system process.

**Hypothesis**: When node CPU is saturated, the Kubernetes scheduler continues routing traffic to healthy nodes, and the overall service error rate stays < 2%.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/node-cpu-hog \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-cpu-hog-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: node-cpu-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: NODE_CPU_CORE
              value: "2"         # cores to stress
            - name: CPU_LOAD
              value: "100"       # %
            - name: TARGET_NODES
              value: "chaos-lab-worker"   # leave blank for random
            - name: LIB_IMAGE
              value: "litmuschaos/go-runner:3.9.0"
        probe:
          - name: service-health
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 2
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Observe

```bash
# Watch node CPU via metric-server
kubectl top nodes -w

# Watch pod eviction / rescheduling
kubectl get events -n default --field-selector reason=Evicted

# Grafana query: node CPU utilisation
node_cpu_seconds_total{mode!="idle"}
```

## Who runs the stress tool?

LitmusChaos spawns a `stress-ng` Job on the *target node* itself using a DaemonSet that has `hostPID: true`. It does NOT exec into application pods.

## Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_CPU_CORE` | 2 | Cores to stress |
| `CPU_LOAD` | 100 | Per-core % |
| `TARGET_NODES` | "" | Node name(s) or blank for random |
| `TOTAL_CHAOS_DURATION` | 60 | s |

## Insights this experiment reveals

- Does your HPA detect slow responses caused by node-level CPU pressure?
- Does the scheduler evict lower-priority pods to free CPU for your service?
- Do you have CPU limits set on all containers? (No limits = noisy-neighbour risk)

---
*Part of the 100-Lesson Chaos Engineering Series.*
