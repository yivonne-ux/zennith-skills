# Meta Ads Bidding Strategies & Testing Frameworks — Deep Research 2026

> For Mirra (meal subscription, Malaysia, CTWA/WhatsApp campaigns)
> Researched: 2026-03-21

---

## 1. BIDDING STRATEGIES: Cost Cap vs Bid Cap vs Lowest Cost vs ROAS Target

### Decision Matrix

| Strategy | Control Level | Best For | Risk | Volume |
|---|---|---|---|---|
| **Lowest Cost** (default) | None | Learning phase, new campaigns, unknown CPA | CPA creep | Highest |
| **Cost Cap** | Medium (avg CPA) | Scaling with cost guardrails | Under-delivery if cap too tight | High |
| **Bid Cap** | Strict (per-auction max) | Precise cost control, short bursts, flash sales | Severely limited delivery | Low-Medium |
| **ROAS Target** (Min ROAS) | Medium (return floor) | E-commerce/subscription with purchase data | Stops delivery if target unrealistic | Medium |

### When to Use Each

**LOWEST COST (Highest Volume)**
- Use when: launching new campaigns, exploring new audiences, no CPA baseline yet
- How it works: Meta spends full budget, maximizes conversions regardless of cost
- Risk: costs creep up silently — requires daily monitoring
- Best for Mirra: first 2-4 weeks of any new campaign to establish CPA baseline

**COST CAP**
- Use when: you have 50-100+ conversions of data and know your target CPA
- How it works: Meta keeps AVERAGE CPA at or below your target; individual conversions may cost more
- How to set the value:
  - Run Lowest Cost for 2+ weeks, get 50-100 conversions
  - Find your average CPA over last 7-14 days
  - Set Cost Cap 10-20% ABOVE that average (NOT at the average)
  - Example: if avg CPA = RM40, set Cost Cap at RM44-48
  - If your best ad converts at RM35 but average is RM50, set cap at RM40
- Transition strategy: start Lowest Cost -> gather data -> switch to Cost Cap
- Best for Mirra: scaling CTWA campaigns with known conversation cost

**BID CAP**
- Use when: you need absolute cost control, short-term promotions, auction competition is predictable
- How it works: hard ceiling per auction — Meta will NOT bid above this amount
- Risk: if cap is too aggressive, delivery drops to near-zero
- Requires frequent manual adjustment
- More "hands-off once working" because Meta won't overspend, but can severely limit volume
- Best for Mirra: Raya flash sales, limited-time promos where CPA must stay under X

**ROAS TARGET (Minimum ROAS)**
- Introduced late 2025 — sets a minimum ROAS threshold Meta must respect
- Requirements: functional Meta Pixel/SDK, purchase event tracking, value optimization eligible
- How to set:
  - Check account's average ROAS over prior 30 days
  - Set target 20-30% BELOW that average (conservative start)
  - Example: if historical ROAS = 4.0x, start with target of 2.5-3.0x
  - NEVER set aspirational targets — anchor in proven performance
- If target too high: delivery stops, budget unspent
- Expect ROAS fluctuations during learning phase
- Best for Mirra: when CAPI is fully connected and purchase data flows back

### Progression Strategy (Mirra-Specific)

```
Week 1-2:  Lowest Cost (establish baseline CPA)
Week 3-4:  Cost Cap at baseline + 15% (control costs, maintain volume)
Week 5+:   Cost Cap optimized OR Bid Cap for specific high-intent segments
When CAPI mature: ROAS Target for purchase-optimized campaigns
```

### Key Formula

```
Daily Budget per Ad Set = (Target CPA x 50) / 7
Example: RM40 CPA target = (40 x 50) / 7 = RM286/day minimum per ad set
```

---

## 2. CBO vs ABO in 2026

### The Andromeda-Era Consensus

**ABO is where you LEARN. CBO is where you EARN.**

With Meta's Andromeda algorithm, this is no longer either/or — it's a two-campaign system.

### ABO (Ad Set Budget Optimization)

