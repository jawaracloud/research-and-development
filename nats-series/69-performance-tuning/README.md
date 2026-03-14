# 69 — Performance Tuning

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Optimizing NATS performance involves tuning both the server configuration and how the client interacts with it. This lesson covers the "low-hanging fruit" for high-performance clusters.

## 1. Server-Side Tuning

### RAM vs Disk
For maximum performance, use `MemoryStorage` for JetStream. For durability with speed, use local NVMe drives for `FileStorage`.

### Buffers & Payloads
`server.conf`:
```
max_payload: 1MB         # Default is 1MB. Smaller is faster.
max_pending: 100MB       # Increase for bursty traffic
write_deadline: "10s"    # For slow network links
```

## 2. Client-Side Tuning

### Batching (JetStream Pull)
High-volume consumers should fetch in batches, not one-by-one.

```go
// Fetch 100 at a time
msgs, _ := sub.Fetch(100, nats.MaxWait(time.Second))
```

### Async Publishing
If you don't need immediate confirmation for every message, use async publishing to increase throughput significantly.

```go
js.PublishAsync("orders.created", data)
// Use nats.PublishAsyncMaxPending to limit memory usage
```

### Protocol Efficiency
- **NoEcho:** If you subscribe to a subject you also publish to, use `nats.NoEcho()` to avoid receiving your own messages.
- **Headers Only:** If you only need to know a message arrived, use `HeadersOnly()` in JetStream to avoid downloading the payload.

## 3. OS Tuning (Linux)

For high-concurrency servers:
- **File Descriptors:** Increase `ulimit -n` to 65535 or higher.
- **TCP Stack:**
    ```bash
    sysctl -w net.core.somaxconn=4096
    sysctl -w net.ipv4.tcp_max_syn_backlog=4096
    ```

## 4. Architecture Tuning
- **Leaf Nodes:** Offload high-frequency local traffic to a leaf node to keep the core cluster light.
- **Subject Pruning:** Ensure your subjects aren't too deep (e.g., more than 5-7 tokens) as it increases routing overhead.

---
*Part of the 100-Lesson NATS Series.*
