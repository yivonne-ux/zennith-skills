#!/usr/bin/env bash
# ad-image-gen.sh — Unified Ad Image Generation CLI for GAIA CORP-OS
# Wraps NanoBanana (Gemini), Recraft V4, and Flux 2 Pro (fal.ai) into a single CLI.
# macOS-compatible: Bash 3.2, no declare -A, no ${var,,}, no GNU timeout
# ---

set -euo pipefail

# ---------------------------------------------------------------------------
# Load environment
# ---------------------------------------------------------------------------

ENV_FILE="$HOME/.openclaw/.env"
if [ -f "$ENV_FILE" ]; then
  # Source each KEY=VALUE line, skipping comments and blanks
  while IFS= read -r line; do
    case "$line" in
      \#*|"") continue ;;
      *=*)
        key="${line%%=*}"
        val="${line#*=}"
        # Only export if not already set
        if [ -z "$(eval echo "\${${key}:-}")" ]; then
          export "$key=$val"
        fi
        ;;
    esac
  done < "$ENV_FILE"
fi

# Also try secrets dir
[ -z "${GEMINI_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/gemini.env" ] && \
  export "$(grep '^GEMINI_API_KEY=' "$HOME/.openclaw/secrets/gemini.env" | head -1)" 2>/dev/null || true

# Normalize key names: support both FAL_KEY and FAL_API_KEY
if [ -z "${FAL_KEY:-}" ] && [ -n "${FAL_API_KEY:-}" ]; then
  export FAL_KEY="$FAL_API_KEY"
fi
if [ -z "${FAL_API_KEY:-}" ] && [ -n "${FAL_KEY:-}" ]; then
  export FAL_API_KEY="$FAL_KEY"
fi

# Support both GEMINI_API_KEY and GOOGLE_API_KEY
if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
  export GEMINI_API_KEY="$GOOGLE_API_KEY"
fi

# ---------------------------------------------------------------------------
# Constants & Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
IMAGES_DIR="$HOME/.openclaw/workspace/data/images"
LOG_FILE="$HOME/.openclaw/logs/ad-image-gen.log"
NANOBANANA_SCRIPT="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"

VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() {
  echo "ERROR: $*" >&2
  log "ERROR" "$*"
  exit 1
}

warn() {
  echo "WARN: $*" >&2
  log "WARN" "$*"
}

info() {
  echo "INFO: $*" >&2
  log "INFO" "$*"
}

log() {
  local level="$1"
  shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$ts] [$level] $*" >> "$LOG_FILE"
}

to_lower() {
  echo "$1" | tr 'A-Z' 'a-z'
}

timestamp_str() {
  date '+%Y%m%d_%H%M%S'
}

# JSON-escape a string for embedding in curl payloads
json_escape() {
  python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$1"
}

# ---------------------------------------------------------------------------
# Brand Profile Loading (shared with NanoBanana pattern)
# ---------------------------------------------------------------------------

BRAND_NAME=""
BRAND_STYLE=""
BRAND_LIGHTING=""
BRAND_PHOTO_STYLE=""
BRAND_COLOR_PRIMARY=""
BRAND_COLOR_SECONDARY=""
BRAND_COLOR_BG=""

