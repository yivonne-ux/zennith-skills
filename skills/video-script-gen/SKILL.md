---
name: video-script-gen
agents:
  - dreami
  - taoz
---

# Video Script Generator — Zennith OS Skill

## What This Is

LLM-powered video script generator with 3 strategies, 13 flow types (A-M), and 7 Visual Craft Rules. Ported from Tricia's 222KB script engine. Generates structured AIDA-tagged scripts ready for video-compiler and remotion-renderer.

## 3 Strategies

| Strategy | When | How |
|----------|------|-----|
| **script_first** | Flows A-E, G, K | Full narrative → segment into blocks |
| **two_layer** | Flow F (compiled montage) | Text overlay + visual shot list separately |
| **block_first** | Flow H, L | Structure IS content, fill per block |

## 7 Visual Craft Rules

1. **Tension hooks**: First block MUST contain a specific number or provocative question. No brand mention in first 2 blocks.
2. **Emotional arc**: Each block gets a distinct emotion: curiosity → frustration → surprise → relief → confidence → urgency. Never repeat adjacent.
3. **Emphasis budget**: Exactly 5-7 key *phrases* across entire script (3-6 CN chars / 2-4 EN words each). Prioritize: number+unit > result > brand name.
4. **Text-image counterpoint**: Caption = emotion/insight, visual = proof/evidence. Never caption what the clip shows.
5. **No silent gaps**: VO narrates all blocks. Every block has spoken_dialogue + text_overlay.
6. **Variety pacing**: Mix durations — most 1.8-2.5s, 2 slow (3-4s), 1 rapid sequence (3× 1.2-1.5s).
7. **Callback structure**: CTA echoes hook's theme for thematic closure.

## Flow → Voice Rules

| Flow | Voice | Structure |
|------|-------|-----------|
| A (testimonial) | 1st person | Personal story/diary |
| B (PAS) | 2nd person | Argue: pain → worse → solution → proof |
| C (challenge) | 1st person | Day-by-day editorial, independent claims |
| D (slap) | 2nd person | Shock then rapid claims |
| E (convenience) | 1st person | Sparse (4-5 lines), visuals carry |
| F (compiled) | Mixed | Multi-KOL voices overlaid |
| G (brand story) | 3rd person | Warm editorial narration |
| H (what I eat) | 1st person | Day-by-day food showcase |
| I (sales hype) | 2nd person | Promotional claim stacking |
| J (curiosity) | 2nd person | Mystery → reveal |
| K (before/after) | 1st person | Transformation result first |
| L (brand montage) | None | Kinetic text only, no VO |
| M (vo montage) | 3rd person | Full VO over muted clips |

## Usage

```bash
# Generate script variants
video-script-gen.sh generate \
  --brand mirra \
  --product "Bento Bowl" \
  --goal conversion \
  --flow testimonial \
  --variants 3 \
  --duration 40

# Generate with specific tone and audience
video-script-gen.sh generate \
  --brand jade-oracle \
  --product "Oracle Reading" \
  --goal awareness \
  --flow curiosity_reveal \
  --tone "mystical, empowering" \
  --audience "women 25-40 spiritual seekers"

# List available flows
video-script-gen.sh flows

# Validate a script against craft rules
video-script-gen.sh validate --script script.json
```

## Output Format

```json
{
  "variant_id": "mirra_testimonial_v1",
  "flow": "A",
  "flow_name": "testimonial",
  "total_duration_s": 40,
  "spoken_dialogue": "过年之后是不是觉得...",
  "hook_headline": "新年后遗症",
  "blocks": [
    {
      "id": "01_A5_hook",
      "block_code": "A5",
      "aida_phase": "attention",
      "duration_s": 3.0,
      "spoken_dialogue": "过年后你是不是也胖了？",
      "text_overlay": {
        "text": "过年后你是不是也胖了？",
        "style": "bold",
        "emphasis": [{"text": "胖了", "color": "#E68A7E"}]
      },
      "visual_description": "Woman looking at scale, frustrated expression",
      "emotion": "frustration"
    }
  ],
  "craft_check": {
    "tension_hook": true,
    "emotional_arc_valid": true,
    "emphasis_count": 6,
    "text_image_counterpoint": true,
    "no_silent_gaps": true,
    "variety_pacing": true,
    "callback_structure": true
  }
}
```

## Files

```
skills/video-script-gen/
├── SKILL.md
├── scripts/
│   └── video-script-gen.sh     # CLI wrapper
└── config/
    └── flow-prompts.json       # Per-flow LLM prompt templates
```
