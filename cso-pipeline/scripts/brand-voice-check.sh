#!/usr/bin/env bash
# brand-voice-check.sh — Validate copy against GAIA brand voice guidelines
# Uses the brand profile + content-intel rules to score consistency
#
# Usage: bash brand-voice-check.sh --text "Your copy here" --brand gaia-eats
#        echo "copy text" | bash brand-voice-check.sh --brand gaia-eats
#        bash brand-voice-check.sh --file /path/to/copy.txt --brand gaia-eats
#
# Output: pass/needs_revision/reject with score and notes
# Bash 3.2 compatible (macOS)

set -uo pipefail

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
BRANDS_DIR="$OPENCLAW_DIR/skills/nanobanana/brands"

TEXT="" BRAND="gaia-eats" FILE="" THRESHOLD="3.5"

while [ $# -gt 0 ]; do
  case "$1" in
    --text) TEXT="$2"; shift 2;;
    --brand) BRAND="$2"; shift 2;;
    --file) FILE="$2"; shift 2;;
    --threshold) THRESHOLD="$2"; shift 2;;
    --help|-h)
      echo "Usage: bash brand-voice-check.sh --text \"copy\" --brand gaia-eats"
      echo "       echo \"copy\" | bash brand-voice-check.sh --brand gaia-eats"
      exit 0;;
    *) shift;;
  esac
done

# Read from file or stdin if no --text
if [ -z "$TEXT" ] && [ -n "$FILE" ]; then
  TEXT=$(cat "$FILE" 2>/dev/null || echo "")
fi
if [ -z "$TEXT" ]; then
  if [ -t 0 ]; then
    echo "ERROR: No text provided. Use --text, --file, or pipe via stdin." >&2
    exit 1
  fi
  TEXT=$(cat)
fi

if [ -z "$TEXT" ]; then
  echo "ERROR: No text provided." >&2
  exit 1
fi

# Load brand profile
BRAND_FILE="$BRANDS_DIR/${BRAND}.json"

# Write text to temp file for safe Python access
TMPTEXT="/tmp/bvc-text-$$.txt"
TMPBRAND="/tmp/bvc-brand-$$.json"
printf '%s' "$TEXT" > "$TMPTEXT"
if [ -f "$BRAND_FILE" ]; then
  cp "$BRAND_FILE" "$TMPBRAND"
else
  echo '{}' > "$TMPBRAND"
fi

# Cleanup on exit
cleanup() { rm -f "$TMPTEXT" "$TMPBRAND"; }
trap cleanup EXIT

python3 - "$TMPTEXT" "$TMPBRAND" "$THRESHOLD" << 'PYEOF'
import sys, json

text_file = sys.argv[1]
brand_file = sys.argv[2]
threshold = float(sys.argv[3])

with open(text_file) as f:
    text = f.read()

try:
    with open(brand_file) as f:
        brand = json.load(f)
except:
    brand = {}

brand_name = brand.get("brand_name", "Unknown")
values = brand.get("brand_values", [])

scores = {}
notes = []
text_lower = text.lower()

# 1. TONE CHECK — warm, inclusive, not clinical/preachy
clinical_words = ["utilize", "leverage", "synergy", "optimize", "maximize", "facilitate",
                   "paradigm", "disruption", "innovation ecosystem", "value proposition",
                   "stakeholder", "deliverable", "scalable", "actionable"]
preachy_words = ["you must", "you should", "you need to", "it's your duty",
                  "shame on", "how dare", "you're wrong", "stop eating"]

clinical_count = sum(1 for w in clinical_words if w in text_lower)
preachy_count = sum(1 for w in preachy_words if w in text_lower)

tone_score = 5.0
if clinical_count > 0:
    tone_score -= clinical_count * 0.5
    notes.append(f"Clinical language detected: {clinical_count} instance(s)")
if preachy_count > 0:
    tone_score -= preachy_count * 1.0
    notes.append(f"Preachy language detected: {preachy_count} instance(s)")
tone_score = max(1.0, tone_score)
scores["tone"] = tone_score

# 2. LANGUAGE MIX — should naturally mix English + Bahasa Malaysia
malay_words = ["sedap", "best", "padu", "mantap", "ngam", "syok", "lah", "kan",
               "mak", "kampung", "jom", "selamat", "boleh", "bagus", "memang",
               "cantik", "rindu", "sayang", "betul", "gila"]
malay_found = [w for w in malay_words if w in text_lower]

if len(malay_found) >= 2:
    lang_score = 5.0
    notes.append(f"Good BM mix: {', '.join(malay_found[:5])}")
elif len(malay_found) == 1:
    lang_score = 4.0
    notes.append(f"Minimal BM: only '{malay_found[0]}' found")
else:
    lang_score = 3.0
    notes.append("No Bahasa Malaysia detected — consider adding natural BM")
scores["language_mix"] = lang_score

# 3. BRAND VALUES ALIGNMENT
value_keywords = {
    "sustainability": ["sustainable", "planet", "eco", "green", "zero waste", "earth", "environment"],
    "health": ["healthy", "nutrition", "plant-based", "vegan", "wellness", "natural", "wholesome"],
    "accessibility": ["affordable", "easy", "simple", "everyone", "accessible", "inclusive"],
    "Malaysian heritage": ["malaysian", "malaysia", "kampung", "traditional", "heritage", "mak", "nasi"]
}
values_found = 0
for value in values:
    keywords = value_keywords.get(value, [value.lower()])
    if any(kw in text_lower for kw in keywords):
        values_found += 1
value_score = min(5.0, 3.0 + values_found * 0.5)
if values_found == 0:
    notes.append("No brand values reflected in copy")
else:
    notes.append(f"Brand values present: {values_found}/{len(values)}")
scores["brand_values"] = value_score

# 4. READABILITY
word_count = len(text.split())
if word_count < 5:
    scores["readability"] = 2.0
    notes.append(f"Very short ({word_count} words)")
elif word_count > 500:
    scores["readability"] = 3.0
    notes.append(f"Long copy ({word_count} words) — consider trimming")
else:
    scores["readability"] = 5.0

# 5. CTA PRESENCE
cta_phrases = ["shop now", "link in bio", "swipe up", "order now", "try it",
               "get yours", "check out", "click", "tap", "dm us", "visit",
               "grab yours", "follow", "subscribe", "sign up", "join", "jom"]
has_cta = any(p in text_lower for p in cta_phrases)
scores["cta"] = 5.0 if has_cta else 3.0
if not has_cta:
    notes.append("No clear CTA found — consider adding one")

# --- Overall ---
avg_score = sum(scores.values()) / len(scores)
if avg_score >= 4.0:
    verdict = "pass"
elif avg_score >= threshold:
    verdict = "pass"
elif avg_score >= 2.5:
    verdict = "needs_revision"
else:
    verdict = "reject"

print(f"Brand Voice Check: {brand_name}")
print(f"Overall Score: {avg_score:.1f}/5.0")
print(f"Verdict: {verdict}")
print()
for dim, score in scores.items():
    print(f"  {dim}: {score:.1f}/5.0")
print()
if notes:
    print("Notes:")
    for note in notes:
        print(f"  - {note}")
PYEOF
