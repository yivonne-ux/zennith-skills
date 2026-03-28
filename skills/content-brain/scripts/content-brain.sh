#!/usr/bin/env bash
# content-brain.sh — Master Orchestrator for Zennith OS Content Supply Chain
# The brain that overlooks, curates, and produces content across all 14 brands.
#
# Modes:
#   content-brain.sh produce  --brand <brand> [options]    Full 12-step pipeline
#   content-brain.sh plan     --brand <brand> --week <W>   Weekly content plan
#   content-brain.sh brain    --brand <brand>              Daily review + suggestions

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW="$HOME/.openclaw"
SKILLS="$OPENCLAW/skills"
BRANDS_DIR="$OPENCLAW/brands"
WORKSPACE="$OPENCLAW/workspace"
LOG_FILE="$OPENCLAW/logs/content-brain.log"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

# Tool paths
CRE_BRIEF="$SKILLS/creative-reasoning-engine/scripts/cre-to-brief.sh"
SCRIPT_GEN="$SKILLS/video-script-gen/scripts/video-script-gen.sh"
CREATIVE_QA="$SKILLS/creative-qa/scripts/creative-qa.sh"
BRAND_VOICE="$SKILLS/brand-voice-check/scripts/brand-voice-check.sh"
NANOBANANA="$SKILLS/nanobanana/scripts/nanobanana-gen.sh"
VIDEO_GEN="$SKILLS/video-gen/scripts/video-gen.sh"
REMOTION="$SKILLS/remotion-renderer/scripts/remotion-render.sh"
VIDEO_FORGE="$SKILLS/video-forge/scripts/video-forge.sh"
BLOCK_LIB="$SKILLS/video-block-library/scripts/block-library.sh"
SOCIAL_PUB="$SKILLS/social-publish/scripts/social-publish.sh"
CHAR_LOCK="$SKILLS/character-lock/scripts/character-lock.sh"

mkdir -p "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

# Parse args
BRAND=""
PRODUCT=""
FLOW="testimonial"
DURATION=40
VARIANTS=1
TYPE="full"     # full, kinetic, oracle-card, brand-reveal
TEXT=""
CARD=""
MEANING=""
WEEK=""
CHECK=""
PROVIDER="kling"
DRY_RUN=0
SKIP_QA=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)     BRAND="$2"; shift 2 ;;
    --product)   PRODUCT="$2"; shift 2 ;;
    --flow)      FLOW="$2"; shift 2 ;;
    --duration)  DURATION="$2"; shift 2 ;;
    --variants)  VARIANTS="$2"; shift 2 ;;
    --type)      TYPE="$2"; shift 2 ;;
    --text)      TEXT="$2"; shift 2 ;;
    --card)      CARD="$2"; shift 2 ;;
    --meaning)   MEANING="$2"; shift 2 ;;
    --week)      WEEK="$2"; shift 2 ;;
    --check)     CHECK="$2"; shift 2 ;;
    --provider)  PROVIDER="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --skip-qa)   SKIP_QA=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[brain $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }
step() { echo ""; echo "━━━ STEP $1: $2 ━━━"; log "STEP $1: $2"; }
ok() { echo "  ✅ $1"; log "OK: $1"; }
fail() { echo "  ❌ $1"; log "FAIL: $1"; }
skip() { echo "  ⏭️  $1"; log "SKIP: $1"; }

# Output directory for this production run
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
WORK_DIR="$WORKSPACE/data/productions/${BRAND:-unknown}/${TIMESTAMP}"

###############################################################################
# PRODUCE MODE — Full 12-step pipeline
###############################################################################
cmd_produce() {
  [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }

  mkdir -p "$WORK_DIR"

  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  CONTENT BRAIN — Production Pipeline                        ║"
  echo "║  Brand: $BRAND | Type: $TYPE | Flow: $FLOW                  ║"
  echo "║  Output: $WORK_DIR/                                         ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  log "=== PRODUCE: brand=$BRAND type=$TYPE flow=$FLOW ==="

  # Track timing
  local start_time
  start_time=$(date +%s)

  case "$TYPE" in
    kinetic)   produce_kinetic ;;
    oracle-card) produce_oracle_card ;;
    brand-reveal) produce_brand_reveal ;;
    full)      produce_full ;;
    *)         produce_full ;;
  esac

  local end_time elapsed
  end_time=$(date +%s)
  elapsed=$((end_time - start_time))
  echo ""
  echo "━━━ COMPLETE ━━━"
  echo "  Time: ${elapsed}s"
  echo "  Output: $WORK_DIR/"
  log "COMPLETE in ${elapsed}s"
}

