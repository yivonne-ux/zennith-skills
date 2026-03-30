---
name: Pinxin Illustration Style DNA v5 — Final from 5-round calibration
description: CRITICAL. Complete illustration style spec for PX social posts. 5 rounds of yes/no. Character refs, pipeline, what works, what fails. Apply to ALL future PX illustration posts.
type: feedback
---

## PX ILLUSTRATION STYLE — v5 DNA (March 27 2026, 5 rounds calibration)

### The 6 Qualities (ALL must be present)

1. **THIN LINEWORK + FINE DETAIL** (from coat+daisies ref 641763015, sunflower ref 18014467)
   - Thin, confident, VISIBLE outlines — every detail drawn
   - Individual hair strands, fabric weave, food texture, wood grain
   - NOT soft/blurry painterly. NOT thick cartoon outlines. CRISP thin lines with warmth.

2. **RICH MICRO-DETAILING** (from vinyl journal ref 914862, sunflower ref 18014467)
   - Every corner rewards a second look
   - Kitchen: labeled jars (花椒, 八角), herbs in pots, cutting boards, scattered chillies, recipe notebooks, steam wisps
   - Dining: chopstick rests, tea stains, napkin folds, sauce drops, rice grains on table
   - Texture on EVERYTHING: wood grain, ceramic glaze, fabric weave

3. **WARM EXPRESSIVE CHARACTERS** (from sweater girl ref 17732992, glasses girl ref 189503096)
   - Slightly larger eyes (1.3x realistic), round, with catchlight/sparkle
   - Rosy blush on cheeks AND nose tip
   - Asian features, dark brown/black hair with individual strands
   - Characters EMOTE — they think, feel, react. Not stiff.
   - Cozy clothing: knit sweaters, aprons, linen

4. **CREATIVE WHIMSICAL FOOD** (from 立冬 ref 426012446010144620, 腊八 ref 426012446010144618)
   - Imaginative compositions: tiny people + giant food, scale play
   - Food richly detailed — individual beans, chilli flakes, steam wisps
   - NOT just "food on plate" — creative treatment

5. **DREAMY CHINESE SEASONAL ATMOSPHERE** (from 小满 ref 426012446010145241)
   - Ethereal, soft, like a cherished memory
   - Chinese cultural feel — seasonal, familial, traditional
   - Paper grain texture subtle throughout

6. **FULL 7-COLOR PX PALETTE** (not just green + gold!)
   - PX Green #1C372A — backgrounds, depth
   - PX Gold #D0AA7F — lamp light, warm highlights
   - Cream #F2EEE7 — light surfaces, skin highlights
   - Dark Brown #917D6E — wood, hair shadows
   - Darker Brown #42210B — deep accents, soy sauce tones
   - Burgundy #470E23 — clothing accents, cultural warmth
   - Deep Red #6C0E0E — chilli, spice details
   - Use ALL 7. Rich, warm, cultural. Not limited to 2 colors.

### Key Reference Images (for Image 1 + Image 2 in NANO)

| Ref | Pinterest ID | What it provides |
|-----|-------------|-----------------|
| **Character face** | pinterest_17732992278680698 (sweater girl) | Face proportions, rosy cheeks, expression quality |
| **Character personality** | pinterest_189503096827267350 (glasses girl) | Personality, clean lines, expressiveness |
| **Object detailing** | pinterest_914862421943770 (vinyl journal) | Micro-detail, still-life warmth, textures |
| **Botanical detail** | pinterest_18014467258685066 (sunflowers) | Fine linework on nature, gold+green |
| **Linework quality** | pinterest_641763015692323361 (coat+daisies) | Thin strokes, detailed rendering |
| **Creative food** | pinterest_426012446010144620 (立冬) | Whimsical scale, tiny people + giant food |
| **Creative food** | pinterest_426012446010144618 (腊八) | Same — food illustration with character |
| **Atmosphere** | pinterest_426012446010145241 (小满) | Dreamy, ethereal, Chinese seasonal |

All refs in: `04_references/social-media-refs/comics-illustration/_LOCKED/`
Board refs in: `_LOCKED/from-board/pinterest/jennloh85/Pinxin illustration/`

### Production Pipeline (v5 — proven)

```
Image 1: Sweater girl ref (character face anchor)
Image 2: Glasses girl ref (character personality anchor)
→ NANO Banana Pro Edit at 4:5 (1080×1350)
→ PIL resize → logo (gold, top-right, y=30) → grain (0.028)
```

- **MAX 2 reference images** — more dilutes character style
- **Food cutouts = ZERO images** for illustration posts. Describe food in TEXT only.
- **Vegan gate at END of prompt** (last block = strongest signal for NANO)
- **Never use the word "fish"** in any prompt — triggers NANO to draw actual fish

### NANO Character Ceiling (honest assessment)

After 5 rounds, NANO's character rendering is "acceptable" but not matching the refs exactly. NANO fights back toward its default "warm cartoon" style. The v5 pipeline gets closest by:
- Using only 2 character refs (no dilution)
- Extremely specific face proportion instructions (1.3x eyes, rosy cheeks, catchlight)
- Prioritizing character instruction as "#1 most important"

**This is the ceiling for NANO edit mode.** To go further, would need FLUX Kontext (style transfer) — user declined for now, prefers NANO single-pass.
