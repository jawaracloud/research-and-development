# 71 — LSM eBPF Programs

> **Type:** Explanation + How-To

## What you're building

Write SEC("lsm/...") hooks. KernelVersion ≥5.7. Attach with link.AttachLSM.

## Kernel / environment requirements

| Requirement | Minimum |
|-------------|---------|
| Linux kernel | ≥5.13 (BTF + CO-RE) |
| Go | 1.26 |
| Capability | CAP_BPF, CAP_SYS_ADMIN |
| eBPF hook | `lsm` |

## eBPF C program (skeleton)

```c
// SPDX-License-Identifier: GPL-2.0
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

// TODO: implement the 71-lsm-bpf eBPF program

char LICENSE[] SEC("license") = "GPL";
```

## Go userspace program

```go
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -cc clang Bpf 71-lsm-bpf.bpf.c

package main

import (
    "log"

    "github.com/cilium/ebpf/link"
    "github.com/cilium/ebpf/rlimit"
)

func main() {
    // Remove memory limit for eBPF resources
    if err := rlimit.RemoveMemlock(); err != nil {
        log.Fatal("removing memlock:", err)
    }

    // Load pre-compiled eBPF programs
    objs := BpfObjects{}
    if err := LoadBpfObjects(&objs, nil); err != nil {
        log.Fatal("loading BPF objects:", err)
    }
    defer objs.Close()

    // TODO: attach the program via link.*
    _ = objs
    log.Println("eBPF program loaded. See lesson README for attach instructions.")
}
```

## Run it

```bash
# Compile eBPF C to Go assets
go generate ./...

# Build and run (requires privileged access)
go build -o 71-lsm-bpf .
sudo ./71-lsm-bpf
```

## Expected output

```
eBPF program loaded.
[events streaming …]
```

## Key concepts

| Concept | Description |
|---------|-------------|
| Hook | `lsm` — the kernel attach point |
| Map | Used to pass data between kernel and userspace |
| Ring buffer | Low-overhead ordered event streaming |
| CO-RE | Compile Once, Run Everywhere — portable BPF |
