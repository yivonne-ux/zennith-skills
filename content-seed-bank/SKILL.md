---
name: content-seed-bank
version: "1.0.0"
description: Structured storage for every content atom in the GAIA content factory. Stores hooks, copies, images, ads, storyboards, templates, headlines, and CTAs as typed seeds with performance tracking, lineage, and multi-channel targeting.
metadata:
  openclaw:
    scope: data-layer
    guardrails:
      - Always use seed-store.sh for reads and writes — never edit seeds.jsonl directly
      - Every seed must have a type and source_agent
      - Performance metrics are only set via the tag command with real data
      - Never delete seeds — retire them by setting status to retired
      - Lock file prevents concurrent corruption — never bypass it
---

# Content Seed Bank — Phase 1 of the Content Factory

## Purpose

The Content Seed Bank is the central repository for every content atom produced by the GAIA agent team. Every hook, copy block, image prompt, ad variant, storyboard frame, template, headline, and CTA is stored as a **seed** -- a structured JSON record with metadata for type, source, channel targeting, persona targeting, campaign linkage, performance metrics, and evolutionary lineage.

Seeds flow in from multiple sources:
- **Artemis** scouts trends and deposits raw hooks and topic seeds
- **Dreami** creates copy, storyboards, and templates during CSO pipeline adaptation
- **Iris** generates social-native content variants
- **Ad performance tagging** annotates seeds with real CTR, ROAS, and engagement data
- **Content tuner** reads winning patterns to evolve the next generation of seeds

## Seed Schema

Each seed is stored as a single JSON line in `~/.openclaw/workspace/data/seeds.jsonl`:

```json
{
  "id": "seed-001",
  "ts": 1739000000000,
  "type": "hook|copy|image|video|ad|storyboard|template|headline|cta",
  "text": "content text or file path",
  "tags": ["trending", "tiktok", "vegan", "rendang"],
  "source_agent": "artemis|dreami|iris",
  "source_type": "trend-scout|cso-pipeline|manual|winning-ad",
  "campaign_id": "cso-42",
  "channel": "ig|tiktok|shopee|edm|facebook",
  "persona": "health-seeker|foodie|conscious|parent|genz",
  "performance": {
    "ctr": null,
    "roas": null,
    "impressions": null,
    "engagement": null
  },
  "parent_seed": null,
  "generation": 1,
  "status": "draft|published|tested|winner|retired"
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique ID: `seed-<epoch_s>-<random4>` |
| `ts` | number | Creation timestamp in epoch milliseconds |
| `type` | string | Content atom type (hook, copy, image, video, ad, storyboard, template, headline, cta) |
| `text` | string | The actual content text, or a file path for binary assets |
| `tags` | array | Free-form tags for filtering and categorization |
| `source_agent` | string | Which agent created this seed |
| `source_type` | string | How it was created (trend-scout, cso-pipeline, manual, winning-ad) |
| `campaign_id` | string | Linked CSO campaign ID, or null |
| `channel` | string | Target channel (ig, tiktok, shopee, edm, facebook) |
| `persona` | string | Target persona (health-seeker, foodie, conscious, parent, genz) |
| `performance` | object | Metrics: ctr, roas, impressions, engagement (null until measured) |
| `parent_seed` | string | ID of the seed this was derived from (for lineage tracking) |
| `generation` | number | Evolution generation (1 = original, 2+ = derived) |
| `status` | string | Lifecycle state: draft, published, tested, winner, retired |

## CLI: seed-store.sh

All interaction with the seed bank goes through the CLI script:

```
~/.openclaw/skills/content-seed-bank/scripts/seed-store.sh
```

### Commands

#### `add` — Create a new seed

```bash
bash seed-store.sh add \
  --type hook \
  --text "Did you know rendang can be vegan?" \
  --tags "trending,tiktok,vegan" \
  --source artemis \
  --source-type trend-scout \
  --campaign cso-42 \
  --channel tiktok \
  --persona foodie
```

Returns the new seed ID to stdout (e.g., `seed-1739000123-a7x2`).

#### `query` — Search and filter seeds

```bash
# All tiktok hooks, most recent first
bash seed-store.sh query --type hook --tag tiktok --top 10 --sort recent

# Winners on IG, sorted by CTR
bash seed-store.sh query --channel ig --status winner --top 5 --sort performance

# Everything in a campaign
bash seed-store.sh query --campaign cso-42

# Single seed by ID
bash seed-store.sh query --id seed-1739000123-a7x2
```

Filters: `--type`, `--tag`, `--channel`, `--persona`, `--status`, `--campaign`, `--source`, `--id`
Sort: `--sort recent` (default), `--sort performance` (by CTR descending, nulls last)
Limit: `--top N` (default 10)

#### `tag` — Attach performance metrics

```bash
bash seed-store.sh tag \
  --id seed-123 \
  --performance "ctr:3.2,roas:4.1,impressions:15000,engagement:8.5" \
  --status winner
```

#### `update` — Change any field

```bash
bash seed-store.sh update --id seed-123 --status published --channel ig
```

#### `count` — Count matching seeds

```bash
bash seed-store.sh count --type hook --status winner
```

#### `top` — Top performers shorthand

```bash
bash seed-store.sh top --type hook --channel tiktok --metric ctr --top 5
```

### Help

```bash
bash seed-store.sh --help
```

## Integration Points

### CSO Pipeline (writes seeds)

After the ADAPTATION step, Dreami stores each content variant as a seed:

```bash
bash seed-store.sh add --type copy --text "$adapted_copy" \
  --source dreami --source-type cso-pipeline \
  --campaign "$strategy_id" --channel "$target_channel"
```

### Ad Performance (tags seeds)

When ad metrics come in, the ad-performance skill tags seeds with real data:

```bash
bash seed-store.sh tag --id "$seed_id" \
  --performance "ctr:$ctr,roas:$roas,impressions:$impressions,engagement:$engagement"
```

### Content Tuner (reads patterns)

The content tuner queries winning seeds to extract patterns for the next generation:

```bash
# Get all winning hooks for pattern analysis
bash seed-store.sh query --type hook --status winner --sort performance --top 20
```

### Seed Evolution

When a content tuner creates a derivative of a winning seed:

```bash
bash seed-store.sh add --type hook --text "$evolved_text" \
  --source dreami --source-type winning-ad \
  --parent "$parent_seed_id" --generation 2 \
  --tags "evolved,tiktok,vegan"
```

## Data File

- Location: `~/.openclaw/workspace/data/seeds.jsonl`
- Format: One JSON object per line (JSONL)
- Concurrency: Protected by lock file at `/tmp/seed-store.lock`
- Writes: Atomic via temp file + mv

## CHANGELOG

### v1.0.0 (2026-02-13)
- Initial creation: Content Seed Bank as Phase 1 of the Content Factory
- Schema: 15-field seed record with performance tracking and lineage
- CLI: seed-store.sh with add, query, tag, update, count, top commands
- macOS-compatible (bash 3.2, python3 JSON processing)
