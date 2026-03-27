#!/bin/bash
# context-audit.sh — Token context audit for any GAIA OS agent
# Usage: bash context-audit.sh <agent-id>
# Estimates token consumption across identity, skills, memory, session, and tools.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
OPENCLAW_DIR="$HOME/.openclaw"
WARN_THRESHOLD=70  # percent of context window

# Model context windows (tokens). Add new models here as needed.
declare_window() {
  # Bash 3.2 compat — no associative arrays
  case "$1" in
    gpt-5.4)          echo 1000000 ;;
    gpt-4.1)          echo 1000000 ;;
    gemini-3.1-pro*)  echo 2000000 ;;
    gemini-3-flash*)  echo 1000000 ;;
    claude-opus-4*)   echo 200000 ;;
    claude-sonnet-4*) echo 200000 ;;
    o3|o4-mini)       echo 200000 ;;
    *)                echo 200000 ;;  # conservative default
  esac
}

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
if [ -z "${1:-}" ]; then
  echo "Usage: context-audit.sh <agent-id>"
  echo "  e.g. context-audit.sh scout"
  exit 1
fi

AGENT_ID="$1"
WORKSPACE="$OPENCLAW_DIR/workspace-$AGENT_ID"

if [ ! -d "$WORKSPACE" ]; then
  echo "ERROR: Workspace not found at $WORKSPACE"
  exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
chars_to_tokens() {
  # Rough estimate: 1 token ≈ 4 chars (English text average)
  local chars="$1"
  echo $(( chars / 4 ))
}

file_tokens() {
  local path="$1"
  if [ -f "$path" ]; then
    local chars
    # macOS wc -c has leading spaces — trim with tr
    chars=$(wc -c < "$path" | tr -d ' ')
    chars_to_tokens "$chars"
  else
    echo 0
  fi
}

dir_tokens() {
  # Sum tokens for all files matching a glob in a directory
  local dir="$1"
  local pattern="${2:-*}"
  local total=0
  if [ -d "$dir" ]; then
    for f in "$dir"/$pattern; do
      [ -f "$f" ] || continue
      local t
      t=$(file_tokens "$f")
      total=$(( total + t ))
    done
  fi
  echo "$total"
}

