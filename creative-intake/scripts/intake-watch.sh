#!/usr/bin/env bash
# intake-watch.sh — Room watcher for the Creative Intake Engine
# Tails intake.jsonl for new entries and processes them via intake-processor.sh.
# Designed to run as a background job or from cron.
# Bash 3.2 compatible (macOS). No jq, no declare -A, no timeout.
#
# Usage:
#   bash intake-watch.sh           # Process new entries since last run
#   bash intake-watch.sh --daemon  # Continuous watch mode (poll every 5s)
#   bash intake-watch.sh --reset   # Reset cursor to current end of file

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INTAKE_ROOM="$HOME/.openclaw/workspace/rooms/intake.jsonl"
CURSOR_FILE="$HOME/.openclaw/workspace/rooms/.intake-cursor"
LOG_FILE="$HOME/.openclaw/workspace/logs/intake.log"
PROCESSOR="$SCRIPT_DIR/intake-processor.sh"
LOCK_FILE="/tmp/intake-watch.lock"

log() {
  printf '[%s] [intake-watch] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE" 2>/dev/null
}

# --- Lock management (macOS-safe, no flock) ---

acquire_lock() {
  local attempts=0
  while [ $attempts -lt 30 ]; do
    if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then
      trap release_lock EXIT INT TERM HUP
      return 0
    fi
    # Check if holding process is still alive
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -f "$LOCK_FILE"
      continue
    fi
    attempts=$((attempts + 1))
    sleep 1
  done
  log "ERROR: Could not acquire lock after 30 seconds"
  return 1
}

release_lock() {
  rm -f "$LOCK_FILE"
}

# --- Ensure intake room file exists ---

ensure_room() {
  local rooms_dir
  rooms_dir="$(dirname "$INTAKE_ROOM")"
  if [ ! -d "$rooms_dir" ]; then
    mkdir -p "$rooms_dir"
  fi
  if [ ! -f "$INTAKE_ROOM" ]; then
    touch "$INTAKE_ROOM"
    log "Created intake room: $INTAKE_ROOM"
  fi
}

# --- Process new entries ---

process_new_entries() {
  ensure_room

  # Get last processed line number
  local last_line=0
  if [ -f "$CURSOR_FILE" ]; then
    last_line=$(cat "$CURSOR_FILE" 2>/dev/null)
    last_line="${last_line:-0}"
    # Validate it is a number
    case "$last_line" in
      ''|*[!0-9]*) last_line=0 ;;
    esac
  fi

  # Count current lines
  local current_lines
  current_lines=$(wc -l < "$INTAKE_ROOM" 2>/dev/null | tr -d ' ')
  current_lines="${current_lines:-0}"

  # Process new lines
  if [ "$current_lines" -gt "$last_line" ]; then
    local new_count=$((current_lines - last_line))
    log "Found $new_count new entries (lines $((last_line + 1))-$current_lines)"

    local skip=$((last_line + 1))
    local processed=0
    local errors=0

    tail -n +"$skip" "$INTAKE_ROOM" | while IFS= read -r line; do
      # Skip empty lines
      if [ -z "$line" ]; then
        continue
      fi

      # Skip already-processed entries (type=intake-processed)
      IS_PROCESSED=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    t = d.get('type', '')
    if t in ('intake-processed', 'intake-result'):
        print('yes')
    else:
        print('no')
except Exception:
    print('no')
" <<< "$line" 2>/dev/null)

      if [ "$IS_PROCESSED" = "yes" ]; then
        continue
      fi

      log "Processing entry: $(echo "$line" | head -c 120)"

      # Process the entry
      RESULT=$(echo "$line" | bash "$PROCESSOR" 2>>"$LOG_FILE") || {
        log "WARNING: Processor returned non-zero for entry"
        errors=$((errors + 1))
        continue
      }

      if [ -n "$RESULT" ]; then
        log "Result: $(echo "$RESULT" | head -c 200)"
        processed=$((processed + 1))
      fi
    done

    # Update cursor
    echo "$current_lines" > "$CURSOR_FILE"
    log "Cursor updated to line $current_lines"
  else
    log "No new entries (cursor=$last_line, total=$current_lines)"
  fi
}

# --- Main ---

MODE="${1:-}"

case "$MODE" in
  --reset)
    ensure_room
    current_lines=$(wc -l < "$INTAKE_ROOM" 2>/dev/null | tr -d ' ')
    current_lines="${current_lines:-0}"
    echo "$current_lines" > "$CURSOR_FILE"
    log "Cursor reset to line $current_lines"
    echo "Cursor reset to line $current_lines"
    exit 0
    ;;

  --daemon)
    log "Starting intake watcher in daemon mode"
    echo "Intake watcher starting in daemon mode. PID: $$"
    echo "Watching: $INTAKE_ROOM"
    echo "Log: $LOG_FILE"

    while true; do
      if acquire_lock; then
        process_new_entries
        release_lock
      fi
      sleep 5
    done
    ;;

  ""|--once)
    # Single pass (default, cron-friendly)
    if acquire_lock; then
      process_new_entries
    else
      log "ERROR: Could not acquire lock, another instance may be running"
      exit 1
    fi
    ;;

  --help|-h)
    echo "intake-watch.sh — Room watcher for Creative Intake Engine"
    echo ""
    echo "Usage:"
    echo "  bash intake-watch.sh           Process new entries since last run"
    echo "  bash intake-watch.sh --daemon  Continuous watch mode (poll every 5s)"
    echo "  bash intake-watch.sh --reset   Reset cursor to current end of file"
    echo "  bash intake-watch.sh --help    Show this help"
    echo ""
    echo "Room: $INTAKE_ROOM"
    echo "Log:  $LOG_FILE"
    exit 0
    ;;

  *)
    echo "Unknown option: $MODE" >&2
    echo "Use --help for usage" >&2
    exit 1
    ;;
esac
