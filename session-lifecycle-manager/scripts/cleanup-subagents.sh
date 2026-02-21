#!/usr/bin/env bash
# session-lifecycle-manager/scripts/cleanup-subagents.sh
# Cleanup completed/stale subagent sessions

set -uo pipefail

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SESSIONS_FILE="$OPENCLAW_DIR/agents/main/sessions/sessions.json"
ARCHIVE_DIR="$OPENCLAW_DIR/agents/main/sessions/archive"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"

mkdir -p "$ARCHIVE_DIR"

TS=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TS] Cleaning up subagent sessions..."

# Function: Post to feedback room
post_to_room() {
  local type="$1"
  local msg="$2"
  local entry="{\"ts\":$(date +%s)000,\"agent\":\"session-manager\",\"room\":\"feedback\",\"type\":\"$type\",\"msg\":\"$msg\"}"
  echo "$entry" >> "$ROOMS_DIR/feedback.jsonl" 2>/dev/null || true
}

# Find and cleanup old subagents
node << 'NODEOF'
const fs = require('fs');
const path = require('path');

const SESSIONS_FILE = process.env.SESSIONS_FILE || `${process.env.HOME}/.openclaw/agents/main/sessions/sessions.json`;
const SESSIONS_DIR = path.dirname(SESSIONS_FILE);
const ARCHIVE_DIR = `${SESSIONS_DIR}/archive`;

if (!fs.existsSync(SESSIONS_FILE)) {
  console.log('No sessions file found');
  process.exit(0);
}

const data = JSON.parse(fs.readFileSync(SESSIONS_FILE, 'utf8'));
const now = Date.now();
const cutoff = now - (24 * 60 * 60 * 1000); // 24 hours

let cleaned = 0;
let tokensFreed = 0;

for (const [key, session] of Object.entries(data)) {
  // Only process subagents
  if (!key.includes(':subagent:')) continue;
  
  const lastActivity = session.lastActivity || 0;
  const tokens = session.totalTokens || 0;
  
  // Skip if recently active
  if (lastActivity > cutoff) continue;
  
  // Skip if already compressed
  if (session.compressed) continue;
  
  console.log(`Cleaning up: ${key.slice(0, 60)}... (${tokens} tokens)`);
  
  // Mark as compressed in sessions.json
  session.totalTokens = 0;
  session.compressed = true;
  session.cleanedAt = new Date().toISOString();
  
  cleaned++;
  tokensFreed += tokens;
  
  // Try to find and compress the JSONL file
  const sessionIdMatch = key.match(/:subagent:([a-f0-9-]+)/);
  if (sessionIdMatch) {
    const sessionId = sessionIdMatch[1];
    const jsonlPath = path.join(SESSIONS_DIR, `${sessionId}.jsonl`);
    
    if (fs.existsSync(jsonlPath)) {
      // Archive it
      const { execSync } = require('child_process');
      try {
        execSync(`gzip -c "${jsonlPath}" > "${ARCHIVE_DIR}/subagent-${sessionId}-$(date +%s).jsonl.gz"`);
        fs.unlinkSync(jsonlPath);
        console.log(`  ✓ Archived and removed JSONL`);
      } catch (e) {
        console.log(`  ⚠ Could not archive: ${e.message}`);
      }
    }
  }
}

// Write updated sessions.json
fs.writeFileSync(SESSIONS_FILE, JSON.stringify(data, null, 2));

console.log(`\nCleaned ${cleaned} subagent sessions, freed ~${tokensFreed} tokens`);

// Post summary to feedback room
const summary = {
  ts: Date.now(),
  agent: 'session-manager',
  room: 'feedback',
  type: 'subagent_cleanup',
  msg: `Cleaned ${cleaned} stale subagent sessions, freed ~${tokensFreed} tokens`
};

const feedbackPath = `${process.env.HOME}/.openclaw/workspace/rooms/feedback.jsonl`;
try {
  fs.appendFileSync(feedbackPath, JSON.stringify(summary) + '\n');
} catch (e) {
  // ignore
}
NODEOF

echo "[$TS] Subagent cleanup complete"
