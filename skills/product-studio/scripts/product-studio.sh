#!/usr/bin/env bash
# product-studio.sh — Automated e-commerce product photography for all GAIA brands
# macOS Bash 3.2 compatible: no associative arrays, no declare -A, no ${var,,}
# Image engine: NanoBanana (Gemini Image API) via nanobanana-gen.sh
# ---

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants & Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
IMAGES_DIR="$HOME/.openclaw/workspace/data/images"
NANOBANANA="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
LOG_FILE="$HOME/.openclaw/logs/product-studio.log"
VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "ERROR: $*" >&2; log "ERROR" "$*"; exit 1; }
warn() { echo "WARN: $*" >&2; log "WARN" "$*"; }
info() { echo "INFO: $*"; log "INFO" "$*"; }

log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$ts] [$level] $*" >> "$LOG_FILE"
}

to_lower() { echo "$1" | tr 'A-Z' 'a-z'; }

# ---------------------------------------------------------------------------
# Brand DNA Loader (python3 JSON extraction — no jq dependency)
# ---------------------------------------------------------------------------

dna_get() {
  local dna_file="$1"
  local key_path="$2"
  local default="${3:-}"
  local result
  result=$(python3 -c "
import json, sys
try:
    with open('$dna_file') as f:
        d = json.load(f)
    keys = '$key_path'.split('.')
    v = d
    for k in keys:
        v = v[k]
    if isinstance(v, list):
        print(','.join(str(x) for x in v))
    else:
        print(v)
except (KeyError, TypeError, IndexError):
    print('$default')
" 2>/dev/null)
  echo "$result"
}

dna_get_list() {
  local dna_file="$1"
  local key_path="$2"
  python3 -c "
import json
with open('$dna_file') as f:
    d = json.load(f)
keys = '$key_path'.split('.')
v = d
for k in keys:
    v = v[k]
if isinstance(v, list):
    for item in v:
        print(item)
else:
    print(v)
" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Brand DNA Variables (populated by load_brand_dna)
# ---------------------------------------------------------------------------

BRAND=""
BRAND_DISPLAY=""
BRAND_PRIMARY=""
BRAND_SECONDARY=""
BRAND_ACCENT=""
BRAND_BG_COLOR=""
BRAND_LIGHTING=""
BRAND_STYLE=""
BRAND_PHOTOGRAPHY=""
BRAND_AVOID=""
DNA_FILE=""

load_brand_dna() {
  local brand="$1"
  DNA_FILE="$BRANDS_DIR/$brand/DNA.json"
  [ -f "$DNA_FILE" ] || die "Brand DNA not found: $DNA_FILE"

  BRAND="$brand"
  BRAND_DISPLAY=$(dna_get "$DNA_FILE" "display_name" "$brand")
  BRAND_PRIMARY=$(dna_get "$DNA_FILE" "visual.colors.primary" "#FFFFFF")
  BRAND_SECONDARY=$(dna_get "$DNA_FILE" "visual.colors.secondary" "#000000")
  BRAND_ACCENT=$(dna_get "$DNA_FILE" "visual.colors.accent" "#888888")
  BRAND_BG_COLOR=$(dna_get "$DNA_FILE" "visual.colors.primary" "#FFFFFF")
  BRAND_LIGHTING=$(dna_get "$DNA_FILE" "visual.lighting_default" "Clean natural daylight, warm tones")
  BRAND_STYLE=$(dna_get "$DNA_FILE" "visual.style" "Modern, clean")
  BRAND_PHOTOGRAPHY=$(dna_get "$DNA_FILE" "visual.photography" "Professional product photography")
  BRAND_AVOID=$(dna_get "$DNA_FILE" "visual.avoid" "")

  info "Loaded brand DNA: $BRAND ($BRAND_DISPLAY)"
  info "  Colors: primary=$BRAND_PRIMARY secondary=$BRAND_SECONDARY accent=$BRAND_ACCENT"
  info "  Style: $BRAND_STYLE"
}

# ---------------------------------------------------------------------------
# Product Type Detection
# ---------------------------------------------------------------------------

detect_product_type() {
  local product
  product=$(to_lower "$1")
  case "$product" in
    *bento*|*meal*|*rendang*|*laksa*|*nasi*|*satay*|*tempeh*|*rice*|*wrap*|*soup*|*bowl*|*kway*|*lemak*|*paste*)
      echo "food" ;;
    *jamu*|*latte*|*smoothie*|*acai*|*drink*|*beverage*|*juice*|*kopi*|*tea*)
      echo "beverage" ;;
    *capsule*|*powder*|*supplement*|*vitamin*|*tablet*|*bottle*)
      echo "supplement" ;;
    *tee*|*shirt*|*tote*|*bag*|*mug*|*notebook*|*sticker*|*print*)
      echo "print" ;;
    *card*|*oracle*|*deck*|*reading*)
      echo "specialty" ;;
    *course*|*workbook*|*digital*)
      echo "digital" ;;
    *)
      echo "food" ;;
  esac
}

