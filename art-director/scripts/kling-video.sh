#!/usr/bin/env bash
# kling-video.sh — Generate video via Kling AI API
# Usage: bash kling-video.sh text2video "prompt text" [--duration 5] [--ratio 16:9] [--model kling-video-o1] [--mode std] [--output path.mp4]
# Usage: bash kling-video.sh image2video "prompt text" --image "url" [--duration 5] [--output path.mp4]
# Usage: bash kling-video.sh status <task_id>

set -euo pipefail

# --- Config ---
KLING_AK="${KLING_ACCESS_KEY:-ACDE3mpNHFhnbPfB8Kh8QBEE3FQg8f3B}"
KLING_SK="${KLING_SECRET_KEY:-D38tfnYCBrG84nGy9nKBkM49AJnEEdDM}"
BASE_URL="https://api.klingai.com"
DATA_DIR="$HOME/.openclaw/workspace/data/videos"
LOG_FILE="$HOME/.openclaw/logs/kling-video.log"

mkdir -p "$DATA_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# --- JWT Token Generation ---
generate_token() {
  python3 -c "
import jwt, time
headers = {'alg': 'HS256', 'typ': 'JWT'}
payload = {
    'iss': '$KLING_AK',
    'exp': int(time.time()) + 1800,
    'nbf': int(time.time()) - 5
}
print(jwt.encode(payload, '$KLING_SK', algorithm='HS256', headers=headers))
"
}

# --- Commands ---
cmd_text2video() {
  local prompt="" duration=5 ratio="16:9" model="kling-video-o1" mode="std" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --duration) duration="$2"; shift 2 ;;
      --ratio)    ratio="$2"; shift 2 ;;
      --model)    model="$2"; shift 2 ;;
      --mode)     mode="$2"; shift 2 ;;
      --output)   output="$2"; shift 2 ;;
      *)          prompt="$1"; shift ;;
    esac
  done

  if [ -z "$prompt" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: bash kling-video.sh text2video \"prompt\" [--duration 5] [--ratio 16:9]"
    exit 1
  fi

  local token
  token=$(generate_token)

  log "Creating text2video task: model=$model, duration=$duration, ratio=$ratio"
  log "Prompt: $prompt"

  local response
  response=$(curl -s -X POST "${BASE_URL}/v1/videos/text2video" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
print(json.dumps({
    'model_name': '$model',
    'prompt': sys.argv[1],
    'duration': int('$duration'),
    'aspect_ratio': '$ratio',
    'mode': '$mode'
}))
" "$prompt")")

  local task_id
  task_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('task_id',''))" 2>/dev/null)

  if [ -z "$task_id" ]; then
    echo "ERROR: Failed to create task"
    echo "$response"
    log "ERROR: $response"
    exit 1
  fi

  echo "Task created: $task_id"
  log "Task created: $task_id"

  # Poll for completion
  echo "Polling for completion (this may take 2-6 minutes)..."
  local max_attempts=60  # 60 * 15s = 15 minutes
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    # Refresh token every 10 minutes
    if [ $((attempt % 40)) -eq 0 ]; then
      token=$(generate_token)
    fi

    local status_resp
    status_resp=$(curl -s -X GET "${BASE_URL}/v1/videos/text2video/${task_id}" \
      -H "Authorization: Bearer ${token}")

    local status
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status','unknown'))" 2>/dev/null)

    echo "  [$attempt] Status: $status"

    if [ "$status" = "succeed" ]; then
      local video_url
      video_url=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['task_result']['videos'][0]['url'])" 2>/dev/null)

      if [ -z "$output" ]; then
        output="${DATA_DIR}/kling-${task_id}.mp4"
      fi

      curl -s -o "$output" "$video_url"
      echo "Video saved: $output"
      log "Video saved: $output (task: $task_id)"

      # Store in seed bank
      bash "$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh" add \
        --type video --text "$prompt" --tags "kling,$model" \
        --source-agent art-director --source-type video-gen 2>/dev/null || true

      echo "$output"
      exit 0
    elif [ "$status" = "failed" ]; then
      local err_msg
      err_msg=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status_msg','unknown'))" 2>/dev/null)
      echo "FAILED: $err_msg"
      log "FAILED: $task_id — $err_msg"
      exit 1
    fi
  done

  echo "TIMEOUT: Video generation timed out after 15 minutes"
  echo "Check status manually: bash kling-video.sh status $task_id"
  log "TIMEOUT: $task_id"
  exit 1
}

