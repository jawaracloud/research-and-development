# 01 — What Is Playwright?

> **Type:** Explanation

## Why another browser automation tool?

The browser automation space already had Selenium, Cypress, and Puppeteer when Microsoft released Playwright in 2020. Playwright was built from the same team that created Puppeteer, and it addressed the core limitations of each predecessor:

| Tool | Pain point Playwright solves |
|------|------------------------------|
| Selenium | Flaky `sleep()` waits; complex WebDriver setup |
| Cypress | Chromium-only (at launch); no multi-tab support; no mobile emulation |
| Puppeteer | Chromium-only; no built-in TypeScript; no test runner |

## Core architecture

```
Your Test (TypeScript) 
     │
     │ Playwright Node.js client
     │
     ▼
WebSocket / CDP / BiDi
     │
     ├──► Chromium  (Chrome, Edge)
     ├──► Firefox
     └──► WebKit    (Safari engine)
```

Playwright communicates with browsers over the **Chrome DevTools Protocol (CDP)** for Chromium and custom protocols for Firefox and WebKit. All three implementations live in the same API surface — your tests look identical regardless of the target browser.

## Key concepts

### Auto-wait
Playwright automatically waits for elements to be:
- **Visible** — in the viewport and not hidden by CSS.
- **Stable** — not animating.
- **Enabled** — not disabled.
- **Editable** — for input actions.

This eliminates most `sleep()`/`waitFor()` boilerplate found in Selenium tests.

### Locators
A **Locator** is a lazy reference to an element. It is re-queried on each action — so if the DOM re-renders, the locator still finds the correct element without you updating any references.

```typescript
// This locator is evaluated at click time, not at definition time
const button = page.getByRole('button', { name: 'Submit' });
await button.click(); // Playwright waits for it to be ready
```

### Contexts and pages
- A **Browser** can have multiple **BrowserContexts** (like incognito windows).
- Each **BrowserContext** has its own cookies, localStorage, and cached state.
- Each **BrowserContext** can have multiple **Pages** (tabs).

This architecture makes it trivial to test multi-tab flows and isolated sessions.

## What Playwright is NOT

- **Not a performance testing tool** — use k6 or JMeter for load.
- **Not a unit testing tool** — use Vitest or Jest for pure functions.
- **Not a visual design tool** — though it can take screenshots for visual regression.

## When to reach for Playwright

Use Playwright when the behavior you want to verify **only exists in a real browser**:
- Click buttons, fill forms, navigate between pages.
- Test JavaScript-driven UIs (SPAs, React, Vue, Angular, etc.).
- Verify that error states show the right messages.
- Test cross-browser compatibility.
- Measure Core Web Vitals and render timing.
