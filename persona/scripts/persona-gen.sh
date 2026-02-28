#!/usr/bin/env bash
# persona-gen.sh — AI Avatar / Virtual Influencer Generation Pipeline
# Part of GAIA CORP-OS Persona Skill
# macOS Bash 3.2 compatible: NO declare -A, NO timeout, NO ${var,,}
#
# Subcommands:
#   create   — Create a new AI persona (character sheet + profile)
#   selfie   — Generate a character-consistent image in a scene
#   post     — Post an image + caption via WhatsApp
#   animate  — Animate persona in a scene via Kling I2V
#   voice    — Generate speech via ElevenLabs TTS
#   produce  — Full pipeline: voice + animate + assemble
#   list     — List all personas
#   show     — Show persona details
#
# Usage:
#   bash persona-gen.sh create --name Maya --brand gaia-eats [options]
#   bash persona-gen.sh selfie Maya "cooking in a cozy kitchen" [--mood cozy] [--brand gaia-eats]
#   bash persona-gen.sh post Maya "Having fun cooking!" --image /path/to/selfie.png [--to +60126169979]
#   bash persona-gen.sh animate --persona Maya --scene "cooking in kitchen" [options]
#   bash persona-gen.sh voice --persona Maya --text "Hello!" [options]
#   bash persona-gen.sh produce --persona Maya --script scenes.txt --type ugc [options]
#   bash persona-gen.sh list
#   bash persona-gen.sh show Maya

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants & Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PERSONAS_DIR="$SKILL_DIR/personas"
BRANDS_DIR="$HOME/.openclaw/brands"
DATA_DIR="$HOME/.openclaw/workspace/data"
VIDEOS_DIR="$DATA_DIR/videos"
AUDIO_DIR="$DATA_DIR/audio"
CHARACTERS_DIR="$DATA_DIR/characters"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
LOG_FILE="$HOME/.openclaw/logs/persona.log"

NANOBANANA="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
KLING_VIDEO="$HOME/.openclaw/skills/video-gen/scripts/video-gen.sh"
KLING_ENV="$HOME/.openclaw/workspace/ops/.kling-env"

ELEVENLABS_BASE="https://api.elevenlabs.io/v1"

# ---------------------------------------------------------------------------
# Load secrets
# ---------------------------------------------------------------------------

[ -z "${GEMINI_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/gemini.env" ] && \
  export "$(grep '^GEMINI_API_KEY=' "$HOME/.openclaw/secrets/gemini.env" | head -1)"

[ -z "${ELEVENLABS_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/elevenlabs.env" ] && \
  export "$(grep '^ELEVENLABS_API_KEY=' "$HOME/.openclaw/secrets/elevenlabs.env" | head -1)"

[ -f "$KLING_ENV" ] && source "$KLING_ENV"

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

to_lower() {
  echo "$1" | tr 'A-Z' 'a-z'
}

timestamp_str() {
  date '+%Y%m%d_%H%M%S'
}

today_str() {
  date '+%Y-%m-%d'
}

# Read a JSON field using python3 (jq-free)
json_field() {
  local file="$1"
  local field="$2"
  python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    d = json.load(f)
keys = sys.argv[2].split('.')
val = d
for k in keys:
    if isinstance(val, dict):
        val = val.get(k, '')
    else:
        val = ''
        break
if isinstance(val, list):
    print(json.dumps(val))
elif val is None:
    print('')
else:
    print(val)
" "$file" "$field" 2>/dev/null || echo ""
}

