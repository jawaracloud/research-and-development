# 06 — Linear Memory: How Wasm Manages Data

> **Type:** Explanation

## The concept of linear memory

Wasm modules have access to a single, flat array of bytes called **linear memory**. Think of it as a big `Vec<u8>` visible to both Wasm and JavaScript. It grows upward, page by page (1 page = 64 KiB).

```
┌──────────────────────────────────┐
│  Address 0                       │
│  Stack (grows ↓)                 │
│                                  │
│  Heap  (grows ↑)                 │
│  Static data (strings, globals)  │
└──────────────────────────────────┘
  (all of this is "linear memory")
```

## Declaring memory in WAT

```wat
;; Declare 1 page (64 KiB), max 10 pages
(memory 1 10)

;; Export it so JavaScript can access it as an ArrayBuffer
(memory (export "memory") 1)
```

## Reading and writing memory

| Instruction | Description |
|------------|-------------|
| `i32.load` | Read 4 bytes from address |
| `i32.store` | Write 4 bytes to address |
| `i32.load8_u` | Read 1 byte, zero-extend to i32 |
| `i32.store8` | Write low 8 bits of i32 to address |
| `memory.grow n` | Grow by `n` pages, returns old size or -1 |
| `memory.size` | Current size in pages |

## Sharing memory with JavaScript

Once exported, JavaScript sees the Wasm linear memory as an `ArrayBuffer`. You can wrap it in typed array views:

```javascript
const { memory } = wasmModule.instance.exports;
const u8 = new Uint8Array(memory.buffer);
const i32 = new Int32Array(memory.buffer);
```

This enables **zero-copy data sharing** — no serialization needed for raw buffers like image data or audio samples.

## How Rust uses linear memory

When you compile Rust to Wasm:
- **Static data** (string literals, `static` variables) goes at the beginning of memory.
- **Stack** grows downward from a fixed stack pointer.
- **Heap** is managed by Rust's allocator (either the system allocator or `wee_alloc` in Wasm mode).

The allocator itself lives inside the Wasm module. Rust's `Box`, `Vec`, `String`, etc. all allocate in this linear memory heap.

## Key limitations

- There is **only one linear memory** per module (currently — the multi-memory proposal may change this).
- Memory can **only grow**, not shrink. A `memory.grow` call may fail if the host limits it.
- Wasm memory is **isolated** — one module cannot access another module's memory.
- In the browser, total linear memory is also limited (usually to ~4 GB for 32-bit Wasm).

## Why this is safe

The Wasm runtime enforces that all memory accesses stay within bounds. An out-of-bounds access traps (crashes with an error) rather than reading or writing arbitrary host memory. This is the foundation of Wasm's security model.
