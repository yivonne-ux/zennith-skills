---
name: Logo auto-crop transparent padding
description: Logo PNGs have massive transparent padding (2000x2000 canvas, ~1556x855 actual content). MUST auto-crop before resizing or logo renders too small and displaced.
type: feedback
---

## Problem
BB logo PNG files (stacked-wordmark, full-lockup, etc.) are exported at 2000x2000 with the actual logo content centered inside massive transparent padding. For stacked-wordmark, the content is only 1556x855 starting at (222, 572).

## Impact
When resizing to target width (e.g., 220px), the ENTIRE 2000x2000 image gets scaled, so:
- Visible logo content renders at ~170px instead of 220px (too small)
- Y position is displaced because the transparent padding above the content (~572px) gets scaled and pushes the logo down
- Logo appears to "float" lower than expected

## Fix (ALWAYS apply)
```python
logo = Image.open(logo_path).convert("RGBA")
# AUTO-CROP: trim transparent padding to actual content bounds
alpha = logo.split()[3]
bbox = alpha.getbbox()
if bbox:
    logo = logo.crop(bbox)
# NOW resize — this resizes actual content, not padding
r = max_width / logo.width
logo = logo.resize((int(logo.width * r), int(logo.height * r)), Image.LANCZOS)
```

## Rule
ALWAYS auto-crop any PNG with transparency (logos, mascots, icons) to content bounds BEFORE resizing. Never assume the PNG canvas matches the content size.
