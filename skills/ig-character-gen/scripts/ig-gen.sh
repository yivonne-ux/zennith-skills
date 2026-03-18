#!/usr/bin/env bash
# ig-gen.sh — Instagram Character Content Generator
# Uses NanoBanana (Gemini) with face lock + body ref + raw mode
# Produces iPhone-quality, Western city, candid IG content

set -euo pipefail

NANO="/Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
CHARS_DIR="/Users/jennwoeiloh/.openclaw/workspace/data/characters"

# ── Character Definitions ──────────────────────────────────────────────────
# Each character has: face refs, body ref, prompt base, scene library

declare_jade() {
  CHAR_NAME="jade"
  BRAND="jade-oracle"
  FACE_DIR="$CHARS_DIR/jade-oracle/jade/face-refs"
  BODY_REF="$CHARS_DIR/jade-oracle/jade/body-ref.jpg"

  # Primary face refs (best anchors)
  FACE_REF1="$FACE_DIR/jade-d2-anchor.png"
  FACE_REF2="$FACE_DIR/jade-d3-anchor.png"
  FACE_REF3="$FACE_DIR/jade-ig2-market.png"

  # Ref array: 5 face (60%+) + 1 body
  REF_IMAGES="$FACE_REF1,$FACE_REF2,$FACE_REF3,$FACE_REF1,$FACE_REF2,$BODY_REF"

  CHAR_DESC="Korean woman in her early 30s, dark brown hair with soft bangs slightly tousled, warm brown eyes, warm golden skin with natural glow"
  BODY_DESC="curvy hourglass figure with naturally full bust"
  VIBE="poised, calm confidence, warm smile"

  REF_LABEL="Reference images 1-5 show the CHARACTER'S FACE — keep this EXACT face, bone structure, eyes, nose, jawline, hair texture, and bangs.
Reference image 6 shows BODY TYPE and FASHION STYLE only — apply this curvy hourglass figure and clothing drape.
Do NOT generate a different woman. This must be the SAME Korean woman from references 1-5."

  # Scenes: setting | outfit (body-revealing) | activity | lighting | props | emotion
  SCENES=(
    "Western outdoor farmers market on a sunny morning|white linen wrap blouse with deep V-neckline showing her decolletage, high-waisted jeans|browsing stalls and holding a bouquet of wildflowers|warm golden hour sunlight, natural shadows|fresh produce stalls behind her, reusable tote bag|laughing naturally, eyes crinkled, candid joy"
    "Candlelit Western restaurant, intimate dinner setting|black spaghetti strap silk slip dress with low neckline, the thin straps showing her toned shoulders, fabric draping over her full bust|sitting at table, chin resting on hand, wine glass nearby|warm amber candlelight, soft glow on skin|white wine glass, white tablecloth, candle flame|soft knowing smile, relaxed, intimate"
    "Modern Western apartment bedroom, morning|cream ribbed tank top showing bare shoulders and her curvy frame, sitting cross-legged on white bedsheets|writing in a leather-bound journal, pen in hand|soft morning light streaming through sheer curtains|steaming ceramic mug of tea on nightstand, potted plants on windowsill|gentle smile, looking up from journal toward camera"
    "Bright modern coffee shop with large windows|cream cashmere V-neck sweater that drapes softly over her figure, gold pendant necklace|sitting at window seat reading a book, latte with foam art on table|natural daylight flooding through window, warm tones|latte cup, open book, small succulent on table|contemplative, slight smile, absorbed in reading"
    "Western rooftop terrace at sunset, city skyline behind|burgundy wrap dress with deep V showing decolletage, the fabric cinching at her slim waist, jade drop earrings|standing at railing holding a glass of rose wine, looking over the city|golden hour sunset glow, warm orange and pink sky|wine glass, metal railing, potted herbs|serene, wind slightly moving her hair, peaceful"
    "Modern Western kitchen, open plan|sage green linen apron over a fitted black camisole showing her shoulders and neckline, hair loosely pinned up|cooking at the stove, stirring a pot, steam rising|warm overhead pendant light plus window light|wooden cutting board with fresh herbs, olive oil bottle, wine glass on counter|focused but happy, slight smile, domestic goddess energy"
    "Western outdoor brunch cafe with string lights|white off-shoulder linen top showing her collarbones and shoulders, her figure visible through the relaxed fabric, denim cutoffs|sitting at small round table, taking a bite of avocado toast|bright morning sunlight with dappled shade from overhead canopy|avocado toast, iced matcha, sunglasses pushed up on head|laughing mid-bite, natural and unposed"
    "Cozy modern apartment living room, evening|oversized cream cardigan worn open over a fitted black bralette top showing her decolletage and midriff, high-waisted lounge pants|sitting on floor with crystals arranged in a grid on coffee table|warm golden lamp light and candle glow|rose quartz, amethyst, clear quartz crystals, small candles, sage bundle|focused and peaceful, spiritual practice moment"
    "Western art gallery with white walls|all-black outfit — fitted turtleneck tucked into high-waisted leather pants, her curvy silhouette clearly defined, small jade pendant|standing before a large abstract painting, one hand touching her chin|cool gallery lighting with warm accent spotlights|large artwork, polished concrete floor|thoughtful, contemplative, sophisticated"
    "City park in autumn, golden leaves|fitted olive green knit dress that follows her hourglass curves, knee-length, paired with brown leather ankle boots, crossbody bag|walking on a tree-lined path, leaves falling around her, holding a takeaway coffee|warm diffused autumn light, golden tones everywhere|takeaway coffee cup, fallen leaves, park bench in background|natural stride, looking slightly to the side, effortless"
  )
}

