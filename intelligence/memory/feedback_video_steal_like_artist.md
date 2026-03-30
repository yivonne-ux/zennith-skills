---
name: Video Production — Steal Like An Artist, Not "Inspired By"
description: CRITICAL. When adapting a reference video, copy the EXACT structure frame-by-frame — same poses, angles, timing, momentum, cuts. Only change the person, food, setting, and brand. Never try to be creative with the structure. The reference IS the skeleton.
type: feedback
---

When user says "1 to 1 copy of reference" they mean FORENSIC frame-by-frame structural copy:

1. **Same poses/actions** — if reference has woman standing and talking, generate woman standing and talking at same angle
2. **Same cut timing** — if reference cuts every 1.2s, cut every 1.2s
3. **Same energy arc** — if reference is rapid montage to music, don't build a slow narrative
4. **Same number of shots** — count the cuts, match the count
5. **Same text placement** — if reference has 2 text cards, use 2 text cards
6. **Same composition** — if reference is MCU at 55% frame, match that framing

**What to change:** Person (→ Malaysian), setting (→ KL condo), food (→ Mirra dishes from library), text content (→ Mirra message), brand palette

**What NOT to change:** Shot structure, cut rhythm, camera angles, pose/action per shot, energy curve, text position/styling approach

**Why:** Discovered through V1-V3 failures. V1 used random library clips (wrong). V2 generated "a woman" and "some food" loosely inspired (wrong). V3 was closer but still narrative when reference was montage (wrong). The reference video's structure IS what makes it work. Steal the structure, adapt the content.

**How to apply:** Before generating ANY footage, do forensic frame-by-frame breakdown of reference. Create a shot list that maps EVERY second of reference to what Mirra version should be. Generate/source footage that matches each shot EXACTLY. Use library food clips where they match (don't generate food unnecessarily). Then assemble with same timing.

**Also learned:**
- Use library food footage when available (we have 740 clips) — don't AI-generate food unnecessarily
- Mix footage sources freely (different KOLs, generated + library) — reference does this too
- FFmpeg drawtext = functional but boring. Remotion = designed typography with spring physics, glow, animation
- ASS subtitles have CJK font rendering issues — use Remotion or drawtext with explicit fontfile
- No VO needed if reference has no VO — music-driven montage is its own format
