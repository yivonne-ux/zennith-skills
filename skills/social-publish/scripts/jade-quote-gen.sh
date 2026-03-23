#!/usr/bin/env bash
# jade-quote-gen.sh — Jade Oracle Spiritual Quote Post Generator
#
# Generates styled quote images (1080x1080) + captions for Instagram.
# Uses Claude CLI for quote generation and Pillow for image compositing.
#
# Usage:
#   bash jade-quote-gen.sh --type vulnerability
#   bash jade-quote-gen.sh --type wisdom
#   bash jade-quote-gen.sh --type empowerment
#   bash jade-quote-gen.sh --type qmdj
#   bash jade-quote-gen.sh --type relatable
#   bash jade-quote-gen.sh --random
#   bash jade-quote-gen.sh --random --dry-run
#
# macOS Bash 3.2 compatible.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
DATE="$(date +%Y-%m-%d)"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
CLAUDE_CLI="$(command -v claude 2>/dev/null || echo "")"

# NanoBanana paths
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

OUTPUT_DIR="$OPENCLAW_DIR/workspace/data/images/jade-oracle/quote-posts"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"

# Defaults
QUOTE_TYPE=""
DRY_RUN=0

# ─────────────────────────────────────────────────────────────────────────────
# Quote type definitions
# ─────────────────────────────────────────────────────────────────────────────

VALID_TYPES="vulnerability wisdom empowerment qmdj relatable"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

log() {
    echo "[jade-quote-gen $(date +%H:%M:%S)] $1"
}

err() {
    echo "[jade-quote-gen $(date +%H:%M:%S)] ERROR: $1" >&2
}

die() {
    err "$1"
    exit 1
}

# Pick random type
random_type() {
    local types_arr
    # macOS Bash 3.2 compatible array creation
    set -- $VALID_TYPES
    local count=$#
    local rand_bytes
    rand_bytes=$(od -An -tu4 -N4 /dev/urandom 2>/dev/null | tr -d ' ')
    local pick=$(( (rand_bytes % count) + 1 ))
    eval "echo \$$pick"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate quote text via Claude CLI
# ─────────────────────────────────────────────────────────────────────────────

generate_quote_text() {
    local qtype="$1"
    local quote=""

    # Build type-specific prompt guidance
    local type_guidance=""
    case "$qtype" in
        vulnerability)
            type_guidance="Write a vulnerability-style quote. The kind that makes someone screenshot it and send to their best friend at 2am. Raw, honest, about the messy parts of healing. Examples of this energy: 'Nobody tells you that healing isn't linear. Some days you're the phoenix. Most days you're still the ash.' / 'The bravest thing I did this year was admit I didn't have it figured out.' Keep it under 40 words."
            ;;
        wisdom)
            type_guidance="Write a wisdom quote that bridges ancient Chinese philosophy with modern life. Start with or reference a Chinese proverb, Yi Jing principle, or Daoist concept, then add Jade's warm modern interpretation. Example energy: 'The ancient masters said: water overcomes rock not by force, but by persistence. Your softness isn't weakness. It's your oldest strategy.' Keep it under 50 words."
            ;;
        empowerment)
            type_guidance="Write an empowerment quote rooted in QMDJ/Chinese metaphysics. The vibe: your chart already knows the answer, you just need to trust it. Example energy: 'Your chart already knows. Trust it.' / 'You were born in the hour of the Metal Tiger. You were never meant to play small.' / 'The stars didn't align for you — you aligned with them.' Keep it under 35 words."
            ;;
        qmdj)
            type_guidance="Write a QMDJ-specific educational-yet-mystical quote. Reference palaces, doors, stars, or stems in a way that intrigues non-practitioners. Example energy: 'Most people have 8 palaces. Most never look at palace #4. That's where your blind spot lives.' / 'When the Open Door meets the Heavenly Heart star, even the impossible has a window.' Keep it under 45 words."
            ;;
        relatable)
            type_guidance="Write a relatable life quote for women in their late 20s-30s navigating quarter-life crises, career pivots, breakups, and self-discovery. Grounded, real, slightly spiritual. Example energy: 'Your 30s feel like starting over and nobody warned you' / 'Plot twist: the universe wasn't punishing you. It was redirecting you.' / 'You're not behind. You're on a different timeline.' Keep it under 30 words."
            ;;
    esac

    if [ "$DRY_RUN" -eq 1 ]; then
        # Return a placeholder quote for dry run
        case "$qtype" in
            vulnerability) quote="Nobody tells you that healing looks like starting over. Again. And again. And calling that progress." ;;
            wisdom) quote="The Yi Jing teaches: after the storm, the mountain remains. You are the mountain. You were always the mountain." ;;
            empowerment) quote="Your chart already mapped this moment. The question was never if you could — it was when you'd finally believe it." ;;
            qmdj) quote="Palace 6 holds the Open Door. When it activates, opportunities don't knock — they arrive uninvited." ;;
            relatable) quote="Your 30s feel like starting over and nobody gave you the manual for this part." ;;
        esac
        echo "$quote"
        return 0
    fi

    if [ -n "$CLAUDE_CLI" ]; then
        log "Generating $qtype quote via Claude CLI..."
        local _qprompt
        _qprompt=$(mktemp)
        cat > "$_qprompt" << QUOTE_PROMPT
