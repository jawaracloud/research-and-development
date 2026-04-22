# 58 — DNS Chaos

> **Type:** Tutorial  
> **Phase:** Application & Network Chaos

## What you're building

Inject DNS resolution failures targeting specific service names, testing how your application handles `NXDOMAIN` and DNS timeout at the application-layer.

## DNS Failure Modes

| Failure | What it looks like |
|---------|-------------------|
| `NXDOMAIN` | Domain does not exist → immediate error |
| DNS timeout | Query never returns → slow failure |
| Wrong IP | Name resolves to wrong address → connection refused |
| Partial failure | Half of DNS pods down → intermittent errors |

## Method 1: Chaos Mesh DNSChaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: DNSChaos
metadata:
  name: dns-failure
  namespace: default
spec:
  action: error       # or "random" for random IP
  mode: all
  selector:
    namespaces: [default]
    labelSelectors:
      app: target-app
  patterns:
    - "postgres.default.svc.cluster.local"   # only this domain fails
  duration: "60s"
```

```bash
kubectl apply -f dns-chaos.yaml

# From inside target-app pod, DNS should fail
kubectl exec -it <target-app-pod> -- \
  nslookup postgres.default.svc.cluster.local
# ** server can't find postgres...: NXDOMAIN
```

## Method 2: CoreDNS rewrite rule (wrong IP chaos)

```yaml
# Patch CoreDNS ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
      rewrite name exact postgres.default.svc.cluster.local 127.0.0.1
      kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
      }
      forward . /etc/resolv.conf
    }
```

## Go: DNS-aware error handling

```go
// Detect DNS errors specifically
import "net"

err := callUpstream(ctx)
var dnsErr *net.DNSError
if errors.As(err, &dnsErr) {
    if dnsErr.IsNotFound {
        // NXDOMAIN — no point retrying
        return http.StatusServiceUnavailable, "service not found"
    }
    if dnsErr.IsTimeout {
        // DNS timeout — retry with backoff
    }
}
```

## DNS Caching as a resilience measure

```go
// Use a custom resolver with caching
// github.com/miekg/dns or HTTP-level DNS caching

db, err := sql.Open("postgres", "host=10.96.0.15 ...")
// Use the ClusterIP directly (pre-resolved) to bypass DNS
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
