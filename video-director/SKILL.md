---
name: video-director
version: "0.1.0"
description: >
  AI Video Director — storyboard writer, model selector, shot orchestrator, and narrative assembler.
  Turns a concept into a coherent multi-shot video with intelligent model routing.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Always load compound learnings before storyboard generation
      - Budget estimate BEFORE generation — never surprise-spend
      - Model selection based on learnings (Kling for food, Sora for UGC)
      - Review every shot against storyboard before assembly
    agents:
      - iris
      - dreami
      - taoz
---

# Video Director — AI Storyboard Writer + Shot Orchestrator

## Purpose

Replaces manual shot-by-shot prompting with intelligent video direction.
Takes a high-level concept and produces a coherent multi-shot video with:
- **Narrative structure** (hook → build → climax → CTA)
- **Model routing** (Kling for food/texture, Sora for UGC/people)
- **Tempo/pacing** (shot durations matched to narrative beats)
- **Transition design** (crossfade, cut, zoom timing)
- **Budget planning** (cost estimate before any generation)
- **Music cues** (mood, BPM, drop points)

## When to Use

- Making ANY video longer than 5 seconds
- Creating ad content (Reels, TikTok, YouTube Shorts)
- Assembling multi-shot product videos
- Converting a brief/concept into executable video plan

## Commands

```bash
# Generate storyboard from concept
video-director.sh storyboard \
  --brand mirra \
  --concept "Japanese Curry Katsu Rice bento — appetizing product showcase" \
  --duration 30 \
  --platform reels \
  --style cinematic

# Execute storyboard — generate all shots + assemble
video-director.sh direct --storyboard storyboard.json --brand mirra

# Deep-analyze a reference video (beyond video-eye)
video-director.sh reverse-prompt --video reference.mp4

# Review generated video against storyboard
video-director.sh review --video output.mp4 --storyboard storyboard.json

# Feed review into compound learnings
video-director.sh learn --review review.json --brand mirra

# Full pipeline: storyboard → generate → assemble → review
video-director.sh produce \
  --brand mirra \
  --concept "Japanese Curry Katsu Rice" \
  --duration 30 \
  --platform reels
```

## Storyboard JSON Format

```json
{
  "brand": "mirra",
  "concept": "Japanese Curry Katsu Rice bento showcase",
  "platform": "reels",
  "duration_target_s": 30,
  "narrative": "hook-build-climax-cta",
  "music": {
    "mood": "upbeat-warm",
    "bpm_range": [100, 120],
    "drop_at_s": 8
  },
  "shots": [
    {
      "id": 1,
      "name": "hook_reveal",
      "duration_s": 4,
      "model": "kling",
      "model_tier": "standard",
      "narrative_beat": "hook",
      "description": "Bento box lid lifts to reveal colorful curry katsu rice",
      "prompt": "...",
      "camera": "top-down, slight tilt to 45deg",
      "lighting": "warm natural, soft shadows",
      "motion": "lid lifts slowly, food revealed",
      "transition_out": "crossfade 0.5s",
      "ref_image": "/path/to/composite.jpg",
      "cost_estimate": 0.28,
      "learnings_applied": ["no steam for bento", "kling for food close-ups"]
    }
  ],
  "total_cost_estimate": 2.10,
  "assembly": {
    "resolution": "1080x1920",
    "fps": 30,
    "format": "mp4",
    "transitions": "crossfade",
    "music_track": null
  }
}
```

## Narrative Templates

| Template | Structure | Best For |
|----------|-----------|----------|
| `hook-build-climax-cta` | Attention → Interest → Desire → Action | Product ads, Reels |
| `problem-solution` | Pain → Discovery → Transformation → CTA | UGC testimonials |
| `reveal` | Mystery → Tease → Full reveal → Details | Product launches |
| `day-in-life` | Morning → Activity → Product use → Result | Lifestyle content |
| `before-after` | Before state → Transformation → After state | Results-focused |

## Model Selection Logic

| Shot Type | Primary Model | Reason |
|-----------|--------------|--------|
| Food close-up | Kling v3 | Better texture consistency |
| Food with steam/liquid | Kling v3 | Better food physics |
| Person + product (UGC) | Sora 2 | Natural human movement |
| Lifestyle/wide shot | Sora 2 | Better scene composition |
| Product detail/macro | Kling v3 | Texture fidelity |
| Talking head | Sora 2 | Natural expression |
| CTA/text overlay | Kling v3 | Stability for text |

## Dependencies

- `video-gen.sh` — actual video generation (Kling/Sora/Wan)
- `video-forge.sh` — assembly, transitions, music, export
- `video-eye.sh` — reference video analysis
- `resolve-learnings.py` — compound learnings for brand rules
- Gemini API — storyboard intelligence (free tier)

## CHANGELOG

### v0.1.0 (2026-03-06)
- Initial release: storyboard, direct, reverse-prompt, review, learn, produce
- Narrative templates: 5 built-in structures
- Model routing: Kling/Sora selection based on compound learnings
- Budget calculator: pre-generation cost estimate
- Compound learnings integration
