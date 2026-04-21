# 94 — CO-RE: Compile Once, Run Everywhere

> **Type:** Explanation + How-To

## What you're building

How BPF CO-RE uses BTF relocation to adjust field offsets for any kernel version.

## Kernel / environment requirements

| Requirement | Minimum |
|-------------|---------|
| Linux kernel | ≥5.13 (BTF + CO-RE) |
| Go | 1.26 |
| Capability | CAP_BPF, CAP_SYS_ADMIN |
| eBPF hook | `none` |

## eBPF C program (skeleton)

```c
// SPDX-License-Identifier: GPL-2.0
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

// TODO: implement the 94-core eBPF program

char LICENSE[] SEC("license") = "GPL";
```

## Go userspace program

```go
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -cc clang Bpf 94-core.bpf.c

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
go build -o 94-core .
sudo ./94-core
```

## Expected output

```
eBPF program loaded.
[events streaming …]
```

## Key concepts

| Concept | Description |
|---------|-------------|
| Hook | `none` — the kernel attach point |
| Map | Used to pass data between kernel and userspace |
| Ring buffer | Low-overhead ordered event streaming |
| CO-RE | Compile Once, Run Everywhere — portable BPF |
