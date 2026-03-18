---
name: ads-audit
description: Full multi-platform paid advertising audit with parallel subagent delegation. Comprehensive scoring across all ad platforms.
agents:
  - main
---

# Ads Audit — Full Multi-Platform Audit with Delegation

Orchestrates a comprehensive paid advertising audit by dispatching platform-specific analyses in parallel to specialist agents. This is the "audit everything" skill that Zenni uses to coordinate a full review.

## When to Use

- Full advertising audit requested across all active platforms
- Quarterly business reviews that include paid media
- New brand onboarding where existing ad accounts need evaluation
- Performance has dropped and root cause is unknown

## Procedure

### Step 1 — Discovery

Identify all active advertising platforms for the brand:

1. Load brand DNA from `~/.openclaw/brands/{brand}/DNA.json`
2. Check for active ad accounts (Google, Meta, LinkedIn, TikTok, Microsoft)
3. Gather any available data exports, screenshots, or account access
4. Note the audit timeframe (default: last 30 days)

### Step 2 — Parallel Dispatch

Dispatch platform-specific audits simultaneously. For each active platform, delegate to the corresponding sub-skill:

| Platform | Skill to Invoke | Delegate To |
|----------|----------------|-------------|
| Google Ads | `ads-google` | Zenni (main) |
| Meta Ads | `ads-meta` | Zenni or Dreami |
| LinkedIn Ads | `ads-linkedin` | Zenni (main) |
| TikTok Ads | `ads-tiktok` | Dreami |
| Microsoft Ads | `ads-microsoft` | Zenni (main) |
| YouTube Ads | `ads-youtube` | Dreami |

Also dispatch in parallel:
- `ads-budget` — Budget allocation review
- `ads-creative` — Cross-platform creative audit (to Dreami)
- `ads-landing` — Landing page assessment (to Dreami or Scout)
- `ads-competitor` — Competitor intelligence (to Scout)

### Step 3 — Collect Results

Wait for all parallel audits to complete. Each returns:
- Platform score (1-10) per category
- Top issues (ranked)
- Action items (prioritized)

### Step 4 — Synthesize

Combine all platform reports into a unified audit:

1. **Cross-Platform Score Matrix**: Table of all platforms vs all categories
2. **Weighted Overall Score**: Account for budget distribution (higher-spend platforms weighted more)
3. **Universal Issues**: Problems appearing across multiple platforms
4. **Platform-Specific Issues**: Unique to one platform
5. **Budget Reallocation**: Should spend shift between platforms?
6. **Priority Action Plan**: Top 10 actions ranked by expected ROI impact

### Step 5 — Output

Generate the final audit document:

```markdown
# Paid Advertising Audit — {Brand Name}
## Date: {date} | Timeframe: {period}
## Overall Score: {score}/10 ({grade})

### Platform Scores
| Platform | Structure | Targeting | Creative | Bidding | Tracking | Landing | Overall |
...

### Executive Summary
...

### Critical Issues (Fix Immediately)
...

### High Priority (This Week)
...

### Medium Priority (This Month)
...

### Budget Recommendations
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-audit-{brand}-{date}.md`

## Scoring Aggregation

```
Platform Score = sum(category_score * category_weight)
Overall Score = sum(platform_score * platform_budget_share)
```

Budget share ensures platforms where you spend more are weighted proportionally in the overall score.

## Agent Role

- **Zenni (main)**: Owns this skill exclusively. Orchestrates the full audit, dispatches sub-audits, synthesizes results, presents final report.

## Delegation Pattern

Use `sessions_spawn` or `dispatch.sh` for parallel execution:

```
dispatch.sh dreami "Run ads-creative audit for {brand}" ads-creative
dispatch.sh scout "Run ads-competitor analysis for {brand}" ads-competitor
```

Wait for all results before synthesizing.

## Example

```
Run a full ads audit for jade-oracle.
Active platforms: Meta ($2000/mo), TikTok ($500/mo), Google ($1000/mo).
Timeframe: Last 60 days.
Goal: Reduce CPA from $8 to $5 for $1 intro readings.
```

## Related Skills

- `ads` — General ad analysis (single-platform or quick review)
- `ads-plan` — Forward-looking strategy (this skill looks backward at performance)
