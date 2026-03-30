---
name: March Campaign v3 — Full Pipeline Learnings
description: Complete pipeline documentation for Mirra March 2026 campaign v3 — 30 variants, 5 pillars, ACCA funnel. Covers BETTER OUTPUTS DNA, v1→v3 evolution, god mode edit-first technique, logo rules, and all compounding learnings.
type: project
---

# Mirra March 2026 Campaign v3 — Pipeline Learnings

**Date**: 2026-03-12
**Output**: `test/campaign-output/march_campaign_v3_20260312_131628/` (30/30 success)
**God mode fix**: `test/campaign-output/v3_godmode_20260312_182649/` (4/4 success)
**Working dir**: `/Users/yi-vonnehooi/Desktop/Creative Intelligence Module/`

---

## BETTER OUTPUTS DNA — The Quality Bar (CRITICAL — memorize this)

Source: `test/v2-output/BETTER OUTPUTS/` — 5 PNGs that define what "good" looks like.
These outputs from Round 3 (`run_v2_edit_test.py`, run 130540) are the gold standard.

### 8 qualities that make them godlike:
1. **DIRECTIONAL LIGHTING** — Soft warm light from upper-left creating REAL shadows on surfaces. Not flat.
2. **CAMERA CRAFT** — 30-45 degree angles, shallow depth of field, 85mm lens compression. Not flat overhead.
3. **WARM SALMON/CORAL backgrounds** — NOT white/cream. Rich dusty rose, editorial warmth.
4. **PREMIUM PROPS** — Pink glass bottle, gold cutlery, linen napkin, tea glass, scattered herbs. STYLED.
5. **SURFACE TEXTURE** — Two-tone (colored wall + cream table surface). Creates depth.
6. **TYPOGRAPHY** — High-contrast serif, CREAM text on colored backgrounds, mixed weights, breathing room.
7. **SHADOWS & DIMENSION** — Objects float with soft shadows, slight elevation, depth of field blur.
8. **RADICAL SIMPLICITY** — Fewer elements, each one gets space. If you can remove it, remove it.

### What they look like specifically:
- T02 (lifestyle hero): Salmon wall + cream table. 2 bentos at angle. Pink glass bottle + gold cutlery + linen napkin. "lunch that loves you back" in cream serif. MIRRA bottom center.
- T03 (search solution): Search bar UI floating over styled food photography. Warm blush gradient bg.
- T05 (chat dialogue): Warm peach-to-blush gradient. Chat bubbles in cream/blush. Bento in chat. Malaysian casual speak.
- T06 (binary choice): Salmon bg. "this or that" in cream serif. Fast food vs bento side-by-side.
- T10 (narrative type): Salmon bg. "the real food your body actually craves." in cream serif. Food bowl with callout arrows.

### This DNA drove v3's system constants:
| DNA quality | → v3 constant |
|-------------|---------------|
| Directional lighting + camera | → CAMERA_CRAFT (editorial_photo only) |
| Warm salmon/coral + two-tone | → COLOR_MOOD |
| Premium props | → PROP_STYLING (editorial_photo only) |
| Typography | → TYPOGRAPHY_V3 |
| Radical simplicity | → SIMPLICITY_RULE |
| Shadows & dimension | → Embedded in CAMERA_CRAFT + FOOD_INTEGRITY_V3 |

---

## Logo Rule (PERMANENT — from BETTER OUTPUTS + v8 learning)

**NANO renders "MIRRA" / "mirra." as part of the design. PIL does NOT stamp a logo.**

### Why:
- BETTER OUTPUTS all have NANO-rendered "MIRRA" — small, elegant, bottom-center, integrated into the design
- This looks COHESIVE and DESIGNED — the logo is part of the composition
- PIL `place_logo()` on top of NANO's integrated branding = DOUBLE LOGO = wrong
- v8 learning confirmed: "Skip production logo stamp — NANO generates MIRRA branding as part of design"

### Correct post-processing stack:
```
resize 1080×1350 (LANCZOS) → grain(0.016) → DONE
```
NO `place_logo()`. NANO handles it.

### In prompts:
- Tell NANO to render "mirra." or "MIRRA" as part of the design
- For edit-first refs: "Replace [brand] with 'mirra.' in same style, same position"
- For generation refs: include "mirra." in the copy/layout description
- Do NOT include NO_LOGO instruction (that was a v3 regression)

---

## Campaign Structure

### 5 Pillars × 6 variants each = 30 ads
| Pillar | Theme | Target Persona |
|--------|-------|----------------|
| P1-SIZEDROP | Weight management | Sara wants to lose weight |
| P2-AUTOPILOT | Convenience | Sara wants lunch decided for her |
| P3-PASSPORT | Variety (50 countries) | Sara wants something new every day |
| P4-MAINCHAR | Identity/lifestyle | Sara wants to be the main character |
| P5-THEMATH | Rational proof (numbers) | Sara needs data to justify decision |

### ACCA Funnel: Awareness → Awareness → Comprehension → Comprehension → Conviction → Action

### Style split: 9 `editorial_photo` + 21 `graphic_design`

---

## Architecture

```
Reference image (Pinterest) ─┐
                              ├─→ NANO Banana Pro Edit (2K) ─→ resize 1080×1350 ─→ grain(0.016) ─→ final PNG
Real food photo(s) ───────────┘
```

- **NANO does EVERYTHING**: scene, food integration, typography, branding, layout, color
- **PIL only does**: resize + grain (always last). That's it.
- **NO color filter**. Photography IS the aesthetic.
- **NO PIL logo stamp**. NANO renders "mirra." as part of the design.