# ---------------------------------------------------------------------------
# Angle Matrix — returns angle list per product type
# ---------------------------------------------------------------------------

get_angles_for_type() {
  local ptype="$1"
  local filter="$2"  # "all" or specific like "hero" "overhead" "front"

  case "$ptype" in
    food)
      case "$filter" in
        all)       echo "overhead hero-45 front back closeup beauty-15" ;;
        hero)      echo "hero-45" ;;
        overhead)  echo "overhead" ;;
        front)     echo "front" ;;
        *)         echo "overhead hero-45 front back closeup beauty-15" ;;
      esac
      ;;
    beverage)
      case "$filter" in
        all)       echo "front pour-45 closeup lifestyle-hold top" ;;
        hero)      echo "front" ;;
        overhead)  echo "top" ;;
        front)     echo "front" ;;
        *)         echo "front pour-45 closeup lifestyle-hold top" ;;
      esac
      ;;
    supplement)
      case "$filter" in
        all)       echo "front closeup spread shelf three-quarter-45" ;;
        hero)      echo "front" ;;
        overhead)  echo "spread" ;;
        front)     echo "front" ;;
        *)         echo "front closeup spread shelf three-quarter-45" ;;
      esac
      ;;
    print)
      case "$filter" in
        all)       echo "flat-lay worn detail mockup lifestyle" ;;
        hero)      echo "flat-lay" ;;
        overhead)  echo "flat-lay" ;;
        front)     echo "mockup" ;;
        *)         echo "flat-lay worn detail mockup lifestyle" ;;
      esac
      ;;
    *)
      echo "front hero-45 overhead closeup" ;;
  esac
}

# ---------------------------------------------------------------------------
# Angle Prompt Modifier — translates angle code to prompt text
# ---------------------------------------------------------------------------

angle_to_prompt() {
  local angle="$1"
  local ptype="$2"
  case "$angle" in
    overhead)          echo "directly overhead, bird's-eye view" ;;
    hero-45)           echo "45-degree angle, slight elevation, hero product shot" ;;
    front)             echo "straight-on front view, label facing camera" ;;
    back)              echo "straight-on back view, nutrition label visible" ;;
    closeup)           echo "extreme close-up, macro detail of textures and ingredients" ;;
    beauty-15)         echo "15-degree tilt, slight angle, subtle shadow beneath" ;;
    pour-45)           echo "45-degree angle, liquid being poured into glass, motion captured" ;;
    lifestyle-hold)    echo "hand holding bottle/glass at natural angle, casual grip" ;;
    top)               echo "overhead view of open bottle/glass, liquid color visible" ;;
    spread)            echo "overhead flatlay, bottle center with raw ingredients arranged around it" ;;
    shelf)             echo "product on bathroom shelf or kitchen counter, lifestyle context" ;;
    three-quarter-45)  echo "45-degree angle, premium product photography, subtle shadow" ;;
    flat-lay)          echo "perfectly flat lay on clean surface, garment spread, design visible" ;;
    worn)              echo "model wearing/using product, natural pose, lifestyle context" ;;
    detail)            echo "extreme close-up of print quality, fabric texture, design detail" ;;
    mockup)            echo "professional product mockup, clean white background" ;;
    lifestyle)         echo "product styled in workspace/home setting with complementary props" ;;
    *)                 echo "professional product photography, clean composition" ;;
  esac
}

# ---------------------------------------------------------------------------
# Scene Templates — returns scene prompts per brand category
# ---------------------------------------------------------------------------

get_scenes_for_brand() {
  local brand="$1"
  local scene_filter="$2"  # specific scene or empty for defaults

  # Determine brand category
  local category=""
  case "$brand" in
    pinxin-vegan|gaia-eats|mirra|gaia-recipes|wholey-wonder|rasaya)
      category="fnb" ;;
    dr-stan|gaia-supplements|serein)
      category="wellness" ;;
    gaia-print|gaia-os|iris)
      category="print" ;;
    jade-oracle)
      category="specialty" ;;
    *)
      category="fnb" ;;
  esac

  if [ -n "$scene_filter" ] && [ "$scene_filter" != "all" ]; then
    echo "$scene_filter"
    return
  fi

  case "$category" in
    fnb)
      echo "kitchen dining picnic hawker office" ;;
    wellness)
      echo "bathroom-shelf yoga morning-routine gym-bag nightstand" ;;
    print)
      echo "workspace gallery gift-wrap street-style flat-lay-styled" ;;
    specialty)
      echo "altar reading-nook tea-ceremony" ;;
  esac
}

