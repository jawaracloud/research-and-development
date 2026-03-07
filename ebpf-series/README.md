# eBPF in Container Environments — Go Series

> A structured, 100-lesson journey through **eBPF programming with Go 1.26** in Docker and Kubernetes environments. Uses `cilium/ebpf` as the primary library — pure Go, minimal dependencies.

---

## Introduction

**eBPF** (extended Berkeley Packet Filter) is a revolutionary technology that lets you run sandboxed programs in the Linux kernel without changing kernel source code or loading kernel modules. It is the foundation of modern observability, networking, and security tools:

| Tool | Uses eBPF for |
|------|---------------|
| Cilium | Kubernetes networking |
| Falco | Runtime security |
| Pixie | Application observability |
| bcc / bpftrace | Kernel tracing and profiling |
| Tetragon | Security enforcement |

**Why Go 1.26 + cilium/ebpf?**
- `cilium/ebpf` is a **pure Go** library — no CGo, no Python, no BCC dependency.
- `bpf2go` compiles your eBPF C programs at `go generate` time, embedding them as Go byte slices.
- Go 1.26 brings improved generics, range-over-func, and better toolchain performance.

**Series focus: containers.** Every lesson is contextualized in Docker/Kubernetes environments — tracing container syscalls, monitoring pod networking, enforcing security policies at the kernel level.

Each lesson lives in its own directory with a `README.md` following the **Diátaxis** framework.

---

## 🛠️ Environment Setup

> [!IMPORTANT]
> eBPF requires **Linux kernel ≥5.13** and **privileged access** (`CAP_BPF`, `CAP_SYS_ADMIN`). Windows/macOS hosts must use a Linux VM or the dev container.

### Option A — VS Code Dev Container (recommended)

Requires: VS Code + [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) + Docker Desktop (Linux host or Linux VM).

1. Open the `ebpf-series/` folder in VS Code.
2. Click **"Reopen in Container"**.
3. Wait ~5 min first build — Go 1.26 + clang + libbpf install.
4. Terminal has full eBPF access.

### Option B — Docker Compose (CLI)

```bash
# Build once
docker compose build

# Open shell with all tools + privileged access
docker compose run --rm dev
```

### Verify your environment

```bash
bash scripts/verify-env.sh
```

Expected: all ✅, kernel ≥5.13, `/sys/kernel/debug/tracing` accessible.

---

## What's installed

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.26 | Userspace programs |
| clang/LLVM | 18 | Compile eBPF C → BPF bytecode |
| libbpf | system | Low-level BPF syscall wrappers |
| bpftool | system | Inspect/load/debug BPF programs |
| cilium/ebpf | latest | Go eBPF framework |
| bpf2go | latest | Compile-time eBPF C → Go asset |
| linux-headers | kernel | eBPF CO-RE / BTF type resolution |

---

## Table of Contents

### Part 1 — eBPF Fundamentals

| # | Topic | Type |
|---|-------|------|
| [01](./01-what-is-ebpf/README.md) | What Is eBPF? | Explanation |
| [02](./02-architecture/README.md) | eBPF Architecture: Verifier, JIT, Maps, Hooks | Explanation |
| [03](./03-program-types/README.md) | eBPF Program Types Overview | Reference |
| [04](./04-maps/README.md) | eBPF Maps: Hash, Array, Ring Buffer, Per-CPU | Explanation + Reference |
| [05](./05-verifier/README.md) | The eBPF Verifier: Safety Guarantees | Explanation |
| [06](./06-helper-functions/README.md) | eBPF Helper Functions Reference | Reference |
| [07](./07-btf-core/README.md) | BPF Type Format (BTF) and CO-RE | Explanation |
| [08](./08-kernel-requirements/README.md) | Kernel Requirements and Compatibility | Reference |
| [09](./09-bpftool/README.md) | bpftool: Inspect, Load, and Debug eBPF | How-To |
| [10](./10-ebpf-vs-alternatives/README.md) | eBPF vs iptables, tc, and Kernel Modules | Explanation |

### Part 2 — Go Toolchain for eBPF

| # | Topic | Type |
|---|-------|------|
| [11](./11-setup-go-cilium/README.md) | Setting Up Go 1.26 + cilium/ebpf | Tutorial |
| [12](./12-bpf2go/README.md) | bpf2go: Compile eBPF C → Go Assets | Tutorial |
| [13](./13-first-ebpf-program/README.md) | Writing Your First eBPF Program in C | Tutorial |
| [14](./14-load-and-attach/README.md) | Loading and Attaching from Go | How-To |
| [15](./15-reading-maps/README.md) | Reading eBPF Maps from Go | How-To |
| [16](./16-ring-buffer/README.md) | Ring Buffer: Streaming Events to Userspace | How-To |
| [17](./17-perf-vs-ring/README.md) | Perf Buffer vs Ring Buffer | Explanation |
| [18](./18-lifecycle/README.md) | eBPF Program Lifecycle Management | How-To |
| [19](./19-error-handling/README.md) | Error Handling and Debugging in Go | How-To |
| [20](./20-unit-testing/README.md) | Unit Testing eBPF Go Code | How-To + Tutorial |

