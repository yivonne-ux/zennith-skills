#!/usr/bin/env bash
# learn.sh — Compound curator findings back into brand DNA
# Reads curator run results → identifies winning patterns → updates DNA.json creative_learnings
# Usage: learn.sh --brand mirra --run /path/to/curator-run/
# ---
set -euo pipefail

BRANDS_DIR="$HOME/.openclaw/brands"
GAIA_DB="$HOME/.openclaw/workspace/gaia-db/gaia.db"
DIGEST="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"
LOG="$HOME/.openclaw/logs/brand-studio.log"

log() { mkdir -p "$(dirname "$LOG")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [LEARN] $*" >> "$LOG"; }

BRAND="" RUN_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand) BRAND="$2"; shift 2 ;;
    --run)   RUN_DIR="$2"; shift 2 ;;
    --help)
      echo "learn.sh — Compound curator learnings into brand DNA"
      echo ""
      echo "Usage: learn.sh --brand <slug> --run <curator-run-dir>"
      echo ""
      echo "Reads all result JSONs from a curator run, identifies:"
      echo "  - Best-performing templates and headlines"
      echo "  - Patterns to block (repeated failures)"
      echo "  - Prompt modifiers that improved scores"
      echo "Updates DNA.json with creative_learnings section."
      exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
[[ -z "$RUN_DIR" ]] && { echo "ERROR: --run required"; exit 1; }
[[ -d "$RUN_DIR" ]] || { echo "ERROR: Run dir not found: $RUN_DIR"; exit 1; }

DNA="$BRANDS_DIR/$BRAND/DNA.json"
[[ -f "$DNA" ]] || { echo "ERROR: Brand DNA not found: $DNA"; exit 1; }

echo "━━━ Learning from Curator Run ━━━"
echo "  Brand: $BRAND"
echo "  Run:   $RUN_DIR"
echo ""

# --- Analyze results and update DNA ---
python3 - "$RUN_DIR" "$DNA" "$GAIA_DB" "$BRAND" << 'PYEOF'
import json, glob, os, sys
from datetime import datetime

run_dir = sys.argv[1]
dna_path = sys.argv[2]
gaia_db_path = sys.argv[3]
brand = sys.argv[4]

# Load all results
results = []
for f in sorted(glob.glob(os.path.join(run_dir, '*.json'))):
    if os.path.basename(f) == 'summary.json':
        continue
    with open(f) as fh:
        results.append(json.load(fh))

if not results:
    print("  No results found to learn from.")
    sys.exit(0)

# --- Analyze by template ---
by_template = {}
for r in results:
    t = r['template']
    if t not in by_template:
        by_template[t] = {'scores': [], 'headlines': [], 'passed': 0, 'failed': 0}
    by_template[t]['scores'].append(r['score'])
    by_template[t]['headlines'].append({'text': r['headline'], 'score': r['score'], 'passed': r['passed']})
    if r['passed']:
        by_template[t]['passed'] += 1
    else:
        by_template[t]['failed'] += 1

# --- Find best and worst ---
best_templates = []
weak_templates = []
best_headlines = []
blocked_headlines = []

for t, data in by_template.items():
    avg = sum(data['scores']) / len(data['scores'])
    pass_rate = data['passed'] / (data['passed'] + data['failed'])

    if avg >= 9.0 and pass_rate >= 0.8:
        best_templates.append({'template': t, 'avg_score': round(avg, 2), 'pass_rate': round(pass_rate, 3)})
    elif avg < 7.0 or pass_rate < 0.5:
        weak_templates.append({'template': t, 'avg_score': round(avg, 2), 'pass_rate': round(pass_rate, 3)})

    # Best headlines per template
    sorted_hl = sorted(data['headlines'], key=lambda x: x['score'], reverse=True)
    if sorted_hl and sorted_hl[0]['score'] >= 8.0:
        best_headlines.append({
            'template': t,
            'headline': sorted_hl[0]['text'],
            'score': sorted_hl[0]['score']
        })

    # Blocked headlines (failed with low scores)
    for hl in data['headlines']:
        if not hl['passed'] and hl['score'] < 5.0:
            blocked_headlines.append({
                'template': t,
                'headline': hl['text'],
                'score': hl['score']
            })

# --- Print findings ---
print("  Findings:")
print(f"    Total results:     {len(results)}")
print(f"    Strong templates:  {', '.join(t['template'] for t in best_templates) or 'none'}")
print(f"    Weak templates:    {', '.join(t['template'] for t in weak_templates) or 'none'}")
print(f"    Best headlines:    {len(best_headlines)}")
print(f"    Blocked headlines: {len(blocked_headlines)}")
print()