scene_to_prompt() {
  local scene="$1"
  case "$scene" in
    kitchen)
      echo "modern Malaysian kitchen counter, marble surface, natural light from window on left, potted herbs in background, clean and warm" ;;
    dining)
      echo "warm dining table setting, wooden table, warm ambient lighting, napkin and utensils, family meal atmosphere, Malaysian home" ;;
    picnic)
      echo "outdoor picnic setting on woven mat, dappled sunlight through trees, Malaysian park, green grass, relaxed weekend vibe" ;;
    hawker)
      echo "Malaysian hawker stall counter, stainless steel, warm fluorescent lighting, authentic kopitiam atmosphere, bustling market" ;;
    office)
      echo "modern office desk, clean workspace, product as healthy lunch option, natural light from window, productivity context" ;;
    bathroom-shelf)
      echo "clean bathroom shelf, organized wellness products, soft diffused light, morning routine setting, modern and calm" ;;
    yoga)
      echo "yoga mat on wooden floor, product beside mat, soft natural light, zen atmosphere, calming wellness space" ;;
    morning-routine)
      echo "bright morning kitchen counter, golden sunrise light, fresh start atmosphere, product as daily ritual" ;;
    gym-bag)
      echo "open gym bag on bench, product visible among workout essentials, locker room or home entryway, energetic" ;;
    nightstand)
      echo "bedside nightstand, warm lamp light, book and product, calming evening atmosphere, wind-down ritual" ;;
    workspace)
      echo "creative workspace desk, product displayed, design tools nearby, inspiration board in background, modern and artistic" ;;
    gallery)
      echo "modern gallery-style white wall, product displayed as focal piece, track lighting, curated aesthetic" ;;
    gift-wrap)
      echo "gift wrapping scene, kraft paper and twine, product as thoughtful gift, warm holiday or birthday atmosphere" ;;
    street-style)
      echo "urban Malaysian street scene, product in use/visible, street style photography, trendy and authentic" ;;
    flat-lay-styled)
      echo "overhead flat lay, product center, styled with complementary items (coffee, sunglasses, phone), magazine quality" ;;
    altar)
      echo "home altar space, warm candlelight, sacred objects, product displayed reverently, warm jade and cream tones" ;;
    reading-nook)
      echo "cozy reading nook, warm lamp, tea cup nearby, product as spiritual companion, soft textured cushions" ;;
    tea-ceremony)
      echo "tea ceremony setting, wooden tray, ceramic cups, product alongside tea ritual, warm amber light" ;;
    *)
      echo "clean styled setting, product naturally placed, warm inviting atmosphere, brand-consistent" ;;
  esac
}

# ---------------------------------------------------------------------------
# Demographic / Model Templates
# ---------------------------------------------------------------------------

get_demographics_for_brand() {
  local brand="$1"
  case "$brand" in
    mirra)
      echo "malay-woman-30 chinese-woman-32 indian-woman-28" ;;
    pinxin-vegan)
      echo "malay-woman-30 chinese-woman-35 indian-woman-30" ;;
    wholey-wonder)
      echo "young-adult-24 fitness-woman-28 social-native-22" ;;
    rasaya)
      echo "mature-woman-50 young-adult-25 heritage-woman-40" ;;
    dr-stan|gaia-supplements)
      echo "professional-man-35 fitness-woman-30 health-pro-40" ;;
    serein)
      echo "urban-professional-32 mindfulness-woman-35" ;;
    gaia-print)
      echo "genz-woman-22 millennial-man-28 eco-activist-25" ;;
    gaia-eats|gaia-recipes)
      echo "malay-woman-30 home-cook-35 working-parent-38" ;;
    jade-oracle)
      echo "spiritual-woman-30 diaspora-entrepreneur-35" ;;
    *)
      echo "malay-woman-30 chinese-woman-32" ;;
  esac
}

