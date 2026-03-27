---
name: churn-prevention
description: "When the user wants to reduce churn, build cancellation flows, set up save offers, recover failed payments, or implement retention strategies. Also use when the user mentions 'churn,' 'cancel flow,' 'offboarding,' 'save offer,' 'dunning,' 'failed payment recovery,' 'win-back,' 'retention,' 'exit survey,' 'pause subscription,' 'involuntary churn,' 'people keep canceling,' 'churn rate is too high,' 'how do I keep users,' or 'customers are leaving.'"
agents:
  - scout
---

# Churn Prevention -- Subscription Retention for GAIA Brands

Reduce churn for subscription businesses through cancel flows, save offers, dunning sequences, and proactive retention. Adapted for GAIA subscription brands.

## GAIA Subscription Brands

Before any churn work, load the brand's DNA:
- `~/.openclaw/brands/{brand}/DNA.json` -- always load first

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

Single question, single-select with optional free text. 5-8 reasons max.

**GAIA-adapted cancel reasons:**

| Reason | What It Tells You | GAIA Context |
|--------|-------------------|--------------|
| Too expensive | Price sensitivity | Common for MIRRA weekly plans, Serein boxes |
| Not using it enough | Low engagement | Jade Oracle members not doing readings |
| Food/product doesn't suit me | Fit issue | MIRRA taste preferences, Serein product match |
| Switching to competitor | Competitive pressure | Other meal services, wellness boxes |
| Health/diet change | Life circumstance | Common for all wellness brands |
| Temporary / seasonal | Usage pattern | Jade Oracle seasonal interest, travel |
| Moving / relocation | Logistics | MIRRA delivery zone, Pinxin local pickup |
| Other | Catch-all | Always include free text |

**Survey framing:** "Help us improve" works better than "Why are you leaving?"

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

### Save Offer Types

**Discount**
- 20-25% off for 2-3 months (sweet spot)
- Never go above 40% -- trains cancel-for-deals behavior
- Show RM amount saved, not just percentage
- Time-limit: "This offer expires when you leave this page"

**Pause Subscription**
- 1-3 month max (longer pauses rarely reactivate)
- 60-80% of pausers eventually return
- Auto-reactivation with 7-day advance WhatsApp/email notice
- Keep preferences and data intact

**Plan Downgrade**
- MIRRA: switch from 5-day to 3-day plan instead of canceling
- Serein: switch to every-other-month delivery
- Jade Oracle: switch to basic tier with fewer readings
- Frame as "right-size your plan" not "downgrade"

**Menu/Product Swap** (F&B specific)
- Offer dietary preference change (MIRRA: different cuisine style)
- Let them customize next delivery before canceling
- "Try our new menu for one week on us"