### Part 3 — Tracing: Kprobes, Tracepoints, Uprobes

| # | Topic | Type |
|---|-------|------|
| [21](./21-kprobes/README.md) | Kprobes: Hooking Kernel Functions | How-To |
| [22](./22-kretprobes/README.md) | Kretprobes: Capturing Return Values | How-To |
| [23](./23-tracepoints/README.md) | Tracepoints: Stable Kernel Hooks | How-To |
| [24](./24-syscall-tracing/README.md) | Tracing syscalls: open, read, write, exec | How-To |
| [25](./25-process-lifecycle/README.md) | Tracing Process Lifecycle: fork, exec, exit | How-To |
| [26](./26-uprobes/README.md) | Uprobes: Tracing Userspace Functions | How-To |
| [27](./27-go-uprobes/README.md) | Tracing Go Applications with Uprobes | How-To |
| [28](./28-stack-traces/README.md) | Stack Traces and Symbol Resolution | How-To |
| [29](./29-filtering/README.md) | Filtering Events by PID, UID, Cgroup | How-To |
| [30](./30-top-tool/README.md) | Building a Simple Top-like Tool | Tutorial |

### Part 4 — Networking: XDP, TC, Socket Filters

| # | Topic | Type |
|---|-------|------|
| [31](./31-xdp-overview/README.md) | XDP Overview: eXpress Data Path | Explanation |
| [32](./32-xdp-actions/README.md) | XDP: Drop, Pass, Redirect Actions | How-To |
| [33](./33-xdp-parsing/README.md) | XDP Packet Parsing: Ethernet, IP, TCP/UDP | How-To |
| [34](./34-xdp-rate-limiter/README.md) | XDP Rate Limiter | Tutorial |
| [35](./35-xdp-load-balancer/README.md) | XDP Load Balancer (round-robin) | Tutorial |
| [36](./36-tc/README.md) | TC (Traffic Control) eBPF Programs | How-To |
| [37](./37-tc-redirect/README.md) | TC: Packet Modification and Redirect | How-To |
| [38](./38-socket-filter/README.md) | Socket Filters: Per-Socket Packet Inspection | How-To |
| [39](./39-cgroup-socket/README.md) | Cgroup Socket Programs | How-To |
| [40](./40-dns-parser/README.md) | DNS Packet Parser with eBPF | Tutorial |

### Part 5 — Container-Aware eBPF

| # | Topic | Type |
|---|-------|------|
| [41](./41-namespaces-cgroups/README.md) | Linux Namespaces and Cgroups Primer | Explanation |
| [42](./42-cgroup-id/README.md) | Identifying Containers via Cgroup ID | How-To |
| [43](./43-cgroup-to-container/README.md) | Mapping Cgroup IDs to Container Names | How-To |
| [44](./44-per-container-syscalls/README.md) | Per-Container Syscall Counting | Tutorial |
| [45](./45-per-container-network/README.md) | Per-Container Network Traffic Monitoring | Tutorial |
| [46](./46-container-lifecycle/README.md) | Tracing Container Lifecycle Events | How-To |
| [47](./47-container-fs/README.md) | Container Filesystem Access Monitoring | How-To |
| [48](./48-escape-detection/README.md) | Detecting Privileged Container Escapes | How-To |
| [49](./49-ebpf-in-containers/README.md) | eBPF Inside Containers: Capabilities Required | Explanation |
| [50](./50-bpf-namespace/README.md) | BPF Namespace and Resource Limits | Explanation |

### Part 6 — Docker Observability

| # | Topic | Type |
|---|-------|------|
| [51](./51-docker-hooks/README.md) | Docker Architecture and eBPF Hook Points | Explanation |
| [52](./52-docker-network/README.md) | Monitoring Docker Network (veth, bridges) | How-To |
| [53](./53-docker-lifecycle/README.md) | Tracing Docker Container Start/Stop | How-To |
| [54](./54-docker-dns/README.md) | Docker DNS Resolution Tracing | How-To |
| [55](./55-docker-volume-io/README.md) | Docker Volume I/O Monitoring | How-To |
| [56](./56-docker-build-trace/README.md) | Docker Build Step Tracing | How-To |
| [57](./57-docker-compose/README.md) | Docker Compose Multi-Container Monitoring | Tutorial |
| [58](./58-docker-health/README.md) | Docker Health Check Integration | How-To |
| [59](./59-docker-events/README.md) | Docker Daemon Event Correlation | How-To |
| [60](./60-docker-security/README.md) | Building a Docker Security Monitor | Tutorial |

### Part 7 — Kubernetes Networking with eBPF

