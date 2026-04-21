# 89 — Security Chaos

> **Type:** How-To  
> **Phase:** Advanced Topics & GameDay

## Overview

This lesson explores security-oriented chaos scenarios — simulating credential rotation failures, secret expiry, and compromised service accounts to test your secret management resilience.

> **Note:** Security chaos should **only** be run in controlled lab environments. Never simulate credential failures against production without explicit approval.

## Security Chaos Scenarios

| Scenario | Simulates | Tooling |
|----------|-----------|---------|
| Expire database password | Credential rotation failure | kubectl patch |
| Revoke Kubernetes service account | RBAC misconfiguration | kubectl delete |
| Rotate TLS certificates | Cert renewal failure | cert-manager |
| Orphaned secrets | Secret management drift | Chaos Mesh IOChaos |
| Network policy enforcement | Zero-trust misconfiguration | Kubernetes NetworkPolicy |

## Step 1: Secret rotation chaos

```bash
# Simulate: DB password rotated but app not updated

# Create new password
kubectl create secret generic db-credentials-v2 \
  --from-literal=password="newpass456" -n default

# Force app to use old secret (simulate rotation failure)
# App continues to use old password → DB connection fails
kubectl patch deployment target-app -n default \
  --type='json' -p='[{
    "op":"replace",
    "path":"/spec/template/spec/containers/0/env/0/valueFrom/secretKeyRef/name",
    "value":"db-credentials-v1"  
  }]'

# Expected: app connection errors until secret is updated
```

## Step 2: Service account chaos

```bash
# Delete the service account used by target-app
kubectl delete serviceaccount target-app-sa -n default

# Watch for RBAC permission errors in logs
kubectl logs -l app=target-app -n default | grep "403\|forbidden\|cannot"
```

## Step 3: NetworkPolicy enforcement test

```yaml
# Apply strict deny-all network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}    # applies to ALL pods
  policyTypes: [Ingress, Egress]
  # No ingress/egress rules = deny all
```

```bash
kubectl apply -f deny-all.yaml

# Test that services can't communicate
kubectl exec -it debug-pod -- curl http://target-app:8080/health
# Connection refused — ✅ policy is enforced

# Remove the policy (restore connectivity)
kubectl delete networkpolicy deny-all -n default
```

## Step 4: IRSA / Workload Identity chaos

```bash
# On AWS EKS: revoke IRSA role trust
aws iam delete-role-policy \
  --role-name eks-target-app-role \
  --policy-name S3ReadPolicy

# Watch for AWS SDK errors in app logs
kubectl logs -l app=target-app | grep "AccessDenied"
```

## Insights this experiment reveals

- Does secret rotation cause downtime?
- Is RBAC least-privilege correctly enforced?
- Are network policies preventing unauthorised cross-service communication?

---
*Part of the 100-Lesson Chaos Engineering Series.*
