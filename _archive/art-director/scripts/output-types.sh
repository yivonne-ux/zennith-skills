#!/usr/bin/env bash
# output-types.sh — Output type framework for GAIA content factory
# Manages video/image output types with specs, generation, and storyboarding
#
# Usage:
#   bash output-types.sh list                                          — Show all output types
#   bash output-types.sh specs <type>                                  — Detailed specs as JSON
#   bash output-types.sh generate <type> --prompt "..." [--kling|--sora|--zimage]
#   bash output-types.sh storyboard <type> --prompt "..."              — Generate JSON storyboard
#
# macOS compatible (bash 3.2, no declare -A, no timeout)

set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_FILE="$HOME/.openclaw/workspace/data/output-types.json"
LOG_FILE="$HOME/.openclaw/logs/content-gen.log"
KLING_SCRIPT="$SCRIPT_DIR/kling-video.sh"
SORA_SCRIPT="$SCRIPT_DIR/sora-video.sh"

mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }

# --- Helpers ---

# Get all type IDs (one per line)
get_type_ids() {
  python3 -c "
import json
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    print(t['id'])
"
}

# Check if a type ID exists; exits 1 if not
validate_type() {
  local type_id="$1"
  python3 -c "
import json, sys
with open('$DATA_FILE') as f:
    types = json.load(f)
ids = [t['id'] for t in types]
if '$type_id' not in ids:
    print('ERROR: Unknown output type: $type_id', file=sys.stderr)
    print('Available types: ' + ', '.join(ids), file=sys.stderr)
    sys.exit(1)
" || exit 1
}

# Get a single type as JSON
get_type_json() {
  local type_id="$1"
  python3 -c "
import json
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    if t['id'] == '$type_id':
        print(json.dumps(t, indent=2))
        break
"
}

# Get a field from a type
get_type_field() {
  local type_id="$1"
  local field="$2"
  python3 -c "
import json
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    if t['id'] == '$type_id':
        val = t.get('$field')
        if isinstance(val, (dict, list)):
            print(json.dumps(val))
        elif val is None:
            print('null')
        else:
            print(val)
        break
"
}

# --- Commands ---

