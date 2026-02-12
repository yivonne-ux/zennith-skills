#!/usr/bin/env bash
# watchdog.sh — Auto-failover watchdog for GAIA CORP-OS
# Runs every 5 minutes via cron. Checks model health, resets bloated sessions, restarts gateway.
#
# Usage: bash watchdog.sh [--verbose]

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
SESSIONS_FILE="$OPENCLAW_DIR/agents/main/sessions/sessions.json"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/watchdog.log"
VERBOSE="${1:-}"

# Context window limit (tokens) — leave 20% headroom
CONTEXT_LIMIT=262144
WARN_THRESHOLD=$(( CONTEXT_LIMIT * 80 / 100 ))   # 209715
RESET_THRESHOLD=$(( CONTEXT_LIMIT * 90 / 100 ))   # 235929

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TS_LOCAL=$(date +"%Y-%m-%d %H:%M:%S %Z")

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$ROOMS_DIR"

log() {
  echo "[$TS_LOCAL] $1" >> "$LOG_FILE"
  [ "$VERBOSE" = "--verbose" ] && echo "$1"
}

post_to_room() {
  local room="$1" agent="$2" msg="$3" type="${4:-watchdog}"
  local entry="{\"ts\":$(date +%s)000,\"agent\":\"$agent\",\"room\":\"$room\",\"type\":\"$type\",\"msg\":\"$msg\"}"
  echo "$entry" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. CHECK GATEWAY ALIVE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GATEWAY_PID=$(pgrep -f "openclaw-gateway" 2>/dev/null || true)

if [ -z "$GATEWAY_PID" ]; then
  log "ALERT: Gateway process not found. Attempting restart..."
  post_to_room "feedback" "watchdog" "Gateway dead — auto-restarting" "incident"

  # Restart gateway via LaunchAgent (persists across cron cycles)
  launchctl bootout gui/501/ai.openclaw.gateway 2>/dev/null || true
  sleep 2
  launchctl bootstrap gui/501 ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null || \
    nohup openclaw gateway --force >> "$OPENCLAW_DIR/logs/gateway-restart.log" 2>&1 &
  sleep 5

  NEW_PID=$(pgrep -f "openclaw-gateway" 2>/dev/null || true)
  if [ -n "$NEW_PID" ]; then
    log "OK: Gateway restarted (PID: $NEW_PID)"
    post_to_room "feedback" "watchdog" "Gateway restarted successfully (PID: $NEW_PID)" "recovery"
  else
    log "CRITICAL: Gateway restart FAILED"
    post_to_room "feedback" "watchdog" "CRITICAL: Gateway restart failed — manual intervention needed" "incident"
  fi
else
  log "OK: Gateway alive (PID: $GATEWAY_PID)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. CHECK SESSION TOKEN COUNTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -f "$SESSIONS_FILE" ]; then
  # FIRST: Extract recap from bloated sessions BEFORE resetting them
  RECALL_SCRIPT="$HOME/.openclaw/skills/session-recall/scripts/recall.sh"
  if [ -x "$RECALL_SCRIPT" ]; then
    bash "$RECALL_SCRIPT" all "watchdog-auto-reset" >> "$LOG_FILE" 2>&1 || true
  fi

  RESET_COUNT=$(python3 << 'PYEOF'
import json, os, sys, shutil
from datetime import datetime

sessions_file = os.path.expanduser("~/.openclaw/agents/main/sessions/sessions.json")
warn_threshold = int(sys.argv[1]) if len(sys.argv) > 1 else 209715
reset_threshold = int(sys.argv[2]) if len(sys.argv) > 2 else 235929

try:
    with open(sessions_file) as f:
        data = json.load(f)
except:
    print("0")
    sys.exit(0)

reset_count = 0
modified = False

for key, session in data.items():
    tokens = session.get("totalTokens", 0)
    if tokens == 0:
        continue

    if tokens > reset_threshold:
        # Auto-reset: backup session ID and clear ALL state
        old_sid = session.get("sessionId", "none")
        session["totalTokens"] = 0
        session["inputTokens"] = 0
        session["outputTokens"] = 0
        session["sessionId"] = None
        session["sessionFile"] = None
        session["systemSent"] = False
        session["compactionCount"] = 0
        session.pop("systemPromptReport", None)
        session.pop("skillsSnapshot", None)
        modified = True
        reset_count += 1
        print(f"RESET: {key[:50]} (was {tokens} tokens, sid={old_sid})", file=sys.stderr)
    elif tokens > warn_threshold:
        pct = int(tokens * 100 / 262144)
        print(f"WARN: {key[:50]} at {pct}% ({tokens} tokens)", file=sys.stderr)

if modified:
    # Backup before writing
    backup = sessions_file + f".bak.{datetime.now().strftime('%Y%m%d%H%M%S')}"
    shutil.copy2(sessions_file, backup)
    with open(sessions_file, "w") as f:
        json.dump(data, f, indent=2)

print(reset_count)
PYEOF
  )

  if [ "$RESET_COUNT" -gt 0 ] 2>/dev/null; then
    log "ACTION: Reset $RESET_COUNT bloated session(s)"
    post_to_room "feedback" "watchdog" "Auto-reset $RESET_COUNT bloated session(s) approaching token limit" "recovery"
  else
    log "OK: All sessions within token limits"
  fi
else
  log "WARN: Sessions file not found: $SESSIONS_FILE"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. CHECK RECENT LOGS FOR MODEL ERRORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECENT_ERRORS=0
if command -v openclaw &>/dev/null; then
  # Check last 100 log lines for model errors
  ERROR_CHECK=$(openclaw logs --max-bytes 50000 2>&1 | tail -100 | grep -c "token limit\|rate_limit\|HTTP 429\|HTTP 500\|HTTP 502\|HTTP 503\|model.*error\|exceeded model" 2>/dev/null || echo "0")
  RECENT_ERRORS=$ERROR_CHECK
fi

if [ "$RECENT_ERRORS" -gt 3 ] 2>/dev/null; then
  log "ALERT: $RECENT_ERRORS model errors in recent logs — checking if failover needed"

  # Check if primary model is specifically failing
  PRIMARY_ERRORS=$(openclaw logs --max-bytes 50000 2>&1 | tail -100 | grep -c "kimi\|moonshot" 2>/dev/null || echo "0")

  if [ "$PRIMARY_ERRORS" -gt 2 ] 2>/dev/null; then
    log "FAILOVER: Primary model (Kimi K2.5) has $PRIMARY_ERRORS errors. Checking fallback..."

    # Test fallback model
    FALLBACK_OK=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST "https://openrouter.ai/api/v1/chat/completions" \
      -H "Authorization: Bearer $(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['models']['providers']['openrouter']['apiKey'])")" \
      -H "Content-Type: application/json" \
      -d '{"model":"qwen/qwen3-coder-next","messages":[{"role":"user","content":"ping"}],"max_tokens":5}' \
      2>/dev/null || echo "000")

    if [ "$FALLBACK_OK" = "200" ]; then
      log "OK: Fallback model (Qwen3 Coder) is healthy"
      post_to_room "feedback" "watchdog" "Primary model errors detected ($PRIMARY_ERRORS). Fallback (Qwen3) is healthy — OpenClaw will auto-route." "warning"
    else
      log "CRITICAL: Fallback model also failing (HTTP $FALLBACK_OK)"
      post_to_room "feedback" "watchdog" "CRITICAL: Both primary (Kimi) and fallback (Qwen3) models failing. HTTP=$FALLBACK_OK" "incident"
    fi
  fi
