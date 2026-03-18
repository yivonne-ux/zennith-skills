---
name: browser-use
description: Browser automation for GAIA agents — Chrome CDP (primary, local, signed-in) + Browser Use Cloud (fallback for anti-bot)
version: 2.0.0
agents: [scout, dreami, main, taoz]
---

# Browser Automation — GAIA Agents

## Two Modes (Priority Order)

### 1. Chrome CDP (PRIMARY) — Local Signed-In Browser
Uses your REAL Chrome browser via Chrome DevTools Protocol. Agents browse AS YOU — signed into Google, Shopify, Meta, etc.

**Config**: `openclaw.json → browser.profiles.user`
**CDP URL**: `http://127.0.0.1:9222`
**Chrome**: Must be launched with `--remote-debugging-port=9222`

```bash
# Launch Chrome with CDP (done via LaunchAgent on boot)
open -a "Google Chrome" --args --remote-debugging-port=9222
```

**Use for**: Authenticated pages, Shopify admin, Google Workspace, Meta Business, Shopee/Lazada seller, any site you're logged into.

**OpenClaw native tool**:
```
browser.navigate { url: "https://admin.shopify.com/store/7qz8cj-uu", profile: "user" }
browser.snapshot { }
browser.act { action: "click", selector: "button.primary" }
```

### 2. Browser Use Cloud (FALLBACK) — Headless Remote
Cloud-hosted browser for anti-bot pages, CAPTCHAs, and heavy scraping.

**API Key**: `openclaw.json → skills.entries.browser-use.apiKey`
**Dashboard**: https://cloud.browser-use.com

**Use for**: Competitor scraping (anti-bot), CAPTCHA pages, mass data extraction, anonymous browsing.

## Decision Matrix

| Task | Mode | Why |
|------|------|-----|
| Shopify admin | Chrome CDP | Need signed-in session |
| Google Workspace | Chrome CDP | OAuth session required |
| Meta Ads Manager | Chrome CDP | Auth required |
| Competitor website scraping | Cloud | Anti-bot protection |
| Price monitoring | Cloud | Anonymous, headless |
| URL health checks | Chrome CDP | Fast, local |
| Form filling (own sites) | Chrome CDP | Signed in |
| Screenshot for QA | Chrome CDP | Matches real user view |

## Which Agents Use This

| Agent | Use Case | Preferred Mode |
|-------|----------|----------------|
| Scout | Research, competitor scraping, market intel | Cloud (anonymous) |
| Scout | URL health checks, site monitoring | CDP (fast, local) |
| Dreami | Ad landing page analysis, visual QA | CDP (real user view) |
| Dreami | Product listings, marketplace research | Cloud (anti-bot) |
| Zenni (main) | Shopify/Meta/Google admin tasks | CDP (signed-in) |
| Taoz | Technical debugging, API testing | CDP (local) |

## Chrome CDP Launch

Chrome must be running with `--remote-debugging-port=9222`. A LaunchAgent handles this on boot:
`~/Library/LaunchAgents/com.google.chrome.cdp.plist`

Manual launch: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222 --restore-last-session`

## Troubleshooting

- **CDP not responding**: Check `curl http://127.0.0.1:9222/json/version`
- **Chrome not launched with CDP**: Quit Chrome fully, relaunch with `--remote-debugging-port=9222`
- **409 conflict**: Another tool using CDP — check `lsof -i :9222`
- **Cloud rate limit**: Browser Use has per-minute limits — use CDP for high-frequency tasks
