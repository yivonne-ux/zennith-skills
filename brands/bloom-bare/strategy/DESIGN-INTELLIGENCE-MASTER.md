# DESIGN INTELLIGENCE MASTER PLAYBOOK
## World-Class Design Firm Operating System
**Compiled: 10 March 2026 | 7 research streams, 200+ sources**

---

## HOW TO USE THIS DOCUMENT

This is the **master index and synthesis** of 7 deep-research guides totaling ~6,700 lines. Each section links to its detailed source. Read this document first for the unified picture, then dive into specific guides for implementation detail.

---

## THE KNOWLEDGE BASE

| # | Document | Lines | Location |
|---|----------|-------|----------|
| 1 | World-Class Design Firms | 1,014 | `research/WORLD-CLASS-DESIGN-FIRMS-RESEARCH.md` |
| 2 | AI Model Decision Matrix | 634 | `research/AI-MODEL-GUIDE.md` |
| 3 | Design Resources Catalog | ~500 | `research/DESIGN-RESOURCES.md` |
| 4 | Production Workflows | 999 | `strategy/DESIGN-PRODUCTION-GUIDE.md` |
| 5 | Pixel-Level Craft Guide | 676 | `strategy/PIXEL-CRAFT-GUIDE.md` |
| 6 | 2026 Design Trends + Children's Brands | 887 | `strategy/DESIGN-TRENDS-RESEARCH-2026.md` |
| 7 | Programmatic Design (Python/Pillow) | 1,982 | `strategy/PROGRAMMATIC-DESIGN-GUIDE.md` |

---

## PART 1: THE DESIGN FIRM MINDSET

### What Separates World-Class from Average

From studying Pentagram, Collins, Sagmeister & Walsh, Wieden+Kennedy, Buck, Nendo, Kenya Hara, and 8 more top firms, these patterns emerge:

**1. Process Before Pixels**
Every great firm follows: Research → Define → Ideate → Prototype → Test. They spend 40-60% of project time in research and definition BEFORE opening a design tool. (Pentagram, Collins, Wolff Olins)

**2. Compliance by Design, Not by Rules**
Pentagram's principle: "Make compliance the path of least resistance." Brand systems should be so well-designed that following them is EASIER than breaking them. This is exactly what our template system does — the Python pipeline enforces brand consistency automatically.

**3. Separation of Template from Instance**
All major brands separate *template creation* (high-skill, done once) from *template population* (lower-skill, done repeatedly). Nike, Airbnb, Apple — they all use this model. Our 8-template system (T1-T8) is architecturally correct.

**4. The "Invisible Design" Standard**
Work toward designs that feel effortless and natural. Good design is invisible — the viewer notices the MESSAGE, not the design. Every element has a purpose. If removing an element doesn't reduce understanding, it should go.

**5. Typography IS the Design**
Paula Scher: "Typography as image — treat letterforms as the central illustrative component." For Bloom & Bare, DX Lactos IS the brand voice. It's not just a font — it's the personality.

### The Roles We Embody

Our Python pipeline collapses the traditional design team into code:

| Traditional Role | Our Python Equivalent |
|---|---|
| Creative Director | Brand DNA document + template architecture decisions |
| Art Director | Template definitions (layout zones, color system, hierarchy) |
| Designer | `bloom_templates.py` — the template builders |
| Production Artist | Batch runner + format adaptation |
| Retoucher | Post-processing pipeline (grain, color correction) |
| QA Reviewer | Automated checks (resolution, contrast, safe zones) |

---

## PART 2: THE AI MODEL DECISION SYSTEM

### The Golden Rule
**AI generates textures. Code renders everything else.**

This is the proven architecture — confirmed by our v1 rejection learnings and validated by industry best practice.

### Quick Decision Matrix

| Design Task | Best Model | Cost |
|---|---|---|
| Background textures | Ideogram V3 | $0.03/img |
| Photorealistic imagery | FLUX 2 Pro | $0.055/img |
| Artistic/stylized | Midjourney V7 | Subscription |
| Photo editing (single pass) | FLUX 2 Kontext Max | ~$0.06/img |
| Multi-image compositing | Nano Banana Pro | $0.15/edit |
| Vector SVG (icons, patterns) | Recraft V3 | Free tier |
| Text in images (if needed) | Ideogram V3 (~95%) | $0.03/img |
| Bulk budget generation | Imagen 4 Fast | $0.02/img |

