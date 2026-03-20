---
name: Creative Intelligence — Meta Ads Engine (universal)
description: Brand-agnostic Meta Ads audit, diagnosis, campaign architecture, optimization, retargeting, budget scaling, language segmentation, and kill/scale rules. Part of the Creative Intelligence OS. Never hardcoded to one brand.
type: feedback
---

# Creative Intelligence — Meta Ads Engine

Universal. Brand-agnostic. Applies to ANY brand running Meta ads with WhatsApp/CTWA or website conversion.

---

## 1. ACCOUNT AUDIT — Pull via Graph API

### What to pull (3 layers):

```
Layer 1: CAMPAIGNS
- name, objective, bid_strategy, daily_budget, status
- insights: spend, impressions, clicks, ctr, cpc, cpm, actions
- Group by: objective type, language, funnel stage

Layer 2: AD SETS
- name, campaign_id, optimization_goal, destination_type
- targeting: age_min/max, genders, geo_locations, flexible_spec (interests), custom_audiences, excluded_custom_audiences
- promoted_object (page_id, whatsapp_phone_number, pixel_id)
- insights: spend, reach, frequency, ctr, cpc, cpm, actions

Layer 3: ADS
- name, status, creative (title, body, thumbnail_url)
- insights: spend, impressions, clicks, ctr, cpc, cpm, reach, frequency, actions
- Sort by: spend desc, cost_per_result asc
```

### API pattern:
```python
# Always use .get() for optional fields — Meta omits fields with zero values
cpc = float(insight.get('cpc', 0))
cpm = float(insight.get('cpm', 0))
frequency = float(insight.get('frequency', 0))

# WhatsApp conversation actions:
for a in insight.get('actions', []):
    if a['action_type'] in (
        'onsite_conversion.messaging_conversation_started_7d',
        'onsite_conversion.messaging_first_reply'
    ):
        wa_messages = int(a.get('value', 0))
```

### Token: Graph API Explorer → short-lived (~1 hour). Always handle expiry gracefully.

---

## 2. DIAGNOSIS FRAMEWORK — 10-point health check

Run these checks on every account audit:

| # | Check | Red flag | Fix |
|---|---|---|---|
| 1 | **Objective consistency** | Mixed SALES + ENGAGEMENT on same funnel stage | One objective per funnel stage. ENGAGEMENT if no CAPI. |
| 2 | **CAPI status** | No server-side tracking = blind optimization | Priority #1 blocker. SALES objective without CAPI = wasted learning. |
| 3 | **Creative volume** | >50 active ads OR <10 active ads | 15-30 active ads ideal. Kill zombies. |
| 4 | **Budget distribution** | >30% on retarget OR starving ad sets (<$2/day) | 15% test, 50% scale, 25% ASC, 10% retarget |
| 5 | **Frequency** | Any ad set >2.0 frequency in <14 days | Audience too small for budget, or creative fatigued |
| 6 | **Geo targeting** | Too narrow (3 suburbs) OR too broad (entire country) | Match brand's actual delivery/service zone |
| 7 | **Age targeting** | 18-65 (default = lazy) | Narrow to avatar's core demo ±5 years |
| 8 | **Audience exclusions** | Cold campaigns not excluding converters | Always exclude purchasers + WA converters from prospecting |
| 9 | **Naming convention** | "Copy 2", "Copy 3", emoji soup | Structured: {STAGE}-{LANG}-{CONCEPT}-{FORMAT}-{ID} |
| 10 | **Post ID reuse** | Duplicating ads instead of scaling originals | Scale via original Post ID to preserve social proof |

---

## 3. CAMPAIGN ARCHITECTURE — 4-campaign blueprint

This is the universal structure. Adapt budget percentages to brand maturity.

### New brand / no CAPI:
| Campaign | Type | Objective | Budget % | Purpose |
|---|---|---|---|---|
| TEST | ABO | ENGAGEMENT (Conversations or Traffic) | 15% | New creatives. Small budget per ad set. Kill fast. |
| SCALE | CBO | ENGAGEMENT (Conversations or Traffic) | 60% | Proven winners only. Scale via Post ID. |
| RETARGET | CBO | ENGAGEMENT (Conversations or Traffic) | 10% | Custom audiences. 3-tier (hot/warm/cold). |
| BRAND | CBO | ENGAGEMENT (Reach) | 15% | Optional. Broad awareness if brand is unknown. |