You are Jade, The Jade Oracle — a warm Korean-inspired QMDJ practitioner and spiritual guide.

Generate ONE original quote for an Instagram quote post.

Quote type: ${qtype}

${type_guidance}

Rules:
- Output ONLY the quote text. Nothing else. No attribution, no quotation marks.
- Must be original — do NOT copy existing quotes
- Voice: warm, wise, grounded, slightly poetic
- Should feel like something you would screenshot and save
- No hashtags, no @mentions, no emojis
- Shorter is better — punchy and memorable

QUOTE_PROMPT
        quote=$(cat "$_qprompt" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
        rm -f "$_qprompt"
    fi

    # Fallback quotes if Claude fails
    if [ -z "$quote" ]; then
        log "Claude CLI not available — using template quote"
        case "$qtype" in
            vulnerability) quote="Nobody tells you that healing looks like starting over. Again. And again. And calling that progress." ;;
            wisdom) quote="The ancient masters knew: the river reaches the sea not by rushing, but by being willing to go around. Your detour is not a delay." ;;
            empowerment) quote="Your birth chart mapped the fire in you before you ever learned to doubt it. Trust what was written." ;;
            qmdj) quote="Eight palaces. Eight doors. Sixty-four possibilities. And the one that matters is the one you have the courage to walk through." ;;
            relatable) quote="Your 30s feel like unlearning everything your 20s taught you. That's not failure. That's the curriculum." ;;
        esac
    fi

    # Clean up: strip leading/trailing quotes and whitespace
    quote="$(echo "$quote" | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//;s/^[[:space:]]*//;s/[[:space:]]*$//')"

    echo "$quote"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate NanoBanana background prompt
# ─────────────────────────────────────────────────────────────────────────────

generate_bg_prompt() {
    local qtype="$1"

    local scene=""
    case "$qtype" in
        vulnerability)
            scene="soft morning light through sheer linen curtains, a rumpled cream bedsheet, a single steaming cup of tea on a wooden tray"
            ;;
        wisdom)
            scene="an ancient weathered stone surface with moss growing in the cracks, warm golden sunlight casting long shadows, a single dried ginkgo leaf"
            ;;
        empowerment)
            scene="a clean marble tabletop with morning golden light, a jade stone and gold ring placed casually, fresh eucalyptus sprig"
            ;;
        qmdj)
            scene="rice paper with faint ink brushstrokes visible, a jade compass sitting on top, warm candlelight, soft shadows on cream background"
            ;;
        relatable)
            scene="a cozy window seat with cream cushions, rain on the glass outside, a half-read book spine-up, warm afternoon light"
            ;;
    esac

    cat << BG_PROMPT_EOF
Soft, warm background for an Instagram quote post. Minimal — space for text overlay.

Scene: ${scene}.