# Update a JSON field using python3
json_set() {
  local file="$1"
  local field="$2"
  local value="$3"
  local value_type="${4:-string}"  # string, int, list, null
  python3 - "$file" "$field" "$value" "$value_type" <<'PYEOF'
import json, sys

fpath = sys.argv[1]
field = sys.argv[2]
value = sys.argv[3]
vtype = sys.argv[4]

with open(fpath, 'r') as f:
    d = json.load(f)

if vtype == "int":
    d[field] = int(value)
elif vtype == "null":
    d[field] = None
elif vtype == "list":
    d[field] = json.loads(value)
elif vtype == "append":
    if field not in d or not isinstance(d[field], list):
        d[field] = []
    d[field].append(value)
else:
    d[field] = value

with open(fpath, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
PYEOF
}

# Post to communication room
post_to_room() {
  local room="$1"
  local msg="$2"
  local room_file="$ROOMS_DIR/${room}.jsonl"
  if [ -d "$ROOMS_DIR" ]; then
    printf '{"ts":%s000,"agent":"persona","room":"%s","msg":"%s"}\n' \
      "$(date +%s)" "$room" "$(echo "$msg" | sed 's/"/\\"/g')" >> "$room_file"
  fi
}

# Load brand DNA for visual enrichment
load_brand_dna() {
  local brand_slug="$1"
  local dna_path="$BRANDS_DIR/${brand_slug}/DNA.json"
  if [ -f "$dna_path" ]; then
    BRAND_DISPLAY=$(json_field "$dna_path" "display_name")
    BRAND_STYLE=$(json_field "$dna_path" "visual.style")
    BRAND_LIGHTING=$(json_field "$dna_path" "visual.lighting_default")
    BRAND_PHOTO=$(json_field "$dna_path" "visual.photography")
    BRAND_PRIMARY=$(json_field "$dna_path" "visual.colors.primary")
    BRAND_SECONDARY=$(json_field "$dna_path" "visual.colors.secondary")
    BRAND_BG=$(json_field "$dna_path" "visual.colors.background")
    BRAND_TONE=$(json_field "$dna_path" "voice.tone")
    log "INFO" "Loaded Brand DNA: $brand_slug ($BRAND_DISPLAY)"
  else
    BRAND_DISPLAY="$brand_slug"
    BRAND_STYLE="warm, natural, appetizing, accessible"
    BRAND_LIGHTING="warm natural light, soft shadows"
    BRAND_PHOTO="magazine editorial, lifestyle"
    BRAND_PRIMARY="#8FBC8F"
    BRAND_SECONDARY="#DAA520"
    BRAND_BG="#FFFDD0"
    BRAND_TONE="Warm, friendly, proudly Malaysian"
    warn "No Brand DNA at $dna_path, using defaults"
  fi
}

# Build brand visual enrichment string
brand_visual_dna() {
  echo "Brand: ${BRAND_DISPLAY}. Style: ${BRAND_STYLE}. Lighting: ${BRAND_LIGHTING}. Colors: primary ${BRAND_PRIMARY}, secondary ${BRAND_SECONDARY}, background ${BRAND_BG}. Photography: ${BRAND_PHOTO}."
}

# Resolve persona profile path
persona_path() {
  local name="$1"
  echo "$PERSONAS_DIR/${name}.json"
}

# Check persona exists
require_persona() {
  local name="$1"
  local ppath
  ppath=$(persona_path "$name")
  if [ ! -f "$ppath" ]; then
    die "Persona '$name' not found. Run: persona-gen.sh create --name $name --brand <brand>"
  fi
  echo "$ppath"
}

# Print gamified persona card
print_persona_card() {
  local ppath="$1"
  local name brand style vibe refs voice_id videos desc

  name=$(json_field "$ppath" "name")
  brand=$(json_field "$ppath" "brand")
  style=$(json_field "$ppath" "style")
  vibe=$(json_field "$ppath" "vibe")
  voice_id=$(json_field "$ppath" "voice_id")
  videos=$(json_field "$ppath" "videos_generated")
  desc=$(json_field "$ppath" "description")

  # Count reference images
  local ref_count
  ref_count=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
print(len(d.get('reference_images', [])))
" "$ppath" 2>/dev/null || echo "0")

  local voice_status="Not configured"
  if [ -n "$voice_id" ] && [ "$voice_id" != "null" ] && [ "$voice_id" != "None" ]; then
    voice_status="$voice_id"
  fi

  # Capitalize first letter (bash 3.2 safe)
  local style_cap vibe_cap
  style_cap=$(echo "$style" | python3 -c "import sys; s=sys.stdin.read().strip(); print(s[0].upper()+s[1:] if s else '')" 2>/dev/null || echo "$style")
  vibe_cap=$(echo "$vibe" | python3 -c "import sys; s=sys.stdin.read().strip(); print(s[0].upper()+s[1:] if s else '')" 2>/dev/null || echo "$vibe")

  # Brand display name
  local brand_display
  brand_display=$(echo "$brand" | tr '-' ' ' | python3 -c "import sys; print(sys.stdin.read().strip().title())" 2>/dev/null || echo "$brand")

  local pad=36
  echo ""
  printf '%0.s=' $(python3 -c "exec('for i in range($pad+4): print(1, end=\"\")')") ; echo ""
  printf '  PERSONA: %-*s\n' $((pad - 10)) "$name"
  printf '  Brand: %-*s\n' $((pad - 8)) "$brand_display"
  printf '  Style: %s | Vibe: %-*s\n' "$style_cap" $((pad - 18 - ${#style_cap})) "$vibe_cap"
  printf '  References: %d character sheet(s)\n' "$ref_count"
  printf '  Voice: %-*s\n' $((pad - 8)) "$voice_status"
  printf '  Videos: %-*s\n' $((pad - 9)) "$videos"
  printf '%0.s=' $(python3 -c "exec('for i in range($pad+4): print(1, end=\"\")')") ; echo ""

  # Description preview (first 80 chars)
  if [ -n "$desc" ]; then
    local short_desc
    short_desc=$(echo "$desc" | python3 -c "import sys; s=sys.stdin.read().strip(); print(s[:80]+'...' if len(s)>80 else s)" 2>/dev/null || echo "$desc")
    echo "  $short_desc"
  fi
  echo ""
}

# ---------------------------------------------------------------------------
# Command: create
# ---------------------------------------------------------------------------

cmd_create() {
  local name="" brand="" age="28" gender="female" ethnicity="malay"
  local style="casual" vibe="friendly" extra_desc=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)      name="$2";       shift 2 ;;
      --brand)     brand="$2";      shift 2 ;;
      --age)       age="$2";        shift 2 ;;
      --gender)    gender="$2";     shift 2 ;;
      --ethnicity) ethnicity="$2";  shift 2 ;;
      --style)     style="$2";      shift 2 ;;
      --vibe)      vibe="$2";       shift 2 ;;
      --desc)      extra_desc="$2"; shift 2 ;;
      *) die "create: unknown option: $1" ;;
    esac
  done

  [ -z "$name" ] && die "create: --name is required"
  [ -z "$brand" ] && die "create: --brand is required"

  local ppath
  ppath=$(persona_path "$name")
  if [ -f "$ppath" ]; then
    die "Persona '$name' already exists at $ppath. Delete it first or use a different name."
  fi

  echo "Creating persona: $name"
  log "INFO" "Creating persona: $name (brand=$brand, age=$age, gender=$gender, ethnicity=$ethnicity, style=$style, vibe=$vibe)"

  # Load brand DNA
  load_brand_dna "$brand"

  # Build wardrobe based on style + brand
  local wardrobe
  case "$(to_lower "$style")" in
    casual)
      wardrobe="relaxed everyday wear, soft cotton fabrics, warm earth tones, ${BRAND_PRIMARY} accent pieces"
      ;;
    professional)
      wardrobe="smart casual business wear, clean lines, neutral palette with ${BRAND_PRIMARY} accents"
      ;;
    streetwear)
      wardrobe="modern streetwear, oversized fits, graphic elements, bold colors with ${BRAND_PRIMARY} highlights"
      ;;
    apron)
      wardrobe="sage green apron over cream blouse, cooking-ready, sleeves rolled up"
      ;;
    *)
      wardrobe="$style"
      ;;
  esac

  # Build personality traits from vibe
  local personality
  case "$(to_lower "$vibe")" in
    friendly)
      personality="warm smile, approachable expression, open body language, inviting"
      ;;
    energetic)
      personality="bright eyes, dynamic pose, enthusiastic expression, lively"
      ;;
    calm)
      personality="serene expression, gentle posture, peaceful demeanor, grounded"
      ;;
    quirky)
      personality="playful expression, slight head tilt, mischievous smile, unique"
      ;;
    *)
      personality="$vibe"
      ;;
  esac

  # Build full character description
  local description="${age}-year-old ${ethnicity} ${gender}, ${personality}. Wardrobe: ${wardrobe}."
  if [ -n "$extra_desc" ]; then
    description="${description} ${extra_desc}."
  fi

  # Build detailed character prompt for NanoBanana
  local character_prompt
  character_prompt=$(python3 -c "
import sys
name = sys.argv[1]
desc = sys.argv[2]
brand_visual = sys.argv[3]
prompt = (
    'Character sheet for a virtual influencer named ' + name + '. '
    + desc + ' '
    'Show front view, 3/4 view, and side profile on clean white background. '
    'Semi-realistic style, consistent facial features across all angles. '
    'Maintain exact proportions, same hairstyle and outfit in every view. '
    + brand_visual + ' '
    'Professional character reference sheet, suitable for animation and video production. '
    '4K resolution, sharp details, studio lighting.'
)
print(prompt)
" "$name" "$description" "$(brand_visual_dna)")

  echo "  Description: $description"
  echo "  Brand: $brand ($BRAND_DISPLAY)"
  echo "  Generating character sheet via NanoBanana Pro..."

  # Call NanoBanana to generate character sheet
  local ts
  ts=$(timestamp_str)
  local char_dir="${CHARACTERS_DIR}/${brand}"
  mkdir -p "$char_dir"
  local char_image="${char_dir}/${name}_${ts}_charsheet.png"

  local gen_result=""
  if [ -x "$NANOBANANA" ] || [ -f "$NANOBANANA" ]; then
    gen_result=$(bash "$NANOBANANA" generate \
      --brand "$brand" \
      --use-case character \
      --prompt "$character_prompt" \
      --size 4K \
      --ratio 1:1 \
      --model pro \
      --raw 2>&1) || true

    # Extract output path from nanobanana output (last line that looks like a file path)
    local generated_path
    generated_path=$(echo "$gen_result" | python3 -c "
import sys
lines = sys.stdin.read().strip().split('\n')
for line in reversed(lines):
    line = line.strip()
    if line.endswith('.png') or line.endswith('.jpg'):
        print(line)
        break
else:
    print('')
" 2>/dev/null || echo "")

    if [ -n "$generated_path" ] && [ -f "$generated_path" ]; then
      char_image="$generated_path"
      echo "  Character sheet saved: $char_image"
    else
      warn "NanoBanana generation may have failed. Output: $(echo "$gen_result" | tail -3)"
      echo "  Character sheet path (pending): $char_image"
    fi
  else
    warn "NanoBanana script not found at $NANOBANANA"
    echo "  Skipping character sheet generation. Add reference images manually."
    char_image=""
  fi

  # Build reference images array
  local ref_images="[]"
  if [ -n "$char_image" ] && [ -f "$char_image" ]; then
    ref_images=$(python3 -c "import json; print(json.dumps([\"$char_image\"]))")
  fi

  # Save persona profile
  mkdir -p "$PERSONAS_DIR"
  python3 - "$ppath" "$name" "$brand" "$description" "$character_prompt" \
    "$ref_images" "$style" "$vibe" "$wardrobe" <<'PYEOF'
import json, sys
from datetime import date

ppath = sys.argv[1]
profile = {
    "name": sys.argv[2],
    "brand": sys.argv[3],
    "created": str(date.today()),
    "description": sys.argv[4],
    "character_prompt": sys.argv[5],
    "reference_images": json.loads(sys.argv[6]),
    "voice_id": None,
    "style": sys.argv[7],
    "vibe": sys.argv[8],
    "wardrobe": sys.argv[9],
    "videos_generated": 0,
    "audio_generated": 0
}

with open(ppath, 'w') as f:
    json.dump(profile, f, indent=2, ensure_ascii=False)
    f.write('\n')
PYEOF

  log "INFO" "Persona profile saved: $ppath"

  # Post to creative room
  post_to_room "creative" "New persona created: $name for $brand. Style: $style, Vibe: $vibe."

  # Print card
  print_persona_card "$ppath"

  echo "Persona '$name' created successfully."
  echo "Profile: $ppath"
}

# ---------------------------------------------------------------------------
# Command: animate
# ---------------------------------------------------------------------------

cmd_animate() {
  local persona_name="" scene="" duration="5" ratio="9:16" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --persona)   persona_name="$2"; shift 2 ;;
      --scene)     scene="$2";        shift 2 ;;
      --duration)  duration="$2";     shift 2 ;;
      --ratio)     ratio="$2";       shift 2 ;;
      --output)    output="$2";       shift 2 ;;
      *) die "animate: unknown option: $1" ;;
    esac
  done

  [ -z "$persona_name" ] && die "animate: --persona is required"
  [ -z "$scene" ] && die "animate: --scene is required"

  local ppath
  ppath=$(require_persona "$persona_name")

  local brand description char_prompt
  brand=$(json_field "$ppath" "brand")
  description=$(json_field "$ppath" "description")
  char_prompt=$(json_field "$ppath" "character_prompt")

  # Get first reference image
  local ref_image
  ref_image=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
