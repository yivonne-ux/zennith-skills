#!/usr/bin/env bash
# wan-video.sh — Generate video/images via Alibaba Wan models on fal.ai
# Wan is Alibaba's open-source video generation model family (Apache 2.0)
#
# Usage:
#   bash wan-video.sh text2video "prompt" [--duration 5] [--ratio 9:16] [--resolution 720p] [--output path.mp4] [--dry-run]
#   bash wan-video.sh image2video "prompt" --image "url_or_path" [--duration 5] [--ratio 9:16] [--pro] [--output path.mp4] [--dry-run]
#   bash wan-video.sh text2image "prompt" [--ratio 1:1] [--output path.png] [--dry-run]
#   bash wan-video.sh status <request_id> [--model text2video]
#
# Requires: FAL_API_KEY environment variable

set -euo pipefail

# Load API key from secrets if not already in env
[ -z "${FAL_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/fal.env" ] && \
  export "$(grep '^FAL_API_KEY=' "$HOME/.openclaw/secrets/fal.env" | head -1)" 2>/dev/null || true

# --- Config ---
FAL_BASE_URL="https://queue.fal.run"
DATA_DIR="$HOME/.openclaw/workspace/data/videos"
LOG_FILE="$HOME/.openclaw/logs/wan-video.log"
CREATIVE_ROOM="$HOME/.openclaw/workspace/rooms/creative.jsonl"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"

# fal.ai model IDs
MODEL_T2V="fal-ai/wan/v2.1/text-to-video"
MODEL_I2V="fal-ai/wan/v2.1/image-to-video"
MODEL_I2V_PRO="fal-ai/wan-pro/v1/image-to-video"
MODEL_T2I="fal-ai/wan/v2.1/text-to-image"

# Cost estimates (USD)
COST_T2V="0.20"
COST_I2V="0.20"
COST_I2V_PRO="0.80"
COST_T2I="0.05"

# Polling config
POLL_INTERVAL=5
POLL_MAX_SECONDS=300  # 5 minutes

mkdir -p "$DATA_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# --- Helpers ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

post_to_room() {
  local msg="$1"
  if [ -f "$CREATIVE_ROOM" ] || [ -d "$(dirname "$CREATIVE_ROOM")" ]; then
    printf '{"ts":%s000,"agent":"art-director","room":"creative","msg":"%s"}\n' \
      "$(date +%s)" "$msg" >> "$CREATIVE_ROOM" 2>/dev/null || true
  fi
}

register_seed() {
  local content_type="$1"
  local prompt="$2"
  local tags="$3"
  if [ -f "$SEED_STORE" ]; then
    bash "$SEED_STORE" add \
      --type "$content_type" --text "$prompt" --tags "$tags" \
      --source-agent art-director --source-type "${content_type}-gen" 2>/dev/null || true
  fi
}

duration_to_frames() {
  # Wan uses ~16fps; 5s = 81 frames, scale linearly
  # Formula: duration * 16 + 1
  local duration="$1"
  echo $(( duration * 16 + 1 ))
}

check_api_key() {
  if [ -z "${FAL_API_KEY:-}" ]; then
    # Try sourcing from .zshrc
    FAL_API_KEY=$(grep 'FAL_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*FAL_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export FAL_API_KEY
  fi

  if [ -z "${FAL_API_KEY:-}" ]; then
    echo "ERROR: FAL_API_KEY not set"
    echo "Set it in ~/.zshrc: export FAL_API_KEY='your-key-here'"
    echo "Or pass it: FAL_API_KEY=your-key bash wan-video.sh ..."
    exit 1
  fi
}

# Submit job to fal.ai queue
fal_submit() {
  local model_id="$1"
  local payload="$2"

  local response
  response=$(curl -s -X POST "${FAL_BASE_URL}/${model_id}" \
    -H "Authorization: Key ${FAL_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$payload")

  local request_id
  request_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('request_id',''))" 2>/dev/null)

  if [ -z "$request_id" ]; then
    echo "ERROR: Failed to submit job to fal.ai"
    echo "$response"
    log "ERROR: submit failed — $response"
    exit 1
  fi

  echo "$request_id"
}

