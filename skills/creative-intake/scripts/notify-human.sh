#!/usr/bin/env bash
# notify-human.sh — Formats approval request and posts to WhatsApp relay room
# Bash 3.2 compatible (macOS). Uses python3 for JSON. No jq.
#
# Usage: echo '{"id":"appr-xxx","type":"...","summary":"...","agent":"..."}' | bash notify-human.sh
# Posts formatted message to the room that Zenni watches for WhatsApp relay.

set -uo pipefail

ROOM="$HOME/.openclaw/workspace/rooms/creative.jsonl"
LOG_FILE="$HOME/.openclaw/workspace/logs/intake.log"

log() {
  printf '[%s] [notify-human] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE" 2>/dev/null
}

# Read JSON from stdin
INPUT_JSON=""
if [ -t 0 ]; then
  log "ERROR: No JSON on stdin"
  echo "ERROR: Pipe approval JSON to this script." >&2
  exit 1
fi
INPUT_JSON="$(cat)"

if [ -z "$INPUT_JSON" ]; then
  log "ERROR: Empty input"
  echo "ERROR: Empty input" >&2
  exit 1
fi

# Format the notification and post to room
python3 -c "
import json, sys, time

try:
    data = json.loads(sys.stdin.read())
except Exception as e:
    print('ERROR: Invalid JSON: ' + str(e), file=sys.stderr)
    sys.exit(1)

appr_id = data.get('id', 'unknown')
appr_type = data.get('type', 'unknown')
agent = data.get('agent', 'unknown')
summary = data.get('summary', 'No summary provided')
payload = data.get('payload', {})
tier = data.get('tier', 3)

# Format type for display (replace hyphens with spaces, title case)
type_display = appr_type.replace('-', ' ').title()

# Capitalize agent name
agent_display = agent.capitalize()

# Extract details from payload if available
details_parts = []
if isinstance(payload, dict):
    desc = payload.get('description', '')
    if desc:
        details_parts.append(desc)
    funnel = payload.get('funnel_stage', '')
    if funnel:
        details_parts.append('Funnel: ' + funnel)
    ratios = payload.get('aspect_ratios', [])
    if ratios:
        details_parts.append('Ratios: ' + ', '.join(str(r) for r in ratios))
    tools = payload.get('generation_tools', [])
    if tools:
        details_parts.append('Tools: ' + ', '.join(str(t) for t in tools))

details_text = '. '.join(details_parts) if details_parts else 'See payload for details.'

# Build the human-readable message
human_msg = '''APPROVAL NEEDED [{appr_id}]

Type: {type_display}
Agent: {agent_display}
Summary: {summary}

Details: {details}

Reply: \"approve {appr_id}\" or \"reject {appr_id} <reason>\"'''.format(
    appr_id=appr_id,
    type_display=type_display,
    agent_display=agent_display,
    summary=summary,
    details=details_text
)

# Build room message
room_msg = {
    'ts': int(time.time() * 1000),
    'agent': 'approval-queue',
    'room': 'creative',
    'type': 'approval-notification',
    'msg': '[APPROVAL NEEDED] ' + summary + ' (ID: ' + appr_id + ')',
    'approval_id': appr_id,
    'human_message': human_msg
}

room_line = json.dumps(room_msg, ensure_ascii=False)

# Append to room file
try:
    with open('$ROOM', 'a') as f:
        f.write(room_line + '\n')
    print('OK: Notification posted for ' + appr_id)
except Exception as e:
    print('ERROR: Failed to write to room: ' + str(e), file=sys.stderr)
    sys.exit(1)
" <<< "$INPUT_JSON" 2>>"$LOG_FILE"

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  log "Notification posted for approval request"
else
  log "ERROR: Failed to post notification"
fi

exit $EXIT_CODE
