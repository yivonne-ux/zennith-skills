---
name: clip-factory
display_name: ClipForge
description: Long video -> short viral clips pipeline for GAIA CORP-OS. Transcribes, detects scene boundaries, scores segments for virality via LLM, extracts ranked clips, applies VideoForge post-production (caption, brand, effects), and exports multi-platform (TikTok 9:16, Reels, Shorts, Feed). Registers clips in seed-store.
agents:
  - dreami
  - taoz
---

# ClipForge — Video Clip Factory (v1)

Converts long-form video (podcast, vlog, interview, product shoot) into multiple short viral clips ranked by virality potential. A Fomofly/Opus Clip alternative — fully local, ~$0.01-0.03 per video.

## Who Uses This

- **Iris (Art Director)** — runs clip-factory via SCRIPT tier, does visual QA on output
- **Dreami (Creative Director)** — specifies brand + mood for post-production
- **Taoz** — builds and maintains the pipeline

## Dependencies

- **ffmpeg** (required) — video extraction, silence detection, smart crop
- **whisperx** or **faster-whisper** (required) — speech-to-text with word-level timestamps
- **PySceneDetect** (required) — visual shot boundary detection. Install: `pip install scenedetect[opencv]`
- **GOOGLE_API_KEY** (recommended) — Gemini Flash for LLM virality scoring (~$0.01-0.03 per video)
- **OPENAI_API_KEY** (fallback) — gpt-4o-mini if Gemini unavailable
- If no API key: falls back to heuristic scoring (zero cost, lower quality)

## 6-Stage Pipeline

```
INPUT: long_video.mp4
  -> [1] TRANSCRIBE (WhisperX, word-level + diarization)
  -> [2] DETECT (PySceneDetect + FFmpeg silence detection)
  -> [3] SCORE (LLM virality scoring: hook/pacing/emotion/share)
  -> [4] EXTRACT (FFmpeg precise cuts at optimal boundaries)
  -> [5] PRODUCE (VideoForge: caption + brand + effects + smart crop)
  -> [6] EXPORT (multi-platform + seed-store register)
OUTPUT: clips/ directory with ranked clips + metadata.json
```

## Subcommands

### `run` — Full pipeline (THE KEY ONE)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh run \
  --input /path/to/video.mp4 --brand mirra \
  [--min-score 60] [--max-clips 10] [--platforms tiktok,reels,shorts,feed]
```

### `analyze` — Stages 1-3 only (transcribe + detect + score)
```bash
clip-factory.sh analyze --input /path/to/video.mp4 [--min-score 60]
```

### `extract` — Stage 4 (cut clips from analysis)
```bash
clip-factory.sh extract --work-dir /path/to/analysis-dir [--max-clips 10]
```

### `produce` — Stages 5-6 (post-prod + export)
```bash
clip-factory.sh produce --work-dir /path/to/analysis-dir [--brand mirra] [--platforms tiktok,reels,shorts,feed]
```

### `preview` — Quick preview (analyze only, no extraction)
```bash
clip-factory.sh preview --input /path/to/video.mp4 [--top 5]
```

### `batch` — Process multiple videos
```bash
clip-factory.sh batch --file /path/to/video-list.txt [--brand mirra]
```

### `blocks` — Extract reusable video blocks (library builder)
```bash
clip-factory.sh blocks --input /path/to/video.mp4 --brand mirra \
  [--min-score 30] [--min-duration 5] [--max-duration 15] [--max-clips 20]
```

### `catalog` — Register clips in central catalog
```bash
clip-factory.sh catalog --work-dir /path/to/work-dir [--brand mirra]
```

### `find` — Search clip library by semantic tags
```bash
clip-factory.sh find [--brand mirra] [--mood inspiring] [--energy high] \
  [--hook-type question] [--reuse-as hook] [--keyword "vegan"] [--min-score 70] [--top 10] [--json]
```

### `compose` — Build new video from clip library
```bash
clip-factory.sh compose --brand mirra --mood inspiring --energy high --max-clips 5 \
  [--transition crossfade] [--title "mirra-highlights"]
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--input` | (required) | Input video file |
| `--brand` | (none) | Brand name for VideoForge branding + seed-store |
| `--min-score` | 60 | Minimum virality score (0-100) |
| `--min-duration` | 15 | Minimum clip duration in seconds |
| `--max-duration` | 60 | Maximum clip duration in seconds |
| `--max-clips` | 10 | Maximum number of clips to extract |
| `--platforms` | tiktok,reels,shorts,feed | Export platforms (comma-separated) |
| `--no-crop` | (off) | Skip 9:16 smart crop |
| `--no-subs` | (off) | Skip auto-subtitle generation |
| `--work-dir` | auto-generated | Custom working directory |

## Scoring Dimensions

Each clip candidate scored 0-100:
- **Hook strength** (0-30): Does it grab attention in first 3 seconds?
- **Pacing/momentum** (0-25): Does it maintain energy throughout?
- **Emotional resonance** (0-25): Does it make the viewer feel something?
- **Shareability** (0-20): Would someone share, save, or send this?

> Load `references/subtitles-and-output.md` for auto-subtitle details (SRT/ASS generation, platform safe zones, whisper commands), smart crop specs, and full output directory structure.

## Integration

- Chains to **VideoForge** for post-production
- Registers clips in **seed-store** (`seed-store.sh add --type video --source clip-factory`)
- Posts to **creative room** (`rooms/creative.jsonl`)
- Reads **Brand DNA** from `~/.openclaw/brands/{brand}/DNA.json`

## Cost

| Component | Cost |
|-----------|------|
| WhisperX + PySceneDetect + FFmpeg + VideoForge | $0 (local) |
| LLM scoring (Gemini Flash) | ~$0.01-0.03 |
| **Total** | **~$0.01-0.03 per video** |

## Notes

- macOS Bash 3.2 compatible (no declare -A, no timeout)
- 8GB RAM iMac sufficient (base whisper model + scenedetect, no GPU needed)
- All paths must be absolute (gateway exec does NOT expand ~)
- Log file: `/Users/jennwoeiloh/.openclaw/logs/clip-factory.log`
