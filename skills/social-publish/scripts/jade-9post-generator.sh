#!/usr/bin/env bash
# jade-9post-generator.sh — Master daily content generator for Jade Oracle's 9 IG posts
#
# Reads the 9-post schedule from jade-9post-schedule.json, generates images + captions
# for every slot, and saves outputs ready for ig-publish.py.
#
# Usage:
#   bash jade-9post-generator.sh                     # Generate all 9 posts for today
#   bash jade-9post-generator.sh --date 2026-03-22   # Specific date
#   bash jade-9post-generator.sh --slot 3             # Generate only slot 3
#   bash jade-9post-generator.sh --dry-run            # Preview without generating
#   bash jade-9post-generator.sh --slot 4 --dry-run   # Preview single slot
#
# Output structure:
#   ~/.openclaw/workspace/data/content/jade-oracle/daily/YYYY-MM-DD/
#     slot-1-oracle_card.png           slot-1-caption.txt
#     slot-2-lifestyle.png             slot-2-caption.txt
#     slot-3-spiritual_quote.png       slot-3-caption.txt
#     slot-4-oracle_insight-1.png ...   slot-4-caption.txt
#     slot-5-aesthetic_flatlay.png     slot-5-caption.txt
#     slot-6-reading_scene.png        slot-6-caption.txt
#     slot-7-subtle_animation.mp4     slot-7-caption.txt
#     slot-8-pick_a_card-1.png ...    slot-8-caption.txt
#     slot-9-behind_scenes-1.png ...  slot-9-caption.txt
#
# macOS Bash 3.2 compatible (no declare -A, no local -n, no ${var,,}).
# Requires: python3, jq (or python3 json fallback), claude CLI (for captions).

set -euo pipefail

###############################################################################
# Paths & Constants
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

SCHEDULE_FILE="$SKILL_DIR/data/jade-9post-schedule.json"
BRAND_DNA="$OPENCLAW_DIR/brands/jade-oracle/DNA.json"
FACE_REFS_DIR="$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/face-refs"
NANOBANANA="$OPENCLAW_DIR/skills/ad-composer/scripts/nanobanana-gen.sh"
IG_PUBLISH="$SCRIPT_DIR/ig-publish.py"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"
LOG_DIR="$OPENCLAW_DIR/logs"

CLAUDE_CLI="$(command -v claude 2>/dev/null || echo "")"
CLAUDE_MODEL="claude-sonnet-4-6"

# Fallback NanoBanana locations
NANOBANANA_ALT_1="$OPENCLAW_DIR/skills/nanobanana/scripts/nanobanana-gen.sh"
NANOBANANA_ALT_2="$(cd "$SCRIPT_DIR/../../nanobanana/scripts" 2>/dev/null && pwd)/nanobanana-gen.sh"

###############################################################################
# Argument Parsing
###############################################################################

DATE="$(date +%Y-%m-%d)"
DRY_RUN=0
SINGLE_SLOT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --date)
            DATE="$2"
            shift 2
            ;;
        --slot)
            SINGLE_SLOT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        *)
            echo "Unknown flag: $1" >&2
            echo "Usage: jade-9post-generator.sh [--date YYYY-MM-DD] [--slot N] [--dry-run]"
            exit 1
            ;;
    esac
done

OUTPUT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily/$DATE"
LOG_FILE="$LOG_DIR/jade-9post-$(echo "$DATE" | tr -d '-').log"

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

###############################################################################
# Logging
###############################################################################

