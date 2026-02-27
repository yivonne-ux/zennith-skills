#!/usr/bin/env bash
# agent-health.sh -- Per-agent deep health checker for GAIA CORP-OS
#
# Checks a single agent's:
#   - Session file size
#   - Last activity timestamp
#   - Error count in feedback room
#   - Token usage estimate
#   - Model reachability (quick ping via OpenRouter)
#
# Usage: bash agent-health.sh <agent_id>
#        bash agent-health.sh --all
#
# Bash 3.2 compatible (macOS). No declare -A, no timeout, no ${var,,}.

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

OPENCLAW_DIR="$HOME/.openclaw"
AGENTS_DIR="$OPENCLAW_DIR/agents"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"
FEEDBACK_ROOM="$ROOMS_DIR/feedback.jsonl"

AGENT_ID="${1:-}"

if [ -z "$AGENT_ID" ]; then
  echo "Usage: agent-health.sh <agent_id>"
  echo "       agent-health.sh --all"
  echo ""
  echo "Available agents:"
  for d in "$AGENTS_DIR"/*/; do
    [ -d "$d" ] || continue
    local_name=$(basename "$d")
    # Skip symlinks
    if [ -L "$AGENTS_DIR/$local_name" ]; then
      echo "  $local_name (-> $(basename "$(readlink "$AGENTS_DIR/$local_name")"))"
    else
      echo "  $local_name"
    fi
  done
  exit 1
fi

# ============================================================
# Model mapping (agent -> model ID for ping)
# ============================================================

get_agent_model() {
  local agent="$1"
  case "$agent" in
    main|artemis|hermes)       echo "z-ai/glm-4.7-flash" ;;
    dreami)                    echo "moonshotai/kimi-k2.5" ;;
    iris)                      echo "qwen/qwen3-vl-235b-a22b-instruct" ;;
    athena)                    echo "z-ai/glm-5" ;;
    *)                         echo "z-ai/glm-4.7-flash" ;;
  esac
}

get_context_limit() {
  local agent="$1"
  case "$agent" in
    main|artemis|hermes)       echo 202000 ;;
    dreami|iris)               echo 202000 ;;
    athena)                    echo 200000 ;;
    *)                         echo 200000 ;;
  esac
}

# ============================================================
# Check one agent
# ============================================================

check_agent() {
  local agent_name="$1"
  local agent_dir="$AGENTS_DIR/$agent_name"

  # Resolve symlinks
  if [ -L "$agent_dir" ]; then
    local real_target
    real_target=$(readlink "$agent_dir")
    local real_name
    real_name=$(basename "$real_target")
    echo "  Note: $agent_name is a symlink to $real_name"
    agent_dir="$real_target"
    agent_name="$real_name"
  fi

  if [ ! -d "$agent_dir" ]; then
    echo "ERROR: Agent $agent_name not found at $agent_dir"
    return 1
  fi

  local model
  model=$(get_agent_model "$agent_name")
  local context_limit
  context_limit=$(get_context_limit "$agent_name")

  echo "============================================"
  echo "  Agent Health Report: $agent_name"
  echo "  Model: $model"
  echo "  Context Limit: $context_limit tokens"
  echo "============================================"

  # 1. Session file size
  local session_file="$agent_dir/sessions/sessions.json"
  if [ -f "$session_file" ]; then
    local file_size
    file_size=$(wc -c < "$session_file" 2>/dev/null | tr -d ' ')
    local size_kb=$(( file_size / 1024 ))

    local size_status="OK"
    if [ "$file_size" -gt 153600 ]; then
      size_status="BLOATED (>150KB)"
    elif [ "$file_size" -gt 102400 ]; then
      size_status="GROWING (>100KB)"
    fi

    echo "  Session Size:     ${size_kb}KB -- $size_status"
  else
    echo "  Session Size:     N/A (no session file)"
  fi

  # 2. Last activity timestamp
  if [ -f "$session_file" ]; then
    local last_modified
    last_modified=$(stat -f "%m" "$session_file" 2>/dev/null || echo "0")
    local now_ts
    now_ts=$(date +%s)
    local age_minutes=$(( (now_ts - last_modified) / 60 ))

    local activity_status="ACTIVE"
    if [ "$age_minutes" -gt 1440 ]; then
      local age_days=$(( age_minutes / 1440 ))
      activity_status="STALE (${age_days} days ago)"
    elif [ "$age_minutes" -gt 120 ]; then
      local age_hours=$(( age_minutes / 60 ))
      activity_status="IDLE (${age_hours} hours ago)"
    else
      activity_status="ACTIVE (${age_minutes} min ago)"
    fi

    echo "  Last Activity:    $activity_status"
  else
    echo "  Last Activity:    UNKNOWN"
  fi

  # 3. Error count in feedback room
  if [ -f "$FEEDBACK_ROOM" ]; then
    local agent_errors
    agent_errors=$(grep "\"agent\":\"$agent_name\"" "$FEEDBACK_ROOM" 2>/dev/null | wc -l | tr -d ' ')

    local recent_errors
    recent_errors=$(tail -50 "$FEEDBACK_ROOM" | grep "\"agent\":\"$agent_name\"" 2>/dev/null | grep -Ei "error|fail" 2>/dev/null | wc -l | tr -d ' ')

    local error_status="OK"
    if [ "$recent_errors" -gt 5 ]; then
      error_status="HIGH ($recent_errors recent errors)"
    elif [ "$recent_errors" -gt 0 ]; then
      error_status="LOW ($recent_errors recent errors)"
    fi

    echo "  Feedback Errors:  total=$agent_errors, recent=$recent_errors -- $error_status"
  else
    echo "  Feedback Errors:  N/A (no feedback room)"
  fi

  # 4. Token usage estimate
  if [ -f "$session_file" ]; then
    local token_info
    token_info=$(python3 -c "
import json, sys

try:
    with open('$session_file') as f:
        data = json.load(f)

    total_tokens = 0
    session_count = 0
    max_tokens = 0

    for key, session in data.items():
        tokens = session.get('totalTokens', 0) or session.get('contextTokens', 0) or 0
        if tokens > 0:
            total_tokens += tokens
            session_count += 1
            if tokens > max_tokens:
                max_tokens = tokens

    limit = $context_limit
    if max_tokens > 0:
        pct = int(max_tokens * 100 / limit)
    else:
        pct = 0

    status = 'OK'
    if pct > 85:
        status = 'CRITICAL (>85%)'
    elif pct > 75:
        status = 'WARNING (>75%)'

    print(f'sessions={session_count}, max_tokens={max_tokens}, usage={pct}% -- {status}')
except Exception as e:
    print(f'ERROR reading sessions: {e}')
" 2>/dev/null || echo "ERROR: could not parse session file")
    echo "  Token Usage:      $token_info"
  else
    echo "  Token Usage:      N/A"
  fi

  # 5. Model reachability (quick ping)
  echo -n "  Model Reachable:  "

  # Get API key from config
  local api_key
  api_key=$(python3 -c "
import json
try:
    c = json.load(open('$CONFIG_FILE'))
    print(c.get('models', {}).get('providers', {}).get('openrouter', {}).get('apiKey', ''))
except:
    print('')
" 2>/dev/null || echo "")

  if [ -z "$api_key" ]; then
    echo "SKIP (no API key found)"
  else
    # Use background + wait + kill pattern (no timeout on macOS)
    local ping_result_file
    ping_result_file=$(mktemp /tmp/agent-ping.XXXXXX)

    (
      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":1}" \
        2>/dev/null || echo "000")
      echo "$http_code" > "$ping_result_file"
    ) &
    local ping_pid=$!

    # Wait up to 10 seconds
    local waited=0
    while [ "$waited" -lt 10 ]; do
      if ! kill -0 "$ping_pid" 2>/dev/null; then
        break
      fi
      sleep 1
      waited=$(( waited + 1 ))
    done

    # Kill if still running
    if kill -0 "$ping_pid" 2>/dev/null; then
      kill "$ping_pid" 2>/dev/null || true
      wait "$ping_pid" 2>/dev/null || true
      echo "TIMEOUT (>10s)"
    else
      wait "$ping_pid" 2>/dev/null || true
      local http_result
      http_result=$(cat "$ping_result_file" 2>/dev/null || echo "000")
      if [ "$http_result" = "200" ]; then
        echo "YES (HTTP 200)"
      elif [ "$http_result" = "429" ]; then
        echo "RATE LIMITED (HTTP 429)"
      elif [ "$http_result" = "000" ]; then
        echo "UNREACHABLE (no response)"
      else
        echo "ERROR (HTTP $http_result)"
      fi
    fi
    rm -f "$ping_result_file" 2>/dev/null
  fi

  # 6. Circuit breaker status
  local cb_file="$OPENCLAW_DIR/logs/circuit-breakers/${agent_name}.json"
  if [ -f "$cb_file" ]; then
    local cb_state
    cb_state=$(python3 -c "import json; print(json.load(open('$cb_file')).get('state','closed'))" 2>/dev/null || echo "unknown")
    local cb_failures
    cb_failures=$(python3 -c "import json; print(json.load(open('$cb_file')).get('failures',0))" 2>/dev/null || echo "0")
    local cb_status="OK"
    if [ "$cb_state" = "open" ]; then
      cb_status="OPEN (blocked, $cb_failures failures)"
    elif [ "$cb_state" = "half-open" ]; then
      cb_status="HALF-OPEN (testing, $cb_failures failures)"
    else
      cb_status="CLOSED ($cb_failures failures)"
    fi
    echo "  Circuit Breaker:  $cb_status"
  else
    echo "  Circuit Breaker:  N/A (no breaker file)"
  fi

  echo "============================================"
  echo ""
}

# ============================================================
# MAIN
# ============================================================

if [ "$AGENT_ID" = "--all" ]; then
  echo "=============================="
  echo "  Full Agent Health Report"
  echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "=============================="
  echo ""

  for agent_dir in "$AGENTS_DIR"/*/; do
    [ -d "$agent_dir" ] || continue
    local_name=$(basename "$agent_dir")

    # Skip symlinks to avoid double-reporting
    if [ -L "$AGENTS_DIR/$local_name" ]; then
      continue
    fi

    check_agent "$local_name"
  done

  echo "=============================="
  echo "  Report Complete"
  echo "=============================="
else
  check_agent "$AGENT_ID"
fi
