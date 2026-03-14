# 28 — Storage Types: File vs Memory

> **Type:** Explanation  
> **Phase:** JetStream

## Overview

JetStream supports two storage backends for streams: **file storage** (durable) and **memory storage** (ephemeral, fast). Choosing the right storage type is a fundamental design decision.

## File Storage

Messages are persisted to disk. Data survives server restarts and crashes.

```go
&nats.StreamConfig{
    Name:    "ORDERS",
    Storage: nats.FileStorage,
}
```

```bash
nats stream add ORDERS --storage file
```

**Properties:**
- Survives server restart ✅
- Survives server crash ✅ (with JetStream replicas)
- Throughput: limited by disk I/O (~hundreds MB/s on NVMe)
- Latency: adds ~0.5–2 ms for disk write acknowledgement

**Use when:** Any business-critical data (payments, orders, audit logs).

## Memory Storage

Messages are held in RAM only. Fastest possible latency, but data is lost on server restart or crash.

```go
&nats.StreamConfig{
    Name:    "SESSIONS",
    Storage: nats.MemoryStorage,
    MaxAge:  30 * time.Minute,
}
```

```bash
nats stream add SESSIONS --storage memory
```

**Properties:**
- Does NOT survive server restart ❌
- Throughput: only limited by RAM bandwidth (GBs/s)
- Latency: ~0.1 ms (no disk I/O)
- Capacity: bounded by server's available RAM

**Use when:** Session state, caches, ephemeral coordination (leader election), high-frequency metrics.

## Hybrid Pattern

Use both storage types in the same system:

```
Orders → ORDERS stream (file) → long-lived, durable
Session tokens → SESSIONS stream (memory) → short-lived, fast
Metrics → METRICS stream (file, short TTL) → 1h retention
```

## Storage Sizing Guidance

```
File store:
  Size = (avg_msg_bytes × msgs_per_sec × retention_seconds) × 1.2 safety margin

Memory store:
  Size = (avg_msg_bytes × msgs_per_sec × retention_seconds) must fit in RAM
  Rule of thumb: don't exceed 50% of available RAM
```

## JetStream Data Location

```bash
# Default storage directory
/data/jetstream/<account>/<stream>/

# Override in server config:
jetstream {
  store_dir: /nvme/nats-data
}
```

## File vs Memory at a Glance

| | File Storage | Memory Storage |
|-|-------------|---------------|
| **Durability** | ✅ Survives restart | ❌ Lost on restart |
| **Throughput** | ~500 MB/s (NVMe) | ~5 GB/s (RAM) |
| **Latency overhead** | +0.5–2 ms | ~0 |
| **Capacity** | Disk size | Available RAM |
| **Replication** | Supported | Supported |
| **Best for** | Critical data | Session/cache/temp |

---
*Part of the 100-Lesson NATS Series.*
