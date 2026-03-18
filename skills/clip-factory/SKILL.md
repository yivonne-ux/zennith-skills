---
name: clip-factory
display_name: ClipForge
description: Long video → short viral clips pipeline for GAIA CORP-OS. Transcribes, detects scene boundaries, scores segments for virality via LLM, extracts ranked clips, applies VideoForge post-production (caption, brand, effects), and exports multi-platform (TikTok 9:16, Reels, Shorts, Feed). Registers clips in seed-store.
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
  → [1] TRANSCRIBE (WhisperX, word-level + diarization)
  → [2] DETECT (PySceneDetect + FFmpeg silence detection)
  → [3] SCORE (LLM virality scoring: hook/pacing/emotion/share)
  → [4] EXTRACT (FFmpeg precise cuts at optimal boundaries)
  → [5] PRODUCE (VideoForge: caption + brand + effects + smart crop)
  → [6] EXPORT (multi-platform + seed-store register)
OUTPUT: clips/ directory with ranked clips + metadata.json
```

## Subcommands

### `run` — Full pipeline (THE KEY ONE)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh run \
  --input /path/to/video.mp4 \
  --brand mirra \
  [--min-score 60] [--max-clips 10] [--platforms tiktok,reels,shorts,feed]
```

### `analyze` — Stages 1-3 only (transcribe + detect + score)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh analyze \
  --input /path/to/video.mp4 [--min-score 60]
```
Output: `analysis.json` with ranked clip candidates (no extraction).

### `extract` — Stage 4 (cut clips from analysis)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh extract \
  --work-dir /path/to/analysis-dir [--max-clips 10]
```

### `produce` — Stages 5-6 (post-prod + export)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh produce \
  --work-dir /path/to/analysis-dir [--brand mirra] [--platforms tiktok,reels,shorts,feed]
```

### `preview` — Quick preview (analyze only, no extraction)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh preview \
  --input /path/to/video.mp4 [--top 5]
```

### `list` — Show clips from a previous run
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh list \
  --work-dir /path/to/analysis-dir
```

### `batch` — Process multiple videos
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh batch \
  --file /path/to/video-list.txt [--brand mirra]
```
File format: one video path per line.

### `blocks` — Extract reusable video blocks (library builder)
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh blocks \
  --input /path/to/video.mp4 --brand mirra \
  [--min-score 30] [--min-duration 5] [--max-duration 15] [--max-clips 20]
```
Optimized for building a clip LIBRARY — lower score threshold, shorter clips, auto-catalogs.
Extracts b-roll, compilation blocks with auto-categorization.

### `catalog` — Register clips in central catalog
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh catalog \
  --work-dir /path/to/work-dir [--brand mirra]
```
Generates `.meta.json` sidecar files and registers clips in the central catalog JSONL.

### `find` — Search clip library by semantic tags
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh find \
  [--brand mirra] [--mood inspiring] [--energy high] [--hook-type question] \
  [--reuse-as hook] [--keyword "vegan"] [--min-score 70] [--top 10] [--json]
```
Queries seed-store for clips matching semantic criteria. Returns ranked table or JSON.

**Semantic filters:**
- `--mood` — inspiring, funny, educational, emotional, dramatic, calm, urgent, casual
- `--energy` — low, medium, high
- `--hook-type` — question, shock, reveal, story, tip, testimonial, reaction, statistic, challenge
- `--reuse-as` — intro, hook, explainer, testimonial, cta, reaction, story, tip, broll, highlight, quote, behind-scenes
- `--keyword` — free-text search across tags and transcript

### `compose` — Build new video from clip library
```bash
bash /Users/jennwoeiloh/.openclaw/skills/clip-factory/scripts/clip-factory.sh compose \
  --brand mirra --mood inspiring --energy high --max-clips 5 \
  [--transition crossfade] [--title "mirra-highlights"]
