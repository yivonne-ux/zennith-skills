# Agent-Reach — Unified Web Intelligence for GAIA OS Agents

## Purpose
Give ALL OpenClaw agents eyes on the internet. Multiple tools for different jobs — pick the right one.

## Decision Matrix — Which Tool When

| Need | Tool | Cost | Best For |
|------|------|------|----------|
| Quick page read | **web-read.sh** (Jina Reader) | Free | Blog posts, articles, docs, any public page |
| YouTube intel | **youtube-info.sh** (yt-dlp) | Free | Video metadata, subtitles, channel info |
| Anti-bot sites | **scrapling-fetch.sh** (Scrapling) | Free | Cloudflare-protected, dynamic JS sites |
| Browser automation | **pinchtab-browse.sh** (PinchTab) | Free | Login flows, form fills, multi-step scraping, screenshots |
| Complex browser tasks | **browser-use** (cloud API) | Paid | Heavy scraping, anti-bot pages needing real browser |
| General web crawl | **firecrawl-search** skill | $16/mo | Crawl entire sites, extract structured content |
| Platform-specific | **content-scraper** skill | Varies | YouTube API, Pinterest API, Google Trends |
| Web search | **web-search-pro** skill | Free | Multi-engine search (Tavily, Exa, Serper) |

### Rule of Thumb
1. **Start with web-read.sh** (fastest, free, works 80% of the time)
2. **If blocked** → try scrapling-fetch.sh (anti-bot bypass)
3. **If needs interaction** (click, fill, login) → pinchtab-browse.sh
4. **If needs screenshots or complex flows** → pinchtab-browse.sh or browser-use
5. **If crawling entire site** → scrapling-fetch.sh spider or firecrawl

---

## Tools

### web-read.sh — Quick Page Read (Jina Reader)
```bash
bash ~/.openclaw/skills/agent-reach/scripts/web-read.sh "https://example.com"
bash ~/.openclaw/skills/agent-reach/scripts/web-read.sh "https://example.com" --summary
```
Free, no auth. Best for: articles, docs, product pages.

### youtube-info.sh — YouTube Video Intel
```bash
bash ~/.openclaw/skills/agent-reach/scripts/youtube-info.sh "https://youtu.be/VIDEO_ID"
bash ~/.openclaw/skills/agent-reach/scripts/youtube-info.sh "https://youtu.be/VIDEO_ID" --subtitles
```
Uses yt-dlp. Extracts: title, channel, duration, views, description, subtitles.

### scrapling-fetch.sh — Anti-Bot Scraping (Scrapling)
```bash
bash ~/.openclaw/skills/agent-reach/scripts/scrapling-fetch.sh fetch "https://example.com"
bash ~/.openclaw/skills/agent-reach/scripts/scrapling-fetch.sh css "https://example.com" ".product .title::text"
bash ~/.openclaw/skills/agent-reach/scripts/scrapling-fetch.sh stealth "https://cloudflare-site.com"
bash ~/.openclaw/skills/agent-reach/scripts/scrapling-fetch.sh spider "https://example.com" 10
```
Python lib with Cloudflare Turnstile bypass, adaptive element tracking, TLS fingerprint impersonation.
Commands: `fetch` (basic), `css` (selector extract), `stealth` (anti-bot), `spider` (crawl N pages).

### pinchtab-browse.sh — AI Browser Control (PinchTab)
```bash
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh navigate "https://example.com"
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh text          # extract page text
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh snapshot      # accessibility tree
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh click e5      # click element ref
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh fill e3 "query"  # fill input
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh screenshot    # capture screenshot
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh scrape "https://url"  # nav + extract
bash ~/.openclaw/skills/agent-reach/scripts/pinchtab-browse.sh status        # check server
```
12MB Go binary, HTTP API on port 9867, accessibility tree (90% less tokens), stealth mode, human-like clicks.
Auto-starts PinchTab server if not running.

### Direct Access (no script needed)
```bash
# Jina Reader
curl -s "https://r.jina.ai/https://any-website.com"

# yt-dlp
yt-dlp --dump-json "https://youtu.be/VIDEO_ID"

# PinchTab CLI
pinchtab nav https://example.com
pinchtab text
pinchtab snap -i
```

---

## Agent Assignment

| Agent | Primary Use | Preferred Tools |
|-------|-------------|-----------------|
| **Artemis** | Research, competitor intel, trend scraping | web-read, scrapling, pinchtab, content-scraper |
| **Hermes** | Ad research, pricing intel, marketplace scraping | web-read, scrapling, pinchtab |
| **Athena** | Strategy research, performance benchmarks | web-read, web-search-pro |
| **Dreami** | Creative inspiration, reference gathering | web-read, pinchtab (screenshots) |
| **Iris** | Visual analysis, design QA, social trends | pinchtab (screenshots), browser-use |
| **Myrmidons** | Health checks, URL verification, bulk scraping | web-read, scrapling spider |
| **Argus** | QA testing, site health audits | pinchtab, scrapling |
| **Taoz** | Build/debug scraping infra | All tools (builder) |
| **Zenni** | Routes scraping tasks to appropriate agent | N/A (dispatches) |

## Related Skills
- `browser-use` — Cloud browser API (heavy automation)
- `content-scraper` — Platform-specific scrapers (YouTube API, Pinterest, Google Trends)
- `firecrawl-search` — General web crawl + search
- `web-search-pro` — Multi-engine web search
- `site-scraper` — Local website crawler
- `tiktok-trends` — TikTok Creative Center scraper
- `product-scout` — Shopee/Lazada product scanner
- `meta-ads-library` — Meta Ad Library scraper