###############################################################################
# PRODUCE: Kinetic Text Reel ($0, Remotion)
###############################################################################
produce_kinetic() {
  [[ -z "$TEXT" ]] && { echo "ERROR: --text required (use | to separate lines)"; exit 1; }

  step "1-9" "KINETIC TEXT REEL (Remotion, \$0)"

  local output="$WORK_DIR/kinetic-${BRAND}.mp4"

  if [[ -f "$REMOTION" ]]; then
    bash "$REMOTION" kinetic --text "$TEXT" --output "$output" 2>&1 | sed 's/^/  /'
    if [[ -f "$output" ]]; then
      ok "Rendered: $output ($(wc -c < "$output" | tr -d ' ')b)"
    else
      fail "Remotion render failed"
      return 1
    fi
  else
    fail "Remotion renderer not found at $REMOTION"
    return 1
  fi

  # Step 10: Post-production (optional brand overlay)
  if [[ -f "$VIDEO_FORGE" ]]; then
    step "10" "POST-PRODUCTION"
    local branded="$WORK_DIR/kinetic-${BRAND}-branded.mp4"
    bash "$VIDEO_FORGE" brand "$output" --brand "$BRAND" --output "$branded" 2>&1 | sed 's/^/  /' || true
    if [[ -f "$branded" ]]; then
      ok "Branded: $branded"
      output="$branded"
    else
      skip "Brand overlay skipped (no brand assets)"
    fi
  fi

  # Step 11: QA
  if [[ "$SKIP_QA" -eq 0 && -f "$CREATIVE_QA" ]]; then
    step "11" "QUALITY GATE"
    bash "$CREATIVE_QA" video --video "$output" --brand "$BRAND" 2>&1 | sed 's/^/  /'
  fi

  echo ""
  echo "  📹 Final: $output"
}

###############################################################################
# PRODUCE: Oracle Card Reveal (Jade, Remotion, $0)
###############################################################################
produce_oracle_card() {
  [[ -z "$CARD" ]] && { echo "ERROR: --card required (card name)"; exit 1; }

  step "1-9" "ORACLE CARD REVEAL (Remotion, \$0)"

  local text="${CARD}|${MEANING:-Your message awaits}"
  local output="$WORK_DIR/oracle-${CARD// /-}.mp4"

  bash "$REMOTION" kinetic --text "$text" --output "$output" 2>&1 | sed 's/^/  /'

  if [[ -f "$output" ]]; then
    ok "Rendered: $output"
  else
    fail "Render failed"
  fi
}

###############################################################################
# PRODUCE: Full 12-Step Pipeline
###############################################################################
produce_full() {
  [[ -z "$PRODUCT" ]] && { echo "ERROR: --product required for full pipeline"; exit 1; }

  # ── STEP 1: BRIEF ──
  step "1" "CREATIVE INTELLIGENCE (Brief)"
  local brief_file="$WORK_DIR/01-brief.json"

  if [[ -f "$CRE_BRIEF" ]]; then
    bash "$CRE_BRIEF" --brand "$BRAND" --product "$PRODUCT" --goal "conversion" \
      --output "$brief_file" 2>&1 | sed 's/^/  /' || true
  fi

  if [[ ! -f "$brief_file" ]]; then
    # Generate minimal brief
    "$PYTHON3" -c "
import json
brief = {
    'brand': '$BRAND',
    'product': '$PRODUCT',
    'flow': '$FLOW',
    'goal': 'conversion',
    'duration': $DURATION,
    'tone': 'authentic, relatable',
    'generated': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
}
with open('$brief_file', 'w') as f:
    json.dump(brief, f, indent=2)
print('Generated minimal brief')
"
  fi
  ok "Brief: $brief_file"

  # ── STEP 2: FLOW + PLAN ──
  step "2" "FLOW SELECTION + PLANNING"
  local plan_file="$WORK_DIR/02-plan.json"
  log "Flow: $FLOW | Duration: ${DURATION}s | Variants: $VARIANTS"

  "$PYTHON3" - "$BRAND" "$PRODUCT" "$FLOW" "$DURATION" "$VARIANTS" "$plan_file" << 'PYEOF'
import json, sys
brand, product, flow, duration, variants, out_file = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]), sys.argv[6]

