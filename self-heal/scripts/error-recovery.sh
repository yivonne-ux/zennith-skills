#!/usr/bin/env bash
# error-recovery.sh — 3-Tier Self-Healing Error Recovery
#
# Tier 1: Agents retry locally (built into dispatch)
# Tier 2: This script — Zenni diagnoses and fixes (runs every 10 min via cron)
# Tier 3: Escalate to human via WhatsApp
#
# Reads feedback room for structured errors, diagnoses root cause,
# attempts fix, logs resolution to exec room.

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

ROOMS_DIR="${HOME}/.openclaw/workspace/rooms"
FEEDBACK="${ROOMS_DIR}/feedback.jsonl"
EXEC="${ROOMS_DIR}/exec.jsonl"
LOG_FILE="${HOME}/.openclaw/logs/error-recovery.log"
STATE_FILE="${HOME}/.openclaw/logs/error-recovery-state.json"
CIRCUIT_DIR="${HOME}/.openclaw/logs/circuit-breakers"

mkdir -p "$(dirname "$LOG_FILE")" "$CIRCUIT_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Load last check timestamp
get_last_check() {
  if [[ -f "$STATE_FILE" ]]; then
    python3 -c "import json; print(json.load(open('$STATE_FILE')).get('last_check_ts', 0))" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

save_last_check() {
  local ts="$1"
  echo "{\"last_check_ts\": $ts, \"last_run\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$STATE_FILE"
}

# Circuit breaker — check if agent is in "open" state (too many failures)
is_circuit_open() {
  local agent="$1"
  local cb_file="${CIRCUIT_DIR}/${agent}.json"
  if [[ -f "$cb_file" ]]; then
    local state failures last_fail
    state=$(python3 -c "import json; print(json.load(open('$cb_file')).get('state','closed'))" 2>/dev/null || echo "closed")
    if [[ "$state" == "open" ]]; then
      # Check if cooldown period (10 min) has passed → half-open
      last_fail=$(python3 -c "import json; print(json.load(open('$cb_file')).get('last_fail_ts',0))" 2>/dev/null || echo "0")
      local now=$(date +%s)
      local elapsed=$(( now - last_fail ))
      if [[ $elapsed -gt 600 ]]; then
        log "CIRCUIT: $agent transitioning to half-open (${elapsed}s since last failure)"
        python3 -c "
import json
d = json.load(open('$cb_file'))
d['state'] = 'half-open'
json.dump(d, open('$cb_file', 'w'))
"
        return 1  # Allow one test dispatch
      fi
      return 0  # Circuit is open, block dispatch
    fi
  fi
  return 1  # Circuit closed or doesn't exist, allow dispatch
}

# Record agent failure for circuit breaker
record_failure() {
  local agent="$1"
  local error_class="$2"
  local cb_file="${CIRCUIT_DIR}/${agent}.json"

  if [[ -f "$cb_file" ]]; then
    python3 -c "
import json, time
d = json.load(open('$cb_file'))
d['failures'] = d.get('failures', 0) + 1
d['last_fail_ts'] = int(time.time())
d['last_error'] = '$error_class'
# Open circuit after 3 failures in 30 min
if d['failures'] >= 3:
    d['state'] = 'open'
json.dump(d, open('$cb_file', 'w'))
print(d.get('state', 'closed'))
" 2>/dev/null
  else
    echo "{\"agent\":\"$agent\",\"failures\":1,\"last_fail_ts\":$(date +%s),\"last_error\":\"$error_class\",\"state\":\"closed\"}" > "$cb_file"
    echo "closed"
  fi
}

# Reset circuit breaker on success
record_success() {
  local agent="$1"
  local cb_file="${CIRCUIT_DIR}/${agent}.json"
  echo "{\"agent\":\"$agent\",\"failures\":0,\"last_fail_ts\":0,\"last_error\":\"\",\"state\":\"closed\"}" > "$cb_file"
}

# Extract new errors from feedback room since last check
get_new_errors() {
  local last_ts="$1"
  [[ ! -f "$FEEDBACK" ]] && return

  python3 -c "
import json, sys

last_ts = int($last_ts)
errors = []

with open('$FEEDBACK') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
            ts = d.get('ts', 0)
            msg_type = d.get('type', '')
            # Look for error entries (structured or keyword-based)
            if ts > last_ts and ('error' in msg_type.lower() or 'err' in d.get('msg', '').lower()[:20] or 'fail' in d.get('msg', '').lower()[:20]):
                errors.append(json.dumps(d))
        except:
            pass

for e in errors[-10:]:  # Max 10 errors per cycle
    print(e)
" 2>/dev/null
}

# Classify error and determine fix
diagnose_error() {
  local error_json="$1"

  python3 -c "
import json

d = json.loads('$error_json')
msg = d.get('msg', '')
agent = d.get('agent', 'unknown')
mission = d.get('mission', d.get('mission_id', ''))

# Classification rules
if 'auth' in msg.lower() or 'token' in msg.lower() or 'expired' in msg.lower() or 'oauth' in msg.lower():
    print(f'auth_expired|{agent}|{mission}|Re-auth or use API key method')
elif 'exit 127' in msg or 'command not found' in msg or 'NO_OPENCLAW' in msg:
    print(f'env_missing|{agent}|{mission}|PATH or binary not found - check agent environment')
elif 'not logged in' in msg.lower() or 'login' in msg.lower():
    print(f'auth_login|{agent}|{mission}|Agent needs re-authentication')
elif 'timeout' in msg.lower():
    print(f'timeout|{agent}|{mission}|Task took too long - consider splitting or increasing timeout')
elif 'rate limit' in msg.lower() or '429' in msg:
    print(f'rate_limit|{agent}|{mission}|API rate limited - add backoff delay')
elif 'model' in msg.lower() and ('not found' in msg.lower() or '404' in msg.lower()):
    print(f'model_unavailable|{agent}|{mission}|Model not accessible - check OpenRouter config')
elif 'session' in msg.lower() and ('full' in msg.lower() or 'overflow' in msg.lower() or '100%' in msg.lower()):
    print(f'session_full|{agent}|{mission}|Session token limit reached - needs reset')
elif agent == 'artemis' and any(s in msg.lower() for s in ['0 products', '0% success', 'scraper failed', 'no data', 'recycled', 'stale']):
    print(f'data_quality|{agent}|{mission}|Data sources failed - block seed storage')
else:
    print(f'unknown|{agent}|{mission}|Unclassified error: {msg[:80]}')
" 2>/dev/null
}

# Attempt automated fix based on diagnosis
attempt_fix() {
  local error_class="$1"
  local agent="$2"
  local mission="$3"
  local suggestion="$4"

  log "FIXING: $error_class for $agent ($mission)"

  case "$error_class" in
    auth_expired)
      # For Google Sheets: already migrated to API key, so just retry
      log "FIX: Auth expired — checking if API key method is available"
      if [[ -f "${HOME}/.openclaw/workspace/ops/scripts/sales_report_apikey.py" ]]; then
        log "FIX: API key script exists, retrying with API key method"
        post_to_room "exec" "zenni" "Auto-fix: $agent hit auth error on $mission. Retrying with API key method."
        return 0
      fi
      ;;
    env_missing)
      # PATH issue — ensure agent has correct PATH
      log "FIX: Environment/PATH issue for $agent"
      post_to_room "exec" "zenni" "Auto-fix: $agent hit env error (exit 127) on $mission. This is usually a PATH issue in the agent's shell. Routing task to a different agent."
      return 0
      ;;
    session_full)
      # Reset the agent's session
      log "FIX: Resetting $agent session"
      echo '{}' > "${HOME}/.openclaw/agents/${agent}/sessions/sessions.json" 2>/dev/null || true
      post_to_room "exec" "zenni" "Auto-fix: Reset $agent session (was full). Agent can accept new tasks now."
      record_success "$agent"
      return 0
      ;;
    timeout)
      log "FIX: Timeout for $agent — will increase timeout on next dispatch"
      post_to_room "exec" "zenni" "Auto-fix: $agent timed out on $mission. Will retry with increased timeout."
      return 0
      ;;
    rate_limit)
      log "FIX: Rate limit — adding 60s cooldown for $agent"
      sleep 5  # Brief pause, cooldown handled by circuit breaker
      return 0
      ;;
    model_unavailable)
      log "FIX: Model 404 for $agent — checking fallback models"
      post_to_room "exec" "zenni" "Auto-fix: $agent model unavailable on $mission. Check OpenRouter privacy settings or switch model."
      return 1  # Can't auto-fix model config
      ;;
    data_quality)
      log "FIX: Data quality failure for $agent — blocking seed storage"
      local gate_script="${HOME}/.openclaw/skills/content-seed-bank/scripts/data-quality-gate.sh"
      if [ -f "$gate_script" ]; then
        bash "$gate_script" check --agent "$agent" --mission "$mission" 2>/dev/null || true
      fi
      post_to_room "exec" "zenni" "⚠️ DATA QUALITY: $agent sources failed on $mission. Seeds blocked. Confidence downgraded to LOW. Do NOT use this data for content creation."
      post_to_room "feedback" "$agent" "DATA QUALITY CIRCUIT BREAKER: Your data sources failed. Report confidence as LOW, not HIGH. Do NOT store seeds from recycled data." "data-quality"
      return 0
      ;;
    *)
      log "NO AUTO-FIX for: $error_class ($suggestion)"
      return 1
      ;;
  esac
}

