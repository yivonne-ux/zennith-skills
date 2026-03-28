#!/usr/bin/env bash
# block-library.sh — AIDA Block Library Manager for Zennith OS
# Ported from Tricia's 995-clip production system (video-compiler)
#
# Usage:
#   block-library.sh register --file <clip.mp4> --brand <brand> --code <A3> [options]
#   block-library.sh search   --brand <brand> [--phase <phase>] [--code <code>] [--tags <tags>]
#   block-library.sh sequence --brand <brand>
#   block-library.sh enrich   --file <clip.mp4> --brand <brand>
#   block-library.sh expire   --brand <brand> --code <code> --status <fatigued|retired>
#   block-library.sh list     --brand <brand> [--phase <phase>] [--status <status>]
#   block-library.sh health   --brand <brand>

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW="$HOME/.openclaw"
LIBRARY_DIR="${OPENCLAW}/workspace/data/video-blocks"
LOG_FILE="${OPENCLAW}/logs/block-library.log"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

mkdir -p "$LIBRARY_DIR" "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

# Parse args
BRAND=""
FILE=""
BLOCK_CODE=""
CATEGORY=""
SUBTYPE=""
PHASE=""
TAGS=""
STATUS=""
TOP_N=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)    BRAND="$2"; shift 2 ;;
    --file)     FILE="$2"; shift 2 ;;
    --code)     BLOCK_CODE="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --subtype)  SUBTYPE="$2"; shift 2 ;;
    --phase)    PHASE="$2"; shift 2 ;;
    --tags)     TAGS="$2"; shift 2 ;;
    --status)   STATUS="$2"; shift 2 ;;
    --top)      TOP_N="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[block-lib $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

get_library_file() {
  local brand="$1"
  echo "${LIBRARY_DIR}/${brand}-blocks.json"
}

init_library() {
  local brand="$1"
  local lib_file
  lib_file=$(get_library_file "$brand")
  if [[ ! -f "$lib_file" ]]; then
    echo '{"brand":"'"$brand"'","blocks":[],"updated":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' > "$lib_file"
    log "Initialized library for brand: $brand"
  fi
}

case "$MODE" in
  register)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    [[ -z "$FILE" ]] && { echo "ERROR: --file required"; exit 1; }
    [[ -z "$BLOCK_CODE" ]] && { echo "ERROR: --code required (e.g., A3, I1, D1, Act6)"; exit 1; }

    init_library "$BRAND"

    log "=== REGISTER BLOCK ==="
    log "File: $FILE"
    log "Brand: $BRAND, Code: $BLOCK_CODE"

    "$PYTHON3" - "$FILE" "$BRAND" "$BLOCK_CODE" "$CATEGORY" "$SUBTYPE" "$(get_library_file "$BRAND")" << 'PYEOF'
import sys, json, os, subprocess
from datetime import datetime, timezone

file_path = sys.argv[1]
brand = sys.argv[2]
block_code = sys.argv[3]
category = sys.argv[4] or "Unknown"
subtype = sys.argv[5] or ""
lib_file = sys.argv[6]

# Get video duration
duration = 0.0
try:
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", file_path],
        capture_output=True, text=True, timeout=10
    )
    duration = float(result.stdout.strip())
except Exception:
    pass

# Map code to AIDA phase
code_prefix = block_code.rstrip("0123456789")
phase_map = {"A": "attention", "I": "interest", "D": "desire", "Act": "action"}
aida_phase = phase_map.get(code_prefix, "unknown")

# Load library
with open(lib_file) as f:
    library = json.load(f)

# Count existing blocks with same code for versioning
existing = [b for b in library["blocks"] if b.get("block_code") == block_code]
version = len(existing) + 1

block_id = f"{block_code}_{category}_{subtype}_v{version}" if subtype else f"{block_code}_{category}_v{version}"

block = {
    "id": block_id,
    "file": os.path.abspath(file_path),
    "type": "kol_video",
    "block_code": block_code,
    "aida_phase": aida_phase,
    "category": category,
    "subtype": subtype,
    "duration": round(duration, 2),
    "tags": [],
    "quality_score": 3,
    "engagement_score": 50,
    "status": "fresh",
    "times_used": 0,
    "registered_at": datetime.now(timezone.utc).isoformat(),
    "last_used_at": None,
}

library["blocks"].append(block)
library["updated"] = datetime.now(timezone.utc).isoformat()