cmd_list() {
  echo "=== GAIA Content Factory — Output Types ==="
  echo ""
  python3 -c "
import json

with open('$DATA_FILE') as f:
    types = json.load(f)

for t in types:
    dur = t.get('duration_range')
    if dur is None:
        dur_str = 'images only'
    elif dur.get('min') is None and dur.get('max') is None:
        dur_str = 'any duration'
    elif dur.get('max') is None:
        dur_str = str(dur.get('min', '?')) + 's+'
    else:
        dur_str = str(dur.get('min', '?')) + '-' + str(dur.get('max', '?')) + 's'

    ratios = ', '.join(t.get('aspect_ratios', []))
    tools = ', '.join(t.get('generation_tools', []))
    platforms = ', '.join(t.get('platform_targets', [])[:3])
    if len(t.get('platform_targets', [])) > 3:
        platforms += '...'

    print(f\"  {t['id']:<12} {t['name']:<20} {dur_str:<14} {ratios:<16} [{tools}]\")
    print(f\"               {t['description'][:80]}\")
    print()
"
  echo "Usage: bash output-types.sh specs <type> — for detailed specs"
}

cmd_specs() {
  if [ $# -eq 0 ]; then
    echo "ERROR: Type ID required"
    echo "Usage: bash output-types.sh specs <type>"
    echo ""
    echo "Available types:"
    get_type_ids | while read -r id; do
      echo "  $id"
    done
    exit 1
  fi

  local type_id="$1"
  validate_type "$type_id"
  get_type_json "$type_id"
}

cmd_generate() {
  if [ $# -lt 1 ]; then
    echo "ERROR: Type ID required"
    echo "Usage: bash output-types.sh generate <type> --prompt \"...\" [--kling|--sora|--zimage]"
    exit 1
  fi

  local type_id="$1"
  shift
  validate_type "$type_id"

  local prompt=""
  local tool=""
  local extra_args=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt)  prompt="$2"; shift 2 ;;
      --kling)   tool="kling"; shift ;;
      --sora)    tool="sora"; shift ;;
      --zimage)  tool="zimage"; shift ;;
      *)         extra_args="$extra_args $1"; shift ;;
    esac
  done

  if [ -z "$prompt" ]; then
    echo "ERROR: --prompt is required"
    echo "Usage: bash output-types.sh generate <type> --prompt \"...\" [--kling|--sora|--zimage]"
    exit 1
  fi

  # Auto-select tool if not specified
  if [ -z "$tool" ]; then
    tool=$(python3 -c "
import json
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    if t['id'] == '$type_id':
        tools = t.get('generation_tools', [])
        # Prefer order: kling > sora > zimage
        for preferred in ['kling', 'sora', 'zimage']:
            if preferred in tools:
                print(preferred)
                break
        break
")
    echo "Auto-selected tool: $tool"
  fi

  # Validate tool is supported for this type
  python3 -c "
import json, sys
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    if t['id'] == '$type_id':
        if '$tool' not in t.get('generation_tools', []):
            supported = ', '.join(t['generation_tools'])
            print(f'ERROR: Tool \"$tool\" not supported for type \"$type_id\". Supported: {supported}', file=sys.stderr)
            sys.exit(1)
        break
" || exit 1

  # Get type specs for parameter building
  local aspect_ratios duration_min duration_max resolution
  aspect_ratios=$(get_type_field "$type_id" "aspect_ratios")
  resolution=$(get_type_field "$type_id" "resolution")

  # Extract first aspect ratio for default
  local default_ratio
  default_ratio=$(echo "$aspect_ratios" | python3 -c "import json,sys; print(json.load(sys.stdin)[0])")

  # Extract duration
  duration_min=$(python3 -c "
import json
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    if t['id'] == '$type_id':
        dr = t.get('duration_range')
        if dr and dr.get('min'):
            print(dr['min'])
        else:
            print('5')
        break
")
  duration_max=$(python3 -c "
import json
with open('$DATA_FILE') as f:
    types = json.load(f)
for t in types:
    if t['id'] == '$type_id':
        dr = t.get('duration_range')
        if dr and dr.get('max'):
            print(dr['max'])
        else:
            print('5')
        break
")

  # Build brand-aware prompt
  local enhanced_prompt
  enhanced_prompt=$(python3 -c "
import json, sys

with open('$DATA_FILE') as f:
    types = json.load(f)

for t in types:
    if t['id'] == '$type_id':
        style = t.get('style_params', {})
        brand_notes = style.get('brand_notes', '')
        camera = style.get('camera_movement', '')
        lighting = style.get('lighting', '')
        color = style.get('color_grade', '')

        # Build enhanced prompt with style context
        parts = [sys.argv[1]]

        if camera and camera != 'any' and camera != 'platform_dependent':
            cam_first = camera.split('|')[0].replace('_', ' ')
            parts.append(f'Camera: {cam_first}.')

        if lighting and lighting != 'as_shot' and lighting != 'platform_dependent':
            light_first = lighting.split('|')[0].replace('_', ' ')
            parts.append(f'Lighting: {light_first}.')

        if color and color != 'none' and color != 'platform_dependent':
            color_first = color.split('|')[0].replace('_', ' ')
            parts.append(f'Color grade: {color_first}.')

        # GAIA brand context
        parts.append('Brand: GAIA Eats, Malaysian vegan/plant-based food.')

        print(' '.join(parts))
        break
" "$prompt")

  log "GENERATE: type=$type_id tool=$tool prompt=$prompt"

  echo "=== Generating: $type_id ==="
  echo "Tool:       $tool"
  echo "Ratio:      $default_ratio"
  echo "Resolution: $resolution"
  echo "Duration:   ${duration_min}-${duration_max}s"
  echo "Prompt:     $enhanced_prompt"
  echo ""

  case "$tool" in
    kling)
      # Map aspect ratio format: "9:16" stays as "9:16" for Kling
      local kling_duration="$duration_min"
      # Kling supports 5 or 10 second durations
      if [ "$kling_duration" -lt 5 ] 2>/dev/null; then
        kling_duration=5
      elif [ "$kling_duration" -gt 5 ] 2>/dev/null; then
        kling_duration=10
      fi

      echo "Calling Kling AI..."
      log "KLING: duration=$kling_duration ratio=$default_ratio"

      if [ -f "$KLING_SCRIPT" ]; then
        bash "$KLING_SCRIPT" text2video "$enhanced_prompt" \
          --duration "$kling_duration" \
          --ratio "$default_ratio" \
          --model kling-video-o1 \
          --mode std
      else
        echo "ERROR: kling-video.sh not found at $KLING_SCRIPT"
        exit 1
      fi
      ;;

    sora)
      # Map ratio to Sora size format
      local sora_size
      case "$default_ratio" in
        "9:16")  sora_size="1080x1920" ;;
        "16:9")  sora_size="1920x1080" ;;
        "1:1")   sora_size="1080x1080" ;;
        "4:5")   sora_size="1080x1350" ;;
        "4:3")   sora_size="1440x1080" ;;
        "21:9")  sora_size="2560x1080" ;;
        *)       sora_size="1280x720" ;;
      esac

      local sora_seconds="$duration_min"
      # Sora supports specific durations
      if [ "$sora_seconds" -lt 5 ] 2>/dev/null; then
        sora_seconds=5
      elif [ "$sora_seconds" -gt 20 ] 2>/dev/null; then
        sora_seconds=20
      fi

      echo "Calling Sora..."
      log "SORA: seconds=$sora_seconds size=$sora_size"

      if [ -f "$SORA_SCRIPT" ]; then
        bash "$SORA_SCRIPT" generate "$enhanced_prompt" \
          --seconds "$sora_seconds" \
          --size "$sora_size"
      else
        echo "ERROR: sora-video.sh not found at $SORA_SCRIPT"
        exit 1
      fi
      ;;

    zimage)
      # Z-Image is for still images — output the prompt format for MCP tool
      local zimage_resolution
      case "$default_ratio" in
        "1:1")   zimage_resolution="1024x1024 ( 1:1 )" ;;
        "9:16")  zimage_resolution="720x1280 ( 9:16 )" ;;
        "16:9")  zimage_resolution="1280x720 ( 16:9 )" ;;
        "9:7")   zimage_resolution="1152x896 ( 9:7 )" ;;
        "7:9")   zimage_resolution="896x1152 ( 7:9 )" ;;
        "4:3")   zimage_resolution="1152x864 ( 4:3 )" ;;
        "3:4")   zimage_resolution="864x1152 ( 3:4 )" ;;
        "3:2")   zimage_resolution="1248x832 ( 3:2 )" ;;
        "2:3")   zimage_resolution="832x1248 ( 2:3 )" ;;
        "21:9")  zimage_resolution="1344x576 ( 21:9 )" ;;
        "4:5")   zimage_resolution="864x1152 ( 3:4 )" ;;
        *)       zimage_resolution="1024x1024 ( 1:1 )" ;;
      esac

      echo "=== Z-Image Generation Parameters ==="
      echo ""
      echo "Use the Z-Image MCP tool (gr1_z_image_turbo_generate) with:"
      echo ""
      echo "  prompt:     $enhanced_prompt"
      echo "  resolution: $zimage_resolution"
      echo "  steps:      8"
      echo "  shift:      3"
      echo ""
      echo "--- Copy-paste JSON for MCP call ---"
      python3 -c "
