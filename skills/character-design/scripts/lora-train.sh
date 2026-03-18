#!/usr/bin/env bash
# lora-train.sh — LoRA Training Pipeline for GAIA OS Character Consistency
# Trains Flux LoRA (multi-image, 20min, $2) or Kontext LoRA (1 image, 5min, $2)
# via Replicate API. Stores trained weights in character vault.
# macOS-compatible: Bash 3.2, no declare -A, no ${var,,}, no GNU timeout
# ---

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants & Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LEARNINGS_FILE="$SKILL_DIR/learnings.jsonl"
DATA_DIR="$HOME/.openclaw/workspace/data"
CHARACTERS_DIR="$DATA_DIR/characters"
LOG_FILE="$HOME/.openclaw/logs/lora-train.log"
ENV_FILE="$HOME/.openclaw/.env"
SECRETS_DIR="$HOME/.openclaw/secrets"
NANOBANANA="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
DECISION_MATRIX="$HOME/.openclaw/skills/brand-asset-kit/templates/kit-template/schemas/lora-decision-matrix.json"

# Replicate model versions
FLUX_TRAINER="ostris/flux-dev-lora-trainer"
KONTEXT_TRAINER="black-forest-labs/flux-kontext-lora-trainer"
FLUX_GENERATOR="lucataco/flux-dev-lora"
KONTEXT_GENERATOR="black-forest-labs/flux-kontext-pro"

# Polling
POLL_INTERVAL=15       # seconds between status checks
MAX_POLL_MINUTES=45    # give up after this many minutes

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
  echo "INFO: $*"
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

# Load Replicate API token from env, .env, or secrets
load_replicate_token() {
  if [ -n "${REPLICATE_API_TOKEN:-}" ]; then
    return 0
  fi

  # Try secrets dir
  if [ -f "$SECRETS_DIR/replicate.env" ]; then
    export "$(grep '^REPLICATE_API_TOKEN=' "$SECRETS_DIR/replicate.env" | head -1)"
    if [ -n "${REPLICATE_API_TOKEN:-}" ]; then return 0; fi
  fi

  # Try .env
  if [ -f "$ENV_FILE" ]; then
    local val
    val="$(grep '^REPLICATE_API_TOKEN=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true)"
    if [ -n "$val" ]; then
      export REPLICATE_API_TOKEN="$val"
      return 0
    fi
  fi

  die "REPLICATE_API_TOKEN not found. Set it in env, $SECRETS_DIR/replicate.env, or $ENV_FILE"
}

# Replicate API helper
replicate_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local args=(-s -X "$method"
    -H "Authorization: Bearer $REPLICATE_API_TOKEN"
    -H "Content-Type: application/json"
  )
  if [ -n "$data" ]; then
    args+=(-d "$data")
  fi
  curl "${args[@]}" "https://api.replicate.com/v1${endpoint}"
}

# Upload a local image to a temporary hosting service via Replicate file API
# Returns a URL that Replicate can access
upload_image() {
  local file_path="$1"
  local mime_type="image/png"
  case "$file_path" in
    *.jpg|*.jpeg) mime_type="image/jpeg" ;;
    *.webp) mime_type="image/webp" ;;
  esac

  local result
  result=$(curl -s -X POST \
    -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
    -H "Content-Type: $mime_type" \
    --data-binary "@$file_path" \
    "https://api.replicate.com/v1/files")

  local url
  url=$(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('urls',{}).get('get',''))" 2>/dev/null)

  if [ -z "$url" ]; then
    die "Failed to upload $file_path to Replicate. Response: $result"
  fi
  echo "$url"
}

