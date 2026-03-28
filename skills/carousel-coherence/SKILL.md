---
name: carousel-coherence
description: Generate visually coherent multi-slide carousels using Gemini image-to-image referencing. Slide 1 sets visual DNA, slides 2-6+ reference it.
agents:
  - dreami
  - taoz
---

# Carousel Coherence — Visual DNA Pipeline

Generate multi-slide carousels where all slides share consistent visual identity. Uses NanoBanana's ref-image capability to chain slide 1 as visual DNA for subsequent slides.

## When to Use

- Generating carousel posts for Jade Oracle, Luna, or any brand
- Creating multi-image Instagram/TikTok carousels (6-20 slides)
- Building ad creative sets that need visual consistency
- Any multi-image generation where slides must look like they belong together

## The Problem

Default NanoBanana generates each image independently. Result: slides have different color palettes, typography styles, lighting, and overall feel. Looks amateur.

## The Solution: Visual DNA Chaining

1. Generate slide 1 with a complete creative brief (the "DNA slide")
2. Pass slide 1 as `--ref-image` to all subsequent slides
3. Each slide prompt references the DNA while adding its own content

## Procedure

### Step 1 — Define the 6-Slide Narrative Arc

Every carousel follows this proven structure:

| Slide | Purpose | Hook Type |
|-------|---------|-----------|
| 1 | **HOOK** — stop the scroll | Bold claim, question, or pain point |
| 2 | **PROBLEM** — the pain | Specific relatable struggle |
| 3 | **AGITATION** — make it worse | "And it gets worse..." escalation |
| 4 | **SOLUTION** — the answer | Your method/tool/insight |
| 5 | **FEATURE** — proof it works | Data, testimonial, or demo |
| 6 | **CTA** — action | "Comment X", "Save this", "Link in bio" |

### Step 2 — Generate the DNA Slide (Slide 1)

Create slide 1 with FULL creative direction:

```bash
bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand <brand> \
  --use-case social \
  --prompt "Vertical 9:16 social media carousel slide. [FULL VISUAL BRIEF: color palette, typography style, background texture, brand elements, layout direction]. Text overlay: '[HOOK TEXT]'. Style: [cream/terracotta/3D/editorial]. NO text in bottom 20% of image." \
  --model pro \
  --ratio 9:16 \
  --size 2K
```

Save the output path as `$DNA_SLIDE`.

### Step 3 — Generate Slides 2-6 with DNA Reference

For each subsequent slide, pass slide 1 as reference:

```bash
for i in 2 3 4 5 6; do
  bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
    --brand <brand> \
    --use-case social \
    --prompt "Vertical 9:16 carousel slide $i of 6. MATCH the visual style, colors, typography, and layout of the reference image EXACTLY. Same background, same accent colors, same text style. Content for this slide: [SLIDE $i CONTENT]. NO text in bottom 20%." \
    --ref-image "$DNA_SLIDE" \
    --model pro \
    --ratio 9:16 \
    --size 2K
done
```

### Step 4 — Visual QA

For each generated slide, verify:
- [ ] Color palette matches slide 1
- [ ] Typography style is consistent
- [ ] Background treatment matches
- [ ] No text in bottom 20%
- [ ] Brand elements present
- [ ] No visual drift from DNA

If any slide fails QA, regenerate ONLY that slide with the DNA reference.

### Step 5 — Export

All slides saved as JPG (TikTok requires JPG, not PNG):
- Resolution: 768x1376 (9:16 vertical)
- Format: JPG quality 95
- Naming: `carousel-{brand}-{date}-slide-{N}.jpg`

## Script Usage

```bash
bash ~/.openclaw/skills/carousel-coherence/scripts/gen-carousel.sh \
  --brand jade-oracle \
  --hook "The universe is sending you a sign right now" \
  --slides 6 \
  --style "cream-editorial"
```

## Platform Rules

| Platform | Format | Max Slides | Ratio | Notes |
|----------|--------|-----------|-------|-------|
| Instagram | JPG/PNG | 20 | 4:5 or 1:1 | Feed carousels |
| TikTok | JPG only | 35 | 9:16 | Photo mode |
| Instagram Stories | JPG/PNG | 10 | 9:16 | Story sequence |

**Critical: No text in bottom 20%** — TikTok/IG overlay controls there.

## Style Presets

| Style | Colors | Typography | Background | Best For |
|-------|--------|-----------|------------|---------|
| cream-editorial | Cream + terracotta + charcoal | Serif headings + mono code | Off-white textured | Educational, tutorials |
| dark-tech | Dark navy + cyan + white | Sans-serif bold | Dark gradient | Developer, technical |
| warm-spiritual | Sage + gold + cream | Serif italic + elegant | Warm texture | Jade Oracle, spiritual |
| vintage-cool | Muted pastels + brown | Mixed serif + handwritten | Paper texture | Luna, lifestyle |
| bold-modern | White + red/coral + black | Impact/condensed sans | Clean white | Marketing, CTA-heavy |

## Key Constraints

- Slide 1 MUST be generated first — it IS the visual DNA
- ALL subsequent slides MUST reference slide 1 via --ref-image
- JPG only for TikTok carousels
- 768x1376 for vertical, 1080x1350 for 4:5 feed
- Max 6 slides for narrative arc (can extend to 20 for listicles)
- Learnings from each carousel saved to `learnings.json` for compound improvement
