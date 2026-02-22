#!/usr/bin/env bash
# watchdog.sh — Auto-failover watchdog for GAIA CORP-OS
# Runs every 5 minutes via cron. Checks model health, resets bloated sessions, restarts gateway.
#
# Usage: bash watchdog.sh [--verbose]

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
AGENTS_DIR="$OPENCLAW_DIR/agents"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/watchdog.log"
VERBOSE="${1:-}"

# Default context limit — overridden per-agent below
DEFAULT_CONTEXT_LIMIT=200000

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

GATEWAY_PID=$(pgrep -x "openclaw-gateway" 2>/dev/null || ps aux | grep -v grep | grep "openclaw-gateway" | awk '{print $2}' | head -1 || true)

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
# 2. CHECK SESSION TOKEN COUNTS (ALL AGENTS)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get context limit per agent (capped for safety — no agent gets full 1M)
get_context_limit() {
  local agent_name="$1"
  case "$agent_name" in
    main)                      echo 200000 ;;   # claude-sonnet-4.6
    taoz)                      echo 262144 ;;   # qwen3-coder-next
    myrmidons)                 echo 196608 ;;   # minimax-m2.5
    artemis|dreami|artee)      echo 262144 ;;   # kimi-k2.5
    apollo)                    echo 131000 ;;   # qwen3-235b-a22b
    athena|hermes)             echo 202000 ;;   # glm-5
    iris)                      echo 262144 ;;   # qwen3-vl-235b (capped safe)
    *)                         echo 200000 ;;   # Default safe limit
  esac
}

RECALL_SCRIPT="$HOME/.openclaw/skills/session-recall/scripts/recall.sh"
TOTAL_RESETS=0
AGENTS_CHECKED=0