import json, sys
params = {
    'prompt': sys.argv[1],
    'resolution': '$zimage_resolution',
    'steps': 8,
    'shift': 3,
    'random_seed': True
}
print(json.dumps(params, indent=2))
" "$enhanced_prompt"
      echo ""
      log "ZIMAGE: resolution=$zimage_resolution prompt=$enhanced_prompt"

      # For carousel type, generate slide prompts
      if [ "$type_id" = "carousel" ]; then
        echo ""
        echo "=== Carousel: Generate multiple slides ==="
        echo "For a carousel, run Z-Image multiple times with variations:"
        echo "  Slide 1 (Hook): $prompt — attention-grabbing hero visual"
        echo "  Slide 2-N (Content): Vary the prompt for each content slide"
        echo "  Final Slide (CTA): $prompt — with clear call-to-action"
      fi
      ;;

    *)
      echo "ERROR: Unknown tool: $tool"
      exit 1
      ;;
  esac

  log "GENERATE COMPLETE: type=$type_id tool=$tool"
}

cmd_storyboard() {
  if [ $# -lt 1 ]; then
    echo "ERROR: Type ID required"
    echo "Usage: bash output-types.sh storyboard <type> --prompt \"...\""
    exit 1
  fi

  local type_id="$1"
  shift
  validate_type "$type_id"

  local prompt=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --prompt) prompt="$2"; shift 2 ;;
      *)        shift ;;
    esac
  done

  if [ -z "$prompt" ]; then
    echo "ERROR: --prompt is required"
    echo "Usage: bash output-types.sh storyboard <type> --prompt \"...\""
    exit 1
  fi

  log "STORYBOARD: type=$type_id prompt=$prompt"

  python3 -c "
