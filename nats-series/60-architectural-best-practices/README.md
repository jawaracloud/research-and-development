# 60 — Architectural Best Practices

> **Type:** Reference  
> **Phase:** Patterns & Architecture

## Overview

A summary of the architectural principles for building production-grade systems with NATS.

## 1. Subject Design
- **Hierarchical:** Dig deeper than you think. `orders.v1.us.created` is better than `orders`.
- **Prefer small tokens:** `a.b.c` is better than `longtokenname.other`.

## 2. Naming Conventions
- **Streams:** Uppercase (e.g., `ORDERS`).
- **Consumers:** Lowercase, hyphenated (e.g., `payment-processor`).
- **Subjects:** Lowercase, dot-separated (e.g., `orders.created`).

## 3. Storage Efficiency
- **Limits are your friend:** Always set `MaxAge` or `MaxBytes`. Never allow a stream to grow infinitely.
- **Discard Policy:** Default to `DiscardOld` unless data loss is strictly prohibited (then use `DiscardNew` and handle errors in producers).

## 4. Connection Management
- **One Connection per App:** Share one `nats.Conn` across your goroutines.
- **Use Drain():** Never just `Close()`. Allow handlers to finish.
- **Heartbeats:** Enable them for long-lived consumers.

## 5. Security
- **Least Privilege:** Each user/service should only have access to the subjects they need.
- **Use Accounts:** Avoid a single shared namespace for everything.
- **TLS Everywhere:** Never run without encryption in production.

## 6. The "Three-S" Rule
- **Simple:** Don't build complex logic into subjects.
- **Small:** Keep message bodies under 1MB (ideally under 64KB).
- **Scalable:** Design for queue groups from day one.

## 7. Error Handling
- **Idempotency:** Assume every message will be delivered twice.
- **Naks with Delay:** Use exponential backoff for retries.
- **DLQ:** Monitor and alert on dead letter queues.

---
*Part of the 100-Lesson NATS Series.*
