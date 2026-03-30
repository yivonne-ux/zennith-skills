---
name: Social Media Production Engine — Brand-Agnostic Universal System (v1.0)
description: MASTER SYSTEM. The complete social media production pipeline that works for ANY brand. 148 rules from 6 brands, 200+ posts, 10+ production rounds. Brand DNA is a pluggable config layer. Read THIS first for any social production work.
type: feedback
---

# SOCIAL MEDIA PRODUCTION ENGINE — UNIVERSAL (v1.0)
**Built from:** 148 compound learnings across Mirra, Pinxin, DotDot, Bloom & Bare, Jade Oracle, GrabFood
**Proven across:** 200+ posts, 10+ production rounds, 6 brands
**Date:** March 29, 2026

---

## HOW THIS SYSTEM WORKS

This is ONE engine that works for ANY brand. You plug in a Brand Config (palette, voice, style) and the engine handles everything else. 80% of rules are universal — only 20% are brand-specific.

```
BRAND CONFIG (yaml/md)          UNIVERSAL ENGINE (this file)
├── palette                     ├── 1. SCRAPE
├── voice/tone                  ├── 2. CLASSIFY REFERENCE
├── visual DNA                  ├── 3. PLAN CONTENT
├── illustration style          ├── 4. ASSEMBLE PROMPT (7-layer)
├── personas (5-6)              ├── 5. GENERATE (NANO single-pass)
├── categories (10)             ├── 6. POST-PROCESS (PIL resize+logo only)
├── post-process params         ├── 7. AUDIT (12-layer gate)
├── compliance gates            ├── 8. USER GATE
└── logo assets                 └── 9. COMPOUND LEARN
```

---

## STAGE 1: SCRAPE

**Goal:** Build a library of viral references BEFORE producing anything.

**Tools:** gallery-dl, instaloader, WebSearch, MediaCrawler (XHS)
**Output:** Raw refs in `04_references/curated/`

**Rules:**
- Scrape from DIVERSE sources — never loop on the same 5 IG pages
- Sources: Pinterest, IG viral accounts, Twitter/X roundups, Threads, TikTok, XHS, Reddit
- Quality gate: min 600x600, portrait-friendly, min 20KB, no duplicates (perceptual hash)
- Pre-screen for COPYRIGHT (no Disney/Pixar/Bratz/movie stills) and SAFETY (no weapons/violence)
- Pre-screen for RESIDUAL TEXT (marquees/signs have baked-in text that ghosts through)
- Scraping yields ~10% usable — scrape 10x what you need
- Track used refs in `used_refs.json` — zero reuse across batches

---

## STAGE 2: CLASSIFY REFERENCE

Every reference must be classified by PURPOSE before use.

| Type | Purpose | How to Use |
|------|---------|-----------|
| **FORMAT** | Layout/structure (panel count, split, comparison) | Describe in PROMPT TEXT only. NEVER pass as Image 1 |
| **AESTHETIC** | Mood/style/texture/color treatment | Pass as Image 1 — NANO copies the LOOK |
| **CONTENT** | Viral quote/copy text | Extract TEXT from ref. Put in prompt. Never pass image |
| **FOOD** | Sacred product photos | Pass as Image 2+. NEVER modify. PIL enhance before upload |

**DUAL-REFERENCE ARCHITECTURE:**
```
Image 1 = AESTHETIC REF (controls HOW it looks)
Prompt  = FORMAT DESCRIPTION + CONTENT TEXT (controls WHAT it shows)
Image 2+= FOOD/PRODUCT REFS (placed exactly, SACRED)
```

**Critical rule:** Image 1 DOMINATES art style. Whatever you pass as Image 1, NANO copies its rendering. Never pass a non-brand image as Image 1. Format refs go in TEXT only.

---

## STAGE 3: PLAN CONTENT

Before generating, plan the batch:

1. **Category mix** — use ALL 10 categories, not just 2. ACCA funnel ratios (15-20% TOFU / 45-50% MOFU / 25-30% BOFU / 5-10% Advocacy)
2. **Color distribution** — max 2 consecutive posts with same dominant color
3. **Format variety** — every post has a UNIQUE concept. No two posts share the same format-concept pair
4. **Festival fit** — core festivals = deep campaign, cross-cultural = 1 greeting, no connection = skip
5. **Grid rhythm** — BOLD → PHOTO → CLEAN row pattern
6. **Quote sourcing** — ALL quotes COPIED from proven viral posts. NEVER imagined. Zero reuse across batches
7. **Persona rotation** — rotate across 5-6 brand personas, never lazy 2-persona plans

