# 26 — Pod Network Duplication

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that duplicates packets using `tc netem duplicate`, testing whether idempotency logic in your application correctly handles duplicate deliveries.

**Hypothesis**: When 20% of outgoing packets are duplicated, TCP deduplicates them transparently; application-level requests complete without errors or data corruption.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/pod-network-duplication \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-duplication-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-network-duplication
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: NETWORK_PACKET_DUPLICATION_PERCENTAGE
              value: "20"
            - name: PODS_AFFECTED_PERC
              value: "100"
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
        probe:
          - name: idempotency-check
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

## TCP vs UDP under duplication

- **TCP**: Sequence numbers deduplicate packets; application sees clean stream
- **UDP / QUIC**: Duplicate frames may be delivered; application must handle idempotency

## Why this matters for your application

| Pattern | At Risk? |
|---------|----------|
| REST API with idempotency keys | Safe |
| REST API without idempotency | Double-charge risk |
| Message queues (at-least-once) | Expected behavior |
| Event sourcing | Depends on deduplication logic |
| Database writes (INSERT) | Risk of duplicate rows |

## Test idempotency directly

```go
// In your Go handler, check for duplicate request IDs
func handler(w http.ResponseWriter, r *http.Request) {
    idempotencyKey := r.Header.Get("Idempotency-Key")
    if exists := cache.Get(idempotencyKey); exists {
        w.WriteHeader(http.StatusOK)
        w.Write(cachedResponse)
        return
    }
    // process...
    cache.Set(idempotencyKey, response, 24*time.Hour)
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
