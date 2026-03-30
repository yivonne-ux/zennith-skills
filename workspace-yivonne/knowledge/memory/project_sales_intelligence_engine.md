---
name: Sales Intelligence Engine — Vision & Architecture
description: Full-stack marketing loop + sales intelligence system. Maps Zennith skills to ACCA/AIDA/ADDA funnels. Next major build.
type: project
---

## SALES INTELLIGENCE ENGINE — Architecture Vision (March 25, 2026)

**Why:** Current system optimizes AWARENESS (creative production) and CONSIDERATION (ad delivery). Missing: bottom-funnel CONVERSION intelligence + post-sale ADVOCACY loop.

### THE FULL MARKETING LOOP

```
┌─────────────────────────────────────────────────────────┐
│                    MARKETING LOOP                        │
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────┐ │
│  │ ATTRACT  │──▶│ CONVERT  │──▶│  CLOSE   │──▶│DELIGHT│ │
│  │ (TOFU)   │   │ (MOFU)   │   │ (BOFU)   │   │(POST) │ │
│  └──────────┘   └──────────┘   └──────────┘   └──────┘ │
│       │              │              │              │      │
│  Creatives      Conversations   WA Sales        Repeat   │
│  Meta Ads       Landing Page    Reply SOP      Referral  │
│  Content        Lead Capture    Close Script   Upsell    │
│       │              │              │              │      │
│  ✅ BUILT        🟡 PARTIAL      ❌ MISSING     ❌ MISSING│
└─────────────────────────────────────────────────────────┘
```

### FRAMEWORKS — Real Application

**ACCA (Awareness → Comprehension → Conviction → Action)**
- Awareness: Meta Ads creative production ✅ BUILT
- Comprehension: Landing page / WA first reply 🟡 PARTIAL
- Conviction: Objection handling / social proof / urgency ❌ MISSING
- Action: Close script / payment link / order confirmation ❌ MISSING

**AIDA (Attention → Interest → Desire → Action)**
- Attention: Hook/scroll-stop (creative) ✅ BUILT
- Interest: Copy/messaging (ad copy engine) ✅ BUILT
- Desire: Testimonials / transformations / scarcity 🟡 PARTIAL
- Action: CTA optimization / checkout flow ❌ MISSING

**ADDA (Attention → Desire → Decision → Action)**
- Aggressive sales variant — focuses on DECISION stage
- Decision = objection demolition + urgency + FOMO
- Most applicable to Mirra (WA sales) and Pinxin (website checkout)

### ZENNITH SKILLS MAPPING (Already Built by Jenn)

| Funnel Stage | Skill | Status | What It Does |
|-------------|-------|--------|-------------|
| ATTRACT | `ads-meta` | ✅ Active | Meta ads management |
| ATTRACT | `ads-creative` | ✅ Active | Creative generation |
| ATTRACT | `identity-gimmick-promo` | ✅ Active | Identity gimmick format |
| ATTRACT | `pinterest-ref` | ✅ Active | Reference scraping |
| ATTRACT | `content-supply-chain` | ✅ Active | Content production pipeline |
| CONSIDER | `ads-landing` | ✅ Ready | Landing page audit |
| CONSIDER | `cro-converter` | ✅ Ready | CRO conversion optimization |
| CONSIDER | `audience-simulator` | ✅ Ready | Pre-test content with personas |
| CONVERT | `shopify-engine` | ✅ Ready | Store management |
| CONVERT | `shopify-cdp` | ✅ Ready | Admin automation |
| CONVERT | `shopsteal` | ✅ Ready | Clone winning funnels |
| CONVERT | `klaviyo-engine` | ✅ Ready | Email automation |
| RESEARCH | `biz-scraper` | ✅ Ready | Competitor spy → clone → scale |
| RESEARCH | `auto-research` | ✅ Ready | Autonomous research agent |
| RESEARCH | `notebooklm-research` | ✅ Ready | Deep research engine |
| RESEARCH | `site-scraper` | ✅ Ready | Full site decomposition |
| RESEARCH | `firecrawl-search` | ✅ Ready | Deep web scraping |
| SCRAPE | `scrapling` | ✅ Ready | Lightweight scraping |
| SCRAPE | `content-scraper` | ✅ Ready | Content extraction |

### WHAT'S MISSING — The Sales Intelligence Gap

**1. WA Sales Reply SOP Intelligence**
- Forensic scrape Malaysian brand WA reply patterns
- Analyze: first reply speed, greeting, objection handling, close technique
- Build: templated reply SOP per brand (Mirra, Pinxin)
- Scrape targets: competing meal delivery, health food, frozen food brands in MY
- Tools: `biz-scraper` + `scrapling` + custom WA forensic

**2. Messenger/IG DM Sales Flows**
- International best practices (D2C brands with WA/Messenger funnels)
- Close rate optimization: what message converts browse → buy
- Speed-to-reply benchmarks (< 5 min = 3x conversion)
- Objection library: price, quality, trust, timing → response templates

**3. Website Single-Page Sales Funnels**
- `shopsteal` + `cro-converter` = clone + optimize winning funnels
- High-converting single-page templates (Happy Mammoth, AG1, Huel)
- Dopamine Cycles (Seena Rez framework — already in biz-scraper knowledge)
- 3-Second Rule: hero image + headline + CTA above fold

**4. Post-Purchase Intelligence**
- `klaviyo-engine` for email sequences (welcome, upsell, reorder)
- Repeat purchase optimization (Mirra: 34% repeat rate)
- Referral/advocacy loop (NPS, refer-a-friend, UGC collection)
- LTV modeling per acquisition channel

**5. Local Geographic Forensic**
- Malaysian F&B delivery brands: Dahmakan, Yolo Foods, The Rebellious Chickpea, etc.
- Scrape their: WA reply SOP, IG DM flow, website funnel, Meta ads
- Benchmark: price points, delivery areas, menu variety, promo strategy
- Gap analysis: where Mirra/Pinxin can win

**6. International Benchmarks**
- Trifecta Nutrition (13.2x ROAS), Factor 75, HelloFresh, AG1
- Analyze: full funnel from ad → landing → checkout → email → repeat
- Adaptation for Malaysian market (lower AOV, WA-dominant, bilingual)

### BUILD PRIORITY

| Priority | What | Effort | Impact |
|----------|------|--------|--------|
| P0 | WA Reply SOP (Mirra) | 1 session | Immediate — 97% convos don't convert |
| P0 | Attribution fix (ad ID capture) | 1 session | Unlocks all optimization |
| P1 | Local competitor forensic (MY F&B) | 2 sessions | Competitive intelligence |
| P1 | Single-page funnel (Pinxin) | 1 session | Website conversion lift |
| P2 | Email sequences (Klaviyo) | 1 session | Repeat purchase revenue |
| P2 | International funnel forensic | 2 sessions | World-class benchmarks |
| P3 | Post-purchase advocacy loop | 1 session | LTV compound |

### NEXT SESSION: Start with P0 — WA Reply SOP + Attribution Fix
