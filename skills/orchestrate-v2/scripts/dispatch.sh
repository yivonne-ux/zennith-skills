#!/usr/bin/env bash
# dispatch.sh — Zenni's universal agent dispatcher
# Wraps sessions_spawn with the right model/label per agent
# Logs every dispatch to ~/.openclaw/logs/dispatch-log.jsonl
#
# Usage:
#   bash dispatch.sh <agent_id> "<task_brief>" "<label>" [thinking_level] [timeout_seconds]
#
# Agents: taoz | dreami | scout
# Thinking levels: low | medium | high (default: medium)
# Timeout: seconds (default: 300)
#
# Examples:
#   bash dispatch.sh "scout" "Check if gaiaos.com is live" "scout-health"
#   bash dispatch.sh "taoz" "Build skill orchestrate-v2" "taoz-skill" "medium" 600
#   bash dispatch.sh "scout" "Research vegan protein brands MY" "scout-vegan"

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
AGENT="${1:-}"
TASK="${2:-}"
LABEL="${3:-}"
THINKING="${4:-medium}"
TIMEOUT="${5:-300}"
EXECUTE="${6:-true}"  # Default: actually dispatch. Set "false" to only print config.

if [[ -z "$AGENT" || -z "$TASK" || -z "$LABEL" ]]; then
  echo "❌ Usage: dispatch.sh <agent> <task> <label> [thinking] [timeout_seconds]"
  echo "   Agents: taoz | dreami | scout"
  exit 1
fi

# ── Agent → Model (reads from openclaw.json — source of truth) ────────────────
get_model() {
  local agent="$1"
  local config="$HOME/.openclaw/openclaw.json"
  # Read primary model from openclaw.json (source of truth)
  local model
  model=$(python3 -c "
import json, os
with open(os.path.expanduser('$config')) as f:
    data = json.load(f)
for a in data['agents']['list']:
    if a['id'] == '$agent':
        print(a.get('model',{}).get('primary',''))
        break
" 2>/dev/null)
  if [[ -n "$model" ]]; then
    echo "$model"
  else
    echo "openrouter/z-ai/glm-4.7-flash"  # safe fallback
  fi
}

get_cost_tier() {
  case "$1" in
    scout)  echo "cheapest (gemini-3-flash)" ;;
    taoz)   echo "cheapest (chat=gpt-5.4, builds=Claude Code CLI Opus 4.6)" ;;
    dreami) echo "free (gemini-3.1-pro)" ;;
    main)   echo "free (gpt-5.4)" ;;
    *)      echo "unknown" ;;
  esac
}

get_agent_context() {
  case "$1" in
    scout)
      echo "You are Scout — the research and ops agent of Zennith OS. You find information, research markets, scrape data (use scrapling skill), run bulk ops, and deliver structured findings. Use web_search, web_fetch, and scrape.sh aggressively."
      ;;
    taoz)
      echo "You are Taoz — the builder agent of Zennith OS. You write code, build skills, fix bugs, and deploy infrastructure. Use your full tool suite. Run regression if touching classify.sh."
      ;;
    dreami)
      echo "You are Dreami — the creative director of Zennith OS. You write compelling copy, develop campaign concepts, generate images (NanoBanana), manage social content, and give creative direction. Output polished, ready-to-use content."
      ;;
    main)
      echo "You are Zenni — the CEO orchestrator of Zennith OS. You route tasks, analyze strategy, build plans, and provide business insights. Think deeply; structure outputs clearly."
      ;;
  esac
}

# ── Validate agent ────────────────────────────────────────────────────────────
MODEL=$(get_model "$AGENT")
if [[ -z "$MODEL" ]]; then
  echo "❌ Unknown agent: '$AGENT'"
  echo "   Valid: taoz | dreami | scout"
  exit 1
fi

COST_TIER=$(get_cost_tier "$AGENT")
AGENT_CONTEXT=$(get_agent_context "$AGENT")

# ── Log paths ─────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.openclaw/logs"
DISPATCH_LOG="$LOG_DIR/dispatch-log.jsonl"
ACTIVE_LOG="$LOG_DIR/dispatch-active.jsonl"
mkdir -p "$LOG_DIR"

# ── Timestamp ─────────────────────────────────────────────────────────────────
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TS_LOCAL=$(date +"%Y-%m-%d %H:%M %Z")

# ── Generate unique task ID ──────────────────────────────────────────────────
TASK_ID="${LABEL}-$(date +%s)-$(head -c4 /dev/urandom | xxd -p 2>/dev/null || echo $$)"
OUTPUT_FILE="$HOME/.openclaw/logs/dispatch-output-${TASK_ID}.md"

# ── Build the full task prompt for the subagent ───────────────────────────────
FULL_TASK="${AGENT_CONTEXT}

---

TASK ID: ${TASK_ID}
DISPATCHED BY: Zenni at ${TS_LOCAL}

RECEIPT REQUIRED: Before starting work, you MUST write this exact line:
RECEIPT: ${TASK_ID} — ACCEPTED

TASK:
${TASK}

---

OUTPUT RULES:
1. Write your main output to: ${OUTPUT_FILE}
2. If you create other files, list ALL paths at the end.
3. When complete, write this exact line: DONE: ${TASK_ID}
4. Post summary to the mission room if one is specified in the task."

