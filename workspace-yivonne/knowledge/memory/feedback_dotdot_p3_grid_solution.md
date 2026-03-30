---
name: DotDot P3 Product Grid — PIL-only grid is the ONLY solution. NANO grids are always unequal.
description: CRITICAL. NANO cannot generate equal-sized grid cards. Cards always vary wildly (41px vs 292px width). The ONLY fix is 100% PIL-built grid with NANO headline only. Proven pixel-perfect in P3-lineup-perfect.
type: feedback
---

## P3 PRODUCT GRID — SOLVED

### The Problem (5 attempts)
- v9 P3: PIL % positioning → products floating randomly
- v10 P3: NANO rendered product cards → unequal sizes, products too small
- v10-fix P3: Calculated grid → products centered but bottom row too high, too small
- v11-fix P3: Bigger grid → still misaligned with NANO's cards
- v11-p3-perfect: **PIL-only grid → PIXEL PERFECT** ✅

### Root Cause
NANO CANNOT generate equal-sized grid cards. Color detection showed:
- Row 1: cards 119px, 117px, 41px wide (wildly different)
- Row 2: cards 292px, 292px, 290px wide (different from row 1)

No amount of prompting fixes this. NANO's layout is inherently imprecise.

### The Solution: NANO Headline + PIL Grid
```
Step 1: NANO generates ONLY the headline/top area (cream bg fills rest)
Step 2: PIL draws equal rounded rectangle cards programmatically
Step 3: PIL composites real product PNGs centered in each card
Step 4: PIL adds labels, CTA badges, logo
Step 5: Post-process (grade, grain, sharpen)
```

### Exact Parameters (proven):
```python
MARGIN_LEFT = 50
MARGIN_RIGHT = 50
GRID_TOP = int(TH * 0.22)      # Below headline
GRID_BOTTOM = int(TH * 0.84)
GAP_H = 16                      # Between cards
GAP_V = 16                      # Between rows
LABEL_HEIGHT = 50                # Below each card for name

card_w = (grid_w - 2 * GAP_H) // 3    # 316px at 1080 width
card_h = (grid_h - GAP_V - 2*LABEL_HEIGHT) // 2   # 360px

product_scale = 0.80  # Fill 80% of card
```

### Card Colors (match product packaging):
```python
card_colors = {
    "德國膠原": (232, 117, 42),     # orange
    "德國膠原EX": (139, 107, 79),   # brown
    "補矽": (77, 191, 184),         # teal
    "德國蘋果": (212, 99, 122),     # pink
    "德國蜜莎": (212, 168, 67),     # gold
    "冰川牛奶": (125, 213, 219),    # light teal
}
```

### Rule: For ANY multi-product grid layout:
- NEVER rely on NANO for grid positioning
- ALWAYS use PIL programmatic grid
- NANO for creative elements (headline, decorative) only
- PIL for structural layout (grid, positioning, alignment)

**How to apply:** Any time you need 3+ items in a grid → PIL draws the grid. Period.
