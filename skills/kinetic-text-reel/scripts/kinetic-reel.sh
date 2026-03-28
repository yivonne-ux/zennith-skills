#!/usr/bin/env bash
# kinetic-reel.sh — Kinetic Typography Reel Generator
# Creates short-form vertical video reels with animated text overlays.
# Inspired by @ohneis652 "25 Design Styles in 40 Seconds" format.
#
# Types:
#   word-by-word  — Words appear one at a time (TikTok caption style)
#   slide-reveal  — Full phrases slide in/out with transitions
#   style-showcase — Rapid-fire images with text labels (showcase format)
#   quote-reel    — Single quote with Ken Burns + text animation
#
# Usage:
#   kinetic-reel.sh word-by-word --text "The universe is always listening" --duration 10
#   kinetic-reel.sh slide-reveal --slides "slide1.txt,slide2.txt,slide3.txt" --duration 30
#   kinetic-reel.sh style-showcase --images "img1.png,img2.png" --labels "Style 1,Style 2"
#   kinetic-reel.sh quote-reel --text "Your daily oracle message" --bg image.png
#   kinetic-reel.sh --help

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

HOME_DIR="$HOME"
OPENCLAW="${HOME_DIR}/.openclaw"
OUTPUT_DIR="${OPENCLAW}/workspace/data/content/reels/$(date +%Y-%m-%d)"
LOG_FILE="${OPENCLAW}/logs/kinetic-reel.log"
FFMPEG="$(command -v ffmpeg 2>/dev/null || echo "/opt/homebrew/bin/ffmpeg")"

# Fonts
FONT_IMPACT="/System/Library/Fonts/Supplemental/Impact.ttf"
FONT_VERDANA="/System/Library/Fonts/Supplemental/Verdana Bold.ttf"
FONT_SF="/System/Library/Fonts/SFNS.ttf"

# Video settings
WIDTH=1080
HEIGHT=1920
FPS=30
BG_COLOR="1A1A1A"  # Dark charcoal default

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

# Parse common args
TEXT=""
DURATION=10
BG_IMAGE=""
BG_COLOR_ARG=""
SLIDES=""
IMAGES=""
LABELS=""
BRAND=""
OUTPUT_FILE=""
FONT_COLOR="white"
ACCENT_COLOR="FF4444"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --text)       TEXT="$2"; shift 2 ;;
    --duration)   DURATION="$2"; shift 2 ;;
    --bg)         BG_IMAGE="$2"; shift 2 ;;
    --bg-color)   BG_COLOR_ARG="$2"; shift 2 ;;
    --slides)     SLIDES="$2"; shift 2 ;;
    --images)     IMAGES="$2"; shift 2 ;;
    --labels)     LABELS="$2"; shift 2 ;;
    --brand)      BRAND="$2"; shift 2 ;;
    --output)     OUTPUT_FILE="$2"; shift 2 ;;
    --font-color) FONT_COLOR="$2"; shift 2 ;;
    --accent)     ACCENT_COLOR="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$BG_COLOR_ARG" ]] && BG_COLOR="$BG_COLOR_ARG"
[[ -z "$OUTPUT_FILE" ]] && OUTPUT_FILE="${OUTPUT_DIR}/kinetic-${MODE}-$(date +%H%M%S).mp4"

log() { echo "[kinetic $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

# Brand color presets (only apply if user didn't override with explicit flags)
if [[ -n "$BRAND" ]]; then
  case "$BRAND" in
    jade-oracle)  [[ -z "$BG_COLOR_ARG" ]] && BG_COLOR="1A1A1A"; ACCENT_COLOR="00A86B"; [[ "$FONT_COLOR" == "white" ]] && FONT_COLOR="white" ;;
    luna)         [[ -z "$BG_COLOR_ARG" ]] && BG_COLOR="FAF8F5"; ACCENT_COLOR="D4A5A5"; [[ "$FONT_COLOR" == "white" ]] && FONT_COLOR="3A3A3A" ;;
    mirra)        [[ -z "$BG_COLOR_ARG" ]] && BG_COLOR="FFFFFF"; ACCENT_COLOR="2E7D32"; [[ "$FONT_COLOR" == "white" ]] && FONT_COLOR="1A1A1A" ;;
    pinxin-vegan) [[ -z "$BG_COLOR_ARG" ]] && BG_COLOR="F5F0E8"; ACCENT_COLOR="4CAF50"; [[ "$FONT_COLOR" == "white" ]] && FONT_COLOR="333333" ;;
    *)            [[ -z "$BG_COLOR_ARG" ]] && BG_COLOR="1A1A1A" ;;
  esac
