# PINXIN VEGAN — Meta Ads Strategy 2026
## Forensic-Level Deployment Plan for 50 Creatives

> Generated: March 16, 2026
> Based on: 14-day account data, WhatsApp sales history, 15 web research sources, Meta 2026 algorithm intelligence
> Account: act_138893238421035

---

## EXECUTIVE DIAGNOSIS

### Current State (Critical Issues)

| Metric | Current | Benchmark (F&B SEA) | Status |
|--------|---------|---------------------|--------|
| Frequency | 4.05 | <2.5 prospecting / <5.0 retargeting | CRISIS — creative fatigue |
| CTR | 1.78% | 1.5-2.0% | Acceptable but declining |
| CPC | RM0.99 | RM0.60-0.90 MY | Elevated (fatigue tax) |
| CPM | RM17.68 | RM12-16 MY | High — audience saturation |
| Daily Spend | RM1,365 | — | Underleveraged for 50 creatives |
| Website Purchases | 175 (14d) | — | 12.5/day |
| WA Conversations | 418 (14d) | — | 29.9/day |
| WA First Reply | 243 (14d) | — | 58% reply rate (good) |
| Add to Cart | 1,436 (14d) | — | 102.6/day (strong intent signal) |

### Revenue Trajectory (DECLINING)

| Month | Revenue | Orders | AOV | Trend |
|-------|---------|--------|-----|-------|
| Jan 2026 | RM307,853 | 744 | RM414 | CNY peak |
| Feb 2026 | RM70,879 | 166 | RM427 | Post-CNY crash |
| Mar 2026 (16d) | RM12,640 | 66 | RM192 | ALARMING — AOV halved, volume down 60% |

**Root cause**: Post-CNY demand cliff + creative fatigue (freq 4.05) + stale campaigns + AOV collapse (no bundle push).

---

## ANSWER 1: Advantage+ Sales vs Standard CBO

### Verdict: HYBRID — Use Both With Specific Roles

**Do NOT go all-in on Advantage+ Sales (ASC).** Research shows ASC outperforms CBO in only ~20% of cases. For your account specifically:

**Campaign 1 — ASC for Website Purchases (NEW)**
- Role: Broad prospecting + purchase optimization with 50 new creatives
- Why ASC here: You have CAPI connected, strong purchase volume (12.5/day), and 50 diverse creatives — exactly what ASC needs
- ASC delivers average 22% ROAS lift when fed diverse creative + clean conversion data
- Budget: RM800/day (starting)

**Campaign 2 — Standard CBO for CTWA/WhatsApp (NEW)**
- Role: WhatsApp conversation optimization
- Why CBO here: ASC does NOT support Engagement/Conversations objective. CTWA requires Engagement objective optimized for Conversations
- Budget: RM600/day (starting)

**Campaign 3 — Standard CBO for Retargeting (NEW)**
- Role: Cart abandoners + website visitors + WA non-converters
- Why CBO here: Retargeting needs specific audience control that ASC automates away
- Budget: RM200/day (starting)

### Action: OLD Campaigns
- **CBO-FrozenMY-CN-WhatsApp (RM240/day)**: PAUSE after new CTWA campaign exits learning phase (7-10 days)
- **CBO-FrozenMY-CN-Broad-Website-Troas**: PAUSE immediately — RM500K budget with min ROAS bid at frequency 4.05 = burning money on fatigued audience
- **CBO-FrozenMY-CN-Broad-Website-zen**: PAUSE immediately — same issue

**Do not kill old campaigns abruptly.** Reduce old campaign budgets by 50% on Day 1, another 50% on Day 4, pause on Day 7 (after new campaigns exit learning phase).

---

## ANSWER 2: WhatsApp vs Website — Separate or Same Campaign?

### Verdict: ALWAYS SEPARATE CAMPAIGNS

They must be separate because:

1. **Different optimization objectives**: Website = Sales/Purchase optimization. WhatsApp = Engagement/Conversations optimization. Meta optimizes for ONE objective per campaign.
2. **Different attribution**: Website purchases track via Pixel + CAPI. WhatsApp conversions require CAPI from your WA Business API provider (Wati/Respond.io/etc).
3. **Different bid strategies**: Website can use min ROAS bid. WhatsApp should use Cost Cap or Lowest Cost.
4. **Different creative formats work**: Website ads need landing page alignment. CTWA ads need conversation-starter copy.

### Your Campaign Architecture (3 campaigns):

