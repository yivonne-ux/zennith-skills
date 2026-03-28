---
name: video-block-library
agents:
  - dreami
  - taoz
---

# Video Block Library — Zennith OS Skill

## What This Is

AIDA-structured video asset library for managing, searching, matching, and lifecycle-tracking video blocks. Ported from Tricia's 995-clip production system with bilingual scoring, freshness lifecycle, and 4-layer diversity enforcement.

Every video ad is structured as AIDA blocks: Attention → Interest → Desire → Action. This skill manages the blocks.

## AIDA Block Taxonomy

| Phase | Codes | Purpose |
|-------|-------|---------|
| **Attention** | A1-A6 | Stop scrolling — hooks, reactions, pain scenarios |
| **Interest** | I1-I6 | Build trust — BTS, process, materials, reviews |
| **Desire** | D1-D3 | Create want — eating, unboxing, receive scenes |
| **Action** | Act1-Act6 | Close — packaging, promo, CTA end card |

## Block Lifecycle

```
FRESH → MONITOR → FATIGUED → RETIRED
  ↑                              ↓
  └──── REFRESH (re-register) ───┘
```

- **FRESH**: Default, fully eligible for selection
- **FATIGUED**: Deprioritized (0.5× score multiplier), still eligible
- **RETIRED**: Excluded from matching entirely
- Times used → exponential decay: score × 0.5^times_used

## Usage

```bash
# Register a new video block
block-library.sh register --file clip.mp4 --brand mirra --code A3 --category Reaction

# Search for blocks
block-library.sh search --phase attention --code A3 --tags "surprise,reaction" --brand mirra

# Search for complete AIDA sequence
block-library.sh sequence --brand mirra

# Fatigue overused blocks
block-library.sh expire --code A3 --status fatigued --brand mirra

# Enrich block with Gemini Vision analysis
block-library.sh enrich --file clip.mp4 --brand mirra

# List all blocks for a brand
block-library.sh list --brand mirra [--phase attention] [--status fresh]

# Library health check
block-library.sh health --brand mirra
```

## Scoring Algorithm

```
score = quality_bonus (0-0.25) + engagement_bonus (0-0.15) +
        tag_overlap (0-0.4) + narrative_context (0-0.3) +
        content_type_match (0-0.2) + camera_angle (0-0.1) +
        motion_energy (0-0.15) + expression_match (0-0.15)

penalties:
  - Language mismatch: -0.3
  - Fatigued: ×0.5
  - Usage frequency: ×0.5^times_used
  - Recency (same-day): ×0.1

MIN_MATCH_QUALITY = 0.35
```

## Files

```
skills/video-block-library/
├── SKILL.md
├── scripts/
│   └── block-library.sh        # CLI interface
├── schemas/
│   ├── block-schema.json        # Universal AIDA taxonomy
│   ├── mirra-block-schema.json  # Mirra brand extensions
│   └── pinxin-block-schema.json # Pinxin brand extensions
└── config/
    └── sequence-templates.json  # 6 video assembly recipes
```
