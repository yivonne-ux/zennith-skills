# Meta Ads Deep Research 2026
**Date:** 2026-03-19
**Purpose:** Data-driven intelligence for Pinxin Vegan campaign optimization

---

## 1. Advantage+ Shopping Campaigns (ASC) vs Manual Campaigns

### Performance Data
- ASC delivers **22% average ROAS lift** over manual campaigns (Meta internal data)
- E-commerce brands on ASC saw **70% YoY growth** vs previous manual setups
- Advantage+ tools lower **cost per result by up to 44%**
- Manual campaigns can achieve **up to 47% lower CPM** in controlled scenarios
- Switching to Advantage+ cuts **CPA by up to 32%**, especially in ecommerce and lead gen

### 2026 Consensus: Hybrid Strategy Wins
Neither pure ASC nor pure manual is optimal. The best structure:
- **ASC** for broad prospecting and scaling (let algorithm find buyers)
- **Manual CBO** for retargeting, strict lead-quality control, and bottom-of-funnel
- **Manual ABO** for creative testing with controlled budget allocation

### When to Use Each
| Use Case | Best Approach |
|----------|--------------|
| Broad prospecting | Advantage+ Sales Campaign |
| Creative testing | Manual ABO, controlled budget |
| Retargeting | Manual CBO with custom audiences |
| High-ticket/lead quality control | Manual with strict targeting |
| Scaling proven creatives | ASC with broad targeting |

### Pinxin Implication
Run ASC for main prospecting (frozen dishes to broad MY+SG audience). Keep manual CBO for CTWA retargeting where lead quality matters. Test creatives in manual ABO before graduating winners to ASC.

---

## 2. Creative Volume & Testing

### Optimal Creatives Per Ad Set
- **3-5 creatives per ad set** for testing (isolate one variable at a time)
- **8-12 active creative variations per campaign** for scaling
- **25-30% of creative library should refresh monthly**
- **10-15 conceptually distinct assets per Advantage+ campaign** (for Andromeda)

### Creative Fatigue Thresholds (2026 Andromeda Era)
| Frequency | Action |
|-----------|--------|
| 1.8-2.5 | Monitor CTR and hook rate carefully |
| 2.5-3.5 | Begin rotating new creative variants |
| 3.5+ | Immediate creative refresh required |

### Fatigue Detection Rules
- **CTR drops 20%+ from 7-day peak** over 3-day rolling window = fatigue beginning
- **CTR drops to 1.9% or below** for 3 consecutive days = flag creative
- Most creatives in narrow audiences start declining at **days 14-21**
- Post-Andromeda: creative refreshes needed **every 1-3 weeks** (not monthly)

### Budget Distribution
- Meta auto-distributes budget toward winning creatives within an ad set
- Andromeda evaluates each creative's Entity ID separately
- 50 variations of same concept = 1 Entity ID = wasted volume
- 10 truly distinct concepts = 10 Entity IDs = 10x auction eligibility

### Production Cadence
- Introduce **3-5 new creative concepts every 2 weeks**
- Batch create **15-20 variations per month** using templates
- Block 4 hours monthly for batch creation

---

## 3. Learning Phase in 2026

### Exit Requirements
- **50 optimization events within 7 days** (unchanged from previous years)
- Each ad set needs roughly **5 conversions per day minimum**
- Advantage+ campaigns need **7-14 days** to fully stabilize

### Budget Formula
```
Minimum daily budget = (Target CPA x 50) / 7
Example: RM30 CPA target = (RM30 x 50) / 7 = RM214/day minimum per ad set
```

### What Resets Learning Phase
1. Budget change > 20% in a single edit
2. Changing targeting parameters
3. Adding or removing ads
4. Modifying the optimization event
5. Pausing for 7+ days
6. Changing bid strategy

### Pause/Unpause Rules
- **Pausing 7+ days = full learning phase restart**
- Pausing < 7 days = resumes without full reset (but performance may dip)
- Never pause/unpause repeatedly -- this compounds instability

