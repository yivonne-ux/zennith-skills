# REFERENCE-DRIVEN DESIGN ADAPTATION PIPELINE
## Bloom & Bare — Design Intelligence Architecture v5
**Created: 10 March 2026 | Based on 3 deep-research streams**

---

## THE CORE IDEA

**Old workflow**: Build templates from scratch → fill with data
**New workflow**: Reference image in → deep analysis → rebuild as Bloom & Bare

The pipeline takes ANY reference image (Pinterest save, competitor post, mood board image) and produces a Bloom & Bare branded design that captures the reference's compositional intelligence while being 100% on-brand.

---

## THE 5-STAGE PIPELINE

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1: INGEST                                        │
│  Reference image → resize → prepare for analysis        │
├─────────────────────────────────────────────────────────┤
│  STAGE 2: DEEP ANALYSIS (Vision AI + OpenCV)            │
│  → Layout zones (bounding boxes, percentages)           │
│  → Color palette (k-means quantization)                 │
│  → Typography hierarchy (roles, sizes, weights)         │
│  → Element inventory (text, image, shape, character)    │
│  → Compositional structure (alignment, whitespace)      │
│  → Visual weight map                                    │
│  OUTPUT: Structured Layout Spec (JSON)                  │
├─────────────────────────────────────────────────────────┤
│  STAGE 3: BRAND MAPPING                                 │
│  Reference palette → BB palette (CIEDE2000 in LAB)      │
│  Reference fonts → DX Lactos / Mabry Pro                │
│  Reference character → BB mascot (best match)           │
│  Reference logo position → BB logo                      │
│  Reference content → BB content (user provides)         │
│  OUTPUT: Mapped Layout Spec (JSON)                      │
├─────────────────────────────────────────────────────────┤
│  STAGE 4: RECONSTRUCTION                                │
│  Option A: Pure Pillow (programmatic, pixel-perfect)    │
│  Option B: AI mood layer + Pillow brand layer           │
│  OUTPUT: 1080x1350 PNG                                  │
├─────────────────────────────────────────────────────────┤
│  STAGE 5: QA + REFINEMENT                               │
│  SSIM comparison to reference (layout fidelity)         │
│  Brand palette compliance check                         │
│  Vision LLM audit (8 dimensions)                        │
│  OUTPUT: Approved design or refinement notes             │
└─────────────────────────────────────────────────────────┘
```

---

## STAGE 1: INGEST

Simple — load the reference image, normalize it.

```python
def ingest(ref_path):
    img = Image.open(ref_path).convert("RGB")
    # Resize longest edge to 1568px (Claude Vision optimal)
    # Store original dimensions for proportion mapping
    return {"image": img, "width": img.width, "height": img.height}
```

---

## STAGE 2: DEEP ANALYSIS

This is the intelligence core. Two systems work in parallel:

### 2A: Claude Vision — Semantic Understanding

Claude Vision analyzes the reference and returns a structured JSON layout spec. It understands WHAT each element is and its ROLE in the design.

**The Analysis Prompt (tuned for design decomposition):**

```
Analyze this graphic design image as a world-class art director would.
For each distinct visual element, provide:

1. element_type: [text_block | image_zone | solid_color_block | character_mascot | logo | icon | decorative_shape | badge_pill | divider]
2. bounds: {x_pct, y_pct, w_pct, h_pct} as percentage of image dimensions
3. For text_blocks:
   - content (the actual text if readable)
   - font_role: [display_headline | subheadline | body | caption | label | cta]
   - size_relative: [xs | sm | md | lg | xl | xxl]
   - weight: [light | regular | medium | bold | black]
   - case: [sentence | upper | lower | title]
   - alignment: [left | center | right]
   - color_hex
   - estimated_tracking: [tight | normal | loose | very_loose]
4. For solid_color_blocks: {color_hex, role: [background | accent_block | container | overlay]}
5. For character_mascot: {description, estimated_size_pct, mood/expression}
6. For decorative_shape: {shape_type, color_hex, role}
7. z_order: layer order (0=back, higher=front)
8. visual_role: what this element DOES in the composition

