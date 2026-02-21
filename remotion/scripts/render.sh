#!/usr/bin/env bash
# MotionKit Render — CLI wrapper for Remotion rendering
# Usage:
#   render.sh podcast-clip --audio audio.mp3 --captions captions.json --speaker "Jenn" --episode "Ep 1"
#   render.sh animated-captions --video input.mp4 --captions captions.json --style tiktok
#   render.sh product-showcase --image product.png --name "Rendang Paste" --price "RM15.90"
#   render.sh brand-intro --logo logo.png --tagline "Plant-powered, Malaysian-hearted"
#   render.sh data-chart --data data.json --type bar --title "Monthly Sales"
#
# Flags:
#   --output PATH       Output file path (default: ~/motionkit-output/<composition>-<timestamp>.mp4)
#   --quality VALUE     CRF quality 0-63 (default: 18, lower=better)
#   --format FORMAT     Output format: mp4, webm, gif (default: mp4)
#   --duration SECONDS  Override duration in seconds
#   --brand SLUG        Brand slug — reads colors from DNA.json (default: gaia-eats)
#   --logo PATH         Logo image path (used in all compositions)
#   --concurrency NUM   Render concurrency (default: 50%)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../project" && pwd)"
LOG_DIR="$HOME/.openclaw/logs"
LOG_FILE="$LOG_DIR/motionkit.log"
OUTPUT_DIR="$HOME/motionkit-output"
BRANDS_DIR="$HOME/.openclaw/brands"

mkdir -p "$LOG_DIR" "$OUTPUT_DIR"

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $1" | tee -a "$LOG_FILE"
}

error() {
  log "ERROR: $1"
  exit 1
}

usage() {
  echo "MotionKit Render"
  echo ""
  echo "Usage: render.sh <composition> [options]"
  echo ""
  echo "Compositions:"
  echo "  podcast-clip        Square audio visualizer with captions"
  echo "  animated-captions   Video with animated caption overlay"
  echo "  product-showcase    Product spotlight with features"
  echo "  brand-intro         Brand logo animation"
  echo "  data-chart          Animated data visualization"
  echo ""
  echo "Common Options:"
  echo "  --output PATH       Output file path"
  echo "  --quality VALUE     CRF quality 0-63 (default: 18)"
  echo "  --format FORMAT     mp4, webm, gif (default: mp4)"
  echo "  --duration SECONDS  Override duration"
  echo "  --brand SLUG        Brand slug for DNA colors (default: gaia-eats)"
  echo "  --logo PATH         Logo image path"
  echo ""
  echo "Podcast Clip:"
  echo "  --audio PATH        Audio file (required)"
  echo "  --captions PATH     Captions JSON file (required)"
  echo "  --speaker NAME      Speaker name"
  echo "  --episode TITLE     Episode title"
  echo ""
  echo "Animated Captions:"
  echo "  --video PATH        Video file (required)"
  echo "  --captions PATH     Captions JSON file (required)"
  echo "  --style STYLE       tiktok, karaoke, bounce (default: tiktok)"
  echo "  --font-size SIZE    Caption font size (default: 72)"
  echo "  --position POS      top, center, bottom (default: bottom)"
  echo ""
  echo "Product Showcase:"
  echo "  --image PATH        Product image (required)"
  echo "  --name TEXT         Product name (required)"
  echo "  --price TEXT        Price string (required)"
  echo "  --features F1,F2    Comma-separated features"
  echo "  --cta TEXT          CTA button text (default: Shop Now)"
  echo ""
  echo "Brand Intro:"
  echo "  --tagline TEXT      Brand tagline (required)"
  echo ""
  echo "Data Chart:"
  echo "  --data PATH         JSON data file (required)"
  echo "  --type TYPE         bar, line (default: bar)"
  echo "  --title TEXT        Chart title (required)"
  echo "  --subtitle TEXT     Chart subtitle"
  echo "  --y-label TEXT      Y-axis label"
  exit 1
}

# ── Auto-install if needed ────────────────────────────────────────────────

