---
name: Meta ads intelligence — 16 research docs, master playbook, Malaysian market data
description: Complete Meta ads research library for Mirra. 16 docs covering platform updates, ROAS playbook, competitors, DTC brands, psychology, meal subscription, competitive analysis, viral hooks, Malaysian consumer behavior, ad creative benchmarks, offer/conversion strategy. Read master doc first.
type: reference
---

## Meta Ads Intelligence Library (2026-03-13)

All in `/Users/yi-vonnehooi/Desktop/mirra-workflow/`:

### Master document
1. **`MIRRA-META-ADS-INTELLIGENCE.md`** — MASTER DOC. 14 sections: competitive moat, algorithm, ROAS reality, 5x formula, formats, copy frameworks, 10 creative archetypes, campaign structure, fatigue management, production pipeline, tracking, landing page, **Malaysian market intelligence**.

### Deep research docs (in `research/`)
2. **`META_ADS_ROAS_PLAYBOOK_2026.md`** — Tactical playbook. Andromeda scoring, ASC setup, testing framework, kill criteria, frequency management.
3. **`research/MEAL-SUBSCRIPTION-ADS-RESEARCH.md`** — Global case studies. HelloFresh/Factor strategies, ROAS benchmarks, carousel = 4.2x ROAS, offer formulas.
4. **`research/DTC-BRANDS-META-ADS-INTELLIGENCE-2026.md`** — Cross-industry DTC. Glossier, Skims, AG1, Drunk Elephant, ugly ads (+72% ROAS), founder-led, meme marketing. Brand transfer map for Mirra.
5. **`research/META-ADS-PSYCHOLOGY-DEEP-RESEARCH.md`** — Science of conversion. Color psychology, typography neuroscience, parasocial intimacy, food photography angles, social proof hierarchy, Xiaohongshu influence, Chinese Malaysian cultural psychology.
6. **`research/META-ADS-COMPETITIVE-RESEARCH-2026.md`** — Ad Library analysis. 10 brands' actual active ads: AG1 (~500 ads), HelloFresh, Glossier, Skims, Noom, YoloFoods MY, PopMeals MY. 8 recreatable concepts.
7. **`research/VIRAL-AD-FORMULAS-2025-2026.md`** — Top 50 hooks, screenshot aesthetics, ASMR food (highest scroll-stop), Xiaohongshu crossover, anti-ad performance, emotional triggers ranked (FOMO #1, Trust #2, Aspiration #3). 15-second storytelling arc.

### Campaign architecture & setup docs
8. **`META-ADS-ACCOUNT-ARCHITECTURE.md`** — 4-campaign structure (Test 15%, Scale 50%, ASC 25%, Retarget 10%). Exact ad set configs, retargeting 3-tier system with 17 custom audiences, testing cadence Mon/Thu, scaling rules, Malaysia-specific (Ramadan/CNY timing), $1M+ brand patterns.
9. **`META-ADS-BIDDING-OPTIMIZATION-2026.md`** — All 5 bid strategies compared. 3-phase setup (data→scale→value). Cost cap starts AT actual CPA then tighten. Learning phase = 10 conversions for Purchase. Malaysia CPMs RM8-50.
10. **`META-PIXEL-CAPI-SETUP.md`** — Full Pixel + CAPI dual-pipeline. 10 standard + 6 custom subscription events. Python CAPI implementation. AEM 8-event limit REMOVED (June 2025). EMQ targets. WhatsApp tracking via offline uploads. 4-week implementation checklist.
11. **`META-FLEXIBLE-ADS-GUIDE.md`** — Flexible Ads = 2x conversion rate. Auto-generates carousels from images. 3 creative groups per ad. Best inside ASC. NOT a testing tool. Replaced Dynamic Creative for Sales objective.

### Malaysian market research docs (in `research/`)
12. **`research/MALAYSIAN-CONSUMER-RESEARCH-2026.md`** — Market size, competitors (PopMeals/YoloFoods/DietMonsta), lunch habits, payment methods, pricing psychology (RM19 below RM20 barrier), seasonal calendar, XHS influence, demographics, customer avatar.
13. **`research/MALAYSIA-CONSUMER-RESEARCH-2025-2026.md`** — Ad cost benchmarks (CPC RM0.50-6.00), best ad times (Wed best, Sun worst), language nuances (code-switching, Simplified Chinese, Cantonese in KL), BNPL data, social commerce.
14. **`research/MALAYSIA-META-ADS-CREATIVE-RESEARCH-2026.md`** — Malaysia 75% cheaper than US for Meta ads, UGC +38% ROAS, video 3x engagement, color preferences, health claims regulations (RM10K fine), Ramadan opportunity, halal as quality signal.
15. **`research/MALAYSIA-AD-CREATIVE-RESEARCH.md`** — XHS aesthetic (2.5M MY users, 88% female), Korean influence (66.6% favor K-beauty), food photography style, competitor creative analysis, platform usage by demo.
16. **`research/MALAYSIA-OFFER-CONVERSION-RESEARCH-2026.md`** — 50% off first order standard, promo code culture, WhatsApp ordering, payment gateways (Billplz/Curlec), checkout optimization, delivery partners, trust signals, price anchoring.

### Quick-recall cheat sheet (updated)
**Formats:** Carousel = 4.2x ROAS | Reels = 34.5% lower CPA | Static = 60-70% of conversions by volume
**Creative:** Lo-fi/ugly = +72% ROAS | Text-led UGC > talking head by 38% | 40-50% of ads should be unpolished
**Copy:** PAS = highest converting | First-person ("my RM19 lunch") = +90% vs second-person | 125 chars above fold
**Psychology:** Warm tones +18% food ads | Crimson CTA +21-34% | Single-action = +371% clicks | 4.2-4.5 star ratings peak
**Algorithm:** Andromeda suppresses >60% similarity | GEM scores first 3 sec separately | Creative = 75-90% of performance
**Subscription:** Month 1 = 0.8x ROAS | Month 6 = 4.5x | Month 12 = 8.2x | Referral at order 3 | Pause > cancel
**Cultural:** Xiaohongshu shapes IG expectations | RM19 = below impulse threshold | Identity aspiration > rational convince
**Engagement:** Reply to EVERY ad comment = +22% conversion lift (free!)
**Transfer map:** Glossier = mini-story | Skims = exhaustion hook | AG1 = subscription stacking | Reformation = sassy data | Noom = show the "bad" food
**Account:** 4 campaigns: Test (ABO 15%) → Scale (CBO 50%) → ASC (25%) → Retarget (CBO 10%)
**Bidding:** Phase 1 Lowest Cost → Phase 2 Cost Cap (start AT actual CPA) → Phase 3 ROAS Target + Value Rules
**Tracking:** Pixel + CAPI dual-pipeline | Send renewals as BOTH RecurringPurchase AND Purchase | AEM limit removed | EMQ target 8.8+
**Testing:** Mon/Thu launch cadence | Kill at RM450 spend + 0 purchases | Promote at CPA < RM80 + ROAS > 3x + 15+ conversions
**Flexible Ads:** 2x CVR vs standard | Auto-generates carousels | 3 groups per ad | Best inside ASC | NOT for testing (broken per-asset reporting) | Graduate winners FROM test → INTO Flexible Ads for scaling
**Malaysia Market:** CPC RM0.50-1.00 F&B (75% cheaper than US) | CPM RM5-25 | F&B CVR 2.02% (highest vertical) | 70%+ mobile | WhatsApp 89.3% penetration, 45-60% CTR
**Malaysia Language:** Simplified Chinese + English code-switch | Manglish particles (lah, lor, meh) | Pure mainland = foreign | Bilingual = 27% higher CTR | Cantonese for KL audio
**Malaysia Conversion:** WhatsApp > website | FPX mandatory (37%) | TnG 62% preference | 50% off first order (market norm) | Promo code mandatory | Bill on 1st
**Malaysia Timing:** Best 11AM-1PM Wed-Fri | Wednesday = best day | Sunday = worst | Payday 25th-3rd = peak conversion window
**Malaysia Legal:** "Burns fat"/"reduces obesity" = RM10K fine or 2yr jail | Safe: "low calorie," "portion-controlled," "balanced nutrition"
**Malaysia Avatar:** Chinese woman 27-33, KL/PJ, RM4-8K income, Pilates, XHS+IG, loosely counts calories, wants effortless slim
**Unit Economics:** 37-50% contribution margin | CAC RM50-80 | Payback ~12 days | LTV RM1,357 (30% churn) | LTV:CAC 9.1x | Need 632 new subs/month at 30% churn for RM800K
**WhatsApp:** Respond.io $159/mo | ctwa_clid for CAPI attribution (solved) | CTWA = 5x lower CPA | 98% open rate | RM6,860/mo ops at 100 orders/day
**Production:** 3-3-3 method (27 ads/cycle) | Kill CTR<0.5% at 24h | Scale 20% every 48-72h via original Post ID | Lifespan 14-21 days | 80-90% concepts fail (normal)
**XHS:** CES formula (Follow 8x, Comment 4x, Save 1x) | Video 1.7x photos | Content lives months (not 48h like IG) | KOC RM100-300 | 30-50 reviews = critical mass | RM51-87K for 6-month launch
**Competition:** ZERO aspirational/female-first brands in MY meal delivery | Every competitor is generic or fitness-bro | Mirra's position completely uncontested
