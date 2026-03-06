#!/usr/bin/env bash
# video-director.sh — AI Video Director: storyboard → generate → assemble → review
# Part of GAIA CORP-OS creative pipeline
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"
OPENCLAW_DIR="$HOME/.openclaw"
LEARNINGS_DIR="$OPENCLAW_DIR/workspace/data/learnings"
RESOLVE_SCRIPT="$LEARNINGS_DIR/resolve-learnings.py"
VIDEO_GEN="$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh"
VIDEO_FORGE="$OPENCLAW_DIR/skills/video-forge/scripts/video-forge.sh"
VIDEO_EYE="$OPENCLAW_DIR/skills/video-eye/scripts/video-eye.sh"
BRANDS_DIR="$OPENCLAW_DIR/brands"
VIDEOS_DIR="$OPENCLAW_DIR/workspace/data/videos"
LOG_FILE="$OPENCLAW_DIR/workspace/logs/video-director.log"

# Load API keys from .env + secrets
if [ -f "$OPENCLAW_DIR/.env" ]; then
  set -a; source "$OPENCLAW_DIR/.env" 2>/dev/null; set +a
fi
[ -z "${GEMINI_API_KEY:-}" ] && [ -f "$OPENCLAW_DIR/secrets/gemini.env" ] && \
  export "$(grep '^GEMINI_API_KEY=' "$OPENCLAW_DIR/secrets/gemini.env" | head -1)" 2>/dev/null || true

# Support both GEMINI_API_KEY and GOOGLE_API_KEY
if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
  export GEMINI_API_KEY="$GOOGLE_API_KEY"
fi
GEMINI_API_KEY="${GEMINI_API_KEY:-}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
info() { echo "[$1] $2"; log "$1: $2"; }
error() { echo "ERROR: $*" >&2; log "ERROR: $*"; }
die() { error "$@"; exit 1; }

# ─── NARRATIVE TEMPLATES ───────────────────────────────────────────────
# Each template defines shot sequence with narrative beats
get_narrative_template() {
  local template="$1"
  case "$template" in
    hook-build-climax-cta)
      cat <<'TMPL'
[
  {"beat": "hook", "purpose": "Grab attention in first 2s", "duration_pct": 0.13, "energy": "high", "model_hint": "depends_on_content"},
  {"beat": "build", "purpose": "Show product beauty, create interest", "duration_pct": 0.27, "energy": "medium", "model_hint": "kling"},
  {"beat": "climax", "purpose": "Hero moment — the money shot", "duration_pct": 0.33, "energy": "high", "model_hint": "depends_on_content"},
  {"beat": "detail", "purpose": "Close-up texture, ingredients, quality proof", "duration_pct": 0.13, "energy": "low", "model_hint": "kling"},
  {"beat": "cta", "purpose": "Call to action — where to buy, swipe up", "duration_pct": 0.14, "energy": "medium", "model_hint": "kling"}
]
TMPL
      ;;
    problem-solution)
      cat <<'TMPL'
[
  {"beat": "pain", "purpose": "Show the problem the audience faces", "duration_pct": 0.20, "energy": "low", "model_hint": "sora"},
  {"beat": "discovery", "purpose": "Discover the product as solution", "duration_pct": 0.20, "energy": "medium", "model_hint": "sora"},
  {"beat": "transformation", "purpose": "Show product in action, solving the problem", "duration_pct": 0.35, "energy": "high", "model_hint": "depends_on_content"},
  {"beat": "result", "purpose": "Happy outcome, satisfied customer", "duration_pct": 0.15, "energy": "high", "model_hint": "sora"},
  {"beat": "cta", "purpose": "Call to action", "duration_pct": 0.10, "energy": "medium", "model_hint": "kling"}
]
TMPL
      ;;
    reveal)
      cat <<'TMPL'
[
  {"beat": "mystery", "purpose": "Tease — show hints without revealing", "duration_pct": 0.20, "energy": "medium", "model_hint": "kling"},
  {"beat": "tease", "purpose": "Build anticipation, almost show it", "duration_pct": 0.20, "energy": "medium", "model_hint": "kling"},
  {"beat": "reveal", "purpose": "Full product reveal — hero moment", "duration_pct": 0.30, "energy": "high", "model_hint": "kling"},
  {"beat": "details", "purpose": "Show features, ingredients, quality", "duration_pct": 0.20, "energy": "low", "model_hint": "kling"},
  {"beat": "cta", "purpose": "Where to get it", "duration_pct": 0.10, "energy": "medium", "model_hint": "kling"}
]
TMPL
      ;;
    day-in-life)
      cat <<'TMPL'
