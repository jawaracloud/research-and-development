# 63 — Raft & Quorum

> **Type:** Explanation  
> **Phase:** Production & Operations

## Overview

This lesson breaks down how NATS JetStream uses the **Raft consensus algorithm** to manage distributed state, ensure data consistency, and handle leader election.

## What is Raft?

Raft is a protocol for managing a replicated log. It ensures that all nodes in a cluster agree on the same sequence of events, even in the face of network partitions or node failures.

## Key Raft Concepts in NATS

### 1. Leader Election
For every stream, one node is elected the **Leader**.
- Only the Leader can accept new messages (writes).
- The Leader heartbeats to Followers to maintain its status.
- If the Leader fails, Followers hold an election to choose a new one.

### 2. Log Replication
1. Leader receives a message.
2. Leader sends it to Followers.
3. Once a **Quorum** (majority) of nodes have written it to their logs, the Leader acks the publisher.

### 3. Quorum Requirements

| Replicas | Quorum (Majority) | Failures Tolerated |
|----------|-------------------|--------------------|
| 1        | 1                 | 0                  |
| 2        | 2                 | 0 (Dangerous!)     |
| 3        | 2                 | 1                  |
| 5        | 3                 | 2                  |

**Warning:** R=2 is discouraged because if any node fails, you lose quorum and the stream goes read-only.

## Split Brains

If a network partition divides a 3-node cluster into {Node A} and {Node B, Node C}, the side with the majority ({B, C}) will remain functional. The minority side ({A}) will stop accepting writes.

## Monitoring Raft State

```bash
nats stream info ORDERS
```
Look at the `Cluster` section to see the leader and replica health.

## Operational Impact

- **Latency:** Writes are limited by the speed of the slowest node in the quorum.
- **Storage:** Data is duplicated R times across the cluster.
- **Recovery:** When a failed node recovers, it automatically asks the leader for the logs it missed to catch up.

---
*Part of the 100-Lesson NATS Series.*
