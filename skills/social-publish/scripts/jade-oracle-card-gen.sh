#!/usr/bin/env bash
# jade-oracle-card-gen.sh — Jade Oracle Deck Card Image Generator
#
# Generates oracle card images + captions for Instagram from Jade's 25-card system.
# Cards: 9 Archetype (Nine Stars), 8 Pathway (Eight Doors), 8 Guardian (Eight Deities).
#
# Usage:
#   bash jade-oracle-card-gen.sh --card "The Phoenix"
#   bash jade-oracle-card-gen.sh --random
#   bash jade-oracle-card-gen.sh --daily                  # deterministic by date
#   bash jade-oracle-card-gen.sh --pick-a-card            # 3 random cards for carousel
#   bash jade-oracle-card-gen.sh --daily --dry-run
#
# macOS Bash 3.2 compatible.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
DATE="$(date +%Y-%m-%d)"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
CLAUDE_CLI="$(command -v claude 2>/dev/null || echo "")"

# NanoBanana paths — check multiple known locations
NANOBANANA=""
for nb_candidate in \
    "$OPENCLAW_DIR/skills/nanobanana/scripts/nanobanana-gen.sh" \
    "$OPENCLAW_DIR/skills/ad-composer/scripts/nanobanana-gen.sh" \
    "$(dirname "$SCRIPT_DIR")/../nanobanana/scripts/nanobanana-gen.sh"
do
    if [ -f "$nb_candidate" ]; then
        NANOBANANA="$nb_candidate"
        break
    fi
done

OUTPUT_DIR="$OPENCLAW_DIR/workspace/data/images/jade-oracle/oracle-cards"
BRAND_DNA="$OPENCLAW_DIR/brands/jade-oracle/DNA.json"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"

# Defaults
MODE=""
CARD_NAME=""
DRY_RUN=0

# ─────────────────────────────────────────────────────────────────────────────
# Card Data (25 cards)
# ─────────────────────────────────────────────────────────────────────────────
# Format: "Name|Chinese|Suite|Element/Theme|Keyword1|Keyword2|Visual"

CARD_COUNT=25

# Archetype Cards (Nine Stars) — indices 0..8
CARD_0="The Drifter|天蓬|Archetype|Water|Mystery|Depth|A single drop of water falling into a still jade pool, concentric ripples radiating outward, mist rising"
CARD_1="The Healer|天芮|Archetype|Earth|Nurturing|Patience|Hands cupping rich dark soil with a tiny green sprout emerging, warm golden light filtering through fingers"
CARD_2="The Warrior|天冲|Archetype|Wood|Action|Courage|A single bamboo stalk bending but not breaking in wind, morning dew drops catching light, dynamic motion blur"
CARD_3="The Sage|天辅|Archetype|Wood|Wisdom|Teaching|An ancient open book resting beneath a ginkgo tree, golden leaves falling, a jade bookmark ribbon"
CARD_4="The Emperor|天禽|Archetype|Earth|Balance|Stability|A perfectly balanced stone cairn on a mossy rock, still water reflection, mountain backdrop in mist"
CARD_5="The Architect|天心|Archetype|Metal|Strategy|Precision|A compass rose etched in jade, gold geometric lines radiating outward, blueprint-like precision on cream paper"
CARD_6="The Blade|天柱|Archetype|Metal|Precision|Truth|A single jade hairpin standing upright, casting a sharp precise shadow, light catching its edge"
CARD_7="The Mountain|天任|Archetype|Earth|Stability|Endurance|A solitary mountain peak rising above clouds, morning light touching the summit, ancient pine at the base"
CARD_8="The Phoenix|天英|Archetype|Fire|Brilliance|Transformation|A single golden feather aflame at its tip, rising sparks like fireflies, cream and gold background"

