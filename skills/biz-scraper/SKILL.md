---
name: biz-scraper
description: GAIA E-Commerce Flywheel — Ali Akbar "Spy → Clone → Scale" method with AI agents. Scrapes competitors, clones winning funnels, generates content at scale, launches, measures, compounds.
---

# Biz Scraper — GAIA E-Commerce Flywheel

The "Spy → Clone → Scale" engine for GAIA CORP-OS. Turns competitor intelligence into ready-to-launch campaigns using the full agent roster.

Based on vault.db knowledge:
- Ali Akbar spy-clone-scale method
- Multi-business expansion: digital dropshipping (100% margin), physical dropshipping (25-40%), AI content ops (90%+)
- Happy Mammoth funnel analysis (upsells, subscriptions, email collection, urgency, AOV $259)
- Seena Rez Dopamine Cycles + Harmonic Trio + 3-Second Rule

## Script

```
~/.openclaw/skills/biz-scraper/scripts/biz-scraper.sh
```

## Commands

### spy — Scrape & score a product/competitor URL
```bash
biz-scraper.sh spy --url <product_url> [--brand <brand>]
```
Scrapes via Jina Reader API, extracts product name, price, funnel indicators (upsells, bumps, subscriptions, urgency, email capture), scores opportunity, saves to vault.db as `source_type='biz-opportunity'`.

### spy-niche — Research a niche keyword
```bash
biz-scraper.sh spy-niche --keyword <niche> [--brand <brand>]
```
Searches for top competitors in a niche, scrapes top results, scores each.

### clone — Generate campaign brief from opportunity
```bash
biz-scraper.sh clone --id <vault_id> [--brand <brand>]
```
Reads a biz-opportunity from vault.db and outputs a campaign brief JSON.

### status — Check flywheel pipeline
```bash
biz-scraper.sh status [--brand <brand>]
```
Shows counts of opportunities, briefs, campaigns in each stage.

---

## Flywheel Architecture

Six stages, each owned by specific agents. Output of each stage feeds the next.

```
  ┌──────────┐     ┌──────────┐     ┌──────────┐
  │  1. SPY  │────▶│ 2. CLONE │────▶│3.GENERATE│
  │ Artemis  │     │Dreami+   │     │ Iris+    │
  │          │     │Hermes    │     │ Dreami   │
  └──────────┘     └──────────┘     └──────────┘
       ▲                                  │
       │                                  ▼
  ┌──────────┐     ┌──────────┐     ┌──────────┐
  │6.COMPOUND│◀────│5.MEASURE │◀────│4. LAUNCH │
  │  Taoz    │     │ Athena   │     │ Hermes   │
  └──────────┘     └──────────┘     └──────────┘
```

### Stage 1: SPY (Artemis)

**Purpose:** Gather competitive intelligence and score opportunities.

**Input:** Product URL, competitor URL, or niche keyword.

**Process:**
1. Scrape target URL via Jina Reader API (`curl -sL "https://r.jina.ai/<url>"`)
2. Extract structured data:
   - Product name, description, category
   - Pricing (base, upsells, bumps, subscription tiers)
   - Funnel structure (landing page flow, checkout steps, post-purchase upsells)
   - Ad creative style (hooks, CTAs, social proof elements)
   - Email/SMS capture mechanisms
   - Urgency/scarcity tactics (countdown timers, limited stock, FOMO)
3. Score opportunity (0-100):
   - Market size signal (traffic indicators, review count)
   - Margin potential (price vs likely COGS)
   - AI-content fit (can we generate equivalent content with our tools?)
   - Brand alignment (does it fit a GAIA brand?)
4. Save to vault.db as `source_type='biz-opportunity'`

**Output:** `biz-opportunity` JSON in vault.db with fields:
```json
{
  "url": "...",
  "product_name": "...",
  "price": "...",
  "funnel": { "upsells": [], "bumps": [], "subscription": false },
  "score": 75,
  "score_breakdown": { "market": 80, "margin": 70, "ai_fit": 90, "brand_fit": 60 },
  "funnel_indicators": ["email_capture", "urgency_timer", "upsell_post_checkout"],
  "scraped_at": "2026-03-08T..."
}
```

### Stage 2: CLONE (Dreami + Hermes)

**Purpose:** Transform opportunity intel into a complete campaign brief.

**Input:** `biz-opportunity` from Stage 1 (vault.db ID).

**Dreami tasks:**
- Generate ad copy variants using marketing formulas:
  - PAS (Problem-Agitate-Solution) x 3 variants
  - AIDA (Attention-Interest-Desire-Action) x 3 variants
  - BAB (Before-After-Bridge) x 3 variants
- Generate image prompts for NanoBanana (product shots, lifestyle, UGC-style)
- Apply Seena Rez principles:
  - Dopamine Cycles: hook → payoff → hook within each ad
  - Harmonic Trio: visual + text + audio alignment
  - 3-Second Rule: first 3 seconds must arrest attention

**Hermes tasks:**
- Design funnel structure:
  - Landing page (hero, social proof, FAQ, CTA)
  - Checkout flow (order bump, quantity breaks)
  - Post-purchase upsell sequence (complementary products)
  - Email sequence (welcome → value → offer → urgency → last chance)
- Set pricing strategy using growth-engine models:
  - Anchor pricing (show "was" price)
  - Bundle tiers (good / better / best)
  - Subscription option with discount incentive
  - Target AOV based on Happy Mammoth benchmark ($259)

