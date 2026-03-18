#!/usr/bin/env bash
# curator.sh — Regression curation: 5 types x 3 variations → audit → learn → compound into DNA
# The curator generates a matrix of ads, audits every one, learns what works, feeds back into DNA
# Usage: curator.sh --brand mirra [--types comparison,hero,grid,lifestyle,collage] [--variations 3]
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOOP="$SCRIPT_DIR/loop.sh"
LEARN="$SCRIPT_DIR/learn.sh"
BRANDS_DIR="$HOME/.openclaw/brands"
DIGEST="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"
LOG="$HOME/.openclaw/logs/brand-studio.log"

log() { mkdir -p "$(dirname "$LOG")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [CURATOR] $*" >> "$LOG"; }

# --- Headline banks per template (curated from real MIRRA patterns) ---
declare_headlines() {
  # Returns JSON array of headlines for a given template
  python3 -c "
import json, random
banks = {
    'comparison': [
        'This or That',
        'Healthy Day vs Cheat Day',
        'Swap This For This',
        'Same Calories, Different Choices',
        '1 Meal vs 2 MIRRA Meals',
        '900 kcal vs 423 kcal',
        'Regular Lunch vs MIRRA Lunch',
        'Fast Food vs Smart Food',
    ],
    'hero': [
        'Your Lunch, Upgraded',
        'Eat Smart. Eat Clean.',
        'Under 500 kcal. Zero Compromise.',
        'Nutritionist Designed. Chef Approved.',
        'Finally, Healthy That Tastes Good',
        'Malaysian Flavours, No Guilt',
        'Fresh. Balanced. Delivered.',
        'Your New Favourite Lunch',
    ],
    'grid': [
        'Counting Calories at Work?',
        '50+ Menus. All Under 500 kcal.',
        'This Week s Menu',
        'Pick Your Bento',
        'Which One Are You Having?',
        'Monday to Friday, Sorted',
        'Your Weekly Lineup',
        'Variety is Everything',
    ],
    'lifestyle': [
        'The Perfect Work Lunch',
        'Self-Care Starts With Food',
        'Busy Day, Better Lunch',
        'Your Desk Deserves This',
        'Lunch Hour Glow Up',
        'Feel Good Food',
    ],
    'collage': [
        '50+ International Bento',
        'Variety Is Everything',
        'A Bento For Every Mood',
        'Explore Our Full Menu',
        'So Many Choices',
        'Pick Any. Love All.',
    ],
}

template = '$1'
count = int('$2')
pool = banks.get(template, ['Brand Ad'])
random.shuffle(pool)
print(json.dumps(pool[:count]))
"
}

# --- Args ---
BRAND="" TYPES="comparison,hero,grid,lifestyle,collage" VARIATIONS=3 MAX_RETRIES=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)      BRAND="$2";      shift 2 ;;
    --types)      TYPES="$2";      shift 2 ;;
    --variations) VARIATIONS="$2"; shift 2 ;;
    --max-retries) MAX_RETRIES="$2"; shift 2 ;;
    --help)
      echo "curator.sh — Regression curation pipeline"
      echo ""
      echo "Usage: curator.sh --brand <slug> [--types t1,t2,...] [--variations N]"
      echo ""
      echo "Generates a matrix of ad types x variations, audits each,"
      echo "learns what works, and compounds findings back into brand DNA."
      echo ""
      echo "Options:"
      echo "  --brand <slug>         Brand to curate (required)"
      echo "  --types <t1,t2,...>    Ad types (default: comparison,hero,grid,lifestyle,collage)"
      echo "  --variations <N>       Variations per type (default: 3)"
      echo "  --max-retries <N>      Max retries per variation (default: 2)"
      exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
DNA="$BRANDS_DIR/$BRAND/DNA.json"
[[ -f "$DNA" ]] || { echo "ERROR: Brand DNA not found: $DNA"; exit 1; }

