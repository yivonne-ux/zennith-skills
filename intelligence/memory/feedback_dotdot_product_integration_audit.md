---
name: DotDot Product Integration — Must look like ONE finished artwork, not sticker on poster
description: CRITICAL AUDIT LAYER. Product position, size, shadow, color reflection must be designed WITH the background as one composition. PIL paste = sticker effect = rejected. Add to visual audit checklist.
type: feedback
---

## PRODUCT INTEGRATION — NEW AUDIT LAYER

### The Problem (v9)
Product photos were PIL-composited ON TOP of NANO background. Result: product looks like a sticker pasted on a poster. No shadow blending, no color interaction, no compositional integration. Not one finished artwork.

### Why It Fails
The 3-layer stack (NANO bg → PIL product → PIL logo) treats each layer independently. The background doesn't know the product exists. No design relationship between layers:
- No natural shadow from product onto background
- No color reflection (orange box should cast warm light on nearby surface)
- No compositional flow (surrounding elements don't frame/guide eye to product)
- No depth integration (product floats, doesn't sit IN the scene)

### The Correct Approach
The product must be designed INTO the composition from the start. Two methods:

**Method A: NANO placeholder → PIL swap**
1. NANO generates full composition WITH an illustrated product placeholder (correct size, position, angle)
2. NANO renders natural shadows, reflections, color interaction around the placeholder
3. PIL swaps ONLY the product area with real PNG (preserving NANO's shadow/reflection work)
4. This gives integrated composition WITH pixel-perfect product text

**Method B: NANO edit at low strength**
1. Pass real product as Image 2 to NANO at LOW strength (0.3-0.5)
2. NANO integrates it naturally (position, shadow, color) but preserves most of the text
3. May still have some text softening — test per output

**Method C: Full NANO integration + accept text imperfection**
1. Pass real product as Image 2 at normal strength
2. NANO fully integrates product into composition
3. Accept that packaging text may be slightly soft (for proposal, not print)
4. For final production, use Method A

### NEW AUDIT CHECK — Layer 7: Product Integration
Add to the 6-layer visual audit:

- [ ] **Product feels IN the scene** — not floating/pasted on top
- [ ] **Natural shadow** — product casts shadow appropriate to the scene lighting
- [ ] **Color interaction** — product color reflects onto nearby surfaces
- [ ] **Compositional framing** — surrounding elements (badges, text, icons) GUIDE the eye toward the product
- [ ] **Size proportional** — product at 40-60% frame height, not too small/too large
- [ ] **Angle natural** — slight 15-20° tilt, matches scene perspective
- [ ] **No "sticker effect"** — hard edge between product and background = FAIL

### How to Apply
Before showing ANY product post, ask: "Does this look like ONE designed artwork, or does the product look pasted on?" If pasted → reject → use Method A or B.

**This is the same principle as mascot integration**: every element must feel like it was born in the same scene, not assembled from parts.