ensure_deps() {
  if [ ! -d "$PROJECT_DIR/node_modules" ]; then
    log "node_modules not found. Running setup..."
    bash "$SCRIPT_DIR/setup.sh"
  fi
}

# ── Load brand colors from DNA.json ──────────────────────────────────────

load_brand_colors() {
  local brand_slug="${1:-gaia-eats}"
  local dna_file="$BRANDS_DIR/$brand_slug/DNA.json"

  if [ -f "$dna_file" ]; then
    # Extract colors using python3 (reliable JSON parsing)
    python3 -c "
import json, sys
with open('$dna_file') as f:
    dna = json.load(f)
colors = dna.get('visual', {}).get('colors', {})
print(json.dumps(colors))
" 2>/dev/null || echo '{"primary":"#8FBC8F","secondary":"#DAA520","background":"#FFFDD0","accent":"#2E8B57"}'
  else
    log "Brand DNA not found at $dna_file, using defaults"
    echo '{"primary":"#8FBC8F","secondary":"#DAA520","background":"#FFFDD0","accent":"#2E8B57"}'
  fi
}

# ── Parse composition argument ───────────────────────────────────────────

if [ $# -lt 1 ]; then
  usage
fi

COMPOSITION="$1"
shift

# Map CLI name to Remotion composition ID
case "$COMPOSITION" in
  podcast-clip|podcastclip|podcast)
    COMP_ID="PodcastClip"
    ;;
  animated-captions|animatedcaptions|captions)
    COMP_ID="AnimatedCaptions"
    ;;
  product-showcase|productshowcase|product)
    COMP_ID="ProductShowcase"
    ;;
  brand-intro|brandintro|intro)
    COMP_ID="BrandIntro"
    ;;
  data-chart|datachart|chart)
    COMP_ID="DataChart"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    error "Unknown composition: $COMPOSITION. Run 'render.sh help' for usage."
    ;;
esac

# ── Parse flags ───────────────────────────────────────────────────────────

OUTPUT=""
QUALITY="18"
FORMAT="mp4"
DURATION=""
BRAND="gaia-eats"
LOGO_URL=""
CONCURRENCY=""

# Composition-specific
AUDIO=""
VIDEO=""
CAPTIONS=""
SPEAKER=""
EPISODE=""
STYLE="tiktok"
FONT_SIZE="72"
POSITION="bottom"
IMAGE=""
PRODUCT_NAME=""
PRICE=""
FEATURES=""
CTA="Shop Now"
TAGLINE=""
BRAND_NAME=""
DATA_FILE=""
CHART_TYPE="bar"
TITLE=""
SUBTITLE=""
Y_LABEL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --output)       OUTPUT="$2"; shift 2 ;;
    --quality)      QUALITY="$2"; shift 2 ;;
    --format)       FORMAT="$2"; shift 2 ;;
    --duration)     DURATION="$2"; shift 2 ;;
    --brand)        BRAND="$2"; shift 2 ;;
    --logo)         LOGO_URL="$2"; shift 2 ;;
    --concurrency)  CONCURRENCY="$2"; shift 2 ;;
    --audio)        AUDIO="$2"; shift 2 ;;
    --video)        VIDEO="$2"; shift 2 ;;
    --captions)     CAPTIONS="$2"; shift 2 ;;
    --speaker)      SPEAKER="$2"; shift 2 ;;
    --episode)      EPISODE="$2"; shift 2 ;;
    --style)        STYLE="$2"; shift 2 ;;
    --font-size)    FONT_SIZE="$2"; shift 2 ;;
    --position)     POSITION="$2"; shift 2 ;;
    --image)        IMAGE="$2"; shift 2 ;;
    --name)         PRODUCT_NAME="$2"; shift 2 ;;
    --brand-name)   BRAND_NAME="$2"; shift 2 ;;
    --price)        PRICE="$2"; shift 2 ;;
    --features)     FEATURES="$2"; shift 2 ;;
    --cta)          CTA="$2"; shift 2 ;;
    --tagline)      TAGLINE="$2"; shift 2 ;;
    --data)         DATA_FILE="$2"; shift 2 ;;
    --type)         CHART_TYPE="$2"; shift 2 ;;
    --title)        TITLE="$2"; shift 2 ;;
    --subtitle)     SUBTITLE="$2"; shift 2 ;;
    --y-label)      Y_LABEL="$2"; shift 2 ;;
    *)
      error "Unknown flag: $1"
      ;;
  esac
