#!/usr/bin/env bash
# video-gen.sh — Unified video generation CLI for GAIA CORP-OS
# Usage: bash video-gen.sh <provider|command> [subcommand] [options]
#
# Providers: kling, wan, sora
# Commands:  pipeline, reverse-prompt, status
#
# macOS Bash 3.2 compatible — no declare -A, no ${var,,}, no timeout, no jq

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$HOME/.openclaw/.env"
OUTPUT_DIR="$HOME/.openclaw/workspace/data/videos"
BRANDS_DIR="$HOME/.openclaw/brands"
ROOM_WRITE="$HOME/.openclaw/workspace/scripts/room-write.sh"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"
NANOBANANA="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
VIDEO_FORGE="$HOME/.openclaw/skills/video-forge/scripts/video-forge.sh"
LOG_FILE="$HOME/.openclaw/workspace/logs/video-gen.log"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# ============================================================
# HELPERS
# ============================================================

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

load_env() {
  # Load .env file — parse KEY=VALUE lines, skip comments
  if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
      # Skip empty lines and comments
      case "$line" in
        ""|\#*) continue ;;
      esac
      # Only export lines that look like KEY=VALUE
      case "$line" in
        *=*)
          local key
          key=$(echo "$line" | cut -d= -f1)
          local val
          val=$(echo "$line" | cut -d= -f2-)
          # Strip surrounding quotes
          val=$(echo "$val" | sed "s/^['\"]//;s/['\"]$//")
          export "$key=$val" 2>/dev/null || true
          ;;
      esac
    done < "$ENV_FILE"
  fi

  # Also try .zshrc for keys not yet set
  if [ -z "${KLING_ACCESS_KEY:-}" ]; then
    KLING_ACCESS_KEY=$(grep 'KLING_ACCESS_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*KLING_ACCESS_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export KLING_ACCESS_KEY
  fi
  if [ -z "${KLING_SECRET_KEY:-}" ]; then
    KLING_SECRET_KEY=$(grep 'KLING_SECRET_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*KLING_SECRET_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export KLING_SECRET_KEY
  fi
  if [ -z "${FAL_API_KEY:-}" ]; then
    FAL_API_KEY=$(grep 'FAL_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*FAL_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export FAL_API_KEY
    # Also try fal.env
    if [ -z "${FAL_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/fal.env" ]; then
      FAL_API_KEY=$(grep '^FAL_API_KEY=' "$HOME/.openclaw/secrets/fal.env" | head -1 | cut -d= -f2- | sed "s/^['\"]//;s/['\"]$//")
      export FAL_API_KEY
    fi
  fi
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    OPENAI_API_KEY=$(grep 'OPENAI_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*OPENAI_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export OPENAI_API_KEY
  fi
  if [ -z "${GEMINI_API_KEY:-}" ]; then
    GEMINI_API_KEY=$(grep 'GEMINI_API_KEY=' "$HOME/.zshrc" 2>/dev/null | head -1 | sed "s/.*GEMINI_API_KEY=['\"]*//" | sed "s/['\"].*//" || true)
    export GEMINI_API_KEY
  fi
}

# Load brand DNA motion language, colors, tone
load_brand_motion() {
  local brand="$1"
  local dna="$BRANDS_DIR/$brand/DNA.json"
  if [ -f "$dna" ]; then
    python3 << PYEOF
import json
d = json.load(open('$dna'))
ml = d.get('motion_language', {})
if isinstance(ml, dict):
    parts = []
    if ml.get('vibe'): parts.append('Vibe: ' + ml['vibe'])
    if ml.get('motion'): parts.append('Motion: ' + ml['motion'])
    if ml.get('audio'): parts.append('Audio cues: ' + ml['audio'])
    print(' | '.join(parts))
elif isinstance(ml, str) and ml:
    print(ml)
PYEOF
  fi
}

load_brand_colors() {
  local brand="$1"
  local dna="$BRANDS_DIR/$brand/DNA.json"
  if [ -f "$dna" ]; then
    python3 << PYEOF
import json
d = json.load(open('$dna'))
v = d.get('visual', d.get('visual_identity', {}))
colors = v.get('colors', {})
if colors:
    parts = []
    for k, c in colors.items():
        parts.append(k + ':' + str(c))
    print(', '.join(parts))
PYEOF
  fi
}

load_brand_tone() {
  local brand="$1"
  local dna="$BRANDS_DIR/$brand/DNA.json"
  if [ -f "$dna" ]; then
    python3 << PYEOF
import json
d = json.load(open('$dna'))
voice = d.get('voice', {})
tone = voice.get('tone', '')
if tone:
    print(tone)
PYEOF
  fi
}

# Enhance prompt with brand DNA
enhance_prompt() {
  local prompt="$1"
  local brand="${2:-}"

  if [ -z "$brand" ]; then
    echo "$prompt"
    return
  fi

  local motion
  motion=$(load_brand_motion "$brand")
  local colors
  colors=$(load_brand_colors "$brand")
  local tone
  tone=$(load_brand_tone "$brand")

  local enhanced="$prompt"
  if [ -n "$motion" ]; then
    enhanced="$enhanced. Style: $motion"
  fi
  if [ -n "$colors" ]; then
    enhanced="$enhanced. Colors: $colors"
  fi
  if [ -n "$tone" ]; then
    enhanced="$enhanced. Mood: $tone"
  fi

  echo "$enhanced"
}

# Parse common options from args — sets global variables
# Globals: OPT_PROMPT, OPT_IMAGE, OPT_BRAND, OPT_DURATION, OPT_ASPECT_RATIO,
#          OPT_OUTPUT_TYPE, OPT_OUTPUT, OPT_DRY_RUN, OPT_EXTRA_ARGS
OPT_PROMPT=""
OPT_IMAGE=""
OPT_BRAND=""
OPT_DURATION="5"
OPT_ASPECT_RATIO="9:16"
OPT_OUTPUT_TYPE=""
OPT_OUTPUT=""
OPT_DRY_RUN=0
OPT_RESOLUTION="720p"
OPT_MODEL=""
OPT_MODE="std"
OPT_PRO=0
OPT_PROVIDER="wan"
OPT_SCENES=3
OPT_AUTO_REF=0
OPT_NO_FORGE=0

parse_opts() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt)        OPT_PROMPT="$2"; shift 2 ;;
      --image)         OPT_IMAGE="$2"; shift 2 ;;
      --brand)         OPT_BRAND="$2"; shift 2 ;;
      --duration)      OPT_DURATION="$2"; shift 2 ;;
      --aspect-ratio)  OPT_ASPECT_RATIO="$2"; shift 2 ;;
      --ratio)         OPT_ASPECT_RATIO="$2"; shift 2 ;;
      --output-type)   OPT_OUTPUT_TYPE="$2"; shift 2 ;;
      --output)        OPT_OUTPUT="$2"; shift 2 ;;
      --dry-run)       OPT_DRY_RUN=1; shift ;;
      --resolution)    OPT_RESOLUTION="$2"; shift 2 ;;
      --model)         OPT_MODEL="$2"; shift 2 ;;
      --mode)          OPT_MODE="$2"; shift 2 ;;
      --pro)           OPT_PRO=1; shift ;;
      --provider)      OPT_PROVIDER="$2"; shift 2 ;;
      --scenes)        OPT_SCENES="$2"; shift 2 ;;
      --seconds)       OPT_DURATION="$2"; shift 2 ;;
      --size)          # Convert WxH to aspect ratio for Sora
                       OPT_RESOLUTION="$2"; shift 2 ;;
      --auto-ref)      OPT_AUTO_REF=1; shift ;;
      --no-forge)      OPT_NO_FORGE=1; shift ;;
      -*)              echo "Unknown option: $1"; exit 1 ;;
      *)               # Positional = prompt
                       if [ -z "$OPT_PROMPT" ]; then
                         OPT_PROMPT="$1"
                       fi
                       shift ;;
    esac
  done
}

# Duration to frame count for Wan (16fps + 1)
duration_to_frames() {
  local duration="$1"
  echo $(( duration * 16 + 1 ))
}

# Encode local file as data URI for fal.ai
# Upload local file to fal.ai CDN, returns public URL
# Uses fal_client.upload_file() — official fal.ai solution
upload_to_fal_cdn() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "" ; return 1
  fi
  python3 -c "
import os, sys
os.environ.setdefault('FAL_KEY', os.environ.get('FAL_API_KEY', ''))
try:
    import fal_client
    url = fal_client.upload_file('$file')
    print(url)
except Exception as e:
    print('', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null
}

encode_image_for_fal() {
  local image_path="$1"
  local ext
  ext=$(echo "$image_path" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
  local mime="image/jpeg"
  case "$ext" in
    png)       mime="image/png" ;;
    gif)       mime="image/gif" ;;
    webp)      mime="image/webp" ;;
    jpg|jpeg)  mime="image/jpeg" ;;
  esac
  local b64
  b64=$(base64 < "$image_path" | tr -d '\n')
  echo "data:${mime};base64,${b64}"
}

# ============================================================
# AUTO-REFERENCE IMAGE SELECTION
# ============================================================
# When --brand is specified, auto-find the best product photo to use as
# reference image for image2video (instead of text-only generation).
# Searches: brands/{brand}/references/products-flat/ (top-view bento photos)
#           brands/{brand}/references/products/ (nested refs)

