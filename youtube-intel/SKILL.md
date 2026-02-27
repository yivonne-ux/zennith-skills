---
name: youtube-intel
version: "1.0.0"
description: Search YouTube for marketing education, UGC tutorials, ad creative breakdowns, and e-commerce strategies. Public search, no API key needed.
metadata:
  openclaw:
    scope: research
    guardrails:
      - Public search only, no auth required
      - Focus on educational/marketing content relevant to GAIA
      - Respect rate limits (2s between searches)
---

# YouTube Marketing Intelligence

## Purpose

Search YouTube for marketing knowledge that feeds the Pantheon's capabilities:
- **UGC creation tutorials** — how to shoot, edit, and brief UGC creators
- **Ad creative breakdowns** — what makes winning Meta/TikTok ads work
- **E-commerce strategies** — Shopee/Lazada/TikTok Shop optimization
- **Content production** — A-roll, B-roll, product photography, 分镜 (storyboarding)

## Usage

```bash
python3 ~/.openclaw/skills/youtube-intel/scripts/scrape_youtube.py \
  --query "how to create UGC" --max-results 15

python3 ~/.openclaw/skills/youtube-intel/scripts/scrape_youtube.py \
  --query "Meta ads 2026 tutorial" --max-results 10

python3 ~/.openclaw/skills/youtube-intel/scripts/scrape_youtube.py \
  --query "product review video template" --max-results 10
```

## Key Search Topics

### Content Creation
- "how to create UGC for brands"
- "product review video tutorial"
- "A-roll B-roll explained"
- "storyboard for product video"
- "product photography for ecommerce"
- "分镜 教程" (storyboard tutorial in Chinese)

### Ad Creative
- "Meta ads creative 2026"
- "TikTok ads that convert"
- "winning ad creative formula"
- "hook examples for ads"
- "carousel ad design tips"

### E-Commerce
- "Shopee seller tips Malaysia"
- "TikTok Shop tutorial"
- "Lazada listing optimization"
- "ecommerce product launch strategy"

### Marketing Strategy
- "performance marketing for DTC"
- "email marketing Klaviyo"
- "influencer marketing Malaysia"
- "content calendar planning"

## Agent Assignment

- **Dreami 🎭** — creative techniques, visual production
- **Iris 🌈** — platform strategy, engagement tactics
- **Hermes ⚡** — e-commerce and ads optimization
- **All agents** — general marketing education

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: YouTube search scraper for marketing intelligence