declare_luna() {
  CHAR_NAME="luna"
  BRAND="jade-oracle"
  FACE_DIR="$CHARS_DIR/luna"
  BODY_REF=""  # Luna has no body ref yet

  FACE_REF1="$FACE_DIR/face-refs/luna-anchor-street.png"
  FACE_REF2="$FACE_DIR/face-refs/luna-anchor-cafe.png"
  FACE_REF3="$FACE_DIR/face-refs/luna-anchor-closeup.png"

  # 5 face refs (no body ref for Luna yet)
  REF_IMAGES="$FACE_REF1,$FACE_REF2,$FACE_REF3,$FACE_REF1,$FACE_REF2"

  CHAR_DESC="young woman, 22-26, platinum blonde messy updo with loose face-framing strands, ice blue-green eyes, fair porcelain skin, delicate features"
  BODY_DESC="slim petite frame"
  VIBE="free-spirited, edgy yet soft, magnetic"

  REF_LABEL="Reference images 1-5 show the CHARACTER'S FACE — keep this EXACT face, bone structure, ice blue-green eyes, platinum blonde hair, porcelain skin.
Do NOT generate a different woman. This must be the SAME woman from references 1-5."

  SCENES=(
    "Moody city wine bar at night|black leather jacket over a vintage lace camisole, silver layered necklaces|sitting on bar stool, cocktail in hand, looking over her shoulder|warm ambient bar lighting, neon glow from behind|craft cocktail, bar counter, bokeh lights|confident smirk, effortlessly cool"
    "Bohemian bedroom with fairy lights and tapestries|oversized vintage band tee (cropped) over high-waisted shorts, barefoot|sitting cross-legged on bed with tarot cards spread out|warm fairy light glow and candle light|tarot deck, crystals on nightstand, incense smoke|contemplative, reading the cards intently"
    "Rooftop party at sunset, city skyline|silver slip dress, thin straps, doc martens boots, messy updo with loose strands|laughing with drink in hand, city lights beginning to glow|golden sunset plus string lights|champagne glass, friends blurred in background|laughing freely, carefree energy"
    "Vintage thrift shop interior|oversized denim jacket over a cropped white tee, chunky silver rings|browsing through a rack of vintage clothes, examining a find|warm fluorescent mixed with natural window light|clothing racks, vintage mirrors, price tags|excited discovery, genuine smile"
    "Morning bedroom, sunlight streaming in|white oversized button-up shirt (only half buttoned), messy morning hair|sitting up in bed holding a steaming mug, crystals on windowsill|soft golden morning light through sheer curtains|ceramic mug, amethyst cluster on windowsill, rumpled white sheets|peaceful, just woken up, soft expression"
    "Night city street with neon signs|fitted black mini dress, chunky silver jewelry, leather jacket draped on shoulders|walking confidently down the street, city lights reflecting|neon lights mixing with street lamp glow, wet pavement reflections|city neon signs blurred behind, puddle reflections|confident stride, looking ahead, powerful"
    "Cozy cafe corner with exposed brick walls|cream oversized knit sweater, sleeves pulled over hands, small crystal pendant|holding a large ceramic bowl of matcha, sitting in a worn leather chair|warm cafe lighting, afternoon sun through window|matcha bowl, dog-eared book on table, worn leather chair|cozy, content, warm smile"
    "Beach at golden hour, waves in background|flowy white maxi dress with slit, barefoot on sand, anklet with moon charm|walking along shoreline, one hand touching pendant|warm golden sunset light, long shadows|ocean waves, sand, seashells|free, wind in hair, meditative"
    "Apartment balcony at night, full moon visible|black silk robe loosely tied, holding a glass of red wine|sitting with journal and candles, moon overhead|moonlight plus candle glow, city lights in distance|pillar candles, journal, wine glass, moon visible|ritual energy, writing by moonlight"
    "Outdoor music festival, golden hour|crochet halter top, high-waisted vintage jeans, layered festival jewelry|dancing or raising hands, crowd blurred behind|warm sunset golden hour, hazy festival atmosphere|wristbands, temporary tattoos, crowd silhouettes|pure joy, dancing, free-spirited"
  )
}

