# 75 — Backup & Recovery

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Data in JetStream is durable, but hardware fails and human errors happen. This lesson covers how to back up your streams and restore them.

## 1. Stream Backup (Snapshot)

You can create a compressed snapshot of a stream's data and its state:

```bash
# Manual Backup via CLI
nats stream backup ORDERS ./orders_backup/
```

This creates a folder containing the data and metadata.

## 2. Stream Restore

To restore a stream from a backup:

```bash
nats stream restore ./orders_backup/
```
*Note: The stream name cannot already exist in the account during restore.*

## 3. Automated Backups

Run a cron job that snapshots critical streams and uploads them to S3/GCS.

```bash
#!/bin/bash
DAY=$(date +%F)
nats stream backup --account MY_APP ORDERS /tmp/orders-$DAY
tar -czvf orders-$DAY.tar.gz /tmp/orders-$DAY
aws s3 cp orders-$DAY.tar.gz s3://my-nats-backups/
```

## 4. JetStream Mirroring as Backup
For "hot" backups, use a **Mirror** (Lesson 38) in another cluster or another region. 
- If the primary cluster dies, you have an exactly-in-sync replica ready to go.

## 5. Server-Level Backup (Raft Log)
You can also back up the entire `store_dir` of a server.
- **Warning:** Only do this while the server is stopped, or if the filesystem supports snapshots (like ZFS/LVM). 
- **Recommendation:** Use the `nats stream backup` tool instead; it's safe to run while the server is active.

## Recovery Checklist
1. Re-deploy NATS Cluster.
2. Restore Accounts (JWTs/Config).
3. Restore Streams (`nats stream restore`).
4. Re-calculate consumers (they will usually start from the last acked sequence found in the restored data).

---
*Part of the 100-Lesson NATS Series.*
