#!/usr/bin/env bash
# jade-content-gen.sh — Auto-generate Jade Oracle video content from templates
# Uses Remotion ($0/render) + QMDJ oracle card data
#
# Usage:
#   jade-content-gen.sh daily-oracle           Generate today's oracle card reel
#   jade-content-gen.sh pick-a-card            Generate 3 pick-a-card reels (series)
#   jade-content-gen.sh hook --text "..."      Generate hook reel with custom text
#   jade-content-gen.sh moment-gate            Generate QMDJ moment gate reel
#   jade-content-gen.sh batch --count 5        Generate batch of mixed content

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW="$HOME/.openclaw"
REMOTION_RENDER="$SCRIPT_DIR/remotion-render.sh"
OUTPUT_DIR="$OPENCLAW/workspace/data/productions/jade-oracle/$(date +%Y-%m-%d)"
CARD_DATA="$OPENCLAW/skills/psychic-reading-engine/data/jade-oracle-card-system.json"
TEMPLATES="$SKILL_DIR/config/jade-oracle-templates.json"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

mkdir -p "$OUTPUT_DIR"

MODE="${1:-help}"
shift 2>/dev/null || true

TEXT=""
COUNT=5
while [[ $# -gt 0 ]]; do
  case "$1" in
    --text)  TEXT="$2"; shift 2 ;;
    --count) COUNT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

log() { echo "[jade-gen $(date +%H:%M:%S)] $1"; }

# Pull a random card from the deck
pull_card() {
  "$PYTHON3" - "$CARD_DATA" "${1:-}" << 'PYEOF'
import json, sys, random, os

data_file = sys.argv[1]
specific_card = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ""

if not os.path.exists(data_file):
    # Fallback if card data not found
    cards = [
        {"name": "The Phoenix", "keywords": "Rebirth, Transformation, Rising", "message": "What's ending is making space for something extraordinary"},
        {"name": "The Open Road", "keywords": "New Beginnings, Freedom, Choice", "message": "A door is opening. Trust yourself to walk through it"},
        {"name": "The Healer", "keywords": "Restoration, Patience, Inner Wisdom", "message": "Your healing is not linear but it IS happening"},
        {"name": "The Sage", "keywords": "Knowledge, Guidance, Clarity", "message": "The answer you seek is already within you"},
        {"name": "The Crown", "keywords": "Divine Protection, Higher Self, Grace", "message": "You are being guided more than you realize"},
    ]
    card = random.choice(cards) if not specific_card else next((c for c in cards if specific_card.lower() in c["name"].lower()), random.choice(cards))
    print(json.dumps(card))
    sys.exit(0)

with open(data_file) as f:
    deck = json.load(f)

all_cards = []
for tier in ["archetype_cards", "pathway_cards", "guardian_cards"]:
    tier_data = deck.get(tier, {})
    for card in tier_data.get("cards", tier_data if isinstance(tier_data, list) else []):
        name = card.get("card_name", card.get("name", "Unknown"))
        keywords = ", ".join(card.get("keywords", [])[:3])
        # Get the light meaning or first meaning
        if "light" in card:
            message = card["light"]
        elif "meaning" in card:
            message = card["meaning"]
        elif "advice" in card:
            message = card["advice"]
        else:
            message = keywords
        # Truncate for video
        if len(message) > 80:
            message = message[:77] + "..."
        all_cards.append({"name": name, "keywords": keywords, "message": message, "tier": tier})

if specific_card:
    matches = [c for c in all_cards if specific_card.lower() in c["name"].lower()]
    card = matches[0] if matches else random.choice(all_cards)
else:
    card = random.choice(all_cards)

print(json.dumps(card))
PYEOF
}

# Pull a random hook from the library
pull_hook() {
  "$PYTHON3" -c "
import json, random
with open('$TEMPLATES') as f:
    t = json.load(f)
hooks = t.get('hooks_library', [])
h = random.choice(hooks) if hooks else {'hook': 'The universe has a|*message* for you', 'type': 'fate'}
print(h['hook'])
"
}