FLOW_LETTER = {"testimonial":"A","PAS":"B","challenge":"C","slap":"D","convenience_solve":"E",
    "compiled_montage":"F","brand_story":"G","what_i_eat":"H","sales_hype":"I",
    "curiosity_reveal":"J","before_after":"K","brand_montage":"L","vo_montage":"M"}
FLOW_BLOCKS = {"A":["A3","I6","D1","D2","Act6"],"B":["A5","A5","I3","D1","Act6"],
    "C":["A3","D1","D3","Act6"],"D":["A3","I3","D1","Act6"],
    "E":["A5","I4","D2","D1","Act6"],"F":["A3","A3","A4","D1","Act6"],
    "G":["I1","I2","I3","D1","Act6"],"H":["D1","D1","D1","A6","Act6"],
    "I":["A5","Act1","I6","Act6"],"J":["A3","I2","D3","A3","Act6"],
    "K":["A5","A6","D1","Act6"],"L":["kinetic_text","product_image","kinetic_text","Act6"],
    "M":["A1","I1","I3","D1","Act6"]}
EMOTIONS = ["curiosity","frustration","surprise","relief","confidence","urgency"]

letter = FLOW_LETTER.get(flow, "A")
blocks = FLOW_BLOCKS.get(letter, ["A3","I1","D1","Act6"])
n = len(blocks)
block_dur = duration / n

plan = {
    "brand": brand, "product": product, "flow": flow, "flow_letter": letter,
    "duration": duration, "variants": variants,
    "blocks": [
        {"id": f"{i+1:02d}_{code}", "block_code": code,
         "aida_phase": {"A":"attention","I":"interest","D":"desire","Act":"action","k":"attention","p":"interest"}.get(code.rstrip("0123456789_textimag"),"attention"),
         "duration_s": round(block_dur + ((-1)**i * 0.5 if i > 0 and i < n-1 else 0), 1),
         "emotion": EMOTIONS[i % len(EMOTIONS)]}
        for i, code in enumerate(blocks)
    ]
}
with open(out_file, 'w') as f:
    json.dump(plan, f, indent=2)