# Check job status on fal.ai
fal_check_status() {
  local model_id="$1"
  local request_id="$2"

  curl -s -X GET "${FAL_BASE_URL}/${model_id}/requests/${request_id}/status" \
    -H "Authorization: Key ${FAL_API_KEY}"
}

# Get completed job result from fal.ai
fal_get_result() {
  local model_id="$1"
  local request_id="$2"

  curl -s -X GET "${FAL_BASE_URL}/${model_id}/requests/${request_id}" \
    -H "Authorization: Key ${FAL_API_KEY}"
}

# Poll for completion with progress output
# Uses background+wait+kill pattern for timeout (macOS has no GNU timeout)
fal_poll() {
  local model_id="$1"
  local request_id="$2"
  local max_seconds="${3:-$POLL_MAX_SECONDS}"

  local elapsed=0
  local attempt=0

  echo "Polling for completion (every ${POLL_INTERVAL}s, max ${max_seconds}s)..."
  log "Polling: model=$model_id request=$request_id"

  while [ $elapsed -lt $max_seconds ]; do
    sleep "$POLL_INTERVAL"
    elapsed=$((elapsed + POLL_INTERVAL))
    attempt=$((attempt + 1))

    local status_resp
    status_resp=$(fal_check_status "$model_id" "$request_id")

    local status
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null || echo "unknown")

    # Extract queue position or progress if available
    local queue_pos
    queue_pos=$(echo "$status_resp" | python3 -c "
import sys,json
d=json.load(sys.stdin)
pos = d.get('queue_position', None)
if pos is not None:
    print('queue pos: %s' % pos)
else:
    print('')
" 2>/dev/null || echo "")

    local progress_info=""
    if [ -n "$queue_pos" ]; then
      progress_info=" ($queue_pos)"
    fi

    echo "  [${attempt}] ${elapsed}s — Status: ${status}${progress_info}"

    if [ "$status" = "COMPLETED" ] || [ "$status" = "completed" ]; then
      log "Completed: request=$request_id (${elapsed}s)"
      return 0
    elif [ "$status" = "FAILED" ] || [ "$status" = "failed" ]; then
      local err_detail
      err_detail=$(echo "$status_resp" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('error','unknown error'))
" 2>/dev/null || echo "unknown error")
      echo "FAILED: $err_detail"
      log "FAILED: request=$request_id — $err_detail"
      exit 1
    fi
  done

  echo "TIMEOUT: Video generation timed out after ${max_seconds}s"
  echo "Check status manually: bash wan-video.sh status $request_id --model $(echo "$model_id" | sed 's|fal-ai/wan.*/||')"
  log "TIMEOUT: request=$request_id after ${max_seconds}s"
  exit 1
}

# Encode local file as data URI for fal.ai
encode_image_for_fal() {
  local image_path="$1"

  # Detect mime type
  local ext
  ext=$(echo "$image_path" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
  local mime="image/jpeg"
  case "$ext" in
    png)  mime="image/png" ;;
    gif)  mime="image/gif" ;;
    webp) mime="image/webp" ;;
    jpg|jpeg) mime="image/jpeg" ;;
  esac

  local b64
  b64=$(base64 < "$image_path" | tr -d '\n')
  echo "data:${mime};base64,${b64}"
}