import json, sys, math

with open('$DATA_FILE') as f:
    types = json.load(f)

type_data = None
for t in types:
    if t['id'] == '$type_id':
        type_data = t
        break

if not type_data:
    print('ERROR: type not found', file=sys.stderr)
    sys.exit(1)

prompt = sys.argv[1]
dur = type_data.get('duration_range')
style = type_data.get('style_params', {})
text_overlay = type_data.get('text_overlay', {})
audio_info = type_data.get('audio', {})

# Calculate storyboard structure based on type
storyboard = {
    'type': type_data['id'],
    'name': type_data['name'],
    'prompt': prompt,
    'brand': 'GAIA Eats — Malaysian vegan/plant-based',
    'aspect_ratio': type_data['aspect_ratios'][0],
    'resolution': type_data['resolution'],
    'generation_tools': type_data['generation_tools'],
    'scenes': []
}

if dur:
    total_dur = dur.get('max') or dur.get('min') or 10
    storyboard['total_duration'] = total_dur
else:
    total_dur = 0
    storyboard['total_duration'] = None

type_id = type_data['id']

# Generate scenes based on output type
if type_id == 'broll':
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 3, 'shot': 'Close-up product/ingredient detail', 'camera': 'Slow zoom in', 'prompt_hint': f'{prompt} — extreme close-up, macro detail, soft natural light'},
        {'scene': 2, 'start': 3, 'end': 6, 'shot': 'Texture/ambient shot', 'camera': 'Slow pan right', 'prompt_hint': f'{prompt} — texture detail, shallow depth of field, warm tones'},
        {'scene': 3, 'start': 6, 'end': 10, 'shot': 'Wide context shot', 'camera': 'Slow pull back', 'prompt_hint': f'{prompt} — wider shot showing context, natural setting, golden hour light'}
    ]

elif type_id == 'aroll':
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 3, 'shot': 'Hook — attention grab', 'camera': 'Static, eye level', 'text': 'Hook text overlay', 'prompt_hint': f'{prompt} — direct to camera, engaging opening'},
        {'scene': 2, 'start': 3, 'end': 15, 'shot': 'Main content — demo/explanation', 'camera': 'Static with subtle zoom', 'text': 'Captions auto-generated', 'prompt_hint': f'{prompt} — demonstration, clear view of product/process'},
        {'scene': 3, 'start': 15, 'end': 25, 'shot': 'Supporting detail', 'camera': 'Cut to detail shot', 'text': 'Key info captions', 'prompt_hint': f'{prompt} — supporting visuals, results, detail'},
        {'scene': 4, 'start': 25, 'end': 30, 'shot': 'Wrap-up and CTA', 'camera': 'Back to face', 'text': 'CTA overlay', 'prompt_hint': f'{prompt} — closing, call to action, smile'}
    ]