### NANO API call
```python
fal_client.subscribe(
    "fal-ai/nano-banana-pro/edit",
    arguments={
        "prompt": prompt,
        "image_urls": [ref_url, food_url, ...],  # flat list of strings
        "resolution": "2K",
    },
)
```

---

## Two Prompting Approaches (depends on reference type)

### Approach A: System Constants (for simple compositions — 26/30 variants)
Used when reference has simple spatial structures (hero, split, lifestyle, before/after).
v3 prompt = ANTI_RENDER + ref instruction + [CAMERA_CRAFT] + COLOR_MOOD + FOOD_INTEGRITY_V3 + [PROP_STYLING] + TYPOGRAPHY_V3 + SIMPLICITY_RULE + NO_PRICE + extra_text + OUTPUT_SPEC

- CAMERA_CRAFT + PROP_STYLING conditional on `editorial_photo` style only
- Reference treated as "spatial layout + design language guide"
- Works for 26/30 variants — all simple compositions

### Approach B: God Mode Edit-First (for UI-heavy refs — 4/30 variants)
Used when reference has complex UI structure (>8 elements: nav bars, cards, grids, time slots).

**Key insight**: Stop treating the reference as a "guide." NANO is an image EDITOR. The reference IS the image. We are EDITING it.

Prompt structure:
```
"Edit this image. Keep the EXACT same layout structure.

CHANGES — swap these elements only:
1. [specific element swap — brand name]
2. [specific element swap — food photo]
3. [specific element swap — colors]
4. [specific element swap — copy text]

PRESERVE — do NOT change:
- [explicit list of every structural element to keep]

This should look like someone opened the original in a CMS and swapped brand/food/colors/copy.
The STRUCTURE is pixel-identical."
```

**Why this works**: NANO's edit mode preserves what you don't mention. By framing it as "edit this, swap only X" instead of "create something inspired by this", NANO keeps the structure intact and only changes what you ask.

**Proven on**:
- P1-01: Divain "99 problems" → Mirra "800 kcal problems" (emoji row + bento row preserved)
- P2-03: Plately website → Mirra website (nav, hero, tagline, 3 cards all preserved)
- P2-04: iPhone Calendar → Mirra Calendar (week strip, time slots, event block, food breaking through)
- P4-04: REORIA Instagram carousel → Mirra carousel (3 cards, IG UI, blurred bg preserved)

**Output**: `test/campaign-output/v3_godmode_20260312_182649/`

### When to use which:
| Reference type | Approach |
|---------------|----------|
| Simple compositions (hero, split, lifestyle, before/after) | A: System constants |
| UI-heavy (website, calendar, app screenshot, card carousel) | B: God mode edit-first |
| Emoji grids, navigation bars, complex grids | B: God mode edit-first |

---

## v1→v2→v3 Evolution

### v1 — basic prompts, flat outputs
### v2 — added food integrity, color lockdown, no price, typography upgrade
### v3 — MASSIVE art direction upgrade driven by BETTER OUTPUTS DNA analysis:
- CAMERA_CRAFT, COLOR_MOOD, FOOD_INTEGRITY_V3, PROP_STYLING, TYPOGRAPHY_V3, SIMPLICITY_RULE
- ANTI_RENDER (stops NANO rendering hex codes as text)
- Style split: editorial_photo vs graphic_design
- 30/30 success, 26/30 excellent, 4 UI-heavy diverged → fixed with god mode

---

## NANO Edit Limitations (confirmed across all rounds)
- NANO cannot reliably REPLACE text in existing images (text persists)
- NANO renders prompt instructions in brackets as literal text — use natural language
- NANO renders hex codes/font names as visible text without ANTI_RENDER
- NANO treats references LOOSELY for complex UI — needs edit-first framing for structure fidelity
- NANO is excellent at: food swaps, color shifts, scene generation, typography, branding integration

---

## File Registry

| File | Purpose |
|------|---------|
| `test/run_march_campaign_v3.py` | v3 — 30 variants, system constants approach (1214 lines) |
| `test/run_v3_godmode.py` | God mode — edit-first for 4 UI-heavy variants |
| `test/run_v3_fix4.py` | Wireframe technique (superseded by god mode) |
| `test/v2-output/BETTER OUTPUTS/` | **THE quality bar** — 5 PNGs from Round 3 (130540) |
| `test/campaign-output/march_campaign_v3_20260312_131628/` | v3 output — 30 PNGs |
| `test/campaign-output/v3_godmode_20260312_182649/` | God mode output — 4 PNGs |

---

## Key Decisions & Why

1. **NO color filter** — Photography IS the aesthetic. NANO's native output + grain = production quality.
2. **NANO renders everything including logo** — Cohesive "designed" look. PIL logo stamp = amateur.
3. **editorial_photo vs graphic_design** — Camera craft + props only for photography. UI = clean.
4. **ANTI_RENDER** — Prevents NANO from rendering hex codes/font names as visible text.
5. **Edit-first for UI refs** — "Edit this image, swap only X" preserves structure. "Create inspired by" destroys it.
6. **SIMPLICITY_RULE** — Aesop store window. Fewer elements. But NOT for UI-heavy variants.

---

## Operational Notes
- 6 parallel workers for 30 variants, 2 workers + 3s stagger for 4-variant fixes
- Upload retry with exponential backoff for transient DNS errors
- Cost: ~$0.15/image at 2K, ~$4.50 per 30-variant campaign run
- Food: original library + drive-full bento folder. P3-03 uses 9 foods, P4-06 uses 3.
