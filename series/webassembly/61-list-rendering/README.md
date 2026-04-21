# 61 — Rendering Lists with <For>

> **Type:** How-To + Explanation

## Why not just use .map()?

You can render lists with `.map()` + `.collect_view()`, but this re-creates all DOM elements whenever the list changes:

```rust
// ❌ Less efficient: re-renders entire list on any change
{move || items.get().iter().map(|item| view! {
    <li>{item.name.clone()}</li>
}).collect_view()}
```

The `<For>` component is the **keyed** alternative — it tracks items by key, creates new DOM nodes only for new items, and removes DOM nodes only for deleted items. Existing items that didn't change are never touched.

## The <For> component

```rust
use leptos::*;

#[derive(Clone, PartialEq)]
struct Item { id: u32, name: String }

let (items, set_items) = create_signal(vec![
    Item { id: 1, name: "First".into() },
    Item { id: 2, name: "Second".into() },
]);

view! {
    <ul>
        <For
            each=move || items.get()         // signal returning Vec
            key=|item| item.id              // unique key per item
            children=|item| view! {         // render each item
                <li>{item.name}</li>
            }
        />
    </ul>
}
```

## Keys and identity

The `key` function must return a value that:
- **Uniquely identifies** each item in the list.
- Is **stable** — the same item always gets the same key.
- Is **cheap to compute and compare** — usually an `id: u32`.

```rust
// ✅ Good key: database ID
key=|item| item.id

// ❌ Bad key: index (items can shift positions)
key=|(i, _)| i

// ❌ Bad key: name (names can change/duplicate)
key=|item| item.name.clone()
```

React developers: Leptos `<For>` is equivalent to React's `key` prop on list items.

## Adding, removing, and updating items

```rust
let next_id = create_rw_signal(3u32);

let add_item = move || {
    let id = next_id.get();
    next_id.update(|n| *n += 1);
    set_items.update(|items| {
        items.push(Item { id, name: format!("Item {}", id) });
    });
};

let remove_item = move |id: u32| {
    set_items.update(|items| items.retain(|item| item.id != id));
};

view! {
    <button on:click=move |_| add_item()>"Add item"</button>
    <ul>
        <For
            each=move || items.get()
            key=|item| item.id
            children=move |item| {
                let id = item.id;
                view! {
                    <li>
                        {item.name}
                        <button on:click=move |_| remove_item(id)>"×"</button>
                    </li>
                }
            }
        />
    </ul>
}
```

## Nested signals inside list items

For each list item that needs its own reactive state:

```rust
#[derive(Clone)]
struct Todo { id: u32, text: String, done: RwSignal<bool> }

let todos = create_rw_signal(vec![
    Todo { id: 1, text: "Buy milk".into(), done: create_rw_signal(false) },
]);

view! {
    <For
        each=move || todos.get()
        key=|todo| todo.id
        children=|todo| {
            let done = todo.done;
            view! {
                <li class:done=done>
                    <input
                        type="checkbox"
                        checked=done
                        on:change=move |_| done.update(|d| *d = !*d)
                    />
                    {todo.text}
                </li>
            }
        }
    />
}
```

Because each `done` is its own signal, toggling one item only updates that item's DOM — nothing else re-renders.

## Performance tip

For very large lists (1000+ items), consider virtualization — only render items in the visible viewport. The `leptos-virtual-scroller` crate or a custom solution using `resize_observer` can help.
