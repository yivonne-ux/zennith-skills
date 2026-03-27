# Audio Overview Feature (Podcast-Style Research)

NotebookLM's most powerful feature — generates a ~10 minute podcast-style discussion between two AI hosts analyzing your uploaded sources.

## How It Works:
1. Upload sources to notebook
2. Click "Generate Audio Overview" (takes 2-5 minutes to generate)
3. Two AI hosts discuss your sources conversationally
4. They debate, question, connect dots between different sources
5. Often surface insights you wouldn't find from reading alone

## When to Use Audio Overview:

**Always use for:**
- Complex topics with multiple perspectives (e.g., "Is turmeric supplementation effective?")
- Pre-campaign research (listen before planning any major campaign)
- Cross-brand opportunity analysis (upload data from multiple brands)
- Quarterly market review (upload all recent market data)

**Skip for:**
- Simple fact-finding (just ask NotebookLM directly)
- Single-source research (not enough material for meaningful discussion)
- Time-sensitive tasks (generation takes a few minutes)

## Audio Overview -> Content Pipeline:

```
Audio Overview
    |
Transcribe (WhisperX: bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh transcribe audio.wav)
    |
Extract key insights (manually or Claude-assisted)
    |
Claude creates content:
    |- Blog posts from key arguments
    |- Social media hooks from interesting quotes/takes
    |- Ad angles from contrarian perspectives
    |- FAQ from questions the hosts raised
    |- Carousel content from debate points
    |- Video scripts from the most engaging segments
```

## Customizing Audio Overview:
Before generating, you can give NotebookLM instructions:
- "Focus on the Malaysian market implications"
- "Compare the competing viewpoints on [topic]"
- "Emphasize practical applications for a food business"
- "Discuss the regulatory implications"

## Example: Mirra Weight Management Meal Research Audio Overview

Sources uploaded:
1. PDF: "Asia Pacific Healthy Eating Trends 2025" (Euromonitor)
2. URL: Japanese bento culture article (Saveur)
3. URL: Malaysian office lunch habits survey (DOSM)
4. PDF: Competitor analysis — 5 KL bento delivery brands
5. YouTube: "The Rise of Meal Prep Culture in Asia" (CNA Insider)

Audio Overview surfaced:
- Connection between Japanese bento aesthetics and Instagram shareability
- Gap in market: no brand combining "health-forward" + "aesthetically Malaysian"
- Insight: office workers want healthy BUT also want comfort food textures
- Contrarian take: portion control (bento boxes) is a selling point, not a limitation

These became: 4 Instagram carousels, 2 blog posts, 1 campaign brief for "Beautiful Fuel" positioning.
