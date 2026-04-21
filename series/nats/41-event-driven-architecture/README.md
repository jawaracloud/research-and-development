# 41 — Event-Driven Architecture

> **Type:** Explanation  
> **Phase:** Patterns & Architecture

## Overview

Event-driven architecture (EDA) is the foundation of every NATS-based system. Understanding its patterns, tradeoffs, and vocabulary is essential before implementing any of the advanced patterns in this phase.

## EDA Vocabulary

| Term | Definition |
|------|-----------|
| **Event** | A fact that has happened (immutable) |
| **Command** | A request to do something (should be validated before publishing) |
| **Subject** | The address of a message in NATS |
| **Producer** | Service that publishes events |
| **Consumer** | Service that reacts to events |
| **Stream** | Ordered, durable log of events (JetStream) |
| **Projection** | A read model built from replaying events |

## Event vs Command

```
Command: orders.create         {"items": [...], "userId": "u-1"}
  → Telling the order service "create this order"
  → May be rejected (out of stock, invalid payment)

Event: orders.created          {"orderId": "abc", "items": [...]}
  → Stating "an order was created"
  → Always in the past tense, always valid, cannot be "un-created"
```

## Three EDA Topologies

### 1. Simple pub/sub

```
Order Svc → orders.created → [Payment Svc, Inventory Svc, Notification Svc]
```
All subscribers react to every event. Fan-out.

### 2. Pipeline

```
Raw Event → Transform-Svc → Normalised Event → Analytics-Svc → Report
```
Events flow through processing stages (enrichment, filtering, aggregation).

### 3. Choreography (no central orchestrator)

```
Order Svc publishes orders.created
  Payment Svc reacts → publishes payments.processed
    Inventory Svc reacts → publishes inventory.reserved
      Notification Svc reacts → sends email
```
Services react to each other's events. Highly decoupled, harder to trace.

### 4. Orchestration (central orchestrator — Saga)

```
Orchestrator publishes: orders.create-payment
  Payment Svc executes → returns result
Orchestrator publishes: orders.reserve-inventory
  Inventory Svc executes → returns result
Orchestrator publishes: orders.send-confirmation
```
Central control flow, easier to trace, less decoupled. (Covered in lesson 44.)

## EDA Benefits with NATS

| Benefit | NATS feature |
|---------|-------------|
| **Decoupling** | Subjects — producers don't know consumers |
| **Scalability** | Queue groups — add consumers without config |
| **Replay** | JetStream — redeliver historical events |
| **Durability** | JetStream streams — survive crashes |
| **Fan-out** | Core pub/sub — all subscribers notified |
| **Exactly-once** | Deduplication + idempotent consumers |

---
*Part of the 100-Lesson NATS Series.*