| # | Topic | Type |
|---|-------|------|
| [61](./61-k8s-networking/README.md) | Kubernetes Networking Model Overview | Explanation |
| [62](./62-pod-to-pod/README.md) | Tracing Pod-to-Pod Communication | How-To |
| [63](./63-service-traffic/README.md) | Tracing Service (ClusterIP) Traffic | How-To |
| [64](./64-nodeport/README.md) | NodePort and LoadBalancer Tracing | How-To |
| [65](./65-coredns/README.md) | Kubernetes DNS (CoreDNS) Monitoring | How-To |
| [66](./66-network-policy/README.md) | Network Policy Enforcement with eBPF | How-To |
| [67](./67-ingress/README.md) | Ingress Traffic Analysis | How-To |
| [68](./68-service-mesh/README.md) | eBPF-Based Service Mesh Concepts | Explanation |
| [69](./69-cni/README.md) | Kubernetes CNI and eBPF Integration | Explanation |
| [70](./70-multi-cluster/README.md) | Multi-Cluster Network Tracing | How-To |

### Part 8 — Security: LSM, Seccomp, Runtime Defense

| # | Topic | Type |
|---|-------|------|
| [71](./71-lsm-bpf/README.md) | LSM (Linux Security Modules) eBPF Programs | Explanation + How-To |
| [72](./72-lsm-file/README.md) | Blocking File Access with LSM-BPF | How-To |
| [73](./73-lsm-network/README.md) | Restricting Network Connections with LSM-BPF | How-To |
| [74](./74-seccomp-ebpf/README.md) | eBPF-Enhanced Seccomp Policies | How-To |
| [75](./75-exec-monitoring/README.md) | Process Execution Monitoring (Falco-style) | How-To |
| [76](./76-shell-detection/README.md) | Detecting Suspicious Shell in Containers | Tutorial |
| [77](./77-crypto-mining/README.md) | Crypto Mining Detection via Syscall Patterns | Tutorial |
| [78](./78-container-escape/README.md) | Container Escape Detection | Tutorial |
| [79](./79-file-integrity/README.md) | File Integrity Monitoring | How-To |
| [80](./80-runtime-security/README.md) | Building a Runtime Security Agent | Tutorial |

### Part 9 — Performance & Profiling

| # | Topic | Type |
|---|-------|------|
| [81](./81-cpu-profiling/README.md) | CPU Profiling with Perf Events | How-To |
| [82](./82-off-cpu/README.md) | Off-CPU / Scheduler Tracing | How-To |
| [83](./83-memory-tracing/README.md) | Memory Allocation Tracing | How-To |
| [84](./84-disk-io/README.md) | Disk I/O Latency Histograms | How-To |
| [85](./85-network-latency/README.md) | Network Latency Measurement | How-To |
| [86](./86-tcp-retransmit/README.md) | TCP Retransmit and Connection Tracing | How-To |
| [87](./87-go-runtime/README.md) | Go Runtime Tracing (goroutines, GC) | How-To |
| [88](./88-container-profiling/README.md) | Container Resource Usage Profiling | How-To |
| [89](./89-flame-graphs/README.md) | Flame Graphs from eBPF Data | How-To + Tutorial |
| [90](./90-latency-analysis/README.md) | Full-Stack Latency Analysis | Tutorial |

### Part 10 — CI/CD, Testing & Advanced Topics

| # | Topic | Type |
|---|-------|------|
| [91](./91-ci-testing/README.md) | Testing eBPF Programs in CI (GitHub Actions) | How-To + Tutorial |
| [92](./92-test-frameworks/README.md) | Test Frameworks for eBPF Go Programs | How-To + Reference |
| [93](./93-versioning/README.md) | eBPF Program Versioning and Upgrades | How-To |
| [94](./94-core/README.md) | CO-RE: Compile Once, Run Everywhere | Explanation + How-To |
| [95](./95-btf-vmlinux/README.md) | BTF Generation and vmlinux.h | How-To |
| [96](./96-tail-calls/README.md) | Tail Calls and Program Chaining | How-To |
| [97](./97-iterators/README.md) | eBPF Iterators and Batch Operations | How-To |
| [98](./98-wasm-ebpf/README.md) | WASM + eBPF: Wasm-based eBPF Plugins | Explanation + How-To |
| [99](./99-observability-platform/README.md) | Building an Observability Platform | Tutorial |
| [100](./100-whats-next/README.md) | What's Next: Your eBPF Path Forward | Reference |

---

## References

- [cilium/ebpf](https://github.com/cilium/ebpf) — Go eBPF library
- [ebpf.io](https://ebpf.io) — Community hub, introductions
- [Kernel docs: BPF](https://docs.kernel.org/bpf/) — Official kernel documentation
- [isovalent/ebpf-docs](https://github.com/isovalent/ebpf-docs) — Technical eBPF reference
- [bpftool man page](https://man7.org/linux/man-pages/man8/bpftool.8.html)
- [BCC tools](https://github.com/iovisor/bcc) — Reference Python/C implementations
- [Diátaxis Framework](https://diataxis.fr/)
