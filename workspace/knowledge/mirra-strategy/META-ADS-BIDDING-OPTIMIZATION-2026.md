# META ADS BIDDING STRATEGIES & OPTIMIZATION — 2026 DEEP RESEARCH

**For:** Subscription business spending RM5,000–7,000/day (~USD 1,100–1,550/day)
**Date:** 2026-03-13
**Market:** Malaysia (MYR)

---

## 1. BID STRATEGIES COMPARED

### 1A. Lowest Cost (No Cap)

**What it does:** Meta bids whatever it takes to win auctions. No ceiling. Gets you the most results possible within your daily budget.

**Ads Manager setup:**
- Campaign level > Bid strategy > "Highest volume" (this IS Lowest Cost, renamed)
- No fields to fill — just set your daily/lifetime budget

**When to use:**
- New campaigns with zero baseline data
- Testing phase (first 7–14 days)
- When volume matters more than cost control
- To exit learning phase fast before switching strategies

**Pros:**
- Maximum delivery/volume
- Fastest learning phase exit
- Zero setup complexity
- Best for data collection

**Cons:**
- CPA fluctuates dramatically — can spike 2–3x during high-competition periods (Q4, Ramadan, CNY)
- No cost protection
- At RM5,000–7,000/day, you could burn significant budget on expensive conversions
- Once you scale budget, CPA tends to rise (diminishing returns)

**Performance data:** Average CPA variance of 30–50% day-to-day is normal. In competitive periods, can see 100%+ spikes.

---

### 1B. Cost Cap

**What it does:** You set a maximum *average* CPA. Meta dynamically bids above and below that cap, but keeps the average at or below your target.

**Ads Manager setup:**
- Campaign level > Bid strategy > "Cost per result goal"
- Enter your target CPA in the "Cost per result goal" field
- Example: If your target CPA is RM50, enter RM50

**How to set the cap amount:**
1. Run Lowest Cost for 7–14 days first
2. Calculate your average CPA from that data
3. Set Cost Cap at 80–100% of that average CPA
4. If CPA was RM45, set Cost Cap at RM36–45

**How it works in practice:**
- Meta might pay RM65 for one conversion and RM25 for another
- The AVERAGE stays at or below your cap
- Meta has flexibility to bid higher in auctions where it predicts high conversion probability

**When it works:**
- Scaling campaigns where you know your CPA target
- Maintaining profitability while increasing spend
- Competitive periods (gives Meta flexibility while protecting your average)
- At RM5,000–7,000/day — this is your primary scaling strategy

