#!/usr/bin/env bash
# compose.sh — Brand-aware prompt composition + NanoBanana generation
# Reads brand DNA → product photos → reference designs → composes prompt → generates
# Usage: compose.sh --brand mirra --template comparison --headline "This or That"
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
NANOBANANA="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
LOG_FILE="$HOME/.openclaw/logs/brand-studio.log"

log() { mkdir -p "$(dirname "$LOG_FILE")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
die() { echo "ERROR: $*" >&2; log "ERROR: $*"; exit 1; }

# --- Parse args ---
BRAND="" TEMPLATE="" HEADLINE="" SUBTITLE="" PRODUCT="" RATIO="1:1" MODEL="flash" DRY_RUN="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)     BRAND="$2";     shift 2 ;;
    --template)  TEMPLATE="$2";  shift 2 ;;
    --headline)  HEADLINE="$2";  shift 2 ;;
    --subtitle)  SUBTITLE="$2";  shift 2 ;;
    --product)   PRODUCT="$2";   shift 2 ;;
    --ratio)     RATIO="$2";     shift 2 ;;
    --model)     MODEL="$2";     shift 2 ;;
    --dry-run)   DRY_RUN="true"; shift ;;
    --help)
      echo "compose.sh — Brand-aware ad composition via NanoBanana"
      echo ""
      echo "USAGE: compose.sh --brand <slug> --template <type> [options]"
      echo ""
      echo "TEMPLATES:"
      echo "  comparison   Split left/right: regular food vs brand (M4A/M4B style)"
      echo "  grid         3x3 or 2x3 product showcase (M3A style)"
      echo "  hero         Single product hero shot with badges (M2A style)"
      echo "  lifestyle    Product in lifestyle context (desk, kitchen, etc.)"
      echo "  collage      Multi-product collage (M3B style)"
      echo ""
      echo "OPTIONS:"
      echo "  --headline <text>    Main headline text"
      echo "  --subtitle <text>    Subtitle text"
      echo "  --product <name>     Specific product to feature"
      echo "  --ratio <r>          Aspect ratio (default: 1:1)"
      echo "  --model <m>          flash or pro (default: flash)"
      echo "  --dry-run            Show prompt without generating"
      exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -z "$BRAND" ]] && die "Missing --brand"
[[ -z "$TEMPLATE" ]] && die "Missing --template"

DNA_FILE="$BRANDS_DIR/$BRAND/DNA.json"
ASSETS_DIR="$BRANDS_DIR/$BRAND/assets"
[[ -f "$DNA_FILE" ]] || die "Brand DNA not found: $DNA_FILE"

# --- Extract brand DNA ---
DNA_TMP=$(mktemp /tmp/brand-dna.XXXXXX)
python3 - "$DNA_FILE" > "$DNA_TMP" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
v = d.get('visual', {})
colors = v.get('colors', {})
print(d.get('display_name',''))
print(d.get('tagline',''))
print(colors.get('primary',''))
print(colors.get('secondary',''))
print(colors.get('background',''))
print(v.get('typography',{}).get('heading',''))
print(v.get('style',''))
print(v.get('lighting_default',''))
print(v.get('logo_placement',''))
print(' | '.join(v.get('badges', [])))
print(' | '.join(v.get('avoid', [])))
PYEOF

{
  read -r DISPLAY_NAME
  read -r TAGLINE
  read -r PRIMARY
  read -r SECONDARY
  read -r BACKGROUND
  read -r HEADING_FONT
  read -r STYLE
  read -r LIGHTING
  read -r LOGO_PLACEMENT
  read -r BADGES
  read -r AVOID
} < "$DNA_TMP"
rm -f "$DNA_TMP"

log "Composing: brand=$BRAND template=$TEMPLATE headline=$HEADLINE"

