---
name: site-scraper
description: Local website crawler + extractor (best-effort) that turns pages into clean notes, briefs, and checklists.
metadata:
  openclaw:
    requires:
      bins: [python3]
agents:
  - scout
---

# site-scraper

A small local crawler that fetches pages from a site (same-domain), extracts readable text, and outputs:
- a source list
- key bullets
- optional WhatsApp-ready summary/checklist

## Install (one-time)
This skill uses a local venv inside the skill folder.

## Run
```bash
python3 ~/.openclaw/skills/site-scraper/scripts/site_scraper.py --url "https://example.com" --depth 1 --max-pages 10 --out ./scrape-out
```

## Safety defaults
- same-domain only
- max-pages capped
- no form submissions
- respects timeouts

## Typical uses
- scrape campaign landing pages + FAQs
- scrape blog posts into a brief
- extract product copy + objections
