# 02 — Wasm vs JavaScript: Complementary, Not Competing

> **Type:** Explanation

## The relationship

WebAssembly does **not** replace JavaScript. The two are designed to work *together*. JavaScript orchestrates the page, handles high-level logic, and calls into Wasm when raw computation is needed.

A useful analogy: JavaScript is the **manager** and Wasm is the **specialist contractor** brought in for heavy lifting.

## Where each excels

| Task | JavaScript | Wasm |
|------|-----------|------|
| DOM manipulation | ✅ Native | ❌ Via JS interop only |
| String processing | ✅ Good | ⚠️ Crossing boundary has cost |
| Heavy computation (image, video, audio, physics) | ⚠️ Slow | ✅ Near-native |
| Dynamic typing / scripting | ✅ | ❌ Statically typed |
| Startup time | ✅ Fast parse | ⚠️ Binary download + compile |
| Existing web platform APIs | ✅ Direct | ❌ Must go through JS |

## The interop boundary

Every call between JS and Wasm crosses the **JS–Wasm boundary**. This crossing is cheap but *not free*. Passing complex data (strings, objects) requires serialization. This means:

- Keep Wasm doing large chunks of work, not many tiny calls.
- Prefer passing raw numbers (integers, floats) across the boundary — these are zero-cost.
- Use shared memory (`SharedArrayBuffer`) when you need to pass large buffers.

## When to use Wasm

Use Wasm when you have:
- CPU-intensive work (codec decoding, cryptography, physics simulation, image filters).
- Existing native code (C/C++ library) you want to run in the browser.
- A reason to use a language other than JS (type safety, ecosystem, performance).

Do **not** reach for Wasm just because you think it will be faster for simple tasks. The overhead of loading a `.wasm` module, compiling it, and crossing the boundary can easily cost more than a plain JS implementation for small tasks.

## A concrete example

```
User clicks "Apply Blur" on a 4K image
        │
        ▼ JavaScript
reads pixel buffer, passes ArrayBuffer to Wasm
        │
        ▼ Wasm (Rust)
applies Gaussian blur — millions of floating-point ops
        │
        ▼ JavaScript
writes result buffer back to Canvas
```

The billion multiply-and-add operations happen in Wasm at near-C speed. The two boundary crossings (passing in and out the buffer) are cheap because they use shared memory.