[
  {"beat": "morning", "purpose": "Set the scene — relatable daily life", "duration_pct": 0.20, "energy": "low", "model_hint": "sora"},
  {"beat": "activity", "purpose": "Daily activity leading to product use", "duration_pct": 0.20, "energy": "medium", "model_hint": "sora"},
  {"beat": "product_use", "purpose": "Natural product integration", "duration_pct": 0.30, "energy": "medium", "model_hint": "depends_on_content"},
  {"beat": "enjoyment", "purpose": "Satisfaction, pleasure, results", "duration_pct": 0.20, "energy": "high", "model_hint": "sora"},
  {"beat": "cta", "purpose": "Subtle CTA — brand mention", "duration_pct": 0.10, "energy": "low", "model_hint": "kling"}
]
TMPL
      ;;
    before-after)
      cat <<'TMPL'
[
  {"beat": "before", "purpose": "Show current unsatisfying state", "duration_pct": 0.25, "energy": "low", "model_hint": "sora"},
  {"beat": "transition", "purpose": "The change moment — product introduction", "duration_pct": 0.15, "energy": "high", "model_hint": "depends_on_content"},
  {"beat": "after", "purpose": "Transformed, improved state", "duration_pct": 0.35, "energy": "high", "model_hint": "depends_on_content"},
  {"beat": "proof", "purpose": "Evidence, details, close-up quality", "duration_pct": 0.15, "energy": "medium", "model_hint": "kling"},
  {"beat": "cta", "purpose": "Call to action", "duration_pct": 0.10, "energy": "medium", "model_hint": "kling"}
]
TMPL
      ;;
    *)
      die "Unknown narrative template: $template. Available: hook-build-climax-cta, problem-solution, reveal, day-in-life, before-after"
      ;;
  esac
}

# ─── MODEL COST CALCULATOR ─────────────────────────────────────────────
estimate_cost() {
  local model="$1" duration="$2" tier="${3:-standard}"
  case "$model" in
    kling)
      if [ "$tier" = "pro" ]; then
        echo "scale=2; $duration * 0.14" | bc
      else
        echo "scale=2; $duration * 0.056" | bc
      fi
      ;;
    sora)
      # Sora charges per clip: ~$0.10/s
      echo "scale=2; $duration * 0.10" | bc
      ;;
    wan)
      echo "scale=2; $duration * 0.03" | bc
      ;;
    *) echo "0.00" ;;
  esac
}

# ─── RESOLVE LEARNINGS ─────────────────────────────────────────────────
resolve_learnings() {
  local brand="$1" format="${2:-flat}"
  if [ -f "$RESOLVE_SCRIPT" ]; then
    python3 "$RESOLVE_SCRIPT" --brand "$brand" --format "$format" 2>/dev/null
  else
    echo "No compound learnings available"
  fi
}

# ─── FIND REF IMAGES ───────────────────────────────────────────────────
find_ref_image() {
  local brand="$1" product="$2"
  local brand_dir="$BRANDS_DIR/$brand/references"

  # Try composite first (best for video gen)
  local composite
  composite=$(find "$brand_dir/products-composite" -iname "*${product}*" 2>/dev/null | head -1)
  if [ -n "$composite" ]; then echo "$composite"; return; fi

  # Try products directory
  local product_img
  product_img=$(find "$brand_dir/products" -iname "*${product}*" 2>/dev/null | head -1)
  if [ -n "$product_img" ]; then echo "$product_img"; return; fi

  # Try any reference
  find "$brand_dir" -iname "*${product}*" -type f 2>/dev/null | head -1
}

# ─── SORA DURATION HELPER ──────────────────────────────────────────────
# Sora only supports 4, 8, or 12 seconds
nearest_sora_duration() {
  local target="$1"
  if [ "$target" -le 6 ]; then echo "4"
  elif [ "$target" -le 10 ]; then echo "8"
  else echo "12"
  fi
}

