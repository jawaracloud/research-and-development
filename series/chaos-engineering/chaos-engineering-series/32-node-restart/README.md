# 32 — Node Restart

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that reboots a Kubernetes worker node, validating that the cluster recovers fully — pods are rescheduled, the node rejoins, and services are uninterrupted.

**Hypothesis**: When a worker node is rebooted, the Kubernetes control plane reschedules all affected pods within 3 minutes, and p99 latency stays below 1000 ms during the recovery window.

## Prerequisites

- Requires privileged DaemonSet access to the node's host
- Safety: only use on non-control-plane nodes

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/node-restart \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-restart-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: node-restart
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "120"
            - name: REBOOT_COMMAND
              value: "sudo systemctl reboot"
            - name: TARGET_NODE
              value: "chaos-lab-worker"
        probe:
          - name: service-availability
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "10s"
              retry: 5
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Watch the recovery sequence

```bash
# Terminal 1 — watch node status
kubectl get nodes -w
# chaos-lab-worker   Ready      1m
# chaos-lab-worker   NotReady   0s  ← reboot triggered
# chaos-lab-worker   Ready      2m  ← rejoined

# Terminal 2 — watch pod rescheduling
kubectl get pods -n default -o wide -w

# Terminal 3 — watch node events
kubectl describe node chaos-lab-worker | tail -20
```

## Recovery Time Objective (RTO) Measurement

```promql
# Time between node NotReady and all pods Ready
min_over_time(kube_node_status_condition{condition="Ready",status="true"}[5m])
```

## What can go wrong

- If replicas all land on the restarted node, full outage during reboot
- Sticky sessions without session affinity can fail mid-request
- Jobs / StatefulSets may not reschedule automatically in all cases

## Anti-affinity to spread across nodes

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: target-app
          topologyKey: kubernetes.io/hostname
```

---
*Part of the 100-Lesson Chaos Engineering Series.*
