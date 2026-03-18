---
name: ads-tiktok
description: TikTok Ads deep analysis covering creative quality, tracking, bidding, catalog, Spark Ads.
agents:
  - dreami
---

# Ads TikTok — TikTok Ads Deep Analysis

Comprehensive audit of TikTok advertising covering creative quality, tracking setup, bidding strategies, catalog ads, and Spark Ads. Creative-first platform requires Dreami's expertise.

## When to Use

- TikTok Ads account audit
- Creative performance optimization for TikTok
- Setting up TikTok Ads for a new GAIA brand
- Evaluating Spark Ads and organic-to-paid strategy
- TikTok Shop integration review

## Procedure

### Step 1 — Tracking & Setup

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| TikTok Pixel installed | | Base code + event codes? |
| Events API (server-side) | | For iOS attribution? |
| Standard events configured | | ViewContent, AddToCart, Purchase, SubmitForm? |
| Attribution window | | Click-through and view-through settings? |
| TikTok Shop connected | | If e-commerce brand? |
| Catalog uploaded | | Product feed for dynamic ads? |

### Step 2 — Creative Quality (Most Important)

TikTok is a creative-first platform. This is the highest-weighted section.

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Native feel | | Looks like organic TikTok, not an ad? |
| Hook (first 1-2 seconds) | | Pattern interrupt? Curiosity? |
| Vertical video (9:16) | | Full screen native format? |
| Sound design | | Trending audio? Voiceover? Text-to-speech? |
| Pacing | | Quick cuts? New visual every 2-3 seconds? |
| Text overlays | | Key message readable without sound? |
| CTA integration | | Natural, not forced? |
| UGC style | | Creator-style content? Not polished corporate? |
| Trend awareness | | Using current TikTok trends/formats? |
| Length | | 15-30s optimal. Under 60s. |

### Step 3 — Spark Ads Assessment

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Spark Ads active | | Boosting organic posts? |
| Creator partnerships | | Working with TikTok creators? |
| Organic-to-paid pipeline | | Testing organic first, then boosting winners? |
| Authorization codes | | Proper creator authorization? |
| Engagement vs conversion | | Right objective for Spark Ads? |

### Step 4 — Campaign Structure

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Campaign objectives | | Awareness/Traffic/Conversions appropriate? |
| Ad group consolidation | | Not too fragmented? (50 conversions/week rule) |
| Targeting approach | | Interest, behavior, custom, lookalike? |
| Broad targeting test | | Letting TikTok's algorithm find audience? |
| Placement | | TikTok feed, Pangle, automatic? |

### Step 5 — Bidding & Budget

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Bidding strategy | | Lowest cost, cost cap, bid cap? |
| Daily budget | | Min $20/ad group recommended |
| Learning phase | | 50 conversions in first week? |
| Budget scaling | | Gradual (20%/day max increase)? |
| Dayparting | | Active during peak user hours? |

### Step 6 — Performance Benchmarks

| Metric | Current | TikTok Benchmark | Status |
|--------|---------|------------------|--------|
| CTR | | > 1% good | |
| CPC | | $0.30-2.00 | |
| CPM | | $3-15 | |
| CVR | | > 1.5% for e-commerce | |
| Video view rate (6s) | | > 15% | |
| Average watch time | | > 5 seconds | |
| Engagement rate | | > 3% | |

### Step 7 — Output Report

```markdown
# TikTok Ads Audit — {Brand}
## Overall Score: {score}/10

### Creative Score: {score}/10 (most critical)

### Tracking Health
...

### Creative Analysis
- Top performing: ...
- Underperforming: ...
- Missing formats: ...

### Recommendations
1. Creative: ...
2. Targeting: ...
3. Bidding: ...

### New Creative Concepts
1. {TikTok-native concept}
2. {Trend-based concept}
3. {UGC-style concept}
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-tiktok-{brand}-{date}.md`

## Scoring (5 categories)

| Category | Weight |
|----------|--------|
| Creative Quality | 35% |
| Tracking & Setup | 15% |
| Campaign Structure | 15% |
| Bidding & Budget | 15% |
| Spark Ads & Organic | 20% |

Creative is weighted highest because TikTok performance is 80% creative-driven.

## Agent Role

- **Dreami**: Primary owner. TikTok's creative-first nature makes this Dreami's domain. Evaluates video quality, trend alignment, UGC authenticity, and generates new creative concepts.

## GAIA Brand Context

TikTok is highest priority for:
- **jade-oracle**: Spiritual TikTok is massive. $1 reading hooks work perfectly here.
- **gaia-recipes**: Recipe content performs extremely well on TikTok
- **rasaya / serein**: Wellness/lifestyle content

TikTok creative rules: No polished corporate feel. Must feel native. Sound matters.

## Example

```
Audit TikTok Ads for jade-oracle.
Monthly spend: $500. Running conversion campaigns for $1 readings.
Need to assess creative quality — are ads native enough?
Check if we should use Spark Ads with organic content.
```
