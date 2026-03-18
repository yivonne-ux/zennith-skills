#!/usr/bin/env bash
# pinchtab-browse.sh — AI-agent browser control via PinchTab CLI + HTTP API
# Usage:
#   pinchtab-browse.sh navigate "https://example.com"
#   pinchtab-browse.sh text                          # extract page text
#   pinchtab-browse.sh snapshot                      # accessibility tree (interactive elements)
#   pinchtab-browse.sh click e5                      # click element by ref
#   pinchtab-browse.sh fill e3 "search query"        # fill input field
#   pinchtab-browse.sh screenshot                    # capture screenshot
#   pinchtab-browse.sh scrape "https://url"          # navigate + extract text
#   pinchtab-browse.sh status                        # check if PinchTab is running

set -euo pipefail

PINCHTAB_PORT="${PINCHTAB_PORT:-9867}"
PINCHTAB_URL="http://localhost:${PINCHTAB_PORT}"

log() { echo "[$(date +%H:%M:%S)] $*" >&2; }

ensure_running() {
  if ! curl -s "${PINCHTAB_URL}/health" > /dev/null 2>&1; then
    log "Starting PinchTab server..."
    PINCHTAB_STEALTH=full nohup pinchtab > /tmp/pinchtab.log 2>&1 &
    sleep 3
    if ! curl -s "${PINCHTAB_URL}/health" > /dev/null 2>&1; then
      if ! curl -s "${PINCHTAB_URL}/instances" > /dev/null 2>&1; then
        log "ERROR: PinchTab failed to start. Check /tmp/pinchtab.log"
        exit 1
      fi
    fi
    log "PinchTab started on port ${PINCHTAB_PORT}"
  fi
}

# PinchTab uses CLI for instance creation, HTTP API for actions
cmd_navigate() {
  local url="$1"
  ensure_running
  pinchtab nav "$url" 2>/dev/null
  log "Navigated to: $url"
}

cmd_text() {
  ensure_running
  pinchtab text 2>/dev/null
}

cmd_snapshot() {
  ensure_running
  pinchtab snap -i 2>/dev/null
}

cmd_click() {
  local ref="$1"
  ensure_running
  pinchtab click "$ref" 2>/dev/null
}

cmd_fill() {
  local ref="$1"
  local text="$2"
  ensure_running
  pinchtab type "$ref" "$text" 2>/dev/null
}

cmd_screenshot() {
  ensure_running
  local outfile="${1:-/tmp/pinchtab-screenshot-$(date +%s).png}"
  pinchtab screenshot "$outfile" 2>/dev/null || pinchtab snap > "$outfile" 2>/dev/null
  echo "$outfile"
}

cmd_scrape() {
  local url="$1"
  cmd_navigate "$url"
  sleep 1
  cmd_text
}

cmd_status() {
  if curl -s "${PINCHTAB_URL}/health" > /dev/null 2>&1; then
    echo "PinchTab: RUNNING on port ${PINCHTAB_PORT}"
    echo "Version: $(pinchtab --version 2>/dev/null || echo 'unknown')"
    local count
    count=$(curl -s "${PINCHTAB_URL}/instances" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else d)" 2>/dev/null || echo 'unknown')
    echo "Instances: $count"
  else
    echo "PinchTab: NOT RUNNING"
    echo "Binary: $(which pinchtab 2>/dev/null || echo 'not found')"
  fi
}

case "${1:-help}" in
  navigate|nav)  cmd_navigate "${2:?URL required}" ;;
  text)          cmd_text ;;
  snapshot|snap) cmd_snapshot ;;
  click)         cmd_click "${2:?ref required}" ;;
  fill)          cmd_fill "${2:?ref required}" "${3:?text required}" ;;
  screenshot)    cmd_screenshot "${2:-}" ;;
  scrape)        cmd_scrape "${2:?URL required}" ;;
  status)        cmd_status ;;
  help|*)
    echo "PinchTab Browser Control for GAIA OS Agents"
    echo ""
    echo "Usage: pinchtab-browse.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  navigate <url>       Open URL in browser"
    echo "  text                 Extract page text"
    echo "  snapshot             Get accessibility tree (interactive elements)"
    echo "  click <ref>          Click element by ref (from snapshot)"
    echo "  fill <ref> <text>    Fill input field"
    echo "  screenshot [path]    Capture screenshot"
    echo "  scrape <url>         Navigate + extract text"
    echo "  status               Check if PinchTab is running"
    ;;
esac