elif type_id == 'promotion':
    structure = style.get('structure', {})
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 3, 'shot': 'HOOK — Stop the scroll', 'camera': 'Dynamic zoom or cut', 'text': 'Bold hook statement', 'prompt_hint': f'{prompt} — attention-grabbing visual, bold, eye-catching'},
        {'scene': 2, 'start': 3, 'end': 8, 'shot': 'PROBLEM — Pain point', 'camera': 'Relatable scenario', 'text': 'Problem statement overlay', 'prompt_hint': f'{prompt} — showing the problem, relatable situation'},
        {'scene': 3, 'start': 8, 'end': 20, 'shot': 'SOLUTION — Product reveal', 'camera': 'Product hero shot', 'text': 'Product name + benefit', 'prompt_hint': f'{prompt} — GAIA product as the solution, beautiful product shot'},
        {'scene': 4, 'start': 20, 'end': 30, 'shot': 'CTA — Drive action', 'camera': 'Product + price', 'text': 'Price, offer, link', 'prompt_hint': f'{prompt} — call to action, price display, urgency'}
    ]

elif type_id == 'education':
    step_count = 4
    step_dur = max(int(total_dur / (step_count + 1)), 5)
    scenes = [
        {'scene': 1, 'start': 0, 'end': step_dur, 'shot': 'Intro — What we are making/learning', 'camera': 'Overview shot', 'text': 'Title + ingredients/materials', 'prompt_hint': f'{prompt} — opening overview, ingredients laid out'}
    ]
    for i in range(step_count):
        s = step_dur * (i + 1)
        e = min(s + step_dur, total_dur)
        scenes.append({
            'scene': i + 2, 'start': s, 'end': e,
            'shot': f'Step {i+1}', 'camera': 'Overhead or close-up',
            'text': f'Step {i+1} subtitle',
            'prompt_hint': f'{prompt} — step {i+1}, clear demonstration, overhead angle'
        })
    scenes.append({
        'scene': step_count + 2, 'start': total_dur - 5, 'end': total_dur,
        'shot': 'Final result', 'camera': 'Hero shot of finished product',
        'text': 'Final result + CTA',
        'prompt_hint': f'{prompt} — beautiful final result, appetizing presentation'
    })
    storyboard['scenes'] = scenes

elif type_id == 'raw':
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': total_dur, 'shot': 'Continuous raw capture', 'camera': 'As needed', 'text': None, 'prompt_hint': f'{prompt} — raw, unedited, natural'}
    ]

elif type_id == 'lofi':
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 8, 'shot': 'Cozy establishing shot', 'camera': 'Slow drift', 'text': None, 'prompt_hint': f'{prompt} — warm tones, golden hour, film grain, vintage, cozy kitchen'},
        {'scene': 2, 'start': 8, 'end': 18, 'shot': 'Intimate detail moments', 'camera': 'Gentle handheld', 'text': None, 'prompt_hint': f'{prompt} — close-up details, steam rising, warm light, nostalgic feel'},
        {'scene': 3, 'start': 18, 'end': 30, 'shot': 'Lingering final moment', 'camera': 'Static, contemplative', 'text': None, 'prompt_hint': f'{prompt} — final serene moment, fade, warm vignette, lo-fi aesthetic'}
    ]

elif type_id == 'channel':
    storyboard['notes'] = 'Channel type generates platform-specific versions. Storyboard shows the master version.'
    storyboard['platform_versions'] = list(style.get('platform_specs', {}).keys())
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 3, 'shot': 'Platform hook', 'camera': 'Dynamic', 'text': 'Hook text (safe-zone aware)', 'prompt_hint': f'{prompt} — attention hook, platform-optimized'},
        {'scene': 2, 'start': 3, 'end': int(total_dur * 0.7), 'shot': 'Core content', 'camera': 'Varies by platform', 'text': 'Key message', 'prompt_hint': f'{prompt} — main content, engaging, brand-focused'},
        {'scene': 3, 'start': int(total_dur * 0.7), 'end': total_dur, 'shot': 'CTA/close', 'camera': 'Product focus', 'text': 'CTA in safe zone', 'prompt_hint': f'{prompt} — closing CTA, product shot'}
    ]

