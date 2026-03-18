---
name: scrapling
description: Unified web scraping — anti-bot bypass, JS rendering, site crawling, structured extraction. Replaces site-scraper, firecrawl-search, Browser Use Cloud. Powered by Scrapling (30K+ stars).
version: 1.0.0
agents: [scout, dreami, main, taoz]
---

# Scrapling — Unified Web Scraping for Zennith OS

## What This Replaces

This is the ONE scraping skill. It consolidates:
- **site-scraper** → `scrape.sh fetch` / `scrape.sh crawl`
- **firecrawl-search** → `scrape.sh crawl` / `scrape.sh dynamic`
- **Browser Use Cloud** → `scrape.sh stealth` (anti-bot, FREE)
- **content-scraper** (platform scraping) → `scrape.sh stealth` + `scrape.sh extract`

**Still separate** (different purposes):
- **browser-use** — Chrome CDP for AUTHENTICATED pages (Shopify admin, Google, Meta)
- **biz-scraper** — Ali Akbar strategy framework (uses this skill as engine)
- **shopsteal** — clone pipeline (uses this skill as engine)
- **site-health-auditor** — uptime/SSL monitoring (not scraping)

## Decision Matrix — Which Mode?

| Scenario | Command | Why |
|----------|---------|-----|
| Normal website, blog, docs | `fetch` | Fast HTTP, TLS spoof, no browser needed |
| Cloudflare, anti-bot, CAPTCHA | `stealth` | Bypasses Turnstile, fingerprint rotation |
| JS-heavy, SPA, React/Vue sites | `dynamic` | Full Playwright browser rendering |
| Crawl entire site (all pages) | `crawl` | Async spider, concurrent, pause/resume |
| Extract specific data fields | `extract` | CSS selector map → structured JSON |
| Authenticated pages (Shopify, Google) | Use `browser-use` skill (Chrome CDP) | Need signed-in session |

## Usage

```bash
# Basic fetch (fast, handles most sites)
bash scrape.sh fetch "https://example.com" --output json

# Extract specific elements
bash scrape.sh fetch "https://example.com" --selector "h1,h2,h3" --output json

# Anti-bot bypass (Cloudflare, etc)
bash scrape.sh stealth "https://protected-site.com" --solve-cloudflare

# JS-rendered page
bash scrape.sh dynamic "https://spa-site.com" --wait 3

# Crawl entire site (max 20 pages)
bash scrape.sh crawl "https://example.com" --max-pages 20 --output-dir /tmp/crawl

# Structured extraction
bash scrape.sh extract "https://shop.com/product" --selectors '{"name":"h1","price":".price","desc":".description"}'

# Start MCP server (for Claude/AI integration)
bash scrape.sh mcp --http --port 8000
```

## Agent Usage Guide

| Agent | Typical Use | Preferred Mode |
|-------|------------|----------------|
| Scout | Competitor research, market intel | `stealth` (anonymous, anti-bot) |
| Scout | Site crawling, data collection | `crawl` (async, concurrent) |
| Dreami | Ad landing page analysis | `dynamic` (renders JS) |
| Dreami | Product listing scraping | `extract` (structured data) |
| Zenni | Quick URL checks, lookups | `fetch` (fast, simple) |
| Taoz | Technical analysis, API discovery | `fetch` or `dynamic` |

## Output Formats

- `--output json` — structured JSON (default, best for agents)
- `--output md` — markdown (good for reports)
- `--output text` — plain text (good for piping)

## Cost

**$0** — everything runs locally. No API keys. No rate limits. No cloud fees.

## Tech Stack

- Engine: [Scrapling](https://github.com/D4Vinci/Scrapling) v0.4.2 (30K+ stars)
- Venv: `~/.openclaw/venvs/scrapling/`
- TLS fingerprint spoofing (Chrome impersonation)
- Patchright + Playwright browsers for stealth/dynamic
- Adaptive selectors that survive site redesigns
- Built-in MCP server for AI tool integration

## Script Path

`~/.openclaw/skills/scrapling/scripts/scrape.sh`
