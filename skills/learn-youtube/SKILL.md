---
name: learn-youtube
description: Full video intelligence — transcript with timestamps, frame-by-frame screenshots, metadata. Works with YouTube, Instagram, TikTok, Twitter/X, Facebook, local files, any URL.
evolves: true
agents:
  - scout
  - taoz
---

# Learn Video — Universal Video Intelligence Pipeline

One command to fully extract and analyze any video: transcript with timestamps, frame-by-frame visual screenshots, metadata, and structured output.

Works with: YouTube, Instagram, TikTok, Twitter/X, Facebook, local files, direct URLs, and 1000+ sites via yt-dlp.

## Quick Start

```bash
B="$HOME/.openclaw/skills/learn-youtube/scripts/learn-video.sh"

# YouTube
bash "$B" "https://youtube.com/watch?v=VIDEO_ID"

# Instagram Reel
bash "$B" "https://instagram.com/reel/ABC123/"

# TikTok
bash "$B" "https://tiktok.com/@user/video/123456"

# Twitter/X video
bash "$B" "https://x.com/user/status/123456"

# Local video file
bash "$B" /path/to/video.mp4

# Transcript only
bash "$B" "https://youtube.com/watch?v=..." --transcript-only

# Frames only
bash "$B" "https://youtube.com/watch?v=..." --frames-only

# Custom frame interval (every 10s instead of scene detection)
bash "$B" "https://youtube.com/watch?v=..." --interval 10

# Keep the downloaded video (don't auto-delete)
bash "$B" "https://youtube.com/watch?v=..." --keep-video
```

## What It Extracts

| Output | File | Description |
|--------|------|-------------|
| Metadata | `metadata.json` | Title, channel/uploader, duration, views, tags, platform |
| Transcript | `transcript.txt` | Full transcript with `[MM:SS]` timestamps |
| Raw transcript | `transcript-raw.txt` | Plain text, no timestamps |
| Frames | `frames/*.jpg` | Scene-change screenshots (1280x720) |
| Manifest | `frames/manifest.txt` | Frame-by-frame index paired with nearest transcript line |
| Summary | `summary.txt` | Quick stats |

Output directory: `~/.openclaw/workspace/data/video/<slug>/`

## Supported Sources

| Platform | Source detection | Transcript method |
|----------|-----------------|-------------------|
| YouTube | URL pattern | youtube-transcript-api (best) + yt-dlp subtitles (fallback) |
| Instagram | URL pattern | yt-dlp subtitles |
| TikTok | URL pattern | yt-dlp subtitles |
| Twitter/X | URL pattern | yt-dlp subtitles |
| Facebook | URL pattern | yt-dlp subtitles |
| Local file | File exists check | Embedded subtitle extraction (ffmpeg) |
| Direct URL | File extension match | None (frames only) |
| Any other site | yt-dlp auto-detect | yt-dlp subtitles |

## How Frame Extraction Works

1. **Scene detection** (default): ffmpeg detects visual scene changes, extracts a frame at each transition. Threshold 0.4 (adjustable via `--scene`).
2. **Interval fallback**: If scene detection yields <15 frames, auto-supplements with fixed-interval frames.
3. **Frame cap**: Max 80 frames (adjustable via `--max-frames`). Evenly trims excess.
4. **Manifest pairing**: Each frame is matched to the nearest transcript line within 15 seconds.

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--transcript-only` | Transcript with timestamps only | full pipeline |
| `--frames-only` | Frames only (no transcript) | full pipeline |
| `--info` | Metadata only | full pipeline |
| `--interval N` | Frame every N seconds | scene detection |
| `--max-frames N` | Cap frame count | 80 |
| `--scene 0.4` | Scene detection threshold | 0.4 |
| `--keep-video` | Don't delete video after extraction | auto-delete |

## For Analysis in Claude Code

After extraction, use Claude Code to analyze:

```
# Read the manifest to see frame-transcript pairs
Read frames/manifest.txt

# View individual frames (Claude is multimodal)
Read frames/scene_0001.jpg

# Read full transcript
Read transcript.txt
```

Claude Code sees the images and reads the transcript for full forensic analysis.

## Dependencies

All pre-installed:
- `yt-dlp` (2026.02.04) — video download + subtitle extraction (1000+ sites)
- `ffmpeg` (8.0.1) — frame extraction with scene detection
- `ffprobe` — video metadata + duration detection
- `python3` — transcript parsing + manifest generation
- `youtube-transcript-api` (Python) — primary YouTube transcript method

## Backwards Compatibility

- `learn-youtube.sh` still works (symlinks to `learn-video.sh`)
- Old YouTube-only output path (`~/.openclaw/workspace/data/youtube/`) is now `~/.openclaw/workspace/data/video/`

## Agent Roles

- **Scout**: Primary. Fetches video, extracts transcript, frames, performs initial analysis.
- **Taoz**: Technical content — reviews and extracts implementation details.

## Related Skills

- `youtube-video-analyst` — forensic deconstruction of viral patterns (use AFTER this skill extracts the data)
- `knowledge-compound` — ingest analysis into knowledge vault
- `video-forge` — process the downloaded video further