# ─── STORYBOARD COMMAND ────────────────────────────────────────────────
cmd_storyboard() {
  local brand="" concept="" duration=30 platform="reels" style="cinematic" narrative="hook-build-climax-cta" product=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      --concept) concept="$2"; shift 2 ;;
      --duration) duration="$2"; shift 2 ;;
      --platform) platform="$2"; shift 2 ;;
      --style) style="$2"; shift 2 ;;
      --narrative) narrative="$2"; shift 2 ;;
      --product) product="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$brand" ] && die "Missing --brand"
  [ -z "$concept" ] && die "Missing --concept"

  info "STORYBOARD" "Brand: $brand | Concept: $concept | ${duration}s | $platform"

  # Step 1: Load compound learnings
  info "LEARNINGS" "Loading compound learnings for $brand..."
  local learnings
  learnings=$(resolve_learnings "$brand" "flat")

  # Step 2: Get narrative template
  info "NARRATIVE" "Template: $narrative"
  local template_json
  template_json=$(get_narrative_template "$narrative")

  # Step 3: Find ref images
  local ref_image=""
  if [ -n "$product" ]; then
    ref_image=$(find_ref_image "$brand" "$product")
    if [ -n "$ref_image" ]; then
      info "REF" "Found: $ref_image"
    fi
  fi

  # Step 4: Load brand DNA
  local dna_file="$BRANDS_DIR/$brand/DNA.json"
  local brand_context=""
  if [ -f "$dna_file" ]; then
    brand_context=$(python3 -c "
import json
d = json.load(open('$dna_file'))
parts = []
if 'visual' in d: parts.append('Visual: ' + json.dumps(d['visual']))
if 'tone' in d: parts.append('Tone: ' + str(d.get('tone','')))
if 'colors' in d: parts.append('Colors: ' + json.dumps(d.get('colors',d.get('visual',{}).get('colors',[]))))
print(' | '.join(parts[:3]))
" 2>/dev/null || echo "")
  fi

  # Step 5: Generate storyboard via Gemini
  if [ -z "$GEMINI_API_KEY" ]; then
    die "GEMINI_API_KEY not set. Needed for storyboard intelligence."
  fi

  info "GENERATE" "Creating storyboard via Gemini..."

  local output_dir="$VIDEOS_DIR/${brand}-director-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$output_dir"

  local storyboard_file="$output_dir/storyboard.json"

  # Build the prompt for Gemini
  local prompt
  prompt=$(cat <<PROMPT_END
You are a professional video director creating a shot-by-shot storyboard for an AI-generated video ad.

BRAND: $brand
CONCEPT: $concept
TARGET DURATION: ${duration} seconds
PLATFORM: $platform (9:16 portrait)
STYLE: $style
NARRATIVE STRUCTURE: $narrative
${ref_image:+REFERENCE IMAGE: $ref_image}
${brand_context:+BRAND CONTEXT: $brand_context}

NARRATIVE TEMPLATE (use these beats):
$template_json

COMPOUND LEARNINGS (MUST follow these rules):
$learnings

MODEL SELECTION RULES:
- "kling" (Kling v3): Best for food close-ups, texture, physical interactions, product shots. Cost ~\$0.056/s standard, ~\$0.14/s pro.
- "sora" (Sora 2): Best for UGC feel, human movement, wide shots, lifestyle scenes. Cost ~\$0.10/s. ONLY supports 4s, 8s, or 12s durations.
- Default to "kling" for food brands unless shot involves a person.

DURATION RULES:
- Sora ONLY supports exactly 4, 8, or 12 seconds. Pick the closest.
- Kling supports 5 or 10 seconds. Pick the closest.
- Total shot durations should sum to approximately ${duration}s (allow 0.5s crossfade between shots).

OUTPUT FORMAT: Return ONLY valid JSON (no markdown, no explanation) with this structure:
{
  "brand": "$brand",
  "concept": "$concept",
  "platform": "$platform",
  "duration_target_s": $duration,
  "narrative": "$narrative",
  "style": "$style",
  "music": {
    "mood": "descriptive mood for background music",
    "bpm_range": [low, high],
    "drop_at_s": number_where_energy_peaks
  },
  "shots": [
    {
      "id": 1,
      "name": "short_name",
      "duration_s": number,
      "model": "kling|sora",
      "model_tier": "standard|pro",
      "narrative_beat": "beat_name",
      "description": "what happens in this shot",
      "prompt": "FULL generation prompt ready for the model. Include: With audio. [SKU REFERENCE: ...if ref image]. Scene description. Camera. Lighting. Motion. All learnings applied.",
      "camera": "camera angle and movement",
      "lighting": "lighting setup",
      "motion": "what moves in the shot",
      "transition_out": "crossfade 0.5s|cut|none",
      "ref_image": "${ref_image:-null}",
      "cost_estimate": number,
      "learnings_applied": ["list of learnings applied to this shot"]
    }
  ],
  "total_cost_estimate": number,
  "assembly": {
    "resolution": "1080x1920",
    "fps": 30,
    "format": "mp4",
    "transitions": "crossfade"
  }
}

Make the prompts DETAILED and SPECIFIC. Each prompt should be self-contained — ready to paste into the generation model. Apply ALL learnings (no steam for bento, no zoom, one continuous shot per clip, etc.).
PROMPT_END
)

  # Call Gemini API via temp file (avoids quote escaping issues)
  local prompt_file="/tmp/vd-prompt-$$.txt"
  echo "$prompt" > "$prompt_file"

  local response
  response=$(python3 - "$prompt_file" "$GEMINI_API_KEY" <<'PYEOF'
import json, urllib.request, sys, os

prompt_file = sys.argv[1]
api_key = sys.argv[2]

with open(prompt_file) as f:
    prompt_text = f.read()

url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}'

payload = {
    'contents': [{'parts': [{'text': prompt_text}]}],
    'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 8192,
        'responseMimeType': 'application/json'
    }
}