demographic_to_prompt() {
  local demo="$1"
  case "$demo" in
    malay-woman-30)
      echo "young Malay woman, warm smile, professional, approachable" ;;
    chinese-woman-32|chinese-woman-35)
      echo "Chinese Malaysian woman, modern, confident, natural look" ;;
    indian-woman-28|indian-woman-30)
      echo "Indian Malaysian woman, vibrant, warm expression" ;;
    young-adult-24|young-adult-25)
      echo "young Malaysian adult, energetic, Gen Z style, expressive" ;;
    fitness-woman-28|fitness-woman-30)
      echo "fit Malaysian woman, athletic build, active lifestyle look" ;;
    social-native-22)
      echo "young Malaysian woman, social media savvy, trendy, bright energy" ;;
    mature-woman-50)
      echo "mature Malaysian woman, elegant, warm, experienced" ;;
    heritage-woman-40)
      echo "Malaysian woman, heritage-connected, nurturing, warm" ;;
    professional-man-35)
      echo "Malaysian man, friendly, health-conscious, modern casual" ;;
    health-pro-40)
      echo "Malaysian health professional, authoritative but approachable" ;;
    urban-professional-32)
      echo "urban Malaysian professional woman, self-care focused, calm confidence" ;;
    mindfulness-woman-35)
      echo "Malaysian woman, mindfulness practitioner, serene, gentle" ;;
    genz-woman-22)
      echo "Gen Z Malaysian woman, bold, edgy streetwear, expressive" ;;
    millennial-man-28)
      echo "Malaysian millennial man, creative, modern, eco-conscious" ;;
    eco-activist-25)
      echo "young Malaysian eco-activist, passionate, authentic" ;;
    spiritual-woman-30)
      echo "Malaysian woman, spiritual seeker, warm editorial, graceful" ;;
    diaspora-entrepreneur-35)
      echo "Chinese diaspora entrepreneur woman, confident, warm jade aesthetic" ;;
    working-parent-38|home-cook-35)
      echo "Malaysian parent, warm, encouraging, home cook energy" ;;
    *)
      echo "Malaysian adult, friendly, natural, relatable" ;;
  esac
}

# ---------------------------------------------------------------------------
# Pose Library
# ---------------------------------------------------------------------------

get_default_poses() {
  echo "hold-front use-active table-near"
}

pose_to_prompt() {
  local pose="$1"
  local product="$2"
  case "$pose" in
    hold-front)
      echo "holding $product in both hands at chest height, facing camera, friendly smile" ;;
    hold-side)
      echo "casually holding $product at side, relaxed stance, looking at camera with slight smile" ;;
    use-active)
      echo "in the middle of using/eating/drinking $product, natural candid moment" ;;
    table-near)
      echo "seated at table, $product on table in front, reaching for it or looking at it" ;;
    bag-peek)
      echo "walking, $product visible in tote bag or hand, urban lifestyle, on-the-go" ;;
    prep-cook)
      echo "in kitchen, preparing meal with $product, cooking action, warm atmosphere" ;;
    morning)
      echo "morning routine, just woke up, $product on counter, reaching for it" ;;
    share)
      echo "offering/sharing $product with friend, warm interaction, genuine smile" ;;
    *)
      echo "naturally interacting with $product, relaxed and authentic" ;;
  esac
}

# ---------------------------------------------------------------------------
# Prompt Builders
# ---------------------------------------------------------------------------