elif type_id == 'podcast':
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 3, 'shot': 'Title card + speaker intro', 'camera': 'Static', 'text': 'Episode title, speaker name', 'visual': 'Waveform idle, brand background'},
        {'scene': 2, 'start': 3, 'end': int(total_dur * 0.85), 'shot': 'Key quote/insight', 'camera': 'Subtle zoom', 'text': 'Word-by-word caption highlight', 'visual': 'Waveform active, equalizer animation'},
        {'scene': 3, 'start': int(total_dur * 0.85), 'end': total_dur, 'shot': 'Outro + subscribe CTA', 'camera': 'Static', 'text': 'Listen link, subscribe CTA', 'visual': 'Waveform fade, logo'}
    ]

elif type_id == 'ip':
    storyboard['scenes'] = [
        {'scene': 1, 'shot': 'Character reference pose', 'prompt_hint': f'{prompt} — character design, front view, full body, clean background, consistent style'},
        {'scene': 2, 'shot': 'Character in brand context', 'prompt_hint': f'{prompt} — character interacting with GAIA products, brand colors, friendly expression'},
        {'scene': 3, 'shot': 'Character expression sheet', 'prompt_hint': f'{prompt} — character emotions sheet, happy, excited, thinking, waving, consistent proportions'}
    ]
    storyboard['notes'] = 'IP type may be image or video. Generate character sheet first for consistency.'

elif type_id == 'ugc':
    storyboard['scenes'] = [
        {'scene': 1, 'start': 0, 'end': 3, 'shot': 'Casual selfie intro', 'camera': 'Handheld, selfie angle', 'text': 'Native text: reaction or question', 'prompt_hint': f'{prompt} — phone selfie style, casual, authentic, natural lighting'},
        {'scene': 2, 'start': 3, 'end': 12, 'shot': 'Product reveal/unboxing', 'camera': 'POV, slightly shaky', 'text': None, 'prompt_hint': f'{prompt} — unboxing or first look, genuine reaction, phone-shot quality'},
        {'scene': 3, 'start': 12, 'end': 22, 'shot': 'Try/taste/use moment', 'camera': 'Handheld, casual framing', 'text': 'Reaction text', 'prompt_hint': f'{prompt} — trying the product, honest reaction, natural imperfect framing'},
        {'scene': 4, 'start': 22, 'end': 30, 'shot': 'Verdict + soft CTA', 'camera': 'Back to selfie', 'text': 'Rating or recommendation', 'prompt_hint': f'{prompt} — genuine recommendation, casual closing, no hard sell'}
    ]

elif type_id == 'hero':
    if dur:
        storyboard['scenes'] = [
            {'scene': 1, 'start': 0, 'end': 5, 'shot': 'Cinematic product reveal', 'camera': 'Slow cinematic movement', 'text': 'Brand headline', 'prompt_hint': f'{prompt} — premium product shot, studio lighting, cinematic, magazine quality, hero composition'},
            {'scene': 2, 'start': 5, 'end': 10, 'shot': 'Detail and texture', 'camera': 'Slow zoom to detail', 'text': 'Tagline', 'prompt_hint': f'{prompt} — extreme quality detail, professional food photography style'},
            {'scene': 3, 'start': 10, 'end': 15, 'shot': 'Final hero frame', 'camera': 'Static composed', 'text': 'Product name + CTA', 'prompt_hint': f'{prompt} — final hero composition, billboard quality, perfect lighting'}
        ]
    else:
        storyboard['scenes'] = [
            {'scene': 1, 'shot': 'Hero image', 'prompt_hint': f'{prompt} — premium quality, studio lighting, rule of thirds, magazine cover quality, GAIA branding'}
        ]

