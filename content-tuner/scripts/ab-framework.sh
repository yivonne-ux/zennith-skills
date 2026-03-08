#!/usr/bin/env bash
# ab-framework.sh — A/B Testing Framework for Content Factory
# Manages structured A/B tests between default templates and winning patterns
# Cron: Daily 10:00 MYT — evaluate command via Athena
# Safety: Variants need >10% improvement to beat control

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
AB_TESTS="$WORKSPACE/data/ab-tests.jsonl"
TUNING_LOG="$WORKSPACE/data/tuning-log.jsonl"
ROOMS_DIR="$WORKSPACE/rooms"

mkdir -p "$(dirname "$AB_TESTS")"

CMD="${1:-}"

usage() {
  echo "Usage: ab-framework.sh <create|evaluate|list|summary>"
  echo ""
  echo "Commands:"
  echo "  create    Create a new A/B test"
  echo "  evaluate  Evaluate tests past their evaluate_after time"
  echo "  list      List active tests"
  echo "  summary   Summarize completed tests"
  echo ""
  echo "Options (for create):"
  echo "  --name <name>          Test name"
  echo "  --control <desc>       Control variant description"
  echo "  --variant <desc>       Test variant description"
  echo "  --metric <metric>      Primary metric (CTR, ROAS, CPA, engagement)"
  echo "  --days <n>             Days to run before evaluation (default: 7)"
  echo "  --brand <brand>        Target brand"
  exit 1
}

[ -z "$CMD" ] && usage

case "$CMD" in
  create)
    shift
    NAME="" CONTROL="" VARIANT="" METRIC="CTR" DAYS=7 BRAND=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --name) shift; NAME="$1" ;;
        --control) shift; CONTROL="$1" ;;
        --variant) shift; VARIANT="$1" ;;
        --metric) shift; METRIC="$1" ;;
        --days) shift; DAYS="$1" ;;
        --brand) shift; BRAND="$1" ;;
      esac
      shift 2>/dev/null || true
    done

    if [ -z "$NAME" ] || [ -z "$CONTROL" ] || [ -z "$VARIANT" ]; then
      echo "ERROR: --name, --control, and --variant are required"
      exit 1
    fi

    TEST_ID="ab-$(date +%s)-$$"
    EVALUATE_AFTER=$(date -v+"${DAYS}d" +%s 2>/dev/null || date -d "+${DAYS} days" +%s 2>/dev/null || echo "$(($(date +%s) + DAYS * 86400))")

    python3 -c "
import json, sys
test = {
    'id': '$TEST_ID',
    'name': '$NAME',
    'control': '$CONTROL',
    'variant': '$VARIANT',
    'metric': '$METRIC',
    'brand': '$BRAND',
    'status': 'active',
    'created_at': $(date +%s)000,
    'evaluate_after': ${EVALUATE_AFTER}000,
    'days': $DAYS,
    'control_data': [],
    'variant_data': [],
    'result': None
}
with open('$AB_TESTS', 'a') as f:
    f.write(json.dumps(test) + '\n')
print(f'✅ A/B test created: {test[\"id\"]}')
print(f'   Name: {test[\"name\"]}')
print(f'   Control: {test[\"control\"]}')
print(f'   Variant: {test[\"variant\"]}')
print(f'   Metric: {test[\"metric\"]}')
print(f'   Evaluate after: $DAYS days')
"
    ;;

  evaluate)
    echo "═══ A/B TEST EVALUATION ═══"
    echo "$(date '+%Y-%m-%d %H:%M:%S MYT')"
    echo ""

    if [ ! -f "$AB_TESTS" ]; then
      echo "No A/B tests found."
      exit 0
    fi

    python3 << 'PYEOF'
import json, os, time
from datetime import datetime

workspace = os.path.expanduser("~/.openclaw/workspace")
ab_file = os.path.join(workspace, "data/ab-tests.jsonl")
tuning_log = os.path.join(workspace, "data/tuning-log.jsonl")
rooms_dir = os.path.join(workspace, "rooms")

