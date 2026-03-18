#!/usr/bin/env bash
# visual-audit.sh — Vision-based audit of generated images against refs
# Uses Gemini Flash vision to reverse-check:
#   1. Does the output match the reference images?
#   2. Is the brand (colors, logo, style) correct?
#   3. Is the product/character consistent with refs?
#   4. Layout and composition match the use case?
# macOS Bash 3.2 compatible

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
SECRETS_DIR="$OPENCLAW_DIR/secrets"
LOG_FILE="$OPENCLAW_DIR/logs/visual-audit.log"
AUDIT_DIR="$OPENCLAW_DIR/workspace/data/audits"

# Load API key
if [ -f "$SECRETS_DIR/gemini.env" ]; then
  GEMINI_API_KEY=$(grep "GEMINI_API_KEY" "$SECRETS_DIR/gemini.env" | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
elif [ -f "$OPENCLAW_DIR/.env" ]; then
  GEMINI_API_KEY=$(grep "GOOGLE_API_KEY\|GEMINI_API_KEY" "$OPENCLAW_DIR/.env" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
fi

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "ERROR: No Gemini API key found"
  exit 1
fi

log() { mkdir -p "$(dirname "$LOG_FILE")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

usage() {
  echo "visual-audit.sh — Vision-based audit of generated images"
  echo ""
  echo "Usage:"
  echo "  visual-audit.sh check --image <path> --refs <ref1,ref2,...> --brand <brand> --use-case <type>"
  echo "  visual-audit.sh batch --dir <dir> --brand <brand>"
  echo "  visual-audit.sh report --image <path>"
  echo ""
  echo "Options:"
  echo "  --image      Path to generated image to audit"
  echo "  --refs       Comma-separated reference image paths that were used"
  echo "  --brand      Brand name (mirra, pinxin-vegan, etc.)"
  echo "  --use-case   Type: comparison, hero, lifestyle, product, character, grid"
  echo "  --prompt     The prompt that was used (for context)"
  echo "  --strict     Fail on any mismatch (default: warn)"
  echo ""
  echo "Outputs:"
  echo "  PASS/WARN/FAIL with specific reasons"
  echo "  JSON audit report saved to workspace/data/audits/"
}

# Base64 encode an image (resize if >1MB for speed)
encode_image() {
  local img="$1"
  local tmp_img=""

  if [ ! -f "$img" ]; then
    echo ""
    return
  fi

  local size
  size=$(wc -c < "$img" | tr -d ' ')

  # Resize if >1MB to keep API call fast
  if [ "$size" -gt 1048576 ]; then
    tmp_img=$(mktemp /tmp/audit-img.XXXXXX.jpg)
    sips --resampleWidth 512 "$img" --out "$tmp_img" 2>/dev/null || cp "$img" "$tmp_img"
    base64 < "$tmp_img" | tr -d '\n'
    rm -f "$tmp_img"
  else
    base64 < "$img" | tr -d '\n'
  fi
}

# Get MIME type
get_mime() {
  local ext="${1##*.}"
  case "$(echo "$ext" | tr 'A-Z' 'a-z')" in
    png) echo "image/png" ;;
    jpg|jpeg) echo "image/jpeg" ;;
    webp) echo "image/webp" ;;
    *) echo "image/png" ;;
  esac
}

# Use-case specific checks
get_usecase_criteria() {
  local uc="$1"
  if echo "$uc" | grep -q "comparison"; then
    echo "- MUST have split layout (left vs right). Left: unhealthy/generic food, Right: MIRRA bento. Calorie badges on both sides. Clear product differentiation."
  elif echo "$uc" | grep -q "hero"; then
    echo "- Product centered, prominent. Clean background (pink/cream gradient). Space for headline text. Brand badge (nutritionist-designed, calorie count)."
  elif echo "$uc" | grep -q "lifestyle"; then
    echo "- Person enjoying MIRRA meal. Natural warm lighting. Aspirational but relatable. Malaysian setting/context."
  elif echo "$uc" | grep -q "product"; then
    echo "- Product photo front and center. Top-view or slight angle. Clean background. Matches the EXACT product from reference."
  elif echo "$uc" | grep -q "character"; then
    echo "- Character consistency: face/body matches reference. Correct attire. Correct accessories."
  elif echo "$uc" | grep -q "grid"; then
    echo "- Multiple products visible (2x2 or similar). Each product clearly identifiable. Consistent style across grid items. Price or calorie badges."
  else
    echo "- General brand compliance check."
  fi
}

