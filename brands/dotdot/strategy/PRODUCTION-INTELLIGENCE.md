# DotDot Production Intelligence

> 3 production pipelines for 150 pieces/month. Adapted from universal creative intelligence engine.

---

## The Single Law

**NANO Banana Pro Edit renders ALL static visuals. PIL renders NOTHING except post-processing.**

For video: AI video generation (Kling/Hailuo) renders 3D mascot animation.

---

## 3 Production Pipelines

### Pipeline A: IG Static (90 posts/month)
**Tool**: `fal-ai/nano-banana-pro/edit`
**Method**: Edit-first — reference image in, brand-adapted output out
**Cost**: ~$0.15/image × 90 = ~$13.50/month

### Pipeline B: Video (30 videos/month)
**Tool**: Kling AI 2.1 / Hailuo MiniMax / Runway Gen-3
**Method**: 3D mascot character animation with voiceover + subtitle overlay
**Cost**: ~$0.50-2.00/video depending on tool and duration

### Pipeline C: XHS Infographic (30 posts/month)
**Tool**: `fal-ai/nano-banana-pro/edit` + carousel assembly
**Method**: Reference-based infographic generation, XHS aesthetic
**Cost**: ~$0.15/slide × 6 slides × 30 = ~$27/month

**Total estimated cost**: ~$100-120/month for 150 pieces

---

## Pipeline A: IG Static Production

### Architecture
```
Reference Image (Image 1) → NANO Edit → Post-Processing → Final Output
         ↑                      ↑
    Brand approved          Prompt with
    output or ref           DNA blocks
```

### 7-Layer Prompt Architecture

**L1 — Safety Layer**
```
ANTI_RENDER = """
CRITICAL: Do NOT render any hex color codes, font names, pixel dimensions,
or technical specifications as visible text in the image. These are
instructions for you, not content to display.
"""

NO_BRAND_LEAK = """
Do NOT include any brand names, logos, or identifiable marks other than
DotDot. Never render competitor brand names or generic supplement brands.
"""
```

**L2 — Reference Layer**
```
REFERENCE_FIRST = """
Edit this reference image. Preserve the overall layout, composition,
and visual hierarchy. Change ONLY the following elements:
[CHANGES list]
PRESERVE everything else exactly as shown.
"""
```

**L3 — Brand DNA Layer**
```python
DOTDOT_DNA = {
    "palette": {
        "primary_teal": "#4DBFB8",
        "primary_orange": "#E8752A",
        "accent_pink": "#D4637A",
        "accent_gold": "#D4A843",
        "white": "#FFFFFF",
        "black": "#1A1A1A",
        "trust_green": "#2E8B57"
    },
    "color_rule": "60% teal or white, 30% orange or accent, 10% black text",
    "camera_craft": "Clean, clinical-meets-warm. Soft natural lighting. Not overly stylized.",
    "typography_dna": "Rounded sans-serif for Traditional Chinese. Large, high-contrast. Elderly-readable.",
    "product_integrity": "NEVER AI-generate product packaging. Use real product photos ONLY.",
    "logo": "Two black dots + dotdot.. wordmark. Top-right corner, subtle."
}
```

**L4 — Category Layer** (varies per CAT-01 through CAT-10)
```
CAT_01_ANATOMY = """
Style: Medical education illustration, warm and approachable (not clinical).
Reference: XHS meniscus infographic style (see brief-images/page11-13).
Elements: Anatomical diagram, numbered annotations, clear labels in Traditional Chinese.
Background: Cream or light teal. Clean, uncluttered.
"""
```

**L5 — Copy Layer**
```
Headline placement: top 25% of frame, large, high contrast.
Body text: if needed, bottom 30%, smaller but still elderly-readable.
Language: Traditional Chinese. No Simplified.
Max text elements: 4-5 per image (headline + 3-4 supporting points).
```

**L6 — Typography Layer**
```
FONT_DNA_DOTDOT = """
Headlines: Bold rounded sans-serif, warm and friendly.
Imagine the typeface as: approachable, trustworthy, clear, slightly playful.
ALL CAPS for English elements. Generous letter-spacing.
Chinese characters: thick strokes, clear counters, readable at small sizes.
Minimum visual font size for elderly: equivalent to 48pt at 1080px width.
"""
```

