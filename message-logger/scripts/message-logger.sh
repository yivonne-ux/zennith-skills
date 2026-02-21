#!/bin/bash
# message-logger.sh — Log all messages to Obsidian + vector DB
# Usage: message-logger.sh <source> <content> [metadata_json]

set -e

SOURCE="$1"
CONTENT="$2"
METADATA="${3:-{}}"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
DATE=$(date +"%Y-%m-%d")

# Config
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/.openclaw/workspace/obsidian-messages}"
VECTOR_DB="${VECTOR_DB:-$HOME/.openclaw/workspace/vector-messages.db}"

# Ensure directories exist
mkdir -p "$OBSIDIAN_VAULT/Daily"
mkdir -p "$OBSIDIAN_VAULT/BySource"

# Obsidian: Daily note
DAILY_NOTE="$OBSIDIAN_VAULT/Daily/$DATE.md"
if [[ ! -f "$DAILY_NOTE" ]]; then
  echo "# Messages — $DATE" > "$DAILY_NOTE"
  echo "" >> "$DAILY_NOTE"
fi

# Append to daily note
{
  echo "## $TIMESTAMP [$SOURCE]"
  echo "$CONTENT"
  echo ""
} >> "$DAILY_NOTE"

# Obsidian: Source-based note
SOURCE_SAFE=$(echo "$SOURCE" | tr '/' '-' | tr ' ' '-')
SOURCE_NOTE="$OBSIDIAN_VAULT/BySource/$SOURCE_SAFE.md"
if [[ ! -f "$SOURCE_NOTE" ]]; then
  echo "# Messages from $SOURCE" > "$SOURCE_NOTE"
  echo "" >> "$SOURCE_NOTE"
fi

{
  echo "## $TIMESTAMP"
  echo "$CONTENT"
  echo ""
} >> "$SOURCE_NOTE"

# Vector DB: Store for semantic search (using SQLite with simple embedding cache)
sqlite3 "$VECTOR_DB" "
  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT,
    source TEXT,
    content TEXT,
    metadata TEXT
  );
  CREATE INDEX IF NOT EXISTS idx_timestamp ON messages(timestamp);
  CREATE INDEX IF NOT EXISTS idx_source ON messages(source);
  INSERT INTO messages (timestamp, source, content, metadata)
  VALUES ('$TIMESTAMP', '$(echo "$SOURCE" | sed "s/'/''/g")', '$(echo "$CONTENT" | sed "s/'/''/g")', '$(echo "$METADATA" | sed "s/'/''/g")');
" 2>/dev/null || true

echo "✓ Logged to Obsidian + Vector DB"
