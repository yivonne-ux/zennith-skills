# Content Scraper — Multi-Platform Trend & Inspiration Pipeline

_Zenni queues scrape jobs. Artemis + Iris execute. Learnings flow into the organism._

## Purpose

Scrape, analyze, and learn from content across platforms. Not just collecting — understanding what works, why, and how to adapt it for GAIA brands.

## Platforms (Reality Check — 2026)

| Platform | Method | Cost | Agent | Practical Use | Risk |
|----------|--------|------|-------|---------------|------|
| **YouTube** | Data API v3 | **Free** (10K units/day) | Artemis | Trend research, competitor channels, video metadata | Low |
| **Pinterest** | API v5 (OAuth2) | **Free** (needs dev app) | Artemis | Style/mood boards, visual inspiration, design trends | Low |
| **TikTok** | Apify scraper or `TikTokApi` lib | **~RM 200/mo** via Apify | Iris | Viral formats, hooks, hashtag trends | Medium |
| **Instagram** | Own account via `instagrapi` + Apify for competitors | **~RM 100/mo** via Apify | Iris | Own engagement + competitor hashtags | Medium |
| **Facebook** | Meta Graph API (public pages only) | **Free** | Iris | Own brand page monitoring | Low |
| **X.com** | **Skip** — free tier is write-only | N/A | — | Not practical without $200/mo paid tier | — |
| **Google Trends** | Free API | **Free** | Artemis | Keyword trends (Malaysian food, vegan, etc.) | Low |

### Priority Stack (Best ROI)
1. YouTube API v3 (free, reliable, most data)
2. Pinterest API v5 (free, great for visual inspiration)
3. Google Trends (free, tracks keyword momentum)
4. Apify for TikTok + Instagram (RM 200-300/mo when budget allows)
5. Facebook Graph API (free, limited but useful for own pages)

## Scripts

### `scrape-queue.sh` — Job Queue Manager
```bash
bash scrape-queue.sh add --platform pinterest --target "jennloh85" --type board_sync
bash scrape-queue.sh add --platform youtube --target "@veganmalaysia" --type channel_scan
bash scrape-queue.sh add --platform tiktok --target "#veganmalaysia" --type hashtag_trend
bash scrape-queue.sh list                    # show pending jobs
bash scrape-queue.sh next                    # pop next job for processing
bash scrape-queue.sh done <job_id>           # mark complete
```

### `scrape-run.sh` — Execute a Single Scrape Job
```bash
bash scrape-run.sh <job_json>
```
Routes to the right platform handler, executes scrape, stores results in seed bank + RAG memory.

### `pinterest-sync.sh` — Pinterest Board Sync
```bash
bash pinterest-sync.sh boards <username>     # list all boards
bash pinterest-sync.sh pins <board_id>       # get pins from board
bash pinterest-sync.sh sync <username>       # full sync of all boards
```

### `youtube-scan.sh` — YouTube Channel/Topic Scanner
```bash
bash youtube-scan.sh channel <channel_id>    # scan channel videos
bash youtube-scan.sh search "vegan rendang"  # search for topic
bash youtube-scan.sh trending "MY"           # trending in Malaysia
```

### `social-scan.sh` — Instagram/TikTok/Facebook/X Scanner
```bash
bash social-scan.sh instagram <username>     # scan profile
bash social-scan.sh tiktok <hashtag>         # scan hashtag
bash social-scan.sh facebook <page_id>       # scan page
bash social-scan.sh twitter <query>          # search tweets
```

## Queue Architecture

```
Jenn drops instruction (WhatsApp / Claude Code)
    ↓
Zenni classifies → creates scrape job in queue
    ↓
Queue: ~/.openclaw/workspace/data/scrape-queue.jsonl
    ↓
Cron picks up jobs every 30 min
    ↓
Routes to: Artemis (research platforms) or Iris (social platforms)
    ↓
Agent scrapes → extracts insights → stores in:
    - Content Seed Bank (content atoms: hooks, visuals, formats)
    - RAG Memory (insights, learnings, patterns)
    - Rooms (summaries for team awareness)
    ↓
Cross-pollination spreads findings to relevant agents
```

## Job Format

```json
{
  "id": "scrape-001",
  "ts": 1739548800000,
  "platform": "pinterest",
  "target": "jennloh85",
  "type": "board_sync",
  "priority": "medium",
  "status": "pending",
  "agent": "artemis",
  "instructions": "Study style and taste from all boards",
  "created_by": "zenni"
}
```

## API Keys Needed

| Platform | Key | Status |
|----------|-----|--------|
| Pinterest | `PINTEREST_ACCESS_TOKEN` | Needs dev app at developers.pinterest.com |
| YouTube | `YOUTUBE_API_KEY` | Free, 10K units/day |
| TikTok | `TIKTOK_API_KEY` | Research API (apply) |
| Instagram | `META_ACCESS_TOKEN` | Via Facebook Graph API |
| Facebook | `META_ACCESS_TOKEN` | Same as Instagram |
| X.com | `TWITTER_BEARER_TOKEN` | Free tier: 500K tweets/month read |

## Amoeba Integration

Every scrape produces learnings:
- What content formats are trending?
- What hooks get the most engagement?
- What visual styles are competitors using?
- What topics have untapped potential?

These learnings flow into the organism:
- Artemis stores competitive intel in RAG memory
- Iris stores engagement patterns
- Dreami uses insights for next campaign brief
- Iris adapts visual style based on trend data
- The whole team gets smarter about what works