### Mature brand / CAPI live:
| Campaign | Type | Objective | Budget % | Purpose |
|---|---|---|---|---|
| TEST | ABO | SALES (Purchase) | 15% | New creatives. Kill at spend = 3× target CPA with 0 purchases. |
| SCALE | CBO | SALES (Purchase) | 50% | Proven winners. 20% budget increase every 48-72h. |
| ASC | Advantage+ Shopping | SALES (Purchase) | 25% | Flexible Ads with top 5-10 winners. Auto-targeting. |
| RETARGET | CBO | SALES (Purchase) | 10% | Tiered custom audiences. Rotate creative every 7-10 days. |

### Key rules:
- **NEVER use SALES objective without CAPI** — Meta optimizes for a signal it can't see
- **ABO for testing** — you control per-ad-set budget, prevent Meta from starving new creatives
- **CBO for scaling** — let Meta distribute to winners
- **ASC only with proven winners** — NOT a testing tool, broken per-asset reporting
- **Flexible Ads inside ASC** — 2x CVR, 3 creative groups per ad, auto-generates carousels

---

## 4. TESTING FRAMEWORK

### 3-3-3 method (industry standard — Pilothouse):
```
3 CONCEPTS × 3 HOOKS × 3 FORMATS = 27 ads per testing cycle
```

- **Concept** = the core message/angle (e.g., price, convenience, social proof)
- **Hook** = the first 0.5 seconds / first line (e.g., question, stat, pain point)
- **Format** = delivery vehicle (static, carousel, video/Reels, UGC)

### Andromeda diversity (Meta's AI ranking):
Each ad must differ in at least ONE of:
1. Message frame (emotional vs rational vs social proof)
2. Authority source (brand vs customer vs expert vs data)
3. Proof type (testimonial vs statistic vs visual demo)
4. Voice (first-person vs second-person vs third-person)
5. Visual composition (layout, color, photography style)
6. Format (static vs carousel vs Reels)

> Andromeda penalizes >60% visual similarity. "Copy 2" with different headline = NOT different enough.

### Kill criteria (universal):
| Timeframe | Kill if | Confidence |
|---|---|---|
| 24 hours | CTR < 0.5% | Low — early signal only |
| 3 days | CPA > 2× target | Medium |
| 7 days | CPA > 1.5× target AND <15 conversions | High |
| 7 days | Frequency > 3.0 | Audience exhaustion |

### Scale criteria (universal):
| Metric | Threshold | Action |
|---|---|---|
| CPA < target | + 15 conversions | Move to SCALE campaign via Post ID |
| ROAS > 2× target | 7-day sustained | Increase budget 20% every 48-72h |
| CTR > 2× account avg | + significant spend | Test in more audiences |

### Testing cadence:
- Launch new creatives: **Monday and Thursday** (avoid weekend)
- Review and kill: **Wednesday and Saturday**
- Scale decisions: **Friday** (gives full week of data)

---

## 5. LANGUAGE & MARKET SEGMENTATION

### Principles (brand-agnostic):
- **Always split by language** — separate ad sets within campaigns, not separate campaigns
- **Never assume one language dominates** — test both, let data decide budget allocation
- **Code-switching markets** (Malaysia, Singapore, Philippines, etc.) — bilingual copy outperforms pure
- **Measure cost per result by language** — not just CTR (high CTR ≠ high conversion)

### Language performance diagnosis:
```
Pull all ads → classify by language (from ad name or creative body)
→ Compare: cost/result, CTR, CPC, volume
→ If Language B has lower cost/result but <20% of budget → UNDERSPENT, scale immediately
```

### Multilingual creative rules:
- Same concept, adapted copy — NOT literal translation
- Cultural references must be native (not translated idioms)
- Visual aesthetic may differ by language audience (e.g., XHS aesthetic for Chinese, IG aesthetic for English)
- Test language × format combinations independently

---

## 6. RETARGETING — 3-tier system

### Tier structure (universal):
| Tier | Audience | Window | Budget share | Message strategy |
|---|---|---|---|---|
| **HOT** | Started conversation but didn't convert | 1-7 days | 50% of retarget | Urgency, limited offer, overcome objection |
| **WARM** | Clicked ad / visited site but didn't engage | 8-30 days | 30% of retarget | Social proof, testimonial, different angle |
| **COLD retarget** | Page/IG engagers, video viewers | 31-90 days | 20% of retarget | New concept entirely — they forgot you |

