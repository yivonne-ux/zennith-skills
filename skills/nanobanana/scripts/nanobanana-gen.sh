#!/usr/bin/env bash
# nanobanana-gen.sh — NanoBanana Image Generation CLI for GAIA CORP-OS
# Uses Google Gemini Image API (gemini-2.5-flash-image / gemini-3-pro-image-preview)
# macOS-compatible: Bash 3.2, no declare -A, no ${var,,}, no GNU timeout
# ---

set -euo pipefail

# Load API keys from secrets if not already in env
[ -z "${GEMINI_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/gemini.env" ] && \
  export "$(grep '^GEMINI_API_KEY=' "$HOME/.openclaw/secrets/gemini.env" | head -1)"

# ---------------------------------------------------------------------------
# Constants & Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
DATA_DIR="$HOME/.openclaw/workspace/data"
IMAGES_DIR="$DATA_DIR/images"
CHARACTERS_DIR="$DATA_DIR/characters"
STORYBOARDS_DIR="$DATA_DIR/storyboards"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
LOG_FILE="$HOME/.openclaw/logs/nanobanana.log"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"

API_BASE="https://generativelanguage.googleapis.com/v1beta/models"
MODEL_FLASH="gemini-3.1-flash-image-preview"  # NanoBanana 2 (launched 2026-02-26)
MODEL_PRO="gemini-3-pro-image-preview"        # NanoBanana Pro

# Rate limiting: slot-based concurrency control (parallel-safe)
RATE_FILE="/tmp/nanobanana-lastcall"
RATE_LOCK="/tmp/nanobanana-rate.lock"
RATE_LIMIT_SECONDS=6    # Relaxed further: 10 RPM = 6s between calls per slot
MAX_PARALLEL="${NANO_MAX_PARALLEL:-15}"  # Default 15, proven at 100% success. Override via env: NANO_MAX_PARALLEL=24

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

log() {
  local level="$1"
  shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$ts] [$level] $*" >> "$LOG_FILE"
}

# Lowercase a string (bash 3.2 compatible — no ${var,,})
to_lower() {
  echo "$1" | tr 'A-Z' 'a-z'
}

# Generate timestamp string for filenames
timestamp_str() {
  date '+%Y%m%d_%H%M%S'
}

# Epoch seconds
epoch_s() {
  date +%s
}

# Wait for rate limit (parallel-safe using flock)
rate_limit_wait() {
  # Use flock to atomically check-and-update last call time
  (
    flock -x 200 2>/dev/null || true  # flock may not exist on all systems
    if [ -f "$RATE_FILE" ]; then
      local last_call
      last_call=$(cat "$RATE_FILE" 2>/dev/null || echo "0")
      local now
      now=$(epoch_s)
      local diff=$((now - last_call))
      if [ "$diff" -lt "$RATE_LIMIT_SECONDS" ]; then
        local wait_time=$((RATE_LIMIT_SECONDS - diff))
        echo "Rate limit: waiting ${wait_time}s..." >&2
        sleep "$wait_time"
      fi
    fi
    epoch_s > "$RATE_FILE"
  ) 200>"$RATE_LOCK"
}

