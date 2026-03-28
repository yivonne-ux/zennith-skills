#!/usr/bin/env bash
# jade-ig-comment-oracle.sh — IG Comment Auto-Reply with Oracle Card Readings
#
# Polls Jade Oracle's recent IG posts for birth year comments.
# Replies publicly with a personalized oracle card pull (powered silently by QMDJ).
# Funnels to DM for full readings.
#
# Usage:
#   bash jade-ig-comment-oracle.sh poll       # Check recent posts for birth year comments
#   bash jade-ig-comment-oracle.sh reply-all  # Process & reply to all unprocessed comments
#   bash jade-ig-comment-oracle.sh test 1995  # Preview reply for a birth year (no posting)
#   bash jade-ig-comment-oracle.sh status     # Show stats and processed comments
#
# Cron: */15 * * * * bash jade-ig-comment-oracle.sh reply-all >> ~/.openclaw/logs/jade-comment-oracle.log 2>&1

set -euo pipefail

###############################################################################
# Config
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
SECRETS_FILE="$HOME/.openclaw/secrets/meta-marketing.env"
STATE_DIR="$HOME/.openclaw/workspace/data/jade-oracle/comment-oracle"
PROCESSED_FILE="$STATE_DIR/processed-comments.txt"
STATS_FILE="$STATE_DIR/stats.json"
LOG_DIR="$HOME/.openclaw/logs"
API_VERSION="v21.0"
GRAPH_URL="https://graph.facebook.com/$API_VERSION"

# Rate limits (Meta API + natural behavior)
MAX_REPLIES_PER_RUN=10
MIN_DELAY_BETWEEN_REPLIES=8  # seconds — look natural, not bot-like
POSTS_TO_CHECK=5              # how many recent posts to scan

# Birth year detection
MIN_YEAR=1950
MAX_YEAR=2010

mkdir -p "$STATE_DIR" "$LOG_DIR"
touch "$PROCESSED_FILE"

###############################################################################
# Helpers
###############################################################################

log()  { echo "[jade-oracle-reply] $(date +"%H:%M:%S") $*" >&2; }
warn() { echo "[jade-oracle-reply] $(date +"%H:%M:%S") WARN: $*" >&2; }
err()  { echo "[jade-oracle-reply] $(date +"%H:%M:%S") ERROR: $*" >&2; }

###############################################################################
# Load Meta credentials
###############################################################################