build_packshot_prompt_white() {
  local product="$1"
  local angle="$2"
  local ptype="$3"
  local angle_mod
  angle_mod=$(angle_to_prompt "$angle" "$ptype")

  cat <<PROMPT
Professional e-commerce product photography of ${product} by ${BRAND_DISPLAY}.
${angle}: ${angle_mod}.
Pure white background (#FFFFFF), professional studio lighting with soft box from upper-left.
Product centered in frame, fills 85% of image area.
Sharp focus on product, razor-sharp label text, shallow depth of field.
Subtle natural shadow beneath product on white surface.
${BRAND_PHOTOGRAPHY}.
${BRAND_LIGHTING}.
Absolutely photorealistic, no AI artifacts, no warped text, no unnatural reflections.
Professional commercial photography quality, suitable for Shopee/Lazada/Shopify listing.
PROMPT
}

build_packshot_prompt_branded() {
  local product="$1"
  local angle="$2"
  local ptype="$3"
  local angle_mod
  angle_mod=$(angle_to_prompt "$angle" "$ptype")

  cat <<PROMPT
Styled product photography of ${product} by ${BRAND_DISPLAY}.
${angle}: ${angle_mod}.
Background: ${BRAND_BG_COLOR} with subtle ${BRAND_STYLE} textures.
${BRAND_LIGHTING}.
Product centered, complementary props from brand aesthetic.
Brand color palette visible: ${BRAND_PRIMARY}, ${BRAND_SECONDARY}, ${BRAND_ACCENT}.
Food looks appetizing and inviting, styled for social media.
${BRAND_PHOTOGRAPHY}.
Magazine editorial quality, Instagram-ready composition.
PROMPT
}

build_placement_prompt() {
  local product="$1"
  local scene="$2"
  local scene_desc
  scene_desc=$(scene_to_prompt "$scene")

  cat <<PROMPT
Reference image 1 shows the EXACT product -- place it faithfully in the scene.
Lifestyle photography: ${product} by ${BRAND_DISPLAY} naturally placed in scene.
Scene: ${scene_desc}.
Product resting naturally, slight angle as if just placed down.
${BRAND_LIGHTING}, same lighting direction on product and scene.
Natural shadows, product integrates seamlessly into environment.
Malaysian setting, authentic and inviting.
Color temperature: warm, matching ${BRAND_PRIMARY}, ${BRAND_SECONDARY}, ${BRAND_ACCENT}.
The product is the focal point but feels like it belongs in this world.
Photorealistic, no compositing artifacts, no floating product, no scale errors.
PROMPT
}

build_model_prompt() {
  local product="$1"
  local demo="$2"
  local pose="$3"
  local demo_desc
  demo_desc=$(demographic_to_prompt "$demo")
  local pose_desc
  pose_desc=$(pose_to_prompt "$pose" "$product")

  cat <<PROMPT
Reference images 1-3 show the MODEL's FACE -- keep this EXACT face, bone structure, features.
Reference images 4-5 show the EXACT PRODUCT -- do NOT change the product.

EXACT SAME PERSON from references 1-3 -- do NOT generate a different person.
${demo_desc} ${pose_desc} with ${product} by ${BRAND_DISPLAY}.
Product clearly visible, label readable, accurate to references 4-5.
${BRAND_LIGHTING}.
Natural interaction between model and product -- candid, not stiff.
${BRAND_STYLE} aesthetic, ${BRAND_PHOTOGRAPHY}.
Photorealistic, editorial quality. Natural skin texture, visible pores, individual hair strands.
No plasticky skin, no AI hands, no extra fingers, no warped product labels.
PROMPT
}

# ---------------------------------------------------------------------------
# NanoBanana Caller
# ---------------------------------------------------------------------------

call_nanobanana() {
  local prompt="$1"
  local output_name="$2"
  local ref_image="${3:-}"
  local ratio="${4:-1:1}"
  local model="${5:-flash}"
  local extra_flags="${6:-}"

  [ -x "$NANOBANANA" ] || die "nanobanana-gen.sh not found or not executable at: $NANOBANANA"

  local cmd="bash \"$NANOBANANA\" generate --brand \"$BRAND\" --prompt \"$prompt\" --size 2K --ratio \"$ratio\" --model \"$model\""

  if [ -n "$ref_image" ]; then
    cmd="$cmd --ref-image \"$ref_image\""
  fi

  if [ -n "$extra_flags" ]; then
    cmd="$cmd $extra_flags"
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "  [DRY-RUN] Would generate: $output_name"
    echo "  [DRY-RUN] Prompt: $(echo "$prompt" | head -3)..."
    echo "  [DRY-RUN] Ratio: $ratio  Model: $model  Ref: ${ref_image:-none}"
    echo ""
    return 0
  fi

  info "Generating: $output_name"
  log "INFO" "Prompt: $(echo "$prompt" | tr '\n' ' ' | cut -c1-200)"

  local tmp_out="/tmp/product-studio-$$"
  mkdir -p "$tmp_out"

  # Execute nanobanana — it writes output to brand images dir by default
  # We capture the output path from its stdout
  local result
  result=$(eval "$cmd" 2>&1) || {
    warn "Generation failed for $output_name: $result"
    rm -rf "$tmp_out"
    return 1
  }

  # Extract generated file path from nanobanana output (it prints the path)
  local generated_path
  generated_path=$(echo "$result" | grep -E '(OUTPUT|Saved|saved|\.png)' | grep -oE '/[^ ]+\.png' | tail -1 || true)

  if [ -n "$generated_path" ] && [ -f "$generated_path" ]; then
    local dest="$OUTPUT_DIR/${output_name}"
    mkdir -p "$(dirname "$dest")"
    cp "$generated_path" "$dest"
    info "Saved: $dest"
  else
    # If we cannot extract the path, check if nanobanana already saved it
    info "Generation complete for $output_name (check nanobanana output)"
    log "INFO" "nanobanana output: $(echo "$result" | tail -5)"
  fi

  rm -rf "$tmp_out"
  return 0
}

# ---------------------------------------------------------------------------
# Module A: Pack Shot Generator
# ---------------------------------------------------------------------------

run_packshot() {
  local product="$1"
  local angle_filter="$2"
  local ref_image="$3"

  local ptype
  ptype=$(detect_product_type "$product")
  info "Pack Shot Module | product=$product type=$ptype angles=$angle_filter"

  local angles
  angles=$(get_angles_for_type "$ptype" "$angle_filter")

  local count=0
  local total_white=0
  local total_branded=0

  for angle in $angles; do
    # White background variant
    local prompt_white
    prompt_white=$(build_packshot_prompt_white "$product" "$angle" "$ptype")
    local fname_white="${BRAND}_${product}_packshot_${angle}_white.png"
    call_nanobanana "$prompt_white" "$fname_white" "$ref_image" "1:1" "flash"
    total_white=$((total_white + 1))

    # Branded background variant
    local prompt_branded
    prompt_branded=$(build_packshot_prompt_branded "$product" "$angle" "$ptype")
    local fname_branded="${BRAND}_${product}_packshot_${angle}_branded.png"
    call_nanobanana "$prompt_branded" "$fname_branded" "$ref_image" "1:1" "flash"
    total_branded=$((total_branded + 1))

    count=$((count + 1))
  done

  info "Pack Shot complete: $count angles x 2 backgrounds = $((total_white + total_branded)) images"
}

# ---------------------------------------------------------------------------
# Module B: Product Placement Engine
# ---------------------------------------------------------------------------

run_placement() {
  local product="$1"
  local scene_filter="$2"
  local ref_image="$3"

  info "Placement Module | product=$product scene=$scene_filter"

  local scenes
  scenes=$(get_scenes_for_brand "$BRAND" "$scene_filter")

  local count=0
  for scene in $scenes; do
    local prompt
    prompt=$(build_placement_prompt "$product" "$scene")
    local fname="${BRAND}_${product}_placement_${scene}_v1.png"
    call_nanobanana "$prompt" "$fname" "$ref_image" "4:3" "flash"
    count=$((count + 1))
  done

  # Generate one vertical story format (9:16)
  local first_scene
  first_scene=$(echo "$scenes" | awk '{print $1}')
  local story_prompt
  story_prompt=$(build_placement_prompt "$product" "$first_scene")
  story_prompt="$story_prompt
Vertical format optimized for Instagram/WhatsApp stories (9:16 aspect ratio)."
  local fname_story="${BRAND}_${product}_placement_story-9x16_v1.png"
  call_nanobanana "$story_prompt" "$fname_story" "$ref_image" "9:16" "flash"
  count=$((count + 1))

  info "Placement complete: $count scene images generated"
}

# ---------------------------------------------------------------------------
# Module C: Model Swap
# ---------------------------------------------------------------------------

run_model_swap() {
  local product="$1"
  local ref_image="$2"
  local specific_model="$3"

  info "Model Swap Module | product=$product"

  local demographics
  if [ -n "$specific_model" ]; then
    # Single specific model description — use it directly
    local prompt
    prompt=$(cat <<PROMPT
Reference image 1 shows the EXACT PRODUCT -- this must appear in every shot.

${specific_model} with ${product} by ${BRAND_DISPLAY}.
holding $product in both hands at chest height, facing camera, friendly smile.
EXACT product from reference 1 -- same shape, color, label.
${BRAND_LIGHTING}.
${BRAND_STYLE} aesthetic.
Natural and relatable, not stock-photo-posed.
Photorealistic, inclusive, authentic Malaysian representation.
PROMPT
)
    local fname="${BRAND}_${product}_model_custom_v1.png"
    call_nanobanana "$prompt" "$fname" "$ref_image" "4:5" "flash"
    info "Model Swap complete: 1 custom model image"
    return 0
  fi

  demographics=$(get_demographics_for_brand "$BRAND")
  local poses
  poses=$(get_default_poses)
  local first_pose
  first_pose=$(echo "$poses" | awk '{print $1}')

  local count=0
  for demo in $demographics; do
    local prompt
    prompt=$(build_model_prompt "$product" "$demo" "$first_pose")
    local fname="${BRAND}_${product}_model_${demo}_v1.png"
    call_nanobanana "$prompt" "$fname" "$ref_image" "4:5" "flash"
    count=$((count + 1))
  done

  info "Model Swap complete: $count demographic variants generated"
}

# ---------------------------------------------------------------------------
# Subcommand: generate (full pipeline — Modules A + B + C)
# ---------------------------------------------------------------------------

cmd_generate() {
  local product="" ref_image="" angle_filter="all" scene_filter="" specific_model=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --product)    product="$2";        shift 2 ;;
      --ref-image)  ref_image="$2";      shift 2 ;;
      --angles)     angle_filter="$2";   shift 2 ;;
      --scene)      scene_filter="$2";   shift 2 ;;
      --model)      specific_model="$2"; shift 2 ;;
      --output-dir) OUTPUT_DIR="$2";     shift 2 ;;
      --dry-run)    DRY_RUN="true";      shift ;;
      *) die "generate: unknown option: $1" ;;
    esac
  done

  [ -z "$product" ] && die "generate: --product is required"

  info "=== Full Product Studio Pipeline ==="
  info "Brand: $BRAND ($BRAND_DISPLAY)"
  info "Product: $product"
  info "Output: $OUTPUT_DIR"
  [ "$DRY_RUN" = "true" ] && info ">>> DRY RUN MODE — no images will be generated <<<"
  echo ""

  info "--- Module A: Pack Shots ---"
  run_packshot "$product" "$angle_filter" "$ref_image"
  echo ""

  info "--- Module B: Product Placement ---"
  run_placement "$product" "$scene_filter" "$ref_image"
  echo ""

  info "--- Module C: Model Swap ---"
  run_model_swap "$product" "$ref_image" "$specific_model"
  echo ""

  info "=== Pipeline Complete ==="
}

