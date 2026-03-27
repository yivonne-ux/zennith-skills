---
name: ads-competitor
description: Competitor ad intelligence analysis across Google, Meta, LinkedIn, TikTok, Microsoft. Spy on competitor ad copy, targeting, spend.
agents:
  - scout
---

# Ads Competitor — Competitor Ad Intelligence

Analyze competitor advertising strategies across all major platforms. Extract ad copy, creative patterns, targeting signals, estimated spend, and positioning to inform our own ad strategy.

## When to Use

- Launching ads for a new GAIA brand and need competitive landscape
- Competitor is outperforming us and we need to understand why
- Planning creative refresh and want inspiration from market leaders
- Entering a new market or vertical

## Procedure

### Step 1 — Identify Competitors

1. Load brand DNA from `~/.openclaw/brands/{brand}/DNA.json`
2. List top 5-10 competitors in the same space
3. For each competitor, note:
   - Website URL
   - Social media handles
   - Known product/service offerings
   - Estimated scale (employees, funding, revenue if public)

### Step 2 — Ad Library Research

Check each platform's ad transparency tools:

| Platform | Tool | URL |
|----------|------|-----|
| Meta | Ad Library | facebook.com/ads/library |
| Google | Ads Transparency Center | adstransparency.google.com |
| TikTok | Creative Center | ads.tiktok.com/business/creativecenter |
| LinkedIn | Ad Library | linkedin.com/ad-library |

For each competitor, document:
- **Active ad count**: How many ads running?
- **Ad formats**: Video, image, carousel, text?
- **Creative themes**: What visuals and messaging patterns?
- **Landing pages**: Where do ads send traffic?
- **Run duration**: How long have top ads been active? (Longer = better performing)
- **Geographic targeting**: What markets are they targeting?

### Step 3 — Creative Analysis

For each competitor's top-performing ads (longest running or most variations):

1. **Hook**: What is the first 3 seconds / first line?
2. **Value Proposition**: What benefit is promised?
3. **Social Proof**: Reviews, testimonials, numbers?
4. **CTA**: What action is requested?
5. **Visual Style**: UGC, polished, AI-generated, lifestyle?
6. **Offer Structure**: Free trial, discount, loss leader?

### Step 4 — Spend Estimation

Estimate competitor ad spend using:
- Number of active ads and variations
- Platforms active on
- SimilarWeb / SEMrush traffic estimates (if available)
- Social media growth rate correlations
- Industry benchmarks

### Step 5 — Gap Analysis

Compare competitor strategies to our brand:

```markdown
## Competitive Gap Analysis — {Brand}

### What Competitors Do That We Don't
- ...

### What We Do Better
- ...

### Opportunities (Competitor Weaknesses)
- ...

### Threats (Competitor Strengths)
- ...

### Creative Patterns to Test
1. {Pattern from competitor A} — adapt for our brand voice
2. {Pattern from competitor B} — test with our audience
...
```

### Step 6 — Output

Save to: `~/.openclaw/workspace/rooms/logs/ads-competitor-{brand}-{date}.md`

## Agent Roles

- **Scout**: Primary researcher. Scrapes ad libraries, gathers data, estimates spend, identifies patterns. Uses web search and browsing tools.
- **Dreami**: Analyzes creative quality, ad copy effectiveness, visual trends. Recommends creative strategies inspired by competitor patterns while maintaining brand voice.

## Workflow

1. Scout gathers all raw competitor data
2. Scout writes initial analysis with data tables
3. Dreami reviews creative patterns and writes actionable recommendations
4. Report posted to relevant room

## GAIA Brand Context

Key competitive landscapes by brand:
- **jade-oracle**: Psychic Samira ($500K+/mo ad spend, 89M+ views), other spiritual/psychic services
- **pinxin-vegan / gaia-eats**: Vegan meal delivery, plant-based food brands
- **dr-stan / rasaya**: Wellness supplements, health coaching
- **mirra**: Bento-style health food (NOT skincare)

## Example

```
Analyze Psychic Samira's ad strategy for jade-oracle competitive intel.
Focus on Meta and TikTok ads.
Document their hook patterns, offer structure, and creative style.
Estimate monthly spend.
```

## Related Skills

- `ads-creative` — Use competitor insights to improve our own creatives
- `ads-plan` — Incorporate competitive intel into campaign planning
- `biz-scraper` — For deeper website/business scraping