req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
try:
    resp = urllib.request.urlopen(req, timeout=60)
    data = json.loads(resp.read())
    text = data['candidates'][0]['content']['parts'][0]['text']
    # Strip markdown fences if present
    import re
    text = re.sub(r'^```(?:json)?\s*\n?', '', text.strip())
    text = re.sub(r'\n?```\s*$', '', text.strip())
    parsed = json.loads(text)
    print(json.dumps(parsed, indent=2))
except urllib.error.HTTPError as e:
    print(f'HTTP {e.code}: {e.read().decode()[:500]}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
PYEOF
  )

  rm -f "$prompt_file"

  if echo "$response" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    echo "$response" > "$storyboard_file"

    # Display summary
    local num_shots total_cost
    num_shots=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('shots',[])))")
    total_cost=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('total_cost_estimate','?'))")

    info "STORYBOARD" "Generated: $num_shots shots, estimated cost: \$$total_cost"
    info "FILE" "$storyboard_file"

    # Print shot breakdown
    echo ""
    echo "=== SHOT BREAKDOWN ==="
    echo "$response" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for s in d.get('shots', []):
    print(f\"  Shot {s['id']}: {s['name']} | {s['duration_s']}s | {s['model']} | {s['narrative_beat']}\")
    print(f\"    → {s['description'][:80]}...\")
print(f\"\n  Total: {sum(s['duration_s'] for s in d['shots'])}s | Budget: \${d.get('total_cost_estimate', '?')}\")
"
    echo ""
    echo "$storyboard_file"
  else
    error "Failed to generate storyboard. Gemini response:"
    echo "$response" >&2
    exit 1
  fi
}

# ─── DIRECT COMMAND ─────────────────────────────────────────────────────
cmd_direct() {
  local storyboard="" brand="" parallel=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --storyboard) storyboard="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      --parallel) parallel=true; shift ;;
      *) shift ;;
    esac
  done

  [ -z "$storyboard" ] && die "Missing --storyboard <file>"
  [ ! -f "$storyboard" ] && die "Storyboard not found: $storyboard"

  local output_dir
  output_dir="$(dirname "$storyboard")"

  # Read storyboard
  if [ -z "$brand" ]; then
    brand=$(python3 -c "import json; print(json.load(open('$storyboard')).get('brand',''))")
  fi

  info "DIRECT" "Executing storyboard for $brand"

  local num_shots
  num_shots=$(python3 -c "import json; print(len(json.load(open('$storyboard')).get('shots',[])))")

  info "SHOTS" "$num_shots shots to generate"

  # Generate each shot
  local shot_files=()
  local total_cost=0

  for i in $(seq 0 $((num_shots - 1))); do
    local shot_json
    shot_json=$(python3 -c "
import json
d = json.load(open('$storyboard'))
s = d['shots'][$i]
print(json.dumps(s))
")

    local shot_id shot_name model duration prompt ref_image model_tier
    shot_id=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
    shot_name=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['name'])")
    model=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['model'])")
    duration=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['duration_s'])")
    prompt=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])")
    ref_image=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('ref_image','') or '')")
    model_tier=$(echo "$shot_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('model_tier','standard'))")

    local output_file="$output_dir/shot${shot_id}_${shot_name}.mp4"

    info "SHOT $shot_id" "$shot_name | ${duration}s | $model ($model_tier)"

    # Generate based on model
    case "$model" in
      kling)
        if [ -n "$ref_image" ] && [ "$ref_image" != "null" ] && [ -f "$ref_image" ]; then
          # Image-to-video
          info "SHOT $shot_id" "Kling image2video with ref: $ref_image"
          bash "$VIDEO_GEN" kling image2video \
            --image "$ref_image" \
            --prompt "$prompt" \
            --duration "$duration" \
            --output "$output_file" \
            --mode "$model_tier" 2>&1 | while read -r line; do echo "  [$shot_name] $line"; done
        else
          # Text-to-video
          info "SHOT $shot_id" "Kling text2video"
          bash "$VIDEO_GEN" kling text2video \
            "$prompt" \
            --duration "$duration" \
            --output "$output_file" \
            --mode "$model_tier" 2>&1 | while read -r line; do echo "  [$shot_name] $line"; done
        fi
        ;;
      sora)
        local sora_dur
        sora_dur=$(nearest_sora_duration "$duration")

        if [ -n "$ref_image" ] && [ "$ref_image" != "null" ] && [ -f "$ref_image" ]; then
          info "SHOT $shot_id" "Sora image2video (${sora_dur}s) with ref"
          bash "$VIDEO_GEN" sora image2video \
            --image "$ref_image" \
            --prompt "$prompt" \
            --duration "$sora_dur" \
            --size "720x1280" \
            --output "$output_file" 2>&1 | while read -r line; do echo "  [$shot_name] $line"; done
        else
          info "SHOT $shot_id" "Sora generate (${sora_dur}s)"
          bash "$VIDEO_GEN" sora generate \
            "$prompt" \
            --duration "$sora_dur" \
            --size "720x1280" \
            --output "$output_file" 2>&1 | while read -r line; do echo "  [$shot_name] $line"; done
        fi
        ;;
      wan)
        info "SHOT $shot_id" "Wan text2video"
        bash "$VIDEO_GEN" wan text2video \
          "$prompt" \
          --duration "$duration" \
          --output "$output_file" 2>&1 | while read -r line; do echo "  [$shot_name] $line"; done
        ;;
      *)
        error "Unknown model: $model for shot $shot_id"
        continue
        ;;
    esac

    if [ -f "$output_file" ]; then
      shot_files+=("$output_file")
      local cost
      cost=$(estimate_cost "$model" "$duration" "$model_tier")
      total_cost=$(echo "$total_cost + $cost" | bc)
      info "SHOT $shot_id" "Done: $output_file (~\$$cost)"
    else
      error "Shot $shot_id failed to generate"
    fi
  done

  info "GENERATION" "Complete: ${#shot_files[@]}/$num_shots shots generated (~\$$total_cost)"

  # Assemble if we have shots
  if [ ${#shot_files[@]} -ge 2 ]; then
    info "ASSEMBLY" "Assembling ${#shot_files[@]} shots..."

    local assembled="$output_dir/assembled.mp4"
    local filelist="$output_dir/filelist.txt"

    # Normalize all clips first
    local normalized_files=()
    for f in "${shot_files[@]}"; do
      local norm_f="${f%.mp4}_norm.mp4"
      ffmpeg -y -i "$f" \
        -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,fps=30,format=yuv420p" \
        -c:v libx264 -preset fast -crf 23 \
        -c:a aac -b:a 128k -ar 44100 -ac 2 \
        -shortest \
        "$norm_f" 2>/dev/null
      if [ -f "$norm_f" ]; then
        normalized_files+=("$norm_f")
      else
        normalized_files+=("$f")
      fi
    done

    # Build concat file
    > "$filelist"
    for f in "${normalized_files[@]}"; do
      echo "file '$f'" >> "$filelist"
    done

    ffmpeg -y -f concat -safe 0 -i "$filelist" \
      -c:v libx264 -preset fast -crf 23 \
      -c:a aac -b:a 128k \
      "$assembled" 2>/dev/null

    if [ -f "$assembled" ]; then
      local final_dur
      final_dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$assembled" 2>/dev/null | cut -d. -f1)
      info "ASSEMBLED" "$assembled (${final_dur}s, ~\$$total_cost)"

      # Clean up normalized files
      for f in "${normalized_files[@]}"; do
        [[ "$f" == *_norm.mp4 ]] && rm -f "$f"
      done

      echo "$assembled"
    else
      error "Assembly failed"
    fi
  elif [ ${#shot_files[@]} -eq 1 ]; then
    info "OUTPUT" "Single shot: ${shot_files[0]}"
    echo "${shot_files[0]}"
  else
    error "No shots generated"
    exit 1
  fi
}

# ─── REVERSE PROMPT COMMAND ─────────────────────────────────────────────
cmd_reverse_prompt() {
  local video="" depth="deep"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --video) video="$2"; shift 2 ;;
      --depth) depth="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$video" ] && die "Missing --video <file>"
  [ ! -f "$video" ] && die "Video not found: $video"

  info "REVERSE" "Analyzing: $video (depth: $depth)"

  # Extract frames for analysis
  local work_dir="/tmp/vd-reverse-$$"
  mkdir -p "$work_dir"

  # Extract 1 frame per second
  ffmpeg -y -i "$video" -vf "fps=1" "$work_dir/frame_%04d.jpg" 2>/dev/null
  local frame_count
  frame_count=$(ls "$work_dir"/frame_*.jpg 2>/dev/null | wc -l | tr -d ' ')

  info "FRAMES" "Extracted $frame_count frames"

  # Get video duration and metadata
  local duration
  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video" 2>/dev/null | cut -d. -f1)

  # Use Gemini Vision for deep analysis
  if [ -n "$GEMINI_API_KEY" ]; then
    # Pick key frames (first, 25%, 50%, 75%, last)
    local frames_to_analyze=()
    if [ "$frame_count" -ge 5 ]; then
      local q1=$((frame_count / 4)) q2=$((frame_count / 2)) q3=$((frame_count * 3 / 4))
      frames_to_analyze=("$work_dir/frame_0001.jpg" "$work_dir/frame_$(printf '%04d' $q1).jpg" "$work_dir/frame_$(printf '%04d' $q2).jpg" "$work_dir/frame_$(printf '%04d' $q3).jpg" "$work_dir/frame_$(printf '%04d' $frame_count).jpg")
    else
      frames_to_analyze=("$work_dir"/frame_*.jpg)
    fi

    info "ANALYZING" "Sending ${#frames_to_analyze[@]} key frames to Gemini Vision..."

    # Upload frames and analyze
    python3 -c "
import json, os, sys, base64, urllib.request

api_key = os.environ.get('GEMINI_API_KEY') or os.environ.get('GOOGLE_AI_KEY', '')
frames = ${frames_to_analyze[@]+"$(printf "'%s'," "${frames_to_analyze[@]}" | sed 's/,$//')"}
frame_list = [f.strip(\"'\") for f in ['$( IFS=,; echo "${frames_to_analyze[*]}" )'.replace(' ', '').split(',')]] if ',' in '$( IFS=,; echo "${frames_to_analyze[*]}" )' else ['${frames_to_analyze[0]}']

parts = [{'text': '''Analyze this video (${duration}s, ${frame_count} frames). For each frame, describe:

1. SCENE: What's happening, subjects, objects, setting
2. CAMERA: Angle, movement, framing (close-up/medium/wide)
3. LIGHTING: Type, direction, color temperature, mood
4. COLOR PALETTE: Dominant colors, grading style
5. MOTION: What moves, speed, direction
6. EMOTION: Mood, energy level (1-10)

Then provide OVERALL analysis:
- NARRATIVE STRUCTURE: How the story flows
- PACING/TEMPO: Shot rhythm, energy curve
- TRANSITIONS: How shots connect
- MUSIC SUGGESTION: BPM, mood, genre that would fit
- STYLE: Visual style keywords
- STRENGTHS: What works well
- WEAKNESSES: What could improve
- REPRODUCTION PROMPT: If you had to recreate this video using AI, what would the storyboard look like? Give shot-by-shot prompts.

Return as structured JSON.'''}]

for fp in frame_list:
    if os.path.isfile(fp):
        with open(fp, 'rb') as f:
            b64 = base64.b64encode(f.read()).decode()
        parts.append({'inline_data': {'mime_type': 'image/jpeg', 'data': b64}})

url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}'
payload = {
    'contents': [{'parts': parts}],
    'generationConfig': {'temperature': 0.5, 'maxOutputTokens': 4096}
}

req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
resp = urllib.request.urlopen(req, timeout=60)
data = json.loads(resp.read())
text = data['candidates'][0]['content']['parts'][0]['text']
print(text)
" 2>&1
  else
    # Fallback: use video-eye if available
    if [ -f "$VIDEO_EYE" ]; then
      bash "$VIDEO_EYE" quick "$video"
    else
      error "No Gemini API key and video-eye not found"
    fi
  fi

  # Cleanup
  rm -rf "$work_dir"
}

# ─── REVIEW COMMAND ─────────────────────────────────────────────────────
cmd_review() {
  local video="" storyboard=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --video) video="$2"; shift 2 ;;
      --storyboard) storyboard="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$video" ] && die "Missing --video"
  [ -z "$storyboard" ] && die "Missing --storyboard"

  info "REVIEW" "Comparing output to storyboard..."

  # Extract key metrics
  local duration
  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video" 2>/dev/null)
  local target_dur
  target_dur=$(python3 -c "import json; print(json.load(open('$storyboard')).get('duration_target_s',30))")

  echo "=== VIDEO REVIEW ==="
  echo "  Duration: ${duration}s (target: ${target_dur}s)"
  echo "  Storyboard: $storyboard"
  echo "  Video: $video"
  echo ""

  # Use Gemini Vision to compare
  if [ -n "$GEMINI_API_KEY" ]; then
    local work_dir="/tmp/vd-review-$$"
    mkdir -p "$work_dir"
    ffmpeg -y -i "$video" -vf "fps=2" "$work_dir/frame_%04d.jpg" 2>/dev/null

    local storyboard_content
    storyboard_content=$(cat "$storyboard")

    python3 -c "
