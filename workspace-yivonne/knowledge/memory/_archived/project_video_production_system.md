---
name: Video Production System — Complete State (March 16)
description: Full state of the video production system after day 1 of building. Pipeline location, all research docs, all versions produced, what works, what doesn't, next steps.
type: project
---

## What Was Built Today

### Infrastructure
- Full Video Compiler cloned to `~/Desktop/video-compiler/` (1,060 files)
- Node.js 20 + npm + ffmpeg installed (no sudo, via fnm + static binary)
- Python deps: pydantic, anthropic, google-generativeai, fal_client, elevenlabs, soundfile, imageio
- Remotion installed (node_modules), 99/99 tests pass
- .env configured with all API keys (Anthropic, Gemini, FAL, ElevenLabs, Meta)

### Creative Intelligence Layer
- `tools/generate_concepts.py` — 5-step Creative Reasoning Engine
- `config/format_library.json` — 42 format definitions
- All docs sent to colleague's Google Drive transfer package
- `COLLEAGUE_INTEGRATION_INSTRUCTIONS.md` — step-by-step for video team

### Research (9 documents, 5000+ lines)
- VIDEO-MASTERY-PRODUCTION-SPECS.md — master quick-reference
- AI-VIDEO-MODEL-GUIDE.md — Kling/Sora/Veo/MiniMax routing
- typography-vfx-production-specs.md — fonts/text/effects
- LUXURY-VIDEO-AESTHETICS-RESEARCH.md — fashion/film/luxury
- VIRAL-VIDEO-EDITING-INTELLIGENCE.md — creator styles/transitions
- VIRAL-VIDEO-SCIENCE-RESEARCH.md — neuroscience of engagement
- ANIMATION-PRODUCTION-INTELLIGENCE.md — stop-motion/animation
- craft_mastery_guide.md — 7 invisible editing rules (existing)
- editing_mastery_research.md — retention editing gap (existing)

### Videos Produced
- V1: Library-only compilation (rejected — lazy, no narrative)
- V2: Kling face + Sora food (rejected — wrong structure, broken text)
- V3: Sora lifestyle + food (rejected — still wrong structure)
- V4: Sora ultra-detailed character (partial — 4 keepers, face consistency issues)
- V4b: Kling face-locked 8 shots (rejected — all same outfit, not iPhone feel)
- V5: Sora character sheet enforced (partial — 4 good, 4 need regen)
- V6: Forensic 1:1 reference copy (best version — 14 scenes, 18s)
- V7: V6 + more food intercuts (16 scenes, 20s, more food variety)
- **Sora Masterpiece**: Impossible cinematography (5 Sora shots — morning journey, macro food, floating ingredients, pullthrough skyline)
- **Calculator (Path A)**: Format hijack concept (15s, Remotion-ready)
- Total API spend: ~$45

### Key Learnings Saved to Memory
1. `feedback_video_steal_like_artist.md` — 1:1 forensic copy method
2. `feedback_video_production_v1_v6_learnings.md` — complete V1-V6 journey
3. `feedback_video_sora_reverse_creative_process.md` — BREAKTHROUGH: design FOR Sora's strengths

## What Works
- Sora t2v for atmospheric/impossible shots ($0.50/4s)
- Ultra-precise cinematography prompts with lens/aperture/Kelvin specs
- Character sheet approach for ~80% face consistency across Sora shots
- Forensic 1:1 reference adaptation (frame-by-frame structural copy)
- Library food clips (740 real clips, free)
- FFmpeg assembly pipeline (functional but basic)

## What Doesn't Work Yet
- Kling t2v endpoint on fal.ai (404 on poll)
- Kling i2v locks outfit/scene to reference image (can't change outfits)
- Same-girl across all shots (Sora ~80%, Kling 100% but wrong aesthetic)
- Remotion kinetic typography (never implemented, using plain drawtext)
- Audio design (flat BGM only, no ducking/SFX/silence beats)
- Image editing to editorial level (basic PIL grade, not art-directed)

## Next Session Priority
1. Edit food photos to EDITORIAL level → feed to Sora i2v → compare quality
2. Build Remotion kinetic typography components (serif + spring + emphasis)
3. Implement audio design pipeline (ducking + SFX + silence beats)
4. Check Bloom & Bare `bloom_core.py` for image editing pipeline to upgrade
5. Produce a complete end-to-end video with STORY, VALUE, EMOTIONAL TRIGGER — not just pretty clips
6. Three video moods to produce: high-hook creative / girlboss story / food vibes
7. Download stop-motion references from user's Drive folder (needs access)
