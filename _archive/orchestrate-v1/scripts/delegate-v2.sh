#!/usr/bin/env bash
# delegate-v2.sh - Working delegation using sessions_spawn
# Posts results to rooms via JSONL
# Bash 3.2 compatible (macOS)

set -uo pipefail

AGENT_ID="${1:?Usage: delegate-v2.sh <agent_id> <task_brief> <room> <proof_type>}"
TASK_BRIEF="${2:?Error: task_brief is required}"
ROOM="${3:?Error: room required}"
PROOF_TYPE="${4:-structured_data}"
TIMEOUT="${5:-120}"

OPENCLAW_DIR="$HOME/.openclaw"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
AGENT_WORKSPACE="$OPENCLAW_DIR/workspace-$AGENT_ID"
TS=$(date +%s)

# Generate task ID and label
TASK_ID="D$(date +%s%N | cut -c1-10)"
LABEL="${AGENT_ID}-$(echo "$TASK_ID" | tr '[:upper:]' '[:lower:]')"

echo "--- delegate-v2 ---"
echo "Task:    $TASK_ID"
echo "Agent:   $AGENT_ID"
echo "Room:    $ROOM"
echo "Proof:   $PROOF_TYPE"
echo "Label:   $LABEL"
echo "---"

# Build full prompt with agent persona
read -r -d '' FULL_PROMPT <<HEREDOC || true
You are $AGENT_ID, a member of the GAIA CORP-OS Pantheon.

Read your SOUL.md at $AGENT_WORKSPACE/SOUL.md to remember your identity, voice, and domain.

YOUR TASK:
$TASK_BRIEF

INSTRUCTIONS:
- Complete the task thoroughly
- Use your domain-appropriate voice and style
- Return structured results
- If you use files/data, cite sources
- If you cannot complete, explain what is missing

After completing, write a summary to: $ROOMS_DIR/$ROOM.jsonl
Format: {"ts":$(date +%s)000,"agent":"$AGENT_ID","room":"$ROOM","type":"delegation-result","msg":"[summary]","proof_type":"$PROOF_TYPE"}
HEREDOC

# Post delegation start - escape quotes by replacing with single quotes
TASK_PREVIEW=$(printf '%s' "$TASK_BRIEF" | head -c 100 | tr '"' "'")
START_ENTRY=$(printf '{"ts":%s000,"agent":"zenni","to":"%s","room":"%s","type":"delegation-start","msg":"[%s] Delegated to %s","task_preview":"%s"}' \
  "$TS" "$AGENT_ID" "$ROOM" "$TASK_ID" "$AGENT_ID" "$TASK_PREVIEW")
printf '%s\n' "$START_ENTRY" >> "$ROOMS_DIR/$ROOM.jsonl"

# Use openclaw sessions spawn
RESULT=$(openclaw sessions spawn --label "$LABEL" --timeout "$TIMEOUT" "$FULL_PROMPT" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "SUCCESS: Delegation completed"
  printf '%s\n' "$RESULT" | head -20

  # Post completion
  COMPLETE_ENTRY=$(printf '{"ts":%s000,"agent":"%s","room":"%s","type":"delegation-complete","msg":"[%s] Task completed","ref":"%s"}' \
    "$(date +%s)" "$AGENT_ID" "$ROOM" "$TASK_ID" "$LABEL")
  printf '%s\n' "$COMPLETE_ENTRY" >> "$ROOMS_DIR/$ROOM.jsonl"

  # Also post to feedback
  FEEDBACK_ENTRY=$(printf '{"ts":%s000,"agent":"mission-control","room":"feedback","type":"delegation-success","msg":"[%s] %s completed task in %s"}' \
    "$(date +%s)" "$TASK_ID" "$AGENT_ID" "$ROOM")
  printf '%s\n' "$FEEDBACK_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"

  exit 0
else
  echo "FAILED: Exit code $EXIT_CODE"
  printf '%s\n' "$RESULT" | head -20

  # Post failure - escape quotes safely
  ESCAPED_RESULT=$(printf '%s' "$RESULT" | head -c 200 | tr '"' "'")
  FAIL_ENTRY=$(printf '{"ts":%s000,"agent":"mission-control","room":"feedback","type":"delegation-failure","msg":"[%s] %s failed with code %s","error":"%s"}' \
    "$(date +%s)" "$TASK_ID" "$AGENT_ID" "$EXIT_CODE" "$ESCAPED_RESULT")
  printf '%s\n' "$FAIL_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"

  exit "$EXIT_CODE"
fi
