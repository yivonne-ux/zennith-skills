#!/usr/bin/env bash
# audit-visual.sh — Visual audit analyzer for GAIA brand assets
# Uses Kimi K2.5 (Moonshot API) to critique images and videos
#
# Usage:
#   bash audit-visual.sh audit-image <path-or-url>
#   bash audit-visual.sh audit-video <path>
#   bash audit-visual.sh audit-batch <directory>
#
# macOS compatible: bash 3.2, no declare -A, no timeout, no GNU extensions

set -euo pipefail

# --- Config ---
[ -z "${MOONSHOT_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/moonshot.env" ] && \
  export "$(grep '^MOONSHOT_API_KEY=' "$HOME/.openclaw/secrets/moonshot.env" | head -1)" 2>/dev/null || true
MOONSHOT_API_KEY="${MOONSHOT_API_KEY:-sk-5miIle0UC2YJY5YoSbMOl89DobyZbnh9Aw79XvaRzmIghZ9J}"
MOONSHOT_BASE_URL="https://api.moonshot.ai/v1"
MOONSHOT_MODEL="kimi-k2.5"
LOG_FILE="$HOME/.openclaw/logs/visual-audit.log"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
TMP_DIR="${TMPDIR:-/tmp}/gaia-audit-$$"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$TMP_DIR"

# Cleanup temp dir on exit
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$msg" >> "$LOG_FILE"
}

# --- Post to creative room (on failure) ---
post_to_room() {
  local room="$1"
  local message="$2"
  local escaped_msg
  escaped_msg=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$message")
  # Remove outer quotes from json.dumps
  escaped_msg="${escaped_msg:1:${#escaped_msg}-2}"
  printf '{"ts":%s000,"agent":"art-director","room":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$room" "$escaped_msg" \
    >> "${ROOMS_DIR}/${room}.jsonl"
  log "Posted audit result to ${room} room"
}

# --- Brand audit prompt ---
AUDIT_PROMPT='You are the Art Director QA system for GAIA Eats, a Malaysian vegan/plant-based food brand.

BRAND IDENTITY:
- Colors: sage green (#87AE73 range), gold (#C5A55A range), cream (#F5F0E8 range)
- Aesthetic: clean, natural, healthy, premium but accessible
- Feel: warm, inviting, sustainable, plant-forward
- Target: Malaysian market, health-conscious consumers

AUDIT THIS IMAGE across these dimensions (score each 1-5):

1. BRAND FIT (1-5): Does the image align with GAIA Eats brand identity? Check palette adherence (sage green, gold, cream), natural/healthy feel, premium quality.

2. COMPOSITION (1-5): Visual hierarchy, rule of thirds, balance, focal point clarity, whitespace usage.

3. TEXT READABILITY (1-5): If text is present — legibility at mobile sizes (especially on phones at 375px width), contrast ratio, font sizing. Score 5 if no text present and image does not need text.

4. COLOR HARMONY (1-5): Do the colors work together? On-brand palette usage? Any jarring or off-brand colors?

5. EMOTIONAL IMPACT (1-5): Does this evoke appetite, health, nature, warmth? Would a Malaysian consumer feel drawn to this?

6. PLATFORM READINESS (1-5): Safe zones clear for platform overlays (Instagram handle, story UI elements, WhatsApp status bar)? No critical content in top/bottom 15% for stories?

RESPOND IN THIS EXACT JSON FORMAT (no markdown, no code fences, just raw JSON):
{
  "scores": {
    "brand_fit": <1-5>,
    "composition": <1-5>,
    "text_readability": <1-5>,
    "color_harmony": <1-5>,
    "emotional_impact": <1-5>,
    "platform_readiness": <1-5>
  },
  "issues": ["issue 1", "issue 2"],
  "suggestions": ["suggestion 1", "suggestion 2"],
  "brief_analysis": "One paragraph summary of the overall visual quality and brand alignment."
}'

# --- Base64 encode an image file ---
encode_image() {
  local filepath="$1"
  base64 < "$filepath" | tr -d '\n'
}

# --- Detect MIME type ---
detect_mime() {
  local filepath="$1"
  local ext
  ext=$(echo "${filepath##*.}" | tr '[:upper:]' '[:lower:]')
  case "$ext" in
    jpg|jpeg) echo "image/jpeg" ;;
    png)      echo "image/png" ;;
    gif)      echo "image/gif" ;;
    webp)     echo "image/webp" ;;
    bmp)      echo "image/bmp" ;;
    *)        echo "image/jpeg" ;;  # default fallback
  esac
}

