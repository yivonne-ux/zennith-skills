#!/usr/bin/env bash
# reel-reverse-engineer.sh — Reverse-engineer a downloaded reel into a Jade recreation blueprint
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash reel-reverse-engineer.sh --input /path/to/reel.mp4
#   bash reel-reverse-engineer.sh --input /path/to/reel.mp4 --dry-run
#
# Pipeline:
#   1. Extract key frames at 1fps
#   2. Extract audio
#   3. Detect scene changes
#   4. Reverse-prompt key frames (Gemini Vision API or Claude CLI)
#   5. Analyze overall reel structure
#   6. Score virality
#
# Output: JSON blueprint at ~/.openclaw/workspace/data/jade-oracle-content-pipeline/reel-blueprints/

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLUEPRINT_DIR="$HOME/.openclaw/workspace/data/jade-oracle-content-pipeline/reel-blueprints"
LOG_FILE="$HOME/.openclaw/logs/jade-reel-factory.log"
ENV_FILE="$HOME/.openclaw/.env"
MAX_FRAMES_TO_ANALYZE=5

# --- Defaults ---
INPUT=""
DRY_RUN=false

# --- Setup ---
mkdir -p "$BLUEPRINT_DIR" "$(dirname "$LOG_FILE")"

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [reel-reverse] $1"
  echo "$msg" >> "$LOG_FILE"
  echo "$msg" >&2
}

info() {
  echo "[ReelReverse] $1"
  log "$1"
}

error() {
  echo "[ReelReverse] ERROR: $1" >&2
  log "ERROR: $1"
}

# --- Load environment ---
load_env() {
  if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
      case "$line" in
        ""|\#*) continue ;;
        *=*) export "$line" ;;
      esac
    done < "$ENV_FILE"
  fi

  # Fallback: check .zshrc for API keys
  if [ -z "${GEMINI_API_KEY:-}" ] && [ -z "${GOOGLE_API_KEY:-}" ]; then
    local zshrc_key
    zshrc_key=$(grep 'GEMINI_API_KEY=\|GOOGLE_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*=//; s/['\"]//g; s/export //g" || true)
    if [ -n "$zshrc_key" ]; then
      export GEMINI_API_KEY="$zshrc_key"
    fi
  fi

  # Normalize: prefer GEMINI_API_KEY, fall back to GOOGLE_API_KEY
  if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
    export GEMINI_API_KEY="$GOOGLE_API_KEY"
  fi
}

# --- Parse arguments ---
while [ $# -gt 0 ]; do
  case "$1" in
    --input)
      shift
      if [ $# -eq 0 ]; then error "--input requires a video path"; exit 1; fi
      INPUT="$1"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --help|-h)
      echo "reel-reverse-engineer.sh — Reverse-engineer reels into Jade recreation blueprints"
      echo ""
      echo "Usage:"
      echo "  bash reel-reverse-engineer.sh --input <video.mp4>"
      echo "  bash reel-reverse-engineer.sh --input <video.mp4> --dry-run"
      echo ""
      echo "Options:"
      echo "  --input PATH   Path to the reel video file (required)"
      echo "  --dry-run      Show pipeline steps without executing"
      echo "  --help         Show this help"
      echo ""
      echo "Output: $BLUEPRINT_DIR/reel-<hash>-analysis.json"
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# --- Validate ---
if [ -z "$INPUT" ]; then
  error "--input is required"
  echo "Run with --help for usage."
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  error "Input file not found: $INPUT"
  exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  error "ffmpeg is required. Install: brew install ffmpeg"
  exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
  error "ffprobe is required (comes with ffmpeg). Install: brew install ffmpeg"
  exit 1
fi

# --- Compute file hash for unique output naming ---
# macOS uses md5 instead of md5sum
if command -v md5 >/dev/null 2>&1; then
  FILE_HASH=$(md5 -q "$INPUT" | cut -c1-12)
elif command -v md5sum >/dev/null 2>&1; then
  FILE_HASH=$(md5sum "$INPUT" | cut -c1-12)
