#!/usr/bin/env bash
# dispatch.sh — Inter-agent messaging for GAIA CORP-OS
# Any agent can send a message to any other agent via rooms.
#
# Usage: bash dispatch.sh <from_agent> <to_agent> <action> <message> [room]
#
# Actions: request, report, escalate, handoff, ping
#
# Examples:
#   bash dispatch.sh artemis apollo request "Need hero image for CNY email" build
#   bash dispatch.sh athena zenni report "Sales report for Feb 12 ready" exec
#   bash dispatch.sh healer zenni escalate "3 retries exhausted on M001" feedback

set -uo pipefail

# Ensure PATH includes openclaw binary location (cron has minimal PATH)
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

FROM="${1:?Usage: dispatch.sh <from> <to> <action> <message> [room]}"
TO="${2:?Missing: to_agent}"
ACTION="${3:?Missing: action (request|report|escalate|handoff|ping)}"
MESSAGE="${4:?Missing: message}"
ROOM="${5:-townhall}"

OPENCLAW_DIR="$HOME/.openclaw"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/dispatch.log"
TS_EPOCH=$(date +%s)
TS_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$ROOMS_DIR" "$(dirname "$LOG_FILE")"

# Validate action
case "$ACTION" in
  request|report|escalate|handoff|ping) ;;
  *) echo "ERROR: Invalid action '$ACTION'. Use: request|report|escalate|handoff|ping"; exit 1 ;;
esac

# Escape message for JSON (simple: replace quotes and newlines)
SAFE_MSG=$(echo "$MESSAGE" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 2000)

# Write to room JSONL
ENTRY="{\"ts\":${TS_EPOCH}000,\"agent\":\"$FROM\",\"to\":\"$TO\",\"room\":\"$ROOM\",\"type\":\"dispatch\",\"action\":\"$ACTION\",\"msg\":\"$SAFE_MSG\"}"
echo "$ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"

# Log
echo "[$TS_ISO] $FROM -> $TO ($ACTION) [$ROOM] $MESSAGE" >> "$LOG_FILE"

# If action is request or handoff, also invoke the target agent (if it's a real OpenClaw agent)
INVOKE_RESULT=""
if [ "$ACTION" = "request" ] || [ "$ACTION" = "handoff" ]; then
  # Alias mapping (rollback-safe: old names resolve to new)
  case "$TO" in
    calliope) TO="dreami" ;;
    daedalus) TO="artee" ;;
  esac

  # Check if target is a real agent (not taoz which uses claude-code-runner)
  case "$TO" in
    artemis|apollo|hermes|athena|iris|dreami|artee)
      PROMPT="[DISPATCH from $FROM — action: $ACTION]

$MESSAGE