# --- Call Kimi K2.5 with image ---
call_kimi_with_image() {
  local image_source="$1"  # path or URL
  local is_url="$2"        # "url" or "file"

  local image_content
  if [ "$is_url" = "url" ]; then
    image_content=$(python3 -c "
import json
content = {
    'type': 'image_url',
    'image_url': {'url': '$image_source'}
}
print(json.dumps(content))
")
  else
    local b64
    b64=$(encode_image "$image_source")
    local mime
    mime=$(detect_mime "$image_source")
    image_content=$(python3 -c "
import json, sys
b64 = sys.argv[1]
mime = sys.argv[2]
content = {
    'type': 'image_url',
    'image_url': {'url': f'data:{mime};base64,{b64}'}
}
print(json.dumps(content))
" "$b64" "$mime")
  fi

  local request_body
  request_body=$(python3 -c "
import json, sys

prompt_text = sys.argv[1]
image_content = json.loads(sys.argv[2])

body = {
    'model': '$MOONSHOT_MODEL',
    'messages': [
        {
            'role': 'user',
            'content': [
                {'type': 'text', 'text': prompt_text},
                image_content
            ]
        }
    ],
    'temperature': 0.3,
    'max_tokens': 2000
}
print(json.dumps(body))
" "$AUDIT_PROMPT" "$image_content")

  local response
  response=$(curl -s -X POST "${MOONSHOT_BASE_URL}/chat/completions" \
    -H "Authorization: Bearer ${MOONSHOT_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$request_body" 2>&1)

  # Extract the content from the response
  local content
  content=$(echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'choices' in d and len(d['choices']) > 0:
        msg = d['choices'][0].get('message', {}).get('content', '')
        print(msg)
    elif 'error' in d:
        print('ERROR: ' + d['error'].get('message', str(d['error'])))
    else:
        print('ERROR: Unexpected response format')
except Exception as e:
    print('ERROR: ' + str(e))
" 2>&1)

  echo "$content"
}

# --- Parse and format audit result ---
format_audit_result() {
  local file_path="$1"
  local raw_response="$2"

  python3 -c "
import json, sys, re

file_path = sys.argv[1]
raw = sys.argv[2]

# Try to extract JSON from the response (handle markdown fences)
json_match = re.search(r'\{[\s\S]*\}', raw)
if not json_match:
    result = {
        'file': file_path,
        'error': 'Failed to parse model response',
        'raw_response': raw[:500],
        'scores': {'brand_fit':0,'composition':0,'text_readability':0,'color_harmony':0,'emotional_impact':0,'platform_readiness':0},
        'overall': 0,
        'issues': ['Model response could not be parsed'],
        'suggestions': ['Retry the audit'],
        'verdict': 'reject'
    }
    print(json.dumps(result, indent=2))
    sys.exit(0)

try:
    data = json.loads(json_match.group())
except json.JSONDecodeError:
    result = {
        'file': file_path,
        'error': 'Invalid JSON in model response',
        'raw_response': raw[:500],
        'scores': {'brand_fit':0,'composition':0,'text_readability':0,'color_harmony':0,'emotional_impact':0,'platform_readiness':0},
        'overall': 0,
        'issues': ['Model response JSON was malformed'],
        'suggestions': ['Retry the audit'],
        'verdict': 'reject'
    }
    print(json.dumps(result, indent=2))
    sys.exit(0)

scores = data.get('scores', {})
dims = ['brand_fit', 'composition', 'text_readability', 'color_harmony', 'emotional_impact', 'platform_readiness']
vals = [scores.get(d, 0) for d in dims]
total = sum(vals)
count = len([v for v in vals if v > 0])
overall = round(total / count, 1) if count > 0 else 0

# Determine verdict
if overall >= 4.0:
    verdict = 'pass'
elif overall >= 2.5:
    verdict = 'needs_revision'
else:
    verdict = 'reject'

result = {
    'file': file_path,
    'scores': scores,
    'overall': overall,
    'issues': data.get('issues', []),
    'suggestions': data.get('suggestions', []),
    'verdict': verdict
}

if 'brief_analysis' in data:
    result['analysis'] = data['brief_analysis']

print(json.dumps(result, indent=2))
" "$file_path" "$raw_response"
}

# --- Command: audit-image ---
cmd_audit_image() {
  if [ $# -eq 0 ]; then
    echo "ERROR: Path or URL required"
    echo "Usage: bash audit-visual.sh audit-image <path-or-url>"
    exit 1
  fi

  local target="$1"
  local is_url="file"
  local display_path="$target"

  # Check if it's a URL
  case "$target" in
    http://*|https://*)
      is_url="url"
      ;;
    *)
      # It's a file path — verify it exists
      if [ ! -f "$target" ]; then
        echo "ERROR: File not found: $target"
        exit 1
      fi
      # Convert to absolute path
      display_path="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
      ;;
  esac

  log "Auditing image: $display_path"
  echo "Auditing image: $display_path" >&2
  echo "Sending to Kimi K2.5 for analysis..." >&2

  local raw_response
  raw_response=$(call_kimi_with_image "$target" "$is_url")

  # Check for API errors
  case "$raw_response" in
    ERROR:*)
      log "API error for $display_path: $raw_response"
      echo "ERROR: Kimi K2.5 API error: $raw_response" >&2
      exit 1
      ;;
  esac

  local result
  result=$(format_audit_result "$display_path" "$raw_response")

  # Log the result
  local verdict
  verdict=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('verdict','unknown'))")
  local overall
  overall=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('overall',0))")
  log "Audit complete: $display_path — verdict=$verdict, overall=$overall"

  # Post to creative room if audit fails
  if [ "$verdict" = "needs_revision" ] || [ "$verdict" = "reject" ]; then
    local issues
    issues=$(echo "$result" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin).get('issues',[])))")
    post_to_room "creative" "Visual audit $verdict for $(basename "$display_path"): overall=$overall/5. Issues: $issues"
  fi

  # Output JSON to stdout
  echo "$result"
}

