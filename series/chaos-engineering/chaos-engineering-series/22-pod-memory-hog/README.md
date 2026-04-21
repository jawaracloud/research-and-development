# 22 — Pod Memory Hog

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

A memory exhaustion experiment that steadily allocates memory inside target pods until hitting a configured limit, simulating a memory leak.

**Hypothesis**: When pods consume 90% of their memory limit, the app continues serving requests and Kubernetes eventually OOMKills and restarts the affected pods automatically.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-memory-hog \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: memory-hog-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-memory-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: MEMORY_CONSUMPTION
              value: "100"      # MB to consume
            - name: PODS_AFFECTED_PERC
              value: "50"
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
        probe:
          - name: health-check
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 3
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Observe memory and OOM events

```bash
# Watch memory usage
kubectl top pods -n default -w

# Watch for OOMKilled restarts
kubectl get pods -n default -w
# NAME              READY   STATUS      RESTARTS
# target-app-abc    0/1     OOMKilled   1   ← expected

# Check events
kubectl describe pod <pod-name> -n default | grep -A5 "OOM"
```

## Step 4: What to look for in Grafana

```promql
# Memory usage vs limit ratio
container_memory_working_set_bytes{pod=~"target-app.*"}
/
container_spec_memory_limit_bytes{pod=~"target-app.*"}
```

```promql
# OOMKill events
kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}
```

## Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY_CONSUMPTION` | 500 | MB to consume |
| `TOTAL_CHAOS_DURATION` | 60 | Seconds |
| `PODS_AFFECTED_PERC` | 100 | % of pods |

## Insights this experiment reveals

- Is the memory limit set correctly in pod resources?
- Does Kubernetes restart OOMKilled pods fast enough?
- Does the app lose in-flight requests on OOMKill?
- Is there a memory leak or allocation spike in the app code?

---
*Part of the 100-Lesson Chaos Engineering Series.*
