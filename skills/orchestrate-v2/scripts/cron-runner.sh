#!/usr/bin/env bash
# cron-runner.sh — System crontab fallback for jobs NOT handled by gateway-native cron
# NOTE: innovation-scout, nightly-review, weekly-review, meta-ads-scan, tiktok-trends-scan,
#       product-scout-weekly are NOW handled by gateway-native cron (jobs.json).
#       This script only handles: heartbeat (local health check).
#       Other jobs are kept as stubs that skip if gateway cron is handling them.
#
# Usage: bash cron-runner.sh <job-id>
# Jobs: heartbeat

set -uo pipefail

# Ensure PATH includes openclaw binary location (cron has minimal PATH)
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

OPENCLAW="/usr/local/bin/node /Users/jennwoeiloh/local/lib/node_modules/openclaw/dist/index.js"
JOB_ID="${1:-}"
OPENCLAW_DIR="$HOME/.openclaw"
LOG_FILE="$OPENCLAW_DIR/logs/cron-runner.log"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"

TS=$(date +"%Y-%m-%d %H:%M:%S %Z")

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$ROOMS_DIR"

log() {
  echo "[$TS] $1" >> "$LOG_FILE"
}

post_to_room() {
  local room="$1" agent="$2" msg="$3" type="${4:-cron}"
  local entry="{\"ts\":$(date +%s)000,\"agent\":\"$agent\",\"room\":\"$room\",\"type\":\"$type\",\"msg\":\"$msg\"}"
  echo "$entry" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null
}

# Pre-flight: check gateway is reachable (5s timeout)
check_gateway() {
  curl -sf --max-time 5 http://127.0.0.1:18789/ready > /dev/null 2>&1
}

if [ -z "$JOB_ID" ]; then
  echo "Usage: cron-runner.sh <job-id>"
  echo "Jobs: heartbeat"
  echo "NOTE: Most jobs are now handled by gateway-native cron. See: openclaw cron list"
  exit 1
fi

log "START: $JOB_ID"

case "$JOB_ID" in

  heartbeat)
    # Quick health check — verify gateway is running and rooms are writable
    GW_OK=0
    if check_gateway; then
      GW_OK=1
    fi
    ROOMS_OK=0
    for room in exec build creative analytics; do
      if [ -w "$ROOMS_DIR/${room}.jsonl" ] 2>/dev/null; then
        ROOMS_OK=$((ROOMS_OK + 1))
      fi
    done
    if [ "$GW_OK" -eq 1 ] && [ "$ROOMS_OK" -ge 3 ]; then
      log "HEARTBEAT: OK (gateway=UP, rooms=$ROOMS_OK writable)"
    else
      log "HEARTBEAT: WARN (gateway=$([ "$GW_OK" -eq 1 ] && echo UP || echo DOWN), rooms=$ROOMS_OK writable)"
      post_to_room "feedback" "zenni" "HEARTBEAT WARN: gateway=$([ "$GW_OK" -eq 1 ] && echo UP || echo DOWN), rooms=$ROOMS_OK/4" "incident"
    fi
    exit 0
    ;;

  innovation-scout|meta-ads-scan|tiktok-trends-scan|product-scout-weekly|nightly-review|weekly-review)
    # These jobs are now handled by gateway-native cron (jobs.json).
    # Skip to avoid double-execution.
    log "SKIP: $JOB_ID — handled by gateway-native cron. Remove this crontab entry."
    exit 0
    ;;

  *)
    log "ERROR: Unknown job: $JOB_ID"
    exit 1
    ;;
esac

log "END: $JOB_ID"