**L7 — Output Specs**
```python
OUTPUT_SPEC_IG = {
    "width": 1080,
    "height": 1350,
    "format": "4:5 portrait",
    "resolution": "2K",
    "margin_safe": 60  # px from edge
}

OUTPUT_SPEC_XHS = {
    "width": 1080,
    "height": 1440,
    "format": "3:4 portrait",
    "resolution": "2K",
    "margin_safe": 60
}
```

### 9 DNA Prompt Blocks

```python
BLOCKS = {
    "ANTI_RENDER": "...",       # L1 - no hex/font text rendered
    "NO_BRAND_LEAK": "...",     # L1 - no competitor brands
    "FONT_DNA": "...",          # L6 - typography description
    "TYPE_MASTER": "...",       # L6 - headline treatment
    "LAYOUT_MASTER": "...",     # L5 - composition rules
    "COLOR_MASTER": "...",      # L3 - 60-30-10 distribution
    "LOGO_SAFE": "...",         # Top 12-15% clear for logo
    "GRID_SAFE": "...",         # Center horizontal for grid crop
    "ELDERLY_ACCESSIBLE": "..." # NEW — large fonts, high contrast, simple layout
}
```

### ELDERLY_ACCESSIBLE Block (NEW — DotDot specific)
```
ELDERLY_ACCESSIBLE = """
Design for elderly viewers (55-80+ years old):
- Minimum text size: visually equivalent to 48pt at 1080px width
- Contrast ratio: WCAG AAA (7:1 minimum for body text)
- Maximum 3-4 information elements per image
- Clear visual hierarchy: ONE primary message per post
- Avoid thin fonts, low-contrast pastels, or small detail-heavy illustrations
- Icons/illustrations: simple, clear shapes. Not abstract.
- Color coding: distinct, not relying on subtle shade differences
"""
```

### Post-Processing Chain (immutable order)

```python
def post_process_dotdot(image_path, output_path):
    """Post-processing chain for DotDot IG static content."""
    img = force_size(image_path, 1080, 1350)       # 1. Resize to exact dims
    img = editorial_grade(img, desat=0.04, contrast=1.04)  # 2. Subtle grade (less than PX — cleaner)
    img = paper_texture(img, opacity=0.015)          # 3. Subtle paper texture
    img = place_logo(img, logo_path, position="top-right", max_height=120, y_offset=30)  # 4. Logo
    img = add_grain(img, amount=2.5)                 # 5. ALWAYS LAST — subtle grain
    img = sharpen(img, radius=1.0, percent=80, threshold=4)  # 6. Final sharpen
    save(img, output_path, quality=95, format="PNG")
```

**DotDot vs other brands**:
| Parameter | DotDot | Pinxin | Mirra |
|-----------|--------|--------|-------|
| desat | 0.04 | 0.08 | 0.10 |
| contrast | 1.04 | 1.06 | 1.08 |
| paper_texture | 0.015 | 0.020 | 0.018 |
| grain | 2.5 | 3.5 | 3.0 |
| logo_max_height | 120px | 140px | 100px |

Rationale: DotDot is health/clinical — cleaner, less editorial texture than food brands.

---

## Pipeline B: Video Production (NEW)

### Video Architecture
```
Mascot Character Design → AI Video Generation → Voiceover → Subtitle Overlay → Final
```

### 3D Mascot Character System

**Character concept** (pending client mascot assets):
- Based on client's existing brand mascot
- Rendered in Pixar/3D animation style (per @business.shorts and @thegoodsuniverse references)
- Expressive face: can talk, smile, wince (showing pain empathy), demonstrate exercises
- Consistent appearance: same character across ALL 30 monthly videos
- Setting variations: living room, park, clinic, kitchen (rotating backgrounds)

### Video Production Workflow

**Step 1: Script + Storyboard**
```
For each video:
- 3-5 scene breakdown (30-90 seconds total)
- Cantonese voiceover script
- Traditional Chinese subtitle text
- On-screen text overlays (key facts, exercise names)
```

**Step 2: AI Video Generation**
```
Tool options (ranked by quality for 3D character animation):
1. Kling AI 2.1 — best character consistency, face-locking available
2. Hailuo MiniMax — good quality, competitive pricing
3. Runway Gen-3 Alpha — strong motion quality
4. Pika 2.0 — fast iteration

Method:
- Generate character reference frame (NANO or ChatGPT image gen)
- Use face/character locking to maintain consistency
- Generate 3-5 second clips per scene
- Stitch clips in sequence
```

**Step 3: Audio**
```
- Cantonese voiceover: AI voice (e.g., ElevenLabs Cantonese) or human VO
- Background music: royalty-free, calm/warm (not clinical)
- Sound effects: subtle (joint click sounds, exercise counting)
```

