# Winner Detector

Pull campaign metrics and identify statistically significant winners.

## Owner
Artemis

## Trigger
Cron: daily at 7 AM MYT

## What It Does
1. Pull campaign metrics from Meta Ads API after 48hrs, 7 days, 14 days
2. Apply statistical significance test (chi-squared, minimum 95% confidence)
3. Require minimum 1000 impressions before declaring winner
4. Auto-tag winning atoms: hook type, format, formula, visual style, audience, placement
5. Store in winners + seeds tables in gaia.db
6. Trigger variant generation for confirmed winners (notify Apollo)

## Winner Criteria
- ROAS winner: ROAS >= 2.0 with 95% confidence
- CTR winner: CTR >= 2.0% with 95% confidence
- Engagement winner: engagement rate >= 5% with 95% confidence
- Conversion winner: conversion rate top 20% in campaign

## Winning Atoms Tagged
```json
{
  "hook_type": "question|pov|shock|social_proof|...",
  "format": "ugc|lofi|polished|...",
  "formula": "PAS|AIDA|BAB|...",
  "visual_style": "product_hero|lifestyle|text_overlay|...",
  "audience_age": "25-34",
  "audience_gender": "female",
  "placement": "ig_reels|fb_feed|stories|...",
  "cta": "shop_now|learn_more|..."
}
```

## Script
`~/.openclaw/workspace/scripts/detect-winners.py`

## Data
Reads from: Meta Ads API, campaigns table, creatives table
Writes to: seeds table (is_winner, confidence, tags), exec room
