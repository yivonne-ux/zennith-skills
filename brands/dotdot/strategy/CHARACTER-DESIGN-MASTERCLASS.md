# DotDot Mascot — Character Design Masterclass

> Research from: Duolingo, LINE Friends, Kakao Friends, @business.shorts, @thegoodsuniverse,
> Pixar, Headspace. Tools: ChatGPT 4o, Lovart AI, FLUX LoRA, Kling AI, Midjourney.
> Date: 2026-03-29.

---

## KEY FINDING

@business.shorts and @thegoodsuniverse do NOT use traditional 3D software.
Their pipeline is: **Still image + Voice + AI animation**. No Blender, no Cinema 4D.

```
1. Generate character image (ChatGPT 4o / Midjourney)
2. Generate voice (ElevenLabs Cantonese)
3. Animate (Kling AI 3.0 — lip sync from still + audio)
```

The bottleneck is NOT animation — it is **character consistency**. Solve consistency, and the rest is a repeatable factory.

---

## CHARACTER DESIGN SHEET — 8 Components

| # | Component | What | For Mochi Character |
|---|-----------|------|-------------------|
| 1 | **Turnaround** | Front, 3/4, side (3 views for blob) | Sphere doesn't need back view |
| 2 | **Expression Sheet** | 8 expressions: happy, sad, surprised, thinking, excited, encouraging, pain/sympathy, teaching | Critical — face is the ONLY expression vehicle |
| 3 | **Pose Library** | 6 poses: standing, sitting, pointing, holding object, exercising, presenting product | Defines how mascot interacts with DotDot content |
| 4 | **Color Key** | All hex swatches | Teal body #4DBFB8, blush, dot eyes |
| 5 | **Construction Guide** | Circle ratios, head-to-body (1:1 for mochi), limb proportions | Enables consistency |
| 6 | **Hero Illustration** | The definitive "this is the character" image | Canonical reference |
| 7 | **Accessory Details** | Eye style, mouth variations, any brand elements | Dot eyes, line mouth system |
| 8 | **Character Brief** | Name, personality, voice, DO/DON'T | Warm uncle energy, NOT clinical |

---

## EXPRESSION SYSTEM (Minimal Features = Body is Primary)

| Expression | Eyes | Mouth | Body |
|-----------|------|-------|------|
| Happy | ^ ^ (curved up) | U-shape smile | Slight bounce |
| Sad | Dots with tear | Downturned line | Slight droop |
| Surprised | O O (wide circles) | Small O | Slight jump |
| Thinking | — · (one squint) | Wavy line | Tilt to side |
| Excited | ★ ★ (star eyes) | Wide open | Bounce/wiggle |
| Encouraging | ^ ^ with sparkle | Gentle smile | Arms up |
| Pain/Sympathy | > < (squint) | Wavy frown | Clutch body |
| Teaching | · · (normal dots) | Small line | Pointing gesture |

**70% of emotion conveyed through BODY** (squash/stretch, tilt, bounce, gesture).
**30% through face** (eye shape, mouth line).

---

## WHY ROUND MOCHI WORKS (Science)

- **Baby Schema** (Konrad Lorenz): Round = infant features = triggers care + warmth + attention
- Rounded shapes → positive emotions, better retention
- Black dot eyes → innocence + helplessness → sympathy/protectiveness
- Circles = friendliness + approachability
- **Perfect for DotDot**: trust + care + approachability for elderly health brand

---

## CONSISTENCY METHODS — Ranked for DotDot

### Recommended: FLUX LoRA Training
- Train adapter file on 25-50 character renders
- Settings: 1200 steps, learning rate 0.0004, LoRA rank 64
- Cost: $2-4 on fal.ai (one-time)
- Result: unlimited consistent generations with creative poses
- **This is how to use mascot in NANO**: LoRA-trained character + scene prompt = consistent mascot in creative poses

### Alternatives:
- **ChatGPT 4o Gen ID**: conversation-based, good for iteration, not for batch scale
- **Midjourney --cref**: good for exploration, limited precision at scale
- **Lovart AI**: purpose-built for IP/mascot, generates turnaround + expressions in one session
- **Neolemon**: cartoon-style character consistency across scenes

