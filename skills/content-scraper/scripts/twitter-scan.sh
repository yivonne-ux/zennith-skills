#!/usr/bin/env bash
# twitter-scan.sh — X/Twitter Trend Scanner
#
# Note: X.com offers free Twitter API tier with limited read access (500K tweets/month).
# Get BEARER_TOKEN at developer.x.com → API access.
#
# Usage:
#   bash twitter-scan.sh search <query>
#   bash twitter-scan.sh trending
#
# Returns: trending topics, keyword sentiment, key opinion leaders.

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

CMD="${1:-help}"
TARGET="${2:-}"
shift 2>/dev/null || true

SKILLS_DIR="$HOME/.openclaw/skills"
SEED_STORE="$SKILLS_DIR/content-seed-bank/scripts/seed-store.sh"
RAG_STORE="$SKILLS_DIR/rag-memory/scripts/memory-store.sh"
LOG="$HOME/.openclaw/logs/content-scraper.log"
OUTPUT_DIR="$HOME/.openclaw/workspace/data/scrapes/twitter"

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TWITTER] $1" >> "$LOG"
}

TWITTER_TOKEN="${TWITTER_BEARER_TOKEN:-}"

case "$CMD" in

  search)
    if [ -z "$TARGET" ]; then
      echo "Usage: twitter-scan.sh search <query>"
      exit 1
    fi

    log "SEARCH: $TARGET"

    if [ -n "$TWITTER_TOKEN" ]; then
      echo "ERROR: X/Twitter API v2 integration not implemented"
      echo ""
      echo "Get token: developer.x.com → Twitter API → Apply for Basic tier"
    else
      echo "ERROR: TWITTER_BEARER_TOKEN not set"
      echo ""
      echo "X.com API options:"
      echo "  1. X.com Basic tier (free, 500K tweets/month)"
      echo "  2. Search.twitter.com or apify.com (~RM 100/mo)"
    fi
    exit 1
    ;;

  trending)
    log "TRENDING: default"

    if [ -n "$TWITTER_TOKEN" ]; then
      echo "ERROR: X/Twitter API v2 trending integration not implemented"
    else
      echo "ERROR: TWITTER_BEARER_TOKEN not set"
      echo ""
      echo "Use X.com Basic tier (free) or apify.com Twitter Trending (~RM 100/mo)"
    fi
    exit 1
    ;;

  *)
    echo "Twitter Scanner — GAIA Content Scraper"
    echo ""
    echo "Platforms: X.com (Twitter API v2)"
    echo ""
    echo "Usage: twitter-scan.sh <command> [target]"
    echo ""
    echo "Commands:"
    echo "  search <query>        Search tweets for keywords"
    echo "  trending              Get trending topics"
    echo ""
    echo "Requires: TWITTER_BEARER_TOKEN"
    echo "Get token: developer.x.com → Twitter API → Basic tier"
    ;;
esac