elif type_id == 'carousel':
    slide_count = 5
    storyboard['total_slides'] = slide_count
    storyboard['scenes'] = [
        {'slide': 1, 'role': 'Hook', 'text': 'Attention-grabbing headline', 'prompt_hint': f'{prompt} — slide 1 hook, bold visual, curiosity-driven, 1:1 square'},
        {'slide': 2, 'role': 'Context', 'text': 'Problem or insight', 'prompt_hint': f'{prompt} — slide 2, problem setup or key insight, clean infographic style'},
        {'slide': 3, 'role': 'Solution', 'text': 'GAIA product/approach', 'prompt_hint': f'{prompt} — slide 3, solution reveal, product showcase, brand colors'},
        {'slide': 4, 'role': 'Proof', 'text': 'Benefits, stats, testimonial', 'prompt_hint': f'{prompt} — slide 4, social proof or benefits, data visualization'},
        {'slide': 5, 'role': 'CTA', 'text': 'Call to action', 'prompt_hint': f'{prompt} — slide 5 CTA, clear action, link or handle, brand logo'}
    ]
    storyboard['notes'] = 'Generate each slide separately with Z-Image. Maintain consistent style across all slides.'

else:
    storyboard['scenes'] = [
        {'scene': 1, 'shot': 'Default scene', 'prompt_hint': prompt}
    ]

# Add QA checklist
storyboard['qa_checklist'] = type_data.get('qa_checklist', [])

# Add audio guidance
storyboard['audio'] = audio_info

# Add text overlay rules
storyboard['text_overlay'] = text_overlay

print(json.dumps(storyboard, indent=2))
" "$prompt"

  log "STORYBOARD COMPLETE: type=$type_id"
}

# --- Usage ---
show_usage() {
  echo "output-types.sh — GAIA Content Factory Output Type Framework"
  echo ""
  echo "Usage:"
  echo "  bash output-types.sh list                                              List all output types"
  echo "  bash output-types.sh specs <type>                                      Show detailed specs (JSON)"
  echo "  bash output-types.sh generate <type> --prompt \"...\" [--tool]           Generate content"
  echo "  bash output-types.sh storyboard <type> --prompt \"...\"                  Generate storyboard (JSON)"
  echo ""
  echo "Output types:"
  echo "  broll       B-roll footage (5-10s, no text)"
  echo "  aroll       A-roll main content (15-60s, captions)"
  echo "  promotion   Sales/promo (15-30s, hook+CTA)"
  echo "  education   Tutorial/how-to (30-90s, steps)"
  echo "  raw         Raw unedited footage"
  echo "  lofi        Lo-fi aesthetic (15-30s, vintage)"
  echo "  channel     Channel-optimized (auto-adapt)"
  echo "  podcast     Podcast clip (30-60s, waveform)"
  echo "  ip          IP/character content"
  echo "  ugc         UGC-style (15-30s, authentic)"
  echo "  hero        Hero image/video (premium)"
  echo "  carousel    Multi-slide carousel (2-10 images)"
  echo ""
  echo "Generation tools:"
  echo "  --kling     Kling AI video (API)"
  echo "  --sora      OpenAI Sora 2 video (API)"
  echo "  --zimage    Z-Image Turbo image (MCP)"
  echo ""
  echo "Examples:"
  echo "  bash output-types.sh specs broll"
  echo "  bash output-types.sh generate promotion --prompt \"GAIA oat milk launch\" --kling"
  echo "  bash output-types.sh storyboard education --prompt \"How to make tempeh rendang\""
}

# --- Main ---
if [ $# -eq 0 ]; then
  show_usage
  exit 0
fi

# Check data file exists
if [ ! -f "$DATA_FILE" ]; then
  echo "ERROR: Output types data file not found: $DATA_FILE"
  echo "Expected JSON array of output type definitions."
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  list)       cmd_list "$@" ;;
  specs)      cmd_specs "$@" ;;
  generate)   cmd_generate "$@" ;;
  storyboard) cmd_storyboard "$@" ;;
  help|--help|-h)
    show_usage
    ;;
  *)
    echo "Unknown command: $COMMAND"
    echo ""
    show_usage
    exit 1
    ;;
esac
