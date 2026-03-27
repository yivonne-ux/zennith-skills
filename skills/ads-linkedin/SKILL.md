---
name: ads-linkedin
description: LinkedIn Ads deep analysis for B2B advertising. Evaluate 25 checks across targeting, creative, bidding, tracking.
agents:
  - dreami
---

# Ads LinkedIn — LinkedIn Ads Deep Analysis

Comprehensive audit of LinkedIn advertising for B2B campaigns. Covers targeting, creative formats, bidding, tracking, and lead gen forms. 25-point checklist.

## When to Use

- B2B advertising audit for any GAIA brand
- LinkedIn Ads account performance review
- Setting up LinkedIn Ads for the first time
- Lead gen campaign optimization
- Evaluating LinkedIn as a new ad channel

## Procedure

### Step 1 — Account Setup Review (5 checks)

| # | Check | Score (1-10) | Notes |
|---|-------|-------------|-------|
| 1 | Insight Tag installed correctly | | Fires on all pages? |
| 2 | Conversion tracking configured | | Right conversion events? |
| 3 | Matched Audiences set up | | Website retargeting, list uploads? |
| 4 | Campaign Manager organized | | Campaign groups logical? |
| 5 | Billing and spend limits | | Appropriate daily/lifetime budgets? |

### Step 2 — Targeting Review (5 checks)

| # | Check | Score (1-10) | Notes |
|---|-------|-------------|-------|
| 6 | Audience size | | 50K-500K for most objectives |
| 7 | Targeting layers | | Not over-layered (2-3 criteria max) |
| 8 | Job title vs function vs seniority | | Right approach for the audience? |
| 9 | Company targeting | | Industry, size, specific companies? |
| 10 | Audience exclusions | | Competitors, current customers, employees excluded? |

### Step 3 — Creative Review (5 checks)

| # | Check | Score (1-10) | Notes |
|---|-------|-------------|-------|
| 11 | Ad format variety | | Single image, carousel, video, text, conversation? |
| 12 | Copy quality | | Professional but not boring? Hook clear? |
| 13 | Creative-to-audience match | | Speaks to the specific audience segment? |
| 14 | A/B testing | | Multiple creatives per campaign? |
| 15 | Sponsored content vs InMail | | Right format for objective? |

### Step 4 — Bidding & Budget Review (5 checks)

| # | Check | Score (1-10) | Notes |
|---|-------|-------------|-------|
| 16 | Bidding strategy | | Manual CPC, automated, max delivery? |
| 17 | Daily budget adequacy | | Enough for 15+ clicks/day? |
| 18 | Cost benchmarks | | CPC $5-12, CPM $30-50, CPL $15-100 typical |
| 19 | Budget pacing | | Even delivery or frontloaded? |
| 20 | Campaign scheduling | | Weekday only for B2B? Business hours? |

### Step 5 — Performance & Optimization (5 checks)

| # | Check | Score (1-10) | Notes |
|---|-------|-------------|-------|
| 21 | CTR vs benchmark | | > 0.4% for sponsored content is good |
| 22 | Lead gen form completion rate | | > 10% is good, < 5% needs work |
| 23 | Frequency management | | < 4 per member per campaign |
| 24 | Demographic reporting analysis | | Who is actually converting? |
| 25 | Lead quality assessment | | MQL rate from LinkedIn leads? |

### Step 6 — LinkedIn-Specific Opportunities

Evaluate whether these features are being used:

- **Lead Gen Forms**: Pre-filled with LinkedIn data, higher conversion
- **Conversation Ads**: Interactive InMail with branching CTAs
- **Document Ads**: PDF/slides as ad content (great for thought leadership)
- **Event Ads**: For webinars and events
- **Thought Leader Ads**: Boost employee posts
- **Revenue Attribution**: LinkedIn attribution reporting

### Step 7 — Output Report

```markdown
# LinkedIn Ads Audit — {Brand}
## Overall Score: {score}/10

### 25-Point Checklist Summary
- Passing (7+): {n}/25
- Needs Work (4-6): {n}/25
- Critical (<4): {n}/25

### Top Issues
...

### Quick Wins
...

### Strategic Recommendations
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-linkedin-{brand}-{date}.md`

## Scoring

Overall = average of all 25 checks, weighted equally.

LinkedIn-specific benchmarks:
- CTR: > 0.4% good, > 0.65% excellent
- CPL: depends on industry, $15-100 typical
- Lead Gen Form CR: > 10% good
- Frequency: < 4 per 30 days

## Agent Role

- **Zenni (main)**: Owns LinkedIn Ads analysis. B2B strategy, targeting logic, bidding optimization, tracking verification.

## GAIA Brand Context

LinkedIn is most relevant for:
- **gaia-learn**: Educational content, courses, professional development
- **gaia-os / iris**: B2B tech, AI services
- **dr-stan**: Professional health/wellness positioning

Less relevant for B2C brands like jade-oracle, pinxin-vegan, gaia-recipes.

## Example

```
Audit LinkedIn Ads for gaia-learn.
Monthly budget: $2,000. Running lead gen campaigns for course signups.
CTR is 0.3% and CPL is $45. Target CPL: $25.
Check targeting and creative quality.
```
