# 95 — Migration from Kafka to NATS

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

Many teams move from Kafka to NATS for its simplicity, lower operational overhead, and better performance for mixed workloads (Request/Reply + Streams).

## 1. Comparing Terms

| Kafka | NATS JetStream |
|-------|----------------|
| **Topic** | **Stream** |
| **Partition** | **Stream (via Subject-Based Sharding)** |
| **Consumer Group** | **Consumer (with Durable Name)** |
| **Offset** | **Sequence Number** |
| **Broker** | **NATS Server** |
| **Zookeeper/KRaft** | **Internal Raft** |

## 2. Key Differences

- **Dynamic Subjects:** In Kafka, you must pre-create topics. In NATS, you can publish to any subject and the stream captures them using wildcards dynamically.
- **Request/Reply:** Kafka isn't built for low-latency RPC. NATS is.
- **Operational Footprint:** Kafka requires a JVM and complex management. NATS is a single 20MB Go binary.

## 3. Migration Strategy: The Bridge

1. **Phase 1: Dual Publish.** Update your app to publish to both Kafka and NATS.
2. **Phase 2: Shadow Consumers.** Run your new NATS-based microservices but don't let them have commercial side-effects (e.g., skip sending emails). Compare results with Kafka services.
3. **Phase 3: Shift Traffic.** Move consumers one by one to NATS.
4. **Phase 4: Decommission Kafka.**

## 4. The Bridge Tool

You can use a simple Go app to mirror traffic:

```go
// Kafka -> NATS Bridge
kafkaConsumer.OnMessage(func(msg) {
    nats.Publish(msg.Topic, msg.Value)
})
```

## 5. Why the move?

- **"Total Cost of Ownership":** Savings on DevOps time and cloud infrastructure.
- **Simplicity:** One tool for pub/sub, streaming, KV, and RPC.

---
*Part of the 100-Lesson NATS Series.*
