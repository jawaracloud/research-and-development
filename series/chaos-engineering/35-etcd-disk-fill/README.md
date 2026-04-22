# 35 — etcd Disk Fill

> **Type:** How-To  
> **Phase:** Kubernetes Chaos

## Overview

etcd is the key-value store backing the entire Kubernetes state. When its disk quota is exhausted, Kubernetes becomes read-only — no new pods, services, or config changes can be applied.

This experiment simulates etcd disk pressure to validate your monitoring and response procedures.

## etcd Disk Quota

By default, etcd has a `--quota-backend-bytes` of **2 GiB**. When breached, etcd raises an `mvcc: database space exceeded` alarm and blocks writes.

## How to trigger etcd disk pressure (local kind)

### Step 1: Exec into the control-plane node

```bash
docker exec -it chaos-lab-control-plane bash
```

### Step 2: Find the etcd data directory

```bash
ls /var/lib/etcd/member/snap/
```

### Step 3: Write large datasets to etcd (via kubectl)

```bash
# Create thousands of ConfigMaps to bloat etcd
for i in $(seq 1 500); do
  kubectl create configmap "bloat-$i" \
    --from-literal=data="$(head -c 4096 /dev/urandom | base64)"
done
```

### Step 4: Check etcd size

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints https://127.0.0.1:2379 \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table
```

### Step 5: Compact and defragment to recover

```bash
# Get the current revision
REV=$(ETCDCTL_API=3 etcdctl ... endpoint status --write-out=json | jq .[0].Status.header.revision)

# Compact
ETCDCTL_API=3 etcdctl ... compact $REV

# Defragment
ETCDCTL_API=3 etcdctl ... defrag

# Disarm alarm
ETCDCTL_API=3 etcdctl ... alarm disarm
```

## Monitoring etcd Disk

```promql
# etcd database size (bytes)
etcd_mvcc_db_total_size_in_bytes

# etcd disk size as fraction of quota
etcd_mvcc_db_total_size_in_bytes / etcd_server_quota_backend_bytes
```

Alert threshold: trigger at **80%** of quota.

## Insights this experiment reveals

- Do you have an alert for etcd disk utilisation?
- Is there a runbook for etcd compaction / defragmentation?
- Is your etcd on a separate fast disk (SSD) with dedicated IOPS?

---
*Part of the 100-Lesson Chaos Engineering Series.*
