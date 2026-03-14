# 38 — Stream Mirrors & Sources

> **Type:** Tutorial  
> **Phase:** JetStream

## Overview

JetStream **mirrors** create a read-only copy of one stream into another server or account. **Sources** allow a stream to aggregate messages from one or more other streams. Both enable cross-cluster replication and data locality.

## Mirror: Read-Only Replica

A mirror continuously copies all messages from a source stream:

```go
js, _ := nc.JetStream()

// Create a mirror of ORDERS in the local cluster
_, err := js.AddStream(&nats.StreamConfig{
    Name: "ORDERS-DR",    // disaster recovery replica
    Mirror: &nats.StreamSource{
        Name: "ORDERS",
        // For cross-cluster: add external configuration
        // External: &nats.ExternalStream{APIPrefix: "$JS.hub.API"},
    },
})
```

```bash
# Mirror status
nats stream info ORDERS-DR
# Mirror: origin ORDERS, seq 1000 of 1000 (in sync)
```

**Properties of mirrors:**
- Read-only — you cannot publish to a mirror directly
- Automatically catches up after network partition
- Can have a `FilterSubject` to mirror only a subset

```go
Mirror: &nats.StreamSource{
    Name:          "ORDERS",
    FilterSubject: "orders.created",  // only mirror new orders
    StartSeq:      1,                 // from the beginning
},
```

## Source: Aggregate Multiple Streams

A stream can pull messages from multiple remote streams:

```go
// Aggregate: combine orders from EU and US into one global stream
_, err := js.AddStream(&nats.StreamConfig{
    Name: "ORDERS-GLOBAL",
    Sources: []*nats.StreamSource{
        {Name: "ORDERS-EU"},
        {Name: "ORDERS-US"},
        {Name: "ORDERS-APAC"},
    },
})
```

Messages from all source streams flow into `ORDERS-GLOBAL`.

## Cross-Cluster Mirror (via Gateway or Leaf Node)

```go
Mirror: &nats.StreamSource{
    Name: "ORDERS",
    External: &nats.ExternalStream{
        APIPrefix:    "$JS.hub.API",    // JetStream API prefix of remote cluster
        DeliverPrefix: "deliver.hub",  // delivery subject prefix
    },
},
```

## Mirror Lag Monitoring

```bash
nats stream info ORDERS-DR
# Mirror:
#   Stream Name: ORDERS
#   Lag:         0       ← 0 = fully in sync
#   Active:      true
```

```promql
# Alert if mirror is falling behind
nats_js_mirror_lag > 1000
```

## When to Use

| | Mirror | Source |
|-|--------|--------|
| **Purpose** | DR replica, read offload | Aggregation, global view |
| **Writable** | ❌ | ❌ (aggregated) |
| **Number of origins** | 1 | Multiple |
| **Filtering** | ✅ | ✅ per source |

---
*Part of the 100-Lesson NATS Series.*
