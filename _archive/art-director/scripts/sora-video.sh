#!/usr/bin/env bash
# sora-video.sh — Generate video via OpenAI Sora 2 API
# Usage: bash sora-video.sh generate "prompt text" [--seconds 5] [--size 1280x720] [--model sora-2] [--output path.mp4]
# Usage: bash sora-video.sh image2video "prompt" --image path.jpg [--seconds 5] [--output path.mp4]
# Usage: bash sora-video.sh status <video_id>
#
# Requires: OPENAI_API_KEY environment variable

set -euo pipefail

# --- Config ---
if [ -z "${OPENAI_API_KEY:-}" ]; then
  # Try sourcing from .zshrc
  OPENAI_API_KEY=$(grep 'OPENAI_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*OPENAI_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
  export OPENAI_API_KEY
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY not set"
  echo "Set it in ~/.zshrc: export OPENAI_API_KEY='sk-...'"
  echo "Or pass it: OPENAI_API_KEY=sk-... bash sora-video.sh ..."
  exit 1
fi

BASE_URL="https://api.openai.com"
DATA_DIR="$HOME/.openclaw/workspace/data/videos"
LOG_FILE="$HOME/.openclaw/logs/sora-video.log"

mkdir -p "$DATA_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# --- Commands ---
cmd_generate() {
  local prompt="" seconds=5 size="1280x720" model="sora-2" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --seconds) seconds="$2"; shift 2 ;;
      --size)    size="$2"; shift 2 ;;
      --model)   model="$2"; shift 2 ;;
      --output)  output="$2"; shift 2 ;;
      *)         prompt="$1"; shift ;;
    esac
  done

  if [ -z "$prompt" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: bash sora-video.sh generate \"prompt\" [--seconds 5] [--size 1280x720]"
    exit 1
  fi

  log "Creating Sora task: model=$model, seconds=$seconds, size=$size"
  log "Prompt: $prompt"

  local response
  response=$(curl -s -X POST "${BASE_URL}/v1/videos" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -F model="$model" \
    -F prompt="$prompt" \
    -F size="$size" \
    -F seconds="$seconds")

  local video_id
  video_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

  if [ -z "$video_id" ]; then
    echo "ERROR: Failed to create task"
    echo "$response"
    log "ERROR: $response"
    exit 1
  fi

  echo "Video job created: $video_id"
  log "Job created: $video_id"

  # Poll for completion
  echo "Polling for completion (typically 2-4 minutes)..."
  local max_attempts=40  # 40 * 15s = 10 minutes
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    local status_resp
    status_resp=$(curl -s "${BASE_URL}/v1/videos/${video_id}" \
      -H "Authorization: Bearer ${OPENAI_API_KEY}")

    local status progress
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null)
    progress=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('progress',0))" 2>/dev/null)

    echo "  [$attempt] Status: $status ($progress%)"

    if [ "$status" = "completed" ]; then
      if [ -z "$output" ]; then
        output="${DATA_DIR}/sora-${video_id}.mp4"
      fi

      curl -s "${BASE_URL}/v1/videos/${video_id}/content" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" \
        -o "$output"

      echo "Video saved: $output"
      log "Video saved: $output (job: $video_id)"

      # Store in seed bank
      bash "$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh" add \
        --type video --text "$prompt" --tags "sora,$model" \
        --source-agent art-director --source-type video-gen 2>/dev/null || true

      echo "$output"
      exit 0
    elif [ "$status" = "failed" ]; then
      echo "FAILED"
      echo "$status_resp"
      log "FAILED: $video_id"
      exit 1
    fi
  done

  echo "TIMEOUT: Check status: bash sora-video.sh status $video_id"
  exit 1
}

cmd_image2video() {
  local prompt="" image_path="" seconds=5 size="1280x720" model="sora-2" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --image)   image_path="$2"; shift 2 ;;
      --seconds) seconds="$2"; shift 2 ;;
      --size)    size="$2"; shift 2 ;;
      --model)   model="$2"; shift 2 ;;
      --output)  output="$2"; shift 2 ;;
      *)         prompt="$1"; shift ;;
    esac
  done

  if [ -z "$image_path" ] || [ ! -f "$image_path" ]; then
    echo "ERROR: --image path required (file must exist)"
    exit 1
  fi

  log "Creating Sora image2video: image=$image_path"

  local response
  response=$(curl -s -X POST "${BASE_URL}/v1/videos" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -F model="$model" \
    -F prompt="${prompt:-The scene slowly comes to life}" \
    -F size="$size" \
    -F seconds="$seconds" \
    -F input_reference=@"$image_path")

  local video_id
  video_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

  if [ -z "$video_id" ]; then
    echo "ERROR: $response"
    exit 1
  fi

  echo "Job created: $video_id"
  echo "Polling..."

  local max_attempts=40
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    local status
    status=$(curl -s "${BASE_URL}/v1/videos/${video_id}" \
      -H "Authorization: Bearer ${OPENAI_API_KEY}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null)

    echo "  [$attempt] Status: $status"

    if [ "$status" = "completed" ]; then
      if [ -z "$output" ]; then
        output="${DATA_DIR}/sora-i2v-${video_id}.mp4"
      fi
      curl -s "${BASE_URL}/v1/videos/${video_id}/content" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" -o "$output"
      echo "Saved: $output"
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
  local video_id="$1"
  curl -s "${BASE_URL}/v1/videos/${video_id}" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"ID: {d.get('id','unknown')}\")
print(f\"Status: {d.get('status','unknown')}\")
print(f\"Progress: {d.get('progress',0)}%\")
print(f\"Model: {d.get('model','unknown')}\")
"
}

# --- Main ---
if [ $# -eq 0 ]; then
  echo "Usage: bash sora-video.sh <generate|image2video|status> ..."
  echo ""
  echo "Requires: OPENAI_API_KEY environment variable"
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  generate)    cmd_generate "$@" ;;
  image2video) cmd_image2video "$@" ;;
  status)      cmd_status "$@" ;;
  *)
    echo "Unknown command: $COMMAND"
    exit 1
    ;;
esac
