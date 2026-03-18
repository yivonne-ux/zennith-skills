#!/usr/bin/env bash
# clip-factory.sh (ClipForge) — Long video → short viral clips pipeline for GAIA CORP-OS
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash clip-factory.sh analyze --input video.mp4 [options]
#   bash clip-factory.sh extract --work-dir <dir> [options]
#   bash clip-factory.sh produce --work-dir <dir> [options]
#   bash clip-factory.sh run --input video.mp4 [options]        # full pipeline (default)
#   bash clip-factory.sh list --work-dir <dir>                  # show clips from previous run
#   bash clip-factory.sh preview --input video.mp4 [--top N]    # quick preview, no extraction
#   bash clip-factory.sh batch --file list.txt [options]         # process multiple videos
#   bash clip-factory.sh blocks --input video.mp4 [--brand <b>] # extract reusable video blocks
#   bash clip-factory.sh catalog --work-dir <dir> [--brand <b>] # generate metadata + catalog clips
#   bash clip-factory.sh find [--brand <b>] [--mood <m>]        # search clip library by tags
#   bash clip-factory.sh compose --brand <b> [--mood <m>]       # compose video from clip library

set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/clip-factory.log"
BRANDS_DIR="$HOME/.openclaw/brands"
VIDEO_FORGE="$HOME/.openclaw/skills/video-forge/scripts/video-forge.sh"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"
CLIP_SCORER="$SCRIPT_DIR/clip-scorer.py"
SMART_CROP="$SCRIPT_DIR/smart-crop.py"
ENV_FILE="$HOME/.openclaw/.env"
CLIP_LIBRARY_DIR="$HOME/.openclaw/workspace/data/clip-library"
CATALOG_FILE="$CLIP_LIBRARY_DIR/catalog.jsonl"

# Python: prefer 3.13 (has faster-whisper + scenedetect), fall back to python3
if command -v python3.13 >/dev/null 2>&1; then
  PY="python3.13"
else
  PY="python3"
fi

mkdir -p "$(dirname "$LOG_FILE")"

# --- Load env ---
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [clip-factory] $1"
  echo "$msg" >> "$LOG_FILE"
}

info() {
  echo "[ClipFactory] $1" >&2
  log "$1"
}

error() {
  echo "[ClipFactory] ERROR: $1" >&2
  log "ERROR: $1"
}

warn() {
  echo "[ClipFactory] WARN: $1" >&2
  log "WARN: $1"
}

# --- Utility: lowercase (bash 3.2 compatible) ---
to_lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# --- Utility: basename without extension ---
basename_no_ext() {
  local name
  name="$(basename "$1")"
  echo "${name%.*}"
}

# --- Utility: format seconds as HH:MM:SS ---
format_time() {
  local total_secs="$1"
  local h=$((total_secs / 3600))
  local m=$(( (total_secs % 3600) / 60 ))
  local s=$((total_secs % 60))
  printf "%02d:%02d:%02d" "$h" "$m" "$s"
}

# --- Utility: read JSON field with $PY---
json_field() {
  local file="$1"
  local field="$2"
  $PY -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    keys = sys.argv[2].split('.')
    val = data
    for k in keys:
        if isinstance(val, list):
            val = val[int(k)]
        else:
            val = val[k]
    print(val)
except:
    print('')
" "$file" "$field" 2>/dev/null
}

# --- Dependency checks ---
check_ffmpeg() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    error "ffmpeg is required. Install: brew install ffmpeg"
    exit 1
  fi
}

check_whisper() {
  if command -v whisperx >/dev/null 2>&1; then
    echo "whisperx"
  elif command -v faster-whisper >/dev/null 2>&1; then
    echo "faster-whisper"
  elif $PY -c "import faster_whisper" 2>/dev/null; then
    echo "faster-whisper-python"
  elif $PY -c "import whisper" 2>/dev/null; then
    echo "whisper-python"
  elif command -v whisper >/dev/null 2>&1; then
    echo "whisper-cli"
  else
    error "whisperx, faster-whisper, or whisper required for transcription."
    error "Install: pip install whisperx  OR  pip install faster-whisper  OR  pip install openai-whisper"
    exit 1
  fi
}

check_scenedetect() {
  if $PY -c "import scenedetect" 2>/dev/null; then
    return 0
  else
    error "PySceneDetect required. Install: pip install scenedetect[opencv]"
    exit 1
  fi
}

check_deps() {
  check_ffmpeg
  check_whisper >/dev/null
  check_scenedetect
}

# --- Get video duration in seconds ---
get_duration() {
  local input="$1"
  ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$input" 2>/dev/null | cut -d. -f1
}

# --- Get video resolution ---
get_resolution() {
  local input="$1"
  ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$input" 2>/dev/null
}

# ==========================================================================
# STAGE 1: TRANSCRIBE — WhisperX (word-level timestamps + diarization)
# ==========================================================================
stage_transcribe() {
  local input="$1"
  local work_dir="$2"
  local whisper_engine

  info "Stage 1: Transcribing..."
  whisper_engine=$(check_whisper)

  case "$whisper_engine" in
    whisperx)
      whisperx "$input" \
        --model base \
        --diarize \
        --output_format json \
        --output_dir "$work_dir" 2>&1 | tail -3
      # WhisperX outputs as <basename>.json
      local base_name
      base_name="$(basename_no_ext "$input")"
      if [[ -f "$work_dir/${base_name}.json" ]]; then
        mv "$work_dir/${base_name}.json" "$work_dir/transcript.json"
      fi
      ;;
    faster-whisper|faster-whisper-python)
      $PY - "$input" "$work_dir/transcript.json" << 'PYEOF'
import json, sys
from faster_whisper import WhisperModel

input_file = sys.argv[1]
output_file = sys.argv[2]

model = WhisperModel('base', device='cpu', compute_type='int8')
segments_gen, info = model.transcribe(input_file, word_timestamps=True)

segments = []
for seg in segments_gen:
    words = []
    if seg.words:
        for w in seg.words:
            words.append({'start': round(w.start, 3), 'end': round(w.end, 3), 'word': w.word.strip()})
    segments.append({
        'start': round(seg.start, 3),
        'end': round(seg.end, 3),
        'text': seg.text.strip(),
        'speaker': 'SPEAKER_00',
        'words': words
    })

with open(output_file, 'w') as f:
    json.dump({'segments': segments, 'language': info.language}, f, indent=2)
print(f'Transcribed {len(segments)} segments')
PYEOF
      ;;
    whisper-python)
      $PY - "$input" "$work_dir/transcript.json" << 'PYEOF'
import json, sys, whisper

input_file = sys.argv[1]
output_file = sys.argv[2]

model = whisper.load_model('base')
result = model.transcribe(input_file, word_timestamps=True)

segments = []
for seg in result['segments']:
    words = []
    if 'words' in seg:
        for w in seg['words']:
            words.append({'start': round(w['start'], 3), 'end': round(w['end'], 3), 'word': w['word'].strip()})
    segments.append({
        'start': round(seg['start'], 3),
        'end': round(seg['end'], 3),
        'text': seg['text'].strip(),
        'speaker': 'SPEAKER_00',
        'words': words
    })

with open(output_file, 'w') as f:
    json.dump({'segments': segments, 'language': result.get('language', 'en')}, f, indent=2)
print(f'Transcribed {len(segments)} segments')
PYEOF
      ;;
    whisper-cli)
      # Use whisper CLI (openai-whisper installed globally)
      whisper "$input" --model base --output_format json --output_dir "$work_dir" 2>&1 | tail -3
      local base_name
      base_name="$(basename_no_ext "$input")"
      if [[ -f "$work_dir/${base_name}.json" ]]; then
        # Convert whisper CLI JSON to our standard format
        $PY - "$work_dir/${base_name}.json" "$work_dir/transcript.json" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

segments = []
for seg in data.get('segments', []):
    words = []
    if 'words' in seg:
        for w in seg['words']:
            words.append({'start': round(w['start'], 3), 'end': round(w['end'], 3), 'word': w.get('word', '').strip()})
    segments.append({
        'start': round(seg['start'], 3),
        'end': round(seg['end'], 3),
        'text': seg['text'].strip(),
        'speaker': 'SPEAKER_00',
        'words': words
    })

with open(sys.argv[2], 'w') as f:
    json.dump({'segments': segments, 'language': data.get('language', 'en')}, f, indent=2)
print(f'Transcribed {len(segments)} segments')
PYEOF
      fi
      ;;
  esac

  if [[ ! -f "$work_dir/transcript.json" ]]; then
    error "Transcription failed — no transcript.json produced"
    return 1
  fi

  local seg_count
  seg_count=$($PY -c "import json,sys; print(len(json.load(open(sys.argv[1])).get('segments',[])))" "$work_dir/transcript.json" 2>/dev/null || echo "0")
  info "Transcription complete: $seg_count segments"

  # Deduplicate transcript segments (WhisperX hallucination mitigation)
  # Remove consecutive segments with identical or >80% similar text
  info "Deduplicating transcript segments..."
  $PY - "$work_dir/transcript.json" << 'PYEOF'
import json, sys

transcript_file = sys.argv[1]
with open(transcript_file) as f:
    data = json.load(f)

segments = data.get('segments', [])
if not segments:
    sys.exit(0)

def similarity(a, b):
    """Simple word-overlap similarity ratio (0.0-1.0)."""
    if not a or not b:
        return 0.0
    words_a = set(a.lower().split())
    words_b = set(b.lower().split())
    if not words_a or not words_b:
        return 0.0
    intersection = words_a & words_b
    union = words_a | words_b
    return len(intersection) / len(union) if union else 0.0

deduped = [segments[0]]
removed = 0

for i in range(1, len(segments)):
    prev_text = segments[i - 1].get('text', '').strip()
    curr_text = segments[i].get('text', '').strip()

    # Skip if identical or >80% similar to previous segment
    if curr_text == prev_text:
        removed += 1
        continue
    if similarity(curr_text, prev_text) > 0.8:
        removed += 1
        continue

    deduped.append(segments[i])

if removed > 0:
    data['segments'] = deduped
    with open(transcript_file, 'w') as f:
        json.dump(data, f, indent=2)
    print(f'Dedup: removed {removed} duplicate segments ({len(segments)} -> {len(deduped)})')
else:
    print(f'Dedup: no duplicates found ({len(segments)} segments)')
PYEOF
}

