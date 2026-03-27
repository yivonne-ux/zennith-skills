---
name: ads
description: Comprehensive paid advertising audit and optimization for any business type. Covers Google, Meta, LinkedIn, TikTok, Microsoft. Multi-platform analysis with scoring.
agents:
  - dreami
  - main
---

# Ads — Multi-Platform Advertising Audit & Optimization

Comprehensive paid advertising analysis covering all major platforms. Use this as the top-level entry point for any ad-related audit or optimization request. Delegates to platform-specific sub-skills when deep dives are needed.

## When to Use

- Client or brand requests a full advertising review
- Evaluating ad performance across multiple platforms
- Planning a new advertising strategy for any GAIA brand
- Quarterly or monthly ad performance check-ins

## Supported Platforms

| Platform | Sub-Skill | Best For |
|----------|-----------|----------|
| Google Ads | `ads-google` | Search, Shopping, PMax, YouTube, Display |
| Meta Ads | `ads-meta` | Facebook, Instagram, Advantage+ |
| LinkedIn Ads | `ads-linkedin` | B2B targeting, lead gen |
| TikTok Ads | `ads-tiktok` | Short-form video, Spark Ads |
| Microsoft Ads | `ads-microsoft` | Bing Search, Audience Network |
| YouTube Ads | `ads-youtube` | Video campaigns, bumpers, discovery |

## Procedure

### Step 1 — Gather Context

Collect the following before starting:

- **Brand**: Which of the 14 GAIA brands? Load DNA from `~/.openclaw/brands/{brand}/DNA.json`
- **Platforms**: Which platforms are active?
- **Budget**: Monthly spend per platform
- **Goals**: ROAS target, CPA target, awareness vs conversion
- **Access**: Ad account IDs, any exported reports or CSV data
- **Timeframe**: Last 30/60/90 days

### Step 2 — Platform Scoring

For each active platform, evaluate on a 1-10 scale:

| Category | Weight | What to Check |
|----------|--------|---------------|
| Account Structure | 15% | Campaign organization, naming conventions, ad groups |
| Targeting | 20% | Audience segments, exclusions, lookalikes, remarketing |
| Creative Quality | 25% | Ad copy, visuals, video, A/B testing |
| Bidding & Budget | 15% | Strategy alignment, bid caps, budget pacing |
| Tracking & Attribution | 15% | Pixel/CAPI, conversion tracking, UTM params |
| Landing Pages | 10% | Message match, load speed, mobile UX, CTA |

### Step 3 — Cross-Platform Analysis

- **Budget allocation efficiency**: Is spend distributed optimally across platforms?
- **Audience overlap**: Are platforms cannibalizing each other?
- **Creative consistency**: Does brand voice match across platforms?
- **Attribution conflicts**: Are platforms double-counting conversions?
- **Funnel gaps**: Where are prospects dropping off?

### Step 4 — Generate Report

Output a structured report with:

1. **Executive Summary** (3-5 sentences)
2. **Platform Scorecards** (table with scores per category)
3. **Top 5 Wins** (what is working well)
4. **Top 5 Issues** (ranked by revenue impact)
5. **Action Items** (prioritized, with estimated impact)
6. **Budget Reallocation Recommendations**

### Step 5 — Save & Dispatch

- Save report to `~/.openclaw/workspace/rooms/logs/ads-audit-{brand}-{date}.md`
- If deep dives needed, delegate to platform-specific sub-skills
- Post summary to the relevant room if this was a dispatched task

## Agent Roles

- **Zenni (main)**: Routes ad audit requests, coordinates multi-platform reviews, presents final report
- **Dreami**: Evaluates creative quality, ad copy effectiveness, brand voice alignment, visual consistency

## GAIA Brand Context

All 14 brands have DNA files at `~/.openclaw/brands/{brand}/DNA.json`. Always load the relevant DNA before evaluating creative or copy. Core F&B/wellness brands (pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein) have distinct voices that ads must respect.

## Example Usage

```
Audit all active ads for jade-oracle across Meta and TikTok.
Focus on creative quality and ROAS optimization.
Monthly budget: $2,000 Meta, $500 TikTok.
Goal: $5 CPA for $1 intro reading.
```

## Scoring Formula

```
Overall Score = sum(category_score * weight) across all categories
Grade: 9-10 = Excellent | 7-8 = Good | 5-6 = Needs Work | <5 = Critical
```

## Related Skills

- `ads-audit` — Full audit with parallel subagent delegation
- `ads-plan` — Strategic planning and campaign structure
- `ads-creative` — Creative quality deep dive
- `ads-budget` — Budget allocation analysis
- `ads-competitor` — Competitor intelligence