auto_select_reference() {
  local brand="$1"
  local prompt_lower="$2"
  local refs_dir="$BRANDS_DIR/$brand/references/products-flat"
  local refs_nested="$BRANDS_DIR/$brand/references/products"

  # Try to match product name from prompt to a specific photo
  local match=""
  if [ -d "$refs_dir" ]; then
    # Keyword → filename mapping (Mirra bentos)
    if echo "$prompt_lower" | grep -qiE 'fusilli|bolognese|pasta'; then
      match=$(find "$refs_dir" -iname "*fusilli*" -o -iname "*bolognese*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'pad thai|padthai|konjac.*pad'; then
      match=$(find "$refs_dir" -iname "*pad*thai*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'curry.*katsu|katsu'; then
      match=$(find "$refs_dir" -iname "*katsu*" -o -iname "*curry*katsu*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'burrito|buritto'; then
      match=$(find "$refs_dir" -iname "*burri*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'bbq|pita|mushroom.*wrap'; then
      match=$(find "$refs_dir" -iname "*bbq*" -o -iname "*pita*" -o -iname "*mushroom*wrap*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'eryngii|golden.*rice|fragrant'; then
      match=$(find "$refs_dir" -iname "*eryngii*" -o -iname "*golden*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'curry.*noodle|konjac.*noodle'; then
      match=$(find "$refs_dir" -iname "*curry*noodle*" -o -iname "*konjac*noodle*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'nasi.*lemak'; then
      # No specific nasi lemak photo yet — use group image
      match=$(find "$refs_dir" -iname "group*" 2>/dev/null | head -1)
    elif echo "$prompt_lower" | grep -qiE 'group|multiple|weekly|menu|collection|lineup|5.*bento|bento.*line'; then
      match=$(find "$refs_dir" -iname "group*" 2>/dev/null | head -1)
    fi

    # Fallback: random top-view photo from refs dir
    if [ -z "$match" ]; then
      match=$(find "$refs_dir" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | head -1)
    fi
  fi

  # Try nested refs if flat dir didn't match
  if [ -z "$match" ] && [ -d "$refs_nested" ]; then
    match=$(find "$refs_nested" -name "ref-*.png" -o -name "ref-*.jpg" 2>/dev/null | head -1)
  fi

  echo "$match"
}

# ============================================================
# POST-GENERATION HOOKS
# ============================================================

post_generate() {
  local provider="$1"
  local task_id="$2"
  local video_path="$3"
  local brand="${4:-}"
  local prompt="${5:-}"

  # Register in content-seed-bank
  if [ -n "$brand" ] && [ -x "$SEED_STORE" ]; then
    bash "$SEED_STORE" add \
      --type video --text "${prompt:-video from $provider}" --brand "$brand" \
      --tags "video,$provider" \
      --source-agent iris --source-type video-gen 2>/dev/null || true
  fi

  # Post to creative room
  if [ -x "$ROOM_WRITE" ]; then
    bash "$ROOM_WRITE" creative "video-gen" "video-generated" "Video generated via $provider: $video_path" 2>/dev/null || true
  fi

  # AUTO-FORGE: Run video-forge produce if brand is specified
  # Applies: captions, branding (logo/watermark), music, platform export
  if [ -n "$brand" ] && [ -x "$VIDEO_FORGE" ] && [ "$OPT_NO_FORGE" != "1" ]; then
    local forge_output="${video_path%.mp4}-produced.mp4"
    log "Auto-forge: brand=$brand input=$video_path"
    echo ""
    echo "--- Auto Post-Production (video-forge) ---"
    bash "$VIDEO_FORGE" brand --input "$video_path" --brand "$brand" --output "$forge_output" 2>&1 | tail -5 || {
      log "WARNING: Auto-forge brand failed for $video_path"
      echo "  WARNING: Auto-forge failed, raw video still saved"
    }
    if [ -f "$forge_output" ]; then
      echo "  Produced: $forge_output"
      log "Auto-forge complete: $forge_output"
    fi
  fi

  # POST to Iris QA room for visual review
  if [ -x "$ROOM_WRITE" ]; then
    bash "$ROOM_WRITE" iris-qa "video-gen" "video-qa-request" \
      "Please review video quality: $video_path (brand: ${brand:-none}, provider: $provider)" 2>/dev/null || true
  fi

  log "Generated: provider=$provider task=$task_id output=$video_path brand=$brand"
  echo ""
  echo "✅ Written to creative (JSONL + Supabase)"
  echo "$video_path"
}

# ============================================================
# KLING PROVIDER
# ============================================================

KLING_BASE_URL="https://api.klingai.com"

kling_auth() {
  # HMAC-SHA256 JWT generation — no PyJWT required, pure stdlib
  python3 << 'PYEOF'
import hmac, hashlib, base64, time, json, os

access_key = os.environ.get("KLING_ACCESS_KEY", "")
secret_key = os.environ.get("KLING_SECRET_KEY", "")

if not access_key or not secret_key:
    import sys
    print("ERROR: KLING_ACCESS_KEY and KLING_SECRET_KEY required", file=sys.stderr)
    sys.exit(1)

def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

header = b64url(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
now = int(time.time())
payload = b64url(json.dumps({
    "iss": access_key,
    "exp": now + 1800,
    "nbf": now - 5,
    "iat": now
}).encode())
sig = b64url(hmac.new(
    secret_key.encode(),
    (header + "." + payload).encode(),
    hashlib.sha256
).digest())
print(header + "." + payload + "." + sig)
PYEOF
}

kling_text2video() {
  parse_opts "$@"

  if [ -z "$OPT_PROMPT" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: video-gen.sh kling text2video \"prompt\" [--duration 5] [--aspect-ratio 9:16] [--brand pinxin-vegan]"
    exit 1
  fi

  local model="${OPT_MODEL:-kling-v3}"
  local duration="$OPT_DURATION"
  local ratio="$OPT_ASPECT_RATIO"
  local mode="$OPT_MODE"
  local output="$OPT_OUTPUT"
  local brand="$OPT_BRAND"

  # Enhance prompt with brand DNA
  local prompt
  prompt=$(enhance_prompt "$OPT_PROMPT" "$brand")

  echo "=== Kling Text-to-Video ==="
  echo "Prompt:   $prompt"
  echo "Duration: ${duration}s"
  echo "Ratio:    $ratio"
  echo "Model:    $model"
  echo "Mode:     $mode"
  echo "Est cost: ~\$0.30"
  echo ""

  log "kling text2video: model=$model duration=$duration ratio=$ratio mode=$mode"
  log "Prompt: $prompt"

  if [ "$OPT_DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would POST to: ${KLING_BASE_URL}/v1/videos/text2video"
    exit 0
  fi

  if [ -z "${KLING_ACCESS_KEY:-}" ] || [ -z "${KLING_SECRET_KEY:-}" ]; then
    echo "ERROR: KLING_ACCESS_KEY and KLING_SECRET_KEY required"
    echo "Set in ~/.openclaw/.env or environment"
    exit 1
  fi

  local token
  token=$(kling_auth)

  local response
  response=$(curl -s -X POST "${KLING_BASE_URL}/v1/videos/text2video" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
d = {
    'model_name': sys.argv[1],
    'prompt': sys.argv[2],
    'duration': int(sys.argv[3]),
    'aspect_ratio': sys.argv[4],
    'mode': sys.argv[5]
}
# Kling v3.0+ supports native audio generation
if 'v3' in sys.argv[1] or 'v2-6' in sys.argv[1] or 'v2-5' in sys.argv[1]:
    d['enable_audio'] = True
print(json.dumps(d))
" "$model" "$prompt" "$duration" "$ratio" "$mode")")

  local task_id
  task_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('task_id',''))" 2>/dev/null)

  if [ -z "$task_id" ]; then
    echo "ERROR: Failed to create task"
    echo "$response"
    log "ERROR: kling text2video create failed — $response"
    exit 1
  fi

  echo "Task created: $task_id"
  log "Task created: $task_id"

  # Poll for completion
  echo "Polling for completion (every 15s, max 15min)..."
  local max_attempts=60
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    # Refresh token every 10 minutes
    if [ $((attempt % 40)) -eq 0 ]; then
      token=$(kling_auth)
    fi

    local status_resp
    status_resp=$(curl -s -X GET "${KLING_BASE_URL}/v1/videos/text2video/${task_id}" \
      -H "Authorization: Bearer ${token}")

    local status
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status','unknown'))" 2>/dev/null)

    echo "  [$attempt] Status: $status"

    if [ "$status" = "succeed" ]; then
      local video_url
      video_url=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['task_result']['videos'][0]['url'])" 2>/dev/null)

      if [ -z "$output" ]; then
        output="${OUTPUT_DIR}/kling-${task_id}.mp4"
      fi

      curl -s -o "$output" "$video_url"
      local file_size
      file_size=$(wc -c < "$output" | tr -d ' ')

      echo ""
      echo "=== Complete ==="
      echo "Video saved: $output"
      echo "File size:   ${file_size} bytes"
      echo "Cost:        ~\$0.30"
      log "Video saved: $output (${file_size} bytes, task=$task_id)"

      post_generate "kling" "$task_id" "$output" "$brand" "$OPT_PROMPT"
      echo "$output"
      exit 0

    elif [ "$status" = "failed" ]; then
      local err_msg
      err_msg=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status_msg','unknown'))" 2>/dev/null)
      echo "FAILED: $err_msg"
      log "FAILED: kling text2video $task_id — $err_msg"
      exit 1
    fi
  done

  echo "TIMEOUT: Video generation timed out after 15 minutes"
  echo "Check status: video-gen.sh kling status $task_id"
  log "TIMEOUT: kling text2video $task_id"
  exit 1
}

kling_image2video() {
  parse_opts "$@"

  if [ -z "$OPT_IMAGE" ]; then
    echo "ERROR: --image URL is required for image2video"
    echo "Usage: video-gen.sh kling image2video --image \"url\" [--prompt \"...\"] [--duration 5]"
    exit 1
  fi

  local model="${OPT_MODEL:-kling-v3}"
  local duration="$OPT_DURATION"
  local mode="$OPT_MODE"
  local output="$OPT_OUTPUT"
  local brand="$OPT_BRAND"
  local image_url="$OPT_IMAGE"

  # Kling direct API accepts both public URLs and base64 data URIs.
  # For local files: upload to fal.ai CDN (preferred) or encode as base64 (fallback).
  local image_file_ref="/tmp/kling-image-ref-$$.txt"
  if [ -f "$image_url" ]; then
    echo "Local file detected — uploading to fal.ai CDN for Kling..."
    log "kling image2video: local file, uploading to fal CDN"
    local cdn_url
    cdn_url=$(upload_to_fal_cdn "$image_url" 2>/dev/null)
    if [ -n "$cdn_url" ] && [[ "$cdn_url" == http* ]]; then
      echo "Uploaded: $cdn_url"
      image_url="$cdn_url"
    else
      echo "fal CDN upload failed, falling back to base64 encoding..."
      log "kling image2video: fal CDN failed, using base64"
      image_url=$(encode_image_for_fal "$image_url")
    fi
  fi
  echo -n "$image_url" > "$image_file_ref"

  local prompt
  prompt=$(enhance_prompt "${OPT_PROMPT:-}" "$brand")

  echo "=== Kling Image-to-Video ==="
  echo "Image:    ${OPT_IMAGE}"
  echo "Prompt:   ${prompt:-<none>}"
  echo "Duration: ${duration}s"
  echo "Est cost: ~\$0.30"
  echo ""

  log "kling image2video: image=$image_url duration=$duration"

  if [ "$OPT_DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would POST to: ${KLING_BASE_URL}/v1/videos/image2video"
    exit 0
  fi

  if [ -z "${KLING_ACCESS_KEY:-}" ] || [ -z "${KLING_SECRET_KEY:-}" ]; then
    echo "ERROR: KLING_ACCESS_KEY and KLING_SECRET_KEY required"
    exit 1
  fi

  local token
  token=$(kling_auth)

  # Build payload via temp file (handles large base64 images without shell arg limit)
  local tmp_payload="/tmp/kling-i2v-payload-$$.json"
  python3 -c "
import json, sys
with open(sys.argv[4]) as f:
    image_val = f.read()
d = {
    'model_name': sys.argv[1],
    'duration': int(sys.argv[2]),
    'mode': sys.argv[3],
    'image': image_val
}
if sys.argv[5]:
    d['prompt'] = sys.argv[5]
# Kling v3.0+ supports native audio
if 'v3' in sys.argv[1] or 'v2-6' in sys.argv[1] or 'v2-5' in sys.argv[1]:
    d['enable_audio'] = True
with open(sys.argv[6], 'w') as f:
    json.dump(d, f)
" "$model" "$duration" "$mode" "$image_file_ref" "$prompt" "$tmp_payload"
  rm -f "$image_file_ref"

  local response
  response=$(curl -s -X POST "${KLING_BASE_URL}/v1/videos/image2video" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "@${tmp_payload}")
  rm -f "$tmp_payload"

  local task_id
  task_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('task_id',''))" 2>/dev/null)

  if [ -z "$task_id" ]; then
    # Check if balance error — auto-fallback to fal.ai Kling
    local err_code
    err_code=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
    if [ "$err_code" = "1102" ] && [ -n "${FAL_API_KEY:-}" ]; then
      echo "Kling direct API has no balance — switching to fal.ai Kling..."
      log "kling image2video: balance empty, fallback to fal.ai"
      # Read image from ref file (URL or base64)
      local fal_image
      fal_image=$(cat "$image_file_ref" 2>/dev/null || echo "$image_url")
      rm -f "$image_file_ref" "$tmp_payload"
      local fal_result
      fal_result=$(FAL_KEY="$FAL_API_KEY" python3 -c "
import os, fal_client, json, sys
result = fal_client.run(
    'fal-ai/kling-video/v3/standard/image-to-video',
    arguments={
        'image_url': sys.argv[1],
        'prompt': sys.argv[2],
        'duration': sys.argv[3],
        'aspect_ratio': sys.argv[4]
    }
)
print(json.dumps(result, default=str))
" "$fal_image" "$prompt" "$duration" "$OPT_ASPECT_RATIO" 2>&1)

      local fal_video_url
      fal_video_url=$(echo "$fal_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('video',{}).get('url',''))" 2>/dev/null)
      if [ -n "$fal_video_url" ]; then
        if [ -z "$output" ]; then
          output="${OUTPUT_DIR}/kling-fal-$(date +%s).mp4"
        fi
        curl -s -o "$output" "$fal_video_url"
        local file_size
        file_size=$(wc -c < "$output" | tr -d ' ')
        echo ""
        echo "=== Complete (via fal.ai) ==="
        echo "Video saved: $output"
        echo "File size:   $file_size bytes"
        echo "Cost:        ~\$0.28 (fal.ai standard)"
        echo "$output"
        return 0
      else
        echo "ERROR: fal.ai Kling also failed"
        echo "$fal_result"
        log "ERROR: fal.ai kling also failed — $fal_result"
        exit 1
      fi
    fi
    echo "ERROR: Failed to create task"
    echo "$response"
    log "ERROR: kling image2video create failed — $response"
    exit 1
  fi

  echo "Task created: $task_id"
  echo "Polling for completion (every 15s, max 15min)..."

  local max_attempts=60
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    if [ $((attempt % 40)) -eq 0 ]; then
      token=$(kling_auth)
    fi

    local status_resp
    status_resp=$(curl -s -X GET "${KLING_BASE_URL}/v1/videos/image2video/${task_id}" \
      -H "Authorization: Bearer ${token}")

    local status
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status','unknown'))" 2>/dev/null)

    echo "  [$attempt] Status: $status"

    if [ "$status" = "succeed" ]; then
      local video_url
      video_url=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['task_result']['videos'][0]['url'])" 2>/dev/null)

      if [ -z "$output" ]; then
        output="${OUTPUT_DIR}/kling-i2v-${task_id}.mp4"
      fi

      curl -s -o "$output" "$video_url"
      local file_size
      file_size=$(wc -c < "$output" | tr -d ' ')

      echo ""
      echo "=== Complete ==="
      echo "Video saved: $output"
      echo "File size:   ${file_size} bytes"
      echo "Cost:        ~\$0.30"
      log "Video saved: $output (${file_size} bytes, task=$task_id)"

      post_generate "kling" "$task_id" "$output" "$brand" "${OPT_PROMPT:-}"
      echo "$output"
      exit 0

    elif [ "$status" = "failed" ]; then
      local err_msg
      err_msg=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status_msg','unknown'))" 2>/dev/null)
      echo "FAILED: $err_msg"
      log "FAILED: kling image2video $task_id — $err_msg"
      exit 1
    fi
  done

  echo "TIMEOUT: Check status: video-gen.sh kling status $task_id"
  log "TIMEOUT: kling image2video $task_id"
  exit 1
}

kling_status() {
  local task_id="${1:-}"
  if [ -z "$task_id" ]; then
    echo "ERROR: task_id required"
    echo "Usage: video-gen.sh kling status <task_id>"
    exit 1
  fi

  if [ -z "${KLING_ACCESS_KEY:-}" ] || [ -z "${KLING_SECRET_KEY:-}" ]; then
    echo "ERROR: KLING_ACCESS_KEY and KLING_SECRET_KEY required"
    exit 1
  fi

  local token
  token=$(kling_auth)

  # Try text2video first, then image2video
  local resp
  resp=$(curl -s -X GET "${KLING_BASE_URL}/v1/videos/text2video/${task_id}" \
    -H "Authorization: Bearer ${token}")

  local status
  status=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('task_status','not_found'))" 2>/dev/null)

  if [ "$status" = "not_found" ] || [ "$status" = "" ]; then
    resp=$(curl -s -X GET "${KLING_BASE_URL}/v1/videos/image2video/${task_id}" \
      -H "Authorization: Bearer ${token}")
  fi

  echo "$resp" | python3 -c "
import sys, json
d = json.load(sys.stdin)
data = d.get('data', {})
print('Task:   %s' % data.get('task_id', 'unknown'))
print('Status: %s' % data.get('task_status', 'unknown'))
msg = data.get('task_status_msg', '')
if msg:
    print('Message: %s' % msg)
if data.get('task_result', {}).get('videos'):
    print('Video URL: %s' % data['task_result']['videos'][0]['url'])
"
}

kling_download() {
  local task_id="${1:-}"
  shift || true
  parse_opts "$@"

  if [ -z "$task_id" ]; then
    echo "ERROR: task_id required"
    exit 1
  fi

  if [ -z "${KLING_ACCESS_KEY:-}" ] || [ -z "${KLING_SECRET_KEY:-}" ]; then
    echo "ERROR: KLING_ACCESS_KEY and KLING_SECRET_KEY required"
    exit 1
  fi

  local token
  token=$(kling_auth)

  # Try both endpoints to find the video
  local resp
  resp=$(curl -s -X GET "${KLING_BASE_URL}/v1/videos/text2video/${task_id}" \
    -H "Authorization: Bearer ${token}")

  local video_url
  video_url=$(echo "$resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d['data']['task_result']['videos'][0]['url'])
except:
    print('')
" 2>/dev/null)

  if [ -z "$video_url" ]; then
    resp=$(curl -s -X GET "${KLING_BASE_URL}/v1/videos/image2video/${task_id}" \
      -H "Authorization: Bearer ${token}")
    video_url=$(echo "$resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d['data']['task_result']['videos'][0]['url'])
except:
    print('')
" 2>/dev/null)
  fi

  if [ -z "$video_url" ]; then
    echo "ERROR: No completed video found for task $task_id"
    exit 1
  fi

  local output="${OPT_OUTPUT:-${OUTPUT_DIR}/kling-${task_id}.mp4}"
  curl -s -o "$output" "$video_url"
  echo "Downloaded: $output"
  log "Downloaded: kling $task_id -> $output"
}

# ============================================================
# WAN PROVIDER (fal.ai)
# ============================================================

FAL_BASE_URL="https://queue.fal.run"
WAN_MODEL_T2V="fal-ai/wan/v2.1/text-to-video"
WAN_MODEL_I2V="fal-ai/wan/v2.1/image-to-video"
WAN_MODEL_I2V_PRO="fal-ai/wan-pro/v1/image-to-video"

wan_check_key() {
  if [ -z "${FAL_API_KEY:-}" ]; then
    echo "ERROR: FAL_API_KEY not set"
    echo "Set in ~/.openclaw/.env or environment"
    exit 1
  fi
}

# Submit job to fal.ai queue — returns request_id
wan_submit() {
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
    log "ERROR: wan submit failed — $response"
    exit 1
  fi

  echo "$request_id"
}

# Poll fal.ai for completion
wan_poll() {
  local model_id="$1"
  local request_id="$2"
  local max_seconds="${3:-300}"

  local elapsed=0
  local attempt=0

  echo "Polling for completion (every 5s, max ${max_seconds}s)..."
  log "Polling: wan model=$model_id request=$request_id"

  while [ $elapsed -lt $max_seconds ]; do
    sleep 5
    elapsed=$((elapsed + 5))
    attempt=$((attempt + 1))

    local status_resp
    status_resp=$(curl -s -X GET "${FAL_BASE_URL}/${model_id}/requests/${request_id}/status" \
      -H "Authorization: Key ${FAL_API_KEY}")

    local status
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null || echo "unknown")

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
      log "Completed: wan request=$request_id (${elapsed}s)"
      return 0
    elif [ "$status" = "FAILED" ] || [ "$status" = "failed" ]; then
      local err_detail
      err_detail=$(echo "$status_resp" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('error','unknown error'))
" 2>/dev/null || echo "unknown error")
      echo "FAILED: $err_detail"
      log "FAILED: wan request=$request_id — $err_detail"
      exit 1
    fi
  done

  echo "TIMEOUT: Video generation timed out after ${max_seconds}s"
  echo "Check status: video-gen.sh wan status $request_id"
  log "TIMEOUT: wan request=$request_id after ${max_seconds}s"
  exit 1
}

# Extract video URL from fal.ai result
wan_extract_video_url() {
  local model_id="$1"
  local request_id="$2"

  local result
  result=$(curl -s -X GET "${FAL_BASE_URL}/${model_id}/requests/${request_id}" \
    -H "Authorization: Key ${FAL_API_KEY}")

  echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
v = d.get('video', d.get('data', {}))
if isinstance(v, dict):
    print(v.get('url', ''))
elif isinstance(d.get('videos', []), list) and len(d['videos']) > 0:
    print(d['videos'][0].get('url', ''))
else:
    print('')
" 2>/dev/null
}

wan_text2video() {
  parse_opts "$@"

  if [ -z "$OPT_PROMPT" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: video-gen.sh wan text2video \"prompt\" [--duration 5] [--aspect-ratio 9:16] [--brand pinxin-vegan]"
    exit 1
  fi

  local duration="$OPT_DURATION"
  local ratio="$OPT_ASPECT_RATIO"
  local resolution="$OPT_RESOLUTION"
  local output="$OPT_OUTPUT"
  local brand="$OPT_BRAND"

  local prompt
  prompt=$(enhance_prompt "$OPT_PROMPT" "$brand")

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
  echo "Model:      $WAN_MODEL_T2V"
  echo "Est cost:   ~\$0.20"
  echo ""

  log "wan text2video: prompt='${OPT_PROMPT}' duration=${duration}s frames=$num_frames ratio=$ratio resolution=$resolution brand=$brand"

  if [ "$OPT_DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Payload:"
    echo "$payload" | python3 -m json.tool
    echo ""
    echo "Would POST to: ${FAL_BASE_URL}/${WAN_MODEL_T2V}"
    exit 0
  fi

  wan_check_key

  echo "Submitting to fal.ai queue..."
  local request_id
  request_id=$(wan_submit "$WAN_MODEL_T2V" "$payload")

  echo "Job submitted: $request_id"
  log "Submitted: wan request=$request_id model=$WAN_MODEL_T2V"

  wan_poll "$WAN_MODEL_T2V" "$request_id"

  local video_url
  video_url=$(wan_extract_video_url "$WAN_MODEL_T2V" "$request_id")

  if [ -z "$video_url" ]; then
    echo "ERROR: Could not extract video URL from result"
    log "ERROR: wan no video URL for request=$request_id"
    exit 1
  fi

  if [ -z "$output" ]; then
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    output="${OUTPUT_DIR}/wan-t2v-${ts}.mp4"
  fi

  echo "Downloading video..."
  curl -s -o "$output" "$video_url"

  local file_size
  file_size=$(wc -c < "$output" | tr -d ' ')

  echo ""
  echo "=== Complete ==="
  echo "Video saved: $output"
  echo "File size:   ${file_size} bytes"
  echo "Cost:        ~\$0.20"
  log "Video saved: $output (${file_size} bytes, request=$request_id)"

  post_generate "wan" "$request_id" "$output" "$brand" "$OPT_PROMPT"
  echo "$output"
}

wan_image2video() {
  parse_opts "$@"

  if [ -z "$OPT_IMAGE" ]; then
    echo "ERROR: --image URL or file path is required for image2video"
    echo "Usage: video-gen.sh wan image2video --image \"url_or_path\" [--prompt \"...\"] [--duration 5]"
    exit 1
  fi

  local duration="$OPT_DURATION"
  local ratio="$OPT_ASPECT_RATIO"
  local output="$OPT_OUTPUT"
  local brand="$OPT_BRAND"
  local image_url="$OPT_IMAGE"

  local prompt
  prompt=$(enhance_prompt "${OPT_PROMPT:-}" "$brand")

  # If image_url is a local file, encode as base64 data URI
  local resolved_image="$image_url"
  if [ -f "$image_url" ]; then
    echo "Local file detected, encoding as base64..."
    resolved_image=$(encode_image_for_fal "$image_url")
    log "Encoded local image: $image_url (${#resolved_image} chars)"
  fi

  local model_id="$WAN_MODEL_I2V"
  local cost="0.20"
  local model_label="Wan I2V"
  if [ "$OPT_PRO" -eq 1 ]; then
    model_id="$WAN_MODEL_I2V_PRO"
    cost="0.80"
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

  echo "=== $model_label ==="
  echo "Image:    $image_url"
  echo "Prompt:   ${prompt:-<none>}"
  echo "Duration: ${duration}s (${num_frames} frames)"
  echo "Ratio:    $ratio"
  echo "Model:    $model_id"
  echo "Est cost: ~\$${cost}"
  echo ""

  log "wan image2video: image=$image_url prompt='${OPT_PROMPT:-}' duration=${duration}s frames=$num_frames model=$model_id brand=$brand"

  if [ "$OPT_DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would POST to: ${FAL_BASE_URL}/${model_id}"
    if [ -f "$image_url" ]; then
      echo "[DRY RUN] Local image would be base64 encoded"
    fi
    exit 0
  fi

  wan_check_key

  echo "Submitting to fal.ai queue..."
  local request_id
  request_id=$(wan_submit "$model_id" "$payload")

  echo "Job submitted: $request_id"
  log "Submitted: wan request=$request_id model=$model_id"

  wan_poll "$model_id" "$request_id"

  local video_url
  video_url=$(wan_extract_video_url "$model_id" "$request_id")

  if [ -z "$video_url" ]; then
    echo "ERROR: Could not extract video URL from result"
    log "ERROR: wan no video URL for request=$request_id"
    exit 1
  fi

  if [ -z "$output" ]; then
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    output="${OUTPUT_DIR}/wan-i2v-${ts}.mp4"
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

  post_generate "wan" "$request_id" "$output" "$brand" "${OPT_PROMPT:-}"
  echo "$output"
}

wan_image2video_pro() {
  # Convenience alias — sets --pro flag and delegates
  wan_image2video --pro "$@"
}

wan_status() {
  local request_id=""
  local model_type="text2video"

  while [ $# -gt 0 ]; do
    case "$1" in
      --model) model_type="$2"; shift 2 ;;
      -*)      echo "Unknown option: $1"; exit 1 ;;
      *)       request_id="$1"; shift ;;
    esac
  done

  if [ -z "$request_id" ]; then
    echo "ERROR: request_id required"
    echo "Usage: video-gen.sh wan status <request_id> [--model text2video]"
    exit 1
  fi

  wan_check_key

  # Map model_type to fal.ai model ID
  local model_id
  case "$model_type" in
    text2video|t2v)              model_id="$WAN_MODEL_T2V" ;;
    image2video|i2v)             model_id="$WAN_MODEL_I2V" ;;
    image2video-pro|i2v-pro)     model_id="$WAN_MODEL_I2V_PRO" ;;
    *)
      echo "ERROR: Unknown model type: $model_type"
      echo "Valid: text2video, image2video, image2video-pro"
      exit 1
      ;;
  esac

  echo "Checking status for request: $request_id"
  echo "Model: $model_id"
  echo ""

  local status_resp
  status_resp=$(curl -s -X GET "${FAL_BASE_URL}/${model_id}/requests/${request_id}/status" \
    -H "Authorization: Key ${FAL_API_KEY}")

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

  # If completed, show result
  local status
  status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || echo "")

  if [ "$status" = "COMPLETED" ] || [ "$status" = "completed" ]; then
    echo ""
    echo "Fetching result..."
    local result
    result=$(curl -s -X GET "${FAL_BASE_URL}/${model_id}/requests/${request_id}" \
      -H "Authorization: Key ${FAL_API_KEY}")

    echo "$result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
v = d.get('video', {})
if isinstance(v, dict) and v.get('url'):
    print('Video URL: %s' % v['url'])
imgs = d.get('images', [])
if imgs:
    for i, img in enumerate(imgs):
        url = img.get('url', '') if isinstance(img, dict) else ''
        print('Image %d URL: %s' % (i, url))
data = d.get('data', {})
if isinstance(data, dict) and data.get('url'):
    print('Result URL: %s' % data['url'])
" 2>/dev/null
  fi
}

wan_download() {
  local request_id="${1:-}"
  shift || true
  parse_opts "$@"

  if [ -z "$request_id" ]; then
    echo "ERROR: request_id required"
    exit 1
  fi

  wan_check_key

  local model_type="${OPT_MODEL:-text2video}"
  local model_id
  case "$model_type" in
    text2video|t2v)              model_id="$WAN_MODEL_T2V" ;;
    image2video|i2v)             model_id="$WAN_MODEL_I2V" ;;
    image2video-pro|i2v-pro)     model_id="$WAN_MODEL_I2V_PRO" ;;
    *)                           model_id="$WAN_MODEL_T2V" ;;
  esac

  local video_url
  video_url=$(wan_extract_video_url "$model_id" "$request_id")

  if [ -z "$video_url" ]; then
    echo "ERROR: No completed video found for request $request_id"
    exit 1
  fi

  local output="${OPT_OUTPUT:-${OUTPUT_DIR}/wan-${request_id}.mp4}"
  curl -s -o "$output" "$video_url"
  echo "Downloaded: $output"
  log "Downloaded: wan $request_id -> $output"
}

