# 02 — NATS Architecture

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

Understanding how NATS is structured internally helps you design systems that use it correctly — and troubleshoot them when things go wrong.

## Components

```
┌──────────────────────────────────────────────────────────────┐
│                      NATS Server                             │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Client      │  │  Routing     │  │  JetStream       │  │
│  │  Connections │  │  (Cluster)   │  │  (Persistence)   │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Leaf Nodes  │  │  Gateways    │  │  Accounts/Auth   │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Client Connections

Clients connect to NATS over TCP on port **4222**. The protocol is text-based:

```
# Publish
PUB orders.created 25\r\n
{"orderId":"abc-123"}\r\n

# Subscribe
SUB orders.created 1\r\n

# Message delivery
MSG orders.created 1 25\r\n
{"orderId":"abc-123"}\r\n
```

Client libraries abstract this behind a simple API.

## Server Config File

`nats-server.conf`:

```
port: 4222
http_port: 8222

jetstream {
  store_dir: /data/jetstream
  max_memory_store: 1GB
  max_file_store: 10GB
}

cluster {
  name: my-cluster
  port: 6222
  routes: [
    nats://nats-2:6222,
    nats://nats-3:6222
  ]
}
```

## Subject Routing

NATS routes messages based on subject string matching. No central topic registry is needed:

```
orders.created           → exact match
orders.*                 → single token wildcard (orders.created, orders.updated)
orders.>                 → multi-token wildcard (orders.created, orders.items.added)
```

## Clustering

A NATS cluster is a group of servers connected via **route connections** (port 6222). Each server maintains a full mesh with all other servers. When a message arrives at server A and the subscriber is connected to server B, server A **routes** the message to server B.

```
Client-A → nats-1 → nats-2 → Client-B
                ↘ nats-3 ↗
```

## Accounts (Multi-tenancy)

Accounts are isolated messaging namespaces. Subjects in account A are invisible to account B unless explicitly exported/imported:

```
Account "team-payments":  orders.created → payment.svc
Account "team-inventory": orders.created → inventory.svc (isolated)
```

## JetStream Layer

JetStream is a persistence layer built into nats-server. It adds:
- **Streams**: durable storage of messages by subject
- **Consumers**: durable cursor into a stream with delivery guarantees
- **Key-Value**: CRUD key-value operations backed by a stream
- **Object Store**: large file storage backed by a stream

## Leaf Nodes

Leaf nodes are lightweight NATS servers that extend a hub cluster to edge locations. They inherit the hub's subject space while running with local autonomy.

---
*Part of the 100-Lesson NATS Series.*