# ── Main Logic ──────────────────────────────────────────────────────────────

usage() {
  echo "Usage: ig-gen.sh --character <jade|luna> [--scene \"description\"] [--batch N] [--output DIR] [--dry-run]"
  echo ""
  echo "Options:"
  echo "  --character   Character name (jade or luna)"
  echo "  --scene       Custom scene override (single image)"
  echo "  --batch       Number of images from scene library (default: all)"
  echo "  --output      Output directory (default: ~/Desktop/{character}-ig-library/)"
  echo "  --dry-run     Print prompts without generating"
  echo "  --parallel    Max parallel jobs (default: 5)"
  exit 1
}

CHARACTER=""
CUSTOM_SCENE=""
BATCH_COUNT=0
OUTPUT_DIR=""
DRY_RUN=false
MAX_PARALLEL=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --character) CHARACTER="$2"; shift 2 ;;
    --scene) CUSTOM_SCENE="$2"; shift 2 ;;
    --batch) BATCH_COUNT="$2"; shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --parallel) MAX_PARALLEL="$2"; shift 2 ;;
    *) echo "Unknown: $1"; usage ;;
  esac
done

[[ -z "$CHARACTER" ]] && usage

# Load character
case "$CHARACTER" in
  jade) declare_jade ;;
  luna) declare_luna ;;
  *) echo "Unknown character: $CHARACTER"; exit 1 ;;
esac

[[ -z "$OUTPUT_DIR" ]] && OUTPUT_DIR="$HOME/Desktop/${CHAR_NAME}-ig-library"
mkdir -p "$OUTPUT_DIR"

build_prompt() {
  local scene_line="$1"
  IFS='|' read -r setting outfit activity lighting props emotion <<< "$scene_line"

  cat <<PROMPT
$REF_LABEL

Authentic iPhone photo of a $CHAR_DESC.
$emotion.
She has a $BODY_DESC — $outfit.
$setting.
She is $activity.
$lighting.
$props.
Shot on iPhone 16 Pro, natural depth of field, candid moment, warm tones, slightly imperfect framing.
Looks like a real Instagram post from a lifestyle influencer. NOT editorial, NOT studio, NOT cinematic CG.
4:5 portrait aspect ratio.
PROMPT
}

generate_one() {
  local idx="$1"
  local prompt="$2"
  local label="$3"

  if $DRY_RUN; then
    echo "=== Scene $idx: $label ==="
    echo "$prompt"
    echo ""
    return 0
  fi

  echo "[$(date +%H:%M:%S)] Generating scene $idx: $label..."

  local out
  out=$(bash "$NANO" generate \
    --brand "$BRAND" \
    --use-case character \
    --prompt "$prompt" \
    --ref-image "$REF_IMAGES" \
    --model pro \
    --ratio 4:5 \
    --size 2K 2>&1) || true

  # Extract output path from nanobanana output
  local img_path
  img_path=$(echo "$out" | grep -oE '/[^ ]+\.png' | head -1)

  if [[ -n "$img_path" && -f "$img_path" ]]; then
    local dest="$OUTPUT_DIR/${CHAR_NAME}-ig-$(printf '%02d' "$idx")-${label}.png"
    cp "$img_path" "$dest"
    echo "[$(date +%H:%M:%S)] Done: $dest"
  else
    echo "[$(date +%H:%M:%S)] WARN: Scene $idx may have failed. Output:"
    echo "$out" | tail -5
  fi
}

# ── Execute ──────────────────────────────────────────────────────────────────

if [[ -n "$CUSTOM_SCENE" ]]; then
  # Single custom scene
  prompt=$(build_prompt "$CUSTOM_SCENE")
  generate_one 1 "$prompt" "custom"
  exit 0
fi

# Batch from scene library
total=${#SCENES[@]}
[[ $BATCH_COUNT -gt 0 && $BATCH_COUNT -lt $total ]] && total=$BATCH_COUNT

echo "Generating $total IG images for $CHAR_NAME..."
echo "Output: $OUTPUT_DIR"
echo ""

running=0
for i in $(seq 0 $((total - 1))); do
  scene="${SCENES[$i]}"
  # Extract short label from setting
  label=$(echo "$scene" | cut -d'|' -f1 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-30)

  prompt=$(build_prompt "$scene")
  generate_one $((i + 1)) "$prompt" "$label" &

  running=$((running + 1))
  if [[ $running -ge $MAX_PARALLEL ]]; then
    wait -n 2>/dev/null || wait
    running=$((running - 1))
  fi

  # Rate limit: 6s between launches
  sleep 6
done

wait
echo ""
echo "Done. $total images generated in: $OUTPUT_DIR"