# ============================================================
# SORA PROVIDER (OpenAI)
# ============================================================

SORA_BASE_URL="https://api.openai.com"

sora_check_key() {
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "ERROR: OPENAI_API_KEY not set"
    echo "Set in ~/.openclaw/.env or environment"
    exit 1
  fi
}

sora_generate() {
  parse_opts "$@"

  if [ -z "$OPT_PROMPT" ]; then
    echo "ERROR: prompt is required"
    echo "Usage: video-gen.sh sora generate \"prompt\" [--duration 5] [--aspect-ratio 9:16] [--brand pinxin-vegan] [--auto-ref]"
    exit 1
  fi

  # AUTO-REF: If brand is specified but no image, auto-select a reference product photo
  # This switches from text-to-video (generic AI hallucination) to image-to-video (brand-consistent)
  if [ -n "$OPT_BRAND" ] && [ -z "$OPT_IMAGE" ]; then
    local prompt_lower
    prompt_lower=$(echo "$OPT_PROMPT" | tr '[:upper:]' '[:lower:]')
    local auto_ref
    auto_ref=$(auto_select_reference "$OPT_BRAND" "$prompt_lower")
    if [ -n "$auto_ref" ] && [ -f "$auto_ref" ]; then
      OPT_IMAGE="$auto_ref"
      echo "📸 Auto-ref: Using product photo as reference image"
      echo "   $auto_ref"
      log "Auto-ref selected: $auto_ref (brand=$OPT_BRAND)"
    else
      log "Auto-ref: No matching product photo found for brand=$OPT_BRAND — falling back to text-only"
    fi
  fi

  local model="${OPT_MODEL:-sora-2}"
  # Sora only accepts 4, 8, or 12 seconds — snap to nearest valid value
  local seconds="$OPT_DURATION"
  case "$seconds" in
    1|2|3|4) seconds=4 ;;
    5|6)     seconds=4 ;;
    7|8)     seconds=8 ;;
    9|10)    seconds=8 ;;
    11|12)   seconds=12 ;;
    *)       seconds=4 ;;
  esac
  local output="$OPT_OUTPUT"
  local brand="$OPT_BRAND"
  local image_path="$OPT_IMAGE"

  # Map aspect ratio to size for Sora
  local size="$OPT_RESOLUTION"
  if [ "$size" = "720p" ] || [ -z "$size" ]; then
    local auto_ratio="${OPT_ASPECT_RATIO:-}"
    # Auto-detect from source image if no aspect ratio specified
    if [ -z "$auto_ratio" ] && [ -n "$image_path" ] && [ -f "$image_path" ]; then
      local img_dims
      img_dims=$(python3 -c "from PIL import Image; i=Image.open('$image_path'); print(f'{i.width} {i.height}')" 2>/dev/null || echo "")
      if [ -n "$img_dims" ]; then
        local img_w img_h
        img_w=$(echo "$img_dims" | cut -d' ' -f1)
        img_h=$(echo "$img_dims" | cut -d' ' -f2)
        if [ "$img_h" -gt "$img_w" ]; then
          auto_ratio="9:16"
          log "Auto-detected portrait source image (${img_w}x${img_h}) -> 9:16"
        elif [ "$img_w" -gt "$img_h" ]; then
          auto_ratio="16:9"
          log "Auto-detected landscape source image (${img_w}x${img_h}) -> 16:9"
        else
          auto_ratio="1:1"
          log "Auto-detected square source image (${img_w}x${img_h}) -> 1:1"
        fi
      fi
    fi
    case "$auto_ratio" in
      16:9)  size="1280x720" ;;
      9:16)  size="720x1280" ;;
      1:1)   size="720x720" ;;
      *)     size="720x1280" ;;
    esac
  fi

  # ============================================================
  # SKU REFERENCE VALIDATION & ENHANCEMENT
  # ============================================================
  # Validate SKU image exists
  if [ -n "$image_path" ] && [ ! -f "$image_path" ]; then
    echo "ERROR: SKU reference image not found: $image_path"
    echo "Please provide a valid image path."
    exit 1
  fi

  local prompt
  prompt=$(enhance_prompt "$OPT_PROMPT" "$brand")

  # If SKU reference image is provided, explicitly reference it in the prompt
  if [ -n "$image_path" ] && [ -f "$image_path" ]; then
    local img_dims
    img_dims=$(python3 -c "from PIL import Image; i=Image.open('$image_path'); print(f'{i.width}x{i.height}')" 2>/dev/null || echo "unknown")
    
    prompt="[SKU REFERENCE: Product image shown throughout — maintain consistent visual style. Image: $image_path ($img_dims)]. ${prompt}"
    
    # For MIRRA brand, add bento-specific visual instructions
    if [ "$brand" = "mirra" ]; then
      prompt="${prompt}\n[MIRRA BRAND DNA] Top-down bento box in white container, vibrant fresh ingredients, salmon pink + cream background, calorie badge at corner, MIRRA logo placement."
      prompt="${prompt}\n[MOTION STYLE] Top-down bento reveal, steam rising from fresh bento, gentle handheld sway, warm natural lighting."
      prompt="${prompt}\n[CAMERA STYLE] UGC authentic casual, soft natural daylight, slight handheld movement, shallow depth of field for food focus."
      log "MIRRA bento SKU reference applied: $image_path ($img_dims)"
    else
      log "SKU reference applied: $image_path ($img_dims)"
    fi
  else
    log "No SKU reference provided — using prompt-only mode"
  fi

  echo "=== Sora Video Generation ==="
  echo "Prompt:   $prompt"
  echo "Duration: ${seconds}s"
  echo "Size:     $size"
  echo "Model:    $model"
  echo "Est cost: ~\$0.50"
  echo ""

  log "sora generate: model=$model seconds=$seconds size=$size brand=$brand"
  log "Prompt: $prompt"

  if [ "$OPT_DRY_RUN" -eq 1 ]; then
    echo "[DRY RUN] Would POST to: ${SORA_BASE_URL}/v1/videos"
    exit 0
  fi

  sora_check_key

  local response
  if [ -n "$image_path" ] && [ -f "$image_path" ]; then
    # Image-to-video: Sora requires input image to match output dimensions exactly
    local target_w target_h
    target_w=$(echo "$size" | cut -d'x' -f1)
    target_h=$(echo "$size" | cut -d'x' -f2)
    local actual_dims
    actual_dims=$(python3 -c "from PIL import Image; i=Image.open('$image_path'); print(f'{i.width}x{i.height}')" 2>/dev/null || echo "unknown")
    if [ "$actual_dims" != "${target_w}x${target_h}" ] && [ "$actual_dims" != "unknown" ]; then
      echo "Auto-resizing image from $actual_dims to ${target_w}x${target_h} (Sora requires exact match)..."
      local resized="/tmp/sora-resized-$$.png"
      python3 -c "