```
Campaign A: PX-ASC-Website-Purchase
  ├── Objective: Sales
  ├── Type: Advantage+ Sales
  ├── Optimization: Purchase
  ├── Budget: RM800/day
  ├── Creatives: 25 best conversion-oriented (BOFU + FOOD)
  └── Bid: Minimum ROAS (target 3.0x)

Campaign B: PX-CBO-CTWA-WhatsApp
  ├── Objective: Engagement
  ├── Type: Standard CBO
  ├── Optimization: Conversations
  ├── Budget: RM600/day
  ├── Ad Set 1: Broad (25 creatives, all funnel stages)
  ├── Ad Set 2: Retarget WA openers who didn't purchase (top 10 creatives)
  └── Bid: Lowest Cost (let Meta optimize; WA leads are cheap in MY)

Campaign C: PX-CBO-Retarget-Purchase
  ├── Objective: Sales
  ├── Type: Standard CBO
  ├── Optimization: Purchase
  ├── Budget: RM200/day
  ├── Ad Set 1: Website visitors 7d, not purchased (10 BOFU creatives)
  ├── Ad Set 2: Add to cart 14d, not purchased (10 BOFU creatives)
  ├── Ad Set 3: WA conversation started, not purchased 30d (10 BOFU creatives)
  └── Bid: Cost Cap RM25/purchase
```

---

## ANSWER 3: Optimal Daily Budget for Testing 50 Creatives

### Verdict: RM1,600/day total (RM800 Website + RM600 CTWA + RM200 Retarget)

**Math**:
- You need 50 conversions per ad set within 7 days to exit learning phase
- Your current CPA (website purchase) = RM19,108 / 175 = RM109/purchase
- For ASC with 1 ad set: 50 × RM109 = RM5,450 in 7 days = RM778/day minimum
- Round up to RM800/day for the ASC campaign
- CTWA: Cost per conversation ~RM3-5 in MY. 50 conversations × RM5 = RM250 in 7 days = RM36/day minimum. But RM600/day gives volume for creative testing
- Retarget: RM200/day is sufficient for warm audiences

**Do NOT dump all 50 creatives into one campaign.** Split as follows:

| Campaign | Creatives | Logic |
|----------|-----------|-------|
| ASC Website | 25 | BOFU (19) + FOOD (6 best) — conversion-optimized |
| CTWA WhatsApp | 25 | TOFU (5) + MOFU (12) + FOOD (4) + HUMAN (4) — conversation starters |
| Retarget | 10 | Best of BOFU (price/urgency/scarcity) — pulled from the top performers |

### Creative Deployment Schedule

**Week 1 (Day 1-7)**: Launch 25 creatives per campaign. Let Meta's Andromeda algorithm distribute.
**Week 2 (Day 8-14)**: Kill bottom 50% (creatives with <0.5% CTR or zero conversions after RM50 spend). Add 5-10 fresh variants if available.
**Week 3 (Day 15-21)**: Scale winners by 20% budget increase. Refresh killed slots with new hooks/angles.
**Ongoing**: Rotate 3-5 new creatives every 7-10 days to prevent fatigue.

---

## ANSWER 4: Broad Targeting vs Interest Targeting for Malaysian Chinese

### Verdict: BROAD TARGETING with Language Filter Only

Meta's Andromeda algorithm in 2026 has fundamentally changed targeting. Research shows **17% more conversions with broad targeting** vs interest-based audiences. Here is exactly what to set:

### Campaign A & B — Ad Set Targeting Settings:

```
Location: Malaysia
  → Specific: Kuala Lumpur, Selangor, Penang, Johor Bahru
  → Radius: 40km around each city center

Age: 28-55

Gender: All (let Meta optimize; families = both genders)

Language: Chinese (Simplified) + Chinese (Traditional) + Chinese (All)
  → This is your PRIMARY filter. It naturally selects Malaysian Chinese users.
  → Do NOT add English — you want CN-dominant users for CN ads.

Detailed Targeting: LEAVE EMPTY (Advantage+ Detailed Targeting ON)
  → Andromeda will find your buyers better than any interest stack.
  → Your creatives ARE your targeting in 2026.

Advantage+ Placements: ON (all placements)
  → Let Meta choose Feed, Stories, Reels, Search, Audience Network.

Advantage+ Audience: ON
  → Allows Meta to go beyond your geo/demo if it finds converters.
```

### Why NOT Interest Targeting:
- Interest targeting in 2026 is largely cosmetic — Meta uses it as a "suggestion" not a "rule"
- Adding interests like "Vegetarian" or "Health food" actually RESTRICTS Andromeda from finding non-obvious converters
- Your CN language filter already narrows to ~6-7M Malaysian Chinese users
- Agencies testing consolidated broad approach report 15-17% conversion lift

### Exception — Retarget Campaign C:
Use Custom Audiences (not interests):
- Website visitors (Pixel): 7-day, 14-day, 30-day
- Add to Cart but not Purchased: 14-day
- WhatsApp conversation started: 30-day
- Lookalike 1% of Purchasers (for ad set expansion only)

