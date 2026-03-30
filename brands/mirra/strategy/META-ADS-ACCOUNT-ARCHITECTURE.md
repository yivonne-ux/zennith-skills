# Meta Ads Account Architecture — Mirra.Eats
## DTC Meal Subscription | RM5,000-7,000/day | ROAS Target 4-5x
### March 2026

---

## 1. ACCOUNT STRUCTURE — THE 2026 ANSWER

### The Verdict: 3-4 Campaigns, Not 20

In 2026, Meta's algorithm (Andromeda) rewards consolidation. More conversions per ad set = better optimization. The old era of 15+ campaigns with micro-segmented audiences is dead.

**Your exact campaign setup:**

| # | Campaign Name | Type | Objective | Budget Optimization | Daily Budget |
|---|--------------|------|-----------|-------------------|--------------|
| 1 | `MIRRA_TEST_Creative` | Manual Sales | Sales (Purchase) | ABO | RM750-1,050 (15% of total) |
| 2 | `MIRRA_SCALE_Winners` | Manual Sales | Sales (Purchase) | CBO | RM2,500-3,500 (50% of total) |
| 3 | `MIRRA_ASC_Advantage` | Advantage+ Sales | Sales (Purchase) | Auto (ASC) | RM1,250-1,750 (25% of total) |
| 4 | `MIRRA_RT_Retarget` | Manual Sales | Sales (Purchase) | CBO | RM500-700 (10% of total) |

**Total: 4 campaigns. Budget split: 15% test / 50% scale / 25% ASC / 10% retarget.**

### CBO vs ABO — The 2026 Answer

- **ABO for testing.** Each creative gets equal budget. No algorithm favoritism. You control which creative gets spend.
- **CBO for scaling.** Once winners are identified, consolidate into CBO and let Meta allocate spend to the best performers.
- **ASC is its own category.** Advantage+ Sales Campaigns handle their own budget distribution automatically.

### Why This Works at RM5,000-7,000/day

At ~RM6,000/day (~$1,400 USD), you need 50+ purchase conversions per ad set per week for stable delivery. With a RM100 average order:
- RM3,000/day scaling campaign = ~30 purchases/day = 210/week (well above threshold)
- RM750/day testing = enough to identify winners within 3-5 days
- RM500/day retarget = high-intent audiences, efficient spend

---

## 2. CAMPAIGN 1 — CREATIVE TESTING (`MIRRA_TEST_Creative`)

### Setup
- **Objective:** Sales
- **Conversion event:** Purchase
- **Budget optimization:** ABO (Ad Set Budget)
- **Attribution window:** 7-day click, 1-day view
- **Bid strategy:** Lowest Cost (no cap — let it learn freely)

### Ad Set Configuration
- **3-5 ad sets running simultaneously** (one per creative concept/angle)
- **Budget per ad set:** RM150-210/day (equal split)
- **Each ad set contains 1 ad only** (isolate variables)
- **Audience:** Broad targeting, 18-55, KL/Selangor, all genders
- **Placements:** Advantage+ Placements (automatic)

### Testing Framework
- **Volume target:** 10-15 new creatives per week
- **Launch cadence:** New batch every Monday and Thursday (5-7 ads each)
- **Kill criteria:** After RM450-600 spend (3 days) OR 0 purchases — kill the ad
- **Promotion criteria:** CPA below RM80 AND ROAS above 3x after RM600+ spend — promote to Scale campaign
- **Statistical significance:** Minimum 15-20 conversions per creative before declaring winner/loser. Ideally 7+ days of data.

### What You Test (One Variable at a Time)
- **Round 1:** Creative concept/angle (different hooks, different value props)
- **Round 2:** Format (static vs video vs carousel vs Reel)
- **Round 3:** Copy (headline/primary text variations)
- **Round 4:** Hook (first 3 seconds of video, or headline)

### Naming Convention for Test Ads
```
MIRRA_TEST_{concept}_{format}_{version}_{date}
Example: MIRRA_TEST_WeightLoss_Video_V1_Mar26
Example: MIRRA_TEST_LowCal_Static_V3_Mar26
```

---

## 3. CAMPAIGN 2 — SCALING WINNERS (`MIRRA_SCALE_Winners`)

### Setup
- **Objective:** Sales
- **Conversion event:** Purchase
- **Budget optimization:** CBO (Campaign Budget Optimization)
- **Daily budget:** RM2,500-3,500
- **Attribution window:** 7-day click, 1-day view
- **Bid strategy:** Cost Cap (set at your target CPA, e.g., RM75)

### Ad Set Configuration
- **1-3 ad sets maximum** (consolidation = more data per ad set)
- **Primary ad set:** Broad targeting (no interests, no lookalikes)
- **Optional second ad set:** 1% Lookalike of Purchasers (if you have 1,000+ purchasers)
- **Each ad set:** 5-8 proven winning ads
- **Audience:** Broad, 18-55, KL + Selangor + Klang Valley
- **Placements:** Advantage+ Placements

### How to Move Ads from Test to Scale
1. In Test campaign, identify ad with ROAS > 3x and 15+ conversions
2. Copy the **Post ID** (not duplicate — this preserves social proof/engagement)
3. Create new ad in Scale campaign using "Use Existing Post" and paste the Post ID
4. The ad enters the Scale campaign with all its likes, comments, and shares intact

