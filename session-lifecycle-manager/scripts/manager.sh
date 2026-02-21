#!/usr/bin/env bash
# session-lifecycle-manager/scripts/manager.sh
# Proactive session memory management

set -uo pipefail

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SESSIONS_FILE="$OPENCLAW_DIR/agents/main/sessions/sessions.json"
SESSIONS_DIR="$OPENCLAW_DIR/agents/main/sessions"
ARCHIVE_DIR="$SESSIONS_DIR/archive"
MEMORY_DIR="$OPENCLAW_DIR/workspace/memory"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/session-manager.log"

# Thresholds (tokens)
CONTEXT_LIMIT=262144
TIER1_THRESHOLD=$(( CONTEXT_LIMIT * 35 / 100 ))   # 91750 - Monitor (earlier detection)
TIER2_THRESHOLD=$(( CONTEXT_LIMIT * 50 / 100 ))   # 131072 - Compress (proactive, not emergency)
TIER3_THRESHOLD=$(( CONTEXT_LIMIT * 70 / 100 ))   # 183500 - Emergency compression (watchdog backup)

mkdir -p "$ARCHIVE_DIR" "$(dirname "$LOG_FILE")"

TS=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TS] === Session Lifecycle Manager ==="

# Check if another instance is already running (to prevent overlaps)
if [ -f "$SESSIONS_DIR/manager.lock" ]; then
  local lock_time=$(stat -f "%m" "$SESSIONS_DIR/manager.lock" 2>/dev/null)
  local now=$(date +%s)
  if [ "$((now - lock_time))" -lt 3600 ]; then  # If lock is less than 1 hour old
    log "INFO" "Manager already running (lock file exists). Skipping."
    exit 0
  fi
fi

# Create lock file
touch "$SESSIONS_DIR/manager.lock"
trap 'rm -f "$SESSIONS_DIR/manager.lock"' EXIT

# Function: Log to file and console
log() {
  local level="$1"
  local msg="$2"
  local entry="[$(date +"%Y-%m-%d %H:%M:%S")] [$level] $msg"
  echo "$entry"
  echo "$entry" >> "$LOG_FILE"
}

# Function: Post to feedback room
post_to_room() {
  local type="$1"
  local msg="$2"
  local entry="{\"ts\":$(date +%s)000,\"agent\":\"session-manager\",\"room\":\"feedback\",\"type\":\"$type\",\"msg\":\"$msg\"}"
  echo "$entry" >> "$ROOMS_DIR/feedback.jsonl" 2>/dev/null || true
}

# Function: Extract key info from session before compression
extract_session_summary() {
  local session_key="$1"
  local jsonl_file="$2"
  
  if [ ! -f "$jsonl_file" ]; then
    echo "[]"
    return
  fi
  
  # Extract last 10 turns and any decisions
  node << NODEOF
const fs = require('fs');
const lines = fs.readFileSync('$jsonl_file', 'utf8').trim().split('\n').filter(Boolean);
const recent = lines.slice(-20);
const messages = recent.map(l => {
  try { return JSON.parse(l); } catch { return null; }
}).filter(Boolean);

const summary = {
  turnCount: lines.length,
  recentTurns: messages.length,
  lastActivity: messages[messages.length - 1]?.ts || Date.now(),
  keyDecisions: messages
    .filter(m => m.message?.content?.includes('Decision') || m.message?.content?.includes('decided'))
    .map(m => ({
      role: m.message?.role,
      preview: typeof m.message?.content === 'string' 
        ? m.message.content.slice(0, 200) 
        : JSON.stringify(m.message?.content).slice(0, 200)
    }))
};

console.log(JSON.stringify(summary, null, 2));
NODEOF
}

# Function: Compress a session (Tier 2/3)
compress_session() {
  local session_key="$1"
  local tokens="$2"
  local tier="$3"
  
  # Extract session ID from key
  local session_id=$(echo "$session_key" | sed 's/[^a-zA-Z0-9]/-/g' | cut -c1-50)
  local jsonl_file="$SESSIONS_DIR/${session_id}.jsonl"
  
  # If file doesn't exist with that name, try to find it
  if [ ! -f "$jsonl_file" ]; then
    # Extract from sessions.json
    session_id=$(jq -r --arg key "$session_key" '.[$key].sessionFile // empty' "$SESSIONS_FILE" | xargs basename 2>/dev/null | sed 's/.jsonl$//')
    jsonl_file="$SESSIONS_DIR/${session_id}.jsonl"
  fi
  
  if [ ! -f "$jsonl_file" ]; then
    log "WARN" "Cannot find JSONL for session: $session_key"
    return 1
  fi
  
  log "INFO" "Compressing session $session_key ($tokens tokens, tier $tier)"
  
  # Extract summary
  local summary=$(extract_session_summary "$session_key" "$jsonl_file")
  
  # Create compressed metadata
  local meta_file="$ARCHIVE_DIR/${session_id}-$(date +%s).json"
  cat > "$meta_file" << EOF
{
  "originalSession": "$session_key",
  "compressedAt": "$(date -Iseconds)",
  "originalTokens": $tokens,
  "tier": "$tier",
  "summary": $summary
}
EOF
  
  # Archive the full session (compressed)
  local archive_file="$ARCHIVE_DIR/${session_id}-$(date +%s).jsonl.gz"
  gzip -c "$jsonl_file" > "$archive_file"
  
  # Remove original JSONL
  rm -f "$jsonl_file"
  
  # Update sessions.json to mark as compressed
  node << NODEOF
const fs = require('fs');
const file = '$SESSIONS_FILE';
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
const key = '$session_key';

if (data[key]) {
  data[key].totalTokens = 0;
  data[key].compressed = true;
  data[key].compressedAt = new Date().toISOString();
  data[key].archiveLocation = '$archive_file';
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}
NODEOF
  
  log "INFO" "  ✓ Compressed and archived to $archive_file"
  post_to_room "session_compressed" "Session $session_key compressed ($tokens tokens → archive)"
  
  return 0
}

