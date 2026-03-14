# 62 — JetStream Placement & Replicas

> **Type:** Tutorial  
> **Phase:** Production & Operations

## What you're building

Configure JetStream streams with multiple replicas to ensure durability in a clustered environment, and use placement tags to control where data is physically stored.

## Replicas (R=3)

In a cluster, a stream's `Replicas` setting determines how many nodes store the data.

```go
js.AddStream(&nats.StreamConfig{
    Name:     "ORDERS",
    Replicas: 3,  // Recommended for production
})
```

- **R=1:** Data on one node. If node dies, stream is offline.
- **R=3:** Data on 3 nodes. Can lose 1 node without downtime or data loss.
- **R=5:** Can lose 2 nodes. Useful for highly critical data.

## RAFT and Quorum

JetStream uses the Raft consensus algorithm. To perform any write operation (publish), a majority of replicas must agree.

## Stream Placement

Use tags to pin streams to specific servers (e.g., nodes with NVMe drives or in a specific zone).

### Server Config:
```
# server-1.conf
jetstream {
    domain: "prod"
    tags: ["storage:ssd", "zone:us-east-1a"]
}
```

### Stream Config:
```go
js.AddStream(&nats.StreamConfig{
    Name: "FAST-STREAM",
    Placement: &nats.Placement{
        Cluster: "NATS-PROD",
        Tags:    []string{"storage:ssd"},
    },
})
```

## Moving a Stream

You can move a stream between nodes without downtime by updating its placement tags or just letting NATS re-balance.

```bash
# Force re-balance
nats stream cluster step-down ORDERS
```

## Verification

```bash
nats stream info ORDERS
# Cluster Information:
#   Name: NATS-PROD
#   Leader: nats-2
#   Replicas:
#     nats-1: Current, healthy
#     nats-3: Current, healthy
```

---
*Part of the 100-Lesson NATS Series.*