# --- Select reference image based on template ---
select_ref() {
  local template="$1"
  local assets_dir="$2"

  case "$template" in
    comparison)
      # Prefer comparison template ref
      for f in "$assets_dir"/ref-comparison*.jpg "$assets_dir"/ref-comparison*.png; do
        [[ -f "$f" ]] && echo "$f" && return
      done
      ;;
    grid)
      # Look for grid/showcase ref
      for f in "$assets_dir"/ref-grid*.jpg "$assets_dir"/ref-showcase*.jpg; do
        [[ -f "$f" ]] && echo "$f" && return
      done
      ;;
    hero|lifestyle)
      # Look for hero/lifestyle ref
      for f in "$assets_dir"/ref-bento*.png "$assets_dir"/ref-lifestyle*.jpg; do
        [[ -f "$f" ]] && echo "$f" && return
      done
      ;;
  esac

  # Fallback: brand guide
  for f in "$assets_dir"/brand-guide*.jpg "$assets_dir"/brand-guide*.png; do
    [[ -f "$f" ]] && echo "$f" && return
  done
  echo ""
}

REF_IMAGE=$(select_ref "$TEMPLATE" "$ASSETS_DIR")

# --- Select product photo ---
select_product_photo() {
  local assets_dir="$1"
  local product="$2"

  if [[ -n "$product" ]]; then
    # Try to find matching product photo
    local slug
    slug=$(echo "$product" | tr ' ' '-' | tr 'A-Z' 'a-z')
    for f in "$assets_dir"/ref-*"$slug"*.png "$assets_dir"/ref-*"$slug"*.jpg; do
      [[ -f "$f" ]] && echo "$f" && return
    done
  fi

  # Pick a random product photo from assets
  local photos=()
  for f in "$assets_dir"/ref-*topview*.png "$assets_dir"/ref-*bento*.png; do
    [[ -f "$f" ]] && photos+=("$f")
  done

  if [[ ${#photos[@]} -gt 0 ]]; then
    local idx=$((RANDOM % ${#photos[@]}))
    echo "${photos[$idx]}"
  fi
}

PRODUCT_PHOTO=$(select_product_photo "$ASSETS_DIR" "$PRODUCT")

# --- Build template-specific prompt ---
build_prompt() {
  local template="$1"
  local base_prompt=""

  case "$template" in
    comparison)
      local hl="${HEADLINE:-This or That}"
      local sub="${SUBTITLE:-Same calories, totally different quality}"
      base_prompt="Social media ad design. Split comparison layout. Left side: ${PRIMARY} salmon pink background, bold black serif headline showing the unhealthy option with dark calorie badge (e.g. 900 kcal). Right side: ${BACKGROUND} cream background with the ${DISPLAY_NAME} healthy bento box alternative showing lower calories in pink badge. Headline '${hl}' in bold black serif at top. Center thin dashed vertical divider. '${DISPLAY_NAME}' black serif logo top-right corner. Bottom text: '${TAGLINE}' in black serif. ${BADGES} badges near the healthy side. DESIGNED AD LAYOUT composite, not raw photograph. ${STYLE}. ${LIGHTING}."
      ;;
    grid)
      local hl="${HEADLINE:-Counting Calories at Work?}"
      local sub="${SUBTITLE:-We Did It. Delicious bentos under 500 kcal done!}"
      base_prompt="Social media ad design. Solid ${PRIMARY} salmon pink background. Bold black serif headline: '${hl}' with subtitle '${sub}'. '${DISPLAY_NAME}' black serif logo top-right. 3x3 grid of 9 different top-view bento box photographs, each in white compartmented containers showing different colorful Malaysian meals. Below each bento: meal name and calorie count in parentheses. Decorative organic leaf shapes in corners. ${BADGES} badge bottom-right. DESIGNED AD LAYOUT, ${STYLE}. ${LIGHTING}."
      ;;
    hero)
      local hl="${HEADLINE:-Your Lunch, Upgraded}"
      base_prompt="Social media ad design. ${BACKGROUND} cream background with subtle ${PRIMARY} salmon pink organic blob shapes. Center: a beautiful top-view product photograph of a ${DISPLAY_NAME} white compartmented bento box with vibrant healthy Malaysian food. '${DISPLAY_NAME}' black serif logo top-right. Headline '${hl}' in bold black serif. Pink circular calorie badge (e.g. 423 kcal). ${BADGES} badges. Bottom: '${TAGLINE}'. DESIGNED AD LAYOUT, ${STYLE}. ${LIGHTING}."
      ;;
    lifestyle)
      base_prompt="Lifestyle product photography. A ${DISPLAY_NAME} white 4-compartment bento box with vibrant healthy Malaysian food on a light wooden desk. Props: glass of iced lemon tea, white ceramic mug, linen napkin, notebook. ${LIGHTING}. Shot from above at 45 degrees. Warm, inviting, feminine. NOT a designed layout — this is a contextual product photo."
      ;;
    collage)
      local hl="${HEADLINE:-50+ International Bento}"
      local sub="${SUBTITLE:-All Under 500 kcal}"
      base_prompt="Social media ad design. ${PRIMARY} salmon pink background. Bold black serif headline: '${hl}' with large number callout. Subtitle: '${sub}'. Scattered collage of 6+ different bento box photographs at slight angles, overlapping naturally. ${DISPLAY_NAME} logo top-right. Checkmark badges: Nutritionist Approved, Fresh Delivery, High Satiety. DESIGNED AD LAYOUT, ${STYLE}."
      ;;
    *)
      die "Unknown template: $template"
      ;;
  esac

  # Append avoids
  base_prompt="${base_prompt} AVOID: ${AVOID}."

  echo "$base_prompt"
}

