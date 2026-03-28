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
  frames_dir=$(mktemp -d "${OPENCLAW}/workspace/data/content/reels/tmp-frames-XXXXXX")

  # Cleanup on exit/error
  trap "rm -rf '$frames_dir' 2>/dev/null" EXIT

  log "Generating frames via PIL (${pil_mode})..."
  "$PYTHON3" "$FRAMES_SCRIPT" "$pil_mode" "$pil_text" "$pil_duration" "$frames_dir" "$BG_COLOR" "${FONT_COLOR/white/FFFFFF}" 2>>"$LOG_FILE"

  # Detect frame format (BMP preferred for speed, PNG fallback)
  local frame_ext="bmp"
  local frame_count
  frame_count=$(find "$frames_dir" -name "frame-*.bmp" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${frame_count:-0}" -eq 0 ]]; then
    frame_ext="png"
    frame_count=$(find "$frames_dir" -name "frame-*.png" 2>/dev/null | wc -l | tr -d ' ')
  fi

  if [[ "${frame_count:-0}" -gt 0 ]]; then
    log "Stitching ${frame_count} ${frame_ext} frames into video..."
    "$FFMPEG" -y -framerate "$FPS" \
      -i "${frames_dir}/frame-%05d.${frame_ext}" \
      -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
      "$OUTPUT_FILE" 2>>"$LOG_FILE"
  fi

  rm -rf "$frames_dir"
  trap - EXIT

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
# Uses PIL to composite label onto each image, then FFmpeg to stitch
###############################################################################
gen_style_showcase() {
  [[ -z "$IMAGES" ]] && { echo "ERROR: --images required (comma-separated paths)"; exit 1; }
  [[ -z "$LABELS" ]] && { echo "ERROR: --labels required (comma-separated names)"; exit 1; }

  log "=== STYLE SHOWCASE REEL ==="

  IFS=',' read -ra IMG_LIST <<< "$IMAGES"
  IFS=',' read -ra LABEL_LIST <<< "$LABELS"
  local count=${#IMG_LIST[@]}
  local frames_per_image
  frames_per_image=$(( (DURATION * FPS) / count ))

  log "Generating showcase: ${count} styles in ${DURATION}s (${frames_per_image} frames each)..."

  local frames_dir
  frames_dir=$(mktemp -d "${OPENCLAW}/workspace/data/content/reels/tmp-showcase-XXXXXX")
  trap "rm -rf '$frames_dir' 2>/dev/null" EXIT

  # Use PIL to composite label onto each image, generate frames
  local frame_num=0
  for i in "${!IMG_LIST[@]}"; do
    local img="${IMG_LIST[$i]}"
    local label="${LABEL_LIST[$i]:-Style $((i+1))}"

    # Generate frames for this image via Python/PIL
    "$PYTHON3" - "$img" "$label" "$frames_per_image" "$frames_dir" "$frame_num" "$BG_COLOR" "${FONT_COLOR/white/FFFFFF}" << 'PYEOF'
import sys, os, shutil
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit(1)

img_path = sys.argv[1]
label = sys.argv[2]
num_frames = int(sys.argv[3])
output_dir = sys.argv[4]
start_frame = int(sys.argv[5])
bg_hex = sys.argv[6]
fg_hex = sys.argv[7]

W, H = 1080, 1920

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def get_font(size):
    for f in ["/System/Library/Fonts/Supplemental/Impact.ttf",
              "/System/Library/Fonts/Supplemental/Verdana Bold.ttf"]:
        if os.path.exists(f):
            try: return ImageFont.truetype(f, size)
            except: continue
    return ImageFont.load_default()

bg_rgb = hex_to_rgb(bg_hex)
font = get_font(72)

# Load and resize image, or create placeholder
if os.path.exists(img_path):
    src = Image.open(img_path).convert('RGB')
    # Scale to fill
    scale = max(W / src.width, H / src.height)
    src = src.resize((int(src.width * scale), int(src.height * scale)), Image.LANCZOS)
    # Center crop
    left = (src.width - W) // 2
    top = (src.height - H) // 2
    src = src.crop((left, top, left + W, top + H))
else:
    src = Image.new('RGB', (W, H), bg_rgb)

# Add label at top 15%
draw = ImageDraw.Draw(src)
bbox = draw.textbbox((0, 0), label, font=font)
tw = bbox[2] - bbox[0]
x = (W - tw) // 2
y = int(H * 0.12)
# Shadow
draw.text((x+2, y+2), label, font=font, fill=(0, 0, 0))
draw.text((x, y), label, font=font, fill=(255, 255, 255))

# Save first frame, copy for rest
first = f"{output_dir}/frame-{start_frame:05d}.bmp"
src.save(first)
for f in range(1, num_frames):
    shutil.copy2(first, f"{output_dir}/frame-{start_frame + f:05d}.bmp")

print(f"Generated {num_frames} frames for '{label}'")
PYEOF

    frame_num=$((frame_num + frames_per_image))
  done

  # Stitch all frames
  local total_frames
  total_frames=$(find "$frames_dir" -name "frame-*.bmp" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "${total_frames:-0}" -gt 0 ]]; then
    log "Stitching ${total_frames} frames..."
    "$FFMPEG" -y -framerate "$FPS" \
      -i "${frames_dir}/frame-%05d.bmp" \
      -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
      "$OUTPUT_FILE" 2>>"$LOG_FILE"
  fi

  rm -rf "$frames_dir"
  trap - EXIT

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