**Output:** Campaign brief JSON saved to vault.db as `source_type='campaign-brief'`:
```json
{
  "opportunity_id": 123,
  "brand": "wholey-wonder",
  "ad_copy": { "pas": [...], "aida": [...], "bab": [...] },
  "image_prompts": [...],
  "funnel": { "landing": {...}, "checkout": {...}, "upsells": [...], "email_sequence": [...] },
  "pricing": { "base": 49, "anchor": 89, "bundle_3": 129, "subscription": 39 }
}
```

### Stage 3: GENERATE (Iris + Dreami)

**Purpose:** Produce all creative assets from the campaign brief.

**Input:** Campaign brief from Stage 2.

**Iris tasks:**
- Generate product images via NanoBanana (`nanobanana-gen.sh`)
  - Hero product shot (white bg, clean)
  - Lifestyle shot (in-use, aspirational)
  - UGC-style (phone selfie aesthetic)
  - Comparison/before-after
- Generate video ads via video-gen pipeline
  - 5s hook clip (Kling 3.0 for face, Sora 2 for product)
  - 15s story ad
  - 30s full ad (hook → problem → solution → CTA)

**Dreami tasks:**
- Generate 30-day content calendar:
  - Daily hooks (attention-grabbing openers)
  - Platform-specific posts (IG, TikTok, Facebook)
  - Story sequences (3-5 frame narratives)
- Batch variant matrix: 5 hooks x 2 visual styles = 10 variants per product
  - Hook types: question, shock stat, personal story, demonstration, social proof
  - Visual styles: polished brand, raw UGC

**Output:** Content library at `workspace/data/campaigns/<brand>/<campaign>/`:
```
images/      — product shots, lifestyle, UGC
videos/      — ad clips, stories
copy/        — ad copy variants (JSON)
calendar/    — 30-day content plan (JSON)
```

### Stage 4: LAUNCH (Hermes)

**Purpose:** Deploy campaigns to sales channels.

**Input:** Content library from Stage 3.

**Process:**
1. Deploy to channels:
   - Meta Ads (Facebook + Instagram): carousel, story, reel formats
   - TikTok Ads: native-style video ads
   - Shopee: product listings with optimized titles/descriptions
   - Gumroad: digital product pages with upsell flows
2. Set A/B test structure:
   - 2-3 ad sets per campaign
   - Test variables: hook, creative, audience
   - Budget: start at $5-10/day per ad set
3. Configure targeting:
   - Lookalike from existing customers
   - Interest-based for cold traffic
   - Retargeting for warm traffic

**Output:** Live campaign IDs and tracking links saved to vault.db as `source_type='campaign-live'`.

### Stage 5: MEASURE (Athena)

**Purpose:** Analyze performance and identify winners.

**Input:** Campaign performance data (API pulls or manual input).

**Metrics tracked:**
- CTR (click-through rate) — target >2%
- CPA (cost per acquisition) — target <30% of product price
- ROAS (return on ad spend) — target >3x
- Creative fatigue — CTR decline over 3+ days
- Funnel conversion rates — landing → cart → checkout → purchase
- Email sequence performance — open rate, click rate, revenue per email

**Analysis:**
- Rank creatives by ROAS
- Identify fatigue patterns (kill losers early)
- Flag winning hooks/angles for scaling
- Compare against Happy Mammoth benchmarks

**Output:** Optimization report saved to vault.db as `source_type='campaign-analysis'`:
```json
{
  "campaign_id": "...",
  "winners": [{"creative": "pas_v2", "roas": 4.2, "recommendation": "scale"}],
  "losers": [{"creative": "aida_v1", "ctr": 0.8, "recommendation": "kill"}],
  "next_actions": ["scale pas_v2 to $50/day", "generate 3 new hooks based on pas_v2 angle"]
}
```

### Stage 6: COMPOUND (Taoz)

**Purpose:** Feed learnings back into the system so every cycle gets faster and cheaper.

**Process:**
1. Extract winning patterns from Stage 5 analysis
2. Save to vault.db as `source_type='pattern'`:
   - Winning hooks (exact phrases that drove CTR)
   - Winning visuals (styles, compositions, colors)
   - Winning funnels (upsell sequences, pricing tiers)
3. Update system knowledge:
   - KNOWLEDGE-SYNC.md with new patterns
   - digest.sh to crystallize learnings
4. Improve prompts:
   - Update image prompt templates with winning visual patterns
   - Update ad copy templates with winning hooks
   - Update funnel templates with winning structures
5. Next cycle inputs from vault.db — starts faster, costs less, converts better

---

## Routing

| Stage | Tier | Agent(s) | Trigger |
|-------|------|----------|---------|
| SPY | DISPATCH | Artemis | `biz-scraper.sh spy --url ...` |
| CLONE | DISPATCH | Dreami, Hermes | `biz-scraper.sh clone --id ...` |
| GENERATE | DISPATCH/SCRIPT | Iris, Dreami | Campaign brief ready |
| LAUNCH | DISPATCH | Hermes | Content library ready |
| MEASURE | DISPATCH | Athena | Campaign live >48h |
| COMPOUND | CODE | Taoz | Analysis complete |

## Dependencies

- Jina Reader API (free tier, no key needed for basic scraping)
- vault.db (`~/.openclaw/workspace/vault/vault.db`)
- NanoBanana (`nanobanana-gen.sh`) for image generation
- video-gen pipeline for video ads
- marketing-formulas skill for ad copy frameworks
- growth-engine skill for pricing models
- Brand DNA files at `~/.openclaw/brands/{brand}/DNA.json`
