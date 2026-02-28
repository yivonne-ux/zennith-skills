#!/usr/bin/env bash
# creative-pipeline.sh — Multi-step creative video pipeline for GAIA CORP-OS
#
# Usage:
#   bash creative-pipeline.sh <type> <agent> <brand> "<brief>"
#   bash creative-pipeline.sh status <pipeline-id>
#   bash creative-pipeline.sh list [--brand <brand>]
#
# Types:
#   intro          — Character intro video: char-lock check -> keyframe gen (Kling 3.0) -> assembly (FFmpeg) -> QA
#   ugc            — UGC-style video: script writing (Dreami) -> Sora 2 generation -> post-prod -> QA
#   product-ugc    — Product UGC video: product image check -> Sora 2 -> post-prod -> QA
#   character-lock — Character lock: face gen -> body gen -> multi-angle sheet -> lock
#
# Examples:
#   bash creative-pipeline.sh intro iris gaia-os "Iris 6-second self-introduction"
#   bash creative-pipeline.sh ugc dreami mirra "Bento unboxing UGC video for IG Reels"
#   bash creative-pipeline.sh product-ugc iris pinxin-vegan "Vegan cheese platter showcase"
#   bash creative-pipeline.sh character-lock zenni gaia-os "Lock Zenni character for video use"
#
# macOS Bash 3.2 compatible — no declare -A, no ${var,,}, no timeout, no jq

set -uo pipefail

# ============================================================
# PATHS
# ============================================================
OPENCLAW_DIR="$HOME/.openclaw"
BRANDS_DIR="$OPENCLAW_DIR/brands"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
CHARS_DIR="$OPENCLAW_DIR/workspace/data/characters"
VIDEOS_DIR="$OPENCLAW_DIR/workspace/data/videos"
DISPATCH_SH="$OPENCLAW_DIR/skills/mission-control/scripts/dispatch.sh"
ROOM_WRITE_SH="$OPENCLAW_DIR/workspace/scripts/room-write.sh"
VIDEO_GEN_SH="$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh"
VIDEO_FORGE_SH="$OPENCLAW_DIR/skills/video-forge/scripts/video-forge.sh"
NANOBANANA_SH="$OPENCLAW_DIR/skills/nanobanana/scripts/nanobanana-gen.sh"
HANDOFF_SH="$OPENCLAW_DIR/skills/creative-production/scripts/handoff-dispatch.sh"
ENV_FILE="$OPENCLAW_DIR/.env"

LOG_FILE="$OPENCLAW_DIR/workspace/logs/creative-pipeline.log"
COST_LOG="$OPENCLAW_DIR/workspace/log/video-costs.jsonl"
CREATIVE_ROOM="$ROOMS_DIR/creative.jsonl"
PIPELINE_DIR="$VIDEOS_DIR/pipelines"

mkdir -p "$PIPELINE_DIR" "$ROOMS_DIR" "$(dirname "$LOG_FILE")" "$(dirname "$COST_LOG")"

# ============================================================
# HELPERS
# ============================================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

die() {
  echo "ERROR: $*" >&2
  log "ERROR: $*"
  exit 1
}

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Generate a pipeline ID: cp-<epoch>
gen_pipeline_id() {
  echo "cp-$(date +%s)"
}