else
  # Fallback: use filename + size
  FILE_HASH=$(basename "$INPUT" | sed 's/[^a-zA-Z0-9]/_/g' | cut -c1-12)
fi

WORK_DIR="$BLUEPRINT_DIR/.work-$FILE_HASH"
FRAMES_DIR="$WORK_DIR/frames"
SCENES_DIR="$WORK_DIR/scenes"
AUDIO_FILE="$WORK_DIR/audio.wav"
OUTPUT_FILE="$BLUEPRINT_DIR/reel-${FILE_HASH}-analysis.json"

info "=== Jade Reel Factory — Reverse Engineer ==="
info "Input: $INPUT"
info "Hash: $FILE_HASH"
info "Blueprint: $OUTPUT_FILE"
if [ "$DRY_RUN" = "true" ]; then
  info "Mode: DRY RUN"
fi
echo ""

# --- Step 0: Get video metadata via ffprobe ---
info "Step 0: Extracting video metadata..."

if [ "$DRY_RUN" = "true" ]; then
  info "[DRY-RUN] ffprobe -v quiet -print_format json -show_format -show_streams \"$INPUT\""
  DURATION_SEC=15
  WIDTH=1080
  HEIGHT=1920
else
  PROBE_JSON=$(ffprobe -v quiet -print_format json -show_format -show_streams "$INPUT" 2>/dev/null || echo "{}")

  DURATION_SEC=$(echo "$PROBE_JSON" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    dur = data.get('format', {}).get('duration', '0')
    print(int(float(dur)))
except:
    print('0')
" 2>/dev/null || echo "0")

  WIDTH=$(echo "$PROBE_JSON" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for s in data.get('streams', []):
        if s.get('codec_type') == 'video':
            print(s.get('width', 0))
            break
except:
    print('0')
" 2>/dev/null || echo "0")

  HEIGHT=$(echo "$PROBE_JSON" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for s in data.get('streams', []):
        if s.get('codec_type') == 'video':
            print(s.get('height', 0))
            break
except:
    print('0')
" 2>/dev/null || echo "0")

  info "  Duration: ${DURATION_SEC}s | Resolution: ${WIDTH}x${HEIGHT}"
fi

# --- Step 1: Extract key frames at 1fps ---
info "Step 1: Extracting key frames at 1fps..."

if [ "$DRY_RUN" = "true" ]; then
  info "[DRY-RUN] ffmpeg -i \"$INPUT\" -vf fps=1 -q:v 2 \"$FRAMES_DIR/frame_%03d.jpg\""
else
  mkdir -p "$FRAMES_DIR"
  ffmpeg -i "$INPUT" -vf fps=1 -q:v 2 "$FRAMES_DIR/frame_%03d.jpg" -y -loglevel warning 2>> "$LOG_FILE"
  FRAME_COUNT=$(ls "$FRAMES_DIR"/frame_*.jpg 2>/dev/null | wc -l | tr -d ' ')
  info "  Extracted: $FRAME_COUNT frames"
fi

# --- Step 2: Extract audio ---
info "Step 2: Extracting audio..."

if [ "$DRY_RUN" = "true" ]; then
  info "[DRY-RUN] ffmpeg -i \"$INPUT\" -vn -acodec pcm_s16le -ar 16000 \"$AUDIO_FILE\""
else
  mkdir -p "$WORK_DIR"
  ffmpeg -i "$INPUT" -vn -acodec pcm_s16le -ar 16000 "$AUDIO_FILE" -y -loglevel warning 2>> "$LOG_FILE" || {
    info "  Warning: No audio stream found (may be silent reel)"
    AUDIO_FILE=""
  }
  if [ -n "$AUDIO_FILE" ] && [ -f "$AUDIO_FILE" ]; then
    local_audio_size=$(wc -c < "$AUDIO_FILE" | tr -d ' ')
    info "  Audio extracted: ${local_audio_size} bytes"
  fi
fi

# --- Step 3: Detect scene changes ---
info "Step 3: Detecting scene changes..."

SCENE_LOG=""
if [ "$DRY_RUN" = "true" ]; then
  info "[DRY-RUN] ffmpeg -i \"$INPUT\" -filter:v \"select='gt(scene,0.3)',showinfo\" -vsync vfr \"$SCENES_DIR/scene_%03d.jpg\""
  SCENE_COUNT=4
else
  mkdir -p "$SCENES_DIR"
  SCENE_LOG=$(ffmpeg -i "$INPUT" -filter:v "select='gt(scene,0.3)',showinfo" -vsync vfr "$SCENES_DIR/scene_%03d.jpg" -y -loglevel info 2>&1 | grep "showinfo" || true)
  SCENE_COUNT=$(ls "$SCENES_DIR"/scene_*.jpg 2>/dev/null | wc -l | tr -d ' ')
  # If no scene changes detected, count is 1 (the whole video is one scene)
  if [ "$SCENE_COUNT" -eq 0 ]; then
    SCENE_COUNT=1
  fi
  info "  Scene changes detected: $SCENE_COUNT"
fi

# --- Step 4: Reverse-prompt key frames ---
info "Step 4: Reverse-prompting key frames..."

load_env

# Determine which vision API to use
VISION_METHOD="none"
if [ -n "${GEMINI_API_KEY:-}" ]; then
  VISION_METHOD="gemini"
  info "  Using: Gemini Vision API"
elif command -v claude >/dev/null 2>&1; then
  VISION_METHOD="claude"
  info "  Using: Claude CLI (text-based analysis)"
else
  VISION_METHOD="ffprobe"
  info "  Using: ffprobe metadata fallback (no vision API available)"
fi

# Function: analyze a single frame with Gemini Vision API
analyze_frame_gemini() {
  local frame_path="$1"
  local frame_index="$2"
  local timestamp="$3"

  if [ ! -f "$frame_path" ]; then
    echo '{"description":"frame not found","prompt":"","mood":"unknown","camera":"unknown"}'
    return
  fi

  local b64_data
  b64_data=$(base64 < "$frame_path" | tr -d '\n')

  local mime_type="image/jpeg"
  case "$frame_path" in
    *.png) mime_type="image/png" ;;
    *.webp) mime_type="image/webp" ;;
  esac

  local prompt="You are a creative director analyzing an Instagram Reel frame. Describe this frame concisely as JSON with these exact keys:
- subject: what/who is in the frame
- action: what is happening
- clothing: what they are wearing (or N/A)
- setting: the location/background
- lighting: lighting description (natural, studio, golden hour, etc.)
- camera: camera angle (close-up, wide, medium, overhead, etc.)
- mood: emotional mood (mysterious, empowering, calm, energetic, etc.)
- text_overlay: any text visible on screen (or \"none\")

Return ONLY valid JSON. No markdown. No explanation."

  local payload
  payload=$(python3 -c "
import json
prompt = '''$prompt'''
data = {
    'contents': [{
        'parts': [
            {'text': prompt},
            {'inline_data': {'mime_type': '$mime_type', 'data': '''$b64_data'''}}
        ]
    }],
    'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 512}
}
print(json.dumps(data))
" 2>/dev/null)

  if [ -z "$payload" ]; then
    echo '{"description":"payload generation failed","prompt":"","mood":"unknown","camera":"unknown"}'
    return
  fi

  local api_url="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}"

  local response
  response=$(curl -s -X POST "$api_url" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null || echo "")

  if [ -z "$response" ]; then
    echo '{"description":"API call failed","prompt":"","mood":"unknown","camera":"unknown"}'
    return
  fi

  # Extract text from Gemini response and clean it
  python3 -c "
import json, sys

try:
    resp = json.loads('''$response''')
    text = resp.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '')
    # Strip markdown fences if present
    text = text.strip()
    if text.startswith('\`\`\`'):
        lines = text.split('\n')
        lines = [l for l in lines if not l.strip().startswith('\`\`\`')]
        text = '\n'.join(lines)
    parsed = json.loads(text)
    # Add timestamp
    parsed['timestamp'] = '$timestamp'
    print(json.dumps(parsed))
except Exception as e:
    print(json.dumps({
        'description': 'parse error: ' + str(e),
        'prompt': '',
        'mood': 'unknown',
        'camera': 'unknown',
        'timestamp': '$timestamp'
    }))
" 2>/dev/null || echo "{\"description\":\"python error\",\"timestamp\":\"$timestamp\"}"
}

# Function: analyze a frame with Claude CLI (text-based, no image input)
analyze_frame_claude() {
  local frame_path="$1"
  local frame_index="$2"
  local timestamp="$3"
  local filename
  filename=$(basename "$frame_path")

  local prompt="You are analyzing frame $frame_index of an Instagram Reel at timestamp $timestamp.
The frame file is: $filename
Based on the context of this being a spiritual/mystic content reel, provide a plausible analysis as JSON:
{
  \"subject\": \"likely subject based on spiritual/mystic reel context\",
  \"action\": \"likely action\",
  \"clothing\": \"likely clothing\",
  \"setting\": \"likely setting\",
  \"lighting\": \"likely lighting\",
  \"camera\": \"likely camera angle\",
  \"mood\": \"likely mood\",
  \"text_overlay\": \"none\",
  \"timestamp\": \"$timestamp\",
  \"note\": \"inferred from context, not visual analysis\"
}
Return ONLY valid JSON."

  local result
  result=$(echo "$prompt" | claude --print 2>/dev/null || echo "")

  if [ -n "$result" ]; then
    # Try to extract JSON from result
    python3 -c "
import json, sys
text = sys.stdin.read().strip()
# Strip markdown fences
if text.startswith('\`\`\`'):
    lines = text.split('\n')
    lines = [l for l in lines if not l.strip().startswith('\`\`\`')]
    text = '\n'.join(lines)
try:
    parsed = json.loads(text)
    parsed['timestamp'] = '$timestamp'
    print(json.dumps(parsed))
except:
    print(json.dumps({'description': text[:200], 'timestamp': '$timestamp', 'mood': 'unknown', 'camera': 'unknown'}))
" <<< "$result" 2>/dev/null
  else
    echo "{\"description\":\"Claude CLI unavailable\",\"timestamp\":\"$timestamp\",\"mood\":\"unknown\",\"camera\":\"unknown\"}"
  fi
}

# Function: fallback analysis using ffprobe metadata
analyze_frame_ffprobe() {
  local frame_path="$1"
  local frame_index="$2"
  local timestamp="$3"

  echo "{\"description\":\"Frame $frame_index at $timestamp (no vision API)\",\"prompt\":\"\",\"mood\":\"unknown\",\"camera\":\"unknown\",\"timestamp\":\"$timestamp\",\"note\":\"ffprobe fallback — set GEMINI_API_KEY for visual analysis\"}"
}

# Collect scene analyses
SCENES_JSON="["
FIRST_SCENE=true

if [ "$DRY_RUN" = "true" ]; then
  info "[DRY-RUN] Would analyze up to $MAX_FRAMES_TO_ANALYZE key frames using $VISION_METHOD"
  SCENES_JSON="[{\"timestamp\":\"0:00\",\"description\":\"dry-run placeholder\",\"mood\":\"unknown\",\"camera\":\"unknown\"}]"
else
  # Select frames to analyze (evenly spaced, max MAX_FRAMES_TO_ANALYZE)
  FRAME_FILES=""
  if [ -d "$SCENES_DIR" ]; then
    FRAME_FILES=$(ls "$SCENES_DIR"/scene_*.jpg 2>/dev/null || true)
  fi
  # If no scene-change frames, fall back to 1fps frames
  if [ -z "$FRAME_FILES" ] && [ -d "$FRAMES_DIR" ]; then
    FRAME_FILES=$(ls "$FRAMES_DIR"/frame_*.jpg 2>/dev/null || true)
  fi

  if [ -n "$FRAME_FILES" ]; then
    # Convert to array (Bash 3.2 compatible)
    idx=0
    total_available=0
    for f in $FRAME_FILES; do
      total_available=$((total_available + 1))
    done

    # Calculate step size for even spacing
    if [ "$total_available" -le "$MAX_FRAMES_TO_ANALYZE" ]; then
      step=1
    else
      step=$((total_available / MAX_FRAMES_TO_ANALYZE))
    fi

    current=0
    analyzed=0
    for frame_file in $FRAME_FILES; do
      if [ "$analyzed" -ge "$MAX_FRAMES_TO_ANALYZE" ]; then
        break
      fi

      # Only analyze every Nth frame for even spacing
      remainder=$((current % step))
      if [ "$remainder" -ne 0 ] && [ "$step" -gt 1 ]; then
        current=$((current + 1))
        continue
      fi

      # Calculate approximate timestamp
      ts_sec=$current
      ts_min=$((ts_sec / 60))
      ts_remainder=$((ts_sec % 60))
      timestamp=$(printf "%d:%02d" "$ts_min" "$ts_remainder")

      info "  Analyzing frame $((analyzed + 1))/$MAX_FRAMES_TO_ANALYZE at $timestamp..."

      local scene_json=""
      case "$VISION_METHOD" in
        gemini)
          scene_json=$(analyze_frame_gemini "$frame_file" "$analyzed" "$timestamp")
          ;;
        claude)
          scene_json=$(analyze_frame_claude "$frame_file" "$analyzed" "$timestamp")
          ;;
        *)
          scene_json=$(analyze_frame_ffprobe "$frame_file" "$analyzed" "$timestamp")
          ;;
      esac

      # Add to scenes array
      if [ "$FIRST_SCENE" = "true" ]; then
        FIRST_SCENE=false
      else
        SCENES_JSON="$SCENES_JSON,"
      fi
      SCENES_JSON="$SCENES_JSON$scene_json"

      analyzed=$((analyzed + 1))
      current=$((current + 1))
    done
  else
    info "  Warning: No frames found for analysis"
  fi

  SCENES_JSON="$SCENES_JSON]"
