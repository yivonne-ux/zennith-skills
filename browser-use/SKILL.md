---
name: browser-use
description: Cloud browser automation via Browser Use API — autonomous web browsing, scraping, form filling
version: 1.0.0
agent: artemis
---

# Browser Use (Cloud API)

Autonomous browser automation using Browser Use cloud service. Agents can browse websites, scrape content, fill forms, take screenshots, and interact with web pages.

## API Key

Stored in `openclaw.json` at `skills.entries.browser-use.apiKey`.

## Capabilities

- **Web scraping**: Extract structured data from any website
- **Form interaction**: Fill forms, click buttons, navigate flows
- **Screenshot capture**: Take full-page or element screenshots
- **Content extraction**: Pull text, images, links from pages
- **Multi-step workflows**: Chain browser actions for complex tasks

## Which Agents Use This

| Agent | Use Case |
|-------|----------|
| Artemis | Research, competitor scraping, market intel |
| Bee001 | Product listings, marketplace research |
| Hermes | Pricing intel, ad landing page analysis |
| Iris | Visual analysis of live websites, design QA |
| Myrmidons | Health checks, URL verification |

## Usage

Dispatch via Zenni or direct agent call:
```bash
openclaw agent --agent artemis --message "Use browser-use to scrape [URL] and extract [data]"
```

## API Docs

- Cloud API: https://docs.cloud.browser-use.com
- Dashboard: https://cloud.browser-use.com

## Notes

- This is the CLOUD service (Browser Use API), separate from OpenClaw's native `browser` tool
- Native `browser` tool uses local Chrome DevTools Protocol
- Cloud browser-use is better for: complex scraping, anti-bot pages, headless automation
- Native browser is better for: quick page reads, simple interactions
