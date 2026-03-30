---
name: DotDot Calibration v1-v5 Learnings
description: ALL YES/NO from DotDot calibration rounds v1-v5. Art style, skin tone, packaging, brief fidelity, size, logo, confetti. Apply to ALL DotDot production.
type: feedback
---

## DOTDOT CALIBRATION — COMPOUND LEARNINGS (29 March 2026)

### Rounds Summary
- v1: First attempt — wrong API param (image_url vs image_urls), generic refs
- v2: Art style locked (flat editorial), but confetti overload, double logo, size distortion
- v3: Fixed confetti + size param, but crop-fit cut off content on 5/6 templates
- v4: Pad-fit fixed content loss, but T3 leaked "80px" margin text
- v5: Full batch (9 posts). 8/9 pass. Art style consistent. Brief examples adapted.

### ✅ YES — What Works

1. **Flat editorial illustration style** (strokeless, soft gradient, gestural figures) = correct for DotDot
2. **DD-T6-v2 typography** = the bar. Massive bold TC headline filling 20-30% of frame height
3. **Pad-fit resize** (scale to fit, pad with detected bg) = no content loss
4. **Smart logo composite** (PIL only, white pill backing on busy bg) = clean, consistent
5. **Brief example adaptation** = use their existing posts as Image 1, apply our art style
6. **NANO at ~4:5 aspect** (832x1040 or 928x1152) = closest to native portrait output
7. **Post-processing chain**: grade(0.96/1.04) → texture(1.8) → logo → grain(2.5) → sharpen = clean health brand feel
8. **Safety prompt "do NOT render logo"** = prevents double logo (v2 had NANO + PIL logos)
9. **Margin safe zone instruction** = mostly prevents edge cropping (v4 improvement)
10. **Category-specific prompts** map to brief pillars: Education 40%, Exercise 40%, Brand 20%

### ❌ NO — What Fails

1. ❌ **crop-fit resize** = cuts content. NEVER use. Always pad-fit.
2. ❌ **Confetti/sparkles/doodles in prompt** = clutters the design. Client wants CLEAN editorial.
3. ❌ **"80px" / "20px" in prompt text** = NANO renders pixel values as visible text. Use relative terms ("generous margin") not pixel values.
4. ❌ **image_url (singular)** = wrong API param. NANO needs `image_urls` (array).
5. ❌ **image_size not respected** = NANO outputs at its own aspect ratio regardless. Must handle in post-processing.
6. ❌ **Dark skin tones for HK market** = Target audience is Hong Kong Chinese elderly. Figures should have East Asian skin tones (light/medium warm), not dark/African skin tones. This is audience representation, not preference.
7. ❌ **AI-generated product packaging** = Must composite REAL product photos from `03_assets/product-photos/`. Never AI-render the sachet/box.
8. ❌ **Paraphrasing brief example content** = When recreating their existing posts, copy the EXACT text 1:1. Don't rewrite.
9. ❌ **Saving raw + final files** = Only save finals. Raw files clutter exports.
10. ❌ **Anatomy illustrations going semi-realistic** = Should stay flat editorial even for anatomy (N1 was inconsistent with rest of batch).

### 🔧 PRODUCTION RULES — DotDot (Enforced)

| Rule | Detail |
|------|--------|
| **Art style** | Modern flat editorial illustration. Strokeless, soft gradient, gestural. No confetti. |
| **Typography** | DD-T6-v2 bar: massive bold TC headline, 20-30% frame height. 48pt+ equivalent. |
| **Skin tones** | East Asian, light-medium warm. HK Chinese elderly audience. |
| **Size** | Native 4:5 generation → pad-fit to 1080x1350 (IG) or 1080x1440 (XHS). NEVER crop. |
| **Logo** | PIL composite only. White pill backing if bg variance >30. Max 80px height. Top-right, 35px margin. |
| **Product photos** | REAL PNG composite from `03_assets/product-photos/`. NEVER AI-generated packaging. |
| **Brief fidelity** | When adapting brief examples, copy text 1:1. Don't paraphrase. |
| **Pillar mapping** | Every post must map to: Education (40%) OR Exercise/Tips (40%) OR Brand/Trust (20%). |
| **Post-process** | grade → texture → logo → grain → sharpen. Immutable order. |
| **Audit** | 6-layer visual audit on EVERY output before showing. Content crop = auto-fail. |

### 📋 STILL NEEDED

- [ ] DotDot mascot integration (kawaii character from IG highlights — need assets)
- [ ] Real product packaging template posts (refs from Pinterest board)
- [ ] East Asian skin tone figures in all illustrations
- [ ] 1:1 text copy on brief example adaptations
- [ ] Video pipeline (3D Pixar mascot — separate from static)

**How to apply:** Read this before ANY DotDot production batch. Every rule is non-negotiable.
