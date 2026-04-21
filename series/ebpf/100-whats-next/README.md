# 100 — What's Next: Your eBPF Path Forward

> **Type:** Reference

## What you've built

Over 100 lessons you can now:

| Area | Skills |
|------|--------|
| Fundamentals | Verifier, BTF, CO-RE, all map types, bpftool |
| Tracing | kprobes, tracepoints, uprobes, stack traces |
| Networking | XDP drop/redirect, TC rewrite, socket filters |
| Containers | Per-cgroup monitoring, Docker/K8s observability |
| Security | LSM-BPF, exec monitoring, escape detection |
| Performance | CPU/disk/network latency, flame graphs |
| Engineering | CI testing, versioning, iterators, tail calls |

## Suggested next steps

### 1. Contribute to open-source eBPF projects
- [Cilium](https://github.com/cilium/cilium) — K8s networking
- [Tetragon](https://github.com/cilium/tetragon) — Security enforcement
- [Pixie](https://github.com/pixie-io/pixie) — App observability
- [Parca](https://github.com/parca-dev/parca) — Continuous profiling

### 2. Get eBPF certified
- [eBPF Foundation](https://ebpf.io) — Training resources
- [Isovalent eBPF Lab](https://isovalent.com/labs/) — browser-based kernel labs

### 3. Explore advanced features
- **Bloom filter maps** (kernel 5.16+) — fast membership testing
- **Arena maps** (kernel 6.9+) — heap-like allocation in BPF
- **BPF timers** — kernel-side periodic callbacks without userspace polling
- **Struct-ops** — replace kernel subsystem callbacks with BPF

### 4. Build your own platform
Combine lessons 60, 80, 90, and 99:
```
eBPF agent (Go)
    ├── kprobe/exec      → security events
    ├── TC               → per-pod network stats
    ├── perf_event       → CPU profiles
    └── HTTP API         → Prometheus + Grafana
```

## Essential commands reference

| Command | Purpose |
|---------|---------|
| `bpftool prog list` | Show loaded programs |
| `bpftool map dump id N` | Dump map contents |
| `bpftool net show` | XDP/TC program attachments |
| `bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h` | Generate vmlinux header |
| `go generate ./...` | Compile BPF C → Go via bpf2go |
| `sudo cat /sys/kernel/debug/tracing/trace_pipe` | Raw tracing output |

## References

- [cilium/ebpf docs](https://pkg.go.dev/github.com/cilium/ebpf)
- [Kernel BPF docs](https://docs.kernel.org/bpf/)
- [Isovalent eBPF Docs](https://isovalent.com/blog/ebpf/)
- [eBPF Summit talks](https://ebpf.io/summit-2024/)
- [Brendan Gregg's eBPF page](https://www.brendangregg.com/ebpf.html)