# ---------------------------------------------------------------------------
# Subcommand: packshot (Module A only)
# ---------------------------------------------------------------------------

cmd_packshot() {
  local product="" ref_image="" angle_filter="all"

  while [ $# -gt 0 ]; do
    case "$1" in
      --product)    product="$2";      shift 2 ;;
      --ref-image)  ref_image="$2";    shift 2 ;;
      --angles)     angle_filter="$2"; shift 2 ;;
      --output-dir) OUTPUT_DIR="$2";   shift 2 ;;
      --dry-run)    DRY_RUN="true";    shift ;;
      *) die "packshot: unknown option: $1" ;;
    esac
  done

  [ -z "$product" ] && die "packshot: --product is required"

  info "=== Pack Shot Generation ==="
  info "Brand: $BRAND ($BRAND_DISPLAY) | Product: $product | Angles: $angle_filter"
  [ "$DRY_RUN" = "true" ] && info ">>> DRY RUN MODE <<<"
  echo ""

  run_packshot "$product" "$angle_filter" "$ref_image"
  info "=== Pack Shot Complete ==="
}

# ---------------------------------------------------------------------------
# Subcommand: placement (Module B only)
# ---------------------------------------------------------------------------

cmd_placement() {
  local product="" ref_image="" scene_filter=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --product)    product="$2";      shift 2 ;;
      --ref-image)  ref_image="$2";    shift 2 ;;
      --scene)      scene_filter="$2"; shift 2 ;;
      --output-dir) OUTPUT_DIR="$2";   shift 2 ;;
      --dry-run)    DRY_RUN="true";    shift ;;
      *) die "placement: unknown option: $1" ;;
    esac
  done

  [ -z "$product" ] && die "placement: --product is required"

  info "=== Product Placement ==="
  info "Brand: $BRAND ($BRAND_DISPLAY) | Product: $product | Scene: ${scene_filter:-brand-default}"
  [ "$DRY_RUN" = "true" ] && info ">>> DRY RUN MODE <<<"
  echo ""

  run_placement "$product" "$scene_filter" "$ref_image"
  info "=== Placement Complete ==="
}

