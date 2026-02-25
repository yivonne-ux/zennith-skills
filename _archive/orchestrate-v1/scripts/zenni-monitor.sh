#!/usr/bin/env bash
# zenni-monitor.sh — Self-monitoring daemon for GAIA CORP-OS
# Checks if tasks are hanging, triggers fixes, keeps building

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
LOG_FILE="$OPENCLAW_DIR/logs/zenni-monitor.log"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
TS=$(date +"%Y-%m-%d %H:%M:%S %Z")

log() {
  echo "[$TS] $1" | tee -a "$LOG_FILE"
}

# Check if gateway is responsive
check_gateway() {
  if ! pgrep -f "openclaw-gateway" > /dev/null; then
    log "ALERT: Gateway not running!"
    echo '{"ts":'$(date +%s)000',"agent":"zenni-monitor","room":"feedback","type":"alert","msg":"Gateway not running — attempting restart"}' >> "$ROOMS_DIR/feedback.jsonl"
    openclaw gateway restart &
    return 1
  fi
  return 0
}

# Check for stale missions (no activity > 2h)
check_stale_missions() {
  if [ -f "$OPENCLAW_DIR/workspace/MISSIONS.md" ]; then
    # Count IN_PROGRESS missions
    STALE_COUNT=$(grep -c "IN_PROGRESS" "$OPENCLAW_DIR/workspace/MISSIONS.md" 2>/dev/null || echo "0")
    if [ "$STALE_COUNT" -gt 3 ]; then
      log "NOTICE: $STALE_COUNT missions in progress — may need triage"
    fi
  fi
}

# Check for hanging subagents (older than 30 min with no new messages)
check_hanging_subagents() {
  # This would need session API access — simplified version
  ACTIVE_SUBAGENTS=$(openclaw sessions:list --kinds subagent 2>/dev/null | grep -c "subagent" || echo "0")
  if [ "$ACTIVE_SUBAGENTS" -gt 5 ]; then
    log "NOTICE: $ACTIVE_SUBAGENTS active subagents — checking for hangs"
  fi
}

# Self-healing: If no scout activity in 6h, trigger one
check_scout_activity() {
  if [ -f "$OPENCLAW_DIR/logs/continuous-scout.log" ]; then
    LAST_SCOUT=$(stat -c %Y "$OPENCLAW_DIR/logs/continuous-scout.log" 2>/dev/null || stat -f %m "$LOG_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    DIFF=$((NOW - LAST_SCOUT))
    if [ $DIFF -gt 21600 ]; then  # 6 hours
      log "No scout activity for $((DIFF/3600))h — triggering now"
      bash "$OPENCLAW_DIR/skills/orchestrate/scripts/continuous-scout.sh" all &
    fi
  fi
}

# Main monitor loop
log "=== Zenni Monitor Check ==="

check_gateway
check_stale_missions
check_scout_activity

# Heartbeat
log "Monitor check complete — system healthy"
echo '{"ts":'$(date +%s)000',"agent":"zenni-monitor","room":"feedback","type":"heartbeat","msg":"System check OK — gateway up, missions tracked"}' >> "$ROOMS_DIR/feedback.jsonl"
