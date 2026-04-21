# 51 — Why Leptos? Fine-Grained Reactivity in Rust

> **Type:** Explanation

## The Leptos philosophy

Leptos is a **full-stack, fine-grained reactive** framework for Rust. It compiles to WebAssembly for the browser and to native code for the server.

"Fine-grained" means Leptos knows *exactly* which parts of the DOM depend on which pieces of state, and updates *only* those nodes when state changes. No virtual DOM diffing required.

## The reactive graph

When you build a Leptos app, you are building a **reactive dependency graph**:

```
Signal (count) —→ derived_view (the <p> showing count)
                         │
                         ▼
                   <p>Count: {count}</p>  ← only this DOM node updates
```

When `count` changes, Leptos directly sets the text content of that `<p>` — it doesn't re-render the whole component tree.

## How Leptos compares to alternatives

| Framework | Language | Reactivity | SSR | VDOM |
|-----------|----------|-----------|-----|------|
| **Leptos** | Rust | Fine-grained signals | ✅ | ❌ (no VDOM) |
| Yew | Rust | Component state (like React) | Partial | ✅ |
| Dioxus | Rust | Virtual DOM | ✅ | ✅ |
| Perseus | Rust | Thin wrapper over Sycamore | ✅ | ❌ |
| SolidJS | JavaScript | Fine-grained signals | ✅ | ❌ |
| React | JavaScript | Component re-renders + VDOM | ✅ | ✅ |

Leptos is **closest to SolidJS** in its reactivity model — if you've used Solid, Leptos will feel immediately familiar.

## Why not Yew?

Yew was the first major Rust Wasm framework and uses a React-like component model with a virtual DOM. It works well, but:
- VDOM diffing has overhead Rust doesn't need.
- Component re-renders are less granular.
- Leptos has overtaken Yew in community momentum and features (as of 2024).

## Why Leptos wins for this series

1. **Performance** — Benchmarks consistently show Leptos among the fastest frameworks of any language.
2. **Full-stack** — one framework for CSR (Trunk), SSR (Actix/Axum), and streaming.
3. **Sound** — the type system prevents many common bugs (invalid resource access, etc.).
4. **Active community** — Leptos has the most active Rust web framework community.
5. **Production ready** — as of 0.7, Leptos is used in production by multiple companies.

## The mental shift from Part 1

In Part 1 (raw Wasm):
- You told the DOM to update manually after every state change.
- You tracked dependencies yourself.
- You wrote a lot of boilerplate.

In Leptos:
- You declare *what* the UI should look like given some signals.
- The reactive system tracks dependencies automatically.
- Boilerplate is drastically reduced.

> Think of it as the difference between writing SQL imperatively ("open a cursor, fetch row 1, fetch row 2...") vs. declaratively ("give me all users where active = true").

## When NOT to use Leptos

- You need to publish a standalone Wasm *library* (not an app) → use `wasm-bindgen` directly.
- You're targeting WASI / server-only → use regular Rust.
- Team is more comfortable with Yew's React mental model.