**Step 4: Post-Production**
```
- Subtitle overlay: Traditional Chinese, large font, high contrast bg
- Text overlays: key facts, exercise names, brand watermark
- DotDot logo: corner watermark throughout
- End card: WhatsApp CTA + product shot
- Export: 1080x1920 (9:16), MP4, <60 seconds for Reels/TikTok
```

### Video Category Templates

**Template V1: Exercise Demo (12/month)**
```
Scene 1 (5s): Mascot greets viewer, introduces today's exercise
Scene 2 (15s): Mascot demonstrates exercise with counting
Scene 3 (15s): Second exercise variation
Scene 4 (10s): Mascot summarizes benefits
Scene 5 (5s): End card — WhatsApp CTA + logo
Total: 50 seconds
```

**Template V2: Education Explainer (12/month)**
```
Scene 1 (5s): Mascot poses question ("Do you know why knees hurt?")
Scene 2 (20s): Animated anatomy/condition explanation with text overlays
Scene 3 (15s): Key facts (3 points, numbered)
Scene 4 (10s): Mascot gives practical takeaway
Scene 5 (5s): End card
Total: 55 seconds
```

**Template V3: Myth Buster (6/month)**
```
Scene 1 (5s): Mascot reads common myth with skeptical face
Scene 2 (10s): "FACT:" — truth revealed with supporting visual
Scene 3 (10s): Why the myth is wrong
Scene 4 (5s): Mascot gives correct advice
Scene 5 (5s): End card
Total: 35 seconds
```

---

## Pipeline C: XHS Infographic Production

### XHS Design DNA (from PDF reference images)

The client's XHS references show a specific style:
- **Hand-drawn/illustrated medical education** aesthetic
- Warm background (cream, soft orange, light green)
- Numbered symptom/cause lists with anatomical illustrations
- Clear visual hierarchy: large title → numbered points → conclusion
- Illustrated human figures showing pain points (red highlight zones)
- Traditional Chinese text with clear, educational tone

### XHS Production Workflow

**Step 1: Carousel Structure**
```
Slide 1: Hook — large headline + hero illustration (attention-grabbing)
Slide 2-6: Content — numbered points with illustrations
Slide 7: Summary + CTA (save/share)
Optional Slide 8: Product mention (subtle, not hard sell)
```

**Step 2: NANO Generation (per slide)**
```
Reference: XHS health infographic from ref library (Image 1)
Prompt: Edit-first approach — swap content while preserving layout

Key elements per slide:
- Background: cream or soft brand color
- Illustration: anatomical or lifestyle illustration
- Text zone: 40% of frame, Traditional Chinese
- Numbering: circled numbers (①②③) for list items
- Color accents: teal for positive, orange for warnings, red for pain points
```

**Step 3: Post-Processing (per slide)**
```python
def post_process_xhs(image_path, output_path):
    img = force_size(image_path, 1080, 1440)  # 3:4 for XHS
    img = editorial_grade(img, desat=0.03, contrast=1.03)  # Very subtle
    img = place_logo(img, logo_path, position="bottom-right", max_height=80)
    img = add_grain(img, amount=1.5)  # Minimal grain for XHS clean aesthetic
    save(img, output_path, quality=95, format="PNG")
```

### XHS Content Types

| Type | Slides | Style | Monthly |
|------|--------|-------|---------|
| Knee Pain Guide | 6-8 | Anatomical illustration + numbered list | 10 |
| Exercise Step-by-Step | 8-10 | Photo/illustration hybrid, numbered steps | 10 |
| Lifestyle & Diet | 4-6 | Food illustration + benefit callouts | 5 |
| Patient Story | 3-5 | Timeline/before-after + text | 5 |

---

## 8-Dimension Quality Audit

Run on EVERY output before publishing.

| Dimension | Check | Pass Criteria |
|-----------|-------|--------------|
| 1. Brand DNA | Logo present, palette correct, no brand leak | DotDot teal/orange, logo visible, no competitor marks |
| 2. Composition | Clear hierarchy, balanced layout, no dead space | ONE primary message readable in 2 seconds |
| 3. Elderly Accessible | Font size adequate, contrast sufficient | Text readable at arm's length on phone screen |
| 4. Typography | Traditional Chinese correct, no Simplified, no typos | Native speaker review for character accuracy |
| 5. Medical Accuracy | Health claims compliant, no "cure" language | Compliance gate passed |
| 6. Product Integrity | Real product photos only, no AI-generated packaging | Cross-reference with actual product images |
| 7. Cultural Fit | HK context correct, Cantonese natural, references appropriate | No mainland-only references, no tone-deaf content |
| 8. Platform Fit | Correct dimensions, safe zones, format | IG 4:5, Video 9:16, XHS 3:4 |

