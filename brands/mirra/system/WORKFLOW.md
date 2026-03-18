# mirra.eats — Content Generation System
## Full Workflow, Architecture & Compounding Learning Log

> **Living document.** Updated after every batch. When something works, it enters here as a rule. When something fails, it enters here as a lesson. The system gets smarter every run.

---

## 1. What This System Is

mirra.eats is a Singapore-based healthy meal delivery brand. This workflow generates Instagram content (1080×1350, 4:5) across 5 design categories. Each piece goes through a multi-model AI generation pipeline, Mirra brand filter, and automated vision audit.

The system does not generate content from scratch. It takes **reference images** (scraped Pinterest/brand aesthetic boards), transforms them into Mirra-branded compositions, embeds real Mirra food photography, and applies a consistent Mirra filter stack.

---

## 2. File Structure

```
mirra-workflow/
├── cat02_batch.py        — Glitter billboard quote (M-batch done)
├── cat03_batch.py        — Attitude meme still (not yet built)
├── cat04_batch.py        — Pure vibe sparkle (V4 done)
├── cat06_batch.py        — Graphic brand design (Q-batch v8, current)
├── cat08_batch.py        — Typographic quote (L-batch done)
├── WORKFLOW.md           — This document
├── fonts/                — All typography assets
├── cat02-v1/             — M1-M7 outputs
├── cat04-v4/             — V-series outputs (20 images)
├── cat06-v7/             — Q01-Q16 outputs (16 images)
├── cat08-full/           — A/C/D/L-batch outputs

mirra-pinterest-refs/
├── 02-glitter-billboard-quote/
├── 04-pure-vibe-sparkle/
├── 06-graphic-brand-design/     ← ref images for cat06
├── 08-typographic-quote/
└── MIRRA LOGO/
    └── Mirra Social Media Logo.png

Knowledge Base (Google Drive):
└── Mirra/Mirra Knowledge Base/Variety Dishes Mirra/   ← 14 dish photos (food source)
```

---

## 3. Brand DNA — Mirra Rules

These rules are non-negotiable in every output. Any image that violates these fails audit.

### Colour palette
| Role | RGB | Name |
|------|-----|------|
| Primary blush | (248, 190, 205) | Mirra blush rose |
| Dusty rose | (235, 170, 185) | Mirra dusty rose |
| Crimson | (172, 55, 75) | Mirra crimson |
| Cream | (255, 245, 238) | Warm cream |
| Overlay bg | (245, 220, 210) | Blush overlay |

### Brand mark modes
- **Mode A**: `mirra` — lowercase, handwritten script, small signature placement (inside card, bottom-right corner)
- **Mode B**: `@mirra.eats` — small clean type, top-right of frame or bottom-centre

### Voice rules
- Girlboss, unapologetic, aspirational
- No exclamation marks
- No brand references to other companies
- No food references by ingredient (say "the bowl" not "the rice bowl with…")
- Quotes must be viral and sendable — the kind you screenshot and send to your group chat

### Output spec
- 1080 × 1350 px (4:5 portrait)
- PNG format
- Grain applied LAST (always after filter, always after logo)

---

## 4. Multi-Model Generation Pipeline

This is the core architecture. **Do not deviate from this unless there is a documented reason.**

### 4.1 Pipeline overview

```
REF IMAGE (Pinterest scrape)
       │
       ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PIPELINE A — Text/surface swap only (no food photo)               │
│  Models: nano | flux | two_pass                                     │
│  Use when: composition has no food, or food position is generated   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  PIPELINE B — Food photo as INPUT to generation                     │
│  Step 1 (Python): _treat_food_photo() → crop + warm tint + desat   │
│  Step 2 (NANO multi-image): [wireframe, treated_food(s)]           │
│  Prompt anchors food FIRST. Composition built around it.            │
│  Use when: a food photo needs to appear in a defined zone.          │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  PIPELINE B TWO-PASS — FLUX surface first, then NANO adds food     │
│  Step 1 (Python): treat food                                        │
│  Step 2 (FLUX): replace background/surface/text — NO food mention  │
│  Step 3 (NANO multi-image): [FLUX result, treated_food(s)]         │
│  Use when: background needs heavy replacement + food icon needed.   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  PIPELINE C — Food IS the background layer                          │
│  Step 1 (Python): treat food as full-bleed bg (4:5, tint 12%)     │
│  Step 2 (NANO multi-image): [wireframe, treated_bg]                │
│  Prompt anchors bg FIRST. UI overlays sit on top.                  │
│  Use when: food photo fills the entire background.                  │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Post-processing stack (always in this order)

```
AI OUTPUT IMAGE
      │
      ▼
