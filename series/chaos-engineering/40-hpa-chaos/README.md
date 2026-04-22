# 40 — HPA Chaos

> **Type:** How-To  
> **Phase:** Kubernetes Chaos

## Overview

This experiment injects chaos simultaneously with HPA (HorizontalPodAutoscaler) scale-up events, testing whether your application handles rapid pod creation under load correctly.

**Hypothesis**: When CPU load causes the HPA to scale `target-app` from 2 to 5 replicas, the new pods pass readiness checks within 20 seconds and traffic is evenly distributed to all replicas.

## Prerequisites

- `metrics-server` installed
- HPA configured for `target-app`

## Step 1: Configure HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: target-app-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: target-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 15   # fast scale-up
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 60   # slow scale-down
```

```bash
kubectl apply -f hpa.yaml
kubectl get hpa target-app-hpa -n default -w
```

## Step 2: Trigger HPA scale-up + chaos simultaneously

```bash
# Terminal 1 — generate CPU load via k6
cat <<'EOF' > load.js
import http from 'k6/http';
import { sleep } from 'k6';
export const options = { vus: 50, duration: '120s' };
export default () => { http.get('http://localhost:8080/echo'); sleep(0.1); }
EOF
k6 run load.js

# Terminal 2 — simultaneously apply CPU hog chaos
kubectl apply -f ../21-pod-cpu-hog/cpu-hog-engine.yaml

# Terminal 3 — watch HPA reactions
kubectl get hpa target-app-hpa -n default -w
kubectl get pods -n default -w
```

## Observing scale-up readiness race

```promql
# Pods not yet ready during scale-up
kube_deployment_status_replicas_unavailable{deployment="target-app"}

# Traffic hitting unready pods (kube-proxy should prevent this)
sum(rate(http_requests_total{status="503"}[30s]))
```

## Common failure modes discovered

| Failure | Symptom |
|---------|---------|
| Startup probe missing | Traffic sent before app is ready |
| Init container slow | Scale-up takes much longer than expected |
| readinessProbe too lenient | Requests fail on new pods |
| HPA stabilization too slow | Can't respond to sudden spikes |

---
*Part of the 100-Lesson Chaos Engineering Series.*
