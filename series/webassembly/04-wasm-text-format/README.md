# 04 — Reading WAT: The WebAssembly Text Format

> **Type:** Explanation + Reference

## What is WAT?

WAT (WebAssembly Text Format) is the human-readable equivalent of a `.wasm` binary. Every valid `.wasm` file has a 1-to-1 `.wat` representation. It uses S-expression syntax (like Lisp).

You rarely write WAT by hand — but reading it is an essential debugging skill when you want to understand exactly what your Rust code compiled to.

## Converting between formats

```bash
# wasm → wat (requires WABT)
wasm2wat hello.wasm -o hello.wat

# wat → wasm (compile text format)
wat2wasm hello.wat -o hello.wasm
```

Install WABT: https://github.com/WebAssembly/wabt

## Anatomy of a WAT file

```wat
(module
  ;; Declare that we import a function from JavaScript
  (import "env" "log" (func $log (param i32)))

  ;; Declare linear memory: 1 page = 64 KiB
  (memory (export "memory") 1)

  ;; Store the string "Hello" in memory at offset 0
  (data (i32.const 0) "Hello\n")

  ;; Define and export a function
  (func $main (export "main")
    i32.const 0   ;; push pointer to string
    call $log     ;; call imported JS function
  )
)
```

## Key WAT constructs

| Construct | Meaning |
|-----------|---------|
| `(module ...)` | Root container |
| `(import "ns" "name" ...)` | Import from host environment |
| `(func $name ...)` | Define a function |
| `(export "name" (func $f))` | Expose a function to host |
| `(memory n)` | Declare linear memory with `n` pages |
| `(data ...)` | Initialize memory with bytes |
| `(local $x i32)` | Declare local variable |
| `local.get $x` | Push local var onto stack |
| `local.set $x` | Pop stack into local var |
| `i32.const 42` | Push constant integer |
| `i32.add` | Pop two i32s, push their sum |
| `call $fn` | Call a function |
| `if ... end` | Conditional block |
| `loop ... end` | Loop block |

## Why this matters for Rust developers

When you compile Rust to Wasm, `wasm-bindgen` generates glue code. Reading the WAT output lets you verify:
- Functions are being exported correctly.
- No unexpected bloat from monomorphization.
- Memory is initialized as expected.

Use DevTools → Sources → `.wasm` file (browsers auto-disassemble to WAT).