---

## DOTDOT MASCOT PIPELINE

### Phase 1: Create Master Character (1 session)

**Tool**: ChatGPT 4o image generation (best for iterative character design)

**Prompt pattern**:
```
3D Pixar-style render of a round mochi/dumpling character.
Perfectly spherical teal body (#4DBFB8). Head IS the body — one continuous round shape.
Two small black dot eyes positioned high on face. Pink peach blush on both cheeks.
Tiny line mouth. Thin subtle outline. Tiny stub arms and legs.
Soft subsurface scattering lighting. Studio lighting on cream background.
The character is warm, friendly, approachable — designed for a health supplement brand.
```

Iterate via conversation until perfect. Save Gen ID.

### Phase 2: Character Design Sheet (1 session)

**Tool**: ChatGPT 4o (same session) or Lovart AI

Generate:
1. Turnaround: front, 3/4, side (3 views)
2. 8 expressions (per table above)
3. 6 signature poses:
   - Standing neutral (hero pose)
   - Pointing at knee diagram (teaching)
   - Sitting in chair lifting leg (exercise demo)
   - Holding ✗/✓ cards (myth-busting)
   - Hugging product box (product presentation)
   - Giving thumbs up (encouragement/CTA)
4. Scale reference: mascot next to elderly human figure
5. Color key: all hex swatches

Export each as individual PNG (transparent bg if possible).

### Phase 3: Lock Consistency (1 hour)

**Tool**: fal.ai FLUX LoRA training

1. Upload 30-50 renders from Phase 2
2. Train: 1200 steps, lr 0.0004, rank 64
3. Test with 10 varied prompts
4. Cost: $2-4

### Phase 4: Production at Scale

**IG Static (mascot posts)**:
- FLUX LoRA generates mascot in scene
- Image 1 = style anchor (v6 approved output)
- Prompt describes scene + mascot interaction
- PIL composites logo + post-processing

**Video (30/month)**:
- FLUX LoRA generates still frame (mascot in pose)
- ElevenLabs: Cantonese voiceover
- Kling AI 3.0: animate from still + audio (lip sync)
- Post-prod: subtitles + brand bar

---

## BRAND MASCOT LESSONS (from case studies)

### From Duolingo:
- "You can't plan virality, but you can plan mentality"
- Character has personality INDEPENDENT of product
- Strict design system with primitive shapes = any artist can rebuild
- Uses Rive for animation state machine (20+ mouth shapes per character)

### From LINE Friends:
- Started as messenger stickers → became $1.2T business
- Simple enough to adapt to ANY context while remaining recognizable
- Every use must have STORY context — no random appearances

### From Kakao Friends:
- Ryan = lion without mane = aspirational insecurity = relatable
- "Most wary of character content produced without context"
- Character needs emotional depth, not just visual design

### From Headspace:
- No SINGLE mascot — illustration STYLE is the brand
- Viable alternative: brand recognition through style, not character
- All curved shapes, no sharp edges, ambiguous forms

### Applied to DotDot:
1. Give the mascot a NAME (Cantonese nickname Danny's audience connects with)
2. Give it a PERSONALITY (warm, slightly clumsy, genuinely cares about knee health)
3. Give it RELATIONSHIPS (interacts with elderly characters, with Danny)
4. Let it be WEIRD sometimes (not always perfectly on-brand — that's what makes it viral)
5. The mascot is the GUIDE through health education — not a salesperson

---

## TOOL STACK

| Tool | Role | Cost |
|------|------|------|
| ChatGPT 4o | Character creation + iteration | $20/mo |
| Lovart AI | Character sheet generation | Free tier |
| fal.ai FLUX LoRA | Train consistency model | $2-4 one-time |
| FLUX via fal.ai | Generate stills at scale | ~$0.01-0.05/image |
| Kling AI 3.0 | Animate for video (lip sync) | $10-30/mo |
| ElevenLabs | Cantonese voiceover | $5-22/mo |