load_brand_profile() {
  local brand_slug="$1"
  local profile_path="$BRANDS_DIR/${brand_slug}/DNA.json"

  if [ -f "$profile_path" ]; then
    log "INFO" "Loading brand profile: $profile_path"
    eval "$(python3 -c "
import json, sys

with open(sys.argv[1], 'r') as f:
    b = json.loads(f.read())

def sh_escape(s):
    if s is None:
        return ''
    return str(s).replace(\"'\", \"'\\\"'\\\"'\")

visual = b.get('visual', {})
colors = visual.get('colors', {})
print(\"BRAND_NAME='%s'\" % sh_escape(b.get('display_name', b.get('brand', ''))))
print(\"BRAND_COLOR_PRIMARY='%s'\" % sh_escape(colors.get('primary', '')))
print(\"BRAND_COLOR_SECONDARY='%s'\" % sh_escape(colors.get('secondary', '')))
print(\"BRAND_COLOR_BG='%s'\" % sh_escape(colors.get('background', '')))
print(\"BRAND_STYLE='%s'\" % sh_escape(visual.get('style', '')))
print(\"BRAND_LIGHTING='%s'\" % sh_escape(visual.get('lighting_default', '')))
print(\"BRAND_PHOTO_STYLE='%s'\" % sh_escape(visual.get('photography', '')))
" "$profile_path" 2>/dev/null)" || warn "Could not parse brand profile: $profile_path"
  else
    warn "No brand profile at $profile_path"
  fi
}

brand_enrichment() {
  if [ -z "$BRAND_NAME" ]; then
    echo ""
    return
  fi
  local parts="Brand: ${BRAND_NAME}."
  if [ -n "$BRAND_STYLE" ]; then
    parts="${parts} Style: ${BRAND_STYLE}."
  fi
  if [ -n "$BRAND_LIGHTING" ]; then
    parts="${parts} Lighting: ${BRAND_LIGHTING}."
  fi
  if [ -n "$BRAND_COLOR_PRIMARY" ]; then
    parts="${parts} Colors: primary ${BRAND_COLOR_PRIMARY}"
    if [ -n "$BRAND_COLOR_SECONDARY" ]; then
      parts="${parts}, secondary ${BRAND_COLOR_SECONDARY}"
    fi
    parts="${parts}."
  fi
  echo "$parts"
}

# Prepend brand context to a prompt if brand is loaded
enrich_prompt() {
  local prompt="$1"
  local enrichment
  enrichment=$(brand_enrichment)
  if [ -n "$enrichment" ]; then
    echo "${enrichment} ${prompt}"
  else
    echo "$prompt"
  fi
}

# ---------------------------------------------------------------------------
# Aspect ratio mapping per model
# ---------------------------------------------------------------------------

# Map common aspect ratios to Recraft sizes
recraft_size_for_ratio() {
  local ratio="$1"
  local quality="$2"
  case "$ratio" in
    1:1)   if [ "$quality" = "high" ]; then echo "2048x2048"; else echo "1024x1024"; fi ;;
    4:5)   if [ "$quality" = "high" ]; then echo "2048x2048"; else echo "1024x1280"; fi ;;
    5:4)   if [ "$quality" = "high" ]; then echo "2048x2048"; else echo "1280x1024"; fi ;;
    9:16)  if [ "$quality" = "high" ]; then echo "2048x2048"; else echo "1024x1280"; fi ;;
    16:9)  if [ "$quality" = "high" ]; then echo "2048x2048"; else echo "1280x1024"; fi ;;
    *)     if [ "$quality" = "high" ]; then echo "2048x2048"; else echo "1024x1024"; fi ;;
  esac
}

# Map common aspect ratios to Flux image_size presets
flux_size_for_ratio() {
  local ratio="$1"
  case "$ratio" in
    1:1)   echo "square_hd" ;;
    4:5)   echo "portrait_4_3" ;;
    5:4)   echo "landscape_4_3" ;;
    9:16)  echo "portrait_16_9" ;;
    16:9)  echo "landscape_16_9" ;;
    *)     echo "square_hd" ;;
  esac
}

# ---------------------------------------------------------------------------
# Model: NanoBanana (Gemini) — delegates to nanobanana-gen.sh
# ---------------------------------------------------------------------------

generate_nanobanana() {
  local prompt="$1"
  local output="$2"
  local aspect_ratio="$3"
  local style_seed="$4"
  local ref_image="$5"
  local brand="$6"

  if [ ! -f "$NANOBANANA_SCRIPT" ]; then
    die "NanoBanana script not found at $NANOBANANA_SCRIPT"
  fi

  local args=""
  args="generate"
  args="$args --prompt $(json_escape "$prompt")"
  # NanoBanana doesn't support --output flag, it auto-saves to ${IMAGES_DIR}/${brand}/
  if [ -n "$aspect_ratio" ]; then
    args="$args --ratio $aspect_ratio"
  fi
  if [ -n "$style_seed" ]; then
    args="$args --style-seed $style_seed"
  fi
  if [ -n "$ref_image" ]; then
    args="$args --ref-image $ref_image"
  fi
  if [ -n "$brand" ]; then
    args="$args --brand $brand"
  fi

  info "Delegating to NanoBanana: nanobanana-gen.sh $args"
  # Use eval to handle the quoted prompt properly
  local nb_args="generate"
  local nb_cmd=("bash" "$NANOBANANA_SCRIPT" "generate" "--prompt" "$prompt")
  # NanoBanana doesn't support --output flag
  if [ -n "$aspect_ratio" ]; then
    nb_cmd+=("--ratio" "$aspect_ratio")
  fi
  if [ -n "$style_seed" ]; then
    nb_cmd+=("--style-seed" "$style_seed")
  fi
  if [ -n "$ref_image" ]; then
    nb_cmd+=("--ref-image" "$ref_image")
  fi
  if [ -n "$brand" ]; then
    nb_cmd+=("--brand" "$brand")
  fi

  "${nb_cmd[@]}"
}

