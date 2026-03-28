#!/usr/bin/env bash
# character-lock.sh — Identity Enforcement System for Zennith OS
# MUST be called before ANY image/video generation involving characters.
#
# Usage:
#   character-lock.sh load     --brand <brand> --character <name> [--json]
#   character-lock.sh validate --brand <brand> --character <name> --prompt <text>
#   character-lock.sh refs     --brand <brand> --character <name> [--use-case <type>]
#   character-lock.sh audit    --brand <brand> --character <name> --image <path>
#   character-lock.sh init     --brand <brand> --character <name>
#   character-lock.sh list

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW="$HOME/.openclaw"
BRANDS_DIR="$OPENCLAW/brands"
CHARS_DATA="$OPENCLAW/workspace/data/characters"
LOG_FILE="$OPENCLAW/logs/character-lock.log"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

# Character spec locations (search order)
# 1. brands/{brand}/characters/{name}/spec.json (canonical)
# 2. skills/character-lock/schemas/{name}.character.json (defaults)
# 3. workspace/data/characters/{brand}/{name}/*-spec*.json (legacy)

mkdir -p "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

BRAND=""
CHARACTER=""
PROMPT=""
IMAGE=""
USE_CASE="lifestyle"
JSON_OUTPUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)     BRAND="$2"; shift 2 ;;
    --character) CHARACTER="$2"; shift 2 ;;
    --prompt)    PROMPT="$2"; shift 2 ;;
    --image)     IMAGE="$2"; shift 2 ;;
    --use-case)  USE_CASE="$2"; shift 2 ;;
    --json)      JSON_OUTPUT=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[char-lock $(date +%H:%M:%S)] $1" >> "$LOG_FILE"; }

# Find the character spec file
find_spec() {
  local brand="$1" char="$2"
  local paths=(
    "$BRANDS_DIR/$brand/characters/$char/spec.json"
    "$SKILL_DIR/schemas/${char}.character.json"
    "$CHARS_DATA/$brand/$char/${char}-spec-v2.json"
    "$CHARS_DATA/$brand/$char/spec.json"
  )
  for p in "${paths[@]}"; do
    # Expand ~ to $HOME
    p="${p/#\~/$HOME}"
    if [[ -f "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

case "$MODE" in
  load)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }
    [[ -z "$CHARACTER" ]] && { echo "ERROR: --character required" >&2; exit 1; }

    SPEC_FILE=$(find_spec "$BRAND" "$CHARACTER") || {
      echo "ERROR: No character spec found for $BRAND/$CHARACTER" >&2
      echo "  Searched:" >&2
      echo "    $BRANDS_DIR/$BRAND/characters/$CHARACTER/spec.json" >&2
      echo "    $SKILL_DIR/schemas/${CHARACTER}.character.json" >&2
      echo "  Create with: character-lock.sh init --brand $BRAND --character $CHARACTER" >&2
      exit 1
    }

    log "LOAD: $BRAND/$CHARACTER from $SPEC_FILE"

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
      cat "$SPEC_FILE"
    else
      "$PYTHON3" - "$SPEC_FILE" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    spec = json.load(f)

name = spec.get("name", "?")
brand = spec.get("brand", "?")
rules = spec.get("rules", {})
photo = spec.get("photography", {})
hair = spec.get("hair", {})
identity = spec.get("identity", {})

print(f"CHARACTER LOCK: {name} ({brand})")
print(f"  Version: {spec.get('version', '?')}")
print(f"  Style: {photo.get('style', '?')}")
print(f"  Lighting: {photo.get('lighting', '?')}")
print(f"  Hair: {hair.get('description_allcaps', '?')}")
print(f"  Signature: {identity.get('signature_item', 'none')}")
print(f"  Prompt suffix: {rules.get('prompt_suffix', 'none')}")
print(f"  Face ref min: {rules.get('face_ref_min_pct', 60)}%")
print(f"  Anti-drift rules: {len(rules.get('anti_drift', []))}")
print(f"  Never list: {len(rules.get('never', []))} items")
print(f"  Spec: {sys.argv[1]}")
PYEOF
    fi
    ;;

  validate)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }
    [[ -z "$CHARACTER" ]] && { echo "ERROR: --character required" >&2; exit 1; }
    [[ -z "$PROMPT" ]] && { echo "ERROR: --prompt required" >&2; exit 1; }

    SPEC_FILE=$(find_spec "$BRAND" "$CHARACTER") || { echo "ERROR: No spec found" >&2; exit 1; }

    "$PYTHON3" - "$SPEC_FILE" "$PROMPT" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    spec = json.load(f)
