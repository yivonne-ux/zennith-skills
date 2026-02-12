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
  # Check if target is a real agent (not hephaestus which uses claude-code-runner)
  case "$TO" in
    artemis|apollo|hermes|athena|iris)
      PROMPT="[DISPATCH from $FROM — action: $ACTION]

$MESSAGE

Instructions:
- Complete this task and post your result
- Reference this dispatch in your response
- If you cannot complete, explain what's missing and suggest who can help"

      if command -v openclaw &>/dev/null; then
        INVOKE_RESULT=$(timeout 300 openclaw agent --agent "$TO" --message "$PROMPT" --json 2>&1) || true

        # Extract response text
        RESPONSE=$(echo "$INVOKE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['payloads'][0]['text'][:1500])" 2>/dev/null || echo "$INVOKE_RESULT" | head -c 1500)

        # Post response back to room
        SAFE_RESP=$(echo "$RESPONSE" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 1500)
        RESP_ENTRY="{\"ts\":$(date +%s)000,\"agent\":\"$TO\",\"to\":\"$FROM\",\"room\":\"$ROOM\",\"type\":\"dispatch-response\",\"action\":\"report\",\"msg\":\"$SAFE_RESP\"}"
        echo "$RESP_ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"

        echo "[$TS_ISO] $TO replied to $FROM" >> "$LOG_FILE"
      fi
      ;;
    main|zenni)
      # Don't auto-invoke main — just leave the message in the room
      echo "[$TS_ISO] Message queued for Zenni (main) in $ROOM" >> "$LOG_FILE"
      ;;
    hephaestus)
      echo "[$TS_ISO] Hephaestus tasks use claude-code-runner.sh — message queued in $ROOM" >> "$LOG_FILE"
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
