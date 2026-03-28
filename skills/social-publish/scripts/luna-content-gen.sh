#!/usr/bin/env bash
# luna-content-gen.sh — Luna Solaris daily content generator
#
# Usage:
#   luna-content-gen.sh generate-all       Generate all 6 daily posts
#   luna-content-gen.sh generate <slot>    Generate specific slot (1-6)
#   luna-content-gen.sh post <slot>        Post specific slot to IG
#   luna-content-gen.sh health             Check system health
#   luna-content-gen.sh director           Plan today's content themes
#
# Designed to mirror jade-9post-generator.sh but for Luna's 6-post schedule.

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

HOME_DIR="/Users/jennwoeiloh"
OPENCLAW="${HOME_DIR}/.openclaw"
SKILLS="${OPENCLAW}/skills"
DATE=$(date +%Y-%m-%d)
HOUR=$(date +%H)

# Luna-specific paths
BRAND_DNA="${OPENCLAW}/brands/luna/DNA.json"
CHARACTER_SPEC="${OPENCLAW}/workspace/data/characters/jade-oracle/luna-v3-locked/CHARACTER-SPEC.md"
CONTENT_LIBRARY="${OPENCLAW}/workspace/data/characters/jade-oracle/luna-v3-locked/CONTENT-LIBRARY-PROMPTS.md"
FACE_LOCK="${OPENCLAW}/workspace/data/characters/jade-oracle/luna-v3-locked/luna-face-lock.png"
FACE_REFS="${OPENCLAW}/workspace/data/characters/luna/face-refs"
BODY_REFS="${OPENCLAW}/workspace/data/characters/luna/body-refs"
SCHEDULE="${SKILLS}/social-publish/data/luna-6post-schedule.json"

# Shared tools
NANOBANANA="${SKILLS}/nanobanana/scripts/nanobanana-gen.sh"
IG_PUBLISH="${SKILLS}/social-publish/scripts/ig-publish.py"
TOKEN_MGR="${SKILLS}/social-publish/scripts/meta-token-manager.sh"
VIBE_REEL="${SKILLS}/social-publish/scripts/jade-vibe-reel.sh"

# Output
CONTENT_DIR="${OPENCLAW}/workspace/data/content/luna/daily/${DATE}"
LOG_FILE="${OPENCLAW}/logs/luna-content-$(date +%Y%m%d).log"

mkdir -p "$CONTENT_DIR" "$(dirname "$LOG_FILE")"

CMD="${1:-help}"
SLOT="${2:-}"

log() {
  local msg="[luna $(date +%H:%M:%S)] $1"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

err() {
  local msg="[luna ERROR $(date +%H:%M:%S)] $1"
  echo "$msg" >&2
  echo "$msg" >> "$LOG_FILE"
}

# Luna's prompt anchor (MUST include in every generation)
PROMPT_ANCHOR="platinum blonde hair in a messy updo with wispy loose strands, ice blue-green eyes, fair porcelain skin, warm approachable smile"

# Slot definitions
get_slot_type() {
  case "$1" in
    1) echo "morning_ritual" ;;
    2) echo "outfit_of_day" ;;
    3) echo "aesthetic_reel" ;;
    4) echo "story_day_in_life" ;;
    5) echo "story_tarot_pull" ;;
    6) echo "story_aesthetic" ;;
    *) echo "unknown" ;;
  esac
}

get_slot_ratio() {
  case "$1" in
    1|2) echo "4:5" ;;
    3|4|5|6) echo "9:16" ;;
    *) echo "4:5" ;;
  esac
}

get_slot_format() {
  case "$1" in
    1|2) echo "feed_image" ;;
    3) echo "reel" ;;
    4|5|6) echo "story" ;;
    *) echo "feed_image" ;;
  esac
}