import json, os, sys, base64, urllib.request, glob

api_key = os.environ.get('GEMINI_API_KEY') or os.environ.get('GOOGLE_AI_KEY', '')
frames = sorted(glob.glob('$work_dir/frame_*.jpg'))[:10]  # Max 10 frames

storyboard = json.loads('''$storyboard_content''')

parts = [{'text': f'''Review this generated video against the storyboard.

STORYBOARD:
{json.dumps(storyboard, indent=2)}

Score each shot on:
1. PROMPT ADHERENCE (0-10): Does it match the prompt?
2. VISUAL QUALITY (0-10): Resolution, artifacts, realism
3. FOOD ACCURACY (0-10): Does food look appetizing and correct? (if applicable)
4. MOTION QUALITY (0-10): Natural movement, no AI tells
5. NARRATIVE FLOW (0-10): Does the sequence tell a story?

Overall score (0-100) and specific improvement suggestions.
Return as JSON with per-shot scores and overall.'''}]

for fp in frames:
    with open(fp, 'rb') as f:
        b64 = base64.b64encode(f.read()).decode()
    parts.append({'inline_data': {'mime_type': 'image/jpeg', 'data': b64}})

url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}'
payload = {
    'contents': [{'parts': parts}],
    'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 4096}
}

req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
resp = urllib.request.urlopen(req, timeout=60)
data = json.loads(resp.read())
print(data['candidates'][0]['content']['parts'][0]['text'])
" 2>&1

    rm -rf "$work_dir"
  else
    echo "  (Gemini Vision not available — manual review needed)"
  fi
}

