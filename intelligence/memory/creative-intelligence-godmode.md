---
name: Creative Intelligence — God Mode Operating System
description: Universal creative production intelligence. Brand-agnostic. Covers NANO edit mastery, reference-to-production pipeline, prompting techniques, quality DNA, and design principles. Apply to ANY brand, ANY creative project.
type: feedback
---

# Creative Intelligence — God Mode Operating System

This is not brand-specific. This is how to produce world-class creative output with AI image editing for ANY brand.

---

## 1. THE FUNDAMENTAL LAW: AI is an EDITOR, not a generator

**NEVER say "create something inspired by this reference."**
**ALWAYS say "edit this image — swap only these specific elements."**

NANO Banana Pro Edit (and similar models) are IMAGE EDITORS. When you frame the task as "edit this image," the model preserves everything you don't mention. When you frame it as "create based on this," the model reinterprets freely and destroys structure.

This is the single most important insight. It changes everything.

### The Edit-First Prompt Pattern:
```
Edit this image. Keep the EXACT same layout, spacing, and composition structure.

CHANGES — swap these elements only:
1. [specific element] → [new version]
2. [specific element] → [new version]
3. [specific element] → [new version]

PRESERVE — do NOT change:
- [explicit list of structural elements to keep]

This should look like someone opened the original file and swapped [X] — the STRUCTURE is pixel-identical.
```

### When to use edit-first vs system constants:
| Reference complexity | Approach |
|---------------------|----------|
| Simple compositions (hero shots, splits, lifestyle) | System constants — describe the desired output with style directives |
| Complex UI (websites, calendars, apps, card grids, dashboards) | Edit-first — treat reference as the image, swap specific elements |
| Any reference with >8 distinct UI elements | Edit-first |

---

## 2. THE 8 DNA QUALITIES — What separates amateur from editorial

Every world-class creative output shares these 8 qualities. Prompt for ALL of them.

1. **DIRECTIONAL LIGHTING** — Soft warm light from a specific direction (usually upper-left), creating REAL shadows. Never flat, never ambient-only.

2. **CAMERA CRAFT** — 30-45 degree angles, shallow depth of field, 85mm f/1.4 lens compression. Hero elements razor sharp, backgrounds softly blurred. The angle you see in Bon Appétit or Kinfolk.

3. **RICH BACKGROUND COLOR** — Never pure white. Never clinical. Warm tones: salmon, dusty rose, coral, terracotta, sage. Background color IS a design choice, not a default.

4. **PREMIUM PROPS** — 2-3 lifestyle props that create editorial context. Glass bottles catching light, metallic cutlery on linen, fresh herbs scattered naturally. Props are TACTILE and REAL.

5. **SURFACE TEXTURE / TWO-TONE DEPTH** — A colored WALL meeting a cream/neutral SURFACE (table/counter). This two-tone split creates natural depth — like a styled shoot set. Never a single flat color.

6. **WORLD-CLASS TYPOGRAPHY** — High-contrast serif with dramatic thick/thin stroke variation (Playfair Display / Canela / GT Super energy). Mixed weights create RHYTHM. Generous letter-spacing on all-caps. Cream text on colored backgrounds, near-black on light.

7. **SHADOWS & DIMENSION** — Every object casts a soft shadow. Products show slight elevation from surfaces. Depth of field blur on secondary elements. The image has PHYSICAL depth.

8. **RADICAL SIMPLICITY** — Fewer elements, each one gets SPACE. If you can remove something and the piece still works, REMOVE IT. White space is the most expensive ingredient. Think Aesop store window, not phone plan flyer.

### How to encode in prompts:
- For photography/lifestyle: include ALL 8 as system constants
- For UI/graphic design: include only #3 (color), #6 (typography), #8 (simplicity)
- Camera craft + props are for EDITORIAL PHOTOGRAPHY only, not for UI mockups

---

## 3. AI RENDERS BRANDING — No PIL overlay

