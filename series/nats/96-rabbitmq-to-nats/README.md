# 96 — Migration from RabbitMQ to NATS

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

RabbitMQ (AMQP) is a traditional message broker. Moving to NATS often simplifies the architecture by replacing complex exchange/queue bindings with simple subject-based routing.

## 1. Comparing Terms

| RabbitMQ (AMQP) | NATS JetStream |
|-------|----------------|
| **Exchange** | **Subject (Implicit)** |
| **Queue** | **Consumer** |
| **Binding** | **Subject Filter** |
| **Routing Key** | **Subject** |
| **Exchange Type (Direct)** | **Subject (Exact Match)** |
| **Exchange Type (Topic)** | **Subject (Wildcards)** |
| **Exchange Type (Fanout)** | **Interest-Based Routing** |

## 2. Key Differences

- **Brokers vs Channels:** RabbitMQ is a heavy broker that does a lot of work. NATS is a "thin" server that favors client-side efficiency.
- **Protocol:** AMQP is complex and stateful. NATS is a simple text-based protocol (Lesson 2).
- **Scalability:** NATS clusters easily scale to millions of messages per second with lower CPU/RAM than RabbitMQ.

## 3. Migration Strategy

1. **Exchange -> Subject:** Map your routing keys directly to NATS subjects.
2. **Work Queues -> Pull Consumers:** Use Job Queue retention in JetStream to emulate RabbitMQ's worker pattern (Lesson 27).
3. **Dead Lettering:** Replace Rabbit's DLX with NATS DLQ pattern (Lesson 46).

## 4. The MQTT/Stomp Bridge
If you have legacy devices that *must* use RabbitMQ-compatible protocols, remember NATS also supports MQTT (Lesson 85) and STOMP, allowing a "half-step" migration.

## 5. Why the move?
- **Ease of Operations:** No Erlang dependency, no complex clustering issues.
- **Performance:** NATS typically offers 10x-50x the throughput of RabbitMQ on equivalent hardware.

---
*Part of the 100-Lesson NATS Series.*
