---
name: growth-engine
version: "1.0.0"
description: "Statistical winner detection, creative duplication, scaling engine, and growth hacking toolkit. Finds what works, proves it statistically, duplicates it, and scales it."
---

# Growth Engine — Find Winners, Prove Them, Duplicate, Scale

## Purpose
The marketing flywheel: Test → Detect Winner → Prove Statistically → Duplicate → Scale → Compound.
This is what separates amateurs from the top 1% of performance marketers.

## The Growth Loop

```
         ┌───────────────────────────────┐
         │                               │
    ┌────▼────┐     ┌──────────┐    ┌────┴────┐
    │  TEST   │────▶│  DETECT  │───▶│  PROVE  │
    │ (Launch │     │ (Flag    │    │ (Stats  │
    │  ads)   │     │  signals)│    │  test)  │
    └─────────┘     └──────────┘    └────┬────┘
         ▲                               │
         │                          ┌────▼─────┐
    ┌────┴─────┐    ┌──────────┐   │ DUPLICATE │
    │  SCALE   │◀───│ OPTIMIZE │◀──│ (Variant  │
    │ (Budget  │    │ (Refine  │   │  factory) │
    │  ladder) │    │  winners)│   └───────────┘
    └──────────┘    └──────────┘
```

## 1. DETECTION — Signal Flags

### Automatic Winner Flags
| Signal | Threshold | Confidence | Action |
|---|---|---|---|
| CTR > 2x campaign avg | After 1000 impressions | Low | Flag for monitoring |
| ROAS > 2x target | After 48 hours | Medium | Flag for stat test |
| CPA < 50% of target | After 20 conversions | Medium | Flag for stat test |
| Engagement > 3x avg | After 500 reach | Low | Flag for monitoring |
| Video completion > 50% | After 1000 views | Medium | Content winner flag |
| Share rate > 5% | After 500 reach | High | Viral potential flag |

### Automatic Loser Flags
| Signal | Threshold | Action |
|---|---|---|
| CTR < 0.5% | After 2000 impressions | Pause |
| ROAS < 0.5x target | After 72 hours | Pause |
| CPA > 3x target | After 10 conversions | Pause |
| Video completion < 10% | After 500 views | Pause |
| Zero conversions | After 48 hours + 1000 reach | Pause |

## 2. STATISTICAL PROOF

### A/B Test Significance Calculator
```python
# Chi-squared test for conversion rate
# Input: visitors_A, conversions_A, visitors_B, conversions_B
# Output: p-value, confidence level, winner

# Minimum sample sizes for 95% confidence:
# If expected CVR = 3%, need ~1,000 visitors per variant
# If expected CVR = 1%, need ~3,800 visitors per variant

# Decision framework:
# p < 0.01  → 99% confident → STRONG WINNER (scale aggressively)
# p < 0.05  → 95% confident → WINNER (scale)
# p < 0.10  → 90% confident → LIKELY WINNER (scale cautiously)
# p > 0.10  → Not significant → Keep testing OR kill
```

### Bayesian Approach (For Low Traffic)
```
# When you don't have enough data for chi-squared:
# Use Bayesian probability with Beta distribution
# Prior: Beta(1,1) = uniform (no assumption)
# Update with data: Beta(1+conversions, 1+non-conversions)
# Compare: P(A > B) from posterior samples

# Decision:
# P(A > B) > 95% → A is winner
# P(A > B) > 80% → A is probably better (need more data)
# P(A > B) 40-60% → No meaningful difference
```

### Multi-Armed Bandit (For Continuous Optimization)
```
# Instead of fixed A/B test → dynamic allocation
# Thompson Sampling:
# 1. Each variant has a Beta(successes, failures) distribution
# 2. Sample from each distribution
# 3. Allocate more traffic to higher samples
# 4. Over time, traffic naturally flows to winners
# 5. Never fully "kills" losers (allows recovery)

# Best for: Always-on ad campaigns where you want continuous improvement
```

## 3. DUPLICATION — The Variant Factory

### When a winner is confirmed, generate 10 variants:

**Dimension 1: Hook Variation**
- Same visual, 5 different hooks
- Same message, different opening frame
- Same hook style, different specific words

**Dimension 2: Visual Variation**
- Same hook text, different product image
- Same content, different thumbnail
- Same creative, different color scheme
- Image → Video, Video → Carousel

**Dimension 3: Audience Variation**
- Same creative → test on different interest groups
- Same creative → test on different age brackets
- Same creative → test on different placements (Feed vs Reels vs Stories)
- Same creative → test on different platforms (Meta → TikTok → YouTube)

**Dimension 4: Format Variation**
- Winning image → animate to video (Kling AI)
- Winning video → extract still for image ad
- Winning 60s video → cut to 15s for Stories
- Winning single → expand to carousel