Instructions:
- Complete this task and post your result
- Reference this dispatch in your response
- If you cannot complete, explain what's missing and suggest who can help"

      if command -v openclaw &>/dev/null; then
        # macOS has no `timeout` — use background + wait + kill pattern
        openclaw agent --agent "$TO" --message "$PROMPT" --json > /tmp/dispatch-resp-$$.json 2>&1 &
        BGPID=$!
        WAITED=0
        while kill -0 "$BGPID" 2>/dev/null && [ "$WAITED" -lt 300 ]; do
          sleep 1
          WAITED=$((WAITED + 1))
        done
        if kill -0 "$BGPID" 2>/dev/null; then
          kill "$BGPID" 2>/dev/null || true
          INVOKE_RESULT='{"error":"timeout after 300s"}'
        else
          INVOKE_RESULT=$(cat /tmp/dispatch-resp-$$.json 2>/dev/null || echo '{"error":"no output"}')
        fi
        rm -f /tmp/dispatch-resp-$$.json

        # Extract response text (handle both dict and list result shapes)
        RESPONSE=$(echo "$INVOKE_RESULT" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result', d) if isinstance(d, dict) else d
    if isinstance(r, dict):
        p=r.get('payloads', [])
        if p and isinstance(p[0], dict):
            print(p[0].get('text','')[:1500])
        else:
            print(json.dumps(r)[:1500])
    elif isinstance(r, list):
        for item in r:
            if isinstance(item, dict) and 'text' in item:
                print(item['text'][:1500]); break
        else:
            print(json.dumps(r)[:1500])
    else:
        print(str(r)[:1500])
except:
    print(sys.stdin.read()[:1500] if hasattr(sys.stdin,'read') else '')
" 2>/dev/null || echo "$INVOKE_RESULT" | head -c 1500)

        # Post response back to room
        SAFE_RESP=$(echo "$RESPONSE" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 1500)
        RESP_ENTRY="{\"ts\":$(date +%s)000,\"agent\":\"$TO\",\"to\":\"$FROM\",\"room\":\"$ROOM\",\"type\":\"dispatch-response\",\"action\":\"report\",\"msg\":\"$SAFE_RESP\"}"
        echo "$RESP_ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"

        echo "[$TS_ISO] $TO replied to $FROM" >> "$LOG_FILE"

        # Bug 3 fix: Verify room was actually written to after dispatch
        ROOM_FILE="$ROOMS_DIR/${ROOM}.jsonl"
        if [ -f "$ROOM_FILE" ]; then
          LAST_TS=$(tail -1 "$ROOM_FILE" 2>/dev/null | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('ts',0))" 2>/dev/null || echo "0")
          if [ "$LAST_TS" -lt "${TS_EPOCH}000" ] 2>/dev/null; then
            echo "[$TS_ISO] WARNING: Room $ROOM was NOT written to after dispatch to $TO" >> "$LOG_FILE"
            FAIL_ENTRY="{\"ts\":$(date +%s)000,\"agent\":\"dispatch\",\"room\":\"feedback\",\"type\":\"error\",\"severity\":\"high\",\"error_class\":\"silent_completion\",\"msg\":\"Dispatch to $TO in $ROOM produced no room write. Response: $(echo "$SAFE_RESP" | cut -c1-200)\"}"
            echo "$FAIL_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"
          fi
        fi
      fi
      ;;
    main|zenni)
      # Don't auto-invoke main — just leave the message in the room
      echo "[$TS_ISO] Message queued for Zenni (main) in $ROOM" >> "$LOG_FILE"
      ;;
    taoz)
      # Invoke Claude Code runner in background for Taoz tasks
      CC_RUNNER="$OPENCLAW_DIR/skills/claude-code/scripts/claude-code-runner.sh"
      if [ -f "$CC_RUNNER" ]; then
        bash "$CC_RUNNER" dispatch "$MESSAGE" "$FROM" "$ROOM" >> "$LOG_FILE" 2>&1 &
        INVOKE_RESULT="dispatched to claude-code-runner (pid=$!)"
        echo "[$TS_ISO] Taoz: $INVOKE_RESULT" >> "$LOG_FILE"
      else
        echo "[$TS_ISO] Taoz: claude-code-runner.sh not found — message queued in $ROOM" >> "$LOG_FILE"
      fi
      ;;
    *)
      echo "[$TS_ISO] Unknown agent '$TO' — message queued in $ROOM" >> "$LOG_FILE"
      ;;
  esac
fi

# If action is escalate, also post to feedback room
if [ "$ACTION" = "escalate" ] && [ "$ROOM" != "feedback" ]; then
  ESC_ENTRY="{\"ts\":${TS_EPOCH}000,\"agent\":\"$FROM\",\"to\":\"$TO\",\"room\":\"feedback\",\"type\":\"escalation\",\"action\":\"escalate\",\"msg\":\"ESCALATION from $FROM to $TO: $SAFE_MSG\"}"
  echo "$ESC_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"
fi

# Output result
echo "{\"status\":\"sent\",\"from\":\"$FROM\",\"to\":\"$TO\",\"action\":\"$ACTION\",\"room\":\"$ROOM\",\"ts\":\"$TS_ISO\"}"
