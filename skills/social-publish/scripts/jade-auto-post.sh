#!/usr/bin/env bash
# jade-auto-post.sh — Automated Instagram posting for Jade Oracle
#
# Called by: jade-daily-dispatch.sh evening cycle
# Also callable standalone: bash jade-auto-post.sh [DATE] [--dry-run]
#
# Flow:
#   1. Check token validity
#   2. Pick best content from today's generated content
#   3. Generate Jade's image via NanoBanana (if not already generated)
#   4. Post to Instagram via Meta Graph API
#   5. Log result to posting history + room
#
# macOS Bash 3.2 compatible.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"

DATE="${1:-$(date +%Y-%m-%d)}"
DRY_RUN=0
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=1

CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily/$DATE"
IMAGE_DIR="$OPENCLAW_DIR/workspace/data/images/jade-oracle/ig-library/jade"
POSTING_LOG="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"
SECRETS_FILE="$OPENCLAW_DIR/secrets/meta-marketing.env"

IG_PUBLISH="$SCRIPT_DIR/ig-publish.py"
TOKEN_MGR="$SCRIPT_DIR/meta-token-manager.sh"
NANOBANANA="$OPENCLAW_DIR/skills/ad-composer/scripts/nanobanana-gen.sh"
AUTO_LOOP="$OPENCLAW_DIR/skills/auto-research/scripts/auto-loop.sh"
BRAND_VOICE="$OPENCLAW_DIR/skills/brand-voice-check/scripts/brand-voice-check.sh"

mkdir -p "$(dirname "$POSTING_LOG")" "$IMAGE_DIR"

log() {
    local msg="[jade-auto-post $(date +%H:%M:%S)] $1"
    echo "$msg"
    [[ -f "$ROOM_FILE" ]] && echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"ig-post\",\"body\":\"$1\"}" >> "$ROOM_FILE" 2>/dev/null || true
}

err() {
    echo "[jade-auto-post $(date +%H:%M:%S)] ERROR: $1" >&2
    [[ -f "$ROOM_FILE" ]] && echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"ig-post-error\",\"body\":\"$1\"}" >> "$ROOM_FILE" 2>/dev/null || true
}

###############################################################################
# Step 1: Token check
###############################################################################

