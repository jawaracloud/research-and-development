# 85 — Accessibility (a11y) in Wasm Apps

> **Type:** How-To + Reference

## Why accessibility matters for Wasm apps

SPAs and Wasm apps often break accessibility by:
- Not announcing route changes to screen readers.
- Missing ARIA attributes on dynamic components.
- Focus not being managed after modal opens/closes.
- Custom widgets not following ARIA patterns.

## ARIA in view!

```rust
view! {
    // Button with aria-label
    <button aria-label="Close dialog" on:click=on_close>"×"</button>

    // Status message for screen reader announcements
    <div role="status" aria-live="polite">
        {move || if saved.get() { "Saved successfully" } else { "" }}
    </div>

    // Form field with label association
    <label for="email">"Email"</label>
    <input id="email" type="email" aria-required="true"
           aria-describedby="email-error" />
    <span id="email-error" role="alert">
        {move || email_error.get()}
    </span>

    // Loading state
    <button disabled=is_loading aria-busy=is_loading>
        {move || if is_loading.get() { "Saving..." } else { "Save" }}
    </button>
}
```

## Focus management

When a modal opens, focus should move to it. When it closes, focus should return to the trigger:

```rust
use web_sys::HtmlElement;
use leptos::NodeRef;

#[component]
fn Modal(
    is_open: ReadSignal<bool>,
    on_close: Callback<()>,
    trigger_ref: NodeRef<leptos::html::Button>,
    children: Children,
) -> impl IntoView {
    let dialog_ref: NodeRef<leptos::html::Div> = create_node_ref();

    // Move focus to dialog when it opens
    create_effect(move |_| {
        if is_open.get() {
            if let Some(el) = dialog_ref.get() {
                el.dyn_into::<HtmlElement>().unwrap().focus().unwrap();
            }
        } else {
            // Return focus to trigger when closing
            if let Some(el) = trigger_ref.get() {
                el.focus().unwrap();
            }
        }
    });

    view! {
        <Show when=move || is_open.get()>
            <div
                role="dialog"
                aria-modal="true"
                tabindex="-1"
                node_ref=dialog_ref
                on:keydown=move |ev| {
                    if ev.key() == "Escape" {
                        on_close.call(());
                    }
                }
            >
                {children()}
                <button on:click=move |_| on_close.call(())>"Close"</button>
            </div>
        </Show>
    }
}
```

## Announcing route changes

Screen readers don't automatically announce SPA navigation. Use a visually-hidden live region:

```rust
#[component]
fn RouteAnnouncer() -> impl IntoView {
    let location = use_location();
    let (announcement, set_announcement) = create_signal(String::new());

    create_effect(move |_| {
        let path = location.pathname.get();
        let title = web_sys::window().unwrap().document().unwrap()
            .title();
        set_announcement(format!("Navigated to {}", title));
    });

    view! {
        <div
            role="status"
            aria-live="polite"
            aria-atomic="true"
            style="position: absolute; left: -9999px; width: 1px; height: 1px; overflow: hidden;"
        >
            {announcement}
        </div>
    }
}
```

## Keyboard navigation for custom widgets

For a custom dropdown:

```rust
view! {
    <div
        role="combobox"
        aria-expanded=is_open
        aria-haspopup="listbox"
        aria-owns="dropdown-list"
    >
        <input aria-autocomplete="list" aria-controls="dropdown-list" />
        <Show when=move || is_open.get()>
            <ul id="dropdown-list" role="listbox">
                {items.iter().enumerate().map(|(i, item)| view! {
                    <li
                        role="option"
                        aria-selected=move || selected_index.get() == i
                        id=format!("option-{}", i)
                    >
                        {item.label.clone()}
                    </li>
                }).collect_view()}
            </ul>
        </Show>
    </div>
}
```

## Accessibility testing tools

- **axe-core** (browser extension + CI): `npm install -D axe-core`
- **Lighthouse** (Chrome DevTools): automated a11y audits.
- **NVDA** (Windows) / **VoiceOver** (macOS): actual screen reader testing.
- **Playwright + axe**: `await expect(page).toHaveNoAccessibilityViolations()`

## WCAG 2.1 quick checklist

- [ ] All images have `alt` text.
- [ ] All form inputs have `<label>` or `aria-label`.
- [ ] Color contrast ≥ 4.5:1 (normal text), 3:1 (large text).
- [ ] Keyboard navigable — no mouse-only interactions.
- [ ] Focus visible — never `outline: none` without alternative.
- [ ] Dynamic content changes announced with `aria-live`.
- [ ] No content flashes more than 3 times/second.