prompt = sys.argv[2].lower()

rules = spec.get("rules", {})
never_list = rules.get("never", [])
anti_drift = rules.get("anti_drift", [])
suffix = rules.get("prompt_suffix", "")

violations = []
warnings = []

# Check never list (skip if preceded by "no " or "not " or "never " — those are anti-drift)
import re
for item in never_list:
    il = item.lower()
    if il in prompt:
        # Check if it's negated (e.g., "no illustration" is fine)
        pattern = rf'(?:no|not|never|without|avoid)\s+{re.escape(il)}'
        if re.search(pattern, prompt):
            continue  # Negated context — safe
        violations.append(f"NEVER: '{item}' found in prompt")

# Check suffix is present
if suffix and suffix.lower() not in prompt:
    warnings.append(f"Missing prompt suffix — append: {suffix[:80]}...")

# Check hair description
hair = spec.get("hair", {})
hair_allcaps = hair.get("description_allcaps", "")
if hair_allcaps and hair_allcaps.lower() not in prompt:
    warnings.append(f"Hair not in ALL CAPS — add: {hair_allcaps[:60]}...")

# Check signature item
identity = spec.get("identity", {})
sig = identity.get("signature_item", "")
if sig:
    sig_key = sig.split("(")[0].strip().lower()
    if sig_key not in prompt:
        warnings.append(f"Signature item missing: {sig}")

# Check forbidden combinations
photo = spec.get("photography", {})
style = photo.get("style", "").lower()
if "editorial" in prompt and "not editorial" in style:
    violations.append("STYLE CONFLICT: 'editorial' in prompt but spec says NOT editorial")

if "style-seed" in prompt and "ref-image" in prompt:
    violations.append("FORBIDDEN: style-seed + ref-image combo causes chaos")

if violations:
    print(f"❌ VALIDATION FAILED ({len(violations)} violations)")
    for v in violations:
        print(f"  - {v}")
    sys.exit(1)
elif warnings:
    print(f"⚠️  VALIDATION PASS with {len(warnings)} warnings")
    for w in warnings:
        print(f"  - {w}")
    sys.exit(0)
else:
    print("✅ VALIDATION PASS — prompt is character-safe")
    sys.exit(0)
PYEOF
    ;;

  refs)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }
    [[ -z "$CHARACTER" ]] && { echo "ERROR: --character required" >&2; exit 1; }

    SPEC_FILE=$(find_spec "$BRAND" "$CHARACTER") || { echo "ERROR: No spec found" >&2; exit 1; }

    "$PYTHON3" - "$SPEC_FILE" "$USE_CASE" << 'PYEOF'
import json, sys, os

with open(sys.argv[1]) as f:
    spec = json.load(f)
use_case = sys.argv[2]

refs = spec.get("locked_refs", {})
min_pct = spec.get("rules", {}).get("face_ref_min_pct", 60)

# Build reference array following 60% face rule
# 7 slots: face1, face2, face3, face1_dup, face2_dup, body, scene
ref_list = []

# Face refs (slots 1-5 = 71% face coverage)
face_paths = [
    refs.get("face_primary", ""),
    refs.get("face_angle2", ""),
    refs.get("face_angle3", ""),
    refs.get("face_primary", ""),  # duplicate for weight
    refs.get("face_angle2", ""),   # duplicate for weight
]

for fp in face_paths:
    fp = fp.replace("~/", os.path.expanduser("~/") + "/").replace("//", "/")
    if fp and os.path.isfile(fp):
        ref_list.append(fp)

# Body ref (slot 6)
body = refs.get("body_headless", refs.get("body_ref", ""))
body = body.replace("~/", os.path.expanduser("~/") + "/").replace("//", "/")
if body and os.path.isfile(body):
    ref_list.append(body)

# Style anchors
for sa in refs.get("style_anchors", []):
    sa = sa.replace("~/", os.path.expanduser("~/") + "/").replace("//", "/")
    if sa and os.path.isfile(sa):
        ref_list.append(sa)

if ref_list:
    # Verify face percentage
    face_count = min(5, len([p for p in face_paths if p and os.path.isfile(
        p.replace("~/", os.path.expanduser("~/") + "/").replace("//", "/"))]))
    total = len(ref_list)
    pct = (face_count / total * 100) if total > 0 else 0

    if pct < min_pct:
        print(f"WARNING: Face refs only {pct:.0f}% (need {min_pct}%). Add more face refs.", file=sys.stderr)

    print(",".join(ref_list))
else:
    print("WARNING: No locked reference images found. Generate without face-lock.", file=sys.stderr)
    print("")