# --- Command: audit-video ---
cmd_audit_video() {
  if [ $# -eq 0 ]; then
    echo "ERROR: Video path required"
    echo "Usage: bash audit-visual.sh audit-video <path>"
    exit 1
  fi

  local video_path="$1"

  if [ ! -f "$video_path" ]; then
    echo "ERROR: File not found: $video_path"
    exit 1
  fi

  # Check for ffmpeg
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ERROR: ffmpeg is required for video audit. Install with: brew install ffmpeg"
    exit 1
  fi

  # Convert to absolute path
  local abs_path
  abs_path="$(cd "$(dirname "$video_path")" && pwd)/$(basename "$video_path")"

  log "Auditing video: $abs_path"
  echo "Auditing video: $abs_path" >&2

  # Extract key frames (beginning, middle, end-ish)
  local frames_dir="${TMP_DIR}/frames"
  mkdir -p "$frames_dir"

  echo "Extracting key frames with ffmpeg..." >&2
  ffmpeg -i "$abs_path" \
    -vf "select=eq(n\,0)+eq(n\,30)+eq(n\,60)" \
    -vsync vfr \
    "${frames_dir}/frame_%03d.jpg" \
    -y -loglevel error 2>&1

  # Count extracted frames
  local frame_count=0
  local frame_files=""
  for f in "$frames_dir"/frame_*.jpg; do
    if [ -f "$f" ]; then
      frame_count=$((frame_count + 1))
      if [ -n "$frame_files" ]; then
        frame_files="${frame_files} ${f}"
      else
        frame_files="$f"
      fi
    fi
  done

  if [ "$frame_count" -eq 0 ]; then
    # Fallback: extract first frame only
    echo "No frames at specified positions. Extracting first frame..." >&2
    ffmpeg -i "$abs_path" -vframes 1 "${frames_dir}/frame_001.jpg" -y -loglevel error 2>&1
    frame_count=1
    frame_files="${frames_dir}/frame_001.jpg"
  fi

  echo "Extracted $frame_count frames. Analyzing each..." >&2

  # Audit each frame
  local all_scores_json="["
  local first=1
  local frame_num=0

  for frame_file in $frame_files; do
    frame_num=$((frame_num + 1))
    echo "  Analyzing frame $frame_num of $frame_count..." >&2

    local raw_response
    raw_response=$(call_kimi_with_image "$frame_file" "file")

    case "$raw_response" in
      ERROR:*)
        log "API error for frame $frame_num of $abs_path: $raw_response"
        echo "  WARNING: Frame $frame_num analysis failed, skipping" >&2
        continue
        ;;
    esac

    local frame_result
    frame_result=$(format_audit_result "${abs_path}#frame${frame_num}" "$raw_response")

    if [ "$first" -eq 1 ]; then
      all_scores_json="${all_scores_json}${frame_result}"
      first=0
    else
      all_scores_json="${all_scores_json},${frame_result}"
    fi
  done

  all_scores_json="${all_scores_json}]"

  # Average scores across frames and produce final result
  local final_result
  final_result=$(python3 -c "
import json, sys

frames = json.loads(sys.argv[1])
video_path = sys.argv[2]

if not frames:
    result = {
        'file': video_path,
        'type': 'video',
        'error': 'No frames could be analyzed',
        'scores': {'brand_fit':0,'composition':0,'text_readability':0,'color_harmony':0,'emotional_impact':0,'platform_readiness':0},
        'overall': 0,
        'issues': ['No frames extracted or analyzed'],
        'suggestions': ['Check video file integrity'],
        'verdict': 'reject'
    }
    print(json.dumps(result, indent=2))
    sys.exit(0)

dims = ['brand_fit', 'composition', 'text_readability', 'color_harmony', 'emotional_impact', 'platform_readiness']
avg_scores = {}
for d in dims:
    vals = [f['scores'].get(d, 0) for f in frames if f['scores'].get(d, 0) > 0]
    avg_scores[d] = round(sum(vals) / len(vals), 1) if vals else 0

total = sum(avg_scores.values())
count = len([v for v in avg_scores.values() if v > 0])
overall = round(total / count, 1) if count > 0 else 0

# Collect unique issues and suggestions
all_issues = []
all_suggestions = []
for f in frames:
    for i in f.get('issues', []):
        if i not in all_issues:
            all_issues.append(i)
    for s in f.get('suggestions', []):
        if s not in all_suggestions:
            all_suggestions.append(s)

if overall >= 4.0:
    verdict = 'pass'
elif overall >= 2.5:
    verdict = 'needs_revision'
else:
    verdict = 'reject'

result = {
    'file': video_path,
    'type': 'video',
    'frames_analyzed': len(frames),
    'scores': avg_scores,
    'overall': overall,
    'issues': all_issues,
    'suggestions': all_suggestions,
    'verdict': verdict,
    'frame_details': frames
}
print(json.dumps(result, indent=2))
" "$all_scores_json" "$abs_path")

  # Log result
  local verdict
  verdict=$(echo "$final_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('verdict','unknown'))")
  local overall
  overall=$(echo "$final_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('overall',0))")
  log "Video audit complete: $abs_path — verdict=$verdict, overall=$overall, frames=$frame_count"

  # Post to creative room if audit fails
  if [ "$verdict" = "needs_revision" ] || [ "$verdict" = "reject" ]; then
    local issues
    issues=$(echo "$final_result" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin).get('issues',[])[:3]))")
    post_to_room "creative" "Video audit $verdict for $(basename "$abs_path"): overall=$overall/5. Top issues: $issues"
  fi

  # Output JSON to stdout
  echo "$final_result"
}

