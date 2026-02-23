#!/usr/bin/env bash
# memory-compact.sh — Weekly RAG Memory Compaction
#
# Runs weekly (Sunday 9pm MYT) to keep memory.jsonl lean:
# 1. Decay importance by 1 per week since creation
# 2. Deduplicate entries (same agent + first 60 chars of text)
# 3. Purge entries with importance <= 1 that are > 14 days old
# 4. Report stats
#
# Usage: bash memory-compact.sh [--dry-run]
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

MEMORY_FILE="$HOME/.openclaw/workspace/rag/memory.jsonl"
BACKUP_FILE="${MEMORY_FILE}.bak"
LOG="$HOME/.openclaw/logs/rag-memory.log"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

mkdir -p "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMPACT] $1" >> "$LOG"
}

if [ ! -f "$MEMORY_FILE" ]; then
  log "No memory file found at $MEMORY_FILE"
  exit 0
fi

# Get stats before
BEFORE_COUNT=$(wc -l < "$MEMORY_FILE" | tr -d ' ')
BEFORE_SIZE=$(wc -c < "$MEMORY_FILE" | tr -d ' ')

log "=== COMPACTION START === ($BEFORE_COUNT entries, $BEFORE_SIZE bytes)"

# Backup before compaction
cp "$MEMORY_FILE" "$BACKUP_FILE"

python3 - "$MEMORY_FILE" "$DRY_RUN" << 'PYEOF'
import json, sys, os
from datetime import datetime, timezone, timedelta

memory_file = sys.argv[1]
dry_run = sys.argv[2] == "true"

myt = timezone(timedelta(hours=8))
now = datetime.now(myt)
now_str = now.strftime("%Y-%m-%dT%H:%M")

entries = []
parse_errors = 0

# Read all entries
with open(memory_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            if not isinstance(entry, dict):
                parse_errors += 1
                continue
            entries.append(entry)
        except:
            parse_errors += 1
            continue

original_count = len(entries)

# Step 1: Decay importance based on age
for entry in entries:
    ts = entry.get("ts", "")
    if not ts or len(ts) < 10:
        continue
    try:
        # Parse timestamp (format: YYYY-MM-DDTHH:MM or YYYY-MM-DD)
        entry_date = datetime.strptime(ts[:10], "%Y-%m-%d").replace(tzinfo=myt)
        age_days = (now - entry_date).days
        weeks_old = age_days // 7

        original_importance = entry.get("importance", 5)
        # Decay by 1 per week, minimum 0
        decayed = max(0, original_importance - weeks_old)
        entry["importance"] = decayed
    except:
        pass

# Step 2: Deduplicate (same agent + first 60 chars of text)
seen = {}
deduped = []
dup_count = 0

for entry in entries:
    agent = entry.get("agent", "unknown")
    text = entry.get("text", "")[:60].lower().strip()
    key = f"{agent}|{text}"

    if key in seen:
        # Keep the one with higher importance
        existing = seen[key]
        if entry.get("importance", 0) > existing.get("importance", 0):
            # Replace with higher importance version
            deduped = [e for e in deduped if not (e.get("agent","") == agent and e.get("text","")[:60].lower().strip() == text)]
            deduped.append(entry)
            seen[key] = entry
        dup_count += 1
    else:
        seen[key] = entry
        deduped.append(entry)

# Step 3: Purge low-importance old entries
cutoff_date = (now - timedelta(days=14)).strftime("%Y-%m-%d")
purged = []
purge_count = 0

for entry in deduped:
    ts = entry.get("ts", "")
    importance = entry.get("importance", 5)

    # Purge if importance <= 1 AND older than 14 days
    if importance <= 1 and ts[:10] < cutoff_date:
        purge_count += 1
        continue

    purged.append(entry)

# Sort by timestamp (newest first for easier reading)
purged.sort(key=lambda e: e.get("ts", ""), reverse=True)

# Report
print(f"Before: {original_count} entries")
print(f"Parse errors skipped: {parse_errors}")
print(f"Duplicates removed: {dup_count}")
print(f"Low-importance purged: {purge_count}")
print(f"After: {len(purged)} entries")

if not dry_run:
    # Write compacted file
    with open(memory_file, "w") as f:
        for entry in purged:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    print(f"Compacted: {memory_file}")
else:
    print("DRY RUN — no changes written")
PYEOF

# Get stats after
if [ "$DRY_RUN" = "false" ]; then
  AFTER_COUNT=$(wc -l < "$MEMORY_FILE" | tr -d ' ')
  AFTER_SIZE=$(wc -c < "$MEMORY_FILE" | tr -d ' ')
  log "DONE: $BEFORE_COUNT → $AFTER_COUNT entries, $BEFORE_SIZE → $AFTER_SIZE bytes"
else
  log "DRY RUN complete"
fi

log "=== COMPACTION DONE ==="