1. fit_45(img, top_bias)           — crop/resize to 1080×1350
2. mirra_filter_06(img, mode)      — blush overlay, desat, warmth
3. stamp_logo(img)                 — ONLY if logo_in_design=False
4. add_grain(img, strength=0.014)  — ALWAYS LAST
      │
      ▼
OPTIONAL: text_fix_prompt          — NANO single-image text correction
                                     (runs on raw AI output, before fit_45)
```

### 4.3 Model reference

| Model ID | fal endpoint | Best for |
|----------|-------------|----------|
| `nano` | `fal-ai/nano-banana-pro/edit` | UI chrome, text swaps, overlays |
| `flux` | `fal-ai/flux-pro/kontext/max` | Background replacement, gradient preservation |
| `two_pass` | FLUX → NANO | Surface rebuild first, text correction second |
| `pipeline_b` | treat + NANO multi | Food in defined zone, one or multiple dishes |
| `pipeline_b_two_pass` | treat + FLUX → NANO multi | Heavy surface change + food icon placement |
| `pipeline_c` | treat bg + NANO multi | Food as full-bleed background |

### 4.4 Food treatment function

```python
def _treat_food_photo(food_path, zone_ar=(3,4), warm_tint=0.08, desat=0.10):
    food = Image.open(food_path).convert("RGB")
    food = _center_crop_to_ratio(food, zone_ar[0], zone_ar[1])   # never stretch
    arr  = arr + warm_tint * (warm_overlay - arr)                 # amber tint
    arr  = gray * desat + arr * (1.0 - desat)                    # partial desat
    return PIL Image
```

**Zone aspect ratios used:**
- `(3, 4)` — portrait card, polaroid, AirDrop image
- `(16, 9)` — landscape banner inside card
- `(4, 3)` — landscape solution photo
- `(1, 1)` — square grid cell, small icon, floating cut-out

---

## 5. Prompt Engineering Patterns

These patterns are proven. Use them exactly.

### 5.1 Pipeline B prompt structure (mandatory)

```
[SCALE LOCK if needed]: "Do NOT zoom in. The full interface must be visible..."
PART 1 — ANCHOR FOOD (always first):
  "Image 2 is a [dish name] food photograph — [description].
   In Image 1's [zone description], Image 2's food photograph [fills/sits in] [position].
   Image 2's actual photograph IS the food in [zone] — [fill instruction].
   Do not generate any AI food. Preserve Image 2's photograph exactly."
PART 2 — BUILD AROUND IT:
  "Adapt the surrounding [composition type] for Mirra brand:
   [brand surface instructions, text replacements, colour changes]
   Erase all [original brand] watermarks from every corner."
```

### 5.2 Surface replacement prompt (Pipeline A)

```
"Keep the composition exactly: [describe layout].
 SURFACE REPLACEMENT ONLY — do not move or resize any element.
 [specific colour changes]
 [specific text replacements — EXACTLY AS WRITTEN: '...']
 Scan every corner (bottom-left, bottom-right, bottom-centre) and
 erase any creator watermark, handle, or brand tag that is not Mirra copy.
 Apply warm muted Mirra tonal skin."
```

### 5.3 Text fix prompt (single-pass correction)

```
"TEXT CORRECTION ONLY — [everything except the target text] is LOCKED — do not change them.
 [Specific text to change] must read EXACTLY: '[value]'
 ([note any intentional spelling] — intentional, do not correct it).
 No other changes whatsoever."
```

### 5.4 Canvas safety instruction (when text gets cropped)

```
"CANVAS SAFETY: All card text must be FULLY VISIBLE — nothing truncated at the [edge].
 If any text extends beyond the canvas boundary, pull it inward so it reads completely."