### Hard Rules (Never Violate)
1. AI must NEVER render brand text, logos, or mascots
2. Single-pass AI maximum — multi-pass compounds errors
3. Grain is ALWAYS the last step
4. OCR-validate after any AI pass that touches text zones
5. AI-generated logos cannot be copyrighted or trademarked

> **Full guide:** `research/AI-MODEL-GUIDE.md`

---

## PART 3: THE CRAFT NUMBERS

### Typography (memorize these)

| Parameter | Value | Why |
|---|---|---|
| Display tracking (48pt+) | -10 to -30 | Large type looks loose at default |
| All-caps tracking | +20 to +75 | Caps designed for mixed case |
| Body line-height | 1.4 - 1.6x | Optimal readability |
| Headline line-height | 1.0 - 1.2x | Tight for impact |
| Hierarchy scale (recommended) | Major Third (1.25x) | Clear, readable steps |
| Max typefaces per design | 2-3 | More = visual chaos |
| Hierarchy levels | 4-6 | Per design piece |
| Hand-kern threshold | 18pt+ | All headlines above this |

### Color

| Parameter | Value |
|---|---|
| 60-30-10 rule | 60% dominant, 30% secondary, 10% accent |
| WCAG AA contrast (normal text) | 4.5:1 minimum |
| WCAG AA contrast (large text) | 3:1 minimum |
| Darker HSB variation | B down 10-30%, S up 5-15% |
| Lighter HSB variation | B up 10-30%, S down 5-20% |
| Hue shift for depth | 5-25 degrees toward nearest primary |

**Bloom & Bare Specific:**
- Black #1A1A1A on cream #F5F0E8 = 14.5:1 ✅ (passes AAA)
- Black #1A1A1A on yellow #F0D637 = 12:1 ✅ (passes AA)
- Yellow #F0D637 on cream #F5F0E8 = 1.3:1 ❌ (NEVER use yellow text on cream)

### Layout (1080x1350)

| Parameter | Value |
|---|---|
| Recommended grid | 6-column (140px cols, 24px gutters, 48px margins) |
| Premium margins | 60-80px (8-12% of width) |
| White space target | 30-40% of canvas |
| Rule-of-thirds intersections | (360,450), (720,450), (360,900), (720,900) |
| Golden section divide | 834px from top |
| Story safe zone top | 200px |
| Story safe zone bottom | 180px |

### Finishing

| Parameter | Value |
|---|---|
| Grain (modern) | 1.4-2.0% (0.014-0.020) |
| Grain (editorial) | 3-5% (0.030-0.050) |
| Clarity boost | +10 to +25 |
| Sharpening | 80-120%, 0.8-1.2px radius |
| Export JPEG quality | 85-92% |
| Pre-upload saturation bump | +5-10% (Instagram desaturates) |
| Target file size | 500KB - 2MB |

> **Full guides:** `strategy/PIXEL-CRAFT-GUIDE.md` + `strategy/DESIGN-PRODUCTION-GUIDE.md`

---

## PART 4: 2026 DESIGN TRENDS — WHAT'S WORKING NOW

### The 3 Most Relevant Trends for Bloom & Bare

