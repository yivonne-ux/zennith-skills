---
name: tiktok-posting
description: Automated TikTok video publishing via Content Posting API. Upload, caption, schedule posts for brand accounts.
agents:
  - dreami
  - taoz
---

# TikTok Posting — Automated Video Publishing

Publish videos to TikTok brand accounts via the Content Posting API. Handles video upload, caption writing, hashtag strategy, and scheduling.

## When to Use

- Publishing Jade Oracle TikTok content (oracle readings, pick-a-card)
- Publishing MIRRA short-form recipe/meal-prep videos
- Publishing Pinxin vegan content
- Batch scheduling TikTok content from content pipeline

## Prerequisites

### TikTok Developer App Setup

1. Register at [developers.tiktok.com](https://developers.tiktok.com)
2. Create app → select "Content Posting API" scope
3. Get OAuth credentials:
   - Client Key (app ID)
   - Client Secret
4. Authorize brand accounts via OAuth2 flow
5. Store tokens at `/Users/jennwoeiloh/.openclaw/secrets/tiktok-auth.env`

```bash
# /Users/jennwoeiloh/.openclaw/secrets/tiktok-auth.env
TIKTOK_CLIENT_KEY=your_client_key
TIKTOK_CLIENT_SECRET=your_client_secret
TIKTOK_ACCESS_TOKEN=your_access_token
TIKTOK_REFRESH_TOKEN=your_refresh_token
```

**Status: PENDING — requires Developer App registration at developers.tiktok.com**

## Procedure

### Step 1 — Check Auth Status

```bash
bash /Users/jennwoeiloh/.openclaw/skills/tiktok-posting/scripts/tiktok-post.sh status
```

### Step 2 — Upload Video

```bash
# Direct upload (video file + caption)
bash /Users/jennwoeiloh/.openclaw/skills/tiktok-posting/scripts/tiktok-post.sh upload \
  --video /path/to/video.mp4 \
  --caption "Your caption here" \
  --hashtags "#oracle #tarot #spiritual"

# From content pipeline (reads generated content)
bash /Users/jennwoeiloh/.openclaw/skills/tiktok-posting/scripts/tiktok-post.sh publish \
  --content-dir /Users/jennwoeiloh/.openclaw/workspace/data/content/jade-oracle/daily/2026-03-28/
```

### Step 3 — Schedule Post

```bash
bash /Users/jennwoeiloh/.openclaw/skills/tiktok-posting/scripts/tiktok-post.sh schedule \
  --video /path/to/video.mp4 \
  --caption "Caption" \
  --schedule "2026-03-29T10:00:00+08:00"
```

## TikTok Content Posting API Flow

1. **Init upload**: `POST /v2/post/publish/inbox/video/init/` → get `publish_id`
2. **Upload video**: Upload to the provided URL
3. **Check status**: `GET /v2/post/publish/status/fetch/` with `publish_id`
4. **Poll until done**: Status transitions: PROCESSING → PUBLISH_COMPLETE

## Content Guidelines

- Video: 3s - 10min, MP4/WebM, max 4GB
- Caption: max 2200 chars, 0-30 hashtags
- Thumbnail: auto-generated or custom
- Privacy: public, friends, or private
- Comments: on/off, filter keywords
- Duet/stitch: enable/disable

## Brand-Specific Rules

| Brand | Content Type | Frequency | Best Time (MYT) |
|-------|-------------|-----------|-----------------|
| Jade Oracle | Oracle readings, pick-a-card, spiritual | 3/day | 7AM, 12PM, 8PM |
| MIRRA | Meal prep, recipes, before/after | 1/day | 11AM |
| Pinxin | Vegan recipes, lifestyle | 1/day | 12PM |

## Key Constraints

- TikTok API requires approved Developer App (currently PENDING)
- Video must be pre-rendered (use video-gen.sh or video-forge.sh)
- Rate limit: 10 posts/day per account
- Tokens expire — refresh automatically via script
- Never post duplicate content (TikTok penalizes)