```

### 5.5 FLUX prompt rule

Use **FINAL-STATE** prompts with FLUX, not diff/swap prompts.
- ✓ "The background is Mirra blush (248, 190, 205)"
- ✗ "Change the background FROM blue TO Mirra blush"

FLUX confuses overlapping word swaps — describe the final desired state.

---

## 6. Food Library

**ONLY use photos from:** `Variety Dishes Mirra` (Knowledge Base)
**Path:** `.../Knowledge Base/Image & Copywriting content Knowledge Base/Mirra/Mirra Knowledge Base/Variety Dishes Mirra/`

**DO NOT** use `/Resources/Mirra Menu Dishes/` — these are old, inconsistent shots.

| Dish | Assigned to | Zone AR |
|------|-------------|---------|
| Korean Bibimbap | Q03 iMessage | (3, 4) |
| Jawa Mee Bowl | Q05 AirDrop | (16, 9) |
| Teriyaki Mushroom Asada Burrito Bowl | Q06 Kit Card polaroid | (3, 4) |
| Green Curry Rice | Q08 Chat Grid cell 1 | (1, 1) |
| Fusilli Bolognese | Q08 Chat Grid cell 2 | (1, 1) |
| Korean Bulgogi Rice With Broccoli | Q08 Chat Grid cell 3 | (1, 1) |
| Konjac Pad Thai | Q08 Chat Grid cell 4 | (1, 1) |
| Eight Treasure Congee | Q09 Her Week Plans floating | (1, 1) |
| Japanese Katsu Curry | Q12 Search→Solution | (4, 3) |
| Nasi Lemak Classic | Q14 Chat Bubble bg | (4, 5) |
| Taiwanese Braised Mushroom Rice | Q15 Toggle row icon | (1, 1) |

Remaining (unassigned, available): BBQ Pita Bread, Dry Classic Curry Konjac Noodle, Vegan Squid Curry Rice

---

## 7. Vision Audit System

**8-dimension audit** — every output is checked. `overall_pass` requires all 8.

| Dim | What it checks | Critical |
|-----|---------------|---------|
| `watermark_clear` | No foreign brand handles in any corner | YES — triggers auto-retry |
| `mirra_palette` | Pink/blush tones visible | YES |
| `logo_present` | 'mirra' or '@mirra.eats' visible | YES — triggers auto-retry |
| `text_ok` | All text legible, no garbled characters | YES |
| `crop_safe` | No text/element truncated at canvas edge | YES |
| `layout_intact` | Composition coherent, not distorted | YES |
| `food_real` | Food looks photographed, not AI-generated | YES |
| `brand_voice` | Warm, aspirational, sendable | soft check |

**Models:** Primary = `fal-ai/any-llm/vision` + `openai/gpt-4o`
**Fallback:** `fal-ai/llava-next`
**Supplementary:** PIL pixel check (r_mean > b_mean + 4 = pink bias present)

**Auto-retry logic:** If `watermark_clear=false` OR `logo_present=false` → NANO runs on the OUTPUT image with targeted fix prompt. Does NOT re-run full generation.

---

## 8. Compounding Learning — What Works

Lessons locked in as permanent rules.

### Generation

| Learning | Rule |
|----------|------|
| Food post-composited after AI generation = two visual realities | Food must be INPUT, not inserted afterward. Use Pipeline B. |
| NANO with 5+ images misses text changes (too busy managing food) | Add `text_fix_prompt` for critical text corrections after multi-image gen |
| FLUX two_pass on complex designs: FLUX fails with "Error generating image" | NANO fallback on source before falling back to raw ref |
| zoomed-in iMessage output (food bubble fills frame) | Add SCALE LOCK instruction: "full interface must be visible, food bubble is ONE element" |
| Card text cut off at right canvas edge | Add CANVAS SAFETY instruction: "All text fully visible within 90% of frame width" |
| `logo_in_design=False` on food-extending designs stamps logo OVER food | Set `logo_in_design=True` when NANO already places @mirra.eats in design |
| `top_bias=0.4` crops navigation bar on iMessage | Use `top_bias=0.15` for full-interface UI screenshots |
| FLUX Kontext max on gradient poster = correct. NANO on gradient = grunge texture | For gradient backgrounds, always use FLUX Kontext max |
| FLUX needs FINAL-STATE prompts | Do not use diff language ("change X to Y") — describe the final desired state |
| Pipeline A nano for floating-items with AI food = generic AI bowls | Switch to Pipeline B — real dish photo as INPUT replaces AI food generation |
| Toggle row icons (small) with AI food = cartoonish generic icons | Pipeline B_two_pass: FLUX builds card surface, NANO multi-image places real food icon |

### Filtering

| Learning | Rule |
|----------|------|
| `grain=0.016` invisible on flat typography backgrounds | Use `strength=0.022` minimum for cat08 typography |
| `grain=0.014` for cat06 UI screens | Correct — UI designs need lighter grain |
| `overlay_alpha=20-26` invisible on flat backgrounds | Use 40-50 for strong surfaces, 28 only for warm paper (cat08 notecard) |
| Double desaturation when filtering an already-filtered image | For images already Mirra-filtered (e.g. A5-gradient): apply grain+sparkle ONLY |
| Grain must be LAST in post-processing | Always: filter → logo → grain. Never reorder. |

### Audit

| Learning | Rule |
|----------|------|
| `fal-ai/llava-next` 4-dim audit misses crop and food quality issues | Upgrade to 8-dim with `fal-ai/any-llm/vision` + gpt-4o |
| `openai/gpt-4o-mini` model ID deprecated on fal (March 2026) | Use `openai/gpt-4o` |
| PIL pixel check supplements LLM audit | r_mean > b_mean + 4 = pink bias present; flag if fails |
| Auto-retry runs NANO on OUTPUT (not source) | Prevents full re-generation on minor issues |

---

## 9. Compounding Learning — What Was Rejected

Approaches that were tried and abandoned. Do not revisit without new evidence.

| Approach | Why Rejected |
|----------|-------------|
| Pure Python gradient generation | Too flat/pastel — machine-generated look, not organic. ref RGB(215,105,138) vivid pink is impossible in PIL |
| Post-compositing food after AI generation | Creates "two visual realities" — food photo looks pasted, not native to composition |
| Using old `/Resources/Mirra Menu Dishes/` photos | Inconsistent shots, not the approved Variety Dishes Mirra library |
| `nano` model for gradient posters (cat08 T5) | NANO adds grunge texture to smooth gradient backgrounds |
| Overlay alpha 20-26 | Invisible on flat colour backgrounds — always use 40-50 |
| `gpt-4o-mini` on fal-ai/any-llm/vision | Deprecated model ID (March 2026) — use `gpt-4o` |
| Diff/swap language in FLUX prompts | FLUX confuses overlapping replacements — use final-state description |
| `prompt` key for `two_pass` model type | two_pass reads `flux_prompt` + `nano_prompt` separately — `prompt` key does nothing |
| Running full pipeline sequentially | 8 parallel subprocesses complete in ~2 min vs ~15 min sequential |
| `logo_in_design=False` when food extends to bottom | stamp_logo() at bottom overlaps food — use `logo_in_design=True` when @mirra.eats is already in design |

---

## 10. cat06 Template Registry (Q-batch v8)

All 16 templates with their pipeline, food source, and known behaviour.

| # | Key | Label | Pipeline | Food | Notes |
|---|-----|-------|----------|------|-------|
| Q01 | receipt | Receipt Haul | two_pass | — | FLUX clears receipt, NANO rewrites text |
| Q02 | calendar | Calendar Routine | nano | — | iOS Calendar event colour + text swap |
| Q03 | imessage | iMessage Testimonial | pipeline_b | Korean Bibimbap (3:4) | top_bias=0.15; SCALE LOCK in prompt |
| Q04 | giftguide | Gift Guide | two_pass | — | FLUX box/bg, NANO gift text |
| Q05 | cdcover | AirDrop Offer | pipeline_b | Jawa Mee Bowl (16:9) | Food in card landscape zone |
| Q06 | swatch | Kit Profile Card | pipeline_b | Teriyaki Mushroom Asada Burrito Bowl (3:4) | Food in polaroid frame |
| Q07 | profilecard | Profile Card Polaroid | two_pass | — | CANVAS SAFETY — text was cut at right edge |
| Q08 | keycard | Chat + Meal Grid | pipeline_b | 4 dishes (1:1 each) | text_fix_prompt for "Waittt let me think......" |
| Q09 | plans | Her Week Plans | pipeline_b | Eight Treasure Congee (1:1) | Floating cut-out item |
| Q10 | challenge | Mirra Challenge Card | two_pass | — | Bingo card, tag shape, sky bg |
| Q11 | notecard | Morning Routine Note Card | two_pass | — | NANO fallback if FLUX fails |
| Q12 | searchbar | Search Bar + Solution | pipeline_b | Japanese Katsu Curry (4:3) | logo_in_design=True |
| Q13 | calannounce | Calendar Announcement | nano | — | Grid paper background, date text |
| Q14 | chatbubble | Chat Bubble on Photo | pipeline_c | Nasi Lemak Classic (4:5 bg) | Food IS the background |
| Q15 | toggleroutine | Morning Routine Toggle | pipeline_b_two_pass | Taiwanese Braised Mushroom Rice (1:1) | FLUX builds card + text; NANO adds food icon to rows |
| Q16 | essentialscart | Monday Essentials Cart | flux | — | 3D cart, product scatter |

---

## 11. cat08 Template Registry

5 design templates, each batch is 5 outputs with new quotes.

| # | Type | Model | Filter mode | Font |
|---|------|-------|-------------|------|
| T1 | Script quote | nano | C1 (ov_alpha=48, desat=0.83, sparkle=4) | GreatVibes |
| T2 | Notecard | nano | C2 (ov_alpha=28, desat=0.87, sparkle=3) | PlayfairDisplay Bold + CaveatBrush |
| T3 | Display overlap | nano | C3 (ov_alpha=50, desat=0.82, sparkle=5) | GreatVibes accent + PlayfairDisplay |
| T4 | List card | nano | C4 (ov_alpha=40, desat=0.85, sparkle=4) | ClashDisplay + InstrumentSerif |
| T5 | Gradient poster | flux | C5 (grain+sparkle only) | AbrilFatface |

**T3 rule:** Always use A3-display-ai.png as source, never the original ref. Source locks correct scale.
**T5 rule:** FLUX Kontext max from A5-gradient-ai.png. A5 is already filtered — apply grain+sparkle only in post.

---

## 12. Batch Execution Pattern

### For a fix batch (re-run affected templates only):

```python
# Launch in parallel — 8 simultaneous subprocesses
for key in ["imessage", "swatch", "profilecard", "keycard", "plans", "notecard", "searchbar", "toggleroutine"]:
    subprocess or Bash background: python3 -c "m._build(key)"
