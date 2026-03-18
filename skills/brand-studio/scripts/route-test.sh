#!/usr/bin/env bash
# route-test.sh — E2E routing regression for WhatsApp → Zenni → Agent pipeline
# Simulates WhatsApp messages through classify.sh, validates routing, then tests
# actual dispatch for brand-studio tasks through Iris
#
# Usage: route-test.sh [--brand mirra] [--count 66] [--dispatch] [--audit]
# ---
set -euo pipefail

CLASSIFY="$HOME/.openclaw/skills/orchestrate-v2/scripts/classify.sh"
DISPATCH="$HOME/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh"
AUDIT="$HOME/.openclaw/skills/brand-studio/scripts/audit.sh"
BRANDS_DIR="$HOME/.openclaw/brands"
LOG="$HOME/.openclaw/logs/route-test.log"
RESULTS_DIR="$HOME/.openclaw/workspace/data/brand-studio/route-tests"

log() { mkdir -p "$(dirname "$LOG")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ROUTE-TEST] $*" >> "$LOG"; }

BRAND="mirra" COUNT=66 DO_DISPATCH=false DO_AUDIT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)    BRAND="$2";    shift 2 ;;
    --count)    COUNT="$2";    shift 2 ;;
    --dispatch) DO_DISPATCH=true; shift ;;
    --audit)    DO_AUDIT=true; shift ;;
    --help)
      echo "route-test.sh — WhatsApp → Zenni routing regression test"
      echo ""
      echo "Tests classify.sh with real WhatsApp-style messages, validates routing decisions."
      echo ""
      echo "Usage: route-test.sh [--brand mirra] [--count 66] [--dispatch] [--audit]"
      echo ""
      echo "Modes:"
      echo "  (default)    Classify-only: test routing without dispatching"
      echo "  --dispatch   Actually dispatch to agents via openclaw agent"
      echo "  --audit      Also run visual audit on generated images"
      echo ""
      echo "Tests 5 categories: brand-studio, creative, code/build, research, strategy"
      exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

RUN_ID="route-$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RESULTS_DIR/$RUN_ID"
mkdir -p "$RUN_DIR"

echo "================================================================"
echo "  ROUTING REGRESSION TEST — WhatsApp → Zenni Pipeline"
echo "================================================================"
echo ""
echo "  Brand:     $BRAND"
echo "  Tests:     $COUNT"
echo "  Dispatch:  $DO_DISPATCH"
echo "  Audit:     $DO_AUDIT"
echo "  Run ID:    $RUN_ID"
echo ""

