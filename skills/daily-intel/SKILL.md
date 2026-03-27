---
name: daily-intel
agents:
  - scout
triggers:
  - cron: "0 7 * * *"
  - keyword: daily intel
  - keyword: morning briefing
  - keyword: market intelligence
  - keyword: competitor scan
---

# Daily Intel — Morning Intelligence Gathering

_Scout scrapes competitors, trends, and inspiration every morning. Digest feeds all agents._

## Purpose

Automated daily intelligence loop: scrape competitor activity, trending content, and market signals across spiritual/F&B/vegan verticals. Produces a digest that informs Dreami's content, Jade Oracle's positioning, and MIRRA/Pinxin strategy.

## Script

```bash
bash /Users/jennwoeiloh/.openclaw/skills/daily-intel/scripts/daily-intel.sh
```

### Options

```bash
daily-intel.sh                    # full run (all sections)
daily-intel.sh --section competitors   # competitors only
daily-intel.sh --section trends        # trends only
daily-intel.sh --section inspiration   # content inspiration only
daily-intel.sh --digest-only          # skip scraping, regenerate digest from today's raw data
```

## What It Scrapes

### Competitors
| Vertical | Targets | Method |
|----------|---------|--------|
| Spiritual/Psychic | Psychic Samira IG, top tarot creators, spiritual influencers | instaloader, web-read |
| F&B Malaysia | Taiso, Hishin XSlim, Simple Eats, Dahmakan | web-read, scrapling |
| Vegan MY | GoVegan MY, Veggie Planet | web-read, scrapling |

### Trends
| Source | What | Method |
|--------|------|--------|
| Reddit | r/psychic, r/tarot, r/vegan, r/malaysia (top 24h) | web-read (old.reddit JSON) |
| X/Twitter | Malaysia trending, wellness, spirituality keywords | twitter-scan.sh |
| Google Trends | wellness, vegan, tarot, meal plan (MY) | web-read |

### Content Inspiration
- Positive energy / good vibes posts
- Law of attraction content
- Motivational quotes
- Wellness/food memes
- Romance/self-love content

## Output

```
~/.openclaw/workspace/data/daily-intel/
  YYYY-MM-DD/
    competitors/          # raw scrape data per target
    trends/               # reddit, twitter, google trends
    inspiration/          # content inspo raw data
    digest.md             # top 10 insights + opportunities
    compound.md           # pattern comparison vs yesterday
```

Digest also posted to `rooms/analytics.jsonl`.

## Cron Setup

```crontab
0 7 * * * /bin/bash /Users/jennwoeiloh/.openclaw/skills/daily-intel/scripts/daily-intel.sh >> /Users/jennwoeiloh/.openclaw/logs/daily-intel.log 2>&1
```

## Data Flow

```
Cron (7am daily)
  -> daily-intel.sh scrapes all sources
  -> raw data saved to data/daily-intel/YYYY-MM-DD/
  -> digest.md generated (top 10 insights)
  -> compound.md generated (yesterday vs today delta)
  -> analytics.jsonl updated
  -> knowledge-compound digest triggered
  -> Agents read digest for daily planning
```

## Brand Relevance Map

| Signal | Relevant Brand |
|--------|---------------|
| Tarot/psychic trends | Jade Oracle |
| Meal plan / weight loss | MIRRA |
| Vegan food trends | Pinxin Vegan |
| Wellness / self-care | Serein, Rasaya |
| Supplements / health | Dr. Stan, Gaia Supplements |
| Positive energy / LOA | Jade Oracle, Wholey Wonder |

## Dependencies

- `web-read.sh` (Jina Reader, free)
- `scrapling` (anti-bot scraping)
- `instaloader` (Instagram public profiles)
- `twitter-scan.sh` (X/Twitter search)
- `knowledge-compound` (learning loop)
- `jq` (JSON processing)