refs = d.get('reference_images', [])
# Find first existing file
import os
for r in refs:
    if os.path.isfile(r):
        print(r)
        break
else:
    print('')
" "$ppath" 2>/dev/null || echo "")

  if [ -z "$ref_image" ]; then
    die "animate: No reference image found for persona '$persona_name'. Generate one first with 'create' command."
  fi

  # Load brand DNA
  load_brand_dna "$brand"

  # Build scene prompt: character description + scene + brand visual DNA
  local scene_prompt
  scene_prompt=$(python3 -c "
import sys
desc = sys.argv[1]
scene = sys.argv[2]
brand_vis = sys.argv[3]
name = sys.argv[4]
prompt = (
    name + ': ' + desc + ' '
    'Scene: ' + scene + '. '
    'Maintain character identity and proportions throughout. '
    'Natural movement, realistic motion, cinematic quality. '
    + brand_vis
)
print(prompt)
" "$description" "$scene" "$(brand_visual_dna)" "$persona_name")

  echo "Animating persona: $persona_name"
  echo "  Scene: $scene"
  echo "  Duration: ${duration}s"
  echo "  Ratio: $ratio"
  echo "  Reference: $ref_image"
  log "INFO" "Animating $persona_name: scene='$scene' duration=$duration ratio=$ratio"

  # Set output path
  if [ -z "$output" ]; then
    local ts
    ts=$(timestamp_str)
    local vid_dir="${VIDEOS_DIR}/${brand}"
    mkdir -p "$vid_dir"
    output="${vid_dir}/${persona_name}_${ts}.mp4"
  fi

  # For Kling I2V, we need the image as a URL or local path
  # Kling API expects a URL, so we need to check if it's a local file
  # If local, we'll encode it as base64 data URI or upload
  # For now, pass the local path — kling-video.sh handles URL requirement
  local image_arg="$ref_image"

  # Check if kling-video.sh exists
  if [ ! -f "$KLING_VIDEO" ]; then
    die "animate: Kling video script not found at $KLING_VIDEO"
  fi

  # Convert local image to base64 data URI for Kling API
  if [ -f "$ref_image" ]; then
    image_arg=$(python3 -c "
import base64, sys, os
fpath = sys.argv[1]
with open(fpath, 'rb') as f:
    data = base64.b64encode(f.read()).decode('utf-8')
ext = os.path.splitext(fpath)[1].lower()
mime = 'image/png' if ext == '.png' else 'image/jpeg'
print(f'data:{mime};base64,{data}')
" "$ref_image" 2>/dev/null) || image_arg="$ref_image"
  fi

  echo "  Calling Kling AI image2video..."

  # Call Kling image2video
  local kling_output
  kling_output=$(bash "$KLING_VIDEO" image2video \
    "$scene_prompt" \
    --image "$image_arg" \
    --duration "$duration" \
    --output "$output" 2>&1) || true

  echo "$kling_output"

  # Check if video was saved
  if [ -f "$output" ]; then
    local file_size
    file_size=$(python3 -c "import os; print(os.path.getsize('$output'))" 2>/dev/null || echo "0")

    if [ "$file_size" -gt 1000 ]; then
      echo "  Video saved: $output ($file_size bytes)"
      log "INFO" "Video saved: $output ($file_size bytes)"

      # Increment videos_generated count
      local current_count
      current_count=$(json_field "$ppath" "videos_generated")
      current_count=${current_count:-0}
      json_set "$ppath" "videos_generated" "$((current_count + 1))" "int"

      # Post to creative room
      post_to_room "creative" "Persona $persona_name animated: $scene. Video: $output"

      echo "  Done."
    else
      warn "Video file is suspiciously small ($file_size bytes). Check Kling status."
    fi
  else
    # Extract task ID from output for manual status checking
    local task_id
    task_id=$(echo "$kling_output" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'Task created: (\S+)', text)
if m:
    print(m.group(1))
else:
    print('')
" 2>/dev/null || echo "")

    if [ -n "$task_id" ]; then
      echo "  Kling task submitted: $task_id"
      echo "  Check status: bash $KLING_VIDEO status $task_id"
      log "INFO" "Kling task submitted for $persona_name: $task_id"
    else
      warn "Could not determine video generation status."
      log "WARN" "Animate failed for $persona_name. Output: $(echo "$kling_output" | tail -5)"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Command: voice
# ---------------------------------------------------------------------------

cmd_voice() {
  local persona_name="" text="" voice_id="" model="eleven_multilingual_v2"
  local clone_mode="false" sample_path="" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --persona)   persona_name="$2"; shift 2 ;;
      --text)      text="$2";         shift 2 ;;
      --voice-id)  voice_id="$2";     shift 2 ;;
      --model)     model="$2";        shift 2 ;;
      --clone)     clone_mode="true"; shift ;;
      --sample)    sample_path="$2";  shift 2 ;;
      --output)    output="$2";       shift 2 ;;
      *) die "voice: unknown option: $1" ;;
    esac
  done

  [ -z "$persona_name" ] && die "voice: --persona is required"

  local ppath
  ppath=$(require_persona "$persona_name")

  local brand
  brand=$(json_field "$ppath" "brand")

  # Check ElevenLabs API key
  if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
    die "voice: ELEVENLABS_API_KEY is not set. Export it or add to ~/.openclaw/secrets/elevenlabs.env"
  fi

  # Handle voice cloning
  if [ "$clone_mode" = "true" ]; then
    cmd_voice_clone "$ppath" "$persona_name" "$sample_path"
    return
  fi

  # Need text for TTS
  [ -z "$text" ] && die "voice: --text is required (or use --clone to clone a voice)"

  # Resolve voice ID: from flag, then from profile, then fail
  if [ -z "$voice_id" ]; then
    voice_id=$(json_field "$ppath" "voice_id")
  fi

  if [ -z "$voice_id" ] || [ "$voice_id" = "null" ] || [ "$voice_id" = "None" ]; then
    echo "No voice configured for persona '$persona_name'."
    echo ""
    echo "Options:"
    echo "  1. Set a voice ID: persona-gen.sh voice --persona $persona_name --voice-id <id> --text <text>"
    echo "  2. Clone a voice:  persona-gen.sh voice --persona $persona_name --clone --sample <audio_file>"
    echo "  3. List voices:    curl -s -H 'xi-api-key: \$ELEVENLABS_API_KEY' $ELEVENLABS_BASE/voices | python3 -m json.tool"
    echo ""

    # List available voices as a convenience
    echo "Available ElevenLabs voices:"
    local voices_resp
    voices_resp=$(curl -s -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
      "${ELEVENLABS_BASE}/voices" 2>/dev/null) || true

    if [ -n "$voices_resp" ]; then
      echo "$voices_resp" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    voices = d.get('voices', [])
    for v in voices[:20]:
        labels = v.get('labels', {})
        accent = labels.get('accent', '')
        gender = labels.get('gender', '')
        desc = labels.get('description', '')
        info = ', '.join(filter(None, [gender, accent, desc]))
        print(f\"  {v['voice_id'][:12]}...  {v['name']:<20} ({info})\")
    if len(voices) > 20:
        print(f'  ... and {len(voices)-20} more')
except:
    print('  (Could not parse voice list)')
" 2>/dev/null || echo "  (Could not fetch voice list)"
    fi
    return 1
  fi

  # Set output path
  if [ -z "$output" ]; then
    local ts
    ts=$(timestamp_str)
    local aud_dir="${AUDIO_DIR}/${brand}"
    mkdir -p "$aud_dir"
    output="${aud_dir}/${persona_name}_${ts}.mp3"
  fi

  echo "Generating voice for: $persona_name"
  echo "  Voice ID: $voice_id"
  echo "  Model: $model"
  echo "  Text: $(echo "$text" | head -c 80)..."
  log "INFO" "Voice TTS: persona=$persona_name voice=$voice_id model=$model text_len=${#text}"

  mkdir -p "$(dirname "$output")"

  # Call ElevenLabs TTS API
  local http_code
  http_code=$(curl -s -w '%{http_code}' \
    -o "$output" \
    "${ELEVENLABS_BASE}/text-to-speech/${voice_id}" \
    -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, sys
print(json.dumps({
    'text': sys.argv[1],
    'model_id': sys.argv[2],
    'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.75,
        'style': 0.3,
        'use_speaker_boost': True
    }
}))
" "$text" "$model")" 2>/dev/null) || http_code="000"

  if [ "$http_code" = "200" ] && [ -f "$output" ]; then
    local file_size
    file_size=$(python3 -c "import os; print(os.path.getsize('$output'))" 2>/dev/null || echo "0")
    echo "  Audio saved: $output ($file_size bytes)"
    log "INFO" "Audio saved: $output ($file_size bytes)"

    # Update voice_id in profile if it was provided via flag
    local stored_voice
    stored_voice=$(json_field "$ppath" "voice_id")
    if [ "$stored_voice" != "$voice_id" ]; then
      json_set "$ppath" "voice_id" "$voice_id" "string"
      echo "  Voice ID saved to persona profile."
    fi

    # Increment audio count
    local current_count
    current_count=$(json_field "$ppath" "audio_generated")
    current_count=${current_count:-0}
    json_set "$ppath" "audio_generated" "$((current_count + 1))" "int"

    echo "  Done."
  else
    # Read error from output file (ElevenLabs returns JSON errors)
    local err_body=""
    if [ -f "$output" ]; then
      err_body=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    print(d.get('detail', {}).get('message', str(d)))
