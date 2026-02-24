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
  "created_by": "artee",
  "created_at": "2026-02-23"
}
```

## CLI Commands

```bash
# Add a new image seed
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