# Generate a single slot's content
generate_slot() {
  local slot="$1"
  local type
  type=$(get_slot_type "$slot")
  local ratio
  ratio=$(get_slot_ratio "$slot")
  local format
  format=$(get_slot_format "$slot")

  log "Generating slot ${slot}: ${type} (${format}, ${ratio})"

  local output_image="${CONTENT_DIR}/luna-slot${slot}-${type}.png"
  local output_caption="${CONTENT_DIR}/luna-slot${slot}-${type}.txt"

  # Select scene prompt based on type
  local scene_prompt=""
  case "$type" in
    morning_ritual)
      scene_prompt="Photorealistic medium shot photograph of a young woman with ${PROMPT_ANCHOR}, sitting up in bed drinking morning coffee from a ceramic mug, wearing an oversized cream sweater, cozy bedroom with white linen sheets and plants, warm golden morning sunlight streaming through window, real skin with pores, 35mm lens f/1.8, shallow depth of field. No illustration, no cartoon, no CG."
      ;;
    outfit_of_day)
      scene_prompt="Photorealistic full body photograph of a young woman with ${PROMPT_ANCHOR}, mirror selfie style showing today's outfit, wearing a vintage leather jacket over a soft floral dress with white sneakers, aesthetic bedroom mirror with warm tones, natural indoor lighting, real skin with pores, 35mm lens f/2.8, shallow depth of field. No illustration, no cartoon, no CG."
      ;;
    aesthetic_reel)
      scene_prompt="Photorealistic cinematic photograph of a young woman with ${PROMPT_ANCHOR}, sitting by a rainy cafe window writing in a journal, wearing a dark turtleneck and scarf, rainy city street visible through glass, moody warm diffused window light, real skin with pores, 50mm lens f/1.8, shallow depth of field. No illustration, no cartoon, no CG."
      ;;
    story_day_in_life)
      scene_prompt="Photorealistic candid photograph of a young woman with ${PROMPT_ANCHOR}, working on a laptop at a wooden cafe table with a flat white, wearing a casual oversized cardigan, indie cafe interior with warm lighting, natural light, real skin with pores, 35mm lens f/2.0, shallow depth of field. No illustration, no cartoon, no CG."
      ;;
    story_tarot_pull)
      scene_prompt="Photorealistic overhead photograph of a young woman with ${PROMPT_ANCHOR}, sitting cross-legged on floor with oracle cards spread out, candles and crystals around her, wearing cozy loungewear, warm intimate candlelight atmosphere, real skin with pores, 35mm lens f/1.4, shallow depth of field. No illustration, no cartoon, no CG."
      ;;
    story_aesthetic)
      scene_prompt="Photorealistic medium shot photograph of a young woman with ${PROMPT_ANCHOR}, reading a book under fairy lights with a cup of tea, wearing soft cream pajamas under a blanket, cozy bedroom nook setting, warm intimate night lighting, real skin with pores, 50mm lens f/1.4, shallow depth of field. No illustration, no cartoon, no CG."
      ;;
  esac

  # Generate image via NanoBanana
  if [[ -x "$NANOBANANA" ]] && [[ -f "$FACE_LOCK" ]]; then
    log "  Generating image via NanoBanana..."
    bash "$NANOBANANA" \
      --prompt "$scene_prompt" \
      --ref-image "$FACE_LOCK" \
      --aspect-ratio "$ratio" \
      --model pro \
      --output "$output_image" 2>>"$LOG_FILE" || {
        err "  NanoBanana failed for slot ${slot}"
        return 1
      }
    log "  Image: ${output_image}"
  else
    log "  SKIP: NanoBanana or face-lock not available"
    echo "$scene_prompt" > "${output_image%.png}.prompt.txt"
    log "  Prompt saved: ${output_image%.png}.prompt.txt"
  fi

  # Generate caption
  local hashtag_set=""
  case "$type" in
    morning_ritual) hashtag_set="#SlowLiving #SlowMorning #MorningRitual #RomanticizeYourLife #IntentionalLiving" ;;
    outfit_of_day) hashtag_set="#ThriftedStyle #VintageFinds #SecondhandFirst #OOTD #SustainableFashion" ;;
    aesthetic_reel) hashtag_set="#RomanticizeTheMundane #SoftAesthetic #CozyVibes #DreamyLife #SlowLivingDaily" ;;
    story_day_in_life) hashtag_set="#SoftAmbition #FreelanceLife #CafeLife #WorkLifeBalance #GentleLiving" ;;
    story_tarot_pull) hashtag_set="#TarotDaily #OracleCards #MoonRituals #EveningRitual #SpiritualPractice" ;;
    story_aesthetic) hashtag_set="#CozyNight #BookishVibes #FairyLights #NightRoutine #SlowEvening" ;;
  esac

  # Caption templates (rotate based on day of week)
  local dow
  dow=$(date +%u)
  local caption=""
  case "$type" in
    morning_ritual)
      case $((dow % 3)) in
        0) caption="Monday morning reminder: you don't need to have it all figured out today. Start with coffee. The rest will follow." ;;
        1) caption="The best mornings aren't the productive ones — they're the ones where you actually taste your coffee." ;;
        2) caption="Unhurried mornings are my love language. No alarms, just golden light and a really good cup." ;;
      esac
      ;;
    outfit_of_day)
      case $((dow % 3)) in
        0) caption="Today's entire outfit cost less than a fancy brunch. Thrift store magic is real." ;;
        1) caption="The best outfits tell a story. This jacket? \$12 from a vintage shop that smelled like old books." ;;
        2) caption="Proof that you don't need a big budget to feel like yourself. Just a little patience and a good eye." ;;
      esac
      ;;
    aesthetic_reel)
      caption="Romanticizing the ordinary. Because a rainy afternoon with a journal and a window seat is its own kind of luxury."
      ;;
    story_day_in_life)
      caption="Freelance life update: found the perfect cafe. Strong wifi, warm light, and they don't judge me for staying 3 hours."
      ;;
    story_tarot_pull)
      caption="Tonight's pull. What message does this card have for you? Drop a comment and I'll share what I see."
      ;;
    story_aesthetic)
      caption="Winding down the only way I know how — fairy lights, a good book, and zero screen time."
      ;;
  esac

  echo "${caption}

