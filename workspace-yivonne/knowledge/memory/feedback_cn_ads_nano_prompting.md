---
name: CN ads NANO prompting — hard-won patterns from v4 campaign
description: 7-layer prompt architecture, anti-render safety, brand name leak workarounds, typography dominance, human realism failures, packaging photo preservation. All learned from 24-variant cn-ads-v4 campaign with 4 fix rounds.
type: feedback
---

## NANO Prompting Patterns — CN Ads v4 (2026-03-13)

### 7-Layer Prompt Architecture (proven)
L1: SAFETY (anti-render + brand name ban) — ALWAYS first
L2: BRAND DNA (palette, mood)
L3: FOOD integrity (sacred photographs, zero AI food)
L4: TYPOGRAPHY direction (editorial, massive, etc.)
L5: BADGE system (Aesop-style certification marks)
L6: Scene/layout instructions (edit-first, reference-based)
L7: OUTPUT_SPEC (4:5, no crop, no artifacts)

### NANO Brand Name Leak (unsolved, workaround only)
NANO renders "MIRRA" as visible text despite explicit bans ("Do NOT write ANY English brand name", "BRAND NAME BAN", "ABSOLUTE BAN"). It pulls brand names from packaging photos AND from context. No prompt wording stops this 100%.
**Workaround:** Accept it — the post-production `place_logo()` adds the correct small signature. The NANO-rendered "MIRRA" is an extra but doesn't break the ad. For clients who care, PIL inpainting could remove it.

### NANO Cannot Generate Realistic Humans in Scenes
Full-body humans in lifestyle scenes = 100% obviously AI. User called it out immediately: "confirm 100% can tell its AI generated."
**Fix:** Remove the human. Let the SCENE + COPY carry the emotion. An empty cafe table with bento + "你也值得好好吃一顿" is MORE powerful than a fake AI woman — the viewer imagines HERSELF in that seat.
**When humans work:** Close-up/partial (hands holding product — V22), or the reference already HAS a strong human photo that NANO can edit-first.

### Typography Dominance = Expensive Feel
Massive Chinese characters (50%+ of canvas height) = the single biggest factor in making an ad look premium vs cheap.
- fix3 V03 with MASSIVE '不重复' = expensive billboard energy
- fix4 V03 with smaller '午后限定' = lost the premium feel, user rejected
- **Rule:** When the concept is type-driven, the characters must DOMINATE. 50-60% canvas height minimum. Food is secondary.

### Product Packaging Photos — Preserve the Sticker
When using real product packaging photos (e.g., Mirra closed bento with branded sticker):
- Do NOT tell NANO to blank out the sticker text — makes it look fake
- DO tell NANO to preserve the packaging photo EXACTLY as provided
- The branded sticker IS product photography, not added design text
- Tell NANO the sticker color must be vibrant warm salmon pink to match the ad's warm palette (NANO tends to desaturate it)

### "Complete Ad" is NOT a Blanket Rule
User corrected: don't apply badges/CTA/price to ALL ads. Analyze per variant:
- **TOFU (awareness/editorial):** Vibe-first, minimal signals OK. The mood IS the message.
- **MOFU (consideration):** Needs trust signals (badges, reviews, social proof).
- **BOFU (conversion):** Needs price anchor + CTA + trust badges.
- **Concept (storytelling):** Narrative-first. Commercial anchors are subtle, at the end.
Always ask WHY a variant needs something before adding it.

### Post-Processing for CN Ads (locked)
`resize(1080,1350, LANCZOS) → place_logo(position="auto") → add_grain(0.016)` — DONE.
NO filter. NO color grade. Logo + grain ONLY on NANO outputs.