# Wait for parallel slot (max MAX_PARALLEL concurrent)
parallel_slot_wait() {
  local slot_dir="/tmp/nanobanana-slots"
  mkdir -p "$slot_dir"
  while true; do
    local count
    count=$(find "$slot_dir" -name "slot-*" -newer "$slot_dir" -o -name "slot-*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -lt "$MAX_PARALLEL" ]; then
      touch "$slot_dir/slot-$$"
      break
    fi
    # Clean stale slots (older than 5 min)
    find "$slot_dir" -name "slot-*" -mmin +5 -delete 2>/dev/null || true
    sleep 2
  done
}

# Release parallel slot
parallel_slot_release() {
  rm -f "/tmp/nanobanana-slots/slot-$$" 2>/dev/null || true
}

# Post to room (single-line JSONL)
post_to_room() {
  local room="$1"
  local msg="$2"
  local room_file="$ROOMS_DIR/${room}.jsonl"
  if [ -d "$ROOMS_DIR" ]; then
    printf '{"ts":%s000,"agent":"nanobanana","room":"%s","msg":"%s"}\n' \
      "$(epoch_s)" "$room" "$msg" >> "$room_file"
  fi
}

# Register with seed store if available
register_seed() {
  local image_path="$1"
  local brand="$2"
  local use_case="$3"
  if [ -x "$SEED_STORE" ]; then
    "$SEED_STORE" add \
      --type image \
      --text "$image_path" \
      --tags "${brand},${use_case},nanobanana" \
      --source nanobanana \
      --source-type nanobanana \
      --status draft 2>/dev/null || warn "Failed to register seed for $image_path"
  fi
}

# Register with image seed bank (richer metadata for creative pipeline)
IMAGE_SEED_SH="$HOME/.openclaw/skills/image-seed-bank/scripts/image-seed.sh"

register_image_seed() {
  local image_path="$1"
  local brand="$2"
  local use_case="$3"
  local campaign_arg="${4:-}"
  local funnel_arg="${5:-}"
  local style_seed_arg="${6:-}"
  local prompt_arg="${7:-}"

  if [ ! -f "$IMAGE_SEED_SH" ]; then
    return 0
  fi

  # Build tags: brand, use_case, nanobanana, plus funnel if set
  local tags="${brand},${use_case},nanobanana,generated"
  if [ -n "$funnel_arg" ]; then
    tags="${tags},$(echo "$funnel_arg" | tr 'A-Z' 'a-z')"
  fi
  if [ -n "$style_seed_arg" ]; then
    tags="${tags},styled"
  fi

  # campaign defaults to "general" if not set (image-seed.sh requires it)
  local camp="${campaign_arg:-general}"

  bash "$IMAGE_SEED_SH" add \
    --type "$use_case" \
    --brand "$brand" \
    --campaign "$camp" \
    --file-path "$image_path" \
    --tags "$tags" \
    --prompt "${prompt_arg:-}" \
    --created-by "nanobanana" \
    --status draft 2>/dev/null || warn "Failed to register image seed for $image_path"
}

# Auto QA hook — run visual audit if brand DNA exists
auto_qa_hook() {
  local image_path="$1"
  local brand="$2"
  local ref_image="${3:-}"

  local dna_path="$HOME/.openclaw/brands/${brand}/DNA.json"
  local audit_script="$HOME/.openclaw/skills/brand-studio/scripts/visual-audit.py"

  if [ ! -f "$audit_script" ] || [ ! -f "$dna_path" ]; then
    return 0
  fi

  local audit_out="/tmp/nb-qa-$(basename "$image_path" .png).json"

  # Run in background — don't block generation
  (
    if [ -n "$ref_image" ] && [ -f "$ref_image" ]; then
      python3 "$audit_script" "$image_path" "$dna_path" "$audit_out" "$ref_image" 2>/dev/null
    else
      python3 "$audit_script" "$image_path" "$dna_path" "$audit_out" 2>/dev/null
    fi

    # If audit result exists, check scores and post to room if FAIL
    if [ -f "$audit_out" ]; then
      local score defects
      score=$(python3 -c "import json; d=json.load(open('$audit_out')); print(d.get('overall', d.get('overall_score', 0)))" 2>/dev/null || echo "0")
      defects=$(python3 -c "
import json
d=json.load(open('$audit_out'))
s=d.get('scores',{})
issues=[]
if s.get('photorealism',10) < 5: issues.append('NOT-PHOTOREALISTIC')
if s.get('face_quality',10) < 5: issues.append('FACE-DEFECT')
if s.get('hand_quality',10) < 5: issues.append('HAND-DEFECT')
if s.get('artifacts',10) < 5: issues.append('ARTIFACTS')
print(','.join(issues) if issues else 'none')
" 2>/dev/null || echo "unknown")
      if python3 -c "exit(0 if float('$score') < 7.0 else 1)" 2>/dev/null || [ "$defects" != "none" ]; then
        local msg="QA FAIL ($score/10): $(basename "$image_path")"
        if [ "$defects" != "none" ]; then
          msg="$msg [DEFECTS: $defects]"
        fi
        msg="$msg — check $audit_out"
        printf '{"ts":%s000,"agent":"qa-hook","room":"creative","msg":"%s"}\n' \
          "$(date +%s)" "$(echo "$msg" | sed 's/"/\\"/g')" \
          >> "$HOME/.openclaw/workspace/rooms/creative.jsonl"
      fi
    fi
  ) &
}

# ---------------------------------------------------------------------------
# Brand Profile Loading
# ---------------------------------------------------------------------------

# Default brand values (GAIA Eats)
BRAND_NAME="GAIA Eats"
BRAND_COLOR_PRIMARY="#8FBC8F"
BRAND_COLOR_SECONDARY="#DAA520"
BRAND_COLOR_BG="#FFFDD0"
BRAND_STYLE="warm, natural, appetizing, accessible"
BRAND_LIGHTING="warm natural light, soft shadows"
BRAND_PHOTO_STYLE="magazine editorial, lifestyle"

load_brand_profile() {
  local brand_slug="$1"
  local profile_path="$BRANDS_DIR/${brand_slug}/DNA.json"

  if [ -f "$profile_path" ]; then
    log "INFO" "Loading brand profile: $profile_path"
    # Parse brand DNA.json (v4 format: nested visual.colors, voice, etc.)
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
print(\"BRAND_NAME='%s'\" % sh_escape(b.get('display_name', b.get('brand', 'GAIA Eats'))))
print(\"BRAND_COLOR_PRIMARY='%s'\" % sh_escape(colors.get('primary', '#8FBC8F')))
print(\"BRAND_COLOR_SECONDARY='%s'\" % sh_escape(colors.get('secondary', '#DAA520')))
print(\"BRAND_COLOR_BG='%s'\" % sh_escape(colors.get('background', '#FFFDD0')))
print(\"BRAND_STYLE='%s'\" % sh_escape(visual.get('style', 'warm, natural, appetizing, accessible')))
print(\"BRAND_LIGHTING='%s'\" % sh_escape(visual.get('lighting_default', 'warm natural light, soft shadows')))
print(\"BRAND_PHOTO_STYLE='%s'\" % sh_escape(visual.get('photography', 'magazine editorial, lifestyle')))
" "$profile_path" 2>/dev/null)" || warn "Could not parse brand profile: $profile_path"
  else
    log "INFO" "No brand profile at $profile_path, using defaults (GAIA Eats)"
  fi
}

# Build brand enrichment string to append to prompts
# Skip enrichment for character use-case (no food/brand watermarks on characters)
# Caller must set _CURRENT_USE_CASE before calling
_CURRENT_USE_CASE=""
brand_enrichment() {
  if [ "$_CURRENT_USE_CASE" = "character" ]; then
    echo ""
    return 0
  fi
  echo "Brand: ${BRAND_NAME}. Colors: primary ${BRAND_COLOR_PRIMARY}, secondary ${BRAND_COLOR_SECONDARY}, background ${BRAND_COLOR_BG}. Style: ${BRAND_STYLE}. Lighting: ${BRAND_LIGHTING}. Photography: ${BRAND_PHOTO_STYLE}."
}

# ---------------------------------------------------------------------------
# Campaign + Funnel Override Loading
# ---------------------------------------------------------------------------

# Campaign override variables (populated by load_campaign_overrides)
CAMPAIGN_NAME=""
CAMPAIGN_MOOD=""
CAMPAIGN_LIGHTING=""
CAMPAIGN_COLORS=""
CAMPAIGN_TONE=""
CAMPAIGN_CTA=""
CAMPAIGN_CREATIVE_MODE=""
FUNNEL_SUFFIX=""

load_campaign_overrides() {
  local brand_slug="$1"
  local campaign_slug="$2"
  local funnel_stage="$3"

  local campaign_path="$BRANDS_DIR/${brand_slug}/campaigns/${campaign_slug}.json"

  if [ ! -f "$campaign_path" ]; then
    log "WARN" "Campaign file not found: $campaign_path"
    return 1
  fi

  log "INFO" "Loading campaign: $campaign_path (funnel: ${funnel_stage:-none})"

  # Parse campaign JSON and extract funnel overrides via python3
  local stage_upper=""
  if [ -n "$funnel_stage" ]; then
    stage_upper=$(echo "$funnel_stage" | tr 'a-z' 'A-Z')
  fi

  eval "$(python3 -c "
import json, sys

campaign_path = sys.argv[1]
funnel_stage = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ''

with open(campaign_path, 'r') as f:
    c = json.loads(f.read())

def sh_escape(s):
    if s is None:
        return ''
    return str(s).replace(\"'\", \"'\\\"'\\\"'\")

print(\"CAMPAIGN_NAME='%s'\" % sh_escape(c.get('name', c.get('campaign_slug', ''))))

if funnel_stage and 'funnel_overrides' in c:
    ov = c['funnel_overrides'].get(funnel_stage, {})
    vis = ov.get('visual_override', {})
    voice = ov.get('voice_override', {})

    colors = vis.get('colors', [])
    print(\"CAMPAIGN_COLORS='%s'\" % sh_escape(', '.join(colors) if colors else ''))
    print(\"CAMPAIGN_MOOD='%s'\" % sh_escape(vis.get('mood', '')))
    print(\"CAMPAIGN_LIGHTING='%s'\" % sh_escape(vis.get('lighting', '')))
    print(\"CAMPAIGN_TONE='%s'\" % sh_escape(voice.get('tone', '')))
    print(\"CAMPAIGN_CTA='%s'\" % sh_escape(voice.get('cta', '')))
    print(\"CAMPAIGN_CREATIVE_MODE='%s'\" % sh_escape(ov.get('creative_mode', '')))
else:
    print(\"CAMPAIGN_COLORS=''\")
    print(\"CAMPAIGN_MOOD=''\")
    print(\"CAMPAIGN_LIGHTING=''\")
    print(\"CAMPAIGN_TONE=''\")
    print(\"CAMPAIGN_CTA=''\")
    print(\"CAMPAIGN_CREATIVE_MODE=''\")

# Funnel-stage-specific prompt suffix
suffixes = {
    'TOFU': 'Style: aspirational, educational, broad appeal. The viewer should feel curious and inspired. No hard sell.',
    'MOFU': 'Style: detailed, trustworthy, benefit-focused. Show the product in use. Include social proof elements.',
    'BOFU': 'Style: urgent, direct, conversion-focused. Bold text overlays. Clear price/offer. Strong call to action.',
}
print(\"FUNNEL_SUFFIX='%s'\" % sh_escape(suffixes.get(funnel_stage, '')))
" "$campaign_path" "$stage_upper" 2>/dev/null)" || {
    warn "Could not parse campaign: $campaign_path"
    return 1
  }

  return 0
}

# Build campaign enrichment string to append to prompts
campaign_enrichment() {
  local parts=""
  if [ -n "$CAMPAIGN_NAME" ]; then
    parts="Campaign: ${CAMPAIGN_NAME}."
  fi
  if [ -n "$CAMPAIGN_MOOD" ]; then
    parts="${parts} Mood: ${CAMPAIGN_MOOD}."
  fi
  if [ -n "$CAMPAIGN_LIGHTING" ]; then
    parts="${parts} Lighting: ${CAMPAIGN_LIGHTING}."
  fi
  if [ -n "$CAMPAIGN_COLORS" ]; then
    parts="${parts} Campaign colors: ${CAMPAIGN_COLORS}."
  fi
  if [ -n "$CAMPAIGN_TONE" ]; then
    parts="${parts} Tone: ${CAMPAIGN_TONE}."
  fi
  if [ -n "$CAMPAIGN_CTA" ]; then
    parts="${parts} CTA: ${CAMPAIGN_CTA}."
  fi
  if [ -n "$FUNNEL_SUFFIX" ]; then
    parts="${parts} ${FUNNEL_SUFFIX}"
  fi
  echo "$parts"
}

# ---------------------------------------------------------------------------
# Use Case Prompt Templates
# ---------------------------------------------------------------------------

get_usecase_template() {
  local uc="$1"
  local product="${2:-product}"

  case "$uc" in
    product)
      echo "Professional product photography of ${product} by ${BRAND_NAME}. Clean white/cream background, soft studio lighting from upper left. Product centered, slight 15-degree angle, subtle shadow beneath. Sharp focus on product, shallow depth of field. High-end e-commerce listing quality."
      ;;
    food)
      echo "Appetizing food photography of ${product}, plant-based/vegan. Styled on rustic wooden table with natural linen napkin. Warm natural light from window, soft shadows. Fresh herbs and ingredients scattered artfully around dish. Steam or moisture visible for freshness. Magazine editorial quality, makes viewer hungry."
      ;;
    lifestyle)
      echo "Professional lifestyle photography of ${BRAND_NAME} ${product}. Authentic, candid moment — natural pose, not artificial. Aspirational but relatable everyday scene in Malaysian home/cafe/office setting. Natural warm lighting, slightly warm color temperature (3200K-4000K). Character shown enjoying the product as part of daily routine. High-quality composition, editorial magazine style, Instagram-worthy aesthetic. Clean, fresh, inviting atmosphere. Product clearly visible but secondary to the lifestyle scene. Avoid: dark moody photography, harsh shadows, overexposed looks, artificial poses, frozen camera angles."
      ;;
    flatlay)
      echo "Overhead flat lay photography on marble/wood surface. Arranged: ${BRAND_NAME} ${product} center, surrounded by complementary ingredients and props. Geometric arrangement, pleasing negative space. Consistent lighting, no harsh shadows. Clean, organized, Pinterest-worthy composition."
      ;;
    social)
      echo "Instagram feed image for ${BRAND_NAME}. On-brand aesthetic: warm, natural, plant-based lifestyle. Eye-catching, thumb-stopping visual featuring ${product}. Brand colors present but not overwhelming. Vibrant, engaging composition."
      ;;
    packaging)
      echo "Product packaging mockup for ${BRAND_NAME} ${product}. Package on styled surface. Clean typography, modern minimalist design. Lifestyle context visible in background (kitchen/shelf). Professional packaging photography quality."
      ;;
    ecommerce)
      echo "E-commerce product listing image for ${BRAND_NAME} ${product}. Product on white background, centered, well-lit. Product fills 85% of frame. No text overlays, no props, clean isolation. Consistent lighting. Suitable for Shopee/Lazada/Amazon listing standards."
      ;;
    recipe)
      echo "Step-by-step recipe shot for ${product}. Overhead angle, hands visible performing action. Clean workspace, ingredients clearly visible and identifiable. Warm natural lighting from left. Clean, instructional, easy to follow visually."
      ;;
    character)
      echo "Photorealistic photograph of a real person for ${BRAND_NAME}. Real human skin with visible pores, natural lighting, iPhone-quality candid aesthetic. NOT illustration, NOT cartoon, NOT anime, NOT CG render, NOT character sheet, NOT stickers. Single photograph only, no collage, no text overlays, no graphics."
      ;;
    pod)
      echo "Print-on-demand mockup featuring ${BRAND_NAME} ${product} design. Product shown in lifestyle context. Clean, professional e-commerce mockup style. Design clearly visible, colors accurate."
      ;;
    education)
      echo "Educational infographic-style image about ${product}. Clean layout, easy to read at mobile size. Numbered steps or sections clearly defined. Illustrations: simple, modern, friendly style. Text areas with clear contrast for readability."
      ;;
    beforeafter)
      echo "Split image comparison. LEFT: plain, boring meal. RIGHT: vibrant ${BRAND_NAME} ${product} meal, colorful, appetizing. Same angle, same lighting, same table setting. Clear visual contrast between boring and exciting."
      ;;
    *)
      echo "Professional photography of ${BRAND_NAME} ${product}. High quality, brand-consistent, warm natural lighting."
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Gemini API Call
# ---------------------------------------------------------------------------

call_gemini_api() {
  local model="$1"
  local prompt="$2"
  local aspect_ratio="$3"
  local image_size="$4"
  local output_path="$5"
  local dry_run="${6:-false}"
  local ref_images="${7:-}"  # comma-separated list of image paths for multi-image reference

  # Validate API key
  if [ -z "${GEMINI_API_KEY:-}" ]; then
    die "GEMINI_API_KEY environment variable is not set. Export it before running."
  fi

  # Resolve model ID
  local model_id="$MODEL_FLASH"
  local model_lc
  model_lc=$(to_lower "$model")
  case "$model_lc" in
    pro|quality) model_id="$MODEL_PRO" ;;
    flash|fast)  model_id="$MODEL_FLASH" ;;
    *)           model_id="$model" ;;  # allow passing full model ID
  esac

  local endpoint="${API_BASE}/${model_id}:generateContent"

  # Escape prompt for JSON
  local escaped_prompt
  escaped_prompt=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$prompt")

  # Build request body (with optional reference images)
  local body
  body=$(python3 -c "
import json, sys, base64, os

prompt = sys.argv[1]
ratio = sys.argv[2]
size = sys.argv[3]
ref_images_str = sys.argv[4] if len(sys.argv) > 4 else ''

parts = []

# Add reference images first (if any) — auto-resize if >1MB
if ref_images_str:
    import subprocess, tempfile
    for img_path in ref_images_str.split(','):
        img_path = img_path.strip()
        if not img_path or not os.path.isfile(img_path):
            continue
        file_size = os.path.getsize(img_path)
        if file_size > 4_000_000:
            tmp = tempfile.NamedTemporaryFile(suffix='.jpg', delete=False)
            tmp.close()
            subprocess.run(['sips', '-Z', '2048', img_path, '--out', tmp.name,
                            '-s', 'format', 'jpeg', '-s', 'formatOptions', '92'],
                           capture_output=True)
            img_path = tmp.name
            mime = 'image/jpeg'
        else:
            ext = img_path.rsplit('.', 1)[-1].lower()
            mime_map = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp'}
            mime = mime_map.get(ext, 'image/jpeg')
        with open(img_path, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode()
        parts.append({'inlineData': {'mimeType': mime, 'data': b64}})

# Add text prompt last
parts.append({'text': prompt})

payload = {
    'contents': [
        {
            'parts': parts
        }
    ],
    'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'imageConfig': {
            'imageSize': size,
            'aspectRatio': ratio
        }
    }
}

print(json.dumps(payload))
" "$prompt" "$aspect_ratio" "$image_size" "$ref_images")

  # Write body to temp file to avoid ARG_MAX (262144 bytes) on macOS
  # when base64-encoded reference images make the JSON too large for inline -d
  local body_file
  body_file=$(mktemp /tmp/nanobanana-body.XXXXXX)
  printf '%s' "$body" > "$body_file"

  if [ "$dry_run" = "true" ]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Model:   $model_id"
    echo "Size:    $image_size"
    echo "Ratio:   $aspect_ratio"
    echo "Output:  $output_path"
    echo "Prompt:"
    echo "  $prompt"
    echo ""
    echo "Request body:"
    python3 -m json.tool "$body_file" 2>/dev/null || cat "$body_file"
    echo "==============="
    rm -f "$body_file"
    return 0
  fi

  log "INFO" "Calling Gemini API: model=$model_id size=$image_size ratio=$aspect_ratio"
  log "INFO" "Prompt: $prompt"

  # Wait for parallel slot + rate limit
  parallel_slot_wait
  rate_limit_wait

  # Retry loop: up to 3 attempts with exponential backoff for 429/500
  local response_file
  response_file=$(mktemp /tmp/nanobanana-resp.XXXXXX)
  local http_code_file
  http_code_file=$(mktemp /tmp/nanobanana-http.XXXXXX)
  local max_retries=3
  local attempt=1
  local http_code=""

  while [ "$attempt" -le "$max_retries" ]; do
    if [ "$attempt" -gt 1 ]; then
      local backoff=$((attempt * 5))
      echo "Retry $attempt/$max_retries: waiting ${backoff}s..." >&2
      log "WARN" "Retry $attempt after HTTP $http_code, backoff ${backoff}s"
      sleep "$backoff"
    fi

    # Run curl in background for timeout handling
    # Use -d @file instead of -d "$body" to avoid ARG_MAX limit
    curl -s -w '%{http_code}' \
      -X POST "$endpoint" \
      -H "Content-Type: application/json" \
      -H "x-goog-api-key: ${GEMINI_API_KEY}" \
      -d "@${body_file}" \
      -o "$response_file" \
      > "$http_code_file" 2>/dev/null &

    local curl_pid=$!

    # Wait up to 180 seconds (macOS-safe timeout)
    local waited=0
    while kill -0 "$curl_pid" 2>/dev/null; do
      if [ "$waited" -ge 180 ]; then
        kill "$curl_pid" 2>/dev/null || true
        if [ "$attempt" -lt "$max_retries" ]; then
          attempt=$((attempt + 1))
          continue 2  # retry
        fi
        rm -f "$response_file" "$http_code_file" "$body_file"
        parallel_slot_release
        die "API call timed out after 180 seconds (all retries exhausted)"
      fi
      sleep 1
      waited=$((waited + 1))
    done

    wait "$curl_pid" 2>/dev/null
    local exit_code=$?

    http_code=$(cat "$http_code_file" 2>/dev/null | tr -d '[:space:]')

    if [ "$exit_code" -ne 0 ]; then
      if [ "$attempt" -lt "$max_retries" ]; then
        attempt=$((attempt + 1))
        continue
      fi
      local err_body
      err_body=$(cat "$response_file" 2>/dev/null || echo "no response")
      rm -f "$response_file" "$http_code_file" "$body_file"
      parallel_slot_release
      die "curl failed (exit=$exit_code). Response: $err_body"
    fi

    if [ "$http_code" = "200" ]; then
      break  # success
    fi

    # Retry on 429 (rate limit) or 500 (server error)
    if [ "$http_code" = "429" ] || [ "$http_code" = "500" ] || [ "$http_code" = "503" ]; then
      if [ "$attempt" -lt "$max_retries" ]; then
        attempt=$((attempt + 1))
        continue
      fi
    fi

    # Non-retryable error
    local err_body
    err_body=$(cat "$response_file" 2>/dev/null || echo "no response")
    rm -f "$response_file" "$http_code_file" "$body_file"
    parallel_slot_release
    log "ERROR" "API returned HTTP $http_code: $err_body"
    die "API returned HTTP $http_code. Check $LOG_FILE for details. Response: $(echo "$err_body" | head -c 500)"
  done

  rm -f "$http_code_file"
  parallel_slot_release

  # Extract base64 image data and save as PNG — with content-level retry
  mkdir -p "$(dirname "$output_path")"

  local content_attempt=1
  local max_content_retries=2

  while [ "$content_attempt" -le "$max_content_retries" ]; do

  local extract_result
  extract_result=$(python3 -c "
import json, sys, base64, os

response_file = sys.argv[1]
output_path = sys.argv[2]

with open(response_file, 'r') as f:
    data = json.loads(f.read())

# Navigate Gemini response structure
candidates = data.get('candidates', [])
if not candidates:
    print('ERROR:No candidates in response')
    sys.exit(0)

parts = candidates[0].get('content', {}).get('parts', [])
if not parts:
    print('ERROR:No parts in response')
    sys.exit(0)

# Find image part (inline_data with mime_type image/*)
image_saved = False
text_response = ''
for part in parts:
    if 'inlineData' in part:
        inline = part['inlineData']
        b64_data = inline.get('data', '')
        if b64_data:
            img_bytes = base64.b64decode(b64_data)
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, 'wb') as img_f:
                img_f.write(img_bytes)
            image_saved = True
    elif 'inline_data' in part:
        inline = part['inline_data']
        b64_data = inline.get('data', '')
        if b64_data:
            img_bytes = base64.b64decode(b64_data)
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, 'wb') as img_f:
                img_f.write(img_bytes)
            image_saved = True
    elif 'text' in part:
        text_response = part['text']

if image_saved:
    size = os.path.getsize(output_path)
    print('OK:%d' % size)
else:
    # Maybe wrapped in different structure
    print('ERROR:No image data found in response. Text: %s' % text_response[:200])
" "$response_file" "$output_path" 2>&1)

  case "$extract_result" in
    OK:*)
      rm -f "$response_file" "$body_file"
      local file_size
      file_size=$(echo "$extract_result" | sed 's/OK://')
      log "INFO" "Image saved: $output_path ($file_size bytes)"
      # Auto-compress generated image (keep original, create _web.jpg variant)
      if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
        local _img_tool="convert"
        command -v magick >/dev/null 2>&1 && _img_tool="magick"
        local OPTIMIZED="${output_path%.*}_web.jpg"
        "$_img_tool" "$output_path" -resize "1024x1024>" -quality 80 -strip "$OPTIMIZED" 2>/dev/null || true
        if [ -f "$OPTIMIZED" ]; then
          log "INFO" "Compressed: $(du -h "$output_path" | cut -f1) -> $(du -h "$OPTIMIZED" | cut -f1)"
        fi
      fi
      echo "$output_path"
      return 0
      ;;
    ERROR:*)
      local err_msg
      err_msg=$(echo "$extract_result" | sed 's/ERROR://')
      log "WARN" "Content refusal (attempt $content_attempt/$max_content_retries): $err_msg"

      if [ "$content_attempt" -lt "$max_content_retries" ]; then
        echo "Content refusal, retrying with softened prompt..." >&2
        content_attempt=$((content_attempt + 1))
        sleep 3

        # Soften the prompt: prepend safety prefix, remove potential trigger words
        local softened_prompt="Generate a clean, professional food photography image. $prompt"
        local softened_body
        softened_body=$(python3 -c "
import json, sys, base64, os

prompt = sys.argv[1]
ratio = sys.argv[2]
size = sys.argv[3]
ref_images_str = sys.argv[4] if len(sys.argv) > 4 else ''

parts = []
if ref_images_str:
    import subprocess, tempfile
    for img_path in ref_images_str.split(','):
        img_path = img_path.strip()
        if not img_path or not os.path.isfile(img_path):
            continue
        file_size = os.path.getsize(img_path)
        if file_size > 4_000_000:
            tmp = tempfile.NamedTemporaryFile(suffix='.jpg', delete=False)
            tmp.close()
            subprocess.run(['sips', '-Z', '2048', img_path, '--out', tmp.name,
                            '-s', 'format', 'jpeg', '-s', 'formatOptions', '92'],
                           capture_output=True)
            img_path = tmp.name
            mime = 'image/jpeg'
        else:
            ext = img_path.rsplit('.', 1)[-1].lower()
            mime_map = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'webp': 'image/webp'}
            mime = mime_map.get(ext, 'image/jpeg')
        with open(img_path, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode()
        parts.append({'inlineData': {'mimeType': mime, 'data': b64}})

parts.append({'text': prompt})
payload = {
    'contents': [{'parts': parts}],
    'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        'imageConfig': {'imageSize': size, 'aspectRatio': ratio}
    }
}
print(json.dumps(payload))
" "$softened_prompt" "$aspect_ratio" "$image_size" "$ref_images")

        printf '%s' "$softened_body" > "$body_file"

        # Re-call API with softened prompt
        parallel_slot_wait
        rate_limit_wait
        local retry_resp
        retry_resp=$(mktemp /tmp/nanobanana-resp.XXXXXX)
        curl -s -X POST "$endpoint" \
          -H "Content-Type: application/json" \
          -H "x-goog-api-key: ${GEMINI_API_KEY}" \
          -d "@${body_file}" \
          -o "$retry_resp" 2>/dev/null
        parallel_slot_release
        rm -f "$response_file"
        response_file="$retry_resp"
        continue  # re-extract from new response
      fi

      rm -f "$response_file" "$body_file"
      die "Failed to extract image: $err_msg"
      ;;
    *)
      rm -f "$response_file" "$body_file"
      die "Unexpected extraction result: $extract_result"
      ;;
  esac

  done  # end content retry loop

  rm -f "$response_file" "$body_file"
  die "Content retry loop exhausted without success"
}

# ---------------------------------------------------------------------------
# Command: generate
# ---------------------------------------------------------------------------

cmd_generate() {
  local brand="" use_case="product" prompt="" size="2K" ratio="1:1" model="flash" dry_run="false" raw="false" style_seed=""
  local campaign="" funnel_stage="" ref_image="" character="" setting="" auto_ref="false"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)         brand="$2";         shift 2 ;;
      --use-case)      use_case="$2";      shift 2 ;;
      --prompt)        prompt="$2";        shift 2 ;;
      --size)          size="$2";          shift 2 ;;
      --ratio)         ratio="$2";         shift 2 ;;
      --model)         model="$2";         shift 2 ;;
      --style-seed)    style_seed="$2";    shift 2 ;;
      --campaign)      campaign="$2";      shift 2 ;;
      --funnel-stage)  funnel_stage="$2";  shift 2 ;;
      --ref-image)     ref_image="$2";     shift 2 ;;
      --auto-ref)      auto_ref="true";    shift ;;
      --character)     character="$2";     shift 2 ;;
      --setting)       setting="$2";       shift 2 ;;
      --dry-run)       dry_run="true";     shift ;;
      --raw)           raw="true";         shift ;;
      *) die "generate: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "generate: --brand is required"

  # Auto-ref: if no --ref-image provided and --auto-ref is set (or always for ad use cases),
  # use ref-picker to auto-select the best reference images
  local REF_PICKER="$HOME/.openclaw/skills/ref-picker/scripts/ref-picker.sh"
  if [ -z "$ref_image" ] && [ -x "$REF_PICKER" ]; then
    if [ "$auto_ref" = "true" ] || echo "$use_case" | grep -qiE "comparison|beforeafter|lifestyle|product|hero|recipe|social"; then
      local pick_result
      local pick_args="--brand $brand --use-case $use_case --count 3"
      if [ -n "$prompt" ]; then
        pick_result=$(bash "$REF_PICKER" pick --brand "$brand" --use-case "$use_case" --prompt "$prompt" --count 3 2>/dev/null || true)
      else
        pick_result=$(bash "$REF_PICKER" pick --brand "$brand" --use-case "$use_case" --count 3 2>/dev/null || true)
      fi
      local auto_refs
      auto_refs=$(echo "$pick_result" | grep "^REFS:" | sed 's/^REFS://' || true)
      if [ -n "$auto_refs" ]; then
        ref_image="$auto_refs"
        log "INFO" "Auto-ref picked: $auto_refs"
        echo "  Auto-ref: $(echo "$auto_refs" | tr ',' '\n' | wc -l | tr -d ' ') reference images selected"
      fi
    fi
  fi
  
  # Prompt is optional if use-case is provided
  if [ -z "$prompt" ]; then
    if [ -z "$use_case" ]; then
      die "generate: --prompt is required"
    fi
    # Generate a generic prompt from the use case description
    prompt="Showcase ${BRAND_NAME} ${use_case}"
    log "INFO" "No --prompt provided. Using generic prompt: ${prompt}"
  fi

  # Validate size
  local size_upper
  size_upper=$(echo "$size" | tr 'a-z' 'A-Z')
  case "$size_upper" in
    1K|2K|4K) ;;
    *) die "generate: --size must be 1K, 2K, or 4K (got: $size)" ;;
  esac

  # Set global use-case for brand_enrichment() to check
  _CURRENT_USE_CASE="$use_case"

  # Load brand profile
  load_brand_profile "$brand"

  # Load style seed if provided
  local seed_style_prompt=""
  local seed_ref_images=""
  if [ -n "$style_seed" ]; then
    log "INFO" "Loading style seed: $style_seed"
    local seed_tmp
    seed_tmp=$(mktemp /tmp/nanobanana-seed.XXXXXX)
    python3 -c "
