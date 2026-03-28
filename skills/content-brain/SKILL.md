---
name: content-brain
agents:
  - dreami
  - taoz
  - scout
---

# Content Brain — Zennith OS Master Orchestrator

## What This Is

The brain that overlooks and curates the entire content supply chain. Not just a workflow — a creative intelligence system that plans, produces, QAs, distributes, and LEARNS from every piece of content across all 14 brands.

Think of it as the Creative Director + Production Manager + Data Analyst in one command.

## 3 Modes

| Mode | What | When |
|------|------|------|
| **produce** | Execute full 12-step pipeline for one video | On-demand |
| **plan** | Generate weekly content plan for a brand | Weekly |
| **brain** | Review performance, suggest next content, manage library | Daily |

## The 12-Step Pipeline (produce mode)

```
content-brain.sh produce --brand mirra --product "Bento Bowl" --flow testimonial

Step 1:  BRIEF          creative-reasoning-engine → concept + hook
Step 2:  PLAN           flow-alphabet → AIDA blocks → sequence template
Step 3:  SCRIPT          video-script-gen → structured AIDA script
Step 4:  SCRIPT QA       creative-qa script + brand-voice-check
Step 5:  CHARACTERS      NanoBanana face-lock + scene planning
Step 6:  REFERENCES      NanoBanana → 5-dimension scored ref set
Step 7:  VOICEOVER       ElevenLabs → VO MP3 + char_timestamps
Step 8:  VIDEO CLIPS     video-gen.sh → per-block clips (model auto-routed)
Step 9:  ASSEMBLY        remotion-render.sh OR video-forge assemble
Step 10: POST-PROD       video-forge effects/brand/export
Step 11: QUALITY GATE    creative-qa audit (≥80 = ship)
Step 12: DISTRIBUTE      social-publish + register blocks + learn
```

## Content Supply Chain (plan + brain modes)

```
INTELLIGENCE LAYER
├── daily-intel digest (competitor monitoring)
├── content-scraper (reference gathering)
├── Meta Ads performance (what's working)
└── block-library health (freshness lifecycle)
         ↓
PLANNING LAYER
├── creative-reasoning-engine (concept birth)
├── flow selection (A-M based on funnel needs)
├── content calendar (what to produce when)
└── diversity gate (no repetition, Andromeda compliance)
         ↓
PRODUCTION LAYER
├── video-compiler (full AIDA video pipeline)
├── remotion-renderer ($0 template renders)
├── nanobanana (image generation)
├── video-gen (AI video: Kling/Sora/Seedance)
└── video-forge (post-production)
         ↓
QUALITY LAYER
├── creative-qa (100-point scoring)
├── brand-voice-check (compliance)
├── vision QA (face consistency, artifacts)
└── platform compliance (safe zones)
         ↓
DISTRIBUTION LAYER
├── social-publish (Instagram)
├── tiktok-posting (TikTok)
├── Meta Ads (campaign upload)
└── content-repurpose (multi-platform)
         ↓
LEARNING LAYER
├── register to block-library
├── track cost per video
├── Meta Ads → performance feedback
├── knowledge-compound → system improves
└── learnings → next production cycle
```

## Usage

```bash
# PRODUCE — Full pipeline, one video
content-brain.sh produce --brand mirra --product "Bento Bowl" \
  --flow testimonial --duration 40 --variants 1

# PRODUCE — Quick kinetic text reel ($0)
content-brain.sh produce --brand jade-oracle --type kinetic \
  --text "Trust the process|Your path is|*unfolding*"

# PRODUCE — Template render ($0)
content-brain.sh produce --brand jade-oracle --type oracle-card \
  --card "The Tower" --meaning "Transformation through upheaval"

# PLAN — Weekly content plan
content-brain.sh plan --brand mirra --week 2026-W14

# BRAIN — Daily review + suggestions
content-brain.sh brain --brand mirra

# BRAIN — Library health check
content-brain.sh brain --brand mirra --check library
```

## Files

```
skills/content-brain/
├── SKILL.md
├── scripts/
│   └── content-brain.sh        # Master orchestrator
└── config/
    └── production-defaults.json # Per-brand production presets
```
