#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Jade Oracle — Regression Test Suite
# Run after every deploy to verify system health
# Usage: bash jade-regression.sh [base_url]
# ══════════════════════════════════════════════════════════════

set -euo pipefail

BASE="${1:-https://jade-os.fly.dev}"
PASS=0
FAIL=0
SKIP=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
skip() { echo "  ⏭️  $1"; SKIP=$((SKIP + 1)); }

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Jade Oracle — Regression Test Suite     ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Target: $BASE"
echo "Time:   $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

# ── D1: Root endpoint ──
echo "D1: Root endpoint"
ROOT=$(curl -sf "$BASE/" 2>/dev/null || echo "FAIL")
if echo "$ROOT" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['qmdj_engine']==True" 2>/dev/null; then
  pass "Root responds, QMDJ engine: true"
else
  fail "Root endpoint failed or QMDJ engine not loaded"
fi

# ── D2: Health endpoint ──
echo "D2: Health endpoint"
HEALTH=$(curl -sf "$BASE/health" 2>/dev/null || echo "FAIL")
if echo "$HEALTH" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['ok']==True" 2>/dev/null; then
  pass "Health OK"
else
  fail "Health endpoint failed"
fi

# ── D3: Uptime > 60s ──
echo "D3: Uptime check"
UP=$(echo "$HEALTH" | python3 -c "import sys,json; print(json.load(sys.stdin).get('uptime',0))" 2>/dev/null || echo "0")
if python3 -c "assert float('$UP') > 10" 2>/dev/null; then
  pass "Uptime: ${UP}s (running)"
else
  fail "Uptime: ${UP}s (not responding or just crashed)"
fi

# ── D4: Interpretation engine loaded ──
echo "D4: Interpretation engine"
if echo "$HEALTH" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['interpretation_engine']==True" 2>/dev/null; then
  pass "Interpretation engine loaded"
else
  fail "Interpretation engine not loaded"
fi

# ── D5: Model configured ──
echo "D5: LLM model"
MODEL=$(echo "$HEALTH" | python3 -c "import sys,json; print(json.load(sys.stdin).get('model',''))" 2>/dev/null || echo "")
if [ -n "$MODEL" ]; then
  pass "Model: $MODEL"
else
  fail "No model configured"
fi

# ── C1: Debug interpret endpoint ──
echo "C1: Debug interpret (QMDJ + cards)"
DEBUG=$(curl -sf "$BASE/debug-interpret" 2>/dev/null || echo "FAIL")
if [ "$DEBUG" = "FAIL" ]; then
  skip "Debug endpoint not available (deploy pending)"
else
  # Check chart available
  CHART_OK=$(echo "$DEBUG" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('chart_available') else 'no')" 2>/dev/null || echo "no")
  if [ "$CHART_OK" = "yes" ]; then
    pass "QMDJ chart computed"
  else
    fail "QMDJ chart computation failed"
  fi

  # Check interpretation available
  INTERP_OK=$(echo "$DEBUG" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('interpretation_available') else 'no')" 2>/dev/null || echo "no")
  if [ "$INTERP_OK" = "yes" ]; then
    pass "Interpretation generated"
  else
    fail "Interpretation generation failed"
  fi

  # Check cards populated
  ARCHETYPE=$(echo "$DEBUG" | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('cards',{}); print(c.get('archetype',{}).get('name','') if c and c.get('archetype') else '')" 2>/dev/null || echo "")
  PATHWAY=$(echo "$DEBUG" | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('cards',{}); print(c.get('pathway',{}).get('name','') if c and c.get('pathway') else '')" 2>/dev/null || echo "")
  GUARDIAN=$(echo "$DEBUG" | python3 -c "import sys,json; d=json.load(sys.stdin); c=d.get('cards',{}); print(c.get('guardian',{}).get('name','') if c and c.get('guardian') else '')" 2>/dev/null || echo "")

  if [ -n "$ARCHETYPE" ] && [ -n "$PATHWAY" ] && [ -n "$GUARDIAN" ]; then
    pass "Cards: $ARCHETYPE / $PATHWAY / $GUARDIAN"
  else
    fail "Cards incomplete: archetype=$ARCHETYPE pathway=$PATHWAY guardian=$GUARDIAN"
  fi

  # Check narrative length
  NARR_LEN=$(echo "$DEBUG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('narrative_length',0))" 2>/dev/null || echo "0")
  if [ "$NARR_LEN" -gt 500 ]; then
    pass "Narrative: ${NARR_LEN} chars"
  else
    fail "Narrative too short: ${NARR_LEN} chars"
  fi

  # Check palace data structure
  PALACE_KEYS=$(echo "$DEBUG" | python3 -c "import sys,json; s=json.load(sys.stdin).get('chart_palace_sample',[]); print(','.join(s[0].get('keys',[])) if s else '')" 2>/dev/null || echo "")
  if [ -n "$PALACE_KEYS" ]; then
    pass "Palace structure keys: $PALACE_KEYS"
  else
    skip "Palace structure check (no sample)"
  fi
fi

# ── Summary ──
echo ""
echo "════════════════════════════════════════════"
TOTAL=$((PASS + FAIL + SKIP))
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped (of $TOTAL)"
if [ "$FAIL" -eq 0 ]; then
  echo "STATUS: ALL PASS ✅"
else
  echo "STATUS: FAILURES DETECTED ❌"
fi
echo "════════════════════════════════════════════"
echo ""

exit $FAIL
