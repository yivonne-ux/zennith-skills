#!/usr/bin/env bash
# reel-publish.sh — Post a reel to Instagram via Meta Graph API
#
# Usage:
#   bash reel-publish.sh VIDEO_PATH [--caption "text"] [--dry-run]
#
# Uploads video to public hosting, then publishes as IG Reel.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
IG_PUBLISH="$OPENCLAW_DIR/skills/social-publish/scripts/ig-publish.py"
POST_LOG="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
DATE=$(date +%Y-%m-%d)

VIDEO_PATH=""
CAPTION=""
DRY_RUN=0

# Parse args
while [ $# -gt 0 ]; do
    case "$1" in
        --caption) CAPTION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        *) VIDEO_PATH="$1"; shift ;;
    esac
done

if [ -z "$VIDEO_PATH" ] || [ ! -f "$VIDEO_PATH" ]; then
    echo "Usage: reel-publish.sh VIDEO_PATH [--caption \"text\"] [--dry-run]"
    exit 1
fi

echo "[reel-publish] Video: $VIDEO_PATH"
echo "[reel-publish] Size: $(du -h "$VIDEO_PATH" | cut -f1)"

# Generate caption if not provided
if [ -z "$CAPTION" ]; then
    CLAUDE_CLI=$(command -v claude 2>/dev/null || echo "")
    if [ -n "$CLAUDE_CLI" ]; then
        echo "[reel-publish] Generating caption..."
        local_tmp=$(mktemp)
        cat > "$local_tmp" << 'CAPEOF'
You are Jade (@the_jade_oracle), a warm Korean-inspired QMDJ oracle.
Write a short Instagram Reel caption (max 500 chars). Mystical, warm, inviting.
Include a hook, 1-2 lines of wisdom, a soft CTA, and 10 hashtags.
Output ONLY the caption.
CAPEOF
        CAPTION=$(cat "$local_tmp" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
        rm -f "$local_tmp"
    fi

    if [ -z "$CAPTION" ]; then
        CAPTION="Some moments speak louder than words.

This is your sign to pause, breathe, and listen to what the universe is whispering.

Save this for when you need it.

#JadeOracle #TheJadeOracle #SpiritualVibes #QMDJ #OracleReading #HealingVibes #SpiritualAwakening #MysticVibes #EnergyFlow #DailyOracle"
    fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[reel-publish] [DRY RUN] Would publish reel: $VIDEO_PATH"
    echo "[reel-publish] Caption: $(echo "$CAPTION" | head -3)..."
    exit 0
fi

# Upload video to freeimage.host (supports video)
echo "[reel-publish] Uploading video..."
VIDEO_URL=$(curl -s -X POST \
    -F "source=@$VIDEO_PATH" \
    -F "type=file" \
    -F "action=upload" \
    "https://freeimage.host/api/1/upload?key=6d207e02198a847aa98d0a2a901485a5" | \
    "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin).get('image',{}).get('url',''))" 2>/dev/null)

if [ -z "$VIDEO_URL" ] || [ "$VIDEO_URL" = "None" ]; then
    echo "[reel-publish] ERROR: Video upload failed. Trying file.io..."
    VIDEO_URL=$(curl -s -F "file=@$VIDEO_PATH" "https://file.io" | \
        "$PYTHON3" -c "import json,sys; print(json.load(sys.stdin).get('link',''))" 2>/dev/null)
fi

if [ -z "$VIDEO_URL" ] || [ "$VIDEO_URL" = "None" ]; then
    echo "[reel-publish] ERROR: All upload methods failed"
    exit 1
fi

echo "[reel-publish] Uploaded: $VIDEO_URL"

# Publish as Reel
echo "[reel-publish] Publishing reel..."
result=$("$PYTHON3" "$IG_PUBLISH" reel --video-url "$VIDEO_URL" --caption "$CAPTION" 2>&1)
echo "[reel-publish] $result"

# Log
post_id=$(echo "$result" | grep -oE '[0-9]{15,}' | tail -1 || echo "")
if [ -n "$post_id" ]; then
    mkdir -p "$(dirname "$POST_LOG")"
    echo "{\"date\":\"$DATE\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"reel\",\"video\":\"$VIDEO_PATH\",\"post_id\":\"$post_id\",\"status\":\"published\"}" >> "$POST_LOG"
    echo "[reel-publish] Published! Post ID: $post_id"
fi
