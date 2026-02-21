#!/usr/bin/env bash
# evolve.sh — Standalone SOUL Evolution Engine
#
# Updates an agent's SOUL.md "Living Learnings" section from RAG memory.
# Can be called directly or used by pulse.sh.
#
# Usage: bash evolve.sh <agent_name>
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

AGENT="${1:-}"
if [ -z "$AGENT" ]; then
  echo "Usage: evolve.sh <agent_name>" >&2
  exit 1
fi

SKILLS_DIR="$HOME/.openclaw/skills"
RAG_SEARCH="$SKILLS_DIR/rag-memory/scripts/memory-search.sh"
SOUL_FILE="$HOME/.openclaw/workspace-${AGENT}/SOUL.md"
LOG="$HOME/.openclaw/logs/agent-vitality.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [EVOLVE:$AGENT] $1" >> "$LOG"
}

if [ ! -f "$SOUL_FILE" ]; then
  log "No SOUL.md found at $SOUL_FILE"
  exit 0
fi

# Ensure Living Learnings section exists
if ! grep -q "## Living Learnings" "$SOUL_FILE" 2>/dev/null; then
  cat >> "$SOUL_FILE" << 'EOF'

## Living Learnings

_This section evolves automatically. The pulse system adds learnings from your work._
_Oldest learnings get archived to RAG memory when this section exceeds 20 items._

<!-- LEARNINGS_START -->
<!-- LEARNINGS_END -->
EOF
  log "Added Living Learnings section"
fi

# Pull recent learnings from RAG memory
LEARNINGS=""
if [ -f "$RAG_SEARCH" ]; then
  LEARNINGS=$(bash "$RAG_SEARCH" "" --agent "$AGENT" --type learning --recent 14 2>/dev/null || true)
fi

if [ -z "$LEARNINGS" ]; then
  log "No learnings to inject"
  exit 0
fi

# Build and inject learnings block
python3 - "$SOUL_FILE" << 'PYEOF'
import sys, os

soul_path = sys.argv[1]
agent = os.path.basename(os.path.dirname(soul_path)).replace('workspace-', '')

# Read RAG learnings from the search
rag_search = os.path.expanduser(f"~/.openclaw/skills/rag-memory/scripts/memory-search.sh")
import subprocess
result = subprocess.run(
    ["bash", rag_search, "", "--agent", agent, "--type", "learning", "--recent", "14"],
    capture_output=True, text=True, timeout=10
)

learnings = []
seen = set()
for line in result.stdout.strip().split('\n'):
    line = line.strip()
    if not line: continue
    # Deduplicate by first 40 chars
    key = line[:40].lower()
    if key in seen: continue
    seen.add(key)
    if not line.startswith('- '):
        line = '- ' + line
    learnings.append(line)

if not learnings:
    print("No learnings to inject")
    sys.exit(0)

# Cap at 20
learnings = learnings[:20]

with open(soul_path) as f:
    content = f.read()

start_marker = '<!-- LEARNINGS_START -->'
end_marker = '<!-- LEARNINGS_END -->'

if start_marker in content and end_marker in content:
    before = content[:content.index(start_marker) + len(start_marker)]
    after = content[content.index(end_marker):]
    new_content = before + '\n' + '\n'.join(learnings) + '\n' + after

    with open(soul_path, 'w') as f:
        f.write(new_content)
    print(f"Injected {len(learnings)} learnings into {soul_path}")
else:
    print("Markers not found in SOUL.md")
PYEOF

log "Evolution complete"
