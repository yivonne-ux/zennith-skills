#!/usr/bin/env bash
# learn-video.sh — Universal video intelligence pipeline
# Works with: YouTube, Instagram, TikTok, Twitter/X, Facebook, local files, direct URLs
# Downloads video, extracts transcript+timestamps, pulls frame-by-frame screenshots,
# pairs frames with transcript, outputs structured analysis directory.
#
# Usage:
#   learn-video.sh <source>                     # Full pipeline (transcript + frames)
#   learn-video.sh <source> --transcript-only   # Transcript with timestamps only
#   learn-video.sh <source> --frames-only       # Frames only (no transcript)
#   learn-video.sh <source> --info              # Metadata only
#   learn-video.sh <source> --interval 10       # Frame every N seconds (default: scene detection)
#   learn-video.sh <source> --max-frames 60     # Cap frame count (default: 80)
#   learn-video.sh <source> --scene 0.4         # Scene detection threshold (default: 0.4)
#   learn-video.sh <source> --keep-video        # Don't delete video after frame extraction
#
# Sources:
#   YouTube:     https://youtube.com/watch?v=... / https://youtu.be/...
#   Instagram:   https://instagram.com/reel/... / https://instagram.com/p/...
#   TikTok:      https://tiktok.com/@user/video/...
#   Twitter/X:   https://x.com/user/status/... / https://twitter.com/...
#   Facebook:    https://facebook.com/watch/... / https://fb.watch/...
#   Local file:  /path/to/video.mp4  (any format ffmpeg supports)
#   Direct URL:  https://example.com/video.mp4
#
# Output: ~/.openclaw/workspace/data/video/<slug>/
#   metadata.json        — Video metadata (platform, title, etc.)
#   transcript.txt       — Full transcript with [MM:SS] timestamps
#   transcript-raw.txt   — Plain transcript (no timestamps)
#   frames/              — Extracted frame screenshots (JPG)
#   frames/manifest.txt  — Frame index: filename | timestamp | nearest transcript line
#   summary.txt          — Quick stats

set -euo pipefail

# --- Config ---
YTDLP="/opt/homebrew/bin/yt-dlp"
FFMPEG="/opt/homebrew/bin/ffmpeg"
FFPROBE="/opt/homebrew/bin/ffprobe"
P3="python3"
OUTPUT_BASE="$HOME/.openclaw/workspace/data/video"
MAX_FRAMES=80
SCENE_THRESHOLD=0.4
INTERVAL=""
MODE="full"  # full | transcript-only | frames-only | info
KEEP_VIDEO=false
SOURCE_TYPE=""  # youtube | ytdlp | local | direct-url
VIDEO_SLUG=""

# --- Parse args ---
SOURCE="${1:-}"
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --transcript-only) MODE="transcript-only" ;;
    --frames-only)     MODE="frames-only" ;;
    --info)            MODE="info" ;;
    --interval)        INTERVAL="$2"; shift ;;
    --max-frames)      MAX_FRAMES="$2"; shift ;;
    --scene)           SCENE_THRESHOLD="$2"; shift ;;
    --keep-video)      KEEP_VIDEO=true ;;
    *)                 echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$SOURCE" ]]; then
  cat << 'USAGE'
Usage: learn-video.sh <source> [options]

Sources:
  YouTube URL    https://youtube.com/watch?v=...
  Instagram URL  https://instagram.com/reel/...
  TikTok URL     https://tiktok.com/@user/video/...
  Twitter/X URL  https://x.com/user/status/...
  Local file     /path/to/video.mp4
  Any URL        yt-dlp tries 1000+ sites

Options:
  --transcript-only  Transcript with timestamps only
  --frames-only      Frames only (no transcript)
  --info             Metadata only
  --interval N       Frame every N seconds (default: scene detection)
  --max-frames N     Cap frame count (default: 80)
  --scene 0.4        Scene detection threshold (lower=more frames)
  --keep-video       Don't delete video after frame extraction
USAGE
  exit 1
fi

