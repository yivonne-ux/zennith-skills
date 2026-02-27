---
name: ad-performance
description: Ingest ad performance data from Meta Ads CSV exports, map to seed bank entries, extract winning patterns, and feed insights back to creative agents.
metadata: {"openclaw": {"requires": {"bins": ["python3", "bash"]}}}
---

# Ad Performance Skill

Phase 2 of the Content Factory. This skill closes the feedback loop between ad spend and content creation by ingesting performance data, tagging seeds with results, and extracting winning patterns.

## Purpose

- Ingest ad performance data from Meta Ads CSV exports (and eventually the Meta Marketing API)
- Map campaign results back to seed bank entries (hooks, copy, ads)
- Extract winning patterns from top-performing content
- Feed actionable insights to Dreami (creative) and Athena (analytics)

## Data Flow

```
~/Downloads/ (Meta Ads CSV exports)
  |
  v
ingest-csv.sh --auto
  |-- parse CSV with python3 (normalize columns, handle quoting)
  |-- match campaigns to seeds in seeds.jsonl (by campaign_id, fuzzy text, tag overlap)
  |-- tag matched seeds with performance data via seed-store.sh
  |-- create new seeds of type "ad" for unmatched campaigns
  |-- move processed CSVs to ~/.openclaw/workspace/data/processed/
  |-- post summary to exec room
  v
analyze-winners.sh
  |-- query seed bank for seeds with performance data
  |-- analyze patterns across top performers (type, channel, persona, tags, text)
  |-- write winning patterns to winning-patterns.jsonl
  |-- post insights to creative room (Dreami) and exec room
  v
Dreami uses winning patterns to generate better content
```

## Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `ingest-csv.sh` | Parse Meta Ads CSV exports and tag seeds | `bash ingest-csv.sh ~/Downloads/report.csv` or `bash ingest-csv.sh --auto` |
| `ingest-meta.sh` | Future: pull data directly from Meta Marketing API | `bash ingest-meta.sh` (stub, requires API token) |
| `analyze-winners.sh` | Analyze top performers, extract patterns | `bash analyze-winners.sh` or `bash analyze-winners.sh --days 30` |

## Cron Schedule

| Schedule | Script | Description |
|----------|--------|-------------|
| Daily 18:00 MYT | `ingest-csv.sh --auto` | Auto-ingest any new CSV ad reports from ~/Downloads/ |
| Weekly Monday 11:00 MYT | `analyze-winners.sh` | Analyze winners from last 7 days, extract patterns |

Crontab entries (MYT = UTC+8):

```cron
0 10 * * * cd ~/.openclaw/skills/ad-performance/scripts && bash ingest-csv.sh --auto >> ~/.openclaw/logs/ad-ingest.log 2>&1
0 3 * * 1 cd ~/.openclaw/skills/ad-performance/scripts && bash analyze-winners.sh >> ~/.openclaw/logs/ad-analyze.log 2>&1
```

## Integration

- **Seed Bank**: Tags seeds via `seed-store.sh tag` with performance metrics (CTR, ROAS, impressions, engagement). Updates seed status to "tested" or "winner".
- **Exec Room**: Posts ingestion summaries and weekly analysis reports.
- **Creative Room**: Posts winning patterns for Dreami to use when generating new content.
- **Winning Patterns**: Stored in `~/.openclaw/workspace/data/winning-patterns.jsonl` for persistent reference.

## Data Files

| File | Location | Description |
|------|----------|-------------|
| `seeds.jsonl` | `~/.openclaw/workspace/data/seeds.jsonl` | Updated with performance tags and status changes |
| `winning-patterns.jsonl` | `~/.openclaw/workspace/data/winning-patterns.jsonl` | Detected patterns from top-performing content |
| `processed/` | `~/.openclaw/workspace/data/processed/` | Archive of ingested CSV files (timestamped) |

## Expected CSV Columns (Flexible Matching)

The ingestion script handles various column naming conventions from Meta Ads exports:

- Campaign Name / campaign_name
- Impressions / impressions
- CTR (Link Click-Through Rate) / ctr / link_ctr
- CPC (Cost per Link Click) / cpc / cost_per_click
- CPM / cpm
- Amount Spent / spend / cost
- ROAS (Purchase ROAS) / roas / purchase_roas
- Results / conversions / purchases
- Reach / reach
- Engagement (Post Engagement) / engagement

## Pattern Types

Winning patterns are categorized as:

- `hook_style` - Hook structures and formats that resonate
- `copy_formula` - Copywriting formulas with best performance
- `channel_timing` - Channel-specific timing insights
- `persona_affinity` - Which personas respond best to what
- `tag_theme` - Topics and themes that drive engagement

## Dependencies

- `python3` (system, for CSV parsing and analysis)
- `seed-store.sh` from the content-seed-bank skill
- Room JSONL files for posting summaries
