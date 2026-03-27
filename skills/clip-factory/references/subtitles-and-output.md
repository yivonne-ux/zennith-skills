# ClipForge — Subtitles, Smart Crop & Output Details

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

### Whisper Commands

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

## Smart Crop (9:16)

Automatically crops landscape video to portrait for TikTok/Reels:
- Detects speaker/subject position via FFmpeg cropdetect
- Applies dynamic pan to follow subject (not static center crop)
- Falls back to center crop if no clear subject detected
- Output: 1080x1920

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
    clip_001.srt
    clip_001.ass
    clip_002.srt
    clip_002.ass
  produced/           # Post-produced clips (9:16 smart crop + burned subtitles)
  export/             # Multi-platform exports (tiktok_, reels_, shorts_, feed_)
```
