# 50 — Retrospective: What a Framework Solves for You

> **Type:** Explanation

## What we built without a framework

In Part 1 (lessons 11–49), you built real applications using only Rust, `wasm-bindgen`, `web-sys`, and raw DOM manipulation. You now know:

- The Wasm binary format and execution model.
- How to use `wasm-pack` and Trunk.
- How to cross the Rust–JS boundary with strings, structs, and closures.
- How to manipulate the DOM, handle events, draw on a canvas, make HTTP requests.
- How to manage state with `Rc<RefCell<T>>` and `thread_local!`.
- The component pattern and a minimal virtual DOM.

## What was painful

Be honest with yourself about what you struggled with:

| Pain point | How many times you fought it |
|-----------|------------------------------|
| `Closure::forget()` memory management | Every event listener |
| Full re-renders losing event bindings | Every state update |
| Verbosity of `web-sys` DOM calls | Every function |
| Keeping UI in sync with state | Every project |
| No declarative templates | Every component |

## The core problem every framework solves

**The core problem**: *state changes over time, but the DOM cannot update itself*.

Every framework provides:
1. **A reactive primitive** — something that holds state and *notifies* the UI when it changes.
2. **A template system** — a way to describe UI structure declaratively, tied to state.
3. **Efficient DOM updating** — not redrawing everything on every change.

## How Leptos solves each pain point

| Raw Wasm problem | Leptos solution |
|-----------------|----------------|
| `Closure::forget()` everywhere | Closures are managed by the reactive system |
| Full re-renders lose event bindings | DOM nodes that don't change are never touched |
| Verbose DOM calls | `view! { <div>...</div> }` macro |
| State/UI sync | Signals automatically re-run only dependent views |
| No templates | `view!` macro with Rust control flow |

## What you uniquely understand now

Developers who jump straight into Leptos often hit confusing moments:
- "Why can't I call `.get()` on a signal outside a reactive context?" → Because it needs to know *who* is tracking it.
- "Why doesn't my component re-render when I mutate this vec?" → Because mutation doesn't notify signals.
- "When does `create_effect` fire?" → After each reactive update, synchronously.

You now have the mental model to answer all of these questions — because you've implemented the raw versions yourself.

## On to Leptos

Part 2 of this series starts at lesson 51. You will move from understanding *why* to experiencing *how much faster* development becomes with the right abstractions.

> "Every abstraction is a bet that it will hide more complexity than it introduces."
> Leptos wins that bet for Rust web development.

## One rule for Part 2

When something in Leptos "seems like magic," stop and ask: *"How would I have done this in Part 1?"* The answer always demystifies it.