IFS=',' read -r -a TYPE_ARR <<< "$TYPES"
TOTAL=$((${#TYPE_ARR[@]} * VARIATIONS))
RUN_ID="curator-$(date +%Y%m%d-%H%M%S)"
RESULTS_DIR="$HOME/.openclaw/workspace/data/brand-studio/curator-runs/$RUN_ID"
mkdir -p "$RESULTS_DIR"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           CURATOR — Regression Curation Pipeline          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  Brand:      $BRAND"
echo "  Types:      ${TYPES}"
echo "  Variations: $VARIATIONS per type"
echo "  Total:      $TOTAL ads"
echo "  Max retry:  $MAX_RETRIES per ad"
echo "  Run ID:     $RUN_ID"
echo ""

# --- Tracking ---
TOTAL_PASS=0
TOTAL_FAIL=0
TYPE_SCORES=""  # Will collect JSON lines

# --- Per-type loop ---
TYPE_IDX=0
for TEMPLATE in "${TYPE_ARR[@]}"; do
  TYPE_IDX=$((TYPE_IDX + 1))
  echo "╔══════════════════════════════════════════╗"
  echo "║  Type $TYPE_IDX/${#TYPE_ARR[@]}: $TEMPLATE"
  echo "╚══════════════════════════════════════════╝"
  echo ""

  # Get headlines for this type
  HEADLINES_JSON=$(declare_headlines "$TEMPLATE" "$VARIATIONS")
  TYPE_PASS=0
  TYPE_FAIL=0
  TYPE_TOTAL_SCORE=0

  for v in $(seq 0 $((VARIATIONS - 1))); do
    HEADLINE=$(echo "$HEADLINES_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)[$v])")
    GLOBAL_IDX=$(( (TYPE_IDX - 1) * VARIATIONS + v + 1 ))

    echo "── [$GLOBAL_IDX/$TOTAL] $TEMPLATE v$((v+1)): \"$HEADLINE\" ──"

    # Run the loop (generate → audit → retry)
    LOOP_OUTPUT=$(bash "$LOOP" --brand "$BRAND" --template "$TEMPLATE" --headline "$HEADLINE" --max-retries "$MAX_RETRIES" 2>&1) || true

    # Extract results
    BEST_IMAGE=$(echo "$LOOP_OUTPUT" | grep "^BEST_IMAGE=" | cut -d= -f2)
    BEST_SCORE=$(echo "$LOOP_OUTPUT" | grep "^BEST_SCORE=" | cut -d= -f2)
    LOOP_PASSED=$(echo "$LOOP_OUTPUT" | grep "^PASSED=" | cut -d= -f2)
    BEST_SCORE=${BEST_SCORE:-0}

    # Record result
    RESULT_FILE="$RESULTS_DIR/${TEMPLATE}_v$((v+1)).json"
    python3 -c "
import json
result = {
    'template': '$TEMPLATE',
    'variation': $((v+1)),
    'headline': '''$HEADLINE''',
    'score': float('$BEST_SCORE'),
    'passed': '$LOOP_PASSED' == 'true',
    'image': '$BEST_IMAGE',
    'run_id': '$RUN_ID'
}
with open('$RESULT_FILE', 'w') as f:
    json.dump(result, f, indent=2)
"

    if [[ "$LOOP_PASSED" == "true" ]]; then
      TYPE_PASS=$((TYPE_PASS + 1))
      TOTAL_PASS=$((TOTAL_PASS + 1))
      echo "  PASS ($BEST_SCORE/10) -> $BEST_IMAGE"
    else
      TYPE_FAIL=$((TYPE_FAIL + 1))
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
      echo "  FAIL ($BEST_SCORE/10)"
    fi

    TYPE_TOTAL_SCORE=$(python3 -c "print(float('$TYPE_TOTAL_SCORE') + float('$BEST_SCORE'))")
    echo ""
  done

  TYPE_AVG=$(python3 -c "print(round(float('$TYPE_TOTAL_SCORE') / $VARIATIONS, 2))")
  echo "  [$TEMPLATE] Pass: $TYPE_PASS/$VARIATIONS | Avg score: $TYPE_AVG/10"
  echo ""

  # Collect type-level scores as JSON line
  TYPE_SCORES="${TYPE_SCORES}
{\"template\":\"$TEMPLATE\",\"passed\":$TYPE_PASS,\"failed\":$TYPE_FAIL,\"avg_score\":$TYPE_AVG,\"total\":$VARIATIONS}"
done

# --- Final Summary ---
OVERALL_AVG=$(python3 -c "
pass_count = $TOTAL_PASS
fail_count = $TOTAL_FAIL
total = pass_count + fail_count
import glob, json, os
scores = []
for f in glob.glob('$RESULTS_DIR/*.json'):
    with open(f) as fh:
        d = json.load(fh)
        scores.append(d['score'])
avg = sum(scores)/len(scores) if scores else 0
print(round(avg, 2))
")

PASS_RATE=$((TOTAL_PASS * 100 / TOTAL))

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              CURATOR REGRESSION REPORT                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  Run ID:     $RUN_ID"
echo "  Brand:      $BRAND"
echo "  Total:      $TOTAL ads"
echo "  Passed:     $TOTAL_PASS ($PASS_RATE%)"
echo "  Failed:     $TOTAL_FAIL"
echo "  Avg Score:  $OVERALL_AVG/10"
echo ""
echo "  ── Per-Type Breakdown ──"
echo "$TYPE_SCORES" | python3 -c "
import json, sys
lines = [l.strip() for l in sys.stdin if l.strip()]
for line in lines:
    d = json.loads(line)
    icon = 'OK' if d['passed'] == d['total'] else 'MX'
    print(f\"  [{icon}] {d['template']:12s}  {d['passed']}/{d['total']} pass  avg={d['avg_score']}/10\")
"
echo ""

# --- Write summary JSON ---
SUMMARY_FILE="$RESULTS_DIR/summary.json"
python3 - "$RESULTS_DIR" "$BRAND" "$RUN_ID" "$TOTAL" "$TOTAL_PASS" "$TOTAL_FAIL" "$OVERALL_AVG" << 'PYEOF'
import json, glob, sys, os
from datetime import datetime

results_dir = sys.argv[1]
brand = sys.argv[2]
run_id = sys.argv[3]
total = int(sys.argv[4])
passed = int(sys.argv[5])
failed = int(sys.argv[6])
avg = float(sys.argv[7])

# Collect all individual results
results = []
for f in sorted(glob.glob(os.path.join(results_dir, '*.json'))):
    if os.path.basename(f) == 'summary.json':
        continue
    with open(f) as fh:
        results.append(json.load(fh))

# Group by template
by_type = {}
for r in results:
    t = r['template']
    if t not in by_type:
        by_type[t] = {'passed': 0, 'failed': 0, 'scores': [], 'best_headline': '', 'best_score': 0}
    by_type[t]['scores'].append(r['score'])
    if r['passed']:
        by_type[t]['passed'] += 1
    else:
        by_type[t]['failed'] += 1
    if r['score'] > by_type[t]['best_score']:
        by_type[t]['best_score'] = r['score']
        by_type[t]['best_headline'] = r['headline']

type_summary = {}
for t, data in by_type.items():
    type_summary[t] = {
        'pass_rate': data['passed'] / (data['passed'] + data['failed']) if (data['passed'] + data['failed']) > 0 else 0,
        'avg_score': round(sum(data['scores']) / len(data['scores']), 2) if data['scores'] else 0,
        'best_headline': data['best_headline'],
        'best_score': data['best_score'],
        'passed': data['passed'],
        'failed': data['failed'],
    }

summary = {
    'run_id': run_id,
    'brand': brand,
    'timestamp': datetime.utcnow().isoformat() + 'Z',
    'total': total,
    'passed': passed,
    'failed': failed,
    'pass_rate': round(passed / total, 3) if total > 0 else 0,
    'avg_score': avg,
    'by_type': type_summary,
    'results': results,
}

with open(os.path.join(results_dir, 'summary.json'), 'w') as f:
    json.dump(summary, f, indent=2)
print(json.dumps(summary, indent=2))
PYEOF

echo ""
echo "  Summary: $SUMMARY_FILE"

# --- Run learn.sh to compound findings into DNA ---
echo ""
echo "━━━ Compounding Learnings into DNA ━━━"
if [[ -x "$LEARN" ]] || [[ -f "$LEARN" ]]; then
  bash "$LEARN" --brand "$BRAND" --run "$RESULTS_DIR" 2>&1 || true
else
  echo "  (learn.sh not found — skipping DNA compounding)"
fi

# --- Compound to knowledge ---
if [[ -f "$DIGEST" ]]; then
  bash "$DIGEST" \
    --source "curator/$BRAND/$RUN_ID" \
    --type "workflow-metric" \
    --fact "CURATOR: brand=$BRAND total=$TOTAL passed=$TOTAL_PASS failed=$TOTAL_FAIL avg=$OVERALL_AVG pass_rate=${PASS_RATE}%" \
    --agent "iris" 2>/dev/null || true
fi

log "Curator complete: brand=$BRAND run=$RUN_ID total=$TOTAL passed=$TOTAL_PASS failed=$TOTAL_FAIL avg=$OVERALL_AVG"
echo ""
echo "PASS_RATE=${PASS_RATE}%"
echo "AVG_SCORE=$OVERALL_AVG"
echo "RUN_ID=$RUN_ID"