# ---------------------------------------------------------------------------
# Model: Recraft V4 (direct API)
# ---------------------------------------------------------------------------

generate_recraft() {
  local prompt="$1"
  local output="$2"
  local size="$3"
  local style="$4"

  if [ -z "${RECRAFT_API_KEY:-}" ]; then
    die "RECRAFT_API_KEY not set. Add it to $ENV_FILE"
  fi

  # Build JSON payload
  local payload
  payload=$(python3 -c "
import json, sys

prompt = sys.argv[1]
size = sys.argv[2]
style = sys.argv[3]

body = {
    'prompt': prompt,
    'model': 'recraftv4',
    'size': size
}
if style:
    body['style'] = style

print(json.dumps(body))
" "$prompt" "$size" "$style")

  info "Calling Recraft V4 API: size=$size style=${style:-default}"
  log "INFO" "Recraft prompt: $prompt"

  local response_file
  response_file=$(mktemp /tmp/ad-recraft-resp.XXXXXX)
  local http_code_file
  http_code_file=$(mktemp /tmp/ad-recraft-http.XXXXXX)

  curl -s -w '%{http_code}' \
    -X POST "https://external.api.recraft.ai/v1/images/generations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $RECRAFT_API_KEY" \
    -d "$payload" \
    -o "$response_file" \
    > "$http_code_file" 2>/dev/null &

  local curl_pid=$!

  # Wait up to 120 seconds (macOS-safe)
  local waited=0
  while kill -0 "$curl_pid" 2>/dev/null; do
    if [ "$waited" -ge 120 ]; then
      kill "$curl_pid" 2>/dev/null || true
      rm -f "$response_file" "$http_code_file"
      die "Recraft API call timed out after 120 seconds"
    fi
    sleep 1
    waited=$((waited + 1))
  done

  wait "$curl_pid" 2>/dev/null
  local exit_code=$?

  local http_code
  http_code=$(cat "$http_code_file" 2>/dev/null | tr -d '[:space:]')
  rm -f "$http_code_file"

  if [ "$exit_code" -ne 0 ]; then
    local err_body
    err_body=$(cat "$response_file" 2>/dev/null || echo "no response")
    rm -f "$response_file"
    die "Recraft curl failed (exit=$exit_code). Response: $err_body"
  fi

  if [ "$http_code" != "200" ]; then
    local err_body
    err_body=$(cat "$response_file" 2>/dev/null || echo "no response")
    rm -f "$response_file"
    die "Recraft API returned HTTP $http_code: $(echo "$err_body" | head -c 500)"
  fi

  # Extract image URL from response: data[0].url
  local image_url
  image_url=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    data = json.loads(f.read())
urls = [item.get('url', '') for item in data.get('data', [])]
if urls and urls[0]:
    print(urls[0])
else:
    print('ERROR:' + json.dumps(data)[:200])
" "$response_file")

  rm -f "$response_file"

  if echo "$image_url" | grep -q '^ERROR:'; then
    die "Recraft response missing image URL: $image_url"
  fi

  # Download image
  mkdir -p "$(dirname "$output")"
  info "Downloading Recraft image to $output"

  curl -s -L -o "$output" "$image_url" 2>/dev/null
  if [ ! -f "$output" ] || [ ! -s "$output" ]; then
    die "Failed to download Recraft image from $image_url"
  fi

  log "INFO" "Recraft image saved: $output"
  echo "$output"
}

# ---------------------------------------------------------------------------
# Model: Flux 2 Pro (fal.ai queue API)
# ---------------------------------------------------------------------------

generate_flux() {
  local prompt="$1"
  local output="$2"
  local image_size="$3"

  if [ -z "${FAL_KEY:-}" ]; then
    die "FAL_KEY / FAL_API_KEY not set. Add it to $ENV_FILE"
  fi

  local auth_key="$FAL_KEY"

  # Build JSON payload
  local payload
  payload=$(python3 -c "
import json, sys
prompt = sys.argv[1]
image_size = sys.argv[2]
body = {
    'prompt': prompt,
    'image_size': image_size,
    'num_images': 1,
    'safety_tolerance': '5'
}
print(json.dumps(body))
" "$prompt" "$image_size")

  info "Submitting to Flux 2 Pro (fal.ai): image_size=$image_size"
  log "INFO" "Flux prompt: $prompt"

  # Submit to queue
  local submit_resp
  submit_resp=$(curl -s -X POST "https://queue.fal.run/fal-ai/flux-pro/v1.1" \
    -H "Authorization: Key $auth_key" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null)

  local request_id
  request_id=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
rid = data.get('request_id', '')
if rid:
    print(rid)
else:
    print('ERROR:' + json.dumps(data)[:300])
" "$submit_resp")

  if echo "$request_id" | grep -q '^ERROR:'; then
    die "Flux submit failed: $request_id"
  fi

  info "Flux request submitted: $request_id — polling for result..."

  # Poll for completion (max 300 seconds = 5 minutes)
  local max_wait=300
  local poll_interval=3
  local waited=0
  local status=""
  local result_resp=""

  while [ "$waited" -lt "$max_wait" ]; do
    result_resp=$(curl -s "https://queue.fal.run/fal-ai/flux-pro/v1.1/requests/${request_id}/status" \
      -H "Authorization: Key $auth_key" 2>/dev/null)

    status=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    print(data.get('status', 'UNKNOWN'))
except:
    print('PARSE_ERROR')
" "$result_resp")

    case "$status" in
      COMPLETED)
        info "Flux generation completed"
        break
        ;;
      FAILED|ERROR)
        die "Flux generation failed: $(echo "$result_resp" | head -c 300)"
        ;;
      IN_QUEUE|IN_PROGRESS|PENDING)
        sleep "$poll_interval"
        waited=$((waited + poll_interval))
        ;;
      *)
        sleep "$poll_interval"
        waited=$((waited + poll_interval))
        ;;
    esac
  done

  if [ "$status" != "COMPLETED" ]; then
    die "Flux generation timed out after ${max_wait}s (status: $status)"
  fi

  # Fetch the actual result
  local final_resp
  final_resp=$(curl -s "https://queue.fal.run/fal-ai/flux-pro/v1.1/requests/${request_id}" \
    -H "Authorization: Key $auth_key" 2>/dev/null)

  # Extract image URL
  local image_url
  image_url=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    images = data.get('images', [])
    if images:
        print(images[0].get('url', ''))
    else:
        # Try alternate response structure
        output = data.get('output', {})
        images = output.get('images', [])
        if images:
            print(images[0].get('url', ''))
        else:
            print('ERROR:' + json.dumps(data)[:300])
