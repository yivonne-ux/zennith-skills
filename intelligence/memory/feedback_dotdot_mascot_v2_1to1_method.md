---
name: DotDot Mascot v2 — 1:1 reference method (NANO edit 0.65 strength)
description: CRITICAL. Mascot must be generated from ACTUAL reference image via NANO edit, NOT from text description. Strength 0.65 preserves character DNA while allowing pose variation. Proven in v2.
type: feedback
---

## MASCOT 1:1 METHOD — PROVEN

### What Works (v2)
- NANO edit-first with ACTUAL @business.shorts character crop as Image 1
- Strength: 0.65 (lower than normal 0.82 — preserves more of reference character)
- Prompt describes ONLY the pose change — doesn't re-describe the character's appearance
- Result: character matches reference 1:1 in face, proportions, style

### What Failed (v1)
- FLUX Pro text-to-image from description → too 3D Pixar, wrong proportions, wrong eye size/position
- No reference image input → model defaults to its training average, not the specific character

### The Pipeline
```
1. Crop individual character panels from @business.shorts reference grid
2. Use BEST crop as Image 1 for NANO edit
3. Prompt: "Edit this character. Keep EXACT same design. Only change POSE: [describe pose]"
4. Strength: 0.65 (preserve character, vary pose)
5. Negative: "realistic, pixar, 3D render, nose, large eyes, gradient blush, different character"
```

### Reference Files
- `ref-activity.png` — best full body ref (2 characters with pottery)
- `ref-closeup.png` — best face ref (close-up with microphone)
- `ref-crowd.png` — crowd scene ref
- `ref-sympathy.png` — hospital/sad scene ref
- `ref-pair.png` — two characters together

### Character DNA (from ACTUAL reference, NOT imagined)
- Eyes: TINY black dots, close together, center of face
- Nose: NONE
- Mouth: tiny line, barely visible
- Face: occupies ~15-20% of body area, rest is white space
- Body: soft blob, slightly wider than tall, NOT perfect sphere
- Outline: thin black
- Blush: small simple pink circles (NOT gradient airbrush)
- Limbs: tiny nub arms, short stub feet
- Style: flat kawaii with minimal depth — NOT full 3D Pixar render
- Color: cream/white body, cream background, pink accents only

### Never Repeat
- ❌ Text-to-image generation for character (too generic, wrong proportions)
- ❌ Describing character in prompt without image reference (drifts every time)
- ❌ High strength (0.82+) with character ref (changes too much of the character)
- ❌ Using multiple different panels as ref across batch (inconsistent)

**How to apply:** Always use ref-activity.png as Image 1 for mascot poses. Strength 0.65. Describe pose only.