# ── Print dispatch header ─────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DISPATCH: $AGENT → $LABEL"
echo "   Model:    $MODEL"
echo "   Cost:     $COST_TIER"
echo "   Thinking: $THINKING"
echo "   Timeout:  ${TIMEOUT}s"
echo "   Time:     $TS_LOCAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Log the dispatch ──────────────────────────────────────────────────────────
TASK_PREVIEW=$(echo "$TASK" | head -c 200 | tr '\n' ' ' | sed 's/"/\\"/g')
DISPATCH_ENTRY="{\"ts\":\"$TS\",\"agent\":\"$AGENT\",\"label\":\"$LABEL\",\"task_id\":\"$TASK_ID\",\"model\":\"$MODEL\",\"cost_tier\":\"$COST_TIER\",\"thinking\":\"$THINKING\",\"timeout\":$TIMEOUT,\"task_preview\":\"$TASK_PREVIEW\",\"output_file\":\"$OUTPUT_FILE\",\"status\":\"dispatched\"}"
echo "$DISPATCH_ENTRY" >> "$DISPATCH_LOG"
echo "$DISPATCH_ENTRY" >> "$ACTIVE_LOG"

echo "📋 Logged to dispatch-log.jsonl"
echo ""

# ── Output sessions_spawn config (for Zenni to use as tool call) ──────────────
# dispatch.sh serves two purposes:
#   1. Shell context: emits openclaw CLI command + sessions_spawn JSON params
#   2. AI context: Zenni reads this output and uses sessions_spawn tool directly
#
echo "📦 sessions_spawn config (use this in your sessions_spawn tool call):"
echo ""
python3 -c "
import json, sys
task = sys.argv[1]
agent = sys.argv[2]
model = sys.argv[3]
label = sys.argv[4]
thinking = sys.argv[5]
timeout = int(sys.argv[6])

config = {
    'label': label,
    'model': model,
    'thinking': thinking,
    'timeoutSeconds': timeout,
    'task': task
}
print(json.dumps(config, indent=2, ensure_ascii=False))
" "$FULL_TASK" "$AGENT" "$MODEL" "$LABEL" "$THINKING" "$TIMEOUT"

echo ""
echo "📌 CLI equivalent (if running from shell):"
echo "   openclaw agent --agent $AGENT --message \"$(echo "$TASK" | head -c 80)...\""
echo ""

# ── Auto-execute dispatch (default: true) ──────────────────────────────────
if [[ "$EXECUTE" == "true" ]]; then
  echo "🔥 EXECUTING dispatch via openclaw agent..."
  echo ""

  # Run in background with timeout + verification
  (
    RESULT=$(timeout "$TIMEOUT" openclaw agent --agent "$AGENT" -m "$FULL_TASK" 2>&1) || true

    # Verify receipt
    if echo "$RESULT" | grep -q "RECEIPT: $TASK_ID"; then
      RECEIPT_STATUS="confirmed"
    else
      RECEIPT_STATUS="missing"
    fi

    # Verify completion
    if echo "$RESULT" | grep -q "DONE: $TASK_ID"; then
      DONE_STATUS="completed"
    else
      DONE_STATUS="unknown"
    fi

    # Check if output file was written
    if [ -f "$OUTPUT_FILE" ]; then
      OUTPUT_STATUS="file_written"
      OUTPUT_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
    else
      OUTPUT_STATUS="no_file"
      OUTPUT_SIZE=0
    fi

    # Post verified result to build room
    RESULT_PREVIEW=$(echo "$RESULT" | head -c 300 | tr '\n' ' ' | sed 's/"/\\"/g')
    printf '{"ts":%s000,"agent":"dispatch","room":"build","task_id":"%s","receipt":"%s","done":"%s","output":"%s","output_bytes":%s,"msg":"[DISPATCH DONE] %s → %s: %s"}\n' \
      "$(date +%s)" "$TASK_ID" "$RECEIPT_STATUS" "$DONE_STATUS" "$OUTPUT_STATUS" "$OUTPUT_SIZE" "$AGENT" "$LABEL" "$RESULT_PREVIEW" \
      >> "$HOME/.openclaw/workspace/rooms/build.jsonl"

    # Update dispatch log with final status
    printf '{"ts":"%s","task_id":"%s","agent":"%s","label":"%s","receipt":"%s","done":"%s","output":"%s","output_bytes":%s,"status":"finished"}\n' \
      "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$TASK_ID" "$AGENT" "$LABEL" "$RECEIPT_STATUS" "$DONE_STATUS" "$OUTPUT_STATUS" "$OUTPUT_SIZE" \
      >> "$DISPATCH_LOG"

    echo "$RESULT"

    # Print verification summary
    echo ""
    echo "━━━ DISPATCH VERIFICATION ━━━"
    echo "   Task ID:  $TASK_ID"
    echo "   Receipt:  $RECEIPT_STATUS"
    echo "   Done:     $DONE_STATUS"
    echo "   Output:   $OUTPUT_STATUS ($OUTPUT_SIZE bytes)"
    [ "$RECEIPT_STATUS" = "missing" ] && echo "   ⚠️  Agent may not have processed the correct task!"
    [ "$OUTPUT_STATUS" = "no_file" ] && echo "   ⚠️  Agent did not write to expected output file!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ) &

  DISPATCH_PID=$!
  echo "   PID: $DISPATCH_PID"
  echo "   Agent: $AGENT"
  echo "   Label: $LABEL"
  echo "   Task ID: $TASK_ID"
  echo "   Output file: $OUTPUT_FILE"
  echo ""
  echo "⏳ Running in background. Result will post to build room when done."
  echo "   Verify: grep '$TASK_ID' ~/.openclaw/logs/dispatch-log.jsonl"
  echo "   Output: cat $OUTPUT_FILE"
  echo ""
else
  echo "⏳ Config generated (--execute=false). Use the CLI command above to dispatch."
  echo "   Label: $LABEL"
  echo "   When done: bash track.sh done \"$LABEL\" success|fail \"summary\""
  echo ""
fi
