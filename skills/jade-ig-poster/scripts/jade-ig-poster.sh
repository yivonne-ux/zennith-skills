#!/usr/bin/env bash
# jade-ig-poster.sh — Complete Instagram posting pipeline for Jade Oracle
#
# One command: generate → pick → score → fix → review → post
#
# Usage:
#   bash jade-ig-poster.sh run [--count N] [--theme THEME] [--dry-run]
#   bash jade-ig-poster.sh generate [--count N]
#   bash jade-ig-poster.sh pick
#   bash jade-ig-poster.sh score
#   bash jade-ig-poster.sh fix
#   bash jade-ig-poster.sh review
#   bash jade-ig-poster.sh post
#   bash jade-ig-poster.sh status
#
# Called by: Zenni dispatch, cron, or manual

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
CLAUDE_CLI="$(command -v claude 2>/dev/null || echo "")"
DATE=$(date +%Y-%m-%d)

# Paths
CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily/$DATE"
READY_DIR="$CONTENT_DIR/ready-to-post"
IMG_DIR="$OPENCLAW_DIR/workspace/data/images/jade-oracle/ig-library/jade"
IMG_REGISTRY="$OPENCLAW_DIR/workspace/data/images/jade-oracle/ig-library/image-registry.json"
POST_LOG="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
SECRETS="$OPENCLAW_DIR/secrets/meta-marketing.env"
IG_PUBLISH="$OPENCLAW_DIR/skills/social-publish/scripts/ig-publish.py"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"
LOG_FILE="$OPENCLAW_DIR/logs/jade-ig-poster-$(date +%Y%m%d).log"

mkdir -p "$CONTENT_DIR" "$READY_DIR" "$(dirname "$POST_LOG")" "$(dirname "$LOG_FILE")"

# Defaults
COUNT=5
THEME=""
DRY_RUN=0
CMD="${1:-run}"
shift 2>/dev/null || true

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --count)   COUNT="$2"; shift 2 ;;
        --theme)   THEME="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        *)         shift ;;
    esac
done

# Load secrets
if [ -f "$SECRETS" ]; then
    while IFS='=' read -r key value; do
        key=$(echo "$key" | tr -d '[:space:]')
        [ -z "$key" ] || [ "${key#\#}" != "$key" ] && continue
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        export "$key=$value" 2>/dev/null || true
    done < "$SECRETS"
fi

###############################################################################
# Logging
###############################################################################

