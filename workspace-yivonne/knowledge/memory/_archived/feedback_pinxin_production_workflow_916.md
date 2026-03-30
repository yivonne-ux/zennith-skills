---
name: Production Workflow — 4:5 → 9:16 (Universal)
description: PROVEN two-pass NANO workflow for Meta ad safe zone compliance. Generate at 4:5 first, then extend to 9:16. Applies to ALL brands.
type: feedback
---

**ABSOLUTE RULE: NEVER generate directly at 9:16.** Always generate at 4:5 (1080×1350) first, then extend to 9:16 (1080×1920).

**Why:** Content generated directly at 9:16 sprawls outside Meta's safe zone. Meta overlays (profile pic, caption, CTA button) cover the top ~14% and bottom ~20% of the image. Only the middle ~66% is guaranteed visible. Generating at 4:5 keeps ALL critical content (headlines, food, promo text, prices) within the safe zone.

**How to apply — The PROVEN two-pass workflow (from pinxin_final_fixes.py):**

```
Pass 1: NANO at 4:5 (1080×1350) with OUTPUT_SPEC_45
  → Content stays in Meta safe zone (top 14%, bottom 20% free)

PIL: extend_45_to_916()
  → Blur-pad top and bottom to reach 1080×1920

Pass 2: NANO with EXTEND_916_PROMPT
  → Fills the blurred edges seamlessly (background color/texture only)
  → Does NOT add new text or content

Post: place_logo + add_grain(0.028)
```

**Key imports from Creative Intelligence Module:**
- `OUTPUT_SPEC_45` — tells NANO to output at 1080×1350, keep safe zones
- `EXTEND_916_PROMPT` — tells NANO to fill edges without touching center content

**This applies to ALL brands** (Pinxin, Mirra, Bloom & Bare, Jade Oracle).

**What went wrong before:** W3 batch originally used `extend_to_916()` on the REFERENCE (making it 9:16 before NANO) and asked NANO to generate at 9:16 directly. This put content in the danger zones. The proven approach generates content at 4:5 FIRST, then cosmetically extends.
