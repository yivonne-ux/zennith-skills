# Brand Design — Tools & Production Pipeline
> Technical craft guide for logo design and brand identity creation. Compiled 2026-03-21.

---

## 1. LOGO CONSTRUCTION — GOLDEN RATIO METHOD

### The Circle Method (Apple, Twitter, Pepsi)
1. Pre-proportioned circles derived from golden ratio (φ = 1.618) define ALL curves
2. Every arc traces one of these circles exactly
3. Combine, subtract, trim using boolean operations
4. Result: mathematically harmonious curves

### Construction Grid Types

| Grid | Use Case | Famous Examples |
|------|----------|-----------------|
| Golden Ratio Circles | Organic, curved marks | Apple, Twitter bird, Pepsi |
| Square Grid (8x8, 16x16) | Geometric, pixel-perfect | Google, Microsoft |
| Triangular Grid | Dynamic, angular | Mitsubishi, Adidas |
| Circular Grid | Radial symmetry | Target, BMW |
| Baseline Grid | Typography-heavy wordmarks | FedEx, Google |

### Programmatic Golden Ratio Circles (Python)
```python
PHI = 1.6180339887
def golden_circles(base_radius, count=8):
    r = base_radius
    circles = []
    for i in range(count):
        circles.append(round(r, 2))
        r = r / PHI
    return circles
# base 500px -> [500, 309.02, 190.98, 118.03, 72.95, 45.08, 27.86, 17.22]
```

---

## 2. SVG LOGO GENERATION — TOOLS & APIS

| Tool | Output | Text Accuracy | API? | Best For |
|------|--------|---------------|------|----------|
| **Recraft V3/V4** | Native SVG | High | Yes (Replicate) | Vector logos — immediately editable |
| **Ideogram 3.0** | Raster (PNG) | ~95% (best) | Yes | Text-heavy logos |
| **Adobe Firefly** | Native SVG/AI paths | Medium | Yes | Editable native vector paths |
| **Logo Diffusion** | SVG | Medium | Yes | Sketch-to-logo conversion |

### Programmatic SVG Libraries (Python)

| Library | Key Feature | Install |
|---------|-------------|---------|
| **drawsvg** | SVG + PNG + MP4 export | `pip install drawsvg` |
| **svgwrite** | Pure Python, zero deps | `pip install svgwrite` |
| **CairoSVG** | SVG to PNG/PDF conversion | `pip install cairosvg` |
| **svgpathtools** | Parse/manipulate SVG paths | `pip install svgpathtools` |

---

## 3. MONOGRAM CONSTRUCTION

**Types:**
1. **Stacked** — Letters arranged vertically (YSL)
2. **Interlocking** — Letters overlap/interweave (CC, LV)
3. **Contained** — Letters inside geometric shape (HP)
4. **Ligature** — Letters share strokes (GG)

**Interlocking technique:**
1. Choose serif or geometric sans as base
2. Set both letters, overlap at natural intersection points
3. Use two tones or gap-in-stroke to maintain legibility
4. Mirror, rotate, or flip one letter for symmetry
5. Test at 16px (favicon), 64px (social), 500px+ (print)

---

## 4. COLOR SYSTEM TOOLS

| Tool | Method | API? | URL |
|------|--------|------|-----|
| **Coolors** | Spacebar gen, image extraction | Yes | coolors.co |
| **Atmos** | Perceptual easing curves | No | atmos.style |
| **Khroma** | Neural network trained on preferences | No | khroma.co |
| **Leonardo (Adobe)** | Contrast-ratio-based, open source | Yes (npm) | leonardocolor.io |
| **Accessible Palette** | Consistent lightness + contrast | No | accessiblepalette.com |
| **Realtime Colors** | Preview on real website mockup | No | realtimecolors.com |
| **The Color API** | Conversion, naming, schemes | Yes (REST) | thecolorapi.com |

### Python Color Science

| Library | OKLCH? | Key Feature |
|---------|--------|-------------|
| **ColorAide** | Yes | Modern CSS spaces, harmonies, interpolation |
| **colour-science** | Yes | Academic-grade, 100+ color spaces |
| **colormath** | No | DeltaE CIE 2000 distance |

**ColorAide recommended** — supports OKLCH (perceptually uniform), harmonies, interpolation for tint/shade.

### WCAG Contrast Checking
```
https://webaim.org/resources/contrastchecker/?fcolor=1C372A&bcolor=FFFFFF&api
```
AA normal >= 4.5:1, AA large >= 3.0:1, AAA normal >= 7.0:1

---

## 5. TYPOGRAPHY TOOLS

