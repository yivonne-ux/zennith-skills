---
name: Video craft V4 learnings — ohneis + Ana forensic + font liberation
description: Critical production learnings from mirra_cook v1-v4. Ohneis prompt DNA, Ana's Home Cafe forensic analysis, font liberation, ASMR quality requirements. Apply to ALL future video production.
type: feedback
---

## Ohneis Prompt DNA (ALWAYS apply to NANO/Imagen refs)
NOT descriptions. ART DIRECTION. Every prompt must include:
1. **Analog imperfections IN the prompt** — lens scratches, dust particles, halation, bloom, film grain. Baked into generation, not post-processing.
2. **Hyper-specific materials/textures** — not "ceramic mug" but "handmade stoneware with uneven glaze, hairline crazing, matte sage exterior"
3. **Camera/lens as character** — exact mm, f-stop, and WHY that lens for this shot
4. **Environmental props that build a world** — specific details that tell you WHOSE space this is
5. **Mood keywords at the end** — "the mood is intimate, unhurried, cinematic" anchors the generation

**Why:** v1-v3 refs looked like stock photos because prompts were descriptions ("hands on mug"). v4 refs with ohneis DNA created specific, art-directed worlds.

**How to apply:** Write every NANO prompt as if you're briefing a cinematographer, not describing an image.

## Ana's Home Cafe Forensic (ALWAYS apply to lifestyle video structure)
1. **One continuous world** — same room, same props, same light. NOT disconnected shots.
2. **Shot variety as rhythm** — through-glass → abstract bokeh → medium action → wide establishing → extreme macro → intimate detail. Never all the same framing.
3. **Typography as poster design** — mixed fonts, mixed sizes, playful asymmetry. NOT centered text strings.
4. **One hero lockup moment** — tease → REVEAL → breathe. Not 6 equal text cards.
5. **Color grade IS identity** — baked into footage, not CSS filter on top.
6. **Specific objects = real person** — every prop is HER thing, in HER space.

## Font Liberation
Do NOT lock to Mabry Pro + Awesome Serif for every piece. Choose fonts that match the MOOD of the specific content:
- **Playfair Display** — high-contrast editorial, magazine covers
- **Cormorant Garamond** — elegant, warm, light weights feel delicate
- **DM Serif Display** — warm, approachable, modern serif
- **Libre Caslon Display** — classic, timeless editorial
All downloaded to `remotion/public/fonts/`, registered in `fonts.ts` as `FONT_EDITORIAL_*`.

## ASMR Quality Gaps
v4 ASMR was "pretty good" (macro ceramic) but not world-class because:
- No SOUND DESIGN (steam hiss, ceramic clink, fabric rustle)
- No STORY connecting the sensory moments
- No MOTIVE — "why am I watching this?"
- Prompts need more: juice droplets, steam curl behavior, surface tension, fiber tension
- Study: Veo 3 ASMR fruit cutting prompts use extreme specificity on motion + texture

## Art + Message
Not sales-first, but PURPOSE-first. Every shot needs:
- A WHY (not just "showing what's in the house")
- An emotional arc (curiosity → discovery → intimacy → satisfaction → peace)
- Visual storytelling (action, not stillness — someone DOING something)
- Brand DNA without brand mention (Mirra = warmth, intention, care for self)