from PIL import Image
img = Image.open('$image_path')
tw, th = $target_w, $target_h
# Center crop to target aspect ratio, then resize
ratio = tw / th
cur_ratio = img.width / img.height
if cur_ratio > ratio:
    new_w = int(img.height * ratio)
    left = (img.width - new_w) // 2
    img = img.crop((left, 0, left + new_w, img.height))
else:
    new_h = int(img.width / ratio)
    top = (img.height - new_h) // 2
    img = img.crop((0, top, img.width, top + new_h))
img = img.resize((tw, th), Image.LANCZOS)
img.save('$resized')
"
      image_path="$resized"
      log "Auto-resized image to ${target_w}x${target_h}"
    fi

    echo "Submitting with input reference image..."
    response=$(curl -s -X POST "${SORA_BASE_URL}/v1/videos" \
      -H "Authorization: Bearer ${OPENAI_API_KEY}" \
      -F model="$model" \
      -F prompt="$prompt" \
      -F size="$size" \
      -F seconds="$seconds" \
      -F input_reference=@"$image_path")
  else
    # Text-to-video mode
    response=$(curl -s -X POST "${SORA_BASE_URL}/v1/videos" \
      -H "Authorization: Bearer ${OPENAI_API_KEY}" \
      -F model="$model" \
      -F prompt="$prompt" \
      -F size="$size" \
      -F seconds="$seconds")
  fi

  local video_id
  video_id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

  if [ -z "$video_id" ]; then
    echo "ERROR: Failed to create task"
    echo "$response"
    log "ERROR: sora create failed — $response"
    exit 1
  fi

  echo "Video job created: $video_id"
  log "Job created: sora $video_id"

  # Poll for completion
  echo "Polling for completion (every 15s, max 10min)..."
  local max_attempts=40
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    sleep 15
    attempt=$((attempt + 1))

    local status_resp
    status_resp=$(curl -s "${SORA_BASE_URL}/v1/videos/${video_id}" \
      -H "Authorization: Bearer ${OPENAI_API_KEY}")

    local status progress
    status=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null)
    progress=$(echo "$status_resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('progress',0))" 2>/dev/null)

    echo "  [$attempt] Status: $status ($progress%)"

    if [ "$status" = "completed" ]; then
      if [ -z "$output" ]; then
        output="${OUTPUT_DIR}/sora-${video_id}.mp4"
      fi

      curl -s "${SORA_BASE_URL}/v1/videos/${video_id}/content" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" \
        -o "$output"

      local file_size
      file_size=$(wc -c < "$output" | tr -d ' ')

      echo ""
      echo "=== Complete ==="
      echo "Video saved: $output"
      echo "File size:   ${file_size} bytes"
      echo "Cost:        ~\$0.50"
      log "Video saved: $output (${file_size} bytes, job=$video_id)"

      post_generate "sora" "$video_id" "$output" "$brand" "$OPT_PROMPT"
      echo "$output"
      exit 0

    elif [ "$status" = "failed" ]; then
      echo "FAILED"
      echo "$status_resp"
      log "FAILED: sora $video_id"
      exit 1
    fi
  done

  echo "TIMEOUT: Check status: video-gen.sh sora status $video_id"
  log "TIMEOUT: sora $video_id"
  exit 1
}

