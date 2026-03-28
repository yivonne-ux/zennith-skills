#!/usr/bin/env bash
# brand-voice-check.sh — Pre-publish quality gate against brand DNA
#
# Usage:
#   brand-voice-check.sh --brand mirra --text "Your weekly bento is here!"
#   brand-voice-check.sh --brand jade-oracle --file caption.txt
#   brand-voice-check.sh --brand luna --prompt "Photorealistic photo..."
#   brand-voice-check.sh --brand mirra --text "Burns fat fast!" --strict
#
# Exit: 0 = PASS, 1 = FAIL

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

OPENCLAW="$HOME/.openclaw"
BRANDS_DIR="${OPENCLAW}/brands"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

BRAND=""
TEXT=""
FILE=""
PROMPT=""
MODE="warn"  # warn or strict

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)  BRAND="$2"; shift 2 ;;
    --text)   TEXT="$2"; shift 2 ;;
    --file)   FILE="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --strict) MODE="strict"; shift ;;
    --warn)   MODE="warn"; shift ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }

# Load content to check
CONTENT="$TEXT"
[[ -n "$FILE" && -f "$FILE" ]] && CONTENT=$(cat "$FILE")
[[ -n "$PROMPT" ]] && CONTENT="$PROMPT"
[[ -z "$CONTENT" ]] && { echo "ERROR: --text, --file, or --prompt required" >&2; exit 1; }

# Load brand DNA
DNA_FILE="${BRANDS_DIR}/${BRAND}/DNA.json"
if [[ ! -f "$DNA_FILE" ]]; then
  echo "ERROR: Brand DNA not found: ${DNA_FILE}" >&2
  exit 1
fi

# Run checks via Python (access to JSON parsing + regex)
"$PYTHON3" - "$BRAND" "$DNA_FILE" "$CONTENT" "$MODE" << 'PYEOF'
import json, sys, re

brand = sys.argv[1]
dna_path = sys.argv[2]
content = sys.argv[3]
mode = sys.argv[4]

with open(dna_path) as f:
    dna = json.load(f)

warnings = []
failures = []
content_lower = content.lower()

# ── Check 1: Never-list violations ──
never_list = dna.get("never", [])
for item in never_list:
    item_lower = item.lower()
    # Check for keyword matches (not substring — use word boundaries)
    pattern = r'\b' + re.escape(item_lower.split()[0]) + r'\b'
    if re.search(pattern, content_lower):
        failures.append(f"NEVER-LIST: Content contains '{item}' — brand DNA prohibits this")

# ── Check 2: Brand-specific violations ──
brand_lower = brand.lower()

# MIRRA-specific
if brand_lower == "mirra":
    bad_terms = ["skincare", "skin care", "beauty routine", "the-mirra.com", "burns fat", "reduces obesity", "weight loss guaranteed"]
    for term in bad_terms:
        if term in content_lower:
            failures.append(f"MIRRA VIOLATION: '{term}' — MIRRA is meal subscription, NOT skincare. Health claims can result in RM10K fine.")

# Jade Oracle-specific
if "jade" in brand_lower:
    qmdj_terms = ["奇门遁甲", "qmdj", "qi men dun jia", "天盘", "地盘", "八门", "九星"]
    qmdj_count = sum(1 for t in qmdj_terms if t in content_lower)
    if qmdj_count > 1:
        warnings.append(f"JADE: {qmdj_count} QMDJ terms found — max 5% of content should mention Chinese metaphysics. Oracle-focused, not QMDJ-focused.")

# ── Check 3: Tone check ──
voice = dna.get("voice", {})
personality = voice.get("personality", [])
tone = voice.get("tone", "")

# Check for corporate/formal language that conflicts with warm brands
formal_markers = ["pursuant to", "hereby", "aforementioned", "in accordance with", "we regret to inform"]
for marker in formal_markers:
    if marker in content_lower:
        warnings.append(f"TONE: '{marker}' sounds corporate — brand tone is: {tone}")

# Check for AI slop patterns
ai_slop = ["in today's fast-paced world", "at the end of the day", "it's important to note",
            "in conclusion", "without further ado", "game-changer", "dive deep into",
            "leverage", "synergy", "unlock your potential", "revolutionary"]
for slop in ai_slop:
    if slop in content_lower:
        warnings.append(f"AI SLOP: '{slop}' detected — run through humanizer before publishing")

# ── Check 4: Language mix check ──
language_mix = voice.get("language_mix", "")
if "english" in language_mix.lower() and "chinese" in language_mix.lower():
    # Bilingual brand — check for pure mainland Chinese
    mainland_markers = ["的话", "这个", "那个", "什么的", "好吧"]
    mainland_count = sum(1 for m in mainland_markers if m in content)
    if mainland_count > 3:
        warnings.append(f"LANGUAGE: Heavy mainland Chinese markers ({mainland_count}) — Malaysian Chinese uses Simplified Chinese but with local flavor, not pure mainland.")

# ── Check 5: Compliance (Malaysian market) ──
health_claims = ["burns fat", "lose weight fast", "guaranteed weight loss", "reduces obesity",
                 "cures", "treats disease", "medical breakthrough", "clinically proven to cure"]
for claim in health_claims:
    if claim in content_lower:
        failures.append(f"COMPLIANCE: '{claim}' — Malaysian health claims regulation. Safe alternatives: 'low calorie', 'portion-controlled', 'balanced nutrition'. Fine: RM10,000 or 2yr jail.")

# ── Report ──
total_issues = len(failures) + len(warnings)

if failures:
    print(f"FAIL — {len(failures)} violation(s) found for brand '{brand}':")
    for f in failures:
        print(f"  ✗ {f}")

if warnings:
    print(f"WARN — {len(warnings)} warning(s) for brand '{brand}':")
    for w in warnings:
        print(f"  ⚠ {w}")

if not failures and not warnings:
    print(f"PASS — Content matches '{brand}' brand voice")
    sys.exit(0)
elif failures:
    sys.exit(1)
elif mode == "strict" and warnings:
    sys.exit(1)
else:
    # Warnings only in warn mode — pass with notes
    sys.exit(0)
PYEOF
