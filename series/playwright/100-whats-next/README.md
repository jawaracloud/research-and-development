# 100 — What's Next: Your Automation Path Forward

> **Type:** Reference

## What you've built

Over 100 lessons, you now know how to:

| Area | Skills |
|------|--------|
| Fundamentals | Selectors, assertions, lifecycle, debugging |
| Components | 60+ UI component patterns with positive & negative cases |
| Advanced | iframes, shadow DOM, multi-tab, network mocking, accessibility |
| Real-world | Auth, CRUD, search, checkout, cross-browser |
| Engineering | POM, fixtures, CI/CD, visual regression, reporting |
| AI agents | Playwright MCP, Claude Code, self-healing selectors |

## Suggested next steps

### 1. Contribute to your team's test suite
Apply POM + fixtures to your real product. Start with the highest-risk user flows (login, payment, onboarding).

### 2. Add visual regression to CI
Set up `toMatchSnapshot()` with a baseline on your `main` branch. Block PRs that change UI unexpectedly.

### 3. Explore Playwright Component Testing
```bash
npx playwright test --config=playwright-ct.config.ts
```
Test React/Vue/Svelte components in isolation — like Storybook but with the full Playwright API.

### 4. Build an AI testing agent
Combine Playwright MCP + Claude Code into an autonomous agent that:
- Crawls your app
- Discovers new user flows
- Writes tests for them
- Runs and self-fixes failures
- Opens a PR with the new tests

### 5. Performance budgets
```typescript
const metrics = await page.evaluate(() => JSON.stringify(window.performance.timing));
```
Assert that LCP, FID, CLS stay within budget in your CI pipeline.

## Reference: essential Playwright CLI commands

| Command | Purpose |
|---------|---------|
| `npx playwright test` | Run all tests |
| `npx playwright test --ui` | Interactive UI mode |
| `npx playwright test --headed` | Show browsers |
| `npx playwright test --debug` | Step-by-step debugger |
| `npx playwright show-report` | Open HTML report |
| `npx playwright show-trace trace.zip` | Replay a recorded trace |
| `npx playwright codegen http://localhost:3000` | Record actions as test code |

## Community resources

- [playwright.dev](https://playwright.dev) — official docs
- [Playwright Discord](https://discord.gg/playwright) — community support
- [Playwright GitHub](https://github.com/microsoft/playwright) — issues and releases
- [Playwright MCP](https://github.com/microsoft/playwright-mcp) — AI integration
- [Testing Library](https://testing-library.com) — complementary unit testing