except Exception as e:
    print('ERROR:' + str(e))
" "$final_resp")

  if [ -z "$image_url" ] || echo "$image_url" | grep -q '^ERROR:'; then
    die "Flux response missing image URL: $image_url"
  fi

  # Download
  mkdir -p "$(dirname "$output")"
  info "Downloading Flux image to $output"

  curl -s -L -o "$output" "$image_url" 2>/dev/null
  if [ ! -f "$output" ] || [ ! -s "$output" ]; then
    die "Failed to download Flux image from $image_url"
  fi

  log "INFO" "Flux image saved: $output"
  echo "$output"
}

# ---------------------------------------------------------------------------
# Model: Flux 2 Pro (fal.ai queue API — fal-ai/flux-2-pro)
# Upgraded model: better text rendering, HEX color support, up to 10 ref images
# Endpoint: https://queue.fal.run/fal-ai/flux-2-pro
# Cost: ~$0.03/image at 1024x1024
# ---------------------------------------------------------------------------

generate_flux2() {
  local prompt="$1"
  local output="$2"
  local image_size="$3"

  if [ -z "${FAL_KEY:-}" ]; then
    die "FAL_KEY / FAL_API_KEY not set. Add it to $ENV_FILE"
  fi

  local auth_key="$FAL_KEY"

  # Build JSON payload
  local payload
  payload=$(python3 -c "
import json, sys
prompt = sys.argv[1]
image_size = sys.argv[2]
body = {
    'prompt': prompt,
    'image_size': image_size,
    'num_images': 1,
    'safety_tolerance': '5'
}
print(json.dumps(body))
" "$prompt" "$image_size")

  info "Submitting to Flux 2 Pro (fal.ai): image_size=$image_size"
  log "INFO" "Flux 2 prompt: $prompt"

  # Submit to queue
  local submit_resp
  submit_resp=$(curl -s -X POST "https://queue.fal.run/fal-ai/flux-2-pro" \
    -H "Authorization: Key $auth_key" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null)

  local request_id
  request_id=$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
rid = data.get('request_id', '')
if rid:
    print(rid)
else:
    print('ERROR:' + json.dumps(data)[:300])
" "$submit_resp")

  if echo "$request_id" | grep -q '^ERROR:'; then
    die "Flux 2 submit failed: $request_id"
  fi

  info "Flux 2 request submitted: $request_id — polling for result..."

  # Poll for completion (max 300 seconds = 5 minutes)
  local max_wait=300
  local poll_interval=3
  local waited=0
  local status=""
  local result_resp=""

  while [ "$waited" -lt "$max_wait" ]; do
    result_resp=$(curl -s "https://queue.fal.run/fal-ai/flux-2-pro/requests/${request_id}/status" \
      -H "Authorization: Key $auth_key" 2>/dev/null)

    status=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    print(data.get('status', 'UNKNOWN'))
except:
    print('PARSE_ERROR')
" "$result_resp")

    case "$status" in
      COMPLETED)
        info "Flux 2 generation completed"
        break
        ;;
      FAILED|ERROR)
        die "Flux 2 generation failed: $(echo "$result_resp" | head -c 300)"
        ;;
      IN_QUEUE|IN_PROGRESS|PENDING)
        sleep "$poll_interval"
        waited=$((waited + poll_interval))
        ;;
      *)
        sleep "$poll_interval"
        waited=$((waited + poll_interval))
        ;;
    esac
  done

  if [ "$status" != "COMPLETED" ]; then
    die "Flux 2 generation timed out after ${max_wait}s (status: $status)"
  fi

  # Fetch the actual result
  local final_resp
  final_resp=$(curl -s "https://queue.fal.run/fal-ai/flux-2-pro/requests/${request_id}" \
    -H "Authorization: Key $auth_key" 2>/dev/null)

  # Extract image URL from response: images[0].url
  local image_url
  image_url=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    images = data.get('images', [])
    if images:
        print(images[0].get('url', ''))
    else:
        # Try alternate response structure
        output = data.get('output', {})
        images = output.get('images', [])
        if images:
            print(images[0].get('url', ''))
        else:
            print('ERROR:' + json.dumps(data)[:300])