---

## ANSWER 5: Best Bid Strategy for CTWA in Malaysia

### Verdict: Lowest Cost (No Cap) for CTWA

**For Campaign B (CTWA WhatsApp):**

```
Bid Strategy: Lowest Cost
Cost Control: NONE (do not set a cost cap initially)
```

**Reasoning:**
- WhatsApp conversations in Malaysia are cheap (RM3-8 per conversation started)
- Your 58% first reply rate is strong — quality is not the issue, volume is
- Cost Cap or Bid Cap will restrict delivery during learning phase
- Lowest Cost lets Meta find the cheapest conversations while the algorithm learns

**After 2 weeks, if cost per conversation > RM8:**
- Switch to Cost Cap at RM6/conversation
- This gives Meta a soft ceiling while still allowing optimization

**For Campaign A (Website Purchase):**

```
Bid Strategy: Minimum ROAS
ROAS Floor: 3.0x
```

**Reasoning:**
- You have CAPI connected with purchase value data
- Current implied ROAS = (RM12,640 March WA revenue) / (RM19,108 ad spend) = 0.66x (TERRIBLE)
- But this excludes website revenue and WA attribution lag
- Setting 3.0x ROAS floor tells Meta to find high-value purchasers, not just any purchaser
- If delivery stalls, lower to 2.5x, then 2.0x

**For Campaign C (Retarget):**

```
Bid Strategy: Cost Cap
Cost Per Purchase Cap: RM25
```

**Reasoning:**
- Retarget audiences are warm — CPA should be 50-70% lower than prospecting
- RM25 cost cap = aggressive but achievable for cart abandoners
- If too restrictive, raise to RM40

---

## ANSWER 6: Frequency 4.05 Crisis — The Fix

### Verdict: Simultaneous New Launch + Old Phase-Out (7-Day Transition)

**Frequency 4.05 means each person in your audience has seen your ads 4+ times.** This is ABOVE the danger threshold of 3.0 for prospecting. Your CPM is inflated (RM17.68 vs RM12-16 benchmark) because Meta is showing the same ads to the same saturated audience.

### The 7-Day Rescue Plan:

**Day 1:**
1. Launch all 3 new campaigns with 50 fresh creatives
2. Reduce old campaign budgets by 50%
3. Do NOT pause old campaigns yet (sudden pause can disrupt account-level learning)

**Day 4:**
1. Check new campaign metrics (CTR, CPC, frequency)
2. Reduce old campaigns to 25% of original budget
3. New campaigns should show frequency <1.5 (fresh audience)

**Day 7:**
1. New campaigns should have exited learning phase (or be close)
2. PAUSE all old campaigns completely
3. Old campaigns served their purpose — the creative is burned

**Day 14:**
1. Evaluate: new campaign frequency should be 1.5-2.0
2. Kill underperforming creatives (bottom 50%)
3. Plan next creative batch (you need 10-15 fresh creatives every 2 weeks)

### Ongoing Frequency Management:
- **Soft alert**: Frequency hits 2.5 → prepare new creatives
- **Hard action**: Frequency hits 3.0 → swap bottom 30% of creatives immediately
- **Emergency**: Frequency hits 4.0 → full creative refresh (what you are doing NOW)

### Why New Creatives Fix Frequency (Not Budget Reduction):
Reducing budget on fatigued ads just shows the SAME tired ads to FEWER people. The frequency stays high because the audience pool is exhausted. New creatives reset Andromeda's entity_hypothesis — Meta treats them as fresh ad objects and finds NEW audience pockets.

---

## ANSWER 7: Ideal Creative Rotation Cadence

### Verdict: 7-10 Day Cycles for Statics, 14-18 Days for Video

Based on 2026 research, creative decay timelines are:

| Format | Fatigue Onset | Kill Point | Action |
|--------|--------------|------------|--------|
| Static image | 7-10 days | 14 days | Swap or refresh hook |
| UGC-style video | 14-18 days | 21 days | New angle/hook |
| Carousel | 10-14 days | 18 days | Reorder or swap frames |
| Reels/Short video | 7-10 days | 14 days | New first 3 seconds |

### Your 50-Creative Rotation System:

```
Week 1-2: Deploy Batch A (25 creatives per campaign)
  → Monitor daily: CTR, CPC, frequency, conversions

Week 2: Kill & Replace
  → Kill: Any creative with CTR <0.8% after RM50+ spend
  → Kill: Any creative with frequency >3.0 within its ad set
  → Kill: Any creative with zero conversions after 7 days
  → Replace with: Fresh variants (new hook on same concept, or new concept)

Week 3-4: Scale Winners + Fresh Injection
  → Top 5 creatives: increase budget allocation (they'll naturally get more via Advantage+)
  → Inject 5-10 NEW creatives to replace killed ones
  → Target: always have 15-20 active creatives per campaign

Monthly: Full Creative Audit
  → Review all creative performance
  → Identify winning CONCEPTS (not just individual ads)
  → Brief next batch based on winning concepts × new angles
```