import json, sys
index_file = sys.argv[1]
target_id = sys.argv[2]
try:
    with open(index_file) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                entry = json.loads(line)
                if entry.get('type') == 'style_seed' and entry.get('id') == target_id:
                    print(entry.get('style_prompt', ''))
                    imgs = entry.get('source_images', [])
                    print(','.join(imgs) if imgs else '')
                    sys.exit(0)
            except: continue
except: pass
sys.exit(1)
" "$HOME/.openclaw/workspace/rag/image-seed-bank.jsonl" "$style_seed" > "$seed_tmp" 2>/dev/null || true
    if [ -s "$seed_tmp" ]; then
      seed_style_prompt=$(head -1 "$seed_tmp")
      seed_ref_images=$(tail -1 "$seed_tmp")
      log "INFO" "Style seed loaded: prompt=${seed_style_prompt:0:80}..."
      echo "  Style seed: $style_seed"
    else
      warn "Style seed not found: $style_seed"
    fi
    rm -f "$seed_tmp"
  fi

  # Load campaign overrides if --campaign provided
  if [ -n "$campaign" ]; then
    if load_campaign_overrides "$brand" "$campaign" "$funnel_stage"; then
      echo "  Campaign: $campaign ($CAMPAIGN_NAME)"
      if [ -n "$funnel_stage" ]; then
        echo "  Funnel:   $funnel_stage"
      fi
      # If campaign specifies creative_mode, apply it to override BRAND_LIGHTING
      if [ -n "$CAMPAIGN_LIGHTING" ]; then
        BRAND_LIGHTING="$CAMPAIGN_LIGHTING"
      fi
    fi
  fi

  # Enrich prompt with brand context and use case template (skip if --raw or prompt is detailed)
  local full_prompt
  if [ "$raw" = "true" ]; then
    full_prompt="$prompt"
  else
    # Avoid prompt duplication when using generic prompts from --use-case
    # User-provided detailed prompts should be passed as product argument
    local template_product_arg
    if [ "${#prompt}" -lt 50 ]; then
      template_product_arg=""  # Generic prompt - avoid duplication
    else
      template_product_arg="$prompt"  # User provided detailed prompt
    fi

    # Use case template adds structure (character in setting, etc.)
    local template
    template=$(get_usecase_template "$use_case" "$template_product_arg")

    # Replace [CHARACTER] and [SETTING] placeholders if provided
    if [ -n "$character" ]; then
      template="${template//\[CHARACTER\]/$character}"
    fi
    if [ -n "$setting" ]; then
      template="${template//\[SETTING\]/$setting}"
    fi

    local enrichment
    enrichment=$(brand_enrichment)
    full_prompt="${prompt}. ${template} ${enrichment}"
  fi

  # Append campaign enrichment if campaign loaded
  if [ -n "$campaign" ] && [ -n "$CAMPAIGN_NAME" ]; then
    local camp_enrich
    camp_enrich=$(campaign_enrichment)
    if [ -n "$camp_enrich" ]; then
      full_prompt="${full_prompt} ${camp_enrich}"
    fi
  fi

  # Prepend style seed prompt if available
  if [ -n "$seed_style_prompt" ]; then
    full_prompt="[Style: ${seed_style_prompt}] ${full_prompt}"
  fi

  # Output path
  local ts
  ts=$(timestamp_str)
  local output_dir="${IMAGES_DIR}/${brand}"
  mkdir -p "$output_dir"
  local output_path="${output_dir}/${ts}_${use_case}_$$.png"

  echo "Generating image..."
  echo "  Brand:    $brand ($BRAND_NAME)"
  echo "  Use case: $use_case"
  echo "  Model:    $model"
  echo "  Size:     $size_upper"
  echo "  Ratio:    $ratio"
  if [ -n "$campaign" ]; then
    echo "  Campaign: $campaign"
  fi
  if [ -n "$funnel_stage" ]; then
    echo "  Funnel:   $funnel_stage"
  fi

  # Reference images — Gemini 3.x image models DO support image input + image output
  # (up to 14 ref images). Sources: --ref-image flag and/or style seed source_images.
  local ref_images_arg=""
  if [ -n "$ref_image" ]; then
    ref_images_arg="$ref_image"
    echo "  Ref image: $ref_image"
  fi
  if [ -n "$seed_ref_images" ]; then
    if [ -n "$ref_images_arg" ]; then
      ref_images_arg="${ref_images_arg},${seed_ref_images}"
    else
      ref_images_arg="$seed_ref_images"
    fi
    log "INFO" "Style seed has $(echo "$seed_ref_images" | tr ',' '\n' | wc -l | tr -d ' ') ref images (sending to API)"
  fi
  if [ -n "$ref_images_arg" ]; then
    local ref_count
    ref_count=$(echo "$ref_images_arg" | tr ',' '\n' | wc -l | tr -d ' ')
    log "INFO" "Sending $ref_count reference image(s) to API"
  fi

  local result
  result=$(call_gemini_api "$model" "$full_prompt" "$ratio" "$size_upper" "$output_path" "$dry_run" "$ref_images_arg") || {
    log "ERROR" "call_gemini_api failed (exit $?) for brand=$brand use_case=$use_case"
    echo "ERROR: Image generation failed" >&2
    return 1
  }

  if [ "$dry_run" = "true" ]; then
    echo "$result"
    return 0
  fi

  if [ -n "$result" ] && [ -f "$result" ]; then
    echo "  Output:   $result"
    local log_suffix=""
    if [ -n "$style_seed" ]; then
      log_suffix=" style_seed=$style_seed"
    fi
    if [ -n "$campaign" ]; then
      log_suffix="${log_suffix} campaign=$campaign"
    fi
    if [ -n "$funnel_stage" ]; then
      log_suffix="${log_suffix} funnel=$funnel_stage"
    fi
    log "INFO" "Generated: $result (brand=$brand use_case=$use_case${log_suffix})"

    # Register with content seed store (legacy)
    register_seed "$result" "$brand" "$use_case"

    # Register with image seed bank (full metadata for creative pipeline)
    register_image_seed "$result" "$brand" "$use_case" "$campaign" "$funnel_stage" "$style_seed" "$prompt"

    # Auto QA — visual audit in background
    auto_qa_hook "$result" "$brand" "${ref_image:-}"

    # Post to creative room
    local escaped_path
    escaped_path=$(echo "$result" | sed 's/"/\\"/g')
    local room_msg="Image generated: ${use_case} for ${brand}. Path: ${escaped_path}"
    if [ -n "$style_seed" ]; then
      room_msg="${room_msg}. Style seed: ${style_seed}"
    fi
    if [ -n "$campaign" ]; then
      room_msg="${room_msg}. Campaign: ${campaign}"
    fi
    if [ -n "$funnel_stage" ]; then
      room_msg="${room_msg}. Funnel: ${funnel_stage}"
    fi
    post_to_room "creative" "$room_msg"

    echo "Done."
  else
    log "ERROR" "Generation produced no valid file: result='$result' output_path='$output_path'"
    echo "ERROR: Generation produced no valid image file" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Command: character-sheet