with open(lib_file, "w") as f:
    json.dump(library, f, indent=2)

print(f"Registered: {block_id} ({duration:.1f}s, {aida_phase})")
PYEOF
    ;;

  search)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    init_library "$BRAND"

    log "=== SEARCH BLOCKS ==="

    "$PYTHON3" - "$BRAND" "$PHASE" "$BLOCK_CODE" "$TAGS" "$TOP_N" "$(get_library_file "$BRAND")" << 'PYEOF'
import sys, json

brand = sys.argv[1]
phase_filter = sys.argv[2] or None
code_filter = sys.argv[3] or None
tags_str = sys.argv[4] or ""
top_n = int(sys.argv[5])
lib_file = sys.argv[6]

required_tags = [t.strip() for t in tags_str.split(",") if t.strip()] if tags_str else []

with open(lib_file) as f:
    library = json.load(f)

def score_block(block):
    score = 0.0
    if block.get("status") == "retired":
        return -1
    if phase_filter and block.get("aida_phase") != phase_filter:
        return -1
    if code_filter and block.get("block_code") != code_filter:
        return -1

    # Quality bonus (0-0.25)
    score += block.get("quality_score", 3) / 20

    # Engagement bonus (0-0.15)
    eng = block.get("engagement_score", 50)
    if eng >= 80: score += 0.15
    elif eng >= 60: score += 0.10
    elif eng >= 40: score += 0.05

    # Tag overlap (0-0.4)
    if required_tags:
        block_tags = set(block.get("tags", []))
        overlap = len(block_tags & set(required_tags))
        score += (overlap / len(required_tags)) * 0.4

    # Freshness penalty
    if block.get("status") == "fatigued":
        score *= 0.5

    # Usage decay
    times_used = block.get("times_used", 0)
    if times_used > 0:
        score *= 0.5 ** times_used

    return score

results = []
for block in library["blocks"]:
    s = score_block(block)
    if s >= 0:
        results.append((s, block))

results.sort(key=lambda x: -x[0])
results = results[:top_n]

if not results:
    print("No matching blocks found")
else:
    for score, block in results:
        print(f"  [{score:.3f}] {block['id']} ({block['duration']:.1f}s, {block['status']})")
        print(f"         {block['file']}")
PYEOF
    ;;

  sequence)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    init_library "$BRAND"

    log "=== AIDA SEQUENCE SEARCH ==="

    "$PYTHON3" - "$BRAND" "$(get_library_file "$BRAND")" << 'PYEOF'
import sys, json

brand = sys.argv[1]
lib_file = sys.argv[2]

with open(lib_file) as f:
    library = json.load(f)

phases = ["attention", "interest", "desire", "action"]
sequence = {}

for phase in phases:
    candidates = [b for b in library["blocks"]
                  if b.get("aida_phase") == phase and b.get("status") != "retired"]
    if candidates:
        # Pick best by quality_score * engagement_score, penalize usage
        best = max(candidates, key=lambda b: (
            b.get("quality_score", 3) * b.get("engagement_score", 50) *
            (0.5 ** b.get("times_used", 0))
        ))
        sequence[phase] = best
        print(f"  {phase.upper():10s} → {best['id']} ({best['duration']:.1f}s, score={best.get('quality_score',3)})")
    else:
        print(f"  {phase.upper():10s} → [EMPTY — no blocks available]")

total = sum(b.get("duration", 0) for b in sequence.values())
print(f"\n  Total duration: {total:.1f}s ({len(sequence)}/4 phases filled)")
PYEOF
    ;;

  expire)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    [[ -z "$STATUS" ]] && { echo "ERROR: --status required (fatigued|retired|fresh)"; exit 1; }

    log "=== EXPIRE BLOCKS ==="

    "$PYTHON3" - "$BRAND" "$BLOCK_CODE" "$STATUS" "$(get_library_file "$BRAND")" << 'PYEOF'
import sys, json
from datetime import datetime, timezone

brand = sys.argv[1]
code_filter = sys.argv[2] or None
new_status = sys.argv[3]
lib_file = sys.argv[4]

with open(lib_file) as f:
    library = json.load(f)

count = 0
now = datetime.now(timezone.utc).isoformat()

for block in library["blocks"]:
    if code_filter and block.get("block_code") != code_filter:
        continue
    if block.get("status") != new_status:
        block["status"] = new_status
        block["status_changed_at"] = now
        if new_status == "retired":
            block["retired_at"] = now
        elif new_status == "fatigued":
            block["fatigued_at"] = now
        count += 1