### Creative Refresh Math:
- 50 creatives launched now
- ~25 will be killed in 2 weeks (50% kill rate is normal)
- You need 10-15 new creatives every 2 weeks to maintain freshness
- **Plan for 30-40 new creatives per month** to sustain performance

---

## ANSWER 8: TOFU/MOFU/BOFU — Same or Different Campaigns?

### Verdict: SAME CAMPAIGN, Different Through Creative (Not Structure)

In 2026, Meta's Andromeda algorithm renders funnel-based campaign splitting largely unnecessary for your budget level. Here's why:

**Old approach (2023-2024):**
```
Campaign 1: TOFU (Awareness) → RM500/day
Campaign 2: MOFU (Consideration) → RM300/day
Campaign 3: BOFU (Conversion) → RM500/day
```
This fragments data, slows learning, and prevents Meta from cross-funnel optimization.

**2026 approach (Andromeda-optimized):**
```
Campaign A (ASC Website): Mix of BOFU + FOOD creatives → RM800/day
  → Andromeda shows BOFU to ready-to-buy users, FOOD to consideration-stage users
  → The creative IS the funnel stage, not the campaign structure

Campaign B (CTWA): Mix of TOFU + MOFU + FOOD + HUMAN → RM600/day
  → TOFU creatives (Incoming Call, Tinder Swipe) stop the scroll for cold audiences
  → MOFU creatives (Testimonials, Checklists) build trust for warm audiences
  → Andromeda matches creative to user readiness automatically

Campaign C (Retarget): BOFU only → RM200/day
  → This IS your dedicated BOFU campaign, but audience-based, not funnel-based
```

**The exception**: Retargeting (Campaign C) should be separate because it uses Custom Audiences, not because of funnel stage. The funnel separation happens through CREATIVE SELECTION, not campaign structure.

### Creative-to-Funnel Mapping for Your 50 Ads:

| Creative Type | Count | Funnel Stage | Goes In |
|--------------|-------|-------------|---------|
| TOFU (Incoming Call, Tinder, Macro, Feast, Poll) | 5 | Awareness | Campaign B (CTWA) |
| MOFU (Notes, iMessage, Google Review, WA Group, Checklist, Screen Time, Kitchen, Spotify, Ingredients, Art, Voting) | 11 | Consideration | Campaign B (CTWA) |
| BOFU (Calculator, Receipt, Grab, Menu, Golden, Collection, Search, 3D Price, Cart, Lo-fi, Confession, Abundance, Speed, Voice Memo, Notification, Fridge, Bank, Boarding Pass, Diary) | 19 | Conversion | Campaign A (ASC) + Campaign C (Retarget) |
| FOOD (Hero dishes, Abundance, Packaging, Variety, Transformation) | 10 | Mid-to-Bottom | Split across A + B |
| HUMAN (Chopstick, Expression, WeChat, Joy, Heritage) | 5 | Consideration | Campaign B (CTWA) |

---

## ANSWER 9: Flexible Ads for Food Brands

### Verdict: USE Flexible Ads for Website Campaign, NOT for CTWA

**Meta Flexible Ads** (replaced Dynamic Creative in June 2024) allow you to upload up to 10 images/videos into a single ad unit. Meta's algorithm then tests combinations across formats (single image, video, carousel) and shows the best-performing format to each user.

### Where to Use Flexible Ads:

**Campaign A (ASC Website) — YES:**
- Create 5 Flexible Ads, each with 5 images from a thematic group:
  - Flexible Ad 1: 5 FOOD hero images (different dishes)
  - Flexible Ad 2: 5 BOFU format/UI ads (Calculator, Receipt, Cart, Bank, Notification)
  - Flexible Ad 3: 5 BOFU urgency ads (Golden Reveal, 3D Price, Speed, Fridge, Abundance)
  - Flexible Ad 4: 5 MOFU social proof ads (iMessage, Google Review, WA Group, Checklist, Notes)
  - Flexible Ad 5: 5 mixed best-performers (top 1 from each category)
- This gives Andromeda maximum creative combinations to test

**Campaign B (CTWA) — NO:**
- Flexible Ads are only available for Sales and App Promotion objectives
- CTWA uses Engagement objective — Flexible Ads not available
- Use standard single-image ads or carousel ads instead

### Important Limitation:
Flexible Ads reporting is broken — you cannot see which specific image within a Flexible Ad is winning. Workaround: run your top 5 performers as standalone ads after 2 weeks to get clean attribution data.

