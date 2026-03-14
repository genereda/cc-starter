---
name: browser-testing
description: >
  Browser-based testing with intelligent tool selection across chrome-cdp, Chrome extension, Playwright, and PinchTab.
  Use when testing UIs, verifying visual output, running end-to-end flows, checking network/console,
  or performing accessibility audits in a browser.
  Triggers on: "test in browser", "browser test", "visual test", "check the UI", "screenshot test",
  "end-to-end test", "verify the page", "check accessibility".
---

# Browser Testing Skill

## Tool Selection

Pick the right tool based on what you're testing:

| Scenario                                            | Tool                                                                        | Why                                                  |
| --------------------------------------------------- | --------------------------------------------------------------------------- | ---------------------------------------------------- |
| **Quick live-tab inspection** — snap existing tab   | chrome-cdp (`snap`, `shot`)                                                 | No extension needed, direct CDP, handles 100+ tabs   |
| **JS eval / debug in live session**                 | chrome-cdp (`eval`)                                                         | Direct CDP WebSocket, no extension overhead          |
| **Accessibility tree analysis**                     | chrome-cdp (`snap`) or PinchTab (`snap -i -c`)                              | Compact semantic output, lightweight                 |
| **Visual verification** — does the page look right? | Chrome extension                                                            | Real browser, sees what user sees, real auth/cookies |
| **Interactive flows** — click, fill, submit         | Chrome extension or chrome-cdp (`click`, `type`)                            | Real browser state, no setup needed                  |
| **Headless/automated suites**                       | Playwright                                                                  | No UI needed, faster, scriptable                     |
| **Token-efficient page reading**                    | PinchTab                                                                    | 800 tokens/page (5-13x cheaper than screenshots)     |
| **Multi-page crawl / parallel testing**             | PinchTab                                                                    | Multi-instance, HTTP API, lightweight                |
| **Network request inspection**                      | chrome-cdp (`net`) or Chrome (`read_network_requests`) or Playwright        |                                                      |
| **Console error checking**                          | Chrome (`read_console_messages`) or Playwright (`browser_console_messages`) |                                                      |
| **Mobile viewport testing**                         | Playwright (`browser_resize`)                                               | Scriptable exact dimensions                          |
| **CI/CD integration**                               | Playwright                                                                  | Headless, deterministic, no browser dependency       |

**Default choice:** chrome-cdp for quick inspection of live tabs (lightest, no extension). Chrome extension for visual/coordinate-based interaction. Playwright for headless or scripted. PinchTab for reading content or parallel tasks.

## Tool Reference

### chrome-cdp (CLI — `~/.claude/skills/chrome-cdp/scripts/cdp.mjs`)

Direct CDP via WebSocket. No extension, no Puppeteer. Requires Chrome remote debugging enabled (`chrome://inspect/#remote-debugging`) and Node.js 22+.

```bash
cdp.mjs list                        # List open tabs (shows targetId prefixes)
cdp.mjs shot   <target> [file]      # Screenshot viewport → /tmp/screenshot.png
cdp.mjs snap   <target>             # Accessibility tree (compact, semantic)
cdp.mjs html   <target> [selector]  # Full HTML or scoped to CSS selector
cdp.mjs eval   <target> "expr"      # Evaluate JS in page context
cdp.mjs nav    <target> <url>       # Navigate and wait for load
cdp.mjs net    <target>             # Network resource timing
cdp.mjs click  <target> "selector"  # Click element by CSS selector
cdp.mjs clickxy <target> <x> <y>    # Click at CSS pixel coordinates
cdp.mjs type   <target> "text"      # Type at focused element (works in cross-origin iframes)
cdp.mjs stop   [target]             # Stop daemon(s)
```

`<target>` is a unique prefix of the targetId from `list`. Daemons auto-exit after 20 min idle.

### Chrome Extension (`mcp__claude-in-chrome__*`)

