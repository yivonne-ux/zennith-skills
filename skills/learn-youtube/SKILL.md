---
name: learn-youtube
description: Learn from a YouTube video — extract transcript, categorize, analyze, map to GAIA knowledge vault. Structured knowledge extraction pipeline.
agents:
  - scout
  - taoz
---

# Learn YouTube — Video Knowledge Extraction Pipeline

Extract structured knowledge from YouTube videos. Fetches transcript, categorizes content, analyzes key insights, and maps findings to the GAIA knowledge vault for future reference.

## When to Use

- Learning from a competitor's video (e.g., Ali Akbar, Psychic Samira content)
- Extracting marketing strategies from YouTube tutorials
- Ingesting educational content for gaia-learn
- Analyzing viral video patterns for content creation
- Building knowledge base from industry thought leaders

## Procedure

### Step 1 — Video Identification

Input: YouTube URL or search query

If URL provided:
- Extract video ID
- Fetch metadata (title, channel, duration, views, publish date, description)

If search query:
- Search YouTube for relevant videos
- Present top 5 results with metadata
- Select target video(s)

### Step 2 — Transcript Extraction

Fetch the video transcript:

```bash
# Using yt-dlp for transcript
yt-dlp --write-auto-sub --sub-lang en --skip-download --output "%(id)s" "{url}"
```

Or use YouTube API / web scraping if available.

If no transcript available:
- Note this limitation
- Use video description and comments as fallback
- Consider audio extraction + Whisper transcription

### Step 3 — Content Categorization

Classify the video content:

| Category | Subcategories |
|----------|--------------|
| Marketing | Ad strategy, funnel design, copywriting, social media |
| Business | Revenue models, scaling, operations, hiring |
| Creative | Video production, design, content creation |
| Technical | Code, tools, APIs, infrastructure |
| Wellness | Health, nutrition, supplements, fitness |
| Spiritual | Readings, astrology, metaphysics, QMDJ |
| Education | Teaching methods, course design, learning |
| Industry | Market trends, competitor analysis, news |

### Step 4 — Structured Analysis

Extract and organize:

```markdown
## Video Analysis — {Title}
### Source: {channel} | {date} | {views} views | {duration}

### TL;DR (2-3 sentences)
...

### Key Insights
1. {Insight with timestamp}
2. ...

### Actionable Takeaways
1. {Specific action we can take}
2. ...

### Quotes Worth Saving
- "{quote}" — {timestamp}
...

### Frameworks/Models Mentioned
- {Framework name}: {brief description}
...

### Tools/Resources Mentioned
- {Tool}: {what it does, URL if given}
...

### Relevance to GAIA Brands
| Brand | How This Applies |
|-------|-----------------|
| {brand} | {specific application} |
...

### Knowledge Tags
- Primary: {main topic}
- Secondary: {related topics}
- Brands: {relevant GAIA brands}
```

### Step 5 — Knowledge Vault Integration

Ingest into the vault:

```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh \
  --source "youtube" \
  --url "{video_url}" \
  --title "{video_title}" \
  --category "{category}" \
  --file "{analysis_file}"
```

The vault database is at `~/.openclaw/workspace/vault/vault.db` (SQLite with FTS5).

### Step 6 — Cross-Reference

Check if the video connects to existing knowledge:
- Search vault for related entries
- Link to existing missions or strategies
- Update relevant room with findings

### Step 7 — Output

Save analysis to: `~/.openclaw/workspace/rooms/logs/learn-youtube-{video_id}-{date}.md`

Post summary to relevant room if this was a dispatched task.

## Agent Roles

- **Scout**: Primary owner. Fetches video, extracts transcript, performs initial analysis, categorizes content, ingests to vault.
- **Taoz**: If the video contains technical content (code, tools, architecture), Taoz reviews and extracts implementation details. Also handles any scripting needed for transcript extraction.

## Batch Mode

For processing multiple videos (e.g., all videos from a channel):

1. List all video URLs from the channel
2. Process each through the pipeline
3. Generate a summary report across all videos
4. Identify recurring themes and patterns

## GAIA Brand Context

Priority knowledge sources by brand:
- **jade-oracle**: Psychic Samira videos, spiritual marketing, QMDJ content
- **All brands**: Ali Akbar playbook videos, marketing strategy content
- **gaia-learn**: Educational content creation tutorials
- **pinxin-vegan / gaia-eats**: Food content, recipe videos

## Example

```
Learn from this Ali Akbar video on scaling with AI:
https://youtube.com/watch?v=EXAMPLE

Extract marketing frameworks and map to jade-oracle strategy.
```

```
Analyze all Psychic Samira YouTube ads.
Extract hook patterns, offer structures, and CTA strategies.
Compare to our jade-oracle approach.
```

## Related Skills

- `knowledge-compound` — For deeper knowledge processing
- `biz-scraper` — If video references a website to analyze
- `ads-competitor` — If video is a competitor's ad
