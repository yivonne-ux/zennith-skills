---
name: image-seed-bank
version: "1.0.0"
description: Structured storage for every image asset in the GAIA content factory. Stores key visuals, logos, models, action shots, tone images, and headlines as typed image seeds with performance tracking, generation lineage, and multi-brand targeting.
metadata:
  openclaw:
    scope: data-layer
    guardrails:
      - Always use image-seed.sh for reads and writes — never edit image-seeds.jsonl directly
      - Every seed must have a type and created_by
      - Performance metrics are only set via the tag command with real data
      - Never delete seeds — retire them by setting status to retired
      - Lock file prevents concurrent corruption — never bypass it
---

# Image Seed Bank — Visual Asset Store for GAIA Creative Studio

## Purpose

The Image Seed Bank is the central repository for every image asset produced by the GAIA agent team. Every key visual, logo, model shot, action image, tone piece, and headline visual is stored as an **image seed** — a structured JSON record with metadata for type, brand, campaign, colors, mood, generation params, performance metrics, and evolutionary lineage.

Seeds flow in from multiple sources:
- **Artee** generates visuals via NanoBanana / Recraft / Z-Image
- **Dreami** directs campaign key visuals
- **Iris** creates social-native image variants
- **Ad performance tagging** annotates seeds with real CTR, ROAS, and engagement data
- **Content tuner** reads winning patterns to evolve the next generation of visuals

## Seed Schema

Each seed is stored as a single JSON line in `~/.openclaw/workspace/data/image-seeds.jsonl`:

```json
{
  "id": "img-1739000000-a7x2",
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

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique ID: `img-<epoch_s>-<random4>` |
| `ts` | number | Creation timestamp in epoch milliseconds |
| `type` | string | Image type (key_visual, key_image, logo, model, action, tone, headline) |
| `file_path` | string | Relative path to the image file |
| `drive_url` | string | Google Drive URL (null if not uploaded) |
| `brand` | string | Brand slug (gaia-eats, pinxin, etc.) |
| `campaign` | string | Campaign ID or null |
| `tags` | array | Free-form tags for filtering and categorization |
| `colors` | array | Hex color codes used in the image |
| `mood` | string | Mood description |
| `subject` | string | What the image depicts |
| `nanobanana_prompt` | string | The generation prompt used (if applicable) |
| `generation_params` | object | Model, aspect ratio, and other gen settings |
| `parent_seed` | string | ID of the seed this was derived from (for lineage) |
| `generation` | number | Evolution generation (1 = original, 2+ = derived) |
| `performance` | object | Metrics: ctr, roas, impressions (null until measured) |
| `status` | string | Lifecycle state: draft, approved, winner, retired |
| `created_by` | string | Which agent created this seed |
| `created_at` | string | ISO date of creation |

## CLI: image-seed.sh

All interaction with the image seed bank goes through the CLI script:

```
~/.openclaw/skills/image-seed-bank/scripts/image-seed.sh
```

### Commands

#### `add` — Store a new image seed

```bash
bash image-seed.sh add \
  --type key_visual \
  --file-path "brands/gaia-eats/generated/hero-001.jpg" \
  --brand gaia-eats \
  --tags "rendang,vegan,hero" \
  --colors "#108474,#EFC947" \
  --mood "warm, appetizing" \
  --subject "vegan rendang platter" \
  --prompt "A warm appetizing vegan rendang..." \
  --gen-params "model:gemini-3-pro,aspect_ratio:9:16" \
  --created-by artee
```

Returns the new seed ID to stdout.

#### `query` — Search and filter seeds

```bash
# All key visuals for gaia-eats
bash image-seed.sh query --type key_visual --brand gaia-eats --top 10

# Winners sorted by CTR
bash image-seed.sh query --status winner --sort performance --top 5

# By mood
bash image-seed.sh query --mood warm --brand gaia-eats

# By tag
bash image-seed.sh query --tag rendang --top 10