# ─── LEARN COMMAND ──────────────────────────────────────────────────────
cmd_learn() {
  local review="" brand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --review) review="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$brand" ] && die "Missing --brand"

  info "LEARN" "Feeding review into compound learnings for $brand..."

  # If review is a file, read it; otherwise use stdin
  local review_content=""
  if [ -n "$review" ] && [ -f "$review" ]; then
    review_content=$(cat "$review")
  else
    review_content="$review"
  fi

  local brand_learnings="$LEARNINGS_DIR/brand/$brand.json"
  if [ -f "$brand_learnings" ]; then
    # Append to history
    python3 -c "
import json, sys
from datetime import datetime

f = '$brand_learnings'
d = json.load(open(f))
d.setdefault('history', []).append({
    'date': datetime.now().strftime('%Y-%m-%d %H:%M'),
    'type': 'video-director-review',
    'summary': '''$review_content'''[:500]
})
d['review_count'] = d.get('review_count', 0) + 1
d['updated'] = datetime.now().strftime('%Y-%m-%d %H:%M')
json.dump(d, open(f, 'w'), indent=2)
print(f'Updated {f} (review #{d[\"review_count\"]})')
" 2>&1
  else
    info "LEARN" "No brand learnings file at $brand_learnings — creating..."
  fi
}