fi

# --- Step 5: Analyze overall reel structure ---
info "Step 5: Analyzing overall reel structure..."

# Determine pacing from scene count and duration
if [ "$DRY_RUN" = "true" ]; then
  HOOK_TYPE="question"
  TRANSITION_STYLE="hard_cut"
  MUSIC_STYLE="ambient"
  PACING="slow_build"
  CTA="save"
  LEARNINGS="Dry run — no analysis performed."
else
  # Use LLM for overall analysis if available
  OVERALL_JSON=""

  if [ "$VISION_METHOD" = "gemini" ] || [ "$VISION_METHOD" = "claude" ]; then
    local_overall_prompt="You are an expert social media content analyst specializing in spiritual/mystic Instagram Reels.

Based on this reel analysis data:
- Duration: ${DURATION_SEC} seconds
- Scene count: ${SCENE_COUNT}
- Resolution: ${WIDTH}x${HEIGHT}
- Scene descriptions: $SCENES_JSON

Analyze and return JSON with these exact keys:
{
  \"hook_type\": \"question|bold_claim|emotional|suspense\",
  \"transition_style\": \"cross_dissolve|hard_cut|zoom|swipe\",
  \"music_style\": \"lo-fi|ambient|dramatic|upbeat\",
  \"pacing\": \"slow_build|fast_cuts|breathing\",
  \"cta\": \"comment|save|link_in_bio|none\",
  \"learnings\": \"What makes this reel work: 2-3 sentences\"
}

