---
name: Mirra Illustration v5 — LOCKED style + production learnings
description: Korean webtoon illustration pipeline proven. v5 = approved. Generation mode (not edit). Crop-to-fit (not squish). PIL logo. No forced sparkle. Key fixes from v1-v5 iterations.
type: feedback
---

## MIRRA ILLUSTRATION v5 — LOCKED (March 27, 2026)

### What works (v5 approved)
- **Generation mode** — NOT edit mode. Style ref = guidance only, not image to edit.
- **1 style ref per generation** — more = dilution. Single ref locks style stronger.
- **Crop-to-fit** — NANO outputs 1856x2304. CROP to 4:5 (1080x1350), never resize/squish.
- **PIL logo** — actual `Mirra Social Media Logo.png` composited in post-processing. NOT NANO text.
- **No forced sparkle** — only when content calls for it naturally.
- **Stronger grain** — 0.028 for illustrations (vs 0.016 for photos).
- **Anti-NANO-logo instruction** — "DO NOT write any brand name or logo anywhere in the image"
- **Content = relatable girlboss daily life** — NOT food hardsell. Inner voice, quotes, comics, familiar moments.

### Style DNA (forensic-proven)
- Korean semi-realistic, warmcorner.ai / gunelisa style
- Soft cel-shading with visible tapered dark brown contour lines
- Eyes 15-20% enlarged (NOT more), almond shape, warm brown, 1-2 white catchlights
- Hair: dark chocolate brown, chunky straight-wavy masses (NOT curly ringlets)
- Face: mature 25-28, defined jawline, NOT Disney/Pixar/child
- Shading: warm peach-pink shadows, never grey
- Background: flat solid Mirra palette color
- Full forensic: `10-illustration-refs/STYLE-FORENSIC.md`

### v1-v5 iteration log
| Version | Issue | Fix |
|---------|-------|-----|
| v1 | Used edit mode, 2 refs → distorted hybrid | Switch to generation, 1 ref |
| v2 | Not run (skipped to v3) | — |
| v3 | Still Disney eyes, forced sparkle, NANO logo, weak grain | Anti-Disney negatives, remove sparkle, stronger grain |
| v4 | Compression (squished proportions), still NANO logo, hair too curly | Crop-to-fit, explicit no-logo, straight-wavy hair |
| v5 | APPROVED. Typography needs editorial upgrade. Logo area overlap. | TODO: editorial typography, logo safe zone |

### Remaining TODO
1. **Typography** — current NANO text is too plain. Need editorial serif style (Playfair/Canela energy)
2. **Logo safe zone** — bottom 15% of canvas must stay clear for PIL logo placement
3. **Content direction** — NOT food hardsell. Research viral girl-relatable content first, THEN curate.

### Production pipeline (locked)
```
Style ref (1 from 10-illustration-refs/)
→ NANO Banana Pro Edit generation mode (2K)
→ Crop to 4:5 (center crop, bias toward keeping bottom)
→ Grain (0.028)
→ PIL composite Mirra logo (140px wide, bottom center, 45px from bottom)
→ DONE
```

### Proven formats (v5)
1. **Quote post** — girl in scene + relatable quote text (v5-01, v5-02)
2. **Desk scene** — bird's-eye flat-lay with bento/objects (v4-02)
3. **Meme** — girl with speech bubble or holding card (v5-05)
4. **3-panel comic** — before/during/after story (v5-03)
5. **4-panel comic** — group scene with narrative arc (v5-06)
6. **Vibe post** — cozy scene + aspirational text (v5-04)

### 6 Locked Style References
`/Users/yi-vonnehooi/Desktop/_WORK/mirra/04_references/curated/10-illustration-refs/`