# --- Command: audit-batch ---
cmd_audit_batch() {
  if [ $# -eq 0 ]; then
    echo "ERROR: Directory path required"
    echo "Usage: bash audit-visual.sh audit-batch <directory>"
    exit 1
  fi

  local dir_path="$1"

  if [ ! -d "$dir_path" ]; then
    echo "ERROR: Directory not found: $dir_path"
    exit 1
  fi

  # Convert to absolute path
  local abs_dir
  abs_dir="$(cd "$dir_path" && pwd)"

  log "Batch audit starting: $abs_dir"
  echo "Batch audit: $abs_dir" >&2

  # Collect image and video files
  local files=""
  local file_count=0

  for f in "$abs_dir"/*.jpg "$abs_dir"/*.jpeg "$abs_dir"/*.png "$abs_dir"/*.gif "$abs_dir"/*.webp "$abs_dir"/*.bmp \
           "$abs_dir"/*.JPG "$abs_dir"/*.JPEG "$abs_dir"/*.PNG "$abs_dir"/*.GIF "$abs_dir"/*.WEBP "$abs_dir"/*.BMP \
           "$abs_dir"/*.mp4 "$abs_dir"/*.mov "$abs_dir"/*.avi "$abs_dir"/*.webm \
           "$abs_dir"/*.MP4 "$abs_dir"/*.MOV "$abs_dir"/*.AVI "$abs_dir"/*.WEBM; do
    if [ -f "$f" ]; then
      file_count=$((file_count + 1))
      if [ -n "$files" ]; then
        files="${files}|${f}"
      else
        files="$f"
      fi
    fi
  done

  if [ "$file_count" -eq 0 ]; then
    echo "No image or video files found in: $abs_dir" >&2
    echo '{"directory":"'"$abs_dir"'","files_found":0,"results":[]}'
    exit 0
  fi

  echo "Found $file_count files to audit" >&2

  # Process each file
  local all_results="["
  local first=1
  local processed=0
  local pass_count=0
  local revision_count=0
  local reject_count=0

  # Save IFS and split on pipe
  local OLD_IFS="$IFS"
  IFS="|"
  for filepath in $files; do
    IFS="$OLD_IFS"
    processed=$((processed + 1))
    echo "" >&2
    echo "[$processed/$file_count] Processing: $(basename "$filepath")" >&2

    local ext
    ext=$(echo "${filepath##*.}" | tr '[:upper:]' '[:lower:]')

    local result=""
    case "$ext" in
      mp4|mov|avi|webm)
        result=$(cmd_audit_video "$filepath" 2>/dev/null) || true
        ;;
      *)
        result=$(cmd_audit_image "$filepath" 2>/dev/null) || true
        ;;
    esac

    if [ -n "$result" ]; then
      # Count verdicts
      local v
      v=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('verdict','unknown'))" 2>/dev/null || echo "unknown")
      case "$v" in
        pass) pass_count=$((pass_count + 1)) ;;
        needs_revision) revision_count=$((revision_count + 1)) ;;
        reject) reject_count=$((reject_count + 1)) ;;
      esac

      if [ "$first" -eq 1 ]; then
        all_results="${all_results}${result}"
        first=0
      else
        all_results="${all_results},${result}"
      fi
    fi

    IFS="|"
  done
  IFS="$OLD_IFS"

  all_results="${all_results}]"

  # Build batch summary
  local batch_result
  batch_result=$(python3 -c "
import json, sys

results = json.loads(sys.argv[1])
directory = sys.argv[2]
total = int(sys.argv[3])
passed = int(sys.argv[4])
revision = int(sys.argv[5])
rejected = int(sys.argv[6])

# Compute batch average
all_overalls = [r.get('overall', 0) for r in results if r.get('overall', 0) > 0]
batch_avg = round(sum(all_overalls) / len(all_overalls), 1) if all_overalls else 0

batch = {
    'directory': directory,
    'files_found': total,
    'files_audited': len(results),
    'batch_average': batch_avg,
    'summary': {
        'pass': passed,
        'needs_revision': revision,
        'reject': rejected
    },
    'results': results
}
print(json.dumps(batch, indent=2))
" "$all_results" "$abs_dir" "$file_count" "$pass_count" "$revision_count" "$reject_count")

  log "Batch audit complete: $abs_dir — $file_count files, pass=$pass_count, revision=$revision_count, reject=$reject_count"

  # Post batch summary to creative room if any failures
  if [ "$revision_count" -gt 0 ] || [ "$reject_count" -gt 0 ]; then
    local batch_avg
    batch_avg=$(echo "$batch_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('batch_average',0))")
    post_to_room "creative" "Batch audit of $abs_dir: $file_count files, avg=$batch_avg/5. Pass=$pass_count, Needs revision=$revision_count, Reject=$reject_count"
  fi

  # Output JSON to stdout
  echo "$batch_result"
}

# --- Main ---
if [ $# -eq 0 ]; then
  echo "GAIA Visual Audit Analyzer (Kimi K2.5)"
  echo ""
  echo "Usage:"
  echo "  bash audit-visual.sh audit-image <path-or-url>   Audit a single image"
  echo "  bash audit-visual.sh audit-video <path>           Audit a video (extracts key frames)"
  echo "  bash audit-visual.sh audit-batch <directory>      Audit all visuals in a directory"
  echo ""
  echo "Output: JSON with scores (1-5) for brand_fit, composition, text_readability,"
  echo "        color_harmony, emotional_impact, platform_readiness + verdict."
  echo ""
  echo "Verdicts: pass (>=4.0) | needs_revision (2.5-3.9) | reject (<2.5)"
  exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
  audit-image) cmd_audit_image "$@" ;;
  audit-video) cmd_audit_video "$@" ;;
  audit-batch) cmd_audit_batch "$@" ;;
  *)
    echo "ERROR: Unknown command: $COMMAND"
    echo "Available: audit-image, audit-video, audit-batch"
    exit 1
    ;;
esac
