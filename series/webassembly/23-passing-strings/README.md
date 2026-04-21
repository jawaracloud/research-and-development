# 23 — Passing Strings Between Rust and JavaScript

> **Type:** Explanation + How-To

## Why strings are special

Strings cannot be passed between Rust and JavaScript "for free". Wasm only understands numbers. A string must be encoded as bytes, written into Wasm linear memory, and a pointer + length pair passed as integers. `wasm-bindgen` automates this.

## How it works under the hood

When you write:
```rust
#[wasm_bindgen]
pub fn greet(name: &str) -> String { ... }
```

`wasm-bindgen` generates glue that:
1. On the JS side: encodes the JS string to UTF-8 bytes using `TextEncoder`.
2. Allocates space for those bytes in Wasm linear memory.
3. Calls the Rust function with a pointer (i32) and length (i32).
4. On return: reads the returned bytes from Wasm memory.
5. Decodes them back to a JS string using `TextDecoder`.

This is efficient but **not zero-copy** — a string copy happens at the boundary.

## String parameter types

| Rust type | JS type | Notes |
|-----------|---------|-------|
| `&str` | `string` | Borrow, no transfer of ownership |
| `String` | `string` | Owned, Rust allocates |
| `Option<String>` | `string \| undefined` | Optional |

## Returning strings

```rust
// Return an owned String — JS takes ownership of the data
#[wasm_bindgen]
pub fn make_greeting(name: &str) -> String {
    format!("Hello, {}!", name)
}
```

## Receiving strings

```rust
// Borrow a string slice — most efficient
#[wasm_bindgen]
pub fn count_chars(s: &str) -> usize {
    s.chars().count()
}

// Receive an owned String (less common)
#[wasm_bindgen]
pub fn take_and_modify(mut s: String) -> String {
    s.push_str(" appended");
    s
}
```

## Working with string data manually (advanced)

When you need maximum control — e.g., passing a string without `wasm-bindgen` glue:

Rust:
```rust
// Export a malloc-like function so JS can allocate Wasm memory
#[wasm_bindgen]
pub fn alloc(len: usize) -> *mut u8 {
    let mut buf = Vec::with_capacity(len);
    let ptr = buf.as_mut_ptr();
    std::mem::forget(buf);
    ptr
}

// Process a string that JS wrote into Wasm memory
#[wasm_bindgen]
pub fn process(ptr: usize, len: usize) -> usize {
    let slice = unsafe { std::slice::from_raw_parts(ptr as *const u8, len) };
    let s = std::str::from_utf8(slice).unwrap();
    s.len()
}
```

JavaScript:
```javascript
const encoder = new TextEncoder();
const bytes = encoder.encode("hello");
const ptr = instance.exports.alloc(bytes.length);
new Uint8Array(instance.exports.memory.buffer, ptr, bytes.length).set(bytes);
const len = instance.exports.process(ptr, bytes.length);
```

> This is what `wasm-bindgen` does internally — you rarely need to do it manually.

## Performance tips

- Pass `&str` (not `String`) for input parameters — avoids an ownership transfer.
- Avoid passing many small strings in a loop — each crossing encodes/decodes.
- For bulk text processing, pass bytes as `Vec<u8>` / `Uint8Array` and decode once on each side.
- Use `serde` + JSON for complex structured data (lesson 24) rather than manual string formatting.