# --- Update DNA.json ---
with open(dna_path) as f:
    dna = json.load(f)

# Initialize or update creative_learnings section
learnings = dna.get('creative_learnings', {
    'best_templates': [],
    'weak_templates': [],
    'winning_headlines': {},
    'blocked_headlines': [],
    'curator_runs': [],
    'total_generated': 0,
    'total_passed': 0,
    'last_updated': None,
})

# Merge best templates (keep unique, update scores)
existing_best = {t['template']: t for t in learnings.get('best_templates', [])}
for bt in best_templates:
    existing_best[bt['template']] = bt
learnings['best_templates'] = list(existing_best.values())

# Merge weak templates
existing_weak = {t['template']: t for t in learnings.get('weak_templates', [])}
for wt in weak_templates:
    existing_weak[wt['template']] = wt
# Remove from weak if now in best
for bt in best_templates:
    existing_weak.pop(bt['template'], None)
learnings['weak_templates'] = list(existing_weak.values())

# Merge winning headlines (per template, keep top 3)
winning = learnings.get('winning_headlines', {})
for bh in best_headlines:
    t = bh['template']
    if t not in winning:
        winning[t] = []
    # Add if not duplicate
    existing_texts = {h['headline'] for h in winning[t]}
    if bh['headline'] not in existing_texts:
        winning[t].append(bh)
    # Keep top 3 per template
    winning[t] = sorted(winning[t], key=lambda x: x['score'], reverse=True)[:3]
learnings['winning_headlines'] = winning

# Merge blocked headlines
existing_blocked = {(b['template'], b['headline']) for b in learnings.get('blocked_headlines', [])}
for bl in blocked_headlines:
    key = (bl['template'], bl['headline'])
    if key not in existing_blocked:
        learnings['blocked_headlines'].append(bl)
        existing_blocked.add(key)

# Update run history
run_id = os.path.basename(run_dir)
total_pass = sum(1 for r in results if r.get('passed'))
total_fail = sum(1 for r in results if not r.get('passed'))
avg_score = round(sum(r['score'] for r in results) / len(results), 2)

learnings['curator_runs'].append({
    'run_id': run_id,
    'timestamp': datetime.utcnow().isoformat() + 'Z',
    'total': len(results),
    'passed': total_pass,
    'failed': total_fail,
    'avg_score': avg_score,
})
# Keep last 20 runs
learnings['curator_runs'] = learnings['curator_runs'][-20:]

learnings['total_generated'] = learnings.get('total_generated', 0) + len(results)
learnings['total_passed'] = learnings.get('total_passed', 0) + total_pass
learnings['last_updated'] = datetime.utcnow().isoformat() + 'Z'

dna['creative_learnings'] = learnings

# Write back
with open(dna_path, 'w') as f:
    json.dump(dna, f, indent=2)

print("  DNA updated:")
print(f"    creative_learnings.best_templates:   {len(learnings['best_templates'])} types")
print(f"    creative_learnings.winning_headlines: {sum(len(v) for v in learnings['winning_headlines'].values())} headlines")
print(f"    creative_learnings.blocked_headlines: {len(learnings['blocked_headlines'])} blocked")
print(f"    creative_learnings.total_generated:   {learnings['total_generated']} all time")
print(f"    creative_learnings.total_passed:      {learnings['total_passed']} all time")
print()

# --- Also store to gaia.db knowledge ---
try:
    import sqlite3
    db = sqlite3.connect(gaia_db_path)

    for bh in best_headlines:
        fact = f"WINNING: brand={brand} template={bh['template']} headline=\"{bh['headline']}\" score={bh['score']}"
        db.execute("""INSERT OR IGNORE INTO knowledge (source, type, fact, agent, created_at)
                      VALUES (?, 'creative-learning', ?, 'iris', datetime('now'))""",
                   (f"curator/{brand}/{run_id}", fact))

    for bl in blocked_headlines:
        fact = f"BLOCKED: brand={brand} template={bl['template']} headline=\"{bl['headline']}\" score={bl['score']}"
        db.execute("""INSERT OR IGNORE INTO knowledge (source, type, fact, agent, created_at)
                      VALUES (?, 'creative-learning', ?, 'iris', datetime('now'))""",
                   (f"curator/{brand}/{run_id}", fact))

    db.commit()
    db.close()
    print("  Knowledge DB updated with learnings.")
except Exception as e:
    print(f"  WARN: Could not update gaia.db: {e}")

PYEOF

log "Learn complete: brand=$BRAND run=$RUN_DIR"
echo "  Done."
