---
name: GrabFood Pipeline — COMPLETE Yes/No from V1-V9 + Store batch
description: Every single learning. The food is the SKU — NEVER let AI touch it. Segmentation-first architecture is the only way. Read before ANY food photo work.
type: feedback
---

## ABSOLUTE RULES

### 1. FOOD IS THE SKU — NEVER LET AI REIMAGINE IT
NANO/any AI model WILL rearrange, reshape, and reimagine food items.
Wonton-mee-hawker: char siu got rearranged into a neat fan pattern. Original was messy random.
The customer expects to receive EXACTLY what they see in the photo.
**Solution: Segment food OUT. AI only touches background/plate/lighting. Food composited back pixel-perfect.**

### 2. NEVER USE PIL FOR CREATIVE EDITING
PIL ImageEnhance, numpy color math, PIL filters = forced, over-contrasted, amateur results.
ALL creative = AI passes. PIL = resize + save ONLY.

### 3. NO HARDCODED BOWL/PLATE STYLE
"Grey speckled ceramic" was hardcoded in every prompt. Should be flexible — based on reference image or user choice. Some stores want white porcelain, some want wooden bowls, some want the original plate.

### 4. NO YELLOW LIGHTING ARTIFACT
"Warm light from upper-left" = NANO puts a visible yellow glow on the white background.
Fix: separate the lighting instruction from the background instruction. Light enhances FOOD, not background.

### 5. WHITE BACKGROUND MUST BE PURE WHITE
AI cannot generate pure white (VAE drift). But single-pass NANO can get CLOSE if prompted correctly.
The problem is when warm lighting bleeds into the white bg.
Fix: explicitly say "white background must remain PURE WHITE with ZERO color cast, ZERO gradients"

## WHAT WORKS (YES)
- ✅ Scene reconstruction concept (FoodShot approach)
- ✅ Premium bowl/plate upgrade
- ✅ Reference-driven (Pinterest ref as Image 1)
- ✅ Square-in-square-out (pad input to 1:1, NANO outputs 1:1)
- ✅ No props (food and bowls only)
- ✅ Razor sharp everything (product photo, no DOF)
- ✅ Warm food colors (暖色提高食欲感)
- ✅ Natural soft shadow (when NANO handles it, not PIL)
- ✅ Two-pass approach (reconstruct → finish) gives better results than single pass
- ✅ Diagonal composition (main dish lower-left, side upper-right)
- ✅ NANO output resized by PIL only — no post-processing
- ✅ Batch processing with consistent store style template
- ✅ V5 shadow quality was good (before PIL ruined it)

## WHAT FAILS (NO)
- ❌ Single-pass NANO changing food — reimagines arrangement, changes portions
- ❌ PIL color grading — forced, over-contrasted, ruins photos
- ❌ PIL white clipping (>240→255) — destroys shadow gradients
- ❌ PIL film grain — digital noise, not organic
- ❌ Hardcoded bowl style in prompt — should be reference-driven
- ❌ "Warm light from upper-left" in prompt — creates yellow bg artifact
- ❌ rembg on white plates — can't distinguish plate from white bg
- ❌ Landscape output squeezed to square — crops shadow
- ❌ Generic Pexels references — template output
- ❌ NANO "make background white" — produces grey
- ❌ Multiple PIL passes degrading quality
- ❌ Adding props then removing — creates artifacts

## CORRECT ARCHITECTURE (not yet built)

```
1. INPUT: Original food photo (this is the SKU — sacred)

2. SEGMENT: Use RMBG-2.0/BiRefNet to extract food+plate as mask
   - Food pixels preserved EXACTLY
   - Background mask for inpainting

3. SCENE RECONSTRUCT: AI inpaints ONLY the background/plate
   - Uses inverted mask (food region = protected)
   - Reference image guides the style
   - Plate upgrade happens here (if plate is in the inpainting zone)
   - Lighting enhancement on food via relighting (IC-Light)

4. WHITE BACKGROUND: Composite food onto pure white canvas
   - OR second AI pass to replace scene bg with white
   - Shadow synthesized programmatically or via AI

5. PHOTOGRAPHIC FINISH: AI pass for warmth, gloss, exposure
   - "Enhance food warmth and appetite appeal"
   - Applied to the composited result
   - Background protected

6. EXPORT: PIL resize to 800x800. NOTHING ELSE.
```

## BATCH CONSISTENCY
- Same reference for all photos in one store
- Same prompt template — only food description changes
- Same bowl style (but not hardcoded — from reference)
- Same lighting direction
- Same angle (45° default)
- Store consistency check after batch

## REFERENCE REQUIREMENTS
- NOT Pexels stock photos (template output)
- Pinterest / Behance / professional photographer portfolios
- Art-directed, not generic
- Audited by photo scorer (8+/10 only)
- Matched to cuisine type (noodle ref for noodle, soup ref for soup)
- The reference drives the STYLE, not hardcoded prompt text

## TOOLS NEEDED
- RMBG-2.0 or BiRefNet for segmentation (better than rembg for food)
- NANO Banana Pro for scene reconstruction + finish passes
- IC-Light for relighting (optional, advanced)
- DetailTransfer concept for texture preservation
- PIL for resize/save ONLY