# ---------------------------------------------------------------------------
# Subcommand: model-swap (Module C only)
# ---------------------------------------------------------------------------

cmd_model_swap() {
  local product="" ref_image="" specific_model=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --product)    product="$2";        shift 2 ;;
      --ref-image)  ref_image="$2";      shift 2 ;;
      --model)      specific_model="$2"; shift 2 ;;
      --output-dir) OUTPUT_DIR="$2";     shift 2 ;;
      --dry-run)    DRY_RUN="true";      shift ;;
      *) die "model-swap: unknown option: $1" ;;
    esac
  done

  [ -z "$product" ] && die "model-swap: --product is required"

  info "=== Model Swap ==="
  info "Brand: $BRAND ($BRAND_DISPLAY) | Product: $product"
  [ "$DRY_RUN" = "true" ] && info ">>> DRY RUN MODE <<<"
  echo ""

  run_model_swap "$product" "$ref_image" "$specific_model"
  info "=== Model Swap Complete ==="
}

# ---------------------------------------------------------------------------
# Subcommand: batch (all products for a brand)
# ---------------------------------------------------------------------------

cmd_batch() {
  local module="all" ref_image=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --module)     module="$2";     shift 2 ;;
      --ref-image)  ref_image="$2";  shift 2 ;;
      --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
      --dry-run)    DRY_RUN="true";  shift ;;
      *) die "batch: unknown option: $1" ;;
    esac
  done

  info "=== Batch Mode ==="
  info "Brand: $BRAND ($BRAND_DISPLAY) | Module: $module"
  [ "$DRY_RUN" = "true" ] && info ">>> DRY RUN MODE <<<"
  echo ""

  # Load products from DNA.json
  local products_raw
  products_raw=$(dna_get_list "$DNA_FILE" "products")

  if [ -z "$products_raw" ]; then
    die "No products found in $DNA_FILE"
  fi

  local product_count=0
  local IFS_OLD="$IFS"

  # Read products line by line — convert display names to slugs
  echo "$products_raw" | while IFS= read -r product_line; do
    [ -z "$product_line" ] && continue

    # Convert product name to slug: lowercase, spaces to hyphens, strip parens/commas
    local slug
    slug=$(echo "$product_line" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9 -]//g' | sed 's/  */ /g' | sed 's/ /-/g' | cut -c1-50)

    [ -z "$slug" ] && continue

    info "--- Processing product: $slug (from: $product_line) ---"

    case "$module" in
      all)
        run_packshot "$slug" "all" "$ref_image"
        run_placement "$slug" "" "$ref_image"
        run_model_swap "$slug" "$ref_image" ""
        ;;
      packshot)
        run_packshot "$slug" "all" "$ref_image"
        ;;
      placement)
        run_placement "$slug" "" "$ref_image"
        ;;
      model-swap)
        run_model_swap "$slug" "$ref_image" ""
        ;;
      *)
        die "batch: unknown module: $module (use packshot, placement, model-swap, or all)"
        ;;
    esac

    product_count=$((product_count + 1))
    echo ""
  done

  IFS="$IFS_OLD"
  info "=== Batch Complete ==="
}

