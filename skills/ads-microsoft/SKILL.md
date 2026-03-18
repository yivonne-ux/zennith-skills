---
name: ads-microsoft
description: Microsoft/Bing Ads deep analysis covering Search, Performance Max, Audience Network. Import quality from Google.
agents:
  - main
---

# Ads Microsoft — Microsoft (Bing) Ads Deep Analysis

Comprehensive audit of Microsoft Advertising covering Search, Performance Max, Audience Network, and Shopping campaigns. Special focus on Google import quality and Microsoft-specific opportunities.

## When to Use

- Microsoft Ads account audit
- Evaluating Google Ads import quality
- Bing Search performance optimization
- Exploring Microsoft Audience Network
- Adding Microsoft Ads as a new channel for a GAIA brand

## Procedure

### Step 1 — Google Import Quality

Most Microsoft Ads accounts start as Google imports. Evaluate:

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Import freshness | | Last synced? Auto-import on? |
| Campaign selection | | Only relevant campaigns imported? Not everything? |
| Bid adjustments | | Microsoft often needs different bids than Google |
| Budget appropriateness | | Not same budget as Google (smaller audience) |
| Broken extensions | | Sitelinks, callouts transferred correctly? |
| Tracking params | | UTM updated to msclkid? |
| Paused items | | Paused campaigns from Google also paused? |

### Step 2 — Search Campaign Audit

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Keyword coverage | | Same as Google or Microsoft-specific keywords? |
| Match types | | Appropriate for Bing's matching behavior? |
| Negative keywords | | Imported and maintained? |
| Ad copy | | RSAs with full assets? |
| Ad extensions | | All available types used? |
| Quality Score | | Distribution across keywords? |
| Search term report | | Reviewed for Bing-specific queries? |

### Step 3 — Microsoft-Specific Features

Evaluate usage of Microsoft-unique capabilities:

| Feature | Used? | Notes |
|---------|-------|-------|
| LinkedIn Profile Targeting | | Target by company, industry, job function |
| Microsoft Audience Network | | Native ads across MSN, Outlook, Edge |
| Multimedia Ads | | Large visual search ads |
| Action Extensions | | Direct call-to-action in ads |
| Video Extensions | | Video in search results |
| Automotive/Travel/Property verticals | | If applicable |
| Smart Shopping / PMax | | Microsoft's equivalent |

### Step 4 — Audience Network Assessment

If Audience Network is active:

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Placement quality | | Where are ads showing? Reputable sites? |
| Performance vs Search | | CPA comparison |
| Brand safety | | Exclusion lists applied? |
| Creative quality | | Image ads optimized for native? |

### Step 5 — Demographics & Device Analysis

Microsoft/Bing audience skews differently from Google:
- Older demographic (35+)
- Higher income
- Desktop-heavy
- Windows/Edge default users

| Check | Notes |
|-------|-------|
| Device performance | Desktop vs mobile split? |
| Age/gender performance | Which demographics convert? |
| Geographic performance | Any regional differences from Google? |
| Time-of-day | Different peak hours than Google? |

### Step 6 — Output Report

```markdown
# Microsoft Ads Audit — {Brand}
## Overall Score: {score}/10

### Import Health
- Last sync: {date}
- Import issues found: {n}

### Search Performance
- Clicks: {n} | CPC: ${x} | Conv Rate: {x}%
- vs Google: {comparison}

### Microsoft-Specific Opportunities
...

### Action Items
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-microsoft-{brand}-{date}.md`

## Scoring (5 categories)

| Category | Weight |
|----------|--------|
| Import Quality | 20% |
| Search Optimization | 25% |
| Microsoft Features Usage | 20% |
| Audience & Targeting | 20% |
| Tracking & Attribution | 15% |

## Agent Role

- **Zenni (main)**: Owns Microsoft Ads analysis. Technical audit, import quality, bidding, Microsoft-specific feature recommendations.

## GAIA Brand Context

Microsoft Ads is especially relevant for:
- **gaia-learn**: Education audience, professional users
- **dr-stan / gaia-supplements**: Health-conscious older demographic
- Lower CPC than Google in many verticals (15-30% cheaper)

Less priority for youth-focused brands (jade-oracle, style brands).

## Example

```
Audit Microsoft Ads for gaia-supplements.
Account was imported from Google 3 months ago.
Monthly spend: $500. CPC seems high ($4.50).
Check import quality and identify Microsoft-specific opportunities.
```
