#!/usr/bin/env bash
# composer.sh — Block workflow composer/executor
# Reads a workflow from manifest.json and executes blocks in chain order
# Usage: composer.sh --brand mirra --workflow research-fill
#        composer.sh --brand mirra --blocks "compose,audit" --headline "This or That" --template comparison
#        composer.sh --list
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOCKS_DIR="$SCRIPT_DIR/../blocks"
MANIFEST="$BLOCKS_DIR/manifest.json"
LOG="$HOME/.openclaw/logs/brand-studio.log"

log() { mkdir -p "$(dirname "$LOG")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMPOSER] $*" >> "$LOG"; }

# --- Parse args ---
BRAND="" WORKFLOW="" BLOCKS="" TEMPLATE="" HEADLINE="" SUBTITLE="" VARIATIONS=3 TYPES="" MAX_RETRIES=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)      BRAND="$2";      shift 2 ;;
    --workflow)   WORKFLOW="$2";    shift 2 ;;
    --blocks)     BLOCKS="$2";     shift 2 ;;
    --template)   TEMPLATE="$2";   shift 2 ;;
    --headline)   HEADLINE="$2";   shift 2 ;;
    --subtitle)   SUBTITLE="$2";   shift 2 ;;
    --variations) VARIATIONS="$2"; shift 2 ;;
    --types)      TYPES="$2";      shift 2 ;;
    --max-retries) MAX_RETRIES="$2"; shift 2 ;;
    --list)
      echo "Available workflows:"
      python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
wfs = m.get('connections', {}).get('workflows', {})
for k, v in wfs.items():
    print(f'  {k:20s} — {v[\"description\"]}')
    print(f'  {\" \":20s}   chain: {\" → \".join(v.get(\"chain\", []))}')
    print()
"
      echo "Available blocks:"
      python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
for k, v in m['blocks'].items():
    cat = v.get('category', '?')
    print(f'  [{cat:8s}] {k:12s} — {v[\"description\"]}')
"
      exit 0 ;;
    --help)
      echo "composer.sh — Composable workflow executor"
      echo ""
      echo "Usage:"
      echo "  composer.sh --brand <slug> --workflow <name>     Run a pre-wired workflow"
      echo "  composer.sh --brand <slug> --blocks \"a,b,c\"      Run custom block chain"
      echo "  composer.sh --list                               List workflows and blocks"
      echo ""
      echo "Workflows: single-ad, loop-ad, research-fill, curator-regression, discovery-loop"
      echo ""
      echo "Options:"
      echo "  --template <type>      Template (comparison, hero, grid, lifestyle, collage)"
      echo "  --headline <text>      Headline text"
      echo "  --variations <N>       Variations per type (for curator)"
      echo "  --types <t1,t2,...>    Ad types (for curator)"
      echo "  --max-retries <N>      Max retries per generation"
      exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$WORKFLOW" ]] && [[ -z "$BLOCKS" ]]; then
  echo "ERROR: --workflow or --blocks required (use --list to see options)"
  exit 1
fi

