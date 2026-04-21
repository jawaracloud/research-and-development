# 89 — Custom JetStream Placement

> **Type:** How-To  
> **Phase:** Advanced & Real-World

## Overview

In large, heterogeneous NATS clusters, you may want precise control over which physical servers store which stream data. This lesson covers advanced placement strategies using Tags.

## 1. When to use Custom Placement
- **Tiered Storage:** High-throughput streams on NVMe-tagged nodes; archive streams on HDD nodes.
- **Data Sovereignty:** Ensure "User-Data" streams never leave nodes tagged as `zone:germany`.
- **Workload Isolation:** Keep "Telemetery" data off the nodes running "Financial-Transactions".

## 2. Server Configuration

Add tags to your server startup or config.

`server-1.conf`:
```
jetstream {
    domain: "prod"
    tags: ["storage:fast", "region:us-east", "compliance:sox"]
}
```

## 3. Stream Placement Config

```go
js.AddStream(&nats.StreamConfig{
    Name: "SENSITIVE_DATA",
    Placement: &nats.Placement{
        Tags: []string{"compliance:sox", "region:us-east"},
    },
})
```

## 4. Consumer Placement

You can also place consumers specifically on nodes near their streams or logic.

```go
js.AddConsumer("SENSITIVE_DATA", &nats.ConsumerConfig{
    Durable: "processor",
    # Although consumers often follow the stream leader, 
    # you can influence affinity.
})
```

## 5. Inspecting Placement

Use the NATS CLI to see where your data is living:

```bash
nats stream info SENSITIVE_DATA
# ...
# Cluster Information:
#    Leader: node-a (Tags: [storage:fast, compliance:sox])
```

## 6. Dynamic Migration
To move a stream without downtime:
1. Update the stream config with new tags.
2. NATS will hold an election and move the data to nodes matching the new tags.

---
*Part of the 100-Lesson NATS Series.*
