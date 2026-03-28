---
name: creative-qa
agents:
  - dreami
  - taoz
---

# Creative QA Pipeline — Zennith OS Skill

## What This Is

3-stage creative quality gate for video production. Ported from Tricia's 100-point scoring system. Complements the code-focused rigour gate with creative-focused checks.

## 3 Stages

| Stage | When | What |
|-------|------|------|
| **Script Audit** | After script generation | 7 Craft Rules, emotional arc, emphasis budget, brand voice |
| **Audio Audit** | After voiceover generation | Pacing, pronunciation, silence gaps, LUFS levels |
| **Video Audit** | After final assembly | Face consistency, artifacts, caption readability, brand compliance |

## Scoring (100 points)

### Script Audit (40 points)
- Tension hook (5pts): First block has number/question, no brand mention
- Emotional arc (5pts): Distinct emotions, no adjacent repeats
- Emphasis budget (5pts): 5-7 key phrases, meaningful (not single words)
- Text-image counterpoint (5pts): Caption ≠ visual description
- No silent gaps (5pts): All blocks have dialogue (except CTA)
- Variety pacing (5pts): Mix of durations (1.2-4.0s range)
- Callback structure (5pts): CTA echoes hook theme
- Brand voice check (5pts): Passes brand-voice-check.sh

### Audio Audit (30 points)
- Pacing match (10pts): VO duration matches block durations (±0.5s)
- LUFS level (5pts): -14 LUFS (broadcast standard)
- Silence check (5pts): No gaps > 1.0s within dialogue
- Pronunciation (5pts): Key product/brand names pronounced correctly
- BGM balance (5pts): BGM ducks on speech, not competing

### Video Audit (30 points)
- Face consistency (10pts): Same face across all character blocks
- Artifact check (5pts): No drift, morphing, extra limbs
- Caption readability (5pts): Text visible, not cut off, correct positioning
- Brand compliance (5pts): Watermark present, correct colors, logo visible
- Platform compliance (5pts): Safe zones respected for TikTok/Reels

## Usage

```bash
# Full 3-stage audit
creative-qa.sh audit --script script.json --video output.mp4 --brand mirra

# Script-only audit (before production)
creative-qa.sh script --script script.json --brand mirra

# Video-only audit (after assembly)
creative-qa.sh video --video output.mp4 --brand mirra

# Quick pass/fail check
creative-qa.sh check --video output.mp4 --brand mirra --min-score 70
```

## Pass/Fail Thresholds

| Score | Result | Action |
|-------|--------|--------|
| 80-100 | PASS | Ship to platform |
| 60-79 | WARN | Review before shipping |
| 0-59 | FAIL | Regenerate or fix |

## Files

```
skills/creative-qa/
├── SKILL.md
└── scripts/
    └── creative-qa.sh
```