usage() {
  cat <<'USAGE'
wan-video.sh — Wan Video Generation (Alibaba, via fal.ai)

COMMANDS:
  text2video  Generate video from text prompt
  image2video Generate video from image + text prompt
  text2image  Generate image from text prompt
  status      Check job status

USAGE — text2video:
  bash wan-video.sh text2video "A Malaysian woman cooking rendang" \
    --duration 5 --ratio 9:16 --resolution 720p

  Options:
    --duration N     Video duration in seconds (default: 5)
    --ratio RATIO    Aspect ratio: 16:9, 9:16, 1:1, etc. (default: 16:9)
    --resolution RES Resolution: 480p, 720p (default: 720p)
    --output PATH    Output file path (default: auto-generated)
    --dry-run        Show request without submitting

USAGE — image2video:
  bash wan-video.sh image2video "Camera slowly zooms in" \
    --image "https://example.com/photo.jpg" --duration 5 --ratio 9:16

  Options:
    --image URL      Image URL or local file path (required)
    --pro            Use Wan Pro model (1080p, $0.80 instead of $0.20)
    --duration N     Video duration in seconds (default: 5)
    --ratio RATIO    Aspect ratio (default: 16:9)
    --output PATH    Output file path
    --dry-run        Show request without submitting

USAGE — text2image:
  bash wan-video.sh text2image "Professional product shot" --ratio 1:1

  Options:
    --ratio RATIO    Aspect ratio (default: 1:1)
    --output PATH    Output file path
    --dry-run        Show request without submitting

USAGE — status:
  bash wan-video.sh status <request_id> [--model text2video]

  Options:
    --model TYPE     Model type: text2video, image2video, image2video-pro, text2image
                     (default: text2video)

COST ESTIMATES:
  text2video:       ~$0.20 per video
  image2video:      ~$0.20 per video
  image2video-pro:  ~$0.80 per video (1080p)
  text2image:       ~$0.05 per image

ENVIRONMENT:
  FAL_API_KEY       fal.ai API key (required)
USAGE
}

# --- Commands ---

cmd_text2video() {
  local prompt="" duration=5 ratio="16:9" resolution="720p" output="" dry_run=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --duration)    duration="$2"; shift 2 ;;
      --ratio)       ratio="$2"; shift 2 ;;
      --resolution)  resolution="$2"; shift 2 ;;
      --output)      output="$2"; shift 2 ;;
      --dry-run)     dry_run=1; shift ;;
      -*)            echo "Unknown option: $1"; exit 1 ;;
      *)             prompt="$1"; shift ;;
    esac
  done

  if [ -z "$prompt" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: bash wan-video.sh text2video \"prompt\" [--duration 5] [--ratio 9:16]"
    exit 1
  fi

  local num_frames
  num_frames=$(duration_to_frames "$duration")

  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({
    'prompt': sys.argv[1],
    'num_frames': int(sys.argv[2]),
    'resolution': sys.argv[3],
    'aspect_ratio': sys.argv[4]
}))
" "$prompt" "$num_frames" "$resolution" "$ratio")

  echo "=== Wan Text-to-Video ==="
  echo "Prompt:     $prompt"
  echo "Duration:   ${duration}s (${num_frames} frames)"
  echo "Ratio:      $ratio"
  echo "Resolution: $resolution"
  echo "Model:      $MODEL_T2V"
  echo "Est. cost:  \$${COST_T2V}"
  echo ""

  log "text2video: prompt='$prompt' duration=${duration}s frames=$num_frames ratio=$ratio resolution=$resolution"

  if [ "$dry_run" -eq 1 ]; then
    echo "[DRY RUN] Payload:"
    echo "$payload" | python3 -m json.tool
    echo ""
    echo "Would POST to: ${FAL_BASE_URL}/${MODEL_T2V}"
    exit 0
  fi

  check_api_key

  echo "Submitting to fal.ai queue..."
  local request_id
  request_id=$(fal_submit "$MODEL_T2V" "$payload")

  echo "Job submitted: $request_id"
  log "Submitted: request=$request_id model=$MODEL_T2V"

  # Poll for completion
  fal_poll "$MODEL_T2V" "$request_id"

  # Get result
  local result
  result=$(fal_get_result "$MODEL_T2V" "$request_id")

  local video_url
  video_url=$(echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
v = d.get('video', d.get('data', {}))
if isinstance(v, dict):
    print(v.get('url', ''))
elif isinstance(d.get('videos', []), list) and len(d['videos']) > 0:
    print(d['videos'][0].get('url', ''))
else:
    print('')
" 2>/dev/null)

  if [ -z "$video_url" ]; then
    echo "ERROR: Could not extract video URL from result"
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
    log "ERROR: no video URL in result for request=$request_id"
    exit 1
  fi

  if [ -z "$output" ]; then
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    output="${DATA_DIR}/${ts}_t2v.mp4"
  fi

  echo "Downloading video..."
  curl -s -o "$output" "$video_url"

  local file_size
  file_size=$(wc -c < "$output" | tr -d ' ')

  echo ""
  echo "=== Complete ==="
  echo "Video saved: $output"
  echo "File size:   ${file_size} bytes"
  echo "Cost:        ~\$${COST_T2V}"
  log "Video saved: $output (${file_size} bytes, request=$request_id)"

  # Register in seed bank
  register_seed "video" "$prompt" "wan,t2v,${ratio},${resolution}"

  # Post to creative room
  post_to_room "Wan T2V generated: ${duration}s ${ratio} video — ${prompt:0:80}"

  echo "$output"
}

