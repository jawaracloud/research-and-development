# 29 — Node Memory Hog

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

A node-level memory exhaustion experiment that consumes RAM on a worker node until the kernel's OOM Killer activates, simulating a runaway process or memory leak on the host.

**Hypothesis**: When node memory is exhausted, the OOM Killer evicts lower-priority pods first (Best Effort → Burstable → Guaranteed), and Guaranteed QoS `target-app` pods survive.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/node-memory-hog \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-memory-hog-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: node-memory-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: MEMORY_PERCENTAGE
              value: "90"      # % of node memory to consume
            - name: TARGET_NODES
              value: ""        # blank = random node
        probe:
          - name: health-probe
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

## Kubernetes QoS Classes and OOM Eviction Priority

The OOM Killer processes pods in this order (most likely to be killed first):

```
1. BestEffort    (no requests or limits set)
2. Burstable     (requests < limits)
3. Guaranteed    (requests == limits)
```

To make `target-app` Guaranteed QoS:

```yaml
resources:
  requests:
    cpu: 200m
    memory: 128Mi
  limits:
    cpu: 200m        # must == requests
    memory: 128Mi    # must == requests
```

## Step 3: Observe

```bash
# Watch node memory usage
kubectl top nodes

# Watch OOM events
kubectl get events --all-namespaces | grep OOM

# Prometheus: node memory pressure
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
```

## Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY_PERCENTAGE` | 90 | % of node RAM to consume |
| `NODE_MEMORY_MEBIBYTES` | "" | Absolute amount (overrides %) |

## Insights this experiment reveals

- Are all your pods using correct QoS classes?
- Which pods are evicted first — is the priority order correct?
- Does the app recover after evicted pods are rescheduled to another node?

---
*Part of the 100-Lesson Chaos Engineering Series.*