# --- Resolve workflow to block list ---
if [[ -n "$WORKFLOW" ]]; then
  BLOCK_LIST=$(python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
wf = m.get('connections', {}).get('workflows', {}).get('$WORKFLOW')
if not wf:
    print('ERROR')
else:
    blocks = [b['block'] for b in wf.get('blocks', [])]
    print(','.join(blocks))
")
  if [[ "$BLOCK_LIST" == "ERROR" ]]; then
    echo "ERROR: Unknown workflow: $WORKFLOW"
    echo "Use --list to see available workflows."
    exit 1
  fi
else
  BLOCK_LIST="$BLOCKS"
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           COMPOSER — Block Workflow Engine                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  Workflow:  ${WORKFLOW:-custom}"
echo "  Blocks:    $BLOCK_LIST"
echo "  Brand:     $BRAND"
[[ -n "$TEMPLATE" ]]  && echo "  Template:  $TEMPLATE"
[[ -n "$HEADLINE" ]]  && echo "  Headline:  $HEADLINE"
echo ""

IFS=',' read -r -a BLOCK_ARR <<< "$BLOCK_LIST"

# --- State passing between blocks (JSON pipe) ---
PIPE_STATE="{}"
PIPE_FILE=$(mktemp /tmp/composer-pipe.XXXXXX)
echo "$PIPE_STATE" > "$PIPE_FILE"

STEP=0
for BLOCK in "${BLOCK_ARR[@]}"; do
  STEP=$((STEP + 1))
  echo "━━━ Step $STEP: [$BLOCK] ━━━"

  case "$BLOCK" in
    research)
      echo "  Running reference research..."
      OUTPUT=$(python3 - "$HOME/.openclaw/workspace/gaia-db/gaia.db" "$BRAND" << 'PYEOF'
import sqlite3, sys, json
db = sqlite3.connect(sys.argv[1])
brand = sys.argv[2]
row = db.execute("SELECT id FROM brands WHERE name LIKE ?", (f"%{brand}%",)).fetchone()
brand_id = row[0] if row else None
refs = []
if brand_id:
    rows = db.execute("SELECT content_type, url, description FROM reference_library WHERE brand_id=? ORDER BY RANDOM() LIMIT 10", (brand_id,)).fetchall()
    for r in rows:
        refs.append({"type": r[0], "path": r[1], "desc": r[2]})
patterns = []
prows = db.execute("SELECT name, occurrences, status FROM patterns ORDER BY occurrences DESC LIMIT 20").fetchall()
for p in prows:
    patterns.append({"name": p[0], "count": p[1], "status": p[2]})
blocked = [p["name"] for p in patterns if p.get("status") == "blocked"]
print(json.dumps({"refs": refs, "patterns": patterns, "blocked": blocked}))
PYEOF
      )
      echo "$OUTPUT" > "$PIPE_FILE"
      REF_COUNT=$(echo "$OUTPUT" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('refs',[])))")
      echo "  Found $REF_COUNT references"
      ;;

    headline)
      TMPL="${TEMPLATE:-comparison}"
      echo "  Generating headlines for $TMPL..."
      # Pass-through: just generate headlines
      python3 -c "
