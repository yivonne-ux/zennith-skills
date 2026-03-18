#!/usr/bin/env bash
# intake-processor.sh — Creative Intake Engine for GAIA CORP-OS
# Reference-to-Production Machine: classifies, analyzes, and routes any creative input.
# Bash 3.2 compatible (macOS). No jq, no declare -A, no timeout. Uses python3 for JSON.
# 8GB RAM aware: processes one input at a time, cleans temp files.
#
# Input: JSON on stdin (room message format)
# Output: Result JSON on stdout
#
# Usage: echo '{"type":"image","file_path":"/path/to/img.jpg","brand":"pinxin"}' | bash intake-processor.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/workspace/logs/intake.log"
INTAKE_ROOM="$HOME/.openclaw/workspace/rooms/intake.jsonl"
CREATIVE_ROOM="$HOME/.openclaw/workspace/rooms/creative.jsonl"
OUTPUT_TYPES_FILE="$HOME/.openclaw/workspace/data/output-types.json"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"
REGISTER_OUTPUT_TYPE="$HOME/.openclaw/skills/workflow-automation/scripts/register-output-type.sh"
CLASSIFY_LINK="$HOME/.openclaw/skills/link-digester/scripts/classify-link.sh"
DISPATCH="$HOME/.openclaw/skills/mission-control/scripts/dispatch.sh"
CLASSIFY_SCRIPT="$SCRIPT_DIR/intake-classify.sh"
TIER_CHECK="$SCRIPT_DIR/tier-check.sh"
APPROVAL_QUEUE="$SCRIPT_DIR/approval-queue.sh"
ENV_FILE="$HOME/.openclaw/.env"
TMP_DIR="/tmp/gaia-intake-$$"

# Gemini model for vision analysis
GEMINI_MODEL="gemini-2.5-flash"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
  printf '[%s] [intake-processor] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE" 2>/dev/null
}

cleanup() {
  rm -rf "$TMP_DIR" 2>/dev/null
}
trap cleanup EXIT INT TERM HUP

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

# Post a message to a room jsonl file
post_to_room() {
  local room_file="$1"
  local json_line="$2"
  printf '%s\n' "$json_line" >> "$room_file" 2>/dev/null || {
    log "WARNING: Could not write to room $room_file"
  }
}

# Check tier for an action type. Returns 1, 2, or 3.
get_tier() {
  local action_type="$1"
  if [ -x "$TIER_CHECK" ]; then
    bash "$TIER_CHECK" "$action_type" 2>/dev/null
  else
    echo "2"  # default to tier 2 if tier-check.sh not found
  fi
}

# Submit to approval queue (for tier 3 actions).
# Usage: submit_approval "type" "agent" "summary" '{"payload":...}'
submit_approval() {
  local appr_type="$1"
  local appr_agent="$2"
  local appr_summary="$3"
  local appr_payload="$4"
  if [ -x "$APPROVAL_QUEUE" ]; then
    bash "$APPROVAL_QUEUE" submit \
      --type "$appr_type" \
      --agent "$appr_agent" \
      --summary "$appr_summary" \
      --payload "$appr_payload" \
      --tier 3 2>>"$LOG_FILE"
  else
    log "WARNING: approval-queue.sh not found at $APPROVAL_QUEUE — cannot queue for approval"
    echo ""
  fi
}

# Post a tier 2 audit notification to approvals.jsonl
post_tier2_audit() {
  local action_type="$1"
  local agent="$2"
  local summary="$3"
  local approvals_file="$HOME/.openclaw/workspace/rooms/approvals.jsonl"
  python3 -c "
import json, time
record = {
    'id': 'audit-' + str(int(time.time() * 1000)),
    'ts': int(time.time() * 1000),
    'type': '$action_type',
    'tier': 2,
    'status': 'executed',
    'agent': '$agent',
    'summary': '''$summary''',
    'payload': {},
    'human_notes': '',
    'approved_at': None,
    'executed_at': int(time.time() * 1000),
    'result': {'status': 'auto-executed', 'output': 'Tier 2 — auto-executed with notification'}
}
print(json.dumps(record, ensure_ascii=False))
" 2>/dev/null | while IFS= read -r line; do
    printf '%s\n' "$line" >> "$approvals_file" 2>/dev/null
  done
}

# Read GEMINI_API_KEY from .env
get_gemini_key() {
  python3 -c "
import os
env_file = os.path.expanduser('$ENV_FILE')
if os.path.exists(env_file):
    for line in open(env_file):
        line = line.strip()
        if line.startswith('GEMINI_API_KEY='):
            val = line.split('=',1)[1].strip().strip('\"').strip(\"'\")
            print(val)
            break
" 2>/dev/null
}

# Detect MIME type from file extension
detect_mime() {
  local filepath="$1"
  local ext
  ext=$(python3 -c "import os; print(os.path.splitext('$filepath')[1].lower())" 2>/dev/null)
  case "$ext" in
    .jpg|.jpeg) echo "image/jpeg" ;;
    .png)       echo "image/png" ;;
    .gif)       echo "image/gif" ;;
    .webp)      echo "image/webp" ;;
    .bmp)       echo "image/bmp" ;;
    .tiff|.tif) echo "image/tiff" ;;
    .heic)      echo "image/heic" ;;
    .avif)      echo "image/avif" ;;
    *)          echo "image/jpeg" ;;  # safe default
  esac
}

