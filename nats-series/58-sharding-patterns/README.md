# 58 — Data Locality & Sharding

> **Type:** Tutorial  
> **Phase:** Patterns & Architecture

## What you're building

Implement data sharding in NATS to distribute load across multiple streams or consumers based on a shard key (e.g., `userId` or `region`).

## Why Sharding?

As your data volume grows, a single stream might hit storage or throughput limits. Sharding allows you to split the data.

## Pattern 1: Subject-Based Sharding

Use tokens in subjects to partition data:

```
orders.shard-0
orders.shard-1
orders.shard-2
```

Producers calculate the shard:

```go
func getShardSubject(orderID string) string {
    h := fnv.New32a()
    h.Write([]byte(orderID))
    shard := h.Sum32() % 3
    return fmt.Sprintf("orders.shard-%d", shard)
}
```

## Pattern 2: Stream Sharding

Create multiple streams, each capturing a specific partition:

```go
// Stream for Shard 0
js.AddStream(&nats.StreamConfig{
    Name:     "ORDERS_0",
    Subjects: []string{"orders.shard-0"},
})

// Stream for Shard 1
js.AddStream(&nats.StreamConfig{
    Name:     "ORDERS_1",
    Subjects: []string{"orders.shard-1"},
})
```

## Pattern 3: Consumer Side Filtering

One big stream, many consumers each filtering for their shard:

```go
// Multi-subject stream
js.AddStream(&nats.StreamConfig{
    Name:     "ORDERS",
    Subjects: []string{"orders.>"},
})

// Consumer for US region
js.Subscribe("orders.us.>", handler, nats.Durable("processor-us"))

// Consumer for EU region
js.Subscribe("orders.eu.>", handler, nats.Durable("processor-eu"))
```

## NATS 2.10 Metadata Sharding

Use subject mapping in the server to translate keys:

```
# nats-server.conf
mappings {
  "orders.*": "orders.{{wildcard(1)}}.{{partition(5,1)}}"
}
```
This automatically partitions `orders.A` into 5 buckets.

## Data Locality Rules

1. **Keep processing near data:** If a stream is in US-East, run the consumers in US-East.
2. **Shard by affinity:** Group related data (e.g., all events for one user) in the same shard to maintain strict ordering for that entity.
3. **Avoid cross-shard joins:** If services need to join data, consider sharding both services by the same key.

---
*Part of the 100-Lesson NATS Series.*
