---
name: funnel-playbook
version: "1.0.0"
description: "TOFU/MOFU/BOFU operating system. Maps every content type, ad type, formula, hook, and metric to funnel stages. Includes upsell/downsell triggers, retargeting logic, and value ladder design."
---

# Funnel Playbook — Full Funnel Operating System

## The GAIA Funnel Architecture

```
                    ┌─────────────────────┐
                    │      TOFU           │  ← Reach, educate, entertain
                    │   (Awareness)       │  ← 60% of ad budget
                    │                     │  ← CPM optimized
                    ├─────────────────────┤
                    │      MOFU           │  ← Engage, nurture, consider
                    │  (Consideration)    │  ← 25% of ad budget
                    │                     │  ← CTR/engagement optimized
                    ├─────────────────────┤
                    │      BOFU           │  ← Convert, close, sell
                    │   (Conversion)      │  ← 15% of ad budget
                    │                     │  ← ROAS/CPA optimized
                    ├─────────────────────┤
                    │   POST-PURCHASE     │  ← Retain, upsell, advocate
                    │  (Loyalty Loop)     │  ← Email + WhatsApp (low cost)
                    └─────────────────────┘
```

## TOFU — Top of Funnel (Awareness)

### Goal
Get in front of NEW people who don't know your brand yet.

### Content Types
| Type | Platform | Format | Sell Level |
|---|---|---|---|
| Educational tips | IG Reels, TikTok | 15-30s video | 0% sell |
| Trend content | TikTok, Reels | 15-60s video | 0% sell |
| Behind-the-scenes | IG Stories, TikTok | 15-30s video | 5% sell |
| Myth-busting | Reels, YouTube Shorts | 15-60s video | 0% sell |
| Recipe content | All platforms | 30-90s video | 10% sell |
| Challenge/UGC | TikTok, Reels | 15-60s video | 5% sell |
| Memes/humor | TikTok, IG | Image or video | 0% sell |

### Ad Types (from GAIA backend)
- Ugly Ads (authentic, LoFi)
- Challenge (UGC-style)
- POV Content
- Educational Clips
- Trend-Riding

### Formulas to Use
- Curiosity hooks
- POV hooks
- Pattern interrupt
- "Did you know" educational
- Entertainment-first

### Metrics
| Metric | Target | Red Flag |
|---|---|---|
| CPM | < RM 15 | > RM 30 |
| Reach | 10K+/week | < 2K/week |
| Video View Rate | > 25% | < 10% |
| 3s View Rate | > 50% | < 30% |
| Save Rate | > 2% | < 0.5% |

### Audience Targeting
- Broad interests (healthy food, cooking, vegan, wellness)
- Lookalike 5-10% of existing customers
- Geographic: Malaysia (start), then Singapore, then global

---

## MOFU — Middle of Funnel (Consideration)

### Goal
People who've seen your brand — now convince them to CARE.

### Content Types
| Type | Platform | Format | Sell Level |
|---|---|---|---|
| Product deep-dive | IG Feed, YouTube | 60-180s video | 30% sell |
| Comparison | Reels, TikTok | 30-60s video | 20% sell |
| Testimonial/UGC | All platforms | 15-60s video | 40% sell |
| Before/After | Reels, Stories | 15-30s video | 30% sell |
| Ingredient spotlight | IG Feed, Blog | Image + caption | 20% sell |
| FAQ content | Stories, Reels | 15-30s video | 25% sell |
| Social proof | All platforms | Image or video | 40% sell |

### Ad Types (from GAIA backend)
- Testimonial
- Before & After
- Product-as-Hero
- Comparison
- Social Proof Stack

### Formulas to Use
- PAS (Problem → Agitation → Solution)
- BAB (Before → After → Bridge)
- Social proof stacking
- FAQ objection handling
- "3 reasons why" lists

### Metrics
| Metric | Target | Red Flag |
|---|---|---|
| CTR | > 2% | < 1% |
| Engagement Rate | > 5% | < 2% |
| Save/Share Rate | > 3% | < 1% |
| Email Signup Rate | > 3% | < 1% |
| Time on Site | > 60s | < 15s |

