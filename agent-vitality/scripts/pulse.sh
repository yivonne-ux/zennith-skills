#!/usr/bin/env bash
# pulse.sh — Agent Self-Improvement Pulse (Amoeba Heartbeat)
#
# 4-step cycle: REFLECT → LEARN → EVOLVE → SYNC
# Runs every 3 hours per agent (staggered via cron).
#
# Usage: bash pulse.sh <agent_name>
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

AGENT="${1:-}"
if [ -z "$AGENT" ]; then
  echo "Usage: pulse.sh <agent_name>" >&2
  exit 1
fi

SKILLS_DIR="$HOME/.openclaw/skills"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
RAG_STORE="$SKILLS_DIR/rag-memory/scripts/memory-store.sh"
RAG_SEARCH="$SKILLS_DIR/rag-memory/scripts/memory-search.sh"
EVOLVE="$SKILLS_DIR/agent-vitality/scripts/evolve.sh"
LOG="$HOME/.openclaw/logs/agent-vitality.log"
TS=$(date '+%Y-%m-%dT%H:%M:%SZ')

mkdir -p "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PULSE:$AGENT] $1" >> "$LOG"
}

log "=== PULSE START ==="

# ── STEP 1: REFLECT ──────────────────────────────────────
# Read this agent's recent room activity (last 24h)
log "STEP 1: REFLECT"

REFLECT_OUTPUT=""
ROOMS_FOUND=0

# Map agent to their rooms
case "$AGENT" in
  artemis)  AGENT_ROOMS="build townhall" ;;
  athena)   AGENT_ROOMS="exec build" ;;
  dreami)   AGENT_ROOMS="creative exec" ;;
  apollo)   AGENT_ROOMS="creative" ;;
  artee)    AGENT_ROOMS="creative" ;;
  iris)     AGENT_ROOMS="social creative" ;;
  hermes)   AGENT_ROOMS="exec" ;;
  main)     AGENT_ROOMS="exec townhall" ;;
  *)        AGENT_ROOMS="exec townhall" ;;
esac

# Extract this agent's entries from last 24h
YESTERDAY=$(python3 -c "from datetime import datetime, timedelta; print(int((datetime.utcnow() - timedelta(hours=24)).timestamp() * 1000))")

