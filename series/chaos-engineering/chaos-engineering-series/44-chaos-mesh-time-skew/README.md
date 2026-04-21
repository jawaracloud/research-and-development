# 44 — Chaos Mesh Time Skew

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Use Chaos Mesh's `TimeChaos` to introduce clock skew into pods, testing whether time-sensitive logic (JWT expiry, session timeouts, distributed locks, rate limiters) handles drift gracefully.

**Hypothesis**: When the system clock of `target-app` pods is skewed forward by 1 hour, JWT tokens validated against an unaffected external service are rejected (expected), and the error is surfaced with a clear `401` — not a 500 or silent failure.

## Why clock skew matters

| Component | Sensitivity to clock skew |
|-----------|--------------------------|
| JWT validation (`exp`, `iat` claims) | Seconds to minutes |
| TLS certificate validity | Minutes |
| Distributed locks (Redis TTL-based) | Milliseconds |
| Rate limiting (sliding window) | Seconds |
| Kerberos / SPIFFE | < 5 minutes |
| Database MVCC / transactions | Milliseconds |

## Step 1: TimeChaos CR

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: TimeChaos
metadata:
  name: clock-skew-forward
  namespace: default
spec:
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  timeOffset: "+1h"   # skew clock 1 hour forward
  clockIds:
    - CLOCK_REALTIME
    - CLOCK_MONOTONIC
  duration: "60s"
```

```bash
kubectl apply -f time-chaos.yaml

# Verify skew inside a pod
kubectl exec -it $(kubectl get pod -l app=target-app -o name | head -1) -- date
# Should show time 1 hour ahead
```

## Step 2: Test with negative skew (clock going backward)

```yaml
spec:
  timeOffset: "-30m"   # skew clock 30 min backward
```

Backward skew can break monotonic assumptions in logs and distributed systems.

## Clock IDs

| Clock ID | Used for |
|----------|---------|
| `CLOCK_REALTIME` | Wall clock (`time.Now()`) |
| `CLOCK_MONOTONIC` | Duration measurement |
| `CLOCK_BOOTTIME` | Time since boot |

## Go: clock-aware application patterns

```go
// Don't use time.Now() for security-sensitive checks
// Instead, accept time as a parameter (for testability)
func isTokenValid(token *jwt.Token, now time.Time) bool {
    claims := token.Claims.(jwt.MapClaims)
    return claims.VerifyExpiresAt(now.Unix(), true)
}
```

## Insights this experiment reveals

- Does your JWT library use wall clock or monotonic clock for expiry?
- Do your distributed locks have clock-skew-tolerant leases?
- Does NTP keep all your pods synchronized? (Pod time is cloned from node)

---
*Part of the 100-Lesson Chaos Engineering Series.*