except:
    print('Unknown error')
" "$output" 2>/dev/null || echo "Unknown error")
      rm -f "$output"
    fi
    die "voice: ElevenLabs API returned HTTP $http_code. $err_body"
  fi
}

# Voice cloning sub-function
cmd_voice_clone() {
  local ppath="$1"
  local persona_name="$2"
  local sample_path="$3"

  [ -z "$sample_path" ] && die "voice --clone: --sample <audio_file> is required"
  [ ! -f "$sample_path" ] && die "voice --clone: Sample file not found: $sample_path"

  echo "Cloning voice for persona: $persona_name"
  echo "  Sample: $sample_path"
  log "INFO" "Voice clone: persona=$persona_name sample=$sample_path"

  # ElevenLabs voice clone (Instant Voice Cloning)
  local response
  response=$(curl -s \
    "${ELEVENLABS_BASE}/voices/add" \
    -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
    -F "name=${persona_name}" \
    -F "description=AI persona voice for ${persona_name}" \
    -F "files=@${sample_path}" \
    -F "labels={\"persona\":\"${persona_name}\"}" 2>/dev/null) || die "voice --clone: curl failed"

  local new_voice_id
  new_voice_id=$(echo "$response" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    vid = d.get('voice_id', '')
    if vid:
        print(vid)
    else:
        detail = d.get('detail', {})
        msg = detail.get('message', str(d)) if isinstance(detail, dict) else str(detail)
        print('ERROR:' + msg)
except Exception as e:
    print('ERROR:' + str(e))
" 2>/dev/null || echo "")

  case "$new_voice_id" in
    ERROR:*)
      die "voice --clone: ${new_voice_id#ERROR:}"
      ;;
    "")
      die "voice --clone: Failed to parse response from ElevenLabs"
      ;;
    *)
      echo "  Voice cloned successfully!"
      echo "  Voice ID: $new_voice_id"
      json_set "$ppath" "voice_id" "$new_voice_id" "string"
      log "INFO" "Voice cloned for $persona_name: $new_voice_id"
      echo "  Saved to persona profile."
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Command: produce
# ---------------------------------------------------------------------------

