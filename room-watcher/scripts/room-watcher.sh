#!/usr/bin/env bash
# --- anti-loop guard: do not re-dispatch known noisy/recursive errors ---
should_dispatch_line() {
  local line="$1"

  # Drop tail -f file headers and empties
  echo "$line" | grep -q "^==> .* <==$" && return 1
  [ -z "$line" ] && return 1

  # Never re-dispatch control-plane messages (prevents feedback loops)
  echo "$line" | grep -q '"agent":"room-watcher"' && return 1
  echo "$line" | grep -q '"type":"dispatch"' && return 1
  echo "$line" | grep -q '"type":"dispatch-response"' && return 1
  echo "$line" | grep -q "\[REAL-TIME\]" && return 1

  # Stop turn-limit storms (match variations, not just exact "(10)")
  echo "$line" | grep -qi "Reached max turns" && return 1
  echo "$line" | grep -qi "max turns" && return 1

  # Stop old auth-noise from triggering response storms
  echo "$line" | grep -q "Not logged in" && return 1
  echo "$line" | grep -q "Please run /login" && return 1
  echo "$line" | grep -q "Invalid API key" && return 1

  return 0
}
# --- end anti-loop guard ---

# --- single-instance guard (prevents duplicate daemons) ---
LOCKDIR="$HOME/.openclaw/workspace/locks/room-watcher.lock"
PIDFILE="$LOCKDIR/pid"
mkdir -p "$(dirname "$LOCKDIR")"

if [ -d "$LOCKDIR" ] && [ -f "$PIDFILE" ]; then
  OLD_PID="$(cat "$PIDFILE" 2>/dev/null || true)"
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$LOCKDIR" 2>/dev/null || true
fi

if ! mkdir "$LOCKDIR" 2>/dev/null; then
  exit 0
fi

echo $$ > "$PIDFILE" 2>/dev/null || true
cleanup_lock() { rm -rf "$LOCKDIR" 2>/dev/null || true; }
trap cleanup_lock EXIT INT TERM
# --- end single-instance guard ---

# room-watcher.sh — Real-time room message bus
#
# Watches JSONL room files for new entries and dispatches agents instantly.
# Uses tail -f for reliable cross-file monitoring on macOS (bash 3.2 compatible).
#
# Usage: bash room-watcher.sh (runs as daemon)
# Stop: kill $(cat ~/.openclaw/logs/room-watcher.pid)

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

ROOMS_DIR="${HOME}/.openclaw/workspace/rooms"
LOG_FILE="${HOME}/.openclaw/logs/room-watcher.log"
PID_FILE="${HOME}/.openclaw/logs/room-watcher.pid"
DISPATCH="${HOME}/.openclaw/skills/mission-control/scripts/dispatch.sh"
COOLDOWN_DIR="${HOME}/.openclaw/logs/watcher-cooldown"

mkdir -p "$(dirname "$LOG_FILE")" "$COOLDOWN_DIR"

# Write PID
echo $$ > "$PID_FILE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Room Watcher Started (PID $$) ==="

# Check cooldown — don't spam same agent for same room within 5 min
check_cooldown() {
  local agent="$1"
  local room="$2"
  local cooldown_file="${COOLDOWN_DIR}/${agent}-${room}"

  if [ -f "$cooldown_file" ]; then
    local last_time
    last_time=$(cat "$cooldown_file" 2>/dev/null || echo "0")
    local now
    now=$(date +%s)
    local elapsed=$(( now - last_time ))
    if [ "$elapsed" -lt 300 ]; then
      return 1  # Still in cooldown
    fi
  fi

  date +%s > "$cooldown_file"
  return 0
}

# Dispatch notification to an agent
dispatch_agent() {
  local agent="$1"
  local room="$2"
  local from="$3"
  local preview="$4"

  # Skip main/zenni — orchestrator uses heartbeat
  [ "$agent" = "main" ] && return
  [ "$agent" = "zenni" ] && return
  [ "$agent" = "room-watcher" ] && return
  [ "$agent" = "test" ] && return

  # Check cooldown
  if ! check_cooldown "$agent" "$room"; then
    log "COOLDOWN: $agent for $room (skip)"
    return
  fi

  log "DISPATCH: $agent <- $room (from $from): ${preview:0:60}"

  local brief="[REAL-TIME] New message in $room room from $from: $preview. Read $room room for full context and respond if relevant. Follow your SOUL.md Room Protocol."

  if [ -f "$DISPATCH" ]; then
    bash "$DISPATCH" "room-watcher" "$agent" "request" "$brief" "$room" >> "$LOG_FILE" 2>&1 &
  fi
}