Style:
- Korean-inspired lifestyle photography
- Color palette: cream (#F5F0E8), sage (#8FA882), warm gold (#D4AF37) accents
- Very soft depth of field — background should be slightly blurred
- Warm natural lighting, NOT flat or clinical
- Generous negative space in the center (for text overlay)
- NOT busy, NOT cluttered — minimal and breathable
- Think: Kinfolk magazine meets Korean cafe aesthetic
- 1:1 aspect ratio (1080x1080 Instagram square)
- Soft, muted, editorial quality
BG_PROMPT_EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate quote image via Pillow (1080x1080)
# ─────────────────────────────────────────────────────────────────────────────

generate_quote_image() {
    local quote="$1"
    local qtype="$2"
    local output_file="$3"
    local bg_image="${4:-}"

    log "Generating quote image (1080x1080) via Pillow..."

    "$PYTHON3" << PYEOF
import sys
import os
import textwrap

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("ERROR: Pillow not installed. Run: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)

# ── Config ──
WIDTH = 1080
HEIGHT = 1080
BG_COLOR = (245, 240, 232)       # #F5F0E8 cream
TEXT_COLOR = (26, 26, 26)         # #1A1A1A warm black
ACCENT_COLOR = (0, 168, 107)     # #00A86B jade green
WATERMARK_COLOR = (26, 26, 26, 100)  # semi-transparent

QUOTE = """$quote"""
QTYPE = "$qtype"
OUTPUT = "$output_file"
BG_IMG = "$bg_image"

# ── Find system serif font ──
def find_font(size, bold=False):
    """Find the best available serif font on macOS."""
    candidates = []
    if bold:
        candidates = [
            "/Library/Fonts/Cormorant-Bold.ttf",
            "/Library/Fonts/Cormorant-SemiBold.ttf",
            "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
            "/System/Library/Fonts/Supplemental/Palatino Bold.ttc",
            "/System/Library/Fonts/Supplemental/Baskerville.ttc",
            "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
            "/Library/Fonts/Georgia Bold.ttf",
        ]
    else:
        candidates = [
            "/Library/Fonts/Cormorant-Regular.ttf",
            "/Library/Fonts/Cormorant-Medium.ttf",
            "/System/Library/Fonts/Supplemental/Georgia.ttf",
            "/System/Library/Fonts/Supplemental/Palatino.ttc",
            "/System/Library/Fonts/Supplemental/Baskerville.ttc",
            "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
            "/Library/Fonts/Georgia.ttf",
        ]

    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue

    # Last resort: default font
    try:
        return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size)
    except Exception:
        return ImageFont.load_default()

# ── Create base image ──
if BG_IMG and os.path.exists(BG_IMG):
    img = Image.open(BG_IMG).convert("RGBA")
    img = img.resize((WIDTH, HEIGHT), Image.LANCZOS)
    # Add semi-transparent cream overlay for text readability
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (245, 240, 232, 180))
    img = Image.alpha_composite(img, overlay)
    img = img.convert("RGB")
else:
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)

draw = ImageDraw.Draw(img)

# ── Layout constants ──
MARGIN_X = 120
CONTENT_WIDTH = WIDTH - (MARGIN_X * 2)
ACCENT_LINE_WIDTH = 60
ACCENT_LINE_THICKNESS = 2

# ── Load fonts ──
# Adaptive font size based on quote length
quote_len = len(QUOTE)
if quote_len < 60:
    font_size = 48
elif quote_len < 120:
    font_size = 42
elif quote_len < 200:
    font_size = 36
else:
    font_size = 30

font_quote = find_font(font_size)
font_watermark = find_font(18)
font_type_label = find_font(14)

# ── Word-wrap the quote ──
# Calculate approximate chars per line based on font size
chars_per_line = int(CONTENT_WIDTH / (font_size * 0.55))
wrapped_lines = textwrap.wrap(QUOTE.strip(), width=chars_per_line)

# ── Calculate text block height ──
line_spacing = int(font_size * 1.6)
text_block_height = len(wrapped_lines) * line_spacing

# ── Calculate vertical centering ──
# Layout: top_accent_line -- quote_text -- bottom_accent_line -- watermark
accent_gap = 40  # gap between accent line and text
total_content_height = ACCENT_LINE_THICKNESS + accent_gap + text_block_height + accent_gap + ACCENT_LINE_THICKNESS
start_y = (HEIGHT - total_content_height) // 2

# ── Draw top accent line ──
top_line_y = start_y
accent_line_x_start = (WIDTH - ACCENT_LINE_WIDTH) // 2
accent_line_x_end = (WIDTH + ACCENT_LINE_WIDTH) // 2
draw.line(
    [(accent_line_x_start, top_line_y), (accent_line_x_end, top_line_y)],
    fill=ACCENT_COLOR,
    width=ACCENT_LINE_THICKNESS
)

# ── Draw quote text (centered) ──
text_start_y = top_line_y + ACCENT_LINE_THICKNESS + accent_gap
for i, line in enumerate(wrapped_lines):
    line_y = text_start_y + (i * line_spacing)
    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), line, font=font_quote)
    text_w = bbox[2] - bbox[0]
    text_x = (WIDTH - text_w) // 2
    draw.text((text_x, line_y), line, fill=TEXT_COLOR, font=font_quote)

# ── Draw bottom accent line ──
bottom_line_y = text_start_y + text_block_height + accent_gap
draw.line(
    [(accent_line_x_start, bottom_line_y), (accent_line_x_end, bottom_line_y)],
    fill=ACCENT_COLOR,
    width=ACCENT_LINE_THICKNESS
)

