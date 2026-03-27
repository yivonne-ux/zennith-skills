---
name: brand-prompt-library
description: Curated prompt packs for AI image generation across all GAIA brands. F&B photography, wellness lifestyle, product shots, and campaign visuals. 200+ tested prompts organized by brand, product type, and use case.
agents: [dreami, taoz]
version: 1.0.0
triggers: brand prompt, image prompt, prompt library, prompt pack, brand photography, nanobanana prompt, generate image for brand, food photography prompt, product shot prompt, campaign visual prompt
anti-triggers: translate, transcreate, video, code, deploy, build, shopify, ads audit, competitor analysis
outcome: Production-ready image generated from a brand-specific prompt template via NanoBanana, scored >= 7/10, registered in visual-registry
---

# Brand Prompt Library

Pre-tested, brand-specific prompt templates for NanoBanana (Gemini Image API) that produce consistent, high-quality images. Each prompt is tagged by brand, product type, use case, and platform. 200+ prompts across 14 brands, with focus on F&B/wellness verticals.

---

## 1. Overview

This skill provides a curated library of production-ready image generation prompts, organized by brand, product type, and use case. Every prompt has been tested against NanoBanana (Gemini Image API) and scored for quality.

**Key principles:**
- Every prompt encodes brand DNA (colors, lighting, mood) from `~/.openclaw/brands/{brand}/DNA.json`
- Prompts are modular: swap subject/product while keeping brand anchors intact
- NanoBanana-specific formatting: aspect ratio hints, style seed compatibility, reference image slots
- All prompts tested and scored (minimum 7/10 to be included)

### Workflow SOP

```
INPUT: Brand name + use case (e.g., "hero-shot", "lifestyle", "seasonal")
STEP 1: Load brand DNA -> extract colors, mood, typography preferences
STEP 2: Select prompt pack for brand + use case
        Load references/prompt-packs-brands.md for brand-specific prompts
        Load references/prompt-packs-seasonal.md for seasonal/campaign prompts
STEP 3: Apply brand color anchors to prompt template
        Load references/prompt-architecture.md for the 7-part prompt structure
STEP 4: Add lighting and style presets from brand profile
        Load references/prompt-architecture.md for lighting/style preset tables
STEP 5: Generate image using NanoBanana with final prompt
STEP 6: Score output against quality criteria (1-10)
        Load references/usage-and-scoring.md for scoring system
STEP 7: If score >= 7, register in visual-registry; if < 7, regenerate with adjusted prompt
OUTPUT: Production-ready image + prompt logged to learnings for compounding
```

### Output Paths

- Prompts stored at: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/`
- Generated images at: `~/.openclaw/workspace/data/images/{brand}/prompt-library/`
- Learnings at: `~/.openclaw/workspace/data/auto-research/prompt-quality/`

---

## 2. Reference Files

All detailed content has been extracted into reference files to keep this procedure lean:

| Reference File | Contents | Load During |
|---|---|---|
| `references/prompt-architecture.md` | 7-part prompt structure, lighting presets, style presets, NanoBanana formatting notes | Step 3-4: Building prompts |
| `references/prompt-packs-brands.md` | All prompt packs by brand (Packs 1-12): Pinxin Vegan, Wholey Wonder, MIRRA, Rasaya, Dr Stan, Serein, GAIA Eats, GAIA Recipes, GAIA Supplements, GAIA Print, Jade Oracle, Iris, GAIA Learn, GAIA OS | Step 2: Selecting prompts |
| `references/prompt-packs-seasonal.md` | Seasonal/campaign prompt packs: Hari Raya, Chinese New Year, Deepavali, Merdeka, Generic Promotional | Step 2: Selecting seasonal prompts |
| `references/usage-and-scoring.md` | CLI usage commands, quality scoring system (1-10), scoring criteria, testing protocol, A/B testing, promotion rules | Step 6-7: Scoring and testing |
| `references/integration-and-ids.md` | Integration with other skills, prompt ID convention table, NanoBanana generation pipeline, example integration flows | All steps: ID lookup, pipeline |
| `references/style-control.md` | Mood presets taxonomy, style comparison methodology, style seed management, brand bleed prevention | Step 4: Style direction |

---

## 3. Quick Reference: Prompt ID Ranges

| Brand | Code | Range |
|-------|------|-------|
| Pinxin Vegan | PXV | 001-020 |
| Wholey Wonder | WW | 001-015 |
| MIRRA | MIR | 001-015 |
| Rasaya | RAS | 001-012 |
| Dr. Stan | DST | 001-012 |
| Serein | SER | 001-012 |
| GAIA Eats | GE | 001-010 |
| GAIA Recipes | GR | 001-010 |
| GAIA Supplements | GS | 001-010 |
| GAIA Print | GP | 001-010 |
| Jade Oracle | JO | 001-008 |
| Iris | IRS | 001-008 |
| GAIA Learn | GL | 001-002 |
| GAIA OS | GO | 001-002 |
| Hari Raya | HR | 001-010 |
| Chinese New Year | CNY | 001-010 |
| Deepavali | DV | 001-008 |
| Merdeka | MY | 001-008 |
| Promotional | PROMO | 001-010 |

**Total: 200+ production-ready prompts.**

---

## 4. Quick CLI Usage

```bash
# List all prompts for a brand
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh list --brand mirra

# Generate image using a library prompt
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate --brand mirra --prompt-id "MIR-001"

# Search prompts across all brands
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh search "turmeric"

# Random prompt for inspiration
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh random --brand mirra

# Top-scoring prompts
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh top --limit 10
```

For full CLI reference, load `references/usage-and-scoring.md`.

---

## 5. Integration

### Used By
- **`product-studio`** -- pulls product photography prompts for e-commerce
- **`creative-studio`** -- sources lifestyle and campaign prompts
- **`content-supply-chain`** -- automated content generation pipeline
- **`ad-composer`** -- ad creative prompts by funnel stage

### Reads From
- **`~/.openclaw/brands/{brand}/DNA.json`** -- brand colors, mood, style, photography direction
- **NanoBanana SKILL.md** -- generation best practices, API parameters

### Stores Data
- **Prompt definitions**: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/`
- **Test results**: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/test-results/`
- **Score index**: `~/.openclaw/skills/brand-prompt-library/prompts/score-index.json`

For full integration details, load `references/integration-and-ids.md`.