The AI model renders ALL text, branding, and logos as part of the design.
Post-production does NOT stamp logos on top.

**Why**: AI-rendered branding is COHESIVE — it's part of the composition, with matching lighting, shadows, and style. A PIL-stamped logo on top of AI output looks like a sticker on a painting.

### Correct post-processing stack:
```
AI output → resize to target dimensions → grain (always last) → DONE
```

### What to tell the AI about branding:
- For edit-first: "Replace [original brand] with '[new brand]' in same style, same position"
- For generation: include brand name placement in the layout description
- If the brand appears as a headline/hero element, it doesn't appear again as a logo
- Brand mark should be small, elegant, integrated — never shouting

---

## 4. PRODUCT/FOOD PHOTO INTEGRITY — Sacred photographs

When working with real product/food photography:
- Every provided photo is a SACRED REAL PHOTOGRAPH
- DO NOT let AI generate, reimagine, restyle, or modify the product
- Place the EXACT photo as provided — same container, same plating, same colors
- Treat product photos like a magazine editor placing professional photography into a layout
- The photo is UNTOUCHABLE
- If a layout zone needs a product and none was provided, leave that zone as a clean surface or abstract shape

### Multi-image input pattern:
```
image_urls = [reference_image, product_photo_1, product_photo_2, ...]
```
- Image 1 = always the reference/layout
- Image 2+ = product/food photos to integrate
- Reference each by number in the prompt: "Image 2 is the product — place it EXACTLY as provided"

---

## 5. ANTI-RENDER INSTRUCTION — Prevent technical leakage

AI models will render hex codes, font names, pixel values, and other technical specifications as VISIBLE TEXT if they appear in the prompt.

**Always include at the top of every prompt:**
```
You are an image editor, not a text document renderer.
DO NOT render any technical specifications, hex codes, font names, pixel values,
tracking numbers, or measurement units as visible text in the image.
These are INVISIBLE INSTRUCTIONS for how to style elements, not content to display.
Only render the actual COPY/HEADLINES specified in quotes.
```

### Other prompt leakage rules:
- Never use brackets [like this] for instructions — AI renders them as literal text
- Use natural language: "make the headline larger" not "[HEADLINE: 64px bold]"
- Spell out copy in quotes: `Text: "your headline here"` — AI renders what's in quotes

---

## 6. REFERENCE CLASSIFICATION — Know your ref type

Before prompting, classify the reference:

### Simple compositions (use system constants approach):
- Product hero / lifestyle shots
- Before/after split comparisons
- Testimonial cards
- Binary choice (this or that)
- Process flow / step-by-step
- Countdown timers
- Offer/CTA announcements
- Grid/mosaic layouts
- Narrative identity designs

### Complex UI (use edit-first approach):
- Website mockups (nav bars, hero sections, card grids)
- App screenshots (calendar, chat, notification UI)
- Instagram/social card carousels
- Dashboard / analytics views
- Emoji/icon grids with precise spacing
- Any layout with >8 distinct interactive-looking elements

---

## 7. STYLE SPLIT — Editorial vs Graphic

Every variant falls into one of two styles. This determines which DNA qualities to include.

### editorial_photo (lifestyle, hero, testimonial, behind-scenes):
- ALL 8 DNA qualities apply
- Camera craft: 85mm f/1.4, 30-45° angle, directional golden light
- Prop styling: premium lifestyle props
- Two-tone depth: colored wall + cream surface
- Food/product styling: angled, catching light, casting shadows

### graphic_design (UI mockups, split screens, grids, process flows):
- Only DNA #3 (rich color), #6 (typography), #8 (simplicity) apply
- Clean rendering without shallow DOF blur
- No props (UI should be CLEAN)
- Structure and information hierarchy are the design

---

## 8. NANO BANANA PRO EDIT — Technical Reference