Also provide:
- layout_type: [single_column | split_horizontal | split_vertical | centered_stack | grid | freeform | hero_character | type_dominant]
- background: {type, primary_color_hex, secondary_color_hex}
- dominant_palette: [hex colors in order of visual prominence]
- margins: {top_pct, right_pct, bottom_pct, left_pct}
- whitespace_pct: estimated percentage of canvas that is empty/background
- visual_weight: where the eye goes first, second, third
- mood: [playful | sophisticated | bold | minimal | warm | energetic | calm]
- composition_notes: what makes this design work (the "why")

Return ONLY valid JSON.
```

### 2B: OpenCV — Spatial Precision

Run in parallel with the AI analysis to get exact pixel-level data:

```python
def cv_analyze(img):
    """Extract precise spatial data from reference image."""
    arr = np.array(img)

    # 1. Color quantization (dominant palette)
    pixels = arr.reshape(-1, 3)
    small = cv2.resize(arr, (200, 200)).reshape(-1, 3)
    kmeans = MiniBatchKMeans(n_clusters=8).fit(small)
    palette = kmeans.cluster_centers_.astype(int)
    counts = np.bincount(kmeans.labels_)

    # 2. Edge detection (layout skeleton)
    gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
    edges = cv2.Canny(gray, 50, 150)

    # 3. Connected components (element bounding boxes)
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    n_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(binary)

    # 4. Margin detection (distance from edges to nearest content)
    # 5. Grid line detection (Hough transform for alignment axes)

    return {
        "palette": palette,
        "palette_weights": counts / counts.sum(),
        "edges": edges,
        "bounding_boxes": stats,
        "centroids": centroids,
    }
```

### 2C: Merge Results

Combine Claude's semantic understanding with OpenCV's spatial precision:
- Claude says "this is a headline at roughly top-center"
- OpenCV says "there's a text region at (120, 85, 840, 180) exactly"
- Merged: "headline text at (120, 85, 840, 180), font_role=display_headline, size=xxl, weight=bold, alignment=center"

---

## STAGE 3: BRAND MAPPING

### Color Mapping (CIEDE2000 in LAB space)

Not just "closest color" — map by PERCEPTUAL ROLE:

```python
from skimage.color import rgb2lab, deltaE_ciede2000

BB_PALETTE = {
    "background": (245, 240, 232),  # cream
    "text":       (26, 26, 26),     # black
    "yellow":     (240, 214, 55),
    "blue":       (157, 213, 219),
    "green":      (125, 197, 145),
    "coral":      (240, 155, 139),
    "lavender":   (184, 160, 200),
    "orange":     (232, 138, 58),
    "white":      (255, 255, 255),
}

def map_palette(ref_palette, ref_roles):
    """Map reference colors to BB palette by role, then by perceptual distance."""
    mapping = {}
    for ref_color, role in zip(ref_palette, ref_roles):
        if role == "background":
            # Light backgrounds → BB cream; dark → BB black or mascot color
            mapping[ref_color] = BB_PALETTE["background"]
        elif role == "primary_text":
            mapping[ref_color] = BB_PALETTE["text"]
        else:
            # Find closest BB accent color via CIEDE2000
            best = min(BB_PALETTE.items(),
                       key=lambda kv: deltaE_ciede2000(
                           rgb2lab(ref_color), rgb2lab(kv[1])))
            mapping[ref_color] = best[1]
    return mapping
```

### Font Mapping

```python
FONT_MAP = {
    # Reference font role → BB font
    "display_headline": ("DX Lactos", "regular"),   # THE brand voice
    "subheadline":      ("Mabry Pro", "black"),
    "body":             ("Mabry Pro", "regular"),
    "caption":          ("Mabry Pro", "regular"),
    "label":            ("Mabry Pro", "bold"),
    "cta":              ("Mabry Pro", "bold"),
}