for ROOM in $AGENT_ROOMS; do
  ROOM_FILE="$ROOMS_DIR/${ROOM}.jsonl"
  if [ -f "$ROOM_FILE" ]; then
    # Get entries from this agent in last 24h
    ENTRIES=$(python3 -c "
import json, sys
cutoff = $YESTERDAY
entries = []
for line in open('$ROOM_FILE'):
    line = line.strip()
    if not line: continue
    try:
        e = json.loads(line)
        if not isinstance(e, dict): continue
        if e.get('agent','') == '$AGENT' and e.get('ts', 0) > cutoff:
            msg = e.get('msg', '')[:200]
            entries.append(msg)
    except: continue
for e in entries[-5:]:
    print(e)
" 2>/dev/null || true)

    if [ -n "$ENTRIES" ]; then
      REFLECT_OUTPUT="$REFLECT_OUTPUT
[$ROOM] $ENTRIES"
      ROOMS_FOUND=$((ROOMS_FOUND + 1))
    fi
  fi
done

if [ "$ROOMS_FOUND" -eq 0 ]; then
  log "REFLECT: No recent activity found in rooms — skipping pulse"
  log "=== PULSE COMPLETE (no activity) ==="
  exit 0
fi

log "REFLECT: Found activity in $ROOMS_FOUND rooms"

# ── STEP 2: LEARN ─────────────────────────────────────────
# Extract learnings from the reflected activity and store in RAG
log "STEP 2: LEARN"

# Use python to extract a one-line learning from the activity
LEARNING=$(python3 -c "
import sys
activity = '''$REFLECT_OUTPUT'''
lines = [l.strip() for l in activity.strip().split('\n') if l.strip()]
if not lines:
    sys.exit(0)
# Summarize: take the most substantive line as learning seed
best = max(lines, key=len)
# Clean and cap
best = best.replace('[exec]', '').replace('[build]', '').replace('[creative]', '').replace('[social]', '').replace('[townhall]', '').strip()
if len(best) > 200:
    best = best[:197] + '...'
if best:
    print(best)
" 2>/dev/null || true)

if [ -n "$LEARNING" ] && [ -f "$RAG_STORE" ]; then
  # Check for duplicate before storing
  EXISTING=$(bash "$RAG_SEARCH" "" --agent "$AGENT" --type learning --recent 1 --limit 3 2>/dev/null || true)
  # Simple dedup: if the first 40 chars match any recent learning, skip
  LEARN_KEY=$(echo "$LEARNING" | cut -c1-40)
  if echo "$EXISTING" | grep -qi "$(echo "$LEARN_KEY" | head -c 20)" 2>/dev/null; then
    log "LEARN: Duplicate detected — skipping store"
  else
    bash "$RAG_STORE" --agent "$AGENT" --type learning --tags "self-improve,pulse" --importance 7 --text "$LEARNING" 2>/dev/null
    log "LEARN: Stored learning — ${LEARNING:0:80}"
  fi
else
  log "LEARN: No learning extracted or RAG store unavailable"
fi

# ── STEP 3: EVOLVE ────────────────────────────────────────
# Update SOUL.md Living Learnings section from RAG memory
log "STEP 3: EVOLVE"

if [ -f "$EVOLVE" ]; then
  bash "$EVOLVE" "$AGENT" 2>/dev/null
  log "EVOLVE: Updated SOUL.md Living Learnings"
else
  log "EVOLVE: evolve.sh not found at $EVOLVE"
fi

# ── STEP 4: SYNC ──────────────────────────────────────────
# Read team's recent learnings — look for cross-applicable insights
log "STEP 4: SYNC"

if [ -f "$RAG_SEARCH" ]; then
  # Get recent learnings from OTHER agents (not self)
  TEAM_LEARNINGS=$(bash "$RAG_SEARCH" "" --type learning --recent 1 --limit 10 2>/dev/null || true)

  # Filter out own learnings and find relevant ones
  RELEVANT=$(python3 -c "
import sys

# Agent expertise mapping — what learnings are relevant to whom
RELEVANCE = {
    'artemis': ['research', 'scraping', 'competitive', 'trends', 'scout'],
    'athena':  ['analytics', 'sales', 'performance', 'ROI', 'metrics', 'forecast'],
    'dreami':  ['brief', 'campaign', 'brand', 'creative direction', 'review'],
    'apollo':  ['copy', 'headline', 'hook', 'caption', 'voice', 'tone'],
    'artee':   ['visual', 'image', 'design', 'style', 'photo', 'color'],
    'iris':    ['social', 'engagement', 'post', 'reel', 'community'],
    'hermes':  ['pricing', 'margin', 'channel', 'promotion', 'deal', 'ads'],
    'main':    ['delegation', 'routing', 'orchestration', 'workflow'],
}

agent = '$AGENT'
keywords = RELEVANCE.get(agent, [])
team_learnings = '''$TEAM_LEARNINGS'''

relevant = []
for line in team_learnings.strip().split('\n'):
    line = line.strip()
    if not line or '/$AGENT/' in line.lower():
        continue  # skip own learnings
    if '($AGENT/' in line:
        continue
    # Check relevance
    lower = line.lower()
    for kw in keywords:
        if kw in lower:
            relevant.append(line[:150])
            break

if relevant:
    print('\n'.join(relevant[:3]))
" 2>/dev/null || true)

  if [ -n "$RELEVANT" ]; then
    log "SYNC: Found relevant team learnings"
    # Post a sync note to feedback room
    printf '{"ts":%s000,"agent":"%s","room":"feedback","type":"sync","msg":"[PULSE SYNC] %s absorbed team learnings"}\n' \
      "$(date +%s)" "$AGENT" "$AGENT" >> "$ROOMS_DIR/feedback.jsonl" 2>/dev/null
  else
    log "SYNC: No relevant team learnings found"
  fi
else
  log "SYNC: RAG search unavailable"
fi

log "=== PULSE COMPLETE ==="
