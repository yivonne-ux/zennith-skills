---
name: session-lifecycle-manager
version: "2.0.0"
description: Intelligent session memory management with proactive compaction, subagent cleanup, and token optimization. Prevents session bloat before watchdog reset.
metadata:
  openclaw:
    scope: infrastructure
    guardrails:
      - Always backup session before compaction
      - Never delete subagent session files (compress instead)
      - Extract key decisions before any session modification
      - Maintain audit trail of all compaction actions
---

# Session Lifecycle Manager v2.0

## The Problem

Current state: Watchdog resets bloated sessions at 90% (235K tokens)
- ❌ Reactive: Waits until crisis
- ❌ Disruptive: Loses context on reset
- ❌ Inefficient: No proactive management
- ❌ Subagent leak: Spawned agents accumulate forever

## The Solution

Proactive, tiered session lifecycle management:

```
Token Usage
    │
262K├─────────────────────────┬── [CRITICAL] Emergency reset
    │                         │    (watchdog backup + extract)
    │
200K├───────────────────┬───┘     [WARNING] Proactive compaction
    │                   │          Summarize + archive old turns
    │
150K├─────────────┬─────┘         [MONITOR] Increase vigilance
    │             │                Flush decisions after each turn
    │
100K├──────┬──────┘               [NORMAL] Standard operation
    │      │
  0├──────┘
    └─────────────────────────────
```

## Three-Tier Strategy

### Tier 1: Prevention (Every Session)

**After every substantial exchange:**
```javascript
if (contextUsage > 50%) {
  // Write key decisions to memory
  flushToDailyNotes({
    decisions: extractDecisions(lastTurn),
    actionItems: extractTODOs(lastTurn),
    openQuestions: extractOpenLoops(lastTurn)
  });
}
```

### Tier 2: Proactive Compaction (70-80%)

**When approaching limits:**
1. Extract conversation summary
2. Archive full session to compressed storage
3. Create "compressed session" with:
   - Original context + system prompt
   - Summary of completed work
   - Active decisions pending
   - Open action items
4. Continue with compressed context

### Tier 3: Emergency Recovery (90%+)

**When watchdog triggers:**
1. Pre-reset extraction (session-recall already does this)
2. Archive to long-term storage
3. Reset with compressed summary
4. Auto-resume notification

## Subagent Lifecycle Fix

### Current Problem
```
Spawn subagent → Work completes → Session stays forever
(repeat 100x = 100 stale sessions)
```

### Solution: Auto-cleanup Pipeline
```
Spawn subagent ──→ Work completes ──→ Extract result ──→ Compress ──→ Archive ──→ Delete after 7 days
```

### Subagent Policy
| Age | Action |
|-----|--------|
| < 1 hour | Keep (might need follow-up) |
| 1-24 hours | Compress if completed |
| > 24 hours | Archive and delete |
| > 7 days | Purge archives (configurable) |

## Implementation

### Core Script: `session-manager.sh`

```bash
#!/usr/bin/env bash
# session-lifecycle-manager

SESSIONS_FILE="$HOME/.openclaw/agents/main/sessions/sessions.json"
SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
ARCHIVE_DIR="$HOME/.openclaw/agents/main/sessions/archive"
MEMORY_DIR="$HOME/.openclaw/workspace/memory"

# Thresholds (matching 202K context windows)
TIER1_THRESHOLD=101000    # 50% of 202K - Prevention flush
TIER2_THRESHOLD=141000    # 70% of 202K - Proactive compaction start
TIER3_THRESHOLD=162000    # 80% of 202K - Emergency compaction

mkdir -p "$ARCHIVE_DIR"

# Function: Get session token count
get_session_tokens() {
  local session_key="$1"
  jq -r --arg key "$session_key" '.[$key].totalTokens // 0' "$SESSIONS_FILE"
}

# Function: Compress session (Tier 2)
compress_session() {
  local session_key="$1"
  local session_id=$(echo "$session_key" | md5sum | cut -d' ' -f1)
  local jsonl_file="$SESSIONS_DIR/${session_id}.jsonl"
  
  echo "Compressing session: $session_key"
  
  # Extract key information
  local summary=$(extract_session_summary "$jsonl_file")
  local decisions=$(extract_decisions "$jsonl_file")
  
  # Create compressed record
  cat > "$ARCHIVE_DIR/${session_id}-compressed.json" << EOF
{
  "originalSession": "$session_key",
  "compressedAt": "$(date -Iseconds)",
  "summary": $summary,
  "keyDecisions": $decisions,
  "compressionRatio": "~80%"
}
EOF
  
  # Archive original
  gzip -c "$jsonl_file" > "$ARCHIVE_DIR/${session_id}.jsonl.gz"
  rm "$jsonl_file"
  
  echo "  ✓ Compressed and archived"
}

# Function: Cleanup subagent sessions
cleanup_subagents() {
  echo "Scanning subagent sessions..."
  
  local now=$(date +%s)
  local cutoff=$((now - 86400))  # 24 hours ago
  
  jq -r 'to_entries[] | select(.key | contains(":subagent:")) | .key' "$SESSIONS_FILE" | \
  while read -r session_key; do
    local last_activity=$(jq -r --arg key "$session_key" '.[$key].lastActivity // 0' "$SESSIONS_FILE")
    
    if [ "$last_activity" -lt "$cutoff" ]; then
      echo "  Archiving stale subagent: $session_key"
      archive_subagent "$session_key"
    fi
  done
}

# Main execution
echo "=== Session Lifecycle Manager ==="
echo "Time: $(date)"

# Check all sessions
jq -r 'to_entries[] | "\(.key)|\(.value.totalTokens // 0)"' "$SESSIONS_FILE" | \
while IFS='|' read -r session_key tokens; do
  if [ "$tokens" -gt "$TIER3_THRESHOLD" ]; then
    echo "⚠️  CRITICAL: $session_key ($tokens tokens)"
    compress_session "$session_key"
  elif [ "$tokens" -gt "$TIER2_THRESHOLD" ]; then
    echo "⚡ WARNING: $session_key ($tokens tokens)"
    # Queue for proactive compaction
  elif [ "$tokens" -gt "$TIER1_THRESHOLD" ]; then
    echo "📊 MONITOR: $session_key ($tokens tokens)"
  fi
done

# Cleanup old subagents
cleanup_subagents

echo "=== Complete ==="
```