${hashtag_set}" > "$output_caption"
  log "  Caption: ${output_caption}"
  log "  Slot ${slot} generation complete"
}

# Generate all slots
generate_all() {
  log "=== LUNA DAILY CONTENT GENERATION ==="
  log "Date: ${DATE}"

  for slot in 1 2 3 4 5 6; do
    generate_slot "$slot" || err "Slot ${slot} failed (continuing)"
  done

  local count
  count=$(find "$CONTENT_DIR" -name 'luna-*' -type f 2>/dev/null | wc -l | tr -d ' ')
  log "=== GENERATION COMPLETE: ${count} files ==="
}

# Post a slot to Instagram
post_slot() {
  local slot="$1"
  local type
  type=$(get_slot_type "$slot")
  local format
  format=$(get_slot_format "$slot")

  local image="${CONTENT_DIR}/luna-slot${slot}-${type}.png"
  local caption_file="${CONTENT_DIR}/luna-slot${slot}-${type}.txt"

  if [[ ! -f "$image" ]]; then
    err "No image for slot ${slot}. Run generate first."
    return 1
  fi

  local caption=""
  [[ -f "$caption_file" ]] && caption=$(cat "$caption_file")

  log "Posting slot ${slot} (${type}) as ${format}..."

  # TODO: Replace with Luna's own IG credentials when account is set up
  # For now, log what would be posted
  log "  WOULD POST: ${image}"
  log "  Caption: ${caption:0:100}..."
  log "  Format: ${format}"
  log "  NOTE: Luna IG account not yet configured. Set up Meta token for @luna.solaris"
}