except Exception as e:
    print('ERROR:' + str(e))
" "$final_resp")

  if [ -z "$image_url" ] || echo "$image_url" | grep -q '^ERROR:'; then
    die "Flux 2 response missing image URL: $image_url"
  fi

  # Download
  mkdir -p "$(dirname "$output")"
  info "Downloading Flux 2 image to $output"

  curl -s -L -o "$output" "$image_url" 2>/dev/null
  if [ ! -f "$output" ] || [ ! -s "$output" ]; then
    die "Failed to download Flux 2 image from $image_url"
  fi

  log "INFO" "Flux 2 image saved: $output"
  echo "$output"
}

# ---------------------------------------------------------------------------
# Command: generate
# ---------------------------------------------------------------------------

cmd_generate() {
  local model=""
  local prompt=""
  local output=""
  local brand=""
  local aspect_ratio=""
  local quality="standard"
  local style=""
  local size=""
  local style_seed=""
  local ref_image=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --model)       shift; model="$(to_lower "$1")" ;;
      --prompt)      shift; prompt="$1" ;;
      --output)      shift; output="$1" ;;
      --brand)       shift; brand="$(to_lower "$1")" ;;
      --aspect-ratio) shift; aspect_ratio="$1" ;;
      --quality)     shift; quality="$(to_lower "$1")" ;;
      --style)       shift; style="$1" ;;
      --size)        shift; size="$1" ;;
      --style-seed)  shift; style_seed="$1" ;;
      --ref-image)   shift; ref_image="$1" ;;
      *)             die "Unknown flag for generate: $1" ;;
    esac
    shift
  done

  # Validate required
  if [ -z "$model" ]; then
    die "Missing --model. Options: nanobanana, recraft, recraft-pro, flux, flux2"
  fi
  if [ -z "$prompt" ]; then
    die "Missing --prompt"
  fi

  # Default aspect ratio
  if [ -z "$aspect_ratio" ]; then
    aspect_ratio="1:1"
  fi

  # Default output path
  if [ -z "$output" ]; then
    mkdir -p "$IMAGES_DIR/ad-composer"
    output="$IMAGES_DIR/ad-composer/${model}_$(timestamp_str).png"
  fi

  # Load brand if specified
  if [ -n "$brand" ]; then
    load_brand_profile "$brand"
    prompt=$(enrich_prompt "$prompt")
  fi

  info "Model: $model | Aspect: $aspect_ratio | Quality: $quality"
  info "Output: $output"

  case "$model" in
    nanobanana|nano|nb)
      generate_nanobanana "$prompt" "$output" "$aspect_ratio" "$style_seed" "$ref_image" "$brand"
      ;;
    recraft)
      # Determine size from aspect ratio or explicit --size
      if [ -z "$size" ]; then
        size=$(recraft_size_for_ratio "$aspect_ratio" "$quality")
      fi
      generate_recraft "$prompt" "$output" "$size" "$style"
      ;;
    recraft-pro|recraft_pro)
      # Force 2048x2048 for pro
      if [ -z "$size" ]; then
        size="2048x2048"
      fi
      generate_recraft "$prompt" "$output" "$size" "$style"
      ;;
    flux|flux-pro)
      local flux_size
      flux_size=$(flux_size_for_ratio "$aspect_ratio")
      generate_flux "$prompt" "$output" "$flux_size"
      ;;
    flux2|flux-2|flux-2-pro|flux2-pro)
      local flux2_size
      flux2_size=$(flux_size_for_ratio "$aspect_ratio")
      generate_flux2 "$prompt" "$output" "$flux2_size"
      ;;
    *)
      die "Unknown model: $model. Options: nanobanana, recraft, recraft-pro, flux, flux2"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Command: batch
