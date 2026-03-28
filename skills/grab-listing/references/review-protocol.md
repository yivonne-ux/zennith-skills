# Review Protocol — Mandatory Before Delivery

> "Generate is 30% of the work. Review is 70%."
> — Learned from Uncle Chua + Choon production run (50 photos, 4 review passes)

## Why Review Matters

First-pass generation gets ~40% right. Without review:
- Wrong angles slip through (overhead instead of 45°)
- Grey/purple backgrounds pass automated checks but look bad
- Wrong dishes get generated (Gemini hallucinated crackers for beancurd chips)
- Patterned bowls from reference images carry over
- Food looks dull/flat despite passing brightness threshold
- Text labels get baked into the image

**The automated quality gate catches technical failures. Only HUMAN EYES catch "doesn't look delicious" and "wrong dish."**

## The Review Loop

```
GENERATE → AUTO QA GATE → HUMAN VISUAL REVIEW → FIX → RE-REVIEW → SHIP
              ↓                    ↓
         (brightness,         (angle, dish accuracy,
          sharpness,           color vibrancy, bowl type,
          bg whiteness)        food appeal, consistency)
```

## Human Review Checklist (per photo)

### 1. ANGLE
- [ ] Is it 45 degrees? (front rim visible, back higher)
- [ ] NOT overhead / flat-lay / top-down?
- [ ] Consistent with other photos in the catalog?

### 2. BACKGROUND
- [ ] Pure white? No grey patches, no pink/purple tint, no gradient?
- [ ] No shadow ON the background (only under the plate)?
- [ ] Clean edges — no artifacts near food/bowl boundary?

### 3. BOWL / PLATE
- [ ] Clean white ceramic — no patterns, no colored rims?
- [ ] Consistent bowl style across the catalog?
- [ ] Appropriate size (bowl for soup, plate for sides)?

### 4. FOOD ACCURACY
- [ ] Is this the CORRECT dish? (Gemini hallucinates if description is vague)
- [ ] Are ALL the right ingredients present?
- [ ] No WRONG ingredients added?
- [ ] Does it match what the merchant actually serves?

### 5. FOOD APPEAL
- [ ] Does the food look DELICIOUS? Would you order it?
- [ ] Sauce/broth glossy and glistening?
- [ ] Colors vivid — not dull or washed out?
- [ ] Steam visible on hot dishes?
- [ ] Textures clear — crispy looks crispy, juicy looks juicy?

### 6. COMPOSITION
- [ ] Centered in frame?
- [ ] Filling 60-70% of the image (not tiny floating in white)?
- [ ] No text / watermarks / labels added by Gemini?

### 7. CONSISTENCY
- [ ] Same lighting direction as all other photos?
- [ ] Same shadow style?
- [ ] Same overall brightness level?
- [ ] Would look cohesive as a menu catalog?

## Fix Strategy by Issue Type

| Issue | Fix Method |
|-------|-----------|
| Wrong angle (overhead) | Re-gen TEXT-ONLY (reference pulls back to original angle) |
| Grey/purple background | Re-gen TEXT-ONLY, or PIL pixel whitening |
| Wrong dish | Re-gen TEXT-ONLY with VERY SPECIFIC ingredient list |
| Patterned bowl | Re-gen TEXT-ONLY (reference carries bowl pattern) |
| Food looks dull | Re-gen with stronger "GLOSSY, GLISTENING, VIVID" emphasis |
| Too small in frame | Re-gen with "LARGE, filling 65% of frame" + auto-zoom crop |
| Gemini added text | Crop bottom 15% + re-square to 800x800 |
| Black background | Re-gen TEXT-ONLY (dark reference pulls dark output) |

## Production Stats (from this session)

| Metric | Value |
|--------|-------|
| Total photos | 50 |
| Pass on first gen | ~40% (20/50) |
| Pass after auto QA retry | ~65% (33/50) |
| Pass after review + fix | ~90% (45/50) |
| Pass after 2nd review + fix | 100% (50/50) |
| Review passes needed | 4 |
| Re-gens per photo (avg) | 1.8 |

**Key insight: Budget for 2x generations per photo. First gen is rarely final.**
