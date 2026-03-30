# META ADS INTELLIGENCE REPORT — 2026
## Forensic-Level Research for Pinxin Vegan Cuisine
### Compiled: 2026-03-19

---

## TABLE OF CONTENTS
1. [Advantage+ Suite 2026 Overhaul](#1-advantage-suite-2026-overhaul)
2. [Andromeda + GEM: The New AI Brain](#2-andromeda--gem-the-new-ai-brain)
3. [Algorithm & Auction Changes](#3-algorithm--auction-changes)
4. [CTWA (Click-to-WhatsApp) Updates](#4-ctwa-click-to-whatsapp-updates)
5. [Conversion API (CAPI) 2026](#5-conversion-api-capi-2026)
6. [Creative Best Practices 2026](#6-creative-best-practices-2026)
7. [Attribution Changes](#7-attribution-changes)
8. [Budget Optimization Changes](#8-budget-optimization-changes)
9. [Metric & Reporting Changes](#9-metric--reporting-changes)
10. [Action Items for Pinxin](#10-action-items-for-pinxin)

---

## 1. ADVANTAGE+ SUITE 2026 OVERHAUL

### Advantage+ Shopping -> Advantage+ Sales (RENAMED & EXPANDED)
- **Advantage+ Shopping Campaigns (ASC) are DEAD.** Renamed to **Advantage+ Sales** campaigns.
- Advantage+ Sales now supports e-commerce sales, lead generation, AND app installs — not just shopping.
- **Ad sets are back.** Old ASC blended ad set into campaign with no ability to add more. Advantage+ Sales has no limit on ad sets.
- **Max 150 ads total**, capped at 50 per ad set.
- **Existing Customer Budget Cap is GONE.** Previously allowed capping spend on existing customers — removed.

### API Deprecation Timeline (CRITICAL for any automation)
- **Oct 8, 2025 (v24.0):** Legacy ASC and AAC campaign creation prohibited via API.
- **Q1 2026 (v25.0):** Breaking changes — prohibits ASC/AAC creation across ALL API versions.
- **May 19, 2026:** Restriction applies to ALL versions.
- **Sept 2026 (v26.0):** Remaining ASC/AAC campaigns will be PAUSED entirely.

### Lower Conversion Thresholds
- **Old:** 50+ weekly conversions for stable AI optimization.
- **New 2026:** 25 conversions/week for Shopping/Sales campaigns. 15 for App campaigns.
- This opens Advantage+ to smaller budgets (relevant for Pinxin at RM1,200-2,800/day).

### New Advantage+ Features
1. **Natural Language Audience Targeting ("Describe Your Audience")** — New text box accepting up to 2,000 characters. Write plain-text description of ideal customer, Meta AI builds the audience. No more scrolling dropdown interest lists.
2. **Advantage+ Creative Suite** — Bundles all AI creative tools: background generation, image-to-video conversion (up to 20 product photos into video ads), headline variations, text length optimization per placement.
3. **Advantage+ Leads** — New campaign type specifically optimized for lead generation.
4. **AI Dubbing** — Automatic language dubbing for video ads.
5. **AI-generated music** for video ads.
6. **Persona-based image generation** for creative variants.
7. **Predictive Budget Allocation** — Automatically shifts spend to high-performing segments in real-time. Early tests show 8-15% better ROAS.

### Performance Claims
- Advantage+ campaigns deliver ~22% higher ROAS vs manually managed campaigns.
- AI-generated creatives achieve up to 11% higher CTR vs traditional ads.
- 12% lower cost per purchase compared to manual campaigns.

---

## 2. ANDROMEDA + GEM: THE NEW AI BRAIN

### Andromeda: The Retrieval Layer
Andromeda is NOT just an update — it's a **fundamentally new stage** in Meta's ad delivery pipeline.

**How it works:**
1. Millions of ad candidates exist in the system.
2. **Andromeda (retrieval stage)** narrows this to a few thousand relevant options BEFORE the auction even starts.
3. Andromeda evaluates: your creative content, user behavior signals, current context.
4. Only ads that pass Andromeda's filter enter the auction.

**The paradigm shift:** Your ad creative now does most of the targeting work. Audience settings still exist but play a much smaller role. Andromeda reads your creative to decide WHO should see it.

### Creative Similarity Score (CRITICAL)
- **60% similarity threshold triggers retrieval suppression.** If your ads share >60% visual/audio features, Andromeda clusters them under a single "Entity ID" and treats them as one creative.
- Suppressed ads receive severely limited distribution REGARDLESS of bid amounts.
- **Target: Diversity Index below 40% similarity** across active assets.
- **Recommendation: 10-15 conceptually distinct assets per Advantage+ campaign.**

### Creative Fatigue Acceleration
- Andromeda aggressively matches ads to most responsive audiences, which means fatigue develops FASTER.
- **Refresh cycle: every 1-3 weeks** (not monthly like before).
- High fatigue score = declining efficiency = needs replacement.

### GEM (Generative Ads Recommendation Model)
Announced Nov 10, 2025. Meta's largest foundation model for ad recommendation.

**What GEM does:**
- Trained on ad content + user engagement data from BOTH ads and organic interactions.
- Uses customized attention mechanisms across sequence features (activity history) and non-sequence features (age, location, ad format, creative representation).
- 4x efficiency of previous generation models.
- Cross-platform learning: knowledge from Instagram automatically improves Facebook, and vice versa.

**Measured impact:**
- **5% increase in ad conversions on Instagram.**
- **3% increase on Facebook Feed.**
- GEM mixes and matches best creative for each audience segment/individual.

### March 2026 Performance Drop (HAPPENING NOW)
- Advertisers globally reporting unstable results in March 2026.
- Symptoms: fewer leads, rising CPA, increase in unqualified leads, inconsistent reach, reduced scalability of previously successful campaigns.
- Likely connected to Andromeda/GEM algorithm adjustments and creative diversity enforcement.
- **This may be affecting Pinxin right now.**

---

## 3. ALGORITHM & AUCTION CHANGES

### Learning Phase (Updated)
- Still requires ~50 optimization events per ad set per week to exit learning phase.
- **Minimum viable budget formula:** (Target CPA x 50) / 7 days.
- Some experimental reports of 10 conversions over 3 days threshold (not officially confirmed).
- Broader targeting = faster learning phase exit. Meta's algorithm with billions of data points often finds converters you'd never target manually.

### CBO vs ABO in 2026
- CBO is now branded as "Advantage+ Campaign Budget."
- **Neither is inherently better** — they serve different purposes:
  - **ABO = testing.** Use for creative testing, new concepts, audience exploration.
  - **CBO = scaling.** Use for scaling winners with broad targeting.
- CBO real-time optimization: shifts budget hour-by-hour based on CPR across ad sets.

### Bid Strategy Updates
- **Cost Cap:** Still available, sets maximum average cost per result.
- **Bid Cap:** Sets maximum bid per auction.
- **ROAS (Minimum ROAS):** Still available for value-based optimization.
- Key insight: With Andromeda, creative quality matters MORE than bid strategy. A great creative with lowest-cost bidding can outperform a mediocre creative with aggressive bid caps.

### Account Structure Best Practice 2026
**Two-campaign system recommended:**
1. **Creative Testing Campaign** — Max 25% of daily ad spend. ABO. Group ad sets by creative theme/format.
2. **Winners Campaign** — 75%+ of budget. CBO/Advantage+ budget. Broad targeting. Consolidate all winning creatives into single ad set using original Post IDs (retains social proof + estimated action rate).

**Consolidation rules:**
- 50 conversions per ad set per week minimum to exit learning.
- If two audiences overlap >25%, consolidate or use exclusions.
- Spread too thin = perpetual learning phase = wasted spend.

---

## 4. CTWA (CLICK-TO-WHATSAPP) UPDATES

### Pricing Changes (MAJOR)
- **Since July 2025:** Meta charges per delivered template message. No more flat 24-hour conversation fees.
- **CTWA free window: 72 hours.** When a user starts a chat via CTWA ad, ALL messages are free for 72 hours. This is the biggest lever for performance marketing.

### Optimization
- **Best practice:** Create CTWA campaigns using Engagement objective, optimize for Conversations.
- This lets Meta's ML identify users most likely to START a WhatsApp chat.
- **Daily budget rule:** At least 10x the average cost per optimization event. If avg cost/conversation is RM5, daily budget should be at least RM50 per ad set.

### Attribution & Tracking
- **ReferralCtwaClid** — Meta's click ID now included in webhooks.
- Can be sent to Conversions API as `ctwa_clid` to attribute outcomes and optimize targeting.
- **Default attribution:** Last Click, 7-day window.
- Connecting CTWA to CAPI allows Meta to optimize CTWA ads based on actual conversions (not just conversations), improving ROAS.

### WhatsApp Business API Changes
- **Cloud API is the standard.** On-premise option effectively discontinued. Handles up to 500 messages/second.
- **Jan 15, 2026:** Meta banned mainstream chatbots from WhatsApp Business API. Only business automation flows with clear, predictable results allowed. No open-ended AI chat.
- Shared Account Model applies. Old "On-Behalf-Of" model no longer exists.

### Performance Benchmarks
- CTWA campaigns report up to 3x higher conversion rates vs traditional landing page ads in WhatsApp-dominant markets (Malaysia included).
- 60% lower Cost Per Lead vs traditional ads.
- 3-5x more leads.
- Typical cost per conversation: $1-$3 for small businesses.
- Forrester study (commissioned by Meta): 94% lift in conversion rates, 92% drop in average CPL.

---

## 5. CONVERSION API (CAPI) 2026

### Requirements
- **Pixel-only is no longer sufficient in 2026.** Browser tracking degraded by iOS privacy, ad blockers, consent banners — pixel-only misses >50% of actual conversions.
- Meta recommends EVERY advertiser running paid campaigns implement CAPI alongside Pixel.

### Event Match Quality (EMQ)
- **Minimum EMQ: 6.0** for Advantage+ campaigns to function efficiently.
- Above 7.0 = excellent. Above 8.0 = comprehensive matching.
- **Critical insight:** If you send 1,000 purchase events via CAPI but only 300 match to a Facebook user, the algorithm only optimizes on those 300. Unmatched events are WORTHLESS.

### Improving EMQ
- **Add email parameter (SHA256 hashed):** Biggest impact. Typical EMQ jump: +4.0 points.
- Add phone number, first name, last name, city, state, zip code, country.
- More customer parameters = better match rate = better optimization.

### Deduplication
- Meta requires >70% deduplication quality.
- Events with same `event_id` received within 48 hours are deduplicated.
- After 48 hours, treated as separate events.

### Consent Requirements
- Tracking must be "Consent Aware" in 2026 (GDPR, CCPA, PDPA for Malaysia).
- Cookie consent signals must be respected.

---

## 6. CREATIVE BEST PRACTICES 2026

### The Andromeda-Era Creative Rules
1. **Creative IS targeting.** Andromeda reads your creative to decide who sees it. Your ad image/video communicates audience intent to the algorithm.
2. **Diversity over volume.** 10-15 conceptually distinct assets per campaign. <40% similarity between assets.
3. **Refresh every 1-3 weeks.** Fatigue hits faster under Andromeda.
4. **Lo-fi > polished.** UGC-style creative continues to dominate. Ads that look like real customer phone footage outperform professional productions.

### Format Recommendations
- **Static images making a comeback** — simple product photos or text-on-image designs outperforming video in many accounts.
- **4:5 (1080x1350)** for Feed — significantly higher CTR vs square/horizontal.
- **9:16 (1080x1920)** for Stories and Reels.
- **1:1 (1080x1080)** for cross-placement compatibility.
- Always provide all three ratios for maximum placement coverage.

### Video Rules
- **First 3 seconds = everything.** Bold hook, motion, captions required.
- **Design for sound-off.** Add text/captions that carry the full message.
- Keep Feed videos short and focused on product.
- Start Reels with bold hook.

### Text Rules
- **20% text rule officially dead** but less text = better delivery = lower costs.
- **Primary text:** 125 characters visible (more allowed but truncated). Front-load key message.
- **Headline:** Max 40 characters (25-27 ideal for some placements).
- Keep image text minimal for best algorithm treatment.

### AI Creative Tools Available
- Background generation from product photos.
- Image-to-video conversion (up to 20 product photos -> multi-scene video).
- Automatic headline variations.
- Text length optimization per placement.
- Image-to-video is new and potentially useful for Pinxin frozen dish photos.

---

## 7. ATTRIBUTION CHANGES

### View-Through Attribution (Jan 12, 2026)
- **7-day view (7d_view) and 28-day view (28d_view) attribution windows PERMANENTLY REMOVED** from Ads Insights API.
- Measurement window shrunk from 28 days to 1 day for view-through.
- Industry data: some advertisers had 30-40% of conversions in that 8-28 day window that NO LONGER COUNTS.
- **Impact: Reported conversions may drop significantly even if actual performance hasn't changed.**

### Click-Through Attribution (March 2026)
- **Link click attribution now EXCLUDES likes and shares.**
- Previously: any click on any ad element (likes, reactions, shares, saves, comments) + conversion = attributed.
- Now: only actual link clicks count for click-through attribution.

### Engage-Through Attribution (NEW)
- Conversions from non-link interactions (likes, shares, etc.) now fall under "Engage-Through Attribution."
- **Engage-through has a 1-day window only** (not 7 days).
- Some conversions will VANISH entirely: non-link interactions followed by conversion at day 2-7 fall outside engage-through's 1-day window.

### Video Engagement Threshold
- **Video engaged-view window shortened from 10 seconds to 5 seconds.**
- Reflects faster conversion behavior, especially on Reels.

### Historical Data Limitations
- API access to historical data now limited to 13 months for certain breakdowns.

### Billing Note
- Billing is NOT affected. Changes apply only to how conversions are classified/reported in Ads Manager.

---

## 8. BUDGET OPTIMIZATION CHANGES

### Predictive Budget Allocation (NEW)
- Automatically shifts spend to high-performing segments in real-time.
- Early tests: 8-15% better ROAS.

### Advantage+ Campaign Budget (formerly CBO)
- Real-time algorithmic optimization — monitors performance hour-by-hour.
- Shifts budget dynamically to lowest-CPR ad sets.

### Budget Minimums
- Advantage+ Sales: minimum $100/day recommended (lower budgets = insufficient data).
- Recommended starting: $150-300/day for small-to-medium e-commerce.
- CTWA: daily budget >= 10x average cost per optimization event.

### Learning Phase Budget
- Formula: (Target CPA x 50) / 7 = minimum daily budget.
- Pinxin example: If target CPA is RM30, minimum daily = (30 x 50) / 7 = RM214/day per ad set.

---

## 9. METRIC & REPORTING CHANGES

### Views Replacing Reach/Impressions (Organic)
- **Reach -> Viewers.** **Impressions -> Views.** **Engagement -> Interactions.**
- Views count every time content appears on screen, including repeat views. May appear higher than historic Impressions.
- **Important: These changes do NOT yet affect Ads Manager.** Traditional impressions data still available for paid ads.
- Legacy reach/viewer metrics retire by **June 2026**.

---

## 10. ACTION ITEMS FOR PINXIN

### IMMEDIATE (This Week)
1. **Check Creative Similarity Score.** If running similar-looking frozen food ads, Andromeda may be suppressing delivery. Ensure <40% visual similarity across active ads.
2. **Audit attribution settings.** View-through attribution changes may have inflated/deflated your reported numbers since Jan 12. Compare performance before/after.
3. **March 2026 performance drop.** If seeing rising CPA or unstable delivery, this is likely the global Andromeda adjustment — not necessarily your campaigns. Don't panic-kill campaigns.

### SHORT-TERM (Next 2 Weeks)
4. **Increase creative diversity.** Aim for 10-15 conceptually distinct creatives per campaign. Different angles, formats, compositions, copy approaches.
5. **Test "Describe Your Audience."** Try natural language targeting: "Malaysian women 25-45 in KL/Selangor who cook at home, interested in healthy eating, frozen convenience food, Chinese cuisine."
6. **Implement CTWA CAPI tracking.** Pass `ctwa_clid` from WhatsApp webhooks to Conversions API for proper attribution and optimization.
7. **Check EMQ score.** If below 6.0, add hashed email/phone parameters to CAPI events.

### MEDIUM-TERM (Next Month)
8. **Migrate to Advantage+ Sales** if still using legacy ASC. Deadline: May 19, 2026 (all API versions).
9. **Consolidate account structure.** Two campaigns: Creative Testing (25% budget, ABO) + Winners (75% budget, CBO/Advantage+). Avoid >25% audience overlap between ad sets.
10. **Test Meta's image-to-video tool.** Convert frozen dish product photos into video ads at no production cost.
11. **Creative refresh cadence: every 1-3 weeks.** Set calendar reminders.

### BUDGET IMPLICATIONS
- At RM1,200-2,800/day across 4 campaigns, you have sufficient budget for learning phase IF ad sets are consolidated properly.
- Each ad set needs RM214+/day minimum (assuming RM30 CPA) to exit learning.
- With 4 campaigns, ensure no more than ~6-8 ad sets total to maintain adequate per-ad-set budget.
- CTWA campaign: each ad set needs daily budget >= 10x cost per conversation.

### CTWA SPECIFIC
- Leverage the **72-hour free messaging window** aggressively. Close sales within 72 hours of CTWA click.
- WhatsApp chatbot restrictions (Jan 15, 2026): ensure your automation flows are business-specific, not open-ended AI chat.
- Optimize for Conversations (not link clicks) in CTWA campaigns.

---

## SOURCES

### Advantage+ Suite
- [Advantage+ 2026 Updates: New Features & Capabilities](https://benly.ai/learn/meta-ads/advantage-plus-updates-2026)
- [Meta's AI Advertising Plans: 2026](https://www.adtaxi.com/blog/metas-ai-advertising-plans-what-to-expect-in-2026-and-how-to-prepare/)
- [Advantage+ Sales Replaces Shopping - Jon Loomer](https://www.jonloomer.com/qvt/advantage-sales-replaces-advantage-shopping/)
- [Meta deprecates legacy campaign APIs](https://ppc.land/meta-deprecates-legacy-campaign-apis-for-advantage-structure/)
- [Complete 2026 Advantage+ Playbook](https://medium.com/@tentenco/how-to-build-a-successful-campaign-with-metas-advantage-ai-the-complete-2026-playbook-befca729202b)

### Andromeda & GEM
- [Meta's GEM: Engineering at Meta (Nov 10, 2025)](https://engineering.fb.com/2025/11/10/ml-applications/metas-generative-ads-model-gem-the-central-brain-accelerating-ads-recommendation-ai-innovation/)
- [How Andromeda and GEM Work Together - Search Engine Land](https://searchengineland.com/meta-ai-driven-advertising-system-andromeda-gem-468020)
- [Facebook Ad Algorithm Changes 2026 - Social Media Examiner](https://www.socialmediaexaminer.com/facebook-ad-algorithm-changes-for-2026-what-marketers-need-to-know/)
- [March 2026 Performance Drop Analysis](https://www.nagase.com.br/why-meta-ads-performance-dropped-in-march-2026-ai-algorithm-changes-affecting-facebook-and-instagram-advertising/)
- [Creative Similarity Penalties: Andromeda](https://ppcblogpro.com/how-andromeda-detects-and-punishes-ad-duplication/)
- [Andromeda Creative Diversification - Jon Loomer](https://www.jonloomer.com/meta-andromeda-creative-diversification/)
- [GEM Update - AdBeacon](https://www.adbeacon.com/metas-gem-update-2026/)

### CTWA & WhatsApp
- [2026 Guide to CTWA with Twilio](https://www.twilio.com/en-us/blog/products/2026-guide-to-create-ads-that-click-to-whatsapp-with-twilio)
- [CTWA 2026 Guide to Attribution - TBit](https://tbit.app/content/what-is-ctwa-click-to-whatsapp-ads)
- [WhatsApp Advertising Methods: $47K Data](https://acroan.com/whatsapp-advertising-methods/)
- [WhatsApp Business API Compliance 2026](https://gmcsco.com/your-simple-guide-to-whatsapp-api-compliance-2026/)
- [Meta Conversions API for CTWA](https://academy.insiderone.com/docs/meta-conversions-api-for-click-to-whatsapp-ads)

### CAPI
- [Meta Conversions API: Complete 2026 Guide](https://adsuploader.com/blog/meta-conversions-api)
- [Meta Ads CAPI Explained 2026 - wetracked.io](https://www.wetracked.io/post/what-is-capi-meta-facebook-conversion-api)
- [CAPI Setup Guide - DataAlly](https://www.dataally.ai/blog/how-to-set-up-meta-conversions-api)

### Attribution
- [Attribution Window Changes Jan 2026 - Dataslayer](https://www.dataslayer.ai/blog/meta-ads-attribution-window-removed-january-2026)
- [Meta Ads Attribution 2026 - Jon Loomer](https://www.jonloomer.com/meta-ads-attribution-2026/)
- [Click Attribution: Only Link Clicks Count](https://adsuploader.com/blog/meta-click-attribution)
- [Meta Attribution Changes - Supermetrics (Jan 12, 2026)](https://docs.supermetrics.com/docs/facebook-ads-new-historical-limitations-attribution-window-and-metric-removals-january-12-2026)
- [Engage-Through Attribution - ALM Corp](https://almcorp.com/blog/meta-ad-attribution-changes-2026/)

### Account Structure & Budget
- [Best Meta Ads Account Structure 2026 - Flighted](https://www.flighted.co/blog/best-meta-ads-account-structure-2026)
- [2 Campaigns Scale Better Than 20 - Metalla](https://metalla.digital/meta-ads-strategy-2026-blueprint/)
- [ABO vs CBO 2026](https://adsuploader.com/blog/abo-vs-cbo)

### Creative
- [Guide to Meta Ads Creative 2026](https://verdemedia.com/blog/the-guide-to-meta-ads-creative-2026)
- [Meta Ads Size Guide 2026](https://adsuploader.com/blog/meta-ads-size)
- [Meta Updates 2026 - RebootIQ](https://rebootiq.com/meta-updates-2026/)

### Metrics
- [Meta Reporting Changes 2025-2026](https://www.extradigital.co.uk/articles/marketing/meta-reporting-changes-2025/)
- [Views Replacing Impressions - Kolsquare](https://www.kolsquare.com/en/blog/views-are-the-new-impressions-what-metas-metrics-shift-means-for-influencer-marketing)
