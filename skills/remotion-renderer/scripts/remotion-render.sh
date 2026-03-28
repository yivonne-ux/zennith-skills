#!/usr/bin/env bash
# remotion-render.sh — CLI wrapper for Zennith OS Remotion Renderer
#
# Usage:
#   remotion-render.sh render   --props <json> --output <mp4> [--brand <name>]
#   remotion-render.sh kinetic  --text "..." --style word_pop [--brand jade-oracle]
#   remotion-render.sh brand-reveal --brand mirra --products "a.png,b.png" --style zoom_burst
#   remotion-render.sh preview
#   remotion-render.sh studio

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW="$HOME/.openclaw"
OUTPUT_DIR="${OPENCLAW}/workspace/data/videos/remotion/$(date +%Y-%m-%d)"
LOG_FILE="${OPENCLAW}/logs/remotion-render.log"
NPX="$(command -v npx 2>/dev/null || echo "/opt/homebrew/bin/npx")"

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

# Parse args
PROPS_FILE=""
OUTPUT_FILE=""
BRAND=""
TEXT=""
STYLE=""
PRODUCTS=""
COMPOSITION="UGCComposition"
CONCURRENCY=2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --props)        PROPS_FILE="$2"; shift 2 ;;
    --output|-o)    OUTPUT_FILE="$2"; shift 2 ;;
    --brand)        BRAND="$2"; shift 2 ;;
    --text)         TEXT="$2"; shift 2 ;;
    --style)        STYLE="$2"; shift 2 ;;
    --products)     PRODUCTS="$2"; shift 2 ;;
    --composition)  COMPOSITION="$2"; shift 2 ;;
    --concurrency)  CONCURRENCY="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[remotion $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

[[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="${OUTPUT_DIR}/remotion-${MODE}-$(date +%H%M%S).mp4"

case "$MODE" in
  render)
    [[ -z "$PROPS_FILE" ]] && { echo "ERROR: --props required"; exit 1; }
    [[ ! -f "$PROPS_FILE" ]] && { echo "ERROR: Props file not found: $PROPS_FILE"; exit 1; }

    log "=== REMOTION RENDER ==="
    log "Props: $PROPS_FILE"
    log "Output: $OUTPUT_FILE"
    log "Composition: $COMPOSITION"

    cd "$SKILL_DIR"
    "$NPX" remotion render src/index.ts "$COMPOSITION" \
      --props "$PROPS_FILE" \
      --output "$OUTPUT_FILE" \
      --concurrency "$CONCURRENCY" \
      2>>"$LOG_FILE"

    if [[ -f "$OUTPUT_FILE" ]]; then
      SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
      log "SUCCESS: $OUTPUT_FILE (${SIZE}b)"
      echo "$OUTPUT_FILE"
    else
      log "ERROR: Render failed"
      exit 1
    fi
    ;;

  kinetic)
    [[ -z "$TEXT" ]] && { echo "ERROR: --text required"; exit 1; }
    STYLE="${STYLE:-word_pop}"

    log "=== KINETIC TEXT RENDER ==="
    log "Text: ${TEXT:0:80}..."
    log "Style: $STYLE"

    # Generate props JSON for kinetic composition (flat block props per UGC schema)
    LINES_JSON=$(echo "$TEXT" | python3 -c "
import sys, json
text = sys.stdin.read().strip()
lines = [{'text': l.strip()} for l in text.split('|') if l.strip()]
print(json.dumps(lines))
")
    PROPS_TMP="/tmp/remotion-kinetic-$$.json"
    cat > "$PROPS_TMP" << PROPEOF
{
  "variant_id": "kinetic_$(date +%s)",
  "fps": 30,
  "total_duration_s": 10,
  "width": 1080,
  "height": 1920,
  "blocks": [{
    "id": "kinetic_1",
    "type": "kinetic_text",
    "file": "",
    "duration_s": 10,
    "start_s": 0,
    "text_overlay": null,
    "kinetic_lines": $LINES_JSON,
    "kinetic_animation": "$STYLE",
    "kinetic_bg_color": "#1A1A1A"
  }],
  "voiceover": null,
  "voiceover_volume": 0,
  "bgm": null,
  "bgm_volume": 0,
  "bgm_fade_out_s": 0,
  "watermark": null,
  "enable_transitions": false,
  "voiceover_start_s": 0,
  "text_style_preset": "cn_black_outline"
}
PROPEOF

    cd "$SKILL_DIR"
    "$NPX" remotion render src/index.ts UGCComposition \
      --props "$PROPS_TMP" \
      --output "$OUTPUT_FILE" \
      --concurrency "$CONCURRENCY" \
      2>>"$LOG_FILE"

    rm -f "$PROPS_TMP"

    if [[ -f "$OUTPUT_FILE" ]]; then
      SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
      log "SUCCESS: $OUTPUT_FILE (${SIZE}b)"
      echo "$OUTPUT_FILE"
    else
      log "ERROR: Kinetic render failed"
      exit 1
    fi
    ;;

  preview)
    log "Starting Remotion preview server..."
    cd "$SKILL_DIR"
    "$NPX" remotion preview src/index.ts
    ;;

  studio)
    log "Starting Remotion Studio..."
    cd "$SKILL_DIR"
    "$NPX" remotion studio src/index.ts
    ;;

  help|*)
    cat << 'HELPEOF'
Remotion Renderer — Zennith OS Video Skill

Usage:
  remotion-render.sh render       --props <json> --output <mp4> [--brand <name>]
  remotion-render.sh kinetic      --text "Line 1|Line 2" --style word_pop
  remotion-render.sh brand-reveal --brand mirra --products "a.png,b.png"
  remotion-render.sh preview      Start browser preview
  remotion-render.sh studio       Start Remotion Studio

Compositions:
  UGCComposition     Multi-block AIDA video ad (main)
  HelloWorld         Test composition

Kinetic Styles:
  word_pop           Words pop with spring scale (default)
  line_slide         Lines slide from alternating sides
  typewriter         Character-by-character reveal
  scale_bounce       Lines scale with overshoot

Brand Presets:
  mirra, jade-oracle, luna, pinxin-vegan, rasaya

Output: ~/.openclaw/workspace/data/videos/remotion/YYYY-MM-DD/
HELPEOF
    ;;
esac
