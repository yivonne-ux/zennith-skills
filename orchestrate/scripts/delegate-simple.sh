#!/usr/bin/env bash
# delegate-simple.sh — Simple file-based delegation that actually works
# Writes tasks to queue files that agents can poll

set -uo pipefail

AGENT_ID="${1:?Usage: delegate-simple.sh <agent_id> <task_brief> <room> <proof_type>}"
TASK_BRIEF="${2:?Error: task_brief is required}"
ROOM="${3:?Error: room is required}"
PROOF_TYPE="${4:?Error: proof_type is required}"
TIMEOUT="${5:-300}"

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_DIR/workspace"
ROOMS_DIR="$WORKSPACE/rooms"
QUEUE_DIR="$WORKSPACE/queues"
TS_EPOCH=$(date +%s)
TS_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$QUEUE_DIR" "$ROOMS_DIR"

# Generate task ID
TASK_ID="T$(date +%s%N | cut -c1-13)"

echo "--- delegate-simple ---"
echo "Task ID: $TASK_ID"
echo "Agent:   $AGENT_ID"
echo "Room:    $ROOM"
echo "Proof:   $PROOF_TYPE"
echo "---"

# Write task to agent's queue
QUEUE_FILE="$QUEUE_DIR/${AGENT_ID}.jsonl"
TASK_JSON=$(cat <<EOF
{"ts":${TS_EPOCH}000,"task_id":"$TASK_ID","agent":"$AGENT_ID","room":"$ROOM","proof_type":"$PROOF_TYPE","brief":"$(echo "$TASK_BRIEF" | sed 's/"/\\"/g' | tr '\n' ' ')","status":"pending","deadline_ms":$((TS_EPOCH * 1000 + TIMEOUT * 1000))}
EOF
)
echo "$TASK_JSON" >> "$QUEUE_FILE"

# Post delegation start to room
START_ENTRY="{\"ts\":${TS_EPOCH}000,\"agent\":\"zenni\",\"to\":\"$AGENT_ID\",\"room\":\"$ROOM\",\"type\":\"delegation-start\",\"msg\":\"[$TASK_ID] Task queued for $AGENT_ID\"}"
echo "$START_ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"

echo "Task queued: $TASK_ID"
echo "Queue file: $QUEUE_FILE"
echo ""
echo "Waiting for completion (timeout: ${TIMEOUT}s)..."

# Poll for completion
POLL_INTERVAL=5
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
  
  # Check if task has been marked complete
  if [ -f "$QUEUE_FILE" ]; then
    RESULT=$(tail -50 "$QUEUE_FILE" | grep "$TASK_ID" | grep '"status":"complete"' | tail -1)
    if [ -n "$RESULT" ]; then
      echo "Task completed!"
      echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('Result:', d.get('result','')[:500])" 2>/dev/null || echo "$RESULT"
      
      # Post completion to room
      COMPLETE_ENTRY="{\"ts\":$(date +%s)000,\"agent\":\"$AGENT_ID\",\"room\":\"$ROOM\",\"type\":\"delegation-complete\",\"msg\":\"[$TASK_ID] Task completed\",\"result\":\"$(echo "$RESULT" | sed 's/"/\\"/g' | head -c 500)\"}"
      echo "$COMPLETE_ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"
      
      echo "--- delegation complete ---"
      exit 0
    fi
    
    # Check for failure
    FAIL_RESULT=$(tail -50 "$QUEUE_FILE" | grep "$TASK_ID" | grep '"status":"failed"' | tail -1)
    if [ -n "$FAIL_RESULT" ]; then
      echo "Task failed!"
      echo "$FAIL_RESULT"
      exit 1
    fi
  fi
  
  echo "  ... waiting ($ELAPSED/${TIMEOUT}s)"
done

echo "TIMEOUT: Task did not complete in ${TIMEOUT}s"

# Post timeout to feedback
TIMEOUT_ENTRY="{\"ts\":$(date +%s)000,\"agent\":\"mission-control\",\"room\":\"feedback\",\"type\":\"delegation-timeout\",\"msg\":\"[$TASK_ID] Task to $AGENT_ID timed out after ${TIMEOUT}s\"}"
echo "$TIMEOUT_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"

exit 124
