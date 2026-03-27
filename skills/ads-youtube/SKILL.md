---
name: ads-youtube
description: YouTube Ads specific analysis covering campaign types, creative quality, targeting, bumper/skippable/discovery formats.
agents:
  - hermes
  - dreami
---

# Ads YouTube — YouTube Ads Deep Analysis

Comprehensive audit of YouTube advertising covering all campaign types, creative quality by format, targeting strategies, and view-through optimization. Managed through Google Ads but requires format-specific creative expertise.

## When to Use

- YouTube Ads performance audit
- Video ad creative quality assessment
- Setting up YouTube Ads for a new GAIA brand
- Evaluating bumper vs skippable vs discovery formats
- YouTube as part of a Google Ads audit (deeper dive than ads-google covers)

## Procedure

### Step 1 — Campaign Type Review

| Type | Active? | Budget | Performance | Notes |
|------|---------|--------|-------------|-------|
| Skippable In-Stream | | | | Pay per view (30s or click) |
| Non-Skippable In-Stream (15s) | | | | Pay per impression |
| Bumper (6s) | | | | Awareness, pay per impression |
| In-Feed (Discovery) | | | | Thumbnail + text, pay per click |
| Shorts Ads | | | | Vertical, swipeable |
| Masthead | | | | Premium placement |

### Step 2 — Creative Quality by Format

#### Skippable In-Stream (15-60s)

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| First 5 seconds hook | | Must grab before skip button appears |
| Branding in first 5s | | Brand visible before potential skip |
| Storytelling arc | | Problem, solution, CTA? |
| CTA clarity | | Verbal + visual + end card? |
| Production quality | | Appropriate for brand positioning? |
| Multiple creative versions | | A/B testing? |

#### Bumper (6s)

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Single message focus | | ONE idea only in 6 seconds |
| Brand recognition | | Brand visible throughout? |
| Visual simplicity | | Not cluttered? |
| Memorability | | Would you remember it? |
| Series approach | | Multiple bumpers telling a story? |

#### In-Feed / Discovery

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Thumbnail quality | | Compelling, high contrast, text overlay? |
| Title/headline | | Curiosity-driven, keyword-rich? |
| Video content | | Delivers on thumbnail promise? |
| Length | | Longer form OK (2-10 min for discovery) |
| Engagement | | Likes, comments, watch time? |

#### Shorts Ads

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Vertical (9:16) | | Native Shorts format? |
| Hook in first 1-2s | | Instant engagement? |
| Loop-worthy | | Rewatchable? |
| Trend-aligned | | Following Shorts trends? |

### Step 3 — Targeting Strategy

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Audience segments | | In-market, affinity, custom intent? |
| Placement targeting | | Specific channels/videos? |
| Topic targeting | | Relevant content categories? |
| Remarketing | | Website visitors, video viewers? |
| Exclusions | | Inappropriate content excluded? |
| Demographics | | Age, gender, parental status, income? |

### Step 4 — Performance Metrics

| Metric | Current | Benchmark | Status |
|--------|---------|-----------|--------|
| View Rate (skippable) | | > 15% good, > 25% excellent | |
| CPV | | $0.02-0.10 | |
| CTR | | > 0.5% for in-stream | |
| Watch Time | | > 30s average for skippable | |
| Earned Actions | | Shares, likes, subscribes from ad | |
| View-Through Conv | | Conversions after viewing but not clicking | |
| Brand Lift | | If running brand lift study | |

### Step 5 — YouTube-Specific Opportunities

| Feature | Using? | Notes |
|---------|--------|-------|
| Video Action Campaigns | | CTA overlays + companion banners |
| YouTube Shopping | | Product tags in videos |
| Companion Banners | | 300x60 display alongside video |
| End Cards | | CTA cards at end of video |
| Sitelink Extensions | | Additional links below video |
| Audio Ads | | For music/podcast listeners |
| Connected TV | | CTV targeting for big screen |

### Step 6 — Output Report

```markdown
# YouTube Ads Audit — {Brand}
## Overall Score: {score}/10

### Active Formats
| Format | Score | Key Finding |
...

### Creative Analysis
- Best performing video: ...
- Weakest video: ...
- Missing formats: ...

### Targeting Assessment
...

### Recommendations
1. ...

### New Video Concepts
1. {Format}: {concept}
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-youtube-{brand}-{date}.md`

## Scoring (5 categories)

| Category | Weight |
|----------|--------|
| Creative Quality | 30% |
| Format Strategy | 20% |
| Targeting | 20% |
| Performance vs Benchmarks | 15% |
| YouTube Features Usage | 15% |

## Agent Role

- **Dreami**: Primary owner. Video creative assessment requires Dreami's creative expertise. Evaluates hook quality, storytelling, visual appeal, and generates new video concepts. Can use `video-gen.sh` for concept prototyping.

## GAIA Brand Context

YouTube Ads priority by brand:
- **jade-oracle**: Spiritual content, reading demos, testimonials. Compete with Psychic Samira's YouTube presence.
- **gaia-learn**: Educational content, course previews. Discovery format ideal.
- **gaia-recipes**: Recipe videos, cooking tutorials. High organic potential.
- **dr-stan / rasaya**: Expert wellness content, trust-building long-form.

## Example

```
Audit YouTube Ads for jade-oracle.
Running skippable in-stream and bumper campaigns.
Monthly spend: $800. View rate is 12% (below benchmark).
Assess creative quality — are hooks strong enough?
Recommend 3 new video concepts.
```
