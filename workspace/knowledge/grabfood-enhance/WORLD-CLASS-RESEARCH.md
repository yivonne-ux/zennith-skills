# WORLD-CLASS FOOD PHOTOGRAPHY & CURATION RESEARCH

> Deep forensic research across 10 domains. Specific values, techniques, workflows.
> Compiled 2026-03-23 from 50+ professional sources.

---

## TABLE OF CONTENTS

1. [Professional Post-Production Workflow](#1-professional-post-production-workflow)
2. [Adaptive AI Image Enhancement](#2-adaptive-ai-image-enhancement)
3. [Luxury Color Grading & Film Look](#3-luxury-color-grading--film-look)
4. [Plate Styling: Cheap to Premium](#4-plate-styling-cheap-to-premium)
5. [Michelin-Star Photography Aesthetic](#5-michelin-star-photography-aesthetic)
6. [Professional Retouching Techniques](#6-professional-retouching-techniques)
7. [Delivery App Photography Standards](#7-delivery-app-photography-standards)
8. [Film Grain: Organic Analog Texture](#8-film-grain-organic-analog-texture)
9. [Color Science & Split Toning](#9-color-science--split-toning)
10. [Premium Badge & Icon Design](#10-premium-badge--icon-design)

---

## 1. PROFESSIONAL POST-PRODUCTION WORKFLOW

### The Order of Operations (Critical)

Professional food photographers follow a strict sequence. Deviating from this order compounds errors.

**Step 1: Color Profile Selection**
- Choose RAW color profile FIRST (Adobe Standard, Camera Faithful, etc.)
- This determines how ALL subsequent adjustments render
- Camera Faithful = truest to scene; Adobe Standard = punchier midtones

**Step 2: White Balance**
- Shoot with gray card for neutralization
- Kelvin values for food: 5200-5800K (neutral daylight), 5800-6500K (warm golden tone)
- Golden hour warmth = ~4000K ambient; set camera to 5500K+ to enhance warmth
- Studio daylight: 5000-5500K; tungsten: ~3200K
- Tint: typically +5 to +15 (slight magenta push fights green cast from foliage/herbs)

**Step 3: Crop & Straighten**
- Before any tonal work
- 4:5 (Instagram feed), 9:16 (stories), 16:9 (delivery apps)
- Straighten horizon/table lines to within 0.5 degrees

**Step 4: Exposure & Tone**
- Exposure: never exceed +1.00; typical range -0.3 to +0.5
- Highlights: -5 to -30 (recover blown gloss/steam)
- Shadows: +10 to +30 (reveal depth without flatness)
- Whites: +10 to +20 (lift overall brightness ceiling)
- Blacks: -5 to -15 (add density, prevent washed-out look)
- Contrast: +10 to +25 (global)

**Step 5: Tone Curve (S-Curve)**
- Create gentle S: lift shadows point at ~25% input to ~30% output
- Pull highlights point at ~75% input to ~70% output
- FOOD-SPECIFIC: keep the S very gentle; aggressive = dry/unappetizing
- Optional: lift the black point (bottom-left) to ~5-8% for faded film look
- For "expensive" look: barely perceptible S, rely on light quality instead

**Step 6: Clarity & Texture**
- Clarity: +5 to +10 MAX for food (midtone contrast)
- NEVER past +10 or food looks dry, chalky, and unappetizing
- Texture: +10 to +20 (micro-contrast without halo artifacts)

**Step 7: Vibrance & Saturation**
- Vibrance: +5 to +15 (boosts muted colors, protects already-saturated)
- Saturation: +3 to +5 MAX (global push; Vibrance is the better tool)
- Vibrance is preferred because it does not oversaturate already-vivid tones

**Step 8: HSL Panel (Per-Color Control)**
- Orange Hue: +10 to +14 (warm skin tones on hands, warm bread crusts)
- Orange Saturation: -15 to -28 (prevent oversaturation of warm food)
- Orange Luminance: +10 to +17 (brighten warm tones)
- Yellow Saturation: -10 to -20 (calm aggressive yellows)
- Green Saturation: -5 to -15 (natural herb look, not neon)
- Red Luminance: +5 to +10 (make reds pop without oversaturating)
- Professional approach: adjust each color individually, never rely on global sat

**Step 9: Sharpening**
- Amount: 40-60 for food (web); 80-100 for print
- Radius: 0.8-1.2
- Detail: 25-40
- Masking: 40-60 (hold Alt/Option while sliding to see mask; protects smooth areas)

**Step 10: Noise Reduction**
- Luminance: 10-20 (subtle smoothing)
- Detail: 50-60 (preserve texture)
- NEVER push luminance past 30 or food looks plastic/waxy

**Step 11: Vignette**
- Post-crop vignette: -5 to -15 (subtle darkening of edges)
- Draws eye to center/hero dish
- Midpoint: 40-60; Roundness: 0; Feather: 80-100

**Step 12: Grain (Last Step)**
- Added AFTER all other edits
- See Section 8 for specific values

### Capture One vs Lightroom

| Feature | Capture One | Lightroom |
|---------|------------|-----------|
| Color Editor | 3-way (Basic, Advanced, Skin Tone) | HSL panel only |
| Tethering | Industry-leading, instant | Unreliable, slow, glitchy |
| Layers | Full adjustment layers with opacity | No layers (masking only) |
| Skin Tone Tool | Dedicated tool with hue/sat/brightness equalization | None |
| Color Accuracy | Superior color science, finer control | Good, but less granular |
| Batch Processing | Session-based, faster for studio | Catalog-based |
| Learning Curve | Steeper | Easier, more tutorials |
| Price | $299/year or $24/month | $10/month (Photography Plan) |

**Why top food photographers choose Capture One:**
- Skin Tone Tool works on food too: equalize sauce colors, even out browning
- Layers allow separate adjustments for background vs. hero dish vs. garnish
- Tethering designed for studio workflow (shoot-review-adjust in real-time)
- Better shadow recovery with less noise introduction
- Mask opacity control (Lightroom masks are binary)

---

## 2. ADAPTIVE AI IMAGE ENHANCEMENT

### The Problem with One-Size-Fits-All

Traditional presets/filters apply the same adjustment regardless of input quality. A properly exposed photo gets the same +0.5EV as an underexposed one. This is why presets look good on the preset creator's photos and terrible on yours.

### How Adaptive AI Works

1. **Scene Analysis**: CNN models classify lighting (daylight, tungsten, shade, mixed)
2. **Neutral Detection**: AI identifies neutral grays/whites to recalibrate white balance
3. **Exposure Mapping**: Histogram analysis detects underexposure, overexposure, clipping
4. **Per-Region Correction**: Different areas get different adjustments (shadow lift vs. highlight recovery)
5. **Color Grading**: Context-aware saturation and hue shifts based on detected food type

### Production-Ready Tools & APIs

**Claid.ai (Best for Food Delivery)**
- Purpose-built for food/marketplace photos
- API operations: `decompress` (remove JPEG artifacts), `polish` (sharpen details), `enhance` (auto-correct)
- HDR intensity: 0-100 scale (100 recommended for most food)
- Used by Rappi: 25% productivity increase, 42% time saved, 33% more restaurants onboarded
- Pricing: API-based, per-image
- Key advantage: detects and fixes blur, noise, JPEG artifacts, poor lighting in single call

**Autoenhance.ai**
- Originally real estate; expanding to food/product
- API with SDKs for Python, JS, etc.
- Processing time: <10 seconds per image
- Features: HDR merging, perspective correction, color correction
- Per-region calibration: different areas adjusted independently
- Batch processing and bracketed HDR supported

**LetsEnhance.io / Claid Enhancement API**
- Fix blur from camera shake or low-quality sources
- Remove digital noise from low-light photography
- Eliminate JPEG compression artifacts (blocking, color banding, mosquito noise)
- Correct poor lighting and color from inconsistent shooting conditions

### Building Your Own Adaptive Pipeline (Python)

```
Input Image
    |
    v
[1] Analyze: histogram, mean brightness, color cast, noise level
    |
    v
[2] Classify: underexposed / overexposed / color-cast / noisy / OK
    |
    v
[3] Route to correction:
    - Underexposed: gamma correction (1.2-1.5), shadow lift, noise reduction
    - Overexposed: highlight recovery, exposure pull (-0.3 to -0.8)
    - Color cast: white balance correction via gray-world assumption
    - Noisy: bilateral filter (d=9, sigmaColor=75, sigmaSpace=75)
    - OK: skip to enhancement
    |
    v
[4] Enhance: unsharp mask, selective saturation, micro-contrast
    |
    v
[5] Brand layer: logo, grain, vignette
```

### Key Metrics to Detect Before Correction

| Metric | How to Measure | Threshold |
|--------|---------------|-----------|
| Brightness | Mean pixel value (0-255) | <80 = underexposed, >200 = overexposed |
| Contrast | Std deviation of pixel values | <40 = flat, >80 = harsh |
| Color cast | Compare R/G/B channel means | >15 difference = cast present |
| Noise | Variance of Laplacian | <100 = blurry, >500 = noisy |
| Saturation | Mean HSV saturation | <30 = desaturated, >200 = oversaturated |
| Sharpness | Laplacian variance | <100 = soft/blurry |

---

## 3. LUXURY COLOR GRADING & FILM LOOK

### What Makes Food Photos Look "Expensive" vs "Cheap"

**EXPENSIVE:**
- Soft, directional light (side or back) with controlled shadows
- Muted, sophisticated color palette (not oversaturated)
- Shallow depth of field with intentional bokeh
- Subtle film-like grain (organic texture, not digital noise)
- Deliberate negative space
- Warm highlights with cool shadow undertones
- Food appears effortlessly styled (controlled chaos)
- Earth tones, matte surfaces, linen textures
- Restraint in editing: "the best food photography doesn't scream 'edited'"

**CHEAP:**
- Front flash or flat overhead fluorescent
- Oversaturated, garish colors (especially reds and yellows)
- Everything in focus (phone camera deep DOF)
- No texture, plasticky smooth surfaces
- Cluttered frame with no breathing room
- Instagram-filter-heavy (strong vignette, heavy warmth, lifted blacks)
- Shiny, reflective plates
- Busy patterns competing with food

### The Film Look Recipe (Not Instagram Filters)

**1. Lifted Blacks (Faded Film)**
- Tone curve: lift bottom-left point to 5-10% output
- This prevents pure black, creating that slightly faded analog feel
- Too much = washed out; 5-8% is the sweet spot

**2. Muted Highlights**
- Tone curve: pull down top-right point to 95-97% output
- Prevents pure white, softens the overall feel
- Creates that "printed on matte paper" quality

**3. Subtle Color Shift**
- Shadows: push toward blue/teal (Hue 200-220, Saturation 8-15)
- Highlights: push toward warm amber (Hue 40-55, Saturation 5-12)
- Midtones: leave mostly neutral or very slight warm push (Hue 45, Saturation 3-5)

**4. Reduced Global Saturation**
- Pull saturation -5 to -15 from reality
- Then selectively boost only the hero food colors via HSL
- This creates the "desaturated-but-rich" look of editorial food photography

**5. Grain (See Section 8)**
- Fine, luminosity-dependent, organic
- Amount 15-25 in Lightroom

**6. Slight Warmth**
- White balance 100-300K warmer than neutral
- Creates inviting, appetizing feel without being orange

### Color Grading Workflows

**Lightroom Color Grading Panel (replaced Split Toning):**
- Three wheels: Shadows, Midtones, Highlights
- Each has: Hue, Saturation, Luminance
- Blending slider: controls transition softness between tonal regions (default 50)
- Balance slider: shifts the boundary between shadows and highlights

**Photoshop Curves per Channel:**
- Red channel: lift shadows slightly (+3-5 at quarter tone) for warmth in shadows
- Blue channel: pull down highlights (-5-8) for warm highlights; lift shadows (+5-8) for cool shadows
- Green channel: usually left alone or very minor adjustments

---

## 4. PLATE STYLING: CHEAP TO PREMIUM

### Dishware Selection Rules

**Size Matters Most:**
- Use salad/dessert plates (6-7 inches) for most dishes
- Dinner plates (10-11 inches) create too much negative space, look empty
- Small plates make portions look generous and abundant
- Rule: food should fill 60-70% of the plate surface

**Surface Finish:**
- MATTE finishes = premium (no glare, no distracting reflections)
- Glossy/shiny plates = cheap (create hotspots, fight lighting control)
- Best colors: white, cream, beige, light gray, matte black, earth tones
- Avoid: patterned plates, bright colors, metallic rims (compete with food)

**Premium Materials:**
- Stoneware > porcelain > melamine
- Wood boards/slabs for rustic positioning
- Slate for dramatic contrast (dark background for light food)
- Pewter plates (naturally matte, age beautifully)
- Handmade ceramics with slight imperfections = artisanal luxury
- Copper accents for warmth

### Plating Techniques That Upgrade Instantly

**1. Odd Number Rule**
- Always plate in odd groupings: 3, 5, 7
- 3 dumplings > 4 dumplings (more dynamic, visually pleasing)
- Applies to garnishes, sauce dots, ingredient clusters

**2. Height & Layering**
- Stack ingredients to create vertical dimension
- Even 1-2cm of height transforms flat compositions
- Use base layers: rice bed, sauce pool, leaf bed
- Lean proteins against starch for architectural feel

**3. Negative Space**
- Leave 30-40% of plate empty (fine dining standard)
- Empty space = luxury; crowded plate = cheap
- Use the rule of thirds for food placement on plate

**4. Sauce Work**
- Swoosh: drag spoon through sauce puddle (controlled, not sloppy)
- Dots: precision pipette dots of contrasting sauce
- Pool: off-center sauce pool, food placed partially on it
- Drizzle: thin stream from height, creating organic lines

**5. Garnish Hierarchy**
- Microgreens: freshness, color pop, height
- Fresh herb sprigs: rosemary, thyme, basil (odd numbers)
- Citrus zest: bright yellow/orange contrast
- Cracked pepper: texture, sophistication
- Edible flowers: sparingly, only if cuisine-appropriate
- Toasted sesame/seeds: texture contrast
- RULE: garnish must be edible and relate to the dish

**6. Surface/Background Upgrades**
- Dark wood boards: warmth, rustic premium
- Marble slabs: luxury, clean
- Linen napkins/cloth: texture, warmth, lifestyle
- Vintage silverware: character, story
- Clean edges: wipe plate rim with vodka (evaporates streak-free)

### Before/After Transformation Checklist

| Cheap Signal | Premium Fix |
|-------------|------------|
| Food centered on large plate | Food off-center on smaller plate |
| Flat, no height | Layered, stacked, leaned |
| Shiny plate | Matte ceramic or stoneware |
| Even number of items | Odd grouping (3, 5, 7) |
| No garnish | Strategic herbs + microgreens |
| Sauce pooled randomly | Controlled swoosh or dots |
| Bright overhead light | Side/back light with shadow |
| Cluttered background | Clean surface + 1-2 props max |
| Visible plate edges | Tight crop or intentional negative space |

---

## 5. MICHELIN-STAR PHOTOGRAPHY AESTHETIC

### The Michelin Visual Language

Michelin-starred restaurants have a distinctive photographic approach that communicates precision, artistry, and restraint.

**Core Principles:**

**1. Negative Space as Statement**
- 40-60% of plate is empty (vs. 0-20% in casual dining)
- The empty space IS the design
- Communicates: "every element is intentional, nothing is filler"
- Large plates (often 12-14 inches) with small, precise food portions

**2. Precision Placement**
- Every element placed with tweezers (literally)
- Dots of sauce at exact intervals
- Herb leaves at specific angles
- No randomness; controlled asymmetry

**3. Minimal Color Palette**
- Typically 3-4 colors per plate maximum
- Often earth tones: whites, greens, browns, with one accent color
- Color comes from ingredients, not plates or garnish

**4. Chiaroscuro Lighting**
- Strong contrast between light and dark
- Side light or dramatic backlighting
- Deep shadows that add mystery and depth
- Dark backgrounds (black, charcoal, dark wood) are standard
- Key-to-fill ratio of 4:1 or higher

**5. Texture as Hero**
- Macro-level detail: crispy skin pores, sauce viscosity, herb vein structure
- Shot at f/2.8-f/4 for selective focus on texture
- The photograph should make you feel the texture

**6. Dark Moody Palette**
- Earthy tones: dark browns, blacks, deep greens, charcoal
- Matte surfaces exclusively
- Props (if any) are dark, aged, imperfect
- Color temperature: neutral to slightly warm (5200-5600K)

### Technical Setup for Michelin-Style

| Parameter | Value |
|-----------|-------|
| Lighting | Single source, side or 45-degree back |
| Modifier | Large softbox or diffusion panel, feathered |
| Fill | Black cards/V-flats to ABSORB light (not bounce) |
| Background | Dark slate, black stone, charcoal wood |
| Aperture | f/2.8 to f/5.6 (selective focus) |
| Focal length | 90-105mm macro (detail shots), 50-85mm (full plate) |
| ISO | 100-400 (clean files) |
| White balance | 5200-5600K |
| Post-processing | Minimal; slight shadow lift, careful color grading |
| Mood | Dramatic, intimate, reverent |

### Famous Michelin Food Photographers' Approach

- **Lighting philosophy**: The food should emerge from darkness, not sit in brightness
- **Editing restraint**: "If you can tell it's been edited, you've gone too far"
- **Composition**: The Japanese concept of "ma" (negative space as meaningful pause)
- **Focal point**: One clear hero element; everything else supports

---

## 6. PROFESSIONAL RETOUCHING TECHNIQUES

### Complete Food Retouching Workflow (Photoshop)

**Phase 1: Clean-Up**
1. Clone Stamp / Healing Brush: remove crumbs, spills, imperfections
2. Content-Aware Fill: remove distracting background elements
3. Spot Healing: fix small blemishes on food surface
4. NOTE: 10% flow on brush for all food retouching (prevents heavy-handedness)

**Phase 2: Dodge & Burn for Food**

Setup (Non-Destructive):
1. Create two Curves adjustment layers: one "Dodge" (drag curve up), one "Burn" (drag curve down)
2. Invert both masks (Cmd/Ctrl+I) so they start hidden
3. Paint with white brush at 10% flow to reveal
4. Alternative: New layer > Mode: Soft Light > Fill with 50% gray > Paint black (burn) or white (dodge)

Application for Food:
- **Dodge** (lighten): highlight glossy sauce surfaces, steam, bread crust peaks, sauce drizzle edges, fresh herb leaves catching light
- **Burn** (darken): deepen shadow areas around plate edges, underneath food for grounding, between layered ingredients for depth, around garnish to make it pop
- **Brush size**: match the area you're targeting; smaller = more precision
- **Always zoom in**: work at 100-200% for micro dodge/burn
- **Step back frequently**: zoom to fit to check overall balance

**Phase 3: Frequency Separation for Food**

When to Use: smoothing backgrounds while keeping food texture sharp

Setup:
1. Duplicate background twice: name "Low Frequency" and "High Frequency"
2. Low Frequency: Gaussian Blur at 4-8px radius (enough to remove texture, keep color)
3. High Frequency: Image > Apply Image > Source: Low Frequency layer, Blending: Subtract, Scale: 2, Offset: 128
4. Set High Frequency blend mode to Linear Light

Application:
- Work on Low Frequency layer with soft brush to smooth color transitions in backgrounds, plate surfaces, sauce pools
- High Frequency texture remains sharp and untouched
- Perfect for: cleaning up uneven sauce color, smoothing napkin wrinkles, evening out plate glazing

**Phase 4: Selective Color Adjustment**

Technique:
1. Add Selective Color adjustment layer
2. Target specific color ranges (Reds, Yellows, Greens, etc.)
3. Adjust Cyan/Magenta/Yellow/Black sliders within each range
4. Mask to specific areas (e.g., boost reds only in the tomato sauce, not the plate)

Common Food Adjustments:
- Reds (tomato, meat): +5-10 Magenta, +5 Yellow, -5 to -10 Black (brighter reds)
- Yellows (bread, pasta, cheese): -10 Cyan, +5 Yellow, -5 Black (warmer, richer)
- Greens (herbs, salads): +5 to +10 Cyan, -5 Magenta, +5 Yellow (natural, vibrant)
- Whites (plate, rice): -3 to -5 Yellow (removes warmth from plate), +3 Black (slight density)

**Phase 5: Luminosity Masking**

Purpose: target adjustments to specific tonal ranges without affecting others

Creating Luminosity Masks:
1. Cmd/Ctrl+Click RGB channel thumbnail = Highlights selection
2. Invert = Shadows selection
3. Intersect with itself = more targeted (Highlights 2, Highlights 3, etc.)
4. Apply as mask to Curves/Levels adjustment layers

Food Applications:
- Brighten ONLY the highlight areas on glossy sauce without touching shadows
- Deepen ONLY the shadow areas without affecting food surface
- Add warmth to ONLY midtones (where most food color lives)
- Selective contrast: boost highlights AND deepen shadows independently

---

## 7. DELIVERY APP PHOTOGRAPHY STANDARDS

### DoorDash Specifications

| Parameter | Requirement |
|-----------|------------|
| Resolution | Minimum 1400 x 800 pixels |
| Aspect Ratio | 16:9 landscape |
| File Size | Under 16 MB |
| Format | JPEG or PNG |
| Angle | 90 degrees (overhead/flat lay) for most; 45 degrees for burgers, drinks, tall items |
| Background | Clean, uncluttered; consistent across menu |
| Lighting | Natural or well-diffused artificial; no flash |

**14 Rejection Reasons:**
1. Wrong dimensions/zoom
2. Blurry images
3. Bad lighting (too dark, too bright, shadows)
4. Color issues (wrong white balance, oversaturation)
5. Distracting backgrounds
6. Text overlays
7. Collages/multiple images combined
8. Faces visible
9. Unappetizing presentation
10. Item not clearly shown
11. Image doesn't match menu item
12. Duplicate images across items
13. Copyright issues (stock photos)
14. Non-representative AI-generated images

### UberEats Specifications

| Parameter | Requirement |
|-----------|------------|
| Resolution | Minimum 1200 x 800 pixels |
| Aspect Ratio | 5:4 |
| Content | Show ONLY what's included in the order |
| Editing | Light adjustments only: brightness, contrast, white balance |
| Authenticity | Must represent actual portion and presentation |

### GrabFood Specifications (Malaysia)

| Parameter | Requirement |
|-----------|------------|
| Store Photo | Storefront with visible shop name matching platform listing |
| Brand Logo | Required as separate upload |
| Menu Photos | Individual item photos recommended |
| Halal Cert | Required if applicable |
| File Naming | "Storefront Photo", "Ambience 1", "Ambience 2" convention |

### What Professional Delivery App Photography Programs Do

**Shooting Standards:**
- Single hero dish per frame (no composite/collage)
- Consistent background surface across entire menu
- Natural or daylight-balanced lighting (5000-5500K)
- 90-degree overhead for flat items; 0-45 degree for items with height
- Props: minimal or none (occasionally chopsticks, spoon for context)
- No human hands or faces in frame

**Impact Data:**
- Restaurants with complete, high-quality photos: 88%+ higher sales
- Photos boost delivery orders by ~15% on average (Claid.ai study)
- Missing photos = customers skip the item entirely

**Professional Enhancement Pipeline (What Apps Do Internally):**
1. Receive merchant-uploaded photos
2. Auto-detect quality issues (exposure, color, blur, artifacts)
3. Apply adaptive corrections per image
4. Standardize white balance across menu
5. Crop to platform aspect ratio
6. Optional: background replacement/cleanup via AI

---

## 8. FILM GRAIN: ORGANIC ANALOG TEXTURE

### Why Grain Makes Food Look Better

Film grain is NOT digital noise. Key differences:

| Property | Film Grain | Digital Noise |
|----------|-----------|---------------|
| Pattern | Organic, random, natural clusters | Grid-based, uniform squares |
| Shape | Irregular silver halide crystals | Square/rectangular pixels |
| Luminosity response | More visible in shadows, subtle in highlights | Uniform across tonal range |
| Color | Monochromatic (silver) or dye clouds | Often chromatic (colored dots) |
| Feel | Warm, analog, human | Cold, technical, error |
| Size variation | Variable, natural distribution | Fixed, uniform |

### Lightroom Grain Settings (Effects Panel)

**For Subtle Luxury Food Photography:**
- Amount: 15-25 (the intensity of grain)
- Size: 25-40 (larger = film-like; smaller = digital-noise-like)
- Roughness: 50-60 (higher = more irregular = more organic)

**For Medium Film Look:**
- Amount: 25-35
- Size: 40-60
- Roughness: 55-65

**For Strong Vintage/Analog:**
- Amount: 35-50
- Size: 50-80
- Roughness: 60-80

**CRITICAL RULES:**
- Grain ALWAYS goes LAST, after all other edits
- Size below 20 = looks like digital noise, not film
- Roughness and Size close together = softer grain; far apart = harsher
- View at 100% zoom while adjusting, then zoom out to check overall feel
- Lower image contrast slightly before adding grain = more natural blending

### Photoshop Grain Overlay (Superior Control)

**Method 1: Smart Object Grain**
1. New Layer > name "Film Grain"
2. Edit > Fill > 50% Gray, Mode: Normal
3. Convert to Smart Object (allows non-destructive editing)
4. Set blend mode to **Overlay** (strong) or **Soft Light** (subtle)
5. Filter > Noise > Add Noise:
   - Amount: 8-12% (subtle), 12-18% (medium), 18-25% (strong)
   - Distribution: **Gaussian** (organic) not Uniform (digital)
   - Check: **Monochromatic** (removes colored noise dots)
6. Filter > Blur > Gaussian Blur:
   - Radius: 0.5-0.8px (enlarges grain, prevents pixel-sharp noise)
7. Adjust layer opacity: 30-60% for food photography

**Method 2: Luminosity-Dependent Grain**
1. Create grain overlay as above
2. Add a Luminosity mask to the grain layer:
   - Cmd/Ctrl+Click RGB thumbnail in Channels
   - Invert the selection (Cmd/Ctrl+Shift+I)
   - Add as layer mask to the grain layer
3. Result: grain appears MORE in shadows, LESS in highlights
4. This matches real film behavior perfectly
5. Adjust mask levels to control the shadow/highlight distribution

**Method 3: Real Film Scan Overlays**
- Scan actual film frames (unexposed or evenly exposed)
- Overlay at Soft Light or Overlay blend mode
- Opacity: 10-30%
- Advantage: perfectly organic, mathematically impossible to replicate digitally
- Sources: ON1, Indieground, VSCO film packs

### Python/Pillow Grain Implementation

```python
import numpy as np
from PIL import Image, ImageFilter

def add_film_grain(img, amount=0.015, size=1.5, luminosity_dependent=True):
    """
    amount: 0.01-0.03 for subtle, 0.03-0.05 for medium
    size: 1.0-2.0 (gaussian blur sigma for grain enlargement)
    luminosity_dependent: True = more grain in shadows (real film behavior)
    """
    arr = np.array(img).astype(np.float32) / 255.0

    # Generate gaussian noise
    noise = np.random.normal(0, amount, arr.shape[:2])

    if luminosity_dependent:
        # Create luminosity map (darker areas get more grain)
        luminosity = np.mean(arr, axis=2)
        # Invert: shadows (low luminosity) get MORE grain
        grain_mask = 1.0 - (luminosity * 0.7)  # 0.7 = how much to reduce in highlights
        noise = noise * grain_mask

    # Apply to all channels equally (monochromatic)
    for c in range(3):
        arr[:,:,c] = np.clip(arr[:,:,c] + noise, 0, 1)

    result = Image.fromarray((arr * 255).astype(np.uint8))

    # Enlarge grain slightly (prevents pixel-sharp noise)
    if size > 1.0:
        result = result.filter(ImageFilter.GaussianBlur(radius=size * 0.3))

    return result
```

---

## 9. COLOR SCIENCE & SPLIT TONING

### Color Temperature Psychology for Food

| Temperature | Feel | Best For |
|-------------|------|----------|
| Cool (blue-teal) | Fresh, clean, modern | Salads, seafood, sushi, drinks |
| Neutral | Honest, authentic, editorial | Fine dining, any cuisine |
| Warm (amber-gold) | Cozy, comforting, appetizing | Soups, stews, bread, grilled, fried |
| Very warm (orange) | Street food, rustic, nostalgic | BBQ, roasted, comfort food |

### Split Toning Values (Lightroom Color Grading Panel)

**"Quiet Luxury" Food Look:**
- Shadows: Hue 210 (steel blue), Saturation 8-12, Luminance -5
- Midtones: Hue 45 (warm amber), Saturation 3-5, Luminance 0
- Highlights: Hue 45-55 (golden amber), Saturation 5-10, Luminance +3
- Blending: 50-60
- Balance: -10 to 0 (slightly shadow-biased)

**"Warm Editorial" Food Look:**
- Shadows: Hue 30 (warm brown), Saturation 10-15, Luminance -3
- Midtones: Hue 40 (amber), Saturation 5-8, Luminance 0
- Highlights: Hue 50 (gold), Saturation 8-12, Luminance +5
- Blending: 40-50
- Balance: +10 (slightly highlight-biased)

**"Cinematic Cool" Food Look:**
- Shadows: Hue 200-220 (teal/blue), Saturation 12-18, Luminance -5
- Midtones: Neutral (Saturation 0)
- Highlights: Hue 40-50 (warm amber), Saturation 8-15, Luminance +3
- Blending: 50-70
- Balance: -5 to +5

**"Film Emulation" Look:**
- Shadows: Hue 240 (blue-purple), Saturation 5-10, Luminance -3
- Midtones: Hue 30 (warm), Saturation 3-5, Luminance 0
- Highlights: Hue 55 (yellow-gold), Saturation 5-8, Luminance 0
- Blending: 60-70
- Balance: 0
- Combine with: lifted blacks (+5-8), muted highlights (-3-5)

### CRITICAL RULE: Saturation Under 30

Keep ALL color grading saturation values below 30. Above 30 = cartoonish, garish, amateur. The best food photography color grading is felt, not seen.

### Per-Channel Curves for Split Toning (Photoshop)

This gives finer control than Lightroom's Color Grading panel.

**Red Channel Curve:**
- Lift shadow region by +3 to +5 (warmth in shadows)
- Optional: slight midtone lift +2

**Green Channel Curve:**
- Usually leave flat
- Optional: very slight midtone pull -2 (adds subtle magenta cast = food warmth)

**Blue Channel Curve:**
- Lift shadow region by +5 to +10 (cool blue shadows)
- Pull down highlight region by -5 to -10 (warm golden highlights)
- This creates the classic "teal shadows + warm highlights" split tone

### Complementary Color Theory for Food

| Food Color | Complement | Application |
|-----------|------------|-------------|
| Red (tomato, meat) | Green (herbs, salad) | Red food on green garnish bed |
| Orange (curry, fried) | Blue (plate, napkin) | Warm food on cool-toned surface |
| Yellow (pasta, cheese) | Purple (eggplant, flowers) | Golden food with purple accent |
| Green (salad, herbs) | Red/Pink (radish, beet) | Green base with pink accents |
| Brown (bread, chocolate) | Teal/Blue | Dark food on blue-gray surface |

---

## 10. PREMIUM BADGE & ICON DESIGN

### Design Principles for Food Badges

**What Separates Premium from Clipart:**

| Clipart/Cheap | Premium/Luxury |
|--------------|----------------|
| Thick outlines | Thin hairline strokes (0.5-1px) |
| Bright primary colors | Muted, limited palette (1-2 colors + neutral) |
| Gradient fills | Flat or subtle mono-gradient |
| Multiple competing elements | Single icon + text |
| Rounded/bubbly fonts | Refined serif or elegant sans-serif |
| Drop shadows, bevels | Clean, flat, minimal |
| Clip art illustrations | Geometric or typographic badges |
| "BEST SELLER!!!" (all caps, exclamation) | "Best Seller" (title case, period or nothing) |

### Badge Types for Food Menus

**1. Typographic Badge (Most Premium)**
- Text only, no icon
- Refined serif font (e.g., Playfair Display, Cormorant)
- Subtle border: thin (0.5-1px) rounded rectangle or circle
- Color: single accent (gold, deep green, burgundy)
- Size: small, understated
- Example: "Chef's Selection" in 8pt Cormorant Italic inside 0.5px border

**2. Icon + Label Badge**
- Minimal icon (single line stroke): star, flame, laurel, crown
- Short label: "Best Seller" / "House Pick" / "Award Winner"
- Icon and text same color
- Total badge width: 60-80px at display size
- Stroke weight: 1-1.5px for icon

**3. Seal/Emblem Badge**
- Circular or shield shape
- Laurel wreath surround (thin line, not illustrated)
- Central icon: star, fork-knife crossed, chef hat (minimal line style)
- Text wraps around perimeter
- Monochrome: gold on dark, or dark on light
- Example: circular seal with "EST. 2020" and laurel

**4. Ribbon/Tab Badge**
- Small angled tab attached to menu item card
- Solid fill in accent color
- White text: "Popular" / "New" / "Spicy"
- 45-degree fold detail at one end
- Height: 20-24px, text: 10-11px

### Color Systems for Food Badges

| Badge Type | Primary Color | Text Color | Background |
|-----------|--------------|------------|------------|
| Best Seller | Gold (#C5A55A) or Amber (#D4943A) | White or Dark (#1A1A1A) | Transparent or dark card |
| Chef's Pick | Deep Green (#2D5F3F) or Burgundy (#6B2D3E) | White or Gold | Transparent |
| Award/Premium | Gold (#B8933A) with thin border | Dark (#1A1A1A) | Transparent |
| New Item | Accent brand color | White | Solid pill shape |
| Spicy Level | Red gradient (#C43A3A to #8B2020) | White | Transparent or subtle fill |
| Vegetarian | Green (#3A7D44) | White | Small circle or leaf icon |

### Icon Design Specifications

**Stroke-Based Icons (Most Sophisticated):**
- Stroke weight: 1-1.5px at 24px icon size
- Line cap: round
- Line join: round
- Corner radius: 2px on rectangular elements
- Consistent 24x24px grid system
- No fills, outlines only
- Mono-weight (same stroke thickness throughout)

**Common Premium Food Icons:**
- Star (5-point, single stroke, no fill)
- Flame (2-curve minimal, one stroke)
- Laurel wreath (opposing curved branches, 4-5 leaves each)
- Crown (3-point, single line)
- Diamond (rotated square, single stroke)
- Chef hat (simplified dome + band)
- Fork-knife crossed (thin line, 45-degree X)

### Implementation for Delivery App Menus

**Badge Placement Rules:**
- Top-left corner of menu item card (primary badge position)
- Below dish name, inline with description (secondary position)
- Never more than 2 badges per item
- Badge should be 15-20% the width of the menu card
- Opacity: 90-95% (slightly transparent = more sophisticated)
- Padding: 4-6px internal padding within badge border

**Animation (if digital):**
- Subtle entrance: fade in 200ms with 20ms delay after card appears
- No bouncing, spinning, or pulsing (cheap)
- Optional: very subtle scale from 0.95 to 1.0 over 150ms

---

## APPENDIX: QUICK-REFERENCE CHEAT SHEET

### The 10-Second Quality Check

Before publishing any food photo, verify:

1. **White balance**: plates/rice should be neutral white, not yellow/blue
2. **Exposure**: no blown highlights on food surface, visible shadow detail
3. **Focus**: sharpest point on the hero element of the dish
4. **Color**: appetizing (warm) not clinical (cool) or garish (oversaturated)
5. **Composition**: clear subject, breathing room, no clutter
6. **Grain**: subtle organic texture, not digital noise or plastic-smooth
7. **Contrast**: dimensional (not flat, not harsh)
8. **Edges**: clean plate rims, no crumbs outside frame
9. **Consistency**: matches the rest of the menu/feed in tone and style
10. **Appetite appeal**: does it make YOU want to eat it?

### Universal Enhancement Pipeline (Code-Ready)

```
INPUT (merchant photo, variable quality)
  |
  [1] ANALYZE: brightness, contrast, color cast, noise, sharpness
  |
  [2] CORRECT (adaptive):
      - White balance normalization
      - Exposure correction (target mean brightness: 120-140)
      - Shadow lift (+10-20%)
      - Highlight recovery (-5-15%)
  |
  [3] ENHANCE:
      - Clarity/texture: unsharp mask (amount=0.3, radius=2, threshold=3)
      - Vibrance: selective saturation boost on food colors (+5-10%)
      - Warmth: +100-200K color temperature shift
  |
  [4] GRADE:
      - S-curve (subtle): shadow lift 5%, highlight pull 3%
      - Split tone: blue shadows (hue=210, sat=8), warm highlights (hue=45, sat=6)
  |
  [5] FINISH:
      - Vignette: -8 to -12, feathered
      - Grain: amount=0.015, gaussian, monochromatic, luminosity-dependent
      - Logo overlay (brand layer)
  |
  [6] EXPORT:
      - Delivery app: 1400x800 JPEG @ 90% quality
      - Social: 1080x1350 (feed) or 1080x1920 (stories)
      - Sharpen for output: amount=30, radius=0.5 (screen)
```

---

## SOURCES

### Post-Production Workflow
- [Digital Photography School - Lightroom Food Editing](https://digital-photography-school.com/how-edit-food-photography-images-using-lightroom/)
- [Expert Photography - Lightroom Food Process](https://expertphotography.com/lightroom-process-food-photography/)
- [Fstoppers - How I Edit My Food Photographs](https://fstoppers.com/education/how-i-edit-my-food-photographs-409576)
- [Two Loves Studio - Lightroom Magic](https://twolovesstudio.com/blog/why-i-created-lightroom-magic/)
- [Two Loves Studio - Lightroom to Capture One](https://twolovesstudio.com/blog/lightroom-to-capture-one/)
- [PRO EDU - Lightroom Workflow for Food Photography](https://proedu.com/blogs/news/lightroom-workflow-food-photography)
- [Francesco Sapienza - Post-Processing Workflow](https://www.francescosapienza.com/food-photographer-nyc-restaurant-new-york-blog/2019/1/22/food-photography-series-post-processing-workflow)
- [John Fyn - Capture One vs Lightroom](https://johnfyn.com/capture-one-vs-lightroom-for-food-photographers/)
- [Capture One Blog - 5 Advantages Over Lightroom](https://www.captureone.com/blog/5-advantages-of-capture-one-pro-over-lightroom)
- [Food Photography Academy - HSL Panel](https://foodphotographyacademy.co/blog/editing/editing-how-i-edit-food-photography-in-lightroom-for-colour-hsl-panel/)
- [Simple Green Recipes - 9-Step Lightroom Workflow](https://www.simplegreenrecipes.com/9-step-lightroom-editing-workflow-for-food-photography-part-1/)
- [French.ly - Advanced Lightroom Editing](https://french.ly/advanced-lightroom-editing/)
- [Food Photography Blog - White Balance & Kelvin](https://foodphotographyblog.com/what-is-white-balance-color-temperature-and-kelvin/)

### Adaptive AI Enhancement
- [Autoenhance.ai](https://autoenhance.ai/)
- [Claid.ai - Food Delivery Enhancement](https://claid.ai/food/)
- [Claid.ai - Enhancement API](https://claid.ai/product/enhancement)
- [LetsEnhance.io - Image Enhancement API](https://letsenhance.io/blog/all/how-to-enhance-images-api/)
- [Claid.ai - Rappi Case Study](https://claid.ai/customers/case-study/rappi-food-delivery/)

### Color Grading & Film Look
- [Two Loves Studio - Color Grading Food Photography](https://twolovesstudio.com/blog/color-grading-food-photography/)
- [Food Photography Academy - Color Grading Guide](https://foodphotographyacademy.co/blog/editing/editing-lightroom-color-grading-an-in-depth-guide-for-food-photographers/)
- [Vlad Moldovean - Grain Deep Dive](https://vmoldo.com/grain-deepdive/)
- [PHLEARN - Moody Food LUTs](https://phlearn.com/tutorial/moody-food-lut-pack/)

### Plate Styling
- [Helm Publishing - Professional Food Styling](https://www.helmpublishing.com/blogs/blog/crafting-picture-perfect-plates-a-guide-to-professional-food-styling)
- [Food Photography Blog - Perfect Plate Selection](https://foodphotographyblog.com/how-to-pick-the-perfect-plate-for-your-food-photos-five-tips-from-a-prop-stylist/)
- [Unilever Food Solutions - Modern Plating Styles](https://www.unileverfoodsolutions.us/chef-training/food-service-and-hospitality-marketing/food-photography-and-food-plating-tips-and-techniques/modern-food-plating-presentation-styles.html)
- [Nerds with Knives - Props & Dishware Guide](https://nerdswithknives.com/props-dishware-bakeware/)
- [Vancasso Tableware - Plate Styling Mastery](https://www.vancassotableware.com/blogs/news/plate-styling-tips-for-instagram-food-photos)

### Michelin-Star Photography
- [Raymond Jones - Chasing Michelin Stars](https://raymondjonesimages.com/blog-1/2024/2/9/chasing-michelin-stars-a-food-photographers-journey)
- [Lenka's Lens - Dark n Moody](https://www.lenkaslens.com/dark-n-moody)
- [Mainstream Multimedia - Dark Moody Guide](https://www.mainstreammultimedia.com/blog/dark-moody-food-photography-guide)
- [Michelin Guide - Chef Plating Techniques](https://guide.michelin.com/en/article/features/how-chefs-of-michelin-starred-restaurants-entice-with-exquisite-plating)
- [Moca Dining - Michelin Star Plating](https://mocadining.com/michelin-star-plating-techniques/)
- [Placement International - Michelin Plating Tips](https://placement-international.com/blog/5-michelin-plating-tips)

### Professional Retouching
- [Retouching Academy - Dodge & Burn Guide](https://retouchingacademy.com/the-ultimate-guide-to-the-dodge-burn-technique-on-fstoppers-by-julia-kuzmenko-mckim/)
- [PHLEARN - How to Dodge & Burn](https://phlearn.com/tutorial/how-to-dodge-and-burn-in-photoshop/)
- [PHLEARN - Food Photography Styling & Retouching](https://phlearn.com/tutorial/food-photography-styling-retouching/)
- [Two Loves Studio - Retouching Food Photography](https://twolovesstudio.com/blog/retouch-food-photography/)
- [Two Loves Studio - 10 Ways to Retouch Food in Photoshop](https://twolovesstudio.com/blog/ways-to-use-photoshop-to-retouch/)
- [Bootstrapped Ventures - Common Food Photo Fixes](https://bootstrapped.ventures/editing-food-photography/)

### Delivery App Standards
- [Beautiful Food - DoorDash & UberEats Photos](https://www.trybeautifulfood.com/blog/how-to-take-food-photos-doordash-ubereats)
- [DoorDash Photo Requirements 2026](https://gourmetpix.com/blog/doordash-photo-requirements)
- [DoorDash Merchant Photo Requirements](https://merchants.doordash.com/en-us/learning-center/photo-rejection)
- [UberEats Photo Guidelines](https://help.uber.com/merchants-and-restaurants/article/restaurant-submitted-menu-photo-guidelines)
- [Ocusquality - DoorDash Photography Standards](https://www.ocusquality.com/guidelines/doordash-food-photography-en)
- [Spectrum Brand - Tips for Delivery App Photography](https://spectrum-brand.com/blogs/news/food-photography-tips-for-uber-eats-instagram-deliveroo-grabfood-or-doordash)
- [Claid.ai - Food Photo Impact Study](https://claid.ai/blog/article/impact-of-visual-content-on-food-tech)

### Film Grain
- [Analogue Wonderland - Art of Film Grain](https://analoguewonderland.co.uk/blogs/film-photography-blog/the-art-of-film-grain)
- [MasterClass - Film Grain Effect Guide](https://www.masterclass.com/articles/film-grain-effect-guide)
- [PetaPixel - Emulate Film Grain Digitally](https://petapixel.com/2025/09/19/how-to-emulate-film-grain-in-your-digital-photos/)
- [PRO EDU - Grain in Photography](https://proedu.com/blogs/photography-fundamentals/grain-in-photography-understanding-its-creative-use)
- [Ciennaso - Film Grain in Lightroom](https://www.ciennaso.com/post/perfecting-film-grain-in-lightroom-tips-for-a-film-inspired-look-with-presets)
- [Photography Life - Add Film Grain in Lightroom](https://photographylife.com/mastering-lightroom-how-to-add-film-grain)
- [Alik Griffin - Better Film Grain in Lightroom](https://alikgriffin.com/how-to-create-a-better-film-like-grain-in-lightroom/)
- [Medialoot - Simulate Film Grain in Photoshop](https://medialoot.com/blog/how-to-simulate-film-grain/)
- [Carter Hewson - Creating Realistic Film Grain](https://carterhewson.com/for-photographers/film-grain-in-photoshop/)
- [Vlad Moldovean - Grain in Lightroom Masks](https://vmoldo.com/grain-in-lightroom/)

### Color Science & Split Toning
- [Photography Institute - Science of Color](https://www.thephotographyinstitute.com/us/en/blog-the-science-of-colour-in-photography)
- [Food Photography Academy - Color Grading Guide](https://foodphotographyacademy.co/blog/editing/editing-lightroom-color-grading-an-in-depth-guide-for-food-photographers/)
- [Digital Photography School - Complementary Colors](https://digital-photography-school.com/stylize-images-using-complementary-colors-lightroom/)
- [Northlandscapes - Split Toning Guide](https://www.northlandscapes.com/articles/what-is-split-toning-and-how-to-use-it-in-lightroom)
- [SLR Lounge - Split Toning Secret](https://www.slrlounge.com/split-toning-the-secret-in-the-recipes-for-many-adored-images-but-totally-undervalued/)
- [PRO EDU - Chiaroscuro Food Photography](https://proedu.com/blogs/news/how-to-shoot-food-chiaroscuro-style)

### Badge & Icon Design
- [TouchBistro - 51 Restaurant Menu Design Examples](https://www.touchbistro.com/blog/51-examples-of-excellent-restaurant-menu-design/)
- [Creative Market - Best Restaurant Menu Designs](https://creativemarket.com/blog/restaurant-menu-designs)
- [Deliveroo & GrabFood UI Comparison](https://www.linkedin.com/pulse/food-ordering-uiux-comparison-foodpanda-vs-grabfood-sanbron-liong)
- [Dribbble - GrabFood Designs](https://dribbble.com/tags/grabfood)
- [Mobbin - Food App Design Patterns](https://mobbin.com/explore/mobile/app-categories/food-drink)