check_token() {
    log "Checking Meta API token..."

    if [[ ! -f "$SECRETS_FILE" ]]; then
        err "No secrets file found at $SECRETS_FILE"
        err "Run: bash meta-token-manager.sh setup"
        return 1
    fi

    # Source secrets
    while IFS='=' read -r key value; do
        key=$(echo "$key" | tr -d '[:space:]')
        [[ -z "$key" || "$key" == \#* ]] && continue
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        export "$key=$value" 2>/dev/null || true
    done < "$SECRETS_FILE"

    if [[ -z "${META_ACCESS_TOKEN:-}" ]]; then
        err "META_ACCESS_TOKEN not set"
        return 1
    fi
    if [[ -z "${IG_USER_ID:-}" ]]; then
        err "IG_USER_ID not set. Run: bash meta-token-manager.sh discover"
        return 1
    fi

    # Quick validation
    if [[ "$DRY_RUN" -eq 0 ]]; then
        bash "$TOKEN_MGR" validate 2>/dev/null || {
            err "Token validation failed. Run: bash meta-token-manager.sh exchange"
            return 1
        }
    fi

    log "Token OK"
    return 0
}

###############################################################################
# Step 2: Pick best content
###############################################################################

pick_content() {
    log "Selecting best content from $CONTENT_DIR..."

    if [[ ! -d "$CONTENT_DIR" ]]; then
        err "No content directory for $DATE. Run jade-daily-dispatch.sh first."
        return 1
    fi

    # Priority order: forecast > pick-a-card > reel-script > ad-copy
    local content_file=""
    local content_type=""

    for candidate in "forecast-captions.md" "pick-a-card.md" "reel-script.md" "ad-copy.md"; do
        if [[ -f "$CONTENT_DIR/$candidate" ]]; then
            content_file="$CONTENT_DIR/$candidate"
            content_type="${candidate%.md}"
            break
        fi
    done

    # Also check for auto-research generated content
    local ar_dir="$OPENCLAW_DIR/workspace/data/auto-research/jade-instagram-loop"
    if [[ -z "$content_file" ]] && [[ -d "$ar_dir" ]]; then
        local latest_ar=$(find "$ar_dir" -name "*.md" -type f 2>/dev/null | sort -r | head -1)
        if [[ -n "$latest_ar" ]]; then
            content_file="$latest_ar"
            content_type="auto-research"
        fi
    fi

    if [[ -z "$content_file" ]]; then
        err "No content found for $DATE"
        return 1
    fi

    log "Selected: $content_type ($content_file)"

    # Extract caption using LLM
    local caption
    local claude_cli
    claude_cli=$(command -v claude 2>/dev/null || echo "")

    if [[ -n "$claude_cli" ]]; then
        caption=$("$claude_cli" --print --model "claude-sonnet-4-6" << PROMPT
You are creating an Instagram caption for Jade Oracle (@the_jade_oracle).

From this content file, extract or generate ONE Instagram-ready caption.
Rules:
- Max 2200 characters (IG limit)
- Start with a scroll-stopping hook (first line is everything)
- Include 1-2 natural line breaks for readability
- End with a soft CTA (not salesy)
- Add 15-20 relevant hashtags at the end
- Voice: warm, wise, slightly mysterious — like a trusted spiritual advisor over tea
- Mix English with natural Chinese metaphysics terms where appropriate
- Brand: Jade Oracle, QMDJ practitioner

Content to adapt:
$(head -100 "$content_file")

Output ONLY the final Instagram caption. Nothing else.
PROMPT
        ) || true
    fi

    # Fallback if claude fails
    if [[ -z "${caption:-}" ]]; then
        # Use first 500 chars of content as caption
        caption=$(head -20 "$content_file" | sed '/^#/d;/^>/d;/^---/d;/^$/d' | head -10)
        caption="${caption}

#jadeoracle #qmdj #qimendunjia #奇门遁甲 #spirituality #tarot #oraclecard #astrology #divination #spiritualawakening #energyhealing #metaphysics #koreanwellness #selflove #healingjourney"
    fi

    echo "$caption" > "$CONTENT_DIR/ig-caption-$DATE.txt"
    log "Caption generated ($(echo "$caption" | wc -c | tr -d ' ') chars)"

    # Export for later steps
    export JADE_CAPTION="$caption"
    export JADE_CONTENT_TYPE="$content_type"
    return 0
}

###############################################################################
# Step 3: Generate image
###############################################################################

generate_image() {
    log "Generating Jade's image for today's post..."

    local today_images=$(find "$IMAGE_DIR" -name "${DATE//-/}*" -type f 2>/dev/null | head -1)

    if [[ -n "$today_images" ]]; then
        log "Image already exists: $today_images"
        export JADE_IMAGE="$today_images"
        return 0
    fi

    # Pick a scene based on day of week
    local dow=$(date +%u)  # 1=Mon, 7=Sun
    local scene=""
    case "$dow" in
        1) scene="Jade in a cozy Western coffee shop, cream linen top, morning light, journaling with tea, warm tones" ;;
        2) scene="Jade at a farmers market, white wrap blouse showing decolletage, laughing, holding fresh flowers, golden hour" ;;
        3) scene="Jade in modern apartment, sage green tank top, spreading tarot cards on table, candlelight, intimate" ;;
        4) scene="Jade at candlelit restaurant, black slip dress, chin on hand, wine glass, warm amber lighting" ;;
        5) scene="Jade on rooftop at golden hour, burgundy wrap dress, wind in hair, city skyline behind, contemplative" ;;
        6) scene="Jade at Western bookstore, oatmeal cardigan over tank, browsing crystals section, soft window light" ;;
        7) scene="Jade in bed, morning light, cream tank top bare shoulders, steaming tea, soft smile, selfie angle" ;;
    esac

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY RUN] Would generate image: $scene"
        export JADE_IMAGE=""
        return 0
    fi

    # Use NanoBanana if available
    if [[ -f "$NANOBANANA" ]]; then
        # Check multiple known face ref locations
        local face_refs_dir=""
        for candidate in \
            "$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/lock" \
            "$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/face-refs" \
            "$HOME/Desktop/gaia-projects/jade-oracle-site/images/jade/v22-expressions" \
            "$HOME/Desktop/gaia-projects/jade-oracle-site/images/jade/v21-face-fixed"
        do
            if [[ -d "$candidate" ]]; then
                face_refs_dir="$candidate"
                break
            fi
        done

        local face_ref1="" face_ref2="" face_ref3=""

        if [[ -n "$face_refs_dir" ]]; then
            local refs=($(find "$face_refs_dir" -name "*.png" -o -name "*.jpg" 2>/dev/null | head -3))
            face_ref1="${refs[0]:-}"
            face_ref2="${refs[1]:-$face_ref1}"
            face_ref3="${refs[2]:-$face_ref1}"
        fi

        local prompt="Authentic iPhone photo of a Korean woman in her early 30s, long dark hair with soft bangs, warm brown eyes, jade pendant necklace. $scene. Shot on iPhone 16 Pro, natural depth of field, candid moment. Looks like a real Instagram post from a lifestyle influencer. 4:5 aspect ratio."

        local output_file="$IMAGE_DIR/$(date +%Y%m%d)_ig_post.png"

        if [[ -n "$face_ref1" ]]; then
            bash "$NANOBANANA" generate \
                --brand jade-oracle \
                --use-case character \
                --prompt "$prompt" \
                --ref-image "$face_ref1,$face_ref2,$face_ref3" \
                --model pro \
                --ratio "4:5" \
                --size 2K \
                --output "$output_file" 2>&1 || {
                    err "NanoBanana generation failed"
                    return 1
                }
        else
            bash "$NANOBANANA" generate \
                --brand jade-oracle \
                --use-case character \
                --prompt "$prompt" \
                --model pro \
                --ratio "4:5" \
                --size 2K \
                --output "$output_file" 2>&1 || {
                    err "NanoBanana generation failed"
                    return 1
                }
        fi

        if [[ -f "$output_file" ]]; then
            export JADE_IMAGE="$output_file"
            log "Image generated: $output_file"
            return 0
        fi
    fi

    err "No image generation tool available. Add image manually to $IMAGE_DIR/"
    export JADE_IMAGE=""
    return 1
}

