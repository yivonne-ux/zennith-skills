---
name: DotDot Size Bars + Missing Logo — Root Causes and Fixes
description: CRITICAL AUDIT. Left/right bars caused by NANO narrow output + pad-fit. Missing logo caused by fallback not executing. P3 product sizing wrong. Add ALL to audit master.
type: feedback
---

## SIZE BARS — ROOT CAUSE

NANO outputs at ~848x1264 (ratio 0.671) when mascot Image 1 is portrait.
Target is 1080x1350 (ratio 0.800 = 4:5). Pad-fit adds ~116px side bars.

### Why NANO outputs too narrow:
- Image 1 (editorial mascot) is 896x1184 (ratio 0.757)
- NANO tends to match Image 1's aspect ratio regardless of image_size param
- 0.757 ≠ 0.800 → pad-fit kicks in → visible bars

### Fixes (try in order):
1. **Resize Image 1 to exact 4:5** before uploading — force the reference to be the target ratio
2. **Use image_size closer to Image 1's natural ratio** — then scale-up instead of pad
3. **Use a v6 approved post (already 1080x1350) as Image 1** + describe mascot in prompt
4. **Accept narrow output and SCALE-UP** (slight stretch) instead of pad — for <5% difference, stretch is invisible

### The correct approach:
```python
# Before uploading Image 1, resize to exact 4:5
img1 = Image.open(ref_path)
img1_45 = img1.resize((img1.height * 4 // 5, img1.height), Image.LANCZOS)  # or crop
# This forces NANO to output at ~4:5
```

## MISSING LOGO — ROOT CAUSE

Smart logo v2 checks 3 positions. If ALL have high variance + high edge score, the fallback
should force placement anyway with strong pill backing. But the code loop broke before reaching
fallback when the first position matched the variance<45 but edge>25 condition.

### Fix:
```python
# After trying all positions, ALWAYS place logo — never return without logo
# Fallback: top-right with EXTRA STRONG pill backing (opacity 240)
```

### NEW AUDIT CHECK:
```
□ Logo is VISIBLE in the final output (never missing)
□ If no clean zone exists, logo has white pill backing at 240 opacity
□ Check EVERY post for logo presence before showing — auto-FAIL if missing
```

## P3 PRODUCT SIZING — ROOT CAUSE

Grid calculation used:
- grid_bottom = 0.78 → too high, bottom row products sit too high
- product_scale = 0.75 → too small relative to card size

### Fix:
- grid_bottom = 0.82 (lower, gives more room)
- grid_top = 0.30 (adjusted)
- product_scale = 0.85 (larger, fills card better)
- Actually DETECT card positions from NANO output using color matching instead of guessing

## UPDATED AUDIT MASTER CHECKLIST:
```
SPATIAL AUDIT (every post):
□ No left/right space bars (content fills full 1080 width)
□ No top/bottom space bars (content fills full 1350/1440 height)
□ Logo PRESENT (never missing — auto-FAIL)
□ Logo NOT overlapping text/content
□ Product CENTERED within its zone (not floating)
□ Product SIZE proportional (fills 80-85% of its zone)
□ Grid elements ALIGNED (tops/bottoms/sides line up)
□ Mascot SIZE consistent (25-35% of frame height in posts)
□ Background fills entire canvas — no visible padding strips
```

**The pattern I keep missing:** I check CONTENT quality but not SPATIAL quality. I need to check
positioning, sizing, alignment, coverage — not just "is the element there?"

**How to apply:** After every generation, before showing user:
1. Check dimensions (must be EXACT 1080x1350 or 1080x1440)
2. Check for bars (sample left/right/top/bottom 20px strips — if uniform color = BAR = FAIL)
3. Check logo presence (scan for dotdot logo mark in all corners)
4. Check element positions (products in cards, mascot sized right)