```
tabs_context_mcp     → Get current browser tabs (ALWAYS call first)
tabs_create_mcp      → Open new tab
navigate             → Go to URL
read_page            → Get page content
get_page_text        → Get text-only content
find                 → Search for text on page
computer             → Click, scroll, interact at coordinates
form_input           → Fill form fields
read_console_messages → Read console output (use pattern param to filter)
read_network_requests → Inspect network traffic
javascript_tool      → Execute JS in page context
```

### Playwright (`mcp__plugin_playwright_playwright__*`)

```
browser_navigate     → Go to URL
browser_snapshot     → Get accessibility tree snapshot
browser_take_screenshot → Capture screenshot
browser_click        → Click element by ref or text
browser_fill_form    → Fill form fields
browser_type         → Type text
browser_press_key    → Keyboard input
browser_evaluate     → Run JS in page
browser_console_messages → Read console
browser_network_requests → Inspect network
browser_resize       → Set viewport size
browser_tabs         → List/switch tabs
```

### PinchTab (CLI or HTTP API)

```bash
pinchtab                    # Start server (port 9867)
pinchtab nav <url>          # Navigate
pinchtab snap -i -c         # Get page snapshot (interactive + clickable refs)
pinchtab click <ref>        # Click element by ref (e.g., e5)
pinchtab type <ref> "text"  # Type into element
pinchtab text               # Get page text (token-efficient)
pinchtab eval "js code"     # Execute JavaScript
pinchtab screenshot         # Capture screenshot
pinchtab tabs               # List tabs
```

HTTP API (for programmatic use):

```bash
curl http://localhost:9867/api/v1/navigate -d '{"url":"https://example.com"}'
curl http://localhost:9867/api/v1/snapshot
curl http://localhost:9867/api/v1/click -d '{"ref":"e5"}'
```

## Standard Testing Workflow

### 1. Pre-flight

- Ensure local server is running (check `package.json` scripts, `Procfile`, or start manually)
- Choose tool based on selection matrix above
- If using Chrome: call `tabs_context_mcp` first to see open tabs

### 2. Navigate & Baseline

- Open the target URL
- Capture initial state (screenshot or snapshot)
- Check console for errors (`pattern` param to filter noise)

### 3. Test Interactions

- Click through the user flow
- Fill forms with test data
- Verify state changes after each action
- Capture screenshots at key checkpoints

### 4. Verify

- Compare final state against expectations
- Check network requests for expected API calls
- Verify no console errors
- Test error states (invalid input, network failure)

### 5. Report

- Summarize pass/fail with evidence
- Include screenshots for visual verification
- Note any console errors or failed network requests

## Accessibility Testing Checklist

Run these checks on every UI test:

- [ ] **Keyboard navigation:** Tab through all interactive elements. Focus order is logical.
- [ ] **Focus visibility:** Focus ring is visible on all interactive elements.
- [ ] **Screen reader landmarks:** Page has `<main>`, `<nav>`, `<header>`, `<footer>` as appropriate.
- [ ] **ARIA labels:** All interactive elements have accessible names.
- [ ] **Color contrast:** Text meets WCAG AA (4.5:1 normal text, 3:1 large text).
- [ ] **Form labels:** Every input has an associated `<label>`.
- [ ] **Alt text:** Images have descriptive alt text (or `alt=""` for decorative).
- [ ] **Error messages:** Form errors are announced and associated with fields.

Use chrome-cdp `snap` for quick accessibility tree dumps (lightest option), or PinchTab `snap -i -c` for structured element refs.

## Common Patterns

### Screenshot Comparison

```
1. Navigate to page
2. Take screenshot → save as baseline
3. Make change (or interact)
4. Take screenshot → save as result
5. Compare visually or report differences
```

### Network Verification

```
1. Start monitoring network requests
2. Perform action (form submit, page load, etc.)
3. Read network requests
4. Verify expected endpoints were called with correct payloads
5. Check response status codes
```

### Mobile Responsive Testing

```
1. Use Playwright browser_resize to set viewport:
   - Mobile: 375x812 (iPhone)
   - Tablet: 768x1024 (iPad)
   - Desktop: 1440x900
2. Take screenshot at each breakpoint
3. Verify layout adapts correctly
```