### Retargeting health rules:
- **Budget max 10% of total** — retargeting pools are small
- **Frequency cap: 2.0 per 7 days** — if exceeding, reduce budget or expand audience
- **Creative rotation every 7-10 days** — retarget audiences fatigue FAST
- **Always exclude converters** — don't pay to reach existing customers
- **Different creative than cold** — if they saw your MOFU ad and didn't convert, showing the same ad again = wasted money
- **Retarget cost/result SHOULD be lower than cold** — if it's higher, retargeting is broken

### When retarget cost > cold cost (diagnosis):
1. CAPI not connected → SALES objective optimizing blind
2. Audience too small for budget → frequency death spiral
3. Same creative as cold → no new information to convert
4. No exclusions → reaching people who already converted
5. Window too wide (365 days) → audience is stale

---

## 7. BUDGET SCALING — Gates system

### Never scale without gates. Every budget increase requires passing a threshold:

```
Phase 1: TEST (Week 1-2)
  Budget: minimum viable (enough for 50 conversions/week per ad set)
  Gate to Phase 2: CPA < 1.5× target for 7 consecutive days

Phase 2: SCALE (Week 3-4)
  Budget: 2× Phase 1
  Gate to Phase 3: ROAS > 1.5× target, 15+ conversions/week

Phase 3: ACCELERATE (Week 5-8)
  Budget: 3-5× Phase 1
  Gate to Phase 4: ROAS > 2× target, stable frequency <2.0

Phase 4: FULL THROTTLE (Week 9-12)
  Budget: 5-10× Phase 1
  Gate: ROAS > 3× blended (including LTV for subscription businesses)
```

### Scaling rules:
- **20% budget increase maximum** every 48-72 hours (avoids resetting learning phase)
- **Scale via original Post ID** — NEVER duplicate ads (splits social proof, resets learning)
- **If CPA spikes >30% after budget increase** — revert immediately, wait 48h, try smaller increase
- **Horizontal scaling** (new audiences) before vertical scaling (more budget on same audience)

---

## 8. CONVERSION TRACKING HIERARCHY

### What you can trust without CAPI:
| Metric | Trustworthy? | Use for |
|---|---|---|
| Impressions, Reach, Frequency | Yes | Audience saturation diagnosis |
| CTR (all), CPC, CPM | Yes | Creative quality signal |
| Link clicks, Landing page views | Yes | Funnel drop-off |
| WA messages started | Yes (if CTWA) | Proxy for lead quality |
| Cost per WA message | Yes (if CTWA) | Primary optimization metric |
| Purchases, ROAS | **NO** (without CAPI) | Do not optimize on these |
| Add to cart, Checkout | **NO** (without Pixel/CAPI) | Do not optimize on these |

### Without CAPI, optimize for:
1. **Cost per WA message** (CTWA campaigns)
2. **CTR** (creative quality)
3. **CPC** (audience relevance)
4. **Frequency** (fatigue management)

### With CAPI, optimize for:
1. **CPA** (cost per acquisition)
2. **ROAS** (return on ad spend)
3. **LTV:CAC ratio** (for subscription businesses)

---

## 9. WHATSAPP / CTWA SPECIFIC

### CTWA = Click-to-WhatsApp Ads:
- Destination: WhatsApp conversation (not website)
- Optimization: Conversations
- Attribution: ctwa_clid (Click ID) → arrives in first webhook → fire CAPI Purchase event
- Typically **5× lower CPA** than website conversion ads
- **45-60% CTR** on the WhatsApp button (vs 1-3% for website)

### CTWA campaign setup:
```
promoted_object: {
    page_id: "...",
    whatsapp_phone_number: "...",
    // OR whats_app_business_phone_number_id: "..."
}
destination_type: "WHATSAPP"
optimization_goal: "CONVERSATIONS"
```

### CTWA attribution stack (to solve ROAS tracking):
1. **WhatsApp Business API** (via Respond.io, WATI, or similar)
2. **ctwa_clid** captured on first message webhook
3. **CAPI Purchase event** fired when order confirmed, with ctwa_clid as event_id
4. Meta matches CAPI event → attributes purchase to specific ad

### Without CTWA attribution:
- Cost per WA message is the best proxy metric
- Track manually: WA conversations → orders → revenue (spreadsheet)
- Cannot use SALES objective effectively — use ENGAGEMENT (Conversations)

---

## 10. AD NAMING CONVENTION

