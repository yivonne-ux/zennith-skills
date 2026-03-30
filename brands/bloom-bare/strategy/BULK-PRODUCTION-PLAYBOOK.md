# BLOOM & BARE — Bulk Content Production Playbook
*Phase 1: Research & Architecture. 9 March 2026.*

---

## EXECUTIVE SUMMARY

This document reverse-engineers Bloom & Bare's existing 221+ social posts, 37+ Pinterest references, and brand DNA into a repeatable, bulk-producible content system. It defines the template architecture, production workflow, tool stack, and quality gates needed to produce 20-50 branded IG posts per month at consistent, high quality — without per-post manual design.

---

## PART 1: REVERSE ENGINEERING — WHAT MAKES BB DESIGNS WORK

### 1.1 Decomposed Design Anatomy (from 15 audited posts)

Every Bloom & Bare social post is built from **7 layers**, stacked in this order:

```
LAYER 7 (top)  → Logo (small, top-center or top-left)
LAYER 6        → Text (headline in DX Lactos + body in Mabry Pro)
LAYER 5        → Badges/Highlights (yellow starburst, salmon circle, highlight swoosh)
LAYER 4        → Content containers (rounded-corner boxes, speech bubbles)
LAYER 3        → Mascot characters (1-6, as accents or footer lineup)
LAYER 2        → Decorative shapes (wavy organic blobs, curved dividers)
LAYER 1 (base) → Background (cream #F5F0E8, or seasonal color, or photo)
```

### 1.2 The 8 Content Archetypes (from 6 months of posts)

| # | Archetype | Frequency | Layout | Example |
|---|-----------|-----------|--------|---------|
| A1 | **Weekly Schedule** | 4×/month | Grid: days × time slots, emoji legend, mascot accents | Sep/Oct/Nov/Dec/Jan/Feb schedules |
| A2 | **Quote / Values** | 2-4×/month | Centered headline, starburst or heart grid, 1 mascot accent | "Love Languages for Kids", "Things I'll Teach My Daughter" |
| A3 | **Workshop/Event Poster** | 2-4×/month | Large headline, body details, mascot footer, bilingual EN/CN | Holiday Programme, Bath Slime, Christmas Workshop |
| A4 | **Promo/Offer** | 1-2×/month | Price hero, yellow badge, package comparison, CTA | Sept Promo, 11:11, 10% Off |
| A5 | **Photo Storytelling** | 2-4×/month | Full-bleed UV photo, curved text banner overlay, logo | "The Way We Play", BTS, Glow Bunny |
| A6 | **Announcement/Notice** | 1-2×/month | Yellow banner headline, body text, small mascot | CNY Break Notice, reopening |
| A7 | **Educational/Info** | 1-2×/month | Info-forward, small mascots as accents, ingredient/benefit lists | Slime ingredients, "Did You Know?" |
| A8 | **Hiring/Recruitment** | As needed | Bold headline, bilingual job details, mascot lineup, coral container | Hiring posts |

### 1.3 Color Rules (observed across all posts)

| Context | Background | Accent 1 | Accent 2 | Text |
|---------|-----------|----------|----------|------|
| Default/Evergreen | Cream #F5F0E8 | Yellow #F0D637 | Coral #F09B8B | Black #1A1A1A |
| Autumn/Halloween | Cream/Tan | Rust orange #D4763A | Purple #B8A0C8 | Black |
| Christmas | Cream | Forest green #7DC591 | Coral red | Black |
| CNY | Cream/Gold | Red #C23A3A | Gold #F0D637 | Black |
| Valentine/Love | Cream/Pink | Lavender #B8A0C8 | Coral #F09B8B | Black |
| Promo/Sale | Sage green #8ECFAB | Yellow #F0D637 | Salmon #F2A0A0 | Black |

### 1.4 Typography Rules (observed)