# ---------------------------------------------------------------------------

cmd_character_sheet() {
  local brand="" description="" poses_str="front,side,waving" model="pro" size="2K" ratio="1:1" dry_run="false"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)       brand="$2";       shift 2 ;;
      --description) description="$2"; shift 2 ;;
      --poses)       poses_str="$2";   shift 2 ;;
      --model)       model="$2";       shift 2 ;;
      --size)        size="$2";        shift 2 ;;
      --ratio)       ratio="$2";       shift 2 ;;
      --dry-run)     dry_run="true";   shift ;;
      *) die "character-sheet: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "character-sheet: --brand is required"
  [ -z "$description" ] && die "character-sheet: --description is required"

  # Load brand profile
  load_brand_profile "$brand"

  local enrichment
  enrichment=$(brand_enrichment)

  # Parse poses
  local IFS_SAVE="$IFS"
  IFS=','
  set -- $poses_str
  IFS="$IFS_SAVE"
  local poses_count=$#

  local ts
  ts=$(timestamp_str)
  local output_dir="${CHARACTERS_DIR}/${brand}"
  mkdir -p "$output_dir"

  echo "Generating character sheet..."
  echo "  Brand:       $brand ($BRAND_NAME)"
  echo "  Character:   $description"
  echo "  Poses:       $poses_str ($poses_count poses)"
  echo "  Model:       $model"
  echo ""

  local pose_index=0
  local generated_files=""
  local size_upper
  size_upper=$(echo "$size" | tr 'a-z' 'A-Z')

  # PHASE 1: Generate reference pose (first pose — sequential, locks the character)
  local first_pose=""
  local remaining_poses=""
  for pose in "$@"; do
    pose_index=$((pose_index + 1))
    local pose_clean
    pose_clean=$(echo "$pose" | tr -d '[:space:]')

    if [ "$pose_index" -eq 1 ]; then
      first_pose="$pose_clean"
      echo "  [1/$poses_count] Generating reference pose: $pose_clean (locking character)"

      local char_prompt="Character design sheet. ${description}. Pose: ${pose_clean}, full body visible. ${enrichment} White/clean background. Semi-realistic style, consistent proportions."
      local pose_output="${output_dir}/${ts}_char_${pose_clean}.png"

      local result
      result=$(call_gemini_api "$model" "$char_prompt" "$ratio" "$size_upper" "$pose_output" "$dry_run")

      if [ "$dry_run" = "true" ]; then
        echo "$result"
      elif [ -n "$result" ] && [ -f "$result" ]; then
        echo "    Saved: $result (REFERENCE LOCKED)"
        generated_files="$result"
        register_seed "$result" "$brand" "character"
        register_image_seed "$result" "$brand" "character" "" "" "" "$char_prompt"
      fi
    else
      if [ -n "$remaining_poses" ]; then
        remaining_poses="${remaining_poses},${pose_clean}"
      else
        remaining_poses="$pose_clean"
      fi
    fi
  done

  # PHASE 2: Generate remaining poses CONCURRENTLY (reference is locked)
  if [ -n "$remaining_poses" ] && [ "$dry_run" != "true" ]; then
    echo ""
    echo "  Reference locked. Generating remaining poses concurrently..."
    local bg_pids=""
    local bg_outputs=""
    local remaining_index=1

    local IFS_SAVE2="$IFS"
    IFS=','
    set -- $remaining_poses
    IFS="$IFS_SAVE2"
    local remaining_count=$#

    for pose_clean in "$@"; do
      remaining_index=$((remaining_index + 1))
      local pose_output="${output_dir}/${ts}_char_${pose_clean}.png"
      local char_prompt="Same character (${description}). Maintain facial features, preserve proportions, keep identity. Pose: ${pose_clean}, full body visible. ${enrichment} White/clean background. Semi-realistic style, consistent with reference."

      echo "  [$remaining_index/$poses_count] Launching: $pose_clean (background)"

      # Run in background, capture PID
      (
        local r
        r=$(call_gemini_api "$model" "$char_prompt" "$ratio" "$size_upper" "$pose_output" "false")
        if [ -n "$r" ] && [ -f "$r" ]; then
          printf '%s\n%s\n' "$r" "$char_prompt" > "/tmp/nb-char-$$-${pose_clean}.done"
        fi
      ) &
      bg_pids="$bg_pids $!"
      bg_outputs="$bg_outputs $pose_clean"
    done

    # Wait for all background jobs
    echo "  Waiting for $remaining_count concurrent generations..."
    for pid in $bg_pids; do
      wait "$pid" 2>/dev/null || true
    done

    # Collect results
    for pose_clean in $bg_outputs; do
      local done_file="/tmp/nb-char-$$-${pose_clean}.done"
      if [ -f "$done_file" ]; then
        local result
        result=$(head -1 "$done_file")
        local done_prompt
        done_prompt=$(tail -n +2 "$done_file" | head -1)
        rm -f "$done_file"
        echo "    Saved: $result"
        generated_files="${generated_files},${result}"
        register_seed "$result" "$brand" "character"
        register_image_seed "$result" "$brand" "character" "" "" "" "$done_prompt"
      else
        echo "    FAILED: $pose_clean"
      fi
    done
  elif [ "$dry_run" = "true" ] && [ -n "$remaining_poses" ]; then
    # Dry-run: still show prompts for remaining poses
    local IFS_SAVE2="$IFS"
    IFS=','
    set -- $remaining_poses
    IFS="$IFS_SAVE2"
    local remaining_index=1
    for pose_clean in "$@"; do
      remaining_index=$((remaining_index + 1))
      echo "  [$remaining_index/$poses_count] Generating pose: $pose_clean"
      local char_prompt="Same character (${description}). Maintain facial features, preserve proportions, keep identity. Pose: ${pose_clean}, full body visible. ${enrichment} White/clean background. Semi-realistic style, consistent with reference."
      local pose_output="${output_dir}/${ts}_char_${pose_clean}.png"
      local result
      result=$(call_gemini_api "$model" "$char_prompt" "$ratio" "$size_upper" "$pose_output" "$dry_run")
      echo "$result"
    done
  fi

  # Create character metadata JSON
  if [ "$dry_run" != "true" ]; then
    local meta_file="${output_dir}/${ts}_character.json"
    python3 -c "
