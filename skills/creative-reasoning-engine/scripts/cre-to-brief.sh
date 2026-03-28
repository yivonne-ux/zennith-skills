#!/usr/bin/env bash
# cre-to-brief.sh — Adapter: CRE concept output → campaign-planner brief JSON
# Bridges creative-reasoning-engine → campaign-planner → NanoBanana/carousel
#
# Usage:
#   cre-to-brief.sh --brand mirra --concept "Horoscope Lunch Card" \
#     --format "horoscope-card" --hook "Your zodiac says eat this today" \
#     --levers "identity,recognition" --share-trigger "identity"
#
#   cre-to-brief.sh --brand mirra --concepts-file concepts.json
#
# Output: Structured JSON brief ready for campaign-planner or NanoBanana

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

OPENCLAW="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
OUTPUT_DIR="${OPENCLAW}/workspace/data/briefs/$(date +%Y-%m-%d)"

BRAND=""
CONCEPT=""
FORMAT=""
HOOK=""
LEVERS=""
SHARE_TRIGGER=""
CONCEPTS_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)          BRAND="$2"; shift 2 ;;
    --concept)        CONCEPT="$2"; shift 2 ;;
    --format)         FORMAT="$2"; shift 2 ;;
    --hook)           HOOK="$2"; shift 2 ;;
    --levers)         LEVERS="$2"; shift 2 ;;
    --share-trigger)  SHARE_TRIGGER="$2"; shift 2 ;;
    --concepts-file)  CONCEPTS_FILE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"

# Generate structured brief JSON
"$PYTHON3" - "$BRAND" "$CONCEPT" "$FORMAT" "$HOOK" "$LEVERS" "$SHARE_TRIGGER" "$OUTPUT_DIR" "$OPENCLAW" << 'PYEOF'
import json, sys, os
from datetime import datetime

brand = sys.argv[1]
concept = sys.argv[2]
fmt = sys.argv[3]
hook = sys.argv[4]
levers = sys.argv[5]
share_trigger = sys.argv[6]
output_dir = sys.argv[7]
openclaw = sys.argv[8]

# Load brand DNA
dna_path = f"{openclaw}/brands/{brand}/DNA.json"
dna = {}
if os.path.exists(dna_path):
    with open(dna_path) as f:
        dna = json.load(f)

# Load daily-intel digest if available (Fix #5: wire daily-intel → CRE)
intel_path = f"{openclaw}/workspace/data/daily-intel/{datetime.now().strftime('%Y-%m-%d')}/digest.md"
intel_summary = ""
if os.path.exists(intel_path):
    with open(intel_path) as f:
        intel_summary = f.read()[:2000]  # First 2000 chars

# Map format to production params
format_map = {
    "ui-mimicry": {"ratio": "9:16", "ref_type": "screenshot", "model": "pro"},
    "physical-object": {"ratio": "9:16", "ref_type": "photo", "model": "pro"},
    "cultural": {"ratio": "4:5", "ref_type": "design", "model": "pro"},
    "editorial": {"ratio": "4:5", "ref_type": "layout", "model": "pro"},
    "data": {"ratio": "4:5", "ref_type": "infographic", "model": "flash"},
    "social": {"ratio": "9:16", "ref_type": "screenshot", "model": "flash"},
}

# Detect category from format name
category = "editorial"  # default
for cat, data in format_map.items():
    if cat in fmt.lower():
        category = cat
        break

params = format_map.get(category, format_map["editorial"])

# Build structured brief
brief = {
    "brand": brand,
    "brand_display": dna.get("display_name", brand),
    "concept": {
        "name": concept,
        "format_type": fmt,
        "format_category": category,
        "hook_line": hook,
        "psychology_levers": [l.strip() for l in levers.split(",") if l.strip()],
        "share_trigger": share_trigger,
    },
    "production": {
        "ratio": params["ratio"],
        "model": params["model"],
        "ref_type": params["ref_type"],
        "ref_dir": f"{openclaw}/workspace/data/references/{brand}/{fmt}/",
        "output_dir": f"{openclaw}/workspace/data/content/{brand}/ads/{datetime.now().strftime('%Y-%m-%d')}/",
    },
    "brand_context": {
        "tagline": dna.get("tagline", ""),
        "tone": dna.get("voice", {}).get("tone", ""),
        "colors": dna.get("visual", {}).get("colors", {}),
        "never": dna.get("never", []),
    },
    "daily_intel_available": bool(intel_summary),
    "daily_intel_summary": intel_summary[:500] if intel_summary else "No daily intel for today",
    "generated_at": datetime.now().isoformat(),
}

# Save brief
safe_name = concept.lower().replace(" ", "-").replace("/", "-")[:40]
brief_path = f"{output_dir}/{brand}-{safe_name}.json"
with open(brief_path, "w") as f:
    json.dump(brief, f, indent=2)

print(json.dumps(brief, indent=2))
print(f"\nBrief saved: {brief_path}", file=sys.stderr)
PYEOF