PYEOF
    ;;

  audit)
    [[ -z "$IMAGE" ]] && { echo "ERROR: --image required" >&2; exit 1; }
    [[ ! -f "$IMAGE" ]] && { echo "ERROR: Image not found: $IMAGE" >&2; exit 1; }
    echo "AUDIT: Vision-based audit requires Gemini Vision API (not yet wired)"
    echo "  Manual check: compare $IMAGE against locked refs"
    ;;

  init)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }
    [[ -z "$CHARACTER" ]] && { echo "ERROR: --character required" >&2; exit 1; }

    CHAR_DIR="$BRANDS_DIR/$BRAND/characters/$CHARACTER"
    mkdir -p "$CHAR_DIR/locked/faces" "$CHAR_DIR/locked/bodies" "$CHAR_DIR/locked/accessories"
    mkdir -p "$CHAR_DIR/environments" "$CHAR_DIR/wardrobe" "$CHAR_DIR/variations" "$CHAR_DIR/audit"

    # Copy template spec
    TEMPLATE="$SKILL_DIR/schemas/character-spec.schema.json"
    if [[ ! -f "$CHAR_DIR/spec.json" ]]; then
      "$PYTHON3" -c "
import json
spec = {
    'name': '$CHARACTER',
    'brand': '$BRAND',
    'version': 'v1',
    'updated': '$(date +%Y-%m-%d)',
    'identity': {'ethnicity': '', 'age': 25, 'gender': 'female'},
    'face': {'shape': '', 'eyes': '', 'skin': '', 'expression': ''},
    'hair': {'color': '', 'length': '', 'style': '', 'description_allcaps': ''},
    'photography': {'style': 'iPhone candid', 'lighting': 'natural light', 'lens': '35mm f/1.8'},
    'rules': {
        'anti_drift': ['No illustration, no cartoon, no CG'],
        'never': ['illustration', 'cartoon', 'anime', 'CG render'],
        'face_ref_min_pct': 60,
        'prompt_suffix': 'Photorealistic. No illustration, no cartoon, no CG.'
    }
}
with open('$CHAR_DIR/spec.json', 'w') as f:
    json.dump(spec, f, indent=2)
print(f'Initialized: $CHAR_DIR/spec.json')
"
    fi

    echo "Character initialized: $CHAR_DIR/"
    echo "  spec.json created — FILL IN all fields before generation"
    echo "  locked/faces/ — add 3+ canonical face reference PNGs"
    echo "  locked/bodies/ — add headless body reference"
    echo "  environments/ — add approved scene reference images"
    echo "  wardrobe/ — add approved outfit reference images"
    ;;

  list)
    echo "Locked Characters:"
    echo ""
    # Search all brands for character specs
    for brand_dir in "$BRANDS_DIR"/*/; do
      brand=$(basename "$brand_dir")
      char_dir="$brand_dir/characters"
      [[ ! -d "$char_dir" ]] && continue
      for c_dir in "$char_dir"/*/; do
        [[ ! -d "$c_dir" ]] && continue
        char=$(basename "$c_dir")
        spec="$c_dir/spec.json"
        if [[ -f "$spec" ]]; then
          version=$("$PYTHON3" -c "import json; print(json.load(open('$spec')).get('version','?'))" 2>/dev/null || echo "?")
          echo "  ✅ $brand / $char (spec $version)"
        else
          echo "  ⚠️  $brand / $char (no spec.json)"
        fi
      done
    done

    # Also check skill schemas
    echo ""
    echo "Default Specs (in skill):"
    for f in "$SKILL_DIR"/schemas/*.character.json; do
      [[ ! -f "$f" ]] && continue
      name=$(basename "$f" .character.json)
      echo "  📄 $name"
    done
    ;;

  help|*)
    cat << 'HELPEOF'
Character Lock — Identity Enforcement System

Usage:
  character-lock.sh load      --brand <brand> --character <name> [--json]
  character-lock.sh validate  --brand <brand> --character <name> --prompt <text>
  character-lock.sh refs      --brand <brand> --character <name> [--use-case <type>]
  character-lock.sh audit     --brand <brand> --character <name> --image <path>
  character-lock.sh init      --brand <brand> --character <name>
  character-lock.sh list

Rules:
  1. NEVER generate without loading spec first
  2. Face refs ≥ 60% of all refs (prevents drift)
  3. Hair ALWAYS in ALL CAPS in prompts
  4. Prompt suffix ALWAYS appended
  5. style-seed + ref-image = FORBIDDEN
  6. Signature item MUST be visible
  7. "editorial" BANNED for Jade (use "iPhone candid")
HELPEOF
    ;;
esac
