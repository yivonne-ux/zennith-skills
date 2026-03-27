---
name: ad-composer
description: Unified ad image generation CLI wrapping NanoBanana (Gemini), Recraft V4, and Flux 2 Pro (fal.ai) for GAIA CORP-OS brand content.
agents:
  - dreami
  - iris
---

# Ad Composer — Unified Image Generation

Multi-model image generation CLI for ad creatives across all GAIA brands. Wraps three image generation backends into a single interface with brand-aware prompt enrichment.

## Models

| Model | Backend | Best For | Cost | Speed |
|-------|---------|----------|------|-------|
| `nanobanana` | Gemini (Google) | Character consistency, style seeds, ref images | Cheapest | Fastest |
| `recraft` | Recraft V4 API | Marketing visuals, text rendering, product mockups | Mid | Fast |
| `recraft-pro` | Recraft V4 2048x2048 | Highest quality marketing, large format | Higher | Fast |
| `flux` | Flux Pro v1.1 (fal.ai) | Photorealistic, strong prompt adherence | Mid | Slower (queue) |
| `flux2` | Flux 2 Pro (fal.ai) | Better text rendering, HEX color support, up to 10 ref images | ~$0.03/img | Slower (queue) |

## Script

```
~/.openclaw/skills/ad-composer/scripts/ad-image-gen.sh
```

## Commands

### generate — Single image
```bash
ad-image-gen.sh generate --model recraft --prompt "..." --output /path/to/out.png
```

### batch — Multiple prompts from JSON file
```bash
ad-image-gen.sh batch --model nanobanana --prompt-file prompts.json --output-dir ./out/
```
Prompt file format: JSON array of strings `["prompt 1", "prompt 2"]` or objects `[{"prompt": "..."}]`.

### compare — Same prompt across all models
```bash
ad-image-gen.sh compare --prompt "..." --output-dir ./compare/
```
Outputs: `nanobanana.png`, `recraft.png`, `flux.png`, `flux2.png` in the output directory.

### models — List available models
```bash
ad-image-gen.sh models
```

## Common Flags

| Flag | Values | Notes |
|------|--------|-------|
| `--model` | nanobanana, recraft, recraft-pro, flux, flux2 | Required for generate/batch |
| `--prompt` | string | Required |
| `--output` | path | Auto-generated if omitted |
| `--brand` | mirra, pinxin-vegan, wholey-wonder, etc. | Loads brand DNA, enriches prompt |
| `--aspect-ratio` | 1:1, 4:5, 5:4, 9:16, 16:9 | Mapped to each model's native format |
| `--quality` | standard, high | high = 2048px (Recraft) |
| `--style` | realistic, digital_illustration, vector_illustration | Recraft only |
| `--style-seed` | seed ID | NanoBanana only |
| `--ref-image` | path | NanoBanana only |

## API Keys

Set in `~/.openclaw/.env`:
- `GOOGLE_API_KEY` or `GEMINI_API_KEY` — NanoBanana (Gemini)
- `RECRAFT_API_KEY` — Recraft V4
- `FAL_KEY` or `FAL_API_KEY` — Flux 2 Pro (fal.ai)

## Model Selection Guide

- **Speed + volume**: NanoBanana (cheapest, supports style seeds)
- **Text on images**: Recraft (best text rendering in the industry)
- **Product mockups**: Recraft or Recraft Pro (marketing-optimized)
- **Photorealism**: Flux Pro or Flux 2 Pro (strongest prompt adherence)
- **Text on images (AI)**: Flux 2 Pro (improved text rendering + HEX color support)
- **Character consistency**: NanoBanana (style seeds + reference images)
- **Cheapest AI photo**: Flux 2 Pro ($0.03/image at 1024x1024)
- **Comparison**: Use `compare` command to test all four models side by side

## Logs

All operations logged to `~/.openclaw/logs/ad-image-gen.log`.

---

## URL-to-Ad Pipeline

> Implemented in `ad-compose.sh url-to-ad`. Scrapes a product URL, extracts data, and generates ad copy variants + image prompt.

End-to-end pipeline that takes a product URL and outputs a complete ad (image + copy + CTA) ready for Meta/TikTok.

### Pipeline Flow