### Best Practices
- Commit to **7-day hands-off period** after launch
- Make budget changes in **<20% increments**
- Consolidate ad sets to pool conversion data faster
- Use broader targeting to reach 50 events faster
- If optimizing for purchases with low conversion rate, consider optimizing for add-to-cart first

### Pinxin Implication
At RM1,200/day budget across campaigns, ensure each ad set has minimum RM214/day for RM30 CPA target. Max 5-6 ad sets running simultaneously. No budget changes during first 7 days.

---

## 4. Broad Targeting vs Interest Targeting

### 2026 Data
- **65% of U.S. advertisers** now use Advantage+ as primary growth engine
- Switching to Advantage+ broad targeting cuts **CPA by up to 32%**
- Meta's algorithm finds buyers more effectively than manual interest targeting
- Broad targeting + first-party signals = the new standard

### Why Broad Wins Now
- Andromeda processes **10,000x more data** per impression than previous system
- Algorithm uses billions of behavioral signals across FB, IG, Messenger, WhatsApp
- Interest-based micro-segmentation **limits Meta's AI learning**
- Creative IS the targeting now -- different creatives attract different audiences

### When Interest Targeting Still Works
- Very niche B2B audiences
- Geographic restrictions (e.g., 10km radius delivery zones)
- Exclusion-based strategies (exclude existing customers)
- Small budgets that can't afford broad exploration phase

### Audience Size Guidelines
- **Minimum 500,000 estimated audience** for prospecting ad sets
- Smaller audiences = stuck in learning phase
- Broader = better for Andromeda's retrieval system

### Pinxin Implication
Use broad targeting for MY + SG prospecting. Let creative (food visuals, CN/EN copy, pricing) do the targeting work. Only narrow for geo-restrictions (delivery zones). Advantage+ audience for all prospecting campaigns.

---

## 5. Bidding Strategies: ROAS vs Cost Cap vs Bid Cap

### Strategy Comparison
| Strategy | How It Works | Best For | Risk |
|----------|-------------|----------|------|
| **Lowest Cost** (default) | Meta spends full budget at lowest possible CPA | Learning phase, new campaigns | No cost ceiling |
| **Cost Cap** | Targets average CPA, allows individual bid variance | Scaling with ROAS control | May under-deliver if cap too tight |
| **Bid Cap** | Hard maximum on every single auction bid | Strict per-acquisition limits | Severely limits delivery |
| **Minimum ROAS** | Sets floor ROAS threshold per auction | E-commerce with variable AOV | Under-delivery if target too high |

### 2026 Recommendations
1. **Start with Lowest Cost** -- let Meta learn without constraints during learning phase
2. **Graduate to Cost Cap** once you know your target CPA from data (typically after 2-3 weeks)
3. **Use Minimum ROAS** for e-commerce with significant AOV variation
4. **Avoid Bid Cap** unless you have very specific per-conversion economics

### Cost Cap Best Practices
- Set cost cap at **1.2-1.5x your actual target CPA** to give algorithm room
- Don't set it at exactly your target -- algorithm needs headroom
- If delivery drops, raise cap by 10-20% incrementally

### Minimum ROAS (New in late 2025)
- Set minimum ROAS threshold (e.g., 2.5x)
- Meta's AI prioritizes auctions likely to meet or exceed that ratio
- Powerful for variable purchase values (e.g., different dish bundles)
- Requires strong purchase value data feeding back via CAPI

### Pinxin Implication
Start campaigns on Lowest Cost for first 2 weeks. Once CPA stabilizes, apply Cost Cap at 1.3x actual CPA. For CTWA campaigns where conversion value varies, test Minimum ROAS bidding once CAPI is fully integrated.

---

## 6. Holiday/Seasonal Ads Strategy

