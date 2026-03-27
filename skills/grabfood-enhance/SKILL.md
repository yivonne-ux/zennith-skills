---
name: grabfood-enhance
agents:
  - taoz
  - scout
---

# GrabFood Photo Enhancement Pipeline
> Replaces: FoodShot AI ($9-99/mo) + ChatGPT + manual phone editing
> Built on: NANO Banana Pro (fal.ai) + rembg + PIL
> Cost: $0 (using existing fal.ai API key)

---

## RESEARCH SUMMARY

### Why This Matters
- Menu photos increase sales by **65%** (Grubhub data)
- High-quality photos increase orders by **35%** (Snappr data)
- Viewing pictures is **1.44x more important** than reading descriptions
- High-contrast thumbnails improve CTR by **20-40%**

### GrabFood Image Requirements
- Size: **800x800px** (1:1) + **1350x750px** (9:5 banner)
- Format: JPEG or PNG, max 6MB
- Angle: 45° for most dishes, top-down for soups/curries, front for burgers
- NO text, watermarks, or borders

### Color Science — What Makes Food Sell
- **Red**: Most appetite-stimulating color (increases heart rate)
- **Yellow/Orange**: Warmth, comfort, happiness
- **Blue**: Appetite SUPPRESSANT — avoid
- **Warm white background** (RGB 248,246,240): Clean but not clinical
- **Color temperature**: 5500-6000K (slightly warm)
- **Saturation**: Boost vibrance (not saturation) — natural, not neon
- **Contrast ratio**: 4.5:1 minimum between food and background (thumbnail readability)

### What Makes GrabFood Thumbnails Click (80px display)
1. **Clean separation** — food clearly distinct from background
2. **High contrast** — bright food on clean background pops at any size
3. **Saturated warm tones** — reds, oranges, yellows amplified
4. **Single focal point** — one dish, centered, no clutter
5. **Visible texture** — steam, sauce sheen, crispy edges visible even small
6. **No shadows on background** — clean drop shadow only under dish

---

## PIPELINE ARCHITECTURE

```
INPUT: Raw food photo (any quality, any background)
  ↓
STEP 1: BACKGROUND REMOVAL (rembg)
  - Remove existing background
  - Alpha matting for smooth edges
  - Output: transparent PNG cutout
  ↓
STEP 2: PLATE/BOWL STANDARDIZATION (optional)
  - If plate is ugly/mismatched → NANO swaps to clean bowl/plate
  - If plate is fine → skip
  ↓
STEP 3: ENHANCEMENT (NANO Banana Pro Edit)
  - Place food on warm white background
  - Warm color grading (5500-6000K feel)
  - Enhance food saturation (reds, oranges, yellows)
  - Add subtle steam/freshness cues
  - Micro-contrast for texture pop
  - Natural side lighting simulation
  ↓
STEP 4: POST-PROCESSING (PIL)
  - Force to exact 800x800 (1:1 for menu)
  - Also export 1350x750 (9:5 for banner)
  - Increase exposure slightly (+10-15%)
  - Boost vibrance (not saturation)
  - Sharpen for thumbnail clarity
  - Add subtle warm vignette
  ↓
STEP 5: THUMBNAIL TEST (PIL)
  - Generate 80px preview (actual GrabFood display size)
  - Check: is food identifiable at 80px?
  - Check: contrast ratio > 4.5:1?
  ↓
OUTPUT: Menu-ready images (800x800 + 1350x750)
```

---

## ENHANCEMENT RULES (Pixel-Level)

### Color Adjustments
```
White Balance:    Shift warm (+5-10 on temp slider)
Vibrance:         +15 to +25 (boosts muted colors naturally)
Saturation:       +5 to +10 ONLY (subtle, not neon)
Exposure:         +0.1 to +0.3 EV (brighter = more appetizing)
Contrast:         +10 to +15 (food texture pop)
Highlights:       -5 (recover blown whites)
Shadows:          +10 (lift dark areas to show detail)
```

