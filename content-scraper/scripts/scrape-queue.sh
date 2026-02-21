#!/usr/bin/env bash
# scrape-queue.sh — Multi-platform content scrape job queue
#
# Usage:
#   bash scrape-queue.sh add --platform pinterest --target "jennloh85" --type board_sync [--priority high] [--instructions "..."]
#   bash scrape-queue.sh list [--status pending]
#   bash scrape-queue.sh next [--agent artemis]
#   bash scrape-queue.sh done <job_id> [--result "summary"]
#   bash scrape-queue.sh count
#
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

QUEUE_FILE="$HOME/.openclaw/workspace/data/scrape-queue.jsonl"
LOCK_FILE="/tmp/scrape-queue.lock"
LOG="$HOME/.openclaw/logs/content-scraper.log"

mkdir -p "$(dirname "$QUEUE_FILE")" "$(dirname "$LOG")"
touch "$QUEUE_FILE"

CMD="${1:-help}"
shift 2>/dev/null || true

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SCRAPE-QUEUE] $1" >> "$LOG"
}

# Simple file locking (bash 3.2 compatible)
acquire_lock() {
  local attempts=0
  while [ -f "$LOCK_FILE" ] && [ $attempts -lt 10 ]; do
    sleep 0.5
    attempts=$((attempts + 1))
  done
  echo $$ > "$LOCK_FILE"
}
release_lock() {
  rm -f "$LOCK_FILE"
}

# Platform → default agent mapping
get_agent() {
  local platform="$1"
  case "$platform" in
    pinterest|youtube|twitter|x) echo "artemis" ;;
    instagram|tiktok|facebook) echo "iris" ;;
    *) echo "artemis" ;;
  esac
}

case "$CMD" in

  add)
    PLATFORM="" TARGET="" TYPE="general" PRIORITY="medium" INSTRUCTIONS="" AGENT=""

    while [ $# -gt 0 ]; do
      case "$1" in
        --platform) PLATFORM="$2"; shift 2;;
        --target) TARGET="$2"; shift 2;;
        --type) TYPE="$2"; shift 2;;
        --priority) PRIORITY="$2"; shift 2;;
        --instructions) INSTRUCTIONS="$2"; shift 2;;
        --agent) AGENT="$2"; shift 2;;
        *) shift;;
      esac
    done

    if [ -z "$PLATFORM" ] || [ -z "$TARGET" ]; then
      echo "ERROR: --platform and --target required" >&2
      exit 1
    fi

    if [ -z "$AGENT" ]; then
      AGENT=$(get_agent "$PLATFORM")
    fi

    # Generate job ID
    JOB_ID="scrape-$(date +%s)-$(python3 -c 'import random; print(random.randint(1000,9999))')"
    TS=$(date +%s)000

    acquire_lock

    python3 - "$QUEUE_FILE" "$JOB_ID" "$TS" "$PLATFORM" "$TARGET" "$TYPE" "$PRIORITY" "$AGENT" "$INSTRUCTIONS" << 'PYEOF'
import json, sys
queue_file, job_id, ts, platform, target, jtype, priority, agent, instructions = sys.argv[1:]

job = {
    "id": job_id,
    "ts": int(ts),
    "platform": platform,
    "target": target,
    "type": jtype,
    "priority": priority,
    "status": "pending",
    "agent": agent,
    "instructions": instructions,
    "created_by": "zenni",
    "completed_at": None,
    "result": None
}

with open(queue_file, 'a') as f:
    f.write(json.dumps(job) + '\n')

print(f"Queued: {job_id} ({platform}/{target}) → {agent}")
PYEOF

    release_lock
    log "ADD: $JOB_ID ($PLATFORM/$TARGET) → $AGENT"
    ;;

  list)
    STATUS_FILTER="${1:-}"  # Optional --status filter
    FILTER_VAL="${2:-}"

    python3 - "$QUEUE_FILE" "$FILTER_VAL" << 'PYEOF'
import json, sys

queue_file = sys.argv[1]
status_filter = sys.argv[2] if len(sys.argv) > 2 else ""

jobs = []
try:
    with open(queue_file) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                job = json.loads(line)
                if not status_filter or job.get("status") == status_filter:
                    jobs.append(job)
            except: pass
except FileNotFoundError:
    pass

if not jobs:
    print("No jobs in queue")
