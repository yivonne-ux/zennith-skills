# Involuntary Churn: Payment Recovery (Dunning)

## The Dunning Stack

```
Pre-dunning --> Smart retry --> Dunning messages --> Grace period --> Hard cancel
```

## Pre-Dunning (Prevent Failures)

- Card expiry alerts: 30, 15, 7 days before expiry
- Backup payment method: prompt at signup
- Pre-billing notification: 3-5 days before charge (annual/quarterly plans)
- For WhatsApp-based billing (MIRRA, Pinxin): payment reminder the day before

## Smart Retry by Decline Type

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

## Dunning Message Sequence

| Message | Timing | Tone | Channel |
|---------|--------|------|---------|
| 1 | Day 0 | Friendly alert | Email + WhatsApp |
| 2 | Day 3 | Helpful reminder | Email + WhatsApp |
| 3 | Day 7 | Urgency | Email + WhatsApp + SMS |
| 4 | Day 10 | Final warning | All channels |

**WhatsApp Dunning Template (Day 0 -- Friendly Alert):**
> Hi [name]! Your MIRRA payment didn't go through. Tap here to update your card so your meals keep coming: [link]

**WhatsApp Dunning Template (Day 7 -- Urgency):**
> Hi [name], we still haven't been able to process your payment. Your MIRRA meals will pause in 3 days unless we can sort this out. Update your card here: [link]

**Dunning best practices for GAIA:**
- Direct link to payment update (no login if possible)
- Show what they will lose: "Your MIRRA meals pause next week"
- Don't blame: "your payment didn't go through" not "you failed to pay"
- WhatsApp dunning outperforms email for Malaysian audience
- Plain text performs better than designed emails

## Recovery Benchmarks

| Metric | Poor | Average | Good |
|--------|:----:|:-------:|:----:|
| Soft decline recovery | <40% | 50-60% | 70%+ |
| Hard decline recovery | <10% | 20-30% | 40%+ |
| Overall payment recovery | <30% | 40-50% | 60%+ |

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