### Scaling Rules
- **Vertical scaling:** Increase CBO budget by maximum 20% every 3-4 days
- **Example ramp:** RM2,500 → RM3,000 → RM3,600 → RM4,320 (over 12 days)
- **Never increase by more than 20% in a single day** — this resets the learning phase
- **If CPA spikes after increase:** Wait 48-72 hours before making changes. The algorithm needs time to recalibrate.

### When to Use Horizontal Scaling Instead
If you need to scale faster than 20% every 3-4 days:
1. Duplicate the winning ad set
2. Give the duplicate a fresh budget of RM500-750/day
3. Same audience, same ads — Meta will find new pockets within the broad audience
4. Run both in parallel

### Ad Refresh Cadence
- Rotate in 2-3 new proven creatives every 2 weeks
- Remove ads that have been running 30+ days with declining ROAS
- Never remove an ad that's still performing — let Meta decide spend allocation

---

## 4. CAMPAIGN 3 — ADVANTAGE+ SALES (`MIRRA_ASC_Advantage`)

### What ASC Is
ASC is Meta's AI-driven campaign type that automates audience targeting, placement, and creative optimization. It collapses the traditional campaign > ad set > ad structure into a simplified flow. Meta controls everything — you provide creatives and a budget.

### Exact Setup Steps in Ads Manager

**Step 1: Create Campaign**
- Click "Create" → Select "Sales" objective
- Toggle ON "Advantage+ shopping campaign" (it will appear as a campaign subtype)

**Step 2: Campaign Settings**
- Campaign name: `MIRRA_ASC_Advantage_Mar26`
- Campaign budget: RM1,250-1,750/day
- Conversion location: Website
- Conversion event: Purchase
- Attribution: 7-day click, 1-day view

