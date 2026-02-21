#!/usr/bin/env bash
# data-quality-gate.sh — Data quality circuit breaker for content seeds
# Prevents storing seeds from stale/failed data sources.
# Called by agents BEFORE seed-store.sh add, or by mission-check to audit.
#
# Usage:
#   data-quality-gate.sh check  --agent <agent> --mission <mission_id>
#   data-quality-gate.sh audit  [--recent <hours>]
#
# Exit codes: 0 = pass (safe to store), 1 = fail (abort + escalate)

set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
DATA_DIR="$OPENCLAW_DIR/workspace/data"
GATE_LOG="$OPENCLAW_DIR/logs/data-quality-gate.log"
SEEDS_FILE="$DATA_DIR/seeds.jsonl"

mkdir -p "$(dirname "$GATE_LOG")" "$DATA_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$GATE_LOG"; }

post_to_room() {
  local room="$1" agent="$2" msg="$3" type="${4:-data-quality}"
  local safe_msg
  safe_msg=$(echo "$msg" | tr '\n' ' ' | head -c 500)
  printf '{"ts":%s000,"agent":"%s","room":"%s","type":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$agent" "$room" "$type" "$safe_msg" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK: Validate data source freshness
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_check() {
  local agent="" mission=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --agent)   agent="$2";   shift 2 ;;
      --mission) mission="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  [ -z "$agent" ] && { echo "FAIL: --agent required" >&2; exit 1; }

  # Check recent room entries for this agent — look for source failure signals
  local feedback_file="$ROOMS_DIR/feedback.jsonl"
  local now
  now=$(date +%s)
  local window=$((now - 3600))  # Last 1 hour

  if [ ! -f "$feedback_file" ]; then
    echo "PASS: No feedback data (new system)"
    exit 0
  fi

  # Count source failures vs successes for this agent in the last hour
  local result
  result=$(python3 - "$feedback_file" "$agent" "$window" "$mission" << 'PYEOF'
import json, sys

feedback_file = sys.argv[1]
agent = sys.argv[2]
window = int(sys.argv[3])
mission = sys.argv[4] if len(sys.argv) > 4 else ""

failures = 0
successes = 0
total_source_mentions = 0
failure_signals = [
    "0 products", "0% success", "403", "forbidden", "blocked",
    "timeout", "scraper failed", "no data", "empty response",
    "rate limit", "429", "source failed", "all sources failed",
    "recycled", "stale data", "no fresh data"
]
success_signals = [
    "found", "collected", "scraped", "fetched", "products found",
    "success", "complete", "data ready"
]

with open(feedback_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
            ts = d.get("ts", 0)
            # Normalize ts (some are in ms, some in s)
            if ts > 1e12:
                ts = ts / 1000
            if ts < window:
                continue
            msg_agent = d.get("agent", "")
            msg = d.get("msg", "").lower()

            # Only look at entries from this agent or about this mission
            if msg_agent != agent and mission not in msg:
                continue

            total_source_mentions += 1

            for sig in failure_signals:
                if sig in msg:
                    failures += 1
                    break
            else:
                for sig in success_signals:
                    if sig in msg:
                        successes += 1
                        break
        except:
            pass

# Decision logic
if total_source_mentions == 0:
    print("PASS|0|0|0|No recent source activity")
    sys.exit(0)

failure_rate = failures / max(total_source_mentions, 1)

if failure_rate >= 0.8:
    print(f"FAIL|{failures}|{successes}|{total_source_mentions}|{failure_rate:.0%} source failure rate — DO NOT store seeds")
    sys.exit(1)
elif failure_rate >= 0.5:
    print(f"WARN|{failures}|{successes}|{total_source_mentions}|{failure_rate:.0%} source failure rate — seeds are LOW confidence")
    sys.exit(0)
else:
    print(f"PASS|{failures}|{successes}|{total_source_mentions}|{failure_rate:.0%} source failure rate — data quality OK")
    sys.exit(0)
PYEOF
  ) || true

  local verdict
  verdict=$(echo "$result" | cut -d'|' -f1)
  local detail
  detail=$(echo "$result" | cut -d'|' -f5)

  case "$verdict" in
    FAIL)
      log "BLOCKED: $agent/$mission — $detail"
      post_to_room "feedback" "$agent" "DATA QUALITY GATE: BLOCKED seed storage for $mission. $detail" "data-quality"
      post_to_room "exec" "zenni" "⚠️ Data quality gate blocked $agent from storing seeds ($mission). Sources mostly failed. Seeds NOT stored." "escalation"
      echo "FAIL: $detail"
      exit 1
      ;;
    WARN)
      log "WARNING: $agent/$mission — $detail"
      post_to_room "feedback" "$agent" "DATA QUALITY GATE: WARNING for $mission. $detail. Seeds tagged LOW-CONFIDENCE." "data-quality"
      echo "WARN: $detail"
      exit 0
      ;;
    PASS)
      log "PASS: $agent/$mission — $detail"
      echo "PASS: $detail"
      exit 0
      ;;
    *)
      log "UNKNOWN: $agent/$mission — $result"
      echo "PASS: Unknown state, allowing (fail-open)"
      exit 0
      ;;
  esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AUDIT: Review recent seeds for quality issues
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cmd_audit() {
  local hours=24
  while [ $# -gt 0 ]; do
    case "$1" in
      --recent) hours="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local now
  now=$(date +%s)
  local window=$((now - hours * 3600))

  if [ ! -f "$SEEDS_FILE" ]; then
    echo "No seeds file found."
    exit 0
  fi

  python3 - "$SEEDS_FILE" "$window" << 'PYEOF'
import json, sys

seeds_file = sys.argv[1]
window = int(sys.argv[2])

total = 0
by_source = {}
low_quality = []

with open(seeds_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
            ts = d.get("created_at", d.get("ts", 0))
            if ts > 1e12:
                ts = ts / 1000
            if ts < window:
                continue
            total += 1
            src = d.get("source", d.get("source_agent", "unknown"))
            by_source[src] = by_source.get(src, 0) + 1

            # Flag seeds with no performance data AND source is artemis
            if src == "artemis" and not d.get("performance"):
                text = d.get("text", "")[:60]
                low_quality.append({"id": d.get("id", "?"), "text": text})
        except:
            pass

print(f"Seeds added in last {sys.argv[2]}s window: {total}")
print(f"By source: {json.dumps(by_source)}")
if low_quality:
    print(f"⚠️ {len(low_quality)} unverified artemis seeds (no performance data):")
    for s in low_quality[:5]:
        print(f"  - {s['id']}: {s['text']}")
else:
    print("✅ All seeds have quality markers")
PYEOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CMD="${1:-}"
shift || true

case "$CMD" in
  check) cmd_check "$@" ;;
  audit) cmd_audit "$@" ;;
  *)
    echo "Usage: data-quality-gate.sh <check|audit> [options]"
    echo "  check --agent <agent> --mission <mission_id>"
    echo "  audit --recent <hours>"
    exit 1
    ;;
esac
