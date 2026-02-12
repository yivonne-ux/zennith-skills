---
name: tiktok-trends
version: "1.0.0"
description: Scrape TikTok Creative Center for trending hashtags, sounds, top ads, and keyword insights. Public, no auth required.
metadata:
  openclaw:
    scope: research
    guardrails:
      - Public data only — TikTok Creative Center is publicly accessible
      - Respect rate limits (2s delay between pages)
      - Tag all trends with GAIA relevance categories
---

# TikTok Creative Center Trends Scraper

## Purpose

TikTok Creative Center (ads.tiktok.com/business/creativecenter) is a public resource showing what's trending on TikTok. This skill scrapes it for:
- **Trending hashtags** — what topics are hot right now in Malaysia/SEA
- **Trending sounds** — which audio clips are going viral (critical for Reels/TikTok content)
- **Top ads showcase** — best-performing ad creatives on TikTok
- **Keyword insights** — search volume trends for product-related terms

## Usage

```bash
# Trending hashtags in Malaysia
python3 ~/.openclaw/skills/tiktok-trends/scripts/scrape_tiktok_trends.py \
  --type hashtags --country MY

# Trending sounds
python3 ~/.openclaw/skills/tiktok-trends/scripts/scrape_tiktok_trends.py \
  --type sounds --country MY

# Top ads
python3 ~/.openclaw/skills/tiktok-trends/scripts/scrape_tiktok_trends.py \
  --type top-ads --country MY

# Keyword search volume
python3 ~/.openclaw/skills/tiktok-trends/scripts/scrape_tiktok_trends.py \
  --type keyword --query "vegan food"
```

## Output Format

```json
{
  "type": "hashtags",
  "country": "MY",
  "scraped_at": "2026-02-12T16:00:00Z",
  "trends": [
    {
      "rank": 1,
      "name": "#veganmalaysia",
      "views": "2.3M",
      "growth": "+45%",
      "gaia_relevance": "food",
      "relevance_score": 9
    }
  ]
}
```

## Relevance Tagging

Every trend is tagged with GAIA relevance:
- `food` — 食 (vegan, plant-based, cooking, recipes, healthy eating)
- `fashion` — 衣 (streetwear, sustainable, accessories, POD)
- `home` — 住 (decor, wellness, aromatherapy, lifestyle)
- `mobility` — 行 (travel, commute, accessories)
- `marketing` — ads, UGC, business growth, e-commerce
- `general` — entertainment, culture, not directly relevant

Only trends scoring 5+ on relevance are included in agent reports.

## Agent Assignment

- **Artemis 🏹** — daily trend scanning
- **Iris 🌈** — content timing and sound selection
- **Hermes ⚡** — commercial trend opportunities
- **Apollo 🎨** — creative format inspiration

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: TikTok Creative Center scraper for hashtags, sounds, top ads
