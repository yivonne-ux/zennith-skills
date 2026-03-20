---
name: Mirra logo placement requirements
description: Logo must be accurate real PNG (auto-cropped), no overlap, no box, no NANO-rendered placeholder. Reference past Mirra ads on Google Drive for correct treatment.
type: feedback
---

## Logo is NON-NEGOTIABLE — must be perfect every time (2026-03-12)

User has flagged logo issues multiple times. Previous outputs had:
- Logo overlapping with NANO-rendered content
- White box appearing around logo (caused by 591×591 canvas with only 452×91 actual content)
- NANO rendering "MIRRA LOGO" or "MIRRA" placeholder text in the image
- Logo too small or too large

### Rules
1. **Real PNG logo only** — PIL composites the actual `Mirra logo-black.png` file
2. **Auto-crop logo to bounding box** before scaling (fixed in `place_logo()` 2026-03-12)
3. **NANO prompt must emphatically say NO logo** — "DO NOT render any logo, brand name, watermark, or the word 'MIRRA'" + "DO NOT render placeholder text like 'LOGO' or 'YOUR LOGO HERE'"
4. **Reference past Mirra ads** for correct logo size/placement: https://drive.google.com/drive/u/5/folders/1RbXdQdLVNeroAvWmWcjGgjZ5SSbBHGSi
5. Logo should be clean, properly sized (60-120px height after crop), with breathing space around it
6. Check output for any NANO-hallucinated brand text before finalizing

### Logo file details
- `Mirra logo-black.png`: 591×591 canvas but actual text bbox is (69,250,521,341) = 452×91px. MUST crop first.
- `Mirra logo-white.png`: 828×166 full content, use on dark backgrounds.
