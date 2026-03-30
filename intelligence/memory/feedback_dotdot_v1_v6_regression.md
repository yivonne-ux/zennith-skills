---
name: DotDot v1-v6 Regression — Logo + Art Style Root Causes
description: CRITICAL. Why logo kept failing (6 versions). Why art style inconsistent. Root causes + fixes. Apply before ANY future DotDot generation.
type: feedback
---

## DOTDOT v1-v6 REGRESSION (29 March 2026)

### LOGO — 6 VERSIONS OF FAILURE

| Version | Symptom | Root Cause |
|---------|---------|------------|
| v1 | Double logo | Prompt asked NANO to render logo AND PIL composited real logo |
| v2 | Double logo | Didn't fully remove logo instruction from prompt |
| v3 | Clipped by crop | crop-fit cut edges where logo sat |
| v4 | Overlapping content | Pad-fit pushed content center, logo landed on edge |
| v5 | Mostly OK | First version with clean logo, but white pill backing inconsistent |
| v6 | Off frame | Pad-fit added side padding → logo placed on PADDING STRIP not content |

**ROOT CAUSE**: Logo placement is calculated from CANVAS edge (`img.width - logo.width - margin`). But pad-fit changes the canvas size and adds empty padding. Logo ends up on padding, not on content.

**FIX**:
1. Place logo on the RAW NANO output BEFORE pad-fit resizing
2. Or: after pad-fit, calculate logo position relative to CONTENT bounds, not canvas bounds
3. Or: generate at correct aspect ratio so no pad-fit needed (best)

### ART STYLE — WHY INCONSISTENT

**ROOT CAUSE**: Image 1 DOMINATES art style in NANO (proven rule from `feedback_nano_style_dominance_rule.md`). Every post used a DIFFERENT Pinterest pin as Image 1:
- YOTTO quadrant → got YOTTO style
- Herbal Farmer steps → got Herbal Farmer style
- Douyin poster → got Douyin style
- Health infographic → got infographic style

Each Image 1 change = completely different visual output. 10 different refs = 10 different art styles = no visual cohesion.

**FIX**: Lock ONE SINGLE Image 1 reference for the ENTIRE batch. Use the BEST output from previous rounds as the style anchor. Pinterest refs inform the PROMPT TEXT (layout, typography instructions) but are NOT passed as Image 1.

**The hierarchy**:
1. BEST: Own approved output as Image 1 (proven to produce brand-consistent results)
2. OK: ONE Pinterest ref locked for all posts (at least consistent)
3. WRONG: Different Pinterest ref per post (what we did — inconsistent)

### PROCESS MISTAKES (never repeat)

1. ❌ Treating each template independently with its own ref → inconsistent batch
2. ❌ Post-processing (logo/grain) AFTER canvas resizing → logo displacement
3. ❌ Not using own approved outputs as refs → always starting from external refs
4. ❌ Changing multiple variables per iteration → can't isolate what works/fails
5. ❌ Not running visual audit BEFORE showing user → presenting broken outputs

### CORRECT PIPELINE (v7+)

```
1. LOCK one Image 1 ref for entire batch (own approved output or ONE Pinterest ref)
2. Generate ALL posts with same Image 1 (layout/content varies via prompt text only)
3. Place logo on RAW output (before any resizing)
4. THEN pad-fit to target dimensions
5. THEN apply grade → texture → grain → sharpen
6. Run 6-layer audit on EVERY output
7. Only show user if ALL pass audit
```

### WHY THIS MATTERS
The user asked for "one entity" — mascot + typography + illustration + message should feel like ONE brand, ONE visual system. Using different refs per post breaks this fundamental requirement. Lock the style, vary only the content.

**How to apply:** Before ANY DotDot batch, select ONE Image 1 ref (ideally from own approved outputs). Use it for ALL posts in the batch. Describe layout variations in prompt text, not by swapping Image 1.