now_ms = int(time.time() * 1000)
tests = []
with open(ab_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            tests.append(json.loads(line))
        except:
            continue

# Find active tests past evaluation time
active = [t for t in tests if t.get("status") == "active"]
ready = [t for t in active if t.get("evaluate_after", float("inf")) <= now_ms]
pending = [t for t in active if t.get("evaluate_after", float("inf")) > now_ms]

print(f"  Active tests: {len(active)} ({len(ready)} ready, {len(pending)} pending)")

if not ready:
    print("  No tests ready for evaluation.")
else:
    results = []
    for t in ready:
        tid = t["id"]
        control_data = t.get("control_data", [])
        variant_data = t.get("variant_data", [])

        if not control_data or not variant_data:
            print(f"  ⚠️  {tid}: No performance data collected yet. Extending by 3 days.")
            t["evaluate_after"] = now_ms + 3 * 86400 * 1000
            continue

        control_avg = sum(control_data) / len(control_data)
        variant_avg = sum(variant_data) / len(variant_data)

        if control_avg == 0:
            improvement = 100 if variant_avg > 0 else 0
        else:
            improvement = ((variant_avg - control_avg) / control_avg) * 100

        # >10% improvement = variant wins
        if improvement > 10:
            winner = "variant"
            t["status"] = "completed"
            t["result"] = {"winner": "variant", "improvement": round(improvement, 1)}
            print(f"  ✅ {tid} ({t['name']}): VARIANT WINS (+{improvement:.1f}%)")
        else:
            winner = "control"
            t["status"] = "completed"
            t["result"] = {"winner": "control", "improvement": round(improvement, 1)}
            print(f"  ❌ {tid} ({t['name']}): CONTROL WINS (variant only +{improvement:.1f}%)")

        # Log to tuning log
        with open(tuning_log, "a") as log:
            log.write(json.dumps({
                "ts": now_ms, "decision": f"ab-{winner}",
                "pattern_id": tid, "test_name": t["name"],
                "improvement": round(improvement, 1),
                "evidence": f"Control avg: {control_avg:.2f}, Variant avg: {variant_avg:.2f}"
            }) + "\n")

        results.append(t)

    # Rewrite tests file with updated statuses
    with open(ab_file, "w") as f:
        for t in tests:
            f.write(json.dumps(t, default=str) + "\n")

    # Post to exec room
    if results:
        summary = f"[A/B Framework] {len(results)} tests evaluated. " + \
                  ", ".join(f"{t['name']}: {t['result']['winner']} wins" for t in results[:3])
        with open(os.path.join(rooms_dir, "exec.jsonl"), "a") as r:
            r.write(json.dumps({"ts": now_ms, "agent": "content-tuner", "room": "exec", "msg": summary}) + "\n")

print("\n  ✓ Evaluation complete")
PYEOF
    ;;

  list)
    if [ ! -f "$AB_TESTS" ]; then
      echo "No A/B tests found."
      exit 0
    fi
    echo "═══ ACTIVE A/B TESTS ═══"
    python3 -c "
import json
with open('$AB_TESTS') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            t = json.loads(line)
            if t.get('status') == 'active':
                from datetime import datetime
                eval_date = datetime.fromtimestamp(t.get('evaluate_after', 0) / 1000).strftime('%Y-%m-%d')
                print(f\"  {t['id']} | {t['name']} | {t['metric']} | eval: {eval_date}\")
        except: pass
"
    ;;

  summary)
    if [ ! -f "$AB_TESTS" ]; then
      echo "No A/B tests found."
      exit 0
    fi
    echo "═══ A/B TEST SUMMARY ═══"
    python3 -c "
import json
completed = 0; variant_wins = 0; control_wins = 0
with open('$AB_TESTS') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            t = json.loads(line)
            if t.get('status') == 'completed':
                completed += 1
                result = t.get('result', {})
                if result.get('winner') == 'variant':
                    variant_wins += 1
                else:
                    control_wins += 1
                print(f\"  {t['name']}: {result.get('winner','?')} wins (+{result.get('improvement',0)}%)\")
        except: pass
print(f\"\n  Total: {completed} tests | Variant wins: {variant_wins} | Control wins: {control_wins}\")
"
    ;;

  *)
    usage
    ;;
esac
