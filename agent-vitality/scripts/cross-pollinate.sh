#!/usr/bin/env bash
# cross-pollinate.sh — Daily Team Learning Spread
#
# Reads ALL agents' recent learnings from RAG memory.
# Routes relevant learnings to other agents' rooms.
# Prevents duplicates via dedup log.
#
# Runs daily at 11pm MYT (3pm UTC) via cron.
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SKILLS_DIR="$HOME/.openclaw/skills"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
RAG_SEARCH="$SKILLS_DIR/rag-memory/scripts/memory-search.sh"
LOG="$HOME/.openclaw/logs/agent-vitality.log"
DEDUP_FILE="$HOME/.openclaw/logs/cross-pollinate-dedup.log"
TMP_LEARNINGS="/tmp/cross-pollinate-learnings-$$.json"

mkdir -p "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [CROSS-POLLINATE] $1" >> "$LOG"
}

cleanup() {
  rm -f "$TMP_LEARNINGS"
}
trap cleanup EXIT

log "=== CROSS-POLLINATION START ==="

if [ ! -f "$RAG_SEARCH" ]; then
  log "ERROR: memory-search.sh not found"
  exit 1
fi

# Clean dedup log older than 7 days
if [ -f "$DEDUP_FILE" ]; then
  WEEK_AGO=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d'))")
  python3 -c "
import sys
cutoff = '$WEEK_AGO'
kept = []
try:
    for line in open('$DEDUP_FILE'):
        if line[:10] >= cutoff:
            kept.append(line)
    with open('$DEDUP_FILE', 'w') as f:
        f.writelines(kept)
except: pass
" 2>/dev/null || true
fi

# Get all learnings from last 24h across all agents → save to temp file
bash "$RAG_SEARCH" "" --type learning --recent 1 --limit 50 --json > "$TMP_LEARNINGS" 2>/dev/null || echo "[]" > "$TMP_LEARNINGS"

# Route learnings to relevant agents
python3 - "$TMP_LEARNINGS" "$ROOMS_DIR" "$DEDUP_FILE" "$LOG" << 'PYEOF'
import json, os, sys
from datetime import datetime

learnings_file, rooms_dir, dedup_file, log_file = sys.argv[1:5]

# Load learnings from temp file
try:
    with open(learnings_file) as f:
        learnings = json.load(f)
except:
    learnings = []

if not learnings:
    with open(log_file, "a") as lf:
        ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        lf.write(f"[{ts}] [CROSS-POLLINATE] No learnings found in last 24h\n")
    sys.exit(0)

# Load dedup set
seen = set()
if os.path.exists(dedup_file):
    with open(dedup_file) as f:
        for line in f:
            seen.add(line.strip())

# Routing matrix: what keywords route to which agent's room
ROUTING = {
    "artemis": {
        "keywords": ["research", "scraping", "competitive", "trends", "scout", "source", "data collection"],
        "room": "build"
    },
    "athena": {
        "keywords": ["analytics", "sales", "performance", "ROI", "metrics", "forecast", "revenue", "conversion"],
        "room": "exec"
    },
    "dreami": {
        "keywords": ["brief", "campaign", "brand", "creative direction", "review", "strategy", "copy", "headline", "hook", "caption", "voice", "tone", "CTA", "writing"],
        "room": "creative"
    },
    "iris": {
        "keywords": ["social", "engagement", "post", "reel", "community", "instagram", "tiktok", "visual", "image", "design", "style", "photo", "color", "layout", "graphic"],
        "room": "social"
    },
    "hermes": {
        "keywords": ["pricing", "margin", "channel", "promotion", "deal", "ads", "shopee", "lazada", "budget"],
        "room": "exec"
    },
}

routed = 0
new_dedup = []

for learning in learnings:
    if not isinstance(learning, dict):
        continue

    source_agent = learning.get("agent", "")
    text = learning.get("text", "")
    ts = learning.get("ts", "")

    if not text:
        continue

    # Dedup key: first 50 chars of text
    dedup_key = f"{ts}|{text[:50]}"
    if dedup_key in seen:
        continue

    text_lower = text.lower()

    # Route to each relevant agent (excluding the source)
    for target_agent, config in ROUTING.items():
        if target_agent == source_agent:
            continue

        # Check keyword match
        matched = False
        for kw in config["keywords"]:
            if kw in text_lower:
                matched = True
                break

        if matched:
            room = config["room"]
            room_file = os.path.join(rooms_dir, f"{room}.jsonl")

            entry = {
                "ts": int(datetime.now().timestamp() * 1000),
                "agent": "vitality",
                "room": room,
                "type": "cross-pollinate",
                "to": target_agent,
                "msg": f"[LEARNING from {source_agent}] {text[:200]}"
            }

            with open(room_file, "a") as f:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")

            routed += 1

    # Mark as processed
    new_dedup.append(dedup_key)
    seen.add(dedup_key)

# Save dedup log
with open(dedup_file, "a") as f:
    for key in new_dedup:
        f.write(key + "\n")

ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
with open(log_file, "a") as lf:
    lf.write(f"[{ts}] [CROSS-POLLINATE] Routed {routed} learnings from {len(learnings)} total\n")

print(f"Cross-pollinated: {routed} routes from {len(learnings)} learnings")
PYEOF

log "=== CROSS-POLLINATION DONE ==="
