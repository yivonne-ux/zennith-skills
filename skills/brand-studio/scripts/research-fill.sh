#!/usr/bin/env bash
# research-fill.sh — Research similar vibes → generate variants → audit → fill seed bank
# The auto-loop: discover references → compose → generate → audit → store or reject
# Usage: research-fill.sh --brand mirra [--count 3] [--templates comparison,hero,grid]
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE="$SCRIPT_DIR/compose.sh"
AUDIT="$SCRIPT_DIR/audit.sh"
LOOP="$SCRIPT_DIR/loop.sh"
DIGEST="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"
GAIA_DB="$HOME/.openclaw/workspace/gaia-db/gaia.db"
BRANDS_DIR="$HOME/.openclaw/brands"
LOG="$HOME/.openclaw/logs/brand-studio.log"

log() { mkdir -p "$(dirname "$LOG")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FILL] $*" >> "$LOG"; }

BRAND="" COUNT=3 TEMPLATES="comparison,hero,grid"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)     BRAND="$2";     shift 2 ;;
    --count)     COUNT="$2";     shift 2 ;;
    --templates) TEMPLATES="$2"; shift 2 ;;
    --help)
      echo "research-fill.sh — Auto-fill seed bank with brand-compliant ads"
      echo ""
      echo "Usage: research-fill.sh --brand <slug> [--count N] [--templates t1,t2,t3]"
      echo ""
      echo "Pipeline: reference_library → pick template → compose headline → generate → audit → store/reject"
      echo ""
      echo "Options:"
      echo "  --brand <slug>        Brand to generate for (required)"
      echo "  --count <N>           Number of ads to generate (default: 3)"
      echo "  --templates <t1,t2>   Templates to use (default: comparison,hero,grid)"
      exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
DNA="$BRANDS_DIR/$BRAND/DNA.json"
[[ -f "$DNA" ]] || { echo "ERROR: Brand DNA not found: $DNA"; exit 1; }

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  Brand Studio: Research → Generate → Audit → Fill    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "  Brand:     $BRAND"
echo "  Count:     $COUNT"
echo "  Templates: $TEMPLATES"
echo ""

# --- Step 1: Pull reference data from gaia.db ---
echo "━━━ Step 1: Reference Research ━━━"

REF_DATA=$(python3 - "$GAIA_DB" "$BRAND" << 'PYEOF'
import sqlite3, sys, json, random

db = sqlite3.connect(sys.argv[1])
brand = sys.argv[2]

# Get brand_id
row = db.execute("SELECT id FROM brands WHERE name LIKE ?", (f"%{brand}%",)).fetchone()
brand_id = row[0] if row else None

refs = []
if brand_id:
    rows = db.execute("""SELECT content_type, url, description, tags
                         FROM reference_library
                         WHERE brand_id=?
                         ORDER BY RANDOM()""", (brand_id,)).fetchall()
    for r in rows:
        refs.append({"type": r[0], "path": r[1], "desc": r[2], "tags": r[3]})

# Get existing patterns from knowledge
patterns = []
prows = db.execute("SELECT name, occurrences, status FROM patterns ORDER BY occurrences DESC").fetchall()
for p in prows:
    patterns.append({"name": p[0], "count": p[1], "status": p[2]})

# Get blocked patterns (things that failed repeatedly)
blocked = [p["name"] for p in patterns if p.get("status") == "blocked"]

print(json.dumps({"refs": refs, "patterns": patterns, "blocked": blocked}))
PYEOF
)

REF_COUNT=$(echo "$REF_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['refs']))")
PATTERN_COUNT=$(echo "$REF_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['patterns']))")
BLOCKED=$(echo "$REF_DATA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(','.join(d['blocked']) if d['blocked'] else 'none')")

echo "  References found: $REF_COUNT"
echo "  Known patterns: $PATTERN_COUNT"
echo "  Blocked patterns: $BLOCKED"
echo ""

# --- Step 2: Generate headlines per template ---
echo "━━━ Step 2: Headline Generation ━━━"