# ---------------------------------------------------------------------------

cmd_batch() {
  local model=""
  local prompt_file=""
  local output_dir=""
  local brand=""
  local aspect_ratio=""
  local quality="standard"
  local style=""
  local style_seed=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --model)       shift; model="$(to_lower "$1")" ;;
      --prompt-file) shift; prompt_file="$1" ;;
      --output-dir)  shift; output_dir="$1" ;;
      --brand)       shift; brand="$(to_lower "$1")" ;;
      --aspect-ratio) shift; aspect_ratio="$1" ;;
      --quality)     shift; quality="$(to_lower "$1")" ;;
      --style)       shift; style="$1" ;;
      --style-seed)  shift; style_seed="$1" ;;
      *)             die "Unknown flag for batch: $1" ;;
    esac
    shift
  done

  if [ -z "$model" ]; then
    die "Missing --model"
  fi
  if [ -z "$prompt_file" ]; then
    die "Missing --prompt-file (JSON array of prompts)"
  fi
  if [ ! -f "$prompt_file" ]; then
    die "Prompt file not found: $prompt_file"
  fi

  # Default output dir
  if [ -z "$output_dir" ]; then
    output_dir="$IMAGES_DIR/ad-composer/batch_$(timestamp_str)"
  fi
  mkdir -p "$output_dir"

  # Read prompts from JSON array
  local count
  count=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    prompts = json.loads(f.read())
if not isinstance(prompts, list):
    print('0')
else:
    print(len(prompts))
" "$prompt_file")

  if [ "$count" = "0" ]; then
    die "No prompts found in $prompt_file (expected JSON array of strings)"
  fi

  info "Batch mode: $count prompts with model=$model"

  local i=0
  while [ "$i" -lt "$count" ]; do
    local p
    p=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    prompts = json.loads(f.read())
idx = int(sys.argv[2])
if isinstance(prompts[idx], str):
    print(prompts[idx])
elif isinstance(prompts[idx], dict):
    print(prompts[idx].get('prompt', ''))