###############################################################################
# Step 4: Post to Instagram
###############################################################################

post_to_instagram() {
    local caption="${JADE_CAPTION:-}"
    local image="${JADE_IMAGE:-}"

    if [[ -z "$caption" ]]; then
        err "No caption available"
        return 1
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY RUN] Would post to Instagram:"
        log "  Image: ${image:-<none>}"
        log "  Caption: $(echo "$caption" | head -3)..."
        echo "$caption"
        return 0
    fi

    if [[ -z "$image" ]]; then
        err "No image available for posting"
        return 1
    fi

    log "Posting to Instagram..."

    local post_id
    post_id=$("$PYTHON3" "$IG_PUBLISH" image \
        --image-path "$image" \
        --caption "$caption" 2>&1) || {
        err "Instagram publish failed: $post_id"
        return 1
    }

    log "Posted to Instagram! $post_id"

    # Log to posting history
    local entry="{\"date\":\"$DATE\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"content_type\":\"${JADE_CONTENT_TYPE:-unknown}\",\"image\":\"$image\",\"post_id\":\"$post_id\",\"status\":\"published\"}"
    echo "$entry" >> "$POSTING_LOG"

    return 0
}

###############################################################################
# Step 5: Feed learnings
###############################################################################

feed_learnings() {
    log "Recording post for learning loop..."

    # Append to auto-research learnings
    local learnings_dir="$OPENCLAW_DIR/workspace/data/auto-research/jade-instagram-loop"
    mkdir -p "$learnings_dir"

    "$PYTHON3" << PYEOF
import json, os
from datetime import datetime

learnings_file = "$learnings_dir/learnings.json"
data = {"posts": [], "updated": ""}

if os.path.exists(learnings_file):
    try:
        with open(learnings_file) as f:
            data = json.load(f)
    except:
        pass

if "posts" not in data:
    data["posts"] = []

data["posts"].append({
    "date": "$DATE",
    "content_type": "${JADE_CONTENT_TYPE:-unknown}",
    "posted_at": datetime.utcnow().isoformat() + "Z",
    "status": "published" if $DRY_RUN == 0 else "dry_run",
    "engagement": None,  # Filled in later by feedback loop
    "notes": "Auto-posted by jade-auto-post.sh"
})

# Keep last 180 days
data["posts"] = data["posts"][-180:]
data["updated"] = datetime.utcnow().isoformat() + "Z"

with open(learnings_file, "w") as f:
    json.dump(data, f, indent=2)

print(f"[jade-auto-post] Learnings updated: {len(data['posts'])} posts tracked")
PYEOF
}

###############################################################################
# Main
###############################################################################

main() {
    log "========================================="
    log "Jade Oracle — Auto Post to Instagram"
    log "Date: $DATE"
    [[ "$DRY_RUN" -eq 1 ]] && log "MODE: DRY RUN"
    log "========================================="

    # Step 1: Token
    check_token || { err "Token check failed — aborting"; exit 1; }

    # Step 2: Content
    pick_content || { err "Content selection failed — aborting"; exit 1; }

    # Step 3: Image
    generate_image || log "Image generation skipped or failed (will try to post without)"

    # Step 4: Post
    post_to_instagram || { err "Posting failed"; exit 1; }

    # Step 5: Learnings
    feed_learnings || log "Learnings update failed (non-fatal)"

    log "========================================="
    log "Auto-post complete!"
    log "========================================="
}

main "$@"
