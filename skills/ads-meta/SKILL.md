---
name: ads-meta
description: Meta Ads deep analysis covering Facebook and Instagram advertising. Evaluate Pixel/CAPI, EMQ, creative diversity, Advantage+, audience.
agents:
  - hermes
---

# Ads Meta — Meta (Facebook & Instagram) Ads Deep Analysis

Comprehensive audit of Meta advertising covering Pixel/CAPI setup, Event Match Quality, creative diversity, Advantage+ campaigns, audience strategy, and attribution.

## When to Use

- Meta Ads account audit
- Facebook or Instagram ad performance review
- Setting up Meta Ads for a new GAIA brand
- Advantage+ Shopping or App campaigns evaluation
- Pixel/CAPI troubleshooting
- Creative fatigue diagnosis

## Procedure

### Step 1 — Tracking & Data Foundation (Critical)

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Meta Pixel installed | | Fires on all pages? |
| Conversions API (CAPI) active | | Server-side events? |
| Event Match Quality (EMQ) | | > 6.0 for key events? |
| Deduplication working | | No double-counting between Pixel and CAPI? |
| Standard events configured | | ViewContent, AddToCart, Purchase, Lead? |
| Custom conversions | | For brand-specific actions? |
| iOS 14+ handling | | AEM domains configured? 8 priority events set? |
| UTM parameters | | On all ad URLs? |

### Step 2 — Account Structure

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Campaign Objective alignment | | Awareness/Traffic/Conversions matches goal? |
| CBO vs ABO | | Campaign Budget Optimization appropriate? |
| Ad set consolidation | | Not over-fragmented? (50 conversions/week rule) |
| Naming conventions | | Platform_Objective_Audience_Creative format? |
| Campaign count | | Manageable number? Not too many in learning? |

### Step 3 — Audience Strategy

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Custom Audiences | | Website, email list, engagement-based? |
| Lookalike Audiences | | Based on best customers? Multiple %? |
| Broad targeting | | Testing Advantage+ broad for conversion campaigns? |
| Exclusions | | Purchasers excluded from prospecting? |
| Audience overlap | | Not competing against yourself? |
| Advantage+ Audience | | Suggestions vs original audiences? |

### Step 4 — Creative Diversity

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Format variety | | Image, video, carousel, collection, Instant Experience? |
| Aspect ratios | | 1:1, 4:5, 9:16 all covered? |
| UGC content | | User-generated or UGC-style ads? |
| Creative volume | | 3-5+ active creatives per ad set? |
| Dynamic Creative | | Testing headlines/images/CTA combinations? |
| Advantage+ Creative | | Enhancements enabled where appropriate? |
| Refresh cadence | | New creatives every 2-4 weeks? |

### Step 5 — Advantage+ Shopping Campaigns (ASC)

If applicable:

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| ASC active | | Running for e-commerce brands? |
| Existing customer cap | | Set to limit % of spend on existing? |
| Creative variety in ASC | | 10+ creatives recommended? |
| Budget allocation | | ASC vs manual campaigns balanced? |
| Country targeting | | Correct markets? |

### Step 6 — Performance Metrics

| Metric | Current | Benchmark | Status |
|--------|---------|-----------|--------|
| CTR (link) | | > 1% good | |
| CPC | | Industry dependent | |
| CPM | | $5-25 typical | |
| CPA / CPL | | vs target | |
| ROAS | | > 3x for e-commerce | |
| Frequency | | < 3 per 7 days | |
| Relevance Score | | > 5/10 | |
| Outbound CTR | | > 0.8% | |

### Step 7 — Output Report

```markdown
# Meta Ads Audit — {Brand}
## Overall Score: {score}/10

### Tracking Health
- Pixel: {status} | CAPI: {status} | EMQ: {score}

### Account Structure
...

### Audience Strategy
...

### Creative Analysis
...

### Performance Summary
...

### Top 5 Action Items
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-meta-{brand}-{date}.md`

## Scoring (6 categories)

| Category | Weight |
|----------|--------|
| Tracking & Data | 20% |
| Account Structure | 15% |
| Audience Strategy | 20% |
| Creative Diversity | 20% |
| Bidding & Budget | 10% |
| Performance vs Benchmarks | 15% |

## Agent Roles

- **Zenni (main)**: Technical audit — tracking, structure, audiences, bidding, attribution
- **Dreami**: Creative audit — ad copy, visuals, brand voice, creative fatigue, new concepts

## GAIA Brand Context

Meta Ads is primary for most GAIA brands:
- **jade-oracle**: Spiritual audience, $1 reading funnel (compete with Psychic Samira's $500K/mo)
- **pinxin-vegan / gaia-eats**: Food imagery, local targeting
- **dr-stan / rasaya**: Health/wellness, careful with ad policy compliance
- **gaia-print / wholey-wonder**: E-commerce, Advantage+ Shopping ideal

## Example

```
Full Meta Ads audit for jade-oracle.
Monthly spend: $2,000. Running conversion campaigns for $1 intro reading.
CPA is $8, target is $5.
Check Pixel/CAPI health, audience overlap, creative fatigue.
```