HEADLINE_DATA=$(python3 - "$DNA" "$TEMPLATES" "$COUNT" << 'PYEOF'
import json, sys, random

with open(sys.argv[1]) as f:
    dna = json.load(f)

templates = sys.argv[2].split(",")
count = int(sys.argv[3])

brand = dna.get("display_name", "Brand")
products = dna.get("products", [])
values = dna.get("values", [])
pillars = dna.get("content_pillars", {})

# Headline bank per template
headline_bank = {
    "comparison": [
        "This or That",
        "Healthy Day vs Cheat Day",
        "Swap This For This",
        "Same Calories, Different Choices",
        "1 Meal vs 2 " + brand + " Meals",
        "900 kcal vs 423 kcal — Your Call",
        "Regular Lunch vs " + brand + " Lunch",
    ],
    "hero": [
        "Your Lunch, Upgraded",
        "Eat Smart. Eat " + brand + ".",
        "Under 500 kcal. Zero Compromise.",
        "Nutritionist Designed. Chef Approved.",
        "Finally, Healthy That Tastes Good",
        "Malaysian Flavours, No Guilt",
        "Fresh. Balanced. Delivered.",
    ],
    "grid": [
        "Counting Calories at Work?",
        "50+ Menus. All Under 500 kcal.",
        "This Week's Menu",
        "Pick Your Bento",
        "Which One Are You Having?",
        "Monday to Friday, Sorted",
    ],
    "lifestyle": [
        "The Perfect Work Lunch",
        "Self-Care Starts With Food",
        "Busy Day, Better Lunch",
        "Your Desk Deserves This",
    ],
    "collage": [
        "50+ International Bento",
        "Variety Is Everything",
        "A Bento For Every Mood",
        "Explore Our Full Menu",
    ],
}

# Pick template+headline combos
combos = []
for i in range(count):
    template = templates[i % len(templates)]
    headlines = headline_bank.get(template, ["Brand Ad"])
    headline = random.choice(headlines)
    combos.append({"template": template, "headline": headline})

print(json.dumps(combos))
PYEOF
)

echo "$HEADLINE_DATA" | python3 -c "
import json, sys
combos = json.load(sys.stdin)
for i, c in enumerate(combos):
    print(f\"  [{i+1}] {c['template']:12s} → \\\"{c['headline']}\\\"\")"
echo ""

# --- Step 3: Generate → Audit Loop ---
echo "━━━ Step 3: Generate → Audit → Store ━━━"
echo ""

PASSED=0
FAILED=0
RESULTS=()

COMBOS_COUNT=$(echo "$HEADLINE_DATA" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

for i in $(seq 0 $((COMBOS_COUNT - 1))); do
  TEMPLATE=$(echo "$HEADLINE_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin)[$i]['template'])")
  HEADLINE=$(echo "$HEADLINE_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin)[$i]['headline'])")

  echo "── [$((i+1))/$COMBOS_COUNT] $TEMPLATE: \"$HEADLINE\" ──"

  # Run the loop (generate + audit + retry)
  LOOP_OUTPUT=$(bash "$LOOP" --brand "$BRAND" --template "$TEMPLATE" --headline "$HEADLINE" --max-retries 2 2>&1) || true

  # Extract results
  BEST_IMAGE=$(echo "$LOOP_OUTPUT" | grep "^BEST_IMAGE=" | cut -d= -f2)
  BEST_SCORE=$(echo "$LOOP_OUTPUT" | grep "^BEST_SCORE=" | cut -d= -f2)
  LOOP_PASSED=$(echo "$LOOP_OUTPUT" | grep "^PASSED=" | cut -d= -f2)

  if [[ "$LOOP_PASSED" == "true" ]]; then
    PASSED=$((PASSED + 1))
    echo "  ✅ PASS ($BEST_SCORE/10) → $BEST_IMAGE"
    RESULTS+=("PASS|$TEMPLATE|$HEADLINE|$BEST_SCORE|$BEST_IMAGE")
  else
    FAILED=$((FAILED + 1))
    echo "  ❌ FAIL ($BEST_SCORE/10) — best effort stored"
    RESULTS+=("FAIL|$TEMPLATE|$HEADLINE|$BEST_SCORE|${BEST_IMAGE:-none}")

    # Compound the failure
    if [[ -f "$DIGEST" ]]; then
      bash "$DIGEST" \
        --source "brand-studio/$BRAND/$(date +%Y-%m-%d)" \
        --type "workflow-metric" \
        --fact "FAILED: brand=$BRAND template=$TEMPLATE headline=$HEADLINE score=$BEST_SCORE — needs investigation" \
        --agent "iris" 2>/dev/null || true
    fi
  fi
  echo ""
done

# --- Final Report ---
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              FILL RESULTS                             ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "  Brand:   $BRAND"
echo "  Total:   $COMBOS_COUNT"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "  Rate:    $((PASSED * 100 / COMBOS_COUNT))%"
echo ""

for r in "${RESULTS[@]}"; do
  STATUS=$(echo "$r" | cut -d'|' -f1)
  TMPL=$(echo "$r" | cut -d'|' -f2)
  HL=$(echo "$r" | cut -d'|' -f3)
  SC=$(echo "$r" | cut -d'|' -f4)
  IMG=$(echo "$r" | cut -d'|' -f5)
  ICON=$([ "$STATUS" = "PASS" ] && echo "✅" || echo "❌")
  echo "  $ICON $TMPL ($SC/10) \"$HL\""
done

echo ""
log "Fill complete: brand=$BRAND count=$COMBOS_COUNT passed=$PASSED failed=$FAILED"