### Audience Targeting
- Engaged audience (video viewers 50%+, page engagers)
- Email subscribers (not yet purchased)
- Website visitors (not yet purchased)
- Lookalike 1-3% of purchasers

---

## BOFU — Bottom of Funnel (Conversion)

### Goal
Close the sale. These people KNOW you — give them the push.

### Content Types
| Type | Platform | Format | Sell Level |
|---|---|---|---|
| Direct offer | Meta Ads, Email | Image + copy | 90% sell |
| Flash sale | Stories, WhatsApp | Image/video | 100% sell |
| Bundle showcase | Feed, Email | Carousel | 80% sell |
| Limited edition | All platforms | Video | 85% sell |
| Countdown | Stories, Email | Sticker/timer | 100% sell |
| Review roundup | Feed, Email | Carousel | 70% sell |

### Ad Types (from GAIA backend)
- Flash Sale
- Bundle Offer
- Limited Edition
- Direct Response
- Retargeting Special

### Formulas to Use
- AIDA (Attention → Interest → Desire → Action)
- Urgency + Scarcity stack
- Risk reversal (money-back guarantee)
- Price anchoring (was RM99, now RM59)
- Direct CTA with social proof

### Metrics
| Metric | Target | Red Flag |
|---|---|---|
| ROAS | > 3x | < 1.5x |
| CPA | < RM 25 | > RM 50 |
| Conversion Rate | > 3% | < 1% |
| AOV | > RM 80 | < RM 40 |
| Cart Abandon Rate | < 60% | > 80% |

### Audience Targeting
- Add to cart (not purchased) — retarget within 7 days
- Website visitors (product pages) — retarget within 14 days
- Email openers (promotional) — retarget within 7 days
- Previous purchasers (repeat purchase window)

---

## POST-PURCHASE — Loyalty Loop

### Goal
Turn buyers into repeat buyers and advocates.

### Trigger Sequence
```
Purchase → Thank you (immediate)
  → Day 1: Order confirmation + tracking
  → Day 3: "How to enjoy your [product]" (recipes/tips)
  → Day 7: Review request + UGC incentive
  → Day 14: Cross-sell complementary product
  → Day 21: Loyalty program / subscription offer
  → Day 30: Replenishment reminder
  → Day 45: Win-back if no repeat (discount)
  → Day 60: "We miss you" + new product launch
```

### Upsell Triggers
| Trigger | Action | Channel |
|---|---|---|
| Cart > RM50 | "Add [X] for free shipping" | On-site |
| First purchase | "Welcome bundle 20% off" | Email D+3 |
| 2nd purchase | "Subscribe & save 15%" | Email D+7 |
| High AOV | "VIP early access" | WhatsApp |
| Review submitted | "Thanks! Here's 10% off next order" | Email |

### Referral Mechanics
- "Give RM10, Get RM10" referral code in post-purchase email
- UGC incentive: Share + tag = entered in monthly giveaway
- WhatsApp group exclusive: VIP pricing, early access

---

## FUNNEL HEALTH DASHBOARD

### Weekly Check (Athena runs this)
```bash
# Check funnel health
TOFU:  Reach trend (↑/↓), CPM trend, new audience %
MOFU:  CTR trend, engagement trend, email list growth
BOFU:  ROAS trend, CPA trend, conversion rate
POST:  Repeat rate, LTV trend, referral rate

# Rebalance triggers
IF TOFU reach declining → refresh creatives, test new hooks
IF MOFU CTR declining → test new ad types, update social proof
IF BOFU ROAS declining → check creative fatigue, test new offers
IF POST repeat declining → check email sequence, add incentive
```

### Budget Rebalancing Rules
```
Default: TOFU 60% | MOFU 25% | BOFU 15%

IF new brand launch → TOFU 80% | MOFU 15% | BOFU 5%
IF product launch → TOFU 40% | MOFU 30% | BOFU 30%
IF seasonal peak → TOFU 30% | MOFU 20% | BOFU 50%
IF clearance → TOFU 10% | MOFU 10% | BOFU 80%
```

## CHANGELOG
### v1.0.0 (2026-02-20)
- Full TOFU/MOFU/BOFU operating system with post-purchase loyalty loop
