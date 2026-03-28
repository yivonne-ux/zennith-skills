#!/usr/bin/env bash
# seedance-gen.sh — Seedance 2.0 Video Generation via PiAPI
#
# ByteDance's best video model: native audio, physics, camera control,
# multi-shot, up to 15 seconds, 1080p.
#
# Usage:
#   bash seedance-gen.sh --prompt "..." --output out.mp4
#   bash seedance-gen.sh --prompt "..." --output out.mp4 --duration 10 --aspect 9:16
#   bash seedance-gen.sh --prompt "..." --output out.mp4 --quality high
#   bash seedance-gen.sh --image ref.png --prompt "..." --output out.mp4  # image-to-video
#
# Requires: PIAPI_KEY in ~/.openclaw/secrets/piapi.env

set -euo pipefail

# ─── Config ──────────────────────────────────────────────
API_BASE="https://api.piapi.ai/api/v1"
LOG_FILE="$HOME/.openclaw/logs/seedance.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Load API key
PIAPI_KEY="${PIAPI_KEY:-}"
[ -z "$PIAPI_KEY" ] && [ -f "$HOME/.openclaw/secrets/piapi.env" ] && \
  PIAPI_KEY=$(grep '^PIAPI_KEY=' "$HOME/.openclaw/secrets/piapi.env" | cut -d= -f2 | sed "s/^['\"]//;s/['\"]$//")
[ -z "$PIAPI_KEY" ] && { echo "ERROR: PIAPI_KEY not set. Store in ~/.openclaw/secrets/piapi.env" >&2; exit 1; }

# ─── Args ────────────────────────────────────────────────
PROMPT=""
OUTPUT=""
DURATION=5
ASPECT="9:16"
QUALITY="fast"  # fast ($0.08/s) or high ($0.15/s)
IMAGE=""
SEED=""

while [ $# -gt 0 ]; do
  case "$1" in
    --prompt)    PROMPT="$2"; shift 2 ;;
    --output|-o) OUTPUT="$2"; shift 2 ;;
    --duration)  DURATION="$2"; shift 2 ;;
    --aspect)    ASPECT="$2"; shift 2 ;;
    --quality)   QUALITY="$2"; shift 2 ;;
    --image)     IMAGE="$2"; shift 2 ;;
    --seed)      SEED="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: seedance-gen.sh --prompt \"...\" --output out.mp4 [options]"
      echo ""
      echo "Options:"
      echo "  --prompt TEXT    Video description (required)"
      echo "  --output FILE    Output MP4 path (required)"
      echo "  --duration N     Duration in seconds (default: 5, max: 15)"
      echo "  --aspect RATIO   Aspect ratio: 9:16, 16:9, 1:1 (default: 9:16)"
      echo "  --quality MODE   fast (\$0.08/s) or high (\$0.15/s) (default: fast)"
      echo "  --image FILE     Reference image for image-to-video"
      echo "  --seed N         Random seed for reproducibility"
      exit 0
      ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[ -z "$PROMPT" ] && { echo "ERROR: --prompt required" >&2; exit 1; }
[ -z "$OUTPUT" ] && OUTPUT="/tmp/seedance-$(date +%s).mp4"

# Map quality to task type
TASK_TYPE="seedance-2-fast-preview"
[ "$QUALITY" = "high" ] && TASK_TYPE="seedance-2-preview"

log() {
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $1" | tee -a "$LOG_FILE"
}

log "[seedance] Generating: ${PROMPT:0:80}..."
log "[seedance] Duration: ${DURATION}s | Aspect: $ASPECT | Quality: $QUALITY"

# ─── Step 1: Submit task ─────────────────────────────────
INPUT="{\"prompt\": $(python3 -c "import json; print(json.dumps('''$PROMPT'''))"), \"duration\": $DURATION, \"aspect_ratio\": \"$ASPECT\""

