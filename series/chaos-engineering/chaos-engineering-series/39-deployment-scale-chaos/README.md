# 39 — Deployment Scale Chaos

> **Type:** How-To  
> **Phase:** Kubernetes Chaos

## Overview

This experiment manually scales a Deployment to zero replicas mid-traffic, simulating a misconfigured rollout, a faulty CD pipeline action, or an accidental `kubectl scale --replicas=0` in production.

**Hypothesis**: When `target-app` is scaled to zero, requests fail with `503 Service Unavailable`. When scaled back to 3, the service recovers within the readiness probe window (< 30 seconds), and the error rate drops to < 1%.

## This is a simple but revealing test

Real incidents that scaling chaos reveals:
- Missing readiness probes → traffic sent to not-yet-ready pods
- Missing PodDisruptionBudgets → full scale-down is possible
- Misconfigured CDN → no fallback when origin is gone
- Client retry logic → does your client retry 503 responses?

## Step 1: Scale to zero with a Go test

```go
// hypothesis_test.go
package chaos_test

import (
    "net/http"
    "os/exec"
    "testing"
    "time"
)

func TestScaleChaos(t *testing.T) {
    url := "http://localhost:8080/health"

    // Scale to zero
    _ = exec.Command("kubectl", "scale", "deployment", "target-app",
        "-n", "default", "--replicas=0").Run()

    // Expect 503s
    time.Sleep(10 * time.Second)
    resp, err := http.Get(url)
    if err == nil && resp.StatusCode == 200 {
        t.Error("Expected 503 when scaled to zero")
    }

    // Scale back
    _ = exec.Command("kubectl", "scale", "deployment", "target-app",
        "-n", "default", "--replicas=3").Run()

    // Wait for recovery
    deadline := time.Now().Add(60 * time.Second)
    for time.Now().Before(deadline) {
        resp, err := http.Get(url)
        if err == nil && resp.StatusCode == 200 {
            t.Log("✅ Service recovered")
            return
        }
        time.Sleep(2 * time.Second)
    }
    t.Error("Service did not recover within 60s")
}
```

```bash
go test -v -run TestScaleChaos ./...
```

## Step 2: Using kubectl directly

```bash
# Scale to zero
kubectl scale deployment target-app -n default --replicas=0

# Watch endpoints disappear
kubectl get endpoints target-app -n default -w
# target-app  <none>  ← no backends!

# Restore
kubectl scale deployment target-app -n default --replicas=3
kubectl rollout status deployment/target-app -n default
```

## Protecting against accidental scale-down

```yaml
# PodDisruptionBudget (prevents scale below minAvailable)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: target-app-pdb
spec:
  minAvailable: 1   # always at least 1 pod alive
  selector:
    matchLabels:
      app: target-app
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