cmd_image2video() {
  local prompt="" image_url="" duration=5 model="kling-video-o1" mode="std" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --image)    image_url="$2"; shift 2 ;;
      --duration) duration="$2"; shift 2 ;;
      --model)    model="$2"; shift 2 ;;
      --mode)     mode="$2"; shift 2 ;;
      --output)   output="$2"; shift 2 ;;
      *)          prompt="$1"; shift ;;
    esac
  done

  if [ -z "$image_url" ]; then
    echo "ERROR: --image URL is required for image2video"
    exit 1
  fi

  local token
  token=$(generate_token)

  log "Creating image2video task: image=$image_url"

  local response
  response=$(curl -s -X POST "${BASE_URL}/v1/videos/image2video" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
d = {
    'model_name': '$model',
    'duration': int('$duration'),
    'mode': '$mode',
    'image': '$image_url'
}
if sys.argv[1]:
    d['prompt'] = sys.argv[1]
print(json.dumps(d))
" "$prompt")")

  local task_id
  task_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('task_id',''))" 2>/dev/null)

  if [ -z "$task_id" ]; then
    echo "ERROR: Failed to create task"
    echo "$response"
    exit 1
  fi

  echo "Task created: $task_id"
  echo "Polling for completion..."

  local max_attempts=60
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    if [ $((attempt % 40)) -eq 0 ]; then
      token=$(generate_token)
    fi

    local status_resp
    status_resp=$(curl -s -X GET "${BASE_URL}/v1/videos/image2video/${task_id}" \
      -H "Authorization: Bearer ${token}")

    local status
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status','unknown'))" 2>/dev/null)

    echo "  [$attempt] Status: $status"

    if [ "$status" = "succeed" ]; then
      local video_url
      video_url=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['task_result']['videos'][0]['url'])" 2>/dev/null)

      if [ -z "$output" ]; then
        output="${DATA_DIR}/kling-i2v-${task_id}.mp4"
      fi

      curl -s -o "$output" "$video_url"
      echo "Video saved: $output"
      log "Video saved: $output"
      exit 0
    elif [ "$status" = "failed" ]; then
      echo "FAILED"
      exit 1
    fi
  done

  echo "TIMEOUT"
  exit 1
}

cmd_status() {
  local task_id="$1"
  local token
  token=$(generate_token)

  # Try text2video first, then image2video
  local resp
  resp=$(curl -s -X GET "${BASE_URL}/v1/videos/text2video/${task_id}" \
    -H "Authorization: Bearer ${token}")

  local status
  status=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status','not_found'))" 2>/dev/null)

  if [ "$status" = "not_found" ]; then
    resp=$(curl -s -X GET "${BASE_URL}/v1/videos/image2video/${task_id}" \
      -H "Authorization: Bearer ${token}")
  fi

  echo "$resp" | python3 -c "
import sys, json
d = json.load(sys.stdin)
data = d.get('data', {})
print(f\"Task: {data.get('task_id', 'unknown')}\")
print(f\"Status: {data.get('task_status', 'unknown')}\")
if data.get('task_result', {}).get('videos'):
    print(f\"Video URL: {data['task_result']['videos'][0]['url']}\")
"
}

# --- Main ---
if [ $# -eq 0 ]; then
  echo "Usage: bash kling-video.sh <text2video|image2video|status> ..."
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  text2video)  cmd_text2video "$@" ;;
  image2video) cmd_image2video "$@" ;;
  status)      cmd_status "$@" ;;
  *)
    echo "Unknown command: $COMMAND"
    echo "Usage: bash kling-video.sh <text2video|image2video|status> ..."
    exit 1
    ;;
esac
