# Professional Design Production Workflows — Execution Guide
*Deep research compilation. 10 March 2026.*

---

## TABLE OF CONTENTS

1. [Social Media Design Production at Scale](#1-social-media-design-production-at-scale)
2. [Poster & Print Design Workflow](#2-poster--print-design-workflow)
3. [Brand Campaign Production](#3-brand-campaign-production)
4. [Typography Production Techniques](#4-typography-production-techniques)
5. [Color Production Techniques](#5-color-production-techniques)
6. [Layout & Composition Techniques](#6-layout--composition-techniques)
7. [Photo Integration Techniques](#7-photo-integration-techniques)
8. [Design File Organization & Production Standards](#8-design-file-organization--production-standards)
9. [Programmatic Design Production (Python/Pillow)](#9-programmatic-design-production-pythonpillow)

---

## 1. SOCIAL MEDIA DESIGN PRODUCTION AT SCALE

### 1.1 How World-Class Brands Actually Produce Content

**Nike's Model:**
- Uses a hybrid in-house + agency model. Social media management is now in-house (Portland HQ), while campaign creative comes from agency partners (Wieden & Kennedy, AKQA, R/GA)
- Agency services cover: art direction, motion graphics, campaign strategy, social media strategy, campaign production, social management, media planning, analysis and reporting
- Key insight: Nike moved social management in-house for speed and brand control, but keeps campaign production with agencies for creative firepower

**Airbnb's Model:**
- Heavy reliance on user-generated content (UGC) — uses hashtags and location tags to make content shareable
- Produces stories, listicles, blog posts, and email marketing covering travel planning and hosting
- Has expanded into branded entertainment (docuseries "Home" for Apple TV)

**The Common Pattern:**
All major brands separate *template creation* (high-skill, done once) from *template population* (lower-skill, done repeatedly). The template is the product; individual posts are instances.

### 1.2 Batch Production Workflow (The 300% Output Method)

The most effective production method is **strict batching by task type**, not by post:

```
WRONG:  Design Post 1 → Write Post 1 → Design Post 2 → Write Post 2
RIGHT:  Write ALL captions → Design ALL graphics → Schedule ALL posts
```

**Why:** Context switching between different tasks kills productivity. A streamlined batch workflow can increase output by 300% while improving quality by 67%.

**The Professional Batch Schedule:**

| Day | Task | Output |
|-----|------|--------|
| Monday | Content calendar + briefs for month | 30 briefs |
| Tuesday-Wednesday | Batch write ALL captions | 30 captions |
| Thursday-Friday | Batch design ALL graphics | 30 graphics |
| Following Monday | Review + QA pass | 30 approved posts |
| Tuesday | Schedule 60-70% of posts | ~20 scheduled |
| Ongoing | Reserve 30-40% for real-time/reactive | ~10 slots open |

### 1.3 Template Systems for Consistent Quality

**The Design Token Approach (from Figma/design system methodology):**

Design tokens are the atomic values that define your brand's visual language. They operate at three levels:

1. **Primitive tokens** (global) — raw values
   ```
   color-yellow: #F0D637
   font-size-xl: 64px
   spacing-md: 24px
   radius-lg: 20px
   ```

2. **Semantic tokens** (contextual) — what values mean
   ```
   color-primary: {color-yellow}
   heading-size: {font-size-xl}
   card-padding: {spacing-md}
   card-radius: {radius-lg}
   ```

3. **Component tokens** (specific) — where values apply
   ```
   schedule-card-bg: {color-primary}
   schedule-card-heading: {heading-size}
   schedule-card-padding: {card-padding}
   ```

**Why this matters for batch production:**
A token-based system lets you change themes, seasonal palettes, or brand refinements by updating tokens at one level, and all templates update automatically. This is the foundation for producing 30+ on-brand posts per month without drift.

### 1.4 The Content Calendar to Published Post Pipeline

```
PHASE 1: STRATEGY (Week 1 of month)
  Content calendar → Content pillars → Post briefs
  Output: 30 post briefs with type, topic, copy direction, CTA

PHASE 2: COPYWRITING (Week 1-2)
  Post briefs → Draft captions → Review → Approved copy
  Output: 30 approved captions with hashtags

PHASE 3: DESIGN PRODUCTION (Week 2-3)
  Approved copy → Template selection → Asset assembly → Render
  Output: 30 designed posts at final resolution

PHASE 4: QA & REVIEW (Week 3)
  Rendered posts → Brand check → Copy check → Accessibility check
  Output: 30 approved, publish-ready posts

PHASE 5: SCHEDULING (Week 3-4)
  Approved posts → Platform scheduling → Go live
  Output: 20 scheduled + 10 slots reserved for reactive content

PHASE 6: ANALYSIS (End of month)
  Performance data → Insights → Feed back into Phase 1
  Output: Updated content strategy for next month
```

---

## 2. POSTER & PRINT DESIGN WORKFLOW

### 2.1 Pre-Press Production Techniques

Pre-press is the process of preparing digital files for final output. Every file needs verification, correction, and optimization before production. Missing something at this stage means the final product suffers.

**The Pre-Press Checklist:**

1. **Resolution verification** — 300 DPI for print, but even for digital (72 DPI), think in terms of print quality: sharp edges, clean curves, no compression artifacts
2. **Color mode** — CMYK for print, RGB for digital. Convert at the end of the workflow, not the beginning
3. **Bleed and trim** — 3mm bleed on all sides for print. For digital, equivalent is safe zones (no critical content within 5% of edges)
4. **Font embedding/outlining** — All fonts must be embedded or converted to outlines
5. **Image enhancement** — Balance improvement with authenticity. Over-processing looks fake; under-processing leaves obvious flaws
6. **Proofing** — Soft proof on calibrated monitor, then physical proof for print

### 2.2 "Print Quality" Thinking for Digital

Even at 72 DPI screen resolution, professional digital work applies print-quality standards:

- **Sharp vector elements** — Logos, icons, and geometric shapes should be vector or rendered at 2x-3x resolution then downsampled
- **Clean anti-aliasing** — No jagged edges on curves or diagonals
- **Consistent stroke weights** — Thin lines must be at least 1px at final resolution to avoid subpixel rendering issues
- **Color banding prevention** — Gradients should be rendered at higher bit depth (16-bit) then converted to 8-bit
- **Export sharpening** — A final subtle sharpen pass (0.3px radius, 30% strength) compensates for screen softening

### 2.3 Professional Retouching: Frequency Separation

Frequency separation splits an image into two layers:

- **High frequency layer** — Texture, pores, fine details
- **Low frequency layer** — Color, tone, large shapes

This allows independent editing:
- Smooth skin tone without destroying texture (work on low frequency)
- Remove blemishes without affecting color (work on high frequency)
- Common in beauty, portraiture, and fashion photography

**Photoshop Method:**
1. Duplicate background twice
2. Blur bottom copy (Gaussian Blur, 4-8px depending on resolution)
3. Top copy: Image > Apply Image > set to bottom layer, Blending: Subtract, Scale: 2, Offset: 128
4. Set top layer blend mode to Linear Light
5. Retouch: Clone Stamp on high frequency for texture, Brush on low frequency for tone

### 2.4 Color Management: sRGB vs Display P3

| Aspect | sRGB | Adobe RGB | Display P3 |
|--------|------|-----------|------------|
| Gamut size | Smallest | 35% larger than sRGB | 25% larger than sRGB |
| Best for | Web, social media | Print, photography | Apple devices, HDR |
| Browser support | Universal | Limited | Growing |
| Social media | Standard | Converts to sRGB on upload | Converts to sRGB on most platforms |

**Practical recommendation:**
- Work in sRGB for social media content. It is the universal standard and all platforms convert to it anyway
- Use Display P3 only if targeting Apple devices specifically and your pipeline preserves the color profile
- For print crossover work, use Adobe RGB as your working space and convert to sRGB for digital delivery

**Consistency across outputs:**
- Calibrate your monitor (hardware calibration preferred)
- Embed ICC profiles in all exported files
- Test on multiple devices — a $200 phone and a $3000 MacBook will show different colors
- Use relative colorimetric rendering intent when converting between color spaces

---

## 3. BRAND CAMPAIGN PRODUCTION

### 3.1 Multi-Format Campaign Production

The professional approach: **one master concept, many format adaptations.**

**The Master-to-Adaptation Pipeline:**

```
MASTER CREATIVE (conceptual)
  ├── Hero visual (highest quality, most detail)
  ├── Key messaging framework
  ├── Color palette + typography rules
  └── Asset library (photos, illustrations, logos)
      │
      ├── FEED POSTS (1080x1350, 1080x1080)
      │     Adaptation: Full messaging, detailed layout
      │
      ├── STORIES (1080x1920)
      │     Adaptation: Simplified, larger text, CTA-focused
      │
      ├── REELS COVER (1080x1350)
      │     Adaptation: Thumbnail-optimized, bold single message
      │
      ├── WEB BANNER (various)
      │     Adaptation: Responsive, minimal text
      │
      └── PRINT (A4, A3, poster)
            Adaptation: Full resolution, CMYK, bleed
```

**Key principle:** Adaptation is NOT resizing. Each format has different viewing conditions, attention spans, and information hierarchy requirements. A feed post can carry 3-4 information points; a story should carry 1.

### 3.2 Adaptive Design Systems

Professional multi-format tools (Brandeploy, Celtra, Figma) use **composition variants** — the same template with format-specific rules:

- **Anchor points** — Elements that maintain position relative to format edges
- **Reflow rules** — How text and images rearrange when aspect ratio changes
- **Breakpoints** — At what size thresholds do layouts fundamentally change (not just scale)
- **Priority stacking** — Which elements are essential (logo, headline) vs. which can be removed in smaller formats

### 3.3 Asset Management and Version Control

**Naming Convention:**
```
[brand]_[campaign]_[format]_[variant]_[version]_[date].[ext]
bb_summer2026_feed_schedule_v2_20260310.png
bb_summer2026_story_schedule_v2_20260310.png
```

**Folder Structure:**
```
campaign-name/
  ├── 00-brief/           # Strategy docs, briefs
  ├── 01-assets/          # Source photos, illustrations
  ├── 02-working/         # In-progress design files
  ├── 03-review/          # Files pending approval
  ├── 04-approved/        # Final approved files
  │     ├── feed/
  │     ├── stories/
  │     ├── reels/
  │     └── print/
  └── 05-archive/         # Previous versions
```

**Version control rules:**
- Never overwrite — always increment version numbers
- Brand guideline updates flow into ALL templates — always work from current versions
- Template updates propagate downstream; never modify an instance when the template itself needs updating

---

## 4. TYPOGRAPHY PRODUCTION TECHNIQUES

### 4.1 Professional Kerning and Tracking

**The Order of Operations:**
1. Set tracking (letter-spacing) for the entire block first
2. Then adjust kerning for individual problem pairs
3. Final pass: visual check at actual output size

**Tracking Rules of Thumb:**
| Text Type | Tracking | Reason |
|-----------|----------|--------|
| Body text (12-16px) | 0 to +10 | Default metrics are optimized for this range |
| Large headlines (40px+) | -10 to -30 | Large text looks too loose at default spacing |
| All caps | +50 to +150 | Capitals need breathing room without lowercase descenders/ascenders |
| Small caps / labels | +30 to +80 | Improves legibility at small sizes |
| Display type (80px+) | Hand-kern every pair | At this size, every imperfection is visible |

**Hand Kerning Method:**
You MUST hand-kern all headlines larger than ~18pt. This is the only way to achieve professional results.
1. Squint at the text — blurring removes letter recognition and reveals spacing imbalances
2. Work from the center of the word outward
3. Problem pairs to always check: AV, AW, AT, AY, LT, LY, To, Tr, Ta, Ty, VA, WA, YA, FA, PA
4. The goal is optically even spacing, not mathematically equal distances

### 4.2 Optical vs Mathematical Alignment

**Mathematical alignment** places elements at exact pixel coordinates. **Optical alignment** adjusts positions so elements *appear* aligned to the human eye.

**Where optical alignment matters:**

- **Text next to icons** — Text baseline should align with the visual center of the icon, not its bounding box center. Typically shift text up 1-2px
- **Rounded shapes at edges** — A circle must extend ~4% beyond the margin to look aligned with a square at the same margin. This is because curves "pull in" visually
- **Triangles and pointed shapes** — Must overshoot alignment by 5-8% to look flush
- **Hanging punctuation** — Quotation marks, bullets, and hyphens should hang outside the text margin so the actual letter edges stay aligned
- **Optical margin alignment** in typesetting pushes punctuation and letter serifs slightly outside the text block for a cleaner edge

### 4.3 Font Pairing Like a Professional

**The Contrast Principle:**
Good font pairs are DIFFERENT enough to create clear hierarchy, but share 1-2 subtle attributes that create visual harmony.

**Proven Pairing Strategies:**

| Strategy | Example | Why It Works |
|----------|---------|-------------|
| Serif heading + Sans body | Playfair Display + Source Sans Pro | Maximum contrast, clear hierarchy |
| Display + Geometric sans | DX Lactos + Mabry Pro (Bloom & Bare) | Playful display with clean, readable body |
| Same family, different weights | Mabry Pro Bold + Mabry Pro Regular | Guaranteed harmony, hierarchy from weight alone |
| Contrast in x-height | A tall x-height display + a compact body | Creates visual interest from proportional difference |
| Historical pairing | Fonts from the same era/movement | Shared design DNA creates subliminal harmony |

**What to avoid:**
- Two decorative/display fonts together (visual chaos)
- Fonts that are *almost* the same but slightly different (looks like a mistake)
- More than 2-3 fonts in a single piece (unless you are a trained typographer)

### 4.4 Variable Fonts and Responsive Typography

Variable fonts contain multiple styles in a single file, with continuous axes of variation:

**Key axes:**
- **wght** (weight) — From thin to black, continuously
- **wdth** (width) — From condensed to expanded
- **opsz** (optical size) — Adjusts stroke contrast and spacing for different sizes
- **ital** (italic) — From upright to italic
- **slnt** (slant) — Oblique angle

**Professional applications:**
- Fluidly adjust weight/width for different screen sizes without font swapping
- Optical sizing: at small sizes, automatically thicken strokes and open counters for legibility; at large sizes, refine and add contrast
- Condense width slightly for mobile to fit more text without reducing font size
- Single file replaces 6-12 static font files, improving load performance

### 4.5 Text on Curved Paths and in Shapes

**Curved text best practices:**
- Maintain consistent baseline spacing along the curve
- Adjust letter-spacing (increase) on outer curves, decrease on inner curves
- Never curve body text — only headlines, labels, badges
- The radius of the curve should be at least 3x the cap height of the text
- On circular paths: limit to 7-10 characters per quarter arc for readability

### 4.6 Type as Image — When Typography IS the Design

Treating letterforms as visual objects rather than carriers of meaning:

**Techniques:**
- **Letters as containers** — Fill letterforms with photography, texture, or pattern (clipping mask)
- **Letters as architecture** — Scale individual letters to fill the frame, using negative space within and around them
- **Kinetic typography** — Letters in motion, breaking apart, reforming (for video/animation)
- **Texture mapping** — Apply 3D textures (glossy, matte, metallic) to type
- **Fragmented type** — Partially obscure letters with images or other elements; let the viewer's brain complete the form
- **Color blocking** — Each letter in a different color from the brand palette (effective for playful brands like Bloom & Bare)

**Display type categories:**
- Type as FORM — Letterforms are shapes
- Type as PATTERN — Repeated type creates visual texture
- Type as TEXTURE/SURFACE — Type takes on material qualities
- Type as IMAGE — Type depicts or contains imagery

### 4.7 Drop Caps, Pull Quotes, Display Typography

**Drop caps:**
- Standard drop cap: 2-4 lines tall, aligned with body text baseline
- Raised cap: sits above the text block (good for tight columns)
- Graphic drop cap: decorated, illustrated, or placed in a colored shape
- Always kern the first word after the drop cap manually — default spacing will be too loose

**Pull quotes:**
- Extract the most compelling phrase, not the most important information
- Typographic treatment should differ dramatically from body text (larger, different font, different color)
- Position to break up long text blocks or anchor a layout
- Credit line in smaller, lighter weight underneath

---

## 5. COLOR PRODUCTION TECHNIQUES

### 5.1 Professional Color Grading for Social Media

**The Layer-Based Grading Stack:**

```
TOP     → Final adjustment (Curves/Levels — micro-contrast)
        → Color grade (Color Lookup Table or manual Curves per channel)
        → Tone mapping (Brightness/Contrast or Exposure)
        → Saturation control (Hue/Saturation — selective, not global)
BOTTOM  → Original image
```

**Grading for social media specifically:**
- Slightly boost contrast — phone screens in daylight wash out low-contrast images
- Warm shadows slightly (add 3-5% orange/yellow to shadow tones) — creates a "premium" feel
- Desaturate slightly (5-15%) then selectively boost 1-2 key colors — creates a cohesive look without looking oversaturated
- Add a subtle S-curve to the luminosity channel for "pop" without color shifts

### 5.2 Creating Depth with Color (Atmospheric Perspective)

**Atmospheric perspective** in design: distant elements are cooler, lighter, and less saturated. Near elements are warmer, darker, and more saturated.

**Application in flat design:**
- Background layers: cooler, lighter versions of brand colors
- Middle ground: full-strength brand colors
- Foreground elements: slightly darker, more saturated
- Text on top: full contrast (black or white)

**Layered opacity approach:**
```
Layer 1 (back):  Color at 20% opacity → very light, atmospheric
Layer 2 (mid):   Color at 60% opacity → medium presence
Layer 3 (front): Color at 100% opacity → full impact
```

This creates automatic visual depth hierarchy without relying on drop shadows or gradients.

### 5.3 Duotone and Tritone Techniques

**Duotone:** A 2-color image where the entire tonal range is mapped between two chosen colors.

**Duotone creation (programmatic approach for Pillow):**
1. Convert image to grayscale
2. Create a gradient map from Color A (shadows) to Color B (highlights)
3. Map each pixel's luminosity value to the corresponding point on the gradient

**Tritone:** Adds a third color for midtones, giving more tonal control.
- Shadow color → Midtone color → Highlight color
- Example: Deep navy shadows → Coral midtones → Cream highlights

**Social media application:**
- Duotone simplifies complex images into brand-color imagery
- Removes the "stock photo" look instantly
- Creates visual cohesion across a feed even with diverse source imagery
- Effective for "quote over photo" posts — the duotone reduces photo to texture while maintaining visual interest

### 5.4 Color Accessibility (WCAG Contrast Ratios)

**WCAG 2.1 Minimum Requirements:**

| Element | AA Minimum | AAA Minimum |
|---------|-----------|-------------|
| Normal text (<18px / <14px bold) | 4.5:1 | 7:1 |
| Large text (>=18px / >=14px bold) | 3:1 | 4.5:1 |
| UI components and graphics | 3:1 | 3:1 |
| Logos and decorative text | Exempt | Exempt |

**Practical rules for social media design:**
- Body text on colored backgrounds: ALWAYS check contrast ratio
- White text on brand colors: test every color. Many brand yellows and light greens fail
- If a brand color fails contrast: darken it for text backgrounds, or use it only for decorative elements
- Tools: WebAIM Contrast Checker, Stark (Figma plugin), or programmatic check with relative luminance formula

**The relative luminance formula:**
```
L = 0.2126 * R + 0.7152 * G + 0.0722 * B
(where R, G, B are linearized from sRGB)

Contrast ratio = (L_lighter + 0.05) / (L_darker + 0.05)
```

**Bloom & Bare specific notes:**
- Yellow #F0D637 on cream #F5F0E8 = FAILS (approximately 1.3:1). Never use yellow text on cream.
- Black #1A1A1A on cream #F5F0E8 = PASSES AA and AAA (approximately 14.5:1)
- Black #1A1A1A on yellow #F0D637 = PASSES AA (approximately 12:1)
- White #FFFFFF on coral #F09B8B = borderline. Test carefully, may need darker coral for text backgrounds.

### 5.5 Seasonal Color Palettes

**How brands shift colors by season without losing brand identity:**

The key principle: **secondary palettes** extend the core palette, they don't replace it.

| Season | Strategy | Example Shift |
|--------|----------|---------------|
| Spring | Lighter, warmer tints of brand colors | Core blue → sky blue; add floral accents |
| Summer | Brighter, more saturated | Boost saturation 15-20%; add warm metallics |
| Fall | Warmer, muted | Add amber/rust tints; reduce saturation 10-15% |
| Winter | Cooler, higher contrast | Add silver/ice blue; increase contrast |

**Implementation method:**
- Keep primary brand colors (logo, key identifiers) unchanged
- Shift background colors, decorative elements, and accent colors seasonally
- Create a seasonal token override that sits on top of your base design tokens
- Limit seasonal changes to 2-3 elements max — too much change breaks brand recognition

---

## 6. LAYOUT & COMPOSITION TECHNIQUES

### 6.1 Rule of Thirds vs Golden Ratio in Practice

**Rule of Thirds:**
Divide canvas into a 3x3 grid. Place key elements at intersections or along lines.

- **For social media:** Place the primary subject or headline at the top-left or top-right intersection (first things seen in a scroll)
- **For text-heavy posts:** Align text blocks to the left third or right third, leave the other two-thirds for imagery
- **Quick check:** If your design looks balanced with the grid overlay, it works

**Golden Ratio (1:1.618):**
More subtle, creates a natural focal spiral. Professional application:

- **Golden spiral** — Place the focal point where the spiral converges (roughly the lower-right intersection of a rule-of-thirds grid, but offset)
- **Golden sections** — Divide your 1080x1350 canvas at 1350 / 1.618 = 834px from top. The headline zone is 0-834px; supporting info is 834-1350px
- **In practice:** The golden ratio creates more dynamic, less "templated" feeling compositions than strict thirds

### 6.2 Z-Pattern and F-Pattern Layouts

**Z-Pattern** (for graphic/image-heavy posts — most social media):
```
START ──────────► (Logo, branding)
                         │
                         │ (eye travels diagonally)
                         │
◄──────────────── (CTA, secondary info)
FINISH
```
Place in this order: logo/brand (top-left) → key visual (top-right) → supporting info (bottom-left) → CTA (bottom-right).

**F-Pattern** (for text-heavy posts — lists, educational content):
```
━━━━━━━━━━━━━━━━ (headline — full scan)
━━━━━━━━━━━━     (subheading — shorter scan)
┃                (scan down left edge)
━━━━━━━━━        (catch on bullet/bold text)
┃
━━━━━━━          (catch on next bullet)
```
Use bold text, bullets, and indentation to create "catch points" along the left edge.

### 6.3 Modular Grid Systems for Social Templates

**The 4-Column Grid for Social Media:**

For 1080x1350 (4:5 feed post):
```
Margins: 60px left/right, 80px top, 60px bottom
Columns: 4 columns at 210px each
Gutters: 40px between columns
Rows: 6 rows at ~185px each (with 24px row gap)

Total content area: 960px wide x 1210px tall
```

**For 1080x1920 (9:16 stories):**
```
Margins: 60px left/right, 200px top (safe zone), 180px bottom (safe zone)
Columns: 4 columns at 210px each
Gutters: 40px between columns
Rows: 8 rows at ~168px each

Safe zone top: 200px (platform UI overlaps)
Safe zone bottom: 180px (swipe-up/CTA zone)
Total safe content area: 960px wide x 1540px tall
```

### 6.4 Visual Hierarchy with Layout Alone

**The 5 Hierarchy Tools (no color, no font change needed):**

1. **Size** — Largest element is most important. A 3:1 size ratio between headline and body creates clear hierarchy
2. **Position** — Top-left to bottom-right reading flow. Higher = more important
3. **Proximity** — Related items grouped together, unrelated items separated. Spacing between groups should be 2-3x the spacing within groups
4. **Alignment** — Aligned elements appear related; breaking alignment creates emphasis
5. **Isolation** — A single element surrounded by empty space demands attention

### 6.5 Negative Space as a Design Element

**Professional uses of negative space:**

- **Breathing room** — Minimum 15-20% of canvas should be "empty" for a premium feel
- **Implied shapes** — The space between elements can create recognizable forms (the FedEx arrow principle)
- **Text readability** — Line spacing (leading) of 1.4-1.6x font size; paragraph spacing of 1.5-2x line spacing
- **Focus direction** — Negative space pushes the eye toward content areas
- **Brand positioning** — More negative space = more premium feeling. Luxury brands use 40-60% negative space

**The "anti-clutter" test:** Cover each element with your hand. If removing it doesn't reduce understanding, it should probably go.

### 6.6 Breaking the Grid Intentionally

**Prerequisites:** You must have a solid grid first. Breaking the grid is only effective when the grid is visible enough that the break is perceived as intentional.

**Professional grid-breaking techniques:**

1. **Bleed elements** — One element extends beyond its column/row into the margin or off-canvas. Creates energy and suggests the design extends beyond the frame
2. **Overlapping containers** — Two grid-aligned containers that overlap by 10-20%. Creates depth and connection
3. **Rotation** — A single element rotated 3-8 degrees against an otherwise straight grid. Small rotation = playful; large rotation = chaotic
4. **Scale explosion** — One element dramatically larger than the grid allows, overlapping multiple cells. Creates a clear focal point
5. **Diagonal insertion** — A diagonal line, shape, or text block cutting across the grid. Disrupts horizontal/vertical monotony

**The "one break" rule:** In a single composition, break the grid in ONE way, not five. Multiple breaks cancel each other out and create visual noise instead of emphasis.

---

## 7. PHOTO INTEGRATION TECHNIQUES

### 7.1 Professional Photo Compositing

**The 5 Matching Requirements** (in order of importance):

1. **Lighting direction** — The light source must come from the same direction on all elements. Check highlight position and shadow fall direction
2. **Lighting quality** — Soft light (overcast) vs hard light (direct sun) must match. A hard-lit product on a soft-lit background looks fake
3. **Perspective/angle** — Camera angle and focal length must match. A bird's-eye product on a straight-on background is immediately wrong
4. **Color temperature** — Warm light vs cool light must be consistent. Use Color Balance or Photo Filter adjustment layers to match
5. **Resolution and grain** — All elements must have the same level of detail and noise pattern. Add matching grain as a final unifying step

**Shadow creation for composited elements:**
- Study the background shadows for angle, softness, and opacity
- Create shadows on a separate layer using Multiply blend mode
- Soft shadows: Gaussian blur 15-30px, opacity 20-40%
- Hard shadows: Gaussian blur 3-8px, opacity 40-70%
- Contact shadows (where object meets surface): very small blur (1-3px), higher opacity (50-80%), placed directly at the object's base

### 7.2 Cutout Techniques

**Professional cutout quality levels:**

| Level | Technique | Use Case | Quality |
|-------|-----------|----------|---------|
| Quick | AI background removal (remove.bg) | Internal drafts | 70% |
| Standard | Photoshop Select Subject + refine | Social media | 85% |
| Professional | Pen Tool paths + edge refinement | Print, hero images | 95% |
| Premium | Pen Tool + manual hair/fur masking + color decontamination | Beauty, fashion | 99% |

**Edge quality matters:**
- **Decontamination** — Remove color fringing from the original background
- **Feathering** — 0.5-1px feather on clean edges, 1-2px on organic edges
- **Edge contrast** — Slightly darken the edge by 5-10% to prevent the "glowing outline" effect
- **Never use magic wand or color range** for professional cutouts — they create jagged, inconsistent edges

### 7.3 Photo Treatments

**Grain:**
- Analog film grain: monochromatic, Gaussian, 1.5-4% intensity
- Digital noise simulation: chromatic (colored), more uniform than film grain
- Application: always add grain as the LAST step in the pipeline, after all other adjustments
- Grain unifies composited elements by adding a consistent texture layer across the entire image
- For social media: lighter grain (1.5-2%) for clean modern looks; heavier grain (3-5%) for editorial/vintage feels

**Halftone:**
- Convert continuous tone to patterns of dots
- Dot size varies with tone: small dots in highlights, large dots in shadows
- Common in retro, pop art, and editorial design
- Can be combined with duotone for a strong graphic look
- In Pillow: simulate with a threshold operation on a gradient-mapped image, or use a dot pattern overlay at reduced opacity

**Duotone (see Section 5.3)**

**Gradient Maps:**
- Maps luminosity values to a custom color gradient
- More flexible than duotone — can map to any number of colors
- Creates consistent color treatment across diverse source images
- Powerful tool for creating a cohesive visual feed from varied photography

### 7.4 Making Stock Photos Look Custom/Premium

**The 7-Step Stock-to-Premium Pipeline:**

1. **Crop aggressively** — Reframe to focus on the part you need. No one will recognize a stock photo if they only see 40% of it
2. **Apply brand color treatment** — Duotone, color overlay, or selective color adjustment to bring into brand palette
3. **Adjust focus** — Add selective blur (tilt-shift, radial blur) to create depth and direct attention
4. **Color grade** — Apply your brand's consistent color grade / LUT
5. **Add texture** — Subtle grain, paper texture overlay, or halftone pattern
6. **Flip or mirror** — Reverses recognition. A flipped stock photo is effectively a "new" image
7. **Composite with brand elements** — Layer logo, text, shapes, mascots on top. The more brand elements, the less the stock photo reads as stock

**What makes a photo look "stock":**
- Overly perfect lighting with no mood
- Generic subjects (smiling people in business casual, handshakes, etc.)
- Bright, flat, evenly lit backgrounds
- Poses that feel staged rather than candid

**Antidotes:**
- Introduce mood through color grading (cooler, warmer, muted)
- Crop to create interesting compositions the original photographer didn't intend
- Layer with textures, shapes, or translucent overlays to break the "clean" look

---

## 8. DESIGN FILE ORGANIZATION & PRODUCTION STANDARDS

### 8.1 Layer Naming Conventions

**For Pillow/programmatic rendering (Python dictionary/config structure):**
```python
# Semantic naming that maps to function
layers = {
    "bg": {},                    # Background base
    "bg_texture": {},            # Background texture overlay
    "decorative_blobs": {},      # Organic shapes, non-content
    "content_container_main": {},# Primary content area
    "content_container_sub": {}, # Secondary content area
    "mascot_left": {},           # Character placement
    "mascot_right": {},
    "text_headline": {},         # Primary text
    "text_body": {},             # Body copy
    "text_cta": {},              # Call-to-action text
    "badge_highlight": {},       # Starburst, circle highlight
    "logo": {},                  # Brand logo
    "grain": {},                 # Final grain overlay (ALWAYS LAST)
}
```

**For Figma/design tool files:**
```
Frame: "T1-Schedule-Feed-1080x1350"
  ├── logo/bb-logo-horizontal
  ├── text/headline
  ├── text/body
  ├── text/cta
  ├── badge/starburst-yellow
  ├── container/main-card
  ├── container/sub-card
  ├── mascot/sunny-wave
  ├── mascot/cloudy-smile
  ├── decorative/blob-green
  ├── decorative/swoosh-coral
  ├── bg/texture-overlay
  └── bg/base-cream
```

**Naming rules:**
- Use category/name format (category slash descriptive name)
- Name by function, not appearance ("badge/highlight" not "yellow-circle")
- Match naming to what engineers/developers call equivalent elements in code
- Consistent order: top layers listed first (logo at top of layer panel)

### 8.2 Design System Documentation

**A complete design system for social media production includes:**

1. **Color definitions** — All brand colors with hex, RGB, and usage rules
2. **Typography scale** — Every text size used, with font, weight, and line-height
3. **Spacing scale** — Defined spacing values (8px base: 8, 16, 24, 32, 48, 64, 96)
4. **Component library** — Every reusable element (badges, containers, buttons, icons)
5. **Template registry** — Each template type with layout specs, accepted content, and examples
6. **Usage rules** — Do/don't examples for each component
7. **Asset inventory** — All logos, mascots, icons, textures with file locations and sizes

### 8.3 Component-Based Design for Production

**Components vs instances:**
- A **component** is the master element (e.g., the "yellow starburst badge")
- An **instance** is a use of that component in a specific post, which may override content (text inside the badge) but inherits structure (shape, color, shadow)

**Component categories for social media:**

| Category | Examples | Changeability |
|----------|----------|---------------|
| Brand fixed | Logo, mascot illustrations | Never change |
| Structural | Card shapes, grid, margins | Change per template type only |
| Content | Headlines, body text, dates | Change per post |
| Decorative | Blobs, swooshes, textures | Change per variant |
| Functional | CTAs, hashtag bars, swipe indicators | Minimal change |

**In Python/Pillow production:**
Components translate to functions that accept parameters:
```python
def draw_starburst_badge(canvas, center, radius, text, color, font):
    """Reusable badge component — consistent across all templates."""
    # Draw starburst shape
    # Place text centered within
    # Return modified canvas
```

### 8.4 Handoff Standards

For programmatic production, "handoff" means the specification that connects strategy to code:

**A complete template spec includes:**
```
Template: T1-Schedule
Format: 1080x1350
Background: cream #F5F0E8

Layout zones:
  - Logo zone: top-center, y=40, width=200
  - Headline zone: y=120-280, full width, centered
  - Content zone: y=300-1100, margins 60px
  - Mascot zone: y=1100-1280, spread across bottom
  - CTA zone: y=1280-1320, centered

Typography:
  - Headline: DX Lactos, 56px, #1A1A1A, center
  - Body: Mabry Pro Regular, 28px, #1A1A1A, center, leading 1.5
  - Label: Mabry Pro Bold, 22px, #1A1A1A, center, tracking +50

Colors: primary={mascot color of the day}, bg=#F5F0E8, text=#1A1A1A

Dynamic content:
  - {headline}: max 30 chars
  - {body}: max 120 chars
  - {date}: format "DD MMM (DAY)"
  - {mascot}: 1-3 from set of 6
```

---

## 9. PROGRAMMATIC DESIGN PRODUCTION (PYTHON/PILLOW)

### 9.1 Text Rendering Quality in Pillow

**Layout engines:**
- **BASIC** — Simple left-to-right layout with basic kerning. No OpenType shaping.
- **RAQM** — Advanced layout: bidirectional text, OpenType feature support, language-specific shaping. Required for CJK (Chinese/Japanese/Korean) text.

**To enable RAQM:** Install `libraqm` system library. Pillow auto-detects it.

**Typography control in Pillow:**

```python
from PIL import Image, ImageDraw, ImageFont

font = ImageFont.truetype("MabryPro-Regular.otf", size=28)

# Get precise text dimensions
draw = ImageDraw.Draw(image)
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]

# Get single-line length (with 1/64px precision)
length = font.getlength(text)

# Kerning note: textlength for "AV" != textlength("A") + textlength("V")
# due to kerning pairs. Always measure the complete string.

# OpenType features (requires RAQM):
draw.text((x, y), text, font=font, features=["-kern"])  # disable kerning
draw.text((x, y), text, font=font, features=["smcp"])   # small caps
draw.text((x, y), text, font=font, features=["liga"])   # ligatures
```

**Tracking (letter-spacing) in Pillow:**
Pillow does not have a built-in tracking parameter. Implement manually:

```python
def draw_text_with_tracking(draw, pos, text, font, tracking=0, fill="black"):
    """Draw text with custom letter spacing (tracking in pixels)."""
    x, y = pos
    for i, char in enumerate(text):
        draw.text((x, y), char, font=font, fill=fill)
        char_width = font.getlength(char)
        # For kerning-aware tracking, measure pairs:
        if i < len(text) - 1:
            pair_width = font.getlength(text[i:i+2])
            single_width = font.getlength(text[i])
            kern_adjust = pair_width - single_width - font.getlength(text[i+1])
            x += char_width + tracking + kern_adjust
        else:
            x += char_width + tracking
```

### 9.2 Anti-Aliasing and Sharpness

**Pillow's text rendering is anti-aliased by default** when using TrueType fonts. For maximum quality:

- Render at 2x resolution, then downscale with `Image.LANCZOS` — this creates supersampled anti-aliasing
- For shapes and lines, render at 2x then downscale for smooth edges
- Use `ImageDraw.rounded_rectangle()` for containers (available in Pillow 8.2+)

```python
# Supersampled rendering for maximum quality
scale = 2
large = Image.new("RGBA", (1080 * scale, 1350 * scale), "#F5F0E8")
draw = ImageDraw.Draw(large)
# ... draw everything at scale ...
final = large.resize((1080, 1350), Image.LANCZOS)
```

### 9.3 Grain as Final Post-Processing

```python
import numpy as np
from PIL import Image

def add_grain(image, intensity=0.016, monochromatic=True):
    """Add film-like grain. Always apply LAST in pipeline."""
    arr = np.array(image, dtype=np.float32)

    if monochromatic:
        noise = np.random.normal(0, intensity * 255, arr.shape[:2])
        noise = np.stack([noise] * arr.shape[2], axis=-1)
    else:
        noise = np.random.normal(0, intensity * 255, arr.shape)

    result = np.clip(arr + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(result)
```

### 9.4 Programmatic Duotone

```python
def apply_duotone(image, shadow_color, highlight_color):
    """Convert image to duotone using two brand colors."""
    # Convert to grayscale
    gray = image.convert("L")
    pixels = np.array(gray, dtype=np.float32) / 255.0

    # Parse colors
    s = np.array(shadow_color, dtype=np.float32)    # e.g., (26, 26, 26)
    h = np.array(highlight_color, dtype=np.float32)  # e.g., (240, 214, 55)

    # Linear interpolation between shadow and highlight
    result = np.zeros((*pixels.shape, 3), dtype=np.float32)
    for c in range(3):
        result[:, :, c] = s[c] + (h[c] - s[c]) * pixels

    return Image.fromarray(result.astype(np.uint8), "RGB")
```

### 9.5 Batch Production Architecture

**The template-instance pattern:**

```python
# Template definition (created once, carefully)
TEMPLATE_T1_SCHEDULE = {
    "name": "T1-Schedule",
    "size": (1080, 1350),
    "bg_color": "#F5F0E8",
    "zones": {
        "logo": {"pos": (540, 40), "anchor": "mt"},
        "headline": {"pos": (540, 200), "font": "DXLactos", "size": 56},
        "content": {"pos": (60, 300), "width": 960, "height": 800},
        "mascots": {"pos": (540, 1200), "spread": 400},
    },
    "decorative": {
        "blobs": [{"type": "wavy", "pos": (0, 900), "color_key": "primary"}],
        "badges": [{"type": "starburst", "pos": (800, 250)}],
    },
}

# Instance data (changes per post)
posts = [
    {"headline": "This Week at B&B", "body": "Mon: Sensory Play...", "mascots": ["sunny", "cloudy"]},
    {"headline": "Holiday Schedule", "body": "We're open all...", "mascots": ["sprout", "heartie"]},
    # ... 28 more posts
]

# Production loop
for i, post in enumerate(posts):
    image = render_template(TEMPLATE_T1_SCHEDULE, post)
    image = add_grain(image, intensity=0.016)
    image.save(f"exports/t1_schedule_{i+1:03d}.png")
```

### 9.6 Quality Gates in Automated Production

**Automated QA checks to run on every rendered image:**

```python
def qa_check(image, template):
    """Run quality gates on rendered image."""
    checks = {}

    # 1. Resolution check
    checks["resolution"] = image.size == template["size"]

    # 2. Edge safety — no content in outer 5%
    # (Check that the edge pixels match expected bg color)

    # 3. Color palette compliance
    # Sample N random pixels, verify they're within deltaE of brand colors

    # 4. Text contrast check
    # For each text zone, sample bg color and verify WCAG contrast ratio

    # 5. File size sanity
    # A 1080x1350 PNG should be 500KB-3MB. Outside = problem

    # 6. Visual hash comparison
    # Compare to previous version of same template — catch rendering errors

    return all(checks.values()), checks
```

---

## APPENDIX A: QUICK REFERENCE — KEY NUMBERS

| Metric | Value | Context |
|--------|-------|---------|
| Instagram Feed | 1080x1350px (4:5) | Optimal engagement format |
| Instagram Stories | 1080x1920px (9:16) | Full-screen vertical |
| Story safe zone top | 200px | Platform UI overlap |
| Story safe zone bottom | 180px | Swipe/CTA zone |
| WCAG AA text contrast | 4.5:1 minimum | Normal text on background |
| WCAG AA large text | 3:1 minimum | 18px+ or 14px+ bold |
| Line height body text | 1.4-1.6x font size | Optimal readability |
| Paragraph spacing | 1.5-2x line height | Visual separation |
| Negative space (premium) | 15-40% of canvas | More = more premium |
| Grain intensity (modern) | 1.4-2.0% | Subtle texture |
| Grain intensity (editorial) | 3-5% | Visible film look |
| Hand-kern threshold | 18pt+ | All headlines above this |
| All-caps tracking | +50 to +150 | Required for readability |
| Grid columns (social) | 4 | Standard for 1080px width |
| Column width | 210px | With 60px margins, 40px gutters |
| Max fonts per design | 2-3 | More = visual chaos |
| Supersampling factor | 2x | Render at 2x, downscale for quality |

## APPENDIX B: TOOL RECOMMENDATIONS

| Task | Tool | Why |
|------|------|-----|
| Batch rendering | Python + Pillow | Full control, reproducible, scriptable |
| CJK text support | Pillow + libraqm + Noto Sans SC | RAQM handles CJK shaping |
| Vector shapes | Python + cairo (pycairo) or SVG + cairosvg | Better curves than Pillow alone |
| Color management | Python + Pillow (ICC profiles) | Embed profiles in output |
| Background textures | AI generation (one-time library) | Ideogram V3 or similar |
| Cutouts | remove.bg API or rembg (Python) | Automated background removal |
| Quality audit | Vision LLM (GPT-4o) + programmatic checks | Automated QA pipeline |
| Font metrics | fonttools (Python library) | Parse OpenType tables for precise kerning data |

---

*Sources and references are listed at the end of this document.*

## SOURCES

### Social Media Production at Scale
- [Social Media Content Creation Workflows 2025](https://socialrails.com/blog/social-media-content-creation-workflows)
- [Social Media Workflow: 6 Phases to Plan, Approve & Publish](https://www.socialpilot.co/blog/social-media-workflow)
- [Social Media Management Workflow 2026](https://metricool.com/social-media-workflow/)

### Brand Agency Production
- [Nike Digital Content, Social Media, Campaign Production](https://www.wearekettle.com/case-studies/nike)
- [Nike Takes Social Media In-House](https://www.marketingweek.com/nike-takes-social-media-in-house/)
- [Airbnb Branding Strategy](https://marcom.com/airbnb-the-idea-that-caught-fire-in-the-travel-industry/)

### Design Systems & Tokens
- [Building a Scalable Design Token System](https://medium.com/@mailtorahul2485/building-a-scalable-design-token-system-from-figma-to-code-with-style-dictionary-e2c9eacc75aa)
- [Design Tokens Explained](https://www.contentful.com/blog/design-token-system/)
- [Creating Multi-Brand Design Systems — Figma](https://www.figma.com/blog/creating-multi-brand-design-systems/)
- [How to Build a Token-Based Component Library in Figma](https://designilo.com/2025/07/10/how-to-build-a-token-based-component-library-in-figma/)

### Typography
- [Master Kerning for Polished Typography — Adobe](https://www.adobe.com/in/creativecloud/roc/blog/design/kerning-typography-tips.html)
- [Letter Spacing Guide 2026](https://inkbotdesign.com/letter-spacing-guide/)
- [Ultimate Guide to Typography in Design — Figma](https://www.figma.com/resource-library/typography-in-design/)
- [Typography Rules for Graphic Design — Amadine](https://amadine.com/useful-articles/rules-of-typography)
- [Variable Fonts: Responsive Type for Responsive Web](https://www.lyquix.com/blog/variable-fonts-responsive-type-for-responsive-web/)
- [Typography as Image — Yes I'm a Designer](https://yesimadesigner.com/how-to-use-type-as-image/)
- [Illustrative Typography: Merging Text and Image — RMCAD](https://www.rmcad.edu/blog/illustrative-typography-merging-text-and-image/)

### Color Production
- [How to Make a Duotone in Photoshop](https://photoshopcafe.com/make-duotone-photoshop-color-grading/)
- [The Art of Duotone: A Color Theory Guide](https://www.numberanalytics.com/blog/art-duotone-color-theory-guide)
- [Color Contrast for Accessibility: WCAG Guide 2026](https://www.webability.io/blog/color-contrast-for-accessibility)
- [WebAIM: Contrast and Color Accessibility](https://webaim.org/articles/contrast/)
- [sRGB, AdobeRGB, DCI-P3: Color Space Guide for Artists](https://artnewsnviews.com/digital-art/color-spaces-for-artists/)
- [How P3 Displays Affect Your Workflow](https://creativepro.com/how-do-p3-displays-affect-your-workflow/)
- [Seasonal Color Theory for Brands — Tailwind](https://www.tailwindapp.com/blog/seasonal-color-theory)

### Layout & Composition
- [5 Essential Rules for Mastering Layouts](https://designbuddy.net/articles/mastering-composition-in-graphic-design)
- [Grids in Graphic Design Ultimate Guide](https://www.zekagraphic.com/grids-in-graphic-design-ultimate-guide/)
- [Layout Design: Types of Grids — Visme](https://visme.co/blog/layout-design/)
- [How to Effectively Break Out of the Grid](https://www.secretstache.com/blog/how-to-effectively-break-out-of-the-grid/)
- [Breaking the Grid — Design Shack](https://designshack.net/articles/layouts/breaking-the-grid/)
- [Rule of Thirds — IxDF](https://ixdf.org/literature/topics/rule-of-thirds)

### Photo Integration
- [The Perfect Composite — PHLEARN](https://phlearn.com/tutorial/perfect-composite/)
- [Photo Compositing: 7 Essentials — ZevenDesign](https://zevendesign.com/photo-compositing/)
- [Realistic Photo Compositing Primer — DIY Photography](https://www.diyphotography.net/need-know-realistic-photo-compositing-image-manipulation-primer/)
- [How to Edit Stock Photos — Shutterstock](https://www.shutterstock.com/blog/customize-photos)
- [5 Ways to Customize Stock Photography — Depositphotos](https://blog.depositphotos.com/5-ways-to-easily-customize-stock-photography.html)

### Pre-Press & Retouching
- [10 Pre-Press Tips for Perfect Print Publishing — Smashing Magazine](https://www.smashingmagazine.com/2009/10/10-pre-press-tips-for-perfect-print-publishing/)
- [Ultimate Guide to Pre-Press Production — P&H](https://pandh.com/pre-press-production/)
- [Frequency Separation in Photoshop — Adobe](https://www.adobe.com/products/photoshop/frequency-separation.html)
- [Advanced Frequency Separation Techniques — PRO EDU](https://proedu.com/blogs/photoshop-skills/advanced-frequency-separation-techniques-for-flawless-retouching-elevating-your-photo-editing-skills)

### File Organization & Handoff
- [Layer Naming Style Guide — Greg Rogers](https://www.gregrogers.ca/writing/layer-naming-style-guide)
- [File Naming Conventions for Designers — Medium](https://medium.com/design-bootcamp/file-naming-conventions-for-designers-c08f288b4d2a)
- [Guide to Developer Handoff in Figma](https://www.figma.com/best-practices/guide-to-developer-handoff/)
- [Design Handoff Best Practices — Encora](https://medium.com/encora-technology-practices/draft-design-handoff-best-practices-5eb0cfb6452)

### Programmatic Production
- [Pillow ImageFont Documentation](https://pillow.readthedocs.io/en/stable/reference/ImageFont.html)
- [Pillow Kerning Pairs — GitHub Issue #6175](https://github.com/python-pillow/Pillow/issues/6175)
- [Drawing and Text Rendering — Pillow DeepWiki](https://deepwiki.com/python-pillow/Pillow/2.4-drawing-and-font-support)
- [Create Social Media Posts by API — Creatomate](https://creatomate.com/how-to/create-social-media-posts-by-api)
- [imgmaker — Create Images Programmatically](https://github.com/minimaxir/imgmaker)
