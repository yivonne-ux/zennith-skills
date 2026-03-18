#!/usr/bin/env bash
# dispatch-watchdog.sh — Monitors dispatch health for GAIA CORP-OS
# Checks: zombie dispatches, agent reliability scores, dispatch rate
# Run: every 5 minutes via cron, or manually for status report
#
# Usage:
#   bash dispatch-watchdog.sh              # Run check + log to health room
#   bash dispatch-watchdog.sh --report     # Print full report to stdout
#   bash dispatch-watchdog.sh --cleanup    # Kill zombie dispatches (>5min old)

set -euo pipefail

MODE="${1:-check}"

LOG_DIR="$HOME/.openclaw/logs"
DISPATCH_LOG="$LOG_DIR/dispatch-log.jsonl"
HEALTH_ROOM="$HOME/.openclaw/workspace/rooms/health.jsonl"
WATCHDOG_LOG="$LOG_DIR/watchdog.jsonl"
mkdir -p "$LOG_DIR"

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TS_LOCAL=$(date +"%Y-%m-%d %H:%M %Z")

# ── Check if dispatch log exists ──────────────────────────────────────────────
if [[ ! -f "$DISPATCH_LOG" ]]; then
  echo "No dispatch log found at $DISPATCH_LOG"
  exit 0
fi