---

## ANSWER 10: A/B Testing Setup for 50 Creatives

### Verdict: Use Andromeda's Natural Selection (Not Manual A/B Tests)

**Do NOT run formal A/B tests with 50 creatives.** Here's why:
- Meta's A/B test tool splits audience 50/50 between 2 variants — with 50 creatives you'd need 25 A/B tests running simultaneously, fragmenting your audience into tiny slices
- At RM1,600/day, you don't have enough budget for statistical significance across 25 tests

### Instead: The "Darwinian Testing" Framework

**Phase 1: Mass Deploy (Day 1-7)**
```
Campaign A: Load 25 creatives → let Andromeda distribute spend
Campaign B: Load 25 creatives → let Andromeda distribute spend
Set: "Equal distribution" OFF — let Meta's algorithm pick winners naturally
```

**Phase 2: Identify Winners (Day 7-14)**
```
Sort all creatives by:
  1. Cost per result (purchase or conversation)
  2. CTR (must be >1.0%)
  3. Conversion rate
  4. Frequency (<3.0)

Tier creatives:
  🟢 TOP 20% (10 ads): Scale — these get unlimited budget
  🟡 MIDDLE 40% (20 ads): Monitor — give 7 more days
  🔴 BOTTOM 40% (20 ads): Kill — pause immediately
```

**Phase 3: Iterate Winners (Day 14-21)**
```
Take top 5 winning CONCEPTS and create 3 variations each:
  → Same concept, different hook/headline
  → Same concept, different visual angle
  → Same concept, different CTA/offer

This gives you 15 fresh "informed" creatives based on proven concepts.
```

**Phase 4: Controlled A/B Test (Day 21+)**
```
NOW use Meta's A/B test tool — but only for:
  → Testing 2 bid strategies (Min ROAS 3.0x vs Cost Cap RM80)
  → Testing 2 audience strategies (Broad vs 1% Lookalike)
  → Testing 2 landing page versions (Shopify vs WhatsApp)
Never A/B test creatives manually when you can let Andromeda decide.
```

---

## COMPLETE DEPLOYMENT PLAN

### Pre-Launch Checklist (Day 0)

- [ ] Verify CAPI is firing Purchase events with correct values (check Events Manager > Diagnostics)
- [ ] Verify WhatsApp Business API provider has CAPI integration (for WA conversion attribution)
- [ ] Ensure all 50 creatives are 1080x1350 (4:5 ratio) for Feed + 1080x1920 (9:16) for Stories/Reels
- [ ] Prepare ad copy in Simplified Chinese for all 50 creatives (headline, primary text, CTA)
- [ ] Set up UTM parameters: utm_source=meta&utm_medium=paid&utm_campaign={campaign_name}&utm_content={ad_name}
- [ ] Create Custom Audiences: Website Visitors 7d/14d/30d, Add to Cart 14d, Purchase 30d/60d/180d, WA Conversations 30d
- [ ] Create Lookalike 1% from Purchase 180d audience

### Day 1 Launch

**Campaign A: PX-ASC-Website-Purchase**
```
Type: Advantage+ Sales Campaign
Objective: Sales
Optimization: Purchase
Attribution: 7-day click, 1-day view
Budget: RM800/day
ROAS Floor: 3.0x (if delivery stalls after 3 days, lower to 2.5x)
Existing Customer Budget Cap: 20% (force 80% to prospecting)
Geo: KL, Selangor, Penang, JB (40km radius each)
Age: 28-55
Language: Chinese (Simplified), Chinese (Traditional), Chinese (All)
Placements: Advantage+ (all)
Creatives: 25 ads (19 BOFU + 6 FOOD)
Ad Format: Mix of single image + Flexible Ads
CTA Button: "Shop Now" (website link to Shopify)
```

**Campaign B: PX-CBO-CTWA-WhatsApp**
```
Type: Standard CBO
Objective: Engagement
Optimization: Conversations (WhatsApp)
Attribution: 7-day click
Budget: RM600/day
Bid: Lowest Cost (no cap)

Ad Set 1: Broad Prospecting
  Geo: KL, Selangor, Penang, JB
  Age: 28-55
  Language: Chinese (Simplified), Chinese (Traditional), Chinese (All)
  Detailed Targeting: NONE (Advantage+ Detailed Targeting ON)
  Placements: Advantage+ (all)
  Creatives: 25 ads (5 TOFU + 11 MOFU + 5 HUMAN + 4 FOOD)
  CTA: "Send WhatsApp Message"
  Welcome Message: "你好！想了解品珍素食的优惠配套吗？🥢 买6送6，从RM12++起！请选择你想了解的："
  Quick Replies: "查看菜单" | "优惠配套" | "如何订购"

Ad Set 2: WA Retarget (after Week 2)
  Audience: WA conversation started 30d, NOT purchased
  Creatives: Top 10 performers from Ad Set 1
  Budget allocation: 30% of campaign budget
```

