# 71 — Server-Side Rendering: How it Works

> **Type:** Explanation

## What is SSR?

**Server-Side Rendering (SSR)** means the HTML is generated on the server and sent to the browser, rather than the browser generating HTML from JavaScript/Wasm.

With SSR:
1. Browser requests `/`.
2. Server runs Rust code (Leptos app compiled to native, not Wasm).
3. Server sends complete HTML with content already in it.
4. Browser shows content *immediately* — no blank page while JS loads.
5. (Optional) Wasm loads and "hydrates" the page, attaching event listeners.

## Three rendering modes in Leptos

| Mode | HTML on server | Wasm in browser | Best for |
|------|---------------|-----------------|---------|
| **CSR** (Client-Side Rendering) | No — empty shell | Yes — renders everything | Dashboards, SPAs behind auth |
| **SSR** (Server-Side Rendering) | Yes — full HTML | No — stays static | SEO pages, initial load speed |
| **SSR + Hydration** | Yes — full HTML | Yes — attaches interactivity | Best of both worlds |

## The hydration process

```
Server:   Render Rust → HTML with content
                ↓
Browser:  Show HTML immediately (fast paint)
                ↓
Browser:  Download & execute Wasm
                ↓
Browser:  Wasm finds existing DOM nodes (no re-render)
          Attaches event listeners
          Makes page interactive
```

Hydration **reuses** the server-rendered DOM — it doesn't replace it. This is why the initial HTML must exactly match what Wasm would render. A mismatch is called a **hydration mismatch** (logged as a warning).

## Why use SSR?

1. **First Contentful Paint (FCP)** — content appears before Wasm downloads.
2. **SEO** — search crawlers see full HTML content.
3. **Accessibility** — content is readable without JS.
4. **Progressive enhancement** — forms work even without JS (via ActionForm).
5. **Social sharing** — Open Graph meta tags are server-rendered.

## When to skip SSR

- App is behind authentication (no SEO benefit).
- App is a desktop-class tool (users expect full load before starting).
- Team is small and SSR complexity isn't worth it yet.

## The Leptos SSR architecture

```
            ┌─────────────────────────────┐
            │         Leptos App          │
            │   (shared Rust code)        │
            └─────┬───────────────┬───────┘
                  │               │
                  ▼               ▼
        ┌─────────────┐  ┌─────────────────┐
        │  Server     │  │   Browser        │
        │  (native)   │  │   (Wasm)         │
        │  Axum/Actix │  │   leptos csr    │
        └─────────────┘  └─────────────────┘
```

The same component code compiles to both targets — conditional compilation (`#[cfg(feature = "ssr")]`) separates server-only from client-only code.

## Key terms

| Term | Meaning |
|------|---------|
| SSR | HTML rendered on server |
| Hydration | Wasm attaches to server-rendered HTML |
| Island architecture | Most HTML is static, only "islands" are interactive |
| Streaming SSR | Server sends HTML in chunks as async operations complete |
| Server components | Components that only run on the server (Leptos 0.7+) |

## Streaming SSR (Leptos's super power)

Instead of waiting for all data before sending any HTML, Leptos can stream:

```
[Send immediately]  <html><head>...</head><body>
                    <div class="header">...</div>
                    <div class="skeleton" id="user-1"></div>
[Data arrives]      <script>replace("user-1", "<div>Alice</div>")</script>
```

The user sees the page layout instantly, then content fills in as it loads — without any client-side JS framework to coordinate the update.
