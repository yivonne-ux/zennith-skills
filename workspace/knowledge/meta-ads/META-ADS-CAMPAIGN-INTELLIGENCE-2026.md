# Meta Ads Campaign Intelligence — 2026
> Source: Yivonne (Ops) — Pinxin Vegan campaign, March 2026
> Proven from RM5,000+ spend, 20+ purchases, 135+ WA conversations

---

## Bid Strategy Findings (Proven with Real Data)

### TROAS (Minimum ROAS) — FAILED
- ROAS floor is USELESS during learning phase (<50 conversions)
- With 0 purchase data, Meta can't predict ROAS → spends freely or restricts completely
- Pinxin TROAS: RM1,643 spent, RM205 CPA, 0.85x ROAS (poisoned by Day 1 RM1K spike)
- **Never use ROAS bidding on new campaigns. Need 50+ conversions/week first.**

### Bid Cap — WORKS BUT RESTRICTIVE
- Pinxin ZEN (Bid Cap RM80): RM50 CPA, 2.58x ROAS, 3.0% click-to-purchase
- Problem: barely spends (RM50 in 4 days) because cap is too tight during learning
- Good for controlling max CPA, bad for scaling volume

### Cost Cap — BEST FOR SCALING (consensus across experts)
- 90% of marketers report Cost Cap outperforms Bid Cap
- Gives Meta flexibility to find conversions at AVERAGE target (not hard ceiling)
- Recommended: Set at actual CPA + 20% (not aspirational number)

### Lowest Cost — BEST FOR LEARNING PHASE
- No caps, no floors — maximum freedom for algorithm to learn
- Use for first 2 weeks until 50+ conversions
- Then graduate to Cost Cap

### Recommended Progression
1. **Week 1-2**: Lowest Cost (learn)
2. **Week 3-4**: Cost Cap at actual CPA + 20%
3. **Month 2+**: Test Min ROAS (only if 50+ conversions/week)

---

## Campaign Structure (2026 Expert Consensus)

| Expert | Recommendation |
|---|---|
| Ben Heath ($150M spend) | 2 campaigns: 80% Scale + 20% Test |
| Charley T ($1B managed) | 1 campaign. Simple = scalable |
| Nick Theriot ($100M revenue) | Creative is the lever, not structure |
| Meta Official | ASC delivers 4.52x vs 3.70x manual (22% lift) |

### What Works for Malaysian Market
- CBO (Campaign Budget Optimization) for prospecting
- ABO for testing new creatives (equal budget per ad)
- Advantage+ Shopping (ASC) for scaling — test at Month 2
- CTWA uses SALES objective (not ENGAGEMENT) for WhatsApp-dominant markets

---

## CTWA (Click-to-WhatsApp) Critical Learnings

### SALES vs ENGAGEMENT Objective
- **SALES objective** (old Pinxin WA campaign): RM10-15/conversation, high conversion
- **ENGAGEMENT objective** (new CTWA campaign): RM380/conversation, terrible
- WHY: SALES optimizes for BUYERS (using pixel data). ENGAGEMENT finds CHATTERS.
- **For WhatsApp-dominant markets (Malaysia), always use SALES objective even for WA ads**

### 72-Hour Free Messaging
- Since July 2025, all messages within 72 hours of CTWA click are FREE
- Sales team must close within this window
- Track with: Ala Carte Flow template → autofill "我想要看MENU"

### Attribution Gap
- Meta pixel CAN'T track WhatsApp conversions
- Need CAPI integration (Chatwoot → CAPI) to feed WA purchases back to Meta
- Without this, algorithm is blind to 71% of revenue (WhatsApp orders)

---

## Creative Strategy (2026 Data-Backed)

### Andromeda Algorithm
- Groups visually similar ads into ONE Entity ID
- 35 similar ads = 1 auction ticket. 10 distinct concepts = 10 tickets.
- **Creative diversity >> creative volume**

### Optimal Volume
- 10-15 conceptually distinct ads per ad set (not 35 variations)
- Weekly refresh: launch 3-5 new Monday, kill losers Friday
- Creative fatigue = CTR drops 20% from peak over 3-day window

### What Converts (Pinxin Data)
- "Format hijack" ads CRUSH standard food ads
- Receipt format: RM22 CPA (best performer)
- Boarding pass format: RM34 CPA
- Collection/product showcase: RM72 CPA
- Pure food hero photos: RM86+, 0 purchases (people look but don't buy)

### Kill/Scale Rules
| When | Kill if... | Scale if... |
|---|---|---|
| 48 hours | CTR < 0.5% | — |
| Day 4 | RM100+ spend, 0 purchases | — |
| Day 7 | Bottom 50% by CPA | CPA < target → +20% budget |
| Day 14 | CPA > 1.5x target | ROAS > 3x → +20% every 48h |

---

## Malaysian Market Specifics

- CPM: RM14-20 (75% cheaper than US)
- Chinese targeting: locales [20, 21, 22]
- Exclude East Malaysia: Sarawak (2546), Labuan (2550), Sabah (2551)
- WhatsApp = 71% of revenue for food brands
- Raya holiday: CPMs DROP (Malay advertisers pull back), Chinese audience still active
- Payday cycles affect conversion rates

---

## Production Pipeline Rules (Hard Lessons)

1. ALL text = NANO (AI). PIL = resize + logo + grain ONLY
2. References MUST be 9:16 before sending to NANO
3. NEVER crop NANO output — blur-extend pad only
4. Food photos are SACRED — never AI-generated
5. Single NANO pass only — multi-pass compounds errors
6. Post-process chain: resize(1080x1920, blur-pad) → logo → grain(0.028)
7. Same dish + different plate = visual variety without changing food
8. Format-specific references provide STRUCTURE, food cutouts provide CONTENT
