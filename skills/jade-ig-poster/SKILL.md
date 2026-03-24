---
name: jade-ig-poster
description: Complete Instagram posting pipeline for Jade Oracle. Generates oracle-focused captions, picks matching images from tagged library, scores quality, fixes weak spots, reviews visually, and posts. One command does everything.
agents: [taoz, zenni, dreami]
version: 1.0.0
---

# Jade IG Poster — Full Automated Posting Pipeline

One command to generate, score, review, and post Instagram content for @the_jade_oracle.

## Trigger Conditions
- Zenni receives "post to jade instagram", "jade ig post", "jade content"
- Cron fires daily at scheduled times
- Manual: `bash jade-ig-poster.sh run`

## Agent Ownership
- **Zenni (main)**: Dispatches the skill, monitors results
- **Taoz**: Runs the pipeline (Claude Code CLI)
- **Dreami**: Generates captions when dispatched separately

## Usage

### Full Pipeline (generate + score + review + post)
```bash
bash jade-ig-poster.sh run                    # Generate + post 5 posts
bash jade-ig-poster.sh run --count 3          # Generate + post 3 posts
bash jade-ig-poster.sh run --dry-run          # Preview without posting
bash jade-ig-poster.sh run --theme self_love  # Single theme
```

### Individual Steps
```bash
bash jade-ig-poster.sh generate --count 5     # Generate captions only
bash jade-ig-poster.sh pick                   # Match images to captions
bash jade-ig-poster.sh score                  # Auto-research quality scoring
bash jade-ig-poster.sh fix                    # Fix weak spots (low CTA, bad hooks)
bash jade-ig-poster.sh review                 # Visual review (image-caption match)
bash jade-ig-poster.sh post                   # Post reviewed content to IG
bash jade-ig-poster.sh status                 # Show today's posting status
```

### Zenni Dispatch
```bash
bash dispatch.sh taoz "Run jade-ig-poster.sh run --count 5" "jade-ig-post"
```

## Pipeline Flow
```
GENERATE → PICK → SCORE → FIX → REVIEW → POST
    ↓         ↓       ↓       ↓        ↓       ↓
  Claude    Image   8-point  Auto-   Registry  Meta
  CLI      Scanner  scoring  fix     tag check  Graph
           Registry          hooks   warmth/    API
                             +CTAs   brand_fit
```

## Content Rules (ENFORCED)
- NO QMDJ, 奇门遁甲, BaZi, or Chinese metaphysics terms
- Jade is an oracle reader focused on: self-love, kindness, life transitions, intuition
- Max 5-7 hashtags per post
- Max 1800 characters per caption
- Image must match caption mood (verified by registry tags)
- Image warmth >= 7, brand_fit >= 7
- Score >= 60/80 to post (auto-fix if below)

## Files
- **Scripts**: `~/.openclaw/skills/jade-ig-poster/scripts/`
- **Image Registry**: `~/.openclaw/workspace/data/images/jade-oracle/ig-library/image-registry.json`
- **Content Output**: `~/.openclaw/workspace/data/content/jade-oracle/daily/YYYY-MM-DD/`
- **Posting Log**: `~/.openclaw/workspace/data/social-publish/posting-history.jsonl`
- **Meta Token**: `~/.openclaw/secrets/meta-marketing.env`
