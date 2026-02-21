#!/usr/bin/env bash
# healer.sh — Auto-heal unresolved errors via Claude Code Opus 4.6
# Runs after watchdog (every 5 min via cron).
# Detects errors the watchdog can't fix and escalates to Claude Code.
#
# Usage: bash healer.sh [--verbose]

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
LOG_FILE="$OPENCLAW_DIR/logs/healer.log"
STATE_FILE="$OPENCLAW_DIR/logs/healer-state.json"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
CLAUDE_RUNNER="$OPENCLAW_DIR/skills/claude-code/scripts/claude-code-runner.sh"
VERBOSE="${1:-}"
MAX_BUDGET="2.00"
MAX_ATTEMPTS_PER_HOUR=3

TS_LOCAL=$(date +"%Y-%m-%d %H:%M:%S %Z")
TS_EPOCH=$(date +%s)

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$ROOMS_DIR"

log() {
  echo "[$TS_LOCAL] $1" >> "$LOG_FILE"
  [ "$VERBOSE" = "--verbose" ] && echo "$1"
}

post_to_room() {
  local room="$1" agent="$2" msg="$3" type="${4:-healer}"
  local entry="{\"ts\":${TS_EPOCH}000,\"agent\":\"$agent\",\"room\":\"$room\",\"type\":\"$type\",\"msg\":\"$msg\"}"
  echo "$entry" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RATE LIMIT CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_rate_limit() {
  if [ ! -f "$STATE_FILE" ]; then
    echo '{"attempts":[],"fixes":[]}' > "$STATE_FILE"
  fi

  RECENT_ATTEMPTS=$(python3 - "$STATE_FILE" "$TS_EPOCH" "$MAX_ATTEMPTS_PER_HOUR" << 'PYEOF'
import json, sys
state_file = sys.argv[1]
now = int(sys.argv[2])
max_attempts = int(sys.argv[3])
hour_ago = now - 3600

try:
    with open(state_file) as f:
        state = json.load(f)
except:
    state = {"attempts": [], "fixes": []}

# Count attempts in last hour
recent = [a for a in state.get("attempts", []) if a > hour_ago]
print(len(recent))
PYEOF
  )

  if [ "$RECENT_ATTEMPTS" -ge "$MAX_ATTEMPTS_PER_HOUR" ] 2>/dev/null; then
    log "RATE LIMIT: $RECENT_ATTEMPTS attempts in last hour (max $MAX_ATTEMPTS_PER_HOUR). Skipping."
    return 1
  fi
  return 0
}

record_attempt() {
  python3 - "$STATE_FILE" "$TS_EPOCH" << 'PYEOF'
import json, sys
state_file = sys.argv[1]
now = int(sys.argv[2])

try:
    with open(state_file) as f:
        state = json.load(f)
except:
    state = {"attempts": [], "fixes": []}

state.setdefault("attempts", []).append(now)
# Keep only last 24h
state["attempts"] = [a for a in state["attempts"] if a > now - 86400]

with open(state_file, "w") as f:
    json.dump(state, f, indent=2)
PYEOF
}

record_fix() {
  local error_type="$1" fix_desc="$2"
  python3 - "$STATE_FILE" "$TS_EPOCH" "$error_type" "$fix_desc" << 'PYEOF'
import json, sys
state_file = sys.argv[1]
now = int(sys.argv[2])
error_type = sys.argv[3]
fix_desc = sys.argv[4]

try:
    with open(state_file) as f:
        state = json.load(f)
except:
    state = {"attempts": [], "fixes": []}

state.setdefault("fixes", []).append({
    "ts": now,
    "type": error_type,
    "fix": fix_desc
})
# Keep only last 50 fixes
state["fixes"] = state["fixes"][-50:]

with open(state_file, "w") as f:
    json.dump(state, f, indent=2)
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. SCAN LOGS FOR UNRESOLVED ERRORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OPENCLAW_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"

if [ ! -f "$OPENCLAW_LOG" ]; then
  log "OK: No log file found, nothing to heal"
  exit 0
fi

# Get last 200 lines of logs
RECENT_LOGS=$(tail -200 "$OPENCLAW_LOG" 2>/dev/null || true)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. DETECT STUCK SESSION LOCKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LOCK_ERRORS=$(echo "$RECENT_LOGS" | grep -c "session file locked" 2>/dev/null || echo "0")

if [ "$LOCK_ERRORS" -gt 2 ] 2>/dev/null; then
  log "HEAL: $LOCK_ERRORS session lock errors detected"

  # Find and remove stale lock files
  STALE_LOCKS=$(find "$OPENCLAW_DIR/agents" -name "*.lock" -mmin +5 2>/dev/null | head -10)
  if [ -n "$STALE_LOCKS" ]; then
    echo "$STALE_LOCKS" | while read -r lockfile; do
      rm -f "$lockfile"
      log "  Removed stale lock: $lockfile"
    done
    post_to_room "feedback" "healer" "Removed stale session locks ($LOCK_ERRORS errors)" "recovery"
    record_fix "lock-stuck" "Removed stale lock files"
  else
    # Locks are held by active process — restart gateway via LaunchAgent
    log "  No stale locks found — restarting gateway to clear in-memory locks"
    launchctl bootout gui/501/ai.openclaw.gateway 2>/dev/null || true
    sleep 3
    kill $(pgrep -f "openclaw-gateway") 2>/dev/null || true
    sleep 2
    launchctl bootstrap gui/501 ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null || \
      nohup openclaw gateway --force >> "$OPENCLAW_DIR/logs/gateway-restart.log" 2>&1 &
    sleep 5
    if pgrep -f "openclaw-gateway" >/dev/null 2>&1; then
      log "  Gateway restarted to clear locks"
      post_to_room "feedback" "healer" "Restarted gateway to clear session locks" "recovery"
      record_fix "lock-stuck" "Gateway restart to clear in-memory locks"
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. DETECT CRON FAILURES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CRON_ERRORS=$(echo "$RECENT_LOGS" | grep -c "cron.*failed\|cron.*error\|cron.*TypeError" 2>/dev/null || echo "0")

if [ "$CRON_ERRORS" -gt 0 ] 2>/dev/null; then
  # Extract the specific cron error
  CRON_ERROR_MSG=$(echo "$RECENT_LOGS" | grep "cron.*failed\|cron.*error\|cron.*TypeError" | tail -1)
  log "DETECTED: Cron error — $CRON_ERROR_MSG"

  # Check if it's the known trim bug (don't waste Claude Code budget on known bugs)
  if echo "$CRON_ERROR_MSG" | grep -q "reading 'trim'\|gateway/cron" 2>/dev/null; then
    log "SKIP: Known cron CLI bug (trim/gateway). Cron jobs run via jobs.json directly."
  else
    # Unknown cron error — escalate to Claude Code
    if check_rate_limit; then
      log "ESCALATE: Unknown cron error to Claude Code Opus 4.6"
      record_attempt

      if [ -x "$CLAUDE_RUNNER" ]; then
        HEAL_RESULT=$(bash "$CLAUDE_RUNNER" review \
          "OpenClaw cron error. Error: $CRON_ERROR_MSG. DIAGNOSE ONLY — explain root cause and suggest fix. DO NOT modify openclaw.json. DO NOT run 'openclaw doctor'." \
          "$OPENCLAW_DIR" \
          "$MAX_BUDGET" 2>&1 | tail -50)

        log "Claude Code diagnosis: $HEAL_RESULT"
        post_to_room "feedback" "healer" "Claude Code diagnosed cron error. Result: ${HEAL_RESULT:0:200}" "recovery"
        record_fix "cron-broken" "Claude Code diagnosis (read-only)"
      else
        log "WARN: claude-code-runner.sh not found or not executable"
      fi
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. DETECT CODE/RUNTIME ERRORS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CODE_ERRORS=$(echo "$RECENT_LOGS" | grep "TypeError\|ReferenceError\|SyntaxError\|Cannot read properties\|undefined is not" 2>/dev/null | grep -cv "reading 'trim'\|gateway/cron\|cron.*trim" || true)
CODE_ERRORS=${CODE_ERRORS:-0}
REAL_CODE_ERRORS=${CODE_ERRORS%%[!0-9]*}
REAL_CODE_ERRORS=${REAL_CODE_ERRORS:-0}

if [ "$REAL_CODE_ERRORS" -gt 2 ] 2>/dev/null; then
  ERROR_SAMPLE=$(echo "$RECENT_LOGS" | grep "TypeError\|ReferenceError\|SyntaxError\|Cannot read properties\|undefined is not" | grep -v "reading 'trim'\|gateway/cron" | tail -3)
  log "DETECTED: $REAL_CODE_ERRORS code/runtime errors"

  if check_rate_limit; then
    log "ESCALATE: Code errors to Claude Code Opus 4.6"
    record_attempt

    if [ -x "$CLAUDE_RUNNER" ]; then
      HEAL_RESULT=$(bash "$CLAUDE_RUNNER" review \
        "OpenClaw runtime errors detected in logs. Errors: $ERROR_SAMPLE. DIAGNOSE ONLY — explain root cause and suggest fix. DO NOT modify openclaw.json. DO NOT run 'openclaw doctor'. Gateway log: /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log" \
        "$OPENCLAW_DIR" \
        "$MAX_BUDGET" 2>&1 | tail -50)

      log "Claude Code diagnosis: $HEAL_RESULT"
      post_to_room "feedback" "healer" "Claude Code diagnosed $REAL_CODE_ERRORS runtime errors. Result: ${HEAL_RESULT:0:200}" "recovery"
      record_fix "code-bug" "Claude Code diagnosis (read-only)"
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. DETECT PERSISTENT MODEL FAILURES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALL_MODELS_FAILED=$(echo "$RECENT_LOGS" | grep -c "All models failed" 2>/dev/null || echo "0")

if [ "$ALL_MODELS_FAILED" -gt 3 ] 2>/dev/null; then
  FAILURE_SAMPLE=$(echo "$RECENT_LOGS" | grep "All models failed" | tail -1)
  log "DETECTED: $ALL_MODELS_FAILED 'All models failed' errors"

  if check_rate_limit; then
    log "ESCALATE: Persistent model failures to Claude Code Opus 4.6"
    record_attempt

    if [ -x "$CLAUDE_RUNNER" ]; then
      HEAL_RESULT=$(bash "$CLAUDE_RUNNER" review \
        "All AI models are failing for OpenClaw gateway. Error: $FAILURE_SAMPLE. DIAGNOSE ONLY — explain root cause and suggest fix. DO NOT modify openclaw.json. DO NOT run 'openclaw doctor'." \
        "$OPENCLAW_DIR" \
        "$MAX_BUDGET" 2>&1 | tail -50)

      log "Claude Code diagnosis: $HEAL_RESULT"
      post_to_room "feedback" "healer" "Claude Code diagnosed model failures. Result: ${HEAL_RESULT:0:200}" "recovery"
      record_fix "model-failure" "Claude Code diagnosis (read-only)"
    fi
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. DETECT EMPTY RESPONSES (Zenni reads but doesn't reply)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EMPTY_RUNS=$(echo "$RECENT_LOGS" | grep -c "sessionKey=unknown" 2>/dev/null || echo "0")

if [ "$EMPTY_RUNS" -gt 3 ] 2>/dev/null; then
  log "INFO: $EMPTY_RUNS sessionKey=unknown entries (normal noise from CLI invocations — no action needed)"
  # NOTE: sessionKey=unknown is normal for CLI-invoked agent runs.
  # DO NOT restart gateway for this — it causes a death loop.
  # The healer previously killed the gateway repeatedly for this benign log entry.
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. TRIM HEALER LOG
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -f "$LOG_FILE" ]; then
  LINE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
  if [ "$LINE_COUNT" -gt 3000 ]; then
    tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    log "Trimmed healer log from $LINE_COUNT to 1000 lines"
  fi
fi

log "--- healer cycle complete ---"