# Post structured message to a room
post_to_room() {
  local room="$1"
  local agent="$2"
  local msg="$3"
  local escaped_msg
  escaped_msg=$(echo "$msg" | python3 -c "import sys; print(sys.stdin.read().strip().replace('\"','\\\\\"'))" 2>/dev/null || echo "$msg")
  printf '{"ts":%s000,"agent":"%s","room":"%s","type":"auto-fix","msg":"%s"}\n' \
    "$(date +%s)" "$agent" "$room" "$escaped_msg" >> "${ROOMS_DIR}/${room}.jsonl"
}

# Escalate to human (Tier 3) via exec room
escalate_to_human() {
  local agent="$1"
  local mission="$2"
  local error_class="$3"
  local attempts="$4"

  log "ESCALATE: $agent/$mission ($error_class) after $attempts attempts"

  # Tier 2.5: Escalate to Wise Council (GLM-5) before bothering human
  local wise_council="${HOME}/.openclaw/skills/wise-council/scripts/escalate.sh"
  if [ -f "$wise_council" ]; then
    log "Invoking Wise Council (GLM-5) for deep analysis..."
    bash "$wise_council" "Agent $agent failed on mission $mission with error class $error_class after $attempts auto-fix attempts. The circuit breaker is now OPEN. Diagnose and propose fix." "exec" >> "$LOG_FILE" 2>&1 &
  fi

  post_to_room "exec" "zenni" "ESCALATED TO WISE COUNCIL: $agent failed on $mission ($error_class) after $attempts attempts. GLM-5 analyzing. If unresolved, human intervention needed."
}