case "$MODE" in
  daily-oracle)
    log "=== DAILY ORACLE CARD ==="
    CARD_JSON=$(pull_card)
    CARD_NAME=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['name'])")
    CARD_KEYWORDS=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['keywords'])")
    CARD_MSG=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['message'])")

    log "Card: $CARD_NAME ($CARD_KEYWORDS)"
    log "Message: $CARD_MSG"

    OUTPUT="$OUTPUT_DIR/daily-oracle-$(date +%H%M%S).mp4"

    bash "$REMOTION_RENDER" kinetic \
      --text "Today's Oracle|*${CARD_NAME}*|${CARD_KEYWORDS}|${CARD_MSG}" \
      --output "$OUTPUT" 2>&1 | sed 's/^/  /'

    if [[ -f "$OUTPUT" ]]; then
      log "Generated: $OUTPUT ($(wc -c < "$OUTPUT" | tr -d ' ')b)"
      echo "$OUTPUT"
    fi
    ;;

  pick-a-card)
    log "=== PICK A CARD (3 cards) ==="

    for i in 1 2 3; do
      CARD_JSON=$(pull_card)
      CARD_NAME=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['name'])")
      CARD_MSG=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['message'])")

      log "Card $i: $CARD_NAME"
      OUTPUT="$OUTPUT_DIR/pick-a-card-${i}-$(date +%H%M%S).mp4"

      bash "$REMOTION_RENDER" kinetic \
        --text "Pick A Card|You chose *${i}*|${CARD_NAME}|${CARD_MSG}|Follow for daily readings" \
        --output "$OUTPUT" 2>&1 | sed 's/^/  /'

      [[ -f "$OUTPUT" ]] && log "Card $i: $OUTPUT"
    done
    ;;

  hook)
    log "=== HOOK REEL ==="
    if [[ -z "$TEXT" ]]; then
      TEXT=$(pull_hook)
      log "Using random hook: $TEXT"
    fi

    OUTPUT="$OUTPUT_DIR/hook-reel-$(date +%H%M%S).mp4"
    bash "$REMOTION_RENDER" kinetic \
      --text "$TEXT|Follow @the_jade_oracle" \
      --output "$OUTPUT" 2>&1 | sed 's/^/  /'

    [[ -f "$OUTPUT" ]] && log "Generated: $OUTPUT" && echo "$OUTPUT"
    ;;

  moment-gate)
    log "=== MOMENT GATE REEL ==="

    # Pull a pathway card (these are the "gates/doors")
    CARD_JSON=$(pull_card)
    GATE_NAME=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['name'])")
    GATE_MSG=$(echo "$CARD_JSON" | "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin)['message'])")

    log "Gate: $GATE_NAME"

    OUTPUT="$OUTPUT_DIR/moment-gate-$(date +%H%M%S).mp4"
    bash "$REMOTION_RENDER" kinetic \
      --text "If you're seeing this|it's *not* a coincidence|${GATE_NAME}|is open for you|${GATE_MSG}" \
      --output "$OUTPUT" 2>&1 | sed 's/^/  /'

    [[ -f "$OUTPUT" ]] && log "Generated: $OUTPUT" && echo "$OUTPUT"
    ;;

  batch)
    log "=== BATCH GENERATE ($COUNT pieces) ==="
    GENERATED=0

    # Mix: 2 daily oracle, 1 pick-a-card set, 1 moment gate, rest hooks
    bash "$0" daily-oracle && GENERATED=$((GENERATED+1))
    bash "$0" daily-oracle && GENERATED=$((GENERATED+1))
    bash "$0" pick-a-card && GENERATED=$((GENERATED+3))
    bash "$0" moment-gate && GENERATED=$((GENERATED+1))

    REMAINING=$((COUNT - GENERATED))
    for i in $(seq 1 "$REMAINING"); do
      bash "$0" hook && GENERATED=$((GENERATED+1))
    done

    log "Batch complete: $GENERATED pieces in $OUTPUT_DIR/"
    echo ""
    echo "Generated $GENERATED videos in $OUTPUT_DIR/"
    ls -lh "$OUTPUT_DIR/"*.mp4 2>/dev/null | wc -l | tr -d ' '
    echo " videos ready"
    ;;

  help|*)
    cat << 'HELPEOF'
Jade Oracle Content Generator — $0/render via Remotion

Usage:
  jade-content-gen.sh daily-oracle     Today's oracle card reel (12s)
  jade-content-gen.sh pick-a-card      3 pick-a-card reels (series, 15s each)
  jade-content-gen.sh hook             Random fate hook reel (10s)
  jade-content-gen.sh hook --text "Line1|Line2|*emphasis*"
  jade-content-gen.sh moment-gate      QMDJ moment gate reel (15s)
  jade-content-gen.sh batch --count 7  Mixed batch (daily + pick + gate + hooks)

All renders are $0 via Remotion. Output: ~/.openclaw/workspace/data/productions/jade-oracle/YYYY-MM-DD/
HELPEOF
    ;;
esac
