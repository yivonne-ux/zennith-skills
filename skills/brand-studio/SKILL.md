---
name: brand-studio
agents:
  - dreami
  - iris
---

# Brand Studio — Generate → Audit → Refine Loop

Brand-aware ad generation with visual QA scoring against real brand references.

## Core Principle

**Decompose → Categorize → Label → Compose → Audit → Loop**

Every piece of content (ad, post, video, story, comic) follows the same core system:
1. **Read brand DNA** — colors, typography, badges, avoid-list, style
2. **Select references** — product photos, approved designs, style guides
3. **Compose prompt** — template-aware, brand-injected, ref-guided
4. **Generate** — via NanoBanana (Gemini Image API)
5. **Audit** — Gemini Vision scores against brand rules + reference
6. **Loop** — if score < 7/10, extract feedback, adjust, retry (max 3)

## Usage

```bash
# Composer — run any pre-wired workflow or custom block chain
bash ~/.openclaw/skills/brand-studio/scripts/composer.sh --list
bash ~/.openclaw/skills/brand-studio/scripts/composer.sh --brand mirra --workflow loop-ad --template hero
bash ~/.openclaw/skills/brand-studio/scripts/composer.sh --brand mirra --blocks "compose,audit" --template comparison

# Curator — regression test: 5 types x 3 variations, audit all, compound learnings
bash ~/.openclaw/skills/brand-studio/scripts/curator.sh --brand mirra
bash ~/.openclaw/skills/brand-studio/scripts/curator.sh --brand mirra --types "comparison,hero" --variations 2

# Full loop (generate + audit + retry)
bash ~/.openclaw/skills/brand-studio/scripts/loop.sh \
  --brand mirra --template comparison --headline "This or That"

# Research fill (reference library → headline gen → loop → store)
bash ~/.openclaw/skills/brand-studio/scripts/research-fill.sh --brand mirra --count 5

# Just compose + generate
bash ~/.openclaw/skills/brand-studio/scripts/compose.sh \
  --brand mirra --template hero --headline "Lunch, Upgraded"

# Just audit an existing image
bash ~/.openclaw/skills/brand-studio/scripts/audit.sh \
  --brand mirra --image /path/to/generated.png
```

## Templates

| Template | Description | Best For |
|----------|-------------|----------|
| `comparison` | Split left/right: regular food vs brand | MOFU, This-or-That |
| `grid` | 3x3 product showcase with calorie badges | MOFU, menu reveal |
| `hero` | Single product hero shot with badges | TOFU/MOFU, brand awareness |
| `lifestyle` | Product in context (desk, kitchen) | TOFU, lifestyle |
| `collage` | Multi-product scattered collage | MOFU, variety showcase |

## Agents

- **Iris** — runs the loop, does visual QA (qwen3-vl can see images)
- **Dreami** — writes creative briefs, can request brand-studio generation
- **Taoz** — builds/fixes the scripts (Claude Code CLI)
- **Argus** — regression tests the pipeline

## How It Works

```
compose.sh → reads DNA.json → selects ref images → builds prompt → calls nanobanana-gen.sh
                                                                          ↓
audit.sh ← visual-audit.py ← Gemini 2.5 Flash Vision ← generated image + reference + DNA rules
                                                                          ↓
loop.sh → if FAIL: extract feedback → adjust → retry (max 3) → if PASS: compound learning
```

## Scoring Dimensions (1-10 each)

| Dimension | What It Measures |
|-----------|-----------------|
| `brand_colors` | Palette match (primary, secondary, background) |
| `typography` | Font style match (bold serif, warm, elegant) |
| `layout` | Composition quality, professional ad style |
| `logo_badge` | Logo placement + required badges visible |
| `food_quality` | Appetizing, vibrant, realistic food |
| `mood` | Overall vibe (warm, feminine, clean, Malaysian) |
| `avoid_violations` | No violations of brand avoid-list |

**Pass threshold:** overall >= 7.0/10

## Composable Blocks (ComfyUI-style)

Every script is a composable block with typed inputs/outputs. See `blocks/manifest.json`.

| Block | Category | What It Does |
|-------|----------|-------------|
| `research` | input | Pull refs from gaia.db |
| `headline` | transform | Generate template-aware headlines |
| `compose` | generate | Brand-aware prompt + NanoBanana gen |
| `generate` | generate | Raw NanoBanana generation |
| `audit` | evaluate | Gemini Vision brand compliance scoring |
| `loop` | pipeline | Compose → Audit → Retry until pass |
| `learn` | learn | Compound findings into DNA.json |
| `store` | output | Save to content seed bank |
| `curator` | pipeline | Full regression across types x variations |

Pre-wired workflows: `single-ad`, `loop-ad`, `research-fill`, `curator-regression`, `discovery-loop`

## Curator Pipeline

Regression testing for brand creative quality:
1. Generate N types x M variations (e.g., 5x3 = 15 ads)
2. Audit each with visual-audit (Gemini Vision)
3. Track scores by template + headline
4. learn.sh compounds findings back into `DNA.json → creative_learnings`
5. Winning headlines promoted, failed patterns blocked

DNA learns: `creative_learnings.best_templates`, `creative_learnings.winning_headlines`, `creative_learnings.blocked_headlines`

## Cost

- NanoBanana Flash: ~$0.02/image
- Gemini Vision audit: ~$0.01/audit
- Full loop (1 attempt): ~$0.03
- Full loop (3 retries): ~$0.09
- Curator (5x3 = 15 ads): ~$0.45-$1.35
