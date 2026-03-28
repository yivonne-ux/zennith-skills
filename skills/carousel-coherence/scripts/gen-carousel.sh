#!/usr/bin/env bash
# gen-carousel.sh — Generate visually coherent multi-slide carousels
# Slide 1 = visual DNA, slides 2-N reference it via --ref-image
#
# Usage:
#   gen-carousel.sh --brand jade-oracle --hook "Your sign from the universe" --slides 6 --style cream-editorial
#   gen-carousel.sh --brand luna --hook "Slow mornings change everything" --slides 6 --style vintage-cool
#   gen-carousel.sh --brand mirra --hook "15-min meal prep that works" --slides 6 --style warm-spiritual
#   gen-carousel.sh --brand jade-oracle --prompts-file /path/to/slide-prompts.json
#   gen-carousel.sh --dry-run --brand jade-oracle --hook "Test" --slides 3

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

HOME_DIR="$HOME"
OPENCLAW="${HOME_DIR}/.openclaw"
NANOBANANA="${OPENCLAW}/skills/nanobanana/scripts/nanobanana-gen.sh"
OUTPUT_BASE="${OPENCLAW}/workspace/data/content"
LOG_FILE="${OPENCLAW}/logs/carousel-coherence.log"
DATE=$(date +%Y-%m-%d)

mkdir -p "$(dirname "$LOG_FILE")"

# Defaults
BRAND=""
HOOK=""
SLIDE_COUNT=6
STYLE="cream-editorial"
DRY_RUN=false
PROMPTS_FILE=""
RATIO="9:16"
PLATFORM="tiktok"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)        BRAND="$2"; shift 2 ;;
    --hook)         HOOK="$2"; shift 2 ;;
    --slides)       SLIDE_COUNT="$2"; shift 2 ;;
    --style)        STYLE="$2"; shift 2 ;;
    --ratio)        RATIO="$2"; shift 2 ;;
    --platform)     PLATFORM="$2"; shift 2 ;;
    --prompts-file) PROMPTS_FILE="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=true; shift ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
[[ -z "$HOOK" && -z "$PROMPTS_FILE" ]] && { echo "ERROR: --hook or --prompts-file required"; exit 1; }

log() { echo "[carousel $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

# Style presets — background, accent, typography direction
get_style_prompt() {
  case "$1" in
    cream-editorial)
      echo "Off-white cream textured paper background (#F0EDE5), terracotta/coral accent color, dark charcoal text, serif headings, monospace for code/data, clean generous whitespace, editorial magazine feel"
      ;;
    dark-tech)
      echo "Dark navy/charcoal gradient background (#1A1B2E), cyan/teal accent (#00D4FF), white text, bold sans-serif typography, code-style elements, developer aesthetic, subtle grid lines"
      ;;
    warm-spiritual)
      echo "Warm sage and cream background, jade green (#00A86B) and gold (#D4AF37) accents, elegant serif italic typography, soft warm glow, mystical atmospheric feel, Korean editorial warmth"
      ;;
    vintage-cool)
      echo "Muted pastel background with paper texture, dusty rose and sage accents, mixed serif and handwritten italic typography, film grain overlay, vintage analog nostalgia, effortless cool"
      ;;
    bold-modern)
      echo "Clean white background, bold red/coral (#FF4444) and black accents, Impact/condensed sans-serif typography, high contrast, strong geometric layout, marketing-forward"
      ;;
    *)
      echo "Clean professional background, brand-appropriate accent colors, modern typography, balanced layout"
      ;;
  esac
}

# Narrative arc slide purposes
get_slide_purpose() {
  local n="$1"
  local total="$2"
  case "$n" in
    1) echo "HOOK — stop the scroll. Bold claim or question." ;;
    2) echo "PROBLEM — the specific pain point. Relatable struggle." ;;
    3) echo "AGITATION — make it worse. Escalate the consequences." ;;
    4) echo "SOLUTION — the answer. Your method or insight." ;;
    5) echo "FEATURE — proof it works. Data, example, or demonstration." ;;
    6) echo "CTA — call to action. Comment, save, follow, link." ;;
    *) echo "SUPPORTING — additional detail, example, or social proof." ;;
  esac
}

OUTPUT_DIR="${OUTPUT_BASE}/${BRAND}/carousels/${DATE}"
mkdir -p "$OUTPUT_DIR"

STYLE_PROMPT=$(get_style_prompt "$STYLE")

log "=== CAROUSEL GENERATION ==="
log "Brand: $BRAND | Style: $STYLE | Slides: $SLIDE_COUNT | Ratio: $RATIO"
log "Hook: ${HOOK:0:80}"
log "Output: $OUTPUT_DIR"

# ── STEP 1: Generate DNA Slide (Slide 1) ──

DNA_SLIDE="${OUTPUT_DIR}/slide-1.png"
DNA_PROMPT="Vertical ${RATIO} social media carousel cover slide. ${STYLE_PROMPT}. Large bold text overlay reading: '${HOOK}'. The text is the hero element — large, centered in upper 70% of frame, visually striking. Brand watermark small in corner. NO text in bottom 20% of the image. This slide sets the visual DNA for the entire carousel — every color, font, and layout choice will be referenced by subsequent slides."