---

## STAGE 4: ASSEMBLE PROMPT (7-Layer Architecture)

Every NANO prompt follows this structure:

```
Layer 1: SAFETY
  - ANTI_RENDER: "Do NOT render hex codes, font names, pixel values as visible text"
  - NO_BRAND_LEAK: "Do NOT write ANY brand name, logo, watermark ANYWHERE"
  - MARGIN: "Keep ALL text at least 10% from all edges"

Layer 2: REFERENCE
  - "Edit this image" (edit-first default)
  - "Keep the [product/food] photo EXACTLY as shown" (if sacred photo present)

Layer 3: BRAND DNA (from brand config)
  - Palette keywords, visual DNA description, atmosphere
  - Camera craft direction

Layer 4: CAMPAIGN/CATEGORY
  - Persona, funnel stage, emotional hook
  - Entity hypothesis

Layer 5: COPY
  - The actual headline/quote (COPIED from viral source)
  - Copy placement instructions

Layer 6: TYPOGRAPHY
  - Font DNA description for NANO
  - Size guidance (50-60%+ canvas for type-driven posts)

Layer 7: OUTPUT
  - Aspect ratio: "4:5" (always set in API call)
  - Safe zones for Meta (if ads)
  - Vegan/dietary gate at END of prompt (NANO reads end more strongly)
```

**NANO PROMPTING RULES (never violate):**
- Describe FINAL STATE, never diff language ("change X to Y")
- Keep short — NANO garbles after 2-3 lines of dense text
- Never put English text that could leak — use description language
- Never use hex codes, pixel values, font names — NANO renders them literally
- Never use the word "logo" — NANO renders it literally
- Set `"aspect_ratio": "4:5"` in every API call
- Single pass only — multi-pass compounds errors
- Chinese copy in single quotes to prevent English phrase leakage

**POISON WORDS (never use in food prompts):**
sparkle dust, glitter, candlelit, bokeh, dreamy, atmospheric, rose gold

---

## STAGE 5: GENERATE (NANO Single-Pass)

**Model:** NANO Banana Pro Edit (`fal-ai/nano-banana-pro/edit`)
**Resolution:** 2K
**Aspect ratio:** Always set explicitly ("4:5" for feed, "9:16" only via blur-extend)

**Pipeline by post type:**

| Type | Image 1 | Prompt | Image 2+ |
|------|---------|--------|----------|
| Illustration | Korean webtoon style ref | Character + scene + quote | — |
| Labeled food | Enhanced food photo itself | "Add labels on clean bg" | — |
| Comparison | Stock food photo | Split layout + labels | Enhanced brand food |
| Typography | Pinterest aesthetic ref | Quote text + placement | — |
| Meme/edit | Scraped viral ref | Text swap + brand color | — |
| Cat/lifestyle | Pinterest cat/lifestyle ref | Quote overlay | — |

**Food posts:** Image 1 = enhanced food photo. NO aesthetic ref. Prompt = "warm blush pink background. Clean editorial feel." No atmospheric modifiers.

**Illustration posts:** Must trace to a SPECIFIC viral post with proven engagement. Generic concepts rejected.

**9:16 extension:** Generate at 4:5 FIRST → blur-extend to 9:16. NEVER generate directly at 9:16.

---

## STAGE 6: POST-PROCESS

**PIL does ONLY:**
1. `resize()` — force to target dimensions (1080×1350 for 4:5)
2. `smart_logo()` — composite real logo PNG in cleanest zone
3. `save()` — output as PNG

**PIL NEVER does:** color grading, grain, warmth, contrast, sharpening, vibrance, filters. ALL creative = AI pass.

**Logo rules:**
- Single logo only — if NANO renders brand text, PIL skips logo
- Auto-crop transparent padding before resize
- Logo NEVER overlaps text — check text position against logo position
- When text at bottom → logo = top-right. Text at top → logo = bottom
- Black logo on light bg, white logo on dark bg
- Max 110px wide, 90% opacity

---

## STAGE 7: AUDIT (12-Layer Mastery Gate)

Run ALL 12 layers on EVERY image. Score 0/1 per layer. Must be 11/12+ to pass. (!) = instant reject.

