#!/usr/bin/env bash
# campaign-context.sh — Assemble performance context for campaign briefs
# Queries seed bank + winning patterns to give agents data-backed context
#
# Usage: bash campaign-context.sh --category vegan --channel tiktok
#        bash campaign-context.sh --strategy-id CSO-42
#
# Output: Text block injected into agent dispatch messages
# Bash 3.2 compatible (macOS)

set -uo pipefail

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SEED_STORE="$OPENCLAW_DIR/skills/content-seed-bank/scripts/seed-store.sh"
WINNING_PATTERNS="$OPENCLAW_DIR/workspace/data/winning-patterns.jsonl"
CONTENT_INTEL="$OPENCLAW_DIR/skills/content-intel/SKILL.md"

CATEGORY="" CHANNEL="" PERSONA="" STRATEGY_ID="" TOP_N=5 FORMAT="text"

while [ $# -gt 0 ]; do
  case "$1" in
    --category) CATEGORY="$2"; shift 2;;
    --channel) CHANNEL="$2"; shift 2;;
    --persona) PERSONA="$2"; shift 2;;
    --strategy-id) STRATEGY_ID="$2"; shift 2;;
    --top) TOP_N="$2"; shift 2;;
    --json) FORMAT="json"; shift;;
    --help|-h)
      echo "Usage: bash campaign-context.sh [--category vegan] [--channel tiktok] [--persona foodie] [--top 5]"
      exit 0;;
    *) shift;;
  esac
done

# --- 1. Top-performing hooks ---
HOOKS=""
if [ -f "$SEED_STORE" ]; then
  HOOK_ARGS="--type hook --sort performance --top $TOP_N"
  [ -n "$CATEGORY" ] && HOOK_ARGS="$HOOK_ARGS --tag $CATEGORY"
  [ -n "$CHANNEL" ] && HOOK_ARGS="$HOOK_ARGS --channel $CHANNEL"
  HOOKS=$(bash "$SEED_STORE" query $HOOK_ARGS 2>/dev/null | python3 -c "
import sys, json
results = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        s = json.loads(line)
        perf = s.get('performance', {}) or {}
        ctr = perf.get('ctr', 'n/a')
        roas = perf.get('roas', 'n/a')
        results.append(f'  - {s.get(\"text\",\"\")[:120]} (CTR: {ctr}, ROAS: {roas})')
    except: pass
print('\n'.join(results) if results else '  (no hook data yet)')
" 2>/dev/null || echo "  (no hook data yet)")
fi

# --- 2. Top-performing copy ---
COPIES=""
if [ -f "$SEED_STORE" ]; then
  COPY_ARGS="--type copy --sort performance --top $TOP_N"
  [ -n "$CHANNEL" ] && COPY_ARGS="$COPY_ARGS --channel $CHANNEL"
  COPIES=$(bash "$SEED_STORE" query $COPY_ARGS 2>/dev/null | python3 -c "
import sys, json
results = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        s = json.loads(line)
        perf = s.get('performance', {}) or {}
        roas = perf.get('roas', 'n/a')
        eng = perf.get('engagement', 'n/a')
        results.append(f'  - {s.get(\"text\",\"\")[:120]} (ROAS: {roas}, engagement: {eng})')
    except: pass
print('\n'.join(results) if results else '  (no copy data yet)')
" 2>/dev/null || echo "  (no copy data yet)")
fi

# --- 3. Winning patterns ---
PATTERNS=""
if [ -f "$WINNING_PATTERNS" ]; then
  PATTERNS=$(python3 -c "
import sys, json
patterns = []
with open('$WINNING_PATTERNS', 'r') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            p = json.loads(line)
            if p.get('status') in ('detected', 'confirmed', 'promoted'):
                ev = p.get('evidence_count', 0)
                imp = p.get('avg_improvement', 0)
                imp_str = f'{imp:.0%}' if isinstance(imp, (int, float)) else str(imp)
                patterns.append(f'  - {p.get(\"description\", \"?\")} (evidence: {ev}, improvement: {imp_str})')
        except: pass
print('\n'.join(patterns[:$TOP_N]) if patterns else '  (no winning patterns yet)')
" 2>/dev/null || echo "  (no winning patterns yet)")
fi

# --- 4. Seed bank stats ---
STATS=""
if [ -f "$SEED_STORE" ]; then
  TOTAL=$(bash "$SEED_STORE" count 2>/dev/null || echo "0")
  WINNERS=$(bash "$SEED_STORE" count --status winner 2>/dev/null || echo "0")
  TESTED=$(bash "$SEED_STORE" count --status tested 2>/dev/null || echo "0")
  STATS="  Total seeds: $TOTAL | Winners: $WINNERS | Tested: $TESTED"
fi

# --- 5. Best performing ads ---
ADS=""
if [ -f "$SEED_STORE" ]; then
  ADS=$(bash "$SEED_STORE" top --type ad --metric ctr --top 3 2>/dev/null | python3 -c "
import sys, json
results = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        s = json.loads(line)
        perf = s.get('performance', {}) or {}
        results.append(f'  - {s.get(\"text\",\"\")[:100]} (CTR: {perf.get(\"ctr\",\"?\")}, ROAS: {perf.get(\"roas\",\"?\")}, spend: {perf.get(\"spend\",\"?\")})')
    except: pass
print('\n'.join(results) if results else '  (no ad performance data yet)')
" 2>/dev/null || echo "  (no ad performance data yet)")
fi

# --- Output ---
if [ "$FORMAT" = "json" ]; then
  python3 -c "
import json
print(json.dumps({
    'hooks': '''$HOOKS'''.strip(),
    'copies': '''$COPIES'''.strip(),
    'patterns': '''$PATTERNS'''.strip(),
    'ads': '''$ADS'''.strip(),
    'stats': '''$STATS'''.strip()
}, indent=2))
"
else
  cat << EOF

=== CAMPAIGN INTELLIGENCE (from seed bank) ===

TOP-PERFORMING HOOKS:
$HOOKS

TOP-PERFORMING COPY:
$COPIES

WINNING PATTERNS:
$PATTERNS

TOP ADS BY CTR:
$ADS

SEED BANK STATUS:
$STATS

=== END CAMPAIGN INTELLIGENCE ===
EOF
fi