log() {
    local msg="[jade-9post $(date +%H:%M:%S)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

err() {
    local msg="[jade-9post $(date +%H:%M:%S)] ERROR: $1"
    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

room_msg() {
    [ -f "$ROOM_FILE" ] || return 0
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"9post-gen\",\"body\":\"$1\"}" >> "$ROOM_FILE" 2>/dev/null || true
}

###############################################################################
# JSON Helpers (macOS-safe — uses python3 if jq unavailable)
###############################################################################

json_get() {
    # json_get <file> <python_expression>
    # e.g., json_get schedule.json "data['slots'][0]['type']"
    local file="$1"
    local expr="$2"
    "$PYTHON3" -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
print($expr)
" 2>/dev/null
}

json_get_slot() {
    # json_get_slot <slot_number> <field>
    # Returns value of a field for a specific slot (1-indexed)
    local slot_num="$1"
    local field="$2"
    local idx=$((slot_num - 1))
    "$PYTHON3" -c "
import json
with open('$SCHEDULE_FILE') as f:
    data = json.load(f)
slot = data['slots'][$idx]
val = slot.get('$field', '')
print(val if val is not None else '')
" 2>/dev/null
}

json_get_hashtags() {
    # json_get_hashtags <set_name>
    local set_name="$1"
    "$PYTHON3" -c "
import json
with open('$SCHEDULE_FILE') as f:
    data = json.load(f)
print(data.get('hashtag_sets', {}).get('$set_name', ''))
" 2>/dev/null
}

json_slot_count() {
    "$PYTHON3" -c "
import json
with open('$SCHEDULE_FILE') as f:
    data = json.load(f)
print(len(data['slots']))
" 2>/dev/null
}

###############################################################################
# Resolve NanoBanana path
###############################################################################

resolve_nanobanana() {
    if [ -f "$NANOBANANA" ]; then
        echo "$NANOBANANA"
        return 0
    elif [ -f "$NANOBANANA_ALT_1" ]; then
        echo "$NANOBANANA_ALT_1"
        return 0
    elif [ -f "$NANOBANANA_ALT_2" ]; then
        echo "$NANOBANANA_ALT_2"
        return 0
    fi
    return 1
}

###############################################################################
# Resolve face reference images
###############################################################################

resolve_face_refs() {
    local refs_dir=""
    local candidate
    for candidate in \
        "$FACE_REFS_DIR" \
        "$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/lock" \
        "$HOME/Desktop/gaia-projects/jade-oracle-site/images/jade/v22-expressions" \
        "$HOME/Desktop/gaia-projects/jade-oracle-site/images/jade/v21-face-fixed"
    do
        if [ -d "$candidate" ]; then
            refs_dir="$candidate"
            break
        fi
    done

    if [ -z "$refs_dir" ]; then
        echo ""
        return 1
    fi

    # Collect up to 3 reference images
    local ref_list=""
    local count=0
    for img in "$refs_dir"/*.png "$refs_dir"/*.jpg; do
        [ -f "$img" ] || continue
        if [ -z "$ref_list" ]; then
            ref_list="$img"
        else
            ref_list="$ref_list,$img"
        fi
        count=$((count + 1))
        [ "$count" -ge 3 ] && break
    done

    echo "$ref_list"
}

###############################################################################
# Image Generation (NanoBanana with fallback to prompt file)
###############################################################################

generate_image() {
    local prompt="$1"
    local output_file="$2"
    local ratio="${3:-4:5}"
    local ref_images="${4:-}"

    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] Would generate: $(basename "$output_file")"
        log "  Prompt: $(echo "$prompt" | head -c 120)..."
        log "  Ratio: $ratio"
        # Write prompt file even in dry-run for review
        echo "$prompt" > "${output_file%.png}.prompt.txt"
        return 0
    fi

    local nb_path=""
    nb_path="$(resolve_nanobanana)" || true

    if [ -n "$nb_path" ]; then
        log "Generating image via NanoBanana: $(basename "$output_file")"

        # NanoBanana auto-saves to ~/.openclaw/workspace/data/images/brand/timestamp.png
        # It does NOT accept --output. Capture stdout to find the saved path, then move.
        local nb_output=""
        if [ -n "$ref_images" ]; then
            nb_output=$(bash "$nb_path" generate \
                --brand jade-oracle \
                --use-case character \
                --prompt "$prompt" \
                --ref-image "$ref_images" \
                --model pro \
                --ratio "$ratio" \
                --size 2K 2>>"$LOG_FILE") || true
        else
            nb_output=$(bash "$nb_path" generate \
                --brand jade-oracle \
                --use-case character \
                --prompt "$prompt" \
                --model pro \
                --ratio "$ratio" \
                --size 2K 2>>"$LOG_FILE") || true
        fi

        # Extract generated image path from NanoBanana output
        local generated_path=""
        generated_path=$(echo "$nb_output" | grep -oE '/[^ ]+\.png' | tail -1)

        if [ -n "$generated_path" ] && [ -f "$generated_path" ]; then
            cp "$generated_path" "$output_file"
            log "  Generated + copied: $output_file (from $generated_path)"
            return 0
        elif [ -f "$output_file" ]; then
            log "  Generated: $output_file"
            return 0
        else
            err "  NanoBanana failed or no image produced"
            echo "$nb_output" >> "$LOG_FILE"
        fi
    fi

    # Fallback: write prompt file for manual generation
    local prompt_file="${output_file%.png}.prompt.txt"
    log "  NanoBanana unavailable — saving prompt to: $(basename "$prompt_file")"
    {
        echo "# Image Generation Prompt"
        echo "# Output: $(basename "$output_file")"
        echo "# Ratio: $ratio"
        echo "# Brand: jade-oracle"
        echo "# Ref images: ${ref_images:-none}"
        echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        echo "$prompt"
    } > "$prompt_file"
    return 0
}

###############################################################################
# Caption Generation
###############################################################################

generate_caption() {
    local slot_num="$1"
    local post_type="$2"
    local caption_style="$3"
    local hashtag_set="$4"
    local extra_context="${5:-}"

    local output_file="$OUTPUT_DIR/slot-${slot_num}-caption.txt"
    local hashtags=""
    hashtags="$(json_get_hashtags "$hashtag_set")"

    # Build caption style instructions
    local style_instruction=""
    case "$caption_style" in
        mystical_warm)
            style_instruction="Warm, wise, slightly mysterious. Like a trusted spiritual advisor sharing insight over tea. Use sensory language — candle flames, jade stones, soft morning light."
            ;;
        personal_warm)
            style_instruction="Personal and warm, as if sharing a diary entry. Vulnerable yet empowered. First-person, intimate tone."
            ;;
        quote_minimal)
            style_instruction="Minimal — the quote speaks for itself. Short intro line, the quote, then a reflective closer. Max 3 sentences before hashtags."
            ;;
        educational)
            style_instruction="Educational but accessible. Break down complex metaphysics concepts. Use emojis sparingly as section markers. Include a 'save this post' CTA."
            ;;
        aesthetic_minimal)
            style_instruction="Ultra-minimal. 1-2 poetic lines max. Let the image do the talking. Evocative, sensory, no call to action."
            ;;
        interactive)
            style_instruction="Engaging and interactive. Ask a question or prompt action. 'Pick a card' or 'Comment your choice'. Build anticipation in the first line."
            ;;
        vibe_minimal)
            style_instruction="Mood-setting. 1 evocative sentence or phrase. Music emoji optional. Think: caption for an atmospheric reel."
            ;;
        *)
            style_instruction="Warm, wise, slightly mysterious — Jade Oracle brand voice."
            ;;
    esac

    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] Would generate caption for slot $slot_num ($post_type, $caption_style)"
        {
            echo "[DRY RUN CAPTION PLACEHOLDER]"
            echo "Slot: $slot_num | Type: $post_type | Style: $caption_style"
            echo ""
            echo "$hashtags"
        } > "$output_file"
        return 0
    fi

    # Try Claude CLI for caption generation
    if [ -n "$CLAUDE_CLI" ]; then
        local caption=""
        caption=$("$CLAUDE_CLI" --print --model "$CLAUDE_MODEL" <<CAPTION_PROMPT
You are writing an Instagram caption for Jade Oracle (@the_jade_oracle).

POST TYPE: $post_type
CAPTION STYLE: $style_instruction
DATE: $DATE
${extra_context:+CONTEXT: $extra_context}

BRAND VOICE RULES:
- Warm, wise, slightly mysterious — like a trusted spiritual advisor over tea
- Use oracle cards, tarot, and numerology language ONLY
- NEVER mention QMDJ, Qi Men, astronomical, celestial calculation, or Chinese metaphysics terms
- Korean cultural references welcome but not forced
- NEVER use cosmic/celestial/galaxy language
- NEVER sound like a generic horoscope
- Grounded, embodied wisdom — NOT floaty spiritual cliches
- Max 2200 characters (Instagram limit)

STRUCTURE:
- Line 1: Scroll-stopping hook (this is EVERYTHING)
- 2-4 lines of body content with natural line breaks
- Soft CTA (not salesy) — e.g., "Save this for when you need it" or "Which resonates? Tell me below"
- Leave a line gap before hashtags

HASHTAGS (append these at the end, after a line break):
$hashtags

Output ONLY the final Instagram caption. No explanations, no alternatives.
CAPTION_PROMPT
        ) || true

        if [ -n "$caption" ]; then
            echo "$caption" > "$output_file"
            local char_count
            char_count=$(echo "$caption" | wc -c | tr -d ' ')
            log "  Caption generated for slot $slot_num ($char_count chars)"
            return 0
        fi
    fi

    # Fallback: generate a template caption
    log "  Claude CLI unavailable — generating template caption for slot $slot_num"
    {
        case "$post_type" in
            oracle_card|story_card_reveal|story_oracle_tip)
                echo "Your card for today has arrived."
                echo ""
                echo "Sometimes the universe whispers before it speaks. Today's oracle card is a gentle nudge — pay attention to the patterns unfolding around you."
                echo ""
                echo "What does this card stir in you? Tell me below."
                ;;
            lifestyle|story_lifestyle)
                echo "Between readings, there is this."
                echo ""
                echo "Tea steeping. Morning light through the window. A quiet moment before the world rushes in."
                echo ""
                echo "How are you starting your day?"
                ;;
            spiritual_quote|story_quote)
                echo "The ancients knew: timing is everything."
                echo ""
                echo "The oracle cards remind us: every moment carries its own energy. The wise learn to read the signs and move with the current, not against it."
                echo ""
                echo "Save this for when you need the reminder."
                ;;
            oracle_insight)
                echo "Oracle Energy Reading for $(date -d "$DATE" +%A 2>/dev/null || date -j -f %Y-%m-%d "$DATE" +%A 2>/dev/null || echo "today")"
                echo ""
                echo "Swipe through today's oracle insight. The cards reveal the energy patterns around you — save this post to reference throughout your day."
                ;;
            aesthetic_flatlay|story_aesthetic)
                echo "Jade, smoke, stillness."
                ;;
            reading_scene|jade_reading_reel)
                echo "The cards are already turning."
                echo ""
                echo "Every reading begins before the cards are drawn — in the question you carry, in the energy you bring to the table."
                echo ""
                echo "What question have you been holding?"
                ;;
            subtle_animation)
                echo "Breathe. The oracle is listening."
                ;;
            pick_a_card|story_pick_a_card)
                echo "Pick a card — left, center, or right."
                echo ""
                echo "Trust the first one your eye is drawn to. Your intuition already knows."
                echo ""
                echo "Comment 1, 2, or 3 — I'll reveal the messages in Stories tonight."
                ;;
            behind_scenes|story_behind_scenes)
                echo "Behind the veil."
                echo ""
                echo "People ask what an oracle reading looks like behind the scenes. It's cards, intuition, reflection — and a lot of tea."
                echo ""
                echo "Swipe to see the process."
                ;;
            *)
                echo "The Jade Oracle speaks."
                ;;
        esac

        echo ""
        echo "$hashtags"
    } > "$output_file"

    log "  Template caption saved for slot $slot_num"
    return 0
}

###############################################################################
# Slot Generators — one function per content type
###############################################################################

# --- Slot type: oracle_card (single image) ---
gen_oracle_card() {
    local slot_num="$1"
    local output_img="$OUTPUT_DIR/slot-${slot_num}-oracle_card.png"
    local face_refs=""
    face_refs="$(resolve_face_refs)" || true

    # Check for dedicated oracle card generator
    local card_gen="$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/jade-oracle-card-gen.sh"
    local card_gen_alt="$OPENCLAW_DIR/skills/social-publish/scripts/jade-oracle-card-gen.sh"

    if [ -f "$card_gen" ] && [ "$DRY_RUN" -eq 0 ]; then
        log "  Using jade-oracle-card-gen.sh"
        bash "$card_gen" --date "$DATE" --output "$output_img" >> "$LOG_FILE" 2>&1 && return 0
        log "  Card generator failed, falling back to NanoBanana"
    elif [ -f "$card_gen_alt" ] && [ "$DRY_RUN" -eq 0 ]; then
        log "  Using jade-oracle-card-gen.sh (social-publish)"
        bash "$card_gen_alt" --date "$DATE" --output "$output_img" >> "$LOG_FILE" 2>&1 && return 0
        log "  Card generator failed, falling back to NanoBanana"
    fi

    # Day-specific card themes
    local dow
    dow=$(date -j -f %Y-%m-%d "$DATE" +%u 2>/dev/null || date -d "$DATE" +%u 2>/dev/null || date +%u)
    local card_theme=""
    case "$dow" in
        1) card_theme="The Strategist — a card showing a jade compass on an old wooden desk, ink brushes nearby, warm candlelight, cream parchment background" ;;
        2) card_theme="The Flow — a card showing water flowing over smooth jade stones, golden light, misty, organic forms on cream background" ;;
        3) card_theme="The Pivot — a card showing a crossroads with two jade lanterns, twilight sky, warm amber glow, elegant serif text on cream" ;;
        4) card_theme="The Harvest — a card showing hands cupping jade tea bowl, steam rising, golden coins scattered, warm kitchen light, cream card stock" ;;
        5) card_theme="The Gateway — a card showing an ornate moon gate with jade vines, golden hour light streaming through, burgundy accents on cream" ;;
        6) card_theme="The Mirror — a card showing a jade hand mirror reflecting candlelight, dried flowers, dark wood table, cream and gold palette" ;;
        7) card_theme="The Rest — a card showing a sleeping jade cat curled around an oracle deck, soft moonlight, cozy blanket textures, warm cream tones" ;;
    esac

    local prompt="Instagram-ready oracle card design for The Jade Oracle brand. $card_theme. Style: elegant editorial, warm tones, jade green (#00A86B) and gold (#D4AF37) accents on cream (#F5F0E8) background. Photorealistic card photography — NOT illustration, NOT digital art. Shot on marble surface with soft directional light. 4:5 aspect ratio."

    generate_image "$prompt" "$output_img" "4:5" "$face_refs"
}

# --- Slot type: lifestyle (single image with Jade character) ---
gen_lifestyle() {
    local slot_num="$1"
    local output_img="$OUTPUT_DIR/slot-${slot_num}-lifestyle.png"
    local face_refs=""
    face_refs="$(resolve_face_refs)" || true

    local dow
    dow=$(date -j -f %Y-%m-%d "$DATE" +%u 2>/dev/null || date -d "$DATE" +%u 2>/dev/null || date +%u)
    local scene=""
    case "$dow" in
        1) scene="Jade in a cozy cafe, cream linen top, journaling with matcha latte, morning light streaming through window, warm tones, candid" ;;
        2) scene="Jade at an artisan market, white wrap blouse, examining crystals, golden hour light, authentic street photography feel" ;;
        3) scene="Jade in modern minimalist apartment, sage green tank top, meditating by window, incense smoke, soft morning light" ;;
        4) scene="Jade at a candlelit dinner, black slip dress, jade pendant necklace, warm amber lighting, wine glass, editorial" ;;
        5) scene="Jade on rooftop garden at golden hour, burgundy wrap dress, wind in hair, city skyline soft-focus behind, contemplative" ;;
        6) scene="Jade browsing a bookshop, oatmeal cardigan, holding a metaphysics book, soft window light, warm atmosphere" ;;
        7) scene="Jade in bed, morning light, cream tank top, steaming tea on nightstand, soft smile, natural selfie angle, intimate" ;;
    esac

    local prompt="Authentic iPhone photo of a Korean woman in her early 30s, long dark hair with soft bangs, warm brown eyes, jade pendant necklace. $scene. Shot on iPhone 16 Pro, natural depth of field, candid moment. Photorealistic — NOT AI-looking, NOT illustration. 4:5 ratio."

    generate_image "$prompt" "$output_img" "4:5" "$face_refs"
}

# --- Slot type: spiritual_quote (square image) ---
gen_spiritual_quote() {
    local slot_num="$1"
    local output_img="$OUTPUT_DIR/slot-${slot_num}-spiritual_quote.png"

    # Check for dedicated quote generator
    local quote_gen="$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/jade-quote-gen.sh"
    local quote_gen_alt="$OPENCLAW_DIR/skills/social-publish/scripts/jade-quote-gen.sh"

    if [ -f "$quote_gen" ] && [ "$DRY_RUN" -eq 0 ]; then
        log "  Using jade-quote-gen.sh"
        bash "$quote_gen" --date "$DATE" --output "$output_img" >> "$LOG_FILE" 2>&1 && return 0
        log "  Quote generator failed, falling back to NanoBanana"
    elif [ -f "$quote_gen_alt" ] && [ "$DRY_RUN" -eq 0 ]; then
        log "  Using jade-quote-gen.sh (alt)"
        bash "$quote_gen_alt" --date "$DATE" --output "$output_img" >> "$LOG_FILE" 2>&1 && return 0
        log "  Quote generator failed, falling back to NanoBanana"
    fi

    # Generate a quote image with embedded text
    local dow
    dow=$(date -j -f %Y-%m-%d "$DATE" +%u 2>/dev/null || date -d "$DATE" +%u 2>/dev/null || date +%u)
    local quote_text=""
    case "$dow" in
        1) quote_text="The right door opens at the right time. Your only job is to keep walking. — Ancient Oracle Wisdom" ;;
        2) quote_text="Water does not resist. It flows around every obstacle and still reaches the sea." ;;
        3) quote_text="When the student is ready, the teacher appears. When the student is truly ready, the teacher disappears." ;;
        4) quote_text="Your energy introduces you before you even speak. 气 (Qi) knows no language barrier." ;;
        5) quote_text="Ancient wisdom is not old. It is timeless. The oracle cards have been waiting for your question." ;;
        6) quote_text="The universe is not punishing you. It is redirecting you. Trust the turning of the cards — the oracle always reveals what you need." ;;
        7) quote_text="Rest is not giving up. Rest is gathering 气 for your next move." ;;
    esac

    local prompt="Elegant spiritual quote graphic for Instagram. Clean, minimal design on cream (#F5F0E8) background. Text reads: '$quote_text'. Typography: warm elegant serif, jade green (#00A86B) text with subtle gold (#D4AF37) accent line. Small 'The Jade Oracle' watermark bottom center. Subtle texture — handmade paper feel. Square 1:1 format. NOT cluttered, NOT generic Canva template."

    generate_image "$prompt" "$output_img" "1:1" ""
}

# --- Slot type: qmdj_carousel (5 slides) ---
gen_qmdj_carousel() {
    local slot_num="$1"
    local slide_count
    slide_count="$(json_get_slot "$slot_num" "slides")"
    slide_count="${slide_count:-5}"

    log "  Generating $slide_count carousel slides for oracle insight"

    local i=1
    while [ "$i" -le "$slide_count" ]; do
        local output_img="$OUTPUT_DIR/slot-${slot_num}-qmdj_carousel-${i}.png"

        local slide_content=""
        case "$i" in
            1) slide_content="Cover slide: Bold headline 'Your Oracle Energy Reading for $(date -j -f %Y-%m-%d "$DATE" +%A 2>/dev/null || date -d "$DATE" +%A 2>/dev/null || echo "Today")' with jade green background, gold accents, The Jade Oracle branding. Swipe arrow hint at bottom." ;;
            2) slide_content="Slide 2: 'Today's Oracle Spread' — diagram showing today's oracle card energy. Clean infographic style, jade green icons on cream background, educational layout with brief explanatory text." ;;
            3) slide_content="Slide 3: 'Key Energies Today' — three energy highlights with icons. Warm editorial style, jade green and burgundy color blocks on cream. Clear readable serif typography." ;;
            4) slide_content="Slide 4: 'Your Action Guide' — practical advice based on today's oracle reading. Three actionable tips with checkmark icons. Clean card layout, warm tones." ;;
            5) slide_content="Slide 5: CTA slide — 'Want your personal oracle reading?' with link-in-bio prompt. Jade green background with gold text. @the_jade_oracle handle. Warm, inviting design." ;;
        esac

        local prompt="Instagram carousel slide ($i of $slide_count) for The Jade Oracle oracle insight post. $slide_content Style: editorial, warm, educational infographic — NOT generic, NOT cluttered. Colors: jade green (#00A86B), cream (#F5F0E8), burgundy (#722F37), gold (#D4AF37). 4:5 aspect ratio."

        generate_image "$prompt" "$output_img" "4:5" ""
        i=$((i + 1))
    done
}

# --- Slot type: aesthetic_flatlay (single image) ---
gen_aesthetic_flatlay() {
    local slot_num="$1"
    local output_img="$OUTPUT_DIR/slot-${slot_num}-aesthetic_flatlay.png"

    local dow
    dow=$(date -j -f %Y-%m-%d "$DATE" +%u 2>/dev/null || date -d "$DATE" +%u 2>/dev/null || date +%u)
    local scene=""
    case "$dow" in
        1) scene="Oracle cards fanned on dark wood desk, jade stone paperweight, burning incense stick, morning window light, shadow play" ;;
        2) scene="Jade bracelet on marble tray next to matcha in a ceramic cup, dried eucalyptus sprig, cream linen underneath, overhead shot" ;;
        3) scene="Three crystals (clear quartz, jade, amethyst) arranged on cream fabric with candle flame reflection, close-up macro feel" ;;
        4) scene="Old oracle reference book open to a chart page, reading glasses nearby, tea cup half empty, warm desk lamp light, scholarly" ;;
        5) scene="Gold-rimmed jade bowl filled with oracle card collection, burgundy velvet underneath, scattered dried rose petals, editorial" ;;
        6) scene="Incense holder with curling smoke, jade pendant necklace coiled beside it, cream marble surface, golden hour side-light" ;;
        7) scene="Sunday reset spread: journal, jade gua sha, herbal tea, dried flowers, warm bedside lamp, cozy textiles, overhead angle" ;;
    esac

    local prompt="Professional flatlay product photography for Instagram. $scene. Style: Korean editorial aesthetic, warm tones, natural light with soft directional shadows. Colors lean jade green, cream, warm wood, gold accents. Shot overhead or 45-degree angle. Photorealistic — NOT illustration, NOT 3D render. 4:5 aspect ratio."

    generate_image "$prompt" "$output_img" "4:5" ""
}

# --- Slot type: reading_scene (single image with Jade) ---
gen_reading_scene() {
    local slot_num="$1"
    local output_img="$OUTPUT_DIR/slot-${slot_num}-reading_scene.png"
    local face_refs=""
    face_refs="$(resolve_face_refs)" || true

    local dow
    dow=$(date -j -f %Y-%m-%d "$DATE" +%u 2>/dev/null || date -d "$DATE" +%u 2>/dev/null || date +%u)
    local scene=""
    case "$dow" in
        1) scene="Jade seated at dark wood table, spreading oracle cards in arc formation, single candle lit, concentrated expression, moody warm lighting" ;;
        2) scene="Jade's hands close-up, turning over a jade oracle card, rings visible, candlelight casting warm glow on cream table surface" ;;
        3) scene="Jade studying oracle card layouts on paper, pen in hand, reference books stacked, deep in thought, warm desk lamp, evening mood" ;;
        4) scene="Jade mid-reading, looking directly at camera as if reading the viewer, oracle cards between them, intimate warm lighting, powerful" ;;
        5) scene="Jade cleansing oracle deck with incense smoke, eyes closed, peaceful expression, soft backlight, burgundy shawl draped over shoulders" ;;
        6) scene="Over-the-shoulder view of Jade arranging crystals around oracle cards on velvet cloth, warm tones, ritualistic, beautiful composition" ;;
        7) scene="Jade writing in journal after a reading, cards still laid out, tea beside her, quiet contemplative moment, warm evening light" ;;
    esac

    local prompt="Authentic editorial photo of a Korean woman in her early 30s, long dark hair, warm brown eyes, jade pendant necklace. $scene. Photorealistic iPhone-quality photography, natural depth of field. NOT staged-looking, NOT stock photo energy. Warm, intimate, editorial. 4:5 aspect ratio."

    generate_image "$prompt" "$output_img" "4:5" "$face_refs"
}

# --- Slot type: subtle_animation (reel) ---
gen_subtle_animation() {
    local slot_num="$1"
    local output_vid="$OUTPUT_DIR/slot-${slot_num}-subtle_animation.mp4"

    # Check for dedicated vibe reel generator
    local reel_gen="$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/jade-vibe-reel.sh"
    local reel_gen_alt="$OPENCLAW_DIR/skills/social-publish/scripts/jade-vibe-reel.sh"

    if [ -f "$reel_gen" ] && [ "$DRY_RUN" -eq 0 ]; then
        log "  Using jade-vibe-reel.sh"
        bash "$reel_gen" --date "$DATE" --output "$output_vid" >> "$LOG_FILE" 2>&1 && return 0
        log "  Reel generator failed, falling back to prompt file"
    elif [ -f "$reel_gen_alt" ] && [ "$DRY_RUN" -eq 0 ]; then
        log "  Using jade-vibe-reel.sh (alt)"
        bash "$reel_gen_alt" --date "$DATE" --output "$output_vid" >> "$LOG_FILE" 2>&1 && return 0
        log "  Reel generator failed, falling back to prompt file"
    fi

    # Fallback: generate a video prompt file + a still frame for reference
    local dow
    dow=$(date -j -f %Y-%m-%d "$DATE" +%u 2>/dev/null || date -d "$DATE" +%u 2>/dev/null || date +%u)
    local scene=""
    case "$dow" in
        1) scene="Candle flame flickering in slow motion, jade pendant swaying gently beside it, warm dark background, ASMR-like calm" ;;
        2) scene="Incense smoke rising and curling in slow motion, jade stone in foreground, warm amber lighting, meditative" ;;
        3) scene="Oracle cards being slowly shuffled by elegant hands, close-up, candlelight, rhythmic motion, satisfying" ;;
        4) scene="Rain on a window with warm room behind, jade oracle setup visible on desk, cozy lo-fi energy, static camera" ;;
        5) scene="Tea being poured into jade-colored ceramic cup in slow motion, steam rising, warm tones, satisfying ASMR" ;;
        6) scene="Jade's hands slowly placing crystals around an oracle card, overhead shot, warm candlelight, ritualistic, beautiful" ;;
        7) scene="Time-lapse of candle burning down beside oracle card spread, golden hour light shifting, peaceful, meditative" ;;
    esac

    # Save as video prompt + generate a still frame via NanoBanana
    local prompt_file="$OUTPUT_DIR/slot-${slot_num}-subtle_animation.video-prompt.txt"
    {
        echo "# Video Generation Prompt — Jade Oracle Vibe Reel"
        echo "# Duration: 15 seconds"
        echo "# Ratio: 9:16 (vertical reel)"
        echo "# Music: lo-fi / ambient / meditation beats"
        echo "# Date: $DATE"
        echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        echo "SCENE: $scene"
        echo ""
        echo "DIRECTION:"
        echo "- Slow, meditative camera movement or static shot"
        echo "- Warm color grading — jade green, cream, gold tones"
        echo "- Subtle text overlay: 'The Jade Oracle' in elegant serif"
        echo "- Loop-friendly (end frame matches start frame)"
        echo ""
        echo "SUGGESTED TOOLS: Kling 3.0, Wan 2.6, or video-gen.sh"
    } > "$prompt_file"

    log "  Video prompt saved: $(basename "$prompt_file")"

    # Also generate a still frame reference
    local still_img="$OUTPUT_DIR/slot-${slot_num}-subtle_animation-still.png"
    local still_prompt="Cinematic still frame for Instagram Reel. $scene. Vertical 9:16 aspect ratio. Warm tones, jade green accents, photorealistic. NOT illustration."
    generate_image "$still_prompt" "$still_img" "9:16" ""
}

# --- Slot type: pick_a_card (carousel, 3 slides) ---
gen_pick_a_card() {
    local slot_num="$1"
    local slide_count
    slide_count="$(json_get_slot "$slot_num" "slides")"
    slide_count="${slide_count:-3}"

    log "  Generating $slide_count carousel slides for pick-a-card"

    # Check for dedicated card generator
    local card_gen="$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/jade-oracle-card-gen.sh"
    local card_gen_alt="$OPENCLAW_DIR/skills/social-publish/scripts/jade-oracle-card-gen.sh"
    local use_card_gen=""
    if [ -f "$card_gen" ] && [ "$DRY_RUN" -eq 0 ]; then
        use_card_gen="$card_gen"
    elif [ -f "$card_gen_alt" ] && [ "$DRY_RUN" -eq 0 ]; then
        use_card_gen="$card_gen_alt"
    fi

    local i=1
    while [ "$i" -le "$slide_count" ]; do
        local output_img="$OUTPUT_DIR/slot-${slot_num}-pick_a_card-${i}.png"
        local card_label=""
        case "$i" in
            1) card_label="Card 1 (Left)" ;;
            2) card_label="Card 2 (Center)" ;;
            3) card_label="Card 3 (Right)" ;;
        esac

        if [ -n "$use_card_gen" ]; then
            log "  Using jade-oracle-card-gen.sh for $card_label"
            bash "$use_card_gen" --date "$DATE" --variant "$i" --output "$output_img" >> "$LOG_FILE" 2>&1 || {
                log "  Card generator failed for card $i, falling back to NanoBanana"
                use_card_gen=""
            }
        fi

        # NanoBanana fallback
        if [ ! -f "$output_img" ] || [ -z "$use_card_gen" ]; then
            local card_color=""
            case "$i" in
                1) card_color="jade green (#00A86B) backing" ;;
                2) card_color="burgundy (#722F37) backing" ;;
                3) card_color="gold (#D4AF37) backing" ;;
            esac

            local prompt="Instagram pick-a-card post: a beautifully styled oracle card face-down with $card_color, elegant swirl pattern, '$card_label' text in serif font at bottom. The card sits on dark wood table with soft candlelight. Number '$i' subtly embossed. Editorial product photography style. Warm tones, photorealistic. 4:5 aspect ratio."

            generate_image "$prompt" "$output_img" "4:5" ""
        fi

        i=$((i + 1))
    done
}

# --- Slot type: behind_scenes (carousel, 5 slides) ---
gen_behind_scenes() {
    local slot_num="$1"
    local slide_count
    slide_count="$(json_get_slot "$slot_num" "slides")"
    slide_count="${slide_count:-5}"
    local face_refs=""
    face_refs="$(resolve_face_refs)" || true

    log "  Generating $slide_count carousel slides for behind-the-scenes"

    local i=1
    while [ "$i" -le "$slide_count" ]; do
        local output_img="$OUTPUT_DIR/slot-${slot_num}-behind_scenes-${i}.png"

        local scene=""
        case "$i" in
            1) scene="Jade's workspace from the doorway — desk with oracle cards laid out, laptop with oracle cards spread, warm lamp, tea, cozy evening setup. 'Behind the veil' text overlay." ;;
            2) scene="Close-up of Jade's hands writing in a leather journal, oracle cards spread nearby, handwritten notes about card interpretations, warm candlelight." ;;
            3) scene="Jade's phone showing an Instagram DM conversation (blurred names) — she's replying to a client, warm smile reflected in screen, casual home setting." ;;
            4) scene="A messy-beautiful desk scene: oracle reading journals stacked, multiple tea cups, crystals, sticky notes with card meanings, real working space energy." ;;
            5) scene="Jade at her desk looking at camera with warm smile, slightly tired but fulfilled end-of-day energy, warm lamp light, 'Thank you for being here' mood." ;;
        esac

        local prompt="Authentic behind-the-scenes Instagram photo for The Jade Oracle. $scene. Style: candid, warm, relatable — like a friend showing you their world. Photorealistic, iPhone-quality. NOT staged, NOT polished editorial. 4:5 aspect ratio."

        local ref_arg=""
        # Use face refs for slides with Jade character
        case "$i" in
            1|3|5) ref_arg="$face_refs" ;;
            *) ref_arg="" ;;
        esac

        generate_image "$prompt" "$output_img" "4:5" "$ref_arg"
        i=$((i + 1))
    done
}

###############################################################################
# Slot Router — dispatches to correct generator based on type
###############################################################################

generate_slot() {
    local slot_num="$1"

    local post_type=""
    post_type="$(json_get_slot "$slot_num" "type")"
    local caption_style=""
    caption_style="$(json_get_slot "$slot_num" "caption_style")"
    local hashtag_set=""
    hashtag_set="$(json_get_slot "$slot_num" "hashtag_set")"
    local post_format=""
    post_format="$(json_get_slot "$slot_num" "format")"
    local time_myt=""
    time_myt="$(json_get_slot "$slot_num" "time_myt")"
    local purpose=""
    purpose="$(json_get_slot "$slot_num" "purpose")"

    log "Slot $slot_num | $post_type ($post_format) | $time_myt MYT | $purpose"

    # Generate image(s)
    # Map schedule types (story_* prefixed) to generator functions
    case "$post_type" in
        oracle_card|story_card_reveal)
            gen_oracle_card "$slot_num"
            ;;
        lifestyle|story_lifestyle)
            gen_lifestyle "$slot_num"
            ;;
        spiritual_quote|story_quote)
            gen_spiritual_quote "$slot_num"
            ;;
        oracle_insight)
            gen_qmdj_carousel "$slot_num"
            ;;
        aesthetic_flatlay|story_aesthetic)
            gen_aesthetic_flatlay "$slot_num"
            ;;
        reading_scene|jade_reading_reel)
            gen_reading_scene "$slot_num"
            ;;
        subtle_animation)
            gen_subtle_animation "$slot_num"
            ;;
        pick_a_card|story_pick_a_card)
            gen_pick_a_card "$slot_num"
            ;;
        behind_scenes|story_behind_scenes)
            gen_behind_scenes "$slot_num"
            ;;
        story_oracle_tip)
            # Oracle tip stories use the oracle card generator with simpler prompts
            gen_oracle_card "$slot_num"
            ;;
        *)
            err "Unknown post type: $post_type for slot $slot_num"
            return 1
            ;;
    esac

    # Generate caption
    local extra_context="Format: $post_format. Purpose: $purpose. Posting time: $time_myt MYT."
    generate_caption "$slot_num" "$post_type" "$caption_style" "$hashtag_set" "$extra_context"

    log "  Slot $slot_num complete"
}

###############################################################################
# Summary Report
###############################################################################

print_summary() {
    log ""
    log "========================================="
    log "GENERATION SUMMARY — $DATE"
    log "========================================="

    local total_files
    total_files=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    local image_count
    image_count=$(find "$OUTPUT_DIR" -name "*.png" -type f 2>/dev/null | wc -l | tr -d ' ')
    local caption_count
    caption_count=$(find "$OUTPUT_DIR" -name "*-caption.txt" -type f 2>/dev/null | wc -l | tr -d ' ')
    local prompt_count
    prompt_count=$(find "$OUTPUT_DIR" -name "*.prompt.txt" -type f 2>/dev/null | wc -l | tr -d ' ')
    local video_prompts
    video_prompts=$(find "$OUTPUT_DIR" -name "*.video-prompt.txt" -type f 2>/dev/null | wc -l | tr -d ' ')

    log "Output:    $OUTPUT_DIR"
    log "Files:     $total_files total"
    log "Images:    $image_count generated"
    log "Captions:  $caption_count generated"
    log "Prompts:   $prompt_count (for manual generation)"
    log "Video:     $video_prompts video prompts"
    log ""

    # Per-slot status
    local s=1
    local slot_total
    slot_total="$(json_slot_count)"
    while [ "$s" -le "$slot_total" ]; do
        local stype=""
        stype="$(json_get_slot "$s" "type")"
        local stime=""
        stime="$(json_get_slot "$s" "time_myt")"
        local has_caption="no"
        [ -f "$OUTPUT_DIR/slot-${s}-caption.txt" ] && has_caption="yes"
        local asset_count
        asset_count=$(find "$OUTPUT_DIR" -name "slot-${s}-*" -not -name "*caption*" -not -name "*.prompt.txt" -not -name "*.video-prompt.txt" -type f 2>/dev/null | wc -l | tr -d ' ')

        local status_icon="READY"
        if [ "$asset_count" -eq 0 ] && [ "$has_caption" = "no" ]; then
            status_icon="MISSING"
        elif [ "$asset_count" -eq 0 ]; then
            status_icon="CAPTION ONLY"
        fi

        log "  Slot $s ($stime) $stype — $status_icon (assets:$asset_count caption:$has_caption)"
        s=$((s + 1))
    done

    log "========================================="

    # Save manifest for downstream tools
    "$PYTHON3" << PYEOF
import json, os, glob
from datetime import datetime

output_dir = "$OUTPUT_DIR"
date_str = "$DATE"

manifest = {
    "date": date_str,
    "generated_at": datetime.utcnow().isoformat() + "Z",
    "output_dir": output_dir,
    "dry_run": $DRY_RUN == 1,
    "slots": []
}

for s in range(1, 10):
    slot_info = {"slot": s, "assets": [], "caption": None}

    caption_file = os.path.join(output_dir, f"slot-{s}-caption.txt")
    if os.path.exists(caption_file):
        slot_info["caption"] = caption_file

    for f in sorted(glob.glob(os.path.join(output_dir, f"slot-{s}-*"))):
        basename = os.path.basename(f)
        if "caption" not in basename and "prompt" not in basename:
            slot_info["assets"].append(f)

    manifest["slots"].append(slot_info)

manifest_path = os.path.join(output_dir, "manifest.json")
with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)

print(f"Manifest saved: {manifest_path}")
PYEOF
}

###############################################################################
# Main
###############################################################################

main() {
    log "========================================="
    log "JADE ORACLE — 9-POST DAILY GENERATOR"
    log "Date: $DATE"
    [ "$DRY_RUN" -eq 1 ] && log "MODE: DRY RUN"
    [ "$SINGLE_SLOT" -ne 0 ] && log "SINGLE SLOT: $SINGLE_SLOT"
    log "Output: $OUTPUT_DIR"
    log "========================================="

    # Validate schedule file
    if [ ! -f "$SCHEDULE_FILE" ]; then
        err "Schedule file not found: $SCHEDULE_FILE"
        err "Expected at: skills/social-publish/data/jade-9post-schedule.json"
        exit 1
    fi

    local slot_total
    slot_total="$(json_slot_count)"
    log "Schedule loaded: $slot_total slots from $(basename "$SCHEDULE_FILE")"

    room_msg "9-post generator started for $DATE ($([ "$DRY_RUN" -eq 1 ] && echo 'dry-run' || echo 'live'), slots: $([ "$SINGLE_SLOT" -ne 0 ] && echo "$SINGLE_SLOT" || echo "1-$slot_total"))"

    # Track results
    local success_count=0
    local fail_count=0

    if [ "$SINGLE_SLOT" -ne 0 ]; then
        # Single slot mode
        if [ "$SINGLE_SLOT" -lt 1 ] || [ "$SINGLE_SLOT" -gt "$slot_total" ]; then
            err "Invalid slot number: $SINGLE_SLOT (must be 1-$slot_total)"
            exit 1
        fi

        if generate_slot "$SINGLE_SLOT"; then
            success_count=1
        else
            fail_count=1
            err "Slot $SINGLE_SLOT failed"
        fi
    else
        # All slots
        local s=1
        while [ "$s" -le "$slot_total" ]; do
            log ""
            log "--- Slot $s of $slot_total ---"

            if generate_slot "$s"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
                err "Slot $s failed — continuing with remaining slots"
            fi

            s=$((s + 1))
        done
    fi

    # Print summary
    print_summary

    log ""
    log "Results: $success_count succeeded, $fail_count failed"

    room_msg "9-post generation complete: $success_count/$slot_total slots ready for $DATE"

    if [ "$fail_count" -gt 0 ]; then
        log "Some slots failed — check log: $LOG_FILE"
        exit 1
    fi

    log "All done. Content ready at: $OUTPUT_DIR"
}

main "$@"