# Build brand-specific audit criteria
get_brand_criteria() {
  local brand="$1"
  local use_case="$2"
  local uc_checks
  uc_checks=$(get_usecase_criteria "$use_case")

  if echo "$brand" | grep -q "mirra"; then
    echo "Brand: MIRRA (healthy bento meal delivery for Malaysian women 25-45). REQUIRED brand elements: Colors salmon pink #F7AB9F, cream #FFF9EB, black #252525. Logo: MIRRA wordmark (serif, black or white text). Style: Warm, feminine, clean. Photography: Real food photography look, appetizing, fresh. Avoid: Teal, fuchsia, dark moody, film grain, sparkle/glitter. Use-case checks for ${use_case}: ${uc_checks}"
  elif echo "$brand" | grep -q "pinxin"; then
    echo "Brand: Pinxin Vegan (plant-based, earth tones, clean design). REQUIRED: Green/earth tones, clean typography, natural ingredients visible. Use-case checks: ${uc_checks}"
  elif echo "$brand" | grep -q "gaia"; then
    echo "Brand: Gaia Eats/OS (umbrella brand). For character images: check against GAIA OS character references. Use-case checks: ${uc_checks}"
  else
    echo "Brand: $brand. General quality check. Use-case checks: ${uc_checks}"
  fi
}

