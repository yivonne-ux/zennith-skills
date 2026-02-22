#!/usr/bin/env bash
# nightly.sh — CORP-OS Nightly Review + Session Health Check
# Merged: corp-os-compound nightly review + session-lifecycle-manager
# Runs at 22:30 MYT daily

set -uo pipefail

OPENCLAW_DIR="${HOME}/.openclaw"
WORKSPACE="${OPENCLAW_DIR}/workspace"
ROOMS_DIR="${WORKSPACE}/rooms"
LEARNING_LOG_DIR="${WORKSPACE}/corp-os/learning-log"
LOG_FILE="${OPENCLAW_DIR}/logs/nightly-review.log"
DATE=$(date +"%Y-%m-%d")
TS=$(date +"%Y-%m-%d %H:%M:%S %Z")

mkdir -p "${LEARNING_LOG_DIR}" "$(dirname "${LOG_FILE}")"

log() { echo "[$TS] $1" | tee -a "${LOG_FILE}"; }

log "=== GAIA CORP-OS Nightly Review ==="

# ── 1. SESSION HEALTH CHECK ──
log "Checking session token usage..."
SESSION_FILE="${OPENCLAW_DIR}/agents/main/sessions/sessions.json"
CONTEXT_LIMIT=262144
WARN_THRESHOLD=$(( CONTEXT_LIMIT * 70 / 100 ))

SESSION_ALERTS=""
SESSION_TOKENS="unknown"
if [ -f "${SESSION_FILE}" ]; then
    SESSION_TOKENS=$(python3 -c "
import json
with open('${SESSION_FILE}') as f:
    s = json.load(f)
sessions = s if isinstance(s, list) else s.get('sessions', [])
if sessions:
    print(sessions[0].get('totalTokens', 0))
else:
    print(0)
" 2>/dev/null || echo 0)
    
    if [ -n "${SESSION_TOKENS}" ] && [ "${SESSION_TOKENS}" -gt "${WARN_THRESHOLD}" ] 2>/dev/null; then
        SESSION_ALERTS="⚠️ Main session at ${SESSION_TOKENS} tokens (limit: ${CONTEXT_LIMIT})"
        log "WARNING: ${SESSION_ALERTS}"
    else
        log "Session health OK: ${SESSION_TOKENS} tokens"
    fi
fi

# ── 2. SCAN ROOMS (fast: last 200 lines per room, python does timestamp filter) ──
log "Scanning rooms (last 24h)..."
CUTOFF=$(( $(date +%s) - 86400 ))

ROOM_SUMMARY=$(python3 << PYEOF
import json, os, glob

rooms_dir = "${ROOMS_DIR}"
cutoff = ${CUTOFF}
complete = failed = signals = 0

for f in glob.glob(f"{rooms_dir}/*.jsonl"):
    try:
        # Read last 500 lines only for speed
        with open(f) as fh:
            lines = fh.readlines()[-500:]
        for line in lines:
            try:
                d = json.loads(line.strip())
                ts = int(d.get('ts', 0) / 1000)
                if ts < cutoff:
                    continue
                t = d.get('type', '')
                if t == 'task_complete': complete += 1
                elif t in ('task_failed', 'failure'): failed += 1
                elif t in ('signal', 'intel'): signals += 1
            except:
                pass
    except:
        pass

print(f"{complete}|{failed}|{signals}")
PYEOF
)

TASKS_COMPLETE=$(echo "${ROOM_SUMMARY}" | cut -d'|' -f1)
TASKS_FAILED=$(echo "${ROOM_SUMMARY}" | cut -d'|' -f2)
SIGNALS=$(echo "${ROOM_SUMMARY}" | cut -d'|' -f3)
log "24h: ${TASKS_COMPLETE} complete, ${TASKS_FAILED} failed, ${SIGNALS} signals"

# ── 3. CHECK FEEDBACK ROOM ──
UNRESOLVED=0
if [ -f "${ROOMS_DIR}/feedback.jsonl" ]; then
    UNRESOLVED=$(tail -200 "${ROOMS_DIR}/feedback.jsonl" | python3 -c "
import sys, json
failures = set()
resolved = set()
for line in sys.stdin:
    try:
        d = json.loads(line)
        if d.get('type') == 'failure': failures.add(d.get('id','f'+str(len(failures))))
        if d.get('type') == 'resolved': resolved.add(d.get('id',''))
    except: pass
print(len(failures - resolved))
" 2>/dev/null || echo 0)
    log "Unresolved feedback: ${UNRESOLVED}"
fi

# ── 4. WRITE LEARNING LOG ──
LEARNING_FILE="${LEARNING_LOG_DIR}/lrng-${DATE}-nightly.md"
cat > "${LEARNING_FILE}" << LOGEOF
# Nightly Review — ${DATE}
**Run at:** ${TS}

## Session Health
$([ -n "${SESSION_ALERTS}" ] && echo "${SESSION_ALERTS}" || echo "✅ All sessions within limits (${SESSION_TOKENS} tokens)")

## 24h Activity Summary
- Tasks completed: ${TASKS_COMPLETE}
- Tasks failed: ${TASKS_FAILED}
- Signals captured: ${SIGNALS}
- Unresolved feedback: ${UNRESOLVED}

## Status
$([ "${TASKS_FAILED:-0}" -gt 0 ] && echo "⚠️ ${TASKS_FAILED} failed tasks — review feedback room" || echo "✅ No failures detected")
LOGEOF

log "Learning log written: ${LEARNING_FILE}"

# ── 5. FINAL REPORT ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GAIA CORP-OS — Nightly Review ${DATE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "SESSION HEALTH"
[ -n "${SESSION_ALERTS}" ] && echo "  ${SESSION_ALERTS}" || echo "  ✅ Sessions within limits (${SESSION_TOKENS} tokens)"
echo ""
echo "24H ACTIVITY"
echo "  ✅ Completed: ${TASKS_COMPLETE} tasks"
[ "${TASKS_FAILED:-0}" -gt 0 ] && echo "  ⚠️  Failed: ${TASKS_FAILED} tasks" || echo "  ✅ Failed: 0"
echo "  📡 Signals: ${SIGNALS}"
echo "  📋 Unresolved: ${UNRESOLVED}"
echo ""
echo "Log saved: ${LEARNING_FILE}"