import json, sys

meta = {
    'brand': sys.argv[1],
    'brand_name': sys.argv[2],
    'description': sys.argv[3],
    'poses': sys.argv[4].split(','),
    'timestamp': sys.argv[5],
    'model': sys.argv[6],
    'files': sys.argv[7].split(',') if sys.argv[7] else [],
    'anchoring': {
        'technique': 'repeat-description',
        'phrases': ['same character', 'maintain facial features', 'preserve proportions', 'keep identity']
    }
}

with open(sys.argv[8], 'w') as f:
    json.dump(meta, f, indent=2)
print('OK')
" "$brand" "$BRAND_NAME" "$description" "$poses_str" "$ts" "$model" "$generated_files" "$meta_file" 2>/dev/null

    echo ""
    echo "  Metadata: $meta_file"
    post_to_room "creative" "Character sheet generated for ${brand}: ${poses_count} poses. Dir: ${output_dir}"
    echo "Done. $poses_count poses generated."
  fi
}

# ---------------------------------------------------------------------------
# Command: storyboard
# ---------------------------------------------------------------------------

# 12-scene storyboard template
get_storyboard_scene() {
  local scene_num="$1"
  local character="$2"
  local product="$3"

  case "$scene_num" in
    1)  echo "${character} in morning kitchen, reaching for ${BRAND_NAME} ${product} on shelf. Warm natural kitchen light." ;;
    2)  echo "Close-up of ${character}'s hands opening the ${product} package. Detail shot, warm lighting." ;;
    3)  echo "${character} reading the back of the ${product} package, curious expression. Kitchen setting." ;;
    4)  echo "Overhead flat lay of ingredients laid out on wooden cutting board for ${product}. Organized, colorful." ;;
    5)  echo "${character} cooking, stirring pot with ${product}, steam rising, warm lighting. Action shot." ;;
    6)  echo "Close-up of the ${product} dish being plated, vibrant colors. Food styling, appetizing." ;;
    7)  echo "${character} tasting the ${product} dish, delighted expression, thumbs up. Natural reaction." ;;
    8)  echo "${character} serving ${product} dish to family/friends at table, everyone smiling. Warm, social." ;;
    9)  echo "Close-up of the finished ${product} dish on table, styled beauty shot. Magazine quality." ;;
    10) echo "${character} taking photo of ${product} food with phone. Meta/UGC feel, modern lifestyle." ;;
    11) echo "Phone screen showing social media post of the ${product} dish. Instagram-style interface." ;;
    12) echo "${character} relaxing with ${product} meal, satisfied expression, ${BRAND_NAME} logo visible. Closing shot." ;;
    *)  echo "${character} with ${BRAND_NAME} ${product}. Scene ${scene_num}." ;;
  esac
}

