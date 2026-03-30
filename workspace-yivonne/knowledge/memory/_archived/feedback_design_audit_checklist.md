---
name: Design Audit Checklist — What My Eyes Must Catch
description: CRITICAL. Comprehensive visual audit checklist built from W3 failures. Every output must pass ALL checks. Applies to ALL brands.
type: feedback
---

## DESIGN AUDIT — TRAINED EYE CHECKLIST

Built from W3 Pinxin batch — 4 rounds of regeneration, user caught issues I missed every round. These are the exact gaps in my visual assessment.

### LAYER 1: TONAL SEPARATION (missed on RT-02)
- [ ] **Foreground must POP from background** — different value/brightness, not same tone
- [ ] **Text must have contrast ratio >4.5:1 against its background** — if text and bg are both warm brown, REJECT
- [ ] **Food must stand out** — if dish blends into the table/surface color, REJECT
- [ ] **Card/receipt/UI elements must have clear edges** against the scene — shadow, outline, or brightness difference

**The test:** Squint at the image. If you can't instantly see where the foreground ends and background begins, it FAILS tonal separation.

### LAYER 2: LAYOUT COMPOSITION (missed on RT-02)
- [ ] **No dead space** — every zone of the image should have purpose (text, food, decoration, breathing room)
- [ ] **Visual weight balanced** — not all content crammed to one corner while rest is empty
- [ ] **Hierarchy clear** — what's the FIRST thing you see? Second? Third? If nothing dominates, layout fails.
- [ ] **Negative space is intentional** — empty space should feel designed, not accidental/lazy

**The test:** Cover half the image. Does the other half still communicate the message? If half the image is just flat background with no purpose, it FAILS layout.

### LAYER 3: DISTORTION DETECTION (missed on RT-01, RT-03)
- [ ] **Straight lines must be straight** — check edges of cards, receipts, phones, UI elements
- [ ] **Text must not be warped** — characters should be uniform size, not bent/stretched
- [ ] **Circular objects must be circular** — plates, bowls, cups should not be oval/squished
- [ ] **Proportions must be natural** — a boarding pass shouldn't be oddly tall/wide/squeezed
- [ ] **No double edges** — look for ghost lines, double borders, or blurred seams (especially at 4:5→9:16 join area, ~15% and ~85% height)

**The test:** Draw imaginary straight lines along all edges. If anything curves or warps that should be straight, it FAILS distortion.

### LAYER 4: SEAM DETECTION (missed on RT-03)
- [ ] **Check the 4:5→9:16 extension zones** — top ~15% and bottom ~15% of the image
- [ ] **No visible blur transition** — the edge between center content and extended area should be invisible
- [ ] **No double blurred lines** — repeated patterns, halos, or ghosting at the seam
- [ ] **Color should be continuous** — no sudden warm→cool or light→dark shift at the seam

**The test:** Look specifically at y=285px and y=1635px (the blur-pad join points). If you see ANY line, halo, or color shift, it FAILS seam.

### LAYER 5: COLOR GRADING (systemic W3 issue)
- [ ] **Match brand color DNA** — Pinxin = "Quiet Luxury" = muted, natural, sophisticated, NOT oversaturated
- [ ] **Not too warm/reddish** — NANO tends to add warm orange/red cast. Pinxin should be 5000-5300K daylight.
- [ ] **Not too yellow** — gold accents yes, overall yellow cast no
- [ ] **Food looks NATURAL** — not over-graded, not instagram-filtered
- [ ] **Surface textures visible** — wood grain, ceramic texture, fabric weave should be present (quiet luxury = tactile)

**The test:** Compare against the real food cutout photos. If the cutout looks more natural/appetizing than the ad output, the color grading is wrong.

### LAYER 6: FOOD PIXEL-MATCH (from earlier rounds)
- [ ] **Signature markers visible** per dish (petai beans, purple eggplant, okra, black fungus, etc)
- [ ] **Food not AI-remixed** into generic dishes
- [ ] **Packaging is REAL** (from pkg-*.png), never AI-generated

### HOW TO APPLY
Run ALL 6 layers on EVERY output. If ANY layer fails, the creative needs regeneration or is rejected. Do not pass "borderline" — if you hesitate, it fails.

**My previous failure pattern:** I was only checking Layers 5-6 (food + text) and ignoring Layers 1-4 (design fundamentals). A designer checks ALL layers instinctively. I must check them systematically.
