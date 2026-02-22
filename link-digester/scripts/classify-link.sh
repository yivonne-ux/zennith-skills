#!/bin/bash
# classify-link.sh — Classify a URL by type and map to agent + room
# Bash 3.2 compatible (macOS)
set -uo pipefail

SCRIPT_NAME="classify-link"
LOG_FILE="$HOME/.openclaw/logs/link-digester.log"

log() {
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_NAME" "$1" >> "$LOG_FILE" 2>/dev/null
}

usage() {
  printf 'Usage: classify-link.sh <url>\n' >&2
  printf 'Returns JSON: {"type":"...","agent":"...","room":"...","domain":"...","url":"..."}\n' >&2
  exit 1
}

# --- Validate args ---
if [ $# -lt 1 ] || [ -z "$1" ]; then
  usage
fi

URL="$1"

# --- Extract domain ---
# Strip protocol
DOMAIN=$(printf '%s' "$URL" | sed 's|^[a-zA-Z]*://||' | sed 's|/.*||' | sed 's|:.*||')
# Lowercase (bash 3.2 safe)
DOMAIN=$(printf '%s' "$DOMAIN" | tr '[:upper:]' '[:lower:]')

# Extract path for article detection
URL_PATH=$(printf '%s' "$URL" | sed 's|^[a-zA-Z]*://[^/]*||')
URL_PATH=$(printf '%s' "$URL_PATH" | tr '[:upper:]' '[:lower:]')

if [ -z "$DOMAIN" ]; then
  log "ERROR: Could not extract domain from URL: $URL"
  printf '{"error":"Could not extract domain","url":"%s"}\n' "$URL"
  exit 1
fi

log "Classifying URL: $URL (domain: $DOMAIN)"

# --- Classification ---
TYPE="general"
AGENT="artemis"
ROOM="exec"

# YouTube
case "$DOMAIN" in
  *youtube.com*|*youtu.be*)
    TYPE="youtube"
    AGENT="taoz"
    ROOM="exec"
    ;;
esac

# Product marketplaces
if [ "$TYPE" = "general" ]; then
  case "$DOMAIN" in
    *shopee.*|*lazada.*|*amazon.*|*grab.*)
      TYPE="product"
      AGENT="hermes"
      ROOM="exec"
      ;;
  esac
fi

# Visual reference platforms (Pinterest, Behance, Dribbble)
if [ "$TYPE" = "general" ]; then
  case "$DOMAIN" in
    *pinterest.com*|*pin.it*|*behance.net*|*dribbble.com*)
      TYPE="visual-reference"
      AGENT="artee"
      ROOM="creative"
      ;;
  esac
fi

# Social media
if [ "$TYPE" = "general" ]; then
  case "$DOMAIN" in
    *tiktok.com*|*threads.net*)
      TYPE="social"
      AGENT="iris"
      ROOM="creative"
      ;;
    *instagram.com*)
      TYPE="social"
      AGENT="iris"
      ROOM="creative"
      ;;
    *twitter.com*|*x.com*)
      TYPE="social"
      AGENT="iris"
      ROOM="creative"
      ;;
  esac
  # Check for facebook reels specifically
  if [ "$TYPE" = "general" ]; then
    case "$DOMAIN" in
      *facebook.com*)
        case "$URL_PATH" in
          */reel*|*/reels*)
            TYPE="social"
            AGENT="iris"
            ROOM="creative"
            ;;
        esac
        ;;
    esac
  fi
fi

# Competitor domains
if [ "$TYPE" = "general" ]; then
  case "$DOMAIN" in
    *mamee.com*|\
    *gardenia.com*|\
    *farm-fresh.com*|\
    *farmfresh.com*|\
    *oatside.com*|\
    *myprotein.com*|\
    *myprotein.my*|\
    *milo.com*|\
    *nestle.com.my*|\
    *dutchlady.com.my*|\
    *nutrilite.com*|\
    *herbalife.com*|\
    *amway.my*)
      TYPE="competitor"
      AGENT="artemis"
      ROOM="build"
      ;;
  esac
fi

# Article / blog / news patterns
if [ "$TYPE" = "general" ]; then
  # Check path for article patterns
  case "$URL_PATH" in
    */blog/*|*/article/*|*/articles/*|*/news/*|*/post/*|*/posts/*|*/story/*)
      TYPE="article"
      AGENT="artemis"
      ROOM="exec"
      ;;
  esac
fi

# Article by domain (common news / blog sites)
if [ "$TYPE" = "general" ]; then
  case "$DOMAIN" in
    *medium.com*|*substack.com*|*wordpress.com*|\
    *blogspot.com*|*dev.to*|*hashnode.dev*|\
    *techcrunch.com*|*theverge.com*|*wired.com*|\
    *forbes.com*|*businessinsider.com*|*reuters.com*|\
    *bbc.com*|*nytimes.com*|*theguardian.com*|\
    *thestar.com.my*|*malaymail.com*|*nst.com.my*|\
    *says.com*|*vulcanpost.com*|*mashable.com*)
      TYPE="article"
      AGENT="artemis"
      ROOM="exec"
      ;;
  esac
fi

# --- Escape URL for JSON ---
# Replace backslash, double quote, and control chars
JSON_URL=$(printf '%s' "$URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
JSON_DOMAIN=$(printf '%s' "$DOMAIN" | sed 's/\\/\\\\/g; s/"/\\"/g')

# --- Output JSON ---
printf '{"type":"%s","agent":"%s","room":"%s","domain":"%s","url":"%s"}\n' \
  "$TYPE" "$AGENT" "$ROOM" "$JSON_DOMAIN" "$JSON_URL"

log "Classified: type=$TYPE agent=$AGENT room=$ROOM"