log() {
    local msg="[jade-ig-poster $(date +%H:%M:%S)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

err() {
    local msg="[jade-ig-poster $(date +%H:%M:%S)] ERROR: $1"
    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

room_msg() {
    [ -f "$ROOM_FILE" ] || return 0
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"jade-ig-poster\",\"body\":\"$1\"}" >> "$ROOM_FILE" 2>/dev/null || true
}

###############################################################################
# STEP 1: GENERATE captions
###############################################################################

step_generate() {
    log "=== STEP 1: GENERATE ($COUNT posts) ==="

    if [ -z "$CLAUDE_CLI" ]; then
        err "Claude CLI not found"
        return 1
    fi

    local themes="self_love kindness oracle_reading life_transitions empowerment vulnerability morning_routine inner_peace trust_intuition between_chapters"
    if [ -n "$THEME" ]; then
        themes="$THEME"
    fi

    local prompt_file
    prompt_file=$(mktemp)
    cat > "$prompt_file" << GENEOF
You are Jade (@the_jade_oracle), a warm oracle reader for women navigating life transitions.

Generate $COUNT Instagram posts as a JSON array. Each must have a DIFFERENT theme.
CRITICAL RULES:
- DO NOT mention QMDJ, 奇门遁甲, BaZi, or Chinese metaphysics
- Jade is an oracle reader, NOT a metaphysics educator
- Max 5-7 hashtags per post
- Max 1800 characters per caption
- Voice: warm best friend, personal, journal-style, vulnerable
- Topics from: self-love, kindness, life transitions, trusting intuition, oracle readings, morning rituals, being between chapters, vulnerability, inner peace, empowerment

For each post:
{"theme":"...", "mood":"warm|vulnerable|mystical|contemplative|confident", "image_query":"keywords for image picker", "caption":"full caption"}

Output ONLY valid JSON array. No explanation.
GENEOF

    local result
    result=$(cat "$prompt_file" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
    rm -f "$prompt_file"

    if [ -z "$result" ]; then
        err "Caption generation failed"
        return 1
    fi

    echo "$result" > "$CONTENT_DIR/batch-captions.json"
    log "Generated $COUNT captions ($(echo "$result" | wc -c | tr -d ' ') chars)"
    room_msg "Generated $COUNT captions for $DATE"
}

###############################################################################
# STEP 2: PICK matching images
###############################################################################

step_pick() {
    log "=== STEP 2: PICK images ==="

    if [ ! -f "$IMG_REGISTRY" ]; then
        err "Image registry not found: $IMG_REGISTRY"
        return 1
    fi
    if [ ! -f "$CONTENT_DIR/batch-captions.json" ]; then
        err "No captions found. Run 'generate' first."
        return 1
    fi

    "$PYTHON3" << PYEOF
import json, os, re

content_dir = "$CONTENT_DIR"
ready_dir = "$READY_DIR"
registry_path = "$IMG_REGISTRY"

# Load captions
with open(f"{content_dir}/batch-captions.json") as f:
    text = f.read().strip()
    text = re.sub(r'\`\`\`json?\n?', '', text).strip()
    text = re.sub(r'\`\`\`', '', text).strip()
    posts = json.loads(text)

# Load registry
with open(registry_path) as f:
    registry = json.load(f)

images = registry.get("images", [])
used = set()
matched = 0

for i, post in enumerate(posts):
    theme = post.get("theme", "self_love")
    mood = post.get("mood", "warm")
    query = post.get("image_query", f"{theme} {mood}").lower().split()
    caption = post.get("caption", "")

    # Score each image
    scored = []
    for img in images:
        if img["filename"] in used:
            continue
        score = 0
        best_for = [b.lower() for b in img.get("best_for", [])]
        avoid_for = [a.lower() for a in img.get("avoid_for", [])]

        for q in query:
            if any(q in b for b in best_for): score += 10
            if q in img.get("mood", "").lower(): score += 5
            if q in img.get("ig_vibe", "").lower(): score += 3
            if any(q in a for a in avoid_for): score -= 20

        score += img.get("quality", 5) + img.get("brand_fit", 5) + img.get("warmth", 5)

        # Enforce minimums
        if img.get("warmth", 0) < 7 or img.get("brand_fit", 0) < 7:
            score -= 30

        if score > 0:
            scored.append((score, img))

    scored.sort(key=lambda x: -x[0])

    if scored:
        best = scored[0][1]
        used.add(best["filename"])
        img_path = best.get("path", os.path.join("$IMG_DIR", best["filename"]))

        # Save caption
        with open(f"{ready_dir}/post-{i+1}-{theme}-caption.txt", "w") as f:
            f.write(caption)

        # Symlink image
        ext = "jpg" if img_path.endswith(".jpg") else "png"
        link_path = f"{ready_dir}/post-{i+1}-{theme}-image.{ext}"
        if os.path.exists(link_path):
            os.remove(link_path)
        os.symlink(img_path, link_path)

        matched += 1
        print(f"  Post {i+1} ({theme}): {best['filename']} [warmth:{best.get('warmth','?')} brand:{best.get('brand_fit','?')}]")
    else:
        # Save caption without image
        with open(f"{ready_dir}/post-{i+1}-{theme}-caption.txt", "w") as f:
            f.write(caption)
        print(f"  Post {i+1} ({theme}): NO MATCH FOUND")

print(f"\nMatched: {matched}/{len(posts)}")
PYEOF

    log "Image picking complete"
}

###############################################################################
# STEP 3: SCORE quality
###############################################################################

step_score() {
    log "=== STEP 3: SCORE quality ==="

    if [ -z "$CLAUDE_CLI" ]; then
        err "Claude CLI not found"
        return 1
    fi

    local post_count=0
    local total_score=0

    for cap_file in "$READY_DIR"/post-*-caption.txt; do
        [ -f "$cap_file" ] || continue
        local idx
        idx=$(basename "$cap_file" | grep -oE 'post-[0-9]+' | grep -oE '[0-9]+')
        local theme
        theme=$(basename "$cap_file" | sed "s/post-${idx}-//;s/-caption.txt//")
        local caption
        caption=$(cat "$cap_file")
        local img_file
        img_file=$(ls "$READY_DIR"/post-${idx}-*-image.* 2>/dev/null | head -1)
        local img_name="none"
        [ -n "$img_file" ] && img_name=$(basename "$(readlink "$img_file" 2>/dev/null || echo "$img_file")")

        local score_prompt
        score_prompt=$(mktemp)
        cat > "$score_prompt" << SEOF
Score this Instagram post for Jade Oracle on 8 criteria (1-10 each).
Output ONLY JSON: {"scores":{"hook_power":N,"warmth":N,"vulnerability":N,"no_jargon":N,"caption_length":N,"hashtag_count":N,"cta_soft":N,"image_match":N},"total":N,"fix":"what to improve or none"}

IMAGE: $img_name
CAPTION:
$caption
SEOF

        local score_result
        score_result=$(cat "$score_prompt" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
        rm -f "$score_prompt"

        echo "$score_result" > "$READY_DIR/post-${idx}-score.json"

        local score_total
        score_total=$("$PYTHON3" -c "
import json, re
text = open('$READY_DIR/post-${idx}-score.json').read().strip()
text = re.sub(r'\`\`\`json?\n?', '', text).strip()
text = re.sub(r'\`\`\`', '', text).strip()
d = json.loads(text)
t = sum(d.get('scores',{}).values())
fix = d.get('fix','none')
print(f'{t}|{fix}')
" 2>/dev/null || echo "0|error")

        local pts="${score_total%%|*}"
        local fix="${score_total#*|}"

        log "  Post $idx ($theme): $pts/80 ${fix:+— fix: $fix}"
        post_count=$((post_count + 1))
        total_score=$((total_score + ${pts:-0}))
    done

    if [ "$post_count" -gt 0 ]; then
        local avg=$((total_score / post_count))
        log "Average: $avg/80 across $post_count posts"
    fi
}

###############################################################################
# STEP 4: FIX weak spots
###############################################################################

step_fix() {
    log "=== STEP 4: FIX weak spots ==="

    if [ -z "$CLAUDE_CLI" ]; then
        err "Claude CLI not found"
        return 1
    fi

    local fixed=0

    for score_file in "$READY_DIR"/post-*-score.json; do
        [ -f "$score_file" ] || continue
        local idx
        idx=$(basename "$score_file" | grep -oE 'post-[0-9]+' | grep -oE '[0-9]+')

        local needs_fix
        needs_fix=$("$PYTHON3" -c "
import json, re
text = open('$score_file').read().strip()
text = re.sub(r'\`\`\`json?\n?', '', text).strip()
text = re.sub(r'\`\`\`', '', text).strip()
d = json.loads(text)
scores = d.get('scores', {})
fix = d.get('fix', 'none')
total = sum(scores.values())
# Fix if total < 65 or any dimension <= 5
weak = [k for k, v in scores.items() if v <= 5]
if total < 65 or weak:
    print(f'FIX|{fix}|{\" \".join(weak)}')
else:
    print('OK')
" 2>/dev/null || echo "OK")

        if [ "${needs_fix%%|*}" = "FIX" ]; then
            local fix_reason="${needs_fix#FIX|}"
            local cap_file
            cap_file=$(ls "$READY_DIR"/post-${idx}-*-caption.txt 2>/dev/null | head -1)
            [ -f "$cap_file" ] || continue

            local caption
            caption=$(cat "$cap_file")
            local theme
            theme=$(basename "$cap_file" | sed "s/post-${idx}-//;s/-caption.txt//")

            log "  Fixing post $idx ($theme): $fix_reason"

            local fix_prompt
            fix_prompt=$(mktemp)
            cat > "$fix_prompt" << FEOF
Fix this Jade Oracle caption based on this feedback: $fix_reason

Rules: Keep same theme and voice. Max 1800 chars. 5-7 hashtags. NO QMDJ terms.
If feedback mentions weak CTA, add a soft question like "Tell me below" or "Drop an emoji if this is you."
If feedback mentions weak hook, make line 1 a pattern interrupt or emotional gut-punch.

Original:
$caption

Output ONLY the fixed caption.
FEOF
            local fixed_cap
            fixed_cap=$(cat "$fix_prompt" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
            rm -f "$fix_prompt"

            if [ -n "$fixed_cap" ]; then
                echo "$fixed_cap" > "$cap_file"
                fixed=$((fixed + 1))
                log "  Fixed post $idx"
            fi
        fi
    done

    log "Fixed $fixed posts"
}

###############################################################################
# STEP 5: REVIEW (visual match check)
###############################################################################

step_review() {
    log "=== STEP 5: REVIEW (visual match) ==="

    local passed=0
    local failed=0

    for cap_file in "$READY_DIR"/post-*-caption.txt; do
        [ -f "$cap_file" ] || continue
        local idx
        idx=$(basename "$cap_file" | grep -oE 'post-[0-9]+' | grep -oE '[0-9]+')
        local theme
        theme=$(basename "$cap_file" | sed "s/post-${idx}-//;s/-caption.txt//")
        local img_file
        img_file=$(ls "$READY_DIR"/post-${idx}-*-image.* 2>/dev/null | head -1)

        if [ -z "$img_file" ]; then
            log "  Post $idx ($theme): NO IMAGE — FAIL"
            failed=$((failed + 1))
            continue
        fi

        local real_img
        real_img=$(readlink "$img_file" 2>/dev/null || echo "$img_file")
        local img_name
        img_name=$(basename "$real_img")

        # Check registry tags
        local match_result
        match_result=$("$PYTHON3" -c "
import json
reg = json.load(open('$IMG_REGISTRY'))
for img in reg['images']:
    if img['filename'] == '$img_name':
        warmth = img.get('warmth', 0)
        brand = img.get('brand_fit', 0)
        avoid = img.get('avoid_for', [])
        theme_match = '$theme' not in ' '.join(avoid).lower()
        if warmth >= 7 and brand >= 7 and theme_match:
            print(f'PASS|w:{warmth} b:{brand}')
        else:
            reasons = []
            if warmth < 7: reasons.append(f'warmth:{warmth}')
            if brand < 7: reasons.append(f'brand:{brand}')
            if not theme_match: reasons.append('theme in avoid_for')
            print(f'FAIL|{\" \".join(reasons)}')
        break
else:
    print('PASS|not in registry')
" 2>/dev/null || echo "PASS|unchecked")

        local result="${match_result%%|*}"
        local detail="${match_result#*|}"

        if [ "$result" = "PASS" ]; then
            log "  Post $idx ($theme): PASS ($detail)"
            passed=$((passed + 1))
        else
            log "  Post $idx ($theme): FAIL ($detail)"
            failed=$((failed + 1))
        fi
    done

    log "Review: $passed passed, $failed failed"
    [ "$failed" -eq 0 ]
}

###############################################################################
# STEP 6: POST to Instagram
###############################################################################

step_post() {
    log "=== STEP 6: POST to Instagram ==="

    if [ -z "${META_ACCESS_TOKEN:-}" ] || [ -z "${IG_USER_ID:-}" ]; then
        err "Meta token or IG User ID not set"
        return 1
    fi

    local posted=0
    local failed=0

    for cap_file in "$READY_DIR"/post-*-caption.txt; do
        [ -f "$cap_file" ] || continue
        local idx
        idx=$(basename "$cap_file" | grep -oE 'post-[0-9]+' | grep -oE '[0-9]+')
        local theme
        theme=$(basename "$cap_file" | sed "s/post-${idx}-//;s/-caption.txt//")
        local img_file
        img_file=$(ls "$READY_DIR"/post-${idx}-*-image.* 2>/dev/null | head -1)
        local caption
        caption=$(cat "$cap_file")
        local real_img
        real_img=$(readlink "$img_file" 2>/dev/null || echo "$img_file")

        if [ -z "$real_img" ] || [ ! -f "$real_img" ]; then
            err "  Post $idx: no image"
            failed=$((failed + 1))
            continue
        fi

        if [ "$DRY_RUN" -eq 1 ]; then
            log "  [DRY RUN] Post $idx ($theme): $(basename "$real_img") — $(echo "$caption" | head -1)"
            continue
        fi

        # Upload image
        local url
        url=$(curl -s -X POST \
            -F "source=@$real_img" -F "type=file" -F "action=upload" \
            "https://freeimage.host/api/1/upload?key=6d207e02198a847aa98d0a2a901485a5" | \
            "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin).get('image',{}).get('url',''))" 2>/dev/null)

        if [ -z "$url" ] || [ "$url" = "None" ]; then
            err "  Post $idx: upload failed"
            failed=$((failed + 1))
            continue
        fi

        # Post via Graph API
        local result
        result=$("$PYTHON3" "$IG_PUBLISH" image --image-url "$url" --caption "$caption" 2>&1)
        local post_id
        post_id=$(echo "$result" | grep -oE '[0-9]{15,}' | tail -1 || echo "")

        if [ -n "$post_id" ]; then
            log "  Post $idx ($theme): PUBLISHED — $post_id"
            echo "{\"date\":\"$DATE\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"$theme\",\"post_id\":\"$post_id\",\"status\":\"published\",\"pipeline\":\"jade-ig-poster\"}" >> "$POST_LOG"
            posted=$((posted + 1))
        else
            err "  Post $idx ($theme): FAILED — $result"
            failed=$((failed + 1))
        fi

        # Space posts
        sleep 45
    done

    log "Posted: $posted | Failed: $failed"
    room_msg "Posted $posted/$((posted + failed)) to @the_jade_oracle for $DATE"
}

###############################################################################
# STATUS
###############################################################################

step_status() {
    echo "=== Jade IG Poster Status ($DATE) ==="

    # Token
    if [ -n "${META_ACCESS_TOKEN:-}" ]; then
        echo "  Token: SET ($(echo "$META_ACCESS_TOKEN" | wc -c | tr -d ' ') chars)"
    else
        echo "  Token: NOT SET"
    fi

    # Today's content
    local cap_count=0
    local img_count=0
    for f in "$READY_DIR"/post-*-caption.txt; do [ -f "$f" ] && cap_count=$((cap_count + 1)); done
    for f in "$READY_DIR"/post-*-image.*; do [ -f "$f" ] && img_count=$((img_count + 1)); done
    echo "  Captions: $cap_count | Images matched: $img_count"

    # Scores
    local scored=0
    for f in "$READY_DIR"/post-*-score.json; do [ -f "$f" ] && scored=$((scored + 1)); done
    echo "  Scored: $scored"

    # Posted today
    local today_posts=0
    [ -f "$POST_LOG" ] && today_posts=$(grep -c "\"$DATE\"" "$POST_LOG" 2>/dev/null || echo "0")
    echo "  Posted today: $today_posts"

    # Total all-time
    local total=0
    [ -f "$POST_LOG" ] && total=$(wc -l < "$POST_LOG" | tr -d ' ')
    echo "  Total all-time: $total"

    # Registry
    if [ -f "$IMG_REGISTRY" ]; then
        local reg_count
        reg_count=$("$PYTHON3" -c "import json; print(json.load(open('$IMG_REGISTRY')).get('total',0))" 2>/dev/null || echo "?")
        echo "  Image registry: $reg_count images"
    else
        echo "  Image registry: NOT FOUND"
    fi
}

###############################################################################
# RUN (full pipeline)
###############################################################################

step_run() {
    log "========================================="
    log "JADE IG POSTER — FULL PIPELINE"
    log "Date: $DATE | Count: $COUNT"
    [ "$DRY_RUN" -eq 1 ] && log "MODE: DRY RUN"
    log "========================================="

    room_msg "Starting jade-ig-poster pipeline: $COUNT posts for $DATE"

    step_generate || { err "Generate failed"; return 1; }
    step_pick     || { err "Pick failed"; return 1; }
    step_score    || log "Scoring had issues (non-fatal)"
    step_fix      || log "Fix had issues (non-fatal)"
    step_review   || log "Review had failures (non-fatal, posting anyway)"
    step_post     || { err "Post failed"; return 1; }

    log "========================================="
    log "PIPELINE COMPLETE"
    log "========================================="

    step_status
    room_msg "jade-ig-poster pipeline complete for $DATE"
}

###############################################################################
# Main
###############################################################################

case "$CMD" in
    run)      step_run ;;
    generate) step_generate ;;
    pick)     step_pick ;;
    score)    step_score ;;
    fix)      step_fix ;;
    review)   step_review ;;
    post)     step_post ;;
    status)   step_status ;;
    *)
        echo "Usage: jade-ig-poster.sh [run|generate|pick|score|fix|review|post|status] [--count N] [--theme T] [--dry-run]"
        exit 1
        ;;
esac
