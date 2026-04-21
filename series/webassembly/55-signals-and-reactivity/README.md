# 55 — Signals: The Core of Leptos Reactivity

> **Type:** Explanation + Tutorial

## What is a signal?

A **signal** is a reactive container for a value. It has two halves:
- A **getter** (`ReadSignal<T>`) — read the current value and register as a dependency.
- A **setter** (`WriteSignal<T>`) — write a new value and notify all dependents.

```rust
use leptos::*;

let (count, set_count) = create_signal(0);
//   ^^^            ^^^
// ReadSignal<i32>   WriteSignal<i32>
```

## Reading a signal

```rust
// Inside a reactive context (e.g., inside view! or create_effect):
let value = count.get();   // returns i32, registers dependency

// Outside a reactive context:
let value = count.get_untracked();  // returns i32, does NOT register dependency
```

## Writing a signal

```rust
set_count.set(42);                    // replace value
set_count.update(|n| *n += 1);        // mutate in place
set_count.update_returning(|n| { *n += 1; *n }); // mutate and return new value
```

## Signals in the view

```rust
#[component]
fn Counter() -> impl IntoView {
    let (count, set_count) = create_signal(0);

    view! {
        <p>{count}</p>
        // When count changes, only this <p>'s text node updates — nothing else.

        <button on:click=move |_| set_count.update(|n| *n += 1)>
            "+1"
        </button>
        <button on:click=move |_| set_count.update(|n| *n -= 1)>
            "-1"
        </button>
    }
}
```

## Signal types

| Type | Description |
|------|-------------|
| `create_signal(val)` | Basic read/write signal |
| `create_rw_signal(val)` | Combined `RwSignal<T>` (single handle for read+write) |
| `create_memo(expr)` | Derived signal, caches value (lesson 56) |
| `create_resource(source, fetcher)` | Async data signal (lesson 67) |

## RwSignal (when you want one handle)

```rust
let count = create_rw_signal(0);

// Read
let val = count.get();

// Write
count.set(10);
count.update(|n| *n += 1);

// Split if needed
let (read, write) = count.split();
```

## Moving signals into closures

Signals implement `Copy`, so you can move them into closures freely without `clone()`:

```rust
let (count, set_count) = create_signal(0);

// Both closures own a copy of the signal handles
let increment = move |_| set_count.update(|n| *n += 1);
let decrement = move |_| set_count.update(|n| *n -= 1);

let display = move || count.get().to_string();
```

This is much cleaner than `Rc<RefCell<>>` from Part 1.

## How reactivity tracking works

When `count.get()` is called inside a **reactive scope** (inside `view!`, `create_memo`, `create_effect`), Leptos records: *"this scope depends on `count`"*.

When `set_count.set()` is called:
1. Leptos looks up all scopes that depend on `count`.
2. It schedules them to re-run.
3. They re-run synchronously (in the same microtask).
4. Only DOM nodes that actually changed are updated.

This is the **reactive graph** — it's why Leptos doesn't need a virtual DOM.

## Signals vs thread_local! RefCell (Part 1 comparison)

| | `thread_local! + RefCell` | Signal |
|:|:--------------------------|:-------|
| Read | `STATE.with(\|s\| s.borrow().count)` | `count.get()` |
| Write | `STATE.with(\|s\| s.borrow_mut().count += 1)` | `set_count.update(\|n\| *n += 1)` |
| Auto re-render | ❌ manual | ✅ automatic |
| Dependency tracking | ❌ none | ✅ automatic |