Choose the BEST matching option for each field. Return ONLY valid JSON."

    if [ "$VISION_METHOD" = "gemini" ]; then
      local_api_url="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}"
      local_payload=$(python3 -c "
import json
prompt = '''$local_overall_prompt'''
data = {
    'contents': [{'parts': [{'text': prompt}]}],
    'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 512}
}
print(json.dumps(data))
" 2>/dev/null)

      if [ -n "$local_payload" ]; then
        OVERALL_JSON=$(curl -s -X POST "$local_api_url" \
          -H "Content-Type: application/json" \
          -d "$local_payload" 2>/dev/null || echo "")
      fi
    elif [ "$VISION_METHOD" = "claude" ]; then
      OVERALL_JSON=$(echo "$local_overall_prompt" | claude --print 2>/dev/null || echo "")
    fi
  fi

  # Parse overall analysis or use heuristics
  if [ -n "$OVERALL_JSON" ]; then
    eval "$(python3 -c "
import json, sys

raw = sys.stdin.read().strip()

# Try to extract from Gemini response format
try:
    resp = json.loads(raw)
    if 'candidates' in resp:
        raw = resp['candidates'][0]['content']['parts'][0]['text']
except:
    pass

# Strip markdown fences
raw = raw.strip()
if raw.startswith('\`\`\`'):
    lines = raw.split('\n')
    lines = [l for l in lines if not l.strip().startswith('\`\`\`')]
    raw = '\n'.join(lines).strip()

try:
    data = json.loads(raw)
    ht = data.get('hook_type', 'question')
    ts = data.get('transition_style', 'hard_cut')
    ms = data.get('music_style', 'ambient')
    pa = data.get('pacing', 'slow_build')
    ct = data.get('cta', 'save')
    le = data.get('learnings', 'Analysis complete.')
    # Escape for shell
    le = le.replace(\"'\", \"'\\\\''\")
    print(f\"HOOK_TYPE='{ht}'\")
    print(f\"TRANSITION_STYLE='{ts}'\")
    print(f\"MUSIC_STYLE='{ms}'\")
    print(f\"PACING='{pa}'\")
    print(f\"CTA='{ct}'\")
    print(f\"LEARNINGS='{le}'\")
except Exception as e:
    print(\"HOOK_TYPE='question'\")
    print(\"TRANSITION_STYLE='hard_cut'\")
    print(\"MUSIC_STYLE='ambient'\")
    print(\"PACING='slow_build'\")
    print(\"CTA='save'\")
    print(f\"LEARNINGS='Heuristic analysis (LLM parse failed: {e})'\")
" <<< "$OVERALL_JSON" 2>/dev/null)" || {
      # Heuristic fallback
      HOOK_TYPE="question"
      TRANSITION_STYLE="hard_cut"
      MUSIC_STYLE="ambient"
      CTA="save"
      LEARNINGS="Heuristic analysis — no LLM available."

      # Pacing heuristic based on scene count / duration
      if [ "$DURATION_SEC" -gt 0 ] && [ "$SCENE_COUNT" -gt 0 ]; then
        scenes_per_sec=$((SCENE_COUNT * 100 / DURATION_SEC))
        if [ "$scenes_per_sec" -gt 50 ]; then
          PACING="fast_cuts"
        elif [ "$scenes_per_sec" -gt 20 ]; then
          PACING="breathing"
        else
          PACING="slow_build"
        fi
      else
        PACING="slow_build"
      fi
    }
  else
    # Pure heuristic fallback
    HOOK_TYPE="question"
    TRANSITION_STYLE="hard_cut"
    MUSIC_STYLE="ambient"
    CTA="save"
    LEARNINGS="Heuristic analysis — no LLM available. Set GEMINI_API_KEY for full analysis."

    if [ "$DURATION_SEC" -gt 0 ] && [ "$SCENE_COUNT" -gt 0 ]; then
      scenes_per_sec=$((SCENE_COUNT * 100 / DURATION_SEC))
      if [ "$scenes_per_sec" -gt 50 ]; then
        PACING="fast_cuts"
      elif [ "$scenes_per_sec" -gt 20 ]; then
        PACING="breathing"
      else
        PACING="slow_build"
      fi
    else
      PACING="slow_build"
    fi
  fi
fi

info "  Hook: $HOOK_TYPE | Pacing: $PACING | Music: $MUSIC_STYLE"

# --- Step 6: Score virality ---
info "Step 6: Scoring virality..."

# Virality scoring: hook(30) + pacing(25) + emotion(25) + shareability(20)
# Use LLM if available, otherwise heuristic
VIRALITY_SCORE=50

if [ "$DRY_RUN" = "true" ]; then
  VIRALITY_SCORE=0
  info "[DRY-RUN] Would score virality"
elif [ "$VISION_METHOD" != "ffprobe" ] && [ "$VISION_METHOD" != "none" ]; then
  # LLM-based scoring
  score_prompt="Score this reel's virality (0-100) based on:
- Hook strength (30 points): $HOOK_TYPE hook, ${DURATION_SEC}s duration
- Pacing (25 points): $PACING style, $SCENE_COUNT scenes
- Emotional impact (25 points): scenes convey $MUSIC_STYLE mood
- Shareability (20 points): CTA is $CTA

Return ONLY a JSON object: {\"hook\":N, \"pacing\":N, \"emotion\":N, \"shareability\":N, \"total\":N}"

  score_result=""
  if [ "$VISION_METHOD" = "gemini" ]; then
    score_payload=$(python3 -c "
import json
data = {
    'contents': [{'parts': [{'text': '''$score_prompt'''}]}],
    'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 128}
}
print(json.dumps(data))
" 2>/dev/null)
    if [ -n "$score_payload" ]; then
      score_result=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$score_payload" 2>/dev/null || echo "")
    fi
  elif [ "$VISION_METHOD" = "claude" ]; then
    score_result=$(echo "$score_prompt" | claude --print 2>/dev/null || echo "")
  fi

  if [ -n "$score_result" ]; then
    VIRALITY_SCORE=$(python3 -c "
import json, sys

raw = sys.stdin.read().strip()
try:
    resp = json.loads(raw)
    if 'candidates' in resp:
        raw = resp['candidates'][0]['content']['parts'][0]['text']
except:
    pass

raw = raw.strip()
if raw.startswith('\`\`\`'):
    lines = raw.split('\n')
    lines = [l for l in lines if not l.strip().startswith('\`\`\`')]
    raw = '\n'.join(lines).strip()

try:
    data = json.loads(raw)
    total = data.get('total', 0)
    if total == 0:
        total = data.get('hook', 15) + data.get('pacing', 12) + data.get('emotion', 12) + data.get('shareability', 10)
    print(int(total))
except:
    print(50)
" <<< "$score_result" 2>/dev/null || echo "50")
  fi
else
  # Heuristic scoring
  hook_score=15
  pacing_score=12
  emotion_score=12
  share_score=10

  # Better hook types get higher scores
  case "$HOOK_TYPE" in
    emotional) hook_score=25 ;;
    bold_claim) hook_score=22 ;;
    suspense) hook_score=20 ;;
    question) hook_score=18 ;;
  esac

  # Fast pacing scores higher for reels
  case "$PACING" in
    fast_cuts) pacing_score=22 ;;
    breathing) pacing_score=18 ;;
    slow_build) pacing_score=14 ;;
  esac

  # CTAs that drive engagement score higher
  case "$CTA" in
    comment) share_score=18 ;;
    save) share_score=16 ;;
    link_in_bio) share_score=12 ;;
    none) share_score=8 ;;
  esac

  VIRALITY_SCORE=$((hook_score + pacing_score + emotion_score + share_score))
fi

info "  Virality score: $VIRALITY_SCORE / 100"

# --- Build final blueprint JSON ---
info "Step 7: Writing blueprint..."

if [ "$DRY_RUN" = "true" ]; then
  info "[DRY-RUN] Would write blueprint to: $OUTPUT_FILE"
  info ""
  info "=== Pipeline Summary (DRY RUN) ==="
  info "  1. Extract frames: ffmpeg -i INPUT -vf fps=1 ..."
  info "  2. Extract audio: ffmpeg -i INPUT -vn -acodec pcm_s16le ..."
  info "  3. Detect scenes: ffmpeg -i INPUT -filter:v select=gt(scene,0.3) ..."
  info "  4. Reverse-prompt: $VISION_METHOD vision analysis"
  info "  5. Overall analysis: hook/pacing/music/cta"
  info "  6. Virality score: hook(30)+pacing(25)+emotion(25)+share(20)"
  info "  Output: $OUTPUT_FILE"
  exit 0
fi

# Escape the input path and learnings for JSON
INPUT_ESCAPED=$(echo "$INPUT" | sed 's/\\/\\\\/g; s/"/\\"/g')
LEARNINGS_ESCAPED=$(echo "$LEARNINGS" | sed 's/\\/\\\\/g; s/"/\\"/g')

python3 -c "
import json, sys

scenes = json.loads('''$SCENES_JSON''')

# Build scene list with prompt field
formatted_scenes = []
for s in scenes:
    scene = {
        'timestamp': s.get('timestamp', '0:00'),
        'description': s.get('description', s.get('subject', 'unknown')),
        'prompt': '',
        'mood': s.get('mood', 'unknown'),
        'camera': s.get('camera', s.get('camera_angle', 'unknown'))
    }
    # Build a reproduction prompt from the analysis
    parts = []
    if s.get('subject'):
        parts.append(s['subject'])
    if s.get('action'):
        parts.append(s['action'])
    if s.get('setting'):
        parts.append('in ' + s['setting'])
    if s.get('lighting'):
        parts.append(s['lighting'] + ' lighting')
    if s.get('clothing'):
        parts.append('wearing ' + s['clothing'])
    scene['prompt'] = ', '.join(parts) if parts else scene['description']

    # Carry over extra fields
    if s.get('text_overlay') and s.get('text_overlay') != 'none':
        scene['text_overlay'] = s['text_overlay']

    formatted_scenes.append(scene)

blueprint = {
    'source': '$INPUT_ESCAPED',
    'duration_sec': $DURATION_SEC,
    'resolution': '${WIDTH}x${HEIGHT}',
    'scene_count': $SCENE_COUNT,
    'scenes': formatted_scenes,
    'hook_type': '$HOOK_TYPE',
    'transition_style': '$TRANSITION_STYLE',
    'music_style': '$MUSIC_STYLE',
    'pacing': '$PACING',
    'cta': '$CTA',
    'virality_score': $VIRALITY_SCORE,
    'learnings': '$LEARNINGS_ESCAPED',
    'analysis_method': '$VISION_METHOD',
    'analyzed_at': '$(date -u '+%Y-%m-%dT%H:%M:%SZ')'
}

print(json.dumps(blueprint, indent=2, ensure_ascii=False))
" > "$OUTPUT_FILE" 2>/dev/null

if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
  info ""
  info "=== Blueprint Complete ==="
  info "File: $OUTPUT_FILE"
  info "Duration: ${DURATION_SEC}s | Scenes: $SCENE_COUNT | Virality: $VIRALITY_SCORE/100"
  info "Hook: $HOOK_TYPE | Pacing: $PACING | Music: $MUSIC_STYLE | CTA: $CTA"
  info ""
  info "Learnings: $LEARNINGS"
  echo ""

  # Show blueprint preview
  echo "--- Blueprint Preview ---"
  python3 -c "
import json
with open('$OUTPUT_FILE') as f:
    data = json.load(f)
print(json.dumps(data, indent=2))
" 2>/dev/null || cat "$OUTPUT_FILE"

  # Clean up work directory
  if [ -d "$WORK_DIR" ]; then
    info "Work dir preserved at: $WORK_DIR"
    info "  (frames + audio available for further processing)"
  fi
else
  error "Failed to write blueprint"
  exit 1
fi

exit 0