# Pathway Cards (Eight Doors) — indices 9..16
CARD_9="The Rest|休门|Pathway|Ease|Recovery|Rest|A jade teacup steaming on a window ledge, rain outside, linen curtain half-drawn, warm interior light"
CARD_10="The Tomb|死门|Pathway|Endings|Closure|Release|A closed jade box with a golden clasp, a single dried flower resting on top, dust motes in a beam of light"
CARD_11="The Strike|伤门|Pathway|Action|Speed|Force|Lightning captured in a glass orb, sharp angular gold lines on dark sage background, electric energy"
CARD_12="The Veil|杜门|Pathway|Secrecy|Strategy|Hidden|A sheer cream curtain with jade green shadows behind it, silhouette of a hand almost touching the fabric"
CARD_13="The Stage|景门|Pathway|Visibility|Expression|Spotlight|A minimalist Korean-style stage, single jade spotlight from above, golden dust particles dancing in the beam"
CARD_14="The Open Road|开门|Pathway|Opportunity|Career|Expansion|A long straight road vanishing into golden horizon, jade green fields on either side, one pair of footprints"
CARD_15="The Alarm|惊门|Pathway|Shock|Wake-up|Awareness|A jade bell mid-ring, visible sound waves rippling outward in gold, minimal cream background, dynamic moment"
CARD_16="The Garden|生门|Pathway|Growth|Wealth|Abundance|A lush miniature garden in a jade bowl, golden coins scattered among moss and tiny flowers, sunlight streaming"

# Guardian Cards (Eight Deities) — indices 17..24
CARD_17="The Crown|值符|Guardian|Divine protection|Authority|Grace|A minimalist jade crown floating above a silk cushion, single beam of golden light, regal and serene"
CARD_18="The Serpent|腾蛇|Guardian|Illusion|Transformation|Shedding|A jade serpent coiled in an infinity shape, scales reflecting gold light, wisps of smoke at its edges"
CARD_19="The Moon Mother|太阴|Guardian|Feminine wisdom|Intuition|Cycles|A crescent moon reflected in a jade mirror, soft silver and gold tones, lotus petals floating on water"
CARD_20="The Union|六合|Guardian|Partnership|Harmony|Connection|Two jade rings interlocked, resting on a golden silk cloth, soft light creating a warm halo around them"
CARD_21="The White Tiger|白虎|Guardian|Power|Danger|Protection|A single white tiger paw print pressed into jade-colored sand, gold claw marks catching light, powerful stillness"
CARD_22="The Earth Mother|九地|Guardian|Grounding|Patience|Foundation|Rich dark earth with jade moss, a single ancient root visible, warm golden light from below, primal and nurturing"
CARD_23="The Sky Father|九天|Guardian|Expansion|Ambition|Vision|An open sky viewed through a jade archway, gold-edged clouds, single bird soaring high, limitless and aspirational"
CARD_24="The Mirror|空|Guardian|Reflection|Self|Truth|A polished jade disc reflecting the viewer, gold frame, the reflection shows a softly glowing light instead of a face"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

log() {
    echo "[jade-card-gen $(date +%H:%M:%S)] $1"
}

err() {
    echo "[jade-card-gen $(date +%H:%M:%S)] ERROR: $1" >&2
}

die() {
    err "$1"
    exit 1
}

# Get card data by index (0..24). Sets CARD_* variables.
get_card_by_index() {
    local idx="$1"
    local raw=""
    eval "raw=\"\$CARD_${idx}\""
    # Parse pipe-delimited fields
    IFS='|' read -r C_NAME C_CHINESE C_SUITE C_ELEM C_KW1 C_KW2 C_VISUAL <<< "$raw"
}

# Lookup card by name (case-insensitive). Returns index or -1.
find_card_by_name() {
    local search
    search="$(echo "$1" | tr 'A-Z' 'a-z')"
    local i=0
    while [ "$i" -lt "$CARD_COUNT" ]; do
        local raw=""
        eval "raw=\"\$CARD_${i}\""
        local name
        name="$(echo "$raw" | cut -d'|' -f1 | tr 'A-Z' 'a-z')"
        if [ "$name" = "$search" ]; then
            echo "$i"
            return 0
        fi
        i=$((i + 1))
    done
    echo "-1"
    return 1
}

# Get deterministic card index from date string
daily_card_index() {
    # Use date as seed: sum of ASCII values mod CARD_COUNT
    local date_str="${1:-$DATE}"
    local sum=0
    local i=0
    while [ "$i" -lt "${#date_str}" ]; do
        local ch="${date_str:$i:1}"
        # Use printf to get ASCII value (Bash 3.2 compatible)
        local val
        val=$(printf '%d' "'$ch")
        sum=$((sum + val))
        i=$((i + 1))
    done
    echo $((sum % CARD_COUNT))
}

