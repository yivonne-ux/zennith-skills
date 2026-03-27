---
name: shopsteal
agents:
  - scout
---

# ShopSteal — E-Commerce Clone & Improve Pipeline

## What This Does
Scrape any e-commerce site (Shopify, Woo, custom), decompose ALL materials, regenerate everything with YOUR branding, deploy to YOUR Shopify store. Goal: higher CTR, higher conversion rate than the original.

## Pipeline (6 phases)

```
PHASE 1: SCRAPE — Full site decomposition
  Input: target URL (e.g., psychicsamira.com)
  Output: material-inventory.json
  Tool: site-scraper skill + Firecrawl for deep pages

  Captures:
  ├── Screenshots (every page, full-length)
  ├── Images (hero, product, lifestyle, icons, badges)
  ├── Videos (if any — testimonial, demo, explainer)
  ├── Copy (headlines, descriptions, CTAs, FAQs, reviews)
  ├── Layout (section order, grid structure, whitespace)
  ├── Colors (palette extraction from CSS + images)
  ├── Fonts (typeface, weights, sizes)
  ├── Social proof (review count, star ratings, testimonials)
  ├── Trust signals (badges, guarantees, security icons)
  └── Funnel structure (landing → product → cart → upsell)

PHASE 2: INVENTORY — Material decomposition
  Input: raw scrape data
  Output: material-list.json (every asset tagged and categorized)

  Each item gets:
  ├── type: image|icon|badge|video|copy|layout
  ├── category: hero|product|lifestyle|testimonial|trust|cta|faq
  ├── source_url: original URL
  ├── source_file: local screenshot/download
  ├── dimensions: WxH
  ├── priority: P1 (must have) | P2 (nice to have)
  ├── regeneration_method: nanobanana|copy-rewrite|icon-gen|video-gen
  └── reference_for_gen: what to use as ref image/style

PHASE 3: BRAND MAP — Map materials to YOUR brand
  Input: material-list.json + YOUR brand DNA.json
  Output: brand-mapped-materials.json

  For each material:
  ├── Original: "Psychic Samira hero — purple gradient, crystal ball"
  ├── Yours: "Jade Oracle hero — jade green, QMDJ compass, Luna portrait"
  ├── Prompt: full NanoBanana/video-gen prompt
  ├── Ref images: YOUR product photos, character refs, brand assets
  └── Copy rewrite: YOUR voice, YOUR USPs, YOUR pricing

PHASE 4: GENERATE — Parallel material generation
  Input: brand-mapped-materials.json
  Output: all regenerated assets in workspace/data/images/{brand}/shopsteal/

  Parallel execution (5 concurrent):
  ├── NanoBanana: product shots, hero images, lifestyle
  ├── NanoBanana: icons and badges (with brand colors)
  ├── Copy engine: all headlines, descriptions, CTAs
  ├── Video-gen: testimonial/demo videos (if needed)
  └── Auto QA: visual-audit.py on every generated image

PHASE 5: COMPOSE — Shopify theme assembly
  Input: all generated materials
  Output: ready-to-deploy Shopify theme + content

  ├── Theme selection/customization (Liquid templates)
  ├── Asset upload to Shopify CDN
  ├── Copy placement (metafields + section content)
  ├── Product creation (title, description, images, pricing)
  ├── Collection setup
  ├── Navigation structure
  └── SEO (meta titles, descriptions, schema markup)

PHASE 6: DEPLOY — Go live
  Input: composed theme
  Output: live Shopify store

  ├── Theme publish
  ├── Domain connect
  ├── Payment gateway
  ├── Shipping rules
  ├── Email flows (Klaviyo)
  └── Tracking (Meta Pixel, GA4, server-side)
```

## Scripts

| Script | Purpose |
|--------|---------|
| `shopsteal.sh` | Master orchestrator — runs all 6 phases |
| `site-decompose.sh` | Phase 1+2: Scrape + inventory |
| `brand-map.sh` | Phase 3: Map materials to brand DNA |
| `material-gen.sh` | Phase 4: Parallel regeneration |
| `shopify-compose.sh` | Phase 5: Theme assembly |
| `shopify-deploy.sh` | Phase 6: Deploy |

## Usage
```bash
# Full pipeline
shopsteal.sh run --target https://psychicsamira.com --brand jade-oracle

# Just scrape + inventory
shopsteal.sh scrape --target https://psychicsamira.com --output ./inventory.json

# Just regenerate from existing inventory
shopsteal.sh generate --inventory ./inventory.json --brand jade-oracle

# Deploy existing materials to Shopify
shopsteal.sh deploy --brand jade-oracle --store thejadeoracle.myshopify.com
```

## Dependencies
- `site-scraper` skill (Firecrawl API)
- `nanobanana-gen.sh` (image generation)
- `video-gen.sh` (video generation)
- `brand-voice-check.sh` (copy QA)
- `visual-audit.py` (image QA)
- Shopify Admin API access (API key per store)

## Architecture Decision
- **Phase 1-4:** Built and first-run by Claude Code (complex, needs debugging)
- **Phase 5-6:** Built by Claude Code, operated by OpenClaw agents after first run
- **Ongoing ops (ads, social, new products):** Fully OpenClaw autonomous

## Key Principle
NEVER just copy. Always IMPROVE:
- Better images (photorealistic AI vs stock photos)
- Better copy (brand-voice-checked, conversion-optimized)
- Better layout (tested patterns, mobile-first)
- Better trust signals (real testimonials from QMDJ readings)
- Better funnel (A/B tested pricing, optimized checkout)

## Status: SCAFFOLD
Phase 1-2 scripts to be built first. Phases 3-6 after Jade Oracle test run.
