---
name: "image-optimizer"
version: "1.0.0"
description: "Image compression and optimization for GAIA assets"
author: "taoz"
tags: ["images", "optimization", "compression", "avatars", "dashboard"]
agents: ["artee", "taoz"]
---

# Image Optimizer

Compresses and optimizes images for web, social, e-commerce, and dashboard use. Uses ImageMagick (`convert`) with macOS `sips` fallback.

## Usage

```bash
bash ~/.openclaw/skills/image-optimizer/scripts/image-optimizer.sh <command> [options]
```

## Commands

### optimize

Compress a single image with a named profile.

```bash
image-optimizer.sh optimize photo.png --profile avatar --output photo_256.jpg
```

### batch

Batch compress all images in a directory.

```bash
image-optimizer.sh batch ./images --profile social --suffix _opt --recursive
```

### dashboard

Optimize all boss dashboard avatars (reads manifest.json, creates 256x256 JPGs).

```bash
image-optimizer.sh dashboard
```

### stats

Show file size statistics for a directory of images.

```bash
image-optimizer.sh stats ./avatars
```

## Profiles

| Profile    | Dimensions     | Quality | Target Size   |
|------------|---------------|---------|---------------|
| avatar     | 256x256 crop  | 80      | 40-80KB       |
| social     | 1080x1080 max | 82      | 200-300KB     |
| ecommerce  | 800x800 max   | 85      | 100-200KB     |
| web        | 1024 max dim  | 80      | 100-200KB     |
| original   | No resize     | 90      | Metadata only |

## Requirements

- ImageMagick (`convert`) -- primary
- macOS `sips` -- fallback (limited features)

## Logs

All operations logged to `~/.openclaw/logs/image-optimizer.log`.
