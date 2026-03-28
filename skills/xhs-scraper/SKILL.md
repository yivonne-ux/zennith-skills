---
name: xhs-scraper
description: Scrape Xiaohongshu (XHS/RED) posts, notes, and profiles for competitive intelligence and content inspiration.
agents:
  - scout
  - dreami
---

# XHS Scraper — Xiaohongshu Content Intelligence

Extract content, images, and engagement data from Xiaohongshu (Little Red Book) for competitive analysis and creative inspiration. Chinese market intelligence for MIRRA, Pinxin, Jade Oracle.

## When to Use

- Scraping XHS competitor content (Chinese F&B, wellness, spiritual brands)
- Gathering visual inspiration from XHS trending content
- Analyzing Chinese market ad patterns and hooks
- Content research for Jade Oracle Chinese audience

## Tools Available

| Tool | XHS Support | Content Type |
|------|-------------|-------------|
| yt-dlp | Yes (XiaoHongShu extractor) | Video posts |
| learn-video.sh | Yes (via yt-dlp) | Video + transcript |
| web-read.sh / scrapling | Yes (headless) | Text notes, profiles |
| instaloader | No | - |
| gallery-dl | No | - |

## Procedure

### Step 1 — Determine Content Type

XHS content comes in two formats:
- **Video notes**: Use yt-dlp / learn-video.sh
- **Image notes (图文)**: Use web-read.sh / scrapling (headless scrape)

URL pattern: `https://www.xiaohongshu.com/explore/{note_id}` or `https://www.xiaohongshu.com/discovery/item/{note_id}`

### Step 2 — Scrape Video Notes

```bash
# Single video note
bash /Users/jennwoeiloh/.openclaw/skills/learn-youtube/scripts/learn-video.sh "https://www.xiaohongshu.com/explore/VIDEO_ID"

# Extract metadata only
bash /Users/jennwoeiloh/.openclaw/skills/learn-youtube/scripts/learn-video.sh --info "https://www.xiaohongshu.com/explore/VIDEO_ID"
```

### Step 3 — Scrape Image Notes / Profiles

```bash
# Scrape a note page (text + image descriptions)
bash /Users/jennwoeiloh/.openclaw/skills/agent-reach/scripts/web-read.sh "https://www.xiaohongshu.com/explore/NOTE_ID"

# Scrape with anti-bot (if web-read fails)
bash /Users/jennwoeiloh/.openclaw/skills/scrapling/scripts/scrape.sh fetch "https://www.xiaohongshu.com/explore/NOTE_ID" --output md
```

### Step 4 — Bulk Scrape (Competitor Profile)

```bash
# Use the XHS scraper script for batch operations
bash /Users/jennwoeiloh/.openclaw/skills/xhs-scraper/scripts/xhs-scrape.sh profile "USERNAME" --count 20
bash /Users/jennwoeiloh/.openclaw/skills/xhs-scraper/scripts/xhs-scrape.sh trending --category food --count 30
```

### Step 5 — Analyze for Patterns

For each scraped batch, extract:
1. **Hook patterns**: First line / title structure
2. **Visual style**: Color palette, layout, typography trends
3. **Engagement signals**: Likes/saves ratio, comment sentiment
4. **Hashtag strategy**: Which tags drive discovery
5. **Content format**: Carousel length, video duration sweet spots

Output analysis to: `~/.openclaw/workspace/data/xhs-intel/{date}/`

## Output Format

```markdown
# XHS Intel — {date}

## Top Performing Notes
| Note | Likes | Saves | Type | Hook |
|------|-------|-------|------|------|
| ... | ... | ... | video/image | first line |

## Pattern Summary
- Dominant visual style: ...
- Best performing format: ...
- Top hashtags: ...
- Hook formula: ...
```

## Key Constraints

- XHS requires Chinese language understanding — involve Dreami for content analysis
- Rate limiting: max 30 requests per batch, 5s delay between
- Some profiles are private — respect access restrictions
- Image downloads may require authenticated session (cookies)
- Always save raw data before analysis