**Step 3: Audience Controls**
- Country: Malaysia
- Age: Leave broad (18-65+) — let Meta optimize
- **Existing customer definition:** Upload your customer list (email + phone). This tells Meta who is "existing" vs "new"
- **Existing customer budget cap:** Set to 10-15%. This prevents Meta from spending your entire ASC budget on retargeting existing customers (which inflates ROAS but doesn't grow the business)

**Step 4: Creative**
- Upload 10-20 creatives (mix of static, video, carousel)
- ASC supports up to 150 ads, but 10-20 is the sweet spot for your budget level
- Include a mix of creative angles, formats, and hooks
- Meta will automatically test and allocate spend to winners

### ASC vs Manual — How They Coexist
- ASC handles broad prospecting with AI optimization
- Manual Scale campaign handles your proven winners with more control
- Manual Test campaign is where new creatives are validated before feeding into both ASC and Scale
- **Do not run identical creatives across ASC and Manual campaigns** — this causes auction overlap and drives up your own CPMs

### Common ASC Mistakes
1. **Not uploading a customer list** — Meta can't distinguish new vs existing customers
2. **Not setting the existing customer cap** — Meta will retarget existing buyers (easy conversions) and show inflated ROAS
3. **Too few creatives** — ASC needs variety to optimize. Minimum 8-10 ads
4. **Launching ASC before you have Pixel data** — ASC needs 50+ conversions/week to work well. Get manual campaigns running first.

---

## 5. CAMPAIGN 4 — RETARGETING (`MIRRA_RT_Retarget`)

### Setup
- **Objective:** Sales
- **Budget optimization:** CBO
- **Daily budget:** RM500-700
- **Bid strategy:** Lowest Cost
- **Attribution:** 7-day click, 1-day view

### Retargeting Ad Sets (3 tiers)

**Ad Set 1: Hot — Cart Abandoners (RM200-280/day share)**
- Custom Audience: "Added to Cart" in last 7 days, exclude Purchasers (30 days)
- 3-4 ads: urgency-focused, objection-handling, testimonials
- Name: `MIRRA_RT_ATC7d_Excl-Purch`

**Ad Set 2: Warm — Website Visitors + Engagers (RM200-280/day share)**
- Custom Audience: Website visitors 14 days + IG/FB engagers 30 days, exclude ATC + Purchasers
- 3-4 ads: social proof, menu highlights, before/after
- Name: `MIRRA_RT_WV14d-Engage30d_Excl-ATC`

**Ad Set 3: Existing Customers — Reactivation & Upsell (RM100-140/day share)**
- Custom Audience: Past purchasers 30-180 days, exclude purchasers last 14 days (active subscribers)
- 2-3 ads: new menu items, referral offers, win-back
- Name: `MIRRA_RT_Purch30-180d_Winback`

### Retargeting Custom Audiences — Full List

| Audience Name | Source | Window | Use |
|--------------|--------|--------|-----|
| `CA_ATC_7d` | Pixel: AddToCart | 7 days | Hot retarget |
| `CA_ATC_14d` | Pixel: AddToCart | 14 days | Warm retarget |
| `CA_IC_7d` | Pixel: InitiateCheckout | 7 days | Hot retarget |
| `CA_WV_7d` | Pixel: PageView | 7 days | Warm retarget |
| `CA_WV_14d` | Pixel: PageView | 14 days | Warm retarget |
| `CA_WV_30d` | Pixel: PageView | 30 days | Broad retarget |
| `CA_Purch_30d` | Pixel: Purchase | 30 days | Exclusion / upsell |
| `CA_Purch_180d` | Pixel: Purchase | 180 days | Win-back |
| `CA_IG_Engage_30d` | IG Profile: All engagers | 30 days | Warm retarget |
| `CA_IG_Engage_90d` | IG Profile: All engagers | 90 days | Broad retarget |
| `CA_FB_Engage_30d` | FB Page: All engagers | 30 days | Warm retarget |
| `CA_Video_25pct_30d` | Video: 25% watched | 30 days | Awareness retarget |
| `CA_Video_50pct_14d` | Video: 50% watched | 14 days | Warm retarget |
| `CA_Video_75pct_7d` | Video: 75% watched | 7 days | Hot retarget |
| `CA_Video_95pct_7d` | Video: 95% watched | 7 days | Hottest retarget |
| `CA_Email_Customers` | Customer list upload | - | Exclusion / LAL seed |
| `CA_Email_Subscribers` | Customer list upload | - | Exclusion / LAL seed |

### Exclusion Audiences (Critical)
Always exclude downstream audiences from upstream campaigns:
- **Prospecting campaigns (Test, Scale, ASC):** Exclude all purchasers (30 days) + ATC (7 days)
- **Warm retarget:** Exclude ATC (7 days) + Purchasers (30 days)
- **Hot retarget (ATC):** Exclude Purchasers (14 days)
- **Customer reactivation:** Exclude active subscribers (purchasers last 14 days)

### Lookalike Audiences for Prospecting

| LAL Name | Seed Audience | Percentage | Use |
|----------|--------------|------------|-----|
| `LAL_Purch_1pct` | All purchasers | 1% | Best prospecting LAL |
| `LAL_Purch_3pct` | All purchasers | 3% | Broader prospecting |
| `LAL_ATC_1pct` | Add to cart users | 1% | High-intent prospecting |
| `LAL_Value_1pct` | Top 25% purchasers by value | 1% | Highest value prospecting |
| `LAL_IG_1pct` | IG engagers 90d | 1% | Awareness expansion |

**2026 reality check:** Broad targeting (no LALs, no interests) often outperforms LALs at scale. Use LALs as "audience suggestions" within Advantage+ Audience — Meta treats them as signals, not hard boundaries.

---

## 6. AD SET CONFIGURATION DEEP DIVE

### Audience Setup in 2026

**The hierarchy (best to worst at your spend level):**
1. **Broad + Advantage+ Audience** — Let Meta find buyers. Best for Scale + ASC campaigns.
2. **1% LAL of purchasers** — Good for initial testing when you have limited Pixel data.
3. **Interest targeting** — Only use for very early stage when you have zero conversion data. Phase out quickly.
4. **Narrow interest stacking** — Dead. Don't do this.

**For Mirra specifically:**
- Geo: KL, Selangor, Putrajaya (your delivery zone)
- Age: Start broad (18-55). Meta will naturally skew to your best demo. You can narrow after seeing data.
- Gender: Start broad. If data shows 80%+ female purchasers after 2 weeks, consider female-only ad sets for efficiency.

### Placement Strategy
- **Default:** Advantage+ Placements (automatic) for all campaigns
- **Creative requirement:** Provide assets in all ratios — 1:1 (Feed), 9:16 (Stories/Reels), 1.91:1 (Audience Network)
- **Do NOT manually exclude placements** unless data clearly shows a placement is burning budget with zero conversions after 1,000+ impressions
- **Reels typically outperforms Stories** for prospecting (15-25% higher engagement)
- **Feed drives most conversions** — expect 50-60% of spend to go here naturally

### Conversion Window
- **Use:** 7-day click, 1-day view (default, and correct for subscription/meal delivery)
- **Why:** Meal delivery is a considered purchase but not a 28-day decision. 7-day click captures the typical browse > compare > purchase cycle.
- **2026 change:** Meta removed 7-day view and 28-day view windows. Only 1-day view remains.

### Dynamic Creative vs Manual Creative
- **For testing campaign:** Use manual creative (1 ad per ad set). You need to know exactly which creative won.
- **For scaling campaign:** Use manual creative with proven Post IDs.
- **For ASC:** Creative is managed at the campaign level automatically. Upload individual assets — ASC handles the mixing.
- **Dynamic Creative (Flexible Ads):** Can work for rapid iteration but makes it hard to identify which specific combination won. Better for brands testing 50+ variations. At your level, manual is cleaner.

---

## 7. BID STRATEGY — THE RIGHT CHOICE FOR EACH CAMPAIGN

| Campaign | Bid Strategy | Setting | Why |
|----------|-------------|---------|-----|
| Test | Lowest Cost | No cap | Maximum delivery during learning. You want data, not efficiency. |
| Scale | Cost Cap | RM75-85 per purchase | Controls CPA while allowing Meta to optimize within bounds. Start at your target CPA. |
| ASC | Lowest Cost OR Cost Cap | Start with Lowest Cost, add Cost Cap after 2 weeks of data | ASC needs room to learn first. |
| Retarget | Lowest Cost | No cap | Small audience + high intent = naturally low CPA. No cap needed. |

### When to Use ROAS Target (Minimum ROAS)
- Only after you have 90+ days of conversion data with value tracking
- Only if your average order values vary significantly (e.g., RM80 vs RM250 plans)
- Set minimum ROAS at 3x to start (below your 4-5x target — gives Meta room)
- **For subscription with relatively uniform pricing, Cost Cap is usually better than ROAS Target**

### Bid Strategy Progression
1. **Week 1-2:** Lowest Cost everywhere (gather data)
2. **Week 3-4:** Add Cost Cap to Scale campaign (control efficiency)
3. **Month 2+:** Test ROAS Target on Scale campaign (optimize for value)
4. **Ongoing:** Keep Test campaign on Lowest Cost permanently

---

## 8. CREATIVE TESTING FRAMEWORK AT SCALE

### The System for 10+ New Creatives Per Week

**Monday: Launch Batch A (5-7 creatives)**
- Upload to Test campaign
- Each creative gets its own ad set with RM150-210/day
- All ad sets target same broad audience

**Thursday: Launch Batch B (5-7 creatives)**
- Same process as Monday
- This staggers learning phases so you always have data maturing

**Following Monday: Review Week 1 results**
- Kill: Any ad with RM450+ spend and 0 purchases
- Kill: Any ad with CPA > 2x target after RM600+ spend
- Watch: Ads with some conversions but unstable CPA (give 3 more days)
- Promote: Ads with CPA < RM80 and ROAS > 3x after 15+ conversions

### Promotion Process (Test → Scale)
1. Go to the winning ad in Test campaign
2. Click the ad → "View Post" → copy the Post ID from the URL
3. In Scale campaign, create new ad → "Use Existing Post" → paste Post ID
4. The ad appears in Scale with all its engagement history
5. Pause the ad in Test campaign (don't delete — you may need to reference it)

### A/B Testing on Meta
- **Use Meta's built-in A/B test tool** for strategic questions (e.g., "Does Cost Cap or Lowest Cost perform better?")
- Setup: Campaign > A/B Test > Select variable (creative, audience, placement, or delivery optimization)
- **Minimum test duration:** 7 days
- **Minimum budget:** Enough for 50+ conversions per variant
- At RM6,000/day total, you can run 1-2 formal A/B tests alongside your regular creative testing

### What Constitutes Statistical Significance
- **Minimum conversions:** 15-20 per variant (absolute minimum), 50+ for high confidence
- **Minimum time:** 7 days (captures day-of-week variance)
- **Confidence level:** 90%+ (Meta's A/B test tool calculates this automatically)
- **Rule of thumb:** If after RM1,000 spend a creative has zero purchases, it's dead. Don't wait for statistical significance to kill obvious losers.

---

## 9. SCALING RULES — SPECIFIC PROTOCOLS

### When to Scale
- Ad set has exited learning phase (shows "Active" not "Learning")
- ROAS > 3.5x for 5+ consecutive days
- CPA stable (not trending upward) over 7 days
- 50+ conversions in the last 7 days

### Vertical Scaling Protocol
```
Day 1:  RM2,500/day (baseline)
Day 4:  RM3,000/day (+20%)
Day 8:  RM3,600/day (+20%)
Day 12: RM4,320/day (+20%)
Day 16: RM5,184/day (+20%)
```
- **Always wait 72 hours** between increases
- **If CPA rises >20% after increase:** Stop. Wait 48 hours. If it doesn't recover, roll back to previous budget.
- **The 20% rule is still valid in 2026.** Meta's documentation still references avoiding "significant edits" that trigger learning phase resets.

### Horizontal Scaling Protocol
When you need to scale faster than 20% every 3-4 days:
1. Duplicate the entire winning ad set (same ads, same audience)
2. Set duplicate budget at RM500-750/day
3. Both ad sets run simultaneously — Meta will find different pockets within the broad audience
4. You can duplicate 2-3 times before audience saturation becomes an issue
5. **At RM5,000-7,000/day total budget in KL/Selangor, you can run 3-4 prospecting ad sets max before overlap becomes a problem**

### Learning Phase Management
- Learning phase requires ~50 conversions per ad set in 7 days
- At RM500/day per ad set with RM75 CPA target, that's ~47 conversions/week (borderline)
- **Solution:** Keep ad set budgets at RM500+/day minimum for conversion campaigns
- **Edits that reset learning phase:** Budget change >20%, audience change, creative additions, bid strategy change, conversion event change, 7+ day pause
- **Edits that do NOT reset learning:** Adding new ads (if using CBO), small copy changes, bid amount adjustment within 10%

---

## 10. CAPI AND TRACKING SETUP

### Events to Track (Priority Order)

| Event | Trigger | Value | Purpose |
|-------|---------|-------|---------|
| `PageView` | Any page load | - | Retargeting pools |
| `ViewContent` | Menu/plan page viewed | - | Intent signal |
| `AddToCart` | Plan selected / added to cart | Plan price | Hot retarget |
| `InitiateCheckout` | Checkout page reached | Cart value | Hottest retarget |
| `Purchase` | Payment completed | Transaction value | Primary optimization event |
| `Subscribe` | Subscription activated | Subscription value | Subscription tracking |
| `StartTrial` | Free trial started (if applicable) | - | Trial funnel tracking |
| `Lead` | Email/phone captured | - | Lead gen campaigns |

### CAPI Setup for Subscription Business

**Architecture:**
```
Browser (Pixel) ──→ Meta Servers
                         ↑
Your Server (CAPI) ──────┘
```
Both send the same events. Meta deduplicates using `event_id`.

**Implementation Steps:**

1. **Pixel Setup** (browser-side)
   - Install Meta Pixel base code on all pages
   - Fire standard events on appropriate pages
   - Include `event_id` parameter with each event

2. **CAPI Setup** (server-side)
   - Option A: CAPI Gateway (easiest — Meta-hosted, minimal code)
   - Option B: Server-side GTM (Google Tag Manager server container)
   - Option C: Direct API integration (most control)
   - **Recommended for Mirra:** CAPI Gateway or server-side GTM

3. **Deduplication**
   - Every event must have a unique `event_id` parameter
   - Pixel and CAPI send the same `event_id` for the same event
   - Meta automatically deduplicates matching `event_id` values
   - Without deduplication, you'll double-count every conversion

4. **Customer matching parameters** (send with every CAPI event)
   - `em` — hashed email
   - `ph` — hashed phone number
   - `fn` — hashed first name
   - `ln` — hashed last name
   - `ct` — hashed city
   - `st` — hashed state
   - `zp` — hashed zip/postcode
   - `country` — hashed country code
   - `external_id` — your customer ID (hashed)
   - `fbp` — Facebook browser ID (from `_fbp` cookie)
   - `fbc` — Facebook click ID (from `_fbc` cookie or URL `fbclid` parameter)

5. **Event Match Quality (EMQ)**
   - Target: 6.0+ out of 10 (minimum acceptable)
   - Ideal: 8.0+ out of 10
   - Check in Events Manager > Data Sources > Your Pixel > Event Match Quality
   - Improve by sending more customer parameters (email + phone + name = significant boost)

### Subscription-Specific Tracking

For a meal subscription, you need to distinguish:
- **First purchase** (new subscriber acquisition)
- **Recurring purchase** (subscription renewal — don't optimize Meta ads for these, it inflates ROAS)
- **Cancellation** (churn signal)
- **Reactivation** (win-back)

**How to handle:**
- Set Purchase event to fire ONLY on first subscription purchase
- Track renewals as a custom event (`SubscriptionRenewal`) — do NOT use `Purchase` for renewals
- This prevents Meta from claiming credit for recurring revenue it didn't generate
- Your true Meta ROAS = (first purchase revenue attributed to Meta) / (ad spend)

### AEM (Aggregated Event Measurement) — 2026 Update
- **As of June 2025, Meta removed the 8-event limit.** No more event prioritization required.
- You can now track unlimited events without ranking them
- The "Aggregated Event Measurement" tab has been removed from Events Manager
- Just set up your Pixel + CAPI correctly and Meta handles event processing automatically

---

## 11. VALUE OPTIMIZATION SETUP

### When to Enable
- After you have 50+ purchases/week tracked with monetary values
- After 28+ days of conversion data (ideally 90+ days)

### Setup Steps
1. Campaign objective: Sales
2. Ad set level: Performance goal → "Maximize value of conversions"
3. Optional: Set Minimum ROAS (start at 3x, your floor — not your target)
4. Ensure every Purchase event includes the correct `value` and `currency` parameters

### Value Rules (Advanced)
Value Rules let you tell Meta which customers are worth more:
- Example: Customers who order the RM250 family plan are worth more than RM80 individual plans
- Setup: Ads Manager > All Tools > Value Rules
- Create rules based on audience (e.g., "customers from LAL_Value_1pct audience get +30% value multiplier")
- This steers Meta toward higher-LTV customers

### Customer List Uploads
- Upload customer lists monthly (email + phone + first name + last name)
- Segment by value tier: High-value subscribers, churned subscribers, trial users
- Use for: LAL creation, exclusion audiences, ASC existing customer definition
- **Format:** CSV with columns for email, phone, first name, last name, city, country
- **Hashing:** Meta auto-hashes on upload, but pre-hashing with SHA-256 is better practice

---

## 12. BUDGET MANAGEMENT AT RM5,000-7,000/DAY

### Daily vs Lifetime Budgets
- **Use daily budgets** for all campaigns except when you need dayparting
- Daily budgets give you more control and easier scaling math
- Lifetime budgets are only required if you want to schedule ads for specific hours

### Day-Parting (Ad Scheduling)
- **Available only with lifetime budgets** (not daily budgets)
- For Mirra meal delivery in KL/Selangor:
  - **Peak ordering windows:** 10am-1pm (lunch planning) and 5pm-9pm (dinner planning)
  - **Sahur/Iftar during Ramadan:** 3-6am and 4-7pm
- **Recommendation:** Don't daypart initially. Let Meta optimize 24/7 for 30 days, then analyze hourly performance data. Only implement dayparting if you see clear dead zones with zero conversions.
- **2026 reality:** Meta's algorithm already de-prioritizes low-conversion hours. Manual dayparting often hurts more than it helps because you lose data from off-peak hours that might convert at lower CPMs.

### Weekend vs Weekday
- Expect higher CPMs on weekends (more competition)
- But also potentially higher conversion rates for food delivery (people plan meals on weekends)
- **Don't adjust budgets by day of week.** Let CBO handle this automatically.

### Monthly Budget Pacing

**At RM6,000/day average:**
- Monthly budget: ~RM180,000 (~$42,000 USD)
- Week 1 of month: RM5,000/day (conservative start)
- Week 2-3: RM6,000-6,500/day (peak performance)
- Week 4: RM6,500-7,000/day (push if CPA is stable)

### Seasonal Spikes — Malaysia Calendar

| Period | Strategy | Budget Adjustment |
|--------|----------|------------------|
| **Ramadan** (Feb-Mar 2026) | Peak meal delivery demand. Launch Ramadan-specific creatives 2 weeks before. Sahur/Iftar messaging. | +30-50% budget |
| **Hari Raya Aidilfitri** (Mar 2026) | High gift/family meals demand. Family plan push. | +20-30% budget |
| **CNY** (Jan-Feb) | Chinese audience targeting. Reunion dinner sets. | +15-20% (Chinese audience segments) |
| **School holidays** | Family meal plans, convenience messaging. | +10-15% |
| **11.11 / 12.12** | Promo-driven campaigns. Bundle offers. | +20-30% with promo creative |
| **Christmas/New Year** | Party/gathering meal sets. | +10-15% |

**Ramadan-specific creative strategy:**
- First week: Reflective, brand-building content
- Mid-Ramadan: Shift to conversion-focused
- Final week: Urgency messaging, Raya prep
- **Peak ad engagement:** Last hour before Iftar and after Tarawih prayers
- 85% of Malaysian Muslims increase online shopping during Ramadan

---

## 13. WHAT $1M+/MONTH BRANDS DO DIFFERENTLY

### Common Patterns Across Top Meta Spenders

**1. Radical Account Simplification**
- 2-4 campaigns maximum (not 15-20)
- Broad targeting as default (not interest stacking)
- Let the algorithm do the work — feed it great creative, not micro-audiences

**2. Creative Volume is the Growth Lever**
- 50-100+ ads live at any time
- 15-30 new creatives launched per week
- Dedicated creative team producing daily
- Creative is the new targeting — different ads attract different audiences automatically

**3. Systematic Testing Infrastructure**
- Dedicated test campaign with fixed 15-20% of budget
- Clear promotion criteria (not gut feel)
- Post ID preservation when moving winners
- Kill underperformers fast (within 3 days)

**4. First-Party Data Obsession**
- CAPI implemented with 8.0+ Event Match Quality
- Customer lists uploaded weekly (not monthly)
- Value-based optimization enabled
- Server-side tracking as primary (not backup)

**5. Attribution Stack**
- Don't rely on Meta's reporting alone
- Use third-party attribution: Triple Whale ($199-399/mo for brands at your spend level) or Cometly
- Compare Meta-reported ROAS vs actual ROAS (Meta typically over-reports by 15-30%)
- Set up UTM parameters on every ad for Google Analytics cross-reference

**6. Creative Diversity Mandate**
- Different formats: static, video, carousel, Reel, UGC, founder story, testimonial
- Different angles: weight loss, convenience, taste, health, time-saving, cost comparison
- Different tones: aspirational, educational, fear-based, social proof
- Meta's Andromeda algorithm rewards genuine creative diversity — if all ads look the same, it picks one and ignores the rest

### Tools Used by Top Spenders

| Tool | Purpose | Price Range | Recommendation for Mirra |
|------|---------|-------------|--------------------------|
| **Triple Whale** | Attribution, analytics | $199-399/mo | YES — best for $10-40M brands |
| **Motion** | Creative analytics | $199/mo | YES — identifies which creative elements drive performance |
| **Foreplay** | Ad swipe file / spy tool | $49-99/mo | NICE TO HAVE — saves competitor ads |
| **Minea** | Product/ad research | $49-99/mo | OPTIONAL |
| **Hyros** | Deep attribution | $399+/mo | OVERKILL at your spend level |
| **Northbeam** | MMM + attribution | $1,000+/mo | OVERKILL — for $40M+ brands |

---

## 14. NAMING CONVENTIONS THAT SCALE

### Campaign Level
```
{BRAND}_{TYPE}_{PURPOSE}_{DATE}
```
Examples:
- `MIRRA_MANUAL_Test_Mar26`
- `MIRRA_MANUAL_Scale_Mar26`
- `MIRRA_ASC_Prospecting_Mar26`
- `MIRRA_MANUAL_Retarget_Mar26`

### Ad Set Level
```
{AUDIENCE}_{GEO}_{AGE}_{GENDER}_{BID}_{BUDGET}
```
Examples:
- `Broad_KLSEL_18-55_AllGender_LowestCost_RM500`
- `LAL1pct-Purch_KLSEL_18-55_Female_CostCap75_RM750`
- `RT-ATC7d_KLSEL_18-55_All_LowestCost_RM200`
- `RT-WV14d-Engage30d_KLSEL_18-55_All_LowestCost_RM200`

### Ad Level
```
{CONCEPT}_{FORMAT}_{HOOK}_{VERSION}_{DATE}
```
Examples:
- `WeightLoss_Video_BeforeAfter_V1_Mar13`
- `LowCal_Static_PriceCompare_V2_Mar13`
- `Convenience_Carousel_3Steps_V1_Mar10`
- `Testimonial_UGC_MomStory_V3_Mar06`

### UTM Parameters (for every ad)
```
utm_source=meta
utm_medium=paid
utm_campaign={{campaign.name}}
utm_content={{ad.name}}
utm_term={{adset.name}}
```
Use Meta's dynamic parameters `{{campaign.name}}` etc. to auto-populate.

---

## 15. IMPLEMENTATION CHECKLIST — BUILD ORDER

### Week 0: Foundation (Before Launching Any Ads)
- [ ] Install Meta Pixel on all pages
- [ ] Set up CAPI (Gateway or server-side GTM)
- [ ] Verify event deduplication with Test Events tool
- [ ] Check Event Match Quality score (target 6.0+)
- [ ] Upload customer email list (existing subscribers)
- [ ] Create all Custom Audiences (see Section 5 table)
- [ ] Create Lookalike Audiences (1% and 3% of purchasers)
- [ ] Set up UTM parameter template
- [ ] Verify domain in Business Manager
- [ ] Prepare 15-20 launch creatives across multiple formats and angles

### Week 1: Launch Test Campaign
- [ ] Create `MIRRA_TEST_Creative` campaign (ABO, Lowest Cost)
- [ ] Launch 5-7 ad sets (1 creative each, RM150-210/day each)
- [ ] Total test budget: RM750-1,050/day
- [ ] Monitor daily but don't touch for 3 days

### Week 1-2: Launch Retargeting
- [ ] Create `MIRRA_RT_Retarget` campaign (CBO)
- [ ] Set up 3 retarget ad sets (ATC, WV+Engage, Customer reactivation)
- [ ] Budget: RM500-700/day
- [ ] Upload 3-4 retarget-specific creatives per ad set

### Week 2: Launch ASC
- [ ] Create `MIRRA_ASC_Advantage` campaign
- [ ] Upload customer list as existing customer definition
- [ ] Set existing customer cap at 10-15%
- [ ] Upload 10-15 best creatives (mix of test winners + new)
- [ ] Budget: RM1,250-1,750/day

### Week 2-3: Launch Scale Campaign
- [ ] Identify first batch of winning creatives from Test (ROAS > 3x, 15+ conversions)
- [ ] Create `MIRRA_SCALE_Winners` campaign (CBO, Cost Cap)
- [ ] Move winners via Post ID (preserve social proof)
- [ ] Start at RM2,500/day
- [ ] Begin 20% vertical scaling every 3-4 days

### Week 4+: Ongoing Operations
- [ ] Launch 10-15 new test creatives per week (Mon + Thu batches)
- [ ] Review test results every Monday — kill losers, promote winners
- [ ] Scale winners by 20% every 3-4 days
- [ ] Refresh retarget creatives every 2 weeks
- [ ] Upload customer list to Meta monthly
- [ ] Review hourly/daily performance patterns monthly
- [ ] Audit ASC existing customer spend weekly

---

## 16. KEY METRICS DASHBOARD

### Daily Monitoring
| Metric | Target | Action If Missed |
|--------|--------|-----------------|
| ROAS | 4-5x | If < 3x for 3 days, review creatives |
| CPA (Cost Per Purchase) | < RM80 | If > RM100, kill underperforming ads |
| CPM | < RM25 | If > RM35, audience fatigue — new creative needed |
| CTR (Link Click) | > 1.5% | If < 1%, creative isn't resonating — test new hooks |
| Frequency | < 2.5 | If > 3.0, creative fatigue — rotate new ads in |
| Conversion Rate | > 3% | If < 2%, landing page issue or wrong audience |

### Weekly Review
- Creative performance ranking (sort by ROAS, then by spend)
- Ad set learning phase status
- Audience overlap check (use Meta's Audience Overlap tool)
- Budget pacing vs monthly target
- New vs returning customer ratio (from ASC reporting)

### Monthly Review
- Total ROAS (Meta-reported vs third-party attribution)
- Customer acquisition cost vs lifetime value
- Creative fatigue trends (are CPMs rising?)
- Audience saturation signals
- Competitive landscape shifts

---

## SOURCES

- [Best Meta Ads Account Structure 2026 — Flighted](https://www.flighted.co/blog/best-meta-ads-account-structure-2026)
- [Best Meta Ads Account Structure 2026 — Adacted](https://adacted.com/blogs/growth-academy/best-meta-ads-account-structure)
- [Meta Ads Campaign Structure Best Practices — AdStellar](https://www.adstellar.ai/blog/meta-ads-campaign-structure-best-practices)
- [Meta Ads 2026: New Algorithm, Creative Strategy — Anchour](https://www.anchour.com/articles/meta-ads-2026-playbook/)
- [Meta Ads Strategy 2026: Why 2 Campaigns Scale Better — Metalla](https://metalla.digital/meta-ads-strategy-2026-blueprint/)
- [Advantage+ Sales Campaign Complete 2026 Playbook — Medium](https://medium.com/@tentenco/how-to-build-a-successful-campaign-with-metas-advantage-ai-the-complete-2026-playbook-befca729202b)
- [ASC Maximize Performance — CustomerLabs](https://www.customerlabs.com/blog/how-to-maximize-meta-ads-performance-using-advantage-sales-campaigns/)
- [ASC Best Practices — Disruptive Digital](https://disruptivedigital.agency/what-is-metas-advantage-shopping-and-best-practices-for-setting-up-campaigns/)
- [Scaling Meta Ads 2026: 10-20% Rule — Stormy AI](https://stormy.ai/blog/scaling-meta-ads-2026-openclaw-rule)
- [Facebook Ads Scaling: Vertical vs Horizontal — AdBid](https://adbid.me/blog/facebook-ads-scaling-strategies-2026)
- [How to Scale Meta Ads Safely — Expanse Digital](https://www.expansedigital.co/post/how-to-scale-meta-ads-safely-the-complete-guide-to-growing-your-budget-without-killing-your-cpa)
- [Meta Ads Learning Phase Struggles — AdStellar](https://www.adstellar.ai/blog/meta-ads-learning-phase-struggles)
- [Meta Ads Funnel Strategy: Full-Funnel Framework — Stackmatix](https://www.stackmatix.com/blog/meta-ads-funnel-strategy)
- [Meta Ads Full-Funnel Strategy — MetaMktg Agency](https://www.metamktgagency.com/blog/meta-ads-full-funnel-strategy)
- [Facebook CAPI 2026 — Triple Whale](https://www.triplewhale.com/blog/facebook-capi)
- [How to Set Up Meta CAPI — DataAlly](https://www.dataally.ai/blog/how-to-set-up-meta-conversions-api)
- [Meta CAPI Complete Guide — AdsUploader](https://adsuploader.com/blog/meta-conversions-api)
- [Meta Ads Attribution Changes 2026 — Dataslayer](https://www.dataslayer.ai/blog/meta-ads-attribution-window-removed-january-2026)
- [Meta Ads Attribution 2026 — Jon Loomer](https://www.jonloomer.com/meta-ads-attribution-2026/)
- [Meta Ads Bidding Strategies 2026 — Weboin](https://weboin.com/meta-ads-bidding-strategy-2026/)
- [Cost Cap vs Bid Cap — AdAmigo](https://www.adamigo.ai/blog/cost-cap-vs-bid-cap-cpa-strategy-guide)
- [Meta Ads Bidding Strategies Guide — Benly](https://benly.ai/learn/meta-ads/bidding-strategies-guide)
- [ABO vs CBO 2026 — AdsUploader](https://adsuploader.com/blog/abo-vs-cbo)
- [Creative Testing Framework 2026 — Motion](https://motionapp.com/blog/ultimate-guide-creative-testing-2025)
- [Meta Creative Testing 2026: Andromeda Era — Evolut Agency](https://evolutagency.com/meta-creative-testing-in-2026-the-andromeda-era/)
- [3:2:2 Creative Testing Method — AdsManagement](https://www.adsmanagement.co/blog/meta-ads-testing-methodology-the-3-2-2-creative-testing-method)
- [What Best DTC Ad Accounts Have in Common — Motion](https://motionapp.com/blog/best-dtc-ad-accounts)
- [51 Lessons from $200M+ DTC Sales — AdKings](https://www.adkings.agency/51-lessons-learned-from-200m-in-dtc-ecommerce-sales)
- [Meta Ads Targeting Options 2026 — Cropink](https://cropink.com/meta-ads-targeting-options)
- [Broad vs Interest Targeting 2026 — Expanse Digital](https://www.expansedigital.co/post/should-i-use-interest-targeting-in-2026)
- [Advantage+ Audience 2026 — AdNabu](https://blog.adnabu.com/facebook/meta-advantage-plus-audience/)
- [Advantage+ Placements 2026 — AdNabu](https://blog.adnabu.com/facebook/meta-advantage-plus-placements/)
- [Meta Ad Placements Optimization — Benly](https://benly.ai/learn/meta-ads/meta-ads-placements-optimization)
- [Meta Ads Naming Conventions — AdAmigo](https://www.adamigo.ai/blog/meta-ad-naming-conventions-guide)
- [Ad Creative Naming Conventions — AdManage](https://admanage.ai/blog/ad-creative-naming-conventions)
- [Meta Value Rules 2026 Guide — 1ClickReport](https://www.1clickreport.com/blog/meta-value-rules-2025-guide)
- [LTV and Profitability on Meta — Bamboo](https://www.growwithbamboo.com/post/efficient-growth-tips-ltv-and-profitability-on-meta)
- [Value Optimization Meta Setup — ROASPIG](https://roaspig.com/blog/set-up-value-optimization-meta)
- [Triple Whale vs Northbeam 2026 — Head West Guide](https://www.headwestguide.com/triple-whale-vs-northbeam)
- [Meta Ads Attribution Tracking Tools — AdStellar](https://www.adstellar.ai/blog/meta-ads-attribution-tracking-tools)
- [Ramadan Advertising 2026 Guide — VidenGlobe](https://videnglobe.com/blog/ramadan-advertising-guide)
- [Ramadan 2026 Consumer Insights Malaysia — YouGov](https://yougov.com/articles/54011-ramadan-2026-consumer-insights-5-key-findings-across-indonesia-malaysia-saudi-arabia-turkiye-and-the-uae)
- [Meta AEM Changes — Jon Loomer](https://www.jonloomer.com/qvt/aggregated-event-measurement-isnt-going-away/)
- [Meta AEM Explained — Conversios](https://www.conversios.io/blog/meta-aggregated-event-measurement/)
- [Facebook Dayparting — Jon Loomer](https://www.jonloomer.com/facebook-ad-scheduling/)
- [Facebook ROAS by Industry Benchmarks — Intensify](https://www.intensifynow.com/blog/facebook-ads-roas-by-industry-benchmarks/)
