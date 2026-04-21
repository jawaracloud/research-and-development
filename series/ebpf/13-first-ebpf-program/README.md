# 13 — Writing Your First eBPF Program in C

> **Type:** Tutorial

## What you're building

A minimal eBPF kprobe that fires every time any process calls `execve()` (starts a new program). It logs the process name (comm) to a ring buffer, which the Go userspace program reads and prints.

This is the "Hello, World!" of eBPF kernel tracing.

## Project layout

```
13-first-ebpf-program/
├── main.go           # Go userspace: load, attach, read
├── execve.bpf.c      # eBPF C: kernel-side hook
└── go.mod
```

## Step 1: Write the eBPF C program

`execve.bpf.c`:

```c
// SPDX-License-Identifier: GPL-2.0
// Requires kernel ≥5.13 (BTF + ring buffer)
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

// ── Event structure sent to userspace ────────────────────────────────────────
struct event {
    __u32 pid;
    __u32 uid;
    char  comm[16]; // task_struct.comm is 16 bytes
};

// ── Ring buffer map: low-overhead, ordered, variable-size events ─────────────
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 1 << 24); // 16 MB ring buffer
} events SEC(".maps");

// ── kprobe on the sys_execve tracepoint ──────────────────────────────────────
// SEC("tp/syscalls/sys_enter_execve") is preferred over kprobe for stability
SEC("tp/syscalls/sys_enter_execve")
int tracepoint__sys_enter_execve(struct trace_event_raw_sys_enter *ctx)
{
    struct event *e;

    // Reserve space in the ring buffer (non-blocking)
    e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
    if (!e)
        return 0; // ring buffer full — drop event

    // Populate event
    e->pid = bpf_get_current_pid_tgid() >> 32;
    e->uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;
    bpf_get_current_comm(&e->comm, sizeof(e->comm));

    // Submit to userspace
    bpf_ringbuf_submit(e, 0);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

## Step 2: Initialize Go module

```bash
mkdir -p 13-first-ebpf-program && cd 13-first-ebpf-program
go mod init github.com/you/ebpf-series/13-first-ebpf-program
go get github.com/cilium/ebpf@latest
```

## Step 3: Add the go:generate directive

`main.go`:

```go
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go \
//   -cc clang \
//   -cflags "-O2 -g -Wall -target bpf" \
//   Execve execve.bpf.c

package main

import (
    "bytes"
    "encoding/binary"
    "log"
    "os"
    "os/signal"
    "syscall"

    "github.com/cilium/ebpf/link"
    "github.com/cilium/ebpf/ringbuf"
    "github.com/cilium/ebpf/rlimit"
)

// event mirrors the C struct
type event struct {
    PID  uint32
    UID  uint32
    Comm [16]byte
}

func main() {
    // 1. Remove memlock limit (required pre-kernel 5.11)
    if err := rlimit.RemoveMemlock(); err != nil {
        log.Fatal("removing memlock:", err)
    }

    // 2. Load compiled BPF objects
    objs := ExecveObjects{}
    if err := LoadExecveObjects(&objs, nil); err != nil {
        log.Fatal("loading BPF objects:", err)
    }
    defer objs.Close()

    // 3. Attach to the tracepoint
    tp, err := link.Tracepoint("syscalls", "sys_enter_execve",
        objs.TracepointSysEnterExecve, nil)
    if err != nil {
        log.Fatal("attaching tracepoint:", err)
    }
    defer tp.Close()

    // 4. Open the ring buffer reader
    rd, err := ringbuf.NewReader(objs.Events)
    if err != nil {
        log.Fatal("opening ring buffer:", err)
    }
    defer rd.Close()

    log.Println("Listening for execve events… (Ctrl+C to stop)")

    // 5. Handle Ctrl+C
    stop := make(chan os.Signal, 1)
    signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
    go func() {
        <-stop
        rd.Close()
    }()

    // 6. Read events
    for {
        record, err := rd.Read()
        if err != nil {
            if ringbuf.IsUnreadable(err) {
                break // reader closed
            }
            log.Println("reading ring buffer:", err)
            continue
        }

        var e event
        if err := binary.Read(bytes.NewBuffer(record.RawSample),
            binary.LittleEndian, &e); err != nil {
            log.Println("parsing event:", err)
            continue
        }

        comm := string(bytes.TrimRight(e.Comm[:], "\x00"))
        log.Printf("pid=%-6d uid=%-5d comm=%s\n", e.PID, e.UID, comm)
    }
}
```

## Step 4: Compile and run

```bash
# Generate Go types from BPF C (compiles execve.bpf.c → execve_bpf*.go)
go generate ./...

# Build Go binary
go build -o execve-trace .

# Run (requires privilege for BPF)
sudo ./execve-trace
```

## Step 5: Trigger some events

Open another terminal and run any command:

```bash
ls /tmp
echo hello
cat /etc/hostname
```

## Expected output

```
2024/01/01 12:00:00 Listening for execve events… (Ctrl+C to stop)
2024/01/01 12:00:01 pid=12345  uid=1000  comm=ls
2024/01/01 12:00:02 pid=12346  uid=1000  comm=echo
2024/01/01 12:00:03 pid=12347  uid=1000  comm=cat
```

## Key concepts

| Concept | Description |
|---------|-------------|
| `SEC("tp/syscalls/sys_enter_execve")` | Tracepoint — stable interface, preferred over raw kprobe |
| `BPF_MAP_TYPE_RINGBUF` | Ordered, efficient kernel→userspace event channel |
| `bpf_ringbuf_reserve` | Atomically reserves space; returns NULL if full |
| `bpf_ringbuf_submit` | Commits the reserved record for userspace to read |
| `bpf_get_current_comm` | Copies the current task's command name (max 16 bytes) |
| `bpf2go` | Compiles `.bpf.c` → typed Go structs + embedded BPF bytecode |
| `link.Tracepoint` | cilium/ebpf API to attach to a kernel tracepoint |
| `ringbuf.NewReader` | Go reader for `BPF_MAP_TYPE_RINGBUF` events |

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `verifier: permission denied` | Missing `CAP_BPF` | Run as root or in privileged container |
| `invalid argument: unknown func bpf_ringbuf_reserve` | Kernel < 5.8 | Upgrade kernel or use `BPF_MAP_TYPE_PERF_EVENT_ARRAY` |
| `no such file: vmlinux.h` | BTF header missing | Run `bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h` |
| `bpf2go: exec: clang: not found` | clang not installed | `apt install clang-18` |
