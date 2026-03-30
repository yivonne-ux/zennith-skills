---
name: DotDot v10 Final Audit — Mascot editorial APPROVED, P3 product placement REJECTED
description: Mascot art style adaptation approved. P3 product lineup rejected — products floating, wrong size, not integrated with card bg. Product must FIT INSIDE its colored card zone. PIL composite needs precise grid positioning.
type: feedback
---

## v10 FINAL AUDIT (30 March 2026)

### ✅ APPROVED

**Mascot pose fixes (v4-happy-fix, v4-teaching-fix, v4-thumbsup-fix):**
- All 3 fixed. Combined = 8/8 complete character sheet approved.

**Mascot editorial art style adaptation:**
- mascot-editorial-hero, teaching, presenting, thumbsup = ALL approved
- Strokeless, soft gradient, face features preserved pixel-identical
- Teal dot brand accent = nice subtle touch
- This is the mascot rendered in our post art style = LOCKED for post production

**Product posts P1-hero-clean, P2-comparison-fixed:**
- Both approved in earlier round

### ❌ REJECTED

**P3-lineup-6products:**
- Products are FLOATING randomly, not positioned INSIDE their colored card zones
- Product sizes inconsistent — some too big, some too small relative to card
- Products not centered within their respective card rectangles
- Looks like products thrown on top of the layout, not designed together

### ROOT CAUSE — P3

PIL composite used percentage-based x/y positioning (0.30, 0.42 etc.) which doesn't align with where NANO actually placed the colored card rectangles. The cards are NANO-generated at unpredictable positions. PIL is guessing where to place products.

### FIX — Two options:

**Option A: Detect card positions programmatically**
- After NANO generates the bg with colored cards
- Use color detection to find each card's exact bounding box
- Center each product within its detected card zone
- This guarantees product sits INSIDE the card regardless of NANO's layout

**Option B: Fixed template approach**
- Don't rely on NANO for card positions
- PIL draws the entire 3x2 grid programmatically (exact positions, exact colors)
- PIL composites products centered in each cell
- PIL adds headline text
- More control but less "designed" feel

**Option C: NANO generates WITH product descriptions inside cards**
- Instead of empty cards, prompt NANO to show the product type in each card
- Then PIL composites real product OVER NANO's illustration
- At least NANO's layout accounts for the product positions

### NEW AUDIT CHECK — Product Lineup:
```
□ Each product is CENTERED within its designated card/zone
□ Product SIZE is proportional to card size (fills 70-80% of card area)
□ Products are ALIGNED in grid (tops align, sides align)
□ No product overlaps card boundary
□ No product floating outside any card
□ Product shadows respect the card boundary
```

### WHAT PASSED vs WHAT MY AUDIT MISSED:
| Item | My Audit Said | Reality | Gap |
|------|--------------|---------|-----|
| P3 products | "All 6 real products" ✅ | Products floating, wrong position, wrong size | Didn't check POSITIONING within cards |
| v4-happy (earlier) | PASS | Wrong eyes/mouth | Didn't compare feature-by-feature vs canonical |

**The pattern**: I check IF elements are present but not WHERE they are positioned or HOW they're sized relative to the layout. Need spatial/compositional audit, not just presence audit.

**How to apply:** For any composite post, verify spatial relationships: "is element X inside zone Y?" not just "does element X exist?"
