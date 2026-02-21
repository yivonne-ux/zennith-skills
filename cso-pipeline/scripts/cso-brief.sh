#!/usr/bin/env bash
# cso-brief.sh — Create a strategy from a brief, then run the CSO pipeline
# Takes free text (idea, brief, URL) and creates a new strategy in the GAIA backend,
# then hands off to cso-run.sh for full pipeline execution.
#
# Usage: bash cso-brief.sh "<free_text_brief>"
#
# Examples:
#   bash cso-brief.sh "Launch a Valentine's Day vegan gift box campaign for IG and TikTok"
#   bash cso-brief.sh "Promote new oat milk product line on Shopee and Lazada"
#   bash cso-brief.sh "https://example.com/campaign-reference — adapt this for GAIA"

set -uo pipefail

# Ensure PATH includes openclaw binary location
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

###############################################################################
# Configuration
###############################################################################

BRIEF="${1:?Usage: cso-brief.sh \"<free_text_brief>\"}"

API_BASE="http://ai.gaiafoodtech.com/api/v1/agent"
API_KEY="oLBye15RiSQt2AyVUNSwHmeglqzIkLHi"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/cso-pipeline.log"
CSO_RUN_SCRIPT="$OPENCLAW_DIR/skills/cso-pipeline/scripts/cso-run.sh"

mkdir -p "$ROOMS_DIR" "$(dirname "$LOG_FILE")"

###############################################################################
# Helper Functions
###############################################################################

log() {
  local level="$1"
  local msg="$2"
  local entry="[$(date +"%Y-%m-%d %H:%M:%S")] [CSO-BRIEF] [$level] $msg"
  echo "$entry"
  echo "$entry" >> "$LOG_FILE"
}

post_to_room() {
  local room="$1"
  local msg="$2"
  local safe_msg
  safe_msg=$(printf '%s' "$msg" | tr '\n' ' ' | sed 's/"/\\"/g' | cut -c1-2000)
  local entry
  entry=$(printf '{"ts":%s000,"agent":"zenni","room":"%s","type":"cso-brief","msg":"%s"}' \
    "$(date +%s)" "$room" "$safe_msg")
  echo "$entry" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null || true
}

###############################################################################
# Main
###############################################################################

log "INFO" "=========================================="
log "INFO" "CSO Brief received"
log "INFO" "Brief: $(echo "$BRIEF" | cut -c1-300)"
log "INFO" "=========================================="

post_to_room "exec" "[CSO BRIEF] Creating new strategy from brief: $(echo "$BRIEF" | cut -c1-200)"

# -----------------------------------------------------------------------
# Escape the brief for JSON
# -----------------------------------------------------------------------
# Use python3 to safely produce a JSON-encoded string
SAFE_BRIEF=$(printf '%s' "$BRIEF" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null)

# If python3 fails, fall back to simple escaping
if [ -z "$SAFE_BRIEF" ]; then
  SAFE_BRIEF=$(printf '%s' "$BRIEF" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/$//' | tr '\n' ' ')
  SAFE_BRIEF="\"$SAFE_BRIEF\""
fi

# -----------------------------------------------------------------------
# Generate a title from the brief (first 80 chars, cleaned up)
# -----------------------------------------------------------------------
TITLE=$(printf '%s' "$BRIEF" | cut -c1-80 | sed 's/[^a-zA-Z0-9 _.,-]//g')
SAFE_TITLE=$(printf '%s' "$TITLE" | sed 's/"/\\"/g')

# -----------------------------------------------------------------------
# Create strategy in the GAIA backend
# -----------------------------------------------------------------------
log "INFO" "Creating strategy in backend..."

PAYLOAD="{\"title\":\"$SAFE_TITLE\",\"description\":$SAFE_BRIEF,\"status\":\"DRAFT\"}"
TMP_FILE="/tmp/cso-brief-$$.json"

HTTP_CODE=$(curl -s -o "$TMP_FILE" -w "%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d "$PAYLOAD" \
  --max-time 30 \
  "${API_BASE}/strategies" 2>/dev/null)

RESPONSE=$(cat "$TMP_FILE" 2>/dev/null || echo "")
rm -f "$TMP_FILE"

# Check for success
case "$HTTP_CODE" in
  2[0-9][0-9])
    log "INFO" "Strategy created successfully (HTTP $HTTP_CODE)"
    ;;
  *)
    log "ERROR" "Failed to create strategy (HTTP $HTTP_CODE): $(echo "$RESPONSE" | cut -c1-500)"
    # Retry once
    log "WARN" "Retrying in 5s..."
    sleep 5
    HTTP_CODE=$(curl -s -o "$TMP_FILE" -w "%{http_code}" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "X-API-Key: $API_KEY" \
      -d "$PAYLOAD" \
      --max-time 30 \
      "${API_BASE}/strategies" 2>/dev/null)
    RESPONSE=$(cat "$TMP_FILE" 2>/dev/null || echo "")
    rm -f "$TMP_FILE"

    case "$HTTP_CODE" in
      2[0-9][0-9])
        log "INFO" "Strategy created on retry (HTTP $HTTP_CODE)"
        ;;
      *)
        log "ERROR" "Retry also failed (HTTP $HTTP_CODE): $(echo "$RESPONSE" | cut -c1-500)"
        post_to_room "feedback" "[CSO BRIEF FAILED] Could not create strategy. HTTP $HTTP_CODE. Brief: $(echo "$BRIEF" | cut -c1-200)"
        post_to_room "exec" "[CSO BRIEF FAILED] Could not create strategy from brief"
        exit 1
        ;;
    esac
    ;;
esac

# -----------------------------------------------------------------------
# Extract the new strategy ID from the response
# -----------------------------------------------------------------------
STRATEGY_ID=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Try common response shapes
    sid = d.get('id') or d.get('_id') or d.get('data', {}).get('id') or d.get('strategy', {}).get('id') or ''
    print(str(sid))
except:
    print('')
" 2>/dev/null)

if [ -z "$STRATEGY_ID" ]; then
  log "ERROR" "Could not extract strategy ID from response: $(echo "$RESPONSE" | cut -c1-500)"
  post_to_room "feedback" "[CSO BRIEF FAILED] Strategy created but could not extract ID. Response: $(echo "$RESPONSE" | cut -c1-300)"
  post_to_room "exec" "[CSO BRIEF FAILED] Strategy created but ID extraction failed"
  exit 1
fi

log "INFO" "New strategy created with ID: $STRATEGY_ID"
post_to_room "exec" "[CSO BRIEF] New strategy created: ID=$STRATEGY_ID, Title=$TITLE"

# -----------------------------------------------------------------------
# Hand off to cso-run.sh
# -----------------------------------------------------------------------
log "INFO" "Handing off to cso-run.sh..."

if [ ! -f "$CSO_RUN_SCRIPT" ]; then
  log "ERROR" "cso-run.sh not found at $CSO_RUN_SCRIPT"
  post_to_room "feedback" "[CSO BRIEF FAILED] cso-run.sh not found"
  exit 1
fi

exec bash "$CSO_RUN_SCRIPT" "$STRATEGY_ID"
