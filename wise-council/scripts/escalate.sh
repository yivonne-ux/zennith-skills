#!/usr/bin/env bash
# escalate.sh — Smart Escalation to GLM-5 "Wise Council"
#
# When Zenni (fast GLM-4.7-flash) faces a hard problem she can't solve:
# 1. Escalate to GLM-5 for deep analysis
# 2. GLM-5 produces a strategy + action plan
# 3. Actions get dispatched to specialist agents or Claude Code (sub-agents)
#
# Usage: bash escalate.sh "problem description" [room]
# Called by: error-recovery.sh (Tier 2), Zenni via dispatch, or manual

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

PROBLEM="$1"
ROOM="${2:-exec}"
ROOMS_DIR="${HOME}/.openclaw/workspace/rooms"
LOG_FILE="${HOME}/.openclaw/logs/wise-council.log"
DISPATCH="${HOME}/.openclaw/skills/mission-control/scripts/dispatch.sh"

# OpenRouter API for direct GLM-5 call (bypass OpenClaw agent system)
OR_KEY="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"
OR_URL="https://openrouter.ai/api/v1/chat/completions"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Wise Council Invoked ==="
log "Problem: ${PROBLEM:0:200}"

# Gather context from rooms
room_context() {
  local ctx=""
  for r in exec build feedback; do
    if [ -f "${ROOMS_DIR}/${r}.jsonl" ]; then
      local recent
      recent=$(tail -3 "${ROOMS_DIR}/${r}.jsonl" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        print(f\"[{d.get('agent','?')}@{d.get('room','?')}] {d.get('msg','')[:100]}\")
    except: pass
" 2>/dev/null || true)
      if [ -n "$recent" ]; then
        ctx="${ctx}\n--- ${r} room ---\n${recent}"
      fi
    fi
  done
  echo "$ctx"
}

CONTEXT=$(room_context)

# Call GLM-5 directly via OpenRouter API
RESPONSE=$(curl -s -X POST "$OR_URL" \
  -H "Authorization: Bearer $OR_KEY" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c "
import json
prompt = '''You are the Wise Council (GLM-5) for GAIA CORP-OS, a multi-agent AI system for GAIA Eats (Malaysian vegan food brand).

You are called when the fast orchestrator (Zenni) faces a problem she cannot solve alone. Your job:
1. Analyze the problem deeply
2. Identify root cause
3. Produce a concrete action plan
4. Specify which agent(s) should execute each action
5. If the task needs code/infrastructure work, specify it should go to Taoz (Claude Code)

Available agents:
- Artemis: Research, competitive intel, web scraping
- Dreami: Creative content, copywriting, brand voice
- Athena: Analytics, data insights, reporting
- Hermes: Pricing, margins, channel strategy
- Iris: Social media, community engagement
- Taoz: Code, infrastructure (uses Claude Code CLI)

Recent system context:
$CONTEXT

PROBLEM TO SOLVE:
$PROBLEM

Respond with a JSON object:
{
  \"diagnosis\": \"what is the root cause\",
  \"strategy\": \"high-level approach\",
  \"actions\": [
    {\"agent\": \"agent_name\", \"task\": \"specific task description\", \"room\": \"target_room\", \"priority\": \"P0|P1|P2\"}
  ],
  \"needs_subagent\": true/false,
  \"subagent_spec\": \"if needs_subagent, describe what kind of sub-agent to spawn\"
}'''

msg = {
    'model': 'z-ai/glm-5',
    'messages': [{'role': 'user', 'content': prompt}],
    'max_tokens': 2000,
    'temperature': 0.3
}
print(json.dumps(msg))
" 2>/dev/null)" 2>&1) || {
  log "ERROR: GLM-5 API call failed"
  exit 1
}

# Extract response content
COUNCIL_OUTPUT=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    content = d['choices'][0]['message']['content']
    print(content)
except Exception as e:
    print(f'ERROR: {e}')
" 2>/dev/null)

log "Council response: ${COUNCIL_OUTPUT:0:300}"

# Post council response to room
ESCAPED=$(echo "$COUNCIL_OUTPUT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null)
printf '{"ts":%s000,"agent":"wise-council","room":"%s","type":"council-response","msg":%s}\n' \
  "$(date +%s)" "$ROOM" "$ESCAPED" >> "${ROOMS_DIR}/${ROOM}.jsonl"

# Parse and dispatch actions
echo "$COUNCIL_OUTPUT" | python3 -c "
import json, sys, subprocess, os

content = sys.stdin.read().strip()
# Try to find JSON in the response
start = content.find('{')
end = content.rfind('}') + 1
if start >= 0 and end > start:
    try:
        plan = json.loads(content[start:end])
        actions = plan.get('actions', [])
        dispatch = os.path.expanduser('~/.openclaw/skills/mission-control/scripts/dispatch.sh')

        for action in actions:
            agent = action.get('agent', '')
            task = action.get('task', '')
            room = action.get('room', 'build')
            if agent and task:
                print(f'Dispatching to {agent}: {task[:80]}')
                subprocess.Popen(
                    ['bash', dispatch, 'wise-council', agent, 'request', task, room],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )

        # If needs sub-agent (Claude Code)
        if plan.get('needs_subagent'):
            spec = plan.get('subagent_spec', 'General task')
            print(f'Sub-agent needed: {spec}')
            subprocess.Popen(
                ['bash', dispatch, 'wise-council', 'taoz', 'request',
                 f'[SUB-AGENT TASK from Wise Council] {spec}', 'build'],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
    except json.JSONDecodeError as e:
        print(f'Could not parse plan JSON: {e}')
else:
    print('No JSON found in council response')
" 2>/dev/null

log "=== Wise Council Complete ==="
