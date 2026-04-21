# 62 — Controlled & Uncontrolled Forms in Leptos

> **Type:** How-To + Tutorial

## Controlled vs uncontrolled

| | Controlled | Uncontrolled |
|:|:-----------|:------------|
| State lives | In a Leptos signal | In the DOM |
| Access value | Signal getter | `NodeRef` + `.value()` |
| Validate on keypress | ✅ easy | ❌ harder |
| Best for | Complex forms, validation | Simple forms, file inputs |

## Controlled form

State is driven by signals. Every keystroke updates a signal.

```rust
use leptos::*;

#[component]
fn LoginForm() -> impl IntoView {
    let (email, set_email) = create_signal(String::new());
    let (password, set_password) = create_signal(String::new());
    let (error, set_error) = create_signal(String::new());

    let on_submit = move |ev: ev::SubmitEvent| {
        ev.prevent_default();
        if email.get().is_empty() || password.get().is_empty() {
            set_error("All fields required".to_string());
            return;
        }
        if !email.get().contains('@') {
            set_error("Invalid email".to_string());
            return;
        }
        log::info!("Logging in: {}", email.get());
        // call your auth function
    };

    view! {
        <form on:submit=on_submit>
            <input
                type="email"
                placeholder="Email"
                value=email
                on:input=move |ev| set_email(event_target_value(&ev))
            />
            <input
                type="password"
                placeholder="Password"
                value=password
                on:input=move |ev| set_password(event_target_value(&ev))
            />
            <Show when=move || !error.get().is_empty()>
                <p class="error">{error}</p>
            </Show>
            <button type="submit">"Log In"</button>
        </form>
    }
}
```

## Uncontrolled form with NodeRef

Read the DOM value only when needed (e.g., on submit):

```rust
use leptos::*;
use leptos::html::Input;

#[component]
fn SearchForm() -> impl IntoView {
    let input_ref: NodeRef<Input> = create_node_ref();

    let on_submit = move |ev: ev::SubmitEvent| {
        ev.prevent_default();
        let value = input_ref
            .get()
            .expect("input element should be mounted")
            .value();
        log::info!("Searching: {}", value);
    };

    view! {
        <form on:submit=on_submit>
            <input
                type="text"
                placeholder="Search..."
                node_ref=input_ref
            />
            <button type="submit">"Search"</button>
        </form>
    }
}
```

## Select (dropdown)

```rust
let (selected, set_selected) = create_signal("option1".to_string());

view! {
    <select on:change=move |ev| set_selected(event_target_value(&ev))>
        <option value="option1" selected=move || selected.get() == "option1">"Option 1"</option>
        <option value="option2" selected=move || selected.get() == "option2">"Option 2"</option>
        <option value="option3" selected=move || selected.get() == "option3">"Option 3"</option>
    </select>
    <p>"Selected: " {selected}</p>
}
```

## Checkbox

```rust
let (accepted, set_accepted) = create_signal(false);

view! {
    <label>
        <input
            type="checkbox"
            checked=accepted
            on:change=move |ev| set_accepted(event_target_checked(&ev))
        />
        " I agree to the terms"
    </label>

    <button disabled=move || !accepted.get()>"Continue"</button>
}
```

## Radio group

```rust
let (color, set_color) = create_signal("red".to_string());

view! {
    <fieldset>
        <legend>"Choose a color"</legend>
        {["red", "green", "blue"].iter().map(|&opt| {
            let opt = opt.to_string();
            let opt_clone = opt.clone();
            view! {
                <label>
                    <input
                        type="radio"
                        name="color"
                        value=opt.clone()
                        checked=move || color.get() == opt_clone
                        on:change=move |ev| set_color(event_target_value(&ev))
                    />
                    {opt}
                </label>
            }
        }).collect_view()}
    </fieldset>
    <p>"Selected: " {color}</p>
}
```

## File input

File inputs cannot be controlled — always use a `NodeRef` with an `on:change` handler:

```rust
let file_ref: NodeRef<leptos::html::Input> = create_node_ref();

let on_file_change = move |_| {
    if let Some(input) = file_ref.get() {
        if let Some(files) = input.files() {
            if let Some(file) = files.item(0) {
                log::info!("Selected: {}", file.name());
            }
        }
    }
};

view! {
    <input type="file" node_ref=file_ref on:change=on_file_change />
}
```