- **Use for:** testing new creatives, new audiences, new concepts
- **Why:** forces equal spend across all ad sets, preventing premature algorithm bias
- **How:** set identical budgets per ad set so every concept gets equal data
- **When to use:** you have 5 creative concepts and need genuine performance data on ALL 5
- **Advantage:** only way to guarantee fair testing — algorithm can't "pick favorites" too early

### CBO (Campaign Budget Optimization / Advantage Campaign Budget)

- **Use for:** scaling proven winners
- **Why:** Meta's algorithm allocates budget to highest-performing ad sets in real-time
- **How:** set one campaign budget, let Meta distribute across ad sets
- **When to use:** after ABO testing identifies winners, move them to CBO to scale
- **Advantage:** hands budget allocation to algorithm, concentrates spend on high performers

### The Hybrid Structure for Mirra

```
CAMPAIGN 1: TESTING (ABO)
├── Ad Set A: Concept 1 (RM50/day)
├── Ad Set B: Concept 2 (RM50/day)
├── Ad Set C: Concept 3 (RM50/day)
├── Ad Set D: Concept 4 (RM50/day)
└── Ad Set E: Concept 5 (RM50/day)
    Budget: RM250/day total, equal distribution

CAMPAIGN 2: SCALING (CBO)
├── Ad Set: Winner from Concept 1
├── Ad Set: Winner from Concept 3
└── Ad Set: Winner from Concept 5
    Budget: RM750/day, Meta distributes
```

### Key Decision Rules

| Signal | Action |
|---|---|
| New creative/concept to test | ABO testing campaign |
| Winner identified (CPA < target for 5+ days) | Graduate to CBO scaling campaign |
| CBO ad set dying (CPA > 2x target for 3 days) | Kill in CBO, do NOT move back to ABO |
| Need audience comparison | ABO (forces equal spend per audience) |
| Proven creative, broad audience | CBO (let algorithm find best pockets) |

---

## 3. CREATIVE TESTING FRAMEWORKS (2026)

### DCT is Dead — What Replaces It

Dynamic Creative Testing (DCT) was deprecated for Sales and App Promotion campaigns in June 2024. Replaced by **Flexible Ads**.

### Flexible Ads (DCT Replacement)

