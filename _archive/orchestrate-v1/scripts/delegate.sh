#!/usr/bin/env bash
# delegate.sh — Invoke a Pantheon agent via OpenClaw CLI and post results to a room
# Usage: delegate.sh <agent_id> <task_brief> <room> <proof_type> [thinking_level]
#
# Example:
#   delegate.sh artemis "Scout Shopee for vegan snacks in MY" build structured_data medium

set -euo pipefail

AGENT_ID="${1:?Usage: delegate.sh <agent_id> <task_brief> <room> <proof_type> [thinking_level]}"
TASK_BRIEF="${2:?Error: task_brief is required}"
ROOM="${3:?Error: room is required (townhall|exec|build|social|feedback)}"
PROOF_TYPE="${4:?Error: proof_type is required}"
THINKING="${5:-medium}"
TIMEOUT="${6:-300}"

DASHBOARD_URL="http://localhost:19800"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "--- orchestrate.delegate ---"
echo "Agent:    $AGENT_ID"
echo "Room:     $ROOM"
echo "Proof:    $PROOF_TYPE"
echo "Thinking: $THINKING"
echo "Timeout:  ${TIMEOUT}s"
echo "Time:     $TS"
echo "---"

# Build the full prompt with GAIA context
FULL_PROMPT="You are working as part of GAIA CORP-OS Pantheon. Read your SOUL.md to remember who you are.

TASK:
${TASK_BRIEF}

INSTRUCTIONS:
- Complete the task thoroughly
- Post your results in structured format
- Include proof of type: ${PROOF_TYPE}
- Cite data sources for any numbers
- If you cannot complete the task, explain exactly what is missing

PROOF FORMAT (${PROOF_TYPE}):
- structured_data: tables, JSON, or bullet-point findings with sources
- content_draft: complete draft with variants and visual direction
- margin_math: revenue, cost, margin breakdown with projections
- data_table: metrics table with period comparisons and insights
- post_schedule: platform, time, content, status table
- build_log: what changed, test output, file list"

# Invoke the agent
echo "Invoking agent: $AGENT_ID ..."

RESULT=""
EXIT_CODE=0

if command -v openclaw &>/dev/null; then
  # macOS has no `timeout` — use background + wait + kill pattern
  openclaw agent --agent "$AGENT_ID" --message "$FULL_PROMPT" --json > /tmp/delegate-resp-$$.json 2>&1 &
  BGPID=$!
  WAITED=0
  while kill -0 "$BGPID" 2>/dev/null && [ "$WAITED" -lt "$TIMEOUT" ]; do
    sleep 1
    WAITED=$((WAITED + 1))
  done
  if kill -0 "$BGPID" 2>/dev/null; then
    kill "$BGPID" 2>/dev/null || true
    RESULT='{"error":"timeout after '"$TIMEOUT"'s"}'
    EXIT_CODE=124
  else
    wait "$BGPID" 2>/dev/null || EXIT_CODE=$?
    RESULT=$(cat /tmp/delegate-resp-$$.json 2>/dev/null || echo '{"error":"no output"}')
  fi
  rm -f /tmp/delegate-resp-$$.json
else
  echo "ERROR: openclaw CLI not found in PATH"
  EXIT_CODE=127
fi

# Handle errors
if [ "$EXIT_CODE" -ne 0 ]; then
  echo "WARNING: Agent invocation failed (exit code: $EXIT_CODE)"

  if [ "$EXIT_CODE" -eq 124 ]; then
    ERROR_MSG="Agent timed out after ${TIMEOUT}s"
  elif [ "$EXIT_CODE" -eq 127 ]; then
    ERROR_MSG="openclaw CLI not found"
  else
    ERROR_MSG="Agent error (code: $EXIT_CODE)"
  fi

  # Log failure to feedback room
  FAIL_ENTRY=$(cat <<JSONEOF
{"ts":"$TS","agent":"$AGENT_ID","room":"feedback","type":"delegation-failure","msg":"$ERROR_MSG — Task: $(echo "$TASK_BRIEF" | head -c 200)","proof_type":"$PROOF_TYPE"}
JSONEOF
)
  echo "$FAIL_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"

  echo ""
  echo "--- orchestrate.delegate FAILED ---"
  echo "{\"status\":\"error\",\"agent\":\"$AGENT_ID\",\"error\":\"$ERROR_MSG\",\"exit_code\":$EXIT_CODE}"
  exit "$EXIT_CODE"
fi

echo "Agent responded."

# Extract the response text from JSON (if --json flag worked)
RESPONSE_TEXT=""
if echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response',''))" 2>/dev/null; then
  RESPONSE_TEXT=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response',''))" 2>/dev/null)
else
  # Fallback: use raw output
  RESPONSE_TEXT="$RESULT"
fi

# Truncate for room posting (keep first 2000 chars)
ROOM_MSG=$(echo "$RESPONSE_TEXT" | head -c 2000)

# Post to target room via dashboard API
POSTED=false
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$DASHBOARD_URL/api/rooms/$ROOM" \
  -H "Content-Type: application/json" \
  -d "{\"agent\":\"$AGENT_ID\",\"msg\":$(echo "$ROOM_MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),\"type\":\"delegation-result\",\"proof_type\":\"$PROOF_TYPE\"}" \
  2>/dev/null) || true

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  POSTED=true
  echo "Posted to room: $ROOM (HTTP $HTTP_CODE)"
else
  echo "WARNING: Dashboard post failed (HTTP $HTTP_CODE). Falling back to JSONL append."

  # Fallback: append directly to room JSONL
  ROOM_ENTRY=$(cat <<JSONEOF2
{"ts":"$TS","agent":"$AGENT_ID","room":"$ROOM","type":"delegation-result","msg":"$(echo "$ROOM_MSG" | sed 's/"/\\"/g' | tr '\n' ' ' | head -c 1500)","proof_type":"$PROOF_TYPE"}
JSONEOF2
)
  echo "$ROOM_ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"
  POSTED=true
  echo "Appended to $ROOMS_DIR/${ROOM}.jsonl"
fi

# Log to feedback room
FEEDBACK_ENTRY=$(cat <<JSONEOF3
{"ts":"$TS","agent":"$AGENT_ID","room":"feedback","type":"delegation-complete","msg":"Task delegated to $AGENT_ID completed. Room: $ROOM. Proof: $PROOF_TYPE. Posted: $POSTED.","task_summary":"$(echo "$TASK_BRIEF" | head -c 200 | sed 's/"/\\"/g')"}
JSONEOF3
)
echo "$FEEDBACK_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"

echo ""
echo "--- orchestrate.delegate complete ---"

# Output structured result
cat <<RESULT_JSON
{
  "status": "success",
  "agent": "$AGENT_ID",
  "room": "$ROOM",
  "proof_type": "$PROOF_TYPE",
  "room_posted": $POSTED,
  "response_length": ${#RESPONSE_TEXT},
  "ts": "$TS"
}
RESULT_JSON