done

# ── Ensure dependencies ──────────────────────────────────────────────────

ensure_deps

# ── Load brand colors ────────────────────────────────────────────────────

BRAND_COLORS="$(load_brand_colors "$BRAND")"
log "Brand colors ($BRAND): $BRAND_COLORS"

# ── Build props JSON ─────────────────────────────────────────────────────

build_props() {
  python3 - "$@" <<'PYEOF'
import json, sys, os

comp_id = sys.argv[1]
brand_colors = json.loads(sys.argv[2])

# Remaining args are key=value pairs
kv = {}
for arg in sys.argv[3:]:
    if '=' in arg:
        k, v = arg.split('=', 1)
        kv[k] = v

props = {"brandColors": brand_colors}

if kv.get("logoUrl"):
    props["logoUrl"] = kv["logoUrl"]

if comp_id == "PodcastClip":
    props["audioUrl"] = kv.get("audioUrl", "")
    if kv.get("captionsFile"):
        with open(kv["captionsFile"]) as f:
            props["captions"] = json.load(f)
    else:
        props["captions"] = []
    props["speakerName"] = kv.get("speakerName", "Speaker")
    props["episodeTitle"] = kv.get("episodeTitle", "Episode")

elif comp_id == "AnimatedCaptions":
    props["videoUrl"] = kv.get("videoUrl", "")
    if kv.get("captionsFile"):
        with open(kv["captionsFile"]) as f:
            props["captions"] = json.load(f)
    else:
        props["captions"] = []
    props["style"] = kv.get("style", "tiktok")
    props["fontSize"] = int(kv.get("fontSize", "72"))
    props["position"] = kv.get("position", "bottom")

elif comp_id == "ProductShowcase":
    props["productImage"] = kv.get("productImage", "")
    props["productName"] = kv.get("productName", "Product")
    props["price"] = kv.get("price", "")
    features_str = kv.get("features", "")
    props["features"] = [f.strip() for f in features_str.split(",") if f.strip()] if features_str else []
    props["ctaText"] = kv.get("ctaText", "Shop Now")

elif comp_id == "BrandIntro":
    props["tagline"] = kv.get("tagline", "")
    if kv.get("brandName"):
        props["brandName"] = kv["brandName"]

elif comp_id == "DataChart":
    if kv.get("dataFile"):
        with open(kv["dataFile"]) as f:
            props["data"] = json.load(f)
    else:
        props["data"] = []
    props["chartType"] = kv.get("chartType", "bar")
    props["title"] = kv.get("title", "Chart")
    if kv.get("subtitle"):
        props["subtitle"] = kv["subtitle"]
    if kv.get("yAxisLabel"):
        props["yAxisLabel"] = kv["yAxisLabel"]

print(json.dumps(props))
PYEOF
}

# Build key=value args for python
KV_ARGS=()
[ -n "$LOGO_URL" ] && KV_ARGS+=("logoUrl=$LOGO_URL")

