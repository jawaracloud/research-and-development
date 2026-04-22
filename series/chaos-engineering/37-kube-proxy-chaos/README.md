# 37 — kube-proxy Chaos

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment targeting kube-proxy (the process managing iptables/IPVS rules for Kubernetes Services), validating that service traffic is disrupted when kube-proxy is unavailable and recovers when it returns.

**Hypothesis**: When kube-proxy is stopped on a node for 30 seconds, existing TCP connections to Kubernetes Services continue working (iptables rules persist), but new connections to pods rescheduled after the failure may be affected.

## Background: what kube-proxy does

kube-proxy runs as a DaemonSet on every node and programs iptables/IPVS rules that forward `ClusterIP` service traffic to backend pods. Crucially:
- **Existing iptables rules persist** even if kube-proxy stops
- **New endpoints** (pods added/removed) won't be reflected until kube-proxy restarts

## Method 1: Stop kube-proxy DaemonSet pod

```bash
# Find kube-proxy pod on the target node
kubectl get pods -n kube-system -l component=kube-proxy -o wide

# Delete it (DaemonSet will restart it)
kubectl delete pod -n kube-system <kube-proxy-pod-name>

# Race: delete target-app pod immediately after kube-proxy stops
kubectl delete pod -n default -l app=target-app --grace-period=0
# A new endpoint appears; kube-proxy is down — will old pods still receive traffic?
```

## Method 2: Scale kube-proxy DaemonSet replicas to 0 (dangerous!)

```bash
# Suspend the DaemonSet (do NOT do in production)
kubectl patch daemonset kube-proxy -n kube-system \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-existing":"true"}}}}}'

# Restore
kubectl patch daemonset kube-proxy -n kube-system \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"}}}}}'
```

## What to observe

```bash
# Existing service calls should continue (iptables rules persist)
curl http://target-app.default.svc.cluster.local:8080/health   # ✅

# After pod reschedule during kube-proxy downtime:
kubectl delete pod -n default -l app=target-app --grace-period=0
curl http://target-app.default.svc.cluster.local:8080/health   # Depends on timing
```

## iptables rules inspection

```bash
# On the node (exec into kind container)
docker exec -it chaos-lab-worker iptables -t nat -L KUBE-SERVICES --line-numbers | head -30
```

## Insights this experiment reveals

- Does your service mesh (Istio/Linkerd) bypass kube-proxy (it often does)?
- Are your services tolerant of endpoint update delays?

---
*Part of the 100-Lesson Chaos Engineering Series.*