sora_status() {
  local video_id="${1:-}"
  if [ -z "$video_id" ]; then
    echo "ERROR: video_id required"
    echo "Usage: video-gen.sh sora status <video_id>"
    exit 1
  fi

  sora_check_key

  curl -s "${SORA_BASE_URL}/v1/videos/${video_id}" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('ID:       %s' % d.get('id', 'unknown'))
print('Status:   %s' % d.get('status', 'unknown'))
print('Progress: %s%%' % d.get('progress', 0))
print('Model:    %s' % d.get('model', 'unknown'))
"
}

sora_download() {
  local video_id="${1:-}"
  shift || true
  parse_opts "$@"

  if [ -z "$video_id" ]; then
    echo "ERROR: video_id required"
    exit 1
  fi

  sora_check_key

  local output="${OPT_OUTPUT:-${OUTPUT_DIR}/sora-${video_id}.mp4}"
  curl -s "${SORA_BASE_URL}/v1/videos/${video_id}/content" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -o "$output"

  echo "Downloaded: $output"
  log "Downloaded: sora $video_id -> $output"
}

# ============================================================
# PIPELINE — NanoBanana → Video Gen → Video Forge
# ============================================================

pipeline() {
  parse_opts "$@"

  local provider="$OPT_PROVIDER"
  local brand="$OPT_BRAND"
  local prompt="$OPT_PROMPT"
  local scenes="$OPT_SCENES"
  local duration="$OPT_DURATION"
  local ratio="$OPT_ASPECT_RATIO"
  local output="$OPT_OUTPUT"

  if [ -z "$prompt" ]; then
    echo "ERROR: --prompt required for pipeline"
    echo "Usage: video-gen.sh pipeline --prompt \"...\" --brand pinxin-vegan [--provider wan] [--scenes 3] [--duration 5]"
    exit 1
  fi

  if [ ! -x "$NANOBANANA" ]; then
    echo "ERROR: NanoBanana not found at $NANOBANANA"
    echo "Pipeline requires nanobanana skill for scene image generation"
    exit 1
  fi

  echo "=== Video Pipeline ==="
  echo "Prompt:   $prompt"
  echo "Provider: $provider"
  echo "Brand:    ${brand:-<none>}"
  echo "Scenes:   $scenes"
  echo "Duration: ${duration}s per scene"
  echo "Ratio:    $ratio"
  echo ""

  log "pipeline: provider=$provider brand=$brand scenes=$scenes duration=$duration prompt='$prompt'"

  local pipeline_dir
  pipeline_dir="${OUTPUT_DIR}/pipeline-$(date '+%Y%m%d_%H%M%S')"
  mkdir -p "$pipeline_dir"

  local clip_list=""
  local scene_idx=0

  while [ $scene_idx -lt $scenes ]; do
    scene_idx=$((scene_idx + 1))
    echo ""
    echo "--- Scene $scene_idx / $scenes ---"

    # Step 1: Generate scene image via NanoBanana
    local scene_prompt="${prompt} — Scene ${scene_idx} of ${scenes}"
    if [ -n "$brand" ]; then
      scene_prompt="$scene_prompt (brand: $brand)"
    fi

    echo "  [1/2] Generating scene image via NanoBanana..."
    local scene_image="${pipeline_dir}/scene_${scene_idx}.png"

    local nb_args="--prompt"
    nb_args="$nb_args \"$scene_prompt\""
    if [ -n "$brand" ]; then
      nb_args="$nb_args --brand $brand"
    fi
    nb_args="$nb_args --output $scene_image"
    nb_args="$nb_args --ratio $ratio"

    # Auto-ref: Find brand product photo to use as NanoBanana reference
    local scene_ref=""
    if [ -n "$brand" ]; then
      local scene_prompt_lower
      scene_prompt_lower=$(echo "$scene_prompt" | tr '[:upper:]' '[:lower:]')
      scene_ref=$(auto_select_reference "$brand" "$scene_prompt_lower")
      if [ -n "$scene_ref" ] && [ -f "$scene_ref" ]; then
        echo "    📸 Using product ref: $(basename "$scene_ref")"
      fi
    fi

    # NanoBanana call — capture output for the image path
    local nb_output
    local nb_cmd="bash $NANOBANANA --prompt \"$scene_prompt\" --output $scene_image --ratio $ratio"
    if [ -n "$brand" ]; then nb_cmd="$nb_cmd --brand $brand"; fi
    if [ -n "$scene_ref" ] && [ -f "$scene_ref" ]; then nb_cmd="$nb_cmd --ref-image $scene_ref"; fi
    nb_output=$(eval "$nb_cmd" 2>&1) || true

    # Check if image was created
    if [ ! -f "$scene_image" ]; then
      # NanoBanana may output the path on the last line
      local nb_path
      nb_path=$(echo "$nb_output" | tail -1)
      if [ -f "$nb_path" ]; then
        cp "$nb_path" "$scene_image"
      else
        echo "  WARNING: Scene $scene_idx image failed, skipping"
        log "WARNING: pipeline scene $scene_idx NanoBanana failed"
        continue
      fi
    fi

    echo "  Scene image: $scene_image"

    # Step 2: Generate video from scene image
    echo "  [2/2] Generating video clip via $provider..."
    local clip_path="${pipeline_dir}/clip_${scene_idx}.mp4"

    case "$provider" in
      kling)
        kling_image2video --image "$scene_image" --prompt "$scene_prompt" \
          --duration "$duration" --output "$clip_path" \
          ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "    $line"; done || true
        ;;
      wan)
        wan_image2video --image "$scene_image" --prompt "$scene_prompt" \
          --duration "$duration" --aspect-ratio "$ratio" --output "$clip_path" \
          ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "    $line"; done || true
        ;;
      sora)
        sora_generate --image "$scene_image" --prompt "$scene_prompt" \
          --duration "$duration" --aspect-ratio "$ratio" --output "$clip_path" \
          ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "    $line"; done || true
        ;;
    esac

    if [ -f "$clip_path" ]; then
      echo "  Clip ready: $clip_path"
      if [ -z "$clip_list" ]; then
        clip_list="$clip_path"
      else
        clip_list="$clip_list,$clip_path"
      fi
    else
      echo "  WARNING: Clip $scene_idx generation failed"
      log "WARNING: pipeline scene $scene_idx video failed"
    fi
  done

  echo ""

  # Step 3: Assemble via video-forge if available and we have clips
  if [ -z "$clip_list" ]; then
    echo "ERROR: No clips were generated"
    log "ERROR: pipeline produced no clips"
    exit 1
  fi

  if [ -x "$VIDEO_FORGE" ]; then
    echo "--- Assembling via Video Forge ---"
    local final_output="${output:-${OUTPUT_DIR}/pipeline-final-$(date '+%Y%m%d_%H%M%S').mp4}"

    # Build concat file for video-forge
    local concat_file="${pipeline_dir}/concat.txt"
    echo "$clip_list" | tr ',' '\n' | while IFS= read -r clip; do
      echo "file '$clip'"
    done > "$concat_file"

    # Try video-forge assemble, fallback to ffmpeg concat
    bash "$VIDEO_FORGE" assemble --input "$concat_file" --output "$final_output" 2>&1 || {
      echo "  Video Forge failed, falling back to ffmpeg concat..."
      ffmpeg -y -f concat -safe 0 -i "$concat_file" -c copy "$final_output" 2>/dev/null || {
        echo "  ffmpeg concat also failed — clips are in: $pipeline_dir"
        log "WARNING: pipeline assembly failed, individual clips in $pipeline_dir"
        echo "$pipeline_dir"
        exit 0
      }
    }

    local file_size
    file_size=$(wc -c < "$final_output" | tr -d ' ')

    echo ""
    echo "=== Pipeline Complete ==="
    echo "Final video: $final_output"
    echo "File size:   ${file_size} bytes"
    echo "Scenes:      $(echo "$clip_list" | tr ',' '\n' | wc -l | tr -d ' ')"
    log "Pipeline complete: $final_output (${file_size} bytes)"

    post_generate "$provider" "pipeline" "$final_output" "$brand" "$prompt"
    echo "$final_output"
  else
    echo "Video Forge not found — clips saved individually in: $pipeline_dir"
    echo "Clip list: $clip_list"
    log "Pipeline clips ready (no video-forge): $pipeline_dir"
    echo "$pipeline_dir"
  fi
}

