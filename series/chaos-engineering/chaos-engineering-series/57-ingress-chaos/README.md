# 57 — Ingress Chaos

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Introduce chaos at the ingress/load-balancer layer — simulating a flaky or overloaded ingress controller, testing whether your application handles upstream LB failures correctly.

## Ingress Layer Chaos Techniques

| Method | Description |
|--------|------------|
| Delete ingress controller pods | Simulates controller crash |
| Inject latency via Toxiproxy in front of ingress | Simulates slow LB |
| Wrong backend configuration | Tests routing fallback |
| TLS termination failure | Tests cert expiry handling |

## Method 1: Delete nginx-ingress controller pods

```bash
# Find ingress controller
kubectl get pods -n ingress-nginx

# Delete (deployment restarts it)
kubectl delete pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Watch recovery
kubectl get pods -n ingress-nginx -w
```

**Hypothesis**: During the 10–15 second restart window, new connections return 502/504 from the cloud LB; existing keepalive connections continue.

## Method 2: Proxy ingress through Toxiproxy

```bash
# Create Toxiproxy proxy for ingress
curl -XPOST http://localhost:8474/proxies -d '{
  "name": "ingress",
  "listen": "0.0.0.0:8090",
  "upstream": "localhost:80"
}'

# Add latency toxic
curl -XPOST http://localhost:8474/proxies/ingress/toxics -d '{
  "name": "ingress-latency",
  "type": "latency",
  "attributes": {"latency": 1000}
}'

# Test through proxy
curl -H "Host: target-app.local" http://localhost:8090/health
```

## Method 3: LitmusChaos pod-delete on ingress-nginx

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: ingress-chaos
  namespace: litmus
spec:
  appinfo:
    appns: ingress-nginx
    applabel: "app.kubernetes.io/name=ingress-nginx"
    appkind: deployment
  annotationCheck: "false"
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: PODS_AFFECTED_PERC
              value: "50"
```

## Observing 502s and recovery

```bash
# Continuously curl the ingress
while true; do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://target-app.local/health)
  echo "$(date +%T) HTTP $code"
  sleep 1
done
```

## Insights this experiment reveals

- Does your ingress controller have > 1 replica?
- Does your cloud LB health-check the ingress pods frequently enough?
- Do clients get a clean 503 or a TCP RST during rollover?

---
*Part of the 100-Lesson Chaos Engineering Series.*
