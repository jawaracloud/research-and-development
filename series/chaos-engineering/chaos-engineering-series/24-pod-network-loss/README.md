# 24 — Pod Network Loss

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that introduces packet loss on pod egress using `tc netem loss`, simulating a flaky network path or a degraded switch.

**Hypothesis**: When 20% of outgoing packets are dropped from `target-app` pods, the application-layer success rate remains > 99% (TCP retransmits absorb the loss).

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-network-loss \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-loss-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-network-loss
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: NETWORK_PACKET_LOSS_PERCENTAGE
              value: "20"
            - name: PODS_AFFECTED_PERC
              value: "100"
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
        probe:
          - name: error-rate-slo
            type: promProbe
            mode: Continuous
            runProperties:
              probeTimeout: "10s"
              retry: 1
              interval: "5s"
            promProbe/inputs:
              endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
              query: |
                sum(rate(http_requests_total{status=~"5.."}[1m]))
                / sum(rate(http_requests_total[1m]))
              comparator:
                criteria: "<"
                value: "0.01"
```

## Step 3: Monitor TCP retransmissions

```bash
# Exec into a pod and watch network stats during chaos
kubectl exec -it <pod-name> -n default -- ss -s
# Retrans counter should increase but recover

# Prometheus query for retransmission rate
node_netstat_Tcp_RetransSegs
```

## Understanding packet loss levels

| Loss % | Effect |
|--------|--------|
| 1–5% | Barely noticeable; TCP retransmits absorb |
| 10–20% | Noticeable latency increase; some timeouts |
| 50%+ | Severe; TCP throughput degrades significantly |
| 100% | Full partition — connection refused / timeouts |

## Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NETWORK_PACKET_LOSS_PERCENTAGE` | 100 | % packets dropped |
| `DESTINATION_IPS` | "" | Target IPs only |

## Insights this experiment reveals

- Does TCP retransmission absorb low-level packet loss transparently?
- At what loss % does application-level error rate breach SLO?
- Does DNS resolution fail under packet loss (UDP-based)?

---
*Part of the 100-Lesson Chaos Engineering Series.*