cmd_image2video() {
  local prompt="" image_url="" duration=5 ratio="16:9" output="" use_pro=0 dry_run=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --image)     image_url="$2"; shift 2 ;;
      --duration)  duration="$2"; shift 2 ;;
      --ratio)     ratio="$2"; shift 2 ;;
      --pro)       use_pro=1; shift ;;
      --output)    output="$2"; shift 2 ;;
      --dry-run)   dry_run=1; shift ;;
      -*)          echo "Unknown option: $1"; exit 1 ;;
      *)           prompt="$1"; shift ;;
    esac
  done

  if [ -z "$image_url" ]; then
    echo "ERROR: --image URL or file path is required for image2video"
    echo "Usage: bash wan-video.sh image2video \"prompt\" --image \"url\" [--duration 5] [--ratio 9:16]"
    exit 1
  fi

  # If image_url is a local file, encode as base64 data URI
  local resolved_image="$image_url"
  if [ -f "$image_url" ]; then
    echo "Local file detected, encoding as base64..."
    resolved_image=$(encode_image_for_fal "$image_url")
    log "Encoded local image: $image_url (${#resolved_image} chars)"
  fi

  local model_id="$MODEL_I2V"
  local cost="$COST_I2V"
  local model_label="Wan I2V"
  if [ "$use_pro" -eq 1 ]; then
    model_id="$MODEL_I2V_PRO"
    cost="$COST_I2V_PRO"
    model_label="Wan I2V Pro (1080p)"
  fi

  local num_frames
  num_frames=$(duration_to_frames "$duration")

  local payload
  payload=$(python3 -c "
import json, sys
d = {
    'image_url': sys.argv[1],
    'num_frames': int(sys.argv[2]),
    'aspect_ratio': sys.argv[3]
}
if sys.argv[4]:
    d['prompt'] = sys.argv[4]
print(json.dumps(d))
" "$resolved_image" "$num_frames" "$ratio" "$prompt")

  echo "=== Wan Image-to-Video ==="
  echo "Prompt:    ${prompt:-<none>}"
  echo "Image:     ${image_url}"
  echo "Duration:  ${duration}s (${num_frames} frames)"
  echo "Ratio:     $ratio"
  echo "Model:     $model_id"
  echo "Est. cost: \$${cost}"
  echo ""

  log "image2video: prompt='$prompt' image='$image_url' duration=${duration}s frames=$num_frames ratio=$ratio model=$model_id"

  if [ "$dry_run" -eq 1 ]; then
    echo "[DRY RUN] Would POST to: ${FAL_BASE_URL}/${model_id}"
    echo "[DRY RUN] Payload keys: prompt, image_url, num_frames, aspect_ratio"
    if [ -f "$image_url" ]; then
      echo "[DRY RUN] Local image would be base64 encoded"
    fi
    exit 0
  fi

  check_api_key

  echo "Submitting to fal.ai queue..."
  local request_id
  request_id=$(fal_submit "$model_id" "$payload")

  echo "Job submitted: $request_id"
  log "Submitted: request=$request_id model=$model_id"

  # Poll for completion
  fal_poll "$model_id" "$request_id"

  # Get result
  local result
  result=$(fal_get_result "$model_id" "$request_id")

  local video_url
  video_url=$(echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
v = d.get('video', d.get('data', {}))
if isinstance(v, dict):
    print(v.get('url', ''))
elif isinstance(d.get('videos', []), list) and len(d['videos']) > 0:
    print(d['videos'][0].get('url', ''))
else:
    print('')
" 2>/dev/null)

  if [ -z "$video_url" ]; then
    echo "ERROR: Could not extract video URL from result"
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
    log "ERROR: no video URL in result for request=$request_id"
    exit 1
  fi

  if [ -z "$output" ]; then
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    output="${DATA_DIR}/${ts}_i2v.mp4"
  fi

  echo "Downloading video..."
  curl -s -o "$output" "$video_url"

  local file_size
  file_size=$(wc -c < "$output" | tr -d ' ')

  echo ""
  echo "=== Complete ==="
  echo "Video saved: $output"
  echo "File size:   ${file_size} bytes"
  echo "Cost:        ~\$${cost}"
  log "Video saved: $output (${file_size} bytes, request=$request_id)"

  # Register in seed bank
  register_seed "video" "${prompt:-i2v from $image_url}" "wan,i2v,${ratio}"

  # Post to creative room
  post_to_room "Wan I2V generated: ${duration}s ${ratio} video from image — ${prompt:0:60}"

  echo "$output"
}

cmd_text2image() {
  local prompt="" ratio="1:1" output="" dry_run=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --ratio)   ratio="$2"; shift 2 ;;
      --output)  output="$2"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      -*)        echo "Unknown option: $1"; exit 1 ;;
      *)         prompt="$1"; shift ;;
    esac
  done

  if [ -z "$prompt" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: bash wan-video.sh text2image \"prompt\" [--ratio 1:1]"
    exit 1
  fi

  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({
    'prompt': sys.argv[1],
    'aspect_ratio': sys.argv[2]
}))
" "$prompt" "$ratio")

  echo "=== Wan Text-to-Image ==="
  echo "Prompt:    $prompt"
  echo "Ratio:     $ratio"
  echo "Model:     $MODEL_T2I"
  echo "Est. cost: ~\$${COST_T2I}"
  echo ""

  log "text2image: prompt='$prompt' ratio=$ratio"

  if [ "$dry_run" -eq 1 ]; then
    echo "[DRY RUN] Payload:"
    echo "$payload" | python3 -m json.tool
    echo ""
    echo "Would POST to: ${FAL_BASE_URL}/${MODEL_T2I}"
    exit 0
  fi

  check_api_key

  echo "Submitting to fal.ai queue..."
  local request_id
  request_id=$(fal_submit "$MODEL_T2I" "$payload")

  echo "Job submitted: $request_id"
  log "Submitted: request=$request_id model=$MODEL_T2I"

  # Poll for completion
  fal_poll "$MODEL_T2I" "$request_id"

  # Get result
  local result
  result=$(fal_get_result "$MODEL_T2I" "$request_id")

  local image_result_url
  image_result_url=$(echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# fal.ai may return images in different structures
img = d.get('image', d.get('data', {}))
if isinstance(img, dict):
    print(img.get('url', ''))
elif isinstance(d.get('images', []), list) and len(d['images']) > 0:
    print(d['images'][0].get('url', ''))
else:
    print('')
" 2>/dev/null)

  if [ -z "$image_result_url" ]; then
    echo "ERROR: Could not extract image URL from result"
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
    log "ERROR: no image URL in result for request=$request_id"
    exit 1
  fi

  if [ -z "$output" ]; then
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    # Determine extension from URL or default to png
    local img_ext="png"
    case "$image_result_url" in
      *.jpg|*.jpeg) img_ext="jpg" ;;
      *.webp) img_ext="webp" ;;
    esac
    output="${DATA_DIR}/${ts}_t2i.${img_ext}"
  fi

  echo "Downloading image..."
  curl -s -o "$output" "$image_result_url"

  local file_size
  file_size=$(wc -c < "$output" | tr -d ' ')

  echo ""
  echo "=== Complete ==="
  echo "Image saved: $output"
  echo "File size:   ${file_size} bytes"
  echo "Cost:        ~\$${COST_T2I}"
  log "Image saved: $output (${file_size} bytes, request=$request_id)"

  # Register in seed bank
  register_seed "image" "$prompt" "wan,t2i,${ratio}"

  # Post to creative room
  post_to_room "Wan T2I generated: ${ratio} image — ${prompt:0:80}"

  echo "$output"
}

