---
name: Mirra Social Production Pipeline — LOCKED (March 28, 2026)
description: CRITICAL. Full production pipeline for Mirra social media illustrations. Every yes/no from 8-round calibration. Viral format reference-first. NANO generation mode. PIL expert logo. All amendments.
type: feedback
---

## MIRRA SOCIAL ILLUSTRATION PIPELINE — LOCKED

### Architecture (proven in viral-regen-v2, 8/8 success)
```
1. FIND viral reference (scrape IG/Pinterest for proven viral posts)
2. ANALYZE reference layout (describe composition in text)
3. GENERATE with NANO (style ref as Image 1, layout in prompt)
4. POST-PROCESS: crop-to-fit 4:5 → grain 0.028 → PIL expert logo → DONE
```

### NANO API Call (exact)
```python
fal_client.subscribe("fal-ai/nano-banana-pro/edit", arguments={
    "prompt": prompt,
    "image_urls": [style_ref_url],   # ONLY 1 image — style ref
    "resolution": "2K",
    "aspect_ratio": "4:5"            # CRITICAL — prevents crop issues
})
```

### What goes WHERE
| Element | Where | NOT where |
|---------|-------|-----------|
| Layout/composition | TEXT PROMPT (described from reference) | NOT as image input |
| Art style | IMAGE 1 (Korean webtoon ref) | NOT in text only |
| Brand logo | PIL post-production | NOT NANO-rendered |
| Quote text | NANO renders in illustration | NOT PIL overlay |
| Food (if shown) | Described in prompt text | NOT as image input |

### Anti-Brand Prompt Block (prevents NANO rendering logo)
```
You are an image generator creating an illustration.
CRITICAL RULE: Do NOT write ANY text that looks like a brand name, watermark,
signature, handle, or logo ANYWHERE in the image. No words in corners. No small
text at edges. No artist signatures. The ONLY text allowed is dialogue/quote text
explicitly specified in quotes below.
If you are tempted to add a small word in a corner — DO NOT. Leave all corners
and edges completely clean and empty.
```

### Style DNA Block
```
Match the art style from Image 1: Korean semi-realistic digital illustration
(warmcorner.ai / gunelisa style).
NOT Disney, NOT Pixar, NOT chibi. Eyes 15-20 percent larger than real.
Mature face 26yo, defined jawline. Dark chocolate brown straight-wavy hair,
chunky flowing masses. Soft cel-shading, tapered dark brown outlines.
Warm peach-pink shadows. Premium quality.
```

### Face Rendering (CRITICAL — v2 VR04 failed without this)
ALWAYS include in every prompt with a visible face:
```
Her face MUST have fully rendered eyes with brown irises and white catchlights,
defined eyebrows, small nose with tiny shadow, pink lips, subtle cheek blush.
Do NOT leave the face blank or featureless.
```

### PIL Expert Logo Placement
- Analyze image zones (BR, BL, TR, BC) for edge density + luminance
- Pick CLEANEST zone (lowest edge density = least busy)
- Layout-specific preferences: comics→BC/BR, quotes→BR, singles→BR/BL
- Choose black logo (lum>130) or white logo (lum≤130)
- Size: 110-120px wide
- Slight transparency (90% opacity) for subtlety
- NEVER place where NANO rendered text

### Post-Processing Stack
```python
crop_to_45(img)           # Center crop, only 6px sides for 1856x2304 raw
grain(0.028)              # Stronger for illustrations (vs 0.016 for photos)
expert_logo(img, layout)  # Smart PIL placement
```

### Content Rules
- 60% pure girl life (no food/brand mention) / 40% food-adjacent
- Source ALL content from viral research, NEVER imagination
- Viral reference = the FORMAT. Korean webtoon = the STYLE. Mirra voice = the TEXT.
- If food shown, must be actual Mirra bento description (cream 3-compartment tray, pink rice, samosa, curry, greens)
- ALL food must be 100% plant-based vegan (no meat, fish, eggs, dairy)

### Proven Viral Formats (8/8 success)
1. **3-panel empowerment** — action + close-ups + punchline
2. **3-panel motivation fail** — hope → doubt → surrender
3. **6-panel silent routine** — timestamps, no dialogue, aesthetic
4. **Single overwhelm** — swirling text around character's head
5. **4-panel can't get up** — try → fail → empty → back in bed
6. **Single + quote below** — character scene + editorial serif text
7. **2-panel comparison** — chaos vs calm split
8. **3-panel tragedy** — personified concept (orb) leaves

### Scraping Tools (installed, tested)
- **gallery-dl** with Chrome cookies → IG posts (tested, works)
- **instaloader** → IG profiles, hashtags (tested, works with rate limits)
- **RedNote-MCP** → XHS search + read (installed, needs `rednote-mcp init`)
- **Pinterest** → gallery-dl direct search (tested, works)

### v1→v2 Iteration Log
| Version | Issue | Fix |
|---------|-------|-----|
| v1 (edit mode) | Distorted — NANO edited the style ref instead of generating | Switch to generation mode |
| v2 (edit mode + layout ref) | Edited layout ref = wrong output | Remove layout ref from image_urls |
| v3 (generation, layout in text) | Text cropped, face proportions off | Add 4:5 ratio, anti-Disney negatives |
| v4 (forensic fixes) | Double logo (NANO + PIL), compression | PIL logo only, crop-to-fit |
| v5 (relatable scenes) | Good style but imagined content | Use viral references, not imagination |
| viral-regen-v1 | Right content, crop OK, but double logo | Stronger anti-brand prompt |
| viral-regen-v1-smartlogo | Smart logo added, but NANO still renders brand | Accept smartlogo but need single logo |
| viral-regen-v2 | **LOCKED** — 8/8 pass. No crop, single PIL logo, zero NANO brand, VR04 face fixed | aspect_ratio: "4:5", explicit face instruction |

### Anti-patterns (NEVER repeat)
1. ❌ Edit mode for illustrations → distorted hybrids
2. ❌ Layout ref as Image input → NANO edits it instead of generating fresh
3. ❌ Missing aspect_ratio → NANO outputs wrong ratio → content cropped
4. ❌ Saying "don't write mirra" → NANO renders it more. Just OMIT all brand words
5. ❌ PIL logo + NANO logo → double branding
6. ❌ Imagined content → untested engagement. Use viral references
7. ❌ No explicit face instruction → NANO sometimes renders blank face
8. ❌ Calling a faceless illustration "interesting artistic choice" → it's a DEFECT