# --- Detect source type + generate slug ---
detect_source() {
  if [[ -f "$SOURCE" ]]; then
    # Local file
    SOURCE_TYPE="local"
    local basename
    basename=$(basename "$SOURCE")
    VIDEO_SLUG="${basename%.*}"
    echo "Source: local file ($SOURCE)"
  elif [[ "$SOURCE" =~ youtube\.com|youtu\.be|youtube\.com/shorts ]]; then
    SOURCE_TYPE="youtube"
    VIDEO_SLUG=$("$P3" -c "
import re, sys
url = sys.argv[1]
for p in [r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/|youtube\.com/v/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})', r'^([a-zA-Z0-9_-]{11})$']:
    m = re.search(p, url)
    if m:
        print(m.group(1))
        sys.exit(0)
sys.exit(1)
" "$SOURCE" 2>/dev/null) || { echo "Could not extract YouTube video ID" >&2; exit 1; }
    echo "Source: YouTube ($VIDEO_SLUG)"
  elif [[ "$SOURCE" =~ instagram\.com ]]; then
    SOURCE_TYPE="instagram"
    VIDEO_SLUG=$("$P3" -c "
import re, sys
m = re.search(r'/(reel|p|tv)/([A-Za-z0-9_-]+)', sys.argv[1])
print(f'ig-{m.group(2)}' if m else 'ig-' + sys.argv[1][-11:].replace('/',''))
" "$SOURCE")
    # Detect reel vs image post from URL
    if [[ "$SOURCE" =~ /reel/ ]]; then
      IG_TYPE="reel"
    else
      IG_TYPE="post"
    fi
    echo "Source: Instagram $IG_TYPE ($VIDEO_SLUG)"
  elif [[ "$SOURCE" =~ tiktok\.com ]]; then
    SOURCE_TYPE="ytdlp"
    VIDEO_SLUG=$("$P3" -c "
import re, sys
m = re.search(r'/video/(\d+)', sys.argv[1])
print(f'tt-{m.group(1)}' if m else 'tt-' + sys.argv[1][-11:].replace('/',''))
" "$SOURCE")
    echo "Source: TikTok ($VIDEO_SLUG)"
  elif [[ "$SOURCE" =~ twitter\.com|x\.com ]]; then
    SOURCE_TYPE="ytdlp"
    VIDEO_SLUG=$("$P3" -c "
import re, sys
m = re.search(r'/status/(\d+)', sys.argv[1])
print(f'x-{m.group(1)}' if m else 'x-' + sys.argv[1][-11:].replace('/',''))
" "$SOURCE")
    echo "Source: Twitter/X ($VIDEO_SLUG)"
  elif [[ "$SOURCE" =~ facebook\.com|fb\.watch|fb\.com ]]; then
    SOURCE_TYPE="ytdlp"
    VIDEO_SLUG=$("$P3" -c "
import re, sys, hashlib
m = re.search(r'/videos?/(\d+)', sys.argv[1])
if m: print(f'fb-{m.group(1)}')
else: print('fb-' + hashlib.md5(sys.argv[1].encode()).hexdigest()[:12])
" "$SOURCE")
    echo "Source: Facebook ($VIDEO_SLUG)"
  elif [[ "$SOURCE" =~ \.(mp4|mov|avi|mkv|webm|m4v|flv|wmv)$ ]]; then
    # Direct video URL
    SOURCE_TYPE="direct-url"
    VIDEO_SLUG=$("$P3" -c "
import hashlib, sys, os
url = sys.argv[1]
name = os.path.basename(url).split('?')[0].rsplit('.', 1)[0][:30]
h = hashlib.md5(url.encode()).hexdigest()[:8]
print(f'{name}-{h}' if name else h)
" "$SOURCE")
    echo "Source: direct URL ($VIDEO_SLUG)"
  else
    # Try yt-dlp (supports 1000+ sites)
    SOURCE_TYPE="ytdlp"
    VIDEO_SLUG=$("$P3" -c "
import hashlib, sys
from urllib.parse import urlparse
url = sys.argv[1]
host = urlparse(url).hostname or 'unknown'
host = host.replace('www.', '').split('.')[0]
h = hashlib.md5(url.encode()).hexdigest()[:10]
print(f'{host}-{h}')
" "$SOURCE")
    echo "Source: yt-dlp auto-detect ($VIDEO_SLUG)"
  fi
}

detect_source

OUTDIR="$OUTPUT_BASE/$VIDEO_SLUG"
mkdir -p "$OUTDIR/frames"

echo "=== learn-video: $VIDEO_SLUG ==="
echo "Output: $OUTDIR"

# --- Step 1: Metadata ---
fetch_metadata() {
  echo "--- Fetching metadata ---"

  if [[ "$SOURCE_TYPE" == "local" ]]; then
    # Local file: extract metadata via ffprobe
    "$FFPROBE" -v quiet -print_format json -show_format -show_streams "$SOURCE" 2>/dev/null | \
      "$P3" -c "
import json, sys, os
d = json.load(sys.stdin)
fmt = d.get('format', {})
vs = next((s for s in d.get('streams', []) if s.get('codec_type') == 'video'), {})
dur = float(fmt.get('duration', 0))
out = {
    'id': os.path.basename(sys.argv[1]),
    'title': os.path.basename(sys.argv[1]),
    'source': 'local',
    'source_path': sys.argv[1],
    'duration': int(dur),
    'duration_string': f'{int(dur)//3600}:{(int(dur)%3600)//60:02d}:{int(dur)%60:02d}' if dur >= 3600 else f'{int(dur)//60}:{int(dur)%60:02d}',
    'width': vs.get('width'),
    'height': vs.get('height'),
    'codec': vs.get('codec_name'),
    'fps': vs.get('r_frame_rate'),
    'file_size': fmt.get('size'),
}
json.dump(out, sys.stdout, indent=2, ensure_ascii=False)
" "$SOURCE" > "$OUTDIR/metadata.json"
    "$P3" -c "
import json
d = json.load(open('$OUTDIR/metadata.json'))
print(f\"Title: {d['title']}\")
print(f\"Duration: {d['duration_string']}\")
print(f\"Resolution: {d.get('width')}x{d.get('height')}\")
"
  else
    # URL: use yt-dlp for metadata
    "$YTDLP" --dump-json "$SOURCE" 2>/dev/null | "$P3" -c "
import json, sys
d = json.load(sys.stdin)
out = {
    'id': d.get('id'),
    'title': d.get('title'),
    'source': d.get('extractor', 'unknown'),
    'channel': d.get('channel') or d.get('uploader'),
    'channel_id': d.get('channel_id') or d.get('uploader_id'),
    'duration': d.get('duration'),
    'duration_string': d.get('duration_string'),
    'view_count': d.get('view_count'),
    'like_count': d.get('like_count'),
    'upload_date': d.get('upload_date'),
    'description': (d.get('description') or '')[:2000],
    'tags': d.get('tags', []),
    'categories': d.get('categories', []),
    'thumbnail': d.get('thumbnail'),
    'webpage_url': d.get('webpage_url'),
    'width': d.get('width'),
    'height': d.get('height'),
}
json.dump(out, sys.stdout, indent=2, ensure_ascii=False)
" > "$OUTDIR/metadata.json"

    "$P3" -c "
import json
d = json.load(open('$OUTDIR/metadata.json'))
print(f\"Title: {d.get('title', 'N/A')}\")
print(f\"Source: {d.get('source', 'N/A')}\")
ch = d.get('channel') or d.get('channel_id') or 'N/A'
print(f\"Channel: {ch}\")
print(f\"Duration: {d.get('duration_string', 'N/A')}\")
print(f\"Views: {d.get('view_count', 'N/A')}\")
"
  fi
}

# --- Step 2: Transcript ---
fetch_transcript() {
  echo "--- Extracting transcript ---"

  if [[ "$SOURCE_TYPE" == "local" ]]; then
    # Local files: no online transcript, try embedded subtitles or skip
    echo "Local file — checking for embedded subtitles..."
    local sub_count
    sub_count=$("$FFPROBE" -v quiet -select_streams s -show_entries stream=index -of csv=p=0 "$SOURCE" 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$sub_count" -gt 0 ]]; then
      echo "Found $sub_count subtitle stream(s), extracting..."
      "$FFMPEG" -y -i "$SOURCE" -map 0:s:0 "$OUTDIR/_subs.srt" 2>/dev/null || true
      if [[ -f "$OUTDIR/_subs.srt" ]]; then
        "$P3" - "$OUTDIR/_subs.srt" "$OUTDIR" << 'PYEOF'
import re, sys

srt_path = sys.argv[1]
outdir = sys.argv[2]

with open(srt_path) as f:
    content = f.read()

lines_ts = []
lines_raw = []
blocks = content.strip().split("\n\n")
for block in blocks:
    blines = block.strip().split("\n")
    if len(blines) < 3:
        continue
    ts_match = re.match(r"(\d{2}):(\d{2}):(\d{2})[,.](\d+)", blines[1])
    if not ts_match:
        continue
    h, m, s = int(ts_match.group(1)), int(ts_match.group(2)), int(ts_match.group(3))
    ts_str = f"{h:02d}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"
    text = " ".join(blines[2:]).strip()
    text = re.sub(r"<[^>]+>", "", text)
    if text:
        lines_ts.append(f"[{ts_str}] {text}")
        lines_raw.append(text)

with open(f"{outdir}/transcript.txt", "w") as f:
    f.write("\n".join(lines_ts))
with open(f"{outdir}/transcript-raw.txt", "w") as f:
    f.write("\n".join(lines_raw))

print(f"Transcript: {len(lines_ts)} lines extracted (embedded subtitles)")
PYEOF
        rm -f "$OUTDIR/_subs.srt"
        return 0
      fi
    fi

    echo "No subtitles found in local file"
    echo "No transcript available (local file — no subtitles embedded)" > "$OUTDIR/transcript.txt"
    echo "" > "$OUTDIR/transcript-raw.txt"
    return 0
  fi

  # --- Online sources ---

  # Method 1: youtube-transcript-api (YouTube only, best quality)
  if [[ "$SOURCE_TYPE" == "youtube" ]]; then
    "$P3" - "$VIDEO_SLUG" "$OUTDIR" << 'PYEOF' 2>/dev/null && return 0 || true
import sys
try:
    from youtube_transcript_api import YouTubeTranscriptApi
except ImportError:
    sys.exit(1)

video_id = sys.argv[1]
outdir = sys.argv[2]

api = YouTubeTranscriptApi()
transcript = api.fetch(video_id)

lines_ts = []
lines_raw = []
for snippet in transcript.snippets:
    secs = int(snippet.start)
    h, m, s = secs // 3600, (secs % 3600) // 60, secs % 60
    ts = f"{h:02d}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"
    lines_ts.append(f"[{ts}] {snippet.text}")
    lines_raw.append(snippet.text)

with open(f"{outdir}/transcript.txt", "w") as f:
    f.write("\n".join(lines_ts))
with open(f"{outdir}/transcript-raw.txt", "w") as f:
    f.write("\n".join(lines_raw))

print(f"Transcript: {len(lines_ts)} lines extracted")
PYEOF
  fi

  # Method 2: yt-dlp subtitles (works for YouTube + many other sites)
  echo "Trying yt-dlp subtitles..."
  local tmpdir
  tmpdir=$(mktemp -d)
  "$YTDLP" --write-auto-sub --write-sub --sub-lang "en,en-orig,zh,zh-Hans,zh-Hant,zh-CN,zh-TW,ja,ko" \
    --skip-download --sub-format vtt \
    -o "$tmpdir/%(id)s" "$SOURCE" 2>/dev/null || true

  local vtt_file
  vtt_file=$(ls "$tmpdir"/*.vtt 2>/dev/null | head -1 || true)

  if [[ -z "$vtt_file" ]]; then
    echo "No transcript/subtitles available for this video"
    echo "No transcript available" > "$OUTDIR/transcript.txt"
    echo "" > "$OUTDIR/transcript-raw.txt"
    rm -rf "$tmpdir"
    return 0
  fi

  "$P3" - "$vtt_file" "$OUTDIR" << 'PYEOF'
import re, sys

vtt_path = sys.argv[1]
outdir = sys.argv[2]

with open(vtt_path) as f:
    content = f.read()

lines_ts = []
lines_raw = []
seen = set()
ts_str = "00:00"

for line in content.split("\n"):
    ts_match = re.match(r"(\d{2}):(\d{2}):(\d{2})\.\d+ --> ", line)
    if ts_match:
        h, m, s = int(ts_match.group(1)), int(ts_match.group(2)), int(ts_match.group(3))
        ts_str = f"{h:02d}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"
    elif line.strip() and not line.startswith(("WEBVTT", "Kind:", "Language:", "NOTE")):
        clean = re.sub(r"<[^>]+>", "", line.strip())
        if clean and clean not in seen:
            seen.add(clean)
            lines_ts.append(f"[{ts_str}] {clean}")
            lines_raw.append(clean)

with open(f"{outdir}/transcript.txt", "w") as f:
    f.write("\n".join(lines_ts))
with open(f"{outdir}/transcript-raw.txt", "w") as f:
    f.write("\n".join(lines_raw))

print(f"Transcript: {len(lines_ts)} lines extracted (via yt-dlp)")
PYEOF

  rm -rf "$tmpdir"
}

# --- Step 2b: Instagram carousel download (instaloader) ---
fetch_instagram_slides() {
  echo "--- Downloading Instagram slides (instaloader) ---"
  local shortcode
  shortcode=$("$P3" -c "
import re, sys
m = re.search(r'/(reel|p|tv)/([A-Za-z0-9_-]+)', sys.argv[1])
print(m.group(2) if m else '')
" "$SOURCE")

  if [[ -z "$shortcode" ]]; then
    echo "Could not extract shortcode from IG URL" >&2
    return 1
  fi

  local ig_dir="$OUTDIR/ig-raw"
  mkdir -p "$ig_dir"

  # Use instaloader to download all slides
  cd "$ig_dir"
  /opt/homebrew/bin/instaloader \
    --no-profile-pic --no-metadata-json --no-compress-json \
    --filename-pattern="{shortcode}_{mediaid}" \
    -- "-${shortcode}" 2>&1 | tail -5 || true
  cd - > /dev/null

  # Find the downloaded directory
  local dl_dir
  dl_dir=$(find "$ig_dir" -maxdepth 1 -type d -name "-${shortcode}" 2>/dev/null | head -1)
  [[ -z "$dl_dir" ]] && dl_dir="$ig_dir"

  # Move images to frames/ directory with clean names
  local slide_num=1
  for img in $(ls "$dl_dir"/*.jpg 2>/dev/null | sort); do
    local dest="$OUTDIR/frames/slide_$(printf '%02d' $slide_num).jpg"
    cp "$img" "$dest"
    ((slide_num++))
  done

  # Also grab any videos from carousel
  for vid in $(ls "$dl_dir"/*.mp4 2>/dev/null | sort); do
    local dest="$OUTDIR/video.mp4"
    cp "$vid" "$dest"
    echo "Found video in carousel, saved to video.mp4"
    break  # Only take first video
  done

  # Extract caption from instaloader's text file
  local caption_file
  caption_file=$(ls "$dl_dir"/*.txt 2>/dev/null | head -1)
  if [[ -n "$caption_file" ]]; then
    cp "$caption_file" "$OUTDIR/caption.txt"
    echo "Caption saved to caption.txt"
  fi

  local slide_count
  slide_count=$(ls "$OUTDIR/frames"/slide_*.jpg 2>/dev/null | wc -l | tr -d ' ')
  echo "Instagram slides downloaded: $slide_count"

  # Build metadata from instaloader if yt-dlp failed
  if [[ ! -s "$OUTDIR/metadata.json" ]]; then
    "$P3" -c "
import json, sys, os, glob
outdir = sys.argv[1]
shortcode = sys.argv[2]
slides = sorted(glob.glob(os.path.join(outdir, 'frames', 'slide_*.jpg')))
caption = ''
cap_file = os.path.join(outdir, 'caption.txt')
if os.path.exists(cap_file):
    with open(cap_file) as f:
        caption = f.read()[:2000]
meta = {
    'id': shortcode,
    'title': f'Instagram post {shortcode}',
    'source': 'instagram',
    'slides': len(slides),
    'description': caption,
    'type': 'carousel' if len(slides) > 1 else 'single',
}
with open(os.path.join(outdir, 'metadata.json'), 'w') as f:
    json.dump(meta, f, indent=2, ensure_ascii=False)
print(f'Metadata: {len(slides)} slides, type={meta[\"type\"]}')
" "$OUTDIR" "$shortcode"
  fi

  # Clean up raw downloads
  rm -rf "$ig_dir"

  return 0
}

# --- Step 3: Get/download video ---
get_video() {
  local video_file="$OUTDIR/video.mp4"

  if [[ "$SOURCE_TYPE" == "local" ]]; then
    # Local file: symlink instead of copy (save disk)
    if [[ -f "$video_file" ]]; then
      echo "Video already linked"
      return 0
    fi
    echo "--- Linking local video ---"
    local abs_source
    abs_source=$(cd "$(dirname "$SOURCE")" && pwd)/$(basename "$SOURCE")
    ln -sf "$abs_source" "$video_file"
    return 0
  fi

  if [[ -f "$video_file" ]]; then
    echo "Video already downloaded"
    return 0
  fi

  if [[ "$SOURCE_TYPE" == "direct-url" ]]; then
    echo "--- Downloading video (direct URL) ---"
    curl -sL -o "$video_file" "$SOURCE" 2>&1 | tail -3
  else
    echo "--- Downloading video (720p max) ---"
    "$YTDLP" \
      -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720][ext=mp4]/best[height<=720]/best" \
      --merge-output-format mp4 \
      -o "$video_file" \
      "$SOURCE" 2>&1 | tail -5
  fi
}

# --- Step 4: Extract frames ---
extract_frames() {
  local video_file="$OUTDIR/video.mp4"
  if [[ ! -f "$video_file" ]] && [[ ! -L "$video_file" ]]; then
    echo "No video file found, cannot extract frames" >&2
    return 1
  fi

  # Resolve symlink for ffmpeg
  local real_video
  real_video=$(readlink "$video_file" 2>/dev/null || echo "$video_file")
  [[ ! -f "$real_video" ]] && real_video="$video_file"

  # Get video duration
  local duration
  duration=$("$FFPROBE" -v quiet -show_entries format=duration -of csv=p=0 "$real_video" | cut -d. -f1)
  echo "--- Extracting frames (video: ${duration}s) ---"

  local frame_dir="$OUTDIR/frames"
  rm -f "$frame_dir"/scene_*.jpg "$frame_dir"/interval_*.jpg

  if [[ -n "$INTERVAL" ]]; then
    # Fixed interval mode
    echo "Mode: every ${INTERVAL}s"
    "$FFMPEG" -y -i "$real_video" \
      -vf "fps=1/$INTERVAL,scale=1280:720" \
      -q:v 3 \
      "$frame_dir/interval_%04d.jpg" 2>/dev/null
  else
    # Scene detection mode (default)
    echo "Mode: scene detection (threshold=$SCENE_THRESHOLD)"
    "$FFMPEG" -y -i "$real_video" \
      -vf "select='gt(scene\,$SCENE_THRESHOLD)',showinfo,scale=1280:720" \
      -vsync vfr \
      -q:v 3 \
      "$frame_dir/scene_%04d.jpg" 2>&1 | \
      grep "pts_time" | sed 's/.*pts_time:\([0-9.]*\).*/\1/' > "$frame_dir/timestamps.txt" || true

    local frame_count
    frame_count=$(ls "$frame_dir"/scene_*.jpg 2>/dev/null | wc -l | tr -d ' ')

    # If too few frames from scene detection, supplement with intervals
    if [[ "$frame_count" -lt 15 ]]; then
      echo "Only $frame_count scene frames — supplementing with interval extraction"
      local calc_interval=$(( duration / 40 ))
      [[ "$calc_interval" -lt 3 ]] && calc_interval=3
      "$FFMPEG" -y -i "$real_video" \
        -vf "fps=1/$calc_interval,scale=1280:720" \
        -q:v 3 \
        "$frame_dir/interval_%04d.jpg" 2>/dev/null
    fi

    # If too many frames, trim evenly
    frame_count=$(ls "$frame_dir"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$frame_count" -gt "$MAX_FRAMES" ]]; then
      echo "Trimming $frame_count frames to $MAX_FRAMES"
      local all_frames=("$frame_dir"/*.jpg)
      local keep_every=$(( frame_count / MAX_FRAMES ))
      [[ "$keep_every" -lt 1 ]] && keep_every=1
      local idx=0
      for f in "${all_frames[@]}"; do
        if (( idx % keep_every != 0 )); then
          rm -f "$f"
        fi
        ((idx++))
      done
    fi
  fi

  local final_count
  final_count=$(ls "$frame_dir"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
  echo "Frames extracted: $final_count"
}

# --- Step 5: Build manifest (pair frames with transcript) ---
build_manifest() {
  echo "--- Building frame manifest ---"

  "$P3" - "$OUTDIR" << 'PYEOF'
import os, re, sys, json

outdir = sys.argv[1]
frame_dir = os.path.join(outdir, "frames")
transcript_file = os.path.join(outdir, "transcript.txt")
timestamps_file = os.path.join(frame_dir, "timestamps.txt")
manifest_file = os.path.join(frame_dir, "manifest.txt")
metadata_file = os.path.join(outdir, "metadata.json")

# Load video duration from metadata
duration = 0
if os.path.exists(metadata_file):
    with open(metadata_file) as f:
        meta = json.load(f)
        duration = meta.get("duration") or 0

# Parse transcript timestamps
transcript_entries = []
if os.path.exists(transcript_file):
    with open(transcript_file) as f:
        for line in f:
            m = re.match(r"\[(\d+):(\d+):?(\d*)\]\s*(.*)", line.strip())
            if m:
                parts = m.groups()
                if parts[2]:  # HH:MM:SS
                    secs = int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
                else:  # MM:SS
                    secs = int(parts[0]) * 60 + int(parts[1])
                transcript_entries.append((secs, parts[3]))

# Get scene detection timestamps if available
scene_timestamps = {}
if os.path.exists(timestamps_file):
    with open(timestamps_file) as f:
        for i, line in enumerate(f):
            line = line.strip()
            if line:
                ts = float(line)
                scene_timestamps[i + 1] = ts

# Get all frame files sorted
frames = sorted([f for f in os.listdir(frame_dir) if f.endswith(".jpg")])

lines = []
lines.append("# Frame Manifest")
lines.append(f"# Total frames: {len(frames)}")
lines.append(f"# Video duration: {duration}s")
lines.append("#")
lines.append("# filename | timestamp | transcript")
lines.append("")

for i, fname in enumerate(frames):
    ts = None

    scene_match = re.match(r"scene_(\d+)\.jpg", fname)
    if scene_match and int(scene_match.group(1)) in scene_timestamps:
        ts = scene_timestamps[int(scene_match.group(1))]

    interval_match = re.match(r"interval_(\d+)\.jpg", fname)
    if interval_match and duration > 0:
        idx = int(interval_match.group(1)) - 1
        total_interval_frames = len([f for f in frames if f.startswith("interval_")])
        if total_interval_frames > 0:
            ts = (idx / max(total_interval_frames, 1)) * duration

    if ts is None:
        ts = (i / max(len(frames), 1)) * duration if duration > 0 else 0

    nearest_text = ""
    if transcript_entries:
        nearest = min(transcript_entries, key=lambda e: abs(e[0] - ts))
        if abs(nearest[0] - ts) < 15:
            nearest_text = nearest[1]
        else:
            nearest_text = "[no speech]"

    ts_int = int(ts)
    h, m, s = ts_int // 3600, (ts_int % 3600) // 60, ts_int % 60
    ts_str = f"{h:02d}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"

    lines.append(f"{fname} | {ts_str} | {nearest_text}")

with open(manifest_file, "w") as f:
    f.write("\n".join(lines))

print(f"Manifest: {len(frames)} frames paired with transcript")
PYEOF
}

# --- Step 6: Summary ---
write_summary() {
  local frame_count
  frame_count=$(ls "$OUTDIR/frames"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
  local transcript_lines
  transcript_lines=$(wc -l < "$OUTDIR/transcript.txt" 2>/dev/null | tr -d ' ' || echo "0")

  cat > "$OUTDIR/summary.txt" << EOF
=== learn-video: $VIDEO_SLUG ===
Source: $SOURCE
Type: $SOURCE_TYPE
Output: $OUTDIR

Metadata: metadata.json
Transcript: $transcript_lines lines (transcript.txt + transcript-raw.txt)
Frames: $frame_count screenshots (frames/*.jpg)
Manifest: frames/manifest.txt

Files:
$(ls -lh "$OUTDIR"/*.* 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}')
$frame_count frame images in frames/
EOF

  cat "$OUTDIR/summary.txt"
}

# --- Run pipeline ---
case "$MODE" in
  info)
    fetch_metadata
    ;;
  transcript-only)
    fetch_metadata
    fetch_transcript
    echo ""
    echo "--- Transcript ---"
    head -20 "$OUTDIR/transcript.txt"
    local tlines
    tlines=$(wc -l < "$OUTDIR/transcript.txt" | tr -d ' ')
    [[ "$tlines" -gt 20 ]] && echo "... ($tlines total lines)"
    echo "(Full transcript: $OUTDIR/transcript.txt)"
    ;;
  frames-only)
    fetch_metadata
    get_video
    extract_frames
    build_manifest
    write_summary
    ;;
  full)
    if [[ "$SOURCE_TYPE" == "instagram" ]]; then
      # Instagram path: try yt-dlp metadata first, then instaloader for slides
      fetch_metadata || true
      fetch_transcript || true
      fetch_instagram_slides

      # If carousel had a video, extract frames from it too
      if [[ -f "$OUTDIR/video.mp4" ]]; then
        extract_frames || true
      fi

      build_manifest
      write_summary

      # Cleanup video if present
      if [[ "$KEEP_VIDEO" == false ]]; then
        rm -f "$OUTDIR/video.mp4"
      fi
    else
      # Standard path: YouTube, TikTok, local files, etc.
      fetch_metadata
      fetch_transcript
      get_video
      extract_frames
      build_manifest
      write_summary

      # Cleanup: remove downloaded video to save disk (not local files)
      if [[ "$KEEP_VIDEO" == false ]] && [[ "$SOURCE_TYPE" != "local" ]]; then
        echo ""
        echo "Cleaning up video file to save disk..."
        rm -f "$OUTDIR/video.mp4"
      fi
    fi

    echo ""
    echo "DONE. Ready for analysis:"
    echo "  Transcript: $OUTDIR/transcript.txt"
    echo "  Frames:     $OUTDIR/frames/ ($(ls "$OUTDIR/frames"/*.jpg 2>/dev/null | wc -l | tr -d ' ') images)"
    echo "  Manifest:   $OUTDIR/frames/manifest.txt"
    echo ""
    echo "To analyze: read manifest.txt + view frames in Claude Code"
    ;;
esac
