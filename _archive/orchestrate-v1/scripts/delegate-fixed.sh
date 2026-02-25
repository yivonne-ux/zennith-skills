#!/usr/bin/env bash
# delegate-fixed.sh — Fixed delegation script that avoids CLI hanging issues
# Uses direct node execution instead of openclaw CLI

set -uo pipefail

AGENT_ID="${1:?Usage: delegate-fixed.sh <agent_id> <task_brief> <room> <proof_type>}"
TASK_BRIEF="${2:?Error: task_brief is required}"
ROOM="${3:?Error: room is required (townhall|exec|build|social|feedback)}"
PROOF_TYPE="${4:?Error: proof_type is required}"
TIMEOUT="${5:-120}"

OPENCLAW_DIR="$HOME/.openclaw"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
TS_EPOCH=$(date +%s)
TS_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "--- delegate-fixed ---"
echo "Agent: $AGENT_ID"
echo "Room:  $ROOM"
echo "Proof: $PROOF_TYPE"
echo "Timeout: ${TIMEOUT}s"
echo "---"

# Post to room that delegation is starting
START_ENTRY="{\"ts\":${TS_EPOCH}000,\"agent\":\"zenni\",\"to\":\"$AGENT_ID\",\"room\":\"$ROOM\",\"type\":\"dispatch\",\"action\":\"request\",\"msg\":\"DELEGATING: $TASK_BRIEF\"}"
echo "$START_ENTRY" >> "$ROOMS_DIR/${ROOM}.jsonl"

# Use the OpenClaw gateway API directly via WebSocket
# This avoids the hanging CLI issue
node -e "
const WebSocket = require('ws');
const fs = require('fs');

const token = '2a11e48d086d44a061b19b61fbcebabcbe30fd0c9f862a5f';
const agentId = '$AGENT_ID';
const prompt = \`$TASK_BRIEF\`;
const timeout = $TIMEOUT * 1000;

const ws = new WebSocket('ws://127.0.0.1:18789', {
  headers: { 'x-openclaw-token': token }
});

let completed = false;
const startTime = Date.now();

ws.on('open', () => {
  ws.send(JSON.stringify({
    type: 'agent.run',
    agentId: agentId,
    message: prompt,
    json: true
  }));
});

ws.on('message', (data) => {
  try {
    const msg = JSON.parse(data);
    if (msg.type === 'agent.run' && msg.status === 'ok') {
      completed = true;
      const result = msg.result?.payloads?.[0]?.text || 'No response';
      fs.appendFileSync('$ROOMS_DIR/${ROOM}.jsonl', 
        JSON.stringify({
          ts: Date.now(),
          agent: agentId,
          room: '$ROOM',
          type: 'delegation-result',
          msg: result.substring(0, 1500),
          proof_type: '$PROOF_TYPE'
        }) + '\n'
      );
      fs.appendFileSync('$ROOMS_DIR/feedback.jsonl',
        JSON.stringify({
          ts: Date.now(),
          agent: 'mission-control',
          room: 'feedback',
          type: 'delegation-complete',
          msg: 'Delegated task completed by ' + agentId
        }) + '\n'
      );
      console.log('SUCCESS: Agent completed task');
      console.log(result.substring(0, 500));
      ws.close();
      process.exit(0);
    }
    if (msg.type === 'error') {
      console.error('ERROR:', msg.error);
      ws.close();
      process.exit(1);
    }
  } catch (e) {
    console.error('Parse error:', e.message);
  }
});

ws.on('error', (err) => {
  console.error('WebSocket error:', err.message);
  process.exit(1);
});

// Timeout handler
setTimeout(() => {
  if (!completed) {
    console.error('TIMEOUT: Agent did not complete in time');
    ws.close();
    process.exit(124);
  }
}, timeout);
" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "--- delegation complete ---"
else
  echo "--- delegation failed (code: $EXIT_CODE) ---"
  # Post failure to feedback
  FAIL_ENTRY="{\"ts\":$(date +%s)000,\"agent\":\"mission-control\",\"room\":\"feedback\",\"type\":\"delegation-failure\",\"msg\":\"Delegate to $AGENT_ID failed with code $EXIT_CODE\"}"
  echo "$FAIL_ENTRY" >> "$ROOMS_DIR/feedback.jsonl"
fi

exit $EXIT_CODE