- Works at INDIVIDUAL AD level (not ad set level like DCT)
- Upload multiple images, videos, headlines, text — Meta auto-combines
- Supports up to 3 creative groups per ad
- **Limitation:** only one CTA per ad (can't test CTAs within Flexible)
- **Limitation:** "Breakdown by Dynamic Creative Element" doesn't work reliably
- Setup: Ad Setup > Manual Upload > Ad Format: Flexible
- Allow 7-14 days for initial optimization
- Best formats: 1080x1080 (square) and 1080x1920 (9:16 vertical)

### The 3-3-3 Framework (Pilothouse)

Organize testing into 3 dimensions x 3 options = 27 possible combinations:

```
Dimension 1: MESSAGE (3 angles)
├── Weight loss / body transformation
├── Convenience / time saving
└── Taste / variety / no boring diet

Dimension 2: FORMAT (3 types)
├── Static image
├── Video (UGC/talking head)
└── Carousel

Dimension 3: VISUAL STYLE (3 approaches)
├── Lo-fi / UGC-native
├── Clean brand design
└── Bold text-heavy
```

Why it works: prevents creative cannibalization. Two ads with the same hook + angle compete against each other internally, driving up CPMs. Distinct positioning = Meta distributes each to ideal audience.

### The Concept-First Method (2026 Best Practice)

**Step 1: Concept Test**
- Launch 3-5 fundamentally different creative concepts
- Equal budget per concept (ABO)
- Each concept = different story/angle/emotion about product
- Winning concept = 2-5x CPA difference from losing concepts
- Run for 5-7 days minimum

**Step 2: Iteration Test**
- Take winning concept
- Create 5-10 executions within that concept
- Test: different hooks, formats, lengths, talent
- Same story, different packaging

**Step 3: Scale**
- Move top 2-3 executions to CBO scaling campaign
- Continue concept testing in ABO campaign for next wave

### Hypothesis-Driven Testing

Every test starts with a specific, measurable hypothesis:
- "UGC-style videos outperform polished brand videos for cold audiences"
- "Weight loss messaging outperforms convenience messaging for women 25-35"
- "Carousel format delivers lower CPA than single image for BOFU"

### Volume Requirements

- At high spend levels: plan for 5-10 new creative variations per week
- Meta's GEM (Generalized Engagement Model) rewards creative diversity
- One concept expressed through multiple executions (different formats, hooks, lengths)

---

## 4. KILL/SCALE CRITERIA

### Kill Decision Tree

```
Has the ad spent at least 1x Target CPA?
├── NO → Keep running (insufficient data)
└── YES → Check CPA vs Target
    ├── CPA < Target → WINNER (move to scale)
    ├── CPA within 1.0-1.3x Target → WATCH (iterate)
    └── CPA > 1.5x Target → Check secondary metrics
        ├── Good CTR + bad conversion → landing page / offer issue
        ├── Bad CTR + bad conversion → creative is dead → KILL
        └── Low impressions → audience too narrow → expand
```

### Specific Thresholds

| Metric | Kill Signal | Watch Signal | Scale Signal |
|---|---|---|---|
| CPA vs target | > 1.5x for 3+ days | 1.0-1.3x target | < target for 5+ days |
| Spend without conversion | > 2x target CPA spent, 0 conversions | 1x CPA spent, 0 conversions | N/A |
| Frequency (cold) | > 3.0 | > 2.5 | 1.0-2.0 |
| Frequency (retarget) | > 8.0 | > 5.0 | 2.0-5.0 |
| CTR (link clicks) | < 0.5% | 0.5-1.0% | > 1.5% |
| ROAS | < 1.0x for 3 days | 1.0-2.5x | > 3.0x |

### Time + Spend Minimums Before Deciding

- **Minimum spend before kill:** 1-2x target CPA (e.g., if target CPA = RM40, don't kill before RM40-80 spent)
- **Minimum time:** 3-5 days (covers weekday/weekend variance)
- **For statistical significance:** $200-300 per variation, 5-7 days
- **For real confidence:** 50-100 conversions per variant

### Automated Rules (Set in Ads Manager)

```
RULE: AUTO-KILL
IF ad spend last 7 days > RM[2x CPA target]
AND CPA last 3 days > RM[1.5x CPA target]
AND frequency > 3.0
THEN pause ad

RULE: BUDGET-DROP
IF CPA last 2 days > RM[1.3x CPA target]
AND CPA previous 5 days was < RM[target]
THEN reduce daily budget by 20%

RULE: AUTO-SCALE
IF CPA last 3 days < RM[0.8x CPA target]
AND conversions last 3 days > 10
THEN increase daily budget by 15%
```

### E-Commerce / Subscription Rule

If ad doesn't get at least 1 purchase/conversion after spending 1x AOV (Average Order Value), and secondary metrics (ATC, initiate checkout) aren't promising, kill it.

For Mirra: if no WhatsApp conversation started after spending 1x cost of a typical meal plan (RM200-400), investigate. After 2x with zero conversions, kill.

---

## 5. BUDGET SCALING METHODS

### Vertical Scaling (Increase Budget on Existing)

**The 20% Rule:**
- Increase daily budget by maximum 15-20% every 48-72 hours
- Gives Meta's AI time to stabilize and find new buyer pockets
- Keeps CPA relatively flat while volume grows
- Going beyond 20% risks resetting learning phase

**Example progression:**
```
Day 1:   RM300/day
Day 4:   RM360/day (+20%)
Day 7:   RM432/day (+20%)
Day 10:  RM518/day (+20%)
Day 13:  RM622/day (+20%)
Day 16:  RM746/day (+20%)
→ 2.5x budget in 16 days without learning phase reset
```

**When CPA spikes after increase:**
- Drop budget back to the last level where CPA was within target
- Wait 48 hours, try again with smaller increment (10%)

### Horizontal Scaling (Duplicate + Expand)

**Method:**
1. Duplicate best-performing ad set
2. Change ONE variable (usually targeting)
3. Each duplication tests one variable only

**Critical rule:** Always exclude audiences between duplicated ad sets to prevent overlap. Anything above 25% audience overlap = internal competition, CPMs spike.

**Variables to change per duplication:**
- Different interest targeting
- Different lookalike source/size
- Different age range
- Different geo (KL vs Selangor vs Penang)
- Different placement (Feed vs Stories vs Reels)

### Combined Strategy for Mirra

```
PHASE 1: Vertical (Week 1-2)
- Scale winning ad sets by 15-20% every 72 hours
- Monitor CPA daily

PHASE 2: Horizontal (Week 3+)
- Duplicate winners with new targeting angles
- Exclude audiences between ad sets
- Each clone gets same budget as original

PHASE 3: New Campaign Expansion
- Launch new CBO campaign with proven creatives
- Broader targeting than original
- Fresh campaign = clean learning phase
```

### Creative Refresh Rate at Scale

| Daily Spend | New Creatives/Week |
|---|---|
| < RM500 | 2-3 |
| RM500-2,000 | 5-7 |
| RM2,000-5,000 | 8-12 |
| RM5,000+ | 15+ |

---

## 6. A/B TESTING IN ADS MANAGER (2026)

### How Meta's Native A/B Test Works

- Automatically splits audiences so same person CANNOT see both variants
- Uses Meta's Experiments tool for statistical significance determination
- Tests one variable at a time: creative, audience, placement, or delivery optimization

### Minimum Budget & Duration

| Conversion Type | Min Budget/Variant | Min Duration | Ideal Duration |
|---|---|---|---|
| Low-ticket e-comm | $10-20/day | 3-5 days | 7 days |
| High-ticket / subscription | $30-50/day | 7-14 days | 14 days |
| B2B lead gen | $50-100/day | 14-21 days | 21 days |
| CTWA (Mirra) | RM30-50/day | 7 days | 14 days |

### Statistical Significance

- **Meta default:** 90% confidence (faster results, less precise)
- **Best practice:** 95% confidence (more reliable for long-term decisions)
- **Minimum conversions per variant:** 25-50 for trends, 100+ for real significance
- **Total budget planning:** RM500-2,500 for basic creative tests

### Common Mistakes

- Declaring winner after 3 days and $500 — almost certainly noise
- Testing multiple variables simultaneously — impossible to pinpoint driver
- Killing test early because one variant is "obviously winning" at 20% better CPA — could be random variance

### Budget Formula for A/B Tests

```
Minimum test budget = Target CPA x 50 conversions x 2 variants
Example: RM40 CPA x 50 x 2 = RM4,000 total test budget
Duration: RM4,000 / RM300/day = ~13 days
```

---

## 7. AUDIENCE TESTING (2026)

### The Landscape Has Shifted

- Broad targeting + Advantage+ is now default for 65% of US advertisers
- Interest-based targeting is increasingly unreliable (data deprecation)
- First-party signals are the new targeting currency

### Advantage+ Audience

- You provide "audience suggestions" (age, location, interests) as STARTING HINTS
- Meta treats them as signals, then expands beyond if it finds better-performing pockets
- Meta's internal benchmarks: CPA down 32%, CTR up 11-15%, CPC down 5-10%
- Best when: you have strong creative and trust the algorithm

### Broad Targeting

- No interest/behavior targeting, just demographics (age, gender, location)
- Works best with: large budgets, strong creative, mature pixel data
- Let Meta's billions of data points find converters you'd never target manually

### Custom Audience Signals (First-Party Data)

- Website visitors (pixel-based)
- Customer lists (email/phone upload)
- Engagement audiences (IG/FB interactions)
- WhatsApp conversation starters (CTWA-specific)
- Video viewers (25%, 50%, 75%, 95% thresholds)

### Audience Testing Framework for Mirra

```
TEST CAMPAIGN (ABO, equal budgets):
├── Ad Set 1: Advantage+ (broad, audience suggestions only)
├── Ad Set 2: Broad (KL/Selangor, Women 25-45, no interests)
├── Ad Set 3: Interest Stack (health, fitness, meal prep, weight loss)
├── Ad Set 4: Lookalike 1% (based on purchasers/subscribers)
├── Ad Set 5: Lookalike 3-5% (broader lookalike)
└── Ad Set 6: Engagement Custom Audience (IG + FB engagers)
```

### 2026 Best Practice

Feed the algorithm high-quality first-party signals:
- Clean customer lists (email + phone)
- Site visitors with purchase intent signals
- WhatsApp conversation completers
- High-value purchaser lookalikes

---

## 8. ATTRIBUTION SETTINGS (2026)

### Major Changes in 2026

**January 2026 — Post-View Attribution Reduced:**
- Post-view conversion metrics now limited to 1-day view only
- Previously could measure longer view-through windows
- Impact: ~30-40% of conversions that happened 2+ days after viewing are now invisible

**March 2026 — Click-Through Redefined:**
- Old: any click on ad (including social clicks, reactions) counted as "click-through"
- New: only actual LINK CLICKS count as click-through attribution
- Everything else moved to new "engage-through" category
- Impact: reported click-through conversions may appear to drop

### Default Attribution Settings

```
Standard: 7-day click + 1-day view + 1-day engage-through
```

### CTWA/WhatsApp Campaign Attribution

**The Attribution Gap:**
- Meta Pixel CANNOT track what happens inside WhatsApp
- You need CAPI (Conversions API) via WhatsApp Business API provider
- Providers: Respond.io, Wati, AiSensy, Infobip (all support CAPI)

**Recommended settings for Mirra CTWA:**

| Setting | Value | Why |
|---|---|---|
| Attribution window | 7-day click | WhatsApp conversations often convert 1-3 days after initial click |
| View-through | 1-day view (default, can't change) | Limited value for CTWA |
| Engage-through | 1-day engage | New in March 2026 |
| CAPI integration | Required | Only way to close attribution loop |

**Attribution model:** Last Click (default for CTWA)

### CAPI Setup for CTWA (Critical)

```
Customer journey tracked via CAPI:
1. Ad click → WhatsApp conversation started (tracked by Meta)
2. Conversation → Lead qualified (send via CAPI)
3. Lead → Purchase/subscription (send via CAPI)
4. Purchase value sent back → enables ROAS optimization
```

Without CAPI, Meta only sees step 1. With CAPI, Meta can optimize for actual purchases, not just conversations.

---

## 9. FREQUENCY MANAGEMENT

### Optimal Frequency Ranges

| Audience Type | Optimal Frequency | Warning | Kill |
|---|---|---|---|
| Cold (prospecting) | 1.0-2.0 | 2.5 | 3.0+ |
| Warm (site visitors, engagers) | 2.0-5.0 | 5.0 | 8.0+ |
| Hot (cart abandoners, past buyers) | 3.0-7.0 | 7.0 | 12.0+ |
| Retargeting (CTWA re-engage) | 2.0-4.0 | 4.0 | 6.0+ |

### Meta's Own Data

- Optimal ad frequency: 1-2 for cold audiences
- Tipping point: 3.4 — after this, ad loses effectiveness
- For audiences under 100K: start planning refresh at frequency 2.0 (performance drops by 2.5)

### Creative Refresh Triggers

| Signal | Action |
|---|---|
| Frequency hits 2.5-3.0 (cold) | Refresh creative regardless of timeline |
| CPM increasing + CTR declining | Creative fatigue — new ads needed |
| CPA rising for 3+ consecutive days | Test new hooks/visuals |
| Same creative running 14+ days | Proactively prepare replacement |

### Creative Rotation Strategy

- Never run just one ad — use multiple creatives showcasing different benefits
- Rotate: testimonials, product features, lifestyle, pain points, social proof
- For retargeting: segment by intent level
  - Homepage visitor → lower frequency, educational content
  - Cart abandoner → higher frequency for 2-3 days, urgency messaging

### Mirra-Specific Frequency Plan

```
COLD (new audience):
- 4-6 creatives per ad set
- Cap frequency at 2.5 via weekly monitoring
- Refresh creative every 10-14 days

WARM (IG engagers, site visitors):
- 3-4 creatives per ad set
- Allow frequency up to 5.0
- Refresh every 7-10 days

HOT (WhatsApp starters who didn't convert):
- 2-3 creatives per ad set
- Allow frequency up to 7.0
- Show urgency/scarcity messaging
- 3-5 day retarget window
```

---

## 10. CAMPAIGN CONSOLIDATION

### The 2026 Consolidation Principle

**"2 campaigns scale better than 20."**

Fewer, better-funded ad sets almost always outperform many under-funded ones in Meta's current delivery environment.

### When to Consolidate (Merge)

| Signal | Action |
|---|---|
| Ad set gets < 50 conversion events/week | Merge with similar ad set |
| Audience overlap > 25% between ad sets | Consolidate or exclude |
| Multiple campaigns targeting same funnel stage | Merge into one campaign |
| CBO campaign with 8+ ad sets where 2 get all spend | Remove bottom performers |
| Learning phase "limited" for 7+ days | Consolidate to concentrate signal |

### When to Separate

| Signal | Action |
|---|---|
| Different funnel stages (TOFU vs BOFU) | Separate campaigns |
| Different optimization events (conversations vs purchases) | Separate campaigns |
| Different bid strategies needed | Separate campaigns |
| Testing vs scaling | Always separate campaigns |
| Different languages (EN vs CN) | Can be same campaign, different ad sets |

### Optimal Account Structure (2026)

```
THE TWO-CAMPAIGN SYSTEM:

CAMPAIGN 1: CREATIVE TESTING (ABO)
├── Modest budget
├── Equal spend per ad set
├── New concepts tested here
├── Kill losers, graduate winners
└── Optimization: Conversations (CTWA)

CAMPAIGN 2: SCALING WINNERS (CBO)
├── Larger budget (70-80% of total)
├── Meta distributes to best performers
├── Only proven winners from Campaign 1
├── Broad targeting / Advantage+
└── Optimization: Conversations (CTWA)

OPTIONAL CAMPAIGN 3: RETARGETING
├── Separate from prospecting
├── Custom audiences (warm/hot)
├── Lower budget (10-15% of total)
└── Different messaging (urgency, social proof)
```

### Consolidation Rules

- **50 events/week threshold:** each ad set needs a realistic path to 50 conversions/week
- **Budget formula:** (50 x CPA) / 7 = minimum daily budget per ad set
- **Overlap check:** use Meta's Audience Overlap tool monthly — anything >25% needs action
- **Don't consolidate mid-flight:** merging active ad sets resets learning phase
- **Apply to NEW campaigns:** let existing campaigns run to natural conclusion, restructure on relaunch

### Mirra Account Architecture

```
Current: RM1,500/day across campaigns

RECOMMENDED STRUCTURE:
├── MIRRA-TEST-EN (ABO): RM200/day
│   └── 4-5 ad sets testing new EN concepts
├── MIRRA-TEST-CN (ABO): RM150/day
│   └── 3-4 ad sets testing new CN concepts
├── MIRRA-SCALE-EN (CBO): RM600/day
│   └── 3-4 ad sets with proven EN winners
├── MIRRA-SCALE-CN (CBO): RM400/day
│   └── 2-3 ad sets with proven CN winners
└── MIRRA-RETARGET (CBO): RM150/day
    ├── HOT: WhatsApp starters, no purchase
    ├── WARM: Site visitors, IG engagers
    └── COOL: Video viewers 50%+
```

---

## APPENDIX A: Quick-Reference Decision Trees

### Bidding Strategy Decision Tree

```
Do you have 50+ conversions of historical data?
├── NO → Use Lowest Cost (gather baseline)
└── YES → Is CPA predictability important?
    ├── NO → Stay with Lowest Cost (max volume)
    └── YES → Do you need strict per-auction control?
        ├── YES → Bid Cap (set at your max acceptable per-auction bid)
        └── NO → Cost Cap (set at avg CPA + 15%)
            └── Have CAPI purchase data flowing?
                └── YES → Consider ROAS Target (set at historical avg - 25%)
```

### Creative Testing Decision Tree

```
New concept to test?
├── YES → ABO testing campaign, equal budgets
│   └── Run 5-7 days, minimum 1x CPA spend per ad
│       ├── CPA < target for 3+ days → Graduate to CBO
│       ├── CPA 1.0-1.3x target → Iterate (new hook/format)
│       └── CPA > 1.5x target → Kill, analyze why
└── NO → Iterating on proven concept?
    └── YES → Test in ABO: new hooks, formats, lengths
        └── Winner → Add to CBO scaling campaign
```

### Scale Decision Tree

```
Ad performing well (CPA < target, 5+ days)?
├── Vertical first: increase budget 15-20% every 72 hours
│   ├── CPA stable after increase → Continue vertical
│   └── CPA spiked → Roll back, wait 48h, try 10%
├── Horizontal: duplicate ad set, change targeting
│   └── Exclude audiences between duplicates
└── New campaign: fresh CBO with proven creatives + broad targeting
```

---

## APPENDIX B: Key Numbers Cheat Sheet

| Metric | Number | Context |
|---|---|---|
| Learning phase threshold | 50 events/week/ad set | Below this = "Learning Limited" |
| Budget increase max | 15-20% per 72 hours | Exceeding risks learning phase reset |
| Min test spend per variant | 1-2x target CPA | Before any kill decision |
| Min test duration | 5-7 days | Covers weekday/weekend variance |
| A/B test confidence | 95% (Meta defaults 90%) | 95% = reliable long-term decisions |
| Audience overlap threshold | 25% max | Above = consolidate or exclude |
| Cold frequency kill | 3.0+ | Creative is burnt |
| Creative refresh cycle | 10-14 days (cold) | Prepare new creative proactively |
| New creatives at RM1,500/day | 5-7 per week | To sustain performance |
| Cost Cap setting | Avg CPA + 10-20% | NOT at average, slightly above |
| ROAS target setting | Historical avg - 20-30% | Conservative, not aspirational |
| Daily budget per ad set | 5-7x target CPA | To exit learning phase |
| Advantage+ CPA improvement | Up to 32% | Meta's internal benchmarks |
| Attribution (2026) | 7-day click + 1-day view | View window reduced from longer periods |

---

## APPENDIX C: Mirra CTWA-Specific Playbook

### Campaign Optimization Event
- Optimize for: **Conversations** (not link clicks, not impressions)
- This enables Meta to find users most likely to start a WhatsApp chat

### Budget Rule of Thumb
- Daily budget = 10x average cost per conversation
- If avg cost/conversation = RM10, daily budget = RM100 minimum
- Campaign duration: 7+ days minimum for stable results

### Creative Best Practices for CTWA
- Lead with ONE benefit (not multiple)
- Show WhatsApp visual cues in creative
- Test CTAs: "Chat now", "Get help instantly", "Order via WhatsApp"
- Show outcome, not just product (happy person eating, not just food box)
- UGC and mobile-first formats outperform polished brand creative
- Pre-filled quick replies speed qualification

### Targeting for Malaysian Market
- Broad targeting: 2-10 million audience size
- Advantage+ with location signal (KL/Selangor)
- CPC in Malaysia ~75% cheaper than US benchmarks

### Attribution Setup Checklist
- [ ] CAPI connected via WhatsApp Business API provider (Respond.io)
- [ ] Purchase events sent back to Meta via CAPI
- [ ] Attribution window: 7-day click
- [ ] Customer journey mapped: Ad click → WA conversation → Lead → Purchase
- [ ] Value optimization enabled (for ROAS bidding)

---

*Sources compiled from: AdAmigo, Foxwell Digital, Pilothouse, Jon Loomer Digital, Meta Business Help Center, Weboin, Spinta Digital, Two Owls, BigFlare, TheOptimizer, AdStellar, Dancing Chicken, Anchour, VibeMyAd, Scalability School, Motion, Metricool, WeTracked, Madgicx, ROASPIG, AdRow, Infobip, TBit, Twilio, Gallabox, Improvado, Kommo, F22 Labs, Benly AI, 1ClickReport, GeistM, Oboe, Rubin George, Metalla Digital, Flighted, RebootIQ, Seer Interactive, CropInk, DataSlayer, Jetfuel Agency, Gradezilla, Five Nine Strategy, AdsUploader*
