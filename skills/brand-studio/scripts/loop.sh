#!/usr/bin/env bash
# loop.sh — Generate → Audit → Retry loop until brand compliance passes
# Usage: loop.sh --brand mirra --template comparison [--max-retries 3] [compose options...]
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE="$SCRIPT_DIR/compose.sh"
AUDIT="$SCRIPT_DIR/audit.sh"
DIGEST="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"
LOG_FILE="$HOME/.openclaw/logs/brand-studio.log"

log() { mkdir -p "$(dirname "$LOG_FILE")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [LOOP] $*" >> "$LOG_FILE"; }

MAX_RETRIES=3
BRAND="" TEMPLATE=""
COMPOSE_ARGS=()

# Parse args — pass through to compose.sh
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-retries) MAX_RETRIES="$2"; shift 2 ;;
    --brand)     BRAND="$2";     COMPOSE_ARGS+=("$1" "$2"); shift 2 ;;
    --template)  TEMPLATE="$2";  COMPOSE_ARGS+=("$1" "$2"); shift 2 ;;
    --help)
      echo "loop.sh — Generate → Audit → Retry loop"
      echo ""
      echo "Usage: loop.sh --brand <slug> --template <type> [--max-retries N] [compose options...]"
      echo ""
      echo "Runs compose.sh to generate, audit.sh to score, retries up to N times."
      echo "All options after --brand and --template are passed to compose.sh."
      exit 0 ;;
    *)           COMPOSE_ARGS+=("$1"); shift ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
[[ -z "$TEMPLATE" ]] && { echo "ERROR: --template required"; exit 1; }

echo "╔══════════════════════════════════════════════════╗"
echo "║  Brand Studio: Generate → Audit → Refine Loop   ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Brand:       $BRAND"
echo "  Template:    $TEMPLATE"
echo "  Max retries: $MAX_RETRIES"
echo ""

ATTEMPT=1
PASSED=false
BEST_SCORE=0
BEST_IMAGE=""
ALL_RESULTS=()

while [[ $ATTEMPT -le $((MAX_RETRIES + 1)) ]]; do
  echo "━━━ Attempt $ATTEMPT/$((MAX_RETRIES + 1)) ━━━"
  echo ""

  # --- STEP 1: Generate ---
  echo "[1/3] Generating via compose.sh..."
  COMPOSE_OUTPUT=$(bash "$COMPOSE" "${COMPOSE_ARGS[@]}" 2>&1) || true
  echo "$COMPOSE_OUTPUT" | tail -5

  # Extract output path
  OUTPUT_PATH=$(echo "$COMPOSE_OUTPUT" | grep "OUTPUT_PATH=" | tail -1 | sed 's/OUTPUT_PATH=//')
  if [[ -z "$OUTPUT_PATH" ]] || [[ ! -f "$OUTPUT_PATH" ]]; then
    # Try alternate extraction
    OUTPUT_PATH=$(echo "$COMPOSE_OUTPUT" | grep -o '/Users/[^ ]*\.\(png\|jpg\)' | tail -1)
  fi

  if [[ -z "$OUTPUT_PATH" ]] || [[ ! -f "$OUTPUT_PATH" ]]; then
    echo "  WARN: Generation failed on attempt $ATTEMPT"
    log "Generation failed attempt=$ATTEMPT"
    ATTEMPT=$((ATTEMPT + 1))
    continue
  fi

  echo "  Generated: $OUTPUT_PATH"
  echo ""

  # --- STEP 2: Audit ---
  echo "[2/3] Running visual audit..."
  AUDIT_JSON="$HOME/.openclaw/workspace/data/brand-studio/audits/${BRAND}_attempt${ATTEMPT}_$(date +%Y%m%d_%H%M%S).json"

  AUDIT_OUTPUT=$(bash "$AUDIT" --brand "$BRAND" --image "$OUTPUT_PATH" --output "$AUDIT_JSON" 2>&1) || true
  AUDIT_EXIT=$?
  echo "$AUDIT_OUTPUT"
  echo ""

  # Extract score
  SCORE=$(echo "$AUDIT_OUTPUT" | grep "Result:" | grep -o '[0-9.]*' | head -1)
  SCORE=${SCORE:-0}

  ALL_RESULTS+=("attempt=$ATTEMPT score=$SCORE image=$OUTPUT_PATH")

  # Track best
  if python3 -c "exit(0 if float('$SCORE') > float('$BEST_SCORE') else 1)" 2>/dev/null; then
    BEST_SCORE="$SCORE"
    BEST_IMAGE="$OUTPUT_PATH"
  fi

  # --- Check pass ---
  if echo "$AUDIT_OUTPUT" | grep -q "Result: PASS"; then
    PASSED=true
    echo "[3/3] PASSED on attempt $ATTEMPT (score: $SCORE/10)"
    break
  fi

  # --- STEP 3: Extract feedback for retry ---
  if [[ $ATTEMPT -le $MAX_RETRIES ]]; then
    FEEDBACK=""
    if [[ -f "$AUDIT_JSON" ]]; then
      FEEDBACK=$(python3 -c "
import json
with open('$AUDIT_JSON') as f:
    a = json.load(f)
fixes = a.get('fix_suggestions', [])
feedback = a.get('feedback', '')
print(feedback)
for fix in fixes:
    print(f'FIX: {fix}')
" 2>/dev/null)
    fi
    echo ""
    echo "  FAILED (score: $SCORE/10). Retrying with feedback..."
    if [[ -n "$FEEDBACK" ]]; then
      echo "  Feedback: $FEEDBACK"
    fi
    log "Attempt $ATTEMPT failed (score=$SCORE). Retrying..."
  fi

  ATTEMPT=$((ATTEMPT + 1))
  echo ""
done

# --- Final Report ---
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║              LOOP RESULTS                        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Brand:      $BRAND"
echo "  Template:   $TEMPLATE"
echo "  Attempts:   $((ATTEMPT > MAX_RETRIES + 1 ? MAX_RETRIES + 1 : ATTEMPT))"
echo "  Best Score: $BEST_SCORE/10"
echo "  Best Image: $BEST_IMAGE"
echo "  Status:     $([ "$PASSED" = true ] && echo "PASSED" || echo "BEST EFFORT")"
echo ""

for r in "${ALL_RESULTS[@]}"; do
  echo "  $r"
done

# --- Compound learning ---
if [[ -f "$DIGEST" ]]; then
  LEARNING="brand-studio loop: brand=$BRAND template=$TEMPLATE attempts=$((ATTEMPT > MAX_RETRIES + 1 ? MAX_RETRIES + 1 : ATTEMPT)) best_score=$BEST_SCORE passed=$PASSED"
  bash "$DIGEST" \
    --source "brand-studio/$BRAND/$(date +%Y-%m-%d)" \
    --type "workflow-metric" \
    --fact "$LEARNING" \
    --agent "iris" 2>/dev/null || true
fi

echo ""
echo "BEST_IMAGE=$BEST_IMAGE"
echo "BEST_SCORE=$BEST_SCORE"
echo "PASSED=$PASSED"