**Campaign C: PX-CBO-Retarget-Purchase**
```
Type: Standard CBO
Objective: Sales
Optimization: Purchase
Attribution: 7-day click, 1-day view
Budget: RM200/day
Bid: Cost Cap RM25/purchase

Ad Set 1: Cart Abandoners
  Audience: Add to Cart 14d, NOT Purchased
  Creatives: 5 BOFU (Calculator, Receipt, Bold Price, Cart, Abundance)
  Budget allocation: 40%

Ad Set 2: Website Visitors
  Audience: Website Visitors 7d, NOT Purchased
  Creatives: 5 BOFU (Golden Reveal, Fridge POV, Speed Timeline, Notification, Lo-fi)
  Budget allocation: 30%

Ad Set 3: WA Non-Converters
  Audience: WA Conversation Started 30d, NOT Purchased (via CAPI)
  Creatives: 5 BOFU (Bank Statement, Boarding Pass, Diary, Voice Memo, Search Solution)
  Budget allocation: 30%
```

### Day 1 — Old Campaign Transition
```
CBO-FrozenMY-CN-WhatsApp: Reduce budget from RM240 → RM120/day
CBO-FrozenMY-CN-Broad-Website-Troas: Reduce daily spend limit to RM250/day
CBO-FrozenMY-CN-Broad-Website-zen: Reduce daily spend limit to RM250/day
```

### Day 4 — Check & Adjust
```
Old campaigns: Reduce to RM60 + RM125 + RM125 (25% of original)
New campaigns: Check learning phase status
  → If CTR <0.8% across board: review ad copy/creative
  → If CPC >RM2.00: check audience overlap with old campaigns
  → If zero conversions: check CAPI event firing
```

### Day 7 — Decisive Action
```
Old campaigns: PAUSE ALL THREE
New campaigns: Should have ~50 conversions per ad set (or close)
  → Evaluate creative performance (sort by cost per result)
  → Identify top 20% and bottom 40%
```

### Day 14 — Optimize
```
Kill bottom 40% of creatives (pause, don't delete)
Scale budget:
  → Campaign A: RM800 → RM1,000/day (if ROAS >2.5x)
  → Campaign B: RM600 → RM800/day (if cost/conversation <RM8)
  → Campaign C: RM200 → RM300/day (if CPA <RM30)
Total potential: RM2,100/day (RM63,000/month)
```

### Day 21-30 — Scale or Recalibrate
```
If ROAS >3.0x: Scale aggressively
  → Campaign A: RM1,500/day
  → Campaign B: RM1,000/day
  → Campaign C: RM500/day
  → Total: RM3,000/day (RM90,000/month)

If ROAS 2.0-3.0x: Moderate scale + creative refresh
  → Maintain current budgets
  → Launch 15 new creatives (variations of top 5 concepts)

If ROAS <2.0x: Restructure
  → Analyze: Is it creative, audience, or offer?
  → Test: Different bundle offers (买10送10?)
  → Consider: Shopify landing page optimization
```

---

## BUDGET SUMMARY

### Phase 1: Testing (Week 1-2)
| Campaign | Daily | Weekly | Monthly Projection |
|----------|-------|--------|-------------------|
| ASC Website | RM800 | RM5,600 | RM24,000 |
| CTWA WhatsApp | RM600 | RM4,200 | RM18,000 |
| Retarget | RM200 | RM1,400 | RM6,000 |
| Old (tapering) | RM240→0 | ~RM840 | — |
| **Total** | **RM1,840→1,600** | **~RM12,040** | **RM48,000** |

### Phase 2: Scaling (Week 3-4)
| Campaign | Daily | Monthly Projection |
|----------|-------|--------------------|
| ASC Website | RM1,000-1,500 | RM30,000-45,000 |
| CTWA WhatsApp | RM800-1,000 | RM24,000-30,000 |
| Retarget | RM300-500 | RM9,000-15,000 |
| **Total** | **RM2,100-3,000** | **RM63,000-90,000** |

### ROAS Targets by Campaign

| Campaign | Min ROAS | Target ROAS | Stretch ROAS |
|----------|----------|-------------|-------------|
| ASC Website | 2.0x | 3.0x | 5.0x |
| CTWA WhatsApp | 3.0x (attributed) | 5.0x | 8.0x |
| Retarget | 4.0x | 6.0x | 10.0x |
| **Blended** | **2.5x** | **4.0x** | **6.0x** |

At RM63,000/month spend and 4.0x blended ROAS = **RM252,000/month revenue**.
At RM90,000/month spend and 4.0x blended ROAS = **RM360,000/month revenue**.