load_secrets() {
    if [[ -f "$SECRETS_FILE" ]]; then
        while IFS='=' read -r key value; do
            key=$(echo "$key" | tr -d '[:space:]')
            [[ -z "$key" || "$key" == \#* ]] && continue
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            export "$key=$value" 2>/dev/null || true
        done < "$SECRETS_FILE"
    fi
}

load_secrets

check_credentials() {
    if [[ -z "${META_ACCESS_TOKEN:-}" ]] || [[ -z "${IG_USER_ID:-}" ]]; then
        err "Meta credentials not set. Run: bash meta-token-manager.sh status"
        exit 1
    fi
    log "Credentials loaded (IG User: ${IG_USER_ID})"
}

###############################################################################
# Meta Graph API helpers
###############################################################################

graph_get() {
    local endpoint="$1"
    local params="${2:-}"
    local url="${GRAPH_URL}${endpoint}?access_token=${META_ACCESS_TOKEN}"
    [[ -n "$params" ]] && url="${url}&${params}"
    curl -s --max-time 30 "$url" 2>/dev/null
}

graph_post() {
    local endpoint="$1"
    local data="$2"
    curl -s --max-time 30 -X POST \
        "${GRAPH_URL}${endpoint}" \
        -d "access_token=${META_ACCESS_TOKEN}" \
        -d "$data" 2>/dev/null
}

###############################################################################
# Get recent posts
###############################################################################

get_recent_posts() {
    local count="${1:-$POSTS_TO_CHECK}"
    log "Fetching last $count posts..."

    local response
    response=$(graph_get "/${IG_USER_ID}/media" "fields=id,caption,timestamp,comments_count&limit=${count}")

    # Check for empty/error response before JSON parse
    if [[ -z "$response" ]] || [[ "$response" == "null" ]] || ! echo "$response" | grep -q '^{'; then
        err "Meta API returned empty or non-JSON response for media endpoint"
        echo "$response" | head -c 200 >&2
        return 1
    fi

    "$PYTHON3" -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    if 'error' in data:
        print(f'ERROR: {data[\"error\"].get(\"message\", \"unknown\")}', file=sys.stderr)
        sys.exit(1)
    posts = data.get('data', [])
    for p in posts:
        ccount = p.get('comments_count', 0)
        ts = p.get('timestamp', '')[:10]
        caption = (p.get('caption', '') or '')[:50].replace('\n', ' ')
        print(f'{p[\"id\"]}|{ccount}|{ts}|{caption}')
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" "$response"
}

###############################################################################
# Get comments for a post
###############################################################################

get_comments() {
    local post_id="$1"
    local response
    response=$(graph_get "/${post_id}/comments" "fields=id,text,username,timestamp&limit=50")

    # Check for empty/error response before JSON parse
    if [[ -z "$response" ]] || [[ "$response" == "null" ]] || ! echo "$response" | grep -q '^{'; then
        err "Meta API returned empty or non-JSON response for comments endpoint (post: $post_id)"
        return 1
    fi

    "$PYTHON3" -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    if 'error' in data:
        print(f'ERROR: {data[\"error\"].get(\"message\", \"unknown\")}', file=sys.stderr)
        sys.exit(1)
    comments = data.get('data', [])
    for c in comments:
        text = c.get('text', '').replace('|', ' ').replace('\n', ' ')
        print(f'{c[\"id\"]}|{c.get(\"username\", \"unknown\")}|{text}|{c.get(\"timestamp\", \"\")}')
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" "$response"
}

###############################################################################
# Extract birth year from comment text
###############################################################################

extract_birth_year() {
    local text="$1"
    "$PYTHON3" -c "
import re, sys

text = sys.argv[1]

# Match 4-digit years in range
years = re.findall(r'\b(19[5-9]\d|200\d|201[0-5])\b', text)
if years:
    print(years[0])
    sys.exit(0)

# Match 2-digit years (90 → 1990, 02 → 2002)
short_years = re.findall(r'\b(\d{2})\b', text)
for y in short_years:
    yi = int(y)
    if yi >= 50:
        print(f'19{y}')
        sys.exit(0)
    elif yi <= 15:
        print(f'20{y.zfill(2)}')
        sys.exit(0)

sys.exit(1)
" "$text" 2>/dev/null
}

###############################################################################
# Generate oracle card reply
###############################################################################

generate_reply() {
    local year="$1"
    local username="$2"

    # Run the quick oracle engine
    local reply
    reply=$("$PYTHON3" "${SCRIPT_DIR}/jade-quick-oracle.py" --year "$year" --mode ig-reply 2>/dev/null)

    if [[ -z "$reply" ]]; then
        err "Failed to generate oracle reading for year $year"
        return 1
    fi

    # Prepend @username
    echo "@${username} ${reply}"
}

###############################################################################
# Post reply to a comment
###############################################################################

post_reply() {
    local comment_id="$1"
    local reply_text="$2"

    # URL-encode the reply text
    local encoded
    encoded=$("$PYTHON3" -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$reply_text")

    local response
    response=$(graph_post "/${comment_id}/replies" "message=${encoded}")

    # Check for success — guard against empty response
    if [[ -z "$response" ]] || ! echo "$response" | grep -q '^{'; then
        err "Reply API returned empty or non-JSON response"
        return 1
    fi

    "$PYTHON3" -c "
import json, sys
try:
    r = json.loads(sys.argv[1])
    if 'id' in r:
        print(r['id'])
    elif 'error' in r:
        print(f'ERROR: {r[\"error\"].get(\"message\", str(r[\"error\"]))}', file=sys.stderr)
        sys.exit(1)
    else:
        print(f'ERROR: Unexpected: {sys.argv[1][:200]}', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" "$response"
}

###############################################################################
# Mark comment as processed
###############################################################################

mark_processed() {
    local comment_id="$1"
    local username="$2"
    local year="$3"
    echo "${comment_id}|${username}|${year}|$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROCESSED_FILE"
}

is_processed() {
    local comment_id="$1"
    grep -q "^${comment_id}|" "$PROCESSED_FILE" 2>/dev/null
}

###############################################################################
# Update stats
###############################################################################

update_stats() {
    local action="$1"  # reply_sent, comment_scanned, post_scanned

    "$PYTHON3" -c "
import json, sys, os
from datetime import datetime

stats_file = sys.argv[1]
action = sys.argv[2]

stats = {}
if os.path.exists(stats_file):
    try:
        with open(stats_file) as f:
            stats = json.load(f)
    except: pass

today = datetime.now().strftime('%Y-%m-%d')
if 'daily' not in stats: stats['daily'] = {}
if today not in stats['daily']: stats['daily'][today] = {'replies': 0, 'comments_scanned': 0, 'posts_scanned': 0}

if action == 'reply_sent':
    stats['daily'][today]['replies'] = stats['daily'][today].get('replies', 0) + 1
    stats['total_replies'] = stats.get('total_replies', 0) + 1
elif action == 'comment_scanned':
    stats['daily'][today]['comments_scanned'] = stats['daily'][today].get('comments_scanned', 0) + 1
elif action == 'post_scanned':
    stats['daily'][today]['posts_scanned'] = stats['daily'][today].get('posts_scanned', 0) + 1

stats['last_run'] = datetime.now().isoformat()

# Keep only last 30 days of daily stats
dates = sorted(stats.get('daily', {}).keys())
if len(dates) > 30:
    for d in dates[:-30]:
        del stats['daily'][d]

with open(stats_file, 'w') as f:
    json.dump(stats, f, indent=2)
" "$STATS_FILE" "$action"
}

###############################################################################
# Command: poll — scan posts and show birth year comments
###############################################################################

cmd_poll() {
    check_credentials

    log "Scanning recent posts for birth year comments..."

    local posts
    posts=$(get_recent_posts)

    if [[ -z "$posts" ]]; then
        log "No posts found."
        return 0
    fi

    local total_found=0

    while IFS='|' read -r post_id comment_count ts caption; do
        [[ -z "$post_id" ]] && continue
        [[ "$comment_count" == "0" ]] && continue

        update_stats "post_scanned"
        log "Post $post_id ($ts, ${comment_count} comments): $caption"

        local comments
        comments=$(get_comments "$post_id")

        while IFS='|' read -r comment_id username text timestamp; do
            [[ -z "$comment_id" ]] && continue
            update_stats "comment_scanned"

            local year
            year=$(extract_birth_year "$text" 2>/dev/null || true)

            if [[ -n "$year" ]]; then
                local status="NEW"
                is_processed "$comment_id" && status="DONE"
                total_found=$((total_found + 1))
                echo "  [$status] @$username: \"$text\" → Year: $year"
            fi
        done <<< "$comments"

    done <<< "$posts"

    log "Found $total_found birth year comments total."
}

###############################################################################
# Command: reply-all — process and reply to all new birth year comments
###############################################################################

cmd_reply_all() {
    check_credentials

    log "=== Oracle Comment Reply Run ==="

    local posts
    posts=$(get_recent_posts)

    if [[ -z "$posts" ]]; then
        log "No posts found."
        return 0
    fi

    local replies_sent=0

    while IFS='|' read -r post_id comment_count ts caption; do
        [[ -z "$post_id" ]] && continue
        [[ "$comment_count" == "0" ]] && continue

        update_stats "post_scanned"

        local comments
        comments=$(get_comments "$post_id")

        while IFS='|' read -r comment_id username text timestamp; do
            [[ -z "$comment_id" ]] && continue
            update_stats "comment_scanned"

            # Skip already processed
            if is_processed "$comment_id"; then
                continue
            fi

            # Skip our own comments (Jade's account)
            if [[ "$username" == "jadeoracle" ]] || [[ "$username" == "jade.oracle" ]] || [[ "$username" == "jade_oracle" ]]; then
                continue
            fi

            # Try to extract birth year
            local year
            year=$(extract_birth_year "$text" 2>/dev/null || true)

            if [[ -z "$year" ]]; then
                continue
            fi

            # Rate limit check
            if [[ $replies_sent -ge $MAX_REPLIES_PER_RUN ]]; then
                log "Rate limit reached ($MAX_REPLIES_PER_RUN replies). Will continue next run."
                break 2
            fi

            log "  Found: @$username said '$text' → Year: $year"

            # Generate oracle reading
            local reply_text
            reply_text=$(generate_reply "$year" "$username")

            if [[ -z "$reply_text" ]]; then
                warn "Failed to generate reply for @$username ($year)"
                continue
            fi

            log "  Reply preview: ${reply_text:0:80}..."

            # Post the reply
            local reply_id
            reply_id=$(post_reply "$comment_id" "$reply_text" 2>/dev/null || true)

            if [[ -n "$reply_id" && "$reply_id" != ERROR* ]]; then
                log "  ✓ Replied to @$username (reply ID: $reply_id)"
                mark_processed "$comment_id" "$username" "$year"
                update_stats "reply_sent"
                replies_sent=$((replies_sent + 1))

                # Natural delay between replies
                if [[ $replies_sent -lt $MAX_REPLIES_PER_RUN ]]; then
                    local delay=$((MIN_DELAY_BETWEEN_REPLIES + RANDOM % 7))
                    log "  Waiting ${delay}s (natural pacing)..."
                    sleep "$delay"
                fi
            else
                warn "  ✗ Failed to reply to @$username: $reply_id"
                # Still mark as processed to avoid retry loops on permission errors
                mark_processed "$comment_id" "$username" "$year"
            fi

        done <<< "$comments"

    done <<< "$posts"

    log "=== Run complete: $replies_sent replies sent ==="
}

###############################################################################
# Command: test — preview a reply without posting
###############################################################################

cmd_test() {
    local year="${1:-}"

    if [[ -z "$year" ]]; then
        err "Usage: jade-ig-comment-oracle.sh test <birth_year>"
        exit 1
    fi

    echo "=== Oracle Card Reply Preview (Year: $year) ==="
    echo ""
    echo "--- IG Comment Reply ---"
    "$PYTHON3" "${SCRIPT_DIR}/jade-quick-oracle.py" --year "$year" --mode ig-reply
    echo ""
    echo "--- DM Teaser (sent after they DM 'READING') ---"
    "$PYTHON3" "${SCRIPT_DIR}/jade-quick-oracle.py" --year "$year" --mode dm-teaser
    echo ""
    echo "--- Full Data ---"
    "$PYTHON3" "${SCRIPT_DIR}/jade-quick-oracle.py" --year "$year" --mode full-json
}

###############################################################################
# Command: status
###############################################################################

cmd_status() {
    echo "=== Jade Oracle Comment Bot Status ==="
    echo ""

    # Credentials
    load_secrets
    if [[ -n "${META_ACCESS_TOKEN:-}" ]] && [[ -n "${IG_USER_ID:-}" ]]; then
        echo "Credentials: ✓ Loaded (IG User: ${IG_USER_ID})"
    else
        echo "Credentials: ✗ Missing — run: bash meta-token-manager.sh status"
    fi

    # Processed count
    local total_processed
    total_processed=$(wc -l < "$PROCESSED_FILE" 2>/dev/null | tr -d ' ')
    echo "Total processed comments: ${total_processed:-0}"

    # Stats
    if [[ -f "$STATS_FILE" ]]; then
        "$PYTHON3" -c "
import json
with open('$STATS_FILE') as f:
    stats = json.load(f)
print(f'Total replies sent: {stats.get(\"total_replies\", 0)}')
print(f'Last run: {stats.get(\"last_run\", \"never\")}')
daily = stats.get('daily', {})
if daily:
    latest = sorted(daily.keys())[-1]
    d = daily[latest]
    print(f'Today ({latest}): {d.get(\"replies\", 0)} replies, {d.get(\"comments_scanned\", 0)} comments scanned')
"
    else
        echo "Stats: No data yet"
    fi

    echo ""

    # Recent processed
    echo "Last 5 processed comments:"
    tail -5 "$PROCESSED_FILE" 2>/dev/null | while IFS='|' read -r cid user year ts; do
        echo "  @$user (born $year) — $ts"
    done
}

###############################################################################
# Main
###############################################################################

if [[ $# -lt 1 ]]; then
    echo "Usage: jade-ig-comment-oracle.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  poll        Scan recent posts for birth year comments"
    echo "  reply-all   Process & reply to all new birth year comments"
    echo "  test <year> Preview oracle reply for a birth year (no posting)"
    echo "  status      Show bot stats and recent activity"
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    poll)      cmd_poll ;;
    reply-all) cmd_reply_all ;;
    test)      cmd_test "$@" ;;
    status)    cmd_status ;;
    *)         err "Unknown command: $COMMAND"; exit 1 ;;
esac