### API:
```python
fal_client.subscribe(
    "fal-ai/nano-banana-pro/edit",
    arguments={
        "prompt": prompt,                    # 3-50,000 chars
        "image_urls": [url1, url2, ...],     # flat list of strings, up to 14
        "resolution": "2K",                  # 1K (default), 2K, 4K (2x cost)
    },
)
```

### Upload: `fal_client.upload_file(path)` — returns URL string. NOT data URIs.

### Known limitations:
- Cannot reliably REPLACE text in existing images (original text persists)
- Renders prompt instructions in brackets as literal text
- Renders hex codes/font names as visible text without ANTI_RENDER
- Treats references LOOSELY for complex UI — needs edit-first framing
- Long paragraphs of text remain challenging even at 4K
- ~$0.15/image at 2K resolution

### Strengths:
- Excellent food/product swaps with natural lighting integration
- Excellent color palette shifts
- Excellent scene generation and editorial photography
- Excellent typography rendering (94% accuracy at 2K)
- Up to 14 reference images with explicit role assignment
- Gemini 3 Pro reasoning — understands spatial relationships semantically

### Image ordering matters:
- Image 1 = primary reference (layout/style or the image being edited)
- Image 2+ = content to integrate (product photos, food, additional refs)
- Always reference by number in prompt: "Image 1 is...", "Image 2 is..."

---

## 9. POST-PROCESSING — Less is more

### The universal stack:
1. Resize to target dimensions (e.g., 1080×1350 for IG/Meta Feed 4:5)
2. Film grain (strength 0.014-0.018) — ALWAYS LAST

### What NOT to do:
- NO heavy color filters on AI outputs (makes them look "burnt")
- NO PIL logo stamp (AI renders branding as part of design)
- NO multi-pass AI (compounds errors — single pass maximum)
- NO PIL text overlay (AI renders cohesive text — PIL overlay looks amateur)
- Photography itself IS the aesthetic. Don't filter it.

---

## 10. PARALLEL EXECUTION — Speed patterns

- Use ThreadPoolExecutor for batch generation
- 6 workers for large batches (30+ variants)
- 2 workers + 3s stagger for small fix batches (avoid FAL token DNS contention)
- Upload retry with exponential backoff (2s, 4s, 8s) for transient network errors
- Cost-efficient: iterate at 1K, finalize at 2K

---

## 11. COPY VOICE PRINCIPLES (adapt per brand)

These are universal principles for strong ad copy:
- Write like a sales sifu: layman words, numbers, pain points, clear results
- NO diet culture language unless brand specifically asks (calories, macros, "slim down", "clean eating")
- NO exclamation marks (they cheapen everything)
- Aspirational, not educational — assume the audience is smart
- Brand assumes intelligence — never preach
- Malaysian/local casual speak when targeting local markets ("la", "tapao", lowercase)
- The brand voice should feel like a confident friend, not a corporation

---

## 12. META ADS SAFE ZONES

For Meta (Facebook/Instagram) Feed ads at 4:5 ratio:
- Top ~14% (top eighth): keep relatively clean — Meta places ad labels here
- Bottom ~20% (bottom fifth): keep clean — reserved for CTA buttons
- All critical content in the middle 66%
- Include safe zone instructions in every prompt for ad creatives

---

## QUICK DECISION TREE

```
New creative project:
│
├─ Classify reference → simple composition or complex UI?
│
├─ Simple composition:
│   ├─ Is it photography/lifestyle? → editorial_photo (all 8 DNA qualities)
│   └─ Is it graphic/UI? → graphic_design (color + type + simplicity only)
│   └─ Use system constants approach with ref as "layout guide"
│
├─ Complex UI:
│   └─ Use god mode edit-first approach: "Edit this image, swap only X"
│
├─ Product photos provided?
│   └─ Yes → SACRED. Image 2+. Never AI-generate products.
│
├─ Post-processing:
│   └─ resize → grain → DONE. No filters. No logo stamp.
│
└─ Brand rendering:
    └─ AI renders brand name/logo as part of design. Not PIL overlay.
```