**1. Hand-Drawn + Photography Hybrid** (THE trend for children's brands)
Mix real photography with illustrated overlays — hand-drawn arrows, doodle frames, crayon textures, scribble underlines. This is the single most relevant trend. Bloom & Bare's mascot system + organic shapes are perfectly positioned.

**2. Carousel-First Strategy** (1.92% engagement — highest of all formats)
Carousels outperform all other content types. First slide = 80% of the weight. Mixed-media carousels (photo + graphic slides) outperform uniform ones. Our T2 Quote carousel is already built for this.

**3. "Minimalist Maximalism"** (the 2026 sweet spot)
Not pure minimalism (too cold). Not maximalism (too chaotic). The sweet spot: generous white space + one or two elements of bold visual intensity. A single large mascot on a clean cream background with bold DX Lactos type — that IS this trend.

### Bloom & Bare's Strategic Alignment

The research confirms Bloom & Bare's existing brand DNA is **exceptionally well-aligned** with 2026 design culture:
- Cream backgrounds → earthy, organic palettes are trending
- Warm mascot system → character-driven brands (Duolingo playbook) dominate social
- Hand-crafted feel → "imperfect by design" is the 2026 ethos
- Organic shapes → blob/organic forms over sharp geometry

### 10 Action Items from Trends Research

1. Add hand-drawn overlay elements (doodle borders, scribble underlines) to photo content
2. Build mixed-media carousels (photo slide + graphic slide + text slide)
3. Use textured backgrounds (paper, watercolor wash) over flat solid colors
4. Make typography bolder — push display type larger, track tighter
5. Lead with carousel format for all educational + quote content
6. Give each mascot a distinct personality (Sunny = curious, Cloudy = cozy, etc.)
7. Add subtle 3D/clay feel to mascot presentations where possible
8. Plan the 3x3 Instagram grid — alternate content types for visual rhythm
9. Use intentional color rhythm in feed planning (warm → cool → warm)
10. Layer Scandinavian sophistication under the playful surface (for parent appeal)

> **Full guide:** `strategy/DESIGN-TRENDS-RESEARCH-2026.md`

---

## PART 5: THE PRODUCTION PIPELINE

### Batch Production (The 300% Output Method)

```
WRONG:  Design Post 1 → Write Post 1 → Design Post 2 → Write Post 2
RIGHT:  Write ALL captions → Design ALL graphics → Schedule ALL posts
```

Context switching kills productivity. Strict batching by task type increases output by 300% while improving quality by 67%.

### Monthly Production Calendar

| Day | Task | Output |
|---|---|---|
| Monday | Content calendar + briefs | 30 briefs |
| Tue-Wed | Batch write ALL captions | 30 captions |
| Thu-Fri | Batch design ALL graphics | 30 graphics |
| Next Mon | Review + QA pass | 30 approved |
| Tuesday | Schedule 60-70% | ~20 scheduled |
| Ongoing | Reserve 30-40% for reactive | ~10 open slots |

### The Template-Instance Architecture

```python
# Template = created once, carefully (high-skill)
TEMPLATE = {
    "name": "T1-Schedule",
    "size": (1080, 1350),
    "zones": {...},      # Layout architecture
    "typography": {...},  # Font, size, weight per zone
    "colors": {...},      # Palette per element type
}

# Instance = changes per post (lower-skill, automatable)
POST_DATA = {
    "headline": "March Schedule",
    "body": "...",
    "mascots": ["sunny", "cloudy"],
    "theme": "default",
}

# Production loop (batch all at once)
for post in posts:
    image = render_template(TEMPLATE, post)
    image = add_grain(image, 0.016)
    image.save(f"exports/{post['filename']}.png")
```

### Quality Gates (Automated)

Every rendered image should pass:
1. Resolution check (exact 1080x1350)
2. Edge safety (no content in outer 5%)
3. Color palette compliance (sample pixels, verify within brand colors)
4. Text contrast (WCAG AA minimum per text zone)
5. File size sanity (500KB-3MB for PNG)

> **Full guide:** `strategy/DESIGN-PRODUCTION-GUIDE.md`

---

## PART 6: PROGRAMMATIC DESIGN TECHNIQUES

### Key Pillow Techniques for Production

**Custom Tracking (Letter-Spacing):**
Pillow has no built-in tracking. Implement manually with kerning-aware character-by-character rendering. See `PROGRAMMATIC-DESIGN-GUIDE.md` Section 1.

**Supersampled Rendering:**
Render at 2x resolution, downscale with LANCZOS for maximum anti-aliasing quality on text and shapes.

**Blend Modes in NumPy:**
Multiply, Screen, Overlay, Soft Light all implementable via NumPy array math matching Photoshop formulas.

**Organic Blob Generation:**
Sine harmonics + Perlin noise contours create natural, brand-consistent organic shapes programmatically.

**Film Grain (luminosity-dependent):**
Realistic grain that's stronger in midtones, weaker in highlights and shadows — matches real film behavior.

### Tool Recommendation for Bloom & Bare

| Tool | Use For | Status |
|---|---|---|
| **Pillow** (core) | All text, layout, compositing, masks | Current — keep |
| **NumPy** | Grain, blend modes, color manipulation | Current — keep |
| **OpenCV** | Inpainting, text removal from blanks | Current — keep |
| **Cairo** (optional add) | Mesh gradients, vector shapes if needed | Consider |
| **Remotion** (future) | If expanding to animated/video content | Not yet needed |

> **Full guide:** `strategy/PROGRAMMATIC-DESIGN-GUIDE.md` (1,982 lines with code snippets)

---

## PART 7: RESOURCE LIBRARY

### Top 5 Resources Per Category

**Inspiration:** Behance, Dribbble, It's Nice That, Brand New, Are.na
**Typography:** Typewolf, Fonts In Use, Fontshare, Pangram Pangram, Type Scale
**Photography:** Unsplash, Pexels, Stocksy (premium)
**Color:** Coolors, Adobe Color, Realtime Colors, Happy Hues, WebAIM Contrast Checker
**Education:** Refactoring UI (book), Laws of UX, The Futur (YouTube), Smashing Magazine
**Textures:** Subtle Patterns, Textures.com, Transparent Textures

> **Full guide:** `research/DESIGN-RESOURCES.md`

---

## PART 8: BLOOM & BARE — APPLYING IT ALL

### Current System Status

| Template | Approach | Blank Source | Quality |
|---|---|---|---|
| T1 Schedule | Programmatic | — | ✅ Production-ready |
| T2 Quote Cover | Extracted blank | Original artwork | ✅ Clean, original pixels |
| T2 Quote Speech | Extracted blank | Original artwork | ✅ Excellent |
| T2 Quote Content | Extracted blank | Original artwork | ✅ Excellent |
| T3 Event Poster | Programmatic | — | ✅ Production-ready |
| T4 Promo | Programmatic | — | ✅ Production-ready |
| T5 Photo Story | Photo overlay | — | ✅ Production-ready |
| T6 Announcement | Programmatic | — | ✅ Production-ready |
| T7 Educational | Programmatic | — | ✅ Production-ready |
| T8 Hiring | Programmatic | — | ✅ Production-ready |

### Pipeline Architecture (Locked)

```
LAYER 1: Brand Assets (static, pre-made)
  → Logos (8 variants × 4 sizes)
  → Mascots (6 chars × 4 sizes)
  → Fonts (DX Lactos + Mabry Pro family)
  → Template blanks (extracted from originals)

LAYER 2: Template Engine (bloom_templates.py)
  → 8 template builders
  → Data-driven rendering
  → Organic shape system (waves, blobs, clouds)
  → Mask-based compositing (no dark halo artifacts)

LAYER 3: Post-Processing
  → Light grain (0.014-0.018)
  → sRGB color profile
  → 1080x1350 PNG export

LAYER 4: Quality Assurance
  → Resolution verification
  → Visual comparison against originals
  → Brand palette compliance
```

### Immediate Next Steps

1. **Content Calendar** — Define March 2026 content (30 posts across 8 template types)
2. **Batch Production** — Run all 30 posts through the pipeline
3. **Background Texture Library** — Generate 20-30 AI textures (Ideogram V3) for future template variations
4. **Hand-Drawn Overlay Pack** — Create doodle borders, scribble underlines, arrow elements for T5 Photo Story
5. **Carousel Expansion** — Build more carousel variants (T7 Educational as carousel, T3 Event as carousel)
6. **Mascot Personality System** — Define distinct personality per mascot for caption voice

---

## APPENDIX: THE DESIGN OBSESSION CHECKLIST

Before publishing ANY design, verify:

- [ ] Typography hierarchy passes the squint test (blur to 15px — still readable?)
- [ ] Display type is hand-kerned (check AV, AT, WA pairs)
- [ ] All-caps text has +20 to +75 tracking
- [ ] Color contrast meets WCAG AA (4.5:1 for body, 3:1 for large)
- [ ] No yellow text on cream backgrounds
- [ ] Margins are 60-80px (premium feel)
- [ ] White space is 30-40% of canvas
- [ ] Grain applied LAST at 0.014-0.018
- [ ] Logo is crisp (composite PNG, never AI-generated)
- [ ] Mascots are original PNGs (never AI-drawn)
- [ ] File is exactly 1080x1350 for feed
- [ ] File size is 500KB-2MB
- [ ] sRGB color profile embedded
- [ ] Edge safety — no critical content within 5% of edges
