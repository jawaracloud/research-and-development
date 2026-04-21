# 05 — The Wasm Stack Machine Execution Model

> **Type:** Explanation

## What is a stack machine?

WebAssembly uses a **stack-based** virtual machine. Instructions operate by pushing values onto a virtual stack and popping them off. This is different from a register machine (like x86 or ARM) where instructions explicitly name registers.

You never see the stack directly — it is a conceptual model that the compiler and runtime manage.

## How instructions work

| Instruction | Stack before | Stack after | Effect |
|------------|-------------|------------|--------|
| `i32.const 3` | `[]` | `[3]` | pushes constant 3 |
| `i32.const 4` | `[3]` | `[3, 4]` | pushes constant 4 |
| `i32.add` | `[3, 4]` | `[7]` | pops two, pushes sum |
| `drop` | `[7]` | `[]` | discards top of stack |

To compute `(3 + 4) * 2` in WAT:
```wat
i32.const 3
i32.const 4
i32.add      ;; stack: [7]
i32.const 2
i32.mul      ;; stack: [14]
```

## Structured control flow

Unlike most assembly languages, Wasm has **structured control flow** — there is no arbitrary `goto`. Instead:

- `block ... end` — a block you can `br` (break) out of.
- `loop ... end` — a block you can `br` back to the top of.
- `if ... else ... end` — conditional branch.

This makes Wasm safe to validate and easy to JIT-compile.

## Functions and the call stack

When you `call` a function:
1. Arguments are popped from the stack.
2. A new **activation frame** is pushed (local variables, return address).
3. The function runs.
4. Return values are pushed back to the caller's stack.

Wasm has a separate **call stack** (not part of linear memory) managed by the runtime — you cannot overflow a Wasm program's call stack from within JS.

## Types on the stack

Wasm is strongly typed. Every value on the stack has a known type:
- `i32` — 32-bit integer
- `i64` — 64-bit integer
- `f32` — 32-bit float
- `f64` — 64-bit float
- `v128` — 128-bit SIMD vector (with the SIMD proposal)
- `funcref` / `externref` — reference types (newer proposals)

The validator checks types statically before execution — type mismatches are caught at load time, not at runtime.

## Why this matters for Rust

When you compile Rust, `rustc` maps Rust's type system directly onto Wasm types. The stack machine model is why Wasm compiled code is fast to validate — the JIT compiler can compile each function in a single pass without any type inference burden.