# ==========================================================================
# STAGE 2: DETECT — PySceneDetect (visual cuts) + silence detection
# ==========================================================================
stage_detect() {
  local input="$1"
  local work_dir="$2"

  info "Stage 2: Detecting scene boundaries..."

  # Visual shot boundaries via PySceneDetect
  $PY - "$input" "$work_dir/scenes.json" << 'PYEOF'
import json, sys
from scenedetect import detect, ContentDetector

input_file = sys.argv[1]
output_file = sys.argv[2]

scenes = detect(input_file, ContentDetector(threshold=27.0))
scene_list = []
for i, (start, end) in enumerate(scenes):
    scene_list.append({
        'index': i,
        'start': round(start.get_seconds(), 3),
        'end': round(end.get_seconds(), 3)
    })

with open(output_file, 'w') as f:
    json.dump(scene_list, f, indent=2)
print(f'Detected {len(scene_list)} scenes')
PYEOF

  # Silence detection via FFmpeg
  local silence_out="$work_dir/silences_raw.txt"
  ffmpeg -i "$input" -af silencedetect=noise=-30dB:d=0.5 -f null - 2>&1 | grep -E "silence_(start|end)" > "$silence_out" || true

  $PY - "$work_dir/silences_raw.txt" "$work_dir/silences.json" << 'PYEOF'
import json, re, sys

raw_file = sys.argv[1]
output_file = sys.argv[2]

silences = []
starts = []
ends = []

with open(raw_file) as f:
    for line in f:
        m_start = re.search(r'silence_start:\s*([\d.]+)', line)
        m_end = re.search(r'silence_end:\s*([\d.]+)', line)
        if m_start:
            starts.append(float(m_start.group(1)))
        if m_end:
            ends.append(float(m_end.group(1)))

for i in range(min(len(starts), len(ends))):
    silences.append({'start': round(starts[i], 3), 'end': round(ends[i], 3)})

with open(output_file, 'w') as f:
    json.dump(silences, f, indent=2)
print(f'Detected {len(silences)} silence gaps')
PYEOF

  # Merge into boundaries.json
  $PY - "$work_dir/scenes.json" "$work_dir/silences.json" "$work_dir/boundaries.json" << 'PYEOF'
import json, sys

scenes_file = sys.argv[1]
silences_file = sys.argv[2]
output_file = sys.argv[3]

scenes = json.load(open(scenes_file))
silences = json.load(open(silences_file))

boundaries = {
    'scenes': scenes,
    'silences': silences,
    'scene_count': len(scenes),
    'silence_count': len(silences)
}

with open(output_file, 'w') as f:
    json.dump(boundaries, f, indent=2)
print(f'Boundaries: {len(scenes)} scenes, {len(silences)} silences')
PYEOF

  # Cleanup temp
  rm -f "$work_dir/silences_raw.txt"
  info "Boundary detection complete"
}

# ==========================================================================
# STAGE 3: SCORE — LLM-based virality scoring via clip-scorer.py
# ==========================================================================
stage_score() {
  local work_dir="$1"
  local min_score="${2:-60}"
  local min_duration="${3:-15}"
  local max_duration="${4:-60}"
  local scoring_mode="${5:-brand}"

  info "Stage 3: Scoring clip candidates (min_score=$min_score, mode=$scoring_mode)..."

  if [[ ! -f "$CLIP_SCORER" ]]; then
    error "clip-scorer.py not found at $CLIP_SCORER"
    return 1
  fi

  $PY "$CLIP_SCORER" \
    --transcript "$work_dir/transcript.json" \
    --boundaries "$work_dir/boundaries.json" \
    --output "$work_dir/candidates.json" \
    --min-score "$min_score" \
    --min-duration "$min_duration" \
    --max-duration "$max_duration" \
    --scoring-mode "$scoring_mode" \
    2>&1

  if [[ ! -f "$work_dir/candidates.json" ]]; then
    error "Scoring failed — no candidates.json produced"
    return 1
  fi

  local candidate_count
  candidate_count=$($PY -c "import json,sys; print(len(json.load(open(sys.argv[1])).get('candidates',[])))" "$work_dir/candidates.json" 2>/dev/null || echo "0")
  info "Scoring complete: $candidate_count clip candidates"
}

# ==========================================================================
# STAGE 4: EXTRACT — FFmpeg cuts clips at optimal boundaries
# ==========================================================================
stage_extract() {
  local input="$1"
  local work_dir="$2"
  local max_clips="${3:-10}"

  info "Stage 4: Extracting clips..."

  local clip_dir="$work_dir/clips"
  mkdir -p "$clip_dir"

  if [[ ! -f "$work_dir/candidates.json" ]]; then
    error "No candidates.json found. Run 'analyze' first."
    return 1
  fi

  # Extract top N clips
  $PY - "$work_dir/candidates.json" "$clip_dir" "$input" "$max_clips" "$work_dir/clips.json" << 'PYEOF'
import json, subprocess, sys, os

candidates_file = sys.argv[1]
clip_dir = sys.argv[2]
input_file = sys.argv[3]
max_clips = int(sys.argv[4])
manifest_file = sys.argv[5]

candidates = json.load(open(candidates_file))['candidates']

extracted = []
for i, c in enumerate(candidates[:max_clips]):
    rank = i + 1
    score = c['total']
    start = c['start']
    end = c['end']
    duration = round(end - start, 2)
    out_file = os.path.join(clip_dir, f'clip_{rank:02d}_score{score}.mp4')

    # Input seeking (-ss before -i) for speed, -t for duration
    cmd = ['ffmpeg', '-y']
    if start > 0.5:
        cmd.extend(['-ss', str(start)])
    cmd.extend(['-i', input_file, '-t', str(duration)])
    cmd.extend(['-c:v', 'libx264', '-preset', 'fast', '-crf', '23'])
    cmd.extend(['-c:a', 'aac', '-b:a', '128k'])
    if start > 0.5:
        cmd.extend(['-avoid_negative_ts', 'make_start_at_zero'])
    cmd.append(out_file)

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0 and os.path.exists(out_file) and os.path.getsize(out_file) > 0:
        extracted.append({
            'rank': rank,
            'score': score,
            'start': start,
            'end': end,
            'duration': duration,
            'file': out_file,
            'reason': c.get('reason', '')
        })
        print(f'  Clip {rank}: {start:.1f}s-{end:.1f}s (score {score}, {duration:.1f}s)')
    else:
        print(f'  WARN: Clip {rank} extraction failed (returncode={result.returncode})', file=sys.stderr)
        if result.stderr:
            print(f'  FFmpeg: {result.stderr[-200:]}', file=sys.stderr)

# Save extraction manifest
manifest = {'clips': extracted, 'total': len(extracted), 'source': input_file}
with open(manifest_file, 'w') as f:
    json.dump(manifest, f, indent=2)

print(f'Extracted {len(extracted)} clips')
PYEOF

  local clip_count
  clip_count=$($PY -c "import json,sys; print(json.load(open(sys.argv[1])).get('total', 0))" "$work_dir/clips.json" 2>/dev/null || echo "0")
  info "Extraction complete: $clip_count clips in $clip_dir"
}

# ==========================================================================
# GENERATE CLIP METADATA — Write .meta.json sidecar + auto-name/tag/label
# ==========================================================================
_generate_clip_metadata() {
  local work_dir="$1"
  local brand="${2:-}"

  if [[ ! -f "$work_dir/clips.json" ]] || [[ ! -f "$work_dir/candidates.json" ]]; then
    warn "Missing clips.json or candidates.json — skipping metadata generation"
    return 0
  fi

  info "Generating clip metadata sidecars..."

  $PY - "$work_dir" "$brand" << 'PYEOF'
import json, os, sys, uuid
from datetime import datetime, timezone, timedelta

work_dir = sys.argv[1]
brand = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ""

clips = json.load(open(os.path.join(work_dir, 'clips.json'))).get('clips', [])
candidates = json.load(open(os.path.join(work_dir, 'candidates.json'))).get('candidates', [])

# Load source metadata
meta_file = os.path.join(work_dir, 'metadata.json')
source_meta = {}
if os.path.exists(meta_file):
    source_meta = json.load(open(meta_file))

source_path = source_meta.get('input', '')
source_video = os.path.basename(source_path) if source_path else ''

# MYT = UTC+8
myt = timezone(timedelta(hours=8))
created_at = datetime.now(myt).isoformat()

generated = 0
for i, clip in enumerate(clips):
    # Match candidate data (by index — candidates are sorted by score desc, clips follow same order)
    cand = candidates[i] if i < len(candidates) else {}

    score = clip.get('score', cand.get('total', 0))
    start = clip.get('start', cand.get('start', 0))
    end = clip.get('end', cand.get('end', 0))
    duration = round(end - start, 2)
    clip_file = clip.get('file', '')
    transcript = cand.get('text', '')[:500]

    # Semantic tags from scorer
    topic = cand.get('topic', '')
    hook_type = cand.get('hook_type', 'story')
    energy = cand.get('energy', 'medium')
    mood = cand.get('mood', 'casual')
    reuse_as = cand.get('reuse_as', ['highlight'])
    keywords = cand.get('keywords', [])

    # Auto-generate short name from topic
    name_words = [w for w in topic.split() if w][:4]
    name = '-'.join(name_words).lower() if name_words else f'clip-{i+1}'

    # Auto-generate tags from reuse_as + mood + energy
    tags = list(reuse_as)
    if mood and mood not in tags:
        tags.append(mood)
    if energy and energy not in tags:
        tags.append(energy)
    if hook_type and hook_type not in tags:
        tags.append(hook_type)

    # Auto-generate label
    label_parts = []
    if hook_type:
        label_parts.append(hook_type)
    if mood:
        label_parts.append(mood)
    if topic:
        label_parts.append(topic.replace(' ', '-'))
    label = '-'.join(label_parts[:3]).lower() if label_parts else f'clip-{i+1}'

    meta = {
        'id': str(uuid.uuid4()),
        'source_video': source_video,
        'source_path': source_path,
        'clip_file': os.path.basename(clip_file) if clip_file else '',
        'clip_path': clip_file,
        'start': start,
        'end': end,
        'duration': duration,
        'score': score,
        'scores': {
            'hook': cand.get('hook', 0),
            'pacing': cand.get('pacing', 0),
            'emotion': cand.get('emotion', 0),
            'share': cand.get('share', 0),
        },
        'transcript': transcript,
        'name': name,
        'tags': tags,
        'label': label,
        'hook_type': hook_type,
        'energy': energy,
        'mood': mood,
        'reuse_as': reuse_as,
        'keywords': keywords,
        'topic': topic,
        'brand': brand,
        'created_at': created_at,
    }

    # Write sidecar .meta.json next to the clip file
    if clip_file and os.path.exists(clip_file):
        meta_path = clip_file.rsplit('.', 1)[0] + '.meta.json'
        with open(meta_path, 'w') as f:
            json.dump(meta, f, indent=2)
        generated += 1

print(f'Generated {generated} metadata sidecar files')
PYEOF

  info "Metadata sidecars: $($PY -c "
import os, glob
count = len(glob.glob(os.path.join('$work_dir', 'clips', '*.meta.json')))
print(count)
" 2>/dev/null || echo 0) files"
}

