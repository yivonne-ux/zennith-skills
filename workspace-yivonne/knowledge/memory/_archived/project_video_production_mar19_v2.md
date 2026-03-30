---
name: Lost5kg vlog production session — full state March 19 2026 (v2)
description: Complete session state for Lost5kg diet vlog. 14 scenes, v5 delivered, all learnings, all tools built, next steps. Read to resume.
type: project
---

## Project State
- Video: "i lost 5kg eating these everyday" — 39s diet vlog
- Character: 28yo Malaysian Chinese, Taiwanese aesthetic, light brown hair
- v5 delivered at `.tmp/mirra_cook/finals/lost5kg_final_v5.mp4`
- Total Kling API spend: ~$20+ across multiple regeneration rounds

## What's Been Built (new tools this session)
1. `tools/batch_i2v_lost5kg.py` — Batch Kling 3.0 PRO i2v with per-scene prompts
2. `tools/post_process_lost5kg.py` — FFmpeg normalize + trim + grade + speed (single pass)
3. `tools/audio_design_lost5kg.py` — BGM + SFX + timing map
4. `tools/typography_lost5kg.py` — FFmpeg drawtext fallback (DO NOT USE with Remotion)
5. `tools/assemble_lost5kg.py` — Grain + ending card + concat
6. `tools/pre_render_qc.py` — **8-point automated QC gate** (stale clips, double text, setting consistency, brand logo, typography, script, camera prompts, food source)
7. `tools/vlog_mastery_study.py` — Download + analyze viral vlogs for mastery building
8. `remotion/src/Lost5kgComposition.tsx` — Full Remotion composition with motion graphics
9. `.tmp/vlog_mastery/prompt_library/lost5kg_prompts.json` — Every prompt with scores and learnings
10. BGM generated via fal.ai Stable Audio (lo-fi chill, 117 BPM)

## Pipeline (correct order)
```
1. batch_i2v_lost5kg.py      → raw clips (Kling PRO)
2. post_process_lost5kg.py   → processed clips (normalize, trim, grade, speed)
3. Copy processed → remotion/public/clips/  (NOT titled, NOT grained)
4. Remotion render            → video with typography
5. Merge with BGM             → final
```
**CRITICAL: Remotion renders on PROCESSED clips. No FFmpeg drawtext. No grain before Remotion.**

## Known Issues in v5
- 06_bento1 is round bowl, others are square box (user approved but inconsistent)
- yt-dlp YouTube downloads blocked (403) — mastery study tool needs working download method
- BGM is AI-generated placeholder — user hasn't commented on music quality yet

## Next Session Priorities
1. User review of v5 — may need more clip fixes
2. Find real BGM track (or user provides one)
3. Fix yt-dlp download issue for vlog mastery study (try TikTok/IG instead, or user provides URLs)
4. Run vlog mastery study on 10+ viral short-form vlogs
5. Build scene mastery cards from analysis
6. Apply learnings to improve Lost5kg or start next video concept

## Cost Tracking
- Kling 3.0 PRO i2v: ~42 generations × $0.33 = ~$13.86
- NANO image generation: ~20 generations × $0.15 = ~$3.00
- Stable Audio BGM: ~$0.10
- Gemini Vision QC: ~$0.50
- **Total this session: ~$17.50**
