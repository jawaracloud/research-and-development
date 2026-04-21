# 25 — Pod Network Corruption

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that corrupts packets in transit using `tc netem corrupt`, testing whether the application and its dependencies correctly handle checksum failures and protocol errors.

**Hypothesis**: When 5% of packets are corrupted on target pods, TCP's checksum layer discards corrupted packets and retransmits; the application-layer error rate stays < 1%.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-network-corruption \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-corruption-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-network-corruption
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: NETWORK_PACKET_CORRUPTION_PERCENTAGE
              value: "5"
            - name: PODS_AFFECTED_PERC
              value: "100"
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
        probe:
          - name: error-rate-probe
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

## What `tc netem corrupt` does

```bash
tc qdisc add dev eth0 root netem corrupt 5%
# Randomly flips bits in 5% of packets
# TCP detects checksum mismatch and requests retransmission
# UDP packets with corrupted data are silently delivered (!)
```

## UDP vs TCP Behavior Under Corruption

| Protocol | Behavior |
|----------|---------|
| TCP | Checksum failure → retransmit → transparent to app |
| UDP | Checksum failure → silently deliver corrupt data OR drop |
| HTTP/2 over TLS | Frame checksum fails → connection reset |

## Practical Scenarios This Simulates

- Faulty network interface card (NIC) hardware errors
- Bad cables / SFP modules in physical data centers
- Memory bit-flip in a network switch ASIC

## Insights this experiment reveals

- Does your app use UDP-based protocols (DNS, syslog, metrics) that are vulnerable to silent corruption?
- Does your TLS configuration handle MACs correctly?
- Does your serialization layer (protobuf, JSON) validate data integrity?

---
*Part of the 100-Lesson Chaos Engineering Series.*