# Get N unique random card indices (seeded or urandom-based)
random_card_indices() {
    local count="${1:-1}"
    local seed="${2:-}"
    local indices=""
    local picked=0

    while [ "$picked" -lt "$count" ]; do
        local idx
        if [ -n "$seed" ]; then
            # Deterministic: hash seed + picked count
            local hash_input="${seed}_${picked}"
            local hash_sum=0
            local j=0
            while [ "$j" -lt "${#hash_input}" ]; do
                local ch="${hash_input:$j:1}"
                local val
                val=$(printf '%d' "'$ch")
                hash_sum=$((hash_sum + val * (j + 1)))
                j=$((j + 1))
            done
            idx=$((hash_sum % CARD_COUNT))
        else
            # Random: use /dev/urandom
            local rand_bytes
            rand_bytes=$(od -An -tu4 -N4 /dev/urandom 2>/dev/null | tr -d ' ')
            idx=$((rand_bytes % CARD_COUNT))
        fi

        # Check for duplicates
        local is_dup=0
        local existing_idx
        for existing_idx in $indices; do
            if [ "$existing_idx" -eq "$idx" ]; then
                is_dup=1
                break
            fi
        done

        if [ "$is_dup" -eq 0 ]; then
            indices="$indices $idx"
            picked=$((picked + 1))
        else
            # Bump seed to avoid infinite loop on collision
            seed="${seed:-rand}_bump${picked}"
        fi
    done

    echo "$indices"
}

# ─────────────────────────────────────────────────────────────────────────────
# Build NanoBanana prompt for a card
# ─────────────────────────────────────────────────────────────────────────────

