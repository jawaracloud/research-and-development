# 36 — CoreDNS Chaos

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that disrupts CoreDNS pods, testing how service discovery and DNS-dependent connections behave under DNS failures.

**Hypothesis**: When CoreDNS pods are deleted, Kubernetes respawns them within 15 seconds, and service-to-service connections relying on DNS recover with < 5% request failure rate.

## Why CoreDNS is critical

Every pod-to-pod call using a Kubernetes service name (`http://target-app.default.svc.cluster.local`) goes through CoreDNS. DNS failure means:
- New connections fail immediately
- Long-lived connections (HTTP keep-alive) may survive temporarily
- Service mesh sidecar caches may provide short-term resilience

## Step 1: Delete CoreDNS pods

```bash
# Find CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Delete both (Deployment will restart them)
kubectl delete pods -n kube-system -l k8s-app=kube-dns

# Watch recovery
kubectl get pods -n kube-system -l k8s-app=kube-dns -w
```

## Step 2: Use LitmusChaos pod-delete targeting CoreDNS

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: coredns-chaos-engine
  namespace: litmus
spec:
  appinfo:
    appns: kube-system
    applabel: "k8s-app=kube-dns"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  annotationCheck: "false"
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "false"
            - name: PODS_AFFECTED_PERC
              value: "100"   # delete all CoreDNS pods
        probe:
          - name: dns-resolution-check
            type: cmdProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 3
              interval: "5s"
            cmdProbe/inputs:
              command: "nslookup target-app.default.svc.cluster.local"
              comparator:
                type: string
                criteria: contains
                value: "Address"
              source: inline
```

## Step 3: Measure DNS resolution during chaos

```bash
# In another terminal — rapid DNS lookups
while true; do
  dig @10.96.0.10 target-app.default.svc.cluster.local +short
  sleep 0.5
done
```

## Tuning DNS resilience

```yaml
# Increase DNS TTL to reduce re-resolution frequency
# (in application code: use longer TCP keepalive, not short DNS TTL)

# CoreDNS: increase replica count for HA
kubectl scale deployment coredns -n kube-system --replicas=3

# Add ndots:2 to reduce external DNS lookups
# (in pod dnsConfig)
spec:
  dnsConfig:
    options:
      - name: ndots
        value: "2"
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
