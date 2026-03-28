# Grab Listing Skill — Compound Learnings
> From Uncle Chua (34 photos) + Choon Prawn House (16 photos) production run

## Critical Learnings

### 1. Text-only generation > Reference image editing
When the original photo has issues (wrong angle, dark bg, patterned bowl), using it as a Gemini reference PULLS the output back toward the original problems. **Text-only generation** (no reference image) produces consistently better results for:
- Overhead/flat-lay originals → forces proper 45° angle
- Black background originals → avoids dark output
- Patterned bowls → generates clean white bowls
- Wrong dish representations → describe the correct dish in text

**Rule: If the original photo has ANY of these issues, use text-only. Only use reference image if the original is already decent quality.**

### 2. Three category prompts needed
One prompt does NOT fit all. Drinks, food bowls, and rice sets need different prompts:

| Category | Key differences |
|----------|----------------|
| **Food (bowls)** | "Large white ceramic bowl, filling 65-75% of frame" |
| **Drinks (glasses)** | "LARGE tall glass, filling 60-70% of HEIGHT" + "liquid colors VIVID" |
| **Rice sets (plated)** | "ALL components on ONE plate" + "vivid blue butterfly pea rice" |

### 3. Drink photos are hardest
- Tall thin glasses naturally fill less of a square 800x800 canvas
- Gemini renders realistic proportions → glass looks small
- Coffee/tea are naturally low-saturation → look "dull" in metrics
- **Fix: Emphasize LARGE in prompt + auto-zoom crop after generation**

### 4. Quality gate thresholds
From 50-photo production run:
```
Brightness: > 180 (food avg 210, drinks avg 225)
Sharpness:  > 200 (food avg 800, drinks avg 500)
BG white:   > 230 (target 250+)
Coverage:   > 25% for food, > 15% acceptable for drinks
Center X:   0.42 - 0.58
Center Y:   0.42 - 0.58 (drinks tend to sit low at 0.58-0.65)
```

### 5. Auto-retry strategy
- First attempt: reference image + foodporn prompt
- If fails QA (dark/grey bg): retry with same prompt
- If still fails: switch to TEXT-ONLY generation (no reference image)
- If bg grey after generation: PIL pixel-level whitening (neutral grey pixels → white)
- If Gemini adds text labels: crop bottom 15% and re-square

### 6. Dish accuracy matters
Gemini will hallucinate wrong dishes if the text description is vague:
- "Fried beancurd" → generated round crackers instead of rectangular skin chips
- "Pork paste noodle" → generated generic mala with bok choy instead of pork paste balls
- "Nyonya Acar" → generated stir-fried veggies instead of pickled vegetables

**Fix: Be VERY specific in dish descriptions — list every ingredient, color, shape, arrangement.**

### 7. Consistent visual standard
The approved catalog look:
- Clean white ceramic bowl/plate (NO patterns, NO colored rims)
- Pure white seamless background (RGB 250+)
- 45-degree angle (front rim visible, back higher)
- Centered, food filling 65-70% of frame
- Bright soft lighting from upper-left
- Soft drop shadow under bowl only
- Steam rising from hot dishes
- All sauce/broth GLOSSY and GLISTENING
- No text, no watermarks, no labels

### 8. Production workflow
```
1. Audit raw photos → identify best per item
2. Classify each: food / drink / rice-set / overhead / black-bg
3. For clean originals: use reference image + foodporn prompt
4. For problematic originals: use TEXT-ONLY generation
5. Run quality gate on each output
6. Auto-retry failures (max 2x)
7. PIL brightness boost for borderline passes
8. PIL bg whitening for grey patches
9. Manual visual review of ALL outputs
10. Re-gen individual items that fail visual review
```

## Prompt Library

### Approved Foodporn Prompt (for food with reference image)
See `approved-prompt.md`

### Text-Only Food Prompt Template
```
Generate a professional food delivery catalog photo:

[DISH NAME] — a large white ceramic bowl filled with:
- [ingredient 1 with color and texture description]
- [ingredient 2]
- [ingredient 3]
...

PHOTOGRAPHY: 45-degree angle. Large white ceramic bowl (NO pattern),
filling 65% of frame, centered. PURE WHITE background RGB(255,255,255).
Bright luminous lighting. Soft shadow under bowl. Sharp focus.
Do NOT add text.
```

### Text-Only Drink Prompt Template
```
Generate a professional food delivery catalog photo:

[DRINK NAME] — LARGE [glass type] filled with:
- [liquid description with color]
- [ice/garnish]
- [straw type]

The glass must be LARGE, filling 60-70% of frame height, centered.
PURE WHITE background. Bright luminous lighting. 45-degree angle.
Liquid colors VIVID. Condensation visible if cold. Sharp focus.
Do NOT add text.
```

### Text-Only Rice Set Prompt Template
```
Generate a professional food delivery catalog photo:

[SET NAME] — ALL on one LARGE white round plate:
- [rice type with color]
- [main dish with sauce description]
- [sides]
- Halved egg with golden yolk

45-degree angle. PURE WHITE background. Large plate filling 65%.
Centered. Bright lighting. Vivid colors. Do NOT add text.
```