else:
    # Group by status
    by_status = {}
    for j in jobs:
        s = j.get("status", "unknown")
        if s not in by_status:
            by_status[s] = []
        by_status[s].append(j)

    for status, items in sorted(by_status.items()):
        print(f"\n--- {status.upper()} ({len(items)}) ---")
        for j in items[-10:]:  # Show last 10 per status
            print(f"  {j['id']} | {j['platform']}/{j['target']} | {j.get('type','?')} | {j.get('priority','?')} | → {j.get('agent','?')}")
PYEOF
    ;;

  next)
    # Pop next pending job, optionally filtered by agent
    AGENT_FILTER=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --agent) AGENT_FILTER="$2"; shift 2;;
        *) shift;;
      esac
    done

    acquire_lock

    python3 - "$QUEUE_FILE" "$AGENT_FILTER" << 'PYEOF'
import json, sys

queue_file = sys.argv[1]
agent_filter = sys.argv[2] if len(sys.argv) > 2 else ""

# Priority order
priority_rank = {"urgent": 0, "high": 1, "medium": 2, "low": 3}

jobs = []
try:
    with open(queue_file) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                jobs.append(json.loads(line))
            except: pass
except FileNotFoundError:
    pass

# Find next pending job
candidates = [j for j in jobs if j.get("status") == "pending"]
if agent_filter:
    candidates = [j for j in candidates if j.get("agent") == agent_filter]

if not candidates:
    print("")  # Empty = no jobs
    sys.exit(0)

# Sort by priority then timestamp
candidates.sort(key=lambda j: (priority_rank.get(j.get("priority", "medium"), 2), j.get("ts", 0)))
next_job = candidates[0]

# Mark as in_progress
updated = []
for j in jobs:
    if j["id"] == next_job["id"]:
        j["status"] = "in_progress"
    updated.append(j)

with open(queue_file, 'w') as f:
    for j in updated:
        f.write(json.dumps(j) + '\n')

print(json.dumps(next_job))
PYEOF

    release_lock
    ;;

  done)
    JOB_ID="${1:-}"
    RESULT=""
    shift 2>/dev/null || true
    while [ $# -gt 0 ]; do
      case "$1" in
        --result) RESULT="$2"; shift 2;;
        *) shift;;
      esac
    done

    if [ -z "$JOB_ID" ]; then
      echo "ERROR: job_id required" >&2
      exit 1
    fi

    acquire_lock

    python3 - "$QUEUE_FILE" "$JOB_ID" "$RESULT" << 'PYEOF'
import json, sys, time

queue_file, job_id, result = sys.argv[1], sys.argv[2], sys.argv[3]

jobs = []
found = False
with open(queue_file) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            j = json.loads(line)
            if j["id"] == job_id:
                j["status"] = "completed"
                j["completed_at"] = int(time.time()) * 1000
                if result:
                    j["result"] = result
                found = True
            jobs.append(j)
        except: pass

if not found:
    print(f"Job {job_id} not found")
    sys.exit(1)

with open(queue_file, 'w') as f:
    for j in jobs:
        f.write(json.dumps(j) + '\n')

print(f"Completed: {job_id}")
PYEOF

    release_lock
    log "DONE: $JOB_ID"
    ;;

  count)
    python3 - "$QUEUE_FILE" << 'PYEOF'
import json, sys

queue_file = sys.argv[1]
counts = {"pending": 0, "in_progress": 0, "completed": 0}
try:
    with open(queue_file) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                j = json.loads(line)
                s = j.get("status", "unknown")
                counts[s] = counts.get(s, 0) + 1
            except: pass
except FileNotFoundError:
    pass

total = sum(counts.values())
print(f"Total: {total} | Pending: {counts['pending']} | In Progress: {counts['in_progress']} | Completed: {counts['completed']}")
PYEOF
    ;;

  *)
    echo "Usage: scrape-queue.sh <add|list|next|done|count>"
    echo ""
    echo "Commands:"
    echo "  add     --platform <platform> --target <target> [--type <type>] [--priority <priority>] [--instructions <text>]"
    echo "  list    [--status pending|in_progress|completed]"
    echo "  next    [--agent <agent>]"
    echo "  done    <job_id> [--result <summary>]"
    echo "  count"
    echo ""
    echo "Platforms: pinterest, youtube, tiktok, instagram, facebook, twitter"
    ;;
esac