# ============================================================
# REVERSE PROMPT — Video → Frames → Gemini Vision → Analysis
# ============================================================

reverse_prompt() {
  local video="${1:-}"

  if [ -z "$video" ] || [ ! -f "$video" ]; then
    echo "ERROR: video file path required"
    echo "Usage: video-gen.sh reverse-prompt /path/to/video.mp4"
    exit 1
  fi

  if [ -z "${GEMINI_API_KEY:-}" ]; then
    echo "ERROR: GEMINI_API_KEY not set"
    echo "Set in ~/.openclaw/.env or environment"
    exit 1
  fi

  # Check for ffmpeg and ffprobe
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ERROR: ffmpeg required for frame extraction"
    exit 1
  fi

  echo "=== Video Reverse Prompting ==="
  echo "Video: $video"
  echo ""

  log "reverse-prompt: video=$video"

  local tmpdir
  tmpdir=$(mktemp -d)

  # Get video duration
  local vid_duration
  vid_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null | cut -d. -f1)
  vid_duration=${vid_duration:-30}

  echo "Duration: ${vid_duration}s"
  echo "Extracting 5 frames..."

  local interval=$((vid_duration / 5))
  if [ "$interval" -lt 1 ]; then
    interval=1
  fi

  local i=0
  while [ $i -lt 5 ]; do
    local seek=$((i * interval))
    ffmpeg -ss "$seek" -i "$video" -vframes 1 -q:v 2 "${tmpdir}/frame_${i}.jpg" 2>/dev/null
    i=$((i + 1))
  done

  # Count successfully extracted frames
  local frame_count=0
  i=0
  while [ $i -lt 5 ]; do
    if [ -f "${tmpdir}/frame_${i}.jpg" ]; then
      frame_count=$((frame_count + 1))
    fi
    i=$((i + 1))
  done

  echo "Extracted ${frame_count} frames"

  if [ "$frame_count" -eq 0 ]; then
    echo "ERROR: Could not extract any frames"
    rm -rf "$tmpdir"
    exit 1
  fi

  # Send max 3 frames to Gemini Vision (8GB RAM constraint)
  echo "Sending frames to Gemini Vision for analysis..."

  # Build the multipart JSON with inline base64 frames
  # Pick 3 evenly-spaced frames from what we have
  local analysis_result
  analysis_result=$(python3 << PYEOF
import base64, json, os, sys, glob

tmpdir = "$tmpdir"
frames = sorted(glob.glob(os.path.join(tmpdir, "frame_*.jpg")))

# Pick max 3 frames evenly spaced
if len(frames) > 3:
    indices = [0, len(frames) // 2, len(frames) - 1]
    frames = [frames[i] for i in indices]

# Build parts
parts = []
parts.append({"text": """Analyze these video frames and return a JSON object with exactly these keys:
{
  "hooks": ["list of visual/narrative hooks that grab attention"],
  "effects": ["list of visual effects, transitions, or techniques observed"],
  "music_cues": ["suggested music styles, BPM ranges, or specific cues based on the visual mood"],
  "editing_style": "description of the editing style (fast-cut, slow-mo, cinematic, etc.)",
  "virality_score": 7,
  "suggested_output_type": "reels_product_demo or similar content type",
  "scene_description": "brief description of what the video shows",
  "color_palette": ["list of dominant hex colors"],
  "mood": "overall mood/atmosphere"
}
Return ONLY the JSON, no markdown fences, no explanation."""})

for f in frames:
    with open(f, "rb") as fh:
        b64 = base64.b64encode(fh.read()).decode()
    parts.append({
        "inline_data": {
            "mime_type": "image/jpeg",
            "data": b64
        }
    })

payload = {
    "contents": [{"parts": parts}],
    "generationConfig": {
        "temperature": 0.3,
        "maxOutputTokens": 1024
    }
}

api_key = os.environ.get("GEMINI_API_KEY", "")
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"

import urllib.request
req = urllib.request.Request(
    url,
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"},
    method="POST"
)

try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read().decode())
    text = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
    # Try to parse as JSON to validate
    try:
        parsed = json.loads(text)
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError:
        # Return raw text if not valid JSON
        print(text)
except Exception as e:
    print(json.dumps({"error": str(e)}), file=sys.stderr)
    sys.exit(1)
PYEOF
)

  # Clean up
  rm -rf "$tmpdir"

  echo ""
  echo "=== Analysis ==="
  echo "$analysis_result"

  log "reverse-prompt complete: video=$video"

  # Output JSON to stdout for piping
  echo "$analysis_result"
}

