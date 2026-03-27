---
name: ads-plan
description: Strategic paid advertising planning with industry-specific templates. Create campaign structures, budget allocations, audience strategies.
agents:
  - dreami
---

# Ads Plan — Strategic Advertising Planning

Forward-looking advertising strategy creation. Builds campaign structures, budget allocations, audience strategies, creative briefs, and launch timelines. The planning counterpart to the backward-looking audit skills.

## When to Use

- Launching ads for a new GAIA brand
- Planning a new campaign or promotion
- Quarterly advertising strategy refresh
- Entering a new advertising platform
- Scaling ad spend significantly

## Procedure

### Step 1 — Strategic Foundation

Gather and document:

1. **Brand**: Load DNA from `~/.openclaw/brands/{brand}/DNA.json`
2. **Business Goal**: Revenue target, lead volume, awareness metric
3. **Budget**: Total monthly ad budget available
4. **Timeline**: Launch date, campaign duration
5. **Existing Data**: Past performance, customer profiles, seasonal trends
6. **Competitive Context**: Use `ads-competitor` findings if available

### Step 2 — Audience Strategy

Define audience tiers:

| Tier | Audience | Size Est. | Platform | Approach |
|------|----------|-----------|----------|----------|
| Hot | Website visitors, email list, past customers | Small | Meta, Google | Remarketing, high intent |
| Warm | Lookalikes, engagers, similar interests | Medium | Meta, TikTok | Social proof, offers |
| Cold | Broad interest, demographics | Large | All platforms | Awareness, education |

For each tier:
- Define targeting criteria
- Estimate audience size
- Set expected CPA range
- Plan creative approach (different messaging per tier)

### Step 3 — Platform Selection

Recommend platforms based on brand, audience, and budget:

| Factor | Google | Meta | TikTok | LinkedIn | Microsoft |
|--------|--------|------|--------|----------|-----------|
| Min budget/mo | $500 | $300 | $300 | $1,000 | $200 |
| Best for | High intent | Visual, social | Young, viral | B2B | Older, desktop |
| Avg CPC | $1-5 | $0.50-3 | $0.30-2 | $3-12 | $0.80-4 |
| Learning period | 1-2 weeks | 1 week | 1 week | 2-3 weeks | 1-2 weeks |

### Step 4 — Campaign Architecture

Design the campaign structure:

```markdown
## Campaign Structure — {Brand}

### Platform: {name}
Campaign 1: [Objective] — {name}
  Ad Set 1: {audience} — Budget: ${x}/day
    Ad 1: {format} — {angle}
    Ad 2: {format} — {angle}
    Ad 3: {format} — {angle}
  Ad Set 2: {audience} — Budget: ${x}/day
    Ad 1: ...
    Ad 2: ...

Campaign 2: [Objective] — {name}
  ...
```

### Step 5 — Budget Allocation Plan

| Platform | Campaign | Objective | Daily Budget | Monthly Budget | % of Total |
|----------|----------|-----------|-------------|----------------|------------|
| ... | ... | ... | ... | ... | ... |

Include:
- Testing budget (20% first month for new campaigns)
- Scaling criteria (when to increase budget)
- Kill criteria (when to pause a campaign)

### Step 6 — Creative Briefs

For each campaign, create a creative brief:

```markdown
### Creative Brief — {Campaign Name}
- **Objective**: {what this ad should achieve}
- **Audience**: {who sees this}
- **Key Message**: {one sentence value prop}
- **Hook Options**: {3 opening lines/visuals to test}
- **CTA**: {desired action}
- **Format**: {video 15s / image / carousel}
- **Brand Guidelines**: {from DNA.json}
- **References**: {competitor ads, past winners}
```

### Step 7 — Launch Timeline

| Week | Action |
|------|--------|
| Week -2 | Set up tracking (Pixel, CAPI, GA4) |
| Week -1 | Create audiences, upload creatives, QA |
| Week 1 | Launch at 50% budget, monitor daily |
| Week 2 | First optimization pass, pause losers |
| Week 3 | Scale winners, add new creatives |
| Week 4 | Full budget, weekly reporting cadence |

### Step 8 — Output

```markdown
# Advertising Plan — {Brand}
## Period: {start} to {end}
## Total Budget: ${amount}/month

### Strategy Summary
...

### Platform Mix
...

### Campaign Architecture
...

### Budget Allocation
...

### Creative Briefs
...

### Timeline
...

### KPIs & Success Criteria
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-plan-{brand}-{date}.md`

## Agent Roles

- **Zenni (main)**: Strategy, platform selection, budget allocation, campaign architecture, KPIs
- **Dreami**: Creative briefs, ad copy concepts, visual direction, brand voice guidelines

## GAIA Brand Context

Planning priorities by brand type:
- **E-commerce** (jade-oracle, gaia-print, wholey-wonder): Conversion-focused, ROAS-driven
- **F&B/Local** (pinxin-vegan, gaia-eats, mirra): Local targeting, delivery-focused
- **Wellness** (dr-stan, rasaya, serein): Compliance-careful, trust-building
- **Education** (gaia-learn): Lead gen, webinar funnels

## Example

```
Create an ad plan for jade-oracle launch.
Budget: $3,000/month across Meta and TikTok.
Goal: 600 $1 intro reading purchases per month (CPA $5).
Compete with Psychic Samira's hook-based funnel.
Timeline: Launch in 2 weeks.
```