# ==========================================================================
# CATALOG CLIPS — Append clip entries to central catalog.jsonl
# ==========================================================================
_catalog_clips() {
  local work_dir="$1"
  local brand="${2:-}"

  local clip_dir="$work_dir/clips"
  if ! ls "$clip_dir"/*.meta.json >/dev/null 2>&1; then
    warn "No .meta.json files found — run metadata generation first"
    return 0
  fi

  mkdir -p "$CLIP_LIBRARY_DIR"

  info "Cataloging clips to $CATALOG_FILE..."

  $PY - "$clip_dir" "$CATALOG_FILE" << 'PYEOF'
import json, os, sys, glob

clip_dir = sys.argv[1]
catalog_file = sys.argv[2]

meta_files = sorted(glob.glob(os.path.join(clip_dir, '*.meta.json')))
if not meta_files:
    print('No metadata files to catalog')
    sys.exit(0)

# Load existing IDs to avoid duplicates (by source_path + start + end)
existing_keys = set()
if os.path.exists(catalog_file):
    with open(catalog_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                key = f"{entry.get('source_path','')}__{entry.get('start',0)}__{entry.get('end',0)}"
                existing_keys.add(key)
            except:
                pass

appended = 0
with open(catalog_file, 'a') as f:
    for mf in meta_files:
        try:
            meta = json.load(open(mf))
            key = f"{meta.get('source_path','')}__{meta.get('start',0)}__{meta.get('end',0)}"
            if key in existing_keys:
                continue
            f.write(json.dumps(meta, separators=(',', ':')) + '\n')
            existing_keys.add(key)
            appended += 1
        except Exception as e:
            print(f'WARN: Failed to catalog {mf}: {e}', file=sys.stderr)

print(f'Cataloged {appended} new clips ({len(existing_keys)} total in catalog)')
PYEOF

  info "Catalog updated: $CATALOG_FILE"
}

# ==========================================================================
# STAGE 5: PRODUCE — VideoForge post-prod per clip
# ==========================================================================
stage_produce() {
  local work_dir="$1"
  local brand="${2:-}"
  local crop_916="${3:-true}"

  info "Stage 5: Producing clips..."

  if [[ ! -f "$work_dir/clips.json" ]]; then
    error "No clips.json found. Run 'extract' first."
    return 1
  fi

  local clip_dir="$work_dir/clips"
  local produced_dir="$work_dir/produced"
  mkdir -p "$produced_dir"

  # Smart crop to 9:16 if enabled
  if [[ "$crop_916" = "true" ]]; then
    info "Applying 9:16 smart crop..."
    local clips
    clips=$($PY -c "import json,sys; [print(c['file']) for c in json.load(open(sys.argv[1]))['clips']]" "$work_dir/clips.json" 2>/dev/null)

    while IFS= read -r clip_file; do
      if [[ -f "$clip_file" ]]; then
        local base_name
        base_name="$(basename "$clip_file")"
        local cropped="$produced_dir/${base_name%.mp4}_916.mp4"

        # Check if video is already portrait (height > width * 1.5) — skip crop if so
        local clip_dims
        clip_dims=$(get_resolution "$clip_file")
        local clip_w clip_h
        clip_w=$(echo "$clip_dims" | cut -d, -f1)
        clip_h=$(echo "$clip_dims" | cut -d, -f2)

        if [[ -n "$clip_w" ]] && [[ -n "$clip_h" ]] && [[ "$clip_h" -gt $((clip_w * 3 / 2)) ]]; then
          info "  Skipping crop for $base_name — already portrait (${clip_w}x${clip_h})"
          cp "$clip_file" "$cropped"
        elif [[ -f "$SMART_CROP" ]]; then
          $PY "$SMART_CROP" --input "$clip_file" --output "$cropped" 2>&1 || {
            warn "Smart crop failed for $base_name, using center crop"
            _center_crop "$clip_file" "$cropped"
          }
        else
          _center_crop "$clip_file" "$cropped"
        fi
      fi
    done <<< "$clips"
  fi

  # Chain to VideoForge for post-production
  if [[ -f "$VIDEO_FORGE" ]] && [[ -n "$brand" ]]; then
    info "Chaining to VideoForge..."
    local clips_to_produce
    if [[ "$crop_916" = "true" ]] && ls "$produced_dir"/*_916.mp4 >/dev/null 2>&1; then
      clips_to_produce=$(ls "$produced_dir"/*_916.mp4 2>/dev/null)
    else
      clips_to_produce=$($PY -c "import json,sys; [print(c['file']) for c in json.load(open(sys.argv[1]))['clips']]" "$work_dir/clips.json" 2>/dev/null)
    fi

    while IFS= read -r clip_file; do
      if [[ -f "$clip_file" ]]; then
        local base_name
        base_name="$(basename "$clip_file")"
        info "  Producing: $base_name"
        bash "$VIDEO_FORGE" produce "$clip_file" --type ugc --brand "$brand" --output "$produced_dir" 2>> "$LOG_FILE" || {
          warn "VideoForge produce failed for $base_name, copying raw clip"
          cp "$clip_file" "$produced_dir/"
        }
      fi
    done <<< "$clips_to_produce"
  else
    # No VideoForge or no brand — copy clips to produced dir
    if [[ "$crop_916" != "true" ]]; then
      cp "$clip_dir"/*.mp4 "$produced_dir/" 2>/dev/null || true
    fi
  fi

  info "Production complete: $(ls "$produced_dir"/*.mp4 2>/dev/null | wc -l | tr -d ' ') clips in $produced_dir"
}

# ==========================================================================
# STAGE 4.5: AUTO-SUBTITLES — Generate SRT + ASS from transcript per clip
# ==========================================================================
stage_subtitles() {
  local work_dir="$1"
  local platform="${2:-tiktok}"

  info "Stage 4.5: Generating subtitles..."

  if [[ ! -f "$work_dir/clips.json" ]]; then
    error "No clips.json found. Run 'extract' first."
    return 1
  fi

  if [[ ! -f "$work_dir/transcript.json" ]]; then
    warn "No transcript.json found — skipping subtitle generation."
    return 0
  fi

  local subs_dir="$work_dir/subtitles"
  mkdir -p "$subs_dir"

  $PY - "$work_dir/transcript.json" "$work_dir/clips.json" "$subs_dir" "$platform" << 'PYEOF'
import json, sys, os

transcript_file = sys.argv[1]
clips_file = sys.argv[2]
subs_dir = sys.argv[3]
platform = sys.argv[4] if len(sys.argv) > 4 else 'tiktok'

with open(transcript_file) as f:
    transcript = json.load(f)

with open(clips_file) as f:
    clips_data = json.load(f)

segments = transcript.get('segments', [])

# Platform-specific vertical position (percentage from top)
SAFE_ZONES = {
    'tiktok': 60,
    'reels': 65,
    'shorts': 75,
    'feed': 82,
}
vert_pct = SAFE_ZONES.get(platform, 65)
# ASS MarginV: approximate pixels from bottom for 1920h video
margin_v = int(1920 * (100 - vert_pct) / 100)

def format_srt_time(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds % 1) * 1000)
    return f'{h:02d}:{m:02d}:{s:02d},{ms:03d}'

def format_ass_time(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    cs = int((seconds % 1) * 100)
    return f'{h:01d}:{m:02d}:{s:02d}.{cs:02d}'

def get_clip_segments(clip_start, clip_end, all_segments):
    """Extract transcript segments that fall within the clip time range."""
    result = []
    for seg in all_segments:
        seg_start = seg.get('start', 0)
        seg_end = seg.get('end', 0)
        # Overlap check
        if seg_end > clip_start and seg_start < clip_end:
            adjusted = dict(seg)
            adjusted['start'] = max(seg_start - clip_start, 0)
            adjusted['end'] = min(seg_end - clip_start, clip_end - clip_start)
            # Adjust word timestamps too
            if 'words' in seg and seg['words']:
                adj_words = []
                for w in seg['words']:
                    ws = w.get('start', 0)
                    we = w.get('end', 0)
                    if we > clip_start and ws < clip_end:
                        adj_words.append({
                            'start': round(max(ws - clip_start, 0), 3),
                            'end': round(min(we - clip_start, clip_end - clip_start), 3),
                            'word': w.get('word', '')
                        })
                adjusted['words'] = adj_words
            result.append(adjusted)
    return result

def generate_srt(clip_segments):
    """Generate SRT content with 2-3 word groups."""
    lines = []
    idx = 1
    for seg in clip_segments:
        words = seg.get('words', [])
        if words:
            # Group into 2-3 word chunks
            group = []
            group_start = None
            for w in words:
                if group_start is None:
                    group_start = w['start']
                group.append(w['word'])
                if len(group) >= 3:
                    lines.append(f"{idx}")
                    lines.append(f"{format_srt_time(group_start)} --> {format_srt_time(w['end'])}")
                    lines.append(' '.join(group))
                    lines.append('')
                    idx += 1
                    group = []
                    group_start = None
            if group and group_start is not None:
                lines.append(f"{idx}")
                lines.append(f"{format_srt_time(group_start)} --> {format_srt_time(words[-1]['end'])}")
                lines.append(' '.join(group))
                lines.append('')
                idx += 1
        else:
            # No word-level timestamps — use segment-level
            lines.append(f"{idx}")
            lines.append(f"{format_srt_time(seg['start'])} --> {format_srt_time(seg['end'])}")
            lines.append(seg.get('text', ''))
            lines.append('')
            idx += 1
    return '\n'.join(lines)

def generate_ass(clip_segments, margin_v_px):
    """Generate ASS with karaoke-style word highlighting."""
    header = f"""[Script Info]
Title: ClipFactory Auto-Subtitles
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,48,&H00FFFFFF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,40,40,{margin_v_px},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    events = []
    for seg in clip_segments:
        words = seg.get('words', [])
        if words:
            # Build karaoke line: group words into 2-3 word subtitle events
            # Each event highlights words as they are spoken using \\kf tags
            group = []
            group_start = None
            prev_end = None
            for w in words:
                if group_start is None:
                    group_start = w['start']
                group.append(w)
                if len(group) >= 3:
                    karaoke_text = ''
                    for gw in group:
                        dur_cs = int((gw['end'] - gw['start']) * 100)
                        karaoke_text += '{\\kf' + str(max(dur_cs, 1)) + '}' + gw['word'] + ' '
                    events.append(
                        f"Dialogue: 0,{format_ass_time(group_start)},{format_ass_time(group[-1]['end'])},Default,,0,0,0,,{karaoke_text.strip()}"
                    )
                    group = []
                    group_start = None
            if group and group_start is not None:
                karaoke_text = ''
                for gw in group:
                    dur_cs = int((gw['end'] - gw['start']) * 100)
                    karaoke_text += '{\\kf' + str(max(dur_cs, 1)) + '}' + gw['word'] + ' '
                events.append(
                    f"Dialogue: 0,{format_ass_time(group_start)},{format_ass_time(group[-1]['end'])},Default,,0,0,0,,{karaoke_text.strip()}"
                )
        else:
            # Segment-level fallback
            events.append(
                f"Dialogue: 0,{format_ass_time(seg['start'])},{format_ass_time(seg['end'])},Default,,0,0,0,,{seg.get('text', '')}"
            )
    return header + '\n'.join(events) + '\n'

# Process each clip
clips = clips_data.get('clips', [])
generated = 0
for clip in clips:
    clip_file = clip.get('file', '')
    clip_start = clip.get('start', 0)
    clip_end = clip.get('end', 0)
    base = os.path.splitext(os.path.basename(clip_file))[0]

    clip_segs = get_clip_segments(clip_start, clip_end, segments)
    if not clip_segs:
        continue

    srt_content = generate_srt(clip_segs)
    ass_content = generate_ass(clip_segs, margin_v)

    with open(os.path.join(subs_dir, f'{base}.srt'), 'w') as f:
        f.write(srt_content)
    with open(os.path.join(subs_dir, f'{base}.ass'), 'w') as f:
        f.write(ass_content)
    generated += 1

print(f'Generated subtitles for {generated}/{len(clips)} clips')
PYEOF

  local sub_count
  sub_count=$(ls "$subs_dir"/*.srt 2>/dev/null | wc -l | tr -d ' ')
  info "Subtitles generated: $sub_count SRT + ASS files in $subs_dir"
}

# --- Helper: center crop to 9:16 ---
_center_crop() {
  local input="$1"
  local output="$2"
  # Get source dimensions
  local dims
  dims=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$input" 2>/dev/null)
  local src_w src_h
  src_w=$(echo "$dims" | cut -d, -f1)
  src_h=$(echo "$dims" | cut -d, -f2)

  if [[ -z "$src_w" ]] || [[ -z "$src_h" ]]; then
    cp "$input" "$output"
    return
  fi

  # Target 9:16 — calculate crop from center
  local target_w target_h
  target_h="$src_h"
  target_w=$((src_h * 9 / 16))

  if [[ "$target_w" -gt "$src_w" ]]; then
    # Source is already narrower than 9:16, pad instead
    target_w="$src_w"
    target_h=$((src_w * 16 / 9))
  fi

  ffmpeg -y -i "$input" \
    -vf "crop=${target_w}:${target_h},scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
    -c:v libx264 -preset fast -crf 23 \
    -c:a aac -b:a 128k \
    "$output" 2>/dev/null
}

# ==========================================================================
# STAGE 6: EXPORT — Multi-platform + seed-store register
# ==========================================================================
stage_export() {
  local work_dir="$1"
  local brand="${2:-}"
  local platforms="${3:-tiktok,reels,shorts,feed}"

  info "Stage 6: Exporting to platforms..."

  local produced_dir="$work_dir/produced"
  local export_dir="$work_dir/export"
  mkdir -p "$export_dir"

  if [[ ! -d "$produced_dir" ]] || ! ls "$produced_dir"/*.mp4 >/dev/null 2>&1; then
    warn "No produced clips found. Checking clips dir..."
    produced_dir="$work_dir/clips"
  fi

  # Check if produced_dir already has platform-prefixed files (from video-forge produce pipeline).
  # If so, move them to export_dir instead of re-exporting (which would double-prefix).
  local has_platform_exports=false
  for pf in "$produced_dir"/tiktok_*.mp4 "$produced_dir"/reels_*.mp4 "$produced_dir"/shorts_*.mp4 "$produced_dir"/feed_*.mp4; do
    if [[ -f "$pf" ]]; then
      has_platform_exports=true
      break
    fi
  done

  if [[ "$has_platform_exports" = "true" ]]; then
    # VideoForge produce already ran cmd_export internally — just move the platform files
    info "  Moving already-exported platform files to export dir..."
    for pf in "$produced_dir"/tiktok_*.mp4 "$produced_dir"/reels_*.mp4 "$produced_dir"/shorts_*.mp4 "$produced_dir"/feed_*.mp4 "$produced_dir"/youtube_*.mp4 "$produced_dir"/shopee_*.mp4; do
      if [[ -f "$pf" ]]; then
        mv "$pf" "$export_dir/" 2>/dev/null || true
      fi
    done
  elif [[ -f "$VIDEO_FORGE" ]]; then
    for clip_file in "$produced_dir"/*.mp4; do
      if [[ -f "$clip_file" ]]; then
        local base_name
        base_name="$(basename "$clip_file")"
        # Skip already-platform-exported files (tiktok_*, reels_*, shorts_*, feed_*)
        case "$base_name" in
          tiktok_*|reels_*|shorts_*|feed_*|youtube_*|shopee_*) continue ;;
        esac
        info "  Exporting: $base_name"
        bash "$VIDEO_FORGE" export "$clip_file" --platforms "$platforms" --output "$export_dir" 2>&1 | tail -2 || {
          warn "Export failed for $base_name, copying as-is"
          cp "$clip_file" "$export_dir/"
        }
      fi
    done
  else
    # No VideoForge — just copy clips to export dir
    cp "$produced_dir"/*.mp4 "$export_dir/" 2>/dev/null || true
  fi

  # Register in seed store with rich metadata from scoring
  if [[ -f "$SEED_STORE" ]] && [[ -n "$brand" ]]; then
    info "Registering clips in seed store with metadata..."
    $PY - "$SEED_STORE" "$work_dir" << 'PYEOF'
import json, subprocess, sys, os

seed_store = sys.argv[1]
work_dir = sys.argv[2]

# Load candidates for metadata
candidates = []
cand_file = os.path.join(work_dir, 'candidates.json')
if os.path.exists(cand_file):
    candidates = json.load(open(cand_file)).get('candidates', [])

# Load clips manifest for file mapping
clips = []
clips_file = os.path.join(work_dir, 'clips.json')
if os.path.exists(clips_file):
    clips = json.load(open(clips_file)).get('clips', [])

# Register each clip with rich tags
for i, c in enumerate(candidates[:len(clips)]):
    tags = ['clip', 'auto-generated', 'clip-factory']
    tags.append(f'score-{c["total"]}')
    tags.append(f'energy-{c.get("energy", "medium")}')
    tags.append(f'mood-{c.get("mood", "casual")}')
    tags.append(f'hook-{c.get("hook_type", "unknown")}')

    for r in c.get('reuse_as', []):
        tags.append(r)
    for kw in c.get('keywords', []):
        tags.append(kw)

    topic = c.get('topic', '')
    reason = c.get('reason', '')
    duration = round(c['end'] - c['start'], 1)
    text = f'[{topic}] {reason} | {duration}s | hook:{c.get("hook",0)}/30 pace:{c.get("pacing",0)}/25 emo:{c.get("emotion",0)}/25 share:{c.get("share",0)}/20 | {c["text"][:150]}'

    tag_str = ','.join(tags)

    cmd = [
        'bash', seed_store, 'add',
        '--type', 'video-clip',
        '--text', text,
        '--tags', tag_str,
        '--source', 'clip-factory',
        '--source-type', 'auto-extract',
        '--channel', 'tiktok,reels,shorts',
        '--status', 'draft',
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            seed_id = result.stdout.strip()
            print(f'  Registered clip {i+1}: {seed_id} [{tag_str[:60]}...]')
    except Exception as e:
        print(f'  WARN: Failed to register clip {i+1}: {e}')
PYEOF
  fi

  # Post to creative room
  local rooms_dir="$HOME/.openclaw/workspace/rooms"
  if [[ -d "$rooms_dir" ]]; then
    local clip_count
    clip_count=$(ls "$export_dir"/*.mp4 2>/dev/null | wc -l | tr -d ' ')
    local top_score
    top_score=$($PY -c "
import json, os, sys
cf = sys.argv[1]
if os.path.exists(cf):
    c = json.load(open(cf)).get('candidates', [])
    print(c[0]['total'] if c else 0)
else:
    print(0)
" "$work_dir/candidates.json" 2>/dev/null || echo "0")
    echo "{\"type\":\"clip-factory\",\"clips\":$clip_count,\"top_score\":$top_score,\"brand\":\"$brand\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$rooms_dir/creative.jsonl" 2>/dev/null || true
  fi

  info "Export complete: $(ls "$export_dir"/*.mp4 2>/dev/null | wc -l | tr -d ' ') clips in $export_dir"
}

# ==========================================================================
# SUBCOMMAND: analyze — Stage 1-3 (transcribe + detect + score)
# ==========================================================================
cmd_analyze() {
  local input=""
  local work_dir=""
  local min_score="60"
  local min_duration="15"
  local max_duration="60"
  local scoring_mode="brand"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        echo "Usage: clip-factory.sh analyze --input <video.mp4> [options]"
        echo ""
        echo "Stages 1-3: transcribe + detect scene boundaries + score for virality."
        echo "Outputs analysis.json with ranked clip candidates (no extraction)."
        echo ""
        echo "Options:"
        echo "  --input <file>       Input video file (required)"
        echo "  --work-dir <dir>     Custom working directory"
        echo "  --min-score <N>      Minimum virality score 0-100 (default: 60)"
        echo "  --min-duration <N>   Minimum clip duration in seconds (default: 15)"
        echo "  --max-duration <N>   Maximum clip duration in seconds (default: 60)"
        echo "  --scoring-mode <m>   'brand' (default, generous) or 'viral' (strict TikTok)"
        exit 0
        ;;
      --input) shift; input="${1:-}" ;;
      --work-dir) shift; work_dir="${1:-}" ;;
      --min-score) shift; min_score="${1:-60}" ;;
      --min-duration) shift; min_duration="${1:-15}" ;;
      --max-duration) shift; max_duration="${1:-60}" ;;
      --scoring-mode) shift; scoring_mode="${1:-brand}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$input" ]]; then
    error "Usage: clip-factory.sh analyze --input <video.mp4>"
    exit 1
  fi

  if [[ ! -f "$input" ]]; then
    error "Input file not found: $input"
    exit 1
  fi

  # Resolve work dir — sanitize name (spaces break ffmpeg filter paths)
  if [[ -z "$work_dir" ]]; then
    local base_name
    base_name="$(basename_no_ext "$input")"
    # Replace spaces/special chars with hyphens, collapse multiples
    base_name=$(echo "$base_name" | sed 's/[^a-zA-Z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//')
    work_dir="$(cd "$(dirname "$input")" && pwd)/clip-factory-${base_name}-$(date +%Y%m%d-%H%M%S)"
  fi
  mkdir -p "$work_dir"

  local duration
  duration=$(get_duration "$input")
  local resolution
  resolution=$(get_resolution "$input")
  info "Input: $(basename "$input") (${duration}s, $resolution)"
  info "Work dir: $work_dir"

  # Short video guard: warn if < 120s, suggest video-forge.sh directly
  if [[ -n "$duration" ]] && [[ "$duration" -lt 120 ]]; then
    warn "Input video is only ${duration}s (< 120s). ClipForge works best with longer videos."
    warn "For short videos, consider using video-forge.sh directly:"
    warn "  bash video-forge.sh produce \"$input\" --type ugc --brand <brand>"
    if [[ "$duration" -lt 30 ]]; then
      error "Input video is too short (${duration}s < 30s) for clip extraction. Use video-forge.sh directly."
      return 1
    fi
  fi

  # Save metadata — resolve absolute input path
  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local created
  created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  $PY - "$abs_input" "$duration" "$resolution" "$min_score" "$min_duration" "$max_duration" "$created" "$work_dir/metadata.json" << 'PYEOF'
import json, sys

meta = {
    'input': sys.argv[1],
    'duration': int(sys.argv[2]) if sys.argv[2] else 0,
    'resolution': sys.argv[3],
    'min_score': int(sys.argv[4]),
    'min_duration': int(sys.argv[5]),
    'max_duration': int(sys.argv[6]),
    'created': sys.argv[7]
}
with open(sys.argv[8], 'w') as f:
    json.dump(meta, f, indent=2)
PYEOF

  # Run stages 1-3
  stage_transcribe "$input" "$work_dir"
  stage_detect "$input" "$work_dir"
  stage_score "$work_dir" "$min_score" "$min_duration" "$max_duration" "$scoring_mode"

  # Summary
  local candidate_count
  candidate_count=$($PY -c "import json,sys; print(len(json.load(open(sys.argv[1])).get('candidates',[])))" "$work_dir/candidates.json" 2>/dev/null || echo "0")
  info "Analysis complete: $candidate_count clip candidates"
  info "Results in: $work_dir"
  echo "$work_dir"
}

# ==========================================================================
# SUBCOMMAND: extract — Stage 4
# ==========================================================================
cmd_extract() {
  local input=""
  local work_dir=""
  local max_clips="10"

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        echo "Usage: clip-factory.sh extract --work-dir <dir> [options]"
        echo ""
        echo "Stage 4: Cut clips from analysis results into individual .mp4 files."
        echo "Requires a work-dir from a previous 'analyze' run."
        echo ""
        echo "Options:"
        echo "  --work-dir <dir>     Work directory from 'analyze' (required)"
        echo "  --input <file>       Input video file (auto-detected from metadata)"
        echo "  --max-clips <N>      Maximum clips to extract (default: 10)"
        exit 0
        ;;
      --input) shift; input="${1:-}" ;;
      --work-dir) shift; work_dir="${1:-}" ;;
      --max-clips) shift; max_clips="${1:-10}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$work_dir" ]]; then
    error "Usage: clip-factory.sh extract --work-dir <dir> [--max-clips N]"
    exit 1
  fi

  # Resolve input from metadata if not specified
  if [[ -z "$input" ]] && [[ -f "$work_dir/metadata.json" ]]; then
    input=$(json_field "$work_dir/metadata.json" "input")
  fi

  if [[ -z "$input" ]] || [[ ! -f "$input" ]]; then
    error "Input video not found. Specify --input or ensure metadata.json has valid path."
    exit 1
  fi

  stage_extract "$input" "$work_dir" "$max_clips"

  # Generate metadata sidecars + catalog
  _generate_clip_metadata "$work_dir" ""
  _catalog_clips "$work_dir" ""
}

# ==========================================================================
# SUBCOMMAND: produce — Stage 5-6
# ==========================================================================
cmd_produce() {
  local work_dir=""
  local brand=""
  local crop_916="true"
  local gen_subs="true"
  local platforms="tiktok,reels,shorts,feed"

  while [ $# -gt 0 ]; do
    case "$1" in
      --work-dir) shift; work_dir="${1:-}" ;;
      --brand) shift; brand="${1:-}" ;;
      --no-crop) crop_916="false" ;;
      --no-subs) gen_subs="false" ;;
      --platforms) shift; platforms="${1:-tiktok,reels,shorts,feed}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$work_dir" ]]; then
    error "Usage: clip-factory.sh produce --work-dir <dir> [--brand <brand>]"
    exit 1
  fi

  # Stage 4.5: Auto-subtitles (before produce so ASS files are available for burning)
  if [[ "$gen_subs" = "true" ]]; then
    local sub_platform
    sub_platform=$(echo "$platforms" | cut -d, -f1)
    stage_subtitles "$work_dir" "$sub_platform"
  fi

  stage_produce "$work_dir" "$brand" "$crop_916"
  stage_export "$work_dir" "$brand" "$platforms"
}

# ==========================================================================
# SUBCOMMAND: run — Full pipeline (analyze + extract + produce)
# ==========================================================================
cmd_run() {
  local input=""
  local brand=""
  local min_score="60"
  local min_duration="15"
  local max_duration="60"
  local max_clips="10"
  local crop_916="true"
  local gen_subs="true"
  local platforms="tiktok,reels,shorts,feed"
  local work_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h)
        echo "Usage: clip-factory.sh run --input <video.mp4> [--brand <brand>] [options]"
        echo ""
        echo "Full 6-stage pipeline: transcribe -> detect -> score -> extract -> subtitles -> produce -> export."
        echo ""
        echo "Options:"
        echo "  --input <file>       Input video file (required)"
        echo "  --brand <brand>      Brand name for VideoForge branding + seed-store"
        echo "  --min-score <N>      Minimum virality score 0-100 (default: 60)"
        echo "  --min-duration <N>   Minimum clip duration in seconds (default: 15)"
        echo "  --max-duration <N>   Maximum clip duration in seconds (default: 60)"
        echo "  --max-clips <N>      Maximum clips to extract (default: 10)"
        echo "  --no-crop            Skip 9:16 smart crop"
        echo "  --no-subs            Skip auto-subtitle generation"
        echo "  --platforms <list>   Export platforms, comma-separated (default: tiktok,reels,shorts,feed)"
        echo "  --work-dir <dir>     Custom working directory"
        exit 0
        ;;
      --input) shift; input="${1:-}" ;;
      --brand) shift; brand="${1:-}" ;;
      --min-score) shift; min_score="${1:-60}" ;;
      --min-duration) shift; min_duration="${1:-15}" ;;
      --max-duration) shift; max_duration="${1:-60}" ;;
      --max-clips) shift; max_clips="${1:-10}" ;;
      --no-crop) crop_916="false" ;;
      --no-subs) gen_subs="false" ;;
      --platforms) shift; platforms="${1:-tiktok,reels,shorts,feed}" ;;
      --work-dir) shift; work_dir="${1:-}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$input" ]]; then
    error "Usage: clip-factory.sh run --input <video.mp4> [--brand <brand>] [options]"
    exit 1
  fi

  if [[ ! -f "$input" ]]; then
    error "Input file not found: $input"
    exit 1
  fi

  info "=== CLIP FACTORY: Full Pipeline ==="
  local start_time
  start_time=$(date +%s)

  # Stage 1-3: Analyze (last line of stdout is the work dir path)
  work_dir=$(cmd_analyze --input "$input" --work-dir "$work_dir" --min-score "$min_score" --min-duration "$min_duration" --max-duration "$max_duration" | tail -1)

  # Check if we have candidates
  local candidate_count
  candidate_count=$($PY -c "import json,sys; print(len(json.load(open(sys.argv[1])).get('candidates',[])))" "$work_dir/candidates.json" 2>/dev/null || echo "0")
  if [[ "$candidate_count" -eq 0 ]]; then
    warn "No clip candidates found above score threshold ($min_score). Try lowering --min-score."
    return 0
  fi

  # Stage 4: Extract
  stage_extract "$input" "$work_dir" "$max_clips"

  # Generate metadata sidecars + catalog
  _generate_clip_metadata "$work_dir" "$brand"
  _catalog_clips "$work_dir" "$brand"

  # Stage 4.5: Auto-subtitles (before produce so ASS files are available for burning)
  if [[ "$gen_subs" = "true" ]]; then
    local sub_platform
    sub_platform=$(echo "$platforms" | cut -d, -f1)
    stage_subtitles "$work_dir" "$sub_platform"
  fi

  # Stage 5-6: Produce + Export
  stage_produce "$work_dir" "$brand" "$crop_916"
  stage_export "$work_dir" "$brand" "$platforms"

  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - start_time))

  info "=== CLIP FACTORY: Complete ==="
  info "Time: $(format_time $elapsed)"
  info "Clips: $(ls "$work_dir/clips"/*.mp4 2>/dev/null | wc -l | tr -d ' ') extracted"
  info "Output: $work_dir"

  # Print summary
  echo ""
  echo "=== CLIP FACTORY RESULTS ==="
  echo "Input: $(basename "$input")"
  echo "Work dir: $work_dir"
  echo ""
  _print_clips "$work_dir"
}

# ==========================================================================
# SUBCOMMAND: list — Show clips from a previous run
# ==========================================================================
cmd_list() {
  local work_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --work-dir) shift; work_dir="${1:-}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$work_dir" ]]; then
    # Find most recent clip-factory run
    work_dir=$(ls -dt /tmp/clip-factory-* "$HOME"/.openclaw/workspace/data/videos/clip-factory-* 2>/dev/null | head -1)
    if [[ -z "$work_dir" ]]; then
      error "No work dir found. Specify --work-dir."
      exit 1
    fi
  fi

  _print_clips "$work_dir"
}

# --- Helper: print clips table ---
_print_clips() {
  local work_dir="$1"

  if [[ ! -f "$work_dir/candidates.json" ]]; then
    echo "No clips found in $work_dir"
    return
  fi

  $PY - "$work_dir" << 'PYEOF'
import json, os, sys

work_dir = sys.argv[1]
candidates = json.load(open(os.path.join(work_dir, 'candidates.json'))).get('candidates', [])

print(f'Found {len(candidates)} clip candidates:')
print(f'{"Rank":>4}  {"Score":>5}  {"Start":>8}  {"End":>8}  {"Duration":>8}  Reason')
print('-' * 70)

for i, c in enumerate(candidates):
    rank = i + 1
    score = c['total']
    start = c['start']
    end = c['end']
    dur = end - start

    def fmt(s):
        m, sec = divmod(int(s), 60)
        h, m = divmod(m, 60)
        return f'{h:02d}:{m:02d}:{sec:02d}'

    clip_file = os.path.join(work_dir, 'clips', f'clip_{rank:02d}_score{score}.mp4')
    marker = '*' if os.path.exists(clip_file) else ' '

    reason = c.get('reason', '')[:35]
    print(f'{marker}{rank:>3}  {score:>5}  {fmt(start):>8}  {fmt(end):>8}  {dur:>7.1f}s  {reason}')

print()
print('* = extracted clip file exists')
PYEOF
}

# ==========================================================================
# SUBCOMMAND: preview — Quick analysis, show top N without extracting
# ==========================================================================
cmd_preview() {
  local input=""
  local top="5"
  local min_score="50"
  local min_duration="15"
  local max_duration="60"

  while [ $# -gt 0 ]; do
    case "$1" in
      --input) shift; input="${1:-}" ;;
      --top) shift; top="${1:-5}" ;;
      --min-score) shift; min_score="${1:-50}" ;;
      --min-duration) shift; min_duration="${1:-15}" ;;
      --max-duration) shift; max_duration="${1:-60}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$input" ]]; then
    error "Usage: clip-factory.sh preview --input <video.mp4> [--top N]"
    exit 1
  fi

  if [[ ! -f "$input" ]]; then
    error "Input file not found: $input"
    exit 1
  fi

  info "=== CLIP FACTORY: Preview Mode ==="

  # Use temp work dir
  local work_dir="/tmp/clip-factory-preview-$$"
  mkdir -p "$work_dir"

  local duration
  duration=$(get_duration "$input")
  info "Input: $(basename "$input") (${duration}s)"

  # Run stages 1-3 only
  stage_transcribe "$input" "$work_dir"
  stage_detect "$input" "$work_dir"
  stage_score "$work_dir" "$min_score" "$min_duration" "$max_duration"

  # Show top N
  echo ""
  echo "=== TOP $top CLIP CANDIDATES ==="
  $PY - "$work_dir" "$top" << 'PYEOF'
import json, sys, os

work_dir = sys.argv[1]
top = int(sys.argv[2])

candidates = json.load(open(os.path.join(work_dir, 'candidates.json'))).get('candidates', [])

for i, c in enumerate(candidates[:top]):
    rank = i + 1
    score = c['total']
    start = c['start']
    end = c['end']
    dur = end - start

    def fmt(s):
        m, sec = divmod(int(s), 60)
        h, m = divmod(m, 60)
        return f'{h:02d}:{m:02d}:{sec:02d}'

    print(f'')
    print(f'Clip {rank} -- Score: {score}/100')
    print(f'  Time: {fmt(start)} -> {fmt(end)} ({dur:.1f}s)')
    print(f'  Hook: {c.get("hook", 0)}/30 | Pacing: {c.get("pacing", 0)}/25 | Emotion: {c.get("emotion", 0)}/25 | Share: {c.get("share", 0)}/20')
    print(f'  Reason: {c.get("reason", "")}')
    print(f'  Text: {c.get("text", "")[:120]}...')
PYEOF

  echo ""
  info "To extract these clips: clip-factory.sh extract --work-dir $work_dir --max-clips $top"

  # Cleanup preview dir on exit
  rm -rf "$work_dir"
}

# ==========================================================================
# SUBCOMMAND: batch — Process multiple input videos
# ==========================================================================
cmd_batch() {
  local file=""
  local brand=""
  local min_score="60"
  local max_clips="10"
  local output_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --file) shift; file="${1:-}" ;;
      --brand) shift; brand="${1:-}" ;;
      --min-score) shift; min_score="${1:-60}" ;;
      --max-clips) shift; max_clips="${1:-10}" ;;
      --output) shift; output_dir="${1:-}" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$file" ]]; then
    error "Usage: clip-factory.sh batch --file <list.txt> [--brand <brand>]"
    error "File should contain one video path per line."
    exit 1
  fi

  if [[ ! -f "$file" ]]; then
    error "File not found: $file"
    exit 1
  fi

  info "=== CLIP FACTORY: Batch Mode ==="

  local total=0
  local success=0
  local failed=0

  while IFS= read -r video_path || [[ -n "$video_path" ]]; do
    # Skip empty lines and comments
    if [[ -z "$video_path" ]] || [[ "$video_path" = \#* ]]; then
      continue
    fi

    # Trim whitespace
    video_path=$(echo "$video_path" | tr -d '[:space:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ ! -f "$video_path" ]]; then
      warn "Skipping (not found): $video_path"
      failed=$((failed + 1))
      total=$((total + 1))
      continue
    fi

    total=$((total + 1))
    info "--- Processing $total: $(basename "$video_path") ---"

    local run_args="--input $video_path --min-score $min_score --max-clips $max_clips"
    if [[ -n "$brand" ]]; then
      run_args="$run_args --brand $brand"
    fi
    if [[ -n "$output_dir" ]]; then
      local base_name
      base_name="$(basename_no_ext "$video_path")"
      run_args="$run_args --work-dir $output_dir/clip-factory-${base_name}"
    fi

    # Run pipeline (capture errors but continue)
    if eval "cmd_run $run_args" 2>&1; then
      success=$((success + 1))
    else
      warn "Pipeline failed for: $(basename "$video_path")"
      failed=$((failed + 1))
    fi

  done < "$file"

  info "=== BATCH COMPLETE ==="
  info "Processed: $total | Success: $success | Failed: $failed"
}

# ==========================================================================
# SUBCOMMAND: catalog — Generate metadata + register clips in catalog.jsonl
# ==========================================================================
cmd_catalog() {
  local work_dir=""
  local brand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: clip-factory.sh catalog --work-dir <dir> [--brand <brand>]"
        echo ""
        echo "Generate .meta.json sidecar files for extracted clips and register"
        echo "them in the central catalog at $CATALOG_FILE"
        echo ""
        echo "Options:"
        echo "  --work-dir <dir>     Work directory from a previous extract/run (required)"
        echo "  --brand <brand>      Brand to tag clips with"
        exit 0
        ;;
      --work-dir) shift; work_dir="${1:-}" ;;
      --brand)    shift; brand="${1:-}" ;;
      *)          warn "Unknown option: $1" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$work_dir" ]]; then
    error "Usage: clip-factory.sh catalog --work-dir <dir> [--brand <brand>]"
    exit 1
  fi

  if [[ ! -d "$work_dir" ]]; then
    error "Work directory not found: $work_dir"
    exit 1
  fi

  info "=== CATALOG: Generating metadata + registering clips ==="

  _generate_clip_metadata "$work_dir" "$brand"
  _catalog_clips "$work_dir" "$brand"

  # Show catalog stats
  if [[ -f "$CATALOG_FILE" ]]; then
    local total
    total=$(wc -l < "$CATALOG_FILE" | tr -d ' ')
    info "Catalog total: $total clips in $CATALOG_FILE"
  fi
}

# ==========================================================================
# SUBCOMMAND: blocks — Extract reusable video blocks (b-roll/compilation)
# ==========================================================================
cmd_blocks() {
  local input=""
  local brand=""
  local min_score="30"
  local min_duration="5"
  local max_duration="15"
  local max_clips="20"
  local work_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: clip-factory.sh blocks --input <video.mp4> [--brand <brand>] [options]"
        echo ""
        echo "Extract short reusable video blocks (b-roll, compilation clips)."
        echo "Optimized for building a clip LIBRARY — lower score threshold, shorter clips."
        echo ""
        echo "Defaults differ from 'run':"
        echo "  --min-score    30 (vs 60)   — more permissive"
        echo "  --min-duration  5 (vs 15)   — shorter blocks"
        echo "  --max-duration 15 (vs 60)   — cap at 15s"
        echo "  --max-clips    20 (vs 10)   — more blocks per video"
        echo ""
        echo "Options:"
        echo "  --input <file>       Input video file (required)"
        echo "  --brand <brand>      Brand name for tagging"
        echo "  --min-score <N>      Minimum score 0-100 (default: 30)"
        echo "  --min-duration <N>   Minimum block duration in seconds (default: 5)"
        echo "  --max-duration <N>   Maximum block duration in seconds (default: 15)"
        echo "  --max-clips <N>      Maximum blocks to extract (default: 20)"
        echo "  --work-dir <dir>     Custom working directory"
        exit 0
        ;;
      --input)        shift; input="${1:-}" ;;
      --brand)        shift; brand="${1:-}" ;;
      --min-score)    shift; min_score="${1:-30}" ;;
      --min-duration) shift; min_duration="${1:-5}" ;;
      --max-duration) shift; max_duration="${1:-15}" ;;
      --max-clips)    shift; max_clips="${1:-20}" ;;
      --work-dir)     shift; work_dir="${1:-}" ;;
      *)              warn "Unknown option: $1" ;;
    esac
    shift 2>/dev/null || true
  done

  if [[ -z "$input" ]]; then
    error "Usage: clip-factory.sh blocks --input <video.mp4> [--brand <brand>]"
    exit 1
  fi

  if [[ ! -f "$input" ]]; then
    error "Input file not found: $input"
    exit 1
  fi

  info "=== CLIP FACTORY: Blocks Mode (library builder) ==="
  info "Settings: score>=$min_score, duration=${min_duration}-${max_duration}s, max=$max_clips blocks"
  local start_time
  start_time=$(date +%s)

  # Resolve work dir
  if [[ -z "$work_dir" ]]; then
    local base_name
    base_name="$(basename_no_ext "$input")"
    work_dir="$(cd "$(dirname "$input")" && pwd)/clip-factory-blocks-${base_name}-$(date +%Y%m%d-%H%M%S)"
  fi

  # Stage 1-3: Analyze with blocks parameters
  work_dir=$(cmd_analyze --input "$input" --work-dir "$work_dir" --min-score "$min_score" --min-duration "$min_duration" --max-duration "$max_duration" | tail -1)

  # Check if we have candidates
  local candidate_count
  candidate_count=$($PY -c "import json,sys; print(len(json.load(open(sys.argv[1])).get('candidates',[])))" "$work_dir/candidates.json" 2>/dev/null || echo "0")
  if [[ "$candidate_count" -eq 0 ]]; then
    warn "No block candidates found above score threshold ($min_score)."
    return 0
  fi

  info "Found $candidate_count block candidates"

  # Stage 4: Extract (more clips, no produce/export — library only)
  stage_extract "$input" "$work_dir" "$max_clips"

  # Enrich reuse_as with "broll" for all blocks
  $PY - "$work_dir" << 'PYEOF'
import json, os, sys

work_dir = sys.argv[1]
cand_file = os.path.join(work_dir, 'candidates.json')
if not os.path.exists(cand_file):
    sys.exit(0)

data = json.load(open(cand_file))
for c in data.get('candidates', []):
    reuse = c.get('reuse_as', [])
    if 'broll' not in reuse:
        reuse.append('broll')
    c['reuse_as'] = reuse

with open(cand_file, 'w') as f:
    json.dump(data, f, indent=2)
print(f'Enriched {len(data.get("candidates",[]))} candidates with broll tag')
PYEOF

  # Generate metadata + catalog
  _generate_clip_metadata "$work_dir" "$brand"
  _catalog_clips "$work_dir" "$brand"

  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - start_time))

  local clip_count
  clip_count=$(ls "$work_dir/clips"/*.mp4 2>/dev/null | wc -l | tr -d ' ')

  info "=== BLOCKS COMPLETE ==="
  info "Time: $(format_time $elapsed)"
  info "Blocks: $clip_count extracted"
  info "Output: $work_dir/clips/"
  info "Catalog: $CATALOG_FILE"

  echo ""
  echo "=== VIDEO BLOCKS RESULTS ==="
  echo "Input: $(basename "$input")"
  echo "Blocks: $clip_count"
  echo "Work dir: $work_dir"
  echo ""
  _print_clips "$work_dir"
}

# ==========================================================================
# cmd_find — Search catalog.jsonl for clips by semantic tags
# ==========================================================================
cmd_find() {
  local brand=""
  local mood=""
  local energy=""
  local hook_type=""
  local reuse_as=""
  local keyword=""
  local min_score=""
  local top_n="10"
  local output_format="table"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        echo "Usage: clip-factory.sh find [--brand <b>] [--mood <m>] [options]"
        echo ""
        echo "Search the clip catalog ($CATALOG_FILE) with filters."
        echo ""
        echo "Options:"
        echo "  --brand <brand>      Filter by brand"
        echo "  --mood <mood>        Filter: inspiring|funny|educational|emotional|dramatic|calm|urgent|casual"
        echo "  --energy <e>         Filter: low|medium|high"
        echo "  --hook-type <h>      Filter: question|shock|reveal|story|tip|testimonial|reaction|statistic|challenge"
        echo "  --reuse-as <tag>     Filter: intro|hook|explainer|testimonial|cta|reaction|story|tip|broll|highlight"
        echo "  --keyword <word>     Search in keywords, transcript, tags, and topic"
        echo "  --min-score <N>      Minimum score"
        echo "  --top <N>            Max results (default: 10)"
        echo "  --json               Output as JSON (for piping to compose)"
        exit 0
        ;;
      --brand)     brand="$2"; shift 2 ;;
      --mood)      mood="$2"; shift 2 ;;
      --energy)    energy="$2"; shift 2 ;;
      --hook-type) hook_type="$2"; shift 2 ;;
      --reuse-as)  reuse_as="$2"; shift 2 ;;
      --keyword)   keyword="$2"; shift 2 ;;
      --min-score) min_score="$2"; shift 2 ;;
      --top)       top_n="$2"; shift 2 ;;
      --json)      output_format="json"; shift ;;
      *)           warn "Unknown option: $1"; shift ;;
    esac
  done

  # Search catalog.jsonl (primary source)
  if [[ -f "$CATALOG_FILE" ]]; then
    info "Searching clip catalog ($CATALOG_FILE)..."

    $PY - "$CATALOG_FILE" "$brand" "$mood" "$energy" "$hook_type" "$reuse_as" "$keyword" "$min_score" "$top_n" "$output_format" << 'PYEOF'
import json, sys, os

catalog_file = sys.argv[1]
brand = sys.argv[2]
mood = sys.argv[3]
energy = sys.argv[4]
hook_type = sys.argv[5]
reuse_as = sys.argv[6]
keyword = sys.argv[7]
min_score_str = sys.argv[8]
top_n = int(sys.argv[9])
output_format = sys.argv[10]

min_score = int(min_score_str) if min_score_str else 0

# Load all catalog entries
clips = []
with open(catalog_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except:
            continue

        # Apply filters
        if brand and entry.get('brand', '').lower() != brand.lower():
            continue
        if mood and entry.get('mood', '').lower() != mood.lower():
            continue
        if energy and entry.get('energy', '').lower() != energy.lower():
            continue
        if hook_type and entry.get('hook_type', '').lower() != hook_type.lower():
            continue
        if reuse_as and reuse_as.lower() not in [r.lower() for r in entry.get('reuse_as', [])]:
            continue
        if keyword:
            kw_lower = keyword.lower()
            searchable = ' '.join([
                ' '.join(entry.get('keywords', [])),
                entry.get('transcript', ''),
                ' '.join(entry.get('tags', [])),
                entry.get('topic', ''),
                entry.get('name', ''),
                entry.get('label', ''),
            ]).lower()
            if kw_lower not in searchable:
                continue
        if min_score and entry.get('score', 0) < min_score:
            continue

        clips.append(entry)

# Sort by score descending
clips.sort(key=lambda c: c.get('score', 0), reverse=True)
clips = clips[:top_n]

if output_format == 'json':
    print(json.dumps(clips, indent=2))
else:
    if not clips:
        print('No clips found matching criteria.')
        sys.exit(0)

    total_in_catalog = sum(1 for _ in open(catalog_file) if _.strip())
    print(f'Found {len(clips)} clips (catalog: {total_in_catalog} total):')
    print(f'{"#":<4} {"Score":<6} {"Dur":<6} {"Energy":<8} {"Mood":<12} {"Hook":<12} {"Reuse":<20} {"Topic":<25}')
    print('-' * 95)
    for i, c in enumerate(clips):
        score = c.get('score', 0)
        dur = c.get('duration', 0)
        en = c.get('energy', '?')
        mo = c.get('mood', '?')
        hk = c.get('hook_type', '?')
        reuse = ','.join(c.get('reuse_as', []))[:18]
        topic = c.get('topic', '')[:23]
        print(f'{i+1:<4} {score:<6} {dur:<5.1f}s {en:<8} {mo:<12} {hk:<12} {reuse:<20} {topic:<25}')
    print()
    print(f'Use --json for full data. Pipe to clip-factory.sh compose for assembly.')
PYEOF

  else
    # Fallback: search seed-store if no catalog exists yet
    if [[ -f "$SEED_STORE" ]]; then
      info "No catalog found. Falling back to seed-store search..."
      info "Tip: Run 'clip-factory.sh catalog --work-dir <dir>' to populate the catalog."

      $PY - "$SEED_STORE" "$brand" "$mood" "$energy" "$hook_type" "$reuse_as" "$keyword" "$min_score" "$top_n" "$output_format" << 'PYEOF'
import json, subprocess, sys, os

seed_store = sys.argv[1]
brand = sys.argv[2]
mood = sys.argv[3]
energy = sys.argv[4]
hook_type = sys.argv[5]
reuse_as = sys.argv[6]
keyword = sys.argv[7]
min_score = sys.argv[8]
top_n = int(sys.argv[9])
output_format = sys.argv[10]

cmd = ['bash', seed_store, 'query', '--type', 'video-clip', '--top', str(top_n * 3)]
if brand:
    cmd.extend(['--source', 'clip-factory'])

result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
if result.returncode != 0:
    print(f'Query failed: {result.stderr}', file=sys.stderr)
    sys.exit(1)

clips = []
for line in result.stdout.strip().split('\n'):
    if not line.strip():
        continue
    try:
        seed = json.loads(line)
    except:
        continue

    tags = seed.get('tags', [])
    if isinstance(tags, str):
        tags = [t.strip() for t in tags.split(',')]

    if brand and not any(brand.lower() in t.lower() for t in tags + [seed.get('text', '')]):
        continue
    if mood and not any(f'mood-{mood}' == t for t in tags):
        continue
    if energy and not any(f'energy-{energy}' == t for t in tags):
        continue
    if hook_type and not any(f'hook-{hook_type}' == t for t in tags):
        continue
    if reuse_as and not any(reuse_as == t for t in tags):
        continue
    if keyword and not any(keyword.lower() in t.lower() for t in tags + [seed.get('text', '')]):
        continue
    if min_score:
        score_tags = [t for t in tags if t.startswith('score-')]
        if score_tags:
            sc = int(score_tags[0].split('-')[1])
            if sc < int(min_score):
                continue

    clips.append(seed)

def get_score(s):
    tags = s.get('tags', [])
    if isinstance(tags, str):
        tags = [t.strip() for t in tags.split(',')]
    for t in tags:
        if t.startswith('score-'):
            try:
                return int(t.split('-')[1])
            except:
                pass
    return 0

clips.sort(key=get_score, reverse=True)
clips = clips[:top_n]

if output_format == 'json':
    print(json.dumps(clips, indent=2))
else:
    if not clips:
        print('No clips found matching criteria.')
        sys.exit(0)
    print(f'Found {len(clips)} clips (from seed-store):')
    print(f'{"Rank":<5} {"Score":<7} {"Energy":<9} {"Mood":<12} {"Hook":<14} {"Topic":<30}')
    print('-' * 80)
    for i, c in enumerate(clips):
        tags = c.get('tags', [])
        if isinstance(tags, str):
            tags = [t.strip() for t in tags.split(',')]
        score = get_score(c)
        en = next((t.replace('energy-','') for t in tags if t.startswith('energy-')), '?')
        mo = next((t.replace('mood-','') for t in tags if t.startswith('mood-')), '?')
        hk = next((t.replace('hook-','') for t in tags if t.startswith('hook-')), '?')
        text = c.get('text', '')
        topic = ''
        if text.startswith('['):
            topic = text[1:text.find(']')] if ']' in text else text[:30]
        else:
            topic = text[:30]
        print(f'{i+1:<5} {score:<7} {en:<9} {mo:<12} {hk:<14} {topic:<30}')
    print()
    print(f'Use --json for full data. Pipe to clip-factory.sh compose for assembly.')
PYEOF

    else
      error "No catalog ($CATALOG_FILE) and no seed-store found."
      error "Run 'clip-factory.sh run' or 'clip-factory.sh blocks' to create clips first."
      exit 1
    fi
  fi
}

# ==========================================================================
# cmd_compose — Query clips + assemble into new video
# ==========================================================================
cmd_compose() {
  local brand=""
  local mood=""
  local energy=""
  local hook_type=""
  local reuse_as=""
  local keyword=""
  local min_score="60"
  local max_clips="5"
  local transition="crossfade"
  local transition_dur="0.5"
  local output_dir=""
  local title=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brand)          brand="$2"; shift 2 ;;
      --mood)           mood="$2"; shift 2 ;;
      --energy)         energy="$2"; shift 2 ;;
      --hook-type)      hook_type="$2"; shift 2 ;;
      --reuse-as)       reuse_as="$2"; shift 2 ;;
      --keyword)        keyword="$2"; shift 2 ;;
      --min-score)      min_score="$2"; shift 2 ;;
      --max-clips)      max_clips="$2"; shift 2 ;;
      --transition)     transition="$2"; shift 2 ;;
      --transition-dur) transition_dur="$2"; shift 2 ;;
      --output)         output_dir="$2"; shift 2 ;;
      --title)          title="$2"; shift 2 ;;
      *)                warn "Unknown option: $1"; shift ;;
    esac
  done

  if [[ ! -f "$SEED_STORE" ]]; then
    error "seed-store.sh not found at $SEED_STORE"
    exit 1
  fi

  # Default output directory
  if [[ -z "$output_dir" ]]; then
    output_dir="$HOME/.openclaw/workspace/data/videos/composed/compose-$(date +%Y%m%d-%H%M%S)"
  fi
  mkdir -p "$output_dir"

  info "=== COMPOSE: Building video from clip library ==="

  # Step 1: Find matching clips
  info "Step 1: Finding matching clips..."
  local find_args="--top $((max_clips * 2)) --json"
  if [[ -n "$brand" ]]; then find_args="$find_args --brand $brand"; fi
  if [[ -n "$mood" ]]; then find_args="$find_args --mood $mood"; fi
  if [[ -n "$energy" ]]; then find_args="$find_args --energy $energy"; fi
  if [[ -n "$hook_type" ]]; then find_args="$find_args --hook-type $hook_type"; fi
  if [[ -n "$reuse_as" ]]; then find_args="$find_args --reuse-as $reuse_as"; fi
  if [[ -n "$keyword" ]]; then find_args="$find_args --keyword $keyword"; fi
  if [[ -n "$min_score" ]]; then find_args="$find_args --min-score $min_score"; fi

  local found_json
  found_json=$(eval "cmd_find $find_args" 2>/dev/null) || {
    error "No clips found matching criteria"
    exit 1
  }

  if [[ -z "$found_json" ]] || [[ "$found_json" = "[]" ]]; then
    error "No clips found matching criteria"
    exit 1
  fi

  # Step 2: Resolve file paths from seeds and pick top N
  info "Step 2: Resolving clip files..."
  local tmp_json="/tmp/clip-factory-compose-$$.json"
  echo "$found_json" > "$tmp_json"
  local clip_files
  clip_files=$($PY - "$tmp_json" "$max_clips" << 'PYEOF'
import json, sys, os, glob

clips = json.load(open(sys.argv[1]))
max_clips = int(sys.argv[2])

resolved = []
data_dir = os.path.expanduser('~/.openclaw/workspace/data')

for c in clips[:max_clips]:
    text = c.get('text', '')
    seed_id = c.get('id', '')
    file_path = None

    # Search recent clip-factory work dirs
    work_dirs = glob.glob(os.path.join(data_dir, 'clip-factory-*', 'export', '*.mp4'))
    work_dirs += glob.glob(os.path.join(data_dir, 'clip-factory-*', 'produced', '*.mp4'))
    work_dirs += glob.glob(os.path.join(data_dir, 'clip-factory-*', 'clips', '*.mp4'))

    # Find by matching score in filename
    tags = c.get('tags', [])
    if isinstance(tags, str):
        tags = [t.strip() for t in tags.split(',')]
    score_tags = [t for t in tags if t.startswith('score-')]
    score = score_tags[0].split('-')[1] if score_tags else ''

    for wf in work_dirs:
        if score and f'score{score}' in wf:
            file_path = wf
            break

    if file_path and os.path.exists(file_path):
        resolved.append(file_path)
    elif work_dirs:
        work_dirs.sort(key=os.path.getmtime, reverse=True)
        for wf in work_dirs:
            if wf not in resolved:
                resolved.append(wf)
                break

if not resolved:
    print('ERROR:No clip files found on disk', file=sys.stderr)
    sys.exit(1)

for f in resolved:
    print(f)
PYEOF
  )
  rm -f "$tmp_json"

  if echo "$clip_files" | grep -q "^ERROR:"; then
    error "$(echo "$clip_files" | head -1)"
    exit 1
  fi

  local clip_count
  clip_count=$(echo "$clip_files" | wc -l | tr -d ' ')
  info "Found $clip_count clip files to assemble"

  # Step 3: Assemble via VideoForge
  info "Step 3: Assembling clips..."
  local composed_file="$output_dir/composed-$(date +%Y%m%d-%H%M%S).mp4"

  if [[ -f "$VIDEO_FORGE" ]] && [[ $clip_count -gt 1 ]]; then
    local clip_args=""
    while IFS= read -r clip_path; do
      if [[ -f "$clip_path" ]]; then
        clip_args="$clip_args \"$clip_path\""
      fi
    done <<< "$clip_files"

    local asm_cmd="bash \"$VIDEO_FORGE\" assemble $clip_args --transition $transition --duration $transition_dur --output \"$output_dir\""
    info "  Running: video-forge.sh assemble ($clip_count clips, $transition transitions)"
    eval "$asm_cmd" 2>&1 | tail -5 || {
      warn "VideoForge assemble failed, falling back to FFmpeg concat"
    }

    # Check if VideoForge produced output
    local vf_output
    vf_output=$(ls "$output_dir"/assembled*.mp4 2>/dev/null | head -1)
    if [[ -n "$vf_output" ]]; then
      mv "$vf_output" "$composed_file"
    fi
  fi

  # Fallback: FFmpeg concat if VideoForge failed or single clip
  if [[ ! -f "$composed_file" ]]; then
    info "  Using FFmpeg concat..."
    local concat_file="$output_dir/concat.txt"
    while IFS= read -r clip_path; do
      if [[ -f "$clip_path" ]]; then
        echo "file '$clip_path'" >> "$concat_file"
      fi
    done <<< "$clip_files"

    if [[ -f "$concat_file" ]]; then
      ffmpeg -y -f concat -safe 0 -i "$concat_file" \
        -c:v libx264 -preset fast -crf 23 \
        -c:a aac -b:a 128k \
        "$composed_file" 2>/dev/null || {
        error "FFmpeg concat failed"
        exit 1
      }
      rm -f "$concat_file"
    fi
  fi

  # Step 4: Write manifest
  info "Step 4: Writing manifest..."
  $PY - "$output_dir/manifest.json" "$title" "$brand" "$mood" "$energy" "$hook_type" "$reuse_as" "$keyword" "$min_score" "$clip_count" "$transition" "$composed_file" << 'PYEOF'
import json, sys

output_file = sys.argv[1]
title = sys.argv[2] or 'composed-video'
brand = sys.argv[3]
mood = sys.argv[4] or None
energy = sys.argv[5] or None
hook_type = sys.argv[6] or None
reuse_as = sys.argv[7] or None
keyword = sys.argv[8] or None
min_score = int(sys.argv[9]) if sys.argv[9] else None
clip_count = int(sys.argv[10])
transition = sys.argv[11]
composed_file = sys.argv[12]

manifest = {
    'type': 'composed',
    'title': title,
    'brand': brand,
    'criteria': {
        'mood': mood,
        'energy': energy,
        'hook_type': hook_type,
        'reuse_as': reuse_as,
        'keyword': keyword,
        'min_score': min_score,
    },
    'clips_used': clip_count,
    'transition': transition,
    'output': composed_file,
}
manifest['criteria'] = {k: v for k, v in manifest['criteria'].items() if v}
with open(output_file, 'w') as f:
    json.dump(manifest, f, indent=2)
print(json.dumps(manifest, indent=2))
PYEOF

  # Register composed video in seed store
  if [[ -f "$SEED_STORE" ]] && [[ -n "$brand" ]] && [[ -f "$composed_file" ]]; then
    info "Registering composed video in seed store..."
    local compose_tags="composed,clip-factory,auto-assembled"
    if [[ -n "$mood" ]]; then compose_tags="$compose_tags,mood-$mood"; fi
    if [[ -n "$energy" ]]; then compose_tags="$compose_tags,energy-$energy"; fi
    if [[ -n "$keyword" ]]; then compose_tags="$compose_tags,$keyword"; fi

    bash "$SEED_STORE" add \
      --type video \
      --text "[composed] ${title:-auto-composed} | ${clip_count} clips | ${mood:-any} mood | ${energy:-any} energy" \
      --tags "$compose_tags" \
      --source "clip-factory" \
      --source-type "auto-compose" \
      --status "draft" 2>/dev/null || true
  fi

  # Post to creative room
  local rooms_dir="$HOME/.openclaw/workspace/rooms"
  if [[ -d "$rooms_dir" ]]; then
    echo "{\"type\":\"clip-factory-compose\",\"clips\":$clip_count,\"brand\":\"$brand\",\"title\":\"${title:-auto}\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$rooms_dir/creative.jsonl" 2>/dev/null || true
  fi

  info "=== COMPOSE COMPLETE ==="
  info "Output: $composed_file"
  info "Clips used: $clip_count"
}

# ==========================================================================
# MAIN — Parse subcommand and dispatch
# ==========================================================================
SUBCMD="${1:-run}"
shift 2>/dev/null || true

# Help
if [[ "$SUBCMD" = "--help" ]] || [[ "$SUBCMD" = "-h" ]] || [[ "$SUBCMD" = "help" ]]; then
  echo "clip-factory.sh — Long video → short viral clips"
  echo ""
  echo "Usage:"
  echo "  clip-factory.sh run --input video.mp4 [--brand <brand>]      # Full pipeline"
  echo "  clip-factory.sh analyze --input video.mp4                     # Stages 1-3 only"
  echo "  clip-factory.sh extract --work-dir <dir> [--max-clips N]      # Stage 4"
  echo "  clip-factory.sh produce --work-dir <dir> [--brand <brand>]    # Stages 5-6"
  echo "  clip-factory.sh list --work-dir <dir>                         # Show clips"
  echo "  clip-factory.sh preview --input video.mp4 [--top N]           # Quick preview"
  echo "  clip-factory.sh batch --file list.txt [--brand <brand>]       # Multiple videos"
  echo "  clip-factory.sh blocks --input video.mp4 [--brand <brand>]  # Extract reusable video blocks"
  echo "  clip-factory.sh catalog --work-dir <dir> [--brand <brand>]  # Generate metadata + catalog clips"
  echo "  clip-factory.sh find [--brand <b>] [--mood <m>] [--energy <e>]  # Search clip library"
  echo "  clip-factory.sh compose --brand <b> [--mood <m>] [--max-clips N] # Compose from library"
  echo ""
  echo "Options:"
  echo "  --input <file>       Input video file"
  echo "  --brand <brand>      Brand name (for branding + seed-store)"
  echo "  --min-score <N>      Minimum virality score 0-100 (default: 60)"
  echo "  --min-duration <N>   Minimum clip duration in seconds (default: 15)"
  echo "  --max-duration <N>   Maximum clip duration in seconds (default: 60)"
  echo "  --max-clips <N>      Maximum clips to extract (default: 10)"
  echo "  --platforms <list>   Export platforms, comma-separated (default: tiktok,reels,shorts,feed)"
  echo "  --no-crop            Skip 9:16 smart crop"
  echo "  --work-dir <dir>     Custom working directory"
  echo "  --top <N>            Show top N in preview mode (default: 5)"
  echo ""
  echo "Find options:"
  echo "  --mood <mood>        Filter: inspiring|funny|educational|emotional|dramatic|calm|urgent|casual"
  echo "  --energy <e>         Filter: low|medium|high"
  echo "  --hook-type <h>      Filter: question|shock|reveal|story|tip|testimonial|reaction|statistic|challenge"
  echo "  --reuse-as <tag>     Filter: intro|hook|explainer|testimonial|cta|reaction|story|tip|broll|highlight"
  echo "  --keyword <word>     Search in tags and text"
  echo "  --json               Output as JSON (for piping to compose)"
  echo ""
  echo "Compose options:"
  echo "  --transition <type>  crossfade|fade|cut (default: crossfade)"
  echo "  --transition-dur <s> Transition duration in seconds (default: 0.5)"
  echo "  --title <name>       Title for composed video"
  echo "  --output <dir>       Output directory"
  exit 0
fi

# Skip dependency checks if asking for help
first_arg="${1:-}"
if [[ "$first_arg" != "--help" ]] && [[ "$first_arg" != "-h" ]]; then
  # Check dependencies (skip for read-only subcommands)
  case "$SUBCMD" in
    list|find|catalog|compose)
      check_ffmpeg
      ;;
    analyze|extract|produce|run|preview|batch|blocks)
      check_deps
      ;;
  esac
fi

# Dispatch
case "$SUBCMD" in
  analyze)  cmd_analyze "$@" ;;
  extract)  cmd_extract "$@" ;;
  produce)  cmd_produce "$@" ;;
  run)      cmd_run "$@" ;;
  list)     cmd_list "$@" ;;
  preview)  cmd_preview "$@" ;;
  batch)    cmd_batch "$@" ;;
  blocks)   cmd_blocks "$@" ;;
  catalog)  cmd_catalog "$@" ;;
  find)     cmd_find "$@" ;;
  compose)  cmd_compose "$@" ;;
  *)
    error "Unknown subcommand: $SUBCMD"
    error "Run: clip-factory.sh --help"
    exit 1
    ;;
esac
