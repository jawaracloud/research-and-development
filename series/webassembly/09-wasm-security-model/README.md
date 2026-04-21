# 09 — The Wasm Security Sandbox

> **Type:** Explanation

## Why security is built in

WebAssembly was designed from the beginning with security as a first-class constraint. This is because Wasm modules come from the internet and execute on end-user machines.

## The four pillars of Wasm security

### 1. Memory isolation

Each Wasm module has its own **linear memory**. It cannot read or write any other module's memory, the JS heap, the browser's internal memory, or the OS memory. All memory accesses are bounds-checked at the hardware level (or via instrumentation).

An out-of-bounds memory access causes a **trap** (a controlled exception) — never a buffer overflow that could exploit the host.

### 2. Capability-based security

Wasm cannot do *anything* by default:
- No file I/O
- No network
- No DOM access
- No system calls

It can **only** call functions that the host explicitly provides via the import object. The module declares what it wants (imports), and the host decides what to grant. This is the principle of least privilege.

```
Wasm module says:  "I need a function called `env.log`"
Host JS says:      "Fine. Here is console.log."
                   (The module gets only that function — nothing else)
```

### 3. Type safety and validation

Before execution, every Wasm module is **formally validated**. The validator checks:
- All function calls pass the correct types.
- Stack is always consistent.
- Control flow is structured (no goto).
- No undefined behavior is possible.

A module that fails validation is rejected entirely — it never runs.

### 4. Control flow integrity

Indirect calls (via function tables) are validated so that a call target is always a valid function with the expected signature. Wasm cannot jump into the middle of a function or skip instructions.

## What Wasm does NOT protect against

- **Logic bugs in the Wasm code** — a vulnerability in the Rust/Wasm logic is still exploitable.
- **Speculative execution attacks** (Spectre/Meltdown) — browsers use site isolation, JIT mitigations, and timers restrictions to mitigate this.
- **DoS** — a Wasm module can spin in an infinite loop. The browser's watchdog timer handles this the same way it handles infinite JS loops.

## Wasm vs native code security

| Property | Native binary | WebAssembly |
|---------|--------------|------------|
| Memory isolation | ❌ (relies on OS) | ✅ (sandbox) |
| Capability restrictions | ❌ (full syscall access) | ✅ (only granted imports) |
| Control flow integrity | ❌ (partial via ASLR/CFI) | ✅ (by design) |
| Validated before run | ❌ | ✅ |
| Portable | ❌ | ✅ |