### HSL Adjustments (per-color targeting)
```
Red Hue:          0 (keep natural)
Red Saturation:   +15 (make meats/sauces richer)
Red Luminance:    +5 (slightly brighter reds)

Orange Hue:       0
Orange Saturation: +20 (warm skin of fried foods, curry)
Orange Luminance:  +5

Yellow Hue:       -5 (shift slightly toward orange/warm)
Yellow Saturation: +10 (rice, noodles, golden crusts)
Yellow Luminance:  +5

Green Hue:        +5 (shift toward teal, more appetizing)
Green Saturation:  +10 (vegetables, herbs look fresher)
Green Luminance:   +5

Blue Saturation:   -20 (SUPPRESS blue — appetite killer)
```

### Background
```
Type:             Warm white (RGB 248, 246, 240) — NOT pure 255,255,255
Gradient:         Subtle radial, center lighter, edges slightly darker
Shadow:           Soft drop shadow under dish (not hard edge)
Reflection:       Optional subtle surface reflection (premium feel)
```

### Sharpening (for thumbnail readability)
```
Amount:           30-50
Radius:           1.0-1.5
Threshold:        2 (protect smooth areas from noise)
Focus:            Apply selectively to food edges, not background
```

---

## NANO PROMPT TEMPLATE

```
Image 1 = food cutout on transparent/white background.

TASK: Create a professional food delivery app menu photo.

BACKGROUND: Clean warm white background (slightly off-white, not clinical).
Subtle radial gradient — center brighter, edges slightly darker.
Soft drop shadow under the dish.

FOOD: Preserve the food EXACTLY as provided in Image 1.
Enhance colors slightly — warm, appetizing, inviting.
Make reds and oranges richer. Make greens fresher.
Add subtle steam rising if this is a hot dish.
Enhance sauce sheen and food texture visibility.

LIGHTING: Soft natural side light from upper-left.
Warm color temperature (golden hour feel).
Gentle highlight on food surface.

COMPOSITION: Food centered, filling 60-70% of frame.
Shot from 45-degree angle (or top-down if specified).
Clean, minimal — no props, no text, no garnish unless on original.

OUTPUT: Professional menu photo. Must be identifiable and appetizing
even when viewed at 80px thumbnail size.
```

---

## QUALITY CHECKLIST (per photo)

Before exporting, verify:
- [ ] Food is clearly identifiable at 80px
- [ ] Background is clean warm white (no artifacts)
- [ ] Colors are warm and appetizing (no blue cast)
- [ ] Edges between food and background are clean (no halo)
- [ ] Sauce/liquid textures are visible and glossy
- [ ] Steam visible (for hot dishes)
- [ ] No unnatural color banding or AI artifacts
- [ ] Contrast ratio > 4.5:1 (food vs background)
- [ ] File is 800x800 JPEG < 2MB

---

## COMPARISON: Our Pipeline vs FoodShot AI

| Feature | FoodShot AI | Our Pipeline |
|---|---|---|
| Cost | $9-99/month | $0 (existing fal.ai key) |
| Background removal | ✅ | ✅ (rembg) |
| White background | ✅ | ✅ (NANO + PIL) |
| Warm color grading | ✅ | ✅ (PIL HSL + NANO prompt) |
| Plate swap | ✅ | ✅ (NANO edit) |
| Steam/freshness | ✅ | ✅ (NANO prompt) |
| Batch processing | ✅ | ✅ (Python script) |
| 4K output | ✅ | ✅ (NANO 2K + upscale) |
| Thumbnail preview | ❌ | ✅ (80px test built in) |
| Custom pipeline | ❌ | ✅ (fully controllable) |
| Multi-brand | ❌ | ✅ (works for all brands) |
| Speed | ~10s/photo | ~15s/photo |

---

## SOURCES

> See `references/sources.md` for all 12 research sources (Snappr, FoodShot AI, Gastrostoria, GrabFood specs, rembg, NANO Banana Pro, etc.).