# ============================================================
# AUTO-STATUS — Detect provider from task ID
# ============================================================

auto_status() {
  local task_id="${1:-}"
  if [ -z "$task_id" ]; then
    echo "ERROR: task_id required"
    echo "Usage: video-gen.sh status <task_id>"
    exit 1
  fi

  # Heuristics for provider detection:
  # - Sora IDs look like: vid_xxxx or start with common OpenAI patterns
  # - Wan/fal.ai IDs are UUIDs with hyphens
  # - Kling IDs are numeric or alphanumeric

  # Try to detect based on ID format and stored logs
  local provider=""

  # Check logs for this task ID
  if [ -f "$LOG_FILE" ]; then
    if grep -q "kling.*${task_id}" "$LOG_FILE" 2>/dev/null; then
      provider="kling"
    elif grep -q "wan.*${task_id}" "$LOG_FILE" 2>/dev/null; then
      provider="wan"
    elif grep -q "sora.*${task_id}" "$LOG_FILE" 2>/dev/null; then
      provider="sora"
    fi
  fi

  # Fallback heuristics
  if [ -z "$provider" ]; then
    case "$task_id" in
      vid_*|video_*)  provider="sora" ;;
      *-*-*-*-*)      provider="wan" ;;   # UUID format
      *)              provider="kling" ;;  # Default
    esac
  fi

  echo "Auto-detected provider: $provider"
  echo ""

  case "$provider" in
    kling) kling_status "$task_id" ;;
    wan)   wan_status "$task_id" ;;
    sora)  sora_status "$task_id" ;;
  esac
}

# ============================================================
# SORA UGC PIPELINE — Full workflow for UGC video creation
# ============================================================

sora_ugc_pipeline() {
  parse_opts "$@"

  local brand="$OPT_BRAND"
  local concept="$OPT_PROMPT"
  local duration="${OPT_DURATION:-8}"
  local ratio="${OPT_ASPECT_RATIO:-9:16}"
  local reference="$OPT_IMAGE"
  local output="$OPT_OUTPUT"

  if [ -z "$concept" ]; then
    echo "ERROR: --prompt/concept required"
    echo "Usage: video-gen.sh sora-ugc --prompt \"concept\" --brand <brand> [--image ref.png] [--duration 8] [--aspect-ratio 9:16]"
    echo ""
    echo "Full Sora 2 UGC workflow: reverse-prompt → smart prompt → generate → post-prod → export"
    echo "See: skills/video-gen/workflows/SORA-UGC-WORKFLOW.md"
    exit 1
  fi

  local ugc_dir
  ugc_dir="${OUTPUT_DIR}/sora-ugc-$(date '+%Y%m%d_%H%M%S')"
  mkdir -p "$ugc_dir"

  echo "=== Sora UGC Pipeline ==="
  echo "Concept:   $concept"
  echo "Brand:     ${brand:-<none>}"
  echo "Duration:  ${duration}s"
  echo "Ratio:     $ratio"
  echo "Reference: ${reference:-<none>}"
  echo "Output:    $ugc_dir/"
  echo ""

  log "sora-ugc: brand=$brand concept='$concept' duration=$duration ratio=$ratio"

  # Step 1: Reverse prompt (if reference provided)
  local visual_dna=""
  if [ -n "$reference" ] && [ -f "$reference" ]; then
    echo "--- Step 1: Reverse Prompt (reference analysis) ---"
    visual_dna=$(reverse_prompt "$reference" 2>/dev/null | tail -1)
    echo "  Visual DNA extracted: $(echo "$visual_dna" | head -c 200)..."
    echo "$visual_dna" > "$ugc_dir/visual-dna.txt"
    echo ""
  else
    echo "--- Step 1: Reverse Prompt — skipped (no reference) ---"
    echo ""
  fi

  # Step 2: Smart prompt generation (brand-enhanced)
  echo "--- Step 2: Smart Prompt Generation ---"
  local smart_prompt
  if [ -n "$visual_dna" ]; then
    smart_prompt=$(enhance_prompt "$concept. Match this visual style: $visual_dna" "$brand")
  else
    smart_prompt=$(enhance_prompt "$concept. Style: UGC authentic casual, handheld camera, natural lighting" "$brand")
  fi
  echo "  Smart prompt: $smart_prompt"
  echo "$smart_prompt" > "$ugc_dir/smart-prompt.txt"
  echo ""

  # Step 3: Generate via Sora 2 (Storyboard 6 Approach — 4 Scenes for 8-Second Video)
  echo "--- Step 3: Sora 2 Generation (Storyboard Approach) ---"
  
  # Storyboard 6: Break 8-second video into 4 scenes
  local scene_duration=2  # 8s total / 4 scenes = 2s each
  local clip_list=""
  
  # For MIRRA bento videos, use scene-specific prompts
  if [ "$brand" = "mirra" ]; then
    echo "  Using MIRRA bento storyboard scenes..."
    
    # Scene 1: Bento Reveal (0-2s)
    local scene1_prompt="Scene 1/4: Top-down bento reveal shot in white container on salmon pink background, vibrant fresh ingredients visible, slight steam rising from hot food, UGC authentic casual camera, handheld gentle sway."
    if [ -n "$reference" ] && [ -f "$reference" ]; then
      scene1_prompt="[SKU REF: Bento box in frame]. ${scene1_prompt}"
    fi
    
    echo "  [Scene 1/4] Generating bento reveal..."
    local clip1="${ugc_dir}/clip_1_reveal.mp4"
    sora_generate --prompt "${smart_prompt}. ${scene1_prompt}" \
      --image "${reference:-}" --duration "$scene_duration" \
      --aspect-ratio "$ratio" --output "$clip1" \
      ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "      $line"; done || true
    
    if [ -f "$clip1" ]; then
      clip_list="$clip_list$clip1,"
      log "Scene 1/4 complete: $clip1"
    fi
    
    # Scene 2: Hands Placing Ingredients (2-4s)
    local scene2_prompt="Scene 2/4: Medium handheld shot of hands placing colorful ingredients into bento box, slow motion pour animation, ingredient details clearly visible, soft natural lighting from left, warm tones."
    
    echo "  [Scene 2/4] Generating ingredient placement..."
    local clip2="${ugc_dir}/clip_2_ingredients.mp4"
    sora_generate --prompt "${smart_prompt}. ${scene2_prompt}" \
      --image "${reference:-}" --duration "$scene_duration" --aspect-ratio "$ratio" \
      --output "$clip2" \
      ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "      $line"; done || true
    
    if [ -f "$clip2" ]; then
      clip_list="$clip_list$clip2,"
      log "Scene 2/4 complete: $clip2"
    fi
    
    # Scene 3: Completed Bento with Steam (4-6s)
    local scene3_prompt="Scene 3/4: Wide shot of completed bento with steam still rising, slight slow zoom toward food, soft natural lighting, black calorie badge at top-right corner, MIRRA branding visible, UGC style."
    
    echo "  [Scene 3/4] Generating completed bento..."
    local clip3="${ugc_dir}/clip_3_complete.mp4"
    sora_generate --prompt "${smart_prompt}. ${scene3_prompt}" \
      --image "${reference:-}" --duration "$scene_duration" --aspect-ratio "$ratio" \
      --output "$clip3" \
      ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "      $line"; done || true
    
    if [ -f "$clip3" ]; then
      clip_list="$clip_list$clip3,"
      log "Scene 3/4 complete: $clip3"
    fi
    
    # Scene 4: Ingredient Detail + Callout (6-8s)
    local scene4_prompt="Scene 4/4: Close-up of ingredients, macro shots of fresh food texture, bright kitchen background, authentic UGC style, slight handheld movement, food looks appetizing and fresh."
    
    echo "  [Scene 4/4] Generating ingredient details..."
    local clip4="${ugc_dir}/clip_4_detail.mp4"
    sora_generate --prompt "${smart_prompt}. ${scene4_prompt}" \
      --image "${reference:-}" --duration "$scene_duration" --aspect-ratio "$ratio" \
      --output "$clip4" \
      ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "      $line"; done || true
    
    if [ -f "$clip4" ]; then
      clip_list="$clip_list$clip4,"
      log "Scene 4/4 complete: $clip4"
    fi
    
  else
    # Non-MIRRA: generate single video
    echo "  Standard mode: single video (no storyboard)"
    local sora_output="${ugc_dir}/sora-raw.mp4"

    if [ -n "$reference" ] && [ -f "$reference" ]; then
      # Image-to-video mode
      echo "  Mode: image-to-video (from reference)"
      sora_generate --prompt "$smart_prompt" --image "$reference" \
        --duration "$duration" --aspect-ratio "$ratio" --output "$sora_output" \
        ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "    $line"; done || true
    else
      # Text-to-video mode
      echo "  Mode: text-to-video"
      sora_generate --prompt "$smart_prompt" \
        --duration "$duration" --aspect-ratio "$ratio" --output "$sora_output" \
        ${brand:+--brand "$brand"} 2>&1 | while IFS= read -r line; do echo "    $line"; done || true
    fi

    if [ ! -f "$sora_output" ]; then
      echo "ERROR: Sora generation failed"
      log "ERROR: sora-ugc generation failed"
      exit 1
    fi
    
    clip_list="$sora_output"
  fi
  
  # Remove trailing comma if any
  clip_list="${clip_list%,}"
  
  # Check if any clips were generated
  if [ -z "$clip_list" ]; then
    echo "ERROR: No video clips were generated"
    log "ERROR: sora-ugc no clips generated"
    exit 1
  fi
  
  echo ""
  
  # Step 3b: Assemble clips if storyboard mode
  local sora_output="${ugc_dir}/sora-raw.mp4"
  if [ "$brand" = "mirra" ]; then
    echo "--- Step 3b: Assembling Storyboard Clips ---"
    
    # Count clips
    local clip_count
    clip_count=$(echo "$clip_list" | tr ',' '\n' | wc -l | tr -d ' ')
    echo "  Generated $clip_count/4 clips"
    
    # If we have multiple clips, assemble them
    if [ "$clip_count" -gt 1 ]; then
      echo "  Assembling clips with ffmpeg..."
      
      # Create concat file
      local concat_file="${ugc_dir}/concat.txt"
      echo "$clip_list" | tr ',' '\n' | while IFS= read -r clip; do
        echo "file '$clip'"
      done > "$concat_file"
      
      # Assemble with ffmpeg (all clips should be same resolution)
      ffmpeg -y -f concat -safe 0 -i "$concat_file" \
        -c:v libx264 -preset fast -crf 22 \
        -c:a aac -b:a 128k \
        "$sora_output" 2>&1 | grep -v "^\[" || true
      
      if [ -f "$sora_output" ]; then
        echo "  ✓ Assembly complete: $sora_output"
        log "Storyboard assembly complete: $sora_output ($clip_count clips)"
      else
        echo "  ⚠ Assembly failed, using first clip"
        local first_clip
        first_clip=$(echo "$clip_list" | cut -d',' -f1)
        cp "$first_clip" "$sora_output"
      fi
    else
      echo "  Only 1 clip generated, using as-is"
      cp "$clip_list" "$sora_output"
    fi
    
    echo ""
  fi

  # Step 4: Post-production via VideoForge
  echo "--- Step 4: Post-Production (VideoForge) ---"
  local final_output="${output:-${ugc_dir}/final.mp4}"

  if [ -x "$VIDEO_FORGE" ]; then
    bash "$VIDEO_FORGE" produce "$sora_output" \
      --type ugc \
      ${brand:+--brand "$brand"} \
      --grain light \
      --caption \
      --output "$final_output" 2>&1 | while IFS= read -r line; do echo "    $line"; done || true

    if [ ! -f "$final_output" ]; then
      echo "  VideoForge failed, using raw Sora output"
      cp "$sora_output" "$final_output"
    fi
  else
    echo "  VideoForge not found, using raw Sora output"
    cp "$sora_output" "$final_output"
  fi
  echo ""

  # Step 5: Brand voice check
  echo "--- Step 5: QA ---"
  local bvc="$HOME/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh"
  if [ -n "$brand" ] && [ -f "$bvc" ]; then
    echo "  Running brand voice check on prompt..."
    bash "$bvc" --brand "$brand" --text "$concept" 2>/dev/null | head -3 | while IFS= read -r line; do echo "    $line"; done || echo "    (check skipped)"
  else
    echo "  Brand voice check: skipped (no brand or script)"
  fi
  echo ""

  # Summary
  echo "=== Sora UGC Pipeline Complete ==="
  echo "Raw:    $sora_output"
  echo "Final:  $final_output"
  echo "Prompt: $ugc_dir/smart-prompt.txt"
  [ -f "$ugc_dir/visual-dna.txt" ] && echo "DNA:    $ugc_dir/visual-dna.txt"
  echo "Cost:   ~\$0.50"
  echo ""

  log "sora-ugc complete: $final_output"

  post_generate "sora" "ugc-pipeline" "$final_output" "$brand" "$concept"
  echo "$final_output"
}

