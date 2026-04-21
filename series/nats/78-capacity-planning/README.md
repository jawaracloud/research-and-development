# 78 — Capacity Planning

> **Type:** How-To  
> **Phase:** Production & Operations

## Overview

Capacity planning ensures your NATS cluster can grow with your business without hitting hardware walls.

## 1. Network Capacity (The Primary Bottleneck)

NATS is very network-heavy.
- **Calculation:** `(Avg Message Size) * (Messages per Second) * (Number of Consumers) = Required Throughput`.
- **Tip:** Use 10Gbps networking for production servers if processing > 100k msgs/sec.

## 2. Memory (RAM) Sizing
- **Server Overhead:** NATS uses very little RAM itself (~100-200MB).
- **Core Subscriptions:** Uses RAM per subscription and per active client connection.
- **JetStream Memory Store:** If using `MemoryStorage` for streams, ensure you have enough RAM with a 20% buffer.

## 3. Disk (Storage) Sizing
- **Retention Policy:** `(Size per month) * (Retention Months) = Total Storage`.
- **Speed:** Use SSD/NVMe. Spinning disks (HDDs) will bottleneck JetStream writes.

## 4. CPU Sizing
- NATS is highly efficient and multicore-aware.
- **Encryption Overheard:** TLS/JWT signing increases CPU usage.
- **Rule of Thumb:** Start with 4-8 vCPUs and scale up as throughput exceeds 200k+ msgs/sec.

## 5. Monitoring for Scaling

Look at these "clues" that you need to scale up:
- **CPU > 70% consistently.**
- **Network Interface nearing 80% saturation.**
- **Disk Latency increasing** (i.e. `nats_js_store_write_latency` in Prometheus).

## 6. Scaling Out vs Scaling Up
- **Scale Up (Bigger Nodes):** Best for reducing cluster-wide latency.
- **Scale Out (More Nodes):** Best for increasing availability and distributing client connection load.

---
*Part of the 100-Lesson NATS Series.*
