# 97 — Building a PaaS with NATS

> **Type:** Case Study  
> **Phase:** Advanced & Real-World

## Overview

NATS is the secret sauce behind many modern Platforms-as-a-Service (PaaS) and Serverless platforms. This lesson explores how to use NATS as the control plane and data plane for your own platform.

## 1. NATS as the Control Plane
Instead of building a complex REST API to manage your workers, have them talk over NATS.
- **Task Scheduling:** Push a "Deploy" message to `platform.deploy.app_1`.
- **Worker Management:** Workers join a queue group `platform-controller` and pull tasks.

## 2. Real-time Logs & Metrics
Stream logs from thousands of user containers into a NATS stream.
- **Global Ingestion:** Every worker publishes to `logs.<app_id>.<container_id>`.
- **Live Tail:** A developer's CLI tool requests `logs.app_1.>` and sees live output via WebSockets.

## 3. Multi-Tenancy (The "Killer" Feature)
A PaaS *must* be multi-tenant.
- Use **NATS Accounts** (Lesson 73) to isolate every customer.
- **Customer A** can't see **Customer B**'s data, even if they share the same NATS cluster.

## 4. Service Mesh Replacement
Use NATS as a "zero-trust" service mesh.
- Apps don't need to know each other's IP addresses.
- They talk via subjects. Discovery is automatic.

## 5. Case Study: Fly.io
Fly.io uses NATS (specifically their own wrapper called `corrosion` and `nats-server`) for internal coordination and global event propagation across their fleet of micro-VMs.

---
*Part of the 100-Lesson NATS Series.*