# ── Draw watermark ──
watermark_text = "@the_jade_oracle"
wm_bbox = draw.textbbox((0, 0), watermark_text, font=font_watermark)
wm_w = wm_bbox[2] - wm_bbox[0]
wm_x = (WIDTH - wm_w) // 2
wm_y = HEIGHT - 80
draw.text((wm_x, wm_y), watermark_text, fill=(26, 26, 26, 180), font=font_watermark)

# ── Draw type label (subtle, top) ──
type_labels = {
    "vulnerability": "on vulnerability",
    "wisdom": "ancient wisdom",
    "empowerment": "empowerment",
    "qmdj": "qi men dun jia",
    "relatable": "real talk",
}
type_label = type_labels.get(QTYPE, QTYPE)
tl_bbox = draw.textbbox((0, 0), type_label, font=font_type_label)
tl_w = tl_bbox[2] - tl_bbox[0]
tl_x = (WIDTH - tl_w) // 2
tl_y = 60
draw.text((tl_x, tl_y), type_label.upper(), fill=(160, 155, 145), font=font_type_label)

# ── Save ──
os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
img.save(OUTPUT, "PNG", quality=95)
print(f"Quote image saved: {OUTPUT}")
print(f"  Size: {WIDTH}x{HEIGHT}")
print(f"  Quote length: {quote_len} chars, {len(wrapped_lines)} lines")
print(f"  Font size: {font_size}px")
PYEOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate caption for quote post
# ─────────────────────────────────────────────────────────────────────────────