# Health check
health_check() {
  log "=== LUNA HEALTH CHECK ==="

  # Check character files
  [[ -f "$FACE_LOCK" ]] && log "  Face lock: OK" || err "  Face lock: MISSING"
  [[ -f "$CHARACTER_SPEC" ]] && log "  Character spec: OK" || err "  Character spec: MISSING"
  [[ -f "$CONTENT_LIBRARY" ]] && log "  Content library: OK" || err "  Content library: MISSING"
  [[ -f "$BRAND_DNA" ]] && log "  Brand DNA: OK" || err "  Brand DNA: MISSING"
  [[ -f "$SCHEDULE" ]] && log "  Schedule: OK" || err "  Schedule: MISSING"
  [[ -d "$FACE_REFS" ]] && log "  Face refs: OK ($(ls "$FACE_REFS" | wc -l | tr -d ' ') files)" || err "  Face refs: MISSING"
  [[ -d "$BODY_REFS" ]] && log "  Body refs: OK ($(ls "$BODY_REFS" | wc -l | tr -d ' ') files)" || err "  Body refs: MISSING"

  # Check tools
  [[ -x "$NANOBANANA" ]] && log "  NanoBanana: OK" || err "  NanoBanana: MISSING"

  # Check today's content
  local today_count
  today_count=$(find "$CONTENT_DIR" -name 'luna-*' -type f 2>/dev/null | wc -l | tr -d ' ')
  log "  Today's content: ${today_count} files"

  log "=== HEALTH CHECK DONE ==="
}

# Content director — plan today's themes
run_director() {
  log "=== LUNA CONTENT DIRECTOR ==="
  log "Planning content themes for ${DATE}..."

  # Check what day of week for theme rotation
  local dow_name
  dow_name=$(date +%A)

  log "  Day: ${dow_name}"
  log "  Slots: 6 (2 feed + 1 reel + 3 stories)"

  # Theme suggestions based on day
  case "$dow_name" in
    Monday)    log "  Theme: Fresh Start Monday — new week, gentle intentions" ;;
    Tuesday)   log "  Theme: Thrift Tuesday — styling + vintage finds spotlight" ;;
    Wednesday) log "  Theme: Wellness Wednesday — self-care + slow living" ;;
    Thursday)  log "  Theme: Throwback Thursday — nostalgia, old favorites, analog vibes" ;;
    Friday)    log "  Theme: Freedom Friday — weekend plans, relaxed energy" ;;
    Saturday)  log "  Theme: Saturday Slow — farmers market, cooking, no plans" ;;
    Sunday)    log "  Theme: Soul Sunday — tarot, journaling, reflection" ;;
  esac

  log "=== DIRECTOR DONE ==="
}

# Main
case "$CMD" in
  generate-all)   generate_all ;;
  generate)       [[ -n "$SLOT" ]] && generate_slot "$SLOT" || echo "Usage: luna-content-gen.sh generate <slot>" ;;
  post)           [[ -n "$SLOT" ]] && post_slot "$SLOT" || echo "Usage: luna-content-gen.sh post <slot>" ;;
  post-slot)      [[ -n "$SLOT" ]] && post_slot "$SLOT" || echo "Usage: luna-content-gen.sh post-slot <slot>" ;;
  health)         health_check ;;
  director)       run_director ;;
  help|*)
    echo "Luna Solaris — Daily Content Generator"
    echo ""
    echo "Usage:"
    echo "  luna-content-gen.sh generate-all     Generate all 6 daily posts"
    echo "  luna-content-gen.sh generate <slot>  Generate specific slot (1-6)"
    echo "  luna-content-gen.sh post <slot>      Post specific slot to IG"
    echo "  luna-content-gen.sh health           Check system health"
    echo "  luna-content-gen.sh director         Plan today's content themes"
    echo ""
    echo "Schedule: ${SCHEDULE}"
    echo "Content: ${CONTENT_DIR}/"
    ;;
esac