# Process a single new line from a room file
process_line() {
  local room_name="$1"
  local line="$2"

  [ -z "$line" ] && return

  # Parse JSON fields using python3
  local parsed
  parsed=$(python3 -c "
import json, sys
try:
    d = json.loads('''$line''')
    agent = d.get('agent', '')
    to = d.get('to', '')
    needs = d.get('needs', '')
    msg_type = d.get('type', 'message')
    msg = d.get('msg', '')[:100]
    print(f'{agent}|{to}|{needs}|{msg_type}|{msg}')
except:
    print('|||error|')
" 2>/dev/null) || return

  local from_agent to_agent needs_agent msg_type msg_preview
  IFS='|' read -r from_agent to_agent needs_agent msg_type msg_preview <<< "$parsed"

  # Skip system/watcher messages
  [ "$from_agent" = "room-watcher" ] && return
  [ "$msg_type" = "system" ] && return
  [ -z "$from_agent" ] && return

  log "NEW: $room_name <- $from_agent (to=$to_agent, type=$msg_type)"

  # Priority 1: Direct addressing
  if [ -n "$to_agent" ] && [ "$to_agent" != "null" ] && [ "$to_agent" != "" ]; then
    dispatch_agent "$to_agent" "$room_name" "$from_agent" "$msg_preview"
    return
  fi

  # Priority 2: Needs field (error escalation)
  if [ -n "$needs_agent" ] && [ "$needs_agent" != "null" ] && [ "$needs_agent" != "" ]; then
    dispatch_agent "$needs_agent" "$room_name" "$from_agent" "NEEDS YOU: $msg_preview"
    return
  fi

  # Priority 3: Room subscriptions
  case "$room_name" in
    build)
      [ "$from_agent" != "artemis" ] && dispatch_agent "artemis" "$room_name" "$from_agent" "$msg_preview"
      [ "$from_agent" != "athena" ] && dispatch_agent "athena" "$room_name" "$from_agent" "$msg_preview"
      ;;
    exec)
      [ "$from_agent" != "athena" ] && dispatch_agent "athena" "$room_name" "$from_agent" "$msg_preview"
      [ "$from_agent" != "hermes" ] && dispatch_agent "hermes" "$room_name" "$from_agent" "$msg_preview"
      ;;
    creative)
      [ "$from_agent" != "iris" ] && dispatch_agent "iris" "$room_name" "$from_agent" "$msg_preview"
      ;;
    social)
      [ "$from_agent" != "athena" ] && dispatch_agent "athena" "$room_name" "$from_agent" "$msg_preview"
      ;;
  esac
}

# Main: use tail -f to follow all room files
# -n0 means start from end (only new lines)
log "Watching: $ROOMS_DIR/*.jsonl"

while true; do
  current_room=""

  files=("$ROOMS_DIR"/*.jsonl)
  if [ ! -e "${files[0]}" ]; then
    sleep 1
    continue
  fi

  tail -n0 -F "${files[@]}" 2>/dev/null | while IFS= read -r line; do
    should_dispatch_line "$line" || continue

    # tail -F outputs "==> filename <==" headers when switching files
    if echo "$line" | grep -q "^==> .* <==$"; then
      current_room=$(echo "$line" | sed 's/==> //;s/ <==//;s/.*\///;s/\.jsonl//')
      continue
    fi

    [ -z "$line" ] && continue

    if [ -z "$current_room" ]; then
      current_room=$(python3 -c "import json; print(json.loads('''$line''').get('room','unknown'))" 2>/dev/null || echo "unknown")
    fi

    process_line "$current_room" "$line"
  done

  # if tail exits for any reason, restart it
  sleep 1
done
