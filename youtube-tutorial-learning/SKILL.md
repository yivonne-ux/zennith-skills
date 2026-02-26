# YouTube Tutorial Learning Skill

Download, transcribe, visually analyze, and reverse-engineer YouTube tutorials into actionable skills and workflows.

## When to Use
- User shares a YouTube link and wants to learn from it
- Need to reverse-engineer a tutorial into steps/workflow
- Want to build a skill from video content
- Need to understand visual content (not just audio)

## Pipeline

### Step 1: Download (Myrmidons)
```bash
# Create output directory
mkdir -p ~/.openclaw/workspace/knowledge/youtube-tutorials/<topic>/<video_id>

# Download audio + subtitles + metadata
yt-dlp -x --audio-format mp3 --audio-quality 5 \
  --write-auto-sub --sub-lang "en.*" --sub-format vtt \
  --write-info-json \
  -o "<video_id>/<video_id>.%(ext)s" \
  "https://www.youtube.com/watch?v=<video_id>"

# Download video (low quality for frame extraction)
yt-dlp -f "bestvideo[height<=480]+bestaudio/best[height<=480]" \
  --merge-output-format mp4 \
  -o "<video_id>/<video_id>.mp4" \
  "https://www.youtube.com/watch?v=<video_id>"
```

### Step 2: Extract Content (Myrmidons)
```bash
# Convert VTT to clean transcript
python3 scripts/vtt-to-text.py <video_id>/<video_id>.en.vtt > <video_id>/transcript.txt

# Extract key frames (1 per 15 seconds)
ffmpeg -i "<video_id>/<video_id>.mp4" \
  -vf "fps=1/15,scale=640:-1" \
  "<video_id>/frames/frame_%04d.jpg" -y
```

### Step 3: Analyze Content (Athena)
- Read transcript.txt
- Extract: tools mentioned, step-by-step workflow, exact prompts, techniques
- Create digest.md per video

### Step 4: Visual Analysis (Iris)
- Analyze key frames with image model
- Identify: UI screens, tool interfaces, before/after comparisons, settings shown
- Add visual context to digest

### Step 5: Master Digest (Athena)
- Combine all video digests into MASTER-DIGEST.md
- Synthesize: recommended tool stack, unified workflow, prompt templates, best practices

### Step 6: Build Skill (Taoz via Claude Code CLI)
- From MASTER-DIGEST.md, create a reusable SKILL.md
- Include: scripts, prompt templates, workflow steps
- Add regression tests

## Storage
```
knowledge/youtube-tutorials/
  <topic>/
    <video_id>/
      transcript.txt     # Clean transcript
      digest.md          # Analysis
      frames/            # Key frames
      *.mp3              # Audio
      *.info.json        # Metadata
    MASTER-DIGEST.md     # Combined analysis
```

## Agent Roles
| Step | Agent | Why |
|------|-------|-----|
| Download | Myrmidons | Grunt work, cheap |
| Extract | Myrmidons | File operations |
| Analyze transcript | Athena | Strategy + analysis |
| Analyze visuals | Iris | Visual understanding |
| Master digest | Athena | Synthesis |
| Build skill | Taoz (Claude Code) | Coding |
| Test skill | Argus | QA |

## Mandarin/Other Languages
For non-English videos:
1. Download auto-generated subtitles in original language
2. Use Whisper for transcription if no subs available
3. Iris analyzes visuals (language-independent)
4. Athena processes with language context
