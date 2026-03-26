---
name: unified-browse
version: 1.0.0
description: |
  Unified browser for Zennith OS — one script, two modes. Headless by default (no windows,
  no blocking, always works). Auth mode (--auth) for logged-in pages via Chrome CDP.
  Replaces: browser-automation, browser-use, cli-browser, auth-browser nav commands.
  Use when you need to browse, screenshot, scrape, interact with web pages, QA test,
  or automate browser tasks. Use "browse.sh" for everything browser-related.
allowed-tools:
  - Bash
  - Read
---

# Unified Browse — Zennith OS Browser

## Setup

The browse script is at:
```
/Users/jennwoeiloh/.openclaw/skills/agent-reach/scripts/browse.sh
```

Alias for convenience:
```bash
B="/Users/jennwoeiloh/.openclaw/skills/agent-reach/scripts/browse.sh"
```

## Quick Reference

### Headless Mode (default — no windows, no Chrome needed)
```bash
$B nav "https://example.com"              # navigate + extract text
$B screenshot "https://example.com"        # take screenshot (PNG)
$B pdf "https://example.com"               # save as PDF
```

### Auth Mode (--auth flag — for logged-in pages like Shopify, Meta, Gmail)
```bash
$B nav "https://admin.shopify.com" --auth  # navigate with auth cookies
$B text                                     # get current page text
$B screenshot --auth                        # screenshot current page
$B click "button.submit"                   # click element
$B fill "input[name=email]" "test@test.com" # fill input
$B eval "document.title"                   # run JavaScript
$B wait ".loaded" 5000                      # wait for element
```

### System
```bash
$B check                                   # show CDP + Playwright status
$B test                                    # run self-test (6 tests)
```

## Decision Tree

| Need | Command | Why |
|------|---------|-----|
| Read a public page | `$B nav <url>` | Headless, fast, no windows |
| Screenshot for QA | `$B screenshot <url>` | Headless, saves PNG |
| Logged-in admin page | `$B nav <url> --auth` | Uses Chrome CDP session |
| Click/fill on auth page | `$B click/fill ...` | CDP interactive |
| Anti-bot / Cloudflare | Use `scrapling-fetch.sh` instead | Different engine |
| YouTube metadata | Use `youtube-info.sh` instead | yt-dlp is better |

## Rules

1. **ALWAYS use headless mode** unless the page requires authentication
2. **NEVER open visible Chrome windows** — use `--auth` flag which connects to existing CDP
3. If CDP is not running, tell user to start it: `auth-browser/scripts/browser.sh start`
4. Screenshots go to `/tmp/` by default
5. For complex multi-step browser automation, use multiple `$B` calls sequentially
6. For web scraping at scale, use `scrapling-fetch.sh` or `web-read.sh` instead

## Troubleshooting

- **"CDP not running"**: Chrome needs to be started with `--remote-debugging-port=9222`
- **Playwright timeout**: Page may be slow. Increase timeout or check URL
- **No text extracted**: Some SPAs need longer wait. Use `$B eval "document.body.innerText"`