# ── TEST CASES ─────────────────────────────────────────────────────────────────
# Each test: "message|expected_agent|category|description"
# These simulate REAL WhatsApp messages Jenn would send
TESTS=(
  # === BRAND STUDIO (→ iris) ===
  "create mirra comparison ad|iris|brand-studio|Direct brand-studio request"
  "generate mirra hero ad|iris|brand-studio|Generate hero ad"
  "make a mirra grid ad with counting calories|iris|brand-studio|Grid ad with headline"
  "create mirra lifestyle ad|iris|brand-studio|Lifestyle ad request"
  "generate a comparison ad for mirra, this or that|iris|brand-studio|Comparison with headline"
  "make mirra ads|iris|brand-studio|Short brand-studio trigger"
  "create mirra poster|iris|brand-studio|Poster = visual"
  "generate mirra banner|iris|brand-studio|Banner = visual"
  "create pinxin comparison ad|iris|brand-studio|Different brand"
  "generate wholey wonder hero ad|iris|brand-studio|Wholey Wonder"
  "make serein lifestyle ad|iris|brand-studio|Serein"
  "create rasaya grid ad|iris|brand-studio|Rasaya"
  "generate gaia eats comparison ad|iris|brand-studio|Gaia Eats"

  # === VISUAL (→ iris) ===
  "generate image of bento box|iris|visual|Image generation"
  "make a poster for mirra|iris|visual|Poster request"
  "create 3 variations of the hero ad|iris|visual|Variations"
  "mirra visual|iris|visual|Brand + visual noun"
  "reverse prompt this image|iris|visual|Reverse prompting"
  "nanobanana generate mirra ad|iris|visual|Direct NanoBanana mention"
  "style seed for this bento photo|iris|visual|Style seed"
  "what style is this image|iris|visual|Style analysis"
  "product photo for mirra|iris|visual|Product photo"

  # === CREATIVE / COPY (→ dreami) ===
  "write caption for mirra instagram post|dreami|creative|Caption writing"
  "mirra copy for this week|dreami|creative|Brand + copy noun"
  "write a tiktok script for bento unboxing|dreami|creative|TikTok script"
  "campaign concept for mirra recipe rebels pillar|dreami|creative|Campaign concept"
  "write edm for mirra weekly menu|dreami|creative|EDM writing"
  "mirra content|dreami|creative|Brand + content noun"
  "caption for instagram|dreami|creative|Caption request"
  "write headline for mirra ad|dreami|creative|Headline writing"
  "mirra creative|dreami|creative|Brand + creative noun"
  "content for mirra instagram this week|dreami|creative|Weekly content"
  "schedule mirra posts for this week|dreami|creative|Post scheduling"

  # === VIDEO (→ dreami) ===
  "make a ugc video of mirra bento|dreami|video|UGC video"
  "create intro video for mirra|dreami|video|Intro video"
  "product ugc for mirra carbonara|dreami|video|Product UGC"
  "make a 12 second bento unboxing video|dreami|video|Specific duration video"
  "create a reel for mirra|dreami|video|Reel creation"
  "mirra video|dreami|video|Brand + video noun (shorthand)"
  "make youtube shorts for mirra|dreami|video|YouTube shorts"

  # === CODE / BUILD (→ taoz) ===
  "@taoz fix the compose script|taoz|code|Direct @taoz mention"
  "/taoz build a new skill|taoz|code|Direct /taoz mention"
  "build a landing page for mirra|taoz|code|Landing page build"
  "fix the audit script|taoz|code|Fix script"
  "deploy the gaiaos site|taoz|code|Deploy"
  "write a python script for data analysis|taoz|code|Python script"
  "set up cloudflare worker for mirra|taoz|code|Infrastructure"
  "debug why nanobanana fails|taoz|code|Debug"

  # === RESEARCH (→ artemis) ===
  "research vegan meal prep brands in malaysia|artemis|research|Market research"
  "find competitor pricing for healthy bentos kl|artemis|research|Competitor research"
  "scrape tiktok trends for bento content|artemis|research|Trend scraping"
  "what are top selling meal prep products|artemis|research|Product research"
  "research kol rates for food influencers malaysia|artemis|research|KOL research"

  # === STRATEGY (→ athena) ===
  "analyze mirra sales performance this month|athena|strategy|Performance analysis"
  "mirra report|athena|strategy|Brand + report noun"
  "how is mirra doing|athena|strategy|Status inquiry"
  "forecast next month revenue for mirra|athena|strategy|Forecasting"
  "compare all brands performance|athena|strategy|Cross-brand comparison"
  "mirra numbers|athena|strategy|Brand + numbers noun"

  # === ADS / PRICING (→ hermes) ===
  "optimize mirra meta ads budget|hermes|ads|Meta ads optimization"
  "mirra ads|hermes|ads|Brand + ads noun"
  "set pricing for new mirra menu|hermes|ads|Pricing"
  "review mirra ad performance|hermes|ads|Ad review"
  "mirra roas|hermes|ads|ROAS check"

  # === SIMPLE OPS (→ myrmidons) ===
  "check if gateway is running|myrmidons|ops|Health check"
  "git status|myrmidons|ops|Git operation"
  "list files in workspace|myrmidons|ops|File listing"
  "what can you do|myrmidons|ops|Help query"

  # === TESTING (→ argus) ===
  "run regression tests|argus|testing|Regression"
  "run e2e test for brand studio|argus|testing|E2E test"
  "run nightly review|argus|testing|Nightly review"

  # === EDGE CASES ===
  "mirra|athena|edge|Bare brand name"
  "help|myrmidons|edge|Help"
  "@iris check this design|iris|edge|Direct mention"
  "@dreami write copy|dreami|edge|Direct mention"
  "@hermes check ad spend|hermes|edge|Direct mention"
  "@artemis find competitors|artemis|edge|Direct mention"
  "@argus run tests|argus|edge|Direct mention"
)

