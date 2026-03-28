#!/usr/bin/env bash
# xhs-scrape.sh — Xiaohongshu content scraper
#
# Usage:
#   xhs-scrape.sh note <url>                  # Scrape single note
#   xhs-scrape.sh video <url>                 # Download video note
#   xhs-scrape.sh profile <username> [--count N]  # Scrape profile page
#   xhs-scrape.sh trending [--category CAT] [--count N]  # Trending content
#   xhs-scrape.sh search <query> [--count N]  # Search XHS

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

HOME_DIR="/Users/jennwoeiloh"
OPENCLAW="${HOME_DIR}/.openclaw"
WEB_READ="${OPENCLAW}/skills/agent-reach/scripts/web-read.sh"
SCRAPLING="${OPENCLAW}/skills/scrapling/scripts/scrape.sh"
LEARN_VIDEO="${OPENCLAW}/skills/learn-youtube/scripts/learn-video.sh"
OUTPUT_DIR="${OPENCLAW}/workspace/data/xhs-intel/$(date '+%Y-%m-%d')"

mkdir -p "$OUTPUT_DIR"

CMD="${1:-help}"
shift || true

# Parse optional args
COUNT=20
CATEGORY="food"
QUERY=""
URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count) COUNT="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    http*) URL="$1"; shift ;;
    *) QUERY="$1"; shift ;;
  esac
done

log() { echo "[xhs-scrape $(date '+%H:%M:%S')] $1"; }

scrape_url() {
  local url="$1"
  local out="$2"
  local label="${3:-$url}"

  log "Scraping: ${label}"

  # Try scrapling first (better anti-bot)
  if [[ -x "$SCRAPLING" ]]; then
    if timeout 45 bash "$SCRAPLING" fetch "$url" --output md > "$out" 2>/dev/null; then
      local size
      size=$(wc -c < "$out" | tr -d ' ')
      if [[ "$size" -gt 100 ]]; then
        log "  OK (scrapling): ${size}b"
        return 0
      fi
    fi
  fi

  # Fallback to web-read
  if timeout 30 bash "$WEB_READ" "$url" > "$out" 2>/dev/null; then
    local size
    size=$(wc -c < "$out" | tr -d ' ')
    if [[ "$size" -gt 100 ]]; then
      log "  OK (web-read): ${size}b"
      return 0
    fi
  fi

  log "  FAIL: ${label}"
  return 1
}

case "$CMD" in
  note)
    [[ -z "$URL" ]] && { echo "Usage: xhs-scrape.sh note <url>"; exit 1; }
    note_id=$(echo "$URL" | grep -oE '[a-f0-9]{24}' | head -1)
    out="${OUTPUT_DIR}/note-${note_id:-unknown}.md"
    scrape_url "$URL" "$out" "XHS note"
    cat "$out"
    ;;

  video)
    [[ -z "$URL" ]] && { echo "Usage: xhs-scrape.sh video <url>"; exit 1; }
    log "Downloading XHS video via learn-video.sh"
    bash "$LEARN_VIDEO" "$URL"
    ;;

  profile)
    username="${QUERY:-}"
    [[ -z "$username" ]] && { echo "Usage: xhs-scrape.sh profile <username> [--count N]"; exit 1; }
    out="${OUTPUT_DIR}/profile-${username}.md"
    scrape_url "https://www.xiaohongshu.com/user/profile/${username}" "$out" "XHS profile: ${username}"
    log "Profile saved: ${out}"
    cat "$out"
    ;;

  trending)
    log "Scraping XHS trending: category=${CATEGORY}"
    out="${OUTPUT_DIR}/trending-${CATEGORY}.md"
    scrape_url "https://www.xiaohongshu.com/explore?channel_id=${CATEGORY}" "$out" "XHS trending: ${CATEGORY}"
    log "Trending saved: ${out}"
    ;;

  search)
    [[ -z "$QUERY" ]] && { echo "Usage: xhs-scrape.sh search <query> [--count N]"; exit 1; }
    encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))" 2>/dev/null || echo "$QUERY")
    out="${OUTPUT_DIR}/search-${QUERY// /-}.md"
    scrape_url "https://www.xiaohongshu.com/search_result?keyword=${encoded}" "$out" "XHS search: ${QUERY}"
    log "Search saved: ${out}"
    ;;

  help|*)
    echo "XHS Scraper — Xiaohongshu Content Intelligence"
    echo ""
    echo "Usage:"
    echo "  xhs-scrape.sh note <url>                    Scrape single note"
    echo "  xhs-scrape.sh video <url>                   Download video note"
    echo "  xhs-scrape.sh profile <username> [--count N] Scrape profile"
    echo "  xhs-scrape.sh trending [--category CAT]     Trending content"
    echo "  xhs-scrape.sh search <query>                Search XHS"
    echo ""
    echo "Output: ${OUTPUT_DIR}/"
    ;;
esac
