#!/usr/bin/env bash
# track.sh — Task status tracker for Zenni's dispatch log
#
# Usage:
#   bash track.sh list                                   → show active dispatches
#   bash track.sh status <label>                         → check specific task
#   bash track.sh done <label> <success|fail|partial> "<summary>"  → mark complete
#   bash track.sh history [n]                            → show last N dispatches (default 20)
#   bash track.sh stats                                  → success rates per agent

set -euo pipefail

ACTION="${1:-list}"
LOG_DIR="$HOME/.openclaw/logs"
DISPATCH_LOG="$LOG_DIR/dispatch-log.jsonl"
ACTIVE_LOG="$LOG_DIR/dispatch-active.jsonl"

# Ensure files exist
mkdir -p "$LOG_DIR"
touch "$DISPATCH_LOG" 2>/dev/null || true
touch "$ACTIVE_LOG" 2>/dev/null || true

# ── Helpers ───────────────────────────────────────────────────────────────────
count_lines() { wc -l < "${1:-/dev/null}" 2>/dev/null | tr -d ' ' || echo 0; }

pretty_json() {
  if command -v python3 &>/dev/null; then
    python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts    = d.get('ts','?')[:16].replace('T',' ')
        agent = d.get('agent','?').upper()
        label = d.get('label','?')
        status= d.get('status','?')
        outcome= d.get('outcome','')
        task  = d.get('task_preview','')[:60]
        icon  = {'success':'✅','fail':'❌','partial':'⚠️','dispatched':'🚀','cancelled':'🚫'}.get(status,'•')
        result_str = f'  {icon} [{ts}] [{agent:10s}] {label}  — {status}{\" (\"+outcome+\")\" if outcome and outcome!=status else \"\"}'
        print(result_str)
        if task:
            print(f'      Task: {task}...')
    except:
        print(line[:100])
"
  else
    cat
  fi
}

# ── ACTIONS ───────────────────────────────────────────────────────────────────

case "$ACTION" in

  # ── list: show active tasks ──────────────────────────────────────────────
  list)
    echo ""
    echo "📋 ACTIVE DISPATCHES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ ! -s "$ACTIVE_LOG" ]]; then
      echo "   (none — all clear)"
    else
      pretty_json < "$ACTIVE_LOG"
    fi
    echo ""
    TOTAL=$(count_lines "$DISPATCH_LOG")
    ACTIVE=$(count_lines "$ACTIVE_LOG")
    echo "   Total dispatched: $TOTAL | Active: $ACTIVE"
    echo ""
    ;;

  # ── status: check a specific label ──────────────────────────────────────
  status)
    LABEL="${2:-}"
    if [[ -z "$LABEL" ]]; then
      echo "❌ Usage: track.sh status <label>"
      exit 1
    fi
    echo ""
    echo "🔍 STATUS: $LABEL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    FOUND=$(grep "\"label\":\"$LABEL\"" "$DISPATCH_LOG" 2>/dev/null | tail -1 || echo "")
    if [[ -z "$FOUND" ]]; then
      echo "   Not found in dispatch log."
    else
      echo "$FOUND" | pretty_json
    fi
    echo ""
    ;;

  # ── done: mark task complete ─────────────────────────────────────────────
  done)
    LABEL="${2:-}"
    OUTCOME="${3:-success}"  # success | fail | partial
    SUMMARY="${4:-}"

    if [[ -z "$LABEL" ]]; then
      echo "❌ Usage: track.sh done <label> <success|fail|partial> \"summary\""
      exit 1
    fi

    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Find the agent for this task
    AGENT=$(grep "\"label\":\"$LABEL\"" "$DISPATCH_LOG" 2>/dev/null | tail -1 | \
      python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('agent','unknown'))" 2>/dev/null || echo "unknown")
    TASK_TYPE=$(grep "\"label\":\"$LABEL\"" "$DISPATCH_LOG" 2>/dev/null | tail -1 | \
      python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('task_preview','')[:60])" 2>/dev/null || echo "")

    # Append completion record to dispatch log
    DONE_ENTRY=$(cat <<EOF
{"ts":"$TS","agent":"$AGENT","label":"$LABEL","status":"$OUTCOME","outcome":"$OUTCOME","summary":"$(echo "$SUMMARY" | sed 's/"/\\"/g')","task_preview":"$(echo "$TASK_TYPE" | sed 's/"/\\"/g')"}
EOF
)
    echo "$DONE_ENTRY" >> "$DISPATCH_LOG"

    # Remove from active log
    if [[ -s "$ACTIVE_LOG" ]]; then
      grep -v "\"label\":\"$LABEL\"" "$ACTIVE_LOG" > "$ACTIVE_LOG.tmp" 2>/dev/null && \
        mv "$ACTIVE_LOG.tmp" "$ACTIVE_LOG" || rm -f "$ACTIVE_LOG.tmp"
    fi

    # Outcome icon
    case "$OUTCOME" in
      success)  ICON="✅" ;;
      fail)     ICON="❌" ;;
      partial)  ICON="⚠️" ;;
      *)        ICON="•" ;;
    esac

    echo ""
    echo "$ICON  TASK COMPLETE: $LABEL"
    echo "   Agent:   $AGENT"
    echo "   Outcome: $OUTCOME"
    if [[ -n "$SUMMARY" ]]; then
      echo "   Summary: $SUMMARY"
    fi
    echo "   Logged to dispatch-log.jsonl"
    echo ""

    # Run task-complete.sh if available (GAIA OS learning hook)
    TASK_COMPLETE="$HOME/.openclaw/workspace/scripts/learning/task-complete.sh"
    if [[ -x "$TASK_COMPLETE" ]]; then
      bash "$TASK_COMPLETE" "zenni" "dispatched-$AGENT: $LABEL" "$OUTCOME" "$SUMMARY" 2>/dev/null || true
    fi
    ;;

  # ── history: show last N dispatches ─────────────────────────────────────
  history)
    N="${2:-20}"
    echo ""
    echo "📜 DISPATCH HISTORY (last $N)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ ! -s "$DISPATCH_LOG" ]]; then
      echo "   (no history yet)"
    else
      tail -"$N" "$DISPATCH_LOG" | pretty_json
    fi
    echo ""
    ;;

  # ── stats: success rates per agent ──────────────────────────────────────
  stats)
    echo ""
    echo "📊 AGENT PERFORMANCE STATS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ ! -s "$DISPATCH_LOG" ]]; then
      echo "   (no data yet)"
    else
      python3 - "$DISPATCH_LOG" <<'PYEOF'
