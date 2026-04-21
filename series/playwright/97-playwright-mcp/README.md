# 97 — AI Agent: Playwright MCP Server Setup

> **Type:** Tutorial

## What is Playwright MCP?

[Playwright MCP](https://github.com/microsoft/playwright-mcp) is a **Model Context Protocol server** that exposes Playwright browser actions as tools consumable by any MCP-compatible AI agent (Claude, GPT-4o, Gemini, etc.).

The AI agent can:
- `browser_navigate` — go to a URL
- `browser_click` — click an element by label/selector
- `browser_fill` — type into an input
- `browser_screenshot` — take a screenshot and return it to the agent
- `browser_snapshot` — get the accessibility tree (structured DOM)

This enables **AI-driven exploratory testing**: ask Claude to "test the login form and report any issues" — it will navigate, interact, observe, and write a report.

## Setup

### 1. Install the MCP server

```bash
npm install -g @playwright/mcp
```

### 2. Configure in Claude Desktop / any MCP client

Add to `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Or run directly:

```bash
npx @playwright/mcp@latest --port 8931
```

### 3. Start the test app

```bash
npm run serve   # http://localhost:3000
```

### 4. Verify connectivity

Connect your MCP client. The following tools should appear:
- `browser_navigate`
- `browser_click`
- `browser_fill`
- `browser_snapshot`
- `browser_screenshot`

## Using Playwright MCP with Claude

Prompt example:
> "Navigate to http://localhost:3000/pages/auth.html. Try to log in with email 'wrong@test.com' and password 'wrong'. Take a screenshot and describe the error message shown."

Claude will:
1. Call `browser_navigate`
2. Call `browser_fill` twice
3. Call `browser_click` on the submit button
4. Call `browser_screenshot`
5. Return the screenshot + description to you

## ✅ Positive test cases

| # | Scenario | Expected result |
|---|----------|-----------------|
| 1 | Agent navigates to page | URL matches, snapshot returns DOM |
| 2 | Agent fills and submits login | Auth result (success or error) observed |
| 3 | Agent takes screenshot after action | Image returned with correct state captured |

## ❌ Negative test cases

| # | Scenario | Expected result |
|---|----------|-----------------|
| 1 | Navigate to non-existent page | Agent receives 404, reports the error |
| 2 | Click a non-existent selector | Tool returns error; agent handles gracefully |
| 3 | MCP server not running | Client reports connection refused |

## Key assertions (for wrapping in automated tests)

```typescript
// You can assert the MCP server is running programmatically:
import { test, expect } from '@playwright/test';

test('playwright-mcp server responds', async ({ request }) => {
  const res = await request.get('http://localhost:8931/health');
  expect(res.status()).toBe(200);
});
```