" "$prompt_file" "$i")

    if [ -z "$p" ]; then
      warn "Skipping empty prompt at index $i"
      i=$((i + 1))
      continue
    fi

    local padded
    padded=$(printf "%03d" "$i")
    local out_file="$output_dir/${padded}_${model}.png"

    info "[$((i + 1))/$count] Generating: $(echo "$p" | head -c 60)..."

    # Build generate args
    local gen_args="--model $model --prompt"
    local gen_cmd=("--model" "$model" "--prompt" "$p")
    # NanoBanana doesn't support --output flag, it auto-saves to ${IMAGES_DIR}/${brand}/
    # For other models, include output path
    if [ "$model" != "nanobanana" ]; then
      gen_cmd+=("--output" "$out_file")
    fi
    if [ -n "$brand" ]; then
      gen_cmd+=("--brand" "$brand")
    fi
    if [ -n "$aspect_ratio" ]; then
      gen_cmd+=("--aspect-ratio" "$aspect_ratio")
    fi
    if [ -n "$quality" ]; then
      gen_cmd+=("--quality" "$quality")
    fi
    if [ -n "$style" ]; then
      gen_cmd+=("--style" "$style")
    fi
    if [ -n "$style_seed" ]; then
      gen_cmd+=("--style-seed" "$style_seed")
    fi

    cmd_generate "${gen_cmd[@]}" || warn "Failed to generate image $i"

    i=$((i + 1))
  done

  info "Batch complete: $count images in $output_dir"
  echo "$output_dir"
}

# ---------------------------------------------------------------------------
# Command: compare
# ---------------------------------------------------------------------------

cmd_compare() {
  local prompt=""
  local output_dir=""
  local brand=""
  local aspect_ratio=""
  local quality="standard"

  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt)      shift; prompt="$1" ;;
      --output-dir)  shift; output_dir="$1" ;;
      --brand)       shift; brand="$(to_lower "$1")" ;;
      --aspect-ratio) shift; aspect_ratio="$1" ;;
      --quality)     shift; quality="$(to_lower "$1")" ;;
      *)             die "Unknown flag for compare: $1" ;;
    esac
    shift
  done

  if [ -z "$prompt" ]; then
    die "Missing --prompt"
  fi

  if [ -z "$output_dir" ]; then
    output_dir="$IMAGES_DIR/ad-composer/compare_$(timestamp_str)"
  fi
  mkdir -p "$output_dir"

  info "Compare mode: generating same prompt across all models"
  info "Prompt: $(echo "$prompt" | head -c 80)..."
  info "Output: $output_dir"

  local succeeded=0
  local failed=0

  # Model 1: NanoBanana
  local nb_args=("--model" "nanobanana" "--prompt" "$prompt")
  # NanoBanana doesn't support --output flag
  if [ -n "$brand" ]; then nb_args+=("--brand" "$brand"); fi
  if [ -n "$aspect_ratio" ]; then nb_args+=("--aspect-ratio" "$aspect_ratio"); fi
  if [ -n "$quality" ]; then nb_args+=("--quality" "$quality"); fi

  info "[1/4] NanoBanana (Gemini)..."
  if cmd_generate "${nb_args[@]}"; then
    succeeded=$((succeeded + 1))
  else
    warn "NanoBanana generation failed"
    failed=$((failed + 1))
  fi

  # Model 2: Recraft
  local rc_args=("--model" "recraft" "--prompt" "$prompt" "--output" "$output_dir/recraft.png")
  if [ -n "$brand" ]; then rc_args+=("--brand" "$brand"); fi
  if [ -n "$aspect_ratio" ]; then rc_args+=("--aspect-ratio" "$aspect_ratio"); fi
  if [ -n "$quality" ]; then rc_args+=("--quality" "$quality"); fi

  info "[2/4] Recraft V4..."
  if cmd_generate "${rc_args[@]}"; then
    succeeded=$((succeeded + 1))
  else
    warn "Recraft generation failed"
    failed=$((failed + 1))
  fi

  # Model 3: Flux Pro v1.1
  local fx_args=("--model" "flux" "--prompt" "$prompt" "--output" "$output_dir/flux.png")
  if [ -n "$brand" ]; then fx_args+=("--brand" "$brand"); fi
  if [ -n "$aspect_ratio" ]; then fx_args+=("--aspect-ratio" "$aspect_ratio"); fi
  if [ -n "$quality" ]; then fx_args+=("--quality" "$quality"); fi

  info "[3/4] Flux Pro v1.1 (fal.ai)..."
  if cmd_generate "${fx_args[@]}"; then
    succeeded=$((succeeded + 1))
  else
    warn "Flux Pro generation failed"
    failed=$((failed + 1))
  fi

  # Model 4: Flux 2 Pro
  local fx2_args=("--model" "flux2" "--prompt" "$prompt" "--output" "$output_dir/flux2.png")
  if [ -n "$brand" ]; then fx2_args+=("--brand" "$brand"); fi
  if [ -n "$aspect_ratio" ]; then fx2_args+=("--aspect-ratio" "$aspect_ratio"); fi
  if [ -n "$quality" ]; then fx2_args+=("--quality" "$quality"); fi

  info "[4/4] Flux 2 Pro (fal.ai)..."
  if cmd_generate "${fx2_args[@]}"; then
    succeeded=$((succeeded + 1))
  else
    warn "Flux 2 Pro generation failed"
    failed=$((failed + 1))
  fi

  info "Compare done: $succeeded succeeded, $failed failed"
  info "Results in: $output_dir"
  echo "$output_dir"
}

