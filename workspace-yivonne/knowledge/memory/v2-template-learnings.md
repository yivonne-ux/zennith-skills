# V2 Template System — Compounding Learnings (updated 2026-03-11)

## Architecture Rule — v8 CORRECTED (PERMANENT)
- **NANO edit does EVERYTHING in one shot**: scene adaptation, food integration, typography, layout, color.
- **Reference image provides layout intelligence** — visual hierarchy, composition, spacing.
- **Real food photo(s) as input** — NANO integrates food naturally with shared lighting/shadows.
- **NANO handles branding text** — "MIRRA" rendered as part of the design, not PIL overlay.
- **PIL only does**: grain (always last). Production logo stamp SKIPPED (NANO renders it).
- **This approach produced the BETTER OUTPUTS** — confirmed superior to PIL text overlay.
- Model: `fal-ai/nano-banana-pro/edit` via `fal_client.upload_file()` (NOT data URIs).
- Post-processing: resize → grain only. No heavy color filters.

### Previous rule (SUPERSEDED — kept for reference):
- Old: "AI generates ONLY bg + food. PIL renders ALL text." — This produced amateur output.
- The cohesive "designed" look comes from NANO doing everything in one integrated pass.

## User Feedback — Round 2 (2026-03-11)

### Per-template issues:
| Template | Issue | Fix |
|----------|-------|-----|
| T01 | Use Mirra low kcal badge/icon (real asset), not just font text. Logo too small vs production. | Use real badge PNG + larger logo |
| T02 | Not using actual Mirra logo. Too much flat salmon — "all you see is salmon, no layers in color tone". | Need color depth/contrast, not flat overlay |
| T04 | White box artifact (prompt leakage). "Other brands" needs real photo, not cardboard box. Use "Mirra" word as logo (skip PIL stamp). | Real context photo + logo-as-headline pattern |
| T05 | Same prompt leakage. Don't go overly hardcore salmon filter overlay. Need contrast between bg/table/props. | Lighter color treatment, more layered |
| T06 | OK but needs refinement |
| T07 | Cropping own artwork — no safe space maintained. | Enforce margins strictly |
| T08 | Two visible bentos (montage fail). Typography looks "squarish and cheap" — not Mirra fonts. | All text via PIL with AwesomeSerif/MabryPro |
| T09 | Different angle from other images in grid — inconsistency. | Don't change angles in grid layouts |
| T10 | Circle frame doesn't fit template layout. Should be cropped bento. Crimson is off. | Match reference layout framing |

### Design principles from user (PERMANENT):
1. Logo position + size = FIXED per template (like Photoshop layers)
2. If logotype is used as headline, logo doesn't appear again
3. Only use REAL Mirra icons/badges from asset library
4. Each artwork gets individual color treatment — not global filter
5. Need color DEPTH — contrast between bg, table, props (not flat single color)
6. Safe zones / margins are NON-NEGOTIABLE — never crop own artwork
7. Realism in comparison ads — use real photos for context
8. Typography must be actual Mirra fonts — never AI-generated text
9. Grain overlay is the one constant across all artworks
10. Grid layouts must maintain consistent angles across all items

### Voice learnings:
- NO diet culture: calories, kcal, macros, "slim down", "clean eating", "low-cal"
- NO exclamation marks ever
- Aspirational: "she nourishes on purpose" not "320 calories per serve"
- The brand assumes she's smart — never preach or educate

## Production Logo System (confirmed from reverse-engineering)
- File: `Mirra Social Media Logo.png` (1080×1350 full canvas RGBA)
- Visible content: 167×33px at bottom-center, 71px from bottom
- Method: `Image.alpha_composite(canvas, logo_overlay)` — no dynamic positioning
- Auto black/white: check luminance at logo zone, tint overlay if dark bg
- Production standard across ALL categories (cat02, cat04, cat06, cat08, ads)

## NANO Edit Limitations (confirmed)
- NANO cannot reliably REPLACE text in existing images (T08, T09 text persisted)
- NANO is good at: food swaps, color shifts, scene generation, UI/layout recreation
- NANO is bad at: exact text editing, font matching, precise pixel-level changes
- For text replacement on existing ads: need inpainting approach or PIL overlay instead

## Round 3 Results (mirra_20260311_130540) — "BETTER OUTPUTS" source
- These were the quality bar outputs the user selected
- Pipeline: `run_v2_edit_test.py` → NANO edit single shot → resize → grain
- 10/10 success across 3 consecutive runs (120801, 124250, 130540)

## v8 Results (mirra_20260311_153016) — Reference-Guided NANO Edit
- **10/10 success** in 5.7 minutes, parallel 3
- Architecture: reference + food → NANO edit → grain only
- Random food selection + copy variants for each template
- T01: Excellent — MIRRA logo + lotus, nutrition callouts
- T02: Excellent — warm scene, 2 bentos, elegant serif
- T03: Good — prompt instruction "[THIS ONE HIGHLIGHTED IN PINK]" leaked as literal text (FIXED)
- T04: Excellent — split comparison, brown bag vs bento, star ratings
- T05: Excellent — iMessage chat with food photo, casual Malaysian English
- T06: Good — This or That, instant noodle vs bento
- T07: Good — 3-step process. Missing headline at top (prompt clarified)
- T08: Excellent — RM17++ pricing, food swap. "Slim down" persisted from reference (FIXED: explicit override in prompt)
- T09: Excellent — 9-dish grid with kcal labels, BBQ Pita swapped in
- T10: Excellent — "she eats well. on purpose." crimson bg, callout arrows, clean single logo

### Key v8 learnings:
1. NANO edit with `fal_client.upload_file()` is RELIABLE — 0 failures in 10/10
2. Prompt instructions in brackets leak as literal text — use natural language instead
3. NANO preserves reference text (T08 "Slim down") — must explicitly override in prompt
4. Skip production logo stamp — NANO generates MIRRA branding as part of design
5. Random food + copy variants give real variation per run