generate_caption() {
    local quote="$1"
    local qtype="$2"
    local caption_file="$3"
    local caption=""

    if [ "$DRY_RUN" -eq 1 ]; then
        caption="[DRY RUN] Caption for $qtype quote: \"$quote\""
        echo "$caption" > "$caption_file"
        log "[DRY RUN] Caption saved: $caption_file"
        return 0
    fi

    if [ -n "$CLAUDE_CLI" ]; then
        log "Generating caption via Claude CLI..."
        local _cprompt
        _cprompt=$(mktemp)
        cat > "$_cprompt" << CAP_PROMPT
You are Jade (@the_jade_oracle), a warm Korean-inspired QMDJ oracle on Instagram.

Write an Instagram caption to accompany this quote post.

Quote: "${quote}"
Quote type: ${qtype}

Rules:
- Start with the quote itself (it is on the image, but repeat it for accessibility)
- Add 2-3 sentences of personal reflection expanding on the quote
- Voice: warm, wise, conversational — like texting your spiritually-aware best friend
- End with a question that invites comments (e.g., "Which part of this hit different?")
- Soft CTA: "Save this for the days you need it" or "Share with someone who needs to hear this"
- 15-20 hashtags at the end
- Max 1500 characters total
- No emoji overload — max 3-4

Output ONLY the final Instagram caption.
CAP_PROMPT
        caption=$(cat "$_cprompt" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
        rm -f "$_cprompt"
    fi

    # Fallback caption
    if [ -z "$caption" ]; then
        log "Claude CLI not available — generating template caption"
        caption="\"${quote}\"

Some truths don't need explaining. They just need to be said out loud.

Which part of this hit different for you? Tell me in the comments.

Save this for the days you need the reminder.

#jadeoracle #qmdj #spiritualawakening #oraclecards #奇门遁甲 #qimendunjia #healingjourney #selfdiscovery #innerwork #spiritualquotes #dailywisdom #energyhealing #koreanwellness #metaphysics #lifequotes #personalgrowth #selflove #mindfulness #womenwhorise #quotestoliveby"
    fi

    echo "$caption" > "$caption_file"
    log "Caption saved: $caption_file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate background via NanoBanana (optional)
# ─────────────────────────────────────────────────────────────────────────────

generate_background() {
    local qtype="$1"
    local bg_file="$2"

    local prompt
    prompt="$(generate_bg_prompt "$qtype")"

    local bg_prompt_file="${bg_file%.png}-bg-prompt.txt"
    echo "$prompt" > "$bg_prompt_file"
    log "Background prompt saved: $bg_prompt_file"

    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] Would generate background image via NanoBanana"
        return 0
    fi

    if [ -n "$NANOBANANA" ] && [ -f "$NANOBANANA" ]; then
        log "Generating background via NanoBanana..."
        if bash "$NANOBANANA" generate \
            --brand jade-oracle \
            --use-case product \
            --prompt "$prompt" \
            --model flash \
            --ratio "1:1" \
            --size 2K \
            --output "$bg_file" 2>&1; then
            if [ -f "$bg_file" ]; then
                log "Background image generated: $bg_file"
                return 0
            fi
        fi
        log "NanoBanana generation failed — using plain cream background"
    else
        log "NanoBanana not available — using plain cream background"
    fi

    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Post to room log
# ─────────────────────────────────────────────────────────────────────────────

post_to_room() {
    local msg="$1"
    if [ -f "$ROOM_FILE" ] || [ -d "$(dirname "$ROOM_FILE")" ]; then
        echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"quote-gen\",\"body\":\"$msg\"}" >> "$ROOM_FILE" 2>/dev/null || true
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────────────────────────────────

usage() {
    cat << 'USAGE_EOF'
jade-quote-gen.sh — Jade Oracle Spiritual Quote Post Generator

USAGE:
  bash jade-quote-gen.sh --type vulnerability    # raw, honest healing quotes
  bash jade-quote-gen.sh --type wisdom           # Chinese proverb + modern take
  bash jade-quote-gen.sh --type empowerment      # "your chart already knows"
  bash jade-quote-gen.sh --type qmdj             # QMDJ-specific mystical
  bash jade-quote-gen.sh --type relatable         # real-talk for your 30s
  bash jade-quote-gen.sh --random                 # random type
  bash jade-quote-gen.sh --type wisdom --dry-run  # preview without generation

OPTIONS:
  --type TYPE     Quote type: vulnerability | wisdom | empowerment | qmdj | relatable
  --random        Pick a random quote type
  --dry-run       Preview without generating images/captions
  --help          Show this help

OUTPUT:
  quote-TYPE-DATE.png              Final quote image (1080x1080)
  quote-TYPE-DATE-caption.txt      Instagram caption
  quote-TYPE-DATE-bg-prompt.txt    NanoBanana background prompt
USAGE_EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────────────────────────────────────

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --type)
                shift
                if [ $# -eq 0 ]; then
                    die "--type requires a value: vulnerability | wisdom | empowerment | qmdj | relatable"
                fi
                QUOTE_TYPE="$1"
                # Validate type
                local valid=0
                local t
                for t in $VALID_TYPES; do
                    if [ "$t" = "$QUOTE_TYPE" ]; then
                        valid=1
                        break
                    fi
                done
                if [ "$valid" -eq 0 ]; then
                    die "Invalid quote type: '$QUOTE_TYPE'. Valid types: $VALID_TYPES"
                fi
                shift
                ;;
            --random)
                QUOTE_TYPE="$(random_type)"
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

    if [ -z "$QUOTE_TYPE" ]; then
        usage
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"

    local out_dir="$OUTPUT_DIR/$DATE"
    mkdir -p "$out_dir"

    local base_name="quote-${QUOTE_TYPE}-${DATE}"
    local image_file="$out_dir/${base_name}.png"
    local caption_file="$out_dir/${base_name}-caption.txt"
    local bg_file="$out_dir/${base_name}-bg.png"

    log "========================================="
    log "Jade Oracle — Quote Post Generator"
    log "Date: $DATE"
    log "Type: $QUOTE_TYPE"
    [ "$DRY_RUN" -eq 1 ] && log "MODE: DRY RUN"
    log "========================================="

    # Step 1: Generate quote text
    log ""
    log "Step 1: Generating quote text..."
    local quote
    quote="$(generate_quote_text "$QUOTE_TYPE")"
    if [ -z "$quote" ]; then
        die "Failed to generate quote text"
    fi
    log "Quote: \"$quote\""

    # Save raw quote text
    echo "$quote" > "$out_dir/${base_name}-text.txt"

    # Step 2: Generate background (optional, via NanoBanana)
    log ""
    log "Step 2: Generating background..."
    generate_background "$QUOTE_TYPE" "$bg_file"

    # Step 3: Generate quote image via Pillow
    log ""
    log "Step 3: Compositing quote image..."
    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] Would generate 1080x1080 quote image: $image_file"
    else
        local bg_arg=""
        if [ -f "$bg_file" ]; then
            bg_arg="$bg_file"
        fi
        generate_quote_image "$quote" "$QUOTE_TYPE" "$image_file" "$bg_arg"
    fi

    # Step 4: Generate caption
    log ""
    log "Step 4: Generating caption..."
    generate_caption "$quote" "$QUOTE_TYPE" "$caption_file"

    # Summary
    log ""
    log "========================================="
    log "Quote post generation complete!"
    log "========================================="
    log ""
    log "Output files:"
    log "  Quote text: $out_dir/${base_name}-text.txt"
    if [ "$DRY_RUN" -eq 0 ]; then
        log "  Image:      $image_file"
    fi
    log "  Caption:    $caption_file"
    log "  BG prompt:  $out_dir/${base_name}-bg-prompt.txt"
    log ""

    post_to_room "Generated $QUOTE_TYPE quote post for $DATE"

    log "Done."
}

main "$@"
