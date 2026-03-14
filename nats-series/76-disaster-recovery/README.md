# 76 — Disaster Recovery (DR)

> **Type:** Explanation  
> **Phase:** Production & Operations

## Overview

Disaster Recovery (DR) is about ensuring your NATS infrastructure can recover from a catastrophic failure, such as the loss of an entire cloud region or a major data corruption event.

## 1. DR Strategies

### Active-Passive (Cold/Warm Standby)
A second cluster exists but is not receiving traffic.
- **Failover:** Point clients to the standby cluster URL.
- **Recovery Time (RTO):** High (minutes to hours).
- **Data Loss (RPO):** High (depends on when the last backup was taken).

### Active-Active (Multi-Region)
Two clusters in different regions are connected via **Gateways** or **Superclusters**.
- **Failover:** Automated by the NATS protocol or Load Balancer.
- **Recovery Time (RTO):** Low (seconds).
- **Data Loss (RPO):** Low (if using region-to-region mirroring).

## 2. Cross-Region Mirroring

This is the most effective DR tool in NATS.

1. **Primary Cluster (US-East):** Stream `ORDERS`.
2. **Standby Cluster (US-West):** Stream `ORDERS_DR` mirrors `ORDERS`.

If US-East goes offline, US-West has a copy of the sequence.

## 3. Configuration Management as DR

Ensure your cluster configuration (Accounts, Users, Stream Configs) is stored in version control (GitOps).
- If the cluster is deleted, you should be able to re-provision it with `terraform` or `helm` in minutes.

## 4. The "Chaos" Test

To truly verify DR:
1. Hard-stop a NATS node in a 3-node cluster.
2. Verify clients stay connected.
3. Hard-stop the whole region (if testing multi-region).
4. Verify cross-region consumers pick up where they left off.

## 5. RTO/RPO Metrics

| Metric | Target | Solution |
|--------|--------|----------|
| **RTO (Recovery Time)** | < 30s | Multi-node clusters + Gateways |
| **RPO (Recovery Point)** | < 1s | R=3 JetStream + Asynchronous Mirroring |

---
*Part of the 100-Lesson NATS Series.*