import sys, json
from collections import defaultdict

log_path = sys.argv[1]
agents = defaultdict(lambda: {'total': 0, 'success': 0, 'fail': 0, 'partial': 0, 'dispatched': 0})

with open(log_path) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            d = json.loads(line)
            agent = d.get('agent', 'unknown')
            status = d.get('status', 'dispatched')
            agents[agent]['total'] += 1
            if status in agents[agent]:
                agents[agent][status] += 1
        except:
            pass

for agent, s in sorted(agents.items()):
    completed = s['success'] + s['fail'] + s['partial']
    rate = (s['success'] / completed * 100) if completed > 0 else 0
    bar = '█' * int(rate / 10) + '░' * (10 - int(rate / 10))
    print(f"  {agent:12s}  [{bar}] {rate:5.1f}%  "
          f"✅{s['success']} ❌{s['fail']} ⚠️{s['partial']} 🚀{s['dispatched']}")
PYEOF
    fi
    echo ""
    ;;

  # ── cancel: mark a task cancelled ────────────────────────────────────────
  cancel)
    LABEL="${2:-}"
    if [[ -z "$LABEL" ]]; then
      echo "❌ Usage: track.sh cancel <label>"
      exit 1
    fi
    # Remove from active, add cancelled entry
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"ts\":\"$TS\",\"label\":\"$LABEL\",\"status\":\"cancelled\"}" >> "$DISPATCH_LOG"
    grep -v "\"label\":\"$LABEL\"" "$ACTIVE_LOG" > "$ACTIVE_LOG.tmp" 2>/dev/null && \
      mv "$ACTIVE_LOG.tmp" "$ACTIVE_LOG" || rm -f "$ACTIVE_LOG.tmp"
    echo "🚫 Cancelled: $LABEL"
    ;;

  # ── help ─────────────────────────────────────────────────────────────────
  help|--help|-h)
    echo ""
    echo "track.sh — Zenni's dispatch tracker"
    echo ""
    echo "Commands:"
    echo "  list                              Show active dispatches"
    echo "  status <label>                    Check a specific task"
    echo "  done <label> <outcome> [summary]  Mark task complete"
    echo "  history [n]                       Show last N dispatches"
    echo "  stats                             Success rates per agent"
    echo "  cancel <label>                    Cancel a task"
    echo ""
    echo "Outcomes: success | fail | partial"
    echo ""
    ;;

  *)
    echo "❌ Unknown action: '$ACTION'"
    echo "   Run: track.sh help"
    exit 1
    ;;

esac
