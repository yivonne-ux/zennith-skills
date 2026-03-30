# Pixel-Level Craft Guide: Professional Design Execution Techniques

> A practical reference for the obsessive details that separate amateur from professional design.
> Compiled from extensive research across typography, color, layout, texture, and finishing disciplines.

---

## 1. TYPOGRAPHY MASTERY

### 1.1 Optical vs Mathematical Spacing

**The core problem:** Software default spacing (metrics kerning) is mathematically even but visually uneven. The human eye perceives space by *area between letterforms*, not by distance between edges.

**Key letter pairs that always need manual kerning:**
- AV, AW, AT, AY — the diagonal-meets-vertical problem
- To, Tr, Ta, Te — round top + flat bottom
- LT, LY, LV, LW — flat right + diagonal left
- WA, VA, YA — inverse of the AV problem
- OC, OG, OQ — round-meets-round (may need loosening)

**Professional workflow:**
1. Set text in your layout tool with **Optical kerning** as a baseline (better than Metrics for display type)
2. Then manually adjust problem pairs — especially at display sizes (24pt+)
3. The "three-letter test": cover all letters except three at a time, check that the space between the visible pair looks equal to the space in adjacent pairs
4. **Rule of thumb:** The larger the type, the more you must tighten. At 72pt+, default spacing looks cavernous

**Tracking adjustments by context:**
- Body text (10-16pt): Leave at 0 (default). The type designer optimized for this range
- Large display (48pt+): Tighten by -10 to -30 units (depends on typeface)
- All-caps text: Loosen by +20 to +75 units (caps are designed for mixed case; in all-caps, they feel cramped)
- Small caps: Loosen by +10 to +50 units

---

### 1.2 Typographic Hierarchy System

**Professional designs use 4-6 levels of hierarchy.** Each level must be *obviously* different from the next — not subtly different.

**The three tools for creating hierarchy (use at least 2 per level jump):**
1. **Size** — the most obvious differentiator
2. **Weight** — Bold/Black vs Regular/Light creates dramatic contrast
3. **Case/Style** — ALL CAPS, italic, color change

#### Modular Scale Ratios (choose one for your project)

| Ratio Name | Value | Character | Best For |
|---|---|---|---|
| Minor Second | 1.067 | Almost invisible steps | Dense data UIs |
| Major Second | 1.125 | Subtle, refined | Long-form reading |
| Minor Third | 1.200 | Moderate contrast | General UI, web |
| **Major Third** | **1.250** | **Clear, readable steps** | **Social media, brand** |
| Perfect Fourth | 1.333 | Strong contrast | Editorial, posters |
| **Golden Ratio** | **1.618** | **Dramatic, high impact** | **Display, hero type** |

**Example using Major Third (1.25x) from 16px base:**
- Level 6 (caption): 10px
- Level 5 (body small): 13px
- Level 4 (body): 16px (base)
- Level 3 (subhead): 20px
- Level 2 (section head): 25px
- Level 1 (hero/display): 31px

**Example using Golden Ratio (1.618x) from 16px base:**
- Level 4 (body): 16px
- Level 3 (subhead): 26px
- Level 2 (section head): 42px
- Level 1 (hero/display): 67px

**Weight contrast pairings that create drama:**
- Display: Black (900) + Body: Regular (400) — maximum drama
- Display: Bold (700) + Body: Light (300) — elegant tension
- Display: Medium (500) + Body: Regular (400) — subtle, sophisticated

#### The Squint Test

Squint your eyes or step back 3 meters from your screen. The design should still communicate its hierarchy:
- The headline should be the obvious first read
- Secondary information should form a clear second tier
- Body text should blur into a uniform gray block
- If two levels merge into one blob, they need more contrast between them

**Implementation:** Take a screenshot of your design, apply a 10-15px Gaussian blur. If the hierarchy still reads, it works. If elements merge together, increase the contrast between them.

---

### 1.3 Display Typography Techniques

#### Tracking Rules by Context
- **Large display (48pt+):** Tighten tracking -10 to -30. Large type looks loose at default
- **Medium headlines (24-48pt):** -5 to -15 tracking
- **Body text (12-18pt):** 0 tracking (leave at default)
- **Small text/captions (<12pt):** Loosen +10 to +25 for legibility
- **ALL CAPS at any size:** Add +20 to +75 tracking. Caps were designed for mixed case

#### When to Use Each Case Style