# ---------------------------------------------------------------------------
# Command: models
# ---------------------------------------------------------------------------

cmd_models() {
  echo "ad-image-gen.sh v${VERSION} — Available Models"
  echo "================================================"
  echo ""

  # NanoBanana
  local nb_status="NO KEY"
  if [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
    nb_status="READY"
  fi
  local nb_script_status="MISSING"
  if [ -f "$NANOBANANA_SCRIPT" ]; then
    nb_script_status="OK"
  fi
  printf "  %-14s  %-8s  script=%-7s  %s\n" "nanobanana" "$nb_status" "$nb_script_status" "Gemini — fastest, cheapest, style seeds + ref images"

  # Recraft
  local rc_status="NO KEY"
  if [ -n "${RECRAFT_API_KEY:-}" ]; then
    rc_status="READY"
  fi
  printf "  %-14s  %-8s  %-15s  %s\n" "recraft" "$rc_status" "" "Recraft V4 — best text rendering, marketing visuals"

  # Recraft Pro
  printf "  %-14s  %-8s  %-15s  %s\n" "recraft-pro" "$rc_status" "" "Recraft V4 2048x2048 — highest quality marketing"

  # Flux
  local fx_status="NO KEY"
  if [ -n "${FAL_KEY:-}" ] || [ -n "${FAL_API_KEY:-}" ]; then
    fx_status="READY"
  fi
  printf "  %-14s  %-8s  %-15s  %s\n" "flux" "$fx_status" "" "Flux Pro v1.1 (fal.ai) — photorealistic, prompt adherent"
  printf "  %-14s  %-8s  %-15s  %s\n" "flux2" "$fx_status" "" "Flux 2 Pro (fal.ai) — better text, HEX colors, 10 refs, \$0.03/img"

  echo ""
  echo "Usage: ad-image-gen.sh generate --model <name> --prompt \"...\" [--output path.png]"
  echo ""
  echo "Common flags:"
  echo "  --brand <slug>        Load brand DNA (${BRANDS_DIR}/)"
  echo "  --aspect-ratio 1:1    1:1, 4:5, 5:4, 9:16, 16:9"
  echo "  --quality high        Recraft: 2048px, Flux: pro"
  echo "  --style <style>       Recraft: realistic, digital_illustration, vector_illustration"
  echo "  --style-seed <id>     NanoBanana only: lock visual style"
  echo "  --ref-image <path>    NanoBanana only: reference image"
  echo ""
  echo "Commands: generate, batch, compare, models"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  echo "ad-image-gen.sh v${VERSION} — Unified Ad Image Generation CLI"
  echo ""
  echo "Commands:"
  echo "  generate   Generate a single image"
  echo "  batch      Generate images from a JSON prompt file"
  echo "  compare    Generate same prompt across all models"
  echo "  models     List available models and API key status"
  echo ""
  echo "Examples:"
  echo "  ad-image-gen.sh generate --model recraft --prompt \"...\" --output out.png"
  echo "  ad-image-gen.sh generate --model nanobanana --prompt \"...\" --brand mirra"
  echo "  ad-image-gen.sh batch --model flux --prompt-file prompts.json --output-dir ./out/"
  echo "  ad-image-gen.sh compare --prompt \"...\" --output-dir ./compare/"
  echo "  ad-image-gen.sh models"
}

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------

if [ $# -eq 0 ]; then
  usage
  exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
  generate)  cmd_generate "$@" ;;
  batch)     cmd_batch "$@" ;;
  compare)   cmd_compare "$@" ;;
  models)    cmd_models "$@" ;;
  --help|-h|help) usage ;;
  --version|-v)   echo "ad-image-gen.sh v${VERSION}" ;;
  *)         die "Unknown command: $COMMAND. Run with --help for usage." ;;
esac