**Personal Outreach**
- For high-value subscribers (top 20% by LTV)
- WhatsApp message from brand founder (fits GAIA's personal touch)
- Works especially well for MIRRA and Pinxin's community-driven brands

### Cancel Flow UI Principles

- Keep "continue cancelling" visible -- no dark patterns
- One primary offer + one fallback (not a wall of options)
- Show specific RM savings
- Use subscriber's name and order history
- Mobile-first (WhatsApp-heavy customer base)
- For WhatsApp-based brands (MIRRA, Pinxin): cancel flow can be a guided conversation

---

## Churn Prediction -- Proactive Retention

The best save happens before the customer clicks "Cancel."

### Risk Signals for GAIA Brands

| Signal | Risk Level | GAIA Context |
|--------|-----------|--------------|
| Order skips increase | High | MIRRA skip 2+ weeks in a row |
| Login/engagement drops 50%+ | High | Jade Oracle no readings for 3+ weeks |
| Support complaints spike then stop | High | Gave up -- about to churn |
| Stopped opening emails/WhatsApp | Medium | Disengaging from brand |
| Billing page visits increase | High | Researching how to cancel |
| NPS/feedback score drops below 6 | Medium | Growing dissatisfaction |
| Referred friends who churned | Medium | Social proof erosion |

### Health Score Model

Simple 0-100 score from weighted signals:

```
Health Score = (
  Order/usage frequency  x 0.30 +
  Engagement (opens/clicks) x 0.25 +
  Support sentiment        x 0.15 +
  Payment health           x 0.15 +
  Tenure bonus             x 0.15
)
```

| Score | Status | Action |
|-------|--------|--------|
| 80-100 | Healthy | Upsell, referral program |
| 60-79 | Needs attention | Proactive check-in via WhatsApp |
| 40-59 | At risk | Intervention: personal message + special offer |
| 0-39 | Critical | Founder outreach, priority save |

### Proactive Interventions

| Trigger | Intervention | Channel |
|---------|-------------|---------|
| 2+ order skips | "We miss you! Here's what's new on the menu" | WhatsApp |
| No login 14+ days | Re-engagement with recent updates | Email + WhatsApp |
| NPS detractor (0-6) | Personal follow-up within 24h | WhatsApp call |
| Approaching renewal | Value recap: "This month you enjoyed X meals" | Email |
| Payment method expiring | Card update reminder 30/15/7 days before | Email |

---

## Involuntary Churn: Payment Recovery (Dunning)

### The Dunning Stack

```
Pre-dunning --> Smart retry --> Dunning messages --> Grace period --> Hard cancel
```

### Pre-Dunning (Prevent Failures)

- Card expiry alerts: 30, 15, 7 days before expiry
- Backup payment method: prompt at signup
- Pre-billing notification: 3-5 days before charge (annual/quarterly plans)
- For WhatsApp-based billing (MIRRA, Pinxin): payment reminder the day before

### Smart Retry by Decline Type

| Decline Type | Examples | Strategy |
|-------------|----------|----------|
| Soft decline | Insufficient funds, timeout | Retry 3-5 times over 7-10 days |
| Hard decline | Card stolen, account closed | Don't retry -- ask for new card |
| Authentication required | 3D Secure | Send customer to update payment |

**Retry timing:**
- Retry 1: 24 hours after failure
- Retry 2: 3 days after failure
- Retry 3: 5 days after failure
- Retry 4: 7 days after failure (with escalated dunning message)
- After 4 retries: hard cancel with easy reactivation path

### Dunning Message Sequence

| Message | Timing | Tone | Channel |
|---------|--------|------|---------|
| 1 | Day 0 | Friendly alert | Email + WhatsApp |
| 2 | Day 3 | Helpful reminder | Email + WhatsApp |
| 3 | Day 7 | Urgency | Email + WhatsApp + SMS |
| 4 | Day 10 | Final warning | All channels |

**Dunning best practices for GAIA:**
- Direct link to payment update (no login if possible)
- Show what they will lose: "Your MIRRA meals pause next week"
- Don't blame: "your payment didn't go through" not "you failed to pay"
- WhatsApp dunning outperforms email for Malaysian audience
- Plain text performs better than designed emails

### Recovery Benchmarks

| Metric | Poor | Average | Good |
|--------|:----:|:-------:|:----:|
| Soft decline recovery | <40% | 50-60% | 70%+ |
| Hard decline recovery | <10% | 20-30% | 40%+ |
| Overall payment recovery | <30% | 40-50% | 60%+ |

---

## Metrics & Measurement

### Key Churn Metrics

| Metric | Formula | Target |
|--------|---------|--------|
| Monthly churn rate | Churned / Start-of-month subscribers | <5% |
| Revenue churn (net) | (Lost MRR - Expansion MRR) / Start MRR | Negative |
| Cancel flow save rate | Saved / Total cancel attempts | 25-35% |
| Offer acceptance rate | Accepted / Shown | 15-25% |
| Pause reactivation rate | Reactivated / Total paused | 60-80% |
| Dunning recovery rate | Recovered / Total failed payments | 50-60% |

### Cohort Analysis

Segment churn by:
- **Acquisition channel** -- WhatsApp vs Instagram vs referral vs walk-in
- **Plan type** -- weekly vs monthly, meal count, tier
- **Tenure** -- when do most cancellations happen? (30, 60, 90 days)
- **Cancel reason** -- which reasons are growing?
- **Save offer** -- which offers work for which segments?

---

## Common Mistakes

- **No cancel flow at all** -- instant cancel leaves money on the table (even a simple survey + one offer saves 10-15%)
- **Making cancellation hard to find** -- breeds resentment, bad reviews; FTC requires easy cancel
- **Same offer for every reason** -- blanket discount does not address "don't like the food"
- **Discounts too deep** -- 50%+ trains cancel-for-deals behavior
- **Ignoring involuntary churn** -- often 30-50% of total, easiest to fix
- **No dunning messages** -- letting failed payments silently cancel
- **Guilt-trip copy** -- "Are you sure you want to abandon us?" damages brand trust
- **Not tracking saved subscriber LTV** -- a "saved" subscriber who churns 30 days later was not saved
- **Pausing too long** -- pauses beyond 3 months rarely reactivate
- **Email-only dunning in Malaysia** -- WhatsApp open rates are 5-10x higher than email here

---

## Workflow

1. **Diagnose** -- Calculate current churn rate (voluntary vs involuntary split)
2. **Quick win** -- Set up dunning sequence for involuntary churn first
3. **Build cancel flow** -- Exit survey + dynamic save offers matched to reasons
4. **Instrument** -- Track health score signals per subscriber
5. **Proactive retention** -- Automated interventions before cancel intent
6. **Measure** -- Monthly churn metrics, save rates, offer performance
7. **Compound** -- Feed learnings into `knowledge-compound` for cross-brand patterns

## Related Skills

- **klaviyo-engine** -- Email/SMS flows for dunning and win-back sequences
- **acca-engine** -- WhatsApp conversation flows for cancel/save interactions
- **shopify-engine** -- Subscription management on Shopify
- **ads** -- Acquisition cost context for retention ROI calculations