### CPM Impact During Peaks
- CPMs rise **20-80%+** during major shopping seasons (Black Friday, Chinese New Year, etc.)
- Competition for ad inventory increases significantly
- Reels and Stories formats see **less CPM inflation** than feed placements

### Avoiding Algorithm Resets During Low Periods
**DO NOT:**
- Pause campaigns for 7+ days (triggers full learning reset)
- Cut budget by more than 20% in one edit
- Change targeting or optimization events during transition

**DO:**
- Reduce budget gradually (max 20% per edit, wait 48-72 hours between changes)
- Keep campaigns running at reduced spend rather than pausing
- Use automated rules with seasonal tolerance (e.g., accept higher CPA during CNY)
- Pre-build creative for seasonal periods 4+ weeks ahead

### Budget Consistency Principle
Meta's algorithm favors consistent spending over irregular bursts:
- **Better:** RM100/day for 30 days
- **Worse:** RM1,000/day for 3 days, then pause

### Seasonal Transition Strategy
- 4 weeks before peak: Launch awareness/video campaigns to warm audiences
- 2 weeks before: Ramp budget by 15-20% increments every 3 days
- During peak: Maintain steady budget, accept higher CPMs
- After peak: Reduce budget gradually (20% max per edit), never hard pause
- Low season: Run at minimum viable budget to preserve algorithm learning

### Pinxin Implication
Malaysia seasonal calendar: CNY (Jan-Feb), Hari Raya (Apr), mid-year sales, Mooncake Festival (Sep), year-end. Never pause campaigns during between-season periods. Reduce budget gradually. Build CNY/Hari Raya creative 4 weeks ahead. Payday spikes (25th-5th each month) -- increase budget 15% for payday windows.

---

## 7. WhatsApp/CTWA Attribution

### How CTWA Attribution Works
- Attribution model: **Last Click, 7-day window** (default)
- CTWA opens a **72-hour reply window** for brand to respond
- No browser involved = **Meta Pixel cannot track** CTWA conversions
- **CAPI (Conversions API) is mandatory** for CTWA attribution

### CAPI Setup for CTWA
1. Connect WhatsApp Business API provider to Meta CAPI
2. Define conversion events: `LEAD`, `PURCHASE`, or custom events
3. For PURCHASE events: must include `currency` and `value` fields
4. For LEAD events: no additional fields required
5. Events sent server-to-server from CRM/chatbot to Meta
6. Test events appear in Events Manager within ~20 minutes

### Supported Platforms with Native CAPI
- Wati, AiSensy, Helo AI, Interakt, Respond.io, Infobip, Woztell, Kommo
- Custom integration via Meta's CAPI endpoint also possible

### Offline Conversion Upload
- CAPI does NOT automatically track offline/in-store purchases
- For offline: use Meta's Offline Conversions API separately
- Upload CSV of offline conversions with matching parameters (phone, email)
- Match rate depends on data quality

### Attribution Gaps & Solutions
| Gap | Solution |
|-----|----------|
| WhatsApp conversation -> purchase not tracked | CAPI with PURCHASE event from CRM |
| In-store purchase after WhatsApp lead | Offline Conversions API upload |
| Multi-touch attribution | UTM parameters + CRM tracking |
| Cross-device attribution | CAPI with user identifiers |

### Pinxin Implication
CTWA is primary CTA. Must set up CAPI through Respond.io (or chosen platform). Fire LEAD event when user sends first message. Fire PURCHASE event when order confirmed in CRM. Without CAPI, Meta cannot optimize CTWA campaigns effectively -- this is a priority setup item.

---

## 8. Flexible Ads / Dynamic Creative

### What Changed
- Dynamic Creative (DCO) has been **replaced by Flexible Ad Format**
- Flexible Ads work at **individual ad level** (not ad set level like old DCO)
- Meta's AI picks format (carousel vs video vs single image) per impression

### Performance Data
- **25-40% performance improvement** for advertisers who embrace Flexible Ads
- Consolidated campaigns exit learning phase faster
- Better format matching per impression = higher relevance