fi

###############################################################################
# PIL Frame Generator (fallback when FFmpeg drawtext not available)
# Generates PNG frames with PIL, then stitches with FFmpeg
###############################################################################
FRAMES_SCRIPT="$(dirname "$0")/kinetic-frames.py"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

# Check if FFmpeg has drawtext filter
HAS_DRAWTEXT=false
"$FFMPEG" -filters 2>/dev/null | grep -q "drawtext" && HAS_DRAWTEXT=true

gen_via_pil() {
  local pil_mode="$1"
  local pil_text="$2"
  local pil_duration="$3"
  local frames_dir
  frames_dir=$(mktemp -d /tmp/kinetic-frames-XXXXXX)

  log "Generating frames via PIL (${pil_mode})..."
  "$PYTHON3" "$FRAMES_SCRIPT" "$pil_mode" "$pil_text" "$pil_duration" "$frames_dir" "$BG_COLOR" "${FONT_COLOR/white/FFFFFF}" 2>>"$LOG_FILE"

  local frame_count
  frame_count=$(find "$frames_dir" -name "frame-*.png" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$frame_count" -gt 0 ]]; then
    log "Stitching ${frame_count} frames into video..."
    "$FFMPEG" -y -framerate "$FPS" \
      -i "${frames_dir}/frame-%05d.png" \
      -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
      "$OUTPUT_FILE" 2>>"$LOG_FILE"
  fi

  rm -rf "$frames_dir"

  if [[ -f "$OUTPUT_FILE" ]]; then
    local size
    size=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
    log "Generated: $OUTPUT_FILE (${size}b, ${pil_duration}s)"
  else
    log "ERROR: Video generation failed"
  fi
}

###############################################################################
# TYPE 1: Word-by-Word (TikTok caption style)
###############################################################################
gen_word_by_word() {
  [[ -z "$TEXT" ]] && { echo "ERROR: --text required"; exit 1; }

  log "=== WORD-BY-WORD REEL ==="
  log "Text: ${TEXT:0:80}..."
  log "Duration: ${DURATION}s"

  gen_via_pil "word-by-word" "$TEXT" "$DURATION"
}

###############################################################################
# TYPE 2: Slide Reveal (phrases slide in with transitions)
###############################################################################
gen_slide_reveal() {
  [[ -z "$TEXT" ]] && { echo "ERROR: --text required (use | to separate slides)"; exit 1; }

  log "=== SLIDE REVEAL REEL ==="
  gen_via_pil "slide-reveal" "$TEXT" "$DURATION"
}

###############################################################################
# TYPE 3: Style Showcase (rapid images + labels — @ohneis652 format)
###############################################################################
gen_style_showcase() {
  [[ -z "$IMAGES" ]] && { echo "ERROR: --images required (comma-separated paths)"; exit 1; }
  [[ -z "$LABELS" ]] && { echo "ERROR: --labels required (comma-separated names)"; exit 1; }

  log "=== STYLE SHOWCASE REEL ==="

  IFS=',' read -ra IMG_LIST <<< "$IMAGES"
  IFS=',' read -ra LABEL_LIST <<< "$LABELS"
  local count=${#IMG_LIST[@]}
  local per_image
  per_image=$(python3 -c "print(round(${DURATION} / ${count}, 2))")

  log "Generating showcase: ${count} styles in ${DURATION}s..."

  # Generate individual segments then concatenate
  local concat_list="${OUTPUT_DIR}/concat-list.txt"
  > "$concat_list"

  for i in "${!IMG_LIST[@]}"; do
    local img="${IMG_LIST[$i]}"
    local label
    label=$(echo "${LABEL_LIST[$i]:-Style $((i+1))}" | sed 's/^ *//;s/ *$//' | sed "s/'/\\\\'/g" | sed 's/:/\\:/g')
    local segment="${OUTPUT_DIR}/seg-${i}.mp4"

    if [[ ! -f "$img" ]]; then
      log "WARN: Image not found: $img — using color placeholder"
      "$FFMPEG" -y \
        -f lavfi -i "color=c=0x${BG_COLOR}:s=${WIDTH}x${HEIGHT}:d=${per_image}:r=${FPS}" \
        -vf "drawtext=fontfile=${FONT_IMPACT}:text='${label}':fontsize=96:fontcolor=${FONT_COLOR}:x=(w-text_w)/2:y=(h-text_h)/2" \
        -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
        -t "$per_image" "$segment" 2>>"$LOG_FILE"
    else
      # Scale image to fill frame + add label overlay
      "$FFMPEG" -y \
        -loop 1 -i "$img" \
        -f lavfi -i "color=c=0x000000@0.5:s=${WIDTH}x${HEIGHT}:d=${per_image}:r=${FPS}" \
        -filter_complex "[0:v]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},setpts=PTS-STARTPTS[bg];[bg]drawtext=fontfile=${FONT_IMPACT}:text='${label}':fontsize=80:fontcolor=white:borderw=3:bordercolor=black:x=(w-text_w)/2:y=h*0.15[out]" \
        -map "[out]" \
        -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
        -t "$per_image" "$segment" 2>>"$LOG_FILE"
    fi

    [[ -f "$segment" ]] && echo "file '${segment}'" >> "$concat_list"
  done

  # Concatenate all segments
  "$FFMPEG" -y \
    -f concat -safe 0 -i "$concat_list" \
    -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
    "$OUTPUT_FILE" 2>>"$LOG_FILE"

  # Cleanup segments
  rm -f "${OUTPUT_DIR}"/seg-*.mp4 "$concat_list"

  [[ -f "$OUTPUT_FILE" ]] && log "Generated: $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE" | tr -d ' ')b)" || log "ERROR: Failed"
}