# Create a ZIP of training images and upload it
create_and_upload_zip() {
  local images_dir="$1"
  local char_name="$2"
  local tmp_zip="/tmp/lora-train-${char_name}-$(timestamp_str).zip"

  info "Creating training ZIP from $images_dir ..."

  # Find all images (png, jpg, jpeg, webp)
  local img_count=0
  local img_files=""
  for ext in png jpg jpeg webp; do
    for f in "$images_dir"/*."$ext" "$images_dir"/*."$(echo "$ext" | tr 'a-z' 'A-Z')"; do
      if [ -f "$f" ]; then
        img_files="$img_files $f"
        img_count=$((img_count + 1))
      fi
    done
  done

  if [ "$img_count" -eq 0 ]; then
    die "No images found in $images_dir (looked for png/jpg/jpeg/webp)"
  fi

  info "Found $img_count training images"

  # Create zip (use -j to junk paths — flat file list)
  # shellcheck disable=SC2086
  zip -j "$tmp_zip" $img_files > /dev/null 2>&1 || die "Failed to create ZIP"

  info "Uploading training ZIP ($(($(wc -c < "$tmp_zip" | tr -d ' ') / 1024))KB) ..."
  local url
  url=$(curl -s -X POST \
    -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
    -H "Content-Type: application/zip" \
    --data-binary "@$tmp_zip" \
    "https://api.replicate.com/v1/files" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('urls',{}).get('get',''))" 2>/dev/null)

  rm -f "$tmp_zip"

  if [ -z "$url" ]; then
    die "Failed to upload training ZIP"
  fi
  echo "$url"
}

# Poll a Replicate prediction until it completes
poll_prediction() {
  local prediction_id="$1"
  local started_at
  started_at=$(date +%s)
  local max_seconds=$((MAX_POLL_MINUTES * 60))

  info "Polling prediction $prediction_id (max ${MAX_POLL_MINUTES}min) ..."

  while true; do
    local elapsed=$(( $(date +%s) - started_at ))
    if [ "$elapsed" -gt "$max_seconds" ]; then
      die "Training timed out after ${MAX_POLL_MINUTES} minutes. Prediction: $prediction_id"
    fi

    local result
    result=$(replicate_api GET "/predictions/$prediction_id")

    local status
    status=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null)

    case "$status" in
      succeeded)
        info "Training completed in $((elapsed / 60))m $((elapsed % 60))s"
        echo "$result"
        return 0
        ;;
      failed|canceled)
        local error_msg
        error_msg=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error','unknown error'))" 2>/dev/null)
        die "Training $status: $error_msg"
        ;;
      *)
        # still processing
        local mins=$((elapsed / 60))
        local secs=$((elapsed % 60))
        printf "\r  [%02d:%02d] Status: %-12s" "$mins" "$secs" "$status"
        sleep "$POLL_INTERVAL"
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Train: Flux LoRA (multi-image, ~20min, ~$2)
# ---------------------------------------------------------------------------

train_flux() {
  local char_name="$1"
  local images_dir="$2"
  local trigger_word="$3"
  local char_dir="$CHARACTERS_DIR/$char_name"

  info "=== Flux LoRA Training ==="
  info "Character: $char_name"
  info "Images: $images_dir"
  info "Trigger: $trigger_word"

  # Validate: need 5-20 images for best results
  local img_count=0
  for ext in png jpg jpeg webp; do
    for f in "$images_dir"/*."$ext" "$images_dir"/*."$(echo "$ext" | tr 'a-z' 'A-Z')"; do
      [ -f "$f" ] && img_count=$((img_count + 1))
    done
  done

  if [ "$img_count" -lt 3 ]; then
    die "Flux LoRA needs at least 3 images (found $img_count). Use --method kontext for single-image training."
  fi

  if [ "$img_count" -gt 30 ]; then
    warn "More than 30 images ($img_count). Replicate recommends 10-20 for best results."
  fi

  # Upload training ZIP
  local zip_url
  zip_url=$(create_and_upload_zip "$images_dir" "$char_name")

  # Create training via Replicate predictions API
  info "Starting Flux LoRA training on Replicate ..."

  local payload
  payload=$(python3 -c "
import json
print(json.dumps({
    'version': None,
    'input': {
        'input_images': '$zip_url',
        'trigger_word': '$trigger_word',
        'steps': 1000,
        'lora_rank': 16,
        'optimizer': 'adamw8bit',
        'batch_size': 1,
        'resolution': '512,768,1024',
        'autocaption': True,
        'autocaption_prefix': '$trigger_word, '
    }
}))
")

  local result
  result=$(curl -s -X POST \
    -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://api.replicate.com/v1/models/$FLUX_TRAINER/predictions")

  local prediction_id
  prediction_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

  if [ -z "$prediction_id" ]; then
    die "Failed to start training. Response: $result"
  fi

  info "Training started: prediction $prediction_id"
  info "Estimated time: ~20 minutes, ~\$2"

  # Poll until done
  local final_result
  final_result=$(poll_prediction "$prediction_id")
  echo ""  # newline after progress

  # Extract LoRA weights URL
  local weights_url
  weights_url=$(echo "$final_result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
out = d.get('output', '')
# output can be a string URL or a dict
if isinstance(out, str):
    print(out)
elif isinstance(out, dict):
    print(out.get('weights', out.get('url', '')))
else:
    print('')
" 2>/dev/null)

  if [ -z "$weights_url" ]; then
    die "Training succeeded but no weights URL found. Full output: $(echo "$final_result" | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin).get("output",""),indent=2))' 2>/dev/null)"
  fi

  # Save config
  save_lora_config "$char_name" "flux" "$trigger_word" "$weights_url" "$prediction_id" "$img_count"

  info "Flux LoRA training complete!"
  info "Weights: $weights_url"
  info "Config: $char_dir/lora-config.json"
}

# ---------------------------------------------------------------------------
# Train: Kontext LoRA (single image, ~5min, ~$2)
# ---------------------------------------------------------------------------

train_kontext() {
  local char_name="$1"
  local images_dir="$2"
  local trigger_word="$3"
  local char_dir="$CHARACTERS_DIR/$char_name"

  info "=== Kontext LoRA Training ==="
  info "Character: $char_name"
  info "Trigger: $trigger_word"

  # Pick the best single image — prefer *-locked-v*.png > *-locked-*.png > first image
  local source_image=""
  for pattern in "$images_dir"/*-locked-v*.png "$images_dir"/*-locked-*.png "$images_dir"/*-portrait*.png; do
    for f in $pattern; do
      if [ -f "$f" ]; then
        source_image="$f"
        break 2
      fi
    done
  done

  # Fallback: first image in directory
  if [ -z "$source_image" ]; then
    for ext in png jpg jpeg webp; do
      for f in "$images_dir"/*."$ext"; do
        if [ -f "$f" ]; then
          source_image="$f"
          break 2
        fi
      done
    done
  fi

  if [ -z "$source_image" ]; then
    die "No image found in $images_dir for Kontext training"
  fi

  info "Source image: $(basename "$source_image")"

  # Upload image
  info "Uploading source image ..."
  local image_url
  image_url=$(upload_image "$source_image")

  # Create training
  info "Starting Kontext LoRA training on Replicate ..."

  local payload
  payload=$(python3 -c "
import json
print(json.dumps({
    'input': {
        'input_images': '$image_url',
        'trigger_word': '$trigger_word',
        'steps': 1000,
        'lora_rank': 16
    }
}))
")

  local result
  result=$(curl -s -X POST \
    -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://api.replicate.com/v1/models/$KONTEXT_TRAINER/predictions")

  local prediction_id
  prediction_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

  if [ -z "$prediction_id" ]; then
    # Kontext might use trainings API instead
    result=$(curl -s -X POST \
      -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      "https://api.replicate.com/v1/models/$KONTEXT_TRAINER/trainings" 2>/dev/null || echo "")

    prediction_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
  fi

  if [ -z "$prediction_id" ]; then
    die "Failed to start Kontext training. Response: $result"
  fi

  info "Training started: prediction $prediction_id"
  info "Estimated time: ~5 minutes, ~\$2"

  # Poll until done
  local final_result
  final_result=$(poll_prediction "$prediction_id")
  echo ""  # newline after progress

  # Extract weights URL
  local weights_url
  weights_url=$(echo "$final_result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
out = d.get('output', '')
if isinstance(out, str):
    print(out)
elif isinstance(out, dict):
    print(out.get('weights', out.get('url', '')))
elif isinstance(out, list) and len(out) > 0:
    print(out[0] if isinstance(out[0], str) else '')
else:
    print('')
" 2>/dev/null)

  if [ -z "$weights_url" ]; then
    die "Training succeeded but no weights URL found."
  fi

  # Save config
  save_lora_config "$char_name" "kontext" "$trigger_word" "$weights_url" "$prediction_id" "1"

  info "Kontext LoRA training complete!"
  info "Weights: $weights_url"
  info "Config: $char_dir/lora-config.json"
}

# ---------------------------------------------------------------------------
# Save LoRA config to character vault
# ---------------------------------------------------------------------------

save_lora_config() {
  local char_name="$1"
  local method="$2"
  local trigger_word="$3"
  local weights_url="$4"
  local prediction_id="$5"
  local image_count="$6"
  local char_dir="$CHARACTERS_DIR/$char_name"
  local config_file="$char_dir/lora-config.json"

  mkdir -p "$char_dir"

  python3 -c "
import json, os
from datetime import datetime

config_file = '$config_file'
existing = {}
if os.path.exists(config_file):
    with open(config_file) as f:
        existing = json.load(f)

# Preserve history of previous trainings
history = existing.get('history', [])
if existing.get('weights_url'):
    history.append({
        'method': existing.get('method', 'unknown'),
        'weights_url': existing.get('weights_url'),
        'trained_at': existing.get('trained_at', 'unknown'),
        'prediction_id': existing.get('prediction_id', 'unknown')
    })

config = {
    'character': '$char_name',
    'method': '$method',
    'trigger_word': '$trigger_word',
    'weights_url': '$weights_url',
    'prediction_id': '$prediction_id',
    'training_images': int('$image_count'),
    'trained_at': datetime.now().strftime('%Y-%m-%dT%H:%M:%S+0800'),
    'trainer_model': '$FLUX_TRAINER' if '$method' == 'flux' else '$KONTEXT_TRAINER',
    'generator_model': '$FLUX_GENERATOR' if '$method' == 'flux' else '$KONTEXT_GENERATOR',
    'lora_rank': 16,
    'steps': 1000,
    'status': 'active',
    'history': history
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(f'Saved config to {config_file}')
"

  # Log learning
  log_learning "$char_name" "$method" "$prediction_id" "$image_count"
}

# ---------------------------------------------------------------------------
# Log to learnings.jsonl
# ---------------------------------------------------------------------------

log_learning() {
  local char_name="$1"
  local method="$2"
  local prediction_id="$3"
  local image_count="$4"

  local ts
  ts=$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S+0800')

  echo "{\"date\":\"$ts\",\"action\":\"lora_train\",\"character\":\"$char_name\",\"method\":\"$method\",\"prediction_id\":\"$prediction_id\",\"images\":$image_count,\"status\":\"completed\"}" >> "$LEARNINGS_FILE"
}

# ---------------------------------------------------------------------------
# Generate image using trained LoRA
# ---------------------------------------------------------------------------

cmd_generate() {
  local char_name="$1"
  local prompt="$2"
  local char_dir="$CHARACTERS_DIR/$char_name"
  local config_file="$char_dir/lora-config.json"

  if [ ! -f "$config_file" ]; then
    die "No LoRA config found for $char_name. Run training first: lora-train.sh --character $char_name --method kontext"
  fi

  # Read config
  local method trigger_word weights_url generator_model
  method=$(python3 -c "import json; print(json.load(open('$config_file'))['method'])")
  trigger_word=$(python3 -c "import json; print(json.load(open('$config_file'))['trigger_word'])")
  weights_url=$(python3 -c "import json; print(json.load(open('$config_file'))['weights_url'])")
  generator_model=$(python3 -c "import json; print(json.load(open('$config_file'))['generator_model'])")

  info "=== LoRA Image Generation ==="
  info "Character: $char_name"
  info "Method: $method"
  info "Trigger: $trigger_word"
  info "Prompt: $prompt"

  # Ensure trigger word is in the prompt
  if ! echo "$prompt" | grep -q "$trigger_word"; then
    prompt="$trigger_word, $prompt"
    info "Auto-prepended trigger word: $prompt"
  fi

  local payload
  if [ "$method" = "flux" ]; then
    payload=$(python3 -c "
import json
print(json.dumps({
    'input': {
        'prompt': $(python3 -c "import json; print(json.dumps('$prompt'))"),
        'hf_lora': '$weights_url',
        'num_outputs': 1,
        'aspect_ratio': '3:4',
        'output_format': 'png',
        'guidance_scale': 3.5,
        'num_inference_steps': 28
    }
}))
")
  else
    # Kontext — use flux-kontext-pro with LoRA
    payload=$(python3 -c "
import json
print(json.dumps({
    'input': {
        'prompt': $(python3 -c "import json; print(json.dumps('$prompt'))"),
        'lora_weights': '$weights_url',
        'output_format': 'png',
        'aspect_ratio': '3:4'
    }
}))
")
  fi

  local result
  result=$(curl -s -X POST \
    -H "Authorization: Bearer $REPLICATE_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://api.replicate.com/v1/models/$generator_model/predictions")

  local prediction_id
  prediction_id=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

  if [ -z "$prediction_id" ]; then
    die "Failed to start generation. Response: $result"
  fi

  info "Generation started: $prediction_id"

  # Poll
  local final_result
  final_result=$(poll_prediction "$prediction_id")
  echo ""

  # Extract image URL
  local image_url
  image_url=$(echo "$final_result" | python3 -c "
import sys, json
d = json.load(sys.stdin)
out = d.get('output', '')
if isinstance(out, list) and len(out) > 0:
    print(out[0])
elif isinstance(out, str):
    print(out)
else:
    print('')
" 2>/dev/null)

  if [ -z "$image_url" ]; then
    die "Generation succeeded but no image URL found."
  fi

  # Download image
  local ts
  ts=$(timestamp_str)
  local output_file="$char_dir/${char_name}-lora-gen-${ts}.png"
  curl -s -L -o "$output_file" "$image_url"

  info "Generated image saved: $output_file"
  echo "$output_file"
}

# ---------------------------------------------------------------------------
# Status: show LoRA config for a character
# ---------------------------------------------------------------------------

cmd_status() {
  local char_name="$1"
  local config_file="$CHARACTERS_DIR/$char_name/lora-config.json"

  if [ ! -f "$config_file" ]; then
    echo "No LoRA trained for character: $char_name"
    echo "Available characters with LoRA:"
    for d in "$CHARACTERS_DIR"/*/lora-config.json; do
      [ -f "$d" ] && echo "  - $(basename "$(dirname "$d")")"
    done 2>/dev/null
    return 1
  fi

  python3 -c "
import json
with open('$config_file') as f:
    c = json.load(f)
print(f'''=== LoRA Status: {c['character']} ===
Method:      {c['method']}
Trigger:     {c['trigger_word']}
Weights:     {c['weights_url'][:80]}...
Trained:     {c['trained_at']}
Images:      {c['training_images']}
Trainer:     {c['trainer_model']}
Generator:   {c['generator_model']}
Status:      {c['status']}
History:     {len(c.get('history',[]))} previous training(s)''')
"
}

