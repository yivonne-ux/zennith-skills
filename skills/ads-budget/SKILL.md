---
name: ads-budget
description: Budget allocation and bidding strategy review across all ad platforms. Evaluate spend efficiency, ROAS, CPA targets.
agents:
  - dreami
  - main
---

# Ads Budget — Budget Allocation & Bidding Strategy Review

Evaluates how advertising budget is distributed across platforms, campaigns, and ad sets. Analyzes bidding strategies, spend pacing, and identifies waste or under-investment.

## When to Use

- Budget needs rebalancing across platforms or campaigns
- ROAS or CPA targets are not being met
- Scaling up or down ad spend
- New platform being added to the mix
- Monthly/quarterly budget planning

## Procedure

### Step 1 — Collect Budget Data

For each active platform, gather:

- Total monthly budget and actual spend
- Campaign-level budget breakdown
- Bidding strategy per campaign (manual CPC, target CPA, target ROAS, max conversions, etc.)
- Daily budget caps and pacing
- Historical spend trend (last 3-6 months)

### Step 2 — Efficiency Analysis

Evaluate each platform and campaign on:

| Metric | What to Check |
|--------|---------------|
| ROAS | Return on ad spend vs target. Anything under 2x needs review |
| CPA | Cost per acquisition vs target and industry benchmarks |
| CPM | Cost per 1000 impressions — is the platform getting expensive? |
| CPC | Cost per click trends — rising CPC = audience fatigue or competition |
| Budget Utilization | Is the daily budget being fully spent? Under-delivery = targeting too narrow |
| Impression Share | Are you losing auctions due to budget or rank? |
| Wasted Spend | Negative keywords missing? Bad placements? Bot traffic? |

### Step 3 — Bidding Strategy Audit

For each campaign, evaluate:

1. **Strategy Alignment**: Does the bidding strategy match the campaign goal?
   - Awareness = CPM/reach bidding
   - Traffic = CPC bidding
   - Conversions = CPA/ROAS bidding
2. **Bid Caps**: Are caps too tight (limiting delivery) or too loose (overpaying)?
3. **Learning Phase**: Are campaigns stuck in learning phase due to insufficient conversions?
4. **Automated vs Manual**: Is automation appropriate for the data volume?

### Step 4 — Cross-Platform Allocation

Analyze budget distribution:

- **Marginal ROAS**: Which platform gives the best return on the next dollar?
- **Saturation Point**: Is any platform showing diminishing returns at current spend?
- **Funnel Coverage**: Is budget allocated across awareness, consideration, conversion?
- **Seasonal Adjustment**: Does spend need to shift based on time of year?

### Step 5 — Recommendations

Output a budget reallocation plan:

```markdown
## Current Allocation
| Platform | Monthly Budget | ROAS | CPA | Recommendation |
|----------|---------------|------|-----|----------------|
| Meta     | $2,000        | 3.2x | $6  | Increase 20%   |
| Google   | $1,000        | 1.8x | $12 | Restructure    |
| TikTok   | $500          | 4.1x | $4  | Scale 50%      |

## Proposed Allocation
| Platform | New Budget | Expected ROAS | Rationale |
...

## Bidding Changes
| Campaign | Current Strategy | Proposed | Why |
...

## Waste Reduction
- Identified ${amount} monthly waste from: ...
```

### Step 6 — Save

Save to: `~/.openclaw/workspace/rooms/logs/ads-budget-{brand}-{date}.md`

## Scoring (5 dimensions, 1-10 each)

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Spend Efficiency | 25% | ROAS and CPA vs targets |
| Budget Pacing | 20% | Consistent delivery, no under/over-spend |
| Strategy Fit | 20% | Bidding matches campaign objectives |
| Cross-Platform Balance | 20% | Optimal distribution across platforms |
| Waste Control | 15% | Minimal wasted spend on irrelevant traffic |

## Agent Role

- **Zenni (main)**: Owns budget analysis. Pulls data, runs calculations, makes allocation recommendations. May delegate creative efficiency analysis to Dreami.

## GAIA Brand Context

Budget decisions must account for brand maturity:
- **Established brands** (pinxin-vegan, gaia-eats): Can optimize for ROAS
- **New brands** (jade-oracle): Need awareness spend first, CPA optimization later
- **Seasonal brands** (gaia-recipes): Budget should flex with content calendar

## Example

```
Review budget allocation for jade-oracle.
Current: Meta $2000, TikTok $500.
Target CPA: $5 for $1 intro reading.
Considering adding Google Ads with $1000/mo.
Should we reallocate or add new budget?
```