###############################################################################
# TYPE 4: Quote Reel (single quote + Ken Burns on background)
###############################################################################
gen_quote_reel() {
  [[ -z "$TEXT" ]] && { echo "ERROR: --text required"; exit 1; }

  log "=== QUOTE REEL ==="
  log "Quote: ${TEXT:0:80}..."

  if [[ -n "$BG_IMAGE" && -f "$BG_IMAGE" && "$HAS_DRAWTEXT" == "true" ]]; then
    # Ken Burns zoom on background image + text overlay (needs drawtext)
    local escaped_text
    escaped_text=$(echo "$TEXT" | sed "s/'/\\\\'/g" | sed 's/:/\\:/g' | fold -s -w 25 | head -6 | tr '\n' '|' | sed 's/|$//;s/|/\\n/g')
    "$FFMPEG" -y \
      -loop 1 -i "$BG_IMAGE" \
      -vf "scale=1200:2140,zoompan=z='min(zoom+0.0005,1.1)':d=${DURATION}*${FPS}:s=${WIDTH}x${HEIGHT}:fps=${FPS},drawtext=fontfile=${FONT_IMPACT}:text='${escaped_text}':fontsize=64:fontcolor=${FONT_COLOR}:borderw=2:bordercolor=black@0.6:x=(w-text_w)/2:y=(h-text_h)/2:line_spacing=15" \
      -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
      -t "$DURATION" \
      "$OUTPUT_FILE" 2>>"$LOG_FILE"
    [[ -f "$OUTPUT_FILE" ]] && log "Generated: $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE" | tr -d ' ')b)" || log "ERROR: Failed"
  else
    # PIL fallback
    gen_via_pil "quote" "$TEXT" "$DURATION"
  fi
}

###############################################################################
# Main
###############################################################################
case "$MODE" in
  word-by-word)    gen_word_by_word ;;
  slide-reveal)    gen_slide_reveal ;;
  style-showcase)  gen_style_showcase ;;
  quote-reel)      gen_quote_reel ;;
  help|*)
    echo "Kinetic Typography Reel Generator"
    echo ""
    echo "Usage:"
    echo "  kinetic-reel.sh word-by-word  --text 'Words appear one by one' --duration 10"
    echo "  kinetic-reel.sh slide-reveal  --text 'Phrase 1|Phrase 2|Phrase 3' --duration 15"
    echo "  kinetic-reel.sh style-showcase --images 'a.png,b.png' --labels 'Style A,Style B'"
    echo "  kinetic-reel.sh quote-reel    --text 'Your daily oracle' --bg background.png"
    echo ""
    echo "Common options:"
    echo "  --brand <name>     Brand color preset (jade-oracle, luna, mirra, pinxin-vegan)"
    echo "  --bg-color RRGGBB  Background color hex"
    echo "  --font-color <c>   Text color (white, black, etc.)"
    echo "  --accent RRGGBB    Accent color hex"
    echo "  --duration <sec>   Video duration"
    echo "  --output <path>    Output file path"
    echo ""
    echo "Output: ${OUTPUT_DIR}/"
    ;;
esac
