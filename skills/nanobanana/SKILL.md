---
name: nanobanana
description: NanoBanana (Gemini Image API) best practices for character-consistent, multi-scene, brand-aligned image generation across use cases.
agents: [dreami, taoz]
version: 1.0.0
---

# NanoBanana — Image Generation Best Practices

NanoBanana is Google's Gemini image generation system. This skill contains best practices for generating high-quality, brand-consistent images across all GAIA brands.

## Models

| Model | ID | Best For | Max Refs |
|-------|-----|----------|----------|
| **NanoBanana** (fast) | `gemini-3-pro-image-preview` | High-volume, quick iterations | Limited |
| **NanoBanana Pro** (quality) | `gemini-3-pro-image-preview` | Professional assets, character consistency, 4K | 14 images, 5 humans |

## API

```
Endpoint: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
Auth: x-goog-api-key: $GEMINI_API_KEY
```

### Key Parameters
- `response_modalities`: `["TEXT", "IMAGE"]`
- `aspect_ratio`: "1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"
- `image_size`: "1K", "2K", "4K" (uppercase K)

---

## 1. Character Consistency (The Core Technique)

### Step 1: Create Base Character
Define with MAXIMUM specificity in the first prompt. Include age, ethnicity, hair, eyes, clothing, expression, style, lighting.

### Step 2: Lock Core Features
In EVERY follow-up prompt, repeat the defining traits verbatim.

### Step 3: Use Reference Images (Pro only)
Upload previous outputs as reference images to anchor identity (up to 14 refs, 5 humans, 6 objects).

### Step 4: One Change at a Time
Change ONE element per iteration to prevent drift.

### Anchoring Phrases
Always include: "same character", "maintain facial features", "preserve proportions", "keep identity", "consistent with reference"

---

## 2. Tools

**CRITICAL: Always use the full absolute path to nanobanana-gen.sh. NEVER call the Gemini API directly with Python/curl.**

### Generate via API
```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand gaia-eats \
  --use-case product \
  --prompt "GAIA rendang paste packaging on marble surface" \
  --size 4K \
  --ratio 1:1
```

### Generate with Reference Images (HYBRID Approach — Preferred)

**The 3-Ref Setup** (anchors real assets + AI art direction):
1. **Ref 1**: Real SKU product photo (anchors actual food/product)
2. **Ref 2**: Brand style reference (anchors aesthetic, colors, lighting)
3. **Ref 3**: Real logo PNG (anchors brand mark)

**CRITICAL**: Tell the prompt WHICH reference is what:
```
"Showcase the EXACT bento from reference 1,
 styled with the warm natural lighting from reference 2,
 with the MIRRA logo from reference 3 positioned top-right"
```

Up to **14 reference images** total. Refs are comma-separated, placed BEFORE text in API call.
Images >1MB auto-resized via sips to 1024px JPEG.

**WARNING**: NanoBanana does NOT truly lock faces — uses ref as "inspiration", drifts 20-40%.
OK for product/scene consistency. For face lock: use Kling 3.0 elements or LoRA training.

```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand mirra \
  --prompt "EXACT bento from ref 1, styled like ref 2, MIRRA logo from ref 3 top-right." \
  --ref-image "/path/to/sku-photo.png,/path/to/style-ref.jpg,/path/to/logo.png" \
  --size 2K --ratio 1:1 --model flash
```

### Generate with Style Seed
```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand mirra --use-case lifestyle \
  --prompt "Mirra weekly bento meal prep, warm appetizing scene" \
  --style-seed ss-1709000000 --size 2K --ratio 9:16
```

### Generate with Campaign + Funnel Stage
```bash
bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand pinxin-vegan --use-case product \
  --prompt "Festive poon choi hero shot" \
  --campaign cny-2026 --funnel-stage TOFU --size 4K --ratio 16:9
```

Campaign files: `~/.openclaw/brands/{brand}/campaigns/{campaign}.json`. Funnel stages: TOFU, MOFU, BOFU.

### Auto-Registration in Seed Bank
Every successful generation is automatically registered in the image seed bank with full metadata. No manual `image-seed.sh add` needed.

### Other Commands
```bash
# Character sheet
nanobanana-gen.sh character-sheet --brand gaia-eats --description "28yo Malaysian woman" --poses "front,side,waving"

# 12-scene storyboard
nanobanana-gen.sh storyboard --brand gaia-eats --character "28yo Malaysian woman in sage green apron" --product "rendang paste" --scenes 12

# Batch generate
nanobanana-gen.sh batch --brand gaia-eats --product "rendang paste" --use-cases "product,food,lifestyle,flatlay,social"
```

---

## 3. Reference Material

> Load `references/prompt-templates.md` for all use case prompt templates (product, food, lifestyle, flat lay, before/after, packaging, recipe, mascot, print-on-demand, e-commerce, social, educational, 12-scene storyboard).

> Load `references/brand-profiles.md` for brand consistency framework, color/style anchors, brand profile schema, multi-brand support, and content factory integration.