case "$COMP_ID" in
  PodcastClip)
    [ -n "$AUDIO" ] && KV_ARGS+=("audioUrl=$AUDIO")
    [ -n "$CAPTIONS" ] && KV_ARGS+=("captionsFile=$CAPTIONS")
    [ -n "$SPEAKER" ] && KV_ARGS+=("speakerName=$SPEAKER")
    [ -n "$EPISODE" ] && KV_ARGS+=("episodeTitle=$EPISODE")
    ;;
  AnimatedCaptions)
    [ -n "$VIDEO" ] && KV_ARGS+=("videoUrl=$VIDEO")
    [ -n "$CAPTIONS" ] && KV_ARGS+=("captionsFile=$CAPTIONS")
    [ -n "$STYLE" ] && KV_ARGS+=("style=$STYLE")
    [ -n "$FONT_SIZE" ] && KV_ARGS+=("fontSize=$FONT_SIZE")
    [ -n "$POSITION" ] && KV_ARGS+=("position=$POSITION")
    ;;
  ProductShowcase)
    [ -n "$IMAGE" ] && KV_ARGS+=("productImage=$IMAGE")
    [ -n "$PRODUCT_NAME" ] && KV_ARGS+=("productName=$PRODUCT_NAME")
    [ -n "$PRICE" ] && KV_ARGS+=("price=$PRICE")
    [ -n "$FEATURES" ] && KV_ARGS+=("features=$FEATURES")
    [ -n "$CTA" ] && KV_ARGS+=("ctaText=$CTA")
    ;;
  BrandIntro)
    [ -n "$TAGLINE" ] && KV_ARGS+=("tagline=$TAGLINE")
    [ -n "$BRAND_NAME" ] && KV_ARGS+=("brandName=$BRAND_NAME")
    ;;
  DataChart)
    [ -n "$DATA_FILE" ] && KV_ARGS+=("dataFile=$DATA_FILE")
    [ -n "$CHART_TYPE" ] && KV_ARGS+=("chartType=$CHART_TYPE")
    [ -n "$TITLE" ] && KV_ARGS+=("title=$TITLE")
    [ -n "$SUBTITLE" ] && KV_ARGS+=("subtitle=$SUBTITLE")
    [ -n "$Y_LABEL" ] && KV_ARGS+=("yAxisLabel=$Y_LABEL")
    ;;
esac

PROPS_JSON="$(build_props "$COMP_ID" "$BRAND_COLORS" "${KV_ARGS[@]+"${KV_ARGS[@]}"}")"
log "Props: $PROPS_JSON"

# ── Write props to temp file ─────────────────────────────────────────────

PROPS_FILE="$(mktemp /tmp/motionkit-props-XXXXXX.json)"
echo "$PROPS_JSON" > "$PROPS_FILE"
log "Props file: $PROPS_FILE"

# ── Map format to Remotion codec ──────────────────────────────────────────

get_codec() {
  case "$1" in
    mp4)  echo "h264" ;;
    webm) echo "vp8" ;;
    gif)  echo "gif" ;;
    *)    echo "h264" ;;
  esac
}

# ── Build output path ────────────────────────────────────────────────────

if [ -z "$OUTPUT" ]; then
  TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
  OUTPUT="$OUTPUT_DIR/${COMP_ID}-${TIMESTAMP}.${FORMAT}"
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

# ── Build render command ─────────────────────────────────────────────────

RENDER_CMD=(npx remotion render "$COMP_ID" "$OUTPUT")
RENDER_CMD+=(--props "$PROPS_FILE")
RENDER_CMD+=(--codec "$(get_codec "$FORMAT")")
RENDER_CMD+=(--crf "$QUALITY")

if [ -n "$DURATION" ]; then
  DURATION_FRAMES="$(python3 -c "print(int(float('$DURATION') * 30))")"
  RENDER_CMD+=(--frames "0-$DURATION_FRAMES")
fi

if [ -n "$CONCURRENCY" ]; then
  RENDER_CMD+=(--concurrency "$CONCURRENCY")
fi

log "Rendering: ${RENDER_CMD[*]}"

# ── Render ────────────────────────────────────────────────────────────────

cd "$PROJECT_DIR"
"${RENDER_CMD[@]}" 2>&1 | tee -a "$LOG_FILE"
RENDER_EXIT="${PIPESTATUS[0]}"

# ── Cleanup ───────────────────────────────────────────────────────────────

rm -f "$PROPS_FILE"

if [ "$RENDER_EXIT" -eq 0 ]; then
  log "Render complete: $OUTPUT"
  echo ""
  echo "  Output: $OUTPUT"
  echo "  Size: $(du -h "$OUTPUT" | cut -f1)"
  echo ""
else
  error "Render failed with exit code $RENDER_EXIT"
fi
