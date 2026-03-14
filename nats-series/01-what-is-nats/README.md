# 01 — What Is NATS

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

**NATS** (Neural Autonomic Transport System) is an open-source, cloud-native messaging system designed for simplicity, performance, and security. It was created at Apcera (now Synadia) and is a CNCF incubating project used by companies like Apple, AWS, and Mastercard.

## Core Properties

| Property | Value |
|----------|-------|
| **Protocol** | Text-based, TCP |
| **Latency** | < 1 ms (intra-datacenter) |
| **Throughput** | Millions of messages/second |
| **Deployment** | Single binary (`nats-server`) |
| **Languages** | 50+ client libraries |

## What problems does NATS solve?

```
Service A → HTTP → Service B   (tight coupling, synchronous, fragile)

Service A → NATS → Service B   (decoupled, async, resilient)
              ↓
           Service C           (fan-out for free)
```

Traditional REST creates point-to-point coupling. NATS decouples producers from consumers using a **subject-based** addressing model — there are no queues or topics to pre-configure; a message just goes to a subject and whoever is subscribed gets it.

## NATS vs the alternatives

| System | Latency | Complexity | Persistence | Auth |
|--------|---------|-----------|-------------|------|
| **NATS Core** | Sub-ms | Very low | None | Yes |
| **NATS JetStream** | Sub-ms | Low | Yes | Yes |
| **Kafka** | Low-ms | High | Yes | Yes |
| **RabbitMQ** | Low-ms | Medium | Yes | Yes |
| **Redis Streams** | Sub-ms | Low | Yes | Basic |

## The Three Messaging Models

### 1. Pub/Sub (broadcast)
```
Publisher → [subject: weather.update]
                ↓            ↓
           Subscriber-1   Subscriber-2   (both receive every message)
```

### 2. Request/Reply (synchronous)
```
Requester → [subject: api.users.get] → Responder
Requester ← [reply: _INBOX.abc] ←─────────
```

### 3. Queue Groups (load balancing)
```
Publisher → [subject: orders.process]
                ↓
        [Queue Group: workers]
         /        |        \
    Worker-1  Worker-2  Worker-3   (only ONE receives each message)
```

## Why "Neural Autonomic"?

The name reflects the design goal: a messaging system that adapts and self-heals like the autonomic nervous system — always on, always routing, even when individual nodes fail.

## When to choose NATS

✅ High-throughput, low-latency messaging  
✅ Simple pub/sub without broker configuration  
✅ Microservice fan-out (one event → many consumers)  
✅ IoT and edge computing (lightweight footprint)  
✅ Service mesh alternative  

---
*Part of the 100-Lesson NATS Series.*
