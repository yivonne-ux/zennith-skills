---
name: GrabFood pipeline learnings V1-V9 — every yes and no
description: Complete record of what worked and what failed across 9 iterations of the GrabFood photo enhancement pipeline. Read before any food photo work.
type: feedback
---

## GrabFood Enhancement Pipeline — All Learnings (2026-03-23)

### WHAT WORKS (YES)
1. ✅ V5 scene reconstruction approach — NANO rebuilds entire scene, keeps food sacred
2. ✅ V5 shadow quality — natural, soft, gradual fade (before PIL ruined it)
3. ✅ V9 square-in-square-out — generate as 1:1 from start, no aspect ratio conversion
4. ✅ Premium ceramic bowls — grey speckled stoneware looks professional
5. ✅ No props — food and bowls ONLY, no chopsticks/glasses/boards
6. ✅ NANO handles white bg + shadow + warm colors in one/two passes
7. ✅ Reference-driven enhancement — Pinterest/pro reference as Image 1
8. ✅ FoodShot approach: food is mask, everything else is regenerated
9. ✅ Food must fill 75-85% of frame
10. ✅ All items razor sharp — no depth of field blur for product photos
11. ✅ Diagonal composition — main dish lower-left, side dish upper-right

### WHAT FAILS (NO)
1. ❌ PIL color grading — forced, over-contrasted, amateur, ruins the photo
2. ❌ PIL white clipping (pixels >240 → 255) — destroys shadow gradient, creates hard lines
3. ❌ PIL film grain via numpy — looks like digital noise, not organic film
4. ❌ PIL ImageEnhance for vibrance/contrast/sharpness — blanket % changes look artificial
5. ❌ Generating landscape then squeezing to square — crops shadow
6. ❌ NANO "make background white" without proper prompting — produces grey
7. ❌ rembg cutting white plates — can't distinguish white plate from white bg
8. ❌ Generic Pexels references — produce template output, not world-class
9. ❌ Multiple PIL post-processing passes — each one degrades quality
10. ❌ Adding props then removing them — creates artifacts
11. ❌ V1 basic pipeline — just color boost, no scene reconstruction
12. ❌ V3 rembg + PIL composite — cuts plate edges, fake shadow
13. ❌ V6 single pass with PIL clip — smudge artifacts from clipping

### CORRECT PIPELINE (proven V9)
```
1. Pad original photo to 1:1 square (white padding)
2. NANO Pass 1: Scene reconstruction (reference + food → premium bowls, warm light, sharp, NO props)
3. NANO Pass 2: White background + warm colors + shadow (if not done in Pass 1)
4. PIL: Resize to 800x800. NOTHING ELSE.
```

### BATCH CONSISTENCY RULES
- All photos in one store: same angle, same bowl position, same lighting direction
- Same bowl style across entire menu
- Same NANO prompt template — only dish description changes
- Same warm color level

### STILL NEEDS WORK
- Art-directed references (not Pexels stock)
- Film grain/texture needs AI pass not PIL
- The FoodShot-level technical pipeline (RMBG-2.0, IC-Light relighting, DetailTransfer)
- Badge system for Best Seller / Chef's Pick
- Batch processing script with store consistency
