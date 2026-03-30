---
name: DotDot Product Lineup — Calculated grid positioning, not percentage guessing
description: Product lineup posts must use CALCULATED grid zones (not x/y percentage guessing). Define grid_top/bottom/left/right, divide into cells, center product within each cell. Proven in P3 v2.
type: feedback
---

## PRODUCT LINEUP — CORRECT METHOD

### What Failed (v1)
Percentage-based x/y positioning (0.30, 0.42 etc.) doesn't align with NANO's card layout.
Products float randomly, wrong size, not centered in cards.

### What Works (v2 — proven)
1. NANO generates background with colored card grid
2. Define grid boundaries: top/bottom/left/right as percentage of frame
3. Calculate cell dimensions: row_h = grid_height / rows, col_w = grid_width / cols
4. For each product: compute exact card zone, scale product to 75% of card, center within zone
5. PIL composites with drop shadow

### Grid Calculation:
```python
grid_top = int(th * 0.28)    # below headline
grid_bottom = int(th * 0.78)  # above CTA
grid_left = int(tw * 0.08)    # margin
grid_right = int(tw * 0.92)   # margin
row_h = (grid_bottom - grid_top) // num_rows
col_w = (grid_right - grid_left) // num_cols
gap = 8  # px between cards
```

### Product Sizing:
```python
scale = min(card_w / prod.width, card_h / prod.height) * 0.75
# 75% fill = product visible with breathing room inside card
```

**How to apply:** Always use calculated grid for any multi-product composite. Never guess positions.
