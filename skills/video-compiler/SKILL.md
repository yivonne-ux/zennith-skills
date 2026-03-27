---
name: video-compiler
agents:
  - dreami
  - taoz
---

# Video Compiler — GAIA OS Skill

## What This Is

Automated UGC video ad production pipeline. Takes a brief (brand + product + goal + tone) and outputs ready-to-publish video ads for TikTok/Reels/Shorts.

Blends Tricia's WAT architecture (AIDA block taxonomy, ad frameworks, combinatorial generation) with GAIA's existing tools (video-gen.sh, nanobanana-gen.sh, video-forge.sh, seed-store.sh).

## Three Production Modes

| Mode | Output | When to Use |
|------|--------|-------------|
| **assembled** | Multi-block video (30-50s) | Full UGC ads with AIDA structure |
| **single-shot** | Single 12s video | Quick testimonials, simple ads |
| **combinatorial** | M hooks × K bodies = N variants | Bulk A/B testing campaigns |

## Pipeline (6 Stages)

```
BRIEF → SCRIPT → RESOLVE → GENERATE → PRODUCE → DELIVER
  ↓        ↓         ↓          ↓           ↓         ↓
 Parse   Dreami    Match      Parallel   VideoForge  Seed-store
 brand   writes    blocks     video-gen  post-prod   + export
 DNA     script    to assets  (5x conc)  caption/    multi-platform
         with      or mark    Sora/Kling brand/fx
         framework for gen
```

## Usage

```bash
# Full pipeline (assembled mode)
video-compiler.sh run --brand mirra --product "Bento Box" \
  --goal conversion --tone authentic --variants 3

# Plan only (review before spending API credits)
video-compiler.sh run --brand mirra --product "Bento Box" \
  --goal conversion --plan-only

# Resume from plan
video-compiler.sh run --resume /path/to/plan.json

# Single-shot mode (12s quick ads)
video-compiler.sh run --brand mirra --mode single-shot --variants 5

# Combinatorial mode (hooks × bodies)
video-compiler.sh run --brand mirra --mode combinatorial \
  --hooks 3 --bodies 2

# Just generate scripts (Dreami)
video-compiler.sh script --brand mirra --product "Bento Box" \
  --framework pas --variants 3

# Video QA review
video-compiler.sh review --input video.mp4

# Parallel batch generation
video-compiler.sh generate --plan plan.json --concurrency 5
```

## AIDA Block System

Every video is structured using AIDA blocks:

| Phase | Codes | Purpose |
|-------|-------|---------|
| **Attention** | A1-A6 | Stop scrolling (hooks, pain, reactions) |
| **Interest** | I1-I5 | Build trust (BTS, process, materials, reviews) |
| **Desire** | D1-D6 | Create want (usage, unbox, lifestyle, comparison) |
| **Action** | Act1-Act6 | Close (packaging, promo, CTA end card) |

Block sources: **A** (existing footage), **B** (AI-generated), **C** (AI variation of existing)

## Ad Frameworks

| Framework | Best For | Structure |
|-----------|----------|-----------|
| **UGC Testimonial** | Authentic feel | hook → discovery → experience → result → CTA |
| **PAS** | Problem-focused | problem → agitate → solution intro → proof → CTA |
| **SLAP** | Fast/viral | stop → look → act → purchase |
| **Emotional Storytelling** | Premium/lifestyle | setup → conflict → discovery → transformation → new life → CTA |

## Sequence Templates (7 Recipes)

- `standard_ugc_40s` — 6 blocks, full AIDA arc
- `quick_ugc_12s` — 1 block, single-shot testimonial
- `awareness_30s` — 4 blocks, pain→proof→CTA
- `conversion_45s` — 8 blocks, full funnel with reactions
- `transformation_30s` — 4 blocks, before/after
- `lifestyle_30s` — 4 blocks, aspirational aesthetic
- `comparison_40s` — 5 blocks, vs competitor

## Agent Roles

| Agent | Role in Pipeline |
|-------|-----------------|
| **Dreami** | Script generation using ad frameworks |
| **Iris** | Visual QA, thumbnail selection, creative direction |
| **Argus** | Auto-QA via video-review (motion-diff, contact sheets) |
| **Zenni** | Routes brief, coordinates agents |
| **Taoz** | Builds/fixes the pipeline itself |

## GAIA Tools Used

| Stage | Tool | What It Does |
|-------|------|-------------|
| Script | LLM (Gemini Flash) | Generates structured scripts per framework |
| Generate | `video-gen.sh` | Sora 2 / Kling 3.0 / Wan video generation |
| Generate | `nanobanana-gen.sh` | Product images (Gemini Image API) |
| Generate | `parallel-gen.py` | Parallel batch generation (5x concurrency) |
| Produce | `video-forge.sh` | Caption, brand, effects, export |
| Review | `video-review.sh` | Contact sheets, motion-diff, scene detection |
| Register | `seed-store.sh` | Content atom tracking with AIDA tags |
| Deliver | Multi-platform export | TikTok, Reels, Shorts, Feed, YouTube |

## Files

```
skills/video-compiler/
├── SKILL.md                              # This file
├── schemas/
│   ├── block_schema.json                 # AIDA block taxonomy (21 codes)
│   ├── sequence_templates.json           # 7 video recipes
│   └── framework_templates.json          # 4 ad copywriting frameworks
├── scripts/
│   ├── video-compiler.sh                 # Main CLI orchestrator
│   ├── parallel-gen.py                   # Parallel video generation engine
│   ├── video-review.sh                   # Video QA tool
│   └── script-gen.py                     # LLM script generation with frameworks
└── brands/
    └── README.md                         # Per-brand video-blocks.json docs
```

## Cost per Video

| Component | Cost |
|-----------|------|
| Script generation (Gemini Flash) | ~$0.01 |
| Video generation (Sora 2, 12s) | ~$0.40 |
| Video generation (Kling 3.0, 5s) | ~$0.28 |
| Image generation (NanoBanana) | $0 (Gemini free tier) |
| Post-prod (FFmpeg local) | $0 |
| **Typical 40s assembled ad (6 blocks)** | **~$1.50-2.50** |
| **12s single-shot** | **~$0.40-0.80** |

vs. Agency: $500-2000/ad. vs. Fomofly: $15-30/month + manual work.