cmd_produce() {
  local persona_name="" script_file="" output_type="ugc" brand_override=""
  local mood="" output_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --persona)  persona_name="$2";   shift 2 ;;
      --script)   script_file="$2";    shift 2 ;;
      --type)     output_type="$2";    shift 2 ;;
      --brand)    brand_override="$2"; shift 2 ;;
      --mood)     mood="$2";           shift 2 ;;
      --output)   output_dir="$2";     shift 2 ;;
      *) die "produce: unknown option: $1" ;;
    esac
  done

  [ -z "$persona_name" ] && die "produce: --persona is required"
  [ -z "$script_file" ] && die "produce: --script is required"
  [ ! -f "$script_file" ] && die "produce: Script file not found: $script_file"

  local ppath
  ppath=$(require_persona "$persona_name")

  local brand
  brand=$(json_field "$ppath" "brand")
  [ -n "$brand_override" ] && brand="$brand_override"

  local description voice_id
  description=$(json_field "$ppath" "description")
  voice_id=$(json_field "$ppath" "voice_id")

  # Load brand DNA
  load_brand_dna "$brand"

  # Set output directory
  if [ -z "$output_dir" ]; then
    local ts
    ts=$(timestamp_str)
    output_dir="${VIDEOS_DIR}/${brand}/${persona_name}_production_${ts}"
  fi
  mkdir -p "$output_dir"

  echo "========================================="
  echo "  PERSONA PRODUCTION PIPELINE"
  echo "  Persona: $persona_name"
  echo "  Brand: $brand ($BRAND_DISPLAY)"
  echo "  Script: $script_file"
  echo "  Type: $output_type"
  echo "  Output: $output_dir"
  echo "========================================="
  echo ""
  log "INFO" "Production started: persona=$persona_name script=$script_file type=$output_type"

  # Parse script file into scenes
  local scenes_json
  scenes_json=$(python3 - "$script_file" <<'PYEOF'
import sys, json, re

script_path = sys.argv[1]
scenes = []
current = {}

with open(script_path, 'r') as f:
    for line in f:
        line = line.strip()
        # Skip comments and blank lines
        if not line or line.startswith('#'):
            continue

        if line.startswith('SCENE:'):
            # Save previous scene if exists
            if current.get('scene'):
                scenes.append(current)
            current = {
                'scene': line[6:].strip(),
                'voice': '',
                'duration': 5,
                'type': 'ugc'
            }
        elif line.startswith('VOICE:'):
            current['voice'] = line[6:].strip()
        elif line.startswith('DURATION:'):
            try:
                current['duration'] = int(line[9:].strip())
            except:
                current['duration'] = 5
        elif line.startswith('TYPE:'):
            current['type'] = line[5:].strip()

    # Don't forget last scene
    if current.get('scene'):
        scenes.append(current)

print(json.dumps(scenes))
PYEOF
)

  local scene_count
  scene_count=$(echo "$scenes_json" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

  if [ "$scene_count" -eq 0 ]; then
    die "produce: No scenes found in script file. Check format (SCENE:/VOICE:/DURATION:/TYPE:)"
  fi

  echo "Found $scene_count scene(s) in script."
  echo ""

  # Process each scene
  local scene_idx=0
  local clip_paths=""
  local audio_paths=""

  while [ "$scene_idx" -lt "$scene_count" ]; do
    local scene_num=$((scene_idx + 1))
    echo "--- Scene $scene_num of $scene_count ---"

    # Extract scene data
    local scene_data
    scene_data=$(echo "$scenes_json" | python3 -c "
import json, sys
scenes = json.load(sys.stdin)
idx = int(sys.argv[1])
s = scenes[idx]
print(s.get('scene', ''))
print(s.get('voice', ''))
print(str(s.get('duration', 5)))
print(s.get('type', 'ugc'))
" "$scene_idx" 2>/dev/null)

    local scene_desc voice_text scene_duration scene_type
    scene_desc=$(echo "$scene_data" | python3 -c "import sys; lines=sys.stdin.read().strip().split('\n'); print(lines[0] if len(lines)>0 else '')")
    voice_text=$(echo "$scene_data" | python3 -c "import sys; lines=sys.stdin.read().strip().split('\n'); print(lines[1] if len(lines)>1 else '')")
    scene_duration=$(echo "$scene_data" | python3 -c "import sys; lines=sys.stdin.read().strip().split('\n'); print(lines[2] if len(lines)>2 else '5')")
    scene_type=$(echo "$scene_data" | python3 -c "import sys; lines=sys.stdin.read().strip().split('\n'); print(lines[3] if len(lines)>3 else 'ugc')")

    echo "  Scene: $scene_desc"
    echo "  Duration: ${scene_duration}s | Type: $scene_type"

    local scene_audio=""
    local scene_video=""

    # Step A: Generate voice audio (if VOICE line exists)
    if [ -n "$voice_text" ] && [ "$voice_text" != "" ]; then
      if [ -n "$voice_id" ] && [ "$voice_id" != "null" ] && [ "$voice_id" != "None" ]; then
        echo "  Generating voice..."
        local audio_file="${output_dir}/scene_${scene_num}_audio.mp3"

        local audio_http
        audio_http=$(curl -s -w '%{http_code}' \
          -o "$audio_file" \
          "${ELEVENLABS_BASE}/text-to-speech/${voice_id}" \
          -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
          -H "Content-Type: application/json" \
          -d "$(python3 -c "
import json, sys
print(json.dumps({
    'text': sys.argv[1],
    'model_id': 'eleven_multilingual_v2',
    'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.75,
        'style': 0.3,
        'use_speaker_boost': True
    }
}))
" "$voice_text")" 2>/dev/null) || audio_http="000"

        if [ "$audio_http" = "200" ] && [ -f "$audio_file" ]; then
          local asize
          asize=$(python3 -c "import os; print(os.path.getsize('$audio_file'))" 2>/dev/null || echo "0")
          if [ "$asize" -gt 100 ]; then
            echo "  Audio saved: scene_${scene_num}_audio.mp3 ($asize bytes)"
            scene_audio="$audio_file"
          else
            warn "Audio file too small, skipping voice for scene $scene_num"
            rm -f "$audio_file"
          fi
        else
          warn "Voice generation failed for scene $scene_num (HTTP $audio_http)"
          rm -f "$audio_file" 2>/dev/null
        fi
      else
        warn "No voice_id configured, skipping voice for scene $scene_num"
      fi
    fi

    # Step B: Generate video via Kling I2V
    echo "  Generating video via Kling I2V..."
    local video_file="${output_dir}/scene_${scene_num}_video.mp4"

    # Build animate command inline (avoid re-entrant script call for production speed)
    local ref_image
    ref_image=$(python3 -c "
import json, sys, os
with open(sys.argv[1]) as f:
    d = json.load(f)
refs = d.get('reference_images', [])
for r in refs:
    if os.path.isfile(r):
        print(r)
        break
else:
    print('')
" "$ppath" 2>/dev/null || echo "")

    if [ -n "$ref_image" ] && [ -f "$ref_image" ]; then
      # Build scene prompt
      local full_scene_prompt="${persona_name}: ${description}. Scene: ${scene_desc}. $(brand_visual_dna) Maintain character identity. Natural movement, cinematic quality."

      # Convert image to base64 for Kling
      local img_b64
      img_b64=$(python3 -c "
import base64, sys, os
with open(sys.argv[1], 'rb') as f:
    data = base64.b64encode(f.read()).decode('utf-8')
ext = os.path.splitext(sys.argv[1])[1].lower()
mime = 'image/png' if ext == '.png' else 'image/jpeg'
print(f'data:{mime};base64,{data}')
" "$ref_image" 2>/dev/null) || img_b64="$ref_image"

      local kling_out
      kling_out=$(bash "$KLING_VIDEO" image2video \
        "$full_scene_prompt" \
        --image "$img_b64" \
        --duration "$scene_duration" \
        --output "$video_file" 2>&1) || true

      if [ -f "$video_file" ]; then
        local vsize
        vsize=$(python3 -c "import os; print(os.path.getsize('$video_file'))" 2>/dev/null || echo "0")
        if [ "$vsize" -gt 1000 ]; then
          echo "  Video saved: scene_${scene_num}_video.mp4 ($vsize bytes)"
          scene_video="$video_file"
        fi
      else
        # Check for task ID (async)
        local tid
        tid=$(echo "$kling_out" | python3 -c "
import sys, re
m = re.search(r'Task created: (\S+)', sys.stdin.read())
print(m.group(1) if m else '')
" 2>/dev/null || echo "")
        if [ -n "$tid" ]; then
          echo "  Kling task submitted: $tid (async, check status later)"
          echo "KLING_TASK:${scene_num}:${tid}" >> "${output_dir}/pending_tasks.txt"
        else
          warn "Video generation unclear for scene $scene_num"
        fi
      fi
    else
      warn "No reference image available, skipping video for scene $scene_num"
    fi

    # Track outputs
    if [ -n "$scene_video" ]; then
      if [ -z "$clip_paths" ]; then
        clip_paths="$scene_video"
      else
        clip_paths="${clip_paths}|${scene_video}"
      fi
    fi
    if [ -n "$scene_audio" ]; then
      if [ -z "$audio_paths" ]; then
        audio_paths="$scene_audio"
      else
        audio_paths="${audio_paths}|${scene_audio}"
      fi
    fi

    echo ""
    scene_idx=$((scene_idx + 1))
  done

  # --- Post-production summary ---
  echo "========================================="
  echo "  PRODUCTION SUMMARY"
  echo "========================================="

  local completed_clips=0
  local completed_audio=0
  local pending_tasks=0

  if [ -n "$clip_paths" ]; then
    completed_clips=$(echo "$clip_paths" | tr '|' '\n' | python3 -c "import sys; print(len([l for l in sys.stdin.read().strip().split('\n') if l]))")
  fi
  if [ -n "$audio_paths" ]; then
    completed_audio=$(echo "$audio_paths" | tr '|' '\n' | python3 -c "import sys; print(len([l for l in sys.stdin.read().strip().split('\n') if l]))")
  fi
  if [ -f "${output_dir}/pending_tasks.txt" ]; then
    pending_tasks=$(python3 -c "
with open('${output_dir}/pending_tasks.txt') as f:
    print(len([l for l in f if l.strip()]))
" 2>/dev/null || echo "0")
  fi

  echo "  Scenes processed: $scene_count"
  echo "  Videos completed: $completed_clips"
  echo "  Audio completed:  $completed_audio"
  echo "  Pending Kling tasks: $pending_tasks"
  echo "  Output directory: $output_dir"

  if [ "$pending_tasks" -gt 0 ]; then
    echo ""
    echo "  Pending tasks (check with kling-video.sh status <id>):"
    if [ -f "${output_dir}/pending_tasks.txt" ]; then
      while IFS= read -r line; do
        echo "    $line"
      done < "${output_dir}/pending_tasks.txt"
    fi
  fi

  echo ""

  # Update persona stats
  if [ "$completed_clips" -gt 0 ]; then
    local current_vids
    current_vids=$(json_field "$ppath" "videos_generated")
    current_vids=${current_vids:-0}
    json_set "$ppath" "videos_generated" "$((current_vids + completed_clips))" "int"
  fi

  log "INFO" "Production complete: $persona_name, $scene_count scenes, $completed_clips clips, $completed_audio audio"
  post_to_room "creative" "Persona production complete: $persona_name ($scene_count scenes, $completed_clips clips). Output: $output_dir"

  echo "Production pipeline complete."
}

# ---------------------------------------------------------------------------
# Command: list
# ---------------------------------------------------------------------------

cmd_list() {
  if [ ! -d "$PERSONAS_DIR" ]; then
    echo "No personas directory found."
    return
  fi

  local count=0

  # Use python3 to safely glob (bash 3.2 safe)
  local persona_files
  persona_files=$(python3 -c "
import os, glob
pdir = os.path.expanduser('$PERSONAS_DIR')
files = sorted(glob.glob(os.path.join(pdir, '*.json')))
for f in files:
    print(f)
" 2>/dev/null)

  if [ -z "$persona_files" ]; then
    echo "No personas created yet."
    echo "Create one with: persona-gen.sh create --name <name> --brand <brand>"
    return
  fi

  echo ""
  echo "=== GAIA Persona Roster ==="

  while IFS= read -r pfile; do
    if [ -f "$pfile" ]; then
      print_persona_card "$pfile"
      count=$((count + 1))
    fi
  done <<EOF
$persona_files
EOF

  echo "Total personas: $count"
  echo ""
}

# ---------------------------------------------------------------------------
# Command: show
# ---------------------------------------------------------------------------

cmd_show() {
  local persona_name="${1:-}"
  [ -z "$persona_name" ] && die "show: persona name is required. Usage: persona-gen.sh show <name>"

  local ppath
  ppath=$(require_persona "$persona_name")

  # Print card
  print_persona_card "$ppath"

  # Print full details
  echo "--- Full Profile ---"
  python3 -c "
import json, sys, os

with open(sys.argv[1]) as f:
    d = json.load(f)

print(f\"  Name:        {d.get('name', 'unknown')}\")
print(f\"  Brand:       {d.get('brand', 'unknown')}\")
print(f\"  Created:     {d.get('created', 'unknown')}\")
print(f\"  Style:       {d.get('style', 'unknown')}\")
print(f\"  Vibe:        {d.get('vibe', 'unknown')}\")
print(f\"  Wardrobe:    {d.get('wardrobe', 'unknown')}\")
print()
print(f\"  Description:\")
desc = d.get('description', '')
# Word-wrap at 70 chars
words = desc.split()
line = '    '
for w in words:
    if len(line) + len(w) + 1 > 74:
        print(line)
        line = '    ' + w
    else:
        line += ' ' + w if line.strip() else '    ' + w
if line.strip():
    print(line)
print()

voice = d.get('voice_id')
voice_str = voice if voice and voice != 'None' else 'Not configured'
print(f\"  Voice ID:    {voice_str}\")
print(f\"  Videos:      {d.get('videos_generated', 0)}\")
print(f\"  Audio:       {d.get('audio_generated', 0)}\")
print()

refs = d.get('reference_images', [])
print(f\"  Reference Images ({len(refs)}):\")
for r in refs:
    exists = 'exists' if os.path.isfile(r) else 'MISSING'
    print(f\"    - {r} [{exists}]\")
print()

print(f\"  Profile: {sys.argv[1]}\")
" "$ppath"
  echo ""
}

# ---------------------------------------------------------------------------
# Command: selfie
# ---------------------------------------------------------------------------

cmd_selfie() {
  local persona_name="" scene="" mood="" brand_override="" output=""

  # First positional arg is persona name, second is scene description
  if [ $# -ge 1 ] && [ "${1#--}" = "$1" ]; then
    persona_name="$1"
    shift
  fi
  if [ $# -ge 1 ] && [ "${1#--}" = "$1" ]; then
    scene="$1"
    shift
  fi

  # Parse remaining flags
  while [ $# -gt 0 ]; do
    case "$1" in
      --mood)    mood="$2";           shift 2 ;;
      --brand)   brand_override="$2"; shift 2 ;;
      --output)  output="$2";         shift 2 ;;
      *) die "selfie: unknown option: $1" ;;
    esac
  done

  [ -z "$persona_name" ] && die "selfie: persona name is required. Usage: persona-gen.sh selfie <name> \"<scene>\" [--mood cozy] [--brand gaia-eats]"
  [ -z "$scene" ] && die "selfie: scene description is required. Usage: persona-gen.sh selfie $persona_name \"<scene>\""

  local ppath
  ppath=$(require_persona "$persona_name")

  local brand description wardrobe char_prompt
  brand=$(json_field "$ppath" "brand")
  description=$(json_field "$ppath" "description")
  wardrobe=$(json_field "$ppath" "wardrobe")
  char_prompt=$(json_field "$ppath" "character_prompt")

  # Allow brand override
  [ -n "$brand_override" ] && brand="$brand_override"

  # Get first reference image (for logging; NanoBanana Pro uses description-based consistency)
  local ref_image
  ref_image=$(python3 -c "
import json, sys, os
with open(sys.argv[1]) as f:
    d = json.load(f)
refs = d.get('reference_images', [])
for r in refs:
    if os.path.isfile(r):
        print(r)
        break
else:
    print('')
" "$ppath" 2>/dev/null || echo "")

  # Load brand DNA for visual enrichment
  load_brand_dna "$brand"

  # Load mood preset if specified
  local mood_style="" mood_lighting="" mood_atmosphere="" mood_props=""
  if [ -n "$mood" ]; then
    local mood_lower
    mood_lower=$(to_lower "$mood")
    local mood_file="$BRANDS_DIR/${brand}/moods/${mood_lower}.json"
    if [ -f "$mood_file" ]; then
      mood_style=$(json_field "$mood_file" "style.color_grade")
      mood_lighting=$(json_field "$mood_file" "style.lighting")
      mood_atmosphere=$(json_field "$mood_file" "style.atmosphere")
      mood_props=$(json_field "$mood_file" "style.props")
      log "INFO" "Loaded mood preset: $mood_lower from $mood_file"
    else
      warn "Mood preset '$mood_lower' not found at $mood_file. Using brand defaults."
    fi
  fi

  # Build character-consistent selfie prompt
  # Key: lock all character features, only change the scene/setting
  local selfie_prompt
  selfie_prompt=$(python3 - "$persona_name" "$description" "$wardrobe" "$scene" \
    "$(brand_visual_dna)" "$mood_style" "$mood_lighting" "$mood_atmosphere" "$mood_props" <<'PYEOF'
import sys

name = sys.argv[1]
description = sys.argv[2]
wardrobe = sys.argv[3]
scene = sys.argv[4]
brand_vis = sys.argv[5]
mood_style = sys.argv[6]
mood_lighting = sys.argv[7]
mood_atmosphere = sys.argv[8]
mood_props = sys.argv[9]

# Character identity lock (consistency anchoring)
prompt_parts = [
    "Portrait photo of " + name + ", a virtual influencer.",
    "Character identity: " + description,
    "Wardrobe: " + wardrobe + ".",
    "Same character throughout — maintain exact facial features, hairstyle, body proportions, and outfit.",
    "Do not change any character attributes. Only change the scene and setting.",
    "",
    "Scene: " + scene + ".",
]

# Add mood-specific styling
if mood_lighting:
    prompt_parts.append("Lighting: " + mood_lighting + ".")
if mood_atmosphere:
    prompt_parts.append("Atmosphere: " + mood_atmosphere + ".")
if mood_style:
    prompt_parts.append("Color grade: " + mood_style + ".")
if mood_props:
    prompt_parts.append("Props: " + mood_props + ".")

prompt_parts.append("")
prompt_parts.append(brand_vis)
prompt_parts.append("Semi-realistic style, Instagram-quality selfie, natural candid feel.")
prompt_parts.append("Sharp focus on character, shallow depth of field on background.")
prompt_parts.append("4K resolution, high detail.")

print(" ".join(p for p in prompt_parts if p))
PYEOF
)

  # Set output path: personas/<name>/selfies/selfie-<timestamp>.png
  local selfie_dir="${PERSONAS_DIR}/../selfies/${persona_name}"
  mkdir -p "$selfie_dir"
  if [ -z "$output" ]; then
    output="${selfie_dir}/selfie-$(date +%Y%m%d-%H%M%S).png"
  fi

  echo "Generating selfie for: $persona_name"
  echo "  Scene: $scene"
  [ -n "$mood" ] && echo "  Mood: $mood"
  echo "  Brand: $brand ($BRAND_DISPLAY)"
  [ -n "$ref_image" ] && echo "  Reference: $ref_image"
  echo "  Output: $output"
  log "INFO" "Selfie: persona=$persona_name scene='$scene' mood='${mood:-none}' brand=$brand"

  # Check NanoBanana exists
  if [ ! -f "$NANOBANANA" ]; then
    die "selfie: NanoBanana script not found at $NANOBANANA"
  fi

  echo "  Calling NanoBanana Pro (gemini-3-pro-image-preview)..."

  # Call NanoBanana generate with Pro model for best character consistency
  local gen_result=""
  gen_result=$(bash "$NANOBANANA" generate \
    --brand "$brand" \
    --use-case lifestyle \
    --prompt "$selfie_prompt" \
    --size 4K \
    --ratio 1:1 \
    --model pro \
    --raw 2>&1) || true

  # Extract output path from NanoBanana output
  local generated_path
  generated_path=$(echo "$gen_result" | python3 -c "
import sys
lines = sys.stdin.read().strip().split('\n')
for line in reversed(lines):
    line = line.strip()
    if line.endswith('.png') or line.endswith('.jpg'):
        print(line)
        break
else:
    print('')
" 2>/dev/null || echo "")

  if [ -n "$generated_path" ] && [ -f "$generated_path" ]; then
    # Move/copy to the selfie directory with our naming convention
    if [ "$generated_path" != "$output" ]; then
      cp "$generated_path" "$output"
    fi
    local file_size
    file_size=$(python3 -c "import os; print(os.path.getsize('$output'))" 2>/dev/null || echo "0")
    echo "  Selfie saved: $output ($file_size bytes)"
    log "INFO" "Selfie saved: $output ($file_size bytes)"

    # Log to persona's selfie history
    local selfie_log="${selfie_dir}/selfie-log.jsonl"
    printf '{"ts":%s,"persona":"%s","scene":"%s","mood":"%s","brand":"%s","path":"%s","size":%s}\n' \
      "$(date +%s)" \
      "$persona_name" \
      "$(echo "$scene" | sed 's/"/\\"/g')" \
      "${mood:-none}" \
      "$brand" \
      "$(echo "$output" | sed 's/"/\\"/g')" \
      "$file_size" >> "$selfie_log"

    # Post to creative room
    post_to_room "creative" "Persona selfie: $persona_name in '$scene'. Path: $output"

    echo ""
    echo "Done. Selfie ready at: $output"
    echo ""
    echo "To post it:"
    echo "  persona-gen.sh post $persona_name \"Your caption here\" --image $output"
  else
    warn "NanoBanana generation may have failed. Output: $(echo "$gen_result" | tail -5)"
    log "ERROR" "Selfie generation failed for $persona_name. NanoBanana output: $(echo "$gen_result" | tail -5)"
    echo ""
    echo "Full NanoBanana output:"
    echo "$gen_result"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Command: post
# ---------------------------------------------------------------------------

cmd_post() {
  local persona_name="" caption="" image_path="" target="" channel="whatsapp"

  # First positional arg is persona name, second is caption
  if [ $# -ge 1 ] && [ "${1#--}" = "$1" ]; then
    persona_name="$1"
    shift
  fi
  if [ $# -ge 1 ] && [ "${1#--}" = "$1" ]; then
    caption="$1"
    shift
  fi

  # Parse remaining flags
  while [ $# -gt 0 ]; do
    case "$1" in
      --image)   image_path="$2"; shift 2 ;;
      --to)      target="$2";     shift 2 ;;
      --channel) channel="$2";    shift 2 ;;
      *) die "post: unknown option: $1" ;;
    esac
  done

  [ -z "$persona_name" ] && die "post: persona name is required. Usage: persona-gen.sh post <name> \"<caption>\" --image <path> [--to <target>]"
  [ -z "$caption" ] && die "post: caption is required. Usage: persona-gen.sh post $persona_name \"<caption>\" --image <path>"
  [ -z "$image_path" ] && die "post: --image is required. Provide the path to an image (e.g., from selfie command)."
  [ ! -f "$image_path" ] && die "post: image file not found: $image_path"

  local ppath
  ppath=$(require_persona "$persona_name")

  local brand
  brand=$(json_field "$ppath" "brand")

  # Resolve default target from persona profile if not provided
  if [ -z "$target" ]; then
    target=$(json_field "$ppath" "default_post_target")
    # Fallback to owner's WhatsApp
    if [ -z "$target" ] || [ "$target" = "null" ] || [ "$target" = "None" ]; then
      target="+60126169979"
    fi
  fi

  echo "Posting for persona: $persona_name"
  echo "  Caption: $(echo "$caption" | head -c 100)..."
  echo "  Image: $image_path"
  echo "  Target: $target"
  echo "  Channel: $channel"
  log "INFO" "Post: persona=$persona_name target=$target channel=$channel image=$image_path"

  # Post via openclaw message send (supports --media for images)
  local send_result=""
  local send_exit=0

  echo "  Sending via openclaw message send..."
  send_result=$(openclaw message send \
    --channel "$channel" \
    --target "$target" \
    --message "$caption" \
    --media "$image_path" 2>&1) || send_exit=$?

  if [ "$send_exit" -eq 0 ]; then
    echo "  Sent successfully."
    log "INFO" "Post sent: persona=$persona_name target=$target channel=$channel"

    # Log to persona's post history
    local selfie_dir="${PERSONAS_DIR}/../selfies/${persona_name}"
    mkdir -p "$selfie_dir"
    local post_log="${selfie_dir}/post-log.jsonl"
    printf '{"ts":%s,"persona":"%s","caption":"%s","image":"%s","target":"%s","channel":"%s","status":"sent"}\n' \
      "$(date +%s)" \
      "$persona_name" \
      "$(echo "$caption" | sed 's/"/\\"/g')" \
      "$(echo "$image_path" | sed 's/"/\\"/g')" \
      "$(echo "$target" | sed 's/"/\\"/g')" \
      "$channel" >> "$post_log"

    # Post to creative room
    post_to_room "creative" "Persona post: $persona_name posted to $target via $channel. Caption: $(echo "$caption" | head -c 60)"

    echo ""
    echo "Done."
  else
    warn "openclaw message send returned exit code $send_exit"
    echo "  Output: $send_result"
    log "ERROR" "Post failed: persona=$persona_name exit=$send_exit output=$send_result"

    # Fallback: try openclaw agent --deliver with media
    echo ""
    echo "  Trying fallback via openclaw agent --deliver..."
    local fallback_result=""
    local fallback_exit=0
    fallback_result=$(openclaw agent \
      --agent main \
      --channel "$channel" \
      --to "$target" \
      --deliver \
      --message "$caption" 2>&1) || fallback_exit=$?

    if [ "$fallback_exit" -eq 0 ]; then
      echo "  Fallback: text message sent (without media)."
      echo "  NOTE: Media attachment may need to be sent separately."
      log "WARN" "Post fallback (text-only): persona=$persona_name target=$target"

      # Log fallback post
      local selfie_dir="${PERSONAS_DIR}/../selfies/${persona_name}"
      mkdir -p "$selfie_dir"
      local post_log="${selfie_dir}/post-log.jsonl"
      printf '{"ts":%s,"persona":"%s","caption":"%s","image":"%s","target":"%s","channel":"%s","status":"text_only_fallback"}\n' \
        "$(date +%s)" \
        "$persona_name" \
        "$(echo "$caption" | sed 's/"/\\"/g')" \
        "$(echo "$image_path" | sed 's/"/\\"/g')" \
        "$(echo "$target" | sed 's/"/\\"/g')" \
        "$channel" >> "$post_log"
    else
      die "post: Both send methods failed. Message send: $send_result | Agent deliver: $fallback_result"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------

usage() {
  echo "persona-gen.sh — AI Avatar / Virtual Influencer Pipeline"
  echo ""
  echo "Usage:"
  echo "  persona-gen.sh create   --name <name> --brand <brand> [options]"
  echo "  persona-gen.sh selfie   <name> \"<scene>\" [--mood <mood>] [--brand <brand>]"
  echo "  persona-gen.sh post     <name> \"<caption>\" --image <path> [--to <target>]"
  echo "  persona-gen.sh animate  --persona <name> --scene <text> [options]"
  echo "  persona-gen.sh voice    --persona <name> --text <text> [options]"
  echo "  persona-gen.sh produce  --persona <name> --script <file> --type <type> [options]"
  echo "  persona-gen.sh list"
  echo "  persona-gen.sh show     <name>"
  echo ""
  echo "Create options:"
  echo "  --name <name>         Persona name (required)"
  echo "  --brand <brand>       Brand slug, e.g. gaia-eats (required)"
  echo "  --age <n>             Character age (default: 28)"
  echo "  --gender <g>          Character gender (default: female)"
  echo "  --ethnicity <e>       Character ethnicity (default: malay)"
  echo "  --style <s>           casual|professional|streetwear|apron (default: casual)"
  echo "  --vibe <v>            friendly|energetic|calm|quirky (default: friendly)"
  echo "  --desc <text>         Additional character description"
  echo ""
  echo "Selfie options:"
  echo "  <name>                Persona name (required, positional)"
  echo "  \"<scene>\"             Scene/situation description (required, positional)"
  echo "  --mood <mood>         Brand mood preset: cozy|bold|premium|playful|nostalgic|energetic"
  echo "  --brand <brand>       Override brand from persona profile"
  echo "  --output <path>       Override output file path"
  echo ""
  echo "Post options:"
  echo "  <name>                Persona name (required, positional)"
  echo "  \"<caption>\"           Caption text (required, positional)"
  echo "  --image <path>        Image file to post (required)"
  echo "  --to <target>         Recipient: E.164 number or group JID (default: from persona profile)"
  echo "  --channel <ch>        Channel: whatsapp|telegram|discord|etc (default: whatsapp)"
  echo ""
  echo "Animate options:"
  echo "  --persona <name>      Persona to animate (required)"
  echo "  --scene <text>        Scene description (required)"
  echo "  --duration 5|10       Video duration in seconds (default: 5)"
  echo "  --ratio 9:16|16:9|1:1 Aspect ratio (default: 9:16)"
  echo "  --output <path>       Output file path"
  echo ""
  echo "Voice options:"
  echo "  --persona <name>      Persona (required)"
  echo "  --text <text>         Text to speak (required unless --clone)"
  echo "  --voice-id <id>       ElevenLabs voice ID"
  echo "  --model <m>           TTS model (default: eleven_multilingual_v2)"
  echo "  --clone               Clone voice from sample"
  echo "  --sample <file>       Audio sample for voice cloning"
  echo "  --output <path>       Output file path"
  echo ""
  echo "Produce options:"
  echo "  --persona <name>      Persona (required)"
  echo "  --script <file>       Script file with scenes (required)"
  echo "  --type <type>         Output type: ugc|aroll|broll|promotion (default: ugc)"
  echo "  --brand <brand>       Override brand from persona profile"
  echo "  --mood <mood>         Mood preset (cozy|bold|premium|playful|nostalgic|energetic)"
  echo "  --output <dir>        Output directory"
  echo ""
  echo "Examples:"
  echo "  # Create a persona"
  echo "  persona-gen.sh create --name Maya --brand gaia-eats --style apron --vibe friendly"
  echo ""
  echo "  # Generate a selfie in a scene"
  echo "  persona-gen.sh selfie Maya \"cooking rendang in a cozy kitchen\" --mood cozy"
  echo ""
  echo "  # Post the selfie to WhatsApp"
  echo "  persona-gen.sh post Maya \"Masak rendang hari ni!\" --image /path/to/selfie.png"
  echo ""
  echo "  # Post to a specific WhatsApp group"
  echo "  persona-gen.sh post Maya \"Weekend vibes\" --image /path/to/selfie.png --to \"group:120363...@g.us\""
}

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  create)   cmd_create "$@" ;;
  selfie)   cmd_selfie "$@" ;;
  post)     cmd_post "$@" ;;
  animate)  cmd_animate "$@" ;;
  voice)    cmd_voice "$@" ;;
  produce)  cmd_produce "$@" ;;
  list)     cmd_list ;;
  show)     cmd_show "$@" ;;
  help|-h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo ""
    usage
    exit 1
    ;;
esac
