# 11 — NATS CLI Deep Dive

> **Type:** How-To  
> **Phase:** Foundations

## Overview

The `nats` CLI is the primary tool for exploring, testing, and managing a NATS server. This lesson covers the most useful commands for day-to-day development.

## Installation

```bash
# macOS
brew install nats-io/nats-tools/nats

# Linux
curl -sf https://binaries.nats.dev/nats-io/natscli/nats@latest | sh

# Verify
nats --version
```

## Context management

```bash
# Create a local context
nats context add local --server nats://localhost:4222 --description "Local Lab"

# Switch context
nats context select local

# List contexts
nats context ls
```

## Messaging commands

```bash
# Publish a message
nats pub orders.created '{"id":"abc-123","amount":99.99}'

# Subscribe (interactive, Ctrl+C to exit)
nats sub orders.created

# Subscribe with wildcard
nats sub "orders.>"

# Publish/subscribe with count
nats pub --count 100 benchmark.test "hello"
nats sub --count 100 benchmark.test

# Request/Reply (fire single request)
nats req users.get '{"id":"u-001"}'
```

## Server inspection

```bash
# Server info
nats server info

# List all connected clients
nats server clients

# Server ping (latency)
nats server ping

# Subscription list
nats server subscriptions

# Server report
nats server report connections
```

## JetStream commands

```bash
# List streams
nats stream ls

# Create a stream
nats stream add ORDERS \
  --subjects "orders.>" \
  --storage file \
  --retention limits \
  --max-age 7d

# Stream info
nats stream info ORDERS

# Publish to stream
nats pub orders.created '{"id":"1"}' --count 5

# View messages in stream
nats stream view ORDERS

# Get specific message by sequence
nats stream get ORDERS 1

# Consumer commands
nats consumer ls ORDERS
nats consumer add ORDERS payment-svc --pull --deliver all
nats consumer next ORDERS payment-svc   # fetch one message
nats consumer info ORDERS payment-svc
```

## Benchmarking

```bash
# Pub/Sub throughput benchmark
nats bench orders.test --pub 1 --sub 1 --size 128 --msgs 100000
# Pub/Sub stats, 100K messages, 128 bytes each

# JetStream benchmark
nats bench orders.js-test --js --pub 1 --sub 1 --msgs 10000
```

## Key-Value

```bash
# Create KV bucket
nats kv add config --history 5

# Put / Get
nats kv put config service.timeout 30s
nats kv get config service.timeout

# Watch for changes
nats kv watch config
```

---
*Part of the 100-Lesson NATS Series.*
