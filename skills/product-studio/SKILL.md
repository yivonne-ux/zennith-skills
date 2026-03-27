---
name: product-studio
description: Automated product photography, product placement, and model swapping pipeline for all GAIA brands. Pack shots, lifestyle scenes, e-commerce assets, and campaign visuals.
agents: [dreami, taoz]
version: 1.0.0
triggers: product photo, product shot, pack shot, product placement, model swap, outfit swap, e-commerce image, product photography, lifestyle scene, product studio, generate product image
anti-triggers: translate, brand design, jade content, video generation, code deploy, ads audit
outcome: 15-20 production-ready product images per product (pack shots + lifestyle scenes + model shots), quality-checked and registered in visual-registry
---

# Product Studio -- Full Product Content Pipeline

Automated product photography, product placement into AI scenes, and model/outfit swapping for all 14 GAIA brands. Takes a product photo (or product name from brand DNA) and generates a complete visual content library.

---

## 1. How It Works

```
INPUT:  Product name or product photo + brand name
STEP 1: Load brand DNA -> extract colors, mood, typography, avoid-list
STEP 2: Select product type -> load angle/scene/model templates
        Load references/module-a-packshots.md for angle matrices
STEP 3: Generate pack shots (Module A) -> 6-8 images
        Load references/module-a-packshots.md for prompt templates
STEP 4: Generate lifestyle scenes (Module B) -> 4-6 images
        Load references/module-b-placement.md for scene templates + placement prompts
STEP 5: Generate model shots (Module C) -> 3-4 images
        Load references/module-c-model-swap.md for demographic matrix + pose library
STEP 6: Quality check -> brand consistency, product accuracy, artifact scan
        Load references/quality-checklist.md for full checklist
STEP 7: Export to canonical path + register in visual-registry
OUTPUT: 15-20 production-ready images per product
```

For detailed step-by-step with code examples: Load `references/workflow-sop.md`

**Image engine:** NanoBanana (Gemini Image API) via `nanobanana-gen.sh`
**Brand data:** `~/.openclaw/brands/{brand}/DNA.json`
**Output path:** `~/.openclaw/workspace/data/images/{brand}/product-studio/`
**Naming:** `{brand}_{product}_{module}_{angle|scene|pose}_{variant}.png`

---

## 2. Three Modules

### Module A: Pack Shot Generator
Generate product photography at multiple angles with consistent lighting and brand alignment.

**Product types supported:** Food items, beverages, supplements/wellness, print/merch -- each with specific angle matrices.

**Key angles:** Overhead flatlay, 45-degree hero, front packaging, back/nutrition, close-up detail, beauty shot.

**Background variants:** Clean white (e-commerce), branded background, shadow/reflection.

For full angle matrices, background prompts, batch mode, and prompt templates: Load `references/module-a-packshots.md`

### Module B: Product Placement Engine
Place real products into AI-generated lifestyle scenes matching brand mood and context.

**3-step workflow:** Generate base scene -> Composite product via reference image -> Validate lighting/color match.

**Scene categories:** F&B (kitchen, dining, picnic, hawker, office, food truck, breakfast tray), Wellness (bathroom, yoga, morning routine, gym, nightstand), Print/Creative (workspace, gallery, gift, street, flat lay).

For full scene templates and placement prompt engineering: Load `references/module-b-placement.md`

### Module C: Model & Outfit Swap
Generate models interacting with products with demographic diversity and outfit variation.

**Key rules:** Face refs >= 60% of total refs, one change at a time (swap model OR outfit OR pose, never all), Flash for full-body, Pro for close-ups.

**Includes:** Demographic diversity matrix (8 groups), pose library (8 poses), brand-specific model guidelines, complete brand matrix (14 brands).

For full model swap workflows, demographic matrix, and brand matrix: Load `references/module-c-model-swap.md`

---

## 3. Reference Files