### How Flexible Ads Work
1. Upload multiple media assets (images, videos) + multiple text/headline options
2. Meta's AI assembles optimal combination per user per placement
3. Format selection (single image, video, auto-carousel) is automated
4. Placement optimization is built-in

### Structure Benefits
- Moving from 5+ campaigns (3-5 ads each) to 1-2 campaigns (10-30+ ads)
- Concentrates conversion events = clearer signals for AI
- Simplified management

### Limitations
- **Only works with Sales and App Promotion campaigns** (not Awareness, Traffic, Engagement, or Leads)
- Difficult to analyze individual creative performance within Flexible Ads
- Less control over which creative/format serves where
- Not ideal for strict A/B testing (use individual ads for that)

### Pinxin Implication
For CTWA/Lead campaigns, Flexible Ads are NOT available (Leads objective). Use individual ads for CTWA campaigns. For any future Sales-optimized campaigns (e.g., Shopee/Lazada direct), Flexible Ads would be the right format. Keep using individual ads for creative testing regardless.

---

## 9. Meta's Andromeda Model

### What It Is
Andromeda is Meta's AI-powered **ad retrieval system** (launched late 2024, core infrastructure by 2025-2026). It's the first stage of ad delivery, before the auction.

### How It Works (3-Stage Process)
1. **Retrieval (Andromeda):** Scans billions of ads, shortlists ~1,000 candidates per user
2. **Ranking:** Traditional auction model ranks the ~1,000 candidates
3. **Delivery:** Winning ad serves to user

### Technical Specifications
- **10,000x model capacity** increase over previous system
- Uses **computer vision + AI audio analysis** to understand creative content
- Assigns **Entity IDs** based on semantic meaning (not file identity)
- Hierarchical tree structure based on semantic similarity and user intent

### Entity ID System (Critical)
- Each ad gets an Entity ID based on what it's **about**, not what file it is
- **Ads that look or sound similar = clustered into SAME Entity ID**
- 50 variations of same concept = 1 Entity ID = 1 ticket to the auction
- 10 distinct concepts = 10 Entity IDs = 10 tickets to the auction
- This is why creative diversity > creative volume

### New KPIs Released for Andromeda
1. **Creative Similarity** -- measures overlap between your ads
2. **Creative Fatigue** -- tracks audience exposure saturation
3. **Top Creative Themes** -- categorizes creative types by spend distribution

### Optimization Strategies
- **10-15 conceptually distinct assets** per Advantage+ campaign
- Chase unique Entity IDs, not ad volume
- Vary: format, persona, environment, benefit angle, visual style
- Optimal structure: 1 campaign, 1-2 ad sets broad targeting, 10-20 unique ads
- Andromeda rewards volume, variation, and distinct concepts

### What Counts as "Distinct" for Entity ID
- Different visual style (photo vs illustration vs text-heavy)
- Different person/character
- Different environment/background
- Different primary benefit/message
- Different emotional tone
- Different format (static vs video vs carousel)

### Pinxin Implication
Current 50 ads may have high Entity ID overlap if they're variations on same visual theme. Need to ensure creative diversity across: dish types, visual styles (lifestyle vs product shot vs text-dominant), personas (young professional vs family vs health-conscious), and languages (CN vs EN as distinct creatives). Audit current ads for Creative Similarity metric.

---

## 10. Kill/Scale Framework

### Kill Criteria (Specific Numbers)

#### Phase 1: Early Signal (0-24 hours)
- Monitor CTR, CPC, video retention
- **Do NOT kill based on CPA yet** -- insufficient data
- Flag if CTR < 1.0% after first 1,000 impressions

#### Phase 2: Evaluation (24-72 hours)
- Require **minimum 24 hours of consistent underperformance** before killing
- Kill if: CPA > 1.5x target AND spend > 100% of daily budget AND not in learning phase
- Kill if: Zero conversions after spending 2x target CPA

