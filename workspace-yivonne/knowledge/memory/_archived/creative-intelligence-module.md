---
name: Creative Intelligence Module — Project Overview
description: Mirra ads creative automation. 8-agent pipeline, NANO edit architecture, v2 edit pipeline, v3 March campaign (30 variants), triple-input wireframe technique for UI layouts.
type: project
---

# Creative Intelligence Module

Working dir: `/Users/yi-vonnehooi/Desktop/Creative Intelligence Module/`

## User's design philosophy (CRITICAL)
- **EDIT-BASED, not generate-from-scratch.** Reference image IS the canvas. AI edits it.
- Work like a top-tier designer: reference → swap food → fix text → adjust color → grain
- PIL-from-scratch templates REJECTED. No heavy filters ("burnt"). Photography IS the aesthetic.
- Food photos must be THE EXACT real photo. Different photography styles per artwork.

## Current pipeline: v3 March Campaign (2026-03-12)
- Full learnings: [march-campaign-v3-learnings.md](march-campaign-v3-learnings.md)
- Script: `test/run_march_campaign_v3.py` (1214 lines)
- Output: `test/campaign-output/march_campaign_v3_20260312_131628/` — 30/30 PNGs
- Architecture: ref + food → NANO Banana Pro Edit (2K) → resize → grain(0.016). **NO PIL logo stamp.**
- NANO renders EVERYTHING including "mirra." branding (BETTER OUTPUTS learning)
- 5 pillars × 6 ACCA variants = 30 ads. 9 editorial_photo + 21 graphic_design.
- BETTER OUTPUTS DNA → v3 system constants: CAMERA_CRAFT, COLOR_MOOD, PROP_STYLING, TYPOGRAPHY_V3, SIMPLICITY_RULE

## God mode edit-first technique (for UI-heavy layouts)
- Script: `test/run_v3_godmode.py`
- Output: `test/campaign-output/v3_godmode_20260312_182649/` — 4/4 PNGs
- Key insight: "Edit this image, swap only X" instead of "create inspired by this"
- NANO is an editor — preserves structure when you frame it as element swaps
- Proven on: Divain split screen, Plately website, iPhone Calendar, REORIA Instagram carousel
- Supersedes wireframe technique (`run_v3_fix4.py`) — simpler, better results

## v2 Edit Pipeline (working — 10/10 succeeded 2026-03-11)
- Script: `test/run_v2_edit_test.py`
- NANO endpoint: `fal-ai/nano-banana-pro/edit` with `image_urls: [url1, url2, ...]` (flat strings, NOT objects)
- `resolution: "2K"` parameter (NOT `image_size` dict)
- 10 template types across 3 successful runs

## AI model decision matrix
- **Food swap**: FLUX 2 Pro Edit ($0.03) — cheaper + more photorealistic than NANO
- **Multi-image compositing (3+ refs)**: NANO Banana Pro Edit ($0.15, 14 refs max)
- **Text editing**: PIL for production. FLUX Kontext for mockups only.
- **Style transfer**: Ideogram V3 Remix (strength 0.3-0.5)
- **Budget multi-ref**: SeedDream v4.5 Edit ($0.04, 10 refs)

## Architecture (8-agent pipeline — being redesigned)
- `agents/` — 8 agents (ORACLE, STRATEGIST, SCOUT, DIRECTOR, CRAFTSMAN, JUDGE, LIBRARIAN, PROFESSOR)
- `workflows/ads-creative-pipeline.md` — 9-step pipeline spec
- `tools/` — 7 core tools | `shared/brand-identity/mirra/` — brand DNA, food-library, fonts, assets
- Research docs in `research/` — 14 files including master guide
- FAL_KEY in mirra-workflow .env

## Asset inventory (test/v2-templates/ — 399 files)
- 10 reference templates, 288 food images, 103 brand assets
- 20 food photography style refs in `brand-assets/food-photography-refs/`

## Earlier learnings: [v2-template-learnings.md](v2-template-learnings.md)