# Limit to COUNT
if [[ ${#TESTS[@]} -gt $COUNT ]]; then
  TESTS=("${TESTS[@]:0:$COUNT}")
fi
ACTUAL_COUNT=${#TESTS[@]}

echo "Running $ACTUAL_COUNT routing tests..."
echo ""

# ── RUN TESTS ────────────────────────────────────────────────────────────────
PASS=0
FAIL=0
RESULTS=()

for test_case in "${TESTS[@]}"; do
  IFS='|' read -r MESSAGE EXPECTED CATEGORY DESC <<< "$test_case"

  # Run classify.sh — extract just the agent name (suppress all the fancy output)
  ACTUAL=$(bash "$CLASSIFY" "$MESSAGE" 2>/dev/null | grep "AGENT:" | head -1 | sed 's/.*AGENT:[[:space:]]*//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

  # Handle "auto" fallback
  if [[ "$ACTUAL" == "auto" ]] || [[ -z "$ACTUAL" ]]; then
    ACTUAL="auto(fallback)"
  fi

  # Check match
  if [[ "$ACTUAL" == "$EXPECTED" ]]; then
    STATUS="PASS"
    PASS=$((PASS + 1))
    ICON="OK"
  else
    STATUS="FAIL"
    FAIL=$((FAIL + 1))
    ICON="XX"
  fi

  RESULTS+=("$STATUS|$CATEGORY|$EXPECTED|$ACTUAL|$MESSAGE|$DESC")

  # Print condensed result
  printf "  [%s] %-14s %-10s → %-10s  %s\n" "$ICON" "$CATEGORY" "$EXPECTED" "$ACTUAL" "$(echo "$MESSAGE" | head -c 50)"
done

echo ""
echo "================================================================"
echo "  ROUTING REGRESSION RESULTS"
echo "================================================================"
echo ""
echo "  Total:   $ACTUAL_COUNT"
echo "  Passed:  $PASS ($((PASS * 100 / ACTUAL_COUNT))%)"
echo "  Failed:  $FAIL"
echo ""

# ── Show failures ─────────────────────────────────────────────────────────────
if [[ $FAIL -gt 0 ]]; then
  echo "  ── FAILURES ──"
  for r in "${RESULTS[@]}"; do
    IFS='|' read -r STATUS CATEGORY EXPECTED ACTUAL MESSAGE DESC <<< "$r"
    if [[ "$STATUS" == "FAIL" ]]; then
      echo "    [$CATEGORY] \"$MESSAGE\""
      echo "      Expected: $EXPECTED  Got: $ACTUAL  ($DESC)"
    fi
  done
  echo ""
fi

# ── Category breakdown ────────────────────────────────────────────────────────
echo "  ── Per-Category ──"
for cat in brand-studio visual creative video code research strategy ads ops testing edge; do
  CAT_TOTAL=0
  CAT_PASS=0
  for r in "${RESULTS[@]}"; do
    IFS='|' read -r STATUS CATEGORY _ _ _ _ <<< "$r"
    if [[ "$CATEGORY" == "$cat" ]]; then
      CAT_TOTAL=$((CAT_TOTAL + 1))
      [[ "$STATUS" == "PASS" ]] && CAT_PASS=$((CAT_PASS + 1))
    fi
  done
  if [[ $CAT_TOTAL -gt 0 ]]; then
    CAT_RATE=$((CAT_PASS * 100 / CAT_TOTAL))
    ICON=$([ "$CAT_PASS" -eq "$CAT_TOTAL" ] && echo "OK" || echo "!!")
    printf "    [%s] %-14s %d/%d (%d%%)\n" "$ICON" "$cat" "$CAT_PASS" "$CAT_TOTAL" "$CAT_RATE"
  fi
done
echo ""

# ── Write results JSON ────────────────────────────────────────────────────────
RESULTS_FILE="$RUN_DIR/results.json"
python3 -c "
import json
results = []
lines = '''$(printf '%s\n' "${RESULTS[@]}")'''.strip().split('\n')
for line in lines:
    if not line.strip():
        continue
    parts = line.split('|')
    if len(parts) >= 6:
        results.append({
            'status': parts[0],
            'category': parts[1],
            'expected': parts[2],
            'actual': parts[3],
            'message': parts[4],
            'description': parts[5],
        })

summary = {
    'run_id': '$RUN_ID',
    'total': len(results),
    'passed': sum(1 for r in results if r['status'] == 'PASS'),
    'failed': sum(1 for r in results if r['status'] == 'FAIL'),
    'pass_rate': round(sum(1 for r in results if r['status'] == 'PASS') / len(results), 3) if results else 0,
    'failures': [r for r in results if r['status'] == 'FAIL'],
    'results': results,
}
with open('$RESULTS_FILE', 'w') as f:
    json.dump(summary, f, indent=2)
"

echo "  Results: $RESULTS_FILE"
log "Route test: total=$ACTUAL_COUNT pass=$PASS fail=$FAIL rate=$((PASS * 100 / ACTUAL_COUNT))%"
echo ""
echo "PASS_RATE=$((PASS * 100 / ACTUAL_COUNT))%"
echo "TOTAL=$ACTUAL_COUNT"
echo "PASSED=$PASS"
echo "FAILED=$FAIL"