```
Searches clip library → picks top matching clips → assembles into new video via VideoForge.
Agents can use this to build highlight reels, compilations, and themed videos from existing clips.

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
| `--top` | 5 | Show top N in preview mode |

## Scoring Dimensions

Each clip candidate scored 0-100:
- **Hook strength** (0-30): Does it grab attention in first 3 seconds?
- **Pacing/momentum** (0-25): Does it maintain energy throughout?
- **Emotional resonance** (0-25): Does it make the viewer feel something?
- **Shareability** (0-20): Would someone share, save, or send this?

## Smart Crop (9:16)

Automatically crops landscape video to portrait for TikTok/Reels:
- Detects speaker/subject position via FFmpeg cropdetect
- Applies dynamic pan to follow subject (not static center crop)
- Falls back to center crop if no clear subject detected
- Output: 1080x1920

## Auto-Subtitles

After clip extraction (Stage 4), auto-generates SRT and ASS caption files for each clip using the existing transcript data (word-level timestamps from WhisperX or faster-whisper).

### How It Works

1. **Transcript slicing**: Each clip's time range is matched against the full `transcript.json` to extract per-clip segments with word-level timestamps.
2. **SRT generation**: Standard SRT subtitle file with 2-3 word groups for readability.
3. **ASS generation**: Advanced SubStation Alpha format with karaoke-style word highlighting — each word lights up as it is spoken.
4. **Caption burning**: Integrates with VideoForge in Stage 5 (`video-forge.sh produce`) to burn ASS subtitles directly into the video using FFmpeg's `ass` filter.

### Subtitle Styles

- **Default**: Bold white text, black outline (3px), centered bottom — maximum readability on any background.
- **Font**: Arial Bold, 48px (scales with resolution).
- **Shadow**: Subtle drop shadow for depth on bright backgrounds.

### Platform-Specific Safe Zones

Subtitles are positioned to avoid UI overlays on each platform:

| Platform | Bottom Safe Zone | Subtitle Vertical Position |
|----------|-----------------|---------------------------|
| TikTok | Bottom 35% reserved (share/comment buttons) | Placed at 60% from top |
| Instagram Reels | Bottom 30% reserved (caption + buttons) | Placed at 65% from top |
| YouTube Shorts | Bottom 20% reserved (subscribe + title) | Placed at 75% from top |
| Feed / Landscape | Bottom 15% reserved (progress bar) | Placed at 82% from top |

### Pipeline Integration

- **Stage 4.5 (Auto-Subtitles)**: Runs automatically after `stage_extract` and before `stage_produce`.
- Generates `subtitles/` directory inside the work-dir with `.srt` and `.ass` files per clip.
- The `--no-subs` flag skips subtitle generation entirely.
- If transcript has no word-level timestamps, falls back to segment-level timing (less precise but still useful).

### Command

Subtitles are generated automatically in `run` and `produce` pipelines. The underlying whisper command used during transcription:

```bash
# WhisperX (preferred — word-level + diarization):
whisperx <clip.mp4> --model base --diarize --output_format json

# faster-whisper (Python API fallback):
from faster_whisper import WhisperModel
model = WhisperModel('base', device='cpu', compute_type='int8')
segments, info = model.transcribe(clip, word_timestamps=True)

# openai-whisper CLI (last resort):
whisper <clip.mp4> --model small --output_format srt --language en
```

### Output

```
work-dir/
  subtitles/
    clip_001.srt          # Standard SRT (for external players)
    clip_001.ass          # ASS with karaoke highlighting (for burning)
    clip_002.srt
    clip_002.ass
    ...
```

## Integration

- Chains to **VideoForge** for post-production (caption, brand, effects, export)
- Registers clips in **seed-store** (`seed-store.sh add --type video --source clip-factory`)
- Posts to **creative room** for Iris QA (`rooms/creative.jsonl`)
- Reads **Brand DNA** from `~/.openclaw/brands/{brand}/DNA.json`

## Cost

| Component | Cost |
|-----------|------|
| WhisperX transcription | $0 (local CPU) |
| PySceneDetect | $0 (local CPU) |
| LLM scoring (Gemini Flash) | ~$0.01-0.03 |
| FFmpeg extraction/crop | $0 (local) |
| VideoForge post-prod | $0 (local) |
| **Total** | **~$0.01-0.03 per video** |

## Output Structure

Each run creates a work directory with:
```
work-dir/
  metadata.json       # Input video info + settings
  transcript.json     # WhisperX output (segments with timestamps)
  scenes.json         # PySceneDetect scene boundaries
  silences.json       # FFmpeg silence gaps
  boundaries.json     # Merged scenes + silences
  candidates.json     # Scored clip candidates (ranked)
  clips.json          # Extraction manifest
  clips/              # Raw extracted clips
  subtitles/          # Auto-generated .srt + .ass per clip (karaoke-style)
  produced/           # Post-produced clips (9:16 smart crop + burned subtitles)
  export/             # Multi-platform exports (tiktok_, reels_, shorts_, feed_)
```

## Notes

- macOS Bash 3.2 compatible (no declare -A, no timeout, no ${var,,})
- 8GB RAM iMac sufficient (base whisper model + scenedetect, no GPU needed)
- All paths must be absolute (gateway exec does NOT expand ~)
- Python: prefers python3.13 (has faster-whisper), falls back to python3
- Log file: `/Users/jennwoeiloh/.openclaw/logs/clip-factory.log`
- All embedded Python uses sys.argv for path safety (no shell interpolation in Python code)
