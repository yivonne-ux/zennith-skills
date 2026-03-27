---
name: ads-google
description: Google Ads deep analysis covering Search, Performance Max, Display, YouTube, Shopping. Evaluate Quality Score, structure, keywords.
agents:
  - dreami
---

# Ads Google — Google Ads Deep Analysis

Comprehensive audit of Google Ads accounts covering Search, Performance Max, Display, YouTube, and Shopping campaigns. Evaluates account structure, Quality Score, keyword strategy, and conversion tracking.

## When to Use

- Google Ads account needs a full audit
- Quality Score is low or declining
- CPC is rising without performance improvement
- Setting up Google Ads for a new GAIA brand
- Performance Max campaigns are underperforming

## Procedure

### Step 1 — Account Structure Review

Evaluate the overall account organization:

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Campaign naming convention | | Clear, consistent naming? |
| Campaign-to-ad-group ratio | | Not too many ad groups per campaign? |
| SKAG/STAG structure | | Single keyword/theme ad groups where appropriate? |
| Campaign type coverage | | Right mix of Search, PMax, Display, Video? |
| Geographic targeting | | Correct locations? Exclusions set? |
| Device bid adjustments | | Mobile/desktop/tablet optimized? |
| Ad schedule | | Dayparting based on performance data? |
| Negative keyword lists | | Shared lists applied? Regularly updated? |

### Step 2 — Search Campaign Audit (25 checks)

| Category | Checks |
|----------|--------|
| Keywords | Match types appropriate? Search term report reviewed? Negative keywords? Quality Score distribution? |
| Ad Copy | RSA pin strategy? Ad strength "Good" or better? All headlines/descriptions filled? Dynamic insertion used? |
| Extensions | Sitelinks, callouts, structured snippets, call, location, price extensions? |
| Bidding | Strategy matches goal? Target CPA/ROAS realistic? Sufficient conversion volume? |
| Landing Pages | Relevance to ad? Load speed? Mobile-friendly? Conversion tracking on page? |

### Step 3 — Performance Max Audit

| Check | What to Evaluate |
|-------|-----------------|
| Asset Groups | Sufficient variety? All asset types provided? |
| Audience Signals | Custom segments? Your data? Interests? |
| Search Themes | Relevant themes added? Not cannibalizing Search? |
| Placement Reports | Where are ads showing? Any poor placements? |
| Conversion Goals | Correct goals selected? Value-based if applicable? |
| Creative Quality | "Best" vs "Low" asset performance ratings? |

### Step 4 — Quality Score Deep Dive

For top 50 keywords by spend:

1. **Expected CTR**: Below average = ad copy needs work
2. **Ad Relevance**: Below average = keyword-ad alignment off
3. **Landing Page Experience**: Below average = page needs optimization

Calculate Quality Score distribution:
- % of keywords scoring 7+ (good)
- % scoring 4-6 (needs work)
- % scoring 1-3 (critical)

### Step 5 — Conversion Tracking Audit

| Check | Status |
|-------|--------|
| Google Tag installed correctly | |
| Enhanced conversions enabled | |
| Conversion actions aligned to business goals | |
| No duplicate conversions | |
| Conversion window appropriate | |
| Offline conversion import (if applicable) | |
| Google Analytics 4 linked | |

### Step 6 — Shopping / Merchant Center (if applicable)

| Check | Status |
|-------|--------|
| Product feed quality | |
| Disapproved products | |
| Supplemental feeds | |
| Price competitiveness | |
| Product ratings | |

### Step 7 — Output Report

```markdown
# Google Ads Audit — {Brand}
## Overall Score: {score}/10

### Account Health Summary
- Active campaigns: {n}
- Monthly spend: ${amount}
- Avg Quality Score: {score}
- Conversion rate: {rate}%

### Critical Issues
...

### Optimization Opportunities
...

### Keyword Recommendations
- Add: ...
- Pause: ...
- Negative: ...

### Structure Changes
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-google-{brand}-{date}.md`

## Scoring (6 categories, weighted)

| Category | Weight |
|----------|--------|
| Account Structure | 15% |
| Keyword Strategy | 20% |
| Ad Copy & Extensions | 20% |
| Bidding & Budget | 15% |
| Quality Score | 15% |
| Tracking & Attribution | 15% |

## Agent Role

- **Zenni (main)**: Owns Google Ads analysis. Technical audit of structure, keywords, bidding, tracking. May request Dreami's input on ad copy quality.

## Example

```
Audit the Google Ads account for gaia-supplements.
Focus on Search and Performance Max campaigns.
Monthly spend: $3,000. Target ROAS: 4x.
Quality Score seems to be dropping — investigate.
```