| Style | Use When | Example |
|---|---|---|
| ALL CAPS | Short labels, buttons, nav items, category tags. Max ~3-4 words | BOOK NOW |
| Title Case | Headlines, section titles, formal headings | Welcome to Our Studio |
| Sentence case | Body text, long headlines, conversational tone | We believe play matters |
| lowercase | Ultra-casual brands, tech/startup aesthetic | let's play together |

**Critical rule:** NEVER set long paragraphs in ALL CAPS. All-caps text is 13-20% slower to read because words lose their distinctive shape (ascenders/descenders). ALL CAPS should be reserved for max 3-5 words.

#### Making Type "Breathe"

**Line height (leading) by context:**
- Headlines/Display: 1.0 - 1.2 (tight — headlines should feel like a single unit)
- Subheads: 1.2 - 1.3
- Body text: 1.4 - 1.6 (the sweet spot for readability is ~1.5)
- Small/caption text: 1.5 - 1.7 (smaller text needs proportionally more breathing room)

**Paragraph spacing:**
- Optimal paragraph margin = line-height x 0.75
- Example: If line-height is 24px, paragraph spacing should be ~18px
- Space before a heading = 2x the paragraph spacing (creates clear section breaks)

**The "type as hero" approach:**
When type IS the entire design (no imagery needed):
- Use oversized, bold type (80pt+) as the primary visual element
- Combine with generous white space (40%+ of canvas empty)
- Create contrast with one word in a different weight, color, or style
- Limit yourself to 5-8 words maximum
- Works best with strong, geometric typefaces

---

### 1.4 Professional Font Pairing

#### The Three Strategies

**Strategy 1: Contrast pairing (serif + sans-serif)**
The safest and most reliable approach. The structural difference between serif and sans creates natural visual separation.
- Serif for display/headlines + Sans for body (classic editorial)
- Sans for display/headlines + Serif for body (modern editorial)
- Match x-heights between the two typefaces (letters like "a" and "e" should sit at similar heights)
- Check lowercase "a" and "e" — similar shapes signal compatible typefaces

**Strategy 2: Superfamily (one typeface family, multiple weights/widths)**
Using one typeface family with extreme weight contrast (Black headlines + Light body) from the same family:
- Guarantees perfect x-height matching
- Simplifies font loading and file management
- Creates clean, systematic hierarchy
- Example: Mabry Pro Black (display) + Mabry Pro Regular (body)

**Strategy 3: Mood matching with contrast**
- Pair a playful display face (script, rounded, decorative) with a clean, neutral body face
- The display face carries the brand personality; the body face stays invisible (readable)
- Never pair two "personality" fonts — they compete for attention

#### Hard Rules
- **Maximum 2-3 typefaces per design.** More than 3 = visual chaos
- **Never pair two serif fonts** unless they are dramatically different (e.g., slab serif + old style)
- **Never pair two similar sans-serifs** — the subtle difference reads as a mistake, not a choice
- **Same designer principle:** Typefaces by the same designer often pair well (shared DNA in proportions and angles)
- **Test at multiple sizes:** A pairing that works at headline size may fail at caption size

---

## 2. COLOR MASTERY

### 2.1 The 60-30-10 Rule in Practice

**The split:**
- **60% Dominant** — background, large surfaces (usually the most neutral color)
- **30% Secondary** — supporting areas, secondary surfaces, large text blocks
- **10% Accent** — CTAs, highlights, focal points (usually the most vibrant color)

