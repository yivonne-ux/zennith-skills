---
name: video-forge
description: Automated video post-production pipeline for GAIA CORP-OS. Captioning (Whisper + ASS), branding (logo/watermark/LUT), music mixing (auto-duck), effects (grain/vignette/color grade/zoom/shaky), multi-clip assembly, multi-platform export with safe zones, and full produce pipeline that chains operations by output type + brand DNA + mood.
agents:
  - dreami
  - taoz
---

# VideoForge (v1)

Automated video post-production pipeline. Takes raw video clips from Kling, Sora, Wan, or any source and applies post-production: captions, branding, music, effects, assembly, and multi-platform export.

## Who Uses This

- **Iris (Art Director)** — chains VideoForge after video generation (Kling/Sora/Wan)
- **Taoz** — builds and maintains the pipeline, runs batch operations
- **Dreami (Creative Director)** — specifies output type + mood in briefs; VideoForge executes

## Dependencies

- **ffmpeg** (required) — all video processing, hardware-accelerated via h264_videotoolbox on Apple Silicon
- **faster-whisper** or **whisper** (required for `caption` subcommand) — speech-to-text with word-level timestamps
- Run `bash scripts/install-deps.sh` to check and install dependencies

## Subcommands

### `caption` — Generate styled subtitles
```bash
bash scripts/video-forge.sh caption input.mp4 [options]
```
Options:
- `--style tiktok|clean|bold|minimal` (default: tiktok)
- `--lang en|ms|auto` (default: auto)
- `--word-level` — word-by-word timestamps (default for tiktok style)

Output: `.srt` and `.ass` files alongside input. Captioned video as `*_captioned.mp4`.

Styles:
- **tiktok** — word-by-word highlight (yellow active, white others), center screen
- **clean** — standard bottom subtitle, white text with black outline
- **bold** — large center text, impact font, high contrast
- **minimal** — small bottom-left text, low opacity

### `brand` — Apply brand identity overlays
```bash
bash scripts/video-forge.sh brand input.mp4 [options]
```
Options:
- `--brand gaia-eats` (reads `~/.openclaw/brands/{brand}/DNA.json`)
- `--logo /path/to/logo.png` (auto-finds at `~/.openclaw/brands/{brand}/logo.png`)
- `--position tl|tr|bl|br` (default: br)
- `--opacity 0.7` (default: 0.3 for watermark, 0.7 for logo)
- `--lower-third` — add brand name lower-third bar

### `music` — Mix background music with auto-ducking
```bash
bash scripts/video-forge.sh music input.mp4 [options]
```
Options:
- `--track /path/to/music.mp3` (required)
- `--volume 0.2` (default: 0.2)
- `--duck` — auto-duck music when speech detected (sidechaincompress)
- `--fade-in 2` — fade in duration in seconds
- `--fade-out 3` — fade out duration in seconds

### `effects` — Apply visual effects
```bash
bash scripts/video-forge.sh effects input.mp4 [options]
```
Options:
- `--grain light|medium|heavy` — film grain overlay
- `--vignette` — vignette effect
- `--lut /path/to/file.cube` — apply LUT file
- `--grade warm|cool|cinematic|vintage` — built-in color grade presets
- `--zoom-cuts` — 110% zoom every 3-4 seconds for energy
- `--shaky light|medium` — camera shake for UGC feel
- `--speed 0.5|1.5|2.0` — speed ramp

### `assemble` — Concatenate multiple clips
```bash
bash scripts/video-forge.sh assemble clip1.mp4 clip2.mp4 ... [options]
```
Options:
- `--transition fade|wipeleft|dissolve|none` (default: fade)
- `--duration 0.5` — transition duration in seconds

### `export` — Multi-platform resize with safe zones
```bash
bash scripts/video-forge.sh export input.mp4 [options]
```
Options:
- `--platforms tiktok,reels,shorts,youtube,feed,shopee` (comma-separated)
- `--all` — export all platform variants
- `--output /path/to/dir` — output directory

Platform specs:
| Platform | Resolution | Safe Zones |
|----------|-----------|------------|
| tiktok | 1080x1920 | top 120px, bottom 270px, right 80px |
| reels | 1080x1920 | top 100px, bottom 250px |
| shorts | 1080x1920 | bottom 200px |
| youtube | 1920x1080 | none |
| feed | 1080x1080 | none |
| shopee | 1080x1080 | bottom 80px |

### `produce` — Full automated pipeline (THE KEY ONE)
```bash
bash scripts/video-forge.sh produce input.mp4 --type aroll --brand gaia-eats [options]
```
Options:
- `--type aroll|broll|promotion|ugc|lofi|hero|education|channel` (required)
- `--brand gaia-eats` (required, reads DNA.json)
- `--mood cozy` (optional, reads mood preset from `~/.openclaw/brands/{brand}/moods/{mood}.json`)
- `--music /path/to/track.mp3` (optional, overrides auto-select)
- `--audit` — run `audit-visual.sh` on final output

Chains per type:
- **broll**: brand(watermark-only) -> effects(lut from mood) -> export(all)
- **aroll**: caption(word-level, tiktok) -> brand(logo, lower-third) -> music(duck) -> export(all)
- **promotion**: caption(bold) -> brand(logo) -> music(urgency) -> effects(zoom-cuts) -> export(all)
- **ugc**: effects(grain-light, shaky-light) -> caption(tiktok) -> export(9:16 only)
- **lofi**: effects(grain-medium, vignette, warm) -> music(volume 0.15) -> caption(clean, optional) -> brand(watermark) -> export(all)
- **hero**: effects(cinematic) -> brand(headline, premium) -> export(by-placement)
- **education**: caption(clean) -> brand(clean-logo) -> music(soft, volume 0.1) -> export(all)
- **channel**: export(all-platforms-with-safe-zones)

## Brand DNA Integration

Reads `~/.openclaw/brands/{brand}/DNA.json` for:
- Colors (primary, secondary, background, accent) — used for caption styling, lower-thirds
- Typography — font recommendations
- Visual style — influences effect choices

## Mood Integration

Reads `~/.openclaw/brands/{brand}/moods/{mood}.json` for:
- Color grade overrides
- Music mood and BPM
- Lighting and atmosphere adjustments
- Style preferences for the specific mood

## Output

- Processed videos saved to `output/` directory next to input file (or `--output <dir>`)
- Log file: `~/.openclaw/logs/video-forge.log`
- Platform exports: `output/{platform}_filename.mp4`

## Integration with Content Factory

- Post-produced videos -> `seed-store.sh add --type video`
- Audit results -> `audit-visual.sh audit-video <output>`
- Output type specs from `~/.openclaw/workspace/data/output-types.json`
- Brand DNA from `~/.openclaw/brands/{brand}/DNA.json`

## Notes

- macOS Bash 3.2 compatible (no declare -A, no timeout, no ${var,,})
- Uses h264_videotoolbox for hardware acceleration on Apple Silicon
- Single-pass FFmpeg where possible to avoid re-encoding
- Uses python3 -c for JSON parsing (no jq dependency)
- Film grain via FFmpeg noise filter, vignette via FFmpeg vignette filter
- Shaky cam via random crop+pad offset
