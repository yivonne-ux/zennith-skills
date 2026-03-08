#!/usr/bin/env bash
# tune.sh — Weekly tuning cycle for Content Factory
# Reads winning patterns, promotes confirmed winners, flags underperformers
# Cron: Sunday 20:00 MYT via Athena
# Safety: 3+ data points AND >20% improvement required for promotion

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
DATA_DIR="$WORKSPACE/data"
ROOMS_DIR="$WORKSPACE/rooms"
LEARNINGS_DIR="$DATA_DIR/learnings"
WINNING_PATTERNS="$DATA_DIR/winning-patterns.jsonl"
TUNING_LOG="$DATA_DIR/tuning-log.jsonl"
CONTENT_INTEL="$HOME/.openclaw/skills/content-intel/SKILL.md"

mkdir -p "$DATA_DIR" "$(dirname "$TUNING_LOG")"

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

log_decision() {
  local decision="$1" pattern_id="$2" evidence="$3"
  printf '{"ts":%s000,"decision":"%s","pattern_id":"%s","evidence":"%s"}\n' \
    "$(date +%s)" "$decision" "$pattern_id" "$evidence" >> "$TUNING_LOG"
}

post_room() {
  local room="$1" msg="$2"
  printf '{"ts":%s000,"agent":"content-tuner","room":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$room" "$msg" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null
}

echo "═══ CONTENT TUNER — Weekly Cycle ═══"
echo "$(date '+%Y-%m-%d %H:%M:%S MYT')"
echo ""

# Step 1: Read winning patterns
if [ ! -f "$WINNING_PATTERNS" ]; then
  echo -e "${YELLOW}No winning-patterns.jsonl found. Creating empty file.${NC}"
  touch "$WINNING_PATTERNS"
fi

TOTAL_PATTERNS=$(wc -l < "$WINNING_PATTERNS" | tr -d ' ')
echo "Winning patterns: $TOTAL_PATTERNS total"

if [ "$TOTAL_PATTERNS" -eq 0 ]; then
  echo -e "${YELLOW}No patterns to tune. Run ad-performance ingest first.${NC}"
  log_decision "no-action" "none" "No winning patterns available"
  post_room "exec" "[Content Tuner] Weekly cycle: 0 patterns found. Need ad-performance data first."
  exit 0
fi

# Step 2: Analyze patterns with Python
echo ""
echo "Analyzing patterns..."

python3 << 'PYEOF'
import json, os, sys
from datetime import datetime, timedelta
from collections import defaultdict

workspace = os.path.expanduser("~/.openclaw/workspace")
patterns_file = os.path.join(workspace, "data/winning-patterns.jsonl")
tuning_log = os.path.join(workspace, "data/tuning-log.jsonl")
rooms_dir = os.path.join(workspace, "rooms")

# Read patterns
patterns = []
with open(patterns_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            patterns.append(json.loads(line))
        except:
            continue

if not patterns:
    print("  No valid patterns found")
    sys.exit(0)

# Group by type/category
by_type = defaultdict(list)
for p in patterns:
    ptype = p.get("type", p.get("pattern_type", "unknown"))
    by_type[ptype].append(p)

print(f"  Pattern types: {dict((k, len(v)) for k, v in by_type.items())}")

# Promotion analysis: 3+ data points AND >20% improvement
promotions = []
confirmations = []
flags = []

for ptype, items in by_type.items():
    for p in items:
        pid = p.get("id", p.get("pattern_id", f"{ptype}-{hash(json.dumps(p, default=str)) % 10000}"))
        data_points = p.get("data_points", p.get("count", 1))
        improvement = p.get("improvement", p.get("lift", 0))
        status = p.get("status", "detected")

        if isinstance(improvement, str):
            try:
                improvement = float(improvement.replace("%", ""))
            except:
                improvement = 0

        if data_points >= 3 and improvement >= 20:
            if status != "promoted":
                promotions.append({
                    "id": pid, "type": ptype,
                    "data_points": data_points,
                    "improvement": improvement,
                    "evidence": p.get("evidence", p.get("description", ""))
                })
            else:
                confirmations.append(pid)
        elif data_points >= 3 and improvement < 5:
            flags.append({
                "id": pid, "type": ptype,
                "data_points": data_points,
                "improvement": improvement
            })

# Report
print(f"\n  RESULTS:")
print(f"  ├─ Promotions (3+ pts, >20% lift): {len(promotions)}")
print(f"  ├─ Confirmations (already promoted): {len(confirmations)}")
print(f"  └─ Flags (underperformers): {len(flags)}")

# Log decisions
ts = int(datetime.now().timestamp() * 1000)
with open(tuning_log, "a") as log:
    for p in promotions:
        entry = {"ts": ts, "decision": "promote", "pattern_id": p["id"],
                 "type": p["type"], "data_points": p["data_points"],
                 "improvement": p["improvement"],
                 "evidence": str(p.get("evidence", ""))[:200]}
        log.write(json.dumps(entry) + "\n")
        print(f"  ✅ PROMOTE: {p['id']} ({p['type']}) — {p['data_points']} pts, +{p['improvement']}%")

    for pid in confirmations:
        entry = {"ts": ts, "decision": "confirm", "pattern_id": pid}
        log.write(json.dumps(entry) + "\n")

    for f in flags:
        entry = {"ts": ts, "decision": "flag", "pattern_id": f["id"],
                 "type": f["type"], "data_points": f["data_points"],
                 "improvement": f["improvement"]}
        log.write(json.dumps(entry) + "\n")
        print(f"  ⚠️  FLAG: {f['id']} ({f['type']}) — {f['data_points']} pts, only +{f['improvement']}%")

# Post to rooms
summary = f"[Content Tuner] Weekly: {len(patterns)} patterns analyzed. {len(promotions)} promoted, {len(confirmations)} confirmed, {len(flags)} flagged."
with open(os.path.join(rooms_dir, "exec.jsonl"), "a") as r:
    r.write(json.dumps({"ts": ts, "agent": "content-tuner", "room": "exec", "msg": summary}) + "\n")

if promotions:
    promo_msg = f"[Content Tuner] New promotions: {', '.join(p['id'] for p in promotions[:5])}"
    with open(os.path.join(rooms_dir, "creative.jsonl"), "a") as r:
        r.write(json.dumps({"ts": ts, "agent": "content-tuner", "room": "creative", "msg": promo_msg}) + "\n")

if flags:
    flag_msg = f"[Content Tuner] Underperformers flagged: {', '.join(f['id'] for f in flags[:5])}. Review needed."
    with open(os.path.join(rooms_dir, "feedback.jsonl"), "a") as r:
        r.write(json.dumps({"ts": ts, "agent": "content-tuner", "room": "feedback", "msg": flag_msg}) + "\n")

# Feed back to compound learnings
learnings_dir = os.path.join(workspace, "data/learnings/global")
os.makedirs(learnings_dir, exist_ok=True)
if promotions:
    with open(os.path.join(learnings_dir, "content-tuner.jsonl"), "a") as lf:
        for p in promotions:
            learning = {
                "ts": ts, "source": "content-tuner", "type": "promotion",
                "pattern_id": p["id"], "pattern_type": p["type"],
                "improvement": p["improvement"],
                "insight": f"Pattern {p['id']} ({p['type']}) promoted: +{p['improvement']}% with {p['data_points']} data points"
            }
            lf.write(json.dumps(learning) + "\n")
    print(f"\n  📚 {len(promotions)} learnings written to global compound layer")

print("\n  ✓ Tuning cycle complete")
PYEOF

echo ""
echo -e "${GREEN}═══ TUNING COMPLETE ═══${NC}"