| Reference File | Contents | Load During |
|---|---|---|
| `references/module-a-packshots.md` | Angle matrices (food, beverage, supplement, print), background variants, batch mode commands, pack shot prompt template | Step 2-3 |
| `references/module-b-placement.md` | 3-step composite workflow, scene templates (F&B 7 scenes, Wellness 7 scenes, Print 5 scenes), placement prompt engineering, interaction words | Step 4 |
| `references/module-c-model-swap.md` | Character consistency technique, ref image setup, model swap + outfit swap workflows, demographic diversity matrix (8 groups), pose library (8 poses), brand-specific model guidelines (14 brands), complete brand matrix | Step 5 |
| `references/workflow-sop.md` | Pre-flight checklist, full Pinxin Vegan example, step-by-step code (Steps 1-7), generation order, expected outputs per step | Full pipeline |
| `references/cli-reference.md` | CLI examples (generate, packshot, placement, model-swap, outfit-swap, batch, campaign, dry-run), full flags reference table | CLI usage |
| `references/prompt-templates.md` | 10 production-ready templates: food pack shot (white + branded), supplement, print/merch, F&B placement, wellness placement, model hero shot, model swap, outfit swap, batch diversity | Step 3-5 |
| `references/quality-checklist.md` | Full checklist: product accuracy (5 checks), brand consistency (7 checks), lighting coherence (5 checks), AI artifact scan (8 checks), resolution/format (5 checks), model-specific (6 checks) | Step 6 |
| `references/integration-costs-notes.md` | Upstream/downstream skills, dependencies, agent responsibilities, cost estimates (per-image through full batch), important notes (MIRRA=meals not skincare, label text limitations, Malaysian context) | Planning |

---

## 4. Quick CLI Usage

```bash
# Full pipeline for a product (all 3 modules)
bash scripts/product-studio.sh generate \
  --brand mirra --product "bento-box-a" --ref-image /path/to/photo.jpg

# Pack shots only (Module A)
bash scripts/product-studio.sh packshot --brand pinxin-vegan --product "nasi-lemak-set"

# Product placement only (Module B)
bash scripts/product-studio.sh placement \
  --brand rasaya --product "turmeric-latte" --scenes "kitchen,morning-routine"

# Model swap with diverse demographics (Module C)
bash scripts/product-studio.sh model-swap \
  --brand wholey-wonder --product "acai-bowl" --demographics diverse

# Batch all products for a brand
bash scripts/product-studio.sh batch --brand mirra

# Dry run (preview plan, no API calls)
bash scripts/product-studio.sh generate --brand mirra --product "bento-box-a" --dry-run
```

For full CLI reference and all flags: Load `references/cli-reference.md`

---

## 5. Key Rules

1. **Always load brand DNA first** -- `cat ~/.openclaw/brands/{brand}/DNA.json`
2. **Real product photos as reference are ALWAYS preferred** over text-only prompts
3. **One change at a time** when iterating -- changing multiple elements causes drift
4. **MIRRA is a weight management meal subscription** (bento format) -- NOT cosmetics
5. **gaia-os and iris** are non-product brands -- no physical product photography
6. **Reject and regenerate** if quality score < 7.0/10 (max 3 retries, then flag for manual review)
7. **Generation order matters** -- front view on white first (becomes anchor reference for all other angles)
8. **Label text limitation** -- NanoBanana frequently warps text; consider post-production overlay for e-commerce
9. **Malaysian context** -- scenes should feel authentically Malaysian unless brand targets international
10. **Git commit after every significant batch** -- outputs are tracked in visual-registry

---

## 6. Cost Estimate

| Operation | Approx Cost | Images |
|-----------|-------------|--------|
| Full pack shot set (8 images) | ~$0.16 | 8 |
| Full placement set (5 scenes) | ~$0.10-0.20 | 5 |
| Full model set (4 poses) | ~$0.08-0.16 | 4 |
| **Full pipeline (1 product)** | **~$0.50-0.80** | **15-20** |
| **Full pipeline with retries** | **~$0.80-1.50** | **15-20** |

For full cost breakdown: Load `references/integration-costs-notes.md`