---

## CRITICAL META ADS CHANGES (Late 2025 / 2026)

### What's Changed (Must Know)

1. **Andromeda Algorithm**: Meta's new ad retrieval system evaluates creative FIRST, then finds audiences. Creative quality > audience targeting. This is why broad targeting + diverse creatives wins in 2026.

2. **Advantage+ Sales replaced Advantage+ Shopping**: More flexible, works with more objectives and bid strategies. Now allows existing customer budget caps (set to 20% for Pinxin).

3. **Interest Targeting is Optional**: Meta treats detailed targeting as "suggestions" — Andromeda overrides them when it finds better converters. Stop wasting time on interest stacking.

4. **Cross-Platform Bidding**: Unified budgets now span Facebook, Instagram, WhatsApp, and Threads. Advantage+ placements automatically distribute across all surfaces.

5. **Budget Reallocation**: Even with ad-set-level budgets, Meta can now pull up to 20% from one ad set to another that's outperforming. This is automatic in CBO campaigns.

6. **Creative Fatigue Detection**: Meta now has built-in "Creative Fatigue" and "Similarity Score" indicators in Ads Manager. Check these weekly — they tell you when to refresh before performance drops.

7. **Flexible Ads**: Replaced Dynamic Creative for Sales/App campaigns. Upload up to 10 assets per ad unit. Meta tests format combinations automatically.

8. **CAPI is Mandatory**: Pixel-only setups miss 50%+ of conversions due to iOS privacy, ad blockers, and consent banners. Your CAPI connection is a competitive advantage — most Malaysian SMEs still run pixel-only.

---

## OFFER STRATEGY (Critical for AOV Recovery)

Your March AOV collapsed from RM427 (Feb) to RM192. This is an OFFER problem, not just an ad problem.

### Recommended Offer Ladder:

| Bundle | Price | Per Meal | CTA |
|--------|-------|----------|-----|
| 买6送6 (12 meals) | RM144 | RM12/meal | Entry — "Try us" |
| 买8送8 (16 meals) | RM192 | RM12/meal | Mid — "Stock up" |
| 买20送20 (40 meals) | RM480 | RM12/meal | Hero — "Full month supply" |

### Ad Copy Strategy by Offer:

**TOFU/MOFU ads**: Lead with taste/heritage, mention "从RM12++起" as hook
**BOFU ads**: Lead with bundle math — "买20送20 = 40餐只需RM480 = 每餐RM12"
**Retarget ads**: Urgency — "限时优惠" + countdown + specific bundle

**Push 买20送20 as the HERO offer** to recover AOV. At RM480/order, you only need 525 orders/month to hit RM252,000. At RM192 AOV, you need 1,312 orders — 2.5x harder.

---

## WHATSAPP SALES FUNNEL OPTIMIZATION

Your WA data shows strong conversation volume (418/14d) but only 58% first reply rate and unknown conversion rate. To maximize CTWA performance:

### Welcome Flow (Automated):
```
Message 1 (Instant):
"你好！欢迎来到品珍素食 🌿
全马第一植物基冷冻料理，买6送6从RM12++起！
请选择你想了解的："

Quick Reply 1: "🍛 查看完整菜单"
Quick Reply 2: "🎁 今日优惠配套"
Quick Reply 3: "🚚 配送范围"
Quick Reply 4: "💬 直接跟我们聊"
```

### After Quick Reply (Automated):
- Menu → Send full menu carousel + "想尝试哪道菜？"
- 优惠配套 → Send bundle breakdown + "买20送20最划算，要我帮你下单吗？"
- 配送范围 → Send delivery info + "你的地址在哪里？"

### Human Handoff:
After 2 automated messages, route to human agent for closing. WA conversion is about SPEED — respond within 5 minutes for 3-5x higher close rate.

---

## MONITORING DASHBOARD (Check Daily)

| Metric | Campaign A (Website) | Campaign B (CTWA) | Campaign C (Retarget) | Alert Threshold |
|--------|---------------------|-------------------|----------------------|----------------|
| Spend | — | — | — | Over/under 20% of target |
| Frequency | — | — | — | >2.5 (prospecting), >5.0 (retarget) |
| CTR | — | — | — | <1.0% = creative issue |
| CPC | — | — | — | >RM1.50 = fatigue |
| CPM | — | — | — | >RM20 = audience saturation |
| Cost/Purchase | — | — | — | >RM120 (website) |
| Cost/Conversation | — | — | — | >RM8 (WA) |
| ROAS | — | — | — | <2.0x = review immediately |
| Learning Phase | — | — | — | Still learning after 7d = budget/creative issue |

---

## KEY TAKEAWAYS