import json, random
banks = {
    'comparison': ['This or That','Healthy Day vs Cheat Day','Swap This For This','900 kcal vs 423 kcal','Regular Lunch vs MIRRA Lunch'],
    'hero': ['Your Lunch Upgraded','Under 500 kcal. Zero Compromise.','Nutritionist Designed. Chef Approved.','Fresh. Balanced. Delivered.'],
    'grid': ['Counting Calories at Work?','50+ Menus. All Under 500 kcal.','Pick Your Bento','Monday to Friday Sorted'],
    'lifestyle': ['The Perfect Work Lunch','Self-Care Starts With Food','Busy Day Better Lunch'],
    'collage': ['50+ International Bento','Variety Is Everything','A Bento For Every Mood'],
}
pool = banks.get('$TMPL', ['Brand Ad'])
random.shuffle(pool)
headlines = pool[:${VARIATIONS}]
print(json.dumps({'headlines': headlines, 'template': '$TMPL'}))
" > "$PIPE_FILE"
      echo "  Generated $(python3 -c "import json; print(len(json.load(open('$PIPE_FILE'))['headlines']))" ) headlines"
      ;;

    compose)
      TMPL="${TEMPLATE:-comparison}"
      HL="${HEADLINE:-$(python3 -c "import json; print(json.load(open('$PIPE_FILE')).get('headlines',['Ad'])[0])" 2>/dev/null || echo 'Ad')}"
      echo "  Composing: $TMPL / \"$HL\"..."
      COMPOSE_OUT=$(bash "$SCRIPT_DIR/compose.sh" --brand "$BRAND" --template "$TMPL" --headline "$HL" 2>&1) || true
      IMG=$(echo "$COMPOSE_OUT" | grep "OUTPUT_PATH=" | tail -1 | sed 's/OUTPUT_PATH=//')
      echo "{\"image\":\"$IMG\",\"template\":\"$TMPL\",\"headline\":\"$HL\"}" > "$PIPE_FILE"
      echo "  Generated: $IMG"
      ;;

    generate)
      echo "  Raw generate via NanoBanana..."
      NANO_PROMPT="${HEADLINE:-Generate a brand ad}"
      NANO_OUT=$(bash "$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh" generate --brand "$BRAND" --use-case social --prompt "$NANO_PROMPT" --ratio "${RATIO:-1:1}" 2>&1) || true
      IMG=$(echo "$NANO_OUT" | grep "Output:" | sed 's/.*Output:[[:space:]]*//' | tr -d '[:space:]')
      echo "{\"image\":\"$IMG\"}" > "$PIPE_FILE"
      echo "  Generated: $IMG"
      ;;

    audit)
      IMG=$(python3 -c "import json; print(json.load(open('$PIPE_FILE')).get('image',''))" 2>/dev/null || echo "")
      if [[ -z "$IMG" ]] || [[ ! -f "$IMG" ]]; then
        echo "  WARN: No image to audit in pipe state"
      else
        echo "  Auditing: $IMG..."
        AUDIT_OUT=$(bash "$SCRIPT_DIR/audit.sh" --brand "$BRAND" --image "$IMG" 2>&1) || true
        echo "$AUDIT_OUT"
        SCORE=$(echo "$AUDIT_OUT" | grep "Result:" | grep -o '[0-9.]*' | head -1)
        PASSED=$(echo "$AUDIT_OUT" | grep -c "PASS" || true)
        echo "  Score: ${SCORE:-?}/10"
      fi
      ;;

    loop)
      TMPL="${TEMPLATE:-comparison}"
      HL="${HEADLINE:-$(python3 -c "import json; print(json.load(open('$PIPE_FILE')).get('headlines',['This or That'])[0])" 2>/dev/null || echo 'This or That')}"
      echo "  Running loop: $TMPL / \"$HL\"..."
      LOOP_OUT=$(bash "$SCRIPT_DIR/loop.sh" --brand "$BRAND" --template "$TMPL" --headline "$HL" --max-retries "$MAX_RETRIES" 2>&1) || true
      BEST_IMAGE=$(echo "$LOOP_OUT" | grep "^BEST_IMAGE=" | cut -d= -f2)
      BEST_SCORE=$(echo "$LOOP_OUT" | grep "^BEST_SCORE=" | cut -d= -f2)
      LOOP_PASSED=$(echo "$LOOP_OUT" | grep "^PASSED=" | cut -d= -f2)
      echo "{\"image\":\"$BEST_IMAGE\",\"score\":$BEST_SCORE,\"passed\":$([ \"$LOOP_PASSED\" = 'true' ] && echo 'true' || echo 'false')}" > "$PIPE_FILE"
      ICON=$([ "$LOOP_PASSED" = "true" ] && echo "PASS" || echo "FAIL")
      echo "  $ICON ($BEST_SCORE/10) -> $BEST_IMAGE"
      ;;

    store)
      echo "  Storing to seed bank..."
      PIPE_DATA=$(cat "$PIPE_FILE")
      IMG=$(echo "$PIPE_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('image',''))" 2>/dev/null || echo "")
      PASSED=$(echo "$PIPE_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('passed',False))" 2>/dev/null || echo "False")
      if [[ "$PASSED" == "True" ]] && [[ -n "$IMG" ]] && [[ -f "$IMG" ]]; then
        SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"
        if [[ -f "$SEED_STORE" ]]; then
          bash "$SEED_STORE" add --brand "$BRAND" --type "${TEMPLATE:-ad}" --content "$IMG" 2>/dev/null || true
          echo "  Stored: $IMG"
        fi
      else
        echo "  Skipped (not passed or no image)"
      fi
      ;;

    learn)
      RUN_DIR=$(python3 -c "import json; print(json.load(open('$PIPE_FILE')).get('run_dir',''))" 2>/dev/null || echo "")
      if [[ -n "$RUN_DIR" ]] && [[ -d "$RUN_DIR" ]]; then
        echo "  Compounding learnings..."
        bash "$SCRIPT_DIR/learn.sh" --brand "$BRAND" --run "$RUN_DIR" 2>&1 || true
      else
        echo "  No run directory in pipe — skipping learn"
      fi
      ;;

    curator)
      echo "  Running full curator regression..."
      CURATOR_TYPES="${TYPES:-comparison,hero,grid,lifestyle,collage}"
      CURATOR_OUT=$(bash "$SCRIPT_DIR/curator.sh" --brand "$BRAND" --types "$CURATOR_TYPES" --variations "$VARIATIONS" --max-retries "$MAX_RETRIES" 2>&1) || true
      echo "$CURATOR_OUT" | tail -20
      RUN_ID=$(echo "$CURATOR_OUT" | grep "^RUN_ID=" | cut -d= -f2)
      RUN_DIR="$HOME/.openclaw/workspace/data/brand-studio/curator-runs/$RUN_ID"
      echo "{\"run_id\":\"$RUN_ID\",\"run_dir\":\"$RUN_DIR\"}" > "$PIPE_FILE"
      ;;

    *)
      echo "  WARN: Unknown block: $BLOCK"
      ;;
  esac
  echo ""
done

rm -f "$PIPE_FILE"

echo "━━━ Composer Complete ━━━"
log "Composer complete: workflow=${WORKFLOW:-custom} blocks=$BLOCK_LIST brand=$BRAND"