| # | Layer | What to Check |
|---|-------|--------------|
| 1 | **Text Integrity (!)** | No garbled chars, no residual ref text, no typos, text not cropped at edges |
| 2 | **Image-Copy Match (!)** | Visual matches copy meaning ("caffeine" → coffee not pills) |
| 3 | **Food Quality (!)** | Editorial enhanced, appetizing, natural (not over-saturated), no bling ON food |
| 4 | **Photo Authenticity (!)** | ALL food = real photography, never AI-generated. PIL composite for food placement |
| 5 | **Color+Texture (!)** | Multi-layer tonal depth (not flat), brand palette, texture mandatory, feed color variety |
| 6 | **Viral Hook** | Would someone DM this? Trending concept? Specific hook? Purpose (humor/edu/emotion)? |
| 7 | **Format Fidelity** | Correct format executed (labeled = real photo + labels, illustration = Korean semi-realistic) |
| 8 | **Reference Trace (!)** | Every illustration traced to specific viral post. No passthroughs. No double logo. No residual UI |
| 9 | **Reference Uniqueness** | Every post = unique ref. No two posts look similar. Feed diversity |
| 10 | **Brand Consistency (!)** | No non-vegan food, no pricing/CTAs in organic, no copyright chars, no inappropriate content |
| 11 | **Crop & Edge Safety** | All text 10%+ from edges. Post-crop check. No truncated labels |
| 12 | **Value & Shareability** | Gives viewer something (humor/fact/emotion). Pretty + generic = REJECT |

**If ANY (!) layer fails → instant reject regardless of total score.**

---

## STAGE 8: USER GATE

Present batch to user with:
- Each post image
- Score breakdown (12 layers)
- Source ref (which viral post it's from)
- Any flags (copyright risk, residual text, borderline)

**Human approval REQUIRED before publishing.** Never batch-publish without review.

---

## STAGE 9: COMPOUND LEARN

After EVERY user interaction:
1. Save ALL yes/no decisions
2. Update universal rules if brand-agnostic learning
3. Update brand-specific rules if brand-only learning
4. Update this file if new rule discovered
5. Archive stale rules that are superseded

**The system gets SMARTER every round. No mistake repeated twice.**

---

## BRAND CONFIG TEMPLATE

To add a new brand, create `brand-config-{name}.yaml`:

```yaml
name: "Brand Name"
working_dir: "/path/to/brand/"
palette:
  primary: "#hex"
  accent: "#hex"
  background: "#hex"
  text: "#hex"
voice: "one-line tone description"
visual_dna: "one-line aesthetic summary"
languages:
  primary: "EN"
  secondary: "CN"
  split: "65/35"
illustration_style: "description or ref to locked style file"
personas: [list of 5-6 personas with pain/hook/mindstate]
categories: [10 categories mapped to ACCA funnel]
post_process:
  desat: 0.08
  contrast: 1.06
  paper_texture: 0.018
  grain: 3.0
  logo_max_px: 110
  logo_opacity: 0.9
compliance_gates: ["vegan", "no-pricing-in-organic"]
font_dna: "typography description for NANO"
camera_craft: "photography direction for NANO"
atmosphere_keywords: "sparkle glamour, candlelit warmth"
atmosphere_poison_words: ["green", "sage", "nature"]
logo_assets:
  black: "path/to/logo-black.png"
  white: "path/to/logo-white.png"
output_specs:
  feed: "1080x1350"
  stories: "1080x1920"
grid_rhythm: ["BOLD", "PHOTO", "CLEAN"]
```

---

## FILE REFERENCES

This system replaces and consolidates:
- `creative-intelligence-social-media-production.md` (now merged here)
- `creative-intelligence-viral-format-adaptation.md` (Stage 2 classification)
- `feedback_social_production_universal_learnings.md` (all rules merged into Stages 4-7)
- `feedback_visual_audit_6layer.md` (Stage 7 audit)
- `feedback_reference_classification_system.md` (Stage 2)
- `feedback_copy_not_imagine_quotes.md` (Stage 3 rule)
- `feedback_nano_prompt_poison_words.md` (Stage 4 poison words)
- `feedback_nano_anti_patterns.md` (Stage 4 rules)

Brand-specific files still needed per brand:
- `feedback_mirra_brand_specific_learnings.md` (Mirra DNA layer)
- `feedback_pinxin_*` files (Pinxin DNA layer)
- `feedback_bb_*` files (Bloom & Bare DNA layer)
- `project_dotdot_brand.md` (DotDot DNA layer)