#### Phase 3: Confirmation (72 hours - 7 days)
- Kill if: ROAS below 1.5:1 for 48+ hours
- Kill if: ROI is worse than -30% after 3 full days
- Kill if: Meta allocated < 10% of ad set budget to the ad (algorithm has deprioritized it)

### Scale Criteria

#### Pre-Scale Checklist (ALL must be true)
- [ ] CPA stable for at least 7 days
- [ ] Daily conversion volume consistent
- [ ] Campaign NOT in learning phase
- [ ] Frequency below 2.5 for prospecting
- [ ] Blended MER/ROAS supports profit targets

#### Scaling Protocol
1. Increase budget by **10-20% maximum per edit**
2. Wait **48-72 hours** before next adjustment
3. Cap daily budget increases to stay under 20-30% to avoid learning phase reset
4. Monitor CPA and conversion volume daily after each increase

### Automation Rules Template
```
KILL RULE:
IF cost_per_result > [1.5x target CPA]
AND amount_spent > [1x daily budget]
AND campaign NOT in learning phase
AND time_running > 24 hours
THEN pause ad

SCALE RULE:
IF cost_per_result < [0.8x target CPA]
AND conversions > 10 in last 3 days
AND campaign NOT in learning phase
AND frequency < 2.5
THEN increase budget by 15%
(max 1 increase per 72 hours)

FATIGUE RULE:
IF frequency > 3.5
OR CTR dropped > 30% from 7-day peak
THEN flag for creative refresh
```

### Critical Warnings
- Never kill during learning phase (first 50 conversions / 7 days)
- Don't over-optimize on few hours of data
- "If Meta decides not to give an ad budget, it's never going to scale" -- pause low-delivery ads
- Trust blended metrics over individual ad metrics for overall health

### Pinxin Implication
With RM1,200/day budget and ~RM30 target CPA:
- Kill ads that spend >RM60 with zero conversions
- Kill ads with CPA >RM45 after 3 days (if not in learning phase)
- Scale ads with CPA <RM24 after 7 stable days
- Budget increases: max RM180-240/day per increment (15-20%)
- Check Creative Similarity score -- high overlap = wasted Entity IDs

---

## Key Structural Recommendations for Pinxin

### Optimal 2026 Account Structure
Based on all research, the recommended structure:

```
CAMPAIGN 1: Advantage+ Sales (Prospecting)
  - 1-2 ad sets, broad targeting
  - 10-15 conceptually distinct creatives
  - Largest budget allocation (60-70%)

CAMPAIGN 2: Manual CBO (CTWA/Lead Gen)
  - 2-3 ad sets (MY broad, SG broad, retarget)
  - Individual ads (Flexible not available for Leads)
  - 20-30% of budget

CAMPAIGN 3: Manual ABO (Creative Testing)
  - 3-5 ad sets, controlled budget
  - Test 3-5 new creatives per cycle
  - 10% of budget
  - Graduate winners to Campaign 1 or 2
```

### Minimum audience size: 500,000+ per prospecting ad set
### Minimum ad set budget: RM214/day for RM30 CPA target
### Creative refresh: Every 1-3 weeks, 3-5 new concepts per cycle
### Entity ID target: 10-15 distinct concepts active at all times

---

## Sources

