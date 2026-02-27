---
name: ig-reels-trends
version: "1.0.0"
description: Scrape publicly accessible Instagram hashtag/explore pages for trending Reels formats, caption patterns, and engagement signals.
metadata:
  openclaw:
    scope: research
    guardrails:
      - Public data only — no login, no private profiles
      - Instagram may rate-limit or block; handle gracefully
      - Never scrape DMs, stories, or private content
      - Respect robots.txt and rate limits (3s delay)
---

# Instagram Reels Trends Scraper

## Purpose

Track what's trending on Instagram Reels to inform GAIA's content strategy. Scrapes public hashtag and explore pages for:
- **Trending content formats** — POV, tutorial, before/after, GRWM, transitions
- **Caption patterns** — hooks, hashtag strategies, CTA styles
- **Engagement signals** — what gets likes/comments/shares
- **Posting patterns** — optimal times, frequency

## Usage

```bash
# Scrape trending posts for a hashtag
python3 ~/.openclaw/skills/ig-reels-trends/scripts/scrape_ig_trends.py \
  --hashtag veganfood --max-posts 20

# Multiple hashtags
python3 ~/.openclaw/skills/ig-reels-trends/scripts/scrape_ig_trends.py \
  --hashtag "veganfood,plantbased,veganmalaysia" --max-posts 15

# Explore page (general trending)
python3 ~/.openclaw/skills/ig-reels-trends/scripts/scrape_ig_trends.py \
  --explore --max-posts 20
```

## Output Format

```json
{
  "source": "instagram",
  "hashtag": "#veganfood",
  "scraped_at": "2026-02-12T16:00:00Z",
  "posts": [
    {
      "caption": "First 3 lines of caption...",
      "hashtags": ["#veganfood", "#plantbased", "#healthyeating"],
      "likes_estimate": "1.2K",
      "comments_estimate": "45",
      "format_type": "tutorial",
      "has_audio": true,
      "is_reel": true,
      "gaia_relevance": "food",
      "relevance_score": 8
    }
  ]
}
```

## Content Format Detection

The scraper tags each post with detected format:
- `tutorial` — step-by-step, how-to, recipe
- `pov` — POV/perspective content
- `before_after` — transformation reveal
- `grwm` — "get ready with me" style
- `transition` — creative transitions
- `product_review` — unboxing, review, comparison
- `day_in_life` — lifestyle/vlog content
- `other` — unclassified

## Agent Assignment

- **Artemis 🏹** — hashtag research and trend detection
- **Dreami 🎭** — creative format inspiration
- **Iris 🌈** — posting strategy and engagement patterns

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: IG hashtag/explore scraper with format detection