cmd_storyboard() {
  local brand="" character="" product="" scenes=12 model="pro" size="2K" ratio="16:9" dry_run="false"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)     brand="$2";     shift 2 ;;
      --character) character="$2"; shift 2 ;;
      --product)   product="$2";   shift 2 ;;
      --scenes)    scenes="$2";    shift 2 ;;
      --model)     model="$2";     shift 2 ;;
      --size)      size="$2";      shift 2 ;;
      --ratio)     ratio="$2";     shift 2 ;;
      --dry-run)   dry_run="true"; shift ;;
      *) die "storyboard: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "storyboard: --brand is required"
  [ -z "$character" ] && die "storyboard: --character is required"
  [ -z "$product" ] && die "storyboard: --product is required"

  # Clamp scenes
  if [ "$scenes" -lt 1 ] || [ "$scenes" -gt 12 ]; then
    warn "Scenes clamped to range 1-12"
    if [ "$scenes" -lt 1 ]; then scenes=1; fi
    if [ "$scenes" -gt 12 ]; then scenes=12; fi
  fi

  # Load brand profile
  load_brand_profile "$brand"

  local enrichment
  enrichment=$(brand_enrichment)

  local ts
  ts=$(timestamp_str)
  local output_dir="${STORYBOARDS_DIR}/${brand}/${ts}"
  mkdir -p "$output_dir"

  local size_upper
  size_upper=$(echo "$size" | tr 'a-z' 'A-Z')

  echo "Generating ${scenes}-scene storyboard..."
  echo "  Brand:     $brand ($BRAND_NAME)"
  echo "  Character: $character"
  echo "  Product:   $product"
  echo "  Model:     $model"
  echo "  Ratio:     $ratio"
  echo ""

  local generated_files=""
  local scene_descriptions=""
  local i=1

  while [ "$i" -le "$scenes" ]; do
    local scene_desc
    scene_desc=$(get_storyboard_scene "$i" "$character" "$product")

    local scene_prompt
    if [ "$i" -eq 1 ]; then
      scene_prompt="Storyboard Scene 1 of ${scenes}. ${scene_desc} ${enrichment} Semi-realistic style, soft focus, magazine quality."
    else
      scene_prompt="Storyboard Scene ${i} of ${scenes}. Same character (${character}). Maintain facial features, preserve proportions, keep identity, consistent with previous scenes. ${scene_desc} ${enrichment} Semi-realistic style, soft focus, magazine quality. Same lighting and art style as Scene 1."
    fi

    local padded
    padded=$(printf "%02d" "$i")
    local scene_output="${output_dir}/scene_${padded}.png"

    echo "  [Scene $i/$scenes] $(echo "$scene_desc" | head -c 80)..."

    local result
    result=$(call_gemini_api "$model" "$scene_prompt" "$ratio" "$size_upper" "$scene_output" "$dry_run")

    if [ "$dry_run" = "true" ]; then
      echo "$result"
    elif [ -n "$result" ] && [ -f "$result" ]; then
      echo "    Saved: $result"
      if [ -n "$generated_files" ]; then
        generated_files="${generated_files},${result}"
      else
        generated_files="$result"
      fi
      register_seed "$result" "$brand" "storyboard"
      register_image_seed "$result" "$brand" "storyboard" "" "" "" "$scene_prompt"
    fi

    # Track scene descriptions for metadata
    if [ -n "$scene_descriptions" ]; then
      scene_descriptions="${scene_descriptions}|||${scene_desc}"
    else
      scene_descriptions="$scene_desc"
    fi

    i=$((i + 1))
  done

  # Create storyboard metadata JSON
  if [ "$dry_run" != "true" ]; then
    local meta_file="${output_dir}/storyboard.json"
    python3 -c "
import json, sys

scenes_desc = sys.argv[5].split('|||')
files_list = sys.argv[6].split(',') if sys.argv[6] else []

meta = {
    'brand': sys.argv[1],
    'brand_name': sys.argv[2],
    'character': sys.argv[3],
    'product': sys.argv[4],
    'total_scenes': len(scenes_desc),
    'timestamp': sys.argv[7],
    'model': sys.argv[8],
    'ratio': sys.argv[9],
    'scenes': [],
    'files': files_list
}

for idx, desc in enumerate(scenes_desc, 1):
    scene_entry = {
        'scene': idx,
        'description': desc.strip(),
        'file': files_list[idx-1] if idx-1 < len(files_list) else None
    }
    meta['scenes'].append(scene_entry)

with open(sys.argv[10], 'w') as f:
    json.dump(meta, f, indent=2)
print('OK')
" "$brand" "$BRAND_NAME" "$character" "$product" "$scene_descriptions" "$generated_files" "$ts" "$model" "$ratio" "$meta_file" 2>/dev/null

    echo ""
    echo "  Metadata:  $meta_file"
    echo "  Directory: $output_dir"
    post_to_room "creative" "Storyboard generated for ${brand}: ${scenes} scenes for ${product}. Dir: ${output_dir}"
    echo "Done. ${scenes} scenes generated."
  fi
}

