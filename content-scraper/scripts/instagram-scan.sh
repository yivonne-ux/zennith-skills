#!/usr/bin/env bash
# instagram-scan.sh — Instagram Content Scanner
#
# Note: Instagram Meta Graph API requires Meta Developer account (paid).
# For now, uses web scraping via instagrapi (requires account credentials).
#
# Usage:
#   bash instagram-scan.sh profile <username>
#   bash instagram-scan.sh hashtag <hashtag>
#
# Returns: post formats, captions, engagement patterns.

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

CMD="${1:-help}"
TARGET="${2:-}"
shift 2>/dev/null || true

SKILLS_DIR="$HOME/.openclaw/skills"
SEED_STORE="$SKILLS_DIR/content-seed-bank/scripts/seed-store.sh"
RAG_STORE="$SKILLS_DIR/rag-memory/scripts/memory-store.sh"
LOG="$HOME/.openclaw/logs/content-scraper.log"
OUTPUT_DIR="$HOME/.openclaw/workspace/data/scrapes/instagram"

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INSTAGRAM] $1" >> "$LOG"
}

# Check for Meta API token or fallback to web scraping
METADATA_TOKEN="${META_ACCESS_TOKEN:-}"

case "$CMD" in

  profile)
    if [ -z "$TARGET" ]; then
      echo "Usage: instagram-scan.sh profile <username>"
      exit 1
    fi

    log "PROFILE: $TARGET"

    if [ -n "$METADATA_TOKEN" ]; then
      echo "ERROR: Instagram Meta Graph API integration not implemented"
      echo "Get token from Meta Developer console with 'Instagram Basic Display' or 'Page Feed' API"
    else
      echo "ERROR: META_ACCESS_TOKEN not set"
      echo ""
      echo "Instagram API options:"
      echo "  1. Meta Developer Console (paid): Basic Display API, Page Feed"
      echo "  2. apify.com scraper (~RM 100/mo)"
      echo "  3. Manual web scraping (requires credentials)"
    fi
    exit 1
    ;;

  hashtag)
    if [ -z "$TARGET" ]; then
      echo "Usage: instagram-scan.sh hashtag <hashtag>"
      exit 1
    fi

    log "HASHTAG: $TARGET"

    echo "ERROR: Instagram hashtag analytics requires API access"
    echo "Use Apify.com or manual Instagram web scraping"
    exit 1
    ;;

  *)
    echo "Instagram Scanner — GAIA Content Scraper"
    echo ""
    echo "Platforms: Instagram (Meta Graph API)"
    echo ""
    echo "Usage: instagram-scan.sh <command> <target>"
    echo ""
    echo "Commands:"
    echo "  profile <username>   Scan a profile's posts"
    echo "  hashtag <tag>        Analyze hashtag trends"
    echo ""
    echo "Requires: META_ACCESS_TOKEN from Meta Developer Console"
    echo "Get token: developers.meta.com → Apps → Create App → Instagram"
    ;;
esac