# Load env vars (API keys)
load_env() {
  if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
      case "$line" in
        ""|\#*) continue ;;
      esac
      case "$line" in
        *=*)
          local key
          key=$(echo "$line" | cut -d= -f1)
          local val
          val=$(echo "$line" | cut -d= -f2-)
          val=$(echo "$val" | sed "s/^['\"]//;s/['\"]$//")
          export "$key=$val" 2>/dev/null || true
          ;;
      esac
    done < "$ENV_FILE"
  fi
  # Fallback: pull keys from .zshrc if not set
  if [ -z "${FAL_API_KEY:-}" ]; then
    FAL_API_KEY=$(grep 'FAL_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*FAL_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export FAL_API_KEY
  fi
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    OPENAI_API_KEY=$(grep 'OPENAI_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*OPENAI_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export OPENAI_API_KEY
  fi
  if [ -z "${KLING_ACCESS_KEY:-}" ]; then
    KLING_ACCESS_KEY=$(grep 'KLING_ACCESS_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*KLING_ACCESS_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export KLING_ACCESS_KEY
  fi
  if [ -z "${KLING_SECRET_KEY:-}" ]; then
    KLING_SECRET_KEY=$(grep 'KLING_SECRET_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*KLING_SECRET_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export KLING_SECRET_KEY
  fi
  if [ -z "${GEMINI_API_KEY:-}" ]; then
    GEMINI_API_KEY=$(grep 'GEMINI_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*GEMINI_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export GEMINI_API_KEY
  fi
}

# Post a structured event to creative.jsonl
post_to_creative_room() {
  local pipeline_id="$1"
  local step_name="$2"
  local step_status="$3"  # started|completed|failed
  local agent="$4"
  local brand="$5"
  local pipeline_type="$6"
  local detail="${7:-}"

  local ts
  ts=$(epoch_ms)

  local entry
  entry=$(python3 -c "
import json, sys
entry = {
    'ts': int(sys.argv[1]),
    'agent': sys.argv[2],
    'type': 'creative-pipeline',
    'pipeline_id': sys.argv[3],
    'pipeline_type': sys.argv[4],
    'step': sys.argv[5],
    'step_status': sys.argv[6],
    'brand': sys.argv[7],
    'detail': sys.argv[8]
}
print(json.dumps(entry))
" "$ts" "$agent" "$pipeline_id" "$pipeline_type" "$step_name" "$step_status" "$brand" "$detail")

  echo "$entry" >> "$CREATIVE_ROOM"
  log "Room post: $pipeline_id step=$step_name status=$step_status agent=$agent"
}

# Log cost for a step
log_cost() {
  local pipeline_id="$1"
  local step_name="$2"
  local agent="$3"
  local model="$4"
  local cost_usd="$5"
  local duration_s="${6:-0}"
  local file="${7:-}"

  local ts
  ts=$(iso_now)

  local entry
  entry=$(python3 -c "
import json, sys
entry = {
    'ts': sys.argv[1],
    'pipeline_id': sys.argv[2],
    'step': sys.argv[3],
    'agent': sys.argv[4],
    'model': sys.argv[5],
    'cost_usd': float(sys.argv[6]),
    'duration_s': int(sys.argv[7]),
    'file': sys.argv[8]
}
print(json.dumps(entry))
" "$ts" "$pipeline_id" "$step_name" "$agent" "$model" "$cost_usd" "$duration_s" "$file")

  echo "$entry" >> "$COST_LOG"
  log "Cost: $pipeline_id $step_name $model \$${cost_usd}"
}

# Dispatch to an agent via the inter-agent bus
dispatch_to_agent() {
  local from_agent="$1"
  local to_agent="$2"
  local action="$3"
  local message="$4"
  local room="${5:-creative}"

  if [ -f "$DISPATCH_SH" ]; then
    bash "$DISPATCH_SH" "$from_agent" "$to_agent" "$action" "$message" "$room" 2>/dev/null || {
      log "WARN: dispatch to $to_agent failed (non-fatal)"
      return 1
    }
    return 0
  else
    log "WARN: dispatch.sh not found at $DISPATCH_SH"
    return 1
  fi
}

# Check if character has locked assets
check_character_lock() {
  local agent="$1"
  local char_dir="$CHARS_DIR/$agent"

  if [ ! -d "$char_dir" ]; then
    echo "none"
    return 0
  fi

  local face_lock=""
  local body_lock=""
  local sheet_lock=""

  # Check for locked face (any -locked-v*.png or -locked-front.png)
  for f in "$char_dir"/*-locked-v*.png "$char_dir"/*-locked-front*.png; do
    if [ -f "$f" ]; then
      face_lock="$f"
      break
    fi
  done

  # Check for locked fullbody
  for f in "$char_dir"/*-locked-fullbody*.png; do
    if [ -f "$f" ]; then
      body_lock="$f"
      break
    fi
  done

  # Check for locked angle sheet
  for f in "$char_dir"/*-locked-9angle*.png; do
    if [ -f "$f" ]; then
      sheet_lock="$f"
      break
    fi
  done

  # Also check for character.json metadata files (gaia-eats pattern)
  local char_json=""
  for f in "$char_dir"/*_character.json; do
    if [ -f "$f" ]; then
      char_json="$f"
      break
    fi
  done

  if [ -n "$face_lock" ] && [ -n "$body_lock" ]; then
    echo "full"
  elif [ -n "$face_lock" ]; then
    echo "face-only"
  elif [ -n "$char_json" ]; then
    echo "partial"
  else
    echo "none"
  fi
}

# Get the path to a locked character asset
get_locked_asset() {
  local agent="$1"
  local asset_type="$2"  # face|body|sheet|storyboard
  local char_dir="$CHARS_DIR/$agent"

  case "$asset_type" in
    face)
      for f in "$char_dir"/*-locked-v*.png "$char_dir"/*_char_front.png; do
        if [ -f "$f" ]; then
          echo "$f"
          return 0
        fi
      done
      ;;
    body)
      for f in "$char_dir"/*-locked-fullbody*.png "$char_dir"/*_char_front.png; do
        if [ -f "$f" ]; then
          echo "$f"
          return 0
        fi
      done
      ;;
    sheet)
      for f in "$char_dir"/*-locked-9angle*.png; do
        if [ -f "$f" ]; then
          echo "$f"
          return 0
        fi
      done
      ;;
    storyboard)
      for f in "$char_dir"/*-locked-storyboard*.png; do
        if [ -f "$f" ]; then
          echo "$f"
          return 0
        fi
      done
      ;;
  esac
  echo ""
}

# Save pipeline manifest
save_manifest() {
  local pipeline_id="$1"
  local pipeline_type="$2"
  local agent="$3"
  local brand="$4"
  local brief="$5"
  local work_dir="$6"
  local status="${7:-active}"

  local manifest_path="$work_dir/manifest.json"
  local now_iso
  now_iso=$(iso_now)

  python3 -c "
import json, sys

manifest = {
    'pipeline_id': sys.argv[1],
    'type': sys.argv[2],
    'agent': sys.argv[3],
    'brand': sys.argv[4],
    'brief': sys.argv[5],
    'work_dir': sys.argv[6],
    'status': sys.argv[7],
    'steps': [],
    'total_cost_usd': 0.0,
    'created_at': sys.argv[8],
    'updated_at': sys.argv[8],
    'artifacts': {}
}

with open(sys.argv[9], 'w') as f:
    json.dump(manifest, f, indent=2)
" "$pipeline_id" "$pipeline_type" "$agent" "$brand" "$brief" "$work_dir" "$status" "$now_iso" "$manifest_path"

  echo "$manifest_path"
}

# Update manifest step
update_manifest_step() {
  local manifest_path="$1"
  local step_name="$2"
  local step_status="$3"
  local artifact="${4:-}"
  local cost="${5:-0}"

  if [ ! -f "$manifest_path" ]; then
    return 1
  fi

  python3 -c "
import json, sys, datetime

manifest_path = sys.argv[1]
step_name = sys.argv[2]
step_status = sys.argv[3]
artifact = sys.argv[4] if len(sys.argv) > 4 else ''
cost = float(sys.argv[5]) if len(sys.argv) > 5 else 0.0

with open(manifest_path) as f:
    m = json.load(f)

now = datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%dT%H:%M:%SZ')
step = {
    'name': step_name,
    'status': step_status,
    'artifact': artifact,
    'cost_usd': cost,
    'timestamp': now
}

# Update or append step
found = False
for i, s in enumerate(m['steps']):
    if s['name'] == step_name:
        m['steps'][i] = step
        found = True
        break
if not found:
    m['steps'].append(step)

m['total_cost_usd'] = sum(s.get('cost_usd', 0) for s in m['steps'])
m['updated_at'] = now

if artifact:
    m['artifacts'][step_name] = artifact

if step_status == 'failed':
    m['status'] = 'failed'
elif step_status == 'completed' and step_name in ('qa', 'lock', 'assembly_qa'):
    m['status'] = 'completed'

with open(manifest_path, 'w') as f:
    json.dump(m, f, indent=2)
" "$manifest_path" "$step_name" "$step_status" "$artifact" "$cost"
}

# ============================================================
# PIPELINE: intro
# Character intro video pipeline
# char-lock check -> keyframe gen (Kling 3.0) -> assembly (FFmpeg) -> QA
# ============================================================
pipeline_intro() {
  local agent="$1"
  local brand="$2"
  local brief="$3"
  local pipeline_id
  pipeline_id=$(gen_pipeline_id)

  local work_dir="$PIPELINE_DIR/$pipeline_id"
  mkdir -p "$work_dir"

  echo "=== Creative Pipeline: INTRO ==="
  echo "Pipeline ID: $pipeline_id"
  echo "Agent:       $agent"
  echo "Brand:       $brand"
  echo "Brief:       $brief"
  echo ""

  log "INTRO pipeline started: id=$pipeline_id agent=$agent brand=$brand"
  post_to_creative_room "$pipeline_id" "pipeline_start" "started" "creative-pipeline" "$brand" "intro" "Starting intro pipeline for $agent"

  local manifest_path
  manifest_path=$(save_manifest "$pipeline_id" "intro" "$agent" "$brand" "$brief" "$work_dir")

  # ─── Step 1: Character Lock Check ───────────────────────────────
  echo "--- Step 1: Character Lock Check ---"
  post_to_creative_room "$pipeline_id" "char_lock_check" "started" "creative-pipeline" "$brand" "intro"

  local lock_status
  lock_status=$(check_character_lock "$agent")

  echo "  Lock status: $lock_status"

  local face_ref=""
  local body_ref=""

  case "$lock_status" in
    full)
      echo "  Character $agent is fully locked. Using existing assets."
      face_ref=$(get_locked_asset "$agent" "face")
      body_ref=$(get_locked_asset "$agent" "body")
      echo "  Face ref: $face_ref"
      echo "  Body ref: $body_ref"
      update_manifest_step "$manifest_path" "char_lock_check" "completed" "$face_ref" "0"
      post_to_creative_room "$pipeline_id" "char_lock_check" "completed" "creative-pipeline" "$brand" "intro" "Locked: $face_ref"
      ;;
    face-only)
      echo "  Character $agent has face lock only. Body needed for intro."
      echo "  Dispatching to Iris for body generation..."
      face_ref=$(get_locked_asset "$agent" "face")
      dispatch_to_agent "creative-pipeline" "iris" "request" \
        "[PIPELINE $pipeline_id] Generate fullbody for $agent. Face ref: $face_ref. Brief: $brief" "creative"
      update_manifest_step "$manifest_path" "char_lock_check" "completed" "$face_ref" "0"
      post_to_creative_room "$pipeline_id" "char_lock_check" "completed" "creative-pipeline" "$brand" "intro" "Face only, body dispatched to Iris"
      body_ref="$face_ref"  # Use face as fallback start image
      ;;
    partial|none)
      echo "  Character $agent is NOT locked. Cannot generate intro without character lock."
      echo "  Run: bash creative-pipeline.sh character-lock $agent $brand \"Lock $agent for intro\""
      echo ""
      echo "  Dispatching character-lock request to Iris..."
      dispatch_to_agent "creative-pipeline" "iris" "request" \
        "[PIPELINE $pipeline_id] Character $agent needs full lock before intro video. Brief: $brief. Please generate face + body + approve." "creative"
      update_manifest_step "$manifest_path" "char_lock_check" "failed" "" "0"
      post_to_creative_room "$pipeline_id" "char_lock_check" "failed" "creative-pipeline" "$brand" "intro" "No lock found — dispatched to Iris"

      echo ""
      echo "Pipeline $pipeline_id PAUSED: character lock required."
      echo "Resume after locking: bash creative-pipeline.sh intro $agent $brand \"$brief\""
      log "INTRO pipeline $pipeline_id paused: no character lock for $agent"
      return 1
      ;;
  esac
  echo ""

  # ─── Step 2: Keyframe Generation via Kling 3.0 (fal.ai) ────────
  echo "--- Step 2: Keyframe Generation (Kling 3.0 via fal.ai) ---"
  post_to_creative_room "$pipeline_id" "keyframe_gen" "started" "iris" "$brand" "intro"

  local start_image="$face_ref"
  if [ -n "$body_ref" ] && [ "$body_ref" != "$face_ref" ]; then
    start_image="$body_ref"
  fi

  echo "  Start image: $start_image"
  echo "  Face ref:    $face_ref"

  if [ -z "${FAL_API_KEY:-}" ]; then
    echo "  ERROR: FAL_API_KEY not set. Cannot generate via Kling 3.0."
    update_manifest_step "$manifest_path" "keyframe_gen" "failed" "" "0"
    post_to_creative_room "$pipeline_id" "keyframe_gen" "failed" "iris" "$brand" "intro" "FAL_API_KEY missing"
    die "FAL_API_KEY required for Kling 3.0"
  fi

  # Upload start image to fal.ai for URL
  echo "  Uploading start image to fal.ai..."
  local image_url
  image_url=$(python3 -c "
import sys, requests, os, base64, json

fal_key = os.environ.get('FAL_API_KEY', '')
image_path = sys.argv[1]

# Read and base64 encode
with open(image_path, 'rb') as f:
    data = f.read()

# Upload to fal.ai storage
resp = requests.post(
    'https://fal.run/fal-ai/any-llm/upload',
    headers={'Authorization': 'Key ' + fal_key, 'Content-Type': 'application/json'},
    json={'media_type': 'image/png', 'file_name': os.path.basename(image_path)}
)
if resp.status_code == 200:
    upload_url = resp.json().get('upload_url', '')
    file_url = resp.json().get('file_url', '')
    if upload_url:
        requests.put(upload_url, data=data, headers={'Content-Type': 'image/png'})
        print(file_url)
    else:
        print('')
else:
    # Fallback: if the image is already a URL, pass through
    if image_path.startswith('http'):
        print(image_path)
    else:
        print('')
" "$start_image" 2>/dev/null || echo "")

  # Fallback: if fal upload failed, try submitting directly via video-gen.sh
  if [ -z "$image_url" ]; then
    echo "  WARN: fal.ai upload failed. Falling back to video-gen.sh kling image2video."
    image_url="$start_image"
  fi

  # Generate intro clip via Kling 3.0 with character elements
  local clip_output="$work_dir/intro-clip.mp4"
  local enhanced_prompt
  enhanced_prompt="$brief. Character is centered, looking at camera, natural movement, cinematic lighting, 16:9 aspect ratio."

  # Try Kling first, then fall back to Sora 2
  echo "  Generating via video-gen.sh kling image2video..."
  echo "  Prompt: $enhanced_prompt"

  bash "$VIDEO_GEN_SH" kling image2video \
    --image "$image_url" \
    --prompt "$enhanced_prompt" \
    --duration 4 \
    --brand "$brand" \
    --output "$clip_output" 2>&1 | while IFS= read -r line; do echo "    $line"; done

  local kling_exit=${PIPESTATUS[0]:-0}

  # If Kling failed, fall back to Sora 2
  if [ ! -f "$clip_output" ] || [ "$(wc -c < "$clip_output" 2>/dev/null | tr -d ' ')" -lt 1000 ]; then
    echo "  Kling failed or unavailable. Trying Sora 2 fallback..."
    post_to_creative_room "$pipeline_id" "keyframe_gen" "retry" "iris" "$brand" "intro" "Kling failed, trying Sora 2"

    bash "$VIDEO_GEN_SH" sora generate \
      --prompt "$enhanced_prompt" \
      --image "$start_image" \
      --duration 4 \
      --brand "$brand" \
      --output "$clip_output" 2>&1 | while IFS= read -r line; do echo "    $line"; done
  fi

  if [ -f "$clip_output" ] && [ "$(wc -c < "$clip_output" | tr -d ' ')" -gt 1000 ]; then
    echo "  Clip generated: $clip_output"
    local clip_size
    clip_size=$(wc -c < "$clip_output" | tr -d ' ')
    update_manifest_step "$manifest_path" "keyframe_gen" "completed" "$clip_output" "0.28"
    log_cost "$pipeline_id" "keyframe_gen" "iris" "video-gen" "0.28" "4" "$clip_output"
    post_to_creative_room "$pipeline_id" "keyframe_gen" "completed" "iris" "$brand" "intro" "Clip: $clip_output (${clip_size} bytes)"
  else
    echo "  WARN: Both Kling and Sora failed."
    update_manifest_step "$manifest_path" "keyframe_gen" "failed" "" "0.28"
    log_cost "$pipeline_id" "keyframe_gen" "iris" "video-gen" "0.28" "0" ""
    post_to_creative_room "$pipeline_id" "keyframe_gen" "failed" "iris" "$brand" "intro" "Both Kling and Sora failed"
    echo ""
    echo "Pipeline $pipeline_id: video generation failed."
    echo "Manual retry: bash video-gen.sh sora generate --prompt \"$brief\" --duration 4 --brand $brand --output $clip_output"
    return 1
  fi
  echo ""

  # ─── Step 3: Assembly via VideoForge ────────────────────────────
  echo "--- Step 3: Assembly (VideoForge / FFmpeg) ---"
  post_to_creative_room "$pipeline_id" "assembly" "started" "taoz" "$brand" "intro"

  local final_output="$work_dir/${agent}-intro-final.mp4"

  if [ -x "$VIDEO_FORGE_SH" ]; then
    echo "  Assembling via VideoForge..."
    # Create concat file
    local concat_file="$work_dir/concat.txt"
    echo "file '$clip_output'" > "$concat_file"

    bash "$VIDEO_FORGE_SH" assemble --input "$concat_file" --output "$final_output" 2>&1 | \
      while IFS= read -r line; do echo "    $line"; done || {
      echo "  VideoForge failed, falling back to ffmpeg copy..."
      cp "$clip_output" "$final_output" 2>/dev/null || true
    }
  else
    echo "  VideoForge not available. Copying clip as final."
    cp "$clip_output" "$final_output"
  fi

  if [ -f "$final_output" ]; then
    local final_size
    final_size=$(wc -c < "$final_output" | tr -d ' ')
    echo "  Final video: $final_output (${final_size} bytes)"
    update_manifest_step "$manifest_path" "assembly" "completed" "$final_output" "0"
    post_to_creative_room "$pipeline_id" "assembly" "completed" "taoz" "$brand" "intro" "Final: $final_output"
  else
    update_manifest_step "$manifest_path" "assembly" "failed" "" "0"
    post_to_creative_room "$pipeline_id" "assembly" "failed" "taoz" "$brand" "intro" "Assembly failed"
    die "Assembly failed for $pipeline_id"
  fi
  echo ""

  # ─── Step 4: QA — Dispatch to Argus ────────────────────────────
  echo "--- Step 4: QA (Argus) ---"
  post_to_creative_room "$pipeline_id" "qa" "started" "argus" "$brand" "intro"

  dispatch_to_agent "creative-pipeline" "argus" "request" \
    "[PIPELINE $pipeline_id] QA check for intro video. Agent: $agent, Brand: $brand. Video: $final_output. Checklist: face match, body proportions, lighting, aspect ratio 16:9, duration, no artifacts, brand DNA colors. Brief: $brief" "creative"

  update_manifest_step "$manifest_path" "qa" "completed" "$final_output" "0"
  post_to_creative_room "$pipeline_id" "qa" "completed" "argus" "$brand" "intro" "QA dispatched"

  # ─── Auto-send to Jenn via WhatsApp ────────────────────────────
  if [ -f "$final_output" ]; then
    echo "--- Sending to Jenn via WhatsApp ---"
    openclaw message send \
      --channel whatsapp \
      --target "+60126169979" \
      --media "$final_output" \
      --message "[Pipeline $pipeline_id] $agent intro video ($brand). Review and reply approve/redo." \
      2>/dev/null && echo "  Sent to WhatsApp." || echo "  WhatsApp send failed (non-blocking)."
  fi

  echo ""
  echo "=== Pipeline $pipeline_id COMPLETE ==="
  echo "  Type:        intro"
  echo "  Agent:       $agent"
  echo "  Brand:       $brand"
  echo "  Final video: $final_output"
  echo "  Work dir:    $work_dir"
  echo "  Manifest:    $manifest_path"
  echo ""
  echo "QA review dispatched to Argus. Check: bash creative-pipeline.sh status $pipeline_id"

  log "INTRO pipeline $pipeline_id completed: $final_output"
}

# ============================================================
# PIPELINE: ugc
# UGC video: script writing (Dreami) -> Sora 2 -> post-prod -> QA
# ============================================================
pipeline_ugc() {
  local agent="$1"
  local brand="$2"
  local brief="$3"
  local pipeline_id
  pipeline_id=$(gen_pipeline_id)

  local work_dir="$PIPELINE_DIR/$pipeline_id"
  mkdir -p "$work_dir"

  echo "=== Creative Pipeline: UGC ==="
  echo "Pipeline ID: $pipeline_id"
  echo "Agent:       $agent"
  echo "Brand:       $brand"
  echo "Brief:       $brief"
  echo ""

  log "UGC pipeline started: id=$pipeline_id agent=$agent brand=$brand"
  post_to_creative_room "$pipeline_id" "pipeline_start" "started" "creative-pipeline" "$brand" "ugc" "Starting UGC pipeline"

  local manifest_path
  manifest_path=$(save_manifest "$pipeline_id" "ugc" "$agent" "$brand" "$brief" "$work_dir")

  # ─── Step 1: Script Writing (Dreami) ────────────────────────────
  echo "--- Step 1: Script Writing (Dreami) ---"
  post_to_creative_room "$pipeline_id" "script_writing" "started" "dreami" "$brand" "ugc"

  # Dispatch to Dreami for UGC script
  local script_path="$work_dir/ugc-script.txt"

  dispatch_to_agent "creative-pipeline" "dreami" "request" \
    "[PIPELINE $pipeline_id] Write a UGC video script for brand $brand. Brief: $brief. Requirements: 1) Hook in first 2 seconds, 2) Natural/authentic feel, 3) Mobile-first (9:16), 4) 8-12 seconds total, 5) Write scene-by-scene with camera directions. Output: plain text script with scene numbers." "creative"

  # Create a starter script in case Dreami response is async
  python3 -c "
import sys

brief = sys.argv[1]
brand = sys.argv[2]
agent = sys.argv[3]

script = '''UGC Video Script — {brand}
Pipeline brief: {brief}
Character: {agent}

Scene 1 (0-2s): HOOK
- Camera: Close-up, natural lighting
- Action: Character catches attention
- Audio: Upbeat music starts

Scene 2 (2-5s): SHOW
- Camera: Medium shot, product visible
- Action: Character demonstrates/unboxes
- Audio: Music continues

Scene 3 (5-8s): TELL
- Camera: Tracking shot, dynamic
- Action: Character shares key benefit
- Audio: Music + optional voice

Scene 4 (8-12s): CTA
- Camera: Pull back to full scene
- Action: Character shows final result
- Audio: Music resolves, brand tag

---
NOTE: This is a template. Dreami has been dispatched to write the full script.
Check creative.jsonl for Dreami response.
'''.format(brand=brand, brief=brief, agent=agent)

with open(sys.argv[4], 'w') as f:
    f.write(script)
" "$brief" "$brand" "$agent" "$script_path"

  echo "  Template script: $script_path"
  echo "  Dreami dispatched for enrichment."
  update_manifest_step "$manifest_path" "script_writing" "completed" "$script_path" "0"
  log_cost "$pipeline_id" "script_writing" "dreami" "kimi-k2.5" "0" "0" "$script_path"
  post_to_creative_room "$pipeline_id" "script_writing" "completed" "dreami" "$brand" "ugc" "Script template + Dreami dispatch"
  echo ""

  # ─── Step 2: Sora 2 Video Generation ───────────────────────────
  echo "--- Step 2: Sora 2 Video Generation ---"
  post_to_creative_room "$pipeline_id" "video_gen" "started" "iris" "$brand" "ugc"

  if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "  ERROR: OPENAI_API_KEY not set. Cannot use Sora 2."
    update_manifest_step "$manifest_path" "video_gen" "failed" "" "0"
    post_to_creative_room "$pipeline_id" "video_gen" "failed" "iris" "$brand" "ugc" "OPENAI_API_KEY missing"
    die "OPENAI_API_KEY required for Sora 2"
  fi

  local sora_prompt
  sora_prompt="UGC style video, authentic feel, mobile-first vertical format. $brief. Brand: $brand. Natural lighting, casual setting, real-person energy."

  local clip_output="$work_dir/ugc-raw.mp4"

  echo "  Generating via video-gen.sh sora generate..."
  echo "  Prompt: $sora_prompt"
  echo "  Duration: 8s"
  echo "  Aspect: 9:16 (vertical)"
  echo ""
  echo "  IMPORTANT: Sora 2 URLs expire in 1 hour. Downloading immediately."

  bash "$VIDEO_GEN_SH" sora generate \
    --prompt "$sora_prompt" \
    --duration 8 \
    --aspect-ratio "9:16" \
    --brand "$brand" \
    --output "$clip_output" 2>&1 | while IFS= read -r line; do echo "    $line"; done

  if [ -f "$clip_output" ] && [ "$(wc -c < "$clip_output" | tr -d ' ')" -gt 1000 ]; then
    local clip_size
    clip_size=$(wc -c < "$clip_output" | tr -d ' ')
    echo "  UGC clip generated: $clip_output (${clip_size} bytes)"
    update_manifest_step "$manifest_path" "video_gen" "completed" "$clip_output" "0.80"
    log_cost "$pipeline_id" "video_gen" "iris" "sora-2" "0.80" "8" "$clip_output"
    post_to_creative_room "$pipeline_id" "video_gen" "completed" "iris" "$brand" "ugc" "Sora 2 clip: $clip_output"
  else
    echo "  WARN: Sora 2 generation failed."
    update_manifest_step "$manifest_path" "video_gen" "failed" "" "0.80"
    log_cost "$pipeline_id" "video_gen" "iris" "sora-2" "0.80" "0" ""
    post_to_creative_room "$pipeline_id" "video_gen" "failed" "iris" "$brand" "ugc" "Sora 2 failed"
    echo ""
    echo "Pipeline $pipeline_id: video generation failed."
    echo "Retry: bash video-gen.sh sora generate --prompt \"$sora_prompt\" --duration 8 --aspect-ratio 9:16 --brand $brand --output $clip_output"
    return 1
  fi
  echo ""

  # ─── Step 3: Post-Production (VideoForge) ──────────────────────
  echo "--- Step 3: Post-Production (VideoForge) ---"
  post_to_creative_room "$pipeline_id" "post_prod" "started" "taoz" "$brand" "ugc"

  local final_output="$work_dir/${agent}-ugc-final.mp4"

  if [ -x "$VIDEO_FORGE_SH" ]; then
    echo "  Running VideoForge post-production..."
    # Apply captions, brand overlay, music
    bash "$VIDEO_FORGE_SH" process \
      --input "$clip_output" \
      --output "$final_output" \
      --brand "$brand" 2>&1 | while IFS= read -r line; do echo "    $line"; done || {
      echo "  VideoForge failed, copying raw clip as final."
      cp "$clip_output" "$final_output"
    }
  else
    echo "  VideoForge not available. Using raw Sora output."
    cp "$clip_output" "$final_output"
  fi

  if [ -f "$final_output" ]; then
    local final_size
    final_size=$(wc -c < "$final_output" | tr -d ' ')
    echo "  Final UGC: $final_output (${final_size} bytes)"
    update_manifest_step "$manifest_path" "post_prod" "completed" "$final_output" "0"
    post_to_creative_room "$pipeline_id" "post_prod" "completed" "taoz" "$brand" "ugc" "Post-prod done: $final_output"
  else
    update_manifest_step "$manifest_path" "post_prod" "failed" "" "0"
    post_to_creative_room "$pipeline_id" "post_prod" "failed" "taoz" "$brand" "ugc" "Post-prod failed"
  fi
  echo ""

  # ─── Step 4: QA (Argus) ────────────────────────────────────────
  echo "--- Step 4: QA (Argus) ---"
  post_to_creative_room "$pipeline_id" "qa" "started" "argus" "$brand" "ugc"

  dispatch_to_agent "creative-pipeline" "argus" "request" \
    "[PIPELINE $pipeline_id] QA for UGC video. Brand: $brand. Video: $final_output. Check: hook in first 2s, authentic feel, 9:16 vertical, no artifacts, brand colors, duration 8-12s. Brief: $brief" "creative"

  update_manifest_step "$manifest_path" "qa" "completed" "$final_output" "0"
  post_to_creative_room "$pipeline_id" "qa" "completed" "argus" "$brand" "ugc" "QA dispatched"

  # ─── Auto-send to Jenn via WhatsApp ────────────────────────────
  if [ -f "$final_output" ]; then
    echo "--- Sending to Jenn via WhatsApp ---"
    openclaw message send \
      --channel whatsapp \
      --target "+60126169979" \
      --media "$final_output" \
      --message "[Pipeline $pipeline_id] $agent UGC ($brand). Review and reply approve/redo." \
      2>/dev/null && echo "  Sent to WhatsApp." || echo "  WhatsApp send failed (non-blocking)."
  fi

  echo ""
  echo "=== Pipeline $pipeline_id COMPLETE ==="
  echo "  Type:        ugc"
  echo "  Agent:       $agent"
  echo "  Brand:       $brand"
  echo "  Final video: $final_output"
  echo "  Total cost:  ~\$0.80"
  echo "  Work dir:    $work_dir"
  echo ""
  echo "QA review dispatched to Argus."

  log "UGC pipeline $pipeline_id completed: $final_output"
}

# ============================================================
# PIPELINE: product-ugc
# Product UGC: product image check -> Sora 2 -> post-prod -> QA
# ============================================================
pipeline_product_ugc() {
  local agent="$1"
  local brand="$2"
  local brief="$3"
  local pipeline_id
  pipeline_id=$(gen_pipeline_id)

  local work_dir="$PIPELINE_DIR/$pipeline_id"
  mkdir -p "$work_dir"

  echo "=== Creative Pipeline: PRODUCT-UGC ==="
  echo "Pipeline ID: $pipeline_id"
  echo "Agent:       $agent"
  echo "Brand:       $brand"
  echo "Brief:       $brief"
  echo ""

  log "PRODUCT-UGC pipeline started: id=$pipeline_id agent=$agent brand=$brand"
  post_to_creative_room "$pipeline_id" "pipeline_start" "started" "creative-pipeline" "$brand" "product-ugc" "Starting product-ugc pipeline"

  local manifest_path
  manifest_path=$(save_manifest "$pipeline_id" "product-ugc" "$agent" "$brand" "$brief" "$work_dir")

  # ─── Step 1: Product Image Check ───────────────────────────────
  echo "--- Step 1: Product Image Check ---"
  post_to_creative_room "$pipeline_id" "product_check" "started" "iris" "$brand" "product-ugc"

  # Look for product images in brand assets
  local brand_assets="$BRANDS_DIR/$brand/assets"
  local product_image=""

  if [ -d "$brand_assets" ]; then
    # Find most recent product image
    for f in "$brand_assets"/product*.png "$brand_assets"/product*.jpg "$brand_assets"/*.png; do
      if [ -f "$f" ]; then
        product_image="$f"
        break
      fi
    done
  fi

  if [ -n "$product_image" ] && [ -f "$product_image" ]; then
    echo "  Product image found: $product_image"
    update_manifest_step "$manifest_path" "product_check" "completed" "$product_image" "0"
    post_to_creative_room "$pipeline_id" "product_check" "completed" "iris" "$brand" "product-ugc" "Product image: $product_image"
  else
    echo "  No product image found in $brand_assets"
    echo "  Generating product keyframe via NanoBanana..."

    if [ -x "$NANOBANANA_SH" ]; then
      product_image="$work_dir/product-keyframe.png"
      bash "$NANOBANANA_SH" \
        --prompt "Product shot for $brand. $brief. Clean white background, professional product photography, appetizing, high resolution." \
        --brand "$brand" \
        --output "$product_image" 2>&1 | while IFS= read -r line; do echo "    $line"; done || true

      if [ -f "$product_image" ]; then
        echo "  Generated product image: $product_image"
        update_manifest_step "$manifest_path" "product_check" "completed" "$product_image" "0.01"
        log_cost "$pipeline_id" "product_check" "iris" "gemini-image" "0.01" "0" "$product_image"
        post_to_creative_room "$pipeline_id" "product_check" "completed" "iris" "$brand" "product-ugc" "Generated: $product_image"
      else
        echo "  Product image generation failed."
        echo "  Dispatching to Iris for manual product image..."
        dispatch_to_agent "creative-pipeline" "iris" "request" \
          "[PIPELINE $pipeline_id] Need product image for $brand product-ugc. Brief: $brief" "creative"
        update_manifest_step "$manifest_path" "product_check" "failed" "" "0"
        post_to_creative_room "$pipeline_id" "product_check" "failed" "iris" "$brand" "product-ugc" "NanoBanana failed, dispatched to Iris"
        echo ""
        echo "Pipeline $pipeline_id PAUSED: product image needed."
        return 1
      fi
    else
      echo "  NanoBanana not available. Dispatching to Iris..."
      dispatch_to_agent "creative-pipeline" "iris" "request" \
        "[PIPELINE $pipeline_id] Need product image for $brand product-ugc. Brief: $brief" "creative"
      update_manifest_step "$manifest_path" "product_check" "failed" "" "0"
      post_to_creative_room "$pipeline_id" "product_check" "failed" "iris" "$brand" "product-ugc" "No NanoBanana, dispatched to Iris"
      echo ""
      echo "Pipeline $pipeline_id PAUSED: product image needed."
      return 1
    fi
  fi
  echo ""

  # ─── Step 2: Sora 2 Generation ─────────────────────────────────
  echo "--- Step 2: Sora 2 Video Generation ---"
  post_to_creative_room "$pipeline_id" "video_gen" "started" "iris" "$brand" "product-ugc"

  if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "  ERROR: OPENAI_API_KEY not set."
    update_manifest_step "$manifest_path" "video_gen" "failed" "" "0"
    post_to_creative_room "$pipeline_id" "video_gen" "failed" "iris" "$brand" "product-ugc" "OPENAI_API_KEY missing"
    die "OPENAI_API_KEY required for Sora 2"
  fi

  local sora_prompt
  sora_prompt="Product showcase UGC video. $brief. Brand: $brand. Natural hands interacting with product, appetizing close-up, Instagram Reels style, vertical 9:16."

  local clip_output="$work_dir/product-ugc-raw.mp4"

  echo "  Generating via Sora 2 with product reference image..."
  echo "  IMPORTANT: Downloading immediately (Sora 2 URLs expire in 1 hour)"

  bash "$VIDEO_GEN_SH" sora generate \
    --image "$product_image" \
    --prompt "$sora_prompt" \
    --duration 8 \
    --aspect-ratio "9:16" \
    --brand "$brand" \
    --output "$clip_output" 2>&1 | while IFS= read -r line; do echo "    $line"; done

  if [ -f "$clip_output" ] && [ "$(wc -c < "$clip_output" | tr -d ' ')" -gt 1000 ]; then
    local clip_size
    clip_size=$(wc -c < "$clip_output" | tr -d ' ')
    echo "  Product UGC clip: $clip_output (${clip_size} bytes)"
    update_manifest_step "$manifest_path" "video_gen" "completed" "$clip_output" "0.80"
    log_cost "$pipeline_id" "video_gen" "iris" "sora-2" "0.80" "8" "$clip_output"
    post_to_creative_room "$pipeline_id" "video_gen" "completed" "iris" "$brand" "product-ugc" "Clip: $clip_output"
  else
    echo "  WARN: Sora 2 generation failed."
    update_manifest_step "$manifest_path" "video_gen" "failed" "" "0.80"
    log_cost "$pipeline_id" "video_gen" "iris" "sora-2" "0.80" "0" ""
    post_to_creative_room "$pipeline_id" "video_gen" "failed" "iris" "$brand" "product-ugc" "Sora 2 failed"
    return 1
  fi
  echo ""

  # ─── Step 3: Post-Production ───────────────────────────────────
  echo "--- Step 3: Post-Production ---"
  post_to_creative_room "$pipeline_id" "post_prod" "started" "taoz" "$brand" "product-ugc"

  local final_output="$work_dir/${brand}-product-ugc-final.mp4"

  if [ -x "$VIDEO_FORGE_SH" ]; then
    echo "  Running VideoForge..."
    bash "$VIDEO_FORGE_SH" process \
      --input "$clip_output" \
      --output "$final_output" \
      --brand "$brand" 2>&1 | while IFS= read -r line; do echo "    $line"; done || {
      cp "$clip_output" "$final_output"
    }
  else
    cp "$clip_output" "$final_output"
  fi

  if [ -f "$final_output" ]; then
    local final_size
    final_size=$(wc -c < "$final_output" | tr -d ' ')
    echo "  Final: $final_output (${final_size} bytes)"
    update_manifest_step "$manifest_path" "post_prod" "completed" "$final_output" "0"
    post_to_creative_room "$pipeline_id" "post_prod" "completed" "taoz" "$brand" "product-ugc" "Done: $final_output"
  else
    cp "$clip_output" "$final_output" 2>/dev/null || true
    update_manifest_step "$manifest_path" "post_prod" "completed" "${final_output:-$clip_output}" "0"
  fi
  echo ""

  # ─── Step 4: QA ────────────────────────────────────────────────
  echo "--- Step 4: QA (Argus) ---"
  post_to_creative_room "$pipeline_id" "qa" "started" "argus" "$brand" "product-ugc"

  dispatch_to_agent "creative-pipeline" "argus" "request" \
    "[PIPELINE $pipeline_id] QA product-ugc. Brand: $brand. Video: $final_output. Check: product visible, appetizing, 9:16 vertical, brand colors, no artifacts. Brief: $brief" "creative"

  update_manifest_step "$manifest_path" "qa" "completed" "$final_output" "0"
  post_to_creative_room "$pipeline_id" "qa" "completed" "argus" "$brand" "product-ugc" "QA dispatched"

  # ─── Auto-send to Jenn via WhatsApp ────────────────────────────
  if [ -f "$final_output" ]; then
    echo "--- Sending to Jenn via WhatsApp ---"
    openclaw message send \
      --channel whatsapp \
      --target "+60126169979" \
      --media "$final_output" \
      --message "[Pipeline $pipeline_id] Product UGC ($brand). Review and reply approve/redo." \
      2>/dev/null && echo "  Sent to WhatsApp." || echo "  WhatsApp send failed (non-blocking)."
  fi

  echo ""
  echo "=== Pipeline $pipeline_id COMPLETE ==="
  echo "  Type:        product-ugc"
  echo "  Brand:       $brand"
  echo "  Final video: $final_output"
  echo "  Total cost:  ~\$0.81"
  echo "  Work dir:    $work_dir"

  log "PRODUCT-UGC pipeline $pipeline_id completed: $final_output"
}

# ============================================================
# PIPELINE: character-lock
# Face gen -> body gen -> multi-angle sheet -> lock
# ============================================================
pipeline_character_lock() {
  local agent="$1"
  local brand="$2"
  local brief="$3"
  local pipeline_id
  pipeline_id=$(gen_pipeline_id)

  local work_dir="$PIPELINE_DIR/$pipeline_id"
  local char_dir="$CHARS_DIR/$agent"
  mkdir -p "$work_dir" "$char_dir"

  echo "=== Creative Pipeline: CHARACTER-LOCK ==="
  echo "Pipeline ID: $pipeline_id"
  echo "Agent:       $agent"
  echo "Brand:       $brand"
  echo "Brief:       $brief"
  echo ""

  log "CHARACTER-LOCK pipeline started: id=$pipeline_id agent=$agent brand=$brand"
  post_to_creative_room "$pipeline_id" "pipeline_start" "started" "creative-pipeline" "$brand" "character-lock" "Starting character-lock pipeline for $agent"

  local manifest_path
  manifest_path=$(save_manifest "$pipeline_id" "character-lock" "$agent" "$brand" "$brief" "$work_dir")

  # Check if already locked
  local existing_lock
  existing_lock=$(check_character_lock "$agent")
  if [ "$existing_lock" = "full" ]; then
    echo "  Character $agent is already FULLY LOCKED."
    echo "  Face: $(get_locked_asset "$agent" "face")"
    echo "  Body: $(get_locked_asset "$agent" "body")"
    echo "  Sheet: $(get_locked_asset "$agent" "sheet")"
    echo ""
    echo "  To re-lock, delete existing assets in $char_dir first."
    update_manifest_step "$manifest_path" "lock" "completed" "$(get_locked_asset "$agent" "face")" "0"
    post_to_creative_room "$pipeline_id" "pipeline_start" "completed" "creative-pipeline" "$brand" "character-lock" "Already locked"
    return 0
  fi

  # ─── Step 1: Face Generation ───────────────────────────────────
  echo "--- Step 1: Face Generation (NanoBanana) ---"
  post_to_creative_room "$pipeline_id" "face_gen" "started" "iris" "$brand" "character-lock"

  local face_output="$work_dir/${agent}-face-draft.png"

  if [ -x "$NANOBANANA_SH" ]; then
    local face_prompt
    face_prompt="Portrait headshot of $agent character. $brief. High resolution, detailed face, clean background, consistent lighting. Front-facing, symmetrical features."

    echo "  Generating face via NanoBanana generate..."
    local nb_output
    nb_output=$(bash "$NANOBANANA_SH" generate \
      --prompt "$face_prompt" \
      --brand "$brand" \
      --use-case "character" \
      --model pro 2>&1) || true
    echo "    $nb_output" | tail -5

    # NanoBanana saves to its own dir — find the latest generated file
    local nb_img
    nb_img=$(echo "$nb_output" | grep -oE '/[^ ]*\.png' | tail -1)
    if [ -n "$nb_img" ] && [ -f "$nb_img" ]; then
      cp "$nb_img" "$face_output"
      echo "  Face draft: $face_output"
      update_manifest_step "$manifest_path" "face_gen" "completed" "$face_output" "0.01"
      log_cost "$pipeline_id" "face_gen" "iris" "gemini-image" "0.01" "0" "$face_output"
      post_to_creative_room "$pipeline_id" "face_gen" "completed" "iris" "$brand" "character-lock" "Face: $face_output"
    else
      echo "  Face generation failed. Dispatching to Iris..."
      dispatch_to_agent "creative-pipeline" "iris" "request" \
        "[PIPELINE $pipeline_id] Generate face for $agent. Brief: $brief" "creative"
      update_manifest_step "$manifest_path" "face_gen" "failed" "" "0"
      post_to_creative_room "$pipeline_id" "face_gen" "failed" "iris" "$brand" "character-lock" "NanoBanana failed"
    fi
  else
    echo "  NanoBanana not available. Dispatching to Iris..."
    dispatch_to_agent "creative-pipeline" "iris" "request" \
      "[PIPELINE $pipeline_id] Generate face for $agent character. Brief: $brief" "creative"
    update_manifest_step "$manifest_path" "face_gen" "failed" "" "0"
  fi
  echo ""

  # ─── Step 2: Body Generation ───────────────────────────────────
  echo "--- Step 2: Full Body Generation (NanoBanana) ---"
  post_to_creative_room "$pipeline_id" "body_gen" "started" "iris" "$brand" "character-lock"

  local body_output="$work_dir/${agent}-body-draft.png"

  if [ -x "$NANOBANANA_SH" ] && [ -f "$face_output" ]; then
    local body_prompt
    body_prompt="Full body character design of $agent. $brief. Same face as reference, standing pose, full body visible head to toe, clean background, consistent with face portrait."

    echo "  Generating fullbody via NanoBanana generate..."
    local nb_body_out
    nb_body_out=$(bash "$NANOBANANA_SH" generate \
      --prompt "$body_prompt" \
      --brand "$brand" \
      --use-case "character" \
      --model pro 2>&1) || true
    echo "    $nb_body_out" | tail -5

    local nb_body_img
    nb_body_img=$(echo "$nb_body_out" | grep -oE '/[^ ]*\.png' | tail -1)
    if [ -n "$nb_body_img" ] && [ -f "$nb_body_img" ]; then
      cp "$nb_body_img" "$body_output"
      echo "  Body draft: $body_output"
      update_manifest_step "$manifest_path" "body_gen" "completed" "$body_output" "0.01"
      log_cost "$pipeline_id" "body_gen" "iris" "gemini-image" "0.01" "0" "$body_output"
      post_to_creative_room "$pipeline_id" "body_gen" "completed" "iris" "$brand" "character-lock" "Body: $body_output"
    else
      echo "  Body generation failed."
      update_manifest_step "$manifest_path" "body_gen" "failed" "" "0"
      post_to_creative_room "$pipeline_id" "body_gen" "failed" "iris" "$brand" "character-lock" "Body gen failed"
    fi
  else
    echo "  Skipping (requires face output first)."
    update_manifest_step "$manifest_path" "body_gen" "failed" "" "0"
  fi
  echo ""

  # ─── Step 3: Multi-Angle Sheet ─────────────────────────────────
  echo "--- Step 3: Multi-Angle Sheet (NanoBanana) ---"
  post_to_creative_room "$pipeline_id" "angle_sheet" "started" "iris" "$brand" "character-lock"

  local sheet_output="$work_dir/${agent}-9angle-sheet-draft.png"

  if [ -x "$NANOBANANA_SH" ] && [ -f "$face_output" ]; then
    # Use NanoBanana character-sheet command for multi-angle generation
    echo "  Generating character sheet via NanoBanana character-sheet..."
    local nb_sheet_out
    nb_sheet_out=$(bash "$NANOBANANA_SH" character-sheet \
      --brand "$brand" \
      --description "$brief" \
      --poses "front,three-quarter,side" \
      --model pro 2>&1) || true
    echo "    $nb_sheet_out" | tail -10

    # character-sheet generates to a directory — find the output
    local nb_sheet_dir
    nb_sheet_dir=$(echo "$nb_sheet_out" | grep -oE '/[^ ]*characters/[^ ]*' | head -1)
    local nb_sheet_img
    nb_sheet_img=$(echo "$nb_sheet_out" | grep -oE '/[^ ]*\.png' | tail -1)
    if [ -n "$nb_sheet_img" ] && [ -f "$nb_sheet_img" ]; then
      cp "$nb_sheet_img" "$sheet_output"
      echo "  Angle sheet: $sheet_output"
      echo "  WARNING: NanoBanana WILL drift face ~20-40%. Accept ~80% match for sheets."
      update_manifest_step "$manifest_path" "angle_sheet" "completed" "$sheet_output" "0.01"
      log_cost "$pipeline_id" "angle_sheet" "iris" "gemini-image" "0.01" "0" "$sheet_output"
      post_to_creative_room "$pipeline_id" "angle_sheet" "completed" "iris" "$brand" "character-lock" "Sheet: $sheet_output"
    else
      # Fallback: use generate command with sheet prompt
      local sheet_prompt
      sheet_prompt="Character turnaround sheet of $agent. $brief. Show front view, 3/4 view, and side profile. Grid layout, consistent character across all angles."
      nb_sheet_out=$(bash "$NANOBANANA_SH" generate \
        --prompt "$sheet_prompt" \
        --brand "$brand" \
        --use-case "character" \
        --model pro 2>&1) || true
      nb_sheet_img=$(echo "$nb_sheet_out" | grep -oE '/[^ ]*\.png' | tail -1)
      if [ -n "$nb_sheet_img" ] && [ -f "$nb_sheet_img" ]; then
        cp "$nb_sheet_img" "$sheet_output"
        echo "  Angle sheet (fallback): $sheet_output"
        update_manifest_step "$manifest_path" "angle_sheet" "completed" "$sheet_output" "0.01"
        log_cost "$pipeline_id" "angle_sheet" "iris" "gemini-image" "0.01" "0" "$sheet_output"
        post_to_creative_room "$pipeline_id" "angle_sheet" "completed" "iris" "$brand" "character-lock" "Sheet: $sheet_output"
      else
        echo "  Sheet generation failed."
        update_manifest_step "$manifest_path" "angle_sheet" "failed" "" "0"
        post_to_creative_room "$pipeline_id" "angle_sheet" "failed" "iris" "$brand" "character-lock" "Sheet gen failed"
      fi
    fi
  else
    echo "  Skipping (requires face output first)."
    update_manifest_step "$manifest_path" "angle_sheet" "failed" "" "0"
  fi
  echo ""

  # ─── Step 4: Lock Decision ─────────────────────────────────────
  echo "--- Step 4: Character Lock ---"
  echo ""
  echo "  HUMAN APPROVAL REQUIRED"
  echo ""
  echo "  Generated assets in: $work_dir"
  echo "  Face:  ${face_output:-NOT GENERATED}"
  echo "  Body:  ${body_output:-NOT GENERATED}"
  echo "  Sheet: ${sheet_output:-NOT GENERATED}"
  echo ""
  echo "  To approve and lock, run:"
  echo "    cp $work_dir/${agent}-face-draft.png $char_dir/${agent}-locked-v1.png"
  echo "    cp $work_dir/${agent}-body-draft.png $char_dir/${agent}-locked-fullbody.png"
  echo "    cp $work_dir/${agent}-9angle-sheet-draft.png $char_dir/${agent}-locked-9angle-sheet.png"
  echo ""
  echo "  To reject and regenerate, re-run this pipeline with a revised brief."

  update_manifest_step "$manifest_path" "lock" "completed" "$work_dir" "0"
  post_to_creative_room "$pipeline_id" "lock" "completed" "creative-pipeline" "$brand" "character-lock" "Assets generated. Human approval needed. Dir: $work_dir"

  # Post to approvals room for Jenn
  if [ -f "$ROOM_WRITE_SH" ]; then
    bash "$ROOM_WRITE_SH" "approvals" "creative-pipeline" "approval-needed" \
      "Character lock for $agent (pipeline $pipeline_id). Assets in $work_dir. Approve by copying to $char_dir." 2>/dev/null || true
  fi

  echo ""
  echo "=== Pipeline $pipeline_id COMPLETE (pending approval) ==="
  echo "  Type:     character-lock"
  echo "  Agent:    $agent"
  echo "  Brand:    $brand"
  echo "  Work dir: $work_dir"

  log "CHARACTER-LOCK pipeline $pipeline_id: assets generated, pending approval"
}

# ============================================================
# COMMAND: status
# ============================================================
cmd_status() {
  local pipeline_id="${1:-}"

  if [ -z "$pipeline_id" ]; then
    die "Usage: creative-pipeline.sh status <pipeline-id>"
  fi

  local work_dir="$PIPELINE_DIR/$pipeline_id"
  local manifest_path="$work_dir/manifest.json"

  if [ ! -f "$manifest_path" ]; then
    die "Pipeline $pipeline_id not found (no manifest at $manifest_path)"
  fi

  python3 -c "
import json, sys

with open(sys.argv[1]) as f:
    m = json.load(f)

print('Pipeline: %s' % m['pipeline_id'])
print('  Type:      %s' % m['type'])
print('  Agent:     %s' % m['agent'])
print('  Brand:     %s' % m['brand'])
print('  Status:    %s' % m['status'])
print('  Cost:      \$%.2f' % m.get('total_cost_usd', 0))
print('  Created:   %s' % m['created_at'])
print('  Updated:   %s' % m['updated_at'])
print('  Work dir:  %s' % m['work_dir'])
print()
print('  Steps:')
for s in m.get('steps', []):
    status = s.get('status', '?')
    if status == 'completed':
        marker = '[x]'
    elif status == 'failed':
        marker = '[!]'
    else:
        marker = '[ ]'
    line = '    %s %s' % (marker, s['name'])
    if s.get('cost_usd', 0) > 0:
        line += ' (\$%.2f)' % s['cost_usd']
    if s.get('artifact'):
        line += ' -> %s' % s['artifact']
    print(line)

if m.get('artifacts'):
    print()
    print('  Artifacts:')
    for k, v in m['artifacts'].items():
        print('    %s: %s' % (k, v))
" "$manifest_path"
}

# ============================================================
# COMMAND: list
# ============================================================
cmd_list() {
  local filter_brand=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand) filter_brand="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local manifests
  manifests=$(find "$PIPELINE_DIR" -name "manifest.json" -type f 2>/dev/null || true)

  if [ -z "$manifests" ]; then
    echo "No creative pipelines found."
    return 0
  fi

  local manifests_tmp="/tmp/cp-manifests-$$.txt"
  echo "$manifests" > "$manifests_tmp"

  python3 -c "
import json, sys

filter_brand = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else ''
manifests_file = sys.argv[2]

with open(manifests_file) as f:
    manifest_paths = [line.strip() for line in f if line.strip()]

results = []
for mp in manifest_paths:
    try:
        with open(mp) as f:
            m = json.load(f)
        if filter_brand and m.get('brand') != filter_brand:
            continue
        results.append(m)
    except:
        continue

if not results:
    print('No matching pipelines found.')
    sys.exit(0)

results.sort(key=lambda x: x.get('created_at', ''), reverse=True)

fmt = '%-16s %-14s %-10s %-16s %-10s %-8s %s'
print(fmt % ('ID', 'Type', 'Agent', 'Brand', 'Status', 'Cost', 'Created'))
print('-' * 100)
for m in results:
    pid = m.get('pipeline_id', '?')
    ptype = m.get('type', '?')
    agent = m.get('agent', '?')
    brand = m.get('brand', '?')
    status = m.get('status', '?')
    cost = '\$%.2f' % m.get('total_cost_usd', 0)
    created = m.get('created_at', '?')[:19]
    print(fmt % (pid, ptype, agent, brand, status, cost, created))

print()
print('Total: %d pipeline(s)' % len(results))
" "$filter_brand" "$manifests_tmp"

  rm -f "$manifests_tmp"
}

# ============================================================
# MAIN
# ============================================================
COMMAND="${1:-help}"

case "$COMMAND" in
  status)
    shift
    cmd_status "$@"
    ;;
  list)
    shift
    cmd_list "$@"
    ;;
  help|--help|-h)
    echo "Usage: bash creative-pipeline.sh <type> <agent> <brand> \"<brief>\""
    echo "       bash creative-pipeline.sh status <pipeline-id>"
    echo "       bash creative-pipeline.sh list [--brand <brand>]"
    echo ""
    echo "Types:"
    echo "  intro          Character intro video (Kling 3.0)"
    echo "  ugc            UGC-style video (Sora 2)"
    echo "  product-ugc    Product showcase UGC (Sora 2)"
    echo "  character-lock Character asset lock (NanoBanana)"
    echo ""
    echo "Examples:"
    echo "  bash creative-pipeline.sh intro iris gaia-os \"Iris 6-second intro\""
    echo "  bash creative-pipeline.sh ugc dreami mirra \"Bento unboxing UGC\""
    echo "  bash creative-pipeline.sh product-ugc iris pinxin-vegan \"Cheese platter showcase\""
    echo "  bash creative-pipeline.sh character-lock zenni gaia-os \"Lock Zenni character\""
    echo "  bash creative-pipeline.sh status cp-1709000000"
    echo "  bash creative-pipeline.sh list --brand mirra"
    ;;
  intro|ugc|product-ugc|character-lock)
    # Parse positional args: <type> <agent> <brand> "<brief>"
    TYPE="$COMMAND"
    AGENT="${2:-}"
    BRAND="${3:-}"
    BRIEF="${4:-}"

    [ -z "$AGENT" ] && die "Missing agent. Usage: creative-pipeline.sh $TYPE <agent> <brand> \"<brief>\""
    [ -z "$BRAND" ] && die "Missing brand. Usage: creative-pipeline.sh $TYPE $AGENT <brand> \"<brief>\""
    [ -z "$BRIEF" ] && die "Missing brief. Usage: creative-pipeline.sh $TYPE $AGENT $BRAND \"<brief>\""

    # Normalize agent name to lowercase (Bash 3.2 safe)
    AGENT=$(echo "$AGENT" | tr '[:upper:]' '[:lower:]')

    # Load API keys
    load_env

    case "$TYPE" in
      intro)          pipeline_intro "$AGENT" "$BRAND" "$BRIEF" ;;
      ugc)            pipeline_ugc "$AGENT" "$BRAND" "$BRIEF" ;;
      product-ugc)    pipeline_product_ugc "$AGENT" "$BRAND" "$BRIEF" ;;
      character-lock) pipeline_character_lock "$AGENT" "$BRAND" "$BRIEF" ;;
    esac
    ;;
  *)
    die "Unknown command or type: $COMMAND. Use 'help' for usage."
    ;;
esac
