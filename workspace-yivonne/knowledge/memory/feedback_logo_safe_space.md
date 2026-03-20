---
name: Logo needs safe space — no text overlap
description: v3 outputs had text overlapping the Mirra logo. Must define explicit 120px exclusion zone at logo position. Offer multiple logo placement options (bottom-center, bottom-right, top-right) based on composition.
type: feedback
---

## Logo overlap fix (2026-03-12)

User: "A lot of overlapping words on the mirra logo, need to set a safe space OR options of logo placement"

### Rules
1. **NANO prompt must instruct**: "Leave 120px of COMPLETELY EMPTY space at bottom-center — no text, no graphics, no decorative elements in this zone. This is reserved for post-production logo placement."
2. **Multiple placement options**: Logo can go bottom-center (default), bottom-right, or top-right depending on composition. Auto-detect best position based on content density.
3. **Safe zone logic in post-process**: Before placing logo, check if the target area has text/graphics. If bottom-center is busy, try bottom-right, then top-right.
4. **In NANO prompt**: Be ultra-explicit about the exclusion zone coordinates — "Bottom 120px center strip (x: 350-730, y: 1230-1350) must be empty"