# Function: Cleanup subagent sessions
cleanup_subagents() {
  log "INFO" "Scanning for stale subagent sessions..."
  
  local now=$(date +%s)
  local cutoff=$((now - 86400))  # 24 hours ago
  local cleaned=0
  
  # Find subagent sessions older than 24h
  jq -r 'to_entries[] | select(.key | contains(":subagent:")) | "\(.key)|\(.value.lastActivity // 0)"' "$SESSIONS_FILE" 2>/dev/null | \
  while IFS='|' read -r session_key last_activity; do
    if [ -n "$last_activity" ] && [ "$last_activity" -lt "$cutoff" ]; then
      log "INFO" "  Archiving stale subagent: $session_key"
      
      # Get token count
      local tokens=$(jq -r --arg key "$session_key" '.[$key].totalTokens // 0' "$SESSIONS_FILE")
      
      if compress_session "$session_key" "$tokens" "subagent-cleanup"; then
        cleaned=$((cleaned + 1))
      fi
    fi
  done
  
  log "INFO" "Cleaned up $cleaned stale subagent sessions"
  return $cleaned
}

# Function: Analyze session growth patterns
analyze_growth() {
  log "INFO" "Analyzing session growth patterns..."
  
  node << NODEOF
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$SESSIONS_FILE', 'utf8'));

const stats = {
  total: 0,
  byType: {},
  large: [],
  subagents: 0
};

for (const [key, session] of Object.entries(data)) {
  stats.total++;
  
  const tokens = session.totalTokens || 0;
  
  // Categorize by type
  let type = 'other';
  if (key.includes(':subagent:')) type = 'subagent';
  else if (key.includes(':whatsapp:')) type = 'whatsapp';
  else if (key.includes(':cron:')) type = 'cron';
  else if (key.includes(':webchat:')) type = 'webchat';
  
  stats.byType[type] = (stats.byType[type] || 0) + 1;
  if (type === 'subagent') stats.subagents++;
  
  // Track large sessions
  if (tokens > $TIER2_THRESHOLD) {
    stats.large.push({ key: key.slice(0, 60), tokens, type });
  }
}

// Sort by token count
stats.large.sort((a, b) => b.tokens - a.tokens);

console.log('Session Statistics:');
console.log('  Total sessions:', stats.total);
console.log('  By type:', stats.byType);
console.log('  Large sessions (>70%):', stats.large.length);
if (stats.large.length > 0) {
  console.log('  Top 5 largest:');
  stats.large.slice(0, 5).forEach(s => {
    console.log('    -', s.key, ':', s.tokens, 'tokens');
  });
}
NODEOF
}

# Main execution
echo "Time: $(date)"
echo "Thresholds: Monitor=${TIER1_THRESHOLD}, Warn=${TIER2_THRESHOLD}, Critical=${TIER3_THRESHOLD}"
echo ""

# Check if sessions file exists
if [ ! -f "$SESSIONS_FILE" ]; then
  log "ERROR" "Sessions file not found: $SESSIONS_FILE"
  exit 1
fi

# Analyze current state
analyze_growth
echo ""

# Process all sessions
log "INFO" "Processing sessions..."

jq -r 'to_entries[] | "\(.key)|\(.value.totalTokens // 0)"' "$SESSIONS_FILE" | \
while IFS='|' read -r session_key tokens; do
  # Skip if already compressed
  if jq -e --arg key "$session_key" '.[$key].compressed == true' "$SESSIONS_FILE" > /dev/null 2>&1; then
    continue
  fi
  
  if [ "$tokens" -gt "$TIER3_THRESHOLD" ]; then
    log "CRITICAL" "Session $session_key: $tokens tokens - EMERGENCY compression"
    compress_session "$session_key" "$tokens" "emergency"
    post_to_room "session_alert" "CRITICAL: Session $session_key at $tokens tokens - compressed"
  elif [ "$tokens" -gt "$TIER2_THRESHOLD" ]; then
    log "WARNING" "Session $session_key: $tokens tokens - COMPRESSION"
    compress_session "$session_key" "$tokens" "warning"
  elif [ "$tokens" -gt "$TIER1_THRESHOLD" ]; then
    log "MONITOR" "Session $session_key: $tokens tokens (monitoring)"
  fi
done

# Cleanup subagents
echo ""
cleanup_subagents

# Summary
log "INFO" "=== Session Manager Complete ==="
