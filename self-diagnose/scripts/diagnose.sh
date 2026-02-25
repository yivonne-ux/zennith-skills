#!/usr/bin/env bash
# GAIA OS Self-Diagnosis Script — run by Athena
# Collects system health data for analysis

set -euo pipefail

echo "=== GAIA OS DIAGNOSTIC REPORT ==="
echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Local: $(date '+%Y-%m-%d %H:%M %Z')"
echo ""

# 1. Session count
echo "--- Sessions ---"
SESSIONS_DIR="$HOME/.openclaw/sessions"
if [ -d "$SESSIONS_DIR" ]; then
  SESSION_COUNT=$(find "$SESSIONS_DIR" -name "*.jsonl" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "Total session files: $SESSION_COUNT"
  # Large sessions (>1MB)
  echo "Large sessions (>1MB):"
  find "$SESSIONS_DIR" -name "*.jsonl" -size +1M -exec ls -lh {} \; 2>/dev/null || echo "  None"
  # Very large (>5MB)
  echo "Very large sessions (>5MB):"
  find "$SESSIONS_DIR" -name "*.jsonl" -size +5M -exec ls -lh {} \; 2>/dev/null || echo "  None"
fi
echo ""

# 2. Gateway health
echo "--- Gateway ---"
if pgrep -f "openclaw.*gateway" >/dev/null 2>&1; then
  echo "Gateway: RUNNING (pid $(pgrep -f 'openclaw.*gateway' | head -1))"
else
  echo "Gateway: NOT RUNNING ❌"
fi

# Memory usage of gateway process
GATEWAY_PID=$(pgrep -f "openclaw.*gateway" | head -1 2>/dev/null || true)
if [ -n "$GATEWAY_PID" ]; then
  RSS=$(ps -o rss= -p "$GATEWAY_PID" 2>/dev/null | tr -d ' ')
  if [ -n "$RSS" ]; then
    RSS_MB=$((RSS / 1024))
    echo "Gateway RSS: ${RSS_MB}MB"
    if [ "$RSS_MB" -gt 1024 ]; then
      echo "⚠️ Gateway using >1GB RAM — possible memory leak"
    fi
  fi
fi
echo ""

# 3. Cron health
echo "--- Cron Jobs ---"
if [ -f "$HOME/.openclaw/cron/jobs.json" ]; then
  python3 -c "
import json, sys
with open('$HOME/.openclaw/cron/jobs.json') as f:
    data = json.load(f)
jobs = data.get('jobs', data) if isinstance(data, dict) else data
for j in (jobs if isinstance(jobs, list) else [jobs]):
    state = j.get('state', {})
    status = state.get('lastStatus', 'unknown')
    errors = state.get('consecutiveErrors', 0)
    name = j.get('name', j.get('id', '?'))
    enabled = j.get('enabled', True)
    if not enabled: continue
    flag = '❌' if errors > 0 else '✅'
    print(f'  {flag} {name}: status={status}, errors={errors}')
    if errors > 0:
        print(f'     lastError: {state.get(\"lastError\", \"n/a\")}')
" 2>/dev/null || echo "  Failed to parse cron jobs"
fi
echo ""

# 4. Disk usage
echo "--- Disk ---"
echo "OpenClaw dir: $(du -sh ~/.openclaw 2>/dev/null | cut -f1)"
echo "Sessions dir: $(du -sh ~/.openclaw/sessions 2>/dev/null | cut -f1)"
echo "Logs: $(du -sh /tmp/openclaw 2>/dev/null | cut -f1)"
echo ""

# 5. Recent errors in gateway log
echo "--- Recent Errors (last 2h) ---"
LOG="/tmp/openclaw/openclaw-$(date '+%Y-%m-%d').log"
if [ -f "$LOG" ]; then
  TWO_HOURS_AGO=$(date -v-2H '+%Y-%m-%dT%H' 2>/dev/null || date -d '2 hours ago' '+%Y-%m-%dT%H' 2>/dev/null || echo "")
  if [ -n "$TWO_HOURS_AGO" ]; then
    grep "ERROR" "$LOG" | grep "$TWO_HOURS_AGO" | tail -5 || echo "  No recent errors"
  else
    grep "ERROR" "$LOG" | tail -5 || echo "  No recent errors"
  fi
else
  echo "  Log file not found"
fi
echo ""

echo "=== END DIAGNOSTIC ==="
