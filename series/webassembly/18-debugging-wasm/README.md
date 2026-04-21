# 18 — Debugging Wasm in the Browser DevTools

> **Type:** How-To

## The debugging challenge

Wasm runs as binary code. Unlike JavaScript, you can't just open the file and read it. However, modern browsers have dedicated Wasm debugging support.

## Source maps and DWARF debug info

Rust can emit **DWARF** debug information into the Wasm binary, and browsers with the C/C++ DevTools extension (Chrome) can map Wasm instructions back to Rust source lines.

Enable DWARF in `Cargo.toml`:
```toml
[profile.dev]
debug = true        # include debug symbols (default for dev)
opt-level = 0       # no optimization (easier to debug)
```

For release builds with some debug info:
```toml
[profile.release]
debug = 1           # minimal debug info (line numbers only)
```

## Chrome: DWARF debugging (recommended)

1. Install **C/C++ DevTools Support (DWARF)** extension from the Chrome Web Store.
2. Build in debug mode: `wasm-pack build --dev` or `trunk serve`.
3. Open DevTools → Sources tab → you will see Rust files listed.
4. Set breakpoints directly on Rust source lines.
5. Step through code, inspect local variables.

## All browsers: disassembly view

Without the DWARF extension:
- Open DevTools → Sources.
- Find the `.wasm` file — the browser auto-disassembles it to WAT.
- You can set breakpoints on WAT instructions.
- Local variables show as `$var0`, `$var1` (not Rust variable names).

## Firefox developer tools

Firefox has built-in Wasm debugging (no extension). Open DevTools → Debugger → find the `.wasm` file. Firefox shows WAT format with Rust function names (if debug symbols are present).

## Using `console_error_panic_hook`

By default, Rust panics in Wasm produce an unhelpful error. Add this crate:

```toml
[dependencies]
console_error_panic_hook = "0.1"
```

Call it once at startup:
```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen(start)]
pub fn main() {
    console_error_panic_hook::set_once();
    // your app logic
}
```

Now panics show the full Rust backtrace in the browser console:
```
panicked at 'index out of bounds: the len is 3 but the index is 5', src/lib.rs:42:10
    at wasm-function[23]:0x1234
```

## Logging from Rust

```toml
[dependencies]
log = "0.4"
console_log = "1"
```

```rust
#[wasm_bindgen(start)]
pub fn main() {
    console_log::init_with_level(log::Level::Debug).unwrap();
    log::info!("App started");
    log::debug!("Debug value: {}", 42);
}
```

Output appears in the browser console with the correct level (info, debug, warn, error).

## Common issues

| Problem | Solution |
|---------|---------|
| No Rust source in DevTools | Install DWARF extension, use debug build |
| Panic shows no useful info | Add `console_error_panic_hook::set_once()` |
| Variables show as `i32` values | Use debug build with `debug = true` |
| Build too slow in debug mode | Use `opt-level = 1` for faster dev builds |