# ---------------------------------------------------------------------------
# Command: batch
# ---------------------------------------------------------------------------

cmd_batch() {
  local brand="" product="" use_cases_str="" model="flash" size="2K" ratio="1:1" dry_run="false"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)      brand="$2";          shift 2 ;;
      --product)    product="$2";        shift 2 ;;
      --use-cases)  use_cases_str="$2";  shift 2 ;;
      --model)      model="$2";          shift 2 ;;
      --size)       size="$2";           shift 2 ;;
      --ratio)      ratio="$2";          shift 2 ;;
      --dry-run)    dry_run="true";      shift ;;
      *) die "batch: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "batch: --brand is required"
  [ -z "$product" ] && die "batch: --product is required"
  [ -z "$use_cases_str" ] && die "batch: --use-cases is required"

  # Load brand profile
  load_brand_profile "$brand"

  local enrichment
  enrichment=$(brand_enrichment)

  # Parse use cases
  local IFS_SAVE="$IFS"
  IFS=','
  set -- $use_cases_str
  IFS="$IFS_SAVE"
  local total=$#

  local ts
  ts=$(timestamp_str)
  local size_upper
  size_upper=$(echo "$size" | tr 'a-z' 'A-Z')

  echo "Batch generating $total images..."
  echo "  Brand:     $brand ($BRAND_NAME)"
  echo "  Product:   $product"
  echo "  Use cases: $use_cases_str"
  echo "  Model:     $model"
  echo ""

  local uc_index=0
  local success_count=0
  local fail_count=0
  local max_concurrent=5

  if [ "$dry_run" = "true" ]; then
    # Dry run: sequential (just print prompts)
    for uc in "$@"; do
      uc_index=$((uc_index + 1))
      local uc_clean
      uc_clean=$(echo "$uc" | tr -d '[:space:]')
      echo "  [$uc_index/$total] Generating: $uc_clean"
      local template
      template=$(get_usecase_template "$uc_clean" "$product")
      local full_prompt="${product}. ${template} ${enrichment}"
      local output_dir="${IMAGES_DIR}/${brand}"
      mkdir -p "$output_dir"
      local output_path="${output_dir}/${ts}_${uc_clean}.png"
      local result
      result=$(call_gemini_api "$model" "$full_prompt" "$ratio" "$size_upper" "$output_path" "$dry_run" 2>&1) || true
      echo "$result"
    done
  else
    # Parallel generation: up to max_concurrent at a time
    local output_dir="${IMAGES_DIR}/${brand}"
    mkdir -p "$output_dir"
    local bg_pids=""
    local bg_ucs=""
    local running=0

    for uc in "$@"; do
      uc_index=$((uc_index + 1))
      local uc_clean
      uc_clean=$(echo "$uc" | tr -d '[:space:]')

      echo "  [$uc_index/$total] Launching: $uc_clean (background)"

      local template
      template=$(get_usecase_template "$uc_clean" "$product")
      local full_prompt="${product}. ${template} ${enrichment}"
      local output_path="${output_dir}/${ts}_${uc_clean}.png"

      # Run in background, write result to done-file
      (
        local r
        r=$(call_gemini_api "$model" "$full_prompt" "$ratio" "$size_upper" "$output_path" "false" 2>&1) || true
        if [ -n "$r" ] && [ -f "$r" ]; then
          printf '%s\n%s\n' "$r" "$full_prompt" > "/tmp/nb-batch-$$-${uc_clean}.done"
        fi
      ) &
      bg_pids="$bg_pids $!"
      bg_ucs="$bg_ucs $uc_clean"
      running=$((running + 1))

      # When we hit max_concurrent, wait for all before launching more
      if [ "$running" -ge "$max_concurrent" ]; then
        echo "  Waiting for batch of $running concurrent jobs..."
        for pid in $bg_pids; do
          wait "$pid" 2>/dev/null || true
        done
        bg_pids=""
        running=0
      fi
    done

    # Wait for any remaining jobs
    if [ -n "$bg_pids" ]; then
      echo "  Waiting for final $running concurrent jobs..."
      for pid in $bg_pids; do
        wait "$pid" 2>/dev/null || true
      done
    fi

    # Collect results
    for uc_clean in $bg_ucs; do
      local done_file="/tmp/nb-batch-$$-${uc_clean}.done"
      if [ -f "$done_file" ]; then
        local result
        result=$(head -1 "$done_file")
        local done_prompt
        done_prompt=$(tail -n +2 "$done_file" | head -1)
        rm -f "$done_file"
        echo "    Saved: $result"
        success_count=$((success_count + 1))
        register_seed "$result" "$brand" "$uc_clean"
        register_image_seed "$result" "$brand" "$uc_clean" "" "" "" "$done_prompt"
      else
        warn "Failed to generate $uc_clean"
        fail_count=$((fail_count + 1))
      fi
    done
  fi

  if [ "$dry_run" != "true" ]; then
    echo ""
    echo "Batch complete: $success_count/$total succeeded, $fail_count failed."
    post_to_room "creative" "Batch generation for ${brand}: ${success_count}/${total} images for ${product}."
    log "INFO" "Batch complete: brand=$brand product=$product success=$success_count fail=$fail_count"
  fi
}

# ---------------------------------------------------------------------------
# Command: sheet (multi-panel single-image generation)
# ---------------------------------------------------------------------------

# Sheet type definitions — each returns a prompt fragment
get_sheet_prompt() {
  local sheet_type="$1"
  local description="$2"

  case "$sheet_type" in
    turnaround|9-angle)
      echo "Character turnaround sheet. Generate exactly 9 views of this SAME character arranged in a 3x3 grid:

Row 1: Front view | 3/4 left view | Left side profile
Row 2: 3/4 back left | Back view | 3/4 back right
Row 3: Right side profile | 3/4 right view | Close-up face

Every panel must show the IDENTICAL character from the reference image. Same face, same outfit, same proportions. Upper body framing. Clean background per panel. Small text label per angle."
      ;;
    scenes|12-scene)
      echo "Character scene sheet. Generate exactly 12 scenes of this SAME character arranged in a 4x3 grid. Each scene shows the character in a DIFFERENT environment but looking IDENTICAL:

Row 1: Neon city street at night | Futuristic laboratory | Zen garden
Row 2: Floating in space | Glass bridge | Crystal cave
Row 3: Holographic data streams | Rooftop at sunset | Misty forest
Row 4: Spacecraft cockpit | Marketplace | Empty white room

Same character in every panel. Small text label per scene."
      ;;
    camera|12-camera)
      echo "Cinematic camera angle sheet. Generate exactly 12 camera angles of this SAME character arranged in a 4x3 grid:

Row 1: Extreme close-up (eyes) | Medium close-up (face) | Medium shot (waist up)
Row 2: Full body | Wide establishing | Low angle (looking up)
Row 3: High angle (looking down) | Dutch angle (tilted) | Over-the-shoulder
Row 4: Silhouette (backlit) | Reflection | Bird's eye (from above)

Same character in every panel. Dark or studio background. Small text label per angle."
      ;;
    expressions|6-expression)
      echo "Character expression sheet. Generate exactly 6 expressions of this SAME character arranged in a 3x2 grid:

Row 1: Neutral / calm | Happy / warm smile | Serious / determined
Row 2: Curious / interested | Surprised / amazed | Confident / powerful

Same character in every panel — same outfit, same lighting. Close-up face framing. Clean background. Small text label per expression."
      ;;
    outfits|4-outfit)
      echo "Character outfit variation sheet. Generate exactly 4 versions of this SAME character arranged in a 2x2 grid. Same face in every panel, different context clothing:

Panel 1: Original outfit (as reference)
Panel 2: Casual / relaxed version
Panel 3: Formal / ceremonial version
Panel 4: Action / dynamic version

Same face and body proportions in every panel. Full body framing. Clean background. Small text label per outfit."
      ;;
    custom)
      echo "$description"
      ;;
    *)
      echo "Character sheet. Generate multiple views of this SAME character in a grid. $description"
      ;;
  esac
}

