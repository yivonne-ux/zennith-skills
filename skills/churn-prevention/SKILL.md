---
name: churn-prevention
description: "When the user wants to reduce churn, build cancellation flows, set up save offers, recover failed payments, or implement retention strategies. Also use when the user mentions 'churn,' 'cancel flow,' 'offboarding,' 'save offer,' 'dunning,' 'failed payment recovery,' 'win-back,' 'retention,' 'exit survey,' 'pause subscription,' 'involuntary churn,' 'people keep canceling,' 'churn rate is too high,' 'how do I keep users,' or 'customers are leaving.'"
agents:
  - scout
---

# Churn Prevention -- Subscription Retention for GAIA Brands

Reduce churn for subscription businesses through cancel flows, save offers, dunning sequences, and proactive retention.

## GAIA Subscription Brands

Before any churn work, load the brand's DNA: `~/.openclaw/brands/{brand}/DNA.json`

| Brand | Subscription Type | Billing | Key Churn Risk |
|-------|-------------------|---------|----------------|
| **MIRRA** | Weekly bento meal subscription (weight management) | Weekly/monthly via Stripe or manual | Taste fatigue, diet drop-off, price sensitivity |
| **Jade Oracle** | Membership / reading credits | Monthly via Stripe | Perceived value gap, seasonal interest |
| **Serein** | Wellness subscription box | Monthly via Stripe/Shopify | Product fatigue, unmet expectations |
| **Pinxin Vegan** | Meal plans / recurring orders | Manual / WhatsApp | Convenience competitors, diet changes |
| **Dr. Stan** | Supplement subscription | Monthly via Shopify | Results skepticism, forgot to use |

MIRRA = bento-style weight management meal subscription (NOT skincare, NOT the-mirra.com).

---

## Two Types of Churn

| Type | Cause | % of Total | Solution |
|------|-------|:----------:|----------|
| **Voluntary** | Customer chooses to cancel | 50-70% | Cancel flows, save offers, exit surveys |
| **Involuntary** | Payment fails | 30-50% | Dunning emails, smart retries, card updaters |

Involuntary churn is often easier to fix. Start there for quick wins.

---

## Cancel Flow Design

### Flow Structure
```
Trigger --> Exit Survey --> Dynamic Save Offer --> Confirmation --> Post-Cancel
```

### Exit Survey
Single question, single-select with optional free text. 5-8 reasons max. Frame as "Help us improve" not "Why are you leaving?"

**GAIA-adapted cancel reasons:** Too expensive | Not using it enough | Food/product doesn't suit me | Switching to competitor | Health/diet change | Temporary/seasonal | Moving/relocation | Other

### Dynamic Save Offers
Match the offer to the reason. A discount will not save someone who dislikes the food.

| Cancel Reason | Primary Offer | Fallback Offer |
|---------------|---------------|----------------|
| Too expensive | 20-25% off for 2-3 months | Downgrade to smaller plan |
| Not using it enough | Pause 1-3 months | Free onboarding / guided session |
| Food/product doesn't suit me | Menu customization / swap | One free trial of different menu |
| Switching to competitor | Comparison + loyalty discount | Feedback call |
| Health/diet change | Adapted menu / wellness plan | Pause until ready |
| Temporary / seasonal | Pause subscription | Downgrade temporarily |
| Moving / relocation | Check new delivery zone | Pause + notify when zone expands |

### Save Offer Rules
- **Discount**: 20-25% off for 2-3 months (never above 40%). Show RM saved, not just %.
- **Pause**: 1-3 month max (60-80% of pausers return). Auto-reactivate with 7-day advance notice.
- **Downgrade**: Frame as "right-size your plan" not "downgrade."
- **Menu Swap**: Offer dietary preference change or "try new menu for one week on us."
- **Personal Outreach**: For top 20% by LTV. WhatsApp from founder.

### Cancel Flow UI Principles
- Keep "continue cancelling" visible -- no dark patterns
- One primary offer + one fallback (not a wall of options)
- Mobile-first (WhatsApp-heavy customer base)

---

## Churn Prediction -- Proactive Retention

### Risk Signals

| Signal | Risk Level | GAIA Context |
|--------|-----------|--------------|
| Order skips increase | High | MIRRA skip 2+ weeks in a row |
| Login/engagement drops 50%+ | High | Jade Oracle no readings for 3+ weeks |
| Support complaints spike then stop | High | Gave up -- about to churn |
| Billing page visits increase | High | Researching how to cancel |
| Stopped opening emails/WhatsApp | Medium | Disengaging from brand |
| NPS/feedback score drops below 6 | Medium | Growing dissatisfaction |

### Health Score Model (0-100)
```
Health Score = (Order frequency x 0.30) + (Engagement x 0.25) + (Support sentiment x 0.15) + (Payment health x 0.15) + (Tenure bonus x 0.15)
```

| Score | Status | Action |
|-------|--------|--------|
| 80-100 | Healthy | Upsell, referral program |
| 60-79 | Needs attention | Proactive WhatsApp check-in |
| 40-59 | At risk | Personal message + special offer |
| 0-39 | Critical | Founder outreach, priority save |

---

## Workflow

1. **Diagnose** -- Calculate current churn rate (voluntary vs involuntary split)
2. **Quick win** -- Set up dunning sequence for involuntary churn first
3. **Build cancel flow** -- Exit survey + dynamic save offers matched to reasons
4. **Instrument** -- Track health score signals per subscriber
5. **Proactive retention** -- Automated interventions before cancel intent
6. **Measure** -- Monthly churn metrics, save rates, offer performance
7. **Compound** -- Feed learnings into `knowledge-compound` for cross-brand patterns

> Load `references/dunning-and-payment-recovery.md` for full dunning stack, smart retry logic, message templates, recovery benchmarks, and churn metrics/cohort analysis.

> Load `references/win-back-sequences.md` for 7/30/90-day win-back sequences, WhatsApp templates, re-activation incentives, and re-onboarding flow.

## Common Mistakes
- No cancel flow at all (even a simple survey + one offer saves 10-15%)
- Making cancellation hard to find (breeds resentment, bad reviews)
- Same offer for every reason (blanket discount does not address "don't like the food")
- Discounts too deep (50%+ trains cancel-for-deals behavior)
- Ignoring involuntary churn (often 30-50% of total, easiest to fix)
- Email-only dunning in Malaysia (WhatsApp open rates are 5-10x higher)

## Related Skills
- **klaviyo-engine** -- Email/SMS flows for dunning and win-back sequences
- **acca-engine** -- WhatsApp conversation flows for cancel/save interactions
- **shopify-engine** -- Subscription management on Shopify
- **ads** -- Acquisition cost context for retention ROI calculations
