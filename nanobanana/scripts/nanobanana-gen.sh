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
BRANDS_DIR="$SKILL_DIR/brands"
DATA_DIR="$HOME/.openclaw/workspace/data"
IMAGES_DIR="$DATA_DIR/images"
CHARACTERS_DIR="$DATA_DIR/characters"
STORYBOARDS_DIR="$DATA_DIR/storyboards"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
LOG_FILE="$HOME/.openclaw/logs/nanobanana.log"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"

API_BASE="https://generativelanguage.googleapis.com/v1beta/models"
MODEL_FLASH="gemini-2.5-flash-image"
MODEL_PRO="gemini-3-pro-image-preview"

# Rate limiting: track last request time
RATE_FILE="/tmp/nanobanana-lastcall"
RATE_LIMIT_SECONDS=30  # 2 req/min = 1 every 30s

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

# Wait for rate limit
rate_limit_wait() {
  if [ -f "$RATE_FILE" ]; then
    local last_call
    last_call=$(cat "$RATE_FILE" 2>/dev/null || echo "0")
    local now
    now=$(epoch_s)
    local diff=$((now - last_call))
    if [ "$diff" -lt "$RATE_LIMIT_SECONDS" ]; then
      local wait_time=$((RATE_LIMIT_SECONDS - diff))
      echo "Rate limit: waiting ${wait_time}s..."
      sleep "$wait_time"
    fi
  fi
  epoch_s > "$RATE_FILE"
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
  local profile_path="$BRANDS_DIR/${brand_slug}.json"

  if [ -f "$profile_path" ]; then
    log "INFO" "Loading brand profile: $profile_path"
    # Parse brand JSON with python3
    eval "$(python3 -c "
import json, sys

with open(sys.argv[1], 'r') as f:
    b = json.loads(f.read())

def sh_escape(s):
    if s is None:
        return ''
    return str(s).replace(\"'\", \"'\\\"'\\\"'\")

colors = b.get('colors', {})
print(\"BRAND_NAME='%s'\" % sh_escape(b.get('brand_name', 'GAIA Eats')))
print(\"BRAND_COLOR_PRIMARY='%s'\" % sh_escape(colors.get('primary', '#8FBC8F')))
print(\"BRAND_COLOR_SECONDARY='%s'\" % sh_escape(colors.get('secondary', '#DAA520')))
print(\"BRAND_COLOR_BG='%s'\" % sh_escape(colors.get('background', '#FFFDD0')))
print(\"BRAND_STYLE='%s'\" % sh_escape(b.get('style', 'warm, natural, appetizing, accessible')))
print(\"BRAND_LIGHTING='%s'\" % sh_escape(b.get('lighting', 'warm natural light, soft shadows')))
print(\"BRAND_PHOTO_STYLE='%s'\" % sh_escape(b.get('photography_style', 'magazine editorial, lifestyle')))
" "$profile_path" 2>/dev/null)" || warn "Could not parse brand profile: $profile_path"
  else
    log "INFO" "No brand profile at $profile_path, using defaults (GAIA Eats)"
  fi
}

# Build brand enrichment string to append to prompts
brand_enrichment() {
  echo "Brand: ${BRAND_NAME}. Colors: primary ${BRAND_COLOR_PRIMARY}, secondary ${BRAND_COLOR_SECONDARY}, background ${BRAND_COLOR_BG}. Style: ${BRAND_STYLE}. Lighting: ${BRAND_LIGHTING}. Photography: ${BRAND_PHOTO_STYLE}."
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
      echo "Lifestyle photography: person using/enjoying ${BRAND_NAME} ${product} as part of daily routine. Candid, natural moment, not posed. Warm, inviting atmosphere, Malaysian home/cafe setting. Natural lighting, slightly warm color temperature. Aspirational but relatable, Instagram-worthy."
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
      echo "Brand mascot/character design for ${BRAND_NAME}. Friendly, approachable, warm expression. Style: modern, clean illustration. White background, character sheet format. Suitable for social media, packaging, stickers."
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

  # Build request body
  local body
  body=$(python3 -c "
import json, sys

prompt = sys.argv[1]
ratio = sys.argv[2]
size = sys.argv[3]

payload = {
    'contents': [
        {
            'parts': [
                {'text': prompt}
            ]
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
" "$prompt" "$aspect_ratio" "$image_size")

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
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    echo "==============="
    return 0
  fi

  log "INFO" "Calling Gemini API: model=$model_id size=$image_size ratio=$aspect_ratio"
  log "INFO" "Prompt: $prompt"

  # Rate limit
  rate_limit_wait

  # Make API call with timeout (macOS-safe: background + wait + kill)
  local response_file
  response_file=$(mktemp /tmp/nanobanana-resp.XXXXXX)
  local http_code_file
  http_code_file=$(mktemp /tmp/nanobanana-http.XXXXXX)

  # Run curl in background for timeout handling
  curl -s -w '%{http_code}' \
    -X POST "$endpoint" \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -d "$body" \
    -o "$response_file" \
    > "$http_code_file" 2>/dev/null &

  local curl_pid=$!

  # Wait up to 120 seconds (macOS-safe timeout)
  local waited=0
  while kill -0 "$curl_pid" 2>/dev/null; do
    if [ "$waited" -ge 120 ]; then
      kill "$curl_pid" 2>/dev/null || true
      rm -f "$response_file" "$http_code_file"
      die "API call timed out after 120 seconds"
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
    die "curl failed (exit=$exit_code). Response: $err_body"
  fi

  if [ "$http_code" != "200" ]; then
    local err_body
    err_body=$(cat "$response_file" 2>/dev/null || echo "no response")
    rm -f "$response_file"
    log "ERROR" "API returned HTTP $http_code: $err_body"
    die "API returned HTTP $http_code. Check $LOG_FILE for details. Response: $(echo "$err_body" | head -c 500)"
  fi

  # Extract base64 image data and save as PNG
  mkdir -p "$(dirname "$output_path")"

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

  rm -f "$response_file"

  case "$extract_result" in
    OK:*)
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
      die "Failed to extract image: $err_msg"
      ;;
    *)
      die "Unexpected extraction result: $extract_result"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Command: generate
# ---------------------------------------------------------------------------

cmd_generate() {
  local brand="" use_case="product" prompt="" size="2K" ratio="1:1" model="flash" dry_run="false" raw="false"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)     brand="$2";     shift 2 ;;
      --use-case)  use_case="$2";  shift 2 ;;
      --prompt)    prompt="$2";    shift 2 ;;
      --size)      size="$2";      shift 2 ;;
      --ratio)     ratio="$2";     shift 2 ;;
      --model)     model="$2";     shift 2 ;;
      --dry-run)   dry_run="true"; shift ;;
      --raw)       raw="true";     shift ;;
      *) die "generate: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "generate: --brand is required"
  [ -z "$prompt" ] && die "generate: --prompt is required"

  # Validate size
  local size_upper
  size_upper=$(echo "$size" | tr 'a-z' 'A-Z')
  case "$size_upper" in
    1K|2K|4K) ;;
    *) die "generate: --size must be 1K, 2K, or 4K (got: $size)" ;;
  esac

  # Load brand profile
  load_brand_profile "$brand"

  # Enrich prompt with brand context and use case template (skip if --raw)
  local full_prompt
  if [ "$raw" = "true" ]; then
    full_prompt="$prompt"
  else
    local template
    template=$(get_usecase_template "$use_case" "$prompt")
    local enrichment
    enrichment=$(brand_enrichment)
    full_prompt="${prompt}. ${template} ${enrichment}"
  fi

  # Output path
  local ts
  ts=$(timestamp_str)
  local output_dir="${IMAGES_DIR}/${brand}"
  mkdir -p "$output_dir"
  local output_path="${output_dir}/${ts}_${use_case}.png"

  echo "Generating image..."
  echo "  Brand:    $brand ($BRAND_NAME)"
  echo "  Use case: $use_case"
  echo "  Model:    $model"
  echo "  Size:     $size_upper"
  echo "  Ratio:    $ratio"

  local result
  result=$(call_gemini_api "$model" "$full_prompt" "$ratio" "$size_upper" "$output_path" "$dry_run")

  if [ "$dry_run" = "true" ]; then
    echo "$result"
    return 0
  fi

  if [ -n "$result" ] && [ -f "$result" ]; then
    echo "  Output:   $result"
    log "INFO" "Generated: $result (brand=$brand use_case=$use_case)"

    # Register with seed store
    register_seed "$result" "$brand" "$use_case"

    # Post to creative room
    local escaped_path
    escaped_path=$(echo "$result" | sed 's/"/\\"/g')
    post_to_room "creative" "Image generated: ${use_case} for ${brand}. Path: ${escaped_path}"

    echo "Done."
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

  for pose in "$@"; do
    pose_index=$((pose_index + 1))
    local pose_clean
    pose_clean=$(echo "$pose" | tr -d '[:space:]')

    echo "  [$pose_index/$poses_count] Generating pose: $pose_clean"

    local char_prompt
    if [ "$pose_index" -eq 1 ]; then
      char_prompt="Character design sheet. ${description}. Pose: ${pose_clean}, full body visible. ${enrichment} White/clean background. Semi-realistic style, consistent proportions."
    else
      char_prompt="Same character (${description}). Maintain facial features, preserve proportions, keep identity. Pose: ${pose_clean}, full body visible. ${enrichment} White/clean background. Semi-realistic style, consistent with reference."
    fi

    local pose_output="${output_dir}/${ts}_char_${pose_clean}.png"

    local result
    result=$(call_gemini_api "$model" "$char_prompt" "$ratio" "$size_upper" "$pose_output" "$dry_run")

    if [ "$dry_run" = "true" ]; then
      echo "$result"
    elif [ -n "$result" ] && [ -f "$result" ]; then
      echo "    Saved: $result"
      if [ -n "$generated_files" ]; then
        generated_files="${generated_files},${result}"
      else
        generated_files="$result"
      fi
      register_seed "$result" "$brand" "character"
    fi
  done

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

    if [ "$dry_run" = "true" ]; then
      echo "$result"
    elif [ -n "$result" ] && [ -f "$result" ]; then
      echo "    Saved: $result"
      success_count=$((success_count + 1))
      register_seed "$result" "$brand" "$uc_clean"
    else
      warn "Failed to generate $uc_clean: $result"
      fail_count=$((fail_count + 1))
    fi
  done

  if [ "$dry_run" != "true" ]; then
    echo ""
    echo "Batch complete: $success_count/$total succeeded, $fail_count failed."
    post_to_room "creative" "Batch generation for ${brand}: ${success_count}/${total} images for ${product}."
    log "INFO" "Batch complete: brand=$brand product=$product success=$success_count fail=$fail_count"
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
  --brand <slug>     Brand slug (required, e.g., gaia-eats)
  --use-case <uc>    Use case type (default: product)
  --prompt <text>    Image prompt (required)
  --size <size>      Image size: 1K, 2K, 4K (default: 2K)
  --ratio <ratio>    Aspect ratio: 1:1, 16:9, 9:16, 4:3, etc. (default: 1:1)
  --model <model>    Model: flash (fast) or pro (quality) (default: flash)
  --dry-run          Show prompt without calling API

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
  lifestyle     Lifestyle photography, candid, Malaysian setting
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
  flash         gemini-2.5-flash-image (fast, high-volume)
  pro           gemini-3-pro-image-preview (quality, character consistency, 4K)

ENVIRONMENT:
  GEMINI_API_KEY  Required. Google Gemini API key.

BRAND PROFILES:
  Store brand JSON at ~/.openclaw/skills/nanobanana/brands/{brand}.json
  See SKILL.md for the brand profile schema.

EXAMPLES:
  # Generate a single product image
  nanobanana-gen.sh generate \
    --brand gaia-eats \
    --use-case product \
    --prompt "GAIA rendang paste packaging on marble surface" \
    --size 4K --ratio 1:1 --model pro

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
  --help|-h|help)
    usage
    exit 0
    ;;
  *)
    die "Unknown command: $COMMAND. Run with --help for usage."
    ;;
esac