PROMPT=$(build_prompt "$TEMPLATE")

# --- Determine use case and ratio ---
USE_CASE="social"
if [[ "$TEMPLATE" == "lifestyle" ]]; then
  USE_CASE="lifestyle"
fi

# --- Report ---
echo "=== Brand Studio: Compose ==="
echo "  Brand:    $BRAND ($DISPLAY_NAME)"
echo "  Template: $TEMPLATE"
echo "  Headline: ${HEADLINE:-<default>}"
echo "  Ratio:    $RATIO"
echo "  Model:    $MODEL"
echo "  Ref:      ${REF_IMAGE:-none}"
echo "  Product:  ${PRODUCT_PHOTO:-none}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "=== DRY RUN ==="
  echo "Prompt: $PROMPT"
  echo ""
  echo "Would call: nanobanana-gen.sh generate --brand $BRAND --use-case $USE_CASE --ratio $RATIO --model $MODEL"
  [[ -n "$REF_IMAGE" ]] && echo "  --ref-image $REF_IMAGE"
  exit 0
fi

# --- Generate via NanoBanana ---
NANO_ARGS=(generate --brand "$BRAND" --use-case "$USE_CASE" --prompt "$PROMPT" --ratio "$RATIO" --model "$MODEL" --funnel-stage MOFU)
[[ -n "$REF_IMAGE" ]] && NANO_ARGS+=(--ref-image "$REF_IMAGE")

echo "Generating via NanoBanana..."
OUTPUT=$(bash "$NANOBANANA" "${NANO_ARGS[@]}" 2>&1)
echo "$OUTPUT"

# Extract output path — look for the "Output:" line from NanoBanana (the actual generated file)
OUTPUT_PATH=$(echo "$OUTPUT" | grep "Output:" | sed 's/.*Output:[[:space:]]*//' | tr -d '[:space:]')
if [[ -z "$OUTPUT_PATH" ]] || [[ ! -f "$OUTPUT_PATH" ]]; then
  # Fallback: find the most recent mirra image
  OUTPUT_PATH=$(find "$HOME/.openclaw/workspace/data/images/$BRAND" -name "*.png" -newer /tmp/nanobanana-lastcall -type f 2>/dev/null | sort | tail -1)
fi
if [[ -n "$OUTPUT_PATH" ]] && [[ -f "$OUTPUT_PATH" ]]; then
  echo ""
  echo "OUTPUT_PATH=$OUTPUT_PATH"
  log "Generated: $OUTPUT_PATH (template=$TEMPLATE)"
else
  die "Generation failed — no output file found"
fi