# ─── PRODUCE COMMAND (FULL PIPELINE) ───────────────────────────────────
cmd_produce() {
  local brand="" concept="" duration=30 platform="reels" style="cinematic" narrative="hook-build-climax-cta" product=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      --concept) concept="$2"; shift 2 ;;
      --duration) duration="$2"; shift 2 ;;
      --platform) platform="$2"; shift 2 ;;
      --style) style="$2"; shift 2 ;;
      --narrative) narrative="$2"; shift 2 ;;
      --product) product="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$brand" ] && die "Missing --brand"
  [ -z "$concept" ] && die "Missing --concept"

  info "PRODUCE" "Full pipeline: storyboard → generate → assemble"
  echo ""

  # Step 1: Storyboard
  info "STEP 1/3" "Generating storyboard..."
  local storyboard_output
  storyboard_output=$(cmd_storyboard --brand "$brand" --concept "$concept" --duration "$duration" --platform "$platform" --style "$style" --narrative "$narrative" ${product:+--product "$product"})

  local storyboard_file
  storyboard_file=$(echo "$storyboard_output" | tail -1)

  if [ ! -f "$storyboard_file" ]; then
    die "Storyboard generation failed"
  fi

  echo ""

  # Show budget and ask to proceed
  local budget
  budget=$(python3 -c "import json; print(json.load(open('$storyboard_file')).get('total_cost_estimate','?'))")
  info "BUDGET" "Estimated cost: \$$budget"
  echo ""

  # Step 2: Generate + Assemble
  info "STEP 2/3" "Generating shots..."
  local assembled_output
  assembled_output=$(cmd_direct --storyboard "$storyboard_file" --brand "$brand")

  local assembled_file
  assembled_file=$(echo "$assembled_output" | tail -1)

  echo ""

  # Step 3: Review (optional, non-blocking)
  if [ -f "$assembled_file" ] && [ -n "$GEMINI_API_KEY" ]; then
    info "STEP 3/3" "Auto-reviewing..."
    cmd_review --video "$assembled_file" --storyboard "$storyboard_file"
  fi

  echo ""
  info "DONE" "Video: $assembled_file"
  info "DONE" "Storyboard: $storyboard_file"
}