# ---------------------------------------------------------------------------
# List all characters with LoRA
# ---------------------------------------------------------------------------

cmd_list() {
  echo "=== Characters with LoRA Training ==="
  local found=0
  for config in "$CHARACTERS_DIR"/*/lora-config.json; do
    if [ -f "$config" ]; then
      found=1
      python3 -c "
import json
with open('$config') as f:
    c = json.load(f)
print(f\"  {c['character']:<20} {c['method']:<10} {c['trigger_word']:<20} {c['trained_at']}\")
"
    fi
  done 2>/dev/null

  if [ "$found" -eq 0 ]; then
    echo "  No characters trained yet."
    echo ""
    echo "Available characters:"
    for d in "$CHARACTERS_DIR"/*/; do
      [ -d "$d" ] && echo "  - $(basename "$d")"
    done 2>/dev/null
  fi
}

# ---------------------------------------------------------------------------
# Recommend: check decision matrix for what a character needs
# ---------------------------------------------------------------------------

cmd_recommend() {
  local char_name="$1"
  local char_dir="$CHARACTERS_DIR/$char_name"

  if [ ! -d "$char_dir" ]; then
    die "Character directory not found: $char_dir"
  fi

  # Count images
  local img_count=0
  for ext in png jpg jpeg webp; do
    for f in "$char_dir"/*."$ext" "$char_dir"/*."$(echo "$ext" | tr 'a-z' 'A-Z')"; do
      [ -f "$f" ] && img_count=$((img_count + 1))
    done
  done

  # Check for face images (locked portraits)
  local has_face=false
  for f in "$char_dir"/*-locked-v*.png "$char_dir"/*-portrait*.png "$char_dir"/*-locked-*.png; do
    if [ -f "$f" ]; then
      has_face=true
      break
    fi
  done

  echo "=== LoRA Recommendation: $char_name ==="
  echo "Images found: $img_count"
  echo "Has face ref: $has_face"
  echo ""

  if [ "$has_face" = true ]; then
    if [ "$img_count" -ge 10 ]; then
      echo "RECOMMENDATION: Flux LoRA (multi-image)"
      echo "  - Best quality with $img_count training images"
      echo "  - Cost: ~\$2, Time: ~20min"
      echo "  - Run: lora-train.sh --character $char_name --method flux"
    else
      echo "RECOMMENDATION: Kontext LoRA (single image)"
      echo "  - Fast training from best locked image"
      echo "  - Cost: ~\$2, Time: ~5min"
      echo "  - Run: lora-train.sh --character $char_name --method kontext"
    fi
    echo ""
    echo "Per decision matrix: character+face -> ALWAYS train LoRA"
    echo "NanoBanana drifts 20-40% on faces without LoRA lock."
  else
    echo "RECOMMENDATION: No LoRA needed"
    echo "  - No face detected — use multi-ref composite (stitch-refs.py)"
    echo "  - Cost: \$0, Time: instant"
  fi
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<'USAGE'
lora-train.sh — LoRA Training Pipeline for GAIA OS Characters

USAGE:
  lora-train.sh --character <name> --method flux|kontext [OPTIONS]
  lora-train.sh --character <name> --generate "<prompt>"
  lora-train.sh --character <name> --status
  lora-train.sh --character <name> --recommend
  lora-train.sh --list

TRAINING:
  --character <name>    Character name (maps to workspace/data/characters/{name}/)
  --method flux|kontext Training method:
                          flux    = Multi-image, ~20min, ~$2 (best quality, 10-20 images)
                          kontext = Single image, ~5min, ~$2 (fastest, 1 locked image)
  --images <dir>        Override image directory (default: characters/{name}/)
  --trigger-word <word> Trigger word for LoRA (default: TOK_{NAME})

GENERATION:
  --generate "<prompt>" Generate image using trained LoRA
                        Trigger word auto-prepended if missing

INFO:
  --status              Show LoRA training status for character
  --recommend           Analyze character and recommend training method
  --list                List all characters with LoRA training

EXAMPLES:
  # Train Kontext LoRA for Iris (single image, 5min)
  lora-train.sh --character iris --method kontext

  # Train Flux LoRA for Artemis with custom images dir
  lora-train.sh --character artemis --method flux --images ~/training-imgs/

  # Generate using trained LoRA
  lora-train.sh --character iris --generate "TOK_IRIS portrait in cyberpunk city"

  # Check what training a character needs
  lora-train.sh --character iris --recommend
USAGE
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local character=""
  local method=""
  local images_dir=""
  local trigger_word=""
  local action="train"
  local generate_prompt=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --character|-c)
        character="$2"; shift 2 ;;
      --method|-m)
        method="$(to_lower "$2")"; shift 2 ;;
      --images|-i)
        images_dir="$2"; shift 2 ;;
      --trigger-word|-t)
        trigger_word="$2"; shift 2 ;;
      --generate|-g)
        action="generate"; generate_prompt="$2"; shift 2 ;;
      --status|-s)
        action="status"; shift ;;
      --recommend|-r)
        action="recommend"; shift ;;
      --list|-l)
        action="list"; shift ;;
      --help|-h)
        usage; exit 0 ;;
      *)
        die "Unknown option: $1. Use --help for usage." ;;
    esac
  done

  # List doesn't need a character
  if [ "$action" = "list" ]; then
    cmd_list
    return 0
  fi

  # All other actions need a character
  if [ -z "$character" ]; then
    usage
    die "Missing required: --character <name>"
  fi

  character="$(to_lower "$character")"

  case "$action" in
    status)
      cmd_status "$character"
      ;;
    recommend)
      cmd_recommend "$character"
      ;;
    generate)
      load_replicate_token
      if [ -z "$generate_prompt" ]; then
        die "Missing prompt. Use: --generate \"your prompt here\""
      fi
      cmd_generate "$character" "$generate_prompt"
      ;;
    train)
      if [ -z "$method" ]; then
        die "Missing required: --method flux|kontext"
      fi
      if [ "$method" != "flux" ] && [ "$method" != "kontext" ]; then
        die "Invalid method: $method. Use flux or kontext."
      fi

      load_replicate_token

      # Default images dir
      if [ -z "$images_dir" ]; then
        images_dir="$CHARACTERS_DIR/$character"
      fi
      if [ ! -d "$images_dir" ]; then
        die "Images directory not found: $images_dir"
      fi

      # Default trigger word: TOK_{NAME} (uppercase)
      if [ -z "$trigger_word" ]; then
        trigger_word="TOK_$(echo "$character" | tr 'a-z' 'A-Z')"
      fi

      info "LoRA Training Pipeline"
      info "Character: $character"
      info "Method: $method"
      info "Images: $images_dir"
      info "Trigger: $trigger_word"
      echo ""

      case "$method" in
        flux)    train_flux "$character" "$images_dir" "$trigger_word" ;;
        kontext) train_kontext "$character" "$images_dir" "$trigger_word" ;;
      esac

      echo ""
      info "Done! Use --generate to create images with the trained LoRA:"
      info "  lora-train.sh --character $character --generate \"$trigger_word portrait in studio lighting\""
      ;;
  esac
}

# Run
if [ $# -eq 0 ]; then
  usage
  exit 0
fi

main "$@"