**When it fails:**
- Cap set too low (below what Meta can realistically achieve) — delivery throttles to near zero
- Not enough conversion volume to let the average math work out
- New campaigns with no baseline data (you won't know what cap to set)

**Critical warning:** If your cost cap is way below what Meta can realistically achieve, it will throttle delivery hard. Your ads might barely serve, or you get poor placements and low-quality clicks. Start at or slightly above your actual CPA, then tighten gradually.

---

### 1C. Bid Cap

**What it does:** Sets a HARD MAXIMUM per auction. Meta will never bid above this amount in any single auction. Unlike Cost Cap (which is an average), Bid Cap is absolute.

**Ads Manager setup:**
- Campaign level > Bid strategy > "Bid cap"
- Enter maximum bid amount per auction

**How to set:**
1. Your Bid Cap should be your maximum acceptable CPA
2. If you can't afford more than RM60 per conversion ever, set RM60
3. Factor in that you'll miss some auctions — delivery will be lower than Cost Cap

**Use cases (advanced only):**
- Short campaigns (flash sales, limited promos) where you can't afford learning time
- When you need predictable, never-exceed cost control
- Highly competitive niches where you've seen CPAs spike unpredictably
- When you have strong historical data and know exact auction dynamics

**Pros:**
- Absolute cost control — never overspend per conversion
- No learning phase waste (good for short campaigns)
- Predictable unit economics

**Cons:**
- Significantly reduced delivery volume
- Meta can't optimize as freely — misses potentially profitable auctions
- If set too low, delivery stops entirely
- Requires deep knowledge of your auction landscape
- Not recommended for most subscription businesses at this spend level

---

### 1D. ROAS Target (Minimum ROAS)

**What it does:** You set a minimum return on ad spend. Meta optimizes to hit that ROAS across the campaign lifetime.

**Ads Manager setup:**
- Campaign level > Performance goal > "ROAS goal" (previously "Minimum ROAS")
- Enter your target ROAS as a number (e.g., 2.0 means RM2 revenue per RM1 spent)
- Requires value optimization to be enabled (see 1E below)

**How to set the ROAS target:**
1. Calculate your breakeven ROAS: (Ad Spend / Revenue needed to break even)
2. For subscriptions: include projected LTV, not just first-purchase revenue
3. Start with a target 10–20% ABOVE your current ROAS performance
4. Gradually increase as the algorithm learns

**What happens when Meta can't hit it:**
- Delivery slows dramatically
- Budget goes unspent
- Campaign effectively pauses itself
- You must lower the ROAS target or the campaign dies

**For your RM5,000–7,000/day spend:**
- Only use after 28+ days of conversion data
- Need minimum 50 conversions/week with revenue data attached
- If your subscription is RM X/month, send that value with every Purchase event via CAPI

---

### 1E. Value Optimization

**What it does:** Instead of optimizing for conversion COUNT, optimizes for conversion VALUE. Finds users likely to spend more, not just users likely to convert.

**Ads Manager setup:**
- Ad set level > Optimization for ad delivery > "Value"
- Requires: Purchase events with revenue values being sent via Pixel + CAPI
- Must have 100+ attributed conversions with at least 5 distinct values in the past 14 days

**How it differs from ROAS Target:**
- Value Optimization = maximize total value (no floor)
- ROAS Target = maximize value but don't go below X return
- You can combine them: Value Optimization + ROAS Target

**Setup requirements for subscriptions:**
1. Send purchase value with every conversion event (e.g., first month subscription = RM89)
2. For LTV: use `predicted_ltv` parameter in your Purchase event
3. Need 100+ purchases with 5+ distinct values in 14 days
4. Sync subscription renewal data as offline conversions (this teaches Meta which subscribers retain)

**For subscription businesses specifically:**
- Send first subscription purchase as Purchase event with value
- Send renewals as offline conversions with value
- Use `predicted_ltv` parameter to signal LTV to Meta's algorithm
- Meta's LTV prediction needs minimum 50 conversions/week, ideally 90+ days of conversion data

---

## 2. BID STRATEGY BY CAMPAIGN TYPE

| Campaign Type | Recommended Bid Strategy | Why |
|---|---|---|
| **ASC (Advantage+ Shopping)** | Start Lowest Cost, then Cost Cap | ASC needs volume to learn. Let AI optimize first, then add cost control. ~50 conversions/week needed. |
| **Testing campaigns** | Lowest Cost (always) | Never cap bids during testing. You need volume + data, not efficiency. ABO budget structure. |
| **Scaling campaigns** | Cost Cap | Set cap at 90–100% of proven CPA. Increase budget 10–20% every 3–5 days. CBO budget structure. |
| **Retargeting campaigns** | Cost Cap or Lowest Cost | Warm audiences convert cheaply. Cost Cap prevents overpaying. If volume is low, use Lowest Cost. |
| **Win-back campaigns** | Lowest Cost or Cost Cap | With Advantage+, dedicated retargeting may be unnecessary — the algorithm re-engages lapsed users automatically. If manual, use Cost Cap at 120% of cold CPA (win-back costs more). |

**ASC-specific notes:**
- ASC uses AI to allocate budget across audiences and placements automatically
- Feed it strong first-party data via CAPI for faster learning
- Need ~50 conversions/week per campaign (not per ad set)
- Enhanced "Learning Phase Retention" in 2026 maintains bid stability after creative updates
- Use hybrid: ASC for broad scaling + manual campaigns for retargeting/testing/niche

---

## 3. THE LEARNING PHASE (2026)

### 3A. How Many Conversions to Exit?

**Standard rule (still applies in 2026):** ~50 optimization events within 7 days of the last significant edit.

**NEW in 2025/2026:** Meta lowered the requirement to just 10 conversions for:
- Purchase-optimized campaigns
- Mobile App Install campaigns
- This benefits smaller budgets and lower-volume advertisers

**For your spend level (RM5,000–7,000/day):** You should comfortably hit 50 conversions in 7 days. The 10-conversion minimum is less relevant to you.

### 3B. What Resets Learning Phase?

ANY of these "significant edits" trigger a reset:
- Budget changes greater than 20% in either direction
- Any modification to target audience
- Switching optimization event (e.g., Purchase to Add to Cart)
- Adding or removing ad creative
- Changing bid strategy
- Pausing campaign for 7+ days
- Modifying Value Rules (triggers new learning)

**Critical rule:** When you launch or make changes, commit to a 7-day hands-off period.

### 3C. How to Avoid Getting Stuck in Learning

1. **Budget formula:** Daily budget = Target CPA x 7 (minimum)
   - If CPA is RM50 → minimum RM350/day per ad set
   - At RM5,000–7,000/day total, you can run 10–20 ad sets comfortably

2. **Consolidate ad sets** — fewer ad sets = more conversions per ad set = faster learning exit

3. **Broader audiences** — use Advantage+ Audience rather than narrow interest stacks

4. **Limit creative variants** — 2–3 per ad set during learning, use proven elements

5. **Don't touch anything for 7 days** after launch

### 3D. Learning Phase by Bid Strategy

| Bid Strategy | Learning Phase Behavior |
|---|---|
| Lowest Cost | Fastest exit — no cost constraints, maximum delivery |
| Cost Cap | Slower if cap is tight — Meta throttles delivery to maintain average |
| Bid Cap | Slowest — hard cap limits auction wins, fewer conversions |
| ROAS Target | Variable — depends on how achievable target is |
| Value Optimization | Needs more data (100+ conversions with values) — longer initial learning |

### 3E. "Learning Limited" — What It Means & How to Fix

**What it means:** Your ad set can't get ~50 optimization events in 7 days. Meta is telling you the campaign structure makes successful learning mathematically impossible.

**How to fix:**

1. **Increase budget:** Daily minimum = (Average CPA x 50) / 7
   - Example: CPA RM60 → minimum daily = (60 x 50) / 7 = RM429/day per ad set

2. **Consolidate ad sets:** Merge similar audiences. Fewer ad sets = more budget concentration.

3. **Broaden targeting:** Remove restrictions. Let Advantage+ find your audience.

4. **Switch to higher-funnel event temporarily:**
   - If only getting 2–3 purchases/day, optimize for Add to Cart or Initiate Checkout
   - These have higher volume → hit 50 events faster
   - Switch back to Purchase once learning exits

5. **Increase bid/cap:** If using Cost Cap or Bid Cap, your limit may be too restrictive.

6. **Reduce creative count:** Too many ads splits the conversion signal.

---

## 4. BUDGET OPTIMIZATION (CBO vs ABO)

### 4A. CBO (Campaign Budget Optimization / Advantage Campaign Budget)

**What it does:** You set ONE budget at campaign level. Meta distributes it across ad sets based on predicted performance in real-time.

**When to use CBO:**
- Scaling proven winners
- When you've validated which creatives and audiences work
- When you don't have time to monitor daily (CBO auto-optimizes)
- RM5,000–7,000/day scaling campaigns

**How CBO distributes budget:**
- Allocates more to ad sets with better predicted performance
- Can allocate very unevenly (e.g., 80% to one ad set, 5% to another)
- Processes signals across all ad sets simultaneously
- Shifts spend toward predicted winners in real-time

**CBO minimum spend settings:**
- You CAN set minimum/maximum spend per ad set within CBO
- Use minimum spend to ensure each ad set gets enough budget to learn
- Minimum = CPA x 7 per ad set (so each can exit learning)
- Example: 4 ad sets, CPA RM50 → set min RM350/ad set → RM1,400 minimum, rest floats

### 4B. ABO (Ad Set Budget Optimization)

**What it does:** You set a fixed budget PER ad set. Each ad set spends exactly what you allocate, regardless of performance.

**When to use ABO:**
- Testing new audiences or creatives (ensures equal spend per variant)
- Newer accounts with little historical data
- When you want controlled, even spending across all tests
- Creative testing campaigns

**Key advantage:** Forced equal distribution — every creative/audience gets the same budget for fair comparison.

### 4C. The Hybrid Approach (Recommended for RM5,000–7,000/day)

```
TESTING CAMPAIGN (ABO) — RM500–1,000/day
├── Ad Set 1: Creative Test A — RM150/day
├── Ad Set 2: Creative Test B — RM150/day
├── Ad Set 3: Creative Test C — RM150/day
└── Ad Set 4: Audience Test — RM150/day

SCALING CAMPAIGN (CBO) — RM4,000–6,000/day
├── Ad Set 1: Best Audience + Winners (Meta allocates freely)
├── Ad Set 2: Lookalike Audience + Winners
└── Ad Set 3: Broad + Winners
    (CBO auto-distributes across these based on performance)
```

### 4D. Budget-to-Bid Strategy Relationship

| Budget Level | Recommended Strategy |
|---|---|
| RM500–1,000/day (testing) | Lowest Cost + ABO |
| RM1,000–3,000/day (moderate) | Cost Cap + CBO |
| RM3,000–7,000/day (scaling) | Cost Cap + CBO (with ad set minimums) |
| RM7,000+/day (aggressive) | Cost Cap or ROAS Target + CBO + Value Rules |

---

## 5. CONVERSION OPTIMIZATION SETTINGS

### 5A. Which Event to Optimize For

| Scenario | Optimize For | Why |
|---|---|---|
| **Subscription purchase (primary)** | Purchase | Directly optimizes for the event that makes money |
| **Low purchase volume (<50/week)** | Add to Cart or Initiate Checkout | Higher volume → exits learning faster. Switch to Purchase once volume grows |
| **High-value subscription tiers** | Purchase + Value Optimization | Finds users who choose higher-value plans |
| **App subscriptions** | Subscribe event (custom) | Track subscription start as custom event with value |

**When to optimize for higher-funnel events:**
- ONLY when Purchase volume is too low to exit learning (<50/week)
- Temporary measure — always migrate back to Purchase
- Higher-funnel optimization brings more leads but lower quality
- For your spend level (RM5,000–7,000/day), you should have enough volume for Purchase optimization

**When NOT to optimize higher-funnel:**
- If you're already getting 50+ purchases/week
- If your funnel has a large drop-off between Add to Cart and Purchase (optimizing ATC brings volume but not buyers)

### 5B. Attribution Windows

**Default (recommended for most):** 7-day click, 1-day view

| Attribution Window | Best For | Your Subscription Business |
|---|---|---|
| **7-day click, 1-day view** | Standard e-commerce, subscriptions | **USE THIS** — subscribers often research before buying |
| **1-day click** | Impulse purchases, flash sales, AOV under ~RM50 | Not ideal for subscriptions |
| **7-day click only** | High-consideration purchases | Good alternative if view-through over-attributes |

**For subscriptions specifically:**
- Use 7-day click, 1-day view (the default)
- Subscription decisions often involve research/comparison → 7-day click captures this
- If you see over-attribution, test removing 1-day view

### 5C. Conversion Value Optimization for Subscriptions

**Setup checklist:**
1. Pixel + CAPI sending Purchase events with value (e.g., `value: 89, currency: 'MYR'`)
2. Different subscription tiers = different values (e.g., Basic RM49, Premium RM89, Annual RM799)
3. Need 100+ attributed conversions with 5+ distinct values in 14 days
4. Sync renewal data as offline conversions
5. Use `predicted_ltv` parameter for LTV signaling

**Practical steps in Ads Manager:**
1. Ad set > Optimization for ad delivery > select "Value"
2. Optionally add ROAS goal
3. Ensure your conversion event (Purchase) is sending monetary values
4. Wait 14 days for sufficient data before evaluating

---

## 6. DELIVERY OPTIMIZATION

### 6A. Accelerated vs Standard Delivery

**Status in 2026:** Accelerated delivery appears to still be available on Meta (unlike Google Ads, which removed it in 2019). However, Meta strongly pushes Standard delivery and Advantage+ automation.

- **Standard delivery** (recommended): Paces spend evenly throughout the day. Reaches diverse audiences at different times. Prevents budget exhaustion early in the day.
- **Accelerated delivery**: Spends budget as fast as possible. Use ONLY for time-sensitive campaigns (flash sales, event promotions). Risk: exhausts budget by midday, missing evening/night audiences.

**For RM5,000–7,000/day:** Use Standard delivery. At this spend level, accelerated would burn through budget too fast and miss profitable evening traffic.

### 6B. Ad Scheduling with Advantage+

Ad scheduling (dayparting) is limited with Advantage+ campaigns. Advantage+ controls delivery timing automatically based on predicted conversion probability.

For manual campaigns:
- Keep ads on a custom schedule to decrease ad frequency
- Test time-of-day performance first before implementing
- Malaysian prime times: 10am–12pm, 8pm–11pm (food content)
- Weekend mornings tend to have lower CPMs

### 6C. Audience Saturation Signals

**Watch for these indicators:**
- Frequency rising above 3–4 (for cold audiences) or 6–8 (for retargeting)
- CTR declining while frequency increases
- CPM increasing without corresponding CTR improvement
- Conversion rate dropping despite stable traffic

**Why it happens faster in 2026:** Meta's Andromeda engine concentrates spend aggressively behind winning creatives, which accelerates audience saturation.

**How to monitor:** Use Facebook Delivery Insights > Audience Saturation metric (measures % of audience seeing your ad for first time)

### 6D. When Delivery Stalls — Diagnosis & Fixes

| Symptom | Likely Cause | Fix |
|---|---|---|
| Zero or near-zero delivery | Bid/cap too restrictive | Raise Cost Cap/Bid Cap by 20% |
| Delivery drops after first day | Failed learning phase | Increase budget to CPA x 7 per ad set |
| Delivery drops after 1–2 weeks | Audience saturation or creative fatigue | Refresh creatives (new hooks, angles) |
| Intermittent delivery | Budget too low for bid strategy | Increase daily budget or remove cap |
| Delivery concentrated in first half of day | Accelerated delivery on or budget pacing issue | Switch to Standard delivery |
| Learning Limited status | Not enough conversions | See Section 3E above |

---

## 7. ADVANCED TACTICS

### 7A. Cost Cap Management (Not "Surfing" — Proper Approach)

The common advice of "start low and raise gradually" is actually **backwards**. The correct approach:

1. **Start at or above your actual CPA** (from Lowest Cost data)
2. **Tighten gradually** — lower the cap once you see consistent performance
3. If you start too low, Meta throttles delivery, you get poor placements and junk clicks
4. Decrease by 5–10% every 3–5 days as long as delivery remains stable

**Budget scaling with Cost Cap:**
- Increase budget by 10–20% max every 3–5 days
- Wait for delivery to stabilize between increases
- Never jump more than 20% — resets learning phase
- If CPA rises after increase, hold (don't lower cap AND raise budget simultaneously)

### 7B. Campaign Budget Rebalancing

For CBO campaigns where Meta over-concentrates on one ad set:
- Set minimum spend per ad set (CPA x 7)
- Set maximum spend cap on dominant ad set (prevents 90/10 splits)
- Create separate campaigns for audiences that need guaranteed budget
- Check allocation daily for first 7 days

### 7C. Multiple Optimization Events in One Account

You CAN optimize different campaigns for different events:
- Campaign 1: Optimize for Purchase (main scaling)
- Campaign 2: Optimize for Lead (email capture)
- Campaign 3: Optimize for Add to Cart (retargeting feed)

**Important:** Each campaign's pixel events are independent. Having an ATC-optimized campaign doesn't dilute your Purchase-optimized campaign.

### 7D. Value Rules for Segment-Level Bidding

**What they are:** Bid multipliers that adjust how much Meta bids for specific audience segments.

**Setup in Ads Manager:**
- Account Settings > Value Rules (or within campaign setup)
- Segments available: Age, Gender, OS, Location, Placement

**How to configure:**
- Increase bids for high-value segments: e.g., +60% for iOS users aged 25–34
- Decrease bids for low-value segments: e.g., -40% for users under 18
- Range: increase up to 1,000%, decrease up to 90%
- If a user matches multiple rules, only the FIRST applicable rule applies

**For your subscription business:**
```
Example Value Rules:
├── iOS users, Age 25-44, KL/Selangor: +50% bid
├── iOS users, Age 25-44, other states: +30% bid
├── Android users, Age 25-44: +10% bid
├── Age 18-24: -20% bid
└── Age 45+: -30% bid (adjust based on your data)
```

**Best practices:**
- Start with ±30–50% adjustments
- If a Value Rule isn't improving segment ROAS within 21 days, remove it
- Adding/modifying Value Rules triggers new learning phase
- Batch your changes — wait 7–14 days between adjustments

### 7E. Creative Scaling (the Real Driver in 2026)

Meta's Andromeda algorithm has made creative the #1 lever, more impactful than bid strategy:
- Maintain 8–12 active creative variations per campaign
- Refresh 25–30% of creative library monthly
- Each product should exist in multiple formats with diverse messaging angles
- When a winner starts fatiguing, refresh the hook — not the campaign settings
- Launch 5–10 new creatives per week in your testing campaign

---

## 8. MALAYSIA-SPECIFIC CONSIDERATIONS

### 8A. Typical CPMs in Malaysia (2025–2026)

| Category | CPM Range (RM) | Notes |
|---|---|---|
| General average | RM8–50 | Wide range based on industry |
| Food & Beverage | RM10–25 | Your likely range |
| E-commerce | RM15–35 | Higher competition |
| Finance/Insurance | RM25–50 | Most expensive vertical |
| Local services | RM8–15 | Lowest competition |
| Subscription/SaaS | RM15–30 | Moderate competition |

### 8B. Typical CPC in Malaysia (2025–2026)

| Category | CPC Range (RM) | Notes |
|---|---|---|
| General average | RM0.50–5.00 | |
| Low competition (local F&B) | RM0.50–1.00 | |
| Medium competition (e-commerce) | RM1.00–3.00 | |
| High competition (finance, real estate) | RM2.00–6.00 | |
| Subscription services | RM1.00–3.00 | Estimated for your vertical |

### 8C. Best Performing Bid Strategies for Malaysia

1. **Lowest Cost** — works well because Malaysian CPMs are relatively low vs. Western markets. Good for volume.
2. **Cost Cap** — ideal for scaling. Malaysian market has enough audience size in Klang Valley for Meta to optimize effectively.
3. **ROAS Target** — less commonly used in Malaysia due to smaller conversion volumes vs. US/UK, but viable at RM5,000–7,000/day.

### 8D. Currency & Payment

- Meta bills in MYR for Malaysian payment methods
- Credit card payments in MYR — no conversion fees
- Payment threshold starts low, increases with account history
- At RM5,000–7,000/day, you'll likely hit payment threshold daily — ensure sufficient credit limit
- Consider multiple payment methods as backup (Meta can reject charges and pause campaigns)

### 8E. Local Attribution Challenges

- Malaysian users frequently switch between mobile and desktop — cross-device attribution is weaker
- Many purchases happen via WhatsApp/DM after clicking ads — these are NOT automatically tracked
- Set up WhatsApp click tracking as a custom conversion event
- Use UTM parameters + CAPI for offline-to-online attribution
- Ramadan, CNY, Hari Raya, and school holidays dramatically shift CPMs (plan budget accordingly)

### 8F. Seasonal CPM Fluctuations (Malaysia)

| Period | CPM Impact | Strategy |
|---|---|---|
| CNY (Jan–Feb) | +20–40% | Reduce spend or tighten caps |
| Ramadan (Feb–Mar 2026) | +15–30% | Food content performs well but competition high |
| Hari Raya (Mar–Apr) | +30–50% | Peak competition — consider pausing testing |
| 11.11 / 12.12 sales | +40–60% | Worst CPMs of the year |
| Jan, May, Aug (quiet) | -10–20% | Best time to scale aggressively |

---

## 9. RECOMMENDED SETUP FOR RM5,000–7,000/DAY SUBSCRIPTION BUSINESS

### Phase 1: Data Collection (Week 1–2)
```
Campaign: Testing (ABO)
├── Budget: RM1,000/day
├── Bid strategy: Lowest Cost (no cap)
├── Optimization: Purchase
├── Attribution: 7-day click, 1-day view
├── 3–4 ad sets with different audiences
├── 3 creatives per ad set
└── Goal: Collect CPA baseline data, exit learning phase
```

### Phase 2: Scale with Control (Week 3+)
```
Campaign 1: Scaling (CBO)
├── Budget: RM4,000–5,500/day
├── Bid strategy: Cost Cap (set at 90% of Phase 1 avg CPA)
├── Optimization: Purchase
├── 2–3 ad sets with proven audiences
├── Winning creatives from Phase 1
├── Ad set minimums: CPA x 7 each
└── Scale budget by 15–20% every 4–5 days

Campaign 2: Testing (ABO)
├── Budget: RM500–1,000/day
├── Bid strategy: Lowest Cost
├── 5–10 new creatives per week
└── Winners graduate to Campaign 1
```

### Phase 3: Value Optimization (Week 6+ / when you have 100+ purchases with values)
```
Campaign 1: Scaling (CBO)
├── Switch to Value Optimization + ROAS Target
├── ROAS target: 10–20% above current ROAS
├── Send subscription values + LTV data via CAPI
├── Add Value Rules for high-value segments
└── Budget: RM4,000–6,000/day

Campaign 2: ASC (Advantage+ Shopping)
├── Budget: RM1,000–2,000/day
├── Let Meta's AI handle everything
├── Feed strong first-party data
└── Use as discovery/broad reach engine
```

### Key Daily Checklist
- [ ] Check CPA vs Cost Cap target (within 10%?)
- [ ] Check frequency (below 3 for cold, below 7 for retargeting?)
- [ ] Check learning phase status (Learning, Active, Learning Limited?)
- [ ] Check creative performance (any fatigue signals?)
- [ ] Check budget pacing (spending full daily budget?)
- [ ] Check CBO allocation (any ad set starved?)

---

## SOURCES

- [Meta Ads Bidding 2026 — Weboin](https://weboin.com/meta-ads-bidding-strategy-2026/)
- [Cost Cap vs Bid Cap CPA Strategy — AdAmigo](https://www.adamigo.ai/blog/cost-cap-vs-bid-cap-cpa-strategy-guide)
- [Bid Cap vs Cost Cap 2026 — TwoOwls](https://twoowls.io/blogs/bid-cap-and-cost-cap/)
- [Meta Ads Bidding Strategies 2026 — Spinta Digital](https://spintadigital.com/blog/meta-ads-bidding-strategies-2026/)
- [Meta Bid Strategies Explained — Dancing Chicken](https://www.dancingchicken.com/post/meta-bid-strategies-explained-pros-and-cons)
- [About Bid Cap — Meta Help Center](https://www.facebook.com/business/help/272503946776144)
- [Facebook Ads Bid Strategies — Jon Loomer](https://www.jonloomer.com/facebook-ads-bid-strategies/)
- [Meta Ads Bidding Strategies — Benly.ai](https://benly.ai/learn/meta-ads/bidding-strategies-guide)
- [Meta Lowers Learning Phase Requirement — Madgicx](https://madgicx.com/blog/meta-lowers-learning-phase-requirement-for-select-campaigns)
- [Learning Phase Struggles 2026 — AdStellar](https://www.adstellar.ai/blog/meta-ads-learning-phase-struggles)
- [Learning Limited — Meta Help Center](https://www.facebook.com/business/help/269269737396981)
- [ABO vs CBO 2026 — Ads Uploader](https://adsuploader.com/blog/abo-vs-cbo)
- [CBO vs ABO 2026 — Gradezilla](https://gradezilla.org/cbo-vs-abo-in-meta-ads-which-budget-strategy-wins-in-2026/)
- [CBO Facebook Ads 2026 — Cropink](https://cropink.com/cbo-facebook-ads)
- [About ROAS Goal — Meta Help Center](https://www.facebook.com/business/help/1113453135474912)
- [Meta Value Rules 2026 — 1ClickReport](https://www.1clickreport.com/blog/meta-value-rules-2025-guide)
- [Value Rules Deep Dive — Jon Loomer](https://www.jonloomer.com/value-rules/)
- [Meta Bid Multipliers Setup — Madgicx](https://madgicx.com/blog/meta-bid-multipliers)
- [About Value Rules — Meta Help Center](https://www.facebook.com/business/help/535014515741813)
- [Meta Ads CPM CPC Benchmarks by Country 2026 — AdAmigo](https://www.adamigo.ai/blog/meta-ads-cpm-cpc-benchmarks-by-country-2026)
- [Facebook Ads Cost Malaysia — Shopify MY](https://www.shopify.com/my/blog/facebook-ads-cost)
- [Facebook Advertising Cost Malaysia — Newnormz](https://www.newnormz.com.my/facebook-advertisting-cost-in-malaysia/)
- [Facebook Ads Malaysia Guide — Iffah Ishak](https://iffahishak.com/facebook-ads-malaysia-a-complete-guide-to-costs-strategies-success-in-2025/)
- [Meta Ads Attribution Setting — Jon Loomer](https://www.jonloomer.com/meta-ads-attribution-setting-a-complete-guide/)
- [Meta Value Optimization — Birch](https://bir.ch/blog/meta-value-optimization)
- [Acquiring Subscription Customers with Meta — SeaMonster Studios](https://seamonsterstudios.com/2025/04/18/acquiring-subscription-customers-with-meta-ads/)
- [Meta Ads LTV Prediction — Madgicx](https://madgicx.com/blog/meta-ads-ltv-prediction)
- [Optimization for Ad Delivery 2026 — Cropink](https://cropink.com/optimization-for-ad-delivery-meta)
- [Meta Ads Audience Saturation — AdAmigo](https://www.adamigo.ai/blog/meta-ads-audience-saturation-causes-and-fixes)
- [Facebook Ads Not Delivering 2026 — SuperAds](https://www.superads.ai/blog/facebook-ads-not-delivering)
- [Cost Cap Strategy — Motion App](https://motionapp.com/blog/cost-caps-facebook-ads)
- [Advanced Scaling Facebook Ads — Social Media Examiner](https://www.socialmediaexaminer.com/advanced-scaling-with-facebook-ads/)
- [Meta Ads Strategy 2026 Blueprint — Metalla](https://metalla.digital/meta-ads-strategy-2026-blueprint/)
- [Advantage+ Complete 2026 Playbook — Medium](https://medium.com/@tentenco/how-to-build-a-successful-campaign-with-metas-advantage-ai-the-complete-2026-playbook-befca729202b)
- [Meta Ads Best Practices 2026 — Flighted](https://www.flighted.co/blog/meta-ads-best-practices)