### Topic 1: ASC vs Manual
- [Advantage+ Sales vs Manual Campaigns 2026 - First Launch](https://firstlaunch.in/blog/advantage-manual-campaigns-guide-2026/)
- [ABO vs CBO Budget Strategy 2026 - AdsUploader](https://adsuploader.com/blog/abo-vs-cbo)
- [Meta Advantage+ vs Manual 2026 - Kirnani](https://blog.kirnanitechnologies.com/meta-advantage-vs-manual-campaigns-which-strategy-wins-in-2026/)
- [How to Use Advantage+ to Cut Ad Costs by 44% - Madgicx](https://madgicx.com/blog/advantage-plus)
- [Best Meta Ads Account Structure 2026 - Flighted](https://www.flighted.co/blog/best-meta-ads-account-structure-2026)

### Topic 2: Creative Volume & Testing
- [Creative Scaling Ultimate Guide 2026 - Admetrics](https://www.admetrics.io/en/post/creative-scaling-the-ultimate-guide)
- [Creative Testing Framework 2026 - Share of Voice](https://theshareofvoice.com/post/creative-testing-framework-for-meta-ads-your-ultimate-2026-guide/)
- [Ad Creative Fatigue Detection 2026 - Adligator](https://adligator.com/blog/ad-creative-fatigue-detection-checklist)
- [How Many Ad Creatives to Test 2026 - AdManage](https://admanage.ai/blog/how-many-ad-creatives-to-test)
- [Creative Fatigue in Meta Ads 2026 - Pixel Panda](https://www.pixelpandacreative.com/blog/why-your-best-performing-ad-is-your-biggest-risk-in-2026)
- [19 Rules for Meta Advertising - Jon Loomer](https://www.jonloomer.com/19-rules-of-successful-meta-advertising/)

### Topic 3: Learning Phase
- [Exit Meta Ads Learning Phase 2026 - Modern Marketing Institute](https://www.modernmarketinginstitute.com/blog/how-to-exit-the-meta-ads-learning-phase-fast-and-start-scaling-profitably-in-2026)
- [Meta Ads Learning Phase Struggles 2026 - AdStellar](https://www.adstellar.ai/blog/meta-ads-learning-phase-struggles)
- [Learning Phase Manage Volatility - AdAmigo](https://www.adamigo.ai/blog/meta-ads-learning-phase-manage-volatility)
- [Meta Ads Best Practices 2026 - OptiFOX](https://optifox.in/blog/meta-ads-best-practices-2026/)

### Topic 4: Broad vs Interest Targeting
- [Meta Ads Targeting Options 2026 - Cropink](https://cropink.com/meta-ads-targeting-options)
- [Advantage+ Audience Targeting 2026 - Alex Neiman](https://alexneiman.com/meta-advantage-plus-audience-targeting-2026/)
- [Creative Targeting & Algorithm Changes 2026 - Xcceler](https://xcceler.com/blog/creative-targeting-and-meta-changes-in-2026-how-the-facebook-algorithm-actually-works-now/)
- [Meta Ads Audience Targeting Complexity 2026 - AdStellar](https://www.adstellar.ai/blog/meta-ads-audience-targeting-complexity)

### Topic 5: Bidding Strategies
- [Meta Ads Bidding 2026 ROAS - Weboin](https://weboin.com/meta-ads-bidding-strategy-2026/)
- [Meta Ads Bidding Strategies 2026 - Spinta Digital](https://spintadigital.com/blog/meta-ads-bidding-strategies-2026/)
- [Cost Cap vs Bid Cap CPA Guide - AdAmigo](https://www.adamigo.ai/blog/cost-cap-vs-bid-cap-cpa-strategy-guide)
- [Bid Cap vs Cost Cap 2026 - Two Owls](https://twoowls.io/blogs/bid-cap-and-cost-cap/)
- [Meta Ads Bidding Strategies Guide - Benly](https://benly.ai/learn/meta-ads/bidding-strategies-guide)

### Topic 6: Seasonal Strategy
- [Meta Holiday Marketing 2025 - Meta](https://www.facebook.com/business/holiday)
- [Meta's 6 Tips for Holiday Campaigns 2026 - Newnormz](https://www.newnormz.com.my/maximising-holiday-campaigns-meta-tips-2026/)
- [Automated Campaign Pausing - AdAmigo](https://www.adamigo.ai/blog/ultimate-guide-to-automated-campaign-pausing-in-meta-ads)

### Topic 7: CTWA Attribution
- [Meta Conversions API for CTWA - InsiderOne](https://academy.insiderone.com/docs/meta-conversions-api-for-click-to-whatsapp-ads)
- [CTWA 2026 Guide Attribution - TBit](https://tbit.app/content/what-is-ctwa-click-to-whatsapp-ads)
- [WhatsApp Conversions API - Sanoflow](https://sanoflow.io/en/collection/whatsapp-business-api/whatsapp-conversions-api/)
- [CTWA Ads Guide 2026 - WhatsApp Business APIs](https://whatsappbusinessapis.in/click-to-whatsapp-ads-ctwa/)
- [WhatsApp Conversion API - Stape](https://stape.io/news/whatsapp-conversion-api)
- [CTWA & Conversion API - Sprint Asia](https://sprintasia.co.id/ctwa-ads-conversion-api-smarter-whatsapp-lead-conversion/)

### Topic 8: Flexible Ads
- [Meta Flexible Ads When to Use - AdsUploader](https://adsuploader.com/blog/meta-flexible-ads)
- [Dynamic Ads Replaced by Flexible Ads - WeTracked](https://www.wetracked.io/post/facebook-meta-dynamic-ads-replaced-by-flexible-ads--cant-check-performance)
- [Flexible Ads Replacing Dynamic Creatives - Madgicx](https://madgicx.com/blog/flexible-ads-are-replacing-dynamic-creatives)
- [Flexible Ads 93% Conversion Boost - Wonderful](https://www.usewonderful.com/blog/meta-flexible-ads-conversion-boost)

### Topic 9: Andromeda
- [Inside Meta's Andromeda and GEM - Search Engine Land](https://searchengineland.com/meta-ai-driven-advertising-system-andromeda-gem-468020)
- [Meta Andromeda Algorithm 2026 - Drive Lead Media](https://www.driveleadmedia.com/blog/meta-andromeda-algorithm-2026)
- [Andromeda Entity IDs vs Creative Volume - AdsUploader](https://adsuploader.com/blog/meta-andromeda)
- [Creative Diversity for Andromeda - 303 London](https://www.303.london/blog/complete-guide-to-creative-diversity-for-meta-andromeda)
- [Creative Similarity Penalties Andromeda - PPC Blog Pro](https://ppcblogpro.com/how-andromeda-detects-and-punishes-ad-duplication/)
- [Andromeda Engineering Blog - Meta](https://engineering.fb.com/2024/12/02/production-engineering/meta-andromeda-advantage-automation-next-gen-personalized-ads-retrieval-engine/)
- [Entity IDs and Creative-Led Targeting - Webtopia](https://www.webtopia.co/blog/entity-ids-andromeda-and-the-new-era-of-creative-led-targeting-on-meta)

### Topic 10: Kill/Scale Framework
- [Scale Meta Ads Without Killing Performance - The Optimizer](https://theoptimizer.io/blog/how-to-scale-meta-ads-without-killing-performance)
- [Meta Ads Testing Framework 2026 - VibeMyAd](https://www.vibemyad.com/blog/the-meta-ads-testing-framework-that-actually-works)
- [Scaling Meta Ads 10-20% Rule - Stormy AI](https://stormy.ai/blog/scaling-meta-ads-2026-openclaw-rule)
- [Creative Scaling Guide 2026 - Admetrics](https://www.admetrics.io/en/post/creative-scaling-the-ultimate-guide)
- [Creative Testing Frameworks 2026 - Foxwell Digital](https://www.foxwelldigital.com/blog/the-meta-creative-testing-frameworks-top-brands-use-in-2026)
- [Meta Ads 2 Campaigns Scale Better Than 20 - Metalla](https://metalla.digital/meta-ads-strategy-2026-blueprint/)
- [Meta Campaign Structure Best Practices 2026 - AdStellar](https://www.adstellar.ai/blog/meta-campaign-structure-best-practices)