1. **Frequency 4.05 is the #1 problem.** New creatives + new campaigns = the only fix. Budget reduction on old ads does not solve fatigue.

2. **3 campaigns, not 1.** Website (ASC) + WhatsApp (CBO) + Retarget (CBO). Different objectives require different campaigns.

3. **Broad targeting + Chinese language filter.** Andromeda in 2026 outperforms interest targeting by 15-17%. Your creatives ARE your targeting.

4. **RM1,600/day starting budget.** Scale to RM3,000/day if ROAS holds above 3.0x.

5. **Kill fast, iterate faster.** 50% of creatives will fail in 2 weeks. Have 15 new creatives ready every 2 weeks.

6. **Push 买20送20 to recover AOV.** RM192 AOV is not sustainable. RM480 AOV changes the entire unit economics.

7. **CAPI is your edge.** Most Malaysian competitors run pixel-only. Your server-side tracking gives Meta better conversion data = better optimization.

8. **WhatsApp is your moat.** 58% first reply rate is strong. Optimize the conversation flow to close faster.

---

## Sources

- [Meta Advantage+ Sales Campaign Guide (2026)](https://medium.com/@tentenco/how-to-build-a-successful-campaign-with-metas-advantage-ai-the-complete-2026-playbook-befca729202b)
- [Meta Ads Best Practices 2026 — Flighted](https://www.flighted.co/blog/meta-ads-best-practices)
- [Meta Ads Best Practices 2026 — LeadsBridge](https://leadsbridge.com/blog/meta-ads-best-practices/)
- [CTWA Click-to-WhatsApp Ads Guide 2026](https://whatsappbusinessapis.in/click-to-whatsapp-ads-ctwa/)
- [CTWA Attribution Guide — TBit](https://tbit.app/content/what-is-ctwa-click-to-whatsapp-ads)
- [WhatsApp Advertising $47K Campaign Data](https://acroan.com/whatsapp-advertising-methods/)
- [Meta Andromeda 2026 Playbook — Ad-Times](https://ad-times.com/meta-ads-2026-ai-driven-andromeda-playbook/)
- [Meta Andromeda Update for Ecommerce — wetracked.io](https://www.wetracked.io/post/andromeda-update-ecommerce)
- [Andromeda Best Practices 2026 — adlibrary.com](https://www.adlibrary.com/posts/meta-ads-campaign-structure-2026-andromeda-update)
- [Creative Fatigue & Similarity Score — Admetrics](https://www.admetrics.io/en/post/meta-creative-fatigue-and-similarity-score-complete-guide)
- [Creative Fatigue Fix — Pixel Panda](https://www.pixelpandacreative.com/blog/why-your-best-performing-ad-is-your-biggest-risk-in-2026)
- [Meta Flexible Ads Guide — adsuploader](https://adsuploader.com/blog/meta-flexible-ads)
- [Creative Testing Framework 2026 — Foxwell Digital](https://www.foxwelldigital.com/blog/the-meta-creative-testing-frameworks-top-brands-use-in-2026)
- [Meta Ads Funnel Strategy 2026 — Stackmatix](https://www.stackmatix.com/blog/meta-ads-funnel-strategy)
- [Best Meta Ads Account Structure 2026 — Flighted](https://www.flighted.co/blog/best-meta-ads-account-structure-2026)
- [Advantage+ vs CBO Performance — BMG360](https://www.bmg360.com/blog/post/are-advantage-shopping-campaigns-worth-it)
- [Meta CAPI Setup for Shopify 2026 — wetracked.io](https://www.wetracked.io/post/set-up-facebook-conversion-api-on-shopify)
- [Meta Ads CPM/CPC Benchmarks by Country 2026 — AdAmigo](https://www.adamigo.ai/blog/meta-ads-cpm-cpc-benchmarks-by-country-2026)
- [Cost Cap vs Bid Cap Strategy — AdAmigo](https://www.adamigo.ai/blog/cost-cap-vs-bid-cap-cpa-strategy-guide)
- [Meta Ads Bidding Strategies 2026 — Spinta Digital](https://spintadigital.com/blog/meta-ads-bidding-strategies-2026/)
- [Facebook Ad Algorithm Changes 2026 — Social Media Examiner](https://www.socialmediaexaminer.com/facebook-ad-algorithm-changes-for-2026-what-marketers-need-to-know/)
- [Creative Scaling Guide 2026 — Admetrics](https://www.admetrics.io/en/post/creative-scaling-the-ultimate-guide)
- [Meta Ads Creative Testing Guide — AdStellar](https://www.adstellar.ai/blog/meta-ads-creative-testing-guide)
- [F&B ROAS Benchmarks — Varos](https://www.varos.com/benchmarks/facebook-roas-for-food-and-beverage)