cmd_status() {
  local request_id="" model_type="text2video"

  if [ $# -eq 0 ]; then
    echo "ERROR: request_id is required"
    echo "Usage: bash wan-video.sh status <request_id> [--model text2video]"
    exit 1
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --model) model_type="$2"; shift 2 ;;
      -*)      echo "Unknown option: $1"; exit 1 ;;
      *)       request_id="$1"; shift ;;
    esac
  done

  if [ -z "$request_id" ]; then
    echo "ERROR: request_id is required"
    exit 1
  fi

  # Map model_type to fal.ai model ID
  local model_id
  case "$model_type" in
    text2video|t2v)        model_id="$MODEL_T2V" ;;
    image2video|i2v)       model_id="$MODEL_I2V" ;;
    image2video-pro|i2v-pro) model_id="$MODEL_I2V_PRO" ;;
    text2image|t2i)        model_id="$MODEL_T2I" ;;
    *)
      echo "ERROR: Unknown model type: $model_type"
      echo "Valid types: text2video, image2video, image2video-pro, text2image"
      exit 1
      ;;
  esac

  check_api_key

  echo "Checking status for request: $request_id"
  echo "Model: $model_id"
  echo ""

  local status_resp
  status_resp=$(fal_check_status "$model_id" "$request_id")

  echo "$status_resp" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Status:         %s' % d.get('status', 'unknown'))
