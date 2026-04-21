# 01 — What Is eBPF?

> **Type:** Explanation

## The short answer

eBPF lets you **run your own code inside the Linux kernel** — safely, efficiently, and without modifying the kernel or loading a kernel module.

Think of it as a **programmable hook** that sits at the deepest observability point possible (the kernel itself) and can filter, aggregate, modify, and act on events in real time.

## Why does eBPF exist?

For decades, extending the Linux kernel meant:
1. Writing a kernel module in C (dangerous — a crash kills the machine).
2. Adding system calls (slow — requires kernel patch + distribution cycle).
3. Using `ptrace` / `strace` (very slow — ~50× overhead per syscall).
4. Userspace proxies (copies every packet to userspace).

eBPF breaks this trade-off. It provides a safe, portable, high-performance extension mechanism that runs at kernel speed.

## Origin story

| Year | Event |
|------|-------|
| 1992 | BPF (Berkeley Packet Filter) introduced for `tcpdump` |
| 2014 | Alexei Starovoitov extends BPF into **eBPF** — 64-bit registers, maps, arbitrary hooks |
| 2016 | Cilium launches — first production Kubernetes network using eBPF |
| 2020 | eBPF Foundation formed; Microsoft, Google, Meta, Netflix adopt it |
| 2021 | Windows eBPF announced |
| 2024 | eBPF is table stakes for observability and security tools |

## What makes eBPF safe?

Every eBPF program is run through the **verifier** before execution:
- **Bounded loops** — the program must terminate (no infinite loops).
- **Memory safety** — all pointer dereferences are bounds-checked.
- **No bad calls** — only approved helper functions are accessible.
- **Stack check** — the 512-byte eBPF stack is validated for overflow.

A program that fails verification is rejected before it ever touches kernel memory.

## What can eBPF do?

```
                    ┌─────────────────────────────┐
                    │        Linux Kernel          │
                    │                              │
  Network ──────►  │  XDP ──► TC ──► Socket      │
                    │                              │
  Syscalls ──────► │  Tracepoints / Kprobes       │
                    │                              │
  Security ──────► │  LSM (Linux Security Module) │
                    │                              │
  Perf ──────────► │  Perf Events                 │
                    └────────────┬────────────────┘
                                 │  maps / ring buffer
                    ┌────────────▼────────────────┐
                    │  Your Go userspace program   │
                    │  (cilium/ebpf)               │
                    └─────────────────────────────┘
```

| Category | What it enables |
|----------|-----------------|
| **Observability** | Zero-overhead syscall tracing, network flow logs, CPU profiles |
| **Networking** | XDP packet filtering at line rate, L4 load balancing, NAT |
| **Security** | Policy enforcement at exec/file/network hooks, runtime threat detection |
| **Profiling** | Sampling-based CPU profiler, latency histograms, flame graphs |

## eBPF in the container ecosystem

Every major container-native tool today runs on eBPF:

| Tool | What it replaces | eBPF feature |
|------|-----------------|--------------|
| Cilium CNI | kube-proxy + iptables | XDP + TC + sockmap |
| Tetragon | Falco (iptables-based) | kprobe + LSM |
| Pixie | Distributed tracing sidecars | uprobe |
| Parca | Polling-based profilers | perf_event |
| Retina | Windows CoreDNS sidecar | eBPF (Windows) |

## What this series teaches

You will learn eBPF from **first principles** through **production-grade Go programs**:
- Write eBPF C programs that run in the kernel.
- Compile them with `bpf2go` into typed Go assets.
- Load, attach, and read events from Go using `cilium/ebpf`.
- Apply this in real Docker and Kubernetes environments.

Every lesson pairs **a kernel-side eBPF C program** with **a Go userspace program** — no Python, no BCC, no CGo.

## Prerequisites for the rest of the series

- Linux host or VM running kernel **≥5.13** (recommended: 6.1+).
- Go 1.26 installed (via gvm: `gvm use go1.26rc1`).
- Docker or the VS Code Dev Container.

Run `bash scripts/verify-env.sh` to confirm your environment.