# ---------------------------------------------------------------------------
# Detect model
# ---------------------------------------------------------------------------
MODEL="unknown"
if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
  # Try to extract model for this agent (lightweight jq-free parse)
  if command -v python3 &>/dev/null; then
    MODEL=$(python3 -c "
import json, sys
try:
    cfg = json.load(open('$OPENCLAW_DIR/openclaw.json'))
    agents = cfg.get('agents', [])
    for a in agents:
        if a.get('id') == '$AGENT_ID':
            print(a.get('model', a.get('defaultModel', 'unknown')))
            sys.exit(0)
    print('unknown')
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")
  fi
fi

CONTEXT_WINDOW=$(declare_window "$MODEL")

# ---------------------------------------------------------------------------
# Collect sizes
# ---------------------------------------------------------------------------

# Category: Identity
SOUL_TOKENS=$(file_tokens "$WORKSPACE/SOUL.md")
HEARTBEAT_TOKENS=$(file_tokens "$WORKSPACE/HEARTBEAT.md")
IDENTITY_TOKENS=$(( SOUL_TOKENS + HEARTBEAT_TOKENS ))

# Also check for other identity files
for idfile in IDENTITY.md AGENTS.md USER.md BOOTSTRAP.md; do
  if [ -f "$WORKSPACE/$idfile" ]; then
    t=$(file_tokens "$WORKSPACE/$idfile")
    IDENTITY_TOKENS=$(( IDENTITY_TOKENS + t ))
  fi
done

# Category: Shared protocol
SHARED_TOKENS=$(file_tokens "$OPENCLAW_DIR/workspace/SHARED-PROTOCOL.md")

# Category: Skills (loaded SKILL.md files — check workspace for symlinks/copies)
SKILL_TOKENS=0
SKILL_DETAILS=""
if [ -d "$OPENCLAW_DIR/skills" ]; then
  for skill_dir in "$OPENCLAW_DIR/skills"/*/; do
    skill_file="$skill_dir/SKILL.md"
    if [ -f "$skill_file" ]; then
      t=$(file_tokens "$skill_file")
      skill_name=$(basename "$skill_dir")
      SKILL_TOKENS=$(( SKILL_TOKENS + t ))
      SKILL_DETAILS="${SKILL_DETAILS}    ${skill_name}: ${t} tokens\n"
    fi
  done
fi

# Category: Memory
MEMORY_TOKENS=0
if [ -d "$WORKSPACE/memory" ]; then
  MEMORY_TOKENS=$(dir_tokens "$WORKSPACE/memory" "*.md")
  # Also check for json memory files
  json_mem=$(dir_tokens "$WORKSPACE/memory" "*.json")
  MEMORY_TOKENS=$(( MEMORY_TOKENS + json_mem ))
fi

# Category: Sessions / Rooms
SESSION_TOKENS=0
if [ -d "$WORKSPACE/sessions" ]; then
  for sf in "$WORKSPACE/sessions"/*; do
    [ -f "$sf" ] || continue
    t=$(file_tokens "$sf")
    SESSION_TOKENS=$(( SESSION_TOKENS + t ))
  done
fi

ROOM_TOKENS=0
if [ -d "$OPENCLAW_DIR/workspace/rooms" ]; then
  for rf in "$OPENCLAW_DIR/workspace/rooms"/*.jsonl; do
    [ -f "$rf" ] || continue
    t=$(file_tokens "$rf")
    ROOM_TOKENS=$(( ROOM_TOKENS + t ))
  done
fi

# Category: Tools (TOOLS.md if present)
TOOLS_TOKENS=$(file_tokens "$WORKSPACE/TOOLS.md")

# Category: Knowledge sync
KNOWLEDGE_TOKENS=0
if [ -f "$WORKSPACE/KNOWLEDGE-SYNC.md" ]; then
  KNOWLEDGE_TOKENS=$(file_tokens "$WORKSPACE/KNOWLEDGE-SYNC.md")
fi

# ---------------------------------------------------------------------------
# Totals
# ---------------------------------------------------------------------------
TOTAL_TOKENS=$(( IDENTITY_TOKENS + SHARED_TOKENS + SKILL_TOKENS + MEMORY_TOKENS + SESSION_TOKENS + ROOM_TOKENS + TOOLS_TOKENS + KNOWLEDGE_TOKENS ))
UTIL_PERCENT=0
if [ "$CONTEXT_WINDOW" -gt 0 ]; then
  UTIL_PERCENT=$(( TOTAL_TOKENS * 100 / CONTEXT_WINDOW ))
fi

# ---------------------------------------------------------------------------
# Find top 3 consumers
# ---------------------------------------------------------------------------
# Build a sortable list: "tokens category"
TOP_LIST=$(cat <<TOPEOF
$IDENTITY_TOKENS Identity (SOUL.md + HEARTBEAT.md + extras)
$SHARED_TOKENS Shared Protocol
$SKILL_TOKENS Skills (all SKILL.md files)
$MEMORY_TOKENS Memory
$SESSION_TOKENS Sessions
$ROOM_TOKENS Rooms
$TOOLS_TOKENS Tools (TOOLS.md)
$KNOWLEDGE_TOKENS Knowledge Sync
TOPEOF
)

TOP3=$(echo "$TOP_LIST" | sort -t' ' -k1 -rn | head -3)

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo "================================================================"
echo "  CONTEXT AUDIT: agent=$AGENT_ID  model=$MODEL"
echo "================================================================"
echo ""
echo "Context Window:  $(printf "%'d" $CONTEXT_WINDOW) tokens"
echo "Total Estimated: $(printf "%'d" $TOTAL_TOKENS) tokens  (${UTIL_PERCENT}%)"
echo ""
echo "--- Breakdown by Category ---"
printf "  %-25s %'8d tokens\n" "Identity" "$IDENTITY_TOKENS"
printf "    %-23s %'8d\n" "SOUL.md" "$SOUL_TOKENS"
printf "    %-23s %'8d\n" "HEARTBEAT.md" "$HEARTBEAT_TOKENS"
printf "  %-25s %'8d tokens\n" "Shared Protocol" "$SHARED_TOKENS"
printf "  %-25s %'8d tokens\n" "Skills (all)" "$SKILL_TOKENS"
printf "  %-25s %'8d tokens\n" "Memory" "$MEMORY_TOKENS"
printf "  %-25s %'8d tokens\n" "Sessions" "$SESSION_TOKENS"
printf "  %-25s %'8d tokens\n" "Rooms" "$ROOM_TOKENS"
printf "  %-25s %'8d tokens\n" "Tools (TOOLS.md)" "$TOOLS_TOKENS"
printf "  %-25s %'8d tokens\n" "Knowledge Sync" "$KNOWLEDGE_TOKENS"
echo ""
echo "--- Top 3 Consumers ---"
echo "$TOP3" | while read -r tok rest; do
  printf "  %'8d tokens  %s\n" "$tok" "$rest"
done
echo ""

# ---------------------------------------------------------------------------
# Warnings
# ---------------------------------------------------------------------------
if [ "$UTIL_PERCENT" -ge "$WARN_THRESHOLD" ]; then
  echo "!! WARNING: Context utilization is ${UTIL_PERCENT}% (>= ${WARN_THRESHOLD}% threshold)"
  echo "   Model: $MODEL  Window: $(printf "%'d" $CONTEXT_WINDOW) tokens"
  echo "   Action: Apply compaction, observation masking, or progressive disclosure."
  echo ""
fi

# ---------------------------------------------------------------------------
# Recommendations
# ---------------------------------------------------------------------------
echo "--- Recommendations ---"
RECS=0

if [ "$SOUL_TOKENS" -gt 4000 ]; then
  echo "  * SOUL.md is ${SOUL_TOKENS} tokens — consider splitting to a compact version"
  echo "    (keep core identity < 2K tokens, move reference material to loadable sections)"
  RECS=$(( RECS + 1 ))
fi

if [ "$HEARTBEAT_TOKENS" -gt 2000 ]; then
  echo "  * HEARTBEAT.md is ${HEARTBEAT_TOKENS} tokens — prune stale status entries"
  RECS=$(( RECS + 1 ))
fi

if [ "$SHARED_TOKENS" -gt 3000 ]; then
  echo "  * SHARED-PROTOCOL.md is ${SHARED_TOKENS} tokens — move infrequent rules to a loadable appendix"
  RECS=$(( RECS + 1 ))
fi

if [ "$SKILL_TOKENS" -gt 20000 ]; then
  echo "  * Total skills consume ${SKILL_TOKENS} tokens — enforce progressive disclosure (L1/L2/L3)"
  echo "    Only load full SKILL.md on activation; keep L1 metadata in SOUL.md"
  RECS=$(( RECS + 1 ))
fi

if [ "$MEMORY_TOKENS" -gt 5000 ]; then
  echo "  * Memory files total ${MEMORY_TOKENS} tokens — run memory compaction or prune old entries"
  RECS=$(( RECS + 1 ))
fi

if [ "$SESSION_TOKENS" -gt 10000 ]; then
  echo "  * Active sessions consume ${SESSION_TOKENS} tokens — consider session pruning"
  RECS=$(( RECS + 1 ))
fi

if [ "$ROOM_TOKENS" -gt 10000 ]; then
  echo "  * Room files total ${ROOM_TOKENS} tokens — archive completed room conversations"
  RECS=$(( RECS + 1 ))
fi

if [ "$TOOLS_TOKENS" -gt 3000 ]; then
  echo "  * TOOLS.md is ${TOOLS_TOKENS} tokens — consolidate tool definitions or lazy-load"
  RECS=$(( RECS + 1 ))
fi

if [ "$KNOWLEDGE_TOKENS" -gt 3000 ]; then
  echo "  * KNOWLEDGE-SYNC.md is ${KNOWLEDGE_TOKENS} tokens — archive older sync entries"
  RECS=$(( RECS + 1 ))
fi

if [ "$RECS" -eq 0 ]; then
  echo "  Context usage looks healthy. No immediate action needed."
fi

echo ""
echo "================================================================"
echo "  Tip: Run this after skill activations or long sessions to"
echo "  catch context bloat before it degrades output quality."
echo "================================================================"
