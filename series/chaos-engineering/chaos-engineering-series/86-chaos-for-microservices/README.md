# 86 — Chaos for Microservices

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

Microservices introduce unique resilience challenges: cascading failures, partial degradation, and deep call chains. This lesson shows how to structure chaos experiments across a multi-service architecture.

## Sample Microservices Architecture

```
Client
  └── API Gateway (target-app:8080)
        ├── User Service (user-svc:8081)
        │     └── PostgreSQL
        ├── Order Service (order-svc:8082)
        │     ├── PostgreSQL
        │     └── Queue Service (NATS)
        └── Notification Service (notif-svc:8083)
              └── Email Provider (external)
```

## Chaos Test Matrix

| Experiment | Expected behaviour |
|------------|-------------------|
| Kill `user-svc` pods | API gateway returns 503 with error body |
| Network partition `order-svc` → `postgres` | Orders degrade to read-only mode |
| Simulate `notif-svc` failure | Orders succeed; notification is queued for retry |
| Kill all `user-svc` AND `order-svc` | Circuit breaker opens; gateway serves cached home page |

## Step 1: ChaosEngine per service

```yaml
# Kill user-svc — test API gateway fallback
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: user-svc-kill
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=user-svc"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: PODS_AFFECTED_PERC
              value: "100"
        probe:
          - name: gateway-graceful-degradation
            type: httpProbe
            mode: OnChaos
            runProperties:
              probeTimeout: "5s"
              retry: 2
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/api/users/me"
              method:
                get:
                  criteria: "!="
                  responseCode: "500"  # must not be 500 (503 or 200 from cache ok)
```

## Step 2: Observing cascading failures

```bash
# Watch all services simultaneously
kubectl get pods -n default -w &

# Trace the call chain in Jaeger
# Filter by: error=true AND service=api-gateway
# You should see which downstream calls failed
```

## Step 3: Chaos test matrix Argo Workflow

```yaml
dag:
  tasks:
    - name: kill-user-svc
      template: pod-delete
      arguments:
        parameters: [{name: label, value: "app=user-svc"}]
    - name: kill-order-svc
      template: pod-delete
      dependencies: [kill-user-svc]   # serial to test one at a time
    - name: kill-both
      template: pod-delete-both
      dependencies: [kill-order-svc]  # final test: both down simultaneously
```

## Chaos test matrix tracking

| Date | Experiment | Hypothesis | Result | Action |
|------|-----------|-----------|--------|--------|
| 2026-01 | user-svc kill | 503 from GW | ✅ | — |
| 2026-01 | order-svc + db partition | read-only mode | ❌ | Add read replica fallback |

---
*Part of the 100-Lesson Chaos Engineering Series.*
