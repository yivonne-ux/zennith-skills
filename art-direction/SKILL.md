# Art Direction & Creative Design Skill

## Purpose
Equip creative agents (Iris, Dreami) with structured art direction, UI/UX design thinking, character design, and graphic design capabilities. Every visual output must follow a brand's Design DNA — never generic.

## When to Use
- Designing landing pages, UI components, or marketing visuals
- Creating character designs or avatar systems
- Building design systems or style guides
- Reviewing visual output for brand alignment
- Briefing design tasks to build agents

## Core Design Principles

### 1. Design DNA First (MANDATORY)
Before ANY visual work, check for a Design DNA file:
- `brands/{brand}/DESIGN-DNA.md` — extracted visual language
- `brands/{brand}/graphic-refs/` — reference images defining the look
- `brands/{brand}/character-refs/` — character aesthetic references

If no Design DNA exists, CREATE ONE by:
1. Analyzing any available reference images
2. Extracting: color palette, typography choices, layout patterns, texture/material language, mood
3. Writing it to `brands/{brand}/DESIGN-DNA.md`

### 2. Reference-Driven Design
NEVER design from imagination alone. Always:
- Study reference images before coding
- Identify the 3-5 key visual patterns in the references
- Name each pattern explicitly (e.g., "editorial brutalism", "sacred geometry", "data-as-decoration")
- Apply those patterns to the output

### 3. Typography as Architecture
Typography is the #1 element of visual identity:
- **Scale contrast:** Mix massive display (80-200px) with tiny data text (10-12px)
- **Tracking:** Tight for display (-0.03 to -0.08em), wide for labels (0.1-0.3em)
- **Weight contrast:** Ultra-bold headlines with thin body
- **Breaking:** Allow words to split across lines for visual drama
- **Font pairing:** Always pair a display font with a monospace utility font

### 4. Color as Signal (Not Decoration)
- Primary accent = emotional tone (red = urgency/power, green = data/growth)
- Use color sparingly — mostly neutrals with 1-2 accent colors
- Background alternation = rhythm (light/dark section switching)
- Never use more than 3 colors in any single section

### 5. Layout as Grid System
- Make the grid VISIBLE — thin rule lines, crosshairs at intersections
- Use asymmetry over centering for editorial feel
- Data decorations: index numbers, dates, coordinates, barcodes
- Negative space is intentional — don't fill every gap
- Mix media types: photo + line art + text + data elements

### 6. Texture & Material
- Film grain for warmth (CSS noise overlay, opacity 0.02-0.05)
- Paper/archival texture for organic feel
- Chrome/metallic for tech elements
- Organic shapes breaking rigid grids (blob masks, torn edges)

## Character Design Framework

### Creating Consistent Characters
1. **Base prompt** → generate initial concept with description
2. **Source image** → best-quality generation (Kora Pro / NanoBanana Pro)
3. **Enhancement** → skin texture, imperfections, realism (Enhancor V3)
4. **Character sheet** → 4-angle rotation for 3D consistency
5. **Style lock** → save enhanced source + prompt template for future use

### Character Profile Card (Template)
```
┌─────────────────────────────────────┐
│  +                            001   │
│  ┌──────────┐  NAME: ___________   │
│  │          │  DESIGNATION: ____   │
│  │  PHOTO   │  STATUS: ACTIVE      │
│  │          │  CLEARANCE: ████     │
│  │          │  ARCHETYPE: _____    │
│  └──────────┘                       │
│  ||||||||||||||||||||||||| ID:001   │
│  2026.02.25        GAIA OS v0.1    │
└─────────────────────────────────────┘
```

## UI/UX Design Checklist

Before approving any UI output:
- [ ] Follows brand Design DNA (colors, type, layout)
- [ ] Typography has clear hierarchy (3+ size levels)
- [ ] NOT generic — has a distinct visual identity
- [ ] Grid structure visible or implied
- [ ] Color usage is restrained and intentional
- [ ] Mobile responsive
- [ ] Animations are subtle, not distracting
- [ ] Data decorations present (for brutalist/editorial styles)
- [ ] Photography/imagery properly framed
- [ ] Builds successfully (npm run build)

## Tools & Resources
- **Lovart.ai** — AI infinity canvas for design exploration
- **Flora.ai** — Pipeline/workflow visual editor
- **Enhancor** — Kora Pro (image gen), V3 (skin fix), Upscaler
- **NanoBanana Pro** — Character consistency + variations
- **GSAP** — Animation library for web
- **Google Fonts** — Playfair Display, JetBrains Mono, Space Mono, Cinzel
- **CSS tricks:** clamp() for responsive type, CSS noise for grain, SVG for wireframes

## Anti-Patterns (NEVER DO)
- Generic SaaS landing page template
- All-centered layout with no grid tension
- Gradient backgrounds everywhere
- Stock photography feel
- More than 3 fonts on a page
- Animations that delay content visibility
- Ignoring brand references to "make it look nice"
