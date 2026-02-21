#!/usr/bin/env bash
# memory-search.sh — Search the structured memory store for relevant facts
# Usage: bash memory-search.sh "keyword" [--agent zenni] [--type decision] [--limit 10] [--recent 7]
#        bash memory-search.sh "sales report" --agent athena --limit 5
#        bash memory-search.sh "" --type learning --recent 3   # all learnings from last 3 days
#
# Bash 3.2 compatible (macOS)

set -uo pipefail

MEMORY_FILE="$HOME/.openclaw/workspace/rag/memory.jsonl"

if [ ! -f "$MEMORY_FILE" ]; then
  echo "No memory store found at $MEMORY_FILE" >&2
  exit 0
fi

QUERY="${1:-}"
shift 2>/dev/null || true

AGENT="" TYPE="" LIMIT=10 RECENT=0 FORMAT="human"
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2;;
    --type) TYPE="$2"; shift 2;;
    --limit) LIMIT="$2"; shift 2;;
    --recent) RECENT="$2"; shift 2;;
    --json) FORMAT="json"; shift;;
    *) shift;;
  esac
done

python3 - "$MEMORY_FILE" "$QUERY" "$AGENT" "$TYPE" "$LIMIT" "$RECENT" "$FORMAT" << 'PYEOF'
import sys, json, re
from datetime import datetime, timezone, timedelta

memory_file, query, agent_filter, type_filter, limit, recent_days, fmt = sys.argv[1:8]
limit = int(limit)
recent_days = int(recent_days)

# Calculate date cutoff if --recent specified
cutoff = None
if recent_days > 0:
    myt = timezone(timedelta(hours=8))
    cutoff = (datetime.now(myt) - timedelta(days=recent_days)).strftime("%Y-%m-%d")

results = []
try:
    with open(memory_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                fact = json.loads(line)
            except:
                continue

            # Filter by agent
            if agent_filter and fact.get("agent", "") != agent_filter:
                continue

            # Filter by type
            if type_filter and fact.get("type", "") != type_filter:
                continue

            # Filter by recency
            if cutoff and fact.get("ts", "") < cutoff:
                continue

            # Filter by query (case-insensitive search across text + tags)
            if query:
                search_corpus = (
                    fact.get("text", "") + " " +
                    " ".join(fact.get("tags", [])) + " " +
                    fact.get("type", "")
                ).lower()
                # Check if ALL query words appear in the corpus
                query_words = query.lower().split()
                if not all(w in search_corpus for w in query_words):
                    continue

            results.append(fact)
except FileNotFoundError:
    pass

# Sort by importance (desc), then recency (desc)
# Handle case where results is list or empty
if results and isinstance(results, list):
    results.sort(key=lambda f: (f.get("importance", 5) if isinstance(f, dict) else 5, f.get("ts", "") if isinstance(f, dict) else ""), reverse=True)

# Apply limit
results = results[:limit]

if fmt == "json":
    print(json.dumps(results, indent=2, ensure_ascii=False))
else:
    if not results:
        print("No matching facts found.")
    else:
        for fact in results:
            ts = fact.get("ts", "?")
            agent = fact.get("agent", "?")
            ftype = fact.get("type", "?")
            text = fact.get("text", "")[:200]
            importance = fact.get("importance", 5)
            tags = ",".join(fact.get("tags", []))
            tag_str = f" [{tags}]" if tags else ""
            print(f"[{ts}] ({agent}/{ftype} i={importance}{tag_str}) {text}")
PYEOF