# Add image reference if provided
if [ -n "$IMAGE" ] && [ -f "$IMAGE" ]; then
  # Base64 encode the image
  IMG_B64=$(base64 < "$IMAGE" | tr -d '\n')
  INPUT="$INPUT, \"image\": \"data:image/png;base64,$IMG_B64\""
  log "[seedance] Image-to-video mode: $(basename "$IMAGE")"
fi

# Add seed if provided
[ -n "$SEED" ] && INPUT="$INPUT, \"seed\": $SEED"

INPUT="$INPUT}"

BODY="{\"model\": \"seedance\", \"task_type\": \"$TASK_TYPE\", \"input\": $INPUT}"

SUBMIT_RESPONSE=$(curl -s -X POST "$API_BASE/task" \
  -H "X-API-Key: $PIAPI_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY")

TASK_ID=$(echo "$SUBMIT_RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
task_id = d.get('data', {}).get('task_id', d.get('task_id', ''))
if not task_id:
    err = d.get('message', d.get('error', str(d)))
    print(f'ERROR:{err}', file=sys.stderr)
    sys.exit(1)
print(task_id)
" 2>&1)

if echo "$TASK_ID" | grep -q "^ERROR:"; then
  log "[seedance] ERROR: ${TASK_ID#ERROR:}"
  exit 1
fi

log "[seedance] Task submitted: $TASK_ID"

# ─── Step 2: Poll for completion ─────────────────────────
MAX_POLLS=40  # 40 x 15s = 10 min max
for i in $(seq 1 $MAX_POLLS); do
  sleep 15

  STATUS_RESPONSE=$(curl -s "$API_BASE/task/$TASK_ID" \
    -H "X-API-Key: $PIAPI_KEY")

  STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
data = d.get('data', {})
status = data.get('status', 'unknown')
print(status)
" 2>/dev/null)

  case "$STATUS" in
    completed)
      log "[seedance] Generation complete! Downloading..."

      # Extract video URL
      VIDEO_URL=$(echo "$STATUS_RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
data = d.get('data', {})
output = data.get('output', {})
# Try various response structures
url = output.get('video', output.get('video_url', output.get('url', '')))
if not url:
    result = output.get('result', {})
    if isinstance(result, dict):
        url = result.get('video', result.get('video_url', result.get('url', '')))
    elif isinstance(result, str):
        url = result
if not url:
    videos = output.get('videos', [])
    if videos:
        url = videos[0].get('url', '') if isinstance(videos[0], dict) else videos[0]
print(url)
" 2>/dev/null)

      if [ -n "$VIDEO_URL" ] && [ "$VIDEO_URL" != "None" ]; then
        curl -s -L -o "$OUTPUT" "$VIDEO_URL"
        SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
        if [ "$SIZE" -gt 10000 ]; then
          DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT" 2>/dev/null || echo "?")
          RES=$(ffprobe -v quiet -show_entries stream=width,height -of csv=p=0 "$OUTPUT" 2>/dev/null | head -1 || echo "?")
          log "[seedance] SUCCESS: $OUTPUT (${SIZE} bytes, ${DUR}s, ${RES})"
          echo "$OUTPUT"
          exit 0
        else
          log "[seedance] ERROR: Downloaded file too small ($SIZE bytes)"
          cat "$OUTPUT" 2>/dev/null | head -5
          exit 1
        fi
      else
        log "[seedance] ERROR: No video URL in response"
        echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null | head -20 >> "$LOG_FILE"
        exit 1
      fi
      ;;
    failed|error)
      ERROR_MSG=$(echo "$STATUS_RESPONSE" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('data', {}).get('error', {}).get('message', 'Unknown error'))
" 2>/dev/null)
      log "[seedance] FAILED: $ERROR_MSG"
      exit 1
      ;;
    *)
      log "[seedance] Generating... ($i/$MAX_POLLS, status: $STATUS)"
      ;;
  esac
done

log "[seedance] ERROR: Timeout after 10 minutes"
exit 1