**Dimension 5: Copy Variation**
- Same visual, different headline formula
- Same visual, different CTA
- Same visual, different emotional angle
- Same visual, add/remove price

### Variant Naming Convention
```
[brand]-[campaign]-[variant]-[dimension]-[number]
gaia-cny2026-v1-hook-03
gaia-cny2026-v1-visual-02
gaia-cny2026-v1-audience-05
```

## 4. SCALING — Budget Ladder

### The Conservative Scale (Recommended)
```
Day 1-3:   RM 50/day    (test)       → If ROAS > target: proceed
Day 4-7:   RM 100/day   (validate)   → If ROAS holds ±20%: proceed
Day 8-14:  RM 250/day   (grow)       → If ROAS holds ±20%: proceed
Day 15-21: RM 500/day   (scale)      → If ROAS holds ±20%: proceed
Day 22-30: RM 1000/day  (accelerate) → Monitor daily
Day 31+:   Uncapped      (full scale) → Weekly reviews
```

### Kill Switches
```
IMMEDIATE PAUSE if:
  - ROAS drops below 1.0x for 24 hours
  - CPA exceeds 3x target for 24 hours
  - Spend > RM 500 with zero conversions
  - CTR drops below 0.3%

GRADUAL REDUCE if:
  - ROAS declines 3 consecutive days (creative fatigue)
  - Frequency > 3 (audience fatigue)
  - CPM increases > 50% (competition/saturation)
```

### Creative Fatigue Detection
```
Signals of fatigue:
  1. CTR declining for 3+ consecutive days
  2. Frequency > 2.5 on same audience
  3. Negative feedback increasing
  4. CPM rising without competition changes

Response:
  1. Rotate to next variant in lineup
  2. Refresh hook (keep winning body)
  3. Change visual (keep winning hook)
  4. Expand audience (new interest layers)
  5. If all above fail → new creative cycle
```

## 5. GROWTH HACKING TOOLKIT

### ICE Scoring Matrix
For every growth experiment:
```
Impact (1-10):     How big is the potential upside?
Confidence (1-10): How sure are we this will work?
Ease (1-10):       How easy is it to implement?
ICE Score:         (I × C × E) / 10

Priority: Run highest ICE scores first
Kill at: 2 weeks with no positive signal
```

### Growth Experiment Templates

**Referral Program**
- ICE: 7×6×5 = 210/10 = 21
- Mechanism: Give RM10, Get RM10
- Tracking: Unique referral codes per customer
- Expected: 5-15% referral rate if incentive is right

**Free Shipping Threshold Optimization**
- ICE: 8×8×9 = 576/10 = 57.6
- Test: Current threshold vs +10% vs +20%
- Expected: Higher threshold → higher AOV (up to a point)

**Exit Intent Popup**
- ICE: 6×7×8 = 336/10 = 33.6
- Trigger: Mouse leaves viewport (desktop) / scroll up (mobile)
- Offer: 5% off or free shipping
- Expected: Recover 3-8% of bouncing visitors

**Social Proof Notification**
- ICE: 5×6×9 = 270/10 = 27
- "Sarah from KL just purchased Vegan Rendang (2 min ago)"
- Expected: 2-5% conversion lift

**Cart Abandonment WhatsApp**
- ICE: 8×7×6 = 336/10 = 33.6
- 1 hour after abandon → WhatsApp message with product image
- Expected: 10-20% recovery rate (vs 5-8% email)

**Bundle Builder**
- ICE: 7×6×5 = 210/10 = 21
- Let customer build custom bundle at discount
- Expected: 20-40% AOV increase

### AARRR Pirate Metrics Dashboard
```
ACQUISITION
  - New visitors/week: ___
  - Cost per new visitor: ___
  - Top channels: ___
  - Trend: ↑/↓/→

ACTIVATION
  - Signup rate: ___
  - First purchase rate: ___
  - Time to first purchase: ___
  - Trend: ↑/↓/→

RETENTION
  - 30-day repeat rate: ___
  - 90-day repeat rate: ___
  - Churn rate: ___
  - Trend: ↑/↓/→

REVENUE
  - AOV: RM ___
  - LTV: RM ___
  - Monthly revenue: RM ___
  - ROAS: ___x
  - Trend: ↑/↓/→

REFERRAL
  - Referral rate: ___%
  - NPS score: ___
  - UGC submissions/month: ___
  - Trend: ↑/↓/→
```

## Agent Assignment
- **Athena** → Statistical testing, winner detection, dashboard
- **Hermes** → Scaling decisions, budget management
- **Apollo** → Variant factory (creative duplication)
- **Artemis** → Growth experiment scouting
- **Zenni** → Approval gates for budget increases

## CHANGELOG
### v1.0.0 (2026-02-20)
- Winner detection, statistical proof, variant factory, budget ladder, growth experiments, AARRR metrics