log "Generating DNA slide (slide 1)..."

if [[ "$DRY_RUN" == "true" ]]; then
  log "  [DRY RUN] Would generate: slide-1.png"
  echo "$DNA_PROMPT" > "${OUTPUT_DIR}/slide-1.prompt.txt"
else
  if [[ -x "$NANOBANANA" ]]; then
    nb_out=$(bash "$NANOBANANA" generate \
      --brand "$BRAND" \
      --use-case social \
      --prompt "$DNA_PROMPT" \
      --model pro \
      --ratio "$RATIO" \
      --size 2K 2>>"$LOG_FILE") || true

    generated=$(echo "$nb_out" | grep -oE '/[^ ]+\.png' | tail -1)

    if [[ -n "$generated" && -f "$generated" ]]; then
      cp "$generated" "$DNA_SLIDE"
      log "  DNA slide generated: $DNA_SLIDE ($(wc -c < "$DNA_SLIDE" | tr -d ' ')b)"
    else
      log "  ERROR: DNA slide generation failed"
      echo "$DNA_PROMPT" > "${OUTPUT_DIR}/slide-1.prompt.txt"
    fi
  else
    log "  NanoBanana not found — saving prompt only"
    echo "$DNA_PROMPT" > "${OUTPUT_DIR}/slide-1.prompt.txt"
  fi
fi

# ── STEP 2: Generate Slides 2-N with DNA Reference ──

for i in $(seq 2 "$SLIDE_COUNT"); do
  SLIDE_FILE="${OUTPUT_DIR}/slide-${i}.png"
  SLIDE_PURPOSE=$(get_slide_purpose "$i" "$SLIDE_COUNT")

  SLIDE_PROMPT="Vertical ${RATIO} carousel slide ${i} of ${SLIDE_COUNT}. MATCH the visual style, colors, typography, and layout of the reference image EXACTLY — same background texture, same accent colors, same text style, same brand feel. Content for this slide: ${SLIDE_PURPOSE}. Slide number '${i}/${SLIDE_COUNT}' small in corner. NO text in bottom 20% of the image."

  log "Generating slide ${i}/${SLIDE_COUNT} (${SLIDE_PURPOSE:0:40})..."

  if [[ "$DRY_RUN" == "true" ]]; then
    log "  [DRY RUN] Would generate: slide-${i}.png (referencing slide-1)"
    echo "$SLIDE_PROMPT" > "${OUTPUT_DIR}/slide-${i}.prompt.txt"
    continue
  fi

  if [[ -x "$NANOBANANA" && -f "$DNA_SLIDE" ]]; then
    nb_out=$(bash "$NANOBANANA" generate \
      --brand "$BRAND" \
      --use-case social \
      --prompt "$SLIDE_PROMPT" \
      --ref-image "$DNA_SLIDE" \
      --model pro \
      --ratio "$RATIO" \
      --size 2K 2>>"$LOG_FILE") || true

    generated=$(echo "$nb_out" | grep -oE '/[^ ]+\.png' | tail -1)

    if [[ -n "$generated" && -f "$generated" ]]; then
      cp "$generated" "$SLIDE_FILE"
      log "  Slide ${i} generated: $(wc -c < "$SLIDE_FILE" | tr -d ' ')b"
    else
      log "  ERROR: Slide ${i} failed — saving prompt"
      echo "$SLIDE_PROMPT" > "${OUTPUT_DIR}/slide-${i}.prompt.txt"
    fi
  else
    log "  Skipping (no DNA slide or NanoBanana) — saving prompt"
    echo "$SLIDE_PROMPT" > "${OUTPUT_DIR}/slide-${i}.prompt.txt"
  fi

  # Rate limit between API calls
  sleep 2
done

# ── STEP 3: Summary ──

GENERATED=$(find "$OUTPUT_DIR" -name "slide-*.png" 2>/dev/null | wc -l | tr -d ' ')
PROMPTS=$(find "$OUTPUT_DIR" -name "slide-*.prompt.txt" 2>/dev/null | wc -l | tr -d ' ')

log "=== CAROUSEL COMPLETE ==="
log "  Images: ${GENERATED}/${SLIDE_COUNT}"
log "  Prompts: ${PROMPTS}"
log "  Output: ${OUTPUT_DIR}/"

# Convert to JPG if TikTok (requires JPG not PNG)
if [[ "$PLATFORM" == "tiktok" && "$GENERATED" -gt 0 ]]; then
  log "Converting to JPG for TikTok..."
  for png in "${OUTPUT_DIR}"/slide-*.png; do
    [[ -f "$png" ]] || continue
    jpg="${png%.png}.jpg"
    sips -s format jpeg -s formatOptions 95 "$png" --out "$jpg" >/dev/null 2>&1 && \
      log "  Converted: $(basename "$jpg")" || \
      log "  WARN: Failed to convert $(basename "$png")"
  done
fi

echo ""
echo "Carousel ready: ${OUTPUT_DIR}/"
echo "  ${GENERATED} images, ${PROMPTS} prompts"