# ---------------------------------------------------------------------------
# Help / Usage
# ---------------------------------------------------------------------------

show_help() {
  cat <<'USAGE'
product-studio.sh — Automated e-commerce product photography for GAIA brands

USAGE:
  product-studio.sh <subcommand> --brand <brand> [options]

SUBCOMMANDS:
  generate      Full pipeline: pack shots + placement + model swap
  packshot      Module A: Product photos at multiple angles (white + branded BG)
  placement     Module B: Product placed in lifestyle scenes
  model-swap    Module C: Models holding/using product with demographic diversity
  batch         Run pipeline for ALL products in a brand's DNA.json

REQUIRED FLAGS:
  --brand <brand>       Brand slug (e.g., mirra, pinxin-vegan, dr-stan)
  --product <product>   Product slug (not needed for batch)

OPTIONAL FLAGS:
  --ref-image <path>    Path to real product photo (strongly recommended)
  --angles <filter>     Angle filter: all, hero, overhead, front (default: all)
  --scene <scene>       Scene type: kitchen, dining, hawker, office, etc.
  --model <desc>        Specific model description for model-swap
  --output-dir <path>   Override output directory
  --dry-run             Show what would be generated without calling API

EXAMPLES:
  # Full pipeline for MIRRA bento box
  product-studio.sh generate --brand mirra --product "bento-box-a" \
    --ref-image /path/to/photo.jpg

  # Pack shots only (all angles, white + branded backgrounds)
  product-studio.sh packshot --brand pinxin-vegan --product "nasi-lemak-set"

  # Pack shots — hero angle only
  product-studio.sh packshot --brand gaia-eats --product "rendang-paste" \
    --angles hero

  # Product placement in kitchen scene
  product-studio.sh placement --brand rasaya --product "turmeric-latte" \
    --scene kitchen --ref-image /path/to/bottle.jpg

  # Model swap with specific model
  product-studio.sh model-swap --brand mirra --product "bento-box-a" \
    --model "Malay woman 30, hijab, professional, warm smile"

  # Model swap with brand-default diverse demographics
  product-studio.sh model-swap --brand wholey-wonder --product "acai-bowl"

  # Batch all products for a brand (full pipeline)
  product-studio.sh batch --brand mirra

  # Batch pack shots only
  product-studio.sh batch --brand mirra --module packshot

  # Dry run — preview what would be generated
  product-studio.sh generate --brand mirra --product "bento-box-a" --dry-run

OUTPUT:
  Images saved to: ~/.openclaw/workspace/data/images/{brand}/product-studio/
  Naming: {brand}_{product}_{module}_{angle|scene|demo}_{variant}.png

VERSION: 1.0.0
USAGE
}

# ---------------------------------------------------------------------------
# Main Entry Point
# ---------------------------------------------------------------------------

DRY_RUN="false"
OUTPUT_DIR=""

main() {
  [ $# -eq 0 ] && { show_help; exit 0; }

  local subcommand="$1"
  shift

  if [ "$subcommand" = "--help" ] || [ "$subcommand" = "-h" ] || [ "$subcommand" = "help" ]; then
    show_help
    exit 0
  fi

  # Parse --brand from args (must appear before subcommand-specific parsing)
  local brand=""
  local remaining_args=""
  local args_array=""
  local skip_next="false"

  # First pass: extract --brand and --dry-run, --output-dir from top-level
  local i=0
  local saved_args=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)
        brand="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN="true"
        saved_args="$saved_args --dry-run"
        shift
        ;;
      --output-dir)
        OUTPUT_DIR="$2"
        saved_args="$saved_args --output-dir $2"
        shift 2
        ;;
      *)
        saved_args="$saved_args $1"
        shift
        ;;
    esac
  done

  [ -z "$brand" ] && die "--brand is required. Run with --help for usage."

  # Load brand DNA
  load_brand_dna "$brand"

  # Set default output dir if not overridden
  if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$IMAGES_DIR/$brand/product-studio"
  fi
  mkdir -p "$OUTPUT_DIR"

  # Dispatch to subcommand (re-set positional params from saved_args)
  eval "set -- $saved_args"

  case "$subcommand" in
    generate)    cmd_generate "$@" ;;
    packshot)    cmd_packshot "$@" ;;
    placement)   cmd_placement "$@" ;;
    model-swap)  cmd_model_swap "$@" ;;
    batch)       cmd_batch "$@" ;;
    *)           die "Unknown subcommand: $subcommand. Run with --help for usage." ;;
  esac
}

main "$@"