# Main audit function — calls Gemini Vision
do_audit() {
  local image="$1"
  local refs="$2"
  local brand="$3"
  local use_case="$4"
  local prompt="${5:-}"
  local strict="${6:-false}"

  if [ ! -f "$image" ]; then
    echo "FAIL: Image not found: $image"
    return 1
  fi

  log "Auditing: $image (brand=$brand, use_case=$use_case, refs=$refs)"

  # Encode the generated image
  local gen_b64
  gen_b64=$(encode_image "$image")
  if [ -z "$gen_b64" ]; then
    echo "FAIL: Could not encode image"
    return 1
  fi
  local gen_mime
  gen_mime=$(get_mime "$image")

  # Build parts array with generated image
  local parts_json
  parts_json=$(python3 -c "
import json, sys, os, base64

image_path = sys.argv[1]
refs_str = sys.argv[2]
brand_criteria = sys.argv[3]
prompt_used = sys.argv[4]
use_case = sys.argv[5]

parts = []

# Add audit instructions
audit_prompt = '''You are a visual quality auditor for advertising images.

TASK: Compare the GENERATED IMAGE against the REFERENCE IMAGES and brand criteria.

BRAND CRITERIA:
''' + brand_criteria + '''

ORIGINAL PROMPT USED:
''' + (prompt_used if prompt_used else 'Not provided') + '''

Score each dimension 1-10 and provide specific feedback:

1. PRODUCT_MATCH (1-10): Does the product in the generated image match the reference product photos? Same food/item? Same presentation? Or was it hallucinated?
2. BRAND_COMPLIANCE (1-10): Colors correct? Logo present and correct? Style matches brand guidelines?
3. LAYOUT_MATCH (1-10): Does the layout match the use case (''' + use_case + ''')? Comparison = split, Hero = centered, Grid = multi-product, etc.
4. QUALITY (1-10): Professional quality? Sharp, well-composed, appetizing (for food)?
5. REF_USAGE (1-10): How well did the AI use the reference images? Did it anchor to them or ignore them?

OVERALL VERDICT: PASS (avg >= 7), WARN (avg 5-7), or FAIL (avg < 5)

OUTPUT FORMAT (strict JSON):
{
  \"product_match\": {\"score\": N, \"note\": \"...\"},
  \"brand_compliance\": {\"score\": N, \"note\": \"...\"},
  \"layout_match\": {\"score\": N, \"note\": \"...\"},
  \"quality\": {\"score\": N, \"note\": \"...\"},
  \"ref_usage\": {\"score\": N, \"note\": \"...\"},
  \"overall_score\": N,
  \"verdict\": \"PASS|WARN|FAIL\",
  \"issues\": [\"issue 1\", \"issue 2\"],
  \"suggestions\": [\"suggestion 1\"]
}'''

parts.append({'text': audit_prompt})

# Add generated image (resize if large)
import subprocess, tempfile
img_size = os.path.getsize(image_path)
if img_size > 500000:
    tmp_gen = tempfile.mktemp(suffix='.jpg')
    subprocess.run(['sips', '--resampleWidth', '512', image_path, '--out', tmp_gen], capture_output=True)
    read_gen = tmp_gen if os.path.exists(tmp_gen) else image_path
else:
    read_gen = image_path
    tmp_gen = None

with open(read_gen, 'rb') as f:
    img_data = base64.standard_b64encode(f.read()).decode()
if tmp_gen and os.path.exists(tmp_gen): os.remove(tmp_gen)

mime = 'image/jpeg' if read_gen.endswith('.jpg') else 'image/png'

parts.append({'text': 'GENERATED IMAGE (this is what we are auditing):'})
parts.append({'inline_data': {'mime_type': mime, 'data': img_data}})

# Add reference images
if refs_str:
    ref_paths = [r.strip() for r in refs_str.split(',') if r.strip()]
    for i, ref_path in enumerate(ref_paths[:3]):  # Max 3 refs for speed
        if os.path.exists(ref_path):
            # Resize large refs to 512px for speed
            import subprocess, tempfile
            ref_size = os.path.getsize(ref_path)
            if ref_size > 500000:
                tmp = tempfile.mktemp(suffix='.jpg')
                subprocess.run(['sips', '--resampleWidth', '512', ref_path, '--out', tmp], capture_output=True)
                read_path = tmp if os.path.exists(tmp) else ref_path
            else:
                read_path = ref_path
                tmp = None
            with open(read_path, 'rb') as f:
                ref_data = base64.standard_b64encode(f.read()).decode()
            if tmp and os.path.exists(tmp): os.remove(tmp)
            ref_mime = 'image/jpeg' if read_path.endswith('.jpg') else 'image/png'
            parts.append({'text': f'REFERENCE IMAGE {i+1} ({os.path.basename(ref_path)}):'})
            parts.append({'inline_data': {'mime_type': ref_mime, 'data': ref_data}})

payload = {
    'contents': [{'parts': parts}],
    'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 4096,
        'responseMimeType': 'application/json'
    }
}

print(json.dumps(payload))
" "$image" "$refs" "$(get_brand_criteria "$brand" "$use_case")" "${prompt:-}" "$use_case")

  # Write to temp file (avoid ARG_MAX)
  local body_file
  body_file=$(mktemp /tmp/audit-body.XXXXXX)
  echo "$parts_json" > "$body_file"

  # Call Gemini Flash (vision)
  local endpoint="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
  local response_file
  response_file=$(mktemp /tmp/audit-resp.XXXXXX)

  local http_code
  http_code=$(curl -s -w '%{http_code}' \
    -X POST "$endpoint" \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -d "@${body_file}" \
    -o "$response_file" 2>/dev/null)

  rm -f "$body_file"

  if [ "$http_code" != "200" ]; then
    local err
    err=$(cat "$response_file" 2>/dev/null | head -c 500)
    rm -f "$response_file"
    echo "FAIL: Vision API returned HTTP $http_code: $err"
    log "ERROR: Vision API HTTP $http_code"
    return 1
  fi

  # Extract the audit result
  local audit_json
  audit_json=$(python3 -c "
import json, sys

with open(sys.argv[1], 'r') as f:
    data = json.loads(f.read())

candidates = data.get('candidates', [])
if not candidates:
    print(json.dumps({'error': 'No response from vision model'}))
    sys.exit(0)

parts = candidates[0].get('content', {}).get('parts', [])
text = ''
for part in parts:
    if 'text' in part:
        text += part['text']

# Try to parse as JSON
import re
try:
    result = json.loads(text)
    print(json.dumps(result))
except:
    # Try to extract JSON from markdown code blocks
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        try:
            result = json.loads(json_match.group())
            print(json.dumps(result))
        except:
            print(json.dumps({'raw': text[:2000], 'error': 'Could not parse JSON'}))
    else:
        print(json.dumps({'raw': text[:2000], 'error': 'Could not parse JSON'}))
" "$response_file")

  rm -f "$response_file"

  # Save audit report
  mkdir -p "$AUDIT_DIR"
  local audit_id
  audit_id="audit-$(date '+%Y%m%d-%H%M%S')-$$"
  local audit_file="$AUDIT_DIR/${audit_id}.json"

  python3 -c "
import json, sys, os

audit = json.loads(sys.argv[1])
report = {
    'id': sys.argv[2],
    'image': sys.argv[3],
    'refs': sys.argv[4].split(',') if sys.argv[4] else [],
    'brand': sys.argv[5],
    'use_case': sys.argv[6],
    'prompt': sys.argv[7],
    'timestamp': '$(date -u '+%Y-%m-%dT%H:%M:%SZ')',
    'audit': audit
}

with open(sys.argv[8], 'w') as f:
    json.dump(report, f, indent=2)

# Print human-readable summary
verdict = audit.get('verdict', 'UNKNOWN')
overall = audit.get('overall_score', '?')
print(f'')
print(f'=== Visual Audit: {verdict} (Score: {overall}/10) ===')
print(f'  Image: {os.path.basename(sys.argv[3])}')

for dim in ['product_match', 'brand_compliance', 'layout_match', 'quality', 'ref_usage']:
    d = audit.get(dim, {})
    if isinstance(d, dict):
        score = d.get('score', '?')
        note = d.get('note', '')
        symbol = '✓' if isinstance(score, (int, float)) and score >= 7 else ('⚠' if isinstance(score, (int, float)) and score >= 5 else '✗')
        print(f'  {symbol} {dim}: {score}/10 — {note}')

issues = audit.get('issues', [])
if issues:
    print(f'')
    print(f'  Issues:')
    for issue in issues:
        print(f'    - {issue}')

suggestions = audit.get('suggestions', [])
if suggestions:
    print(f'')
    print(f'  Suggestions:')
    for s in suggestions:
        print(f'    - {s}')

print(f'')
print(f'  Report: {sys.argv[8]}')
" "$audit_json" "$audit_id" "$image" "$refs" "$brand" "$use_case" "${prompt:-}" "$audit_file"

  log "Audit complete: $audit_id verdict=$(echo "$audit_json" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('verdict','?'))" 2>/dev/null || echo 'unknown')"

  # Return exit code based on verdict
  local verdict
  verdict=$(echo "$audit_json" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('verdict','FAIL'))" 2>/dev/null || echo "FAIL")

  case "$verdict" in
    PASS) return 0 ;;
    WARN) [ "$strict" = "true" ] && return 1 || return 0 ;;
    FAIL) return 1 ;;
    *) return 1 ;;
  esac
}