# Get existing output type IDs as a comma-separated list
get_existing_output_types() {
  python3 -c "
import json, os
types_file = os.path.expanduser('$OUTPUT_TYPES_FILE')
if os.path.exists(types_file):
    try:
        with open(types_file) as f:
            types = json.load(f)
        if isinstance(types, list):
            ids = [t.get('id','') for t in types if isinstance(t, dict)]
        else:
            ids = []
        print(','.join(ids))
    except Exception:
        print('')
else:
    print('')
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Read input
# ---------------------------------------------------------------------------

INPUT_JSON=""
if [ -t 0 ]; then
  log "ERROR: No JSON input on stdin"
  printf '{"error":"No JSON input on stdin. Pipe room message JSON to this script."}\n'
  exit 1
fi
INPUT_JSON="$(cat)"

if [ -z "$INPUT_JSON" ]; then
  log "ERROR: Empty input"
  printf '{"error":"Empty input"}\n'
  exit 1
fi

log "Processing intake event"

# Create temp dir
mkdir -p "$TMP_DIR"

# ---------------------------------------------------------------------------
# Parse input fields
# ---------------------------------------------------------------------------

PARSED=$(python3 -c "
import json, sys

try:
    data = json.loads(sys.stdin.read())
except Exception as e:
    print('ERROR:Invalid JSON: ' + str(e))
    sys.exit(0)

# Extract fields with defaults
fields = {
    'ts': data.get('ts', ''),
    'agent': data.get('agent', 'unknown'),
    'source': data.get('source', 'unknown'),
    'type': data.get('type', ''),
    'content': data.get('content', ''),
    'file_path': data.get('file_path', ''),
    'brand': data.get('brand', ''),
    'context': data.get('context', ''),
    'requested_by': data.get('requested_by', 'system'),
}

# Output as key=value lines (safe for bash parsing)
for k, v in fields.items():
    # Replace newlines with spaces for safe bash assignment
    safe_v = str(v).replace('\\n', ' ').replace('\\r', '')
    print(k + '=' + safe_v)
" <<< "$INPUT_JSON" 2>/dev/null)

if echo "$PARSED" | grep -q "^ERROR:"; then
  ERR_MSG=$(echo "$PARSED" | sed 's/^ERROR://')
  log "ERROR: $ERR_MSG"
  printf '{"error":"%s"}\n' "$ERR_MSG"
  exit 1
fi

# Parse fields into variables (safe: no eval, use grep+cut)
INPUT_TS=$(echo "$PARSED" | grep "^ts=" | cut -d= -f2-)
INPUT_AGENT=$(echo "$PARSED" | grep "^agent=" | cut -d= -f2-)
INPUT_SOURCE=$(echo "$PARSED" | grep "^source=" | cut -d= -f2-)
INPUT_TYPE=$(echo "$PARSED" | grep "^type=" | cut -d= -f2-)
INPUT_CONTENT=$(echo "$PARSED" | grep "^content=" | cut -d= -f2-)
INPUT_FILE_PATH=$(echo "$PARSED" | grep "^file_path=" | cut -d= -f2-)
INPUT_BRAND=$(echo "$PARSED" | grep "^brand=" | cut -d= -f2-)
INPUT_CONTEXT=$(echo "$PARSED" | grep "^context=" | cut -d= -f2-)
INPUT_REQUESTED_BY=$(echo "$PARSED" | grep "^requested_by=" | cut -d= -f2-)

# Set timestamp if not provided
if [ -z "$INPUT_TS" ]; then
  INPUT_TS=$(epoch_ms)
fi

# ---------------------------------------------------------------------------
# Step 1: Detect input type (if not specified)
# ---------------------------------------------------------------------------

if [ -z "$INPUT_TYPE" ] || [ "$INPUT_TYPE" = "unknown" ]; then
  INPUT_TYPE=$(echo "$INPUT_JSON" | bash "$CLASSIFY_SCRIPT" 2>/dev/null)
  INPUT_TYPE="${INPUT_TYPE:-unknown}"
  log "Auto-detected type: $INPUT_TYPE"
fi

if [ "$INPUT_TYPE" = "unknown" ]; then
  log "ERROR: Could not determine input type"
  RESULT_JSON=$(python3 -c "
import json, time
result = {
    'status': 'error',
    'error': 'Could not determine input type',
    'ts': int(time.time() * 1000),
    'input_type': 'unknown'
}
print(json.dumps(result))
")
  printf '%s\n' "$RESULT_JSON"
  exit 1
fi

log "Input type: $INPUT_TYPE, source: $INPUT_SOURCE, agent: $INPUT_AGENT, brand: $INPUT_BRAND"

# ---------------------------------------------------------------------------
# Step 2: Route by type
# ---------------------------------------------------------------------------

RESULT_STATUS="processed"
RESULT_ACTION=""
RESULT_AGENT=""
RESULT_DETAILS=""
RESULT_SEED_ID=""
RESULT_NEW_TYPE=""

case "$INPUT_TYPE" in

# =========================================================================
# TYPE: LINK
# =========================================================================
link)
  log "Processing link: $INPUT_CONTENT"
  LINK_URL="$INPUT_CONTENT"

  if [ -z "$LINK_URL" ]; then
    log "ERROR: Link type but no URL in content"
    RESULT_STATUS="error"
    RESULT_DETAILS="Link type but no URL in content field"
  else
    # Classify the link using existing classify-link.sh
    LINK_CLASS=""
    if [ -f "$CLASSIFY_LINK" ]; then
      LINK_CLASS=$(bash "$CLASSIFY_LINK" "$LINK_URL" 2>/dev/null) || true
      log "Link classification: $LINK_CLASS"
    else
      log "WARNING: classify-link.sh not found at $CLASSIFY_LINK"
    fi

    # Parse classification result
    LINK_TYPE=$(python3 -c "
import json, sys
try:
    d = json.loads('''$(echo "$LINK_CLASS" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null | sed 's/^"//;s/"$//')''')
    print(d.get('type', 'general'))
except Exception:
    print('general')
" 2>/dev/null)
    LINK_TYPE="${LINK_TYPE:-general}"

    LINK_AGENT=$(python3 -c "
import json, sys
try:
    d = json.loads('''$(echo "$LINK_CLASS" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null | sed 's/^"//;s/"$//')''')
    print(d.get('agent', 'artemis'))
except Exception:
    print('artemis')
" 2>/dev/null)
    LINK_AGENT="${LINK_AGENT:-artemis}"

    log "Link type: $LINK_TYPE, routed to: $LINK_AGENT"

    # Route based on link type
    case "$LINK_TYPE" in
      visual-reference)
        RESULT_ACTION="reverse-prompt"
        RESULT_AGENT="iris"
        RESULT_DETAILS="Visual reference link classified. Routing to Iris for reverse-prompting."
        # Dispatch to Iris
        if [ -x "$DISPATCH" ]; then
          DISPATCH_MSG="[INTAKE] Visual reference for reverse-prompting: $LINK_URL"
          if [ -n "$INPUT_CONTEXT" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Context: $INPUT_CONTEXT"
          fi
          if [ -n "$INPUT_BRAND" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Brand: $INPUT_BRAND"
          fi
          bash "$DISPATCH" "zenni" "iris" "request" "$DISPATCH_MSG" "creative" 2>>"$LOG_FILE" || true
        fi
        ;;
      competitor)
        RESULT_ACTION="competitor-analysis"
        RESULT_AGENT="artemis"
        RESULT_DETAILS="Competitor link detected. Routing to Artemis for competitive analysis."
        if [ -x "$DISPATCH" ]; then
          DISPATCH_MSG="[INTAKE] Competitor intel for analysis: $LINK_URL"
          if [ -n "$INPUT_CONTEXT" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Context: $INPUT_CONTEXT"
          fi
          bash "$DISPATCH" "zenni" "artemis" "request" "$DISPATCH_MSG" "build" 2>>"$LOG_FILE" || true
        fi
        ;;
      youtube|article)
        RESULT_ACTION="technique-extraction"
        RESULT_AGENT="artemis"
        RESULT_DETAILS="Tutorial/article link detected. Routing to Artemis for technique extraction."
        if [ -x "$DISPATCH" ]; then
          DISPATCH_MSG="[INTAKE] Content to extract techniques from: $LINK_URL"
          if [ -n "$INPUT_CONTEXT" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Context: $INPUT_CONTEXT"
          fi
          bash "$DISPATCH" "zenni" "artemis" "request" "$DISPATCH_MSG" "exec" 2>>"$LOG_FILE" || true
        fi
        ;;
      product)
        RESULT_ACTION="product-analysis"
        RESULT_AGENT="iris"
        RESULT_DETAILS="Product link detected. Routing to Iris for product photography workflow."
        if [ -x "$DISPATCH" ]; then
          DISPATCH_MSG="[INTAKE] Product page for visual analysis: $LINK_URL"
          if [ -n "$INPUT_BRAND" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Brand: $INPUT_BRAND"
          fi
          bash "$DISPATCH" "zenni" "iris" "request" "$DISPATCH_MSG" "creative" 2>>"$LOG_FILE" || true
        fi
        ;;
      social)
        RESULT_ACTION="social-analysis"
        RESULT_AGENT="iris"
        RESULT_DETAILS="Social media link detected. Routing to Iris for content analysis."
        if [ -x "$DISPATCH" ]; then
          DISPATCH_MSG="[INTAKE] Social content to analyze: $LINK_URL"
          if [ -n "$INPUT_CONTEXT" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Context: $INPUT_CONTEXT"
          fi
          bash "$DISPATCH" "zenni" "iris" "request" "$DISPATCH_MSG" "creative" 2>>"$LOG_FILE" || true
        fi
        ;;
      *)
        RESULT_ACTION="general-research"
        RESULT_AGENT="$LINK_AGENT"
        RESULT_DETAILS="General link. Routing to $LINK_AGENT for processing."
        if [ -x "$DISPATCH" ]; then
          DISPATCH_MSG="[INTAKE] Link to process: $LINK_URL"
          if [ -n "$INPUT_CONTEXT" ]; then
            DISPATCH_MSG="$DISPATCH_MSG | Context: $INPUT_CONTEXT"
          fi
          bash "$DISPATCH" "zenni" "$LINK_AGENT" "request" "$DISPATCH_MSG" "exec" 2>>"$LOG_FILE" || true
        fi
        ;;
    esac
  fi
  ;;

# =========================================================================
# TYPE: IMAGE
# =========================================================================
image)
  FILE_PATH="$INPUT_FILE_PATH"
  if [ -z "$FILE_PATH" ]; then
    FILE_PATH="$INPUT_CONTENT"
  fi

  log "Processing image: $FILE_PATH"

  if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    log "ERROR: Image file not found: $FILE_PATH"
    RESULT_STATUS="error"
    RESULT_DETAILS="Image file not found: $FILE_PATH"
  else
    # Get Gemini API key
    GEMINI_API_KEY=$(get_gemini_key)

    if [ -z "$GEMINI_API_KEY" ]; then
      log "ERROR: GEMINI_API_KEY not found in $ENV_FILE"
      RESULT_STATUS="error"
      RESULT_DETAILS="GEMINI_API_KEY not found. Cannot analyze image."
    else
      # Base64 encode the image
      BASE64_IMG=$(base64 < "$FILE_PATH" 2>/dev/null)
      MIME_TYPE=$(detect_mime "$FILE_PATH")

      if [ -z "$BASE64_IMG" ]; then
        log "ERROR: Failed to base64 encode image"
        RESULT_STATUS="error"
        RESULT_DETAILS="Failed to encode image for analysis"
      else
        log "Sending image to Gemini Vision API ($GEMINI_MODEL)"

        # Get existing output types for the prompt
        EXISTING_TYPES=$(get_existing_output_types)

        # Build the Gemini API request
        ANALYSIS_PROMPT="Analyze this image for creative production reference. Return a JSON object with these exact fields:
{
  \"style\": \"(describe the visual style: e.g. minimalist, maximalist, editorial, organic, luxe, rustic, clinical, etc.)\",
  \"mood\": \"(describe the mood/feeling: e.g. warm, energetic, calm, playful, sophisticated, etc.)\",
  \"colors\": [\"list\", \"of\", \"dominant\", \"colors\", \"as\", \"hex\", \"or\", \"names\"],
  \"composition\": \"(describe composition: e.g. centered, rule-of-thirds, overhead flat-lay, close-up macro, etc.)\",
  \"subject\": \"(what is the main subject of the image)\",
  \"techniques\": \"(lighting techniques, post-processing, special effects visible)\",
  \"suggested_output_type\": \"(which GAIA output type this could inspire: one of: $EXISTING_TYPES — or suggest a NEW type if none fit)\",
  \"confidence\": 0.0-1.0,
  \"production_notes\": \"(how GAIA could reproduce this style for F&B/wellness content)\"
}
Return ONLY the JSON object, no markdown fences, no explanation."

        # Write request payload to temp file to avoid shell escaping issues
        python3 -c "
import json, sys

prompt_text = sys.stdin.read()
payload = {
    'contents': [{
        'parts': [
            {'inlineData': {'mimeType': '$MIME_TYPE', 'data': ''}},
            {'text': prompt_text}
        ]
    }],
    'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024
    }
}
# Write payload without base64 data (we'll inject it separately for memory efficiency)
with open('$TMP_DIR/request.json', 'w') as f:
    json.dump(payload, f)
" <<< "$ANALYSIS_PROMPT" 2>/dev/null

        # Inject base64 data into the request (avoids holding two copies in memory)
        python3 -c "
import json
with open('$TMP_DIR/request.json') as f:
    payload = json.load(f)
with open('$FILE_PATH', 'rb') as f:
    import base64
    b64 = base64.b64encode(f.read()).decode('ascii')
payload['contents'][0]['parts'][0]['inlineData']['data'] = b64
with open('$TMP_DIR/request_full.json', 'w') as f:
    json.dump(payload, f)
" 2>/dev/null

        # Call Gemini API
        GEMINI_RESPONSE=$(curl -s -m 60 \
          "https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}" \
          -H "Content-Type: application/json" \
          -d @"$TMP_DIR/request_full.json" 2>/dev/null)

        # Clean up large temp files immediately (8GB RAM)
        rm -f "$TMP_DIR/request_full.json" "$TMP_DIR/request.json" 2>/dev/null

        if [ -z "$GEMINI_RESPONSE" ]; then
          log "ERROR: Empty response from Gemini API"
          RESULT_STATUS="error"
          RESULT_DETAILS="Empty response from Gemini Vision API"
        else
          # Extract the analysis JSON from the Gemini response
          ANALYSIS=$(python3 -c "
import json, sys, re

try:
    resp = json.loads(sys.stdin.read())
    # Extract text from Gemini response
    text = resp.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '')
    if not text:
        print('ERROR:No text in Gemini response')
        sys.exit(0)
    # Try to parse as JSON (strip markdown fences if present)
    text = text.strip()
    fence = chr(96)*3
    text = re.sub(r'^' + fence + r'json\s*', '', text)
    text = re.sub(r'^' + fence + r'\s*', '', text)
    text = re.sub(r'\s*' + fence + r'$', '', text)
    text = text.strip()
    analysis = json.loads(text)
    print(json.dumps(analysis))
except Exception as e:
    # If we got an error response, extract it
    try:
        resp = json.loads(sys.stdin.read() if not 'resp' in dir() else json.dumps(resp))
        err = resp.get('error', {}).get('message', str(e))
        print('ERROR:' + err)
    except Exception:
        print('ERROR:' + str(e))
" <<< "$GEMINI_RESPONSE" 2>/dev/null)

          if echo "$ANALYSIS" | grep -q "^ERROR:"; then
            ERR_MSG=$(echo "$ANALYSIS" | sed 's/^ERROR://')
            log "ERROR: Gemini analysis failed: $ERR_MSG"
            RESULT_STATUS="error"
            RESULT_DETAILS="Gemini analysis failed: $ERR_MSG"
          else
            log "Image analysis complete"
            RESULT_ACTION="image-analyzed"
            RESULT_AGENT="iris"

            # Save analysis as a style seed in content-seed-bank
            if [ -x "$SEED_STORE" ]; then
              SEED_TEXT=$(python3 -c "
import json, sys
try:
    a = json.loads(sys.stdin.read())
    parts = []
    parts.append('Style: ' + a.get('style', 'unknown'))
    parts.append('Mood: ' + a.get('mood', 'unknown'))
    colors = a.get('colors', [])
    if colors:
        parts.append('Colors: ' + ', '.join(str(c) for c in colors))
    parts.append('Composition: ' + a.get('composition', 'unknown'))
    parts.append('Subject: ' + a.get('subject', 'unknown'))
    parts.append('Techniques: ' + a.get('techniques', 'unknown'))
    parts.append('Production notes: ' + a.get('production_notes', ''))
    print(' | '.join(parts))
except Exception:
    print('Image style seed from intake')
" <<< "$ANALYSIS" 2>/dev/null)

              SEED_TAGS="intake,image-ref,style-seed"
              if [ -n "$INPUT_BRAND" ]; then
                SEED_TAGS="$SEED_TAGS,$INPUT_BRAND"
              fi

              RESULT_SEED_ID=$(bash "$SEED_STORE" add \
                --type image \
                --text "$SEED_TEXT" \
                --tags "$SEED_TAGS" \
                --source "iris" \
                --source-type "manual" \
                --status "draft" 2>/dev/null | grep -o 'seed-[a-z0-9-]*' | head -1) || true

              if [ -n "$RESULT_SEED_ID" ]; then
                log "Created style seed: $RESULT_SEED_ID"
              else
                log "WARNING: seed-store.sh did not return a seed ID"
              fi
            else
              log "WARNING: seed-store.sh not found at $SEED_STORE"
            fi

            # Check if suggested output type is new
            SUGGESTED_TYPE=$(python3 -c "
import json, sys
try:
    a = json.loads(sys.stdin.read())
    print(a.get('suggested_output_type', ''))
except Exception:
    print('')
" <<< "$ANALYSIS" 2>/dev/null)

            CONFIDENCE=$(python3 -c "
import json, sys
try:
    a = json.loads(sys.stdin.read())
    print(a.get('confidence', 0))
except Exception:
    print('0')
" <<< "$ANALYSIS" 2>/dev/null)

            IS_NEW_TYPE="false"
            if [ -n "$SUGGESTED_TYPE" ]; then
              IS_NEW_TYPE=$(python3 -c "
import json, os
suggested = '$SUGGESTED_TYPE'.lower().strip().replace(' ', '-')
types_file = os.path.expanduser('$OUTPUT_TYPES_FILE')
if os.path.exists(types_file):
    try:
        with open(types_file) as f:
            types = json.load(f)
        existing_ids = [t.get('id','').lower() for t in types if isinstance(t, dict)]
        if suggested not in existing_ids:
            print('true')
        else:
            print('false')
    except Exception:
        print('false')
else:
    print('false')
" 2>/dev/null)
            fi

            if [ "$IS_NEW_TYPE" = "true" ]; then
              log "New output type suggested: $SUGGESTED_TYPE (confidence: $CONFIDENCE)"
              RESULT_NEW_TYPE="$SUGGESTED_TYPE"

              # Only auto-register if confidence is high enough
              CONF_HIGH=$(python3 -c "print('yes' if float('$CONFIDENCE') >= 0.7 else 'no')" 2>/dev/null)

              if [ "$CONF_HIGH" = "yes" ] && [ -x "$REGISTER_OUTPUT_TYPE" ]; then
                # Tier check: new-output-type is tier 3, requires approval
                REG_TIER=$(get_tier "new-output-type")
                NEW_TYPE_PAYLOAD=$(python3 -c "
import json, sys

analysis = json.loads(sys.stdin.read())
new_type = {
    'id': '$SUGGESTED_TYPE'.lower().strip().replace(' ', '-'),
    'name': '$SUGGESTED_TYPE',
    'description': 'Auto-discovered from image intake. ' + analysis.get('production_notes', ''),
    'funnel_stage': 'TOFU',
    'aspect_ratios': ['9:16', '1:1'],
    'style_params': {
        'style': analysis.get('style', ''),
        'mood': analysis.get('mood', ''),
        'colors': analysis.get('colors', []),
        'composition': analysis.get('composition', ''),
        'techniques': analysis.get('techniques', '')
    },
    'generation_tools': ['zimage', 'kling'],
    'requested_by': '$INPUT_REQUESTED_BY',
    'source': 'creative-intake'
}
print(json.dumps(new_type))
" <<< "$ANALYSIS" 2>/dev/null)

                if [ "$REG_TIER" = "3" ]; then
                  # Tier 3: queue for human approval
                  log "Tier 3: Queuing new output type for approval: $SUGGESTED_TYPE"
                  APPR_ID=$(submit_approval \
                    "new-output-type" \
                    "${INPUT_AGENT:-iris}" \
                    "New output type from image intake: $SUGGESTED_TYPE" \
                    "$NEW_TYPE_PAYLOAD")
                  if [ -n "$APPR_ID" ]; then
                    log "Queued for approval: $APPR_ID (type: $SUGGESTED_TYPE)"
                    RESULT_DETAILS=$(python3 -c "
import json, sys
try:
    details = json.loads(sys.stdin.read())
except Exception:
    details = {}
details['approval_id'] = '$APPR_ID'
details['approval_status'] = 'pending'
print(json.dumps(details))
" <<< "$RESULT_DETAILS" 2>/dev/null)
                  fi
                else
                  # Tier 1 or 2: execute directly
                  log "Tier $REG_TIER: Auto-registering new output type: $SUGGESTED_TYPE"
                  REG_RESULT=$(echo "$NEW_TYPE_PAYLOAD" | bash "$REGISTER_OUTPUT_TYPE" --from-approval 2>>"$LOG_FILE") || true

                  if [ -n "$REG_RESULT" ]; then
                    log "Registered new output type: $REG_RESULT"
                  else
                    log "WARNING: register-output-type.sh did not return a type ID"
                  fi

                  # Tier 2: post audit trail
                  if [ "$REG_TIER" = "2" ]; then
                    post_tier2_audit "new-output-type" "${INPUT_AGENT:-iris}" "Auto-registered output type: $SUGGESTED_TYPE"
                  fi
                fi
              else
                log "Suggested type confidence too low ($CONFIDENCE < 0.7) or register script not found. Logging for manual review."
              fi
            fi

            # Dispatch to Iris for production with the analysis as context
            if [ -x "$DISPATCH" ]; then
              DISPATCH_MSG="[INTAKE] Image analyzed for production reference."
              DISPATCH_MSG="$DISPATCH_MSG | Style: $(python3 -c "import json,sys; a=json.loads(sys.stdin.read()); print(a.get('style','unknown'))" <<< "$ANALYSIS" 2>/dev/null)"
              DISPATCH_MSG="$DISPATCH_MSG | Mood: $(python3 -c "import json,sys; a=json.loads(sys.stdin.read()); print(a.get('mood','unknown'))" <<< "$ANALYSIS" 2>/dev/null)"
              DISPATCH_MSG="$DISPATCH_MSG | Type: ${SUGGESTED_TYPE:-unknown}"
              if [ -n "$INPUT_BRAND" ]; then
                DISPATCH_MSG="$DISPATCH_MSG | Brand: $INPUT_BRAND"
              fi
              if [ -n "$RESULT_SEED_ID" ]; then
                DISPATCH_MSG="$DISPATCH_MSG | Seed: $RESULT_SEED_ID"
              fi
              DISPATCH_MSG="$DISPATCH_MSG | File: $FILE_PATH"
              bash "$DISPATCH" "zenni" "iris" "request" "$DISPATCH_MSG" "creative" 2>>"$LOG_FILE" || true
            fi

            RESULT_DETAILS="$ANALYSIS"
          fi
        fi
      fi
    fi
  fi
  ;;

# =========================================================================
# TYPE: VIDEO
# =========================================================================
video)
  FILE_PATH="$INPUT_FILE_PATH"
  if [ -z "$FILE_PATH" ]; then
    FILE_PATH="$INPUT_CONTENT"
  fi

  log "Processing video: $FILE_PATH"

  if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    log "ERROR: Video file not found: $FILE_PATH"
    RESULT_STATUS="error"
    RESULT_DETAILS="Video file not found: $FILE_PATH"
  else
    # Check for ffmpeg
    if ! command -v ffmpeg >/dev/null 2>&1; then
      log "ERROR: ffmpeg not found"
      RESULT_STATUS="error"
      RESULT_DETAILS="ffmpeg not installed. Cannot extract video frames."
    else
      # Get video duration
      DURATION=$(python3 -c "
import subprocess, re
result = subprocess.run(
    ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', '$FILE_PATH'],
    capture_output=True, text=True
)
try:
    print(float(result.stdout.strip()))
except Exception:
    print('0')
" 2>/dev/null)
      DURATION="${DURATION:-0}"

      log "Video duration: ${DURATION}s"

      # Extract 5 evenly spaced frames
      FRAMES_DIR="$TMP_DIR/frames"
      mkdir -p "$FRAMES_DIR"

      python3 -c "
import subprocess, os

duration = float('$DURATION')
if duration <= 0:
    duration = 10  # fallback: just try first 10 seconds

num_frames = 5
interval = duration / (num_frames + 1)

for i in range(1, num_frames + 1):
    timestamp = interval * i
    output = '$FRAMES_DIR/frame_%02d.jpg' % i
    subprocess.run([
        'ffmpeg', '-y', '-ss', str(timestamp), '-i', '$FILE_PATH',
        '-vframes', '1', '-q:v', '3', output
    ], capture_output=True, timeout=30)
" 2>/dev/null || {
        log "WARNING: Some frame extraction may have failed"
      }

      # Count extracted frames
      FRAME_COUNT=$(ls "$FRAMES_DIR"/frame_*.jpg 2>/dev/null | wc -l | tr -d ' ')

      if [ "$FRAME_COUNT" -eq 0 ]; then
        log "ERROR: No frames extracted from video"
        RESULT_STATUS="error"
        RESULT_DETAILS="Failed to extract frames from video"
      else
        log "Extracted $FRAME_COUNT frames, sending to Gemini Vision"

        # Get Gemini API key
        GEMINI_API_KEY=$(get_gemini_key)

        if [ -z "$GEMINI_API_KEY" ]; then
          log "ERROR: GEMINI_API_KEY not found"
          RESULT_STATUS="error"
          RESULT_DETAILS="GEMINI_API_KEY not found. Cannot analyze video frames."
        else
          # Get existing output types for the prompt
          EXISTING_TYPES=$(get_existing_output_types)

          # Build multi-frame request: send first 3 frames to save memory (8GB constraint)
          MAX_FRAMES=3
          python3 -c "
import json, base64, os, glob

frames_dir = '$FRAMES_DIR'
frames = sorted(glob.glob(os.path.join(frames_dir, 'frame_*.jpg')))[:$MAX_FRAMES]

parts = []
for frame_path in frames:
    with open(frame_path, 'rb') as f:
        b64 = base64.b64encode(f.read()).decode('ascii')
    parts.append({'inlineData': {'mimeType': 'image/jpeg', 'data': b64}})

prompt_text = '''Analyze these video frames (extracted from a single video, evenly spaced) for creative production reference. Return a JSON object with these exact fields:
{
  \"technique\": \"(primary video technique: e.g. stop-motion, timelapse, slow-motion, jump-cuts, montage, talking-head, POV, etc.)\",
  \"hooks\": [\"list of hook techniques visible in the opening frames\"],
  \"effects\": [\"list of visual effects: transitions, overlays, color grading, text animations, etc.\"],
  \"editing_style\": \"(overall editing approach: fast-paced, slow-contemplative, raw-authentic, polished-studio, etc.)\",
  \"pacing\": \"(fast/medium/slow)\",
  \"mood\": \"(mood conveyed by the video)\",
  \"subject\": \"(main subject of the video)\",
  \"suggested_output_type\": \"(which GAIA output type this matches: one of: $EXISTING_TYPES — or suggest a NEW type if none fit)\",
  \"confidence\": 0.0-1.0,
  \"production_notes\": \"(how GAIA could reproduce this technique for F&B/wellness content)\"
}
Return ONLY the JSON object, no markdown fences, no explanation.'''

parts.append({'text': prompt_text})

payload = {
    'contents': [{'parts': parts}],
    'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024
    }
}

with open('$TMP_DIR/video_request.json', 'w') as f:
    json.dump(payload, f)
" 2>/dev/null

          # Call Gemini API
          GEMINI_RESPONSE=$(curl -s -m 90 \
            "https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}" \
            -H "Content-Type: application/json" \
            -d @"$TMP_DIR/video_request.json" 2>/dev/null)

          # Clean up temp files
          rm -rf "$FRAMES_DIR" "$TMP_DIR/video_request.json" 2>/dev/null

          if [ -z "$GEMINI_RESPONSE" ]; then
            log "ERROR: Empty response from Gemini API for video analysis"
            RESULT_STATUS="error"
            RESULT_DETAILS="Empty response from Gemini Vision API"
          else
            # Parse the analysis
            ANALYSIS=$(python3 -c "
import json, sys, re

try:
    resp = json.loads(sys.stdin.read())
    text = resp.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '')
    if not text:
        print('ERROR:No text in Gemini response')
        sys.exit(0)
    text = text.strip()
    fence = chr(96)*3
    text = re.sub(r'^' + fence + r'json\s*', '', text)
    text = re.sub(r'^' + fence + r'\s*', '', text)
    text = re.sub(r'\s*' + fence + r'$', '', text)
    text = text.strip()
    analysis = json.loads(text)
    print(json.dumps(analysis))
except Exception as e:
    print('ERROR:' + str(e))
" <<< "$GEMINI_RESPONSE" 2>/dev/null)

            if echo "$ANALYSIS" | grep -q "^ERROR:"; then
              ERR_MSG=$(echo "$ANALYSIS" | sed 's/^ERROR://')
              log "ERROR: Video analysis failed: $ERR_MSG"
              RESULT_STATUS="error"
              RESULT_DETAILS="Video analysis failed: $ERR_MSG"
            else
              log "Video analysis complete"
              RESULT_ACTION="video-analyzed"
              RESULT_AGENT="iris"

              # Save as seed
              if [ -x "$SEED_STORE" ]; then
                SEED_TEXT=$(python3 -c "
import json, sys
try:
    a = json.loads(sys.stdin.read())
    parts = []
    parts.append('Technique: ' + a.get('technique', 'unknown'))
    parts.append('Editing: ' + a.get('editing_style', 'unknown'))
    parts.append('Pacing: ' + a.get('pacing', 'unknown'))
    parts.append('Mood: ' + a.get('mood', 'unknown'))
    hooks = a.get('hooks', [])
    if hooks:
        parts.append('Hooks: ' + ', '.join(str(h) for h in hooks))
    effects = a.get('effects', [])
    if effects:
        parts.append('Effects: ' + ', '.join(str(e) for e in effects))
    parts.append('Production notes: ' + a.get('production_notes', ''))
    print(' | '.join(parts))
except Exception:
    print('Video technique seed from intake')
" <<< "$ANALYSIS" 2>/dev/null)

                SEED_TAGS="intake,video-ref,technique-seed"
                if [ -n "$INPUT_BRAND" ]; then
                  SEED_TAGS="$SEED_TAGS,$INPUT_BRAND"
                fi

                RESULT_SEED_ID=$(bash "$SEED_STORE" add \
                  --type video \
                  --text "$SEED_TEXT" \
                  --tags "$SEED_TAGS" \
                  --source "iris" \
                  --source-type "manual" \
                  --status "draft" 2>/dev/null | grep -o 'seed-[a-z0-9-]*' | head -1) || true

                if [ -n "$RESULT_SEED_ID" ]; then
                  log "Created technique seed: $RESULT_SEED_ID"
                fi
              fi

              # Check for new output type
              SUGGESTED_TYPE=$(python3 -c "
import json, sys
try:
    a = json.loads(sys.stdin.read())
    print(a.get('suggested_output_type', ''))
except Exception:
    print('')
" <<< "$ANALYSIS" 2>/dev/null)

              CONFIDENCE=$(python3 -c "
import json, sys
try:
    a = json.loads(sys.stdin.read())
    print(a.get('confidence', 0))
except Exception:
    print('0')
" <<< "$ANALYSIS" 2>/dev/null)

              IS_NEW_TYPE=$(python3 -c "
import json, os
suggested = '$SUGGESTED_TYPE'.lower().strip().replace(' ', '-')
types_file = os.path.expanduser('$OUTPUT_TYPES_FILE')
if suggested and os.path.exists(types_file):
    try:
        with open(types_file) as f:
            types = json.load(f)
        existing_ids = [t.get('id','').lower() for t in types if isinstance(t, dict)]
        if suggested not in existing_ids:
            print('true')
        else:
            print('false')
    except Exception:
        print('false')
else:
    print('false')
" 2>/dev/null)

              if [ "$IS_NEW_TYPE" = "true" ]; then
                log "New output type suggested from video: $SUGGESTED_TYPE"
                RESULT_NEW_TYPE="$SUGGESTED_TYPE"

                CONF_HIGH=$(python3 -c "print('yes' if float('$CONFIDENCE') >= 0.7 else 'no')" 2>/dev/null)

                if [ "$CONF_HIGH" = "yes" ] && [ -x "$REGISTER_OUTPUT_TYPE" ]; then
                  # Tier check: new-output-type is tier 3, requires approval
                  REG_TIER=$(get_tier "new-output-type")
                  NEW_TYPE_PAYLOAD=$(python3 -c "
import json, sys

analysis = json.loads(sys.stdin.read())
new_type = {
    'id': '$SUGGESTED_TYPE'.lower().strip().replace(' ', '-'),
    'name': '$SUGGESTED_TYPE',
    'description': 'Auto-discovered from video intake. ' + analysis.get('production_notes', ''),
    'funnel_stage': 'TOFU',
    'aspect_ratios': ['9:16'],
    'style_params': {
        'technique': analysis.get('technique', ''),
        'editing_style': analysis.get('editing_style', ''),
        'hooks': analysis.get('hooks', []),
        'effects': analysis.get('effects', []),
        'pacing': analysis.get('pacing', '')
    },
    'generation_tools': ['kling', 'sora'],
    'requested_by': '$INPUT_REQUESTED_BY',
    'source': 'creative-intake'
}
print(json.dumps(new_type))
" <<< "$ANALYSIS" 2>/dev/null)

                  if [ "$REG_TIER" = "3" ]; then
                    # Tier 3: queue for human approval
                    log "Tier 3: Queuing new output type for approval: $SUGGESTED_TYPE"
                    APPR_ID=$(submit_approval \
                      "new-output-type" \
                      "${INPUT_AGENT:-iris}" \
                      "New output type from video intake: $SUGGESTED_TYPE" \
                      "$NEW_TYPE_PAYLOAD")
                    if [ -n "$APPR_ID" ]; then
                      log "Queued for approval: $APPR_ID (type: $SUGGESTED_TYPE)"
                    fi
                  else
                    # Tier 1 or 2: execute directly
                    log "Tier $REG_TIER: Auto-registering new output type from video: $SUGGESTED_TYPE"
                    REG_RESULT=$(echo "$NEW_TYPE_PAYLOAD" | bash "$REGISTER_OUTPUT_TYPE" --from-approval 2>>"$LOG_FILE") || true
                    if [ -n "$REG_RESULT" ]; then
                      log "Registered new output type: $REG_RESULT"
                    fi
                    # Tier 2: post audit trail
                    if [ "$REG_TIER" = "2" ]; then
                      post_tier2_audit "new-output-type" "${INPUT_AGENT:-iris}" "Auto-registered output type from video: $SUGGESTED_TYPE"
                    fi
                  fi
                fi
              fi

              # Dispatch to production room
              if [ -x "$DISPATCH" ]; then
                TECHNIQUE=$(python3 -c "import json,sys; a=json.loads(sys.stdin.read()); print(a.get('technique','unknown'))" <<< "$ANALYSIS" 2>/dev/null)
                DISPATCH_MSG="[INTAKE] Video analyzed. Technique: $TECHNIQUE | Type: ${SUGGESTED_TYPE:-matched-existing}"
                if [ -n "$INPUT_BRAND" ]; then
                  DISPATCH_MSG="$DISPATCH_MSG | Brand: $INPUT_BRAND"
                fi
                if [ -n "$RESULT_SEED_ID" ]; then
                  DISPATCH_MSG="$DISPATCH_MSG | Seed: $RESULT_SEED_ID"
                fi
                bash "$DISPATCH" "zenni" "iris" "request" "$DISPATCH_MSG" "creative" 2>>"$LOG_FILE" || true
              fi

              RESULT_DETAILS="$ANALYSIS"
            fi
          fi
        fi
      fi
    fi
  fi
  ;;

# =========================================================================
# TYPE: TEXT
# =========================================================================
text)
  log "Processing text brief"
  BRIEF_TEXT="$INPUT_CONTENT"
  if [ -z "$BRIEF_TEXT" ]; then
    BRIEF_TEXT="$INPUT_CONTEXT"
  fi

  if [ -z "$BRIEF_TEXT" ]; then
    log "ERROR: Text type but no content provided"
    RESULT_STATUS="error"
    RESULT_DETAILS="Text type but no content provided"
  else
    RESULT_ACTION="creative-brief"
    RESULT_AGENT="dreami"
    RESULT_DETAILS="Text brief received. Routing to Dreami for creative direction."

    # Dispatch to Dreami
    if [ -x "$DISPATCH" ]; then
      DISPATCH_MSG="[INTAKE] Creative brief from ${INPUT_REQUESTED_BY}: $BRIEF_TEXT"
      if [ -n "$INPUT_BRAND" ]; then
        DISPATCH_MSG="$DISPATCH_MSG | Brand: $INPUT_BRAND"
      fi
      if [ -n "$INPUT_CONTEXT" ] && [ "$INPUT_CONTEXT" != "$BRIEF_TEXT" ]; then
        DISPATCH_MSG="$DISPATCH_MSG | Context: $INPUT_CONTEXT"
      fi
      bash "$DISPATCH" "zenni" "dreami" "request" "$DISPATCH_MSG" "creative" 2>>"$LOG_FILE" || true
    fi
  fi
  ;;

# =========================================================================
# UNKNOWN TYPE
# =========================================================================
*)
  log "ERROR: Unknown input type: $INPUT_TYPE"
  RESULT_STATUS="error"
  RESULT_DETAILS="Unknown input type: $INPUT_TYPE"
  ;;
esac

# ---------------------------------------------------------------------------
# Step 3: Log to intake room
# ---------------------------------------------------------------------------

INTAKE_LOG_JSON=$(python3 -c "
import json, time

result = {
    'ts': int(time.time() * 1000),
    'agent': '$INPUT_AGENT',
    'source': '$INPUT_SOURCE',
    'type': 'intake-processed',
    'input_type': '$INPUT_TYPE',
    'status': '$RESULT_STATUS',
    'action': '$(echo "$RESULT_ACTION" | sed "s/'/\\\\'/g")',
    'routed_to': '$RESULT_AGENT',
    'brand': '$INPUT_BRAND',
    'requested_by': '$INPUT_REQUESTED_BY'
}

content = '$(echo "$INPUT_CONTENT" | head -c 200 | sed "s/'/\\\\'/g")'
if content:
    result['content_preview'] = content[:200]

seed_id = '$RESULT_SEED_ID'
if seed_id:
    result['seed_id'] = seed_id

new_type = '$(echo "$RESULT_NEW_TYPE" | sed "s/'/\\\\'/g")'
if new_type:
    result['new_output_type'] = new_type

print(json.dumps(result, ensure_ascii=False))
" 2>/dev/null)

if [ -n "$INTAKE_LOG_JSON" ]; then
  post_to_room "$INTAKE_ROOM" "$INTAKE_LOG_JSON"
  log "Logged intake event to intake.jsonl"
fi

# Post summary to creative room
CREATIVE_MSG=$(python3 -c "
import json, time

msg = {
    'ts': int(time.time() * 1000),
    'agent': 'intake-engine',
    'room': 'creative',
    'type': 'intake-result',
    'msg': '[INTAKE] Processed $INPUT_TYPE input from $INPUT_SOURCE. Action: ${RESULT_ACTION:-none}. Routed to: ${RESULT_AGENT:-none}.'
}
print(json.dumps(msg, ensure_ascii=False))
" 2>/dev/null)

if [ -n "$CREATIVE_MSG" ]; then
  post_to_room "$CREATIVE_ROOM" "$CREATIVE_MSG"
fi

# ---------------------------------------------------------------------------
# Step 4: Output result JSON to stdout
# ---------------------------------------------------------------------------

RESULT_JSON=$(python3 -c "
import json, time

result = {
    'status': '$RESULT_STATUS',
    'input_type': '$INPUT_TYPE',
    'action': '$(echo "$RESULT_ACTION" | sed "s/'/\\\\'/g")',
    'routed_to': '$RESULT_AGENT',
    'brand': '$INPUT_BRAND',
    'ts': int(time.time() * 1000)
}

seed_id = '$RESULT_SEED_ID'
if seed_id:
    result['seed_id'] = seed_id

new_type = '$(echo "$RESULT_NEW_TYPE" | sed "s/'/\\\\'/g")'
if new_type:
    result['new_output_type'] = new_type

# Try to parse details as JSON; if not, include as string
details_raw = '''$(echo "$RESULT_DETAILS" | python3 -c "import sys; print(sys.stdin.read().replace(chr(39), chr(92)+chr(39)).replace(chr(10), ' '))" 2>/dev/null)'''
try:
    result['details'] = json.loads(details_raw)
except Exception:
    if details_raw.strip():
        result['details'] = details_raw.strip()

print(json.dumps(result, ensure_ascii=False))
" 2>/dev/null)

log "Intake processing complete: status=$RESULT_STATUS action=$RESULT_ACTION routed_to=$RESULT_AGENT"

printf '%s\n' "$RESULT_JSON"