# ── Parse dispatch stats ─────────────────────────────────────────────────────
# Count dispatches in last 24h, last 1h, and totals
STATS=$(python3 -c "
import json, sys
from datetime import datetime, timezone, timedelta

log_path = '$DISPATCH_LOG'
now = datetime.now(timezone.utc)
h1_ago = now - timedelta(hours=1)
h24_ago = now - timedelta(hours=24)

dispatches = []
completions = []
agents = {}
zombies = []

with open(log_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except:
            continue

        ts_str = entry.get('ts', '')
        try:
            ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
        except:
            continue

        status = entry.get('status', '')
        agent = entry.get('agent', 'unknown')
        pid = entry.get('pid')
        label = entry.get('label', '')

        if status in ('dispatching', 'dispatched'):
            dispatches.append({'ts': ts, 'agent': agent, 'pid': pid, 'label': label, 'status': status})
            if agent not in agents:
                agents[agent] = {'dispatched': 0, 'completed': 0, 'failed': 0}
            if status == 'dispatched':
                agents[agent]['dispatched'] += 1
        elif status == 'success':
            completions.append({'ts': ts, 'agent': agent, 'label': label})
            if agent not in agents:
                agents[agent] = {'dispatched': 0, 'completed': 0, 'failed': 0}
            agents[agent]['completed'] += 1
        elif status == 'failed':
            if agent not in agents:
                agents[agent] = {'dispatched': 0, 'completed': 0, 'failed': 0}
            agents[agent]['failed'] += 1

# Find zombie dispatches (dispatched but no completion, PID exists, >5min old)
import subprocess
dispatched_labels = {d['label'] for d in dispatches if d['status'] == 'dispatched'}
completed_labels = {c['label'] for c in completions}
pending_labels = dispatched_labels - completed_labels

for d in dispatches:
    if d['status'] == 'dispatched' and d['label'] in pending_labels and d['pid']:
        age_min = (now - d['ts']).total_seconds() / 60
        if age_min > 5:
            # Check if PID still running
            try:
                result = subprocess.run(['kill', '-0', str(d['pid'])], capture_output=True)
                alive = result.returncode == 0
            except:
                alive = False
            zombies.append({
                'label': d['label'],
                'agent': d['agent'],
                'pid': d['pid'],
                'age_min': round(age_min, 1),
                'alive': alive
            })

# Last 1h and 24h counts
d_1h = sum(1 for d in dispatches if d['ts'] > h1_ago and d['status'] == 'dispatched')
d_24h = sum(1 for d in dispatches if d['ts'] > h24_ago and d['status'] == 'dispatched')

# Output as JSON
result = {
    'total_dispatches': len([d for d in dispatches if d['status'] == 'dispatched']),
    'total_completions': len(completions),
    'dispatches_1h': d_1h,
    'dispatches_24h': d_24h,
    'agents': agents,
    'zombies': zombies,
    'pending_count': len(pending_labels)
}
print(json.dumps(result))
" 2>/dev/null || echo '{"error":"parse_failed"}')

if echo "$STATS" | grep -q '"error"'; then
  echo "Failed to parse dispatch log"
  exit 1
fi

# ── Extract values ────────────────────────────────────────────────────────────
TOTAL_DISPATCHES=$(echo "$STATS" | python3 -c "import json,sys; print(json.load(sys.stdin)['total_dispatches'])")
TOTAL_COMPLETIONS=$(echo "$STATS" | python3 -c "import json,sys; print(json.load(sys.stdin)['total_completions'])")
DISPATCHES_1H=$(echo "$STATS" | python3 -c "import json,sys; print(json.load(sys.stdin)['dispatches_1h'])")
DISPATCHES_24H=$(echo "$STATS" | python3 -c "import json,sys; print(json.load(sys.stdin)['dispatches_24h'])")
PENDING=$(echo "$STATS" | python3 -c "import json,sys; print(json.load(sys.stdin)['pending_count'])")
ZOMBIE_COUNT=$(echo "$STATS" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['zombies']))")

# ── Health score ──────────────────────────────────────────────────────────────
# Green: 0 zombies, dispatches flowing
# Yellow: 1-2 zombies or no dispatches in 1h
# Red: 3+ zombies or dispatch log errors
if [[ "$ZOMBIE_COUNT" -ge 3 ]]; then
  HEALTH="RED"
elif [[ "$ZOMBIE_COUNT" -ge 1 ]]; then
  HEALTH="YELLOW"
else
  HEALTH="GREEN"
fi

# ── MODE: --report ────────────────────────────────────────────────────────────
if [[ "$MODE" = "--report" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 DISPATCH HEALTH REPORT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Time:       $TS_LOCAL"
  echo "Health:     $HEALTH"
  echo ""
  echo "Dispatches: $TOTAL_DISPATCHES total | $DISPATCHES_24H (24h) | $DISPATCHES_1H (1h)"
  echo "Completed:  $TOTAL_COMPLETIONS"
  echo "Pending:    $PENDING"
  echo "Zombies:    $ZOMBIE_COUNT"
  echo ""

  # Per-agent stats
  echo "Agent Reliability:"
  echo "$STATS" | python3 -c "
import json, sys
data = json.load(sys.stdin)
agents = data.get('agents', {})
for agent, stats in sorted(agents.items()):
    d = stats['dispatched']
    c = stats['completed']
    f = stats['failed']
    rate = round(c / d * 100, 1) if d > 0 else 0
    status = '✅' if rate >= 80 else '⚠️' if rate >= 50 else '❌'
    print(f'  {status} {agent:12s} dispatched={d:3d}  completed={c:3d}  failed={f:3d}  rate={rate}%')
"

  # Zombies
  if [[ "$ZOMBIE_COUNT" -gt 0 ]]; then
    echo ""
    echo "Zombie Dispatches (>5min, no completion):"
    echo "$STATS" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for z in data.get('zombies', []):
    alive = '🔴 running' if z['alive'] else '💀 dead'
    print(f\"  {z['label']:30s} agent={z['agent']:12s} pid={z['pid']}  age={z['age_min']}min  {alive}\")
"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# ── MODE: --cleanup ───────────────────────────────────────────────────────────
if [[ "$MODE" = "--cleanup" ]]; then
  echo "Cleaning up zombie dispatches..."
  echo "$STATS" | python3 -c "
import json, sys, subprocess
data = json.load(sys.stdin)
killed = 0
for z in data.get('zombies', []):
    if z['alive'] and z['pid']:
        try:
            subprocess.run(['kill', str(z['pid'])], check=True)
            killed += 1
            print(f\"  Killed {z['label']} (pid={z['pid']}, agent={z['agent']}, age={z['age_min']}min)\")
        except:
            print(f\"  Failed to kill {z['label']} (pid={z['pid']})\")
    elif not z['alive']:
        print(f\"  Already dead: {z['label']} (pid={z['pid']})\")
print(f'\nKilled {killed} zombie(s)')
"
  exit 0
fi

# ── MODE: check (default — log to health room + watchdog log) ────────────────
# Log watchdog result
WATCHDOG_ENTRY="{\"ts\":\"$TS\",\"health\":\"$HEALTH\",\"dispatches_1h\":$DISPATCHES_1H,\"dispatches_24h\":$DISPATCHES_24H,\"pending\":$PENDING,\"zombies\":$ZOMBIE_COUNT}"
echo "$WATCHDOG_ENTRY" >> "$WATCHDOG_LOG"

# Only post to health room if there's an issue
if [[ "$HEALTH" != "GREEN" ]]; then
  HEALTH_MSG="{\"ts\":\"$TS\",\"source\":\"dispatch-watchdog\",\"health\":\"$HEALTH\",\"zombies\":$ZOMBIE_COUNT,\"pending\":$PENDING,\"msg\":\"Dispatch health: $HEALTH — $ZOMBIE_COUNT zombie(s), $PENDING pending\"}"
  echo "$HEALTH_MSG" >> "$HEALTH_ROOM"
  echo "[$HEALTH] $ZOMBIE_COUNT zombie(s), $PENDING pending — logged to health room"
else
  echo "[GREEN] $DISPATCHES_1H dispatches (1h), $PENDING pending, 0 zombies"
fi