### Type Scale Calculators
| Tool | Key Feature | URL |
|------|-------------|-----|
| **Fluid Type Scale** | CSS clamp() output | fluid-type-scale.com |
| **Typecast** | Visual + CSS/Tailwind export | typecast.pro |

**Common ratios:** Minor Third (1.200), Major Third (1.250), Perfect Fourth (1.333), Golden Ratio (1.618)

### Font Pairing
| Tool | Method |
|------|--------|
| **Monotype Font Pairing** | AI-powered suggestions |
| **Fontjoy** | Deep learning pairing |
| **Typewolf** | Curated pairings with real examples |

### Premium Type Foundries
Grilli Type, Klim Type, Dinamo, Colophon, Commercial Type, Production Type, Pangram Pangram, Sharp Type, OH no Type

---

## 6. BRAND ASSET PIPELINE

### Deliverables Structure
```
Brand_Name/
  Print/  → AI, EPS, PDF, SVG
  Digital/
    PNG/  → full-color (128/256/512/1024), monochrome, reversed
    Favicon/ → .ico (16/32/48), 192px (Android), 512px (PWA), 180px (Apple)
  Social/ → profile pics (IG 320², FB 170²), covers
  Brand Kit/ → color-palette.ase, color-palette.json, fonts/
```

### Logo Variation Matrix
| Variation | Use Case |
|-----------|----------|
| Primary (full) | Hero placement, headers |
| Stacked/Vertical | Square spaces, social |
| Icon/Mark only | Favicons, app icons, watermarks |
| Wordmark only | Text-heavy contexts |
| Monochrome black | Documents, stamps |
| Monochrome white | Dark backgrounds, overlays |
| With tagline | Marketing materials, signage |

---

## 7. BRAND GUIDELINES STRUCTURE

1. **Cover** — brand name, mark, version date
2. **Brand Story** (2-4pp) — mission, vision, values, personality, audience
3. **Logo** (6-10pp) — primary, variations, clear space, minimum size, color variations, incorrect usage
4. **Color** (2-4pp) — primary palette (HEX/RGB/CMYK/Pantone), secondary, tint system, contrast ratios
5. **Typography** (3-5pp) — primary + secondary typefaces, type scale, hierarchy, web fonts + fallbacks
6. **Imagery** (2-4pp) — photography style, illustration, icons, textures
7. **Voice & Tone** (2-3pp) — voice attributes, tone by context, do/don't
8. **Applications** (4-8pp) — business cards, stationery, social templates, website, packaging

### Guidelines Platforms
| Platform | Best For |
|----------|---------|
| **Frontify** | Enterprise, distributed teams, DAM |
| **Corebook** | Design-centric, visual freedom |
| **Gingersauce** | Auto-calculates clear space, proportions |
| **Figma** | AI brand guideline generator (2025+) |

---

## 8. MOCKUP TOOLS

| Tool | API? | Best For |
|------|------|---------|
| **Artboard Studio** | No | Realistic product mockups |
| **Mockuuups Studio** | Yes | Automated generation at scale |
| **SudoMock** | Yes | Developer-first automation |

---

## 9. COMPLETE PRODUCTION PIPELINE

**Phase 1: Discovery** → Brief, competitor analysis, moodboards
**Phase 2: Logo** → AI concepts (Recraft V3/V4 SVG) → grid refinement → Bezier editing → test 16px to 1000px+
**Phase 3: Brand System** → Colors (Coolors + Leonardo + ColorAide) → Typography (Google Fonts + Fluid Type Scale) → Guidelines (Figma AI or Gingersauce)
**Phase 4: Assets** → Batch resize (Python/Pillow), favicons, social exports, mockups, SVG optimization (SVGO)
**Phase 5: Brand Book** → Figma (interactive) or InDesign (print), hosted on Frontify/Corebook
**Phase 6: Production** → NanoBanana with brand prompts, templates with locked variables, Vision QC

---

## 10. TOOL QUICK-REFERENCE

### Must-Have Free Stack
| Need | Tool |
|------|------|
| Vector logo | Figma or Linearity Curve |
| AI logo SVG | Recraft V3 via Replicate |
| AI text logos | Ideogram 3.0 |
| Color palette | Coolors + Leonardo |
| Accessibility | WebAIM API |
| Type scale | Fluid Type Scale |
| Font pairing | Fontjoy or Monotype |
| Fonts | Google Fonts API |
| Mockups | Artboard Studio |
| SVG gen (Python) | drawsvg |
| Color science (Python) | ColorAide |
| Image processing | Pillow |
| SVG optimization | SVGO (npm) |
