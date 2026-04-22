# 27 — Container Kill

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

An experiment that kills a specific container within a pod (without deleting the pod itself), testing whether Kubernetes' container restart logic recovers correctly without impacting the pod's network identity.

**Hypothesis**: When the `target-app` container is killed inside a running pod, Kubernetes restarts it within 30 seconds and requests continue to succeed with < 5% error rate during the restart window.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/container-kill \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: container-kill-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: container-kill
      spec:
        components:
          env:
            - name: TARGET_CONTAINER
              value: "target-app"
            - name: TOTAL_CHAOS_DURATION
              value: "20"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: PODS_AFFECTED_PERC
              value: "50"
            - name: SIGNAL
              value: "SIGKILL"     # or SIGTERM for graceful
            - name: CONTAINER_RUNTIME
              value: containerd
            - name: SOCKET_PATH
              value: /run/containerd/containerd.sock
        probe:
          - name: health-check
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 3
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Step 3: Observe the restart cycle

```bash
kubectl get pods -n default -w
# NAME               READY   STATUS    RESTARTS
# target-app-abc     0/1     Error     0      ← container killed
# target-app-abc     0/1     CrashLoopBackOff 1
# target-app-abc     1/1     Running   1      ← restarted

kubectl describe pod target-app-abc -n default | grep -A5 "Last State"
```

## Container Kill vs Pod Delete

| Aspect | Container Kill | Pod Delete |
|--------|---------------|------------|
| Pod IP changes | No | Yes |
| Service endpoints | Unchanged | Briefly removed |
| Restart count | Increments | Resets |
| Use case | Test restart policy | Test scheduling |

## SIGTERM vs SIGKILL

| Signal | Behaviour |
|--------|-----------|
| `SIGTERM` | Graceful shutdown; app has time to drain connections |
| `SIGKILL` | Immediate termination; no cleanup possible |

Use SIGTERM to validate graceful shutdown logic. Use SIGKILL to simulate OOM or kernel kill.

---
*Part of the 100-Lesson Chaos Engineering Series.*
