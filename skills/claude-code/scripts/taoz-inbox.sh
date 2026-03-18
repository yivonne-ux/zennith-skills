#!/usr/bin/env bash
# taoz-inbox.sh — View and manage Taoz's task inbox
#
# Usage:
#   bash taoz-inbox.sh list          # Show pending tasks
#   bash taoz-inbox.sh count         # Count pending tasks
#   bash taoz-inbox.sh peek          # Show next pending task details
#   bash taoz-inbox.sh done <id>     # Mark task as done
#   bash taoz-inbox.sh all           # Show all tasks (including completed)
#
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

CMD="${1:-list}"
INBOX="$HOME/.openclaw/workspace/taoz-inbox.jsonl"

if [ ! -f "$INBOX" ]; then
  echo "No inbox file found. No pending tasks."
  exit 0
fi

case "$CMD" in
  list)
    echo "=== Taoz Inbox (Pending Tasks) ==="
    echo ""
    python3 - "$INBOX" << 'PYEOF'
import json, sys
from datetime import datetime

inbox_file = sys.argv[1]
tasks = {}

with open(inbox_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            tid = entry.get('id', '')
            if not tid:
                continue
            if 'msg' in entry:
                tasks[tid] = entry
            elif entry.get('status') == 'completed':
                if tid in tasks:
                    tasks[tid]['status'] = 'completed'
        except:
            continue

pending = {k: v for k, v in tasks.items() if v.get('status') == 'pending'}
if not pending:
    print("No pending tasks.")
    sys.exit(0)

for i, (tid, task) in enumerate(sorted(pending.items(), key=lambda x: x[1].get('ts', 0)), 1):
    ts = task.get('ts', 0) / 1000
    dt = datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M') if ts else '?'
    msg = task.get('msg', '')[:120]
    frm = task.get('from', '?')
    room = task.get('room', '?')
    print(f"{i}. [{tid}] from {frm} ({room})")
    print(f"   Time: {dt}")
    print(f"   Task: {msg}")
    print()

print(f"Total: {len(pending)} pending task(s)")
PYEOF
    ;;

  count)
    python3 - "$INBOX" << 'PYEOF'
import json, sys

inbox_file = sys.argv[1]
tasks = {}
with open(inbox_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            tid = entry.get('id', '')
            if not tid:
                continue
            if 'msg' in entry:
                tasks[tid] = entry
            elif entry.get('status') == 'completed':
                if tid in tasks:
                    tasks[tid]['status'] = 'completed'
        except:
            continue

pending = sum(1 for v in tasks.values() if v.get('status') == 'pending')
print(f"{pending}")
PYEOF
    ;;

  peek)
    python3 - "$INBOX" << 'PYEOF'
import json, sys
from datetime import datetime

inbox_file = sys.argv[1]
tasks = {}
with open(inbox_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            tid = entry.get('id', '')
            if not tid:
                continue
            if 'msg' in entry:
                tasks[tid] = entry
            elif entry.get('status') == 'completed':
                if tid in tasks:
                    tasks[tid]['status'] = 'completed'
        except:
            continue

pending = [(k, v) for k, v in tasks.items() if v.get('status') == 'pending']
if not pending:
    print("No pending tasks.")
    sys.exit(0)

pending.sort(key=lambda x: x[1].get('ts', 0))
tid, task = pending[0]
ts = task.get('ts', 0) / 1000
dt = datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S') if ts else '?'

print(f"=== Next Task ===")
print(f"ID:   {tid}")
print(f"From: {task.get('from', '?')}")
print(f"Room: {task.get('room', '?')}")
print(f"Time: {dt}")
print(f"Task: {task.get('msg', '')}")
PYEOF
    ;;

  done)
    TASK_ID="${2:?Usage: taoz-inbox.sh done <task_id>}"
    printf '{"id":"%s","ts":%s000,"status":"completed"}\n' "$TASK_ID" "$(date +%s)" >> "$INBOX"
    echo "Marked $TASK_ID as completed."
    ;;

  all)
    python3 - "$INBOX" << 'PYEOF'
import json, sys
from datetime import datetime

inbox_file = sys.argv[1]
tasks = {}
with open(inbox_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
            tid = entry.get('id', '')
            if not tid:
                continue
            if 'msg' in entry:
                tasks[tid] = entry
            elif entry.get('status') == 'completed':
                if tid in tasks:
                    tasks[tid]['status'] = 'completed'
        except:
            continue

for i, (tid, task) in enumerate(sorted(tasks.items(), key=lambda x: x[1].get('ts', 0)), 1):
    ts = task.get('ts', 0) / 1000
    dt = datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M') if ts else '?'
    status = task.get('status', '?')
    msg = task.get('msg', '')[:100]
    frm = task.get('from', '?')
    marker = "DONE" if status == "completed" else "PENDING"
    print(f"{i}. [{marker}] [{tid}] from {frm}: {msg}")
    print(f"   Time: {dt}")
    print()

print(f"Total: {len(tasks)} task(s)")
PYEOF
    ;;

  *)
    echo "Taoz Inbox Manager"
    echo ""
    echo "Usage: taoz-inbox.sh <command>"
    echo ""
    echo "Commands:"
    echo "  list     Show pending tasks"
    echo "  count    Count pending tasks"
    echo "  peek     Show next pending task details"
    echo "  done <id> Mark task as done"
    echo "  all      Show all tasks (including completed)"
    ;;
esac