cmd_sheet() {
  local brand="" sheet_type="turnaround" model="flash" size="1K" ratio="1:1" dry_run="false"
  local ref_image="" description="" character_name=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)      brand="$2";          shift 2 ;;
      --type)       sheet_type="$2";     shift 2 ;;
      --ref-image)  ref_image="$2";      shift 2 ;;
      --model)      model="$2";          shift 2 ;;
      --size)       size="$2";           shift 2 ;;
      --ratio)      ratio="$2";          shift 2 ;;
      --name)       character_name="$2"; shift 2 ;;
      --description) description="$2";   shift 2 ;;
      --dry-run)    dry_run="true";      shift ;;
      *) die "sheet: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "sheet: --brand is required"
  [ -z "$ref_image" ] && die "sheet: --ref-image is required (path to locked character image)"
  [ -f "$ref_image" ] || die "sheet: ref image not found: $ref_image"

  # Default ratio based on sheet type
  case "$sheet_type" in
    turnaround|9-angle) ratio="${ratio:-1:1}" ;;
    scenes|12-scene|camera|12-camera) ratio="3:4" ;;
    expressions|6-expression) ratio="3:2" ;;
    outfits|4-outfit) ratio="1:1" ;;
  esac

  local size_upper
  size_upper=$(echo "$size" | tr 'a-z' 'A-Z')

  # Build prompt
  local sheet_prompt
  sheet_prompt=$(get_sheet_prompt "$sheet_type" "$description")

  # Output path
  local ts
  ts=$(timestamp_str)
  local name_slug="${character_name:-character}"
  local output_dir="${CHARACTERS_DIR}/${brand}"
  mkdir -p "$output_dir"
  local output_path="${output_dir}/${ts}_${name_slug}_${sheet_type}.png"

  echo "Generating ${sheet_type} sheet (single image, multi-panel)..."
  echo "  Brand:     $brand"
  echo "  Type:      $sheet_type"
  echo "  Ref image: $ref_image"
  echo "  Model:     $model"
  echo "  Size:      $size_upper (generate small, upscale later)"
  echo "  Ratio:     $ratio"
  echo ""

  local result
  result=$(call_gemini_api "$model" "$sheet_prompt" "$ratio" "$size_upper" "$output_path" "$dry_run" "$ref_image")

  if [ "$dry_run" = "true" ]; then
    echo "$result"
    return 0
  fi

  if [ -n "$result" ] && [ -f "$result" ]; then
    local file_kb
    file_kb=$(du -k "$result" | cut -f1)
    echo "  Output: $result (${file_kb} KB)"
    log "INFO" "Sheet generated: $result (type=$sheet_type brand=$brand)"

    # Register
    register_image_seed "$result" "$brand" "character-sheet" "" "" "" "$sheet_prompt"

    # Save metadata
    local meta_file="${output_dir}/${ts}_${name_slug}_${sheet_type}.json"
    python3 -c "
import json, sys, os
meta = {
    'brand': sys.argv[1],
    'character': sys.argv[2],
    'sheet_type': sys.argv[3],
    'ref_image': sys.argv[4],
    'model': sys.argv[5],
    'resolution': sys.argv[6],
    'output': sys.argv[7],
    'timestamp': sys.argv[8],
    'verdict': None,
    'tags': [],
    'learnings': []
}
with open(sys.argv[9], 'w') as f:
    json.dump(meta, f, indent=2)
" "$brand" "$name_slug" "$sheet_type" "$ref_image" "$model" "$size_upper" "$result" "$ts" "$meta_file" 2>/dev/null

    echo "  Metadata: $meta_file"
    post_to_room "creative" "Sheet generated: ${sheet_type} for ${name_slug} (${brand}). Path: $result"
    echo "Done."
  fi
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<'USAGE'
nanobanana-gen.sh — NanoBanana Image Generation CLI (Gemini Image API)

USAGE:
  nanobanana-gen.sh <command> [options]

COMMANDS:
  generate          Generate a single image
  character-sheet   Generate character reference images (multiple poses)
  storyboard        Generate a multi-scene campaign storyboard
  batch             Batch generate for multiple use cases
  --help            Show this help

GENERATE OPTIONS:
  --brand <slug>          Brand slug (required, e.g., gaia-eats)
  --use-case <uc>         Use case type (default: product)
  --prompt <text>         Image prompt (required)
  --character <text>      Character description for lifestyle/recipe use cases (replaces [CHARACTER] placeholder)
  --setting <text>        Setting description for lifestyle use cases (replaces [SETTING] placeholder)
  --size <size>           Image size: 1K, 2K, 4K (default: 2K)
  --ratio <ratio>         Aspect ratio: 1:1, 16:9, 9:16, 4:3, etc. (default: 1:1)
  --model <model>         Model: flash (fast) or pro (quality) (default: flash)
  --style-seed <id>       Style seed ID (e.g., ss-1234567890) to apply style
  --campaign <slug>       Campaign slug (e.g., cny-2026) for campaign overrides
  --funnel-stage <stage>  Funnel stage: TOFU, MOFU, or BOFU
  --dry-run               Show prompt without calling API

CHARACTER-SHEET OPTIONS:
  --brand <slug>          Brand slug (required)
  --description <text>    Character description (required)
  --poses <p1,p2,...>     Comma-separated poses (default: front,side,waving)
  --model <model>         Model: flash or pro (default: pro)
  --size <size>           Image size (default: 2K)
  --ratio <ratio>         Aspect ratio (default: 1:1)
  --dry-run               Show prompts without calling API

STORYBOARD OPTIONS:
  --brand <slug>       Brand slug (required)
  --character <text>   Character description (required)
  --product <text>     Product name (required)
  --scenes <N>         Number of scenes, 1-12 (default: 12)
  --model <model>      Model: flash or pro (default: pro)
  --size <size>        Image size (default: 2K)
  --ratio <ratio>      Aspect ratio (default: 16:9)
  --dry-run            Show prompts without calling API

BATCH OPTIONS:
  --brand <slug>        Brand slug (required)
  --product <text>      Product name (required)
  --use-cases <u1,u2>   Comma-separated use cases (required)
  --model <model>       Model: flash or pro (default: flash)
  --size <size>         Image size (default: 2K)
  --ratio <ratio>       Aspect ratio (default: 1:1)
  --dry-run             Show prompts without calling API

USE CASE TYPES:
  product       Professional product photography, studio lighting
  food          Appetizing food photography, natural light
  lifestyle     Lifestyle photography, candid authentic moments in Malaysian setting. Optional: --character to include model, product must be specific and described.
  flatlay       Overhead flat lay, organized arrangement
  social        Instagram-ready, vibrant, thumb-stopping
  packaging     Packaging mockup with brand elements
  ecommerce     E-commerce listing, white background, 85% frame fill
  recipe        Step-by-step recipe shot
  character     Character/mascot design
  pod           Print-on-demand mockup
  education     Educational infographic style
  beforeafter   Split image comparison

MODELS:
  flash         gemini-3.1-flash-image-preview (NanoBanana 2 — Pro quality at Flash speed)
  pro           gemini-3-pro-image-preview (NanoBanana Pro — max quality, reasoning)

ENVIRONMENT:
  GEMINI_API_KEY  Required. Google Gemini API key.

BRAND PROFILES:
  Brand DNA stored at ~/.openclaw/brands/{brand}/DNA.json
  7 brands: pinxin-vegan, wholey-wonder, mirra, rasaya, dr-stan, serein, gaia-eats

EXAMPLES:
  # Generate a single product image
  nanobanana-gen.sh generate \
    --brand gaia-eats \
    --use-case product \
    --prompt "GAIA rendang paste packaging on marble surface" \
    --size 4K --ratio 1:1 --model pro

  # Generate a lifestyle image with character and setting
  nanobanana-gen.sh generate \
    --brand mirra \
    --use-case lifestyle \
    --character "A 28-year-old Malaysian woman with warm brown skin, wearing a sage green lab coat over casual attire" \
    --setting "Modern Malaysian home kitchen with wooden countertops and sunlight streaming through window" \
    --prompt "Enjoying fresh healthy meal" \
    --size 2K --ratio 9:16

  # Generate character reference sheet
  nanobanana-gen.sh character-sheet \
    --brand gaia-eats \
    --description "28yo Malaysian woman, friendly, sage green apron" \
    --poses "front,side,waving,cooking,tasting"

  # Generate 12-scene storyboard
  nanobanana-gen.sh storyboard \
    --brand gaia-eats \
    --character "28yo Malaysian woman in sage green apron" \
    --product "rendang paste" --scenes 12

  # Batch generate multiple use cases
  nanobanana-gen.sh batch \
    --brand gaia-eats \
    --product "rendang paste" \
    --use-cases "product,food,lifestyle,flatlay,social"

  # Dry run (preview prompt without API call)
  nanobanana-gen.sh generate --brand gaia-eats --use-case food \
    --prompt "Vegan laksa bowl" --dry-run

  # Generate with campaign + funnel stage (CNY TOFU hero)
  nanobanana-gen.sh generate \
    --brand pinxin-vegan \
    --prompt "Festive vegan poon choi reunion dinner" \
    --campaign cny-2026 --funnel-stage TOFU \
    --ratio 16:9 --size 2K

  # BOFU ugly ads for meal kits
  nanobanana-gen.sh generate \
    --brand gaia-eats \
    --prompt "Last chance meal kit bundle deal" \
    --campaign mco-meal-kits --funnel-stage BOFU \
    --ratio 9:16

CAMPAIGNS:
  Campaign files: ~/.openclaw/brands/{brand}/campaigns/{campaign}.json
  Funnel stages:  TOFU (awareness), MOFU (consideration), BOFU (conversion)
  Overrides:      visual (colors, mood, lighting), voice (tone, CTA), creative_mode

RATE LIMITING:
  Free tier: ~2 requests/minute (30s between calls, auto-enforced)

OUTPUT PATHS:
  Images:      ~/.openclaw/workspace/data/images/{brand}/
  Characters:  ~/.openclaw/workspace/data/characters/{brand}/
  Storyboards: ~/.openclaw/workspace/data/storyboards/{brand}/{timestamp}/
  Log:         ~/.openclaw/logs/nanobanana.log
USAGE
}

# ---------------------------------------------------------------------------
# Main Dispatch
# ---------------------------------------------------------------------------

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  generate)
    cmd_generate "$@"
    ;;
  character-sheet)
    cmd_character_sheet "$@"
    ;;
  storyboard)
    cmd_storyboard "$@"
    ;;
  batch)
    cmd_batch "$@"
    ;;
  sheet)
    cmd_sheet "$@"
    ;;
  --help|-h|help)
    usage
    exit 0
    ;;
  *)
    die "Unknown command: $COMMAND. Run with --help for usage."
    ;;
esac
