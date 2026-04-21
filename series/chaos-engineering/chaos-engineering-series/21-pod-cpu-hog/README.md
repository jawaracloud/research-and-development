# 21 — Pod CPU Hog

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

A CPU stress experiment that pins CPU cores inside target pods, simulating a runaway process or CPU-bound computation spike.

**Hypothesis**: When CPU is saturated on 50% of `target-app` pods, the HTTP service continues to respond within 1000 ms p99 and error rate stays < 1%.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-cpu-hog \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: cpu-hog-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-cpu-hog
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: CPU_CORES
              value: "1"        # number of cores to stress
            - name: CPU_LOAD
              value: "100"      # % load per core (0–100)
            - name: PODS_AFFECTED_PERC
              value: "50"
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
        probe:
          - name: latency-check
            type: promProbe
            mode: Continuous
            runProperties:
              probeTimeout: "10s"
              retry: 1
              interval: "5s"
            promProbe/inputs:
              endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
              query: |
                histogram_quantile(0.99,
                  rate(http_request_duration_seconds_bucket[1m]))
              comparator:
                criteria: "<"
                value: "1.0"
```

## Step 3: Apply and observe

```bash
kubectl apply -f cpu-hog-engine.yaml

# Watch CPU usage surge
kubectl top pods -n default -w
# NAME                    CPU(cores)   MEMORY
# target-app-abc   999m         50Mi   ← pegged at 1 CPU

# Watch experiment
kubectl get chaosresult -n litmus -w
```

## Step 4: What to look for

In Grafana, monitor:
- `container_cpu_usage_seconds_total` — should spike to requested `CPU_CORES`
- `http_request_duration_seconds` — latency may increase but should stay under threshold
- Pod `requests/limits` — did HPA trigger a scale-out?

## Key environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CPU_CORES` | 1 | Cores to stress |
| `CPU_LOAD` | 100 | % load (0–100) |
| `TOTAL_CHAOS_DURATION` | 60 | Seconds |
| `PODS_AFFECTED_PERC` | 100 | % of matching pods |
| `CONTAINER_RUNTIME` | docker | docker / containerd / crio |

## Insights this experiment reveals

- Does the app successfully serve requests despite CPU contention?
- Does HPA scale out additional replicas?
- Does the Kubernetes scheduler re-balance load to healthy pods?

---
*Part of the 100-Lesson Chaos Engineering Series.*
