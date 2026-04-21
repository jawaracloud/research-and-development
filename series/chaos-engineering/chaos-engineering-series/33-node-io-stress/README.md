# 33 — Node I/O Stress

> **Type:** Tutorial  
> **Phase:** Kubernetes Chaos

## What you're building

A disk I/O stress experiment at the node level that saturates storage throughput with `stress-ng`, simulating a disk-heavy workload competing with your application.

**Hypothesis**: When node I/O is saturated, the application's read/write latency increases but remains within the SLO of < 2x baseline, and no data corruption occurs.

## Step 1: Install the experiment

```bash
kubectl apply -f \
  https://hub.litmuschaos.io/api/chaos/3.9.0?item=generic/node-io-stress \
  -n litmus
```

## Step 2: ChaosEngine

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-io-stress-engine
  namespace: litmus
spec:
  appinfo:
    appns: default
    applabel: "app=target-app"
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: node-io-stress
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "60"
            - name: FILESYSTEM_UTILIZATION_PERCENTAGE
              value: "80"   # % of disk to fill
            - name: CPU_CORES
              value: "1"    # also causes mild CPU load from I/O
            - name: NUMBER_OF_WORKERS
              value: "4"    # parallel I/O workers
            - name: TARGET_NODES
              value: "chaos-lab-worker"
        probe:
          - name: app-health
            type: httpProbe
            mode: Continuous
            runProperties:
              probeTimeout: "5s"
              retry: 2
              interval: "5s"
            httpProbe/inputs:
              url: "http://target-app.default.svc.cluster.local:8080/health"
              method:
                get:
                  criteria: "=="
                  responseCode: "200"
```

## Monitoring disk I/O

```promql
# Node disk read throughput
rate(node_disk_read_bytes_total[1m])

# Node disk write throughput
rate(node_disk_written_bytes_total[1m])

# I/O wait time (high = disk bottleneck)
rate(node_cpu_seconds_total{mode="iowait"}[1m])
```

## What `stress-ng` does

```bash
stress-ng --io 4 --hdd 2 --hdd-bytes 1G --timeout 60s
# Spawns 4 I/O workers hammering the disk with sequential writes
```

## Insights this experiment reveals

- Does your application log to local disk? Does log I/O contend with data I/O?
- Are your Kubernetes volumes on the same disk as the OS? (anti-pattern)
- Does the application use disk caching that is disrupted by I/O pressure?
- Does etcd performance degrade under node I/O stress?

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FILESYSTEM_UTILIZATION_PERCENTAGE` | 80 | % disk fill |
| `NUMBER_OF_WORKERS` | 4 | Parallel stress workers |
| `VOLUME_MOUNT_PATH` | /mnt | Mount point for stress files |

---
*Part of the 100-Lesson Chaos Engineering Series.*
