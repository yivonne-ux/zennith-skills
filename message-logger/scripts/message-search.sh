#!/bin/bash
# message-search.sh — Search messages via Obsidian or Vector DB
# Usage: message-search.sh <query> [--obsidian|--vector|--all]

set -e

QUERY="$1"
MODE="${2:---all}"
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/.openclaw/workspace/obsidian-messages}"
VECTOR_DB="${VECTOR_DB:-$HOME/.openclaw/workspace/vector-messages.db}"

echo "🔍 Searching for: $QUERY"
echo ""

if [[ "$MODE" == "--obsidian" ]] || [[ "$MODE" == "--all" ]]; then
  echo "=== Obsidian Search ==="
  if command -v rg &>/dev/null; then
    rg -i "$QUERY" "$OBSIDIAN_VAULT" --type md -C 2 2>/dev/null | head -50 || echo "No Obsidian results"
  else
    grep -ri "$QUERY" "$OBSIDIAN_VAULT" --include="*.md" 2>/dev/null | head -20 || echo "No Obsidian results"
  fi
  echo ""
fi

if [[ "$MODE" == "--vector" ]] || [[ "$MODE" == "--all" ]]; then
  echo "=== Vector DB Search ==="
  if [[ -f "$VECTOR_DB" ]]; then
    sqlite3 "$VECTOR_DB" "
      SELECT timestamp, source, substr(content, 1, 200) 
      FROM messages 
      WHERE content LIKE '%$(echo "$QUERY" | sed "s/'/''/g")%' 
      ORDER BY timestamp DESC 
      LIMIT 20;
    " 2>/dev/null | column -t -s '|' || echo "No Vector DB results"
  else
    echo "Vector DB not found at $VECTOR_DB"
  fi
  echo ""
fi

echo "✓ Search complete"