```

Each subprocess runs independently — fal.ai calls are non-blocking. 8 templates = ~2 min parallel vs ~15 min sequential.

### For a new full batch:
1. Edit `BATCH_PREFIX` (next letter: R, S, T…)
2. Edit `QUOTES` dict with new Mirra voice copy
3. Run `python3 cat06_batch.py`
4. Review outputs in `cat06-v7/`
5. Document any new failures in this file

---

## 13. Innovation Pipeline — What We're Building Toward

Ideas being tested or queued. Not yet production rules.

### Active experiments
- **Qwen3-VL for audit** — Qwen3-VL-235B has best spatial reasoning in benchmarks. Test if it catches layout failures that gpt-4o misses on complex UI compositions.
- **Parallel audit** — Run gpt-4o + Qwen3-VL simultaneously, flag if they disagree.

### Queued for cat03 (attitude-meme-still)
- 8 refs in folder, batch script not yet built
- Attitude memes are image-text composites — likely Pipeline A nano (text swap)
- May need Pipeline B for food-in-meme compositions
- Meme voice is different: edgier, more irreverent than cat08 typographic quotes

### Structural improvements
- **Reference locking** — Store canonical approved output as new source for next batch. NANO edits approved output → drifts less over time.
- **Batch validation report** — After every run, write a JSON report with all 8 audit scores per template. Track score trends over batches.
- **Auto-tune top_bias** — Detect if important elements (nav bars, logos) are cropped by sampling edge rows, auto-correct top_bias.

---

## 14. Version History

| Version | Batch | Date | Key change |
|---------|-------|------|------------|
| v1 | original | — | Basic Python filter, no AI |
| v5 | P-batch | — | First NANO/FLUX integration, food post-composited |
| v7 | P-batch | — | 17 templates, food zones in prompts, fal.ai pipeline |
| v8 | Q-batch | Feb 2026 | **Multi-model pipeline architecture** — Pipeline A/B/C. Food as INPUT not post-composited. 8-dim audit. pipeline_b_two_pass. text_fix_prompt. NANO fallback for FLUX failures. |
| v8.1 | Q-batch fix | Mar 2026 | All 8 failing templates fixed + regenerated in parallel. Audit model → gpt-4o. |

---

## 15. Running the System

### Full batch
```bash
cd /Users/yi-vonnehooi/Desktop/mirra-workflow
python3 cat06_batch.py
```

### Single template (for debugging)
```python
import importlib.util
spec = importlib.util.spec_from_file_location("m", "cat06_batch.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m._build("imessage")  # or any key
```

### Audit only (on existing output)
```python
from PIL import Image
img = Image.open("cat06-v7/Q03-imessage.png")
result = m.audit_image(img, "iMessage Testimonial")
m._print_audit(result)
```

---

*Last updated: March 2026 — Q-batch v8.1 fix run complete. All 16 templates passing 8/8 audit.*
