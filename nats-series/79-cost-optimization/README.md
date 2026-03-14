# 79 — Cost Optimization

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Running NATS in the cloud can get expensive due to egress costs and disk IOPs. This lesson covers how to keep the bills low.

## 1. Data Compression

NATS does not compress messages by default.
- **Client Side:** Use `zstd` or `gzip` before publishing large payloads.
- **Benefit:** Reduces network egress cost and storage cost by up to 10x.

## 2. Egress Management

Cloud providers charge for data moving between regions.
- **Pattern:** Use **Subject Mapping** to keep traffic local.
- **Pattern:** Only mirror specific high-value streams to other regions, not every "chatty" debug stream.

## 3. Storage Tiers

- **High Speed:** Use local NVMe for the primary stream.
- **Long Term:** For audit logs that are rarely read, use a large `DiscardOld` limit or move old data to a cheaper storage tier/Object Store (S3).

## 4. Resource Allocation

Don't over-provision.
- Many NATS clusters are idle 90% of the time. 
- Start with smaller instances (e.g. `c6g.large` on AWS) and use Horizontal Pod Autoscaling if on Kubernetes.

## 5. Subject Pruning

Each active subscription takes a small amount of memory on every server in the cluster.
- Encourage developers to **Unsubscribe** or use **AutoUnsubscribe**.
- Clean up inactive ephemeral consumers.

## 6. Comparing Cloud Costs

| Component | Cost Driver | Savings Tip |
|-----------|-------------|-------------|
| **Network** | Inter-region traffic | Use Leaf Nodes with local processing. |
| **Disk** | IOPS | Use `Batching` on publishers to reduce disk writes. |
| **Storage** | Total Bytes | Use aggressive `MaxAge` limits. |

---
*Part of the 100-Lesson NATS Series.*