## Integration Points

### 1. Pre-Compaction Flush
Hook into OpenClaw before compaction:
```javascript
// In agent's message handler
if (session.tokens > TIER1_THRESHOLD) {
  await sessionManager.flushDecisions();
}
```

### 2. Subagent Cleanup Cron
```json
{
  "id": "subagent-cleanup",
  "schedule": "0 */6 * * *",
  "command": "bash ~/.openclaw/skills/session-lifecycle-manager/scripts/cleanup-subagents.sh",
  "description": "Clean up completed subagent sessions every 6 hours"
}
```

### 3. Session Size Alert
```javascript
// Alert when sessions growing fast
if (session.growthRate > tokensPerHour) {
  alertToRoom('feedback', {
    type: 'session_growth_warning',
    session: session.key,
    growthRate: session.growthRate,
    recommendation: 'Consider session compaction'
  });
}
```

## Compression Strategy

### What to Keep (Compressed Session)
1. **System context** — Always preserve
2. **Recent context** — Last 10 turns
3. **Key decisions** — Extracted summary
4. **Open items** — TODOs, pending questions
5. **Tool definitions** — Current skill set

### What to Archive (Full History)
1. Complete conversation log
2. All tool calls and results
3. Intermediate reasoning
4. Full context before compression

### Compression Format
```json
{
  "compressedSession": {
    "originalTokens": 200000,
    "compressedTokens": 40000,
    "compressionRatio": 0.8,
    "preservedContext": [
      { "role": "system", "content": "..." },
      { "role": "user", "content": "...", "summary": "Initial request" }
    ],
    "keyDecisions": [
      "Decision 1: ...",
      "Decision 2: ..."
    ],
    "openItems": [
      "TODO: ...",
      "Question: ..."
    ]
  }
}
```

## Metrics & Monitoring

Track in `hive-state.json`:
```json
{
  "sessionManagement": {
    "totalSessions": 150,
    "compressedSessions": 23,
    "avgCompressionRatio": 0.78,
    "sessionsPreventedReset": 15,
    "subagentsCleaned": 45,
    "tokensSaved": 3400000
  }
}
```

## Success Criteria

- [ ] Sessions rarely hit 90% (watchdog reset)
- [ ] Subagent sessions auto-cleanup within 24h
- [ ] No lost context on proactive compaction
- [ ] Archive searchable for historical queries
- [ ] <5% of sessions require emergency reset

## Files to Create

1. `~/.openclaw/skills/session-lifecycle-manager/SKILL.md` — This file
2. `~/.openclaw/skills/session-lifecycle-manager/scripts/manager.sh` — Main script
3. `~/.openclaw/skills/session-lifecycle-manager/scripts/cleanup-subagents.sh` — Subagent cleanup
4. `~/.openclaw/skills/session-lifecycle-manager/lib/compressor.js` — Compression logic
5. `~/.openclaw/skills/session-lifecycle-manager/lib/extractor.js` — Decision extraction

## CHANGELOG

### v2.0.0 (2026-02-12)
- Three-tier proactive management
- Subagent auto-cleanup
- Compression with context preservation
- Integration with existing watchdog