else
  log "OK: No significant model errors in recent logs"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. CHECK DASHBOARD ALIVE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DASHBOARD_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:19800/api/health" 2>/dev/null || echo "000")

if [ "$DASHBOARD_HTTP" != "200" ]; then
  log "WARN: Dashboard not responding (HTTP $DASHBOARD_HTTP). Attempting restart..."

  # Kill existing dashboard and restart
  pkill -f "boss-dashboard/server.js" 2>/dev/null || true
  sleep 1
  cd "$OPENCLAW_DIR/workspace/apps/boss-dashboard" && nohup node server.js >> /tmp/boss-dashboard.log 2>&1 &
  sleep 3

  DASH_RECHECK=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:19800/api/health" 2>/dev/null || echo "000")
  if [ "$DASH_RECHECK" = "200" ]; then
    log "OK: Dashboard restarted"
  else
    log "WARN: Dashboard restart may have failed (HTTP $DASH_RECHECK)"
  fi
else
  log "OK: Dashboard alive"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. TRIM OLD WATCHDOG LOGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -f "$LOG_FILE" ]; then
  LINE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
  if [ "$LINE_COUNT" -gt 5000 ]; then
    tail -2000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    log "Trimmed watchdog log from $LINE_COUNT to 2000 lines"
  fi
fi

log "--- watchdog cycle complete ---"
