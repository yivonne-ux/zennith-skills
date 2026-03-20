---
name: Logo smart placement — designer-grade system
description: Logo placement must be SMART per design, not forced to one position. Auto-crop, zone analysis, exclusion zone, variant adaptation. Think like a designer.
type: feedback
---

## Rule
Logo placement is a DESIGN DECISION, not a fixed position. Every design has different content, so the logo must adapt.

## Requirements
1. **Auto-crop transparent padding** before resizing (logo PNGs have massive transparent borders)
2. **Multiple placement candidates** — top-center, top-left, top-right, bottom-center, bottom-left, bottom-right
3. **Zone analysis** — check brightness, uniformity, and visual busyness of each candidate zone. Pick the CLEANEST, most uniform area with good contrast.
4. **120px exclusion zone** — logo must have clear breathing room. Never overlap text, key visuals, or edge-bleed elements.
5. **Variant adaptation**:
   - Dark photo backgrounds → white/bw logo variant
   - Light/cream backgrounds → color stacked logo
   - Busy backgrounds → outlined variant (more visible)
   - Photo overlays → bw or outlined with slight drop shadow
6. **Per-design override** — when a specific design clearly needs the logo in a specific spot, hard-code it. Smart placement is the DEFAULT, not a straitjacket.
7. **Safe space from edges** — minimum 35-40px from any canvas edge

## BB logo variants available
- stacked (color, 1.82:1 aspect)
- horizontal (color, 7.46:1 aspect — very wide, use for narrow horizontal spaces)
- full-lockup (color, 1.52:1 — includes more brand elements)
- outlined (works on busy backgrounds)
- with-mascots (large, use sparingly)
- bw (for dark/photo backgrounds)

## Anti-pattern
NEVER force all logos to the same position across all designs. That's lazy, not designed.