for AGENT_DIR in "$AGENTS_DIR"/*/; do
  # Skip if not a real directory (could be symlink — follow it, but skip broken ones)
  [ -d "$AGENT_DIR" ] || continue

  AGENT_NAME=$(basename "$AGENT_DIR")

  # Skip symlinks to avoid double-processing (art-director -> artee, creative-director -> dreami)
  if [ -L "$AGENTS_DIR/$AGENT_NAME" ]; then
    log "SKIP: $AGENT_NAME (symlink to $(readlink "$AGENTS_DIR/$AGENT_NAME"))"
    continue
  fi

  SESSION_FILE="$AGENT_DIR/sessions/sessions.json"
  if [ ! -f "$SESSION_FILE" ]; then
    continue
  fi

  AGENTS_CHECKED=$(( AGENTS_CHECKED + 1 ))
  AGENT_LIMIT=$(get_context_limit "$AGENT_NAME")
  AGENT_WARN=$(( AGENT_LIMIT * 75 / 100 ))
  AGENT_RESET=$(( AGENT_LIMIT * 85 / 100 ))

  # Run session-recall BEFORE resetting (only if recall script exists)
  if [ -x "$RECALL_SCRIPT" ]; then
    bash "$RECALL_SCRIPT" all "watchdog-auto-reset-$AGENT_NAME" >> "$LOG_FILE" 2>&1 || true
  fi

  RESET_COUNT=$(WATCHDOG_AGENT="$AGENT_NAME" WATCHDOG_AGENT_DIR="$AGENT_DIR" WATCHDOG_WARN="$AGENT_WARN" WATCHDOG_RESET="$AGENT_RESET" WATCHDOG_LIMIT="$AGENT_LIMIT" python3 << 'PYEOF'
import json, os, sys, shutil
from datetime import datetime

agent_name = os.environ.get("WATCHDOG_AGENT", "unknown")
agent_dir = os.environ.get("WATCHDOG_AGENT_DIR", "")
sessions_file = os.path.join(agent_dir, "sessions", "sessions.json")
context_limit = int(os.environ.get("WATCHDOG_LIMIT", "200000"))
warn_threshold = int(os.environ.get("WATCHDOG_WARN", "150000"))
reset_threshold = int(os.environ.get("WATCHDOG_RESET", "170000"))

try:
    with open(sessions_file) as f:
        data = json.load(f)
except Exception:
    print("0")
    sys.exit(0)

reset_count = 0
modified = False

# Handle both dict and list formats (zenni uses [] instead of {})
if isinstance(data, list):
    # Zenni and some agents use list format — treat as empty dict
    data = {}

if not data:
    print("0")
    sys.exit(0)

for key, session in data.items():
    tokens = session.get("totalTokens", 0) or session.get("contextTokens", 0) or 0
    if tokens == 0:
        continue

    if tokens > reset_threshold:
        old_sid = session.get("sessionId", "none")
        session["totalTokens"] = 0
        session["inputTokens"] = 0
        session["outputTokens"] = 0
        session["contextTokens"] = 0
        session["sessionId"] = None
        session["sessionFile"] = None
        session["systemSent"] = False
        session["compactionCount"] = 0
        session.pop("systemPromptReport", None)
        session.pop("skillsSnapshot", None)
        modified = True
        reset_count += 1
        print("[RESET] Agent: {}, Session: {}, was {} tokens".format(
            agent_name, key[:60], tokens), file=sys.stderr)
    elif tokens > warn_threshold:
        pct = int(tokens * 100 / context_limit)
        print("[WARN] Agent: {}, Session: {} at {}% ({} tokens)".format(
            agent_name, key[:60], pct, tokens), file=sys.stderr)

if modified:
    backup = sessions_file + ".bak.{}".format(datetime.now().strftime('%Y%m%d%H%M%S'))
    shutil.copy2(sessions_file, backup)
    with open(sessions_file, "w") as f:
        json.dump(data, f, indent=2)

print(reset_count)
PYEOF
  )

  if [ "$RESET_COUNT" -gt 0 ] 2>/dev/null; then
    TOTAL_RESETS=$(( TOTAL_RESETS + RESET_COUNT ))
    log "ACTION: Reset $RESET_COUNT session(s) for agent $AGENT_NAME"
  fi
done

if [ "$TOTAL_RESETS" -gt 0 ]; then
  log "ACTION: Total resets across all agents: $TOTAL_RESETS"
  post_to_room "feedback" "watchdog" "Auto-reset $TOTAL_RESETS bloated session(s) across agents (checked $AGENTS_CHECKED agents)" "recovery"
else
  log "OK: All $AGENTS_CHECKED agents within token limits"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. CHECK RECENT LOGS FOR MODEL ERRORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECENT_ERRORS=0
if command -v openclaw &>/dev/null; then
  # Check last 100 log lines for model errors
  ERROR_CHECK=$(openclaw logs --max-bytes 50000 2>&1 | tail -100 | grep -c "token limit\|rate_limit\|HTTP 429\|HTTP 500\|HTTP 502\|HTTP 503\|model.*error\|exceeded model" 2>/dev/null || echo "0")
  RECENT_ERRORS=$(echo "$ERROR_CHECK" | tail -1 | tr -d '[:space:]')
fi

if [ "$RECENT_ERRORS" -gt 3 ] 2>/dev/null; then
  log "ALERT: $RECENT_ERRORS model errors in recent logs — checking if failover needed"

  # Check if primary model is specifically failing
  PRIMARY_ERRORS=$(openclaw logs --max-bytes 50000 2>&1 | tail -100 | grep -c "glm-4.7-flash\|glm-5\|glm-4.7" 2>/dev/null || echo "0")
  PRIMARY_ERRORS=$(echo "$PRIMARY_ERRORS" | tail -1 | tr -d '[:space:]')

  if [ "$PRIMARY_ERRORS" -gt 2 ] 2>/dev/null; then
    log "FAILOVER: GLM models have $PRIMARY_ERRORS errors. Checking fallback..."

    # Test fallback model
    FALLBACK_OK=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST "https://openrouter.ai/api/v1/chat/completions" \
      -H "Authorization: Bearer $(python3 -c "import json; c=json.load(open('$CONFIG_FILE')); print(c['models']['providers']['openrouter']['apiKey'])")" \
      -H "Content-Type: application/json" \
      -d '{"model":"z-ai/glm-4.5-air:free","messages":[{"role":"user","content":"ping"}],"max_tokens":5}' \
      2>/dev/null || echo "000")

    if [ "$FALLBACK_OK" = "200" ]; then
      log "OK: Fallback model (GLM-4.5 Air) is healthy"
      post_to_room "feedback" "watchdog" "GLM model errors detected ($PRIMARY_ERRORS). Fallback (GLM-4.5 Air) is healthy — OpenClaw will auto-route." "warning"
    else
      log "CRITICAL: Fallback model also failing (HTTP $FALLBACK_OK)"
      post_to_room "feedback" "watchdog" "CRITICAL: Both primary (GLM) and fallback (GLM-4.5 Air) models failing. HTTP=$FALLBACK_OK" "incident"
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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. FINAL OUTPUT — SILENT IF ALL CLEAR
# Only print a summary if something needs attention.
# When all clear, print nothing so the cron announce step stays quiet.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ISSUES_FOUND=0
[ -z "$GATEWAY_PID" ] && ISSUES_FOUND=$(( ISSUES_FOUND + 1 ))
[ "$TOTAL_RESETS" -gt 0 ] && ISSUES_FOUND=$(( ISSUES_FOUND + 1 ))
[ "$RECENT_ERRORS" -gt 3 ] && ISSUES_FOUND=$(( ISSUES_FOUND + 1 ))
[ "${DASHBOARD_HTTP:-000}" != "200" ] && ISSUES_FOUND=$(( ISSUES_FOUND + 1 ))

if [ "$ISSUES_FOUND" -gt 0 ]; then
  echo "🚨 Watchdog Alert — $(date '+%I:%M %p, %d %b %Y')"
  [ -z "$GATEWAY_PID" ]         && echo "  ❌ Gateway was down (auto-restart attempted)"
  [ "$TOTAL_RESETS" -gt 0 ]     && echo "  ♻️  $TOTAL_RESETS session(s) auto-reset (token overflow)"
  [ "$RECENT_ERRORS" -gt 3 ]    && echo "  ⚠️  $RECENT_ERRORS model errors detected in logs"
  [ "${DASHBOARD_HTTP:-000}" != "200" ] && echo "  ❌ Dashboard was down (HTTP ${DASHBOARD_HTTP:-000}, restart attempted)"
fi
# If ISSUES_FOUND=0, we print nothing → cron announce delivers nothing → no WhatsApp ping
