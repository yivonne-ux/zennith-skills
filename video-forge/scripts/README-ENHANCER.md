# Video Enhancer — Internal Video Post-Production Tool

A unified CLI tool for automated video enhancement in GAIA CORP-OS. Integrates video-forge.sh + Remotion MotionKit for professional video post-production.

## Features

- **Auto-Captioning (Whisper)** — Generate accurate subtitles automatically
- **Brand Overlays** — Apply logo/watermark and brand identity to videos
- **LUT/Color Grading** — Professional color grading presets
- **Multi-Platform Export** — Export with safe zones for Instagram, TikTok, YouTube, LinkedIn

## Installation

Dependencies are handled automatically. Requires:
- ffmpeg
- Whisper or faster-whisper
- video-forge.sh (included)

## Usage

```bash
# Apply all enhancements
bash video-enhancer.sh video.mp4 --all --brand gaiaos

# Custom enhancements
bash video-enhancer.sh video.mp4 --captions --brand gaiaos --color cinema

# Export only
bash video-enhancer.sh video.mp4 --export-platforms --output-dir ./output
```

## Options

| Option | Description |
|--------|-------------|
| `--all` | Apply all enhancements (captions + branding + color + export) |
| `--captions` | Add auto-captions using Whisper |
| `--brand <brand>` | Apply brand overlays (logo/watermark) |
| `--color <preset>` | Apply LUT/color grading preset: `warm`, `cool`, `cinema`, `vintage`, `none` |
| `--export-platforms` | Export for multiple platforms with safe zones |
| `--output-dir <dir>` | Custom output directory (default: `./enhanced`) |
| `--help` | Show help message |

## Color Presets

- **warm** — Warm tones, increased contrast and saturation
- **cool** — Cool tones, slightly desaturated
- **cinema** — Cinematic look, high contrast, muted colors
- **vintage** — Vintage film look, desaturated with vintage curves

## Platform Exports

- **Instagram** — 9:16 with square safe zone
- **TikTok** — 9:16 vertical video
- **YouTube** — 16:9 horizontal video
- **LinkedIn** — 16:9, 4:5, and 1:1 formats

## Integration with Remotion MotionKit

For programmatic video compositions, the video-enhancer tool works alongside Remotion MotionKit:

1. Use Remotion MotionKit to create keyframe-based animations
2. Use video-enhancer to apply post-production effects
3. Export with safe zones for target platforms

Example workflow:
```bash
# 1. Create motion graphics with Remotion MotionKit
cd /path/to/remotion/project
npm run build

# 2. Enhance the output with video-enhancer
bash ~/.openclaw/skills/video-forge/scripts/video-enhancer.sh \
  dist/video.mp4 \
  --all \
  --brand gaiaos \
  --color cinema \
  --output-dir ./enhanced
```

## Brand Configuration

Brands are configured in `~/.openclaw/brands/<brand>/brand-dna.json`.

To add a new brand:
1. Create brand directory: `~/.openclaw/brands/<brand>/`
2. Add `brand-dna.json` with brand assets (logo, colors, fonts)
3. Reference brand with `--brand <brand>` flag

## Examples

### Example 1: Full Enhancement Pipeline
```bash
bash video-enhancer.sh raw_video.mp4 \
  --all \
  --brand gaiaos \
  --output-dir ./output
```

Output:
- `output/raw_video_captioned_branded_cinema.mp4` — Main enhanced file
- `output/exports/` — Platform-specific versions

### Example 2: Captions + Color Grading Only
```bash
bash video-enhancer.sh raw_video.mp4 \
  --captions \
  --color cinema \
  --output-dir ./output
```

### Example 3: Multi-Platform Export Only
```bash
bash video-enhancer.sh enhanced_video.mp4 \
  --export-platforms \
  --output-dir ./exports
```

## Logging

All operations are logged to:
```
~/.openclaw/logs/video-enhancer.log
```

## Error Handling

- Failed steps are logged but don't stop the pipeline
- Fallback mechanisms for captioning and branding
- Validates input files and dependencies before processing

## Dependencies

The tool automatically checks for:
- `ffmpeg` — Video processing
- `whisper` or `faster-whisper` — Captioning
- `video-forge.sh` — Core video processing
- `~/.openclaw/brands/<brand>/` — Brand assets (if --brand used)

## Troubleshooting

### Captioning Failed
```bash
# Check Whisper installation
bash ~/.openclaw/skills/video-forge/scripts/install-deps.sh
```

### Brand Assets Not Found
```bash
# Verify brand directory structure
ls -la ~/.openclaw/brands/gaiaos/
# Should contain brand-dna.json and assets/
```

### FFmpeg Not Found
```bash
# Install ffmpeg on macOS
brew install ffmpeg
```

## License

Internal tool for GAIA CORP-OS.