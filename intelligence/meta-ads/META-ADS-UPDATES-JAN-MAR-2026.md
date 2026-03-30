# Meta/Facebook Ads Updates: January - March 2026

**Last updated: 2026-03-21**
**Source: Deep web research across 40+ sources**

---

## TABLE OF CONTENTS

1. [Andromeda Algorithm — Global Rollout](#1-andromeda-algorithm)
2. [GEM (Generative Ads Model)](#2-gem-generative-ads-model)
3. [Advantage+ Changes & Consolidation](#3-advantage-changes)
4. [Attribution & Measurement Overhaul](#4-attribution-measurement)
5. [Audience Targeting Deprecations](#5-audience-targeting)
6. [Bidding Strategy Updates](#6-bidding-strategies)
7. [Learning Phase Changes](#7-learning-phase)
8. [AI Creative Tools](#8-ai-creative-tools)
9. [Creative Format & Safe Zone Changes](#9-creative-formats)
10. [CAPI Requirements](#10-capi-requirements)
11. [API Deprecations & Breaking Changes](#11-api-deprecations)
12. [Location Fees (Digital Service Tax)](#12-location-fees)
13. [Campaign Scoring System](#13-campaign-scoring)
14. [Policy Changes](#14-policy-changes)
15. [CTWA / Click-to-WhatsApp Updates](#15-ctwa-updates)
16. [Strategic Implications for Mirra](#16-mirra-implications)

---

## 1. ANDROMEDA ALGORITHM

### What It Is
Andromeda is Meta's AI-driven ad-retrieval system that decides which ads are eligible to be shown. It completed **global rollout in October 2025** and by January 2026 powers ALL Facebook and Instagram ad delivery worldwide.

### How It Works
- Works in **reverse** of traditional targeting: instead of starting with advertiser-defined audiences, it evaluates historical engagement, ad copy, creative, and format to predict which users will engage
- Runs on NVIDIA Grace Hopper Superchip + Meta's own MTIA chips
- Scans **millions of ad options per second** to predict best match
- "Creative is the new audience" — permanent shift from precision targeting to predictive relevance

### Performance Impact
- Advertisers following best practices report **20-35% higher ROAS** compared to legacy campaign structures
- Delivery cycles are faster, creative gets picked up and exhausted with remarkable speed

### Best Practices for Andromeda
- **1 campaign** with campaign-level budget
- **1-2 ad sets** with broad targeting
- **10-20 unique ads** per ad set (chunky creative library)
- Broad targeting gives Andromeda freedom to learn and optimize faster than any media buyer could
- Creative diversity > audience segmentation

---

## 2. GEM (GENERATIVE ADS MODEL)

### What It Is
GEM = Generative Ads Recommendation Model. Meta's most advanced ads foundation model, built on an LLM-inspired paradigm. Trained across thousands of GPUs. **Largest foundation model for recommendation systems in the industry.**

### How It Works with Andromeda
- **Andromeda** decides which ads are ELIGIBLE (what makes it onto the shelf)
- **GEM** determines what SHOULD be shown next (learns what shoppers buy, shapes what gets featured)
- GEM identifies patterns across organic interactions, ad sequences, formats, and messaging
- Synthesizes engagement, behavioral, and conversion data

### Performance Numbers
- **5% increase in ad conversions on Instagram**
- **3% increase on Facebook Feed**
- Began rolling out mid-2025, broad impact by Q4 2025

### Future Direction
- By late 2026, advertisers may only need: a goal + a budget + a single product image — Meta AI builds everything else
- Moving from "Assisted Creation" to "Autonomous Generation"

---

## 3. ADVANTAGE+ CHANGES & CONSOLIDATION

### Rebranding
- Advantage+ Shopping Campaigns renamed to **Advantage+ Sales Campaigns (ASC)**
- Scope expanded: now supports e-commerce sales, lead generation, AND app installs

### Key Structural Changes
- **Removed one-ad-set limit**: ASC can now include several ad sets, each with up to 50 ads
- Advertisers can add or exclude custom audiences and set audience preferences (age, gender)
- "Automated Ads" feature phased out in favor of Advantage+ tools
- Advantage+ automation is now the **default option** for new ad campaigns

### Advantage+ Leads Campaigns
- Now available **globally**
- Early testing shows **10% reduction in cost per qualified lead**

### New Features
- **AI Dubbing**: automatic language dubbing for video ads
- **AI-generated music**: for video ad soundtracks
- **Persona-based image generation**: AI creates ad imagery based on persona descriptions
- **Restricted Words setting**: for AI-generated text in Advantage+ campaign setup
- **Campaign Score (0-100)**: evaluates how closely setup follows Meta best practices

### Post Engagement → Maximize Interactions
- 'Post Engagement' conversion type **replaced** with 'Maximize Interactions' performance goal

---

## 4. ATTRIBUTION & MEASUREMENT OVERHAUL

### January 12, 2026 — Major Deprecations
- **7-day view attribution window: REMOVED**
- **28-day view attribution window: REMOVED**
- Only **1-day view** remains for view-through attribution
- Historical data limited to **13 months** for unique-count fields
- Historical data limited to **6 months** for frequency breakdowns and hourly breakdowns
- **Reported conversions dropped 15-30% overnight** (measurement change, not performance)
- Some advertisers had 30-40% of conversions in the 8-28 day window that no longer counts

### January 26, 2026
- **10-second video view metric: RETIRED**
- Track **ThruPlay** or **2-second continuous views** instead

### March 2026 — Click Attribution Redefined
- Only **link clicks** count toward click-through attribution
- Likes, shares, saves, comments tracked separately as **"Engage-through attribution"**
- Video engaged-view threshold dropped from **10 seconds to 5 seconds**
- Designed to reduce discrepancies between Meta Ads Manager and Google Analytics

### Engaged-View Attribution Changes
- Engaged views for video now counted after **5 seconds** (was 10)
- Engaged-views available when **maximizing value** (new)
- 1-day engaged-videos for **image ads: NO LONGER AVAILABLE**

### Coming: Page Viewer Metric
- By **end of June 2026**, Page Viewer Metric in Graph API
- Replaces legacy reach metric
- Provides consistent cross-platform measurement (Facebook + Instagram)

### Over 100 Metrics Phased Out
- Including `unique_actions` and many others
- Graph API v19 and v20 deprecated in 2026

---

## 5. AUDIENCE TARGETING DEPRECATIONS

### December 15, 2025
- Deprecated interest options removed from Ads Manager — no longer selectable in new ad sets

### January 15, 2026
- Campaigns using **old detailed targeting interests stopped running**
- Must switch to broader groupings or Advantage+ Audience
- Vast number of specific interests (EDM fans, SUVs, vegan food, etc.) merged into broad groups
- Impacts: Saved Audiences, Auto-boost rules containing deprecated interests

### March 31, 2026
- **Detailed targeting exclusions removed from existing campaigns**
- Meta cites internal testing: **22.6% lower median cost per conversion** without exclusions

### Full Lookalike Audience Phase-Out
- Replaced by **predictive models** based on ML and aggregated behavior
- 2026 establishes this as the **default standard**

### Strategic Reality
- Interest-based targeting is effectively dead
- Creative quality + first-party data + CAPI signal = the new targeting

---

## 6. BIDDING STRATEGY UPDATES

### Available Strategies (2026)
1. **Highest Volume (Lowest Cost)**: Meta spends budget to get most conversions, no cost control
2. **Cost Cap**: Keeps average CPA at or below target, allows individual variation
3. **Bid Cap**: Hard maximum per auction, strictest control but may limit delivery
4. **ROAS Target (Minimum ROAS)**: Set minimum ROAS threshold Meta's AI must respect during auctions

### New: Minimum ROAS Threshold (Late 2025)
- If minimum ROAS = 2.5x, Meta prioritizes auctions statistically likely to meet/exceed that ratio
- AI-driven, dynamic bidding around the threshold

### New: Learning Phase Retention (2026)
- AI maintains bid stability even after creative or audience updates
- Reduces volatility when refreshing creative

### Best Practice Guidance
- **Cost Cap**: Best for scaling without losing ROAS, Meta adjusts bids dynamically
- **Bid Cap**: Best for short-term/high-priority campaigns with strict cost control
- **ROAS Target**: Best for ecommerce with clear margin requirements

---

## 7. LEARNING PHASE CHANGES

### Standard Requirement
- **50 conversions per week** (7-day period) to exit learning — still the standard

### Reduced Threshold for Specific Campaigns
- **Purchase-optimized campaigns**: reduced from 50 to **10 conversions**
- **Mobile App Install campaigns**: reduced from 50 to **10 conversions**
- Alternative: **10 conversions within 3 days** also exits learning phase
- Small businesses significantly more likely to exit learning phase

### Duration
- Advantage+ campaigns: typically **7-14 days** to exit
- Standard campaigns: typically **7 days** if generating sufficient events

### What Resets Learning Phase
- Changing targeting parameters
- Adding or removing ads
- Modifying optimization event
- Pausing for **7+ days**
- Budget change of **more than ~20%** in a single edit

---

## 8. AI CREATIVE TOOLS

### Image-to-Video Tool
- Turn up to **20 product photos** into polished, multi-scene video ads
- No external production team needed
- Available on Facebook and Instagram

### Image Animation Tool
- Animate still image assets by adding moving elements
- Based on text prompts
- Static → dynamic conversion

### Video Background Expansion
- Expand background of existing videos
- Resize for various placements without losing quality
- AI fills in the extended canvas

### AI Text Generation
- Advantage+ creative generates and enhances ad variations
- Works across single image, video, and carousel formats
- **"Restricted Words" setting** available to control AI-generated text
- Personalizes content for individual users

### "Made with AI" Labels
- Automatically applied to ad creatives containing photorealistic AI-generated imagery
- **Cannot be removed by advertisers**
- Appears as small "AI Info" tag

### Future: Full Autonomous Generation
- Meta's Generative Ad Model (GEM) moving toward:
  - Advertiser provides: product URL + budget + basic prompt
  - AI generates: entire campaign (images, copy, headlines, animations)
- Expected broad rollout by late 2026

---

## 9. CREATIVE FORMAT & SAFE ZONE CHANGES

### March 2026 — Unified 9:16 Safe Zone
Facebook Stories, Facebook Reels, Instagram Stories, and Instagram Reels now share **one unified 9:16 safe zone**.

### Safe Zone Specifications (1440x2560 canvas)
- **Top**: Keep critical elements outside top **14%** (~358px) — profile icon, username, "Sponsored" label
- **Bottom (Stories)**: Outside bottom **20%** (~512px)
- **Bottom (Reels)**: Outside bottom **35%** (~896px) — additional interactive elements
- **Sides**: Outside **6% each** (~87px)
- **Horizontal**: Center content within middle **~80%** — survives Smart Zoom cropping on ultra-tall (20:9) devices

### Recommended Export Dimensions
- **High-density**: 1440x2560 (avoids upscaling artifacts)
- **Standard**: 1080x1920 (9:16) for Stories and Reels
- Instagram Feed: shifting to **4:5 for images, 9:16 for video**
- 9:16 video ads in Feed showing **7% higher CTR and 4% higher** engagement

### Format Evolution
- Moving away from traditional Flexible, Single Image, Carousel, Collection as separate formats
- New system: multiple formats and creatives within a **single ad** using "Uploaded Media" and "Format display" options
- AI dynamically selects optimal format per placement per user

### Instagram Explore Removal
- 'Instagram Explore' ad placement **removed** (January 2026)
- Ads targeting Instagram Reels now appear in former Explore feed area

### Safe Zone Guardrail Tool
- Ads Manager includes overlay tool showing safe/unsafe regions during ad setup

---

## 10. CAPI (CONVERSIONS API) REQUIREMENTS

### 2026 Status: Effectively Mandatory
- Pixel-only setups miss **over half** of actual conversions due to iOS privacy, ad blockers, consent banners
- Meta strongly recommends CAPI for ALL paid campaign advertisers
- **Offline Conversions API permanently discontinued** (May 2025) — must use CAPI for offline tracking

### Technical Requirements
- **Event deduplication window**: 48 hours
- Real-time server-side transmission critical — delays beyond 48 hours = double-counting
- **Consistent Event IDs** between browser and server tracks mandatory
- Hash all PII with **SHA-256** before transmission (email, phone, name, city, state, zip, country)

### Event Match Quality
- Target score: **8.0+** (anything below 7.0 hurts performance)
- Higher EMQ = better signal = better optimization = lower CPA

### Privacy Compliance (2026)
- Tracking must be **"Consent Aware"** for GDPR, CCPA compliance
- Consent mode integration required for EU/UK campaigns

### CTWA + CAPI Challenge
- Meta Pixel cannot track conversions inside WhatsApp
- Need WhatsApp Business API provider with CAPI integration
- Define conversion events that fire back to Meta when actions occur in WhatsApp

---

## 11. API DEPRECATIONS & BREAKING CHANGES

### Marketing API v25.0 (Q1 2026)
- **Breaking changes**: prohibits ASC and AAC campaign creation across all API versions
- Must migrate to newer Advantage+ campaign structures
- Legacy Advantage Shopping and App Campaign APIs deprecated

### Full Deprecation Timeline
- **ASC and AAC campaigns**: phased out by **September 2026**
- **Graph API v19 and v20**: deprecated in 2026
- **MMM breakdowns**: restricted to asynchronous jobs only (no real-time synchronous access)

### Webhooks
- mTLS certificates change to **Meta CA by March 31, 2026**
- Trust store updates required

### Higher-Spending Accounts
- Required to switch to **monthly invoicing by April 1, 2026**

---

## 12. LOCATION FEES (DIGITAL SERVICE TAX)

### Announcement: March 10, 2026
Starting April 2026, Meta applies "Location Fees" to cover Digital Service Taxes (DST).

### Affected Countries & Rates
| Country | Fee |
|---------|-----|
| Austria | 5% |
| Turkey | 5% |
| France | 3% |
| Italy | 3% |
| Spain | 3% |
| United Kingdom | 2% |

### Key Details
- Fees based on where **ads are shown** (audience location), NOT advertiser's business location
- Applied to ad impressions
- Full billing implementation: **July 1, 2026**
- Meta previously absorbed these costs; citing "evolving regulatory landscape"
- Google and Amazon already pass similar fees

### Impact for Malaysia-Focused Campaigns
- **No direct impact** for Malaysia-only targeting
- Only matters if running ads targeting EU/UK/Turkey audiences

---

## 13. CAMPAIGN SCORING SYSTEM

### Opportunity Score (0-100)
Available inside Ads Manager. Evaluates campaign setup across four dimensions:
1. **Creative variety**: number and diversity of ad creatives
2. **Signal quality**: Pixel and CAPI configuration
3. **Audience breadth**: how broad vs. restricted targeting is
4. **Conversion event accuracy**: correct optimization event selection

### How to Read It
- **Lower score** (e.g. <20) = campaign already well-optimized per Meta's criteria
- **Higher score** = more optimization opportunities exist
- Recommendations ranked by estimated performance impact

### Performance Scoring (Third-Party Framework)
- **85-100**: A-grade winners — increase budget, expand creative, replicate
- **70-84**: Solid B-grade — maintain and iterate
- **55-69**: C-grade — needs immediate attention
- **Below 55**: Danger zone — likely wasting budget

---

## 14. POLICY CHANGES

### Data Source Declaration
- New global policy: companies must **clearly declare the source of data** used in campaigns

### Ad Identity Verification
- Stricter verification system aimed at curbing disinformation and opaque messaging

### AI Labels
- "Made with AI" labels auto-applied to photorealistic AI-generated ad imagery
- Cannot be removed

### Ad Format Selection
- Moving toward AI-driven format selection rather than advertiser-chosen formats

---

## 15. CTWA (CLICK-TO-WHATSAPP) UPDATES

### Campaign Setup
- Select **Leads** as campaign objective → set WhatsApp as conversion location
- Compatible with Advantage+ placements for AI-driven optimization

### Cost Benefits
- Conversations from CTWA ads = **"Free-Entry-Point Conversations"**
- Not charged; customer window lasts **72 hours**
- Businesses report **60% lower Cost Per Lead** and **3-5x more leads** vs. landing page

### Attribution Challenge
- Meta Pixel cannot track in-WhatsApp conversions
- Requires WhatsApp Business API provider with **CAPI integration**
- Must define custom conversion events that fire back to Meta

---

## 16. STRATEGIC IMPLICATIONS FOR MIRRA

### Immediate Action Items

1. **Attribution Window Impact**: With 7-day and 28-day view removed, reported conversions will appear lower. Adjust ROAS expectations and don't kill campaigns based on deflated numbers.

2. **CAPI is Non-Negotiable**: With pixel missing 50%+ of conversions, CAPI must be fully implemented. EMQ target: 8.0+. Critical for CTWA campaigns where pixel cannot track WhatsApp conversions.

3. **Creative Volume is King**: Andromeda + GEM reward 10-20 unique creatives per ad set. Creative diversity > audience segmentation. This validates the current high-volume production approach.

4. **Broad Targeting is the Default**: Detailed targeting interests are dead. Exclusions removed March 31. Let Andromeda find the audience. Focus budget on creative, not audience testing.

5. **Learning Phase is Easier**: Purchase campaigns now only need 10 conversions (not 50) to exit learning. Better for lower-budget ad sets.

6. **9:16 Safe Zone**: All vertical content must respect unified safe zone. Top 14%, bottom 35% (Reels), sides 6% each. Export at 1080x1920 minimum, 1440x2560 for high-density.

7. **Campaign Structure**: 1 campaign → 1-2 ad sets → 10-20 ads each. Campaign-level budget. This is what Andromeda optimizes best.

8. **Format**: 9:16 video ads in Feed showing 7% higher CTR. Push toward vertical video over static where possible.

9. **No Location Fee Impact**: Malaysia-only targeting = no DST fees.

10. **Image-to-Video Tool**: Can turn product photos into video ads directly in Ads Manager. Worth testing for food photography → video conversion.

---

## SOURCES

- [SocialBee — 2026 Meta & Facebook Updates](https://socialbee.com/blog/facebook-updates/)
- [Social Media Examiner — Facebook Ad Algorithm Changes 2026](https://www.socialmediaexaminer.com/facebook-ad-algorithm-changes-for-2026-what-marketers-need-to-know/)
- [OptiFOX — Meta Ads Best Practices 2026](https://optifox.in/blog/meta-ads-best-practices-2026/)
- [Outrank — Meta Ads Shake-Up 2026](https://www.outrank.co.uk/latest-news/the-big-meta-ads-shake-up-what-marketers-need-to-know-in-2026/)
- [AuditSocials — Meta Ad Policy Changes March 2026](https://www.auditsocials.com/blog/meta-ad-policy-updates-2026-guide)
- [Social Media Today — Meta Marketing API Updates](https://www.socialmediatoday.com/news/meta-updates-marketing-api-to-align-with-latest-ad-shifts/812648/)
- [1ClickReport — Meta Andromeda 2026 Update](https://www.1clickreport.com/blog/meta-andromeda-update-2025-guide)
- [AdExchanger — What Andromeda Actually Changes](https://www.adexchanger.com/data-driven-thinking/what-metas-andromeda-update-actually-changes-and-what-it-doesnt/)
- [Search Engine Land — Andromeda and GEM](https://searchengineland.com/meta-ai-driven-advertising-system-andromeda-gem-468020)
- [Meta Engineering — GEM](https://engineering.fb.com/2025/11/10/ml-applications/metas-generative-ads-model-gem-the-central-brain-accelerating-ads-recommendation-ai-innovation/)
- [Admetrics — GEM for E-commerce 2026](https://www.admetrics.io/en/post/metas-gem-ai-model-future-of-e-commerce-advertising)
- [Adtaxi — Meta AI Advertising Plans 2026](https://www.adtaxi.com/blog/metas-ai-advertising-plans-what-to-expect-in-2026-and-how-to-prepare/)
- [PPC Land — Meta Deprecates Legacy APIs](https://ppc.land/meta-deprecates-legacy-campaign-apis-for-advantage-structure/)
- [Dataslayer — Attribution Window Changes](https://www.dataslayer.ai/blog/meta-ads-attribution-window-removed-january-2026)
- [DOJO AI — Meta Attribution 2026](https://www.dojoai.com/blog/meta-ads-attribution-2026-changes-fixes)
- [Aimerce — Meta Attribution Changes 2026](https://www.aimerce.ai/blogs/meta-attribution-changes-2026-what-advertisers-need-to-know)
- [PPC Land — Attribution Windows Restricted](https://ppc.land/meta-restricts-attribution-windows-and-data-retention-in-ads-insights-api/)
- [Supermetrics — January 12 2026 Changes](https://docs.supermetrics.com/docs/facebook-ads-new-historical-limitations-attribution-window-and-metric-removals-january-12-2026)
- [ALM Corp — Meta Ad Attribution Changes](https://almcorp.com/blog/meta-ad-attribution-changes-2026/)
- [Search Engine Land — Click and Engage-Through Attribution](https://searchengineland.com/meta-introduces-click-and-engage-through-attribution-updates-470629)
- [Brandwatch — Meta Detailed Targeting Changes](https://social-media-management-help.brandwatch.com/en/articles/13215856-meta-changes-to-detailed-targeting-interests-in-advertise)
- [TheKeyword — Meta Remove Detailed Targeting](https://www.thekeyword.co/news/meta-to-remove-detailed-targeting-options-in-ads-manager)
- [Jon Loomer — Detailed Targeting Announcement](https://www.jonloomer.com/qvt/detailed-targeting-announcement/)
- [Madgicx — Meta Lowers Learning Phase](https://madgicx.com/blog/meta-lowers-learning-phase-requirement-for-select-campaigns)
- [Billo — Meta Ads Safe Zones 2026](https://billo.app/blog/meta-ads-safe-zones/)
- [Bloomberg — Meta Raises Advertiser Fees](https://www.bloomberg.com/news/articles/2026-03-10/meta-hikes-fees-for-advertisers-to-cover-europe-s-digital-taxes)
- [SwipeInsight — Meta Ads News March 2026](https://web.swipeinsight.app/topics/meta-ads)
- [Medianama — Meta Location Fees](https://www.medianama.com/2026/03/223-meta-advertisers-location-fees-digital-service-taxes/)
- [Meta Business Help — Opportunity Score](https://www.facebook.com/business/tools/opportunity-score)
- [Dancing Chicken — API Deprecation Notices](https://www.dancingchicken.com/post/meta-ads-api-deprecation-notices-what-to-know)
- [WeTracked — Advantage+ for Ecommerce 2026](https://www.wetracked.io/post/advantage-ecommerce)
- [Edge Digital — Facebook Ads Guide 2026](https://www.edgedigital.net/facebook-ads-guide-for-2026/)
- [TBit — Click-to-WhatsApp Ads Guide](https://tbit.app/content/what-is-ctwa-click-to-whatsapp-ads)