# Single seed by ID
bash image-seed.sh query --id img-1739000123-a7x2
```

Filters: `--type`, `--brand`, `--tag`, `--mood`, `--status`, `--campaign`, `--created-by`, `--id`
Sort: `--sort recent` (default), `--sort performance` (by CTR desc, nulls last)
Limit: `--top N` (default 10)

#### `tag` — Attach performance metrics

```bash
bash image-seed.sh tag \
  --id img-123 \
  --performance "ctr:3.2,roas:4.1,impressions:15000" \
  --status winner
```

#### `promote` — Mark as winner (shorthand)

```bash
bash image-seed.sh promote --id img-123
```

#### `export` — Copy seed info for Drive upload

```bash
bash image-seed.sh export --id img-123 --drive-url "https://drive.google.com/..."
```

#### `count` — Count matching seeds

```bash
bash image-seed.sh count --type key_visual --brand gaia-eats --status winner
```

### Help

```bash
bash image-seed.sh --help
```

## Integration Points

### NanoBanana Pipeline (writes seeds)

After image generation, Artee stores each image as a seed:

```bash
bash image-seed.sh add --type key_visual \
  --file-path "$output_path" \
  --brand "$brand" \
  --prompt "$nanobanana_prompt" \
  --gen-params "model:$model,aspect_ratio:$ar" \
  --created-by artee
```

### Creative Studio (reads seeds)

The GAIA Creative Studio canvas reads seeds for the image library panel:

```bash
bash image-seed.sh query --brand gaia-eats --status approved --top 20
```

### Ad Performance (tags seeds)

When ad metrics come in:

```bash
bash image-seed.sh tag --id "$seed_id" \
  --performance "ctr:$ctr,roas:$roas,impressions:$impressions"
```

### Seed Evolution

When creating a derivative:

```bash
bash image-seed.sh add --type key_visual \
  --file-path "$new_path" \
  --brand "$brand" \
  --parent "$parent_seed_id" --generation 2 \
  --created-by artee
```

## Data File

- Location: `~/.openclaw/workspace/data/image-seeds.jsonl`
- Format: One JSON object per line (JSONL)
- Concurrency: Protected by lock file at `/tmp/image-seed.lock`
- Writes: Atomic via temp file + mv

## CHANGELOG

### v1.0.0 (2026-02-23)
- Initial creation: Image Seed Bank for GAIA Creative Studio v2
- Schema: 18-field image seed record with performance tracking and lineage
- CLI: image-seed.sh with add, query, tag, promote, export, count commands
- macOS-compatible (bash 3.2, python3 JSON processing)

## OHNEIS REVERSE PROMPT SYSTEM

### What Ohneis Does
Ohneis builds **style systems** not random images:
1. Lock into a visual look (high grain, stretched light, soft surreal shadows)
2. Create a "visual ruleset" that applies across all content
3. Upload brand assets → apply style → get brand-matched visuals
4. Consistent aesthetic thread across portraits, campaigns, products

### Reverse Prompt Engineering
When analyzing an existing image to recreate its style:

```json
{
  "style_extraction": {
    "camera_angle": "eye-level, slight low angle",
    "lens_specs": "35mm, f/1.8, shallow DOF",
    "lighting": "golden hour, soft directional, window-side",
    "texture": "cinematic grain, soft diffusion",
    "color_grade": "warm shadows, lifted blacks, teal highlights",
    "mood_keywords": ["dreamy", "fashion-forward", "editorial"],
    "composition_rules": "rule of thirds, negative space right"
  }
}
```

### Style ID System
Each extracted style gets a Style ID for reuse:
- `OHNEIS-FASHION-001` — High grain, stretched light, fashion-meets-glitch
- `OHNEIS-EDITORIAL-001` — Porcelain clarity, low-key lighting, cinematic
- `PINXIN-CNY-001` — Warm teal, gold accents, family festive

### Usage in Seeds
```json
{
  "id": "img-001",
  "style_id": "PINXIN-CNY-001",
  "style_extraction": { ... },
  "parent_style": null,
  "style_generation": 1
}
```

### CLI: Extract Style from Image
```bash
# Analyze image and extract style
image-seed.sh extract-style <image_path> --brand pinxin --save

# Output: style_id + extraction JSON saved to seeds
```

This enables **consistent brand universes** — same visual thread across all content.