| Element | Font | Weight | Size (est.) | Case | Color |
|---------|------|--------|-------------|------|-------|
| Primary headline | DX Lactos | Regular (it's already bold) | 72-120pt | Mixed/Title | Black |
| Sub-headline | Mabry Pro | Bold | 36-48pt | UPPER or Title | Black |
| Body text | Mabry Pro | Regular/Medium | 24-32pt | Sentence | Black |
| Badge/label | Mabry Pro | Bold | 20-28pt | UPPER | White on color |
| Chinese text | System CJK sans | Regular-Bold | Matches EN equivalent | N/A | Black |
| Price | DX Lactos | Regular | 64-96pt | N/A | Black or Crimson |
| Schedule cells | Mabry Pro | Regular | 18-22pt | Sentence | Black/Teal |
| Logo text | DX Lactos | Regular | Fixed lockup | "Bloom & Bare" | Black |

### 1.5 Mascot Usage Patterns

| Pattern | When | Which mascots | Placement |
|---------|------|--------------|-----------|
| **Footer lineup** | Event posters, schedules, hiring | All 6 in a row | Bottom edge, overlapping slightly |
| **Single accent** | Quotes, announcements, promos | 1 (usually Sunny or Heartie) | Bottom-left or bottom-right corner |
| **Paired accent** | Schedules, info posts | 2 (contrasting pair) | Opposite corners |
| **Scattered** | Event posters, holiday content | 3-4, different sizes | Peeking from edges/corners |
| **None** | Photo storytelling, values content | N/A | N/A — let the photo speak |

---

## PART 2: TEMPLATE ARCHITECTURE

### 2.1 Template Registry (8 templates → covers all content needs)

```python
TEMPLATES = {
    "T1_schedule": {
        "name": "Weekly Schedule Grid",
        "canvas": (1080, 1350),
        "bg": "#F5F0E8",
        "zones": {
            "header":   {"y": 0,    "h": 180,  "content": "month + title"},
            "grid":     {"y": 180,  "h": 900,  "content": "day × timeslot matrix"},
            "legend":   {"y": 1080, "h": 120,  "content": "emoji + session type key"},
            "mascots":  {"y": 1200, "h": 150,  "content": "2 mascots, opposite corners"},
        },
        "seasonal_override": True,  # palette shifts per month
    },

    "T2_quote": {
        "name": "Quote / Values Card",
        "canvas": (1080, 1350),
        "bg": "#F5F0E8",
        "zones": {
            "headline": {"y": 300,  "h": 500,  "content": "large DX Lactos centered"},
            "subtext":  {"y": 820,  "h": 100,  "content": "small Mabry Pro italic or regular"},
            "mascot":   {"y": 1050, "h": 200,  "content": "1 mascot, bottom-left"},
            "logo":     {"y": 1250, "h": 60,   "content": "horizontal wordmark, centered"},
        },
        "variants": ["highlight_swoosh", "starburst_frame", "heart_grid"],
    },

    "T3_event_poster": {
        "name": "Workshop / Event Poster",
        "canvas": (1080, 1350),
        "bg": "#F5F0E8",
        "zones": {
            "logo":      {"y": 40,   "h": 80,   "content": "logo top-center"},
            "headline":  {"y": 140,  "h": 300,  "content": "DX Lactos massive"},
            "details":   {"y": 460,  "h": 350,  "content": "date/time/age/price in pills"},
            "early_bird":{"y": 830,  "h": 200,  "content": "rounded box with FREE items"},
            "cta":       {"y": 1050, "h": 120,  "content": "register now + QR"},
            "mascots":   {"y": 1180, "h": 170,  "content": "footer lineup or scattered"},
        },
        "bilingual": True,
    },

    "T4_promo": {
        "name": "Promo / Offer Card",
        "canvas": (1080, 1350),
        "bg": "#8ECFAB",  # or seasonal
        "zones": {
            "banner":   {"y": 100,  "h": 200,  "content": "yellow swoosh + offer headline"},
            "packages": {"y": 350,  "h": 600,  "content": "pricing tiers in rounded boxes"},
            "cta":      {"y": 980,  "h": 150,  "content": "promo code + validity"},
            "mascot":   {"y": 1150, "h": 200,  "content": "1 mascot accent"},
        },
    },

    "T5_photo_story": {
        "name": "Photo Storytelling",
        "canvas": (1080, 1350),
        "bg": "photo_bleed",
        "zones": {
            "photo":     {"y": 0,    "h": 1350, "content": "full-bleed UV/activity photo"},
            "text_band": {"y": 900,  "h": 250,  "content": "curved lavender band + white text"},
            "logo":      {"y": 40,   "h": 60,   "content": "white logo, top-left"},
        },
    },

    "T6_announcement": {
        "name": "Announcement / Notice",
        "canvas": (1080, 1350),
        "bg": "#F5F0E8",
        "zones": {
            "banner":  {"y": 300,  "h": 150,  "content": "yellow banner + headline"},
            "body":    {"y": 500,  "h": 400,  "content": "Mabry Pro body text"},
            "mascot":  {"y": 1050, "h": 200,  "content": "1 small mascot"},
            "logo":    {"y": 1250, "h": 60,   "content": "centered logo"},
        },
    },

    "T7_educational": {
        "name": "Educational / Info Card",
        "canvas": (1080, 1350),
        "bg": "#F5F0E8",
        "zones": {
            "hook":     {"y": 80,   "h": 200,  "content": "'DID YOU KNOW?' in starburst"},
            "content":  {"y": 300,  "h": 700,  "content": "info blocks with icons"},
            "mascots":  {"y": 1050, "h": 200,  "content": "2 mascots as accents"},
            "logo":     {"y": 1270, "h": 60,   "content": "centered logo"},
        },
    },

    "T8_hiring": {
        "name": "Hiring / Recruitment",
        "canvas": (1080, 1350),
        "bg": "#F5F0E8",
        "zones": {
            "headline":  {"y": 100,  "h": 250,  "content": "'we are hiring' DX Lactos"},
            "details":   {"y": 380,  "h": 500,  "content": "role/salary/hours in coral box"},
            "mascots":   {"y": 950,  "h": 250,  "content": "full 6-mascot lineup"},
            "logo":      {"y": 1250, "h": 60,   "content": "centered logo"},
        },
        "bilingual": True,
    },
}
```

### 2.2 Variant System

Each template supports **variants** — small layout/color modifications that prevent visual monotony:

| Variant Type | What Changes | Example |
|-------------|-------------|---------|
| **Seasonal palette** | bg color, accent colors, mascot tint | Autumn = warm rust + gold |
| **Mascot rotation** | Which mascot(s), placement | Sunny this week, Petal next |
| **Accent shape** | Starburst vs highlight swoosh vs circle badge | Rotates per post |
| **Layout flip** | Left-align vs center vs right-accent | Prevents same-same feel |
| **Photo vs graphic** | Photo-first vs mascot-first for same content | A/B testing |

---

## PART 3: PRODUCTION WORKFLOW

### 3.1 The Pipeline (Python-first, AI-assisted)

```
┌──────────────────────────────────────────────────────────┐
│  CONTENT BRIEF (spreadsheet / Airtable)                  │
│  → headline_en, headline_cn, body_en, body_cn,           │
│    template_id, mascot_ids, season, food/photo path      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  LAYER 1: BACKGROUND GENERATION (one-time library)       │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Ideogram V3 or GPT-4o generates 30-50 backgrounds  │  │
│  │ → pastel watercolors, organic wavy shapes,          │  │
│  │   confetti, playground textures                     │  │
│  │ → Curated into backgrounds/ library                 │  │
│  │ → NEVER regenerated per-post (reused)               │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  LAYER 2: PYTHON TEMPLATE ENGINE (per-post)              │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 1. Load template layout (T1-T8)                     │  │
│  │ 2. Paint background (solid color or library image)  │  │
│  │ 3. Composite decorative shapes (wavy blobs, curves) │  │
│  │ 4. Composite mascot PNGs (from assets/mascots/)     │  │
│  │ 5. Render ALL text (DX Lactos + Mabry Pro + CJK)   │  │
│  │ 6. Render badges/pills/highlights                   │  │
│  │ 7. Composite logo PNG                               │  │
│  │ 8. Apply light grain (0.014-0.018)                  │  │
│  │ 9. Export 1080×1350 PNG                             │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  QUALITY GATE: Human review before publishing            │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Why Python-First (Not AI-First)

| Dimension | Python Rendering | AI Generation |
|-----------|-----------------|---------------|
| Text accuracy | 100% (rendered from font files) | 70-90% (garbles dense/bilingual text) |
| Mascot fidelity | Pixel-perfect (composites real PNGs) | Off-model (hallucinated approximations) |
| Logo accuracy | Exact (composites real PNG) | Wrong brand hallucinated |
| Brand color | Code constants, zero drift | Approximate, palette wanders |
| Speed per post | <2 seconds | 15-60 seconds API call |
| Cost per post | ~$0 (local compute) | $0.05-0.50 per API call |
| Consistency | Identical brand DNA every time | Varies per generation |
| Bilingual EN/CN | Exact font + positioning control | Garbled CJK, wrong characters |

**AI's role is limited to:**
- Generating a background texture/pattern library (one-time, not per-post)
- Generating decorative elements (confetti, organic shapes) for the library
- Prototyping new layout concepts before coding them
- Upscaling photos when needed

### 3.3 Tool Stack

| Component | Tool | Why |
|-----------|------|-----|
| **Text rendering** | Pillow + DrawBot (macOS) | DrawBot has superior typography control, proper CJK layout, exports PDF/PNG. Pillow for compositing. |
| **Font files** | DX Lactos (`dxlactos-regular-free-personal-use.otf`), Mabry Pro (Regular/Medium/Bold/Black), MyriadPro | Already in `assets/fonts/` |
| **Mascot assets** | 6 characters × 4 sizes (256/512/1000/2000px), transparent PNGs | Already in `assets/mascots/` |
| **Logo assets** | 8 lockup variants × 4 sizes, transparent PNGs | Already in `assets/logos/` |
| **Background library** | Ideogram V3 (best text-in-image accuracy, good for styled patterns) | Generate 30-50 once, reuse |
| **Decorative elements** | Recraft V4 (native SVG vector output) or hand-coded in Python | Wavy shapes, starbursts, badges |
| **Data input** | CSV/JSON spreadsheet per month | 1 row = 1 post, all copy pre-written |
| **CJK font** | Noto Sans SC (free, Google Fonts) — add to `assets/fonts/` | Needed for Chinese text blocks |
| **Batch runner** | Python script, parallel subprocess for speed | Same pattern as mirra.eats batches |

### 3.4 Font Status

| Font | File | Status |
|------|------|--------|
| DX Lactos Regular | `dxlactos-regular-free-personal-use.otf` (30KB) | IN FOLDER — but free/personal use license, check commercial rights |
| Mabry Pro Regular | `MabryPro-Regular.ttf` (200KB) | IN FOLDER |
| Mabry Pro Medium | `MabryPro-Medium.ttf` (198KB) | IN FOLDER |
| Mabry Pro Bold | `MabryPro-Bold.ttf` (201KB) | IN FOLDER |
| Mabry Pro Black | `MabryPro-Black.ttf` (197KB) | IN FOLDER |
| MyriadPro Regular | `MyriadPro-Regular.otf` (97KB) | IN FOLDER |
| Noto Sans SC | — | MISSING — need to download for Chinese text |

---

## PART 4: DESIGN ELEVATION STRATEGY (Compounding Quality)

### 4.1 What's Working (Keep)
- Cream background dominance — warm, distinctive, never corporate
- Mascot system — the brand's strongest differentiator
- Yellow highlight swoosh — instant brand recognition
- Organic/wavy shapes — feels handmade, not templated
- Bilingual execution — natural, not afterthought
- Clean hierarchy — headline → content → mascot → logo

### 4.2 What to Elevate (Improve)

| Current State | Elevated Version | How |
|---------------|-----------------|-----|
| Same headline size every post | **Dynamic type scale** — huge for quotes, medium for events, small for info | Template variants with 3 type scales |
| Single sans-serif body | **Typographic play** — occasional italic Mabry accent, mixed weight in same line | Mabry Pro has 4 weights — use them all |
| Flat mascot compositing | **Depth & personality** — mascots at slight rotation, overlapping edges, peeking from behind elements | Pillow rotation + strategic z-ordering |
| Predictable grid schedules | **Modern timetable design** — color-coded cells, rounded pill shapes per session, micro-mascot icons | Redesign T1 template with pill-grid |
| Basic starburst badges | **Variety of accent shapes** — organic blobs, speech bubbles, hand-drawn circle, ribbon banners | Build a library of 8-10 shapes |
| No texture/grain | **Subtle paper texture** — light grain (0.014) or paper overlay for tactile feel | Already proven in mirra.eats pipeline |
| Same-same seasonal colors | **Distinct seasonal visual kits** — not just color swap but unique decorative elements per season | Pre-generate seasonal element packs with AI |
| No animation | **Simple mascot motion** — GIF/MP4 of mascot bouncing/blinking for stories | DrawBot exports MP4, future phase |

### 4.3 Pinterest Reference DNA (What You're Drawn To)

From analyzing all 37+ Pinterest pins saved, the aesthetic direction clusters around:

| Cluster | Brands Referenced | Visual DNA | Apply to BB |
|---------|------------------|-----------|-------------|
| **Playful rounded type** | Goodies, Brew Bean, Bubblicious, Kooky | Chunky, bubbly, hand-drawn feel | Already aligned — DX Lactos IS this |
| **Character-driven identity** | Headspace, Line & Plane, Olive+Emme | Simple shapes with emotions, consistent cast | BB's 6 mascots — use them MORE |
| **Bold color blocking** | Creative N Chaotic, Pistash, Lactos | Flat color zones creating rhythm | Introduce color-blocked backgrounds as variant |
| **Retro-modern warmth** | Smug, Craft Night, Tiger Snake | Wavy shapes, nostalgic but fresh | BB already does this — push further with wavy containers |
| **Minimal + accent** | Georgia Blair, Nutripia, Club Creative | Clean space with 1-2 bold color hits | BB's quote cards already nail this |

**Key insight:** Your Pinterest saves confirm the brand direction is correct. The gap is execution consistency and production volume — not aesthetic direction.

---

## PART 5: IMPLEMENTATION ROADMAP

### Phase 1: Foundation (This Session)
- [x] Complete brand audit and file inventory
- [x] Reverse-engineer 8 content archetypes
- [x] Define template architecture (T1-T8)
- [x] Research tool stack and AI model capabilities
- [x] Document rejection learnings from v1
- [ ] Download Noto Sans SC for Chinese text support

### Phase 2: Build Core Engine (Next)
- [ ] Build `bloom_core.py` — brand constants, font loader, logo compositer, mascot compositer, grain, text renderer (EN + CN)
- [ ] Build decorative shape library — wavy blobs, starbursts, highlight swooshes, rounded boxes, pills, speech bubbles (all Python/Pillow)
- [ ] Build `bloom_templates.py` — T1 through T8 as Python functions
- [ ] Test with 1 post per template (8 posts total)
- [ ] Human review and iterate

### Phase 3: Background Library (AI-Assisted)
- [ ] Generate 30-50 background textures via Ideogram V3
  - Pastel watercolors (cream/pink/mint/lavender)
  - Organic wavy patterns
  - Confetti/celebration patterns
  - Seasonal variants (autumn, Christmas, CNY, Raya)
- [ ] Curate → store in `assets/backgrounds/`

### Phase 4: Batch Production
- [ ] Create March 2026 content calendar as CSV
- [ ] Batch-generate all March posts (target: 20-25 posts)
- [ ] Human review → approve / request revision
- [ ] Export finals to `exports/2026-mar/`

### Phase 5: Compounding Quality Loop
- [ ] After each month's batch, audit outputs against Pinterest refs
- [ ] Update templates with improvements
- [ ] Add new decorative elements to library
- [ ] Track which archetypes perform best on IG → produce more of those
- [ ] Seasonal element packs generated quarterly

---

## PART 6: ALTERNATIVE APPROACHES CONSIDERED

### Option A: Bannerbear (Hosted Template Service)
- **What:** Visual template editor + API for batch generation
- **Price:** $49/month for ~1,000 images
- **Pros:** No coding, visual template editor, API/Zapier integrations
- **Cons:** Less control than Python, can't do advanced compositing, template editor simpler than Figma
- **Verdict:** Good backup if Python approach feels too heavy. Could use for schedule templates specifically.

### Option B: Canva Bulk Create
- **What:** Spreadsheet-driven batch generation in Canva
- **Price:** Canva Pro $13/month
- **Pros:** Familiar UI, huge template library, easy for non-devs
- **Cons:** No real API without Enterprise, limited automation, can't upload custom fonts on free tier
- **Verdict:** Best for quick one-offs or if you want to hand off to a VA. Not ideal for systematic bulk production.

### Option C: Full AI Generation (Ideogram V3 / GPT-4o)
- **What:** Prompt-to-image for each post
- **Pros:** Fastest prototyping, no coding needed
- **Cons:** Text accuracy ~90% max (unacceptable for bilingual), can't reproduce exact mascots, brand drift, no consistency guarantee
- **Verdict:** REJECTED for production. Use only for background/element library generation.

### Option D: Python Template Engine (RECOMMENDED)
- **What:** Code-defined templates + Pillow/DrawBot rendering + real brand assets
- **Pros:** 100% text accuracy, pixel-perfect mascots/logo, zero brand drift, <2sec per post, $0 marginal cost, full control
- **Cons:** Requires coding upfront, less visual design feedback loop
- **Verdict:** RECOMMENDED. Same proven architecture as mirra.eats. Adapted for BB's pastel/mascot DNA.

---

## APPENDIX A: ASSET INVENTORY SUMMARY

| Asset Type | Count | Location | Status |
|-----------|-------|----------|--------|
| Logo variants (transparent PNG) | 33+ | `assets/logos/` | Ready |
| Mascot characters (transparent PNG) | 30 (6×4 sizes + 6 source) | `assets/mascots/` | Ready |
| Mascot lineup strips | 2 | `assets/textures-patterns/` | Ready |
| Brand palette reference | 1 PNG | `assets/colors/` | Ready |
| Custom icons | 8 PNG | `assets/icons/` | Ready |
| Font files | 6 | `assets/fonts/` | Ready (need CJK font) |
| Past social posts | 221+ | `past-work/social-posts/` | Reference library |
| Pinterest references | 37+ | `references/` | Aesthetic direction |
| AI source files | 51 | `working-files/` | Designer reference |
| Holiday camp photos | 54 | `past-work/events/holiday-camps/` | Photo library |
| BTS photos | 5 | `past-work/social-posts/` (root) | Photo library |

## APPENDIX B: AI MODEL COMPARISON (March 2026)

| Model | Text Accuracy | Brand Consistency | Best Use for BB |
|-------|--------------|-------------------|-----------------|
| **Ideogram V3** | ~90-95% | Medium | Background textures, styled patterns |
| **GPT-4o / GPT Image 1.5** | ~87% | Medium | Layout prototyping, concept exploration |
| **Recraft V4** | ~80-85% | High (brand kit feature) | Vector element generation (SVG) |
| **FLUX Pro / Kontext** | ~70-75% | Low | AVOID for BB (proven failure) |
| **Midjourney V6** | ~30% | Low | Aesthetic inspiration only |
| **Adobe Firefly 5** | ~45% complex | High (IP safe) | Commercially safe backgrounds |

## APPENDIX C: KEY LEARNINGS FROM REJECTED v1

1. FLUX Kontext destroys dense text — garbles after 1 pass, gibberish after 2+
2. FLUX hallucinated wrong brand identity ("MarketplaceAtAvalonPark")
3. Multi-pass AI editing compounds errors — never self-corrects
4. AI cannot faithfully reproduce specific vector mascot characters
5. Python must handle ALL text, layout, logos, mascots — AI only for non-text decorative zones
6. Full log: `exports/rejected-v1/REJECTION-LOG.md`

---

*This is a living document. Update after each production batch with new learnings.*