### Universal format:
```
{FUNNEL}-{LANG}-{CONCEPT_SHORT}-{FORMAT}-{UNIQUE_ID}
```

### Examples:
```
MOFU-EN-LunchDeal-Carousel-a1b2c3
TOFU-CN-SocialProof-Reels-d4e5f6
BOFU-EN-LastChance-Static-g7h8i9
```

### Rules:
- NO emojis in ad names (breaks API parsing, looks unprofessional)
- NO "Copy 2", "Copy 3" — each ad gets a unique ID
- Funnel stage is clear: TOFU (awareness), MOFU (consideration), BOFU (conversion)
- Language always explicit: EN, CN, BM, etc.
- Concept is human-readable: what's the message angle
- Format: Static, Carousel, Reels, Shorts, UGC, KOL

---

## 11. CREATIVE × CAMPAIGN MAPPING

### Where each creative type lives:

| Creative type | Campaign | Why |
|---|---|---|
| New untested concepts | TEST (ABO) | Small budget, fast kill |
| Proven statics (CTR >2%) | SCALE (CBO) | Scale via Post ID |
| Proven video/Reels | SCALE (CBO) | Highest engagement format |
| Carousel (product showcase) | SCALE or ASC | 4.2× ROAS format |
| Flexible Ads (3 groups) | ASC only | 2× CVR, auto-optimizes |
| Testimonial/social proof | RETARGET | Different angle for warm audience |
| Urgency/promo offers | RETARGET (hot tier) | Convert fence-sitters |
| KOL/UGC content | TEST first → SCALE | Often best performers |

### Format performance benchmarks (global averages):
- **Carousel**: 4.2× ROAS (highest), best for product showcase
- **Reels/Shorts**: 34.5% lower CPA, highest reach
- **Static**: 60-70% of conversions by volume (scale workhorse)
- **UGC/Lo-fi**: +72% ROAS vs polished (counterintuitive but proven)

---

## 12. ACCOUNT RESTRUCTURE PLAYBOOK

### When inheriting a messy account:

```
Step 1: AUDIT (this document's framework)
  - Pull 3 layers via API
  - Run 10-point diagnosis
  - Identify top 10 ads by cost/result
  - Identify bottom 20% (kill list)

Step 2: TRIAGE (immediate, same day)
  - Pause all ads with cost/result > 2× account average
  - Pause any campaign with frequency > 2.5
  - Pause retargeting if cost/result > cold campaigns

Step 3: RESTRUCTURE (next 48h)
  - Create 4-campaign structure (TEST/SCALE/ASC/RETARGET)
  - Migrate top performers via Post ID into SCALE
  - Set proper targeting (age, geo, exclusions)
  - Implement naming convention

Step 4: LAUNCH (Week 1)
  - 3-3-3 test batch in TEST campaign
  - Monitor daily: CTR, CPC, cost/result
  - Kill at 24h (CTR), 3-day (CPA), 7-day (final)
  - Graduate winners to SCALE

Step 5: OPTIMIZE (Week 2-4)
  - Scale winners 20% every 48-72h
  - Launch new 3-3-3 batch weekly
  - Introduce ASC with Flexible Ads (Week 4, if CAPI live)
  - Retargeting creative rotation every 7-10 days
```

---

## QUICK DECISION TREE

```
New brand / account audit:
│
├─ Has CAPI?
│   ├─ YES → SALES objective, optimize for Purchase/ROAS
│   └─ NO → ENGAGEMENT objective, optimize for Conversations/CTR
│       └─ PRIORITY: Set up CAPI first (biggest single unlock)
│
├─ Has CTWA (WhatsApp)?
│   ├─ YES → Cost per WA message = primary metric
│   └─ NO → Cost per link click or landing page view
│
├─ Budget allocation:
│   └─ TEST 15% | SCALE 50-60% | ASC 25% (if CAPI) | RETARGET 10%
│
├─ Language split:
│   └─ Separate ad sets per language, WITHIN same campaign (not separate campaigns)
│   └─ Measure cost/result per language — scale the winner
│
├─ Retarget cost > cold cost?
│   └─ YES → Broken. Check: CAPI, audience size, creative, exclusions
│
├─ Frequency > 2.0 in <14 days?
│   └─ YES → Reduce budget OR expand audience OR rotate creative
│
└─ Ready to scale?
    └─ Must pass gate: CPA < target for 7 days + 15 conversions minimum
    └─ Scale via Post ID, 20% every 48-72h, NEVER duplicate
```
