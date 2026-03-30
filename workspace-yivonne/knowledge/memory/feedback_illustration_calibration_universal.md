---
name: Illustration Style Calibration — Universal Process (brand-agnostic)
description: CRITICAL. How to calibrate illustration style for ANY brand in minimum rounds. Extracted from PX 5-round calibration. Apply to ALL brands needing illustration content.
type: feedback
---

## ILLUSTRATION STYLE CALIBRATION — UNIVERSAL PROCESS

### Why this exists
PX illustration calibration took 5 rounds. This should take 2 max. These rules prevent the same mistakes.

### Step 1: COLLECT REFS (before any generation)
Ask the user to provide ALL illustration refs they like. Then classify each ref by what it contributes:

| Dimension | Question to answer | Example |
|-----------|-------------------|---------|
| **Character face** | What face proportions/style? (stylized, realistic, anime?) | Rosy cheeks, eye size, expression quality |
| **Linework** | Thick/thin? Visible/blended? Confident/sketchy? | Thin confident strokes vs soft painterly |
| **Detailing level** | Minimal/medium/rich micro-detail? | Every corner rewards a second look? |
| **Food rendering** | Photo-realistic or illustrated in same style? | Food MUST match scene style |
| **Color palette** | What's the FULL palette? (never reduce to 2 colors) | Map ALL brand colors to illustration use |
| **Atmosphere** | Dreamy? Clean? Bold? Cultural? | Overall mood/feel |
| **Composition** | Straightforward or creative/whimsical? | Tiny people + giant food = creative |

**RULE: Ask "which of these do you like and WHY" before generating.** The "why" tells you which DIMENSION each ref contributes. A user may like one ref for its linework but hate its color.

### Step 2: PIPELINE RULES (proven across brands)

1. **MAX 2 reference images per NANO call.** More images = attention dilution = generic output. The model can't lock onto 5 styles simultaneously.

2. **Food in illustration posts = TEXT DESCRIPTION ONLY.** Do NOT pass food photo cutouts as reference images for illustration posts. This creates style mismatch (realistic food in illustrated scene). Describe food in text with signature markers instead.

3. **For food hero posts** (photography style): mood ref as Image 1 + food cutout as Image 2. This is a DIFFERENT pipeline from illustration.

4. **Vegan/dietary restriction gate at END of prompt.** NANO reads the end more strongly. Placing it first = buried by subsequent instructions.

5. **Never use trigger words that cause unwanted generation.** E.g., product name "Spicy Asam Fish" → NANO draws actual fish. Use "Spicy Asam" only. Audit all product names for problematic words.

6. **Brand palette = FULL range, never reduced.** If a brand has 7 colors, use ALL 7 in prompts. Reducing to 2 (e.g., "green and gold") creates flat, unbranded output.

### Step 3: CHARACTER STYLE (the hardest to control)

NANO edit mode has a CHARACTER CEILING — it treats refs as loose mood guidance, not strict style transfer. After testing:

- **What helps**: 2 character refs with same style, extremely specific face proportion instructions ("1.3x larger eyes, rosy cheeks + nose tip, catchlight in eyes, individual hair strands"), priority instruction ("character style is the #1 most important instruction")
- **What doesn't help**: More refs (dilutes), vague style words ("warm", "cute"), different style refs (NANO averages them into generic)
- **The ceiling**: NANO will get ~70% of the way to the ref. Acceptable but not pixel-matching.
- **To go further**: Need style-transfer models (FLUX Kontext/Redux). But trade-off = less composition control, worse text rendering.

### Step 4: BRAND HOLDING (what makes it look "branded" vs "generic AI")

**Wrong approach**: Force brand elements (logo frame, mascot border, brand pattern overlay). User will reject as "too overwhelming."

**Right approach**: Brand palette + mood = brand identity. The illustration should FEEL like the brand without explicit brand elements.

Specifically:
- Full color palette used throughout (clothing, environment, food, light)
- Consistent character style across all posts
- Consistent detailing level and linework quality
- Consistent atmosphere/mood
- Logo added in post-production (PIL), not in the illustration itself

### Step 5: CALIBRATION CHECKLIST (run after each round)

After generating, audit against these:
- [ ] Character face matches ref? (eyes, cheeks, expression)
- [ ] Food is illustrated in SAME style as scene? (not realistic cutout)
- [ ] Full brand palette visible? (not just 2 colors)
- [ ] No dietary violations? (vegan: no eggs/meat/dairy/fish)
- [ ] Micro-detailing present? (textures, small objects, environmental storytelling)
- [ ] Linework matches ref quality? (thin/thick, visible/blended)
- [ ] Forced brand elements absent? (no overwhelming frames/borders)
- [ ] Overall: does it feel like THIS brand, not generic AI?

### Anti-patterns (NEVER repeat)

1. ❌ 5 reference images → generic average of all styles
2. ❌ Realistic food cutouts in illustrated scenes → style mismatch
3. ❌ Forced botanical/brand frames → "too overwhelming"
4. ❌ Reducing brand palette to 2 colors → flat, unbranded
5. ❌ Anime/manga ref for Chinese food brand → cultural mismatch
6. ❌ Vegan gate at start of prompt → buried, ignored
7. ❌ Product names with trigger words ("fish", "chicken") → NANO draws them literally
8. ❌ Generating without understanding WHY user likes each ref → wasted rounds
