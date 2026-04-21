# 86 — Progressive Web Apps (PWA) with Wasm

> **Type:** How-To + Tutorial

## What makes a PWA?

A Progressive Web App adds native-app-like capabilities to a web app:
1. **Installable** — users can add it to their home screen.
2. **Offline-capable** — a Service Worker caches assets.
3. **Fast** — cached assets load without network.
4. **Push notifications** — optional.

## Step 1: Web App Manifest

```json
// public/manifest.json
{
  "name": "My Leptos App",
  "short_name": "LeptosApp",
  "description": "A WebAssembly app built with Leptos",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#1e1e2e",
  "theme_color": "#cba6f7",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

`index.html`:
```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#cba6f7">
<link rel="apple-touch-icon" href="/icons/icon-192.png">
```

## Step 2: Service Worker for offline caching

```javascript
// public/sw.js
const CACHE_NAME = 'myapp-v1';
const ASSETS_TO_CACHE = [
    '/',
    '/pkg/myapp.js',
    '/pkg/myapp_bg.wasm',
    '/style/main.css',
    '/manifest.json',
];

// Install: cache all static assets
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            return cache.addAll(ASSETS_TO_CACHE);
        })
    );
    self.skipWaiting();
});

// Activate: clean up old caches
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) => {
            return Promise.all(
                keys.filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            );
        })
    );
    self.clients.claim();
});

// Fetch: serve from cache, fall back to network
self.addEventListener('fetch', (event) => {
    // Skip non-GET and API requests
    if (event.request.method !== 'GET') return;
    if (event.request.url.includes('/api/')) return;

    event.respondWith(
        caches.match(event.request).then((cached) => {
            return cached || fetch(event.request).then((response) => {
                // Cache new successful responses
                if (response.ok) {
                    const clone = response.clone();
                    caches.open(CACHE_NAME).then((cache) => {
                        cache.put(event.request, clone);
                    });
                }
                return response;
            });
        })
    );
});
```

## Step 3: Register Service Worker from Rust

```rust
use wasm_bindgen_futures::JsFuture;

#[wasm_bindgen(start)]
pub async fn start() {
    console_error_panic_hook::set_once();

    // Register service worker
    let window = web_sys::window().unwrap();
    if let Ok(sw_registration_promise) = window
        .navigator()
        .service_worker()
        .register("/sw.js")
    {
        match JsFuture::from(sw_registration_promise).await {
            Ok(_) => log::info!("Service worker registered"),
            Err(e) => log::error!("SW registration failed: {:?}", e),
        }
    }

    leptos::mount_to_body(App);
}
```

## Step 4: Install prompt

```rust
use web_sys::Event;

let (can_install, set_can_install) = create_signal(false);
let (install_prompt, set_install_prompt) = create_signal::<Option<web_sys::Event>>(None);

// Listen for beforeinstallprompt
let handler = Closure::wrap(Box::new(move |event: Event| {
    event.prevent_default(); // Prevent automatic prompt
    set_install_prompt(Some(event));
    set_can_install(true);
}) as Box<dyn FnMut(Event)>);

window.add_event_listener_with_callback("beforeinstallprompt", handler.as_ref().unchecked_ref()).unwrap();
handler.forget();

// Show install button when available
view! {
    <Show when=move || can_install.get()>
        <button on:click=move |_| {
            if let Some(prompt) = install_prompt.get() {
                // Trigger the install prompt (JS interop)
            }
        }>
            "Install App"
        </button>
    </Show>
}
```

## Offline indicator

```rust
let (is_online, set_is_online) = create_signal(
    web_sys::window().unwrap().navigator().on_line()
);

let online_handler = Closure::wrap(Box::new(move || set_is_online(true)) as Box<dyn FnMut()>);
let offline_handler = Closure::wrap(Box::new(move || set_is_online(false)) as Box<dyn FnMut()>);

window.add_event_listener_with_callback("online", online_handler.as_ref().unchecked_ref()).unwrap();
window.add_event_listener_with_callback("offline", offline_handler.as_ref().unchecked_ref()).unwrap();
online_handler.forget();
offline_handler.forget();

view! {
    <Show when=move || !is_online.get()>
        <div class="offline-banner">"You are offline — showing cached content"</div>
    </Show>
}
```
