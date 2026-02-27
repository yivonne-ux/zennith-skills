#!/usr/bin/env bash
# cron-runner.sh — System crontab replacement for broken OpenClaw cron module
# Invokes agents on schedule via `openclaw agent --agent <id> --message`
#
# Usage: bash cron-runner.sh <job-id>
# Jobs: heartbeat, innovation-scout, meta-ads-scan, tiktok-trends-scan,
#        product-scout-weekly, nightly-review, weekly-review

set -uo pipefail

# Ensure PATH includes openclaw binary location (cron has minimal PATH)
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

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

if [ -z "$JOB_ID" ]; then
  echo "Usage: cron-runner.sh <job-id>"
  echo "Jobs: heartbeat, innovation-scout, meta-ads-scan, tiktok-trends-scan, product-scout-weekly, nightly-review, weekly-review"
  exit 1
fi

log "START: $JOB_ID"

case "$JOB_ID" in

  heartbeat)
    # Quick health check — verify gateway is running and rooms are writable
    GW_PID=$(pgrep -f "openclaw gateway" || echo "")
    ROOMS_OK=0
    for room in exec build creative analytics; do
      if [ -w "$ROOMS_DIR/${room}.jsonl" ] 2>/dev/null; then
        ROOMS_OK=$((ROOMS_OK + 1))
      fi
    done
    if [ -n "$GW_PID" ] && [ "$ROOMS_OK" -ge 3 ]; then
      log "HEARTBEAT: OK (gateway PID=$GW_PID, rooms=$ROOMS_OK writable)"
    else
      log "HEARTBEAT: WARN (gateway PID=${GW_PID:-NONE}, rooms=$ROOMS_OK writable)"
      post_to_room "feedback" "zenni" "HEARTBEAT WARN: gateway=${GW_PID:-DOWN}, rooms=$ROOMS_OK/4" "incident"
    fi
    exit 0
    ;;

  innovation-scout)
    RESULT=$(openclaw agent --agent artemis \
      --message "You are Artemis. Read your SOUL.md. Run innovation-scout protocol: Scout GitHub trending, Product Hunt, HN for AI agent innovations relevant to GAIA Eats (e-commerce, social, content, marketing). Post structured scout report to townhall room." \
      --json --timeout 300 2>&1)
    AGENT="artemis"
    ROOM="townhall"
    ;;

  meta-ads-scan)
    RESULT=$(openclaw agent --agent artemis \
      --message "You are Artemis. Read your SOUL.md. Run meta-ads-library scraping. Execute: python3 ~/.openclaw/skills/meta-ads-library/scripts/scrape_meta_library.py --keyword 'vegan food,plant based,organic snack' --country MY --max-results 20 --output /tmp/meta-ads-daily.json. Post competitive intelligence summary to build room." \
      --json --timeout 300 2>&1)
    AGENT="artemis"
    ROOM="build"
    ;;

  tiktok-trends-scan)
    RESULT=$(openclaw agent --agent artemis \
      --message "You are Artemis. Read your SOUL.md. Run tiktok-trends scraping. Execute: python3 ~/.openclaw/skills/tiktok-trends/scripts/scrape_tiktok_trends.py --type hashtags --country MY --output /tmp/tiktok-trends-daily.json. Post GAIA-relevant trends summary to build room." \
      --json --timeout 300 2>&1)
    AGENT="artemis"
    ROOM="build"
    ;;

  product-scout-weekly)
    RESULT=$(openclaw agent --agent artemis \
      --message "You are Artemis. Read your SOUL.md. Run product-scout weekly scan. Execute: python3 ~/.openclaw/skills/product-scout/scripts/scout_products.py --platform shopee --country MY --category all --output /tmp/product-scout-weekly.json. Post opportunity report to townhall room." \
      --json --timeout 600 2>&1)
    AGENT="artemis"
    ROOM="townhall"
    ;;

  nightly-review)
    LABEL="zenni-nightly-$(date +%s)"
    RESULT=$(openclaw sessions spawn --label "$LABEL" --timeout 300 "You are Zenni. Read your SOUL.md. Run corp-os-compound nightly review. Scan all rooms from last 24h, extract patterns, detect gaps, update learning-log. Post summary to townhall room." 2>&1)
    AGENT="zenni"
    ROOM="townhall"
    ;;

  weekly-review)
    RESULT=$(openclaw agent --agent main \
      --message "Run corp-os-compound weekly review. Aggregate 7 days of learnings, identify recurring failures, produce Week in Review. Post to townhall room." \
      --json --timeout 600 2>&1)
    AGENT="zenni"
    ROOM="townhall"
    ;;

  *)
    log "ERROR: Unknown job: $JOB_ID"
    exit 1
    ;;
esac

# Check result
STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null || echo "error")

if [ "$STATUS" = "ok" ]; then
  TEXT=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['payloads'][0]['text'][:300])" 2>/dev/null || echo "completed")
  log "OK: $JOB_ID ($AGENT) — $TEXT"
  post_to_room "$ROOM" "$AGENT" "[$JOB_ID] $TEXT" "cron-result"
else
  ERROR=$(echo "$RESULT" | head -5)
  log "FAIL: $JOB_ID ($AGENT) — $ERROR"
  post_to_room "feedback" "$AGENT" "CRON FAIL: $JOB_ID — $ERROR" "incident"
fi

log "END: $JOB_ID"
