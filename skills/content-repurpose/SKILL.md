---
name: content-repurpose
description: |
  TRIGGER: "repurpose", "resize for", "reformat for", "adapt for platforms", "one image to all platforms", "multi-platform variants"
  ANTI-TRIGGER: creating original content from scratch, translating copy between languages (use campaign-translate), brand identity design
  OUTCOME: 10-20 platform-ready asset variants (images, videos, copy) from one hero asset + manifest.json
agents: [dreami, taoz]
version: 1.1.0
---

# Content Repurpose Engine

One hero asset (image, video, or copy) automatically reformatted into every platform variant. No manual resizing. One input, full distribution.

Serves ALL 14 brands. **Agents:** Dreami (copy adaptation), Iris (visual production), Taoz (pipeline automation).
**Cost:** $0 for resize/crop (ffmpeg/ImageMagick local). API cost only when NanoBanana AI recomposition needed.

---

## Workflow SOP

```
INPUT:
  - Hero asset: image (.png/.jpg), video (.mp4), copy (.txt), or carousel (slide-*.png)
  - Brand name (required)
  - Target platforms (optional — defaults to ALL)

STEP 1: DETECT ASSET TYPE
  ├── Image? → Image Pipeline
  ├── Video? → Video Pipeline
  ├── Text?  → Copy Pipeline
  └── Carousel? → Carousel Pipeline

STEP 2: LOAD BRAND DNA
  └── Read ~/.openclaw/brands/{brand}/DNA.json
  └── Extract: colors, font, logo path, mood, voice, special rules
  └── Load references/brand-rules-and-integration.md for brand-specific overrides

STEP 3: LOAD PLATFORM SPECS
  └── Load references/platform-specs.md for all target platform dimensions, limits, and rules

STEP 4: FOR EACH TARGET PLATFORM
  a. Resize/reframe asset to platform dimensions
     → Load references/format-templates.md for ffmpeg commands and crop logic
     → Check crop loss percentage
     → If >30% loss → NanoBanana AI recomposition
  b. Apply brand overlay (logo in platform-safe zone, brand colors for padding)
  c. Adapt copy (enforce char limits, adjust hashtags, adapt CTA, shift tone)
  d. Generate thumbnail (if video)
  e. Export: {platform}-{WxH}.{ext}

STEP 5: QUALITY CHECK
  ├── Verify all output dimensions match spec
  ├── Verify file sizes within platform limits
  ├── Verify logo placement in safe zones
  ├── Verify copy length within limits
  └── Flag any files needing manual review

STEP 6: EXPORT MANIFEST
  └── Generate manifest.json listing all assets with metadata

OUTPUT:
  - 10-20 platform-ready assets in output directory
  - manifest.json with full asset inventory
  - quality_report.txt with any flagged issues
```

---

## CLI Usage

```bash
# Full repurpose (all platforms, auto-detect asset type)
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra --input /path/to/hero.png

# Specific platforms only
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra --input /path/to/hero.mp4 \
  --platforms "ig-feed,ig-stories,tiktok,fb"

# Image only
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh image \
  --brand pinxin-vegan --input /path/to/hero.png

# Video only
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh video \
  --brand pinxin-vegan --input /path/to/hero-video.mp4

# Copy only (no visuals)
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh copy \
  --brand mirra --input /path/to/caption.txt

# Carousel
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh carousel \
  --brand mirra --input /path/to/slides/

# Batch (all recent hero assets for a brand)
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh batch \
  --brand mirra --since 7d

# Dry run (preview what would be generated)
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra --input /path/to/hero.png --dry-run

# With product tag
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra --input /path/to/hero.png --product "matcha-bento-set"

# Skip brand overlay
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra --input /path/to/hero.png --no-overlay

# Quality check on existing output
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh quality-check \
  --dir ~/.openclaw/workspace/data/images/mirra/repurposed/2026-03-23_matcha-bento-set/
```

### CLI Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--brand` | Yes | Brand name (must match `~/.openclaw/brands/`) |
| `--input` | Yes | Path to hero asset |
| `--platforms` | No | Comma-separated targets. Default: all |
| `--product` | No | Product name for output dir naming |
| `--dry-run` | No | Preview without generating |
| `--no-overlay` | No | Skip brand logo/watermark |
| `--since` | No | Batch mode: process assets newer than (e.g., "7d") |
| `--output-dir` | No | Custom output directory |
| `--quality` | No | "draft" or "final" (default: final) |

---

## References (loaded on demand)

| File | Content | Load During |
|------|---------|-------------|
| `references/platform-specs.md` | Image/video/copy platform dimensions, limits, hashtag rules, carousel specs, safe zones | Step 3 |
| `references/format-templates.md` | ffmpeg resize/crop commands, video reframing, duration trimming, hooks, subtitles, copy transformation rules | Step 4 |
| `references/brand-rules-and-integration.md` | Brand DNA loading, overlay rules, brand-specific overrides, output structure, manifest schema, integration map, error handling, quality checklist | Steps 2, 5, 6 |
