---
name: image-prompt-framework
description: 5-layer structured prompt engineering for NanoBanana/Gemini image generation. Produces professional photography prompts across all genres.
agents:
  - dreami
  - taoz
---

# Image Prompt Framework — 5-Layer Structured Prompts

Generate professional-quality NanoBanana prompts using a 5-layer framework. Replaces ad-hoc prompting with structured, repeatable photography-grade prompts across all brands.

## When to Use

- Before ANY NanoBanana image generation call
- When Dreami creates visual content for any brand
- When building image prompts for carousel slides, ads, social posts, product shots
- When quality of AI-generated images needs improvement

## The 5 Layers

### Layer 1: Subject
| Element | Description | Example |
|---------|-------------|---------|
| Primary subject | Who/what is the focus | "Young woman with platinum blonde hair in messy updo" |
| Subject details | Attributes, expressions, poses | "warm approachable smile, holding ceramic coffee mug" |
| Subject interaction | Relationship with environment | "sitting cross-legged on floor" |
| Scale & proportion | Size relationships | "medium shot, waist-up" |

### Layer 2: Environment
| Element | Description | Example |
|---------|-------------|---------|
| Location type | Studio, outdoor, urban, interior | "cozy apartment living room" |
| Environmental details | Specific elements, textures | "plants, books, warm textiles, wooden floor" |
| Background treatment | Sharp, blurred, contextual | "slightly blurred background, bokeh" |
| Atmospheric conditions | Fog, rain, clarity | "warm hazy morning light" |

### Layer 3: Lighting
| Element | Description | Example |
|---------|-------------|---------|
| Light source | Natural or artificial | "natural window light, golden hour" |
| Light direction | Front, side, back, Rembrandt | "side lighting from left window" |
| Light quality | Hard, soft, diffused, volumetric | "soft diffused, no harsh shadows" |
| Color temperature | Warm, cool, neutral | "3800K warm tungsten" |

### Layer 4: Technical Photography
| Element | Description | Example |
|---------|-------------|---------|
| Camera perspective | Eye level, low angle, overhead | "slightly above eye level" |
| Focal length | Wide, standard, telephoto | "85mm lens" |
| Depth of field | Shallow, deep, selective | "f/1.4 shallow DoF, subject sharp" |
| Exposure style | High key, low key, balanced | "balanced, natural exposure" |

### Layer 5: Style & Aesthetic
| Element | Description | Example |
|---------|-------------|---------|
| Photography genre | Portrait, product, editorial | "lifestyle editorial" |
| Era/period | Vintage, contemporary, retro | "contemporary Korean editorial" |
| Post-processing | Film emulation, color grading | "warm muted tones, slight film grain" |
| Anti-AI rules | Prevent AI slop | "No illustration, no cartoon, no CG. Real skin with pores." |

## Procedure

### Step 1 — Gather Context

Load the brand DNA: `bash ~/.openclaw/skills/skill-ref.sh <brand> DNA.json`

Extract: visual style, color palette, photography mood, character specs (if applicable).

### Step 2 — Fill All 5 Layers

For each image, fill out ALL 5 layers. Never skip a layer. Incomplete prompts produce generic results.

```
SUBJECT: [Layer 1 filled]
ENVIRONMENT: [Layer 2 filled]
LIGHTING: [Layer 3 filled]
TECHNICAL: [Layer 4 filled]
STYLE: [Layer 5 filled]
```

### Step 3 — Compose Final Prompt

Merge all 5 layers into a single flowing sentence:

```
Photorealistic [ratio] photograph of [SUBJECT], [ENVIRONMENT], [LIGHTING], real skin with pores, [TECHNICAL], [STYLE]. No illustration, no cartoon, no CG.
```

### Step 4 — Anti-AI-Slop Checklist

Before generating, verify:
- [ ] No "beautiful" or "stunning" (too vague)
- [ ] Specific camera settings (not just "nice photo")
- [ ] Specific light direction + color temperature
- [ ] Real imperfections included (pores, grain, slight blur)
- [ ] No centered-everything composition
- [ ] No generic gradient backgrounds
- [ ] No stock-photo-esque poses

### Step 5 — Generate via NanoBanana

```bash
bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand <brand> \
  --use-case <use-case> \
  --prompt "<5-layer prompt>" \
  --ref-image "<face-lock.png>" \
  --model pro \
  --ratio "<ratio>" \
  --size 2K
```

## Genre Templates

Load full templates: `bash ~/.openclaw/skills/skill-ref.sh image-prompt-framework genre-templates.md`

### Quick Reference

| Genre | Key Settings | Mood |
|-------|-------------|------|
| Portrait | 85mm f/1.4, eye-level, Rembrandt lighting | Intimate, warm |
| Product (F&B) | 50mm f/2.8, 45-degree, overhead softbox | Appetizing, real |
| Lifestyle | 35mm f/2.0, candid angle, natural light | Authentic, relatable |
| Fashion | 50mm f/1.8, slightly low angle, dramatic | Editorial, bold |
| Oracle/Spiritual | 50mm f/1.4, moody, candlelight | Mystical, warm |
| Flat lay | 28mm f/5.6, true overhead, even diffused | Clean, organized |

## Brand-Specific Anchors

| Brand | Must-Include in Every Prompt |
|-------|----------------------------|
| Jade Oracle | "warm Korean editorial, jade green + cream + gold, mystical warm atmosphere" |
| Luna Solaris | "platinum blonde messy updo, ice blue-green eyes, effortless cool, vintage meets feminine" |
| MIRRA | "health bento, Malaysian kitchen, warm natural light, portion-visible" |
| Pinxin Vegan | "plant-based, Malaysian Chinese, family warmth, home cooking" |

## Key Constraints

- ALWAYS end prompts with: `No illustration, no cartoon, no CG.`
- ALWAYS include `real skin with pores` for character images
- NEVER use vague terms: "beautiful", "amazing", "stunning", "perfect"
- NEVER skip lighting layer — it's the #1 quality differentiator
- Use specific lens + aperture, not "nice camera"
- Reference REAL photography (not art styles) for photorealistic output
