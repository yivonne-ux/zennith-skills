---
name: DotDot v10 Audit Gaps — What my eyes missed. Mascot art style adaptation rules.
description: CRITICAL. v4-happy wrong eyes/mouth, v4-teaching missing mouth, v4-thumbsup mouth position wrong, P3 missing real products. Add to audit checklist. Mascot art style adaptation = change style only, keep ALL features pixel-identical.
type: feedback
---

## v10 AUDIT GAPS (30 March 2026)

### What I Missed (add to audit checklist):

**1. v4-happy: wrong eyes and mouth**
- Eyes should match reference exercise pose (two dots) even in happy expression
- Mouth wrong shape/position
- MY AUDIT SAID PASS — it should have FAILED
- **Rule: compare EVERY pose against the canonical reference (v3-exercise) feature-by-feature. Happy expression changes eye SHAPE (curved) but not eye SIZE or POSITION.**

**2. v4-teaching: missing mouth**
- No visible mouth at all
- MY AUDIT SAID PASS — it should have FAILED
- **Rule: mouth MUST be present in every pose. "Neutral" doesn't mean "no mouth."**

**3. v4-thumbsup: mouth at wrong position**
- Mouth should be at BOTTOM of face zone (below nose dots)
- MY AUDIT didn't catch the position error
- **Rule: mouth is ALWAYS at bottom center of peach face zone. Never middle, never side.**

**4. P3-lineup-fixed: only has illustrated icons, not REAL 6 product photos**
- The brief shows a 6-product lineup. I showed icons in colored cards but no actual product photos.
- MY AUDIT SAID "product names all correct" — but the PRODUCTS themselves aren't shown
- **Rule: "product lineup" means ALL 6 REAL product PNGs visible. Not icons representing them.**

### NEW AUDIT CHECKS (add to master checklist):

```
MASCOT AUDIT (run on EVERY mascot output):
□ Face skin tone matches canonical ref (light peach, NOT dark, NOT white)
□ Eye SIZE matches ref (small dots, not large)
□ Eye POSITION matches ref (upper face, moderate spacing)
□ Nose dots PRESENT (two tiny dots, center, below eyes)
□ Mouth PRESENT (never missing)
□ Mouth POSITION at bottom of face zone (below nose, never middle/side)
□ No eyebrows
□ All 4 limbs visible
□ White hood wrapping peach face
□ Compare side-by-side with canonical ref image before marking PASS

PRODUCT LINEUP AUDIT:
□ ALL products from brief are represented (count: should be 6 for DotDot)
□ Each product uses REAL product PNG (not icon/illustration substitute)
□ Product names match exactly (德國膠原/德國膠原EX/補矽/德國蘋果/德國蜜莎/冰川牛奶)
□ No made-up product names (v9 had "德國美物" and "德國豪質" = wrong)
```

---

## MASCOT ART STYLE ADAPTATION — THE RULE

User's intent: "maintain ALL core elements pixel to pixel — only change art style"

This means:
- ✅ CHANGE: no black outline → strokeless flat editorial style
- ✅ CHANGE: add soft gradient fills (flat editorial DNA)
- ✅ CHANGE: add subtle grain texture
- ✅ CHANGE: color palette to DotDot teal/orange accents
- ❌ KEEP IDENTICAL: face SHAPE (round peach zone in white hood)
- ❌ KEEP IDENTICAL: eye SIZE, POSITION, SPACING (two small dots, upper face)
- ❌ KEEP IDENTICAL: nose DOTS (two tiny, center)
- ❌ KEEP IDENTICAL: mouth POSITION (bottom of face)
- ❌ KEEP IDENTICAL: body PROPORTIONS (wider than tall blob)
- ❌ KEEP IDENTICAL: limb STYLE (tiny nubs)
- ❌ KEEP IDENTICAL: hood EFFECT (white wrapping peach face)

**The mascot in flat editorial style should be the SAME CHARACTER drawn in a different rendering technique — NOT a new character that vaguely resembles the original.**

Think of it like: same person, different camera filter. Not same filter, different person.

### How to prompt:
```
"Take this exact character and render it in flat editorial illustration style:
- Remove black outlines → define shapes with color fill boundaries only
- Add soft gradient within the body (subtle light-to-shadow)
- Add subtle grain/paper texture
- Keep EVERY facial feature in EXACTLY the same position, size, and spacing
- Keep body proportions IDENTICAL
- The character must be recognizable as the SAME character, just in a different art style"
```

**How to apply:** Before marking any mascot PASS, open the canonical reference side-by-side and check EVERY feature position. If ANY feature has moved, changed size, or disappeared → FAIL.
