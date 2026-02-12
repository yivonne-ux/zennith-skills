---
name: meta-ads-library
version: "1.0.0"
description: Scrape Meta Ad Library for competitor ads, creative formats, ad copy, and performance marketing intelligence. Public, no auth required.
metadata:
  openclaw:
    scope: research
    guardrails:
      - Public data only — Meta Ad Library is publicly accessible
      - Respect rate limits (2s delay between requests)
      - Never store personal data from ads
      - Output is for research and creative inspiration only
---

# Meta Ad Library Scraper

## Purpose

The Meta Ad Library (facebook.com/ads/library) is the #1 competitive intelligence source for performance marketing. Every ad running on Facebook/Instagram is publicly visible. This skill scrapes it for:
- **Competitor creative analysis** — what ad formats, copy, and visuals competitors use
- **Creative inspiration** — winning ad patterns, hook styles, CTA formulations
- **Market landscape** — who is spending, on what, and how aggressively

## Usage

```bash
# Search by keyword
python3 ~/.openclaw/skills/meta-ads-library/scripts/scrape_meta_library.py \
  --keyword "vegan food" \
  --country MY \
  --max-results 20

# Search by advertiser
python3 ~/.openclaw/skills/meta-ads-library/scripts/scrape_meta_library.py \
  --advertiser "Green Monday" \
  --country MY

# Search by category for GAIA pillars
python3 ~/.openclaw/skills/meta-ads-library/scripts/scrape_meta_library.py \
  --keyword "plant based malaysia" \
  --country MY \
  --max-results 30
```

## Output Format

```json
{
  "query": "vegan food",
  "country": "MY",
  "scraped_at": "2026-02-12T16:00:00Z",
  "ads": [
    {
      "advertiser": "Brand Name",
      "ad_text": "Full ad copy text...",
      "cta": "Shop Now",
      "platform": "facebook,instagram",
      "status": "active",
      "started": "2026-01-15",
      "landing_url": "https://...",
      "media_type": "image|video|carousel",
      "screenshot_path": "/tmp/meta-ads/ad-001.png"
    }
  ],
  "total_found": 20
}
```

## Agent Assignment

- **Artemis 🏹** — runs competitive research scans
- **Apollo 🎨** — uses output for creative inspiration and ad copy patterns
- **Hermes ⚡** — analyzes competitor positioning and offers
- **Athena 🦉** — tracks competitor ad spend patterns over time

## Research Templates

### Competitor Scan
Search: `[competitor brand name]` → extract all active ads → analyze creative patterns

### Category Landscape
Search: `[product category] malaysia` → extract top 30 ads → identify dominant formats and CTAs

### Creative Swipe File
Search: `[keyword]` → screenshot top 10 ads → organize by format (image/video/carousel)

### Offer Intelligence
Search: `[product type] discount|sale|offer` → extract pricing and promotion patterns

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: Playwright-based Meta Ad Library scraper
