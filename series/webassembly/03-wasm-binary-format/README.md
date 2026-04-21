# 03 — Understanding the Wasm Binary Format (.wasm)

> **Type:** Explanation

## What is a .wasm file?

A `.wasm` file is a binary-encoded module. It is not machine code — it is a portable IR (intermediate representation) that browsers download and compile to machine code on the fly.

The binary format is designed to be:
- **Compact** — smaller than equivalent JavaScript.
- **Fast to decode** — sequential, no backtracking required.
- **Validated** — the binary must pass a structural check before execution.

## Anatomy of a Wasm module

A `.wasm` file is made up of **sections**, each with a one-byte section ID, a byte-length, and a body.

| Section | ID | Purpose |
|---------|----|---------|
| Type | 1 | Function signature declarations |
| Import | 2 | Functions/memory/tables imported from the host (JS) |
| Function | 3 | Maps function indices to their type |
| Table | 4 | Indirect function call tables |
| Memory | 5 | Linear memory declarations |
| Global | 6 | Global variable declarations |
| Export | 7 | Functions/memory/tables exported to the host |
| Start | 8 | Optional entry-point function |
| Element | 9 | Initializers for tables |
| Code | 10 | Function bodies (the actual instructions) |
| Data | 11 | Initial values for linear memory |
| Custom | 0 | Debug info, names, linking metadata |

## Magic number and version

Every `.wasm` file starts with:
```
00 61 73 6D  ← magic: "\0asm"
01 00 00 00  ← version: 1
```

You can verify this with `xxd yourfile.wasm | head -1`.

## What goes inside a function body?

Each function body in the Code section contains:
- Local variable declarations.
- A sequence of **opcodes** (instructions), e.g., `i32.const`, `i32.add`, `local.get`, `call`.

Wasm only has four value types: `i32`, `i64`, `f32`, `f64`. (Newer proposals add `v128` for SIMD and reference types.)

## How big is a typical Rust Wasm binary?

| Build profile | Typical size |
|--------------|-------------|
| Debug (unoptimized) | 2–10 MB |
| Release (`wasm-opt -Oz`) | 50–500 KB |
| With `wee_alloc` (tiny allocator) | even smaller |

> For production you always run `wasm-opt` (covered in lesson 16).