# ============================================================
# USAGE
# ============================================================

usage() {
  cat <<'USAGE'
video-gen.sh — Unified Video Generation CLI for GAIA CORP-OS

PROVIDERS:
  kling    Kling AI (text2video, image2video, status, download)
  wan      Wan 2.2 via fal.ai (text2video, image2video, image2video-pro, status, download)
  sora     Sora 2 via OpenAI (generate, image2video, status, download)

COMMANDS:
  sora-ugc        Full UGC workflow: reverse-prompt -> smart prompt -> Sora 2 -> post-prod
  pipeline        Chain: NanoBanana images -> video gen -> video-forge assembly
  reverse-prompt  Extract frames from video -> Gemini Vision analysis
  status          Auto-detect provider from task ID and check status

USAGE — Provider:
  video-gen.sh kling text2video "prompt" [--duration 5] [--aspect-ratio 9:16] [--brand pinxin-vegan]
  video-gen.sh kling image2video --image "url" [--prompt "..."] [--duration 5]
  video-gen.sh kling status <task_id>
  video-gen.sh kling download <task_id> [--output path.mp4]

  video-gen.sh wan text2video "prompt" [--duration 5] [--aspect-ratio 9:16] [--resolution 720p]
  video-gen.sh wan image2video --image "url_or_path" [--prompt "..."] [--duration 5] [--pro]
  video-gen.sh wan image2video-pro --image "url_or_path" [--prompt "..."]
  video-gen.sh wan status <request_id> [--model text2video]
  video-gen.sh wan download <request_id> [--model text2video] [--output path.mp4]

  video-gen.sh sora generate "prompt" [--duration 5] [--aspect-ratio 9:16]
  video-gen.sh sora image2video --image path.jpg [--prompt "..."] [--duration 5]
  video-gen.sh sora status <video_id>
  video-gen.sh sora download <video_id> [--output path.mp4]

USAGE — Pipeline:
  video-gen.sh pipeline --prompt "Brand story for Pinxin Vegan" --brand pinxin-vegan \
    --provider wan --scenes 3 --duration 5 --aspect-ratio 9:16

USAGE — Sora UGC (Storyboard 6 Approach):
  video-gen.sh sora-ugc --prompt "Healthy bento box for working professionals" \
    --brand mirra --image /path/to/bento-sku.jpg \
    --duration 8 --aspect-ratio 9:16
  
  For MIRRA brand, automatically generates 4 storyboard scenes:
  - Scene 1: Bento reveal (0-2s)
  - Scene 2: Hands placing ingredients (2-4s)
  - Scene 3: Completed bento with steam (4-6s)
  - Scene 4: Ingredient details (6-8s)

USAGE — Reverse Prompt:
  video-gen.sh reverse-prompt /path/to/video.mp4

COMMON OPTIONS:
  --prompt "..."         Generation prompt
  --image <path|url>     SKU reference image (MIRRA: validates bento image)
  --brand <slug>         Brand slug (loads DNA.json for motion_language)
  --duration <seconds>   Target duration (Sora: 4, 8, or 12 only; default: 5)
  --aspect-ratio <ratio> 9:16, 16:9, 1:1 (default: 9:16)
  --output <path>        Output file path
  --dry-run              Show request without submitting

COST ESTIMATES:
  Kling text2video:      ~$0.30
  Kling image2video:     ~$0.30
  Wan text2video:        ~$0.20
  Wan image2video:       ~$0.20
  Wan image2video-pro:   ~$0.80
  Sora generate:         ~$0.50

ENVIRONMENT VARIABLES:
  KLING_ACCESS_KEY, KLING_SECRET_KEY  Kling AI credentials
  FAL_API_KEY                         fal.ai API key (for Wan)
  OPENAI_API_KEY                      OpenAI API key (for Sora)
  GEMINI_API_KEY                      Google Gemini API key (for reverse-prompt)
USAGE
}

# ============================================================
# MAIN ROUTER
# ============================================================

main() {
  load_env

  case "${1:-}" in
    kling)
      shift
      case "${1:-}" in
        text2video)  shift; kling_text2video "$@" ;;
        image2video) shift; kling_image2video "$@" ;;
        status)      shift; kling_status "$@" ;;
        download)    shift; kling_download "$@" ;;
        *) echo "Usage: video-gen.sh kling text2video|image2video|status|download"; exit 1 ;;
      esac
      ;;
    wan)
      shift
      case "${1:-}" in
        text2video)      shift; wan_text2video "$@" ;;
        image2video)     shift; wan_image2video "$@" ;;
        image2video-pro) shift; wan_image2video_pro "$@" ;;
        status)          shift; wan_status "$@" ;;
        download)        shift; wan_download "$@" ;;
        *) echo "Usage: video-gen.sh wan text2video|image2video|image2video-pro|status|download"; exit 1 ;;
      esac
      ;;
    sora)
      shift
      case "${1:-}" in
        generate)    shift; sora_generate "$@" ;;
        image2video) shift; sora_generate "$@" ;;
        status)      shift; sora_status "$@" ;;
        download)    shift; sora_download "$@" ;;
        *) echo "Usage: video-gen.sh sora generate|image2video|status|download"; exit 1 ;;
      esac
      ;;
    sora-ugc)       shift; sora_ugc_pipeline "$@" ;;
    pipeline)       shift; pipeline "$@" ;;
    reverse-prompt) shift; reverse_prompt "$@" ;;
    status)         shift; auto_status "$@" ;;
    help|--help|-h) usage ;;
    "")             usage; exit 1 ;;
    *)
      echo "Unknown provider/command: $1"
      echo ""
      usage
      exit 1
      ;;
  esac
}

main "$@"
