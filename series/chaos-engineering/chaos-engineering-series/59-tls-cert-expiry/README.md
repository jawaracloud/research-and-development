# 59 — TLS Certificate Expiry

> **Type:** How-To  
> **Phase:** Application & Network Chaos

## Overview

Simulate expired or invalid TLS certificates to test whether your services detect, alert on, and correctly reject or handle certificate failures before they cause production outages.

## Why this matters

TLS certificate expiry is one of the most common causes of outages that chaos engineering can prevent. Real examples:
- **Slack (2019)**: Expired certificate caused widespread service disruption
- **Spotify (2018)**: Expired cert in a load balancer took hours to debug
- Root cause: no automated certificate renewal monitoring

## Method 1: Generate an expired test certificate

```bash
# Generate a self-signed cert that expired 1 day ago
openssl req -x509 -newkey rsa:2048 -keyout expired.key -out expired.crt \
  -days -1 \      # negative days = already expired
  -nodes \
  -subj "/CN=target-app.default.svc.cluster.local"

# Create K8s secret with expired cert
kubectl create secret tls target-app-expired-tls \
  --cert=expired.crt --key=expired.key -n default

# Patch the Ingress to use the expired cert
kubectl patch ingress target-app -n default \
  --type='json' -p='[{"op":"replace","path":"/spec/tls/0/secretName","value":"target-app-expired-tls"}]'
```

## Method 2: Chaos Mesh to manipulate cert mtime

```yaml
# Use IOChaos to fake file attributes on cert files
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: cert-corruption
  namespace: default
spec:
  action: attrOverride
  mode: one
  selector:
    namespaces: [default]
    labelSelectors:
      app: cert-manager
  volumeMountPath: /etc/tls
  attr:
    mtime:
      nsec: 1000000000    # set mtime to epoch + 1s (very old)
  duration: "30s"
```

## Method 3: Short-lived cert with cert-manager

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: short-lived
  namespace: default
spec:
  secretName: target-app-tls
  duration: 1m           # expires in 1 minute!
  renewBefore: 30s
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
  dnsNames: ["target-app.default.svc.cluster.local"]
```

## Monitoring certificate expiry

```promql
# Cert expiry time remaining (cert-manager exporter)
certmanager_certificate_expiration_timestamp_seconds - time() < 86400
# Alert if cert expires within 24 hours
```

## Go: certificate validation

```go
// Always verify TLS certificates in production
client := &http.Client{
    Transport: &http.Transport{
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: false,  // NEVER set to true in production
            MinVersion:         tls.VersionTLS12,
        },
    },
}
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