# ─── USAGE ──────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
video-director.sh — AI Video Director

COMMANDS:
  storyboard   Generate shot-by-shot storyboard from concept
  direct       Execute storyboard (generate all shots + assemble)
  reverse-prompt  Deep-analyze a reference video
  review       Compare generated video against storyboard
  learn        Feed review into compound learnings
  produce      Full pipeline (storyboard → generate → assemble → review)

EXAMPLES:
  video-director.sh storyboard --brand mirra --concept "Curry Katsu Rice" --duration 30 --platform reels
  video-director.sh direct --storyboard storyboard.json --brand mirra
  video-director.sh produce --brand mirra --concept "Curry Katsu Rice" --duration 30
  video-director.sh reverse-prompt --video reference.mp4
  video-director.sh review --video output.mp4 --storyboard storyboard.json

OPTIONS:
  --brand       Brand name (required for most commands)
  --concept     Video concept/brief
  --duration    Target duration in seconds (default: 30)
  --platform    Target platform: reels, tiktok, shorts, feed (default: reels)
  --style       Visual style: cinematic, ugc, minimal, bold (default: cinematic)
  --narrative   Story structure: hook-build-climax-cta, problem-solution, reveal, day-in-life, before-after
  --product     Product name (for finding ref images)
EOF
}

# ─── MAIN ───────────────────────────────────────────────────────────────
main() {
  mkdir -p "$(dirname "$LOG_FILE")"

  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    storyboard) cmd_storyboard "$@" ;;
    direct) cmd_direct "$@" ;;
    reverse-prompt|reverse_prompt) cmd_reverse_prompt "$@" ;;
    review) cmd_review "$@" ;;
    learn) cmd_learn "$@" ;;
    produce) cmd_produce "$@" ;;
    help|--help|-h) usage ;;
    *) error "Unknown command: $cmd"; usage; exit 1 ;;
  esac
}

main "$@"