# Size mapping: reference relative size → BB pt size (on 1080x1350 canvas)
SIZE_MAP = {
    "xxl": 160,   # MASSIVE display (Pinterest DNA)
    "xl":  100,
    "lg":  64,
    "md":  36,
    "sm":  26,
    "xs":  20,
}
```

### Asset Mapping

```python
def map_character(ref_description, ref_mood):
    """Map reference character/mascot to best BB mascot match."""
    # By color affinity
    color_map = {
        "yellow": "sunny", "gold": "sunny", "star": "sunny",
        "blue": "cloudy", "sky": "cloudy", "cloud": "cloudy",
        "green": "sprout", "leaf": "sprout", "plant": "sprout",
        "pink": "heartie", "red": "heartie", "heart": "heartie",
        "purple": "petal", "lavender": "petal", "flower": "petal",
        "orange": "tangy",
    }
    # By mood
    mood_map = {
        "happy": "sunny", "excited": "sunny", "energetic": "sunny",
        "calm": "cloudy", "peaceful": "cloudy", "sleepy": "cloudy",
        "growing": "sprout", "curious": "sprout", "learning": "sprout",
        "loving": "heartie", "caring": "heartie", "warm": "heartie",
        "playful": "petal", "creative": "petal", "silly": "petal",
        "smart": "tangy", "nerdy": "tangy", "thinking": "tangy",
    }
    # Try color first, then mood
    for keyword, mascot in color_map.items():
        if keyword in ref_description.lower():
            return mascot
    for keyword, mascot in mood_map.items():
        if keyword in ref_mood.lower():
            return mascot
    return "sunny"  # default
