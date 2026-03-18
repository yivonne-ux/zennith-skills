---
name: image-seed-bank
version: "1.0.0"
description: Image seed bank CLI for GAIA Creative Studio — store, query, promote, and export generated images
metadata:
  openclaw:
    scope: creative
    guardrails:
      - Never delete user data or images
      - Always backup before modifying seed-index.json
      - Max 1000 seed entries (prevent unbounded growth)
---

# Image Seed Bank — Image Asset Management

## Purpose

Store, organize, and retrieve all generated images for GAIA Creative Studio.
Each image is catalogued with metadata: brand, campaign, tags, performance, etc.

## Storage

**Index file:** `~/.openclaw/workspace/rag/image-seed-bank.jsonl`

**Structure (JSONL):**
```json
{
  "id": "img-001",
  "ts": 1739000000000,
  "type": "key_visual|key_image|logo|model|action|tone|headline",
  "file_path": "brands/pinxin/generated/img-001.jpg",
  "drive_url": "https://drive.google.com/...",
  "brand": "pinxin",
  "campaign": "cgm-2026",
  "tags": ["poon-choi", "cny", "warm", "family"],
  "colors": ["#108474", "#EFC947"],
  "mood": "warm, festive, family",
  "subject": "poon-choi dish, family gathering",
  "nanobanana_prompt": "...",
  "generation_params": {"model": "gemini-3-pro", "aspect_ratio": "9:16"},
  "parent_seed": null,
  "generation": 1,
  "performance": {"ctr": null, "roas": null, "impressions": null},
  "status": "draft|approved|winner|retired",
  "created_by": "dreami",
  "created_at": "2026-02-23"
}
```

## CLI Commands

```bash
# Add a new image seed (--brand and --tags are REQUIRED)
bash ~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh add \
  --type key_visual \
  --brand pinxin \
  --campaign cgm-2026 \
  --file-path brands/pinxin/generated/img-001.jpg \
  --tags "poon-choi,cny,warm" \
  --colors "#108474,#EFC947" \
  --mood "warm, festive, family" \
  --subject "poon-choi dish" \
  --prompt "Golden prawn..."

# Query seeds by criteria
bash ~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh query \
  --brand pinxin \
  --tag "cny" \
  --status approved

# Promote a seed to winner
bash ~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh promote \
  --id img-001

# Export seed to Drive
bash ~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh export \
  --id img-001 \
  --drive-path "GAIA/Campaigns/CNY 2026"

# Digest — Analyze reference images via Gemini Vision and save as a style seed (Phase 2)
bash ~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh digest \
  --images "ref1.jpg,ref2.jpg" \
  --name "mirra ig vibes" \
  --brand mirra \
  --tags "instagram,lifestyle"

# Query style seeds — search saved style seeds by brand and tags (Phase 2)
bash ~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh query-style \
  --brand mirra \
  --tags "instagram"
```

## Asset Bridge (Phase 1)

Syncs assets between `library.db` (Creative Studio) and `image-seed-bank.jsonl` (seed bank).
Runs every 6 hours via cron. Script: `scripts/asset-bridge.sh`

```bash
# Sync in both directions
bash ~/.openclaw/skills/image-seed-bank/scripts/asset-bridge.sh --direction both

# Dry-run (no writes, just show what would sync)
bash ~/.openclaw/skills/image-seed-bank/scripts/asset-bridge.sh --dry-run

# Sync only from library.db -> seed bank
bash ~/.openclaw/skills/image-seed-bank/scripts/asset-bridge.sh --direction db-to-jsonl

# Sync only from seed bank -> library.db
bash ~/.openclaw/skills/image-seed-bank/scripts/asset-bridge.sh --direction jsonl-to-db
```

## Integration with Creative Studio

- Seed bank images appear in left panel for drag-drop
- Drag image to canvas creates ImageNode with that seed
- RecraftNode can reference seed for style consistency
- Export from canvas saves to seed bank automatically

## Guardrails

- Max 1000 seed entries per brand (enforced in CLI)
- Never modify `file_path` of existing seeds
- Always backup `seed-index.jsonl` before bulk operations
- Performance metrics are optional (can be null)
- **Force-tag guardrail**: `--brand` and `--tags` are required for `add` — untagged seeds are rejected to prevent orphaned assets
