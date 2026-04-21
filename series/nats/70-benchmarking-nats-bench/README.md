# 70 — Benchmarking with nats-bench

> **Type:** Tutorial  
> **Phase:** Production & Operations

## What you're building

Learn to use the built-in `nats-bench` tool to baseline your cluster performance and test your architectural changes under load.

## What is `nats-bench`?

It's a high-performance benchmarking tool included with the NATS CLI. It can simulate thousands of publishers and subscribers with varying message sizes.

## 1. Basic Pub/Sub Benchmark

Test core throughput between a single publisher and two subscribers:

```bash
nats bench test-subject --pub 1 --sub 2 --msgs 1000000 --size 128
```

- `--pub`: Number of publishers.
- `--sub`: Number of subscribers.
- `--msgs`: Total messages to send.
- `--size`: Payload size in bytes.

## 2. Testing JetStream Performance

Benchmark persistent storage (will be limited by disk IO):

```bash
nats bench test-js --js --pub 1 --sub 1 --msgs 10000 --size 1024
```

- `--js`: Enable JetStream mode.
- `--sync`: Wait for acks for every message (slowest, most reliable).

## 3. Simulating Production Load

Simulate many small clients with a large payload burst:

```bash
nats bench production.load --pub 10 --sub 5 --msgs 500000 --size 512 --storage file
```

## 4. Interpreting the Results

Watch for:
- **Throughput (msgs/sec):** Is it stable or dropping over time?
- **Latency (Avg/Max):** Is the max latency spiked? (Indicating buffer bloat or disk contention).
- **CPU/RAM:** Check server metrics during the benchmark to find the bottleneck.

## Batch Benchmarking Script

Automate your tests to find the "sweet spot" for your payload size:

```bash
for size in 128 512 1024 4096; do
  echo "Testing size $size bytes..."
  nats bench bench.size --pub 1 --sub 1 --msgs 100000 --size $size
done
```

---
*Part of the 100-Lesson NATS Series.*
