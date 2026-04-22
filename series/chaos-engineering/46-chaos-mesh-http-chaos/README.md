# 46 — Chaos Mesh HTTP Chaos

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Use Chaos Mesh's `HTTPChaos` to inject faults at the HTTP layer — latency, aborted connections, and response body replacement — without modifying application code.

**Hypothesis**: When 50% of HTTP responses from the downstream `postgres-api` service are aborted, `target-app` falls back to its cached response within 200 ms with no returning 5xx errors to the caller.

## Step 1: HTTP abort (simulate upstream errors)

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: HTTPChaos
metadata:
  name: http-abort
  namespace: default
spec:
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  target: Request          # or Response
  port: 8080
  path: "/api/*"
  method: GET
  abort: true              # abort 100% of matching requests
  duration: "60s"
```

## Step 2: HTTP latency (slow responses)

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: HTTPChaos
metadata:
  name: http-latency
  namespace: default
spec:
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  target: Response
  port: 8080
  path: "/echo"
  delay: "500ms"
  duration: "60s"
```

## Step 3: HTTP response replacement

Inject a fake error body to test client-side error parsing:

```yaml
spec:
  target: Response
  port: 8080
  path: "/health"
  replace:
    code: 503
    body: eyJlcnJvciI6InNlcnZpY2UgdW5hdmFpbGFibGUifQ==  # base64 JSON
    headers:
      Content-Type: application/json
```

## Decoding the replace body

```bash
echo '{"error":"service unavailable"}' | base64
# eyJlcnJvciI6InNlcnZpY2UgdW5hdmFpbGFibGUifQ==
```

## Observing the chaos

```bash
kubectl apply -f http-chaos.yaml

# Test from inside cluster
kubectl exec -it debug-pod -- curl -v http://target-app:8080/echo
# Should see connection abort or 503

kubectl get httpchaos -n default
kubectl describe httpchaos http-abort -n default
```

## Use cases

| Scenario | HTTPChaos config |
|----------|-----------------|
| Upstream returns 500 | `replace.code: 500` |
| Upstream is slow | `delay: "2s"` |
| Upstream drops connection | `abort: true` |
| Upstream returns wrong body | `replace.body: <base64>` |
| Inject headers | `replace.headers: {X-Chaos: "true"}` |

---
*Part of the 100-Lesson Chaos Engineering Series.*
