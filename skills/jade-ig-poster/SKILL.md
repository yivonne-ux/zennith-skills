---
name: jade-ig-poster
description: Instagram feed skill for Jade Oracle — thinks like a real social media creator. Plans grid aesthetics, mixes content types (portraits, oracle cards, quotes, flat lays, faceless hands), deduplicates images, and posts with proper spacing. Only Zenni dispatches this skill.
---

# Jade IG Poster v2 — Social Media Creator Brain

This skill thinks like a real IG content creator, not a bot that spams portraits.

## Content Mix (per 6 posts — two grid rows)

| Slot | Type | Example | Image Source |
|------|------|---------|--------------|
| 1 | Oracle scene | Jade reading cards, candles | Jade lifestyle photo |
| 2 | Quote graphic | Text on cream/sage bg | Generated (Pillow) |
| 3 | Flat lay / aesthetic | Cards, crystals, tea, no person | NanoBanana or stock |
| 4 | Faceless / hands | Hands pulling card, holding tea | NanoBanana close-up |
| 5 | Jade lifestyle | Cafe, bookstore, walking | Jade lifestyle photo |
| 6 | Oracle card design | Single card from 25-deck | Generated card art |

## Rules (ENFORCED)
- **NEVER** post same image twice (SHA256 hash tracked)
- **NEVER** 3 portraits in a row (breaks grid)
- **NEVER** mention QMDJ, 奇门遁甲, BaZi, Chinese metaphysics
- **MAX** 5-7 hashtags per post
- **MAX** 1800 chars per caption
- **ONLY** Zenni dispatches this — no crons, no manual posting
- Image warmth >= 7, brand_fit >= 7
- Score >= 60/80 before posting

## Grid Aesthetic Rules
```
Row pattern (every 3 posts):
  [portrait/scene] [quote/card] [flat lay/hands]

Never adjacent:
  portrait | portrait (looks like AI spam)
  quote | quote (looks lazy)

Always adjacent to portrait:
  flat lay OR quote (breaks up the sameness)
```

## Dispatch
```bash
# Zenni calls:
bash dispatch.sh taoz "bash jade-ig-poster.sh run --count 6" "jade-ig-post"

# Or directly:
bash ~/.openclaw/skills/jade-ig-poster/scripts/jade-ig-poster.sh run --count 6
```

## Pipeline
```
PLAN GRID → GENERATE MIX → DEDUP CHECK → SCORE → FIX → POST
```