# ── MAIN ──

CMD="${1:-}"
shift 2>/dev/null || true

case "$CMD" in
  check)
    image=""
    refs=""
    brand=""
    use_case="product"
    prompt=""
    strict="false"

    while [ $# -gt 0 ]; do
      case "$1" in
        --image)    image="$2";    shift 2 ;;
        --refs)     refs="$2";     shift 2 ;;
        --brand)    brand="$2";    shift 2 ;;
        --use-case) use_case="$2"; shift 2 ;;
        --prompt)   prompt="$2";   shift 2 ;;
        --strict)   strict="true"; shift ;;
        *) shift ;;
      esac
    done

    if [ -z "$image" ]; then
      echo "ERROR: --image is required"
      exit 1
    fi

    do_audit "$image" "$refs" "${brand:-unknown}" "$use_case" "$prompt" "$strict"
    ;;

  batch)
    dir=""
    brand=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --dir)   dir="$2";   shift 2 ;;
        --brand) brand="$2"; shift 2 ;;
        *) shift ;;
      esac
    done

    if [ -z "$dir" ]; then
      echo "ERROR: --dir is required"
      exit 1
    fi

    total=0
    pass=0
    warn=0
    fail=0

    for img in "$dir"/*.png "$dir"/*.jpg "$dir"/*.jpeg; do
      [ -f "$img" ] || continue
      total=$((total + 1))
      echo "--- Auditing: $(basename "$img") ---"
      if do_audit "$img" "" "${brand:-unknown}" "product" "" "false"; then
        pass=$((pass + 1))
      else
        fail=$((fail + 1))
      fi
      sleep 2  # Rate limit for vision API
    done

    echo ""
    echo "=== Batch Audit Complete ==="
    echo "  Total: $total | Pass: $pass | Warn: $warn | Fail: $fail"
    ;;

  report)
    image="${2:-}"
    if [ -z "$image" ]; then
      echo "ERROR: image path required"
      exit 1
    fi
    basename=$(basename "$image" | sed 's/\.[^.]*$//')
    latest=$(ls -t "$AUDIT_DIR"/audit-*.json 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
      python3 -c "import json; print(json.dumps(json.load(open('$latest')), indent=2))"
    else
      echo "No audit reports found"
    fi
    ;;

  *)
    usage
    ;;
esac