```
Input: Product URL (Shopee, Lazada, website, Gumroad)
     ↓
Step 1: Scrape product page (title, price, images, description)
     ↓
Step 2: Auto-detect brand (match against DNA.json library)
     ↓
Step 3: Select funnel stage (TOFU awareness / MOFU consideration / BOFU conversion)
     ↓
Step 4: Generate ad copy using marketing-formulas skill
     ↓
Step 5: Generate ad image via NanoBanana / Recraft / Flux
     ↓
Output: Complete ad (image + copy + CTA) ready for Meta/TikTok
```

### Funnel-Stage Prompts

| Stage | Intent | Prompt Pattern | Example |
|-------|--------|---------------|---------|
| **TOFU** (Top of Funnel) | Problem-awareness hook | "Did you know..." / "Most people don't realize..." | "Did you know 80% of gut issues start with what you eat for breakfast?" |
| **MOFU** (Middle of Funnel) | Solution-education | "Here's how [product] solves [pain point]..." | "Here's how Wholey Wonder's oat bites solve your 3pm energy crash..." |
| **BOFU** (Bottom of Funnel) | Direct offer + urgency | "Get [product] now — [offer] + [urgency]" | "Get Mirra's 5-Day Bento Box now — 20% off, this week only" |

### Auto-Fetch Product Data

Scrape product page using Jina Reader API for clean markdown extraction:

```bash
# Scrape product page
curl -sL "https://r.jina.ai/<product_url>" | head -c 5000
# Extract: title, price, images, description, reviews
```

Fields extracted:
- **Title** — product name
- **Price** — current price + any discount/original price
- **Images** — hero image URL(s) for reference in image generation
- **Description** — product copy, ingredients, specs
- **Reviews** — star rating + review count (social proof for BOFU ads)

### Brand Profile Selection

Auto-match the product URL domain to a brand DNA.json in `~/.openclaw/brands/`:

1. Extract domain from URL (e.g., `shopee.com.my/pinxin-vegan` → `pinxin-vegan`)
2. Match against known brand slugs: pinxin-vegan, wholey-wonder, mirra, rasaya, dr-stan, serein, gaia-eats
3. Load matching `~/.openclaw/brands/{brand}/DNA.json` for voice, colors, fonts, audience
4. If unknown brand: use generic profile, ask user to confirm before generating

Brand DNA applied to output:
- **Colors** — brand palette injected into image generation prompt
- **Fonts** — specified in ad overlay/text rendering
- **Voice** — tone, vocabulary, banned words applied to copy generation
- **Audience** — demographic targeting informs hook selection

### Batch Variant Matrix

Generate multiple ad variants per product for A/B testing (pattern from NemoVideo):

**5 hook types x 2 caption styles = 10 variants per product**

| Hook Type | Example |
|-----------|---------|
| **Question** | "Still struggling with meal prep?" |
| **Statistic** | "9 out of 10 nutritionists recommend..." |
| **Story** | "Last month, Sarah switched to..." |
| **Problem** | "Tired of bland healthy food?" |
| **Social proof** | "Join 5,000+ customers who..." |

| Caption Style | Description |
|---------------|-------------|
| **Short punchy** | 1-2 lines, emoji-driven, CTA-forward |
| **Long-form educational** | 3-5 lines, problem→solution→proof→CTA |

Auto-generate all 10 variants, then let Hermes pick top 3 for testing based on predicted CTR.

### Integration

| Dependency | Purpose |
|------------|---------|
| `nanobanana-gen.sh` | Image generation (cheapest, style-seed support) |
| `ad-image-gen.sh` | Multi-model image generation (Recraft, Flux fallback) |
| `marketing-formulas` skill | Copy frameworks (PAS, AIDA, BAB, 4Ps) |
| `brand-voice-check.sh` | Validates copy matches brand DNA before publishing |
| `meta-ads-manager` | Feeds completed ads into campaign creation |
| `content-scraper` | Scrapes product URLs via Jina Reader API (was `content-intel`, now archived) |

### Usage

```bash
# Single ad from URL (auto-detect brand, default BOFU)
ad-compose.sh url-to-ad --url "https://shopee.com.my/product/123" --funnel bofu

# Specify brand + funnel stage
ad-compose.sh url-to-ad --url "https://gumroad.com/l/product" --brand mirra --funnel tofu

# Batch: generate 10 variants (5 hooks x 2 caption styles)
ad-compose.sh url-to-ad --url "https://shopee.com.my/product/123" --batch --output-dir ./variants/

# Compare across funnel stages
ad-compose.sh url-to-ad --url "https://shopee.com.my/product/123" --funnel all --output-dir ./funnel-test/
```