library["updated"] = now
with open(lib_file, "w") as f:
    json.dump(library, f, indent=2)

print(f"Updated {count} blocks to status: {new_status}")
PYEOF
    ;;

  list)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    init_library "$BRAND"

    "$PYTHON3" - "$BRAND" "$PHASE" "$STATUS" "$(get_library_file "$BRAND")" << 'PYEOF'
import sys, json

brand = sys.argv[1]
phase_filter = sys.argv[2] or None
status_filter = sys.argv[3] or None
lib_file = sys.argv[4]

with open(lib_file) as f:
    library = json.load(f)

blocks = library["blocks"]
if phase_filter:
    blocks = [b for b in blocks if b.get("aida_phase") == phase_filter]
if status_filter:
    blocks = [b for b in blocks if b.get("status") == status_filter]

print(f"Block Library: {brand} ({len(blocks)} blocks)")
print(f"{'ID':40s} {'Code':6s} {'Phase':10s} {'Dur':6s} {'Status':10s} {'Used':4s}")
print("-" * 80)
for b in blocks:
    print(f"{b['id']:40s} {b.get('block_code','?'):6s} {b.get('aida_phase','?'):10s} {b.get('duration',0):5.1f}s {b.get('status','?'):10s} {b.get('times_used',0):4d}")
PYEOF
    ;;

  health)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    init_library "$BRAND"

    log "=== LIBRARY HEALTH ==="

    "$PYTHON3" - "$BRAND" "$(get_library_file "$BRAND")" << 'PYEOF'
import sys, json

brand = sys.argv[1]
lib_file = sys.argv[2]

with open(lib_file) as f:
    library = json.load(f)

blocks = library["blocks"]
total = len(blocks)
fresh = sum(1 for b in blocks if b.get("status") == "fresh")
fatigued = sum(1 for b in blocks if b.get("status") == "fatigued")
retired = sum(1 for b in blocks if b.get("status") == "retired")

phases = {}
for b in blocks:
    phase = b.get("aida_phase", "unknown")
    phases[phase] = phases.get(phase, 0) + 1

print(f"Library Health: {brand}")
print(f"  Total blocks: {total}")
print(f"  Fresh: {fresh} | Fatigued: {fatigued} | Retired: {retired}")
print(f"\n  By AIDA Phase:")
for phase in ["attention", "interest", "desire", "action"]:
    count = phases.get(phase, 0)
    status = "✅" if count >= 3 else "⚠️" if count >= 1 else "❌"
    print(f"    {status} {phase}: {count} blocks")

# Quality distribution
high_q = sum(1 for b in blocks if b.get("quality_score", 0) >= 4)
mid_q = sum(1 for b in blocks if 2 <= b.get("quality_score", 0) < 4)
low_q = sum(1 for b in blocks if b.get("quality_score", 0) < 2)
print(f"\n  Quality: High={high_q} | Mid={mid_q} | Low={low_q}")

if total == 0:
    print("\n  ⚠️ Library is EMPTY — register blocks with: block-library.sh register")
elif fresh < 10:
    print(f"\n  ⚠️ Low fresh blocks ({fresh}) — consider generating or refreshing")
else:
    print(f"\n  ✅ Library healthy ({fresh} fresh blocks)")
PYEOF
    ;;

  help|*)
    cat << 'HELPEOF'
Video Block Library — AIDA-Structured Asset Manager

Usage:
  block-library.sh register  --file <clip> --brand <brand> --code <A3> [--category X]
  block-library.sh search    --brand <brand> [--phase attention] [--code A3] [--tags "x,y"]
  block-library.sh sequence  --brand <brand>
  block-library.sh enrich    --file <clip> --brand <brand>
  block-library.sh expire    --brand <brand> [--code A3] --status <fatigued|retired|fresh>
  block-library.sh list      --brand <brand> [--phase attention] [--status fresh]
  block-library.sh health    --brand <brand>

AIDA Codes:
  A1-A6    Attention (hooks, reactions, pain scenarios)
  I1-I6    Interest (BTS, process, materials, reviews)
  D1-D3    Desire (eating, unboxing, receive scenes)
  Act1-6   Action (packaging, promo, CTA end card)

Block Lifecycle: FRESH → FATIGUED → RETIRED
HELPEOF
    ;;
esac