```

---

## STAGE 4: RECONSTRUCTION

### Option A: Pure Pillow (Programmatic)

Best for: flat graphic designs, typography-dominant layouts, clean illustrations.
This is what the current bloom_core.py pipeline does.

```python
def reconstruct_pillow(mapped_spec):
    """Build the design from the mapped layout spec using Pillow."""
    canvas = new_canvas(bg=mapped_spec["background"]["color"])

    # Sort elements by z_order
    elements = sorted(mapped_spec["elements"], key=lambda e: e["z_order"])

    for elem in elements:
        bounds = elem["bounds"]  # {x_pct, y_pct, w_pct, h_pct}
        x = int(bounds["x_pct"] / 100 * W)
        y = int(bounds["y_pct"] / 100 * H)
        w = int(bounds["w_pct"] / 100 * W)
        h = int(bounds["h_pct"] / 100 * H)

        if elem["type"] == "text_block":
            font_name, weight = FONT_MAP[elem["font_role"]]
            size = SIZE_MAP[elem["size_relative"]]
            font = load_font(font_name, weight, size)
            draw_text(canvas, elem["content"], font, x, y, w,
                      color=elem["color"], align=elem["alignment"],
                      tracking=TRACKING_MAP[elem["tracking"]])

        elif elem["type"] == "solid_color_block":
            draw_color_block(canvas, x, y, w, h,
                             color=elem["color"], radius=elem.get("radius", 0))

        elif elem["type"] == "character_mascot":
            mascot = load_mascot(elem["mascot_name"], size=h)
            composite(canvas, mascot, cx=x+w//2, cy=y+h//2)

        elif elem["type"] == "logo":
            add_logo(canvas, position=elem["position"], size=w)

        elif elem["type"] == "decorative_shape":
            draw_shape(canvas, elem["shape_type"], x, y, w, h, elem["color"])

    # Post-process
    canvas = apply_paper_texture(canvas, intensity=0.02)
    canvas = add_grain(canvas, amount=0.016)
    return canvas
```

### Option B: AI Mood Layer + Pillow Brand Layer (Hybrid)

Best for: textured/photographic references, organic/hand-drawn feels, complex backgrounds.

```
Step 1: Extract Canny edges from reference (OpenCV)
Step 2: Generate mood layer via FLUX Canny Pro or FLUX.2 Flex
         - Input: edge map + brand-constrained prompt
         - Prompt includes BB HEX codes for color control
         - Single pass only (never multi-pass)
Step 3: Composite brand elements on top via Pillow
         - All text rendered with actual font files
         - All mascot PNGs composited
         - Logo PNGs composited
Step 4: Post-process (grain, always last)
```

**When to use Option A vs B:**
| Reference type | Approach |
|---|---|
| Flat graphic design, solid colors | Option A (Pure Pillow) |
| Textured, hand-drawn, organic | Option B (AI mood + Pillow brand) |
| Photography with overlays | Option B |
| Typography-dominant | Option A |
| Complex illustration | Option B for base, A for text/brand |

---

## STAGE 5: QA + REFINEMENT

### Layout Fidelity Check (SSIM)

```python
from skimage.metrics import structural_similarity as ssim

def check_layout_fidelity(reference, output):
    """Compare structural similarity between reference and output."""
    # Resize both to same dimensions
    ref_gray = cv2.cvtColor(np.array(reference.resize((540, 675))), cv2.COLOR_RGB2GRAY)
    out_gray = cv2.cvtColor(np.array(output.resize((540, 675))), cv2.COLOR_RGB2GRAY)
    score = ssim(ref_gray, out_gray)
    # Score >= 0.60 = good structural match for adapted (not copied) design
    # Score >= 0.80 = very close layout match
    return score
```

### Brand Palette Compliance

```python
def check_brand_compliance(output):
    """Verify output uses only BB brand colors."""
    pixels = np.array(output.resize((200, 200))).reshape(-1, 3)
    kmeans = MiniBatchKMeans(n_clusters=6).fit(pixels)
    output_palette = kmeans.cluster_centers_

    for color in output_palette:
        distances = [deltaE_ciede2000(rgb2lab(color), rgb2lab(bb))
                     for bb in BB_PALETTE.values()]
        if min(distances) > 15:  # threshold for "off-brand"
            return False, f"Off-brand color detected: {color}"
    return True, "All colors on-brand"
```

### Vision LLM Audit (8 dimensions for BB)

```python
BB_AUDIT_DIMS = [
    "palette_match",      # Uses only BB brand colors
    "mascot_intact",      # Mascot is crisp, original PNG (not AI-drawn)
    "text_readable",      # All text passes squint test, WCAG AA contrast
    "logo_present",       # BB logo is present and correctly placed
    "layout_fidelity",    # Captures the reference's compositional structure
    "crop_safe",          # No critical content in outer 5%
    "font_correct",       # DX Lactos for headlines, Mabry Pro for body
    "brand_mood",         # Warm, playful, intentional (not cold or chaotic)
]
```

---

## THE LAYOUT SPEC FORMAT

The JSON format that flows between stages:

```json
{
  "meta": {
    "reference_path": "references/6Q/example.jpg",
    "reference_dimensions": {"w": 1080, "h": 1350},
    "target_dimensions": {"w": 1080, "h": 1350},
    "analysis_model": "claude-opus-4-6",
    "timestamp": "2026-03-10T14:00:00Z"
  },
  "composition": {
    "layout_type": "hero_character",
    "background": {
      "type": "solid",
      "color_hex": "#F5F0E8",
      "reference_color_hex": "#FFFFFF"
    },
    "margins_pct": {"top": 5, "right": 6, "bottom": 5, "left": 6},
    "whitespace_pct": 35,
    "mood": "playful",
    "visual_flow": ["mascot_hero", "headline", "details_card"]
  },
  "elements": [
    {
      "id": "bg_block",
      "type": "solid_color_block",
      "role": "accent_background",
      "bounds_pct": {"x": 0, "y": 0, "w": 100, "h": 100},
      "color_hex": "#F0D637",
      "reference_color_hex": "#FF6B35",
      "z_order": 0
    },
    {
      "id": "headline",
      "type": "text_block",
      "role": "display_headline",
      "bounds_pct": {"x": 10, "y": 8, "w": 80, "h": 15},
      "content": "MARCH",
      "font_role": "display_headline",
      "size_relative": "xxl",
      "weight": "regular",
      "case": "upper",
      "alignment": "center",
      "color_hex": "#1A1A1A",
      "tracking": "tight",
      "z_order": 3
    },
    {
      "id": "hero_mascot",
      "type": "character_mascot",
      "role": "hero",
      "bounds_pct": {"x": 25, "y": 55, "w": 50, "h": 40},
      "mascot_name": "sunny",
      "z_order": 2
    },
    {
      "id": "info_card",
      "type": "solid_color_block",
      "role": "container",
      "bounds_pct": {"x": 6, "y": 28, "w": 88, "h": 30},
      "color_hex": "#FFFFFF",
      "corner_radius_pct": 2,
      "z_order": 1
    },
    {
      "id": "logo",
      "type": "logo",
      "role": "branding",
      "bounds_pct": {"x": 35, "y": 2, "w": 30, "h": 5},
      "variant": "horizontal-wordmark",
      "z_order": 4
    }
  ]
}
```

---

## TOOLS & DEPENDENCIES

### Already Have (Current Stack)
- Python 3.x + Pillow (rendering engine)
- NumPy (grain, color manipulation)
- OpenCV (image analysis)
- Brand assets (fonts, mascots, logos as PNGs)

### Need to Add
| Tool | Purpose | Install |
|---|---|---|
| `scikit-learn` | K-Means color quantization | `pip install scikit-learn` |
| `scikit-image` | SSIM comparison, CIEDE2000 color distance | `pip install scikit-image` |
| `anthropic` | Claude Vision API for design analysis | `pip install anthropic` |
| `fal-client` | FLUX.2 Flex / FLUX Canny Pro (Option B only) | `pip install fal-client` |

### API Costs (per design)
| Service | Use | Cost |
|---|---|---|
| Claude Vision (analysis) | Stage 2 | ~$0.01-0.03 |
| FLUX.2 Flex (mood layer) | Stage 4 Option B only | ~$0.02-0.05 |
| FLUX Canny Pro (layout-guided) | Stage 4 Option B only | ~$0.05 |
| Total (Option A — pure Pillow) | | ~$0.01-0.03 |
| Total (Option B — hybrid) | | ~$0.04-0.08 |

---

## WORKFLOW IN PRACTICE

### Daily Usage Pattern

```
User saves a Pinterest image to references/ folder
    ↓
Runs: python3 bloom_adapt.py references/new-ref.jpg --content "MARCH SCHEDULE" --mascot sunny
    ↓
Pipeline:
  1. Claude Vision analyzes reference → layout spec JSON
  2. Maps colors/fonts/assets to BB brand
  3. Reconstructs with Pillow (Option A) or FLUX+Pillow (Option B)
  4. Runs QA checks
  5. Saves to exports/adapted/
    ↓
User reviews output, provides feedback
    ↓
Iterate: adjust content, swap mascot, tweak layout
```

### Batch Production

```
User provides:
  - 10 Pinterest references (different compositions)
  - Content for each (headlines, details, mascot assignments)
    ↓
Pipeline processes all 10 in parallel
    ↓
Output: 10 unique, on-brand BB designs
         each capturing the compositional intelligence of its reference
         but 100% Bloom & Bare in execution
```

---

## KEY PRINCIPLES

1. **Reference = composition, not content.** We take the STRUCTURE, not the specifics.
2. **AI analyzes, code renders.** Vision AI decomposes the reference. Pillow builds the output. AI never touches brand text/logos/mascots.
3. **Brand mapping is perceptual, not mechanical.** Colors map by role (their accent → our accent), not by proximity.
4. **Every design is auditable.** The layout spec JSON is a human-readable record of every design decision.
5. **The pipeline learns.** Each successful adaptation refines our understanding of what works for BB.

---

## IMMEDIATE NEXT STEPS

1. **Build `bloom_adapt.py`** — the main adaptation script
2. **Build `bloom_analyze.py`** — the Claude Vision analysis module
3. **Test with 5 Pinterest references** from the existing `references/` folder
4. **Compare outputs against v4 templates** for quality benchmark
5. **Iterate the analysis prompt** based on real results