### Audit Process
```
Layer 1 (Programmatic): Resolution check, color palette compliance, logo detection
Layer 2 (Vision): Text readability, composition balance, brand consistency
Layer 3 (Human): Medical accuracy, cultural fit, Cantonese naturalness
```

Passing threshold: 7/8 dimensions must pass. Medical Accuracy (dimension 5) is a HARD FAIL — if it fails, entire batch is rejected regardless of other scores.

---

## Diversity Enforcement (Andromeda)

At 90 IG posts/month, repetition is the #1 risk. Enforce across every batch:

| Dimension | Requirement |
|-----------|-------------|
| Category rotation | All 10 CATs represented per week |
| Visual style | Alternate: illustration, photo, infographic, exercise demo |
| Color world | Rotate Position 1 through teal, orange, green, cream, dark |
| Body part | Not all knee — mix in hip, back, shoulder, general mobility |
| Persona | Rotate through 5 personas, never >2 consecutive same |
| Layout | Vary: centered, left-aligned, split, full-bleed, card-on-bg |
| Tone | Alternate: educational, inspirational, practical, personal story |

---

## Batch Production Workflow

### Monthly Production Cycle

**Week 1 (Planning)**
- Content calendar finalized (all 150 pieces mapped)
- Reference images sourced and approved
- Video scripts written
- Copy/captions drafted

**Week 2 (Static Production)**
- IG batch: 90 posts generated via NANO
- XHS batch: 30 infographic carousels generated
- Post-processing applied to all
- Quality audit on all outputs

**Week 3 (Video Production)**
- 30 video scripts finalized
- AI video generation (mascot clips)
- Voiceover recording/generation
- Subtitle + text overlay assembly
- Video quality review

**Week 4 (QA + Scheduling)**
- Full batch QA (all 150 pieces)
- Human review for medical accuracy + cultural fit
- Scheduling across all platforms
- Buffer content prepared (5 flex pieces)

### Parallel Execution
```
Static (IG + XHS) = ~120 pieces → can batch in 2-3 days
Video = 30 pieces → sequential, ~1 week
Total production time: ~2 weeks per month cycle
```

---

## Reference Library Growth

### Starting References Needed
1. DotDot product photos (all 6 products, multiple angles)
2. Danny/founder photos (portrait, at expo, with customers)
3. Clinic/store photos (retail environment, consultation)
4. XHS health infographic references (10-15 from similar accounts)
5. Exercise demonstration references (physiotherapy content)
6. Mascot character sheet (all poses, expressions)

### Compounding Library
- Every approved output becomes a future reference
- Organize by category: `01_references/{cat01-anatomy, cat05-exercise, ...}`
- Tag approved outputs: `_LOCKED/` directory for production-proven references
- Monthly review: which references produce best results?

---

## Tool Stack Summary

| Tool | Purpose | Cost |
|------|---------|------|
| NANO Banana Pro Edit | All static image generation | ~$0.15/image |
| Kling AI 2.1 / Hailuo | 3D mascot video generation | ~$0.50-2/video |
| ElevenLabs | Cantonese voiceover generation | ~$0.30/minute |
| PIL/Pillow | Post-processing only (resize, logo, grain) | Free |
| Python | Batch orchestration, QA automation | Free |
| IG Graph API | Scheduling + posting | Free |
| Meta Business Suite | Cross-posting to FB | Free |

---

## Hard Rules (absolute, never violated)

1. **Reference first** — never generate from scratch
2. **Single-pass AI** — no multi-pass on any image
3. **PIL = resize + save ONLY** — all creative editing via AI
4. **Never AI-generate product packaging** — use real photos
5. **Image 1 = style anchor** — brand's own approved output, never scraped ref
6. **Elderly accessible** — every design must pass readability test
7. **Medical compliance** — no cure claims, proper disclaimers
8. **Traditional Chinese only** — no Simplified on IG/video (XHS tags may use Simplified for search)
9. **Grain always last** — immutable post-processing order
10. **Human review before publishing** — all 150 pieces reviewed for medical accuracy