pos = d.get('queue_position', None)
if pos is not None:
    print('Queue position: %s' % pos)
logs = d.get('logs', [])
if logs:
    print('Recent logs:')
    for l in logs[-5:]:
        print('  %s' % (l.get('message', str(l)) if isinstance(l, dict) else str(l)))
" 2>/dev/null

  # If completed, also show result info
  local status
  status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || echo "")

  if [ "$status" = "COMPLETED" ] || [ "$status" = "completed" ]; then
    echo ""
    echo "Fetching result..."
    local result
    result=$(fal_get_result "$model_id" "$request_id")

    echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# Try video
v = d.get('video', {})
if isinstance(v, dict) and v.get('url'):
    print('Video URL: %s' % v['url'])
# Try images
imgs = d.get('images', [])
if imgs:
    for i, img in enumerate(imgs):
        url = img.get('url', '') if isinstance(img, dict) else ''
        print('Image %d URL: %s' % (i, url))
# Try direct data
data = d.get('data', {})
if isinstance(data, dict) and data.get('url'):
    print('Result URL: %s' % data['url'])
" 2>/dev/null
  fi
}

# --- Main ---
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  text2video|t2v)   cmd_text2video "$@" ;;
  image2video|i2v)  cmd_image2video "$@" ;;
  text2image|t2i)   cmd_text2image "$@" ;;
  status)           cmd_status "$@" ;;
  help|--help|-h)   usage ;;
  *)
    echo "Unknown command: $COMMAND"
    echo ""
    usage
    exit 1
    ;;
esac
