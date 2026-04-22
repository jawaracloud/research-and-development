# 23 — Pod Network Latency

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that injects artificial network latency on the egress traffic of target pods using Linux Traffic Control (`tc netem`), simulating a slow upstream service or degraded network path.

**Hypothesis**: When 100 ms network latency is added to all `target-app` pods, p99 latency stays below 600 ms and error rate stays < 1%.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-network-latency \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-latency-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-network-latency
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: NETWORK_LATENCY
              value: "100"       # ms of added latency
            - name: JITTER
              value: "10"        # ms random jitter (±)
            - name: PODS_AFFECTED_PERC
              value: "100"
            - name: TARGET_CONTAINER
              value: "target-app"
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
            - name: DESTINATION_IPS
              value: ""          # empty = all egress
        probe:
          - name: latency-slo
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
                  rate(http_request_duration_seconds_bucket[1m])) < 0.6
              comparator:
                criteria: "=="
                value: "1"
```

## Step 3: Apply and measure

```bash
kubectl apply -f network-latency-engine.yaml

# From another terminal, continuously probe the app
watch -n1 'curl -o /dev/null -s -w "%{time_total}\n" \
  http://localhost:8080/health'
```

## Understanding tc netem

LitmusChaos uses `tc qdisc add dev eth0 root netem delay Xms Yjitter` inside the pod's network namespace:

```bash
# What it runs internally:
tc qdisc add dev eth0 root netem delay 100ms 10ms
# Adds 100ms ± 10ms uniform jitter to all outgoing packets
```

## Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NETWORK_LATENCY` | 2000 | ms of latency added |
| `JITTER` | 0 | ms of random variance |
| `DESTINATION_IPS` | "" | Comma-separated IPs (empty = all) |
| `DESTINATION_HOSTS` | "" | Comma-separated hostnames |

## Insights this experiment reveals

- Does your service's HTTP client timeout budget account for upstream latency?
- Do you have circuit breakers that trip before the user feels the impact?
- Does the retry logic make things worse (retry storm)?

---
*Part of the 100-Lesson Chaos Engineering Series.*
