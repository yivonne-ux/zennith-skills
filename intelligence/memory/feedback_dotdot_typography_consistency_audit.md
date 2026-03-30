---
name: DotDot Typography Consistency + Text Occlusion — NEW audit layers
description: CRITICAL. PIL system fonts ≠ NANO poster typography = style mismatch = auto-FAIL. Any element blocking text = auto-FAIL. Two new mandatory audit checks.
type: feedback
---

## TWO NEW AUDIT FAILURES (P3-lineup-perfect, 30 March 2026)

### FAILURE 1: PIL text ≠ NANO text (typography inconsistency)

**What happened:** P3 bottom CTA ("了解更多", "WhatsApp 查詢: 6227 6040") drawn with PIL ImageFont
using system font (STHeiti/PingFang). This looks like plain computer text — completely different
from NANO's bold HK commercial poster typography used in the headline.

**Why it fails:** A designed social media post must have ONE consistent typography system.
Mixing NANO's expressive poster typography with PIL's system font = looks unprofessional,
breaks the visual unity. It's like having a hand-painted sign with a Word document footer.

**Rule: PIL must NEVER render visible text.** ALL text must come from NANO.
PIL's only text-related job is logo compositing (which is an image, not rendered text).

**Fix:** Have NANO generate ALL text areas (headline + footer/CTA). PIL only handles:
- Product PNG compositing
- Logo compositing
- Grid card rectangles (structural, no text)
- Post-processing

**Or:** Have NANO generate TWO images:
1. Top headline area
2. Bottom CTA area
Then PIL assembles: NANO top + PIL grid + NANO bottom

### FAILURE 2: Grid blocking headline (text occlusion)

**What happened:** PIL grid started at GRID_TOP = 22% of frame, which overlapped
the NANO-generated headline text below it. The headline was partially hidden behind
the colored product cards.

**Rule: Structural elements must NEVER overlap text.**
Before placing any PIL element (card, product, logo), verify the zone doesn't contain text.

**Fix:** Increase GRID_TOP margin. Or detect where NANO's text ends and start grid below that.

### NEW AUDIT CHECKS (add to master):

```
TYPOGRAPHY CONSISTENCY AUDIT:
□ ALL visible text has the same typographic style (NANO-generated, not PIL)
□ No system font text visible anywhere (STHeiti, PingFang, default = FAIL)
□ If PIL drew any text → auto-FAIL (PIL never draws text, only composites images)
□ Headlines, labels, CTA — all from NANO or pre-rendered as image assets

TEXT OCCLUSION AUDIT:
□ No element (card, product, logo, grid) overlaps any text
□ Headline fully visible — no cards/products covering it
□ CTA fully visible — no elements covering bottom text
□ Labels below cards fully visible — not clipped by frame edge
□ If ANY text is partially hidden → auto-FAIL
```

### THE PATTERN I KEEP MISSING

I audit STRUCTURAL elements (cards equal, products centered, no bars) but not
SEMANTIC elements (is the text readable, does it match the style, is anything blocking it).

A real designer's eye sees:
1. Structure (layout, alignment, spacing) — I check this ✅
2. Semantics (readability, style consistency, occlusion) — I was missing this ❌
3. Aesthetics (does it feel right, brand-consistent) — partially checking

**How to apply:** After every generation, ask TWO questions:
1. "Is ALL text the same style?" — if any text looks different, FAIL
2. "Can I read ALL text without anything blocking it?" — if any text is hidden, FAIL
