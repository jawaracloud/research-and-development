# 56 — Service Mesh Chaos (Istio)

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

Istio's `VirtualService` allows injecting faults — delays and HTTP aborts — without touching application code. This lesson shows how to use Istio fault injection as a lightweight alternative to Chaos Mesh for HTTP-level chaos.

## Prerequisites

```bash
# Install Istio (demo profile for local testing)
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
kubectl rollout restart deployment target-app
```

## Istio Fault Injection: Delay

Add 2 s delay to 50% of traffic to `target-app`:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: target-app-fault
  namespace: default
spec:
  hosts: [target-app]
  http:
    - fault:
        delay:
          percentage:
            value: 50.0
          fixedDelay: 2s
      route:
        - destination:
            host: target-app
            port:
              number: 8080
```

```bash
kubectl apply -f virtual-service-delay.yaml
```

## Istio Fault Injection: Abort

Return 503 for 20% of requests:

```yaml
http:
  - fault:
      abort:
        percentage:
          value: 20.0
        httpStatus: 503
    route:
      - destination:
          host: target-app
          port:
            number: 8080
```

## Combining delay + abort

```yaml
http:
  - fault:
      delay:
        percentage:
          value: 80.0
        fixedDelay: 1s
      abort:
        percentage:
          value: 10.0
        httpStatus: 503
    route:
      - destination:
          host: target-app
```

## Scoping fault injection by header

Inject faults only for canary traffic:

```yaml
http:
  - match:
      - headers:
          X-Chaos-Test:
            exact: "true"
    fault:
      delay:
        percentage: { value: 100 }
        fixedDelay: 3s
    route:
      - destination:
          host: target-app
  - route:
      - destination:
          host: target-app
```

## Undo injection

```bash
kubectl delete virtualservice target-app-fault -n default
```

## vs Chaos Mesh HTTPChaos

| Feature | Istio VS | Chaos Mesh HTTPChaos |
|---------|----------|---------------------|
| Requires Istio | Yes | No |
| Header-based matching | Yes | Yes |
| Response body replace | No | Yes |
| Request abort | Yes | Yes |

---
*Part of the 100-Lesson Chaos Engineering Series.*
