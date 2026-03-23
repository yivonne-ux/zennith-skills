---
name: jade-reel-factory
description: Self-improving reel production pipeline for Jade Oracle. Scrapes competitor reels, reverse-engineers viral patterns, generates Jade versions with NanoBanana + video models, audits quality with visual QA, and compounds learnings via auto-research loop.
agents: [taoz, dreami]
version: 1.0.0
---

# Jade Reel Factory — AI Reel Production Pipeline

Scrape → Reverse-Engineer → Generate → Audit → Improve → Repeat

## Commands

| Script | Purpose |
|--------|---------|
| reel-scraper.sh | Download competitor reels via yt-dlp |
| reel-reverse-engineer.sh | Extract blueprint from any reel |
| reel-generator.sh | Generate Jade reel from blueprint |
| reel-auditor.sh | Visual QA scoring (10 dimensions) |
| reel-loop.sh | Auto-research improvement loop |
| reel-publish.sh | Post reel to Instagram |

## Quick Start

```bash
# Scrape top 3 reels from each competitor
bash reel-scraper.sh --all --count 3

# Reverse-engineer the best one
bash reel-reverse-engineer.sh --input scrapes/reels/mysticmichaela/REEL_ID.mp4

# Generate Jade version
bash reel-generator.sh --blueprint blueprints/reel-HASH-analysis.json

# Audit quality
bash reel-auditor.sh --input reels/DATE/reel-TIMESTAMP.mp4

# Full improvement loop (5 iterations)
bash reel-loop.sh --iterations 5 --publish
```

## Visual QA Dimensions (10)
1. face_consistency — Does Jade look like Jade?
2. physics_logic — No floating objects, weird gravity
3. movement_quality — Natural, not glitchy
4. placement_sense — Objects in correct positions
5. lighting_mood — Warm, consistent, brand-aligned
6. hand_quality — No extra fingers
7. text_artifacts — No gibberish text
8. transition_smooth — Clean scene changes
9. music_sync — Audio matches visual mood
10. brand_alignment — Jade green/gold/cream palette

Pass threshold: >= 7.0/10
