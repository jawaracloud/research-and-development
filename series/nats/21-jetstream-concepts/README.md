# 21 — JetStream Concepts

> **Type:** Explanation  
> **Phase:** JetStream

## Overview

JetStream is NATS's built-in persistence and streaming layer. It transforms NATS from a fire-and-forget message bus into a durable, replay-capable streaming platform — without any external dependencies.

## Core Primitives

```
JetStream
├── Stream        — ordered, persistent log of messages
│   ├── Subject filter(s)
│   ├── Retention policy
│   ├── Storage type (file | memory)
│   └── Limits (messages, bytes, age)
└── Consumer      — cursor + delivery policy into a stream
    ├── Deliver policy (New | All | ByStartSeq | ByStartTime | Last)
    ├── Ack policy (None | All | Explicit)
    ├── Durable name (persisted) or ephemeral
    └── Filter subject
```

## The Stream

A **stream** captures all messages published to one or more subjects and stores them durably:

```
Subject: orders.>     ←── wildcard filter

Publisher-1 → orders.created  → ──┐
Publisher-2 → orders.cancelled → ──┤
Publisher-3 → orders.updated  → ──┘
                                   ↓
                    ┌──────────────────────────────┐
                    │  Stream: ORDERS               │
                    │  Seq 1: orders.created (msg)  │
                    │  Seq 2: orders.cancelled (msg)│
                    │  Seq 3: orders.created (msg)  │
                    └──────────────────────────────┘
```

## The Consumer

A **consumer** is a named, persistent cursor into a stream with controlled delivery:

```
Stream: ORDERS (seq 1 → 500)
         ↕
Consumer: "payment-svc" (cursor at seq 120)
         ↕
Consumer: "analytics" (cursor at seq 1, replaying all)
```

Two consumers can be at completely different positions in the same stream simultaneously.

## Delivery Models

| Model | Description | When to use |
|-------|-------------|-------------|
| **Push** | Server pushes messages to client | Low-volume, event-driven |
| **Pull** | Client fetches messages in batches | High-volume, controlled pacing |

## Ack Policies

| Policy | Description |
|--------|-------------|
| `AckNone` | No acknowledgement required |
| `AckAll` | Ack seq N = all ≤N acked |
| `AckExplicit` | Each message must be acked individually |

## Delivery Policies

| Policy | Description |
|--------|-------------|
| `DeliverAll` | Start from sequence 1 (full replay) |
| `DeliverNew` | Only new messages from now |
| `DeliverLast` | Only the last message per subject |
| `DeliverByStartSeq` | Start from specific sequence number |
| `DeliverByStartTime` | Start from a timestamp |

---
*Part of the 100-Lesson NATS Series.*