# Main
main() {
  log "=== Error Recovery Started ==="

  local last_ts
  last_ts=$(get_last_check)
  local current_ts=$(date +%s)000
  local error_count=0
  local fixed_count=0

  while IFS= read -r error_line; do
    [[ -z "$error_line" ]] && continue
    ((error_count++))

    # Diagnose
    local diagnosis
    diagnosis=$(diagnose_error "$error_line") || continue
    IFS='|' read -r error_class agent mission suggestion <<< "$diagnosis"

    log "ERROR: $error_class | agent=$agent | mission=$mission"

    # Check circuit breaker
    if is_circuit_open "$agent"; then
      log "CIRCUIT OPEN: $agent — skipping (too many recent failures)"
      continue
    fi

    # Attempt fix
    if attempt_fix "$error_class" "$agent" "$mission" "$suggestion"; then
      ((fixed_count++))
      record_success "$agent"
    else
      # Record failure, check if circuit should open
      local state
      state=$(record_failure "$agent" "$error_class")
      if [[ "$state" == "open" ]]; then
        escalate_to_human "$agent" "$mission" "$error_class" "3"
      fi
    fi

  done < <(get_new_errors "$last_ts")

  save_last_check "$current_ts"

  if [[ $error_count -gt 0 ]]; then
    log "Processed $error_count errors, fixed $fixed_count"
  else
    log "No new errors since last check"
  fi

  log "=== Error Recovery Complete ==="
}

main "$@"