build_image_prompt() {
    local name="$1"
    local chinese="$2"
    local suite="$3"
    local element="$4"
    local kw1="$5"
    local kw2="$6"
    local visual="$7"

    cat << PROMPT_EOF
Minimalist oracle card design for "${name}" (${chinese}).

Visual: ${visual}.

Style direction:
- Modern minimalist Korean editorial aesthetic
- Color palette: jade green (#00A86B), gold (#D4AF37), cream (#F5F0E8), warm black (#1A1A1A)
- Clean composition with generous negative space
- The card name "${name}" in elegant serif typography at the bottom
- Chinese characters "${chinese}" subtly placed near the name
- Suite indicator: "${suite}" — ${element}
- Keywords: ${kw1}, ${kw2}
- NOT tarot-cliché, NOT cosmic/galaxy, NOT gothic/witchy
- Think: Kinfolk magazine meets Korean temple aesthetics
- Soft natural lighting, warm tones, photographic texture
- Aspect ratio: 4:5 (Instagram portrait)
- High resolution, print-quality detail
PROMPT_EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate card image via NanoBanana (or save prompt)
# ─────────────────────────────────────────────────────────────────────────────

generate_card_image() {
    local idx="$1"
    get_card_by_index "$idx"

    local safe_name
    safe_name="$(echo "$C_NAME" | tr 'A-Z' 'a-z' | tr ' ' '-')"
    local card_dir="$OUTPUT_DIR/$safe_name"
    mkdir -p "$card_dir"

    local prompt
    prompt="$(build_image_prompt "$C_NAME" "$C_CHINESE" "$C_SUITE" "$C_ELEM" "$C_KW1" "$C_KW2" "$C_VISUAL")"

    # Save prompt file
    local prompt_file="$card_dir/card-${safe_name}-prompt.txt"
    echo "$prompt" > "$prompt_file"
    log "Prompt saved: $prompt_file"

    local image_file="$card_dir/card-${safe_name}.png"

    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] Would generate image for: $C_NAME ($C_CHINESE)"
        log "[DRY RUN] Prompt file: $prompt_file"
        echo "$prompt_file"
        return 0
    fi

    # Try NanoBanana if available
    if [ -n "$NANOBANANA" ] && [ -f "$NANOBANANA" ]; then
        log "Generating image via NanoBanana for: $C_NAME"
        if bash "$NANOBANANA" generate \
            --brand jade-oracle \
            --use-case product \
            --prompt "$prompt" \
            --model pro \
            --ratio "4:5" \
            --size 2K \
            --output "$image_file" 2>&1; then
            if [ -f "$image_file" ]; then
                log "Image generated: $image_file"
                echo "$image_file"
                return 0
            fi
        fi
        err "NanoBanana generation failed for $C_NAME — prompt saved for manual generation"
    else
        log "NanoBanana not available — prompt saved for manual generation: $prompt_file"
    fi

    echo "$prompt_file"
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate caption via Claude CLI
# ─────────────────────────────────────────────────────────────────────────────

generate_caption() {
    local idx="$1"
    get_card_by_index "$idx"

    local safe_name
    safe_name="$(echo "$C_NAME" | tr 'A-Z' 'a-z' | tr ' ' '-')"
    local card_dir="$OUTPUT_DIR/$safe_name"
    mkdir -p "$card_dir"

    local caption_file="$card_dir/card-${safe_name}-caption.txt"
    local caption=""

    if [ "$DRY_RUN" -eq 1 ]; then
        caption="[DRY RUN] Caption for $C_NAME ($C_CHINESE) — $C_SUITE card, element: $C_ELEM. Keywords: $C_KW1, $C_KW2."
        echo "$caption" > "$caption_file"
        log "[DRY RUN] Caption saved: $caption_file"
        return 0
    fi

    if [ -n "$CLAUDE_CLI" ]; then
        log "Generating caption via Claude CLI for: $C_NAME"
        local _prompt_file
        _prompt_file="$(mktemp)"
        cat > "$_prompt_file" << CAPTION_PROMPT
You are Jade (@the_jade_oracle), a warm Korean-inspired QMDJ oracle on Instagram.

Write an Instagram caption for today's Card of the Day: "${C_NAME}" (${C_CHINESE}).

Card details:
- Suite: ${C_SUITE} card
- Element/Theme: ${C_ELEM}
- Keywords: ${C_KW1}, ${C_KW2}
- Visual symbolism: ${C_VISUAL}

Rules:
- Start with a scroll-stopping hook (first line is everything)
- 150-300 words
- Weave in the card's meaning with practical life wisdom
- Reference the Chinese name naturally (not forced)
- End with a reflective question or gentle prompt
- Voice: warm, wise, slightly mysterious — like a trusted spiritual advisor over tea
- Add a soft CTA like "Save this for later" or "Tag someone who needs this"
- Include 15-20 hashtags at the end (mix of #jadeoracle, #qmdj, #oraclecards, #cardoftheday, #奇门遁甲, #spiritualawakening, etc.)
- No emojis overload — max 3-4 meaningful ones

Output ONLY the final Instagram caption. Nothing else.
CAPTION_PROMPT
        caption=$("$CLAUDE_CLI" --print --model "claude-sonnet-4-6" < "$_prompt_file") || true
        rm -f "$_prompt_file"
    fi

    # Fallback if Claude is not available or fails
    if [ -z "$caption" ]; then
        log "Claude CLI not available — generating template caption"
        caption="${C_NAME} (${C_CHINESE})

Today's card whispers of ${C_KW1} and ${C_KW2}.

In Qi Men Dun Jia, ${C_CHINESE} speaks to the ${C_ELEM} within all of us. When this ${C_SUITE} card appears, the time has come to pay attention to what shifts beneath the surface.

What is ${C_NAME} asking you to see today?

Save this for when you need the reminder.

#jadeoracle #qmdj #oraclecards #cardoftheday #奇门遁甲 #qimendunjia #spiritualawakening #energyreading #divination #oracledeck #dailyoracle #spirituality #easternwisdom #metaphysics #healingjourney #selfdiscovery #innerwork #koreanwellness #energyhealing #dailyguidance"
    fi

    echo "$caption" > "$caption_file"
    log "Caption saved: $caption_file"
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate a single card (image + caption)
# ─────────────────────────────────────────────────────────────────────────────

generate_single_card() {
    local idx="$1"
    get_card_by_index "$idx"

    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Card: ${C_NAME} (${C_CHINESE})"
    log "Suite: ${C_SUITE} | Element: ${C_ELEM}"
    log "Keywords: ${C_KW1}, ${C_KW2}"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    generate_card_image "$idx"
    generate_caption "$idx"

    local safe_name
    safe_name="$(echo "$C_NAME" | tr 'A-Z' 'a-z' | tr ' ' '-')"
    local card_dir="$OUTPUT_DIR/$safe_name"

    log ""
    log "Output files:"
    log "  Image/Prompt: $card_dir/card-${safe_name}.png (or card-${safe_name}-prompt.txt)"
    log "  Caption:      $card_dir/card-${safe_name}-caption.txt"
    log ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Pick-a-Card mode: generate 3 random cards for carousel
# ─────────────────────────────────────────────────────────────────────────────

generate_pick_a_card() {
    log "========================================="
    log "Pick-a-Card Mode: Generating 3 cards"
    log "========================================="

    local indices
    indices="$(random_card_indices 3 "$DATE")"

    local carousel_dir="$OUTPUT_DIR/pick-a-card/$DATE"
    mkdir -p "$carousel_dir"

    local card_num=1
    local manifest=""

    for idx in $indices; do
        get_card_by_index "$idx"
        log ""
        log "Card $card_num of 3:"
        generate_single_card "$idx"

        local safe_name
        safe_name="$(echo "$C_NAME" | tr 'A-Z' 'a-z' | tr ' ' '-')"
        manifest="${manifest}Card ${card_num}: ${C_NAME} (${C_CHINESE}) — ${C_SUITE} — ${C_KW1}, ${C_KW2}\n"
        card_num=$((card_num + 1))
    done

    # Generate carousel caption
    local carousel_caption_file="$carousel_dir/pick-a-card-caption.txt"

    if [ "$DRY_RUN" -eq 1 ]; then
        printf "[DRY RUN] Pick-a-Card carousel:\n%b" "$manifest" > "$carousel_caption_file"
        log "[DRY RUN] Carousel caption: $carousel_caption_file"
        return 0
    fi

    if [ -n "$CLAUDE_CLI" ]; then
        log "Generating carousel caption via Claude CLI..."
        local carousel_caption
        local _carousel_prompt_file
        _carousel_prompt_file="$(mktemp)"
        cat > "$_carousel_prompt_file" << CAROUSEL_PROMPT
You are Jade (@the_jade_oracle), a warm Korean-inspired QMDJ oracle on Instagram.

Write an Instagram caption for a Pick-a-Card carousel post. The 3 cards are:
$(printf '%b' "$manifest")

Rules:
- Start with "Pick a card, pick a card..." or similar scroll-stopping hook
- Briefly introduce the energy of the day
- Tell the viewer to swipe and pick Card 1, 2, or 3 based on intuition
- Give a 2-3 sentence reading for each card (don't reveal which is which until they swipe)
- End with "Drop your card number in the comments"
- Voice: warm, wise, playful — like sharing oracle cards over wine with your best friend
- Max 2000 characters
- 15-20 hashtags at the end

Output ONLY the final Instagram caption.
CAROUSEL_PROMPT
        carousel_caption=$("$CLAUDE_CLI" --print --model "claude-sonnet-4-6" < "$_carousel_prompt_file") || true
        rm -f "$_carousel_prompt_file"

        if [ -n "$carousel_caption" ]; then
            echo "$carousel_caption" > "$carousel_caption_file"
        fi
    fi

    # Fallback
    if [ ! -f "$carousel_caption_file" ] || [ ! -s "$carousel_caption_file" ]; then
        printf "Pick a card.\n\nClose your eyes. Take a breath. Which number calls to you — 1, 2, or 3?\n\nToday's Qi Men reading pulled three cards from the deck, each carrying a different message.\n\nSwipe to reveal yours.\n\n%b\n\nDrop your number in the comments. I want to know what found you today.\n\n#jadeoracle #pickacardreading #oraclecards #qmdj #奇门遁甲 #qimendunjia #cardoftheday #spiritualawakening #oracledeck #divination #dailyoracle #koreanwellness #energyreading #tarotcommunity #metaphysics #healingjourney #selfdiscovery #innerwork #spirituality #dailyguidance" "$manifest" > "$carousel_caption_file"
    fi

    log "Carousel caption saved: $carousel_caption_file"

    log ""
    log "========================================="
    log "Pick-a-Card complete!"
    log "Output: $carousel_dir/"
    log "========================================="
}

# ─────────────────────────────────────────────────────────────────────────────
# Post to room log
# ─────────────────────────────────────────────────────────────────────────────

post_to_room() {
    local msg="$1"
    if [ -f "$ROOM_FILE" ] || [ -d "$(dirname "$ROOM_FILE")" ]; then
        echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"card-gen\",\"body\":\"$msg\"}" >> "$ROOM_FILE" 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────────────────────────────────

usage() {
    cat << 'USAGE_EOF'
jade-oracle-card-gen.sh — Jade Oracle Deck Card Generator

USAGE:
  bash jade-oracle-card-gen.sh --card "The Phoenix"     # specific card
  bash jade-oracle-card-gen.sh --random                  # random card
  bash jade-oracle-card-gen.sh --daily                   # deterministic daily card
  bash jade-oracle-card-gen.sh --pick-a-card             # 3 random cards (carousel)
  bash jade-oracle-card-gen.sh --list                    # list all 25 cards
  bash jade-oracle-card-gen.sh --daily --dry-run         # dry run (no generation)

OPTIONS:
  --card NAME       Generate a specific card by name
  --random          Generate a random card
  --daily           Generate today's card (deterministic by date)
  --pick-a-card     Generate 3 cards for Instagram carousel post
  --list            List all 25 cards in the deck
  --dry-run         Preview without generating images/captions
  --help            Show this help

CARDS (25 total):
  Archetype (9): Drifter, Healer, Warrior, Sage, Emperor, Architect, Blade, Mountain, Phoenix
  Pathway (8):   Rest, Tomb, Strike, Veil, Stage, Open Road, Alarm, Garden
  Guardian (8):  Crown, Serpent, Moon Mother, Union, White Tiger, Earth Mother, Sky Father, Mirror
USAGE_EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────────────────────────────────────

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --card)
                MODE="card"
                shift
                if [ $# -eq 0 ]; then
                    die "--card requires a card name (e.g., --card \"The Phoenix\")"
                fi
                CARD_NAME="$1"
                shift
                ;;
            --random)
                MODE="random"
                shift
                ;;
            --daily)
                MODE="daily"
                shift
                ;;
            --pick-a-card)
                MODE="pick-a-card"
                shift
                ;;
            --list)
                MODE="list"
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done

    if [ -z "$MODE" ]; then
        usage
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# List all cards
# ─────────────────────────────────────────────────────────────────────────────

list_cards() {
    echo ""
    echo "Jade Oracle — 25-Card Deck"
    echo "═══════════════════════════════════════════════════"
    echo ""

    local suites="Archetype Pathway Guardian"
    for suite in $suites; do
        echo "  $suite Cards"
        echo "  ─────────────────────────────────────────"
        local i=0
        while [ "$i" -lt "$CARD_COUNT" ]; do
            local raw=""
            eval "raw=\"\$CARD_${i}\""
            local name chinese card_suite elem kw1 kw2
            IFS='|' read -r name chinese card_suite elem kw1 kw2 _ <<< "$raw"
            if [ "$card_suite" = "$suite" ]; then
                printf "    %-20s %s    %s — %s, %s\n" "$name" "$chinese" "$elem" "$kw1" "$kw2"
            fi
            i=$((i + 1))
        done
        echo ""
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"

    mkdir -p "$OUTPUT_DIR"

    case "$MODE" in
        list)
            list_cards
            ;;
        card)
            local idx
            idx="$(find_card_by_name "$CARD_NAME")" || true
            if [ "$idx" = "-1" ] || [ -z "$idx" ]; then
                die "Card not found: '$CARD_NAME'. Use --list to see all cards."
            fi
            log "========================================="
            log "Jade Oracle — Card Generator"
            log "Date: $DATE"
            [ "$DRY_RUN" -eq 1 ] && log "MODE: DRY RUN"
            log "========================================="
            generate_single_card "$idx"
            post_to_room "Generated card: $CARD_NAME"
            ;;
        random)
            local idx
            idx="$(random_card_indices 1)"
            idx="$(echo "$idx" | tr -d ' ')"
            log "========================================="
            log "Jade Oracle — Random Card"
            log "Date: $DATE"
            [ "$DRY_RUN" -eq 1 ] && log "MODE: DRY RUN"
            log "========================================="
            generate_single_card "$idx"
            get_card_by_index "$idx"
            post_to_room "Generated random card: $C_NAME"
            ;;
        daily)
            local idx
            idx="$(daily_card_index "$DATE")"
            log "========================================="
            log "Jade Oracle — Daily Card"
            log "Date: $DATE (card index: $idx)"
            [ "$DRY_RUN" -eq 1 ] && log "MODE: DRY RUN"
            log "========================================="
            generate_single_card "$idx"
            get_card_by_index "$idx"
            post_to_room "Daily card for $DATE: $C_NAME ($C_CHINESE)"
            ;;
        pick-a-card)
            generate_pick_a_card
            post_to_room "Pick-a-card generated for $DATE"
            ;;
    esac

    log "Done."
}

main "$@"