**Practical application for a social media post (1080x1350):**
- 60% = Background fill (e.g., cream #F5F0E8) — ~874,800 pixels
- 30% = Secondary elements: text blocks, shapes, cards (e.g., soft color) — ~437,400 pixels
- 10% = Accent: headline color, button fills, icons (e.g., vibrant brand color) — ~145,800 pixels

**Variations for more colors:**
- 4-color scheme: 60-20-10-10 split
- 5-color scheme: 60-20-10-5-5 split
- The dominant color ALWAYS stays at 60%

**Common mistakes:**
- Making the accent color cover 30%+ (it becomes overwhelming, not accenting)
- Using two equally vibrant colors at similar percentages (competition, not hierarchy)
- Making the dominant color too vibrant (it should be the most neutral/muted)

---

### 2.2 The HSB Color System for Designers

**Why HSB over RGB/HEX:** HSB describes color the way humans perceive it — "how colorful is it" (saturation) and "how light/dark" (brightness) — making it intuitive for making design decisions.

**The three dials:**
- **Hue (H):** 0-360 degrees on the color wheel. Red=0, Yellow=60, Green=120, Cyan=180, Blue=240, Magenta=300
- **Saturation (S):** 0-100%. 0=gray, 100=pure color
- **Brightness (B):** 0-100%. 0=black, 100=maximum brightness

#### Creating Color Variations (The Correct Way)

**Darker variation of a color:**
- Decrease Brightness (B) by 10-30%
- INCREASE Saturation (S) by 5-15% (counterintuitive but critical — this keeps the color rich, not muddy)
- Optional: Shift Hue toward the nearest of Red (0), Green (120), or Blue (240) by 5-15 degrees
- WRONG way: Just decreasing B alone makes colors look washed and dead

**Lighter variation of a color:**
- Increase Brightness (B) by 10-30%
- DECREASE Saturation (S) by 5-20% (lighter = less intense)
- Optional: Shift Hue toward the nearest of Cyan (180), Magenta (300), or Yellow (60) by 5-15 degrees

**Example — creating a blue palette from H:220 S:80 B:90:**
| Shade | H | S | B | Result |
|---|---|---|---|---|
| Lightest | 215 | 30 | 98 | Barely tinted white |
| Light | 217 | 50 | 95 | Soft sky blue |
| Base | 220 | 80 | 90 | Vibrant blue |
| Dark | 223 | 90 | 70 | Rich navy |
| Darkest | 226 | 95 | 45 | Deep midnight |

Notice: Hue shifts toward 240 (blue) as it darkens, toward 180 (cyan) as it lightens. Saturation goes up for dark, down for light. This creates a palette with *life* in it, not flat dead shades.

---

### 2.3 Advanced Color Techniques

#### Creating Depth with Color
- **Warm colors advance** (come toward the viewer): reds, oranges, yellows
- **Cool colors recede** (push away): blues, greens, purples
- Use this for layered compositions: warm foreground elements, cool background
- A warm CTA button on a cool background will visually "pop" forward

#### Saturation as Hierarchy (Selective Saturation)
- Desaturate everything except the focal point
- The eye is drawn to the most saturated area in any composition
- Technique: Set background elements to 20-40% saturation; focal point at 70-100%
- Even a 15% saturation difference creates noticeable visual pull
- Works like a spotlight — guides the eye without the viewer consciously noticing

#### The "Color Noise" Technique
Adding subtle hue variation to flat colors prevents the "dead digital" look:
- Instead of a flat #F5F0E8 cream background, add a subtle gradient with 2-5 degree hue shift
- Or apply a very light noise/grain layer with slight color variation
- Or use a mesh gradient with 3-4 slightly different hues of the same color
- This mimics how real surfaces (paper, fabric, paint) always have micro-variation

#### Duotone and Gradient Techniques
- **Duotone:** Map a gradient between two colors onto the luminosity values of an image
- **Gradient mesh:** A grid of control points, each with its own color, creating organic blends
- **Color stops:** The points where one color transitions to another — using 3-5 stops instead of 2 creates richer, more natural gradients
- Adding noise (1-3%) to gradients prevents visible banding on screens

---

### 2.4 Color Accessibility

#### WCAG Contrast Requirements

| Level | Normal Text (<18pt / <14pt bold) | Large Text (18pt+ / 14pt+ bold) | UI Components |
|---|---|---|---|
| AA (minimum) | 4.5:1 | 3:1 | 3:1 |
| AAA (enhanced) | 7:1 | 4.5:1 | 3:1 |

**Level AA is the legal standard** in most jurisdictions. AAA is aspirational.

**Common contrast ratios to memorize:**
- Pure black on white: 21:1 (maximum possible)
- Dark gray (#333) on white: ~12.6:1 (exceeds AAA)
- Medium gray (#767676) on white: 4.54:1 (barely meets AA)
- Light gray (#999) on white: 2.85:1 (FAILS AA)

**Brand color workaround:** If a brand color fails contrast ratios, create a "text-safe" darker variant specifically for text use, while keeping the original color for decorative/large elements.

**Practical tip:** Test every text-on-background combination with a contrast checker (WebAIM, Stark plugin, etc.). Never guess. Colors that "look fine" on a designer's calibrated monitor may fail for users on cheap laptops or in bright sunlight.

---

## 3. LAYOUT & COMPOSITION

### 3.1 Grid Systems for Social Media (1080x1350)

#### Column Grid for 1080px Width

| Grid Type | Columns | Column Width | Gutter | Margin | Best For |
|---|---|---|---|---|---|
| 4-column | 4 | 225px | 30px | 45px | Simple, bold layouts |
| 6-column | 6 | 140px | 24px | 48px | Medium complexity |
| 12-column | 12 | 65px | 18px | 45px | Maximum flexibility |

**Recommended for social media: 6-column grid** — enough flexibility for varied layouts without overcomplication. Each "unit" is 2 columns, giving you a natural 3-unit layout.

#### Modular Grid (cells instead of just columns)

Divide both width AND height into a grid of cells:
- For 1080x1350: A 6x8 modular grid gives you 48 cells (each ~165x155px after margins/gutters)
- Each cell becomes a placement zone for text, images, or decorative elements
- Cells can be merged (2x2, 3x1, etc.) for larger elements
- This provides both horizontal AND vertical alignment guides

#### Margin Ratios for Premium Feel

**The relationship between margin size and perceived value is direct:**
- Budget/discount feel: 20-30px margins (3-4% of width)
- Standard/professional: 40-60px margins (5-7% of width)
- Premium/luxury: 70-100px margins (8-12% of width)
- Ultra-luxury/editorial: 100-150px margins (12-18% of width)

For a 1080x1350 canvas targeting a warm, premium feel:
- **Outer margins: 60-80px** on all sides (effective content area: ~920-960 x 1190-1230)
- This "wastes" ~15% of the canvas — and that's exactly what makes it feel premium

#### Breaking the Grid (Intentionally)

**Rules for breaking rules:**
1. **Establish the grid first.** The viewer must subconsciously feel the grid before the break has impact
2. **Break it with ONE element** — a single image that bleeds past the margin, one text block that crosses a column boundary
3. **Break it for a reason** — to create a focal point, to add energy, to guide the eye
4. **Keep everything else on-grid** — the break only works because the rest is orderly
5. Common techniques: bleeding an image off-edge, overlapping a shape across columns, rotating one element while others stay aligned

---

### 3.2 Visual Hierarchy — The 5 Tools

Use these tools in combination. Using only one (like size) creates weak hierarchy.

| Tool | How It Works | Strength |
|---|---|---|
| **Size** | Bigger = more important. 2x size difference minimum | Very strong |
| **Weight/Contrast** | Bold vs light, dark vs light, saturated vs muted | Strong |
| **Position** | Top-left reads first (Western layouts). Top-center for social | Moderate |
| **Isolation** | White space around an element = importance | Strong |
| **Color** | Bright/warm accent against neutral background | Very strong |

**The professional trick:** Use 2-3 tools together for each hierarchy level:
- Level 1 (hero): Large size + Bold weight + Accent color
- Level 2 (subhead): Medium size + Medium weight + Secondary color
- Level 3 (body): Base size + Regular weight + Neutral color
- Level 4 (caption): Small size + Regular weight + Muted color

---

### 3.3 Eye-Flow Patterns

#### Z-Pattern (optimal for social media)
The eye follows a Z shape:
1. **Top-left** — Brand mark or hook text (first thing seen)
2. **Top-right** — Supporting info or secondary visual
3. **Diagonal** — sweep down to bottom-left
4. **Bottom-left** — secondary CTA or detail
5. **Bottom-right** — Primary CTA or logo

**For 1080x1350 (portrait social):**
- Place the hook/headline in the top 20-30%
- Place the hero image or key visual in the center 40%
- Place the CTA or takeaway in the bottom 20%
- This follows natural scroll behavior — hook first, content second, action last

#### Rule of Thirds Placement
Divide the canvas into a 3x3 grid. Place key elements at the 4 intersection points:
- For 1080x1350: intersections at (360, 450), (720, 450), (360, 900), (720, 900)
- **Most powerful placement:** top-left intersection (360, 450) — first seen
- **Second most powerful:** bottom-right intersection (720, 900) — natural eye resting point

#### Leading Lines
Use shapes, edges, or implied direction to point toward the focal point:
- A mascot character looking toward text (eye direction = line)
- A diagonal shape pointing from top-left toward center-right
- Converging lines (perspective) drawing the eye to a vanishing point

---

### 3.4 White Space Philosophy

#### Micro vs Macro White Space

**Micro white space** — the small gaps:
- Letter spacing within words
- Line height between text lines
- Padding inside buttons and cards
- Space between list items
- Gap between an icon and its label

**Macro white space** — the large empty areas:
- Margins around the content area
- Space between major sections
- Empty areas with no content at all
- The gap between headline and body text

#### White Space and Perceived Value

Research shows a direct correlation:
- **More white space = higher perceived quality and price point**
- **Less white space = discount, urgency, "busy" feeling**
- Apple, Hermès, Aesop — all use 40-60% white space
- Sale flyers, discount stores — use 10-15% white space

**For Bloom & Bare's warm, playful-but-premium positioning:**
- Target 30-40% white space per composition
- This balances approachability (not too sparse/cold) with quality (not too busy/cheap)
- Let the cream background (#F5F0E8) do heavy lifting — it IS the white space

#### Practical spacing ratios
- Element-to-element spacing: Use an 8px base unit grid (8, 16, 24, 32, 48, 64, 96)
- Related elements: 8-16px apart
- Grouped sections: 24-32px apart
- Major sections: 48-96px apart
- Edge margins: 60-80px for premium feel

---

## 4. TEXTURE & DEPTH

### 4.1 Grain and Noise

#### Why Grain Works
- Grain introduces **analog imperfection** into digital perfection — making designs feel human, tactile, and warm
- It unifies disparate elements (photo + vector + text all get the same grain layer, making them feel cohesive)
- It adds subtle depth to flat colors (a flat cream with grain looks like paper; without grain it looks like a screen)
- It reduces visible banding in gradients

#### Optimal Grain Levels

| Context | Grain Amount | Effect |
|---|---|---|
| Too much | >5% | Dirty, gritty, lo-fi (intentional aesthetic only) |
| Heavy stylistic | 3-5% | Noticeable texture, vintage/retro feel |
| **Sweet spot** | **1.5-2.5%** | **Visible on zoom, felt subconsciously at normal view** |
| Subtle/professional | 0.8-1.5% | Barely visible, adds warmth without obvious texture |
| Micro-texture | 0.3-0.8% | Nearly invisible, just enough to prevent "dead flat" |

**For Bloom & Bare (warm, playful, organic feel): 1.4-1.8% grain** — this matches the existing pipeline setting of 0.014-0.018.

#### Technical Implementation
- **Gaussian noise** (smooth, organic distribution) preferred over Uniform noise (harsh, digital-feeling)
- **Monochromatic grain** (luminance only) for warm/clean looks
- **Chromatic grain** (includes color variation) for film-like/vintage looks
- **ALWAYS apply grain as the last step** — after all color grading, compositing, and effects
- **Apply to a separate overlay layer** at 50% gray, with Overlay or Soft Light blend mode — this is non-destructive and adjustable

---

### 4.2 Shadow and Elevation

#### The Material Design Elevation System (adapted for graphic design)

| Level | Elevation | Shadow Blur | Shadow Opacity | Use Case |
|---|---|---|---|---|
| 0 | Flat on surface | 0px | 0% | Background, flat elements |
| 1 | Resting card | 2-4px | 8-12% | Cards, subtle lift |
| 2 | Raised element | 6-12px | 10-16% | Active cards, dropdowns |
| 3 | Floating element | 16-24px | 12-20% | Modals, popovers |
| 4 | Navigation/header | 24-36px | 15-24% | Fixed nav, overlays |

**Key principles:**
- Shadows should ALWAYS be offset downward (light comes from above)
- Use TWO shadow layers: a tight, darker shadow (2-4px blur, 10-15% opacity) + a broad, softer shadow (12-24px blur, 5-8% opacity). This creates much more realistic depth than a single shadow
- **Shadow color should NEVER be pure black.** Use a dark, slightly warm or cool tint (e.g., dark blue-gray for cool; dark brown for warm). This integrates shadows with the design's color palette
- For warm brands like Bloom & Bare: shadow color could be #2A2520 at 12-18% opacity

#### Inner Shadows for Depth
- Inner shadows make elements feel "pressed in" or inset
- Use for: input fields, sunken panels, letterpress text effects
- Keep subtle: 1-2px offset, 2-4px blur, 5-10% opacity

---

### 4.3 Texture Overlays

#### Paper Texture
- Creates warmth, tactility, and an organic quality
- Best applied as an Overlay or Soft Light layer at 5-15% opacity
- Works particularly well with cream/warm backgrounds
- Source high-resolution paper scans (300+ DPI) so grain structure is visible

#### Halftone Patterns
- Dots arranged in a grid that vary in size to simulate gradients
- Creates a retro/screen-print aesthetic
- Common dot sizes: 4-8px for subtle, 10-20px for bold retro feel
- Apply as Multiply layer at 10-30% opacity for a subtle tint

#### Watercolor Wash
- Soft, organic bleeding edges
- Works well for backgrounds behind text (when very subtle)
- Apply at 5-15% opacity as a Multiply or Soft Light layer
- Best when limited to 2-3 colors with organic blending

#### Golden Rule for Texture Application
**If you can see the texture before the content, it's too much.** Texture should be felt, not seen. It should support the design's mood without competing for attention.

---

## 5. PROFESSIONAL FINISHING

### 5.1 Color Grading for Consistency

#### The "Instagram Warm" Look (deconstructed)
1. **Lifted shadows** — Black point raised to ~5-15% (shadows become dark gray, not black). Creates a faded, dreamy quality
2. **Warm highlights** — Shift highlight temperature +5-10 toward yellow/orange
3. **Slight desaturation** — Drop global saturation 5-15% for a muted, sophisticated feel
4. **Fade the blacks** — Use a curves adjustment to lift the bottom of the curve (no pure black in the image)
5. **Optional: add warmth to midtones** — A subtle orange/amber tint in the midtones

#### Maintaining Brand Consistency Across Posts
- Create a master filter/LUT that encodes your brand's color treatment
- Apply the SAME filter to every post, then adjust intensity (never start from scratch)
- Document your exact settings (curve points, saturation values, hue shifts)
- For Python/Pillow pipeline: encode the filter as a function with locked parameters

#### LUT (Look-Up Table) Workflow
- A LUT is a saved color transformation — input color X always maps to output color Y
- Create ONE master LUT for the brand, apply to all imagery
- Adjust intensity per image (0.7-1.0 strength) rather than creating new grades
- Organize LUTs by category: "brand master," "seasonal warm," "seasonal cool"
- For batch processing: apply LUT programmatically to all images in a folder

---

### 5.2 Sharpening and Clarity

#### Two-Step Approach
1. **Clarity first** — Enhances midtone contrast, making textures and details "pop." Applied globally. Adds dimension without changing edges. +10 to +25 clarity for social media
2. **Sharpening second** — Enhances edge definition. Apply selectively (not to smooth areas like skin or gradients)

#### Sharpening for Social Media
- **Amount:** 80-120% (Photoshop Unsharp Mask)
- **Radius:** 0.8-1.2px for 1080px images
- **Threshold:** 2-4 levels (prevents sharpening noise in smooth areas)
- Alternative: High Pass filter at 1-2px radius on Overlay layer at 30-60% opacity

**Critical rule:** Instagram compresses and resizes everything. Slightly over-sharpen (by ~10-15%) to compensate for compression softening. An image that looks slightly crispy on your monitor will look perfect after Instagram processing.

---

### 5.3 Export Optimization

#### Format Selection

| Format | Best For | Quality | File Size |
|---|---|---|---|
| PNG-24 | Text overlays, logos, graphics, transparency | Lossless | Large (2-8MB) |
| JPEG 85-92% | Photographs, complex imagery | Near-lossless | Medium (300KB-2MB) |
| JPEG 75-80% | Web uploads (will be recompressed) | Good | Small (100-500KB) |

**For Instagram specifically:**
- Export as JPEG at 85-92% quality (Instagram recompresses everything to ~70-75% JPEG)
- Starting at 85%+ gives Instagram's compressor more data to work with
- OR export as PNG if text-heavy — Instagram's PNG-to-JPEG conversion handles text edges better than double JPEG compression

#### Color Profile
- **ALWAYS export in sRGB** — this is the only color space screens and social platforms display correctly
- If working in Adobe RGB or P3: convert to sRGB before export
- Instagram slightly desaturates during compression — boost saturation by 5-10% before export to compensate

#### Resolution and Dimensions
- Export at EXACTLY the platform's native resolution (1080x1350 for IG feed, 1080x1920 for stories)
- Do NOT export larger and let the platform downscale — their scaling algorithms are mediocre
- Do NOT export smaller — upscaling destroys quality

#### File Size Sweet Spot
- Instagram maximum: 8MB per image
- **Optimal range: 500KB - 2MB** — large enough for quality, small enough to avoid aggressive recompression
- Files under 100KB will look pixelated
- Files over 4MB may trigger extra compression

---

## 6. QUICK REFERENCE: NUMBERS TO MEMORIZE

### Typography
- Display tracking: -10 to -30
- All-caps tracking: +20 to +75
- Body line-height: 1.4 - 1.6
- Headline line-height: 1.0 - 1.2
- Paragraph spacing: line-height x 0.75
- Max typefaces per design: 2-3
- Hierarchy levels: 4-6
- Major Third scale ratio: 1.25x
- Golden Ratio scale: 1.618x

### Color
- 60-30-10 split for color application
- WCAG AA contrast: 4.5:1 (normal text), 3:1 (large text)
- WCAG AAA contrast: 7:1 (normal text), 4.5:1 (large text)
- Darker HSB variation: B down 10-30%, S up 5-15%
- Lighter HSB variation: B up 10-30%, S down 5-20%
- Hue shift for interest: 5-25 degrees

### Layout
- Premium margins: 8-12% of canvas width (60-80px on 1080px)
- White space target (premium-playful): 30-40% of canvas
- 8px spacing grid: 8, 16, 24, 32, 48, 64, 96
- Rule of thirds intersections on 1080x1350: (360,450), (720,450), (360,900), (720,900)

### Texture & Finishing
- Grain sweet spot: 1.5-2.5% (0.015-0.025)
- Shadow color: never pure black — use tinted dark (12-18% opacity)
- Clarity boost: +10 to +25
- Sharpening: 80-120%, radius 0.8-1.2px
- Export JPEG quality: 85-92%
- Pre-upload saturation bump: +5-10%
- Target file size: 500KB - 2MB

---

## Sources

### Typography
- [The Art of Optical Kerning](https://www.numberanalytics.com/blog/optical-kerning-graphic-design-typography)
- [Complete Font Kerning Guide](https://www.whatfontis.com/blog/the-complete-font-kerning-guide-what-is-kerning-and-how-to-master-typography-spacing/)
- [Establishing a Type Scale](https://cieden.com/book/sub-atomic/typography/establishing-a-type-scale)
- [Different Types of Typographic Scales](https://cieden.com/book/sub-atomic/typography/different-type-scale-types)
- [More Meaningful Typography - A List Apart](https://alistapart.com/article/more-meaningful-typography/)
- [Typescale Generator](https://typescale.com/)
- [Tracking Your Type - Fonts.com](https://www.myfonts.com/pages/fontscom-learning-fontology-level-2-text-typography-tracking-your-type)
- [What is Tracking in Typography](https://dailycreativeco.com/what-is-tracking-in-typography/)
- [Tracking Typography Guide - InDesign Skills](https://www.indesignskills.com/tutorials/letter-spacing-tracking-typography/)
- [Best Sans and Serif Font Pairings 2025 - Pangram Pangram](https://pangrampangram.com/blogs/journal/best-font-pairings-2025)
- [Three Secrets to Font Pairing - Adobe](https://adobe.design/stories/leading-design/three-secrets-to-font-pairing)
- [Font Pairing Ultimate Guide](https://pikguratype.com/2025/04/04/font-pairing-ultimate-guide-rule-strategy-and-practices/)
- [Mixing Fonts - Butterick's Practical Typography](https://practicaltypography.com/mixing-fonts.html)
- [Best Practices of Combining Typefaces - Smashing Magazine](https://www.smashingmagazine.com/2010/11/best-practices-of-combining-typefaces/)
- [Line Spacing - Butterick's Practical Typography](https://practicaltypography.com/line-spacing.html)
- [Letter Spacing Guide - Inkbot Design](https://inkbotdesign.com/letter-spacing-guide/)
- [Tips for Typographic Hero vs Hero Imagery](https://www.telerik.com/blogs/tips-using-typographic-hero-imagery)
- [Do You Need a Hero Image - Design Shack](https://designshack.net/articles/graphics/do-you-need-a-hero-image/)
- [6 Typography Secrets for Hero Images - Creative Market](https://creativemarket.com/blog/6-typography-secrets-that-will-make-your-hero-images-explosive)

### Color
- [60-30-10 Rule - UX Planet](https://uxplanet.org/the-60-30-10-rule-a-foolproof-way-to-choose-colors-for-your-ui-design-d15625e56d25)
- [60-30-10 Rule - Wix](https://www.wix.com/wixel/resources/60-30-10-color-rule)
- [How to Apply a Color Palette - The Futur](https://www.thefutur.com/content/how-to-apply-a-color-palette-to-your-design)
- [HSB Color System Practitioner's Primer - Learn UI Design](https://www.learnui.design/blog/the-hsb-color-system-practicioners-primer.html)
- [HSB Color Mode - TourBox](https://www.tourboxtech.com/en/news/hsb-color.html)
- [Crafting Color Palette with HSB Manipulation](https://medium.com/@solomoneyitene/crafting-your-unique-color-palette-a-designers-guide-to-hsb-manipulation-ead6d9e3cc70)
- [Color in UI Design - Learn UI Design](https://www.learnui.design/blog/color-in-ui-design-a-practical-framework.html)
- [WCAG Contrast and Color Accessibility - WebAIM](https://webaim.org/articles/contrast/)
- [WCAG Contrast Minimum - W3C](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Warm vs Cool Colors - Kittl](https://www.kittl.com/blogs/warm-and-cool-colors/)
- [Psychology of Warm vs Cool Colors - BrandCrowd](https://www.brandcrowd.com/blog/the-psychology-of-warm-vs-cool-colors)
- [Mastering Desaturation in Color Theory](https://www.numberanalytics.com/blog/ultimate-guide-desaturation-color-theory)
- [Selective Saturation - Nathan Cool Photo](https://www.nathancoolphoto.com/blog/2013/3/selective-saturation)
- [Gradients in Design - Shutterstock](https://www.shutterstock.com/blog/complete-guide-gradients-designs)
- [Mesh Gradient Generator - Learn UI Design](https://www.learnui.design/tools/mesh-gradient-generator.html)

### Layout & Composition
- [Grid Systems in Social Media Design](https://www.synerji.in/post/how-can-i-use-grid-systems-in-social-media-design-for-better-alignment)
- [Layout Design Grid Types - Visme](https://visme.co/blog/layout-design/)
- [Modular Grids Guide](https://www.tiny.cloud/blog/a-guide-to-grids-blog-design/)
- [Visual Hierarchy 101 for Social Posts](https://usevisuals.com/blog/visual-hierarchy-for-social-media-posts)
- [Visual Hierarchy - MasterClass](https://www.masterclass.com/articles/visual-hierarchy)
- [12 Visual Hierarchy Principles - Visme](https://visme.co/blog/visual-hierarchy/)
- [Rule of Thirds in Design - Design Wizard](https://designwizard.com/blog/how-is-the-rule-of-thirds-used-in-design/)
- [Power of White Space - IxDF](https://ixdf.org/literature/article/the-power-of-white-space)
- [White Space Elevating Brand to Premium - Medium](https://medium.com/@mcfarlanematthias/the-power-of-white-space-elevating-your-brand-to-premium-status-c8482e7f2327)
- [White Space in Graphic Design - Zeka](https://www.zekagraphic.com/white-space-in-graphic-design/)
- [Breaking the Grid - Secret Stache](https://www.secretstache.com/blog/how-to-effectively-break-out-of-the-grid/)
- [Breaking the Grid - Design Shack](https://designshack.net/articles/layouts/breaking-the-grid/)
- [Squint Test - Polypane](https://polypane.app/blog/debug-your-visual-hierarchy-with-the-squint-test/)
- [Squint Test - NN/g](https://www.nngroup.com/videos/squint-test/)
- [Spacing, Grids, and Layouts](https://www.designsystems.com/space-grids-and-layouts/)

### Texture & Depth
- [Film Grain Simulation - Medialoot](https://medialoot.com/blog/how-to-simulate-film-grain/)
- [Film Grain Rendering - ACM](https://dl.acm.org/doi/10.1145/3592127)
- [Grain Noise Photoshop Background - RetroSupply](https://www.retrosupply.co/blogs/tutorials/lo-fi-grain-and-noise-photoshop-background-demo)
- [Elevation and Shadows - Material Design](https://m1.material.io/material-design/elevation-shadows.html)
- [Designing Beautiful Shadows in CSS - Josh Comeau](https://www.joshwcomeau.com/css/designing-shadows/)
- [Elevation Design Patterns](https://designsystems.surf/articles/depth-with-purpose-how-elevation-adds-realism-and-hierarchy)
- [Halftone Overlay Guide - Playbook](https://www.playbook.com/blog/how-to-use-halftone-overlay-2/)

### Finishing & Export
- [Color Grading for Brand Consistency - Graphrs](https://www.graphrs.com/blog/color-grading-for-brand-consistency-in-2025---pro-guide)
- [LUT Workflow - Noam Kroll](https://noamkroll.com/how-to-apply-color-grading-luts-professionally-my-workflow-explained/)
- [3D LUTs for Color Grading - ProEdu](https://proedu.com/blogs/photoshop-skills/mastering-the-use-of-3d-luts-for-professional-color-grading-essential-techniques-for-cinematic-visuals)
- [Instagram Photo Quality Optimization](https://socialrails.com/blog/instagram-photo-quality-optimization-guide)
- [PNG vs JPG for Social Media](https://socialrails.com/blog/png-vs-jpg-social-media-guide)
- [Best Export Settings for Facebook and Instagram - Fstoppers](https://fstoppers.com/education/best-export-settings-photos-facebook-and-instagram-532621)
- [Advanced Retouching Techniques - ProEdu](https://proedu.com/blogs/photoshop-skills/advanced-retouching-techniques-for-commercial-photography-elevating-product-imagery)
