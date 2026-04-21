# 80 — Operations Checklist

> **Type:** Reference  
> **Phase:** Production & Operations

## Overview

A "Go-Live" checklist for any engineer deploying NATS to production.

## 🛠 Infrastructure
- [ ] Cluster has at least 3 nodes.
- [ ] Nodes are in different Availability Zones (AZs).
- [ ] TLS is enabled for all clients and cluster routes.
- [ ] Disk is SSD/NVMe class.

## 🔐 Security
- [ ] Default `G` account is not used for data.
- [ ] Every service has a unique User JWT or credentials.
- [ ] ACLs are "Deny by Default".
- [ ] Monitoring port 8222 is not exposed to the public internet.

## 📦 JetStream
- [ ] Critical streams have `Replicas: 3`.
- [ ] Storage limits (`MaxBytes` / `MaxAge`) are defined for every stream.
- [ ] Consumers are **Durable** for stateful services.
- [ ] Retries (`AckWait` / `MaxDeliver`) are tuned for the application.

## 📊 Observability
- [ ] Prometheus is scraping NATS metrics.
- [ ] Grafana Dashboard 2279 is imported.
- [ ] Alerts set for:
    - [ ] Node down.
    - [ ] Consumer lag > X.
    - [ ] Stream storage > 90%.

## 📜 Procedures
- [ ] Backup script is running and verified.
- [ ] Rollback plan for upgrades is documented.
- [ ] Incident Response: "What do we do if we lose a cloud region?"

---
*Part of the 100-Lesson NATS Series.*