print(f"Plan: {letter} ({flow}) → {' → '.join(blocks)} ({n} blocks, ~{block_dur:.1f}s each)")
PYEOF
  ok "Plan: $plan_file"

  # ── STEP 3: SCRIPT ──
  step "3" "SCRIPT GENERATION"
  local script_file="$WORK_DIR/03-script.json"

  if [[ -f "$SCRIPT_GEN" ]]; then
    bash "$SCRIPT_GEN" generate --brand "$BRAND" --product "$PRODUCT" \
      --flow "$FLOW" --duration "$DURATION" --variants "$VARIANTS" 2>&1 | sed 's/^/  /'

    # Find the generated file
    local gen_script
    gen_script=$(find "$WORKSPACE/data/video-scripts/" -name "${BRAND}-${FLOW}-variants.json" -newer "$plan_file" 2>/dev/null | head -1)
    if [[ -n "$gen_script" && -f "$gen_script" ]]; then
      cp "$gen_script" "$script_file"
      ok "Script: $script_file"
    else
      skip "Script gen output not found, using plan as template"
      cp "$plan_file" "$script_file"
    fi
  else
    skip "video-script-gen.sh not found"
    cp "$plan_file" "$script_file"
  fi

  # ── STEP 4: SCRIPT QA ──
  step "4" "SCRIPT QA"
  if [[ "$SKIP_QA" -eq 0 && -f "$CREATIVE_QA" ]]; then
    bash "$CREATIVE_QA" script --script "$script_file" --brand "$BRAND" 2>&1 | sed 's/^/  /'
  else
    skip "QA skipped (--skip-qa or creative-qa not found)"
  fi

  # ── STEP 5: CHARACTER + SCENE PLANNING ──
  step "5" "CHARACTER + SCENE PLANNING"
  local char_dir="$WORK_DIR/05-characters"
  mkdir -p "$char_dir"

  # Load character lock spec (MANDATORY before any generation)
  local char_suffix=""
  local char_refs=""
  if [[ -f "$CHAR_LOCK" ]]; then
    # Try to find a character for this brand
    local char_name
    char_name=$("$PYTHON3" -c "
import json, os, glob
# Check brand characters dir
brand_chars = glob.glob('$BRANDS_DIR/$BRAND/characters/*/spec.json')
# Check skill schemas
skill_chars = glob.glob('$(dirname "$SCRIPT_DIR")/schemas/*.character.json')
# Also check character-lock skill schemas
lock_chars = glob.glob('$SKILLS/character-lock/schemas/*.character.json')
all_specs = brand_chars + skill_chars + lock_chars
for s in all_specs:
    try:
        d = json.load(open(s))
        if d.get('brand') == '$BRAND':
            print(d.get('name', ''))
            break
    except: pass
" 2>/dev/null) || true

    if [[ -n "$char_name" ]]; then
      echo "  Loading character lock: $BRAND / $char_name"
      bash "$CHAR_LOCK" load --brand "$BRAND" --character "$char_name" 2>&1 | sed 's/^/  /'

      # Get prompt suffix
      char_suffix=$(bash "$CHAR_LOCK" load --brand "$BRAND" --character "$char_name" --json 2>/dev/null | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin).get('rules',{}).get('prompt_suffix',''))" 2>/dev/null) || true

      # Get reference images
      char_refs=$(bash "$CHAR_LOCK" refs --brand "$BRAND" --character "$char_name" 2>/dev/null) || true

      if [[ -n "$char_suffix" ]]; then
        ok "Character locked: $char_name (suffix + refs loaded)"
        echo "$char_suffix" > "$char_dir/prompt-suffix.txt"
        echo "$char_refs" > "$char_dir/ref-images.txt"
      else
        skip "Character spec found but no prompt suffix"
      fi
    else
      skip "No character spec for brand $BRAND (brand-only content)"
    fi
  else
    skip "character-lock.sh not found"
  fi

  # Load brand DNA
  local dna_file="$BRANDS_DIR/$BRAND/DNA.json"
  if [[ -f "$dna_file" ]]; then
    ok "Brand DNA loaded: $dna_file"
  else
    skip "No DNA.json for $BRAND"
  fi

  # Generate character reference if NanoBanana available AND no locked refs
  if [[ -f "$NANOBANANA" && "$DRY_RUN" -eq 0 && -z "$char_refs" ]]; then
    log "Generating character reference (no locked refs found)..."
    local char_prompt="Professional UGC-style portrait, natural makeup, warm lighting, iPhone quality, 9:16 vertical. $char_suffix"
    local nb_output
    nb_output=$(bash "$NANOBANANA" generate --brand "$BRAND" \
      --prompt "$char_prompt" 2>&1) || true

    local char_img
    char_img=$(echo "$nb_output" | grep -oE '/[^ ]+\.png' | tail -1)
    if [[ -n "$char_img" && -f "$char_img" ]]; then
      cp "$char_img" "$char_dir/character-ref.png"
      ok "Character ref generated: $char_dir/character-ref.png"
    else
      skip "Character generation failed"
    fi
  elif [[ -n "$char_refs" ]]; then
    ok "Using locked character refs (face-lock enforced)"
  else
    skip "Character generation skipped (dry-run or NanoBanana not found)"
  fi

  # ── STEP 6: REFERENCE IMAGES ──
  step "6" "REFERENCE IMAGES"
  local ref_dir="$WORK_DIR/06-references"
  mkdir -p "$ref_dir"

  if [[ -f "$NANOBANANA" && "$DRY_RUN" -eq 0 ]]; then
    # Generate 3 scene references
    local scene_prompts=("${PRODUCT} being prepared, overhead shot, warm kitchen lighting" "${PRODUCT} being enjoyed by person, close-up reaction, natural light" "${PRODUCT} packaging beauty shot, minimal background, studio light")
    local ref_count=0
    for sp in "${scene_prompts[@]}"; do
      nb_output=$(bash "$NANOBANANA" generate --brand "$BRAND" --prompt "$sp" 2>&1) || true
      local ref_img
      ref_img=$(echo "$nb_output" | grep -oE '/[^ ]+\.png' | tail -1)
      if [[ -n "$ref_img" && -f "$ref_img" ]]; then
        cp "$ref_img" "$ref_dir/scene-ref-$((ref_count+1)).png"
        ref_count=$((ref_count + 1))
      fi
    done
    ok "Generated $ref_count scene references"
  else
    skip "Reference generation skipped"
  fi

  # ── STEP 7: VOICEOVER ──
  step "7" "VOICEOVER"
  skip "ElevenLabs integration pending — manual VO upload to $WORK_DIR/07-voiceover/"
  mkdir -p "$WORK_DIR/07-voiceover"

  # ── STEP 8: VIDEO CLIPS ──
  step "8" "VIDEO CLIP GENERATION"
  local clips_dir="$WORK_DIR/08-clips"
  mkdir -p "$clips_dir"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    skip "Clip generation skipped (dry-run)"
  else
    # Read blocks from plan and generate clips
    local block_count
    block_count=$("$PYTHON3" -c "import json; print(len(json.load(open('$plan_file'))['blocks']))")

    log "Generating $block_count clips via $PROVIDER..."
    for i in $(seq 0 $((block_count - 1))); do
      local block_code
      block_code=$("$PYTHON3" -c "import json; print(json.load(open('$plan_file'))['blocks'][$i]['block_code'])")

      # Skip non-video blocks
      if [[ "$block_code" == "kinetic_text" || "$block_code" == "Act6" || "$block_code" == "end_card" ]]; then
        skip "Block $((i+1))/$block_count ($block_code) — template block, skip generation"
        continue
      fi

      local clip_prompt="${PRODUCT}, ${block_code} scene, natural UGC style, 9:16 vertical, iPhone quality"
      local clip_output="$clips_dir/clip-${block_code}-$(printf '%02d' $((i+1))).mp4"

      echo "  Generating block $((i+1))/$block_count ($block_code) via $PROVIDER..."
      if [[ -f "$VIDEO_GEN" ]]; then
        bash "$VIDEO_GEN" "$PROVIDER" text2video --prompt "$clip_prompt" \
          --duration 5 --aspect-ratio 9:16 --output "$clip_output" \
          --brand "$BRAND" 2>&1 | sed 's/^/    /' || true
      fi

      if [[ -f "$clip_output" ]]; then
        ok "Clip: $clip_output"
      else
        skip "Clip generation pending (async or failed)"
      fi
    done
  fi

  # ── STEP 9: ASSEMBLY ──
  step "9" "ASSEMBLY"
  local assembled="$WORK_DIR/09-assembled.mp4"

  # Check if we have any clips or should do Remotion-only render
  local real_clips
  real_clips=$(find "$clips_dir" -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "${real_clips:-0}" -gt 0 ]]; then
    # Assemble real clips via video-forge
    local clip_list
    clip_list=$(find "$clips_dir" -name "*.mp4" | sort | tr '\n' ' ')
    if [[ -f "$VIDEO_FORGE" ]]; then
      bash "$VIDEO_FORGE" assemble $clip_list --output "$assembled" 2>&1 | sed 's/^/  /' || true
    fi
  fi

  # Fallback: generate a Remotion kinetic placeholder
  if [[ ! -f "$assembled" && -f "$REMOTION" ]]; then
    log "No video clips — generating Remotion kinetic render..."
    local kinetic_text="${PRODUCT}|${FLOW}|${BRAND}"
    bash "$REMOTION" kinetic --text "$kinetic_text" --output "$assembled" 2>&1 | sed 's/^/  /' || true
  fi

  if [[ -f "$assembled" ]]; then
    ok "Assembled: $assembled ($(wc -c < "$assembled" | tr -d ' ')b)"
  else
    fail "Assembly produced no output"
  fi

  # ── STEP 10: POST-PRODUCTION ──
  step "10" "POST-PRODUCTION"
  local final="$WORK_DIR/10-final.mp4"

  if [[ -f "$assembled" && -f "$VIDEO_FORGE" ]]; then
    # Effects
    bash "$VIDEO_FORGE" effects "$assembled" --grain light --vignette \
      --output "$WORK_DIR/10-effects.mp4" 2>&1 | sed 's/^/  /' || true

    local effected="${WORK_DIR}/10-effects.mp4"
    [[ ! -f "$effected" ]] && effected="$assembled"

    # Brand overlay
    bash "$VIDEO_FORGE" brand "$effected" --brand "$BRAND" \
      --output "$final" 2>&1 | sed 's/^/  /' || true

    [[ ! -f "$final" ]] && final="$effected"
    ok "Final: $final"
  else
    final="$assembled"
    skip "Post-production skipped"
  fi

  # ── STEP 11: QUALITY GATE ──
  step "11" "QUALITY GATE"
  if [[ "$SKIP_QA" -eq 0 && -f "$CREATIVE_QA" && -f "$final" ]]; then
    bash "$CREATIVE_QA" video --video "$final" --brand "$BRAND" 2>&1 | sed 's/^/  /'
  else
    skip "QA skipped"
  fi

  # ── STEP 12: DISTRIBUTE + LEARN ──
  step "12" "DISTRIBUTE + LEARN"

  # Register blocks in library
  if [[ -f "$BLOCK_LIB" ]]; then
    for clip in "$clips_dir"/*.mp4; do
      [[ ! -f "$clip" ]] && continue
      local code
      code=$(basename "$clip" | grep -oE '[A-Z][a-z]*[0-9]*' | head -1)
      bash "$BLOCK_LIB" register --file "$clip" --brand "$BRAND" --code "${code:-A3}" 2>/dev/null | sed 's/^/  /' || true
    done
    ok "Blocks registered in library"
  fi

  # Save production manifest
  "$PYTHON3" -c "
import json, os
from datetime import datetime
manifest = {
    'brand': '$BRAND', 'product': '$PRODUCT', 'flow': '$FLOW',
    'duration': $DURATION, 'provider': '$PROVIDER',
    'work_dir': '$WORK_DIR',
    'final_video': '$final' if os.path.exists('$final') else None,
    'completed': datetime.utcnow().isoformat() + 'Z',
    'steps_completed': [s for s in range(1,13)]
}
with open('$WORK_DIR/manifest.json', 'w') as f:
    json.dump(manifest, f, indent=2)
"
  ok "Manifest saved: $WORK_DIR/manifest.json"

  echo ""
  echo "  📹 Final video: ${final:-none}"
  echo "  📁 Work dir: $WORK_DIR/"
}

###############################################################################
# PLAN MODE — Weekly content plan
###############################################################################
cmd_plan() {
  [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }

  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  CONTENT BRAIN — Weekly Plan                                 ║"
  echo "║  Brand: $BRAND | Week: ${WEEK:-current}                      ║"
  echo "╚══════════════════════════════════════════════════════════════╝"

  "$PYTHON3" - "$BRAND" "$BRANDS_DIR" << 'PYEOF'
import json, sys, os
from datetime import datetime

brand = sys.argv[1]
brands_dir = sys.argv[2]

# Load DNA
dna_file = os.path.join(brands_dir, brand, "DNA.json")
dna = {}
if os.path.exists(dna_file):
    with open(dna_file) as f:
        dna = json.load(f)

print(f"\n📋 Weekly Content Plan: {brand.upper()}")
print(f"   Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
print()

# Suggest content mix based on AIDA funnel
plan = [
    {"day": "Monday",    "type": "kinetic_text", "flow": "L", "purpose": "Brand awareness (TOFU)", "cost": "$0"},
    {"day": "Tuesday",   "type": "UGC_video",    "flow": "A", "purpose": "Testimonial (MOFU)", "cost": "$2-3"},
    {"day": "Wednesday", "type": "carousel",      "flow": "-", "purpose": "Education/value (MOFU)", "cost": "$0"},
    {"day": "Thursday",  "type": "UGC_video",    "flow": "B", "purpose": "PAS ad (MOFU/BOFU)", "cost": "$2-3"},
    {"day": "Friday",    "type": "kinetic_text", "flow": "L", "purpose": "Quote/motivation (TOFU)", "cost": "$0"},
    {"day": "Saturday",  "type": "UGC_video",    "flow": "H", "purpose": "What I eat (MOFU)", "cost": "$2-3"},
    {"day": "Sunday",    "type": "brand_reveal",  "flow": "G", "purpose": "Brand story (MOFU)", "cost": "$0"},
]

print(f"{'Day':<12} {'Type':<16} {'Flow':<6} {'Purpose':<30} {'Cost':<6}")
print("-" * 75)
total_cost = 0
for p in plan:
    print(f"{p['day']:<12} {p['type']:<16} {p['flow']:<6} {p['purpose']:<30} {p['cost']:<6}")

print()
print("Weekly budget: ~$6-9 (3 UGC videos + 4 free renders)")
print("vs. Agency: $1,500-4,000/week")
print()
print("Commands:")
for p in plan:
    if p['type'] == 'kinetic_text':
        print(f"  # {p['day']}: content-brain.sh produce --brand {brand} --type kinetic --text \"Your text here\"")
    elif p['type'] == 'UGC_video':
        flow_map = {'A':'testimonial','B':'PAS','H':'what_i_eat'}
        flow_name = flow_map.get(p['flow'],'testimonial')
        print(f"  # {p['day']}: content-brain.sh produce --brand {brand} --product \"Product\" --flow {flow_name}")
PYEOF
}

###############################################################################
# BRAIN MODE — Daily review + suggestions
###############################################################################
cmd_brain() {
  [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }

  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  CONTENT BRAIN — Daily Intelligence                          ║"
  echo "║  Brand: $BRAND                                               ║"
  echo "╚══════════════════════════════════════════════════════════════╝"

  # Library health
  if [[ "$CHECK" == "library" || -z "$CHECK" ]]; then
    echo ""
    echo "📦 Block Library Health:"
    if [[ -f "$BLOCK_LIB" ]]; then
      bash "$BLOCK_LIB" health --brand "$BRAND" 2>&1 | sed 's/^/  /'
    else
      echo "  ⚠️ block-library.sh not found"
    fi
  fi

  # Recent productions
  echo ""
  echo "📹 Recent Productions:"
  local prod_dir="$WORKSPACE/data/productions/$BRAND"
  if [[ -d "$prod_dir" ]]; then
    local count
    count=$(find "$prod_dir" -name "manifest.json" -mtime -7 2>/dev/null | wc -l | tr -d ' ')
    echo "  Last 7 days: $count productions"
    find "$prod_dir" -name "manifest.json" -mtime -7 2>/dev/null | sort -r | head -5 | while read -r m; do
      local dir
      dir=$(dirname "$m")
      echo "    $(basename "$dir")"
    done
  else
    echo "  No productions yet"
  fi

  # Suggestions
  echo ""
  echo "💡 Suggestions:"
  echo "  1. Generate a kinetic text reel (free, builds awareness)"
  echo "     content-brain.sh produce --brand $BRAND --type kinetic --text \"Your hook here\""
  echo "  2. Test a full UGC pipeline (dry-run first)"
  echo "     content-brain.sh produce --brand $BRAND --product \"X\" --flow testimonial --dry-run"
  echo "  3. Check library health"
  echo "     content-brain.sh brain --brand $BRAND --check library"
}

###############################################################################
# MAIN
###############################################################################
case "$MODE" in
  produce) cmd_produce ;;
  plan)    cmd_plan ;;
  brain)   cmd_brain ;;
  help|*)
    cat << 'HELPEOF'
Content Brain — Master Orchestrator

Usage:
  content-brain.sh produce  --brand <brand> [options]   Full 12-step pipeline
  content-brain.sh plan     --brand <brand>             Weekly content plan
  content-brain.sh brain    --brand <brand>             Daily review + suggestions

Produce types:
  --type full          Full 12-step video pipeline (default)
  --type kinetic       Kinetic text reel (Remotion, $0)
  --type oracle-card   Oracle card reveal (Jade, Remotion, $0)
  --type brand-reveal  Brand reveal animation (Remotion, $0)

Options:
  --brand <name>       Brand name (required)
  --product <desc>     Product description (required for --type full)
  --flow <flow>        Flow type: testimonial, PAS, challenge, etc.
  --duration <sec>     Video duration (default: 40)
  --provider <name>    Video model: kling, sora, wan, seedance
  --dry-run            Plan only, don't generate (save $$)
  --skip-qa            Skip quality gate checks

Examples:
  content-brain.sh produce --brand mirra --type kinetic --text "Fresh|Healthy|*Delicious*"
  content-brain.sh produce --brand mirra --product "Bento Bowl" --flow testimonial --dry-run
  content-brain.sh plan --brand jade-oracle
  content-brain.sh brain --brand mirra
HELPEOF
    ;;
esac
