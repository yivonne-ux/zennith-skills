---
name: DotDot Mascot — Character Design Pipeline (ChatGPT 4o → FLUX LoRA → Kling AI)
description: CRITICAL. Build mascot character sheet BEFORE any mascot post production. ChatGPT 4o for creation, FLUX LoRA for consistency, Kling AI for video. No traditional 3D needed.
type: feedback
---

## MASCOT PRODUCTION PIPELINE

### The Rule
NEVER generate mascot posts without a LOCKED character design sheet first.
The mascot is a DESIGN ASSET like the product packaging — build it, lock it, then use it.

### Why
v7-v8 generated mascot from text description → inconsistent shape, proportions, style every time.
Same mistake as generating product packaging from scratch instead of using real PNG.

### Pipeline
```
1. ChatGPT 4o: Create + iterate master character (conversation-based)
2. ChatGPT 4o / Lovart AI: Generate design sheet (turnaround, 8 expressions, 6 poses)
3. Export 30-50 renders as individual PNGs
4. fal.ai FLUX LoRA: Train consistency model ($2-4, 1200 steps)
5. FLUX LoRA: Generate mascot in creative poses for posts (consistent character)
6. Kling AI 3.0: Animate for video (still + audio → lip sync)
```

### For NANO Post Production
- Use FLUX LoRA-generated character still as Image 1 (style + character anchor)
- OR use character sheet pose PNG as Image 1
- Prompt describes the SCENE — NANO renders mascot in context with creative poses
- PIL only for logo + post-processing
- This gives creative freedom WHILE maintaining character consistency

### Key Tools
- ChatGPT 4o ($20/mo) — character creation
- Lovart AI (free) — character sheet generation
- fal.ai FLUX LoRA ($2-4) — consistency training
- Kling AI 3.0 ($10-30/mo) — video animation

### Not Needed
- ❌ Blender / Cinema 4D / ZBrush (traditional 3D)
- ❌ PIL composite for mascot (too static, no creative poses)
- ❌ Text-only description in prompt (inconsistent every time)

**How to apply:** Before ANY mascot content, check: "Do I have the FLUX LoRA trained?" If no → build character sheet first. If yes → use LoRA for all mascot generation.
