#!/usr/bin/env bash
# memory-store.sh — Store a tagged fact in the structured memory store
# Usage: bash memory-store.sh --agent zenni --type decision --tags "sales,report" --text "..." [--importance 6]
#    or: echo "fact text" | bash memory-store.sh --agent zenni --type learning
#
# Bash 3.2 compatible (macOS)

set -uo pipefail

MEMORY_FILE="$HOME/.openclaw/workspace/rag/memory.jsonl"
MAX_SIZE=10485760  # 10MB cap

AGENT="" TYPE="" TAGS="" TEXT="" IMPORTANCE=6
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2;;
    --type) TYPE="$2"; shift 2;;
    --tags) TAGS="$2"; shift 2;;
    --text) TEXT="$2"; shift 2;;
    --importance) IMPORTANCE="$2"; shift 2;;
    *) shift;;
  esac
done

# Read from stdin if no --text
if [ -z "$TEXT" ]; then
  TEXT=$(cat)
fi

# Validate required fields
if [ -z "$TEXT" ]; then
  echo "ERROR: --text is required (or pipe via stdin)" >&2
  exit 1
fi
if [ -z "$AGENT" ]; then
  AGENT="unknown"
fi
if [ -z "$TYPE" ]; then
  TYPE="note"
fi

# Check file size
if [ -f "$MEMORY_FILE" ]; then
  FILE_SIZE=$(wc -c < "$MEMORY_FILE" | tr -d ' ')
  if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
    echo "WARN: memory.jsonl exceeds 10MB ($FILE_SIZE bytes). Run memory-compact.sh" >&2
  fi
fi

# Build and append JSONL entry
python3 - "$MEMORY_FILE" "$AGENT" "$TYPE" "$TAGS" "$TEXT" "$IMPORTANCE" << 'PYEOF'
import sys, json, os
from datetime import datetime, timezone, timedelta

memory_file, agent, fact_type, tags_str, text, importance = sys.argv[1:7]

# Parse tags
tags = [t.strip() for t in tags_str.split(",") if t.strip()] if tags_str else []

# Build fact
myt = timezone(timedelta(hours=8))
ts = datetime.now(myt).strftime("%Y-%m-%dT%H:%M")

fact = {
    "ts": ts,
    "agent": agent,
    "type": fact_type,
    "tags": tags,
    "text": text.strip()[:2000],  # cap at 2000 chars
    "importance": int(importance)
}

# Append
os.makedirs(os.path.dirname(memory_file), exist_ok=True)
with open(memory_file, "a") as f:
    f.write(json.dumps(fact, ensure_ascii=False) + "\n")

print(f"Stored: [{ts}] ({agent}/{fact_type}) {text.strip()[:80]}...")
PYEOF
