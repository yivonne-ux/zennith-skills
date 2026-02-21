#!/bin/bash
# extract-visual-ref.sh — Download visual references from Pinterest, Behance, Dribbble, etc.
# Bash 3.2 compatible (macOS) — no GNU tools, no declare -A, no ${var,,}
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="extract-visual-ref"
LOG_FILE="$HOME/.openclaw/logs/visual-ref.log"
REF_DIR="$HOME/.openclaw/workspace/data/references"
EXTRACT_PY="$SCRIPT_DIR/extract_image_url.py"

# --- Logging ---
log() {
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_NAME" "$1" >> "$LOG_FILE" 2>/dev/null
}

# --- Usage ---
usage() {
  printf 'Usage: extract-visual-ref.sh <url>\n' >&2
  printf 'Downloads visual reference from Pinterest/Behance/Dribbble/Instagram/other\n' >&2
  printf 'Returns JSON: {"platform":"...","image_url":"...","local_path":"...","status":"ok"}\n' >&2
  exit 1
}

# --- JSON-safe escape ---
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

# --- Output JSON result ---
output_json() {
  _platform="$1"
  _image_url="$2"
  _local_path="$3"
  _status="$4"
  _error="${5:-}"

  _platform_esc=$(json_escape "$_platform")
  _image_url_esc=$(json_escape "$_image_url")
  _local_path_esc=$(json_escape "$_local_path")
  _error_esc=$(json_escape "$_error")

  if [ -n "$_error" ]; then
    printf '{"platform":"%s","image_url":"%s","local_path":"%s","status":"%s","error":"%s"}\n' \
      "$_platform_esc" "$_image_url_esc" "$_local_path_esc" "$_status" "$_error_esc"
  else
    printf '{"platform":"%s","image_url":"%s","local_path":"%s","status":"%s"}\n' \
      "$_platform_esc" "$_image_url_esc" "$_local_path_esc" "$_status"
  fi
}

# --- Validate args ---
if [ $# -lt 1 ] || [ -z "$1" ]; then
  usage
fi

URL="$1"

# Ensure output directory exists
mkdir -p "$REF_DIR" 2>/dev/null

log "Starting visual reference extraction: $URL"

# Check Python extractor exists
if [ ! -f "$EXTRACT_PY" ]; then
  log "ERROR: extract_image_url.py not found at $EXTRACT_PY"
  output_json "unknown" "" "" "error" "Python extractor not found"
  exit 1
fi

# --- Detect platform ---
DOMAIN=$(printf '%s' "$URL" | sed 's|^[a-zA-Z]*://||' | sed 's|/.*||' | sed 's|:.*||')
DOMAIN=$(printf '%s' "$DOMAIN" | tr '[:upper:]' '[:lower:]')

PLATFORM="other"
case "$DOMAIN" in
  *pinterest.com*|*pin.it*)
    PLATFORM="pinterest"
    ;;
  *behance.net*)
    PLATFORM="behance"
    ;;
  *dribbble.com*)
    PLATFORM="dribbble"
    ;;
  *instagram.com*)
    PLATFORM="instagram"
    ;;
esac

log "Detected platform: $PLATFORM (domain: $DOMAIN)"

# --- User agent strings ---
# Instagram needs a more aggressive mobile user-agent
UA_DESKTOP="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
UA_MOBILE="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

if [ "$PLATFORM" = "instagram" ]; then
  UA="$UA_MOBILE"
else
  UA="$UA_DESKTOP"
fi

# --- Fetch the page HTML ---
TEMP_HTML=$(mktemp /tmp/visual-ref-XXXXXX.html)

log "Fetching URL with curl..."
HTTP_CODE=$(curl -s -o "$TEMP_HTML" -w '%{http_code}' \
  -L \
  -H "User-Agent: $UA" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: en-US,en;q=0.9" \
  --max-time 30 \
  "$URL" 2>>"$LOG_FILE")

if [ "$HTTP_CODE" -lt 200 ] 2>/dev/null || [ "$HTTP_CODE" -ge 400 ] 2>/dev/null; then
  log "ERROR: HTTP $HTTP_CODE fetching $URL"
  rm -f "$TEMP_HTML"
  output_json "$PLATFORM" "" "" "error" "HTTP $HTTP_CODE"
  exit 1
fi

HTML_SIZE=$(wc -c < "$TEMP_HTML" | tr -d ' ')
log "Fetched $HTML_SIZE bytes (HTTP $HTTP_CODE)"

if [ "$HTML_SIZE" -lt 100 ]; then
  log "ERROR: HTML response too small ($HTML_SIZE bytes) — likely blocked"
  rm -f "$TEMP_HTML"
  output_json "$PLATFORM" "" "" "error" "Response too small, likely blocked"
  exit 1
fi

# --- Extract image URL using python3 ---
IMAGE_URL=$(python3 "$EXTRACT_PY" "$TEMP_HTML" "$PLATFORM" 2>>"$LOG_FILE")

rm -f "$TEMP_HTML"

# --- Validate extracted URL ---
if [ -z "$IMAGE_URL" ]; then
  log "ERROR: Could not extract image URL from $URL"
  output_json "$PLATFORM" "" "" "error" "No image URL found in page"
  exit 1
fi

log "Extracted image URL: $IMAGE_URL"

# --- Determine file extension ---
# Extract extension from URL path (strip query params first)
URL_PATH_CLEAN=$(printf '%s' "$IMAGE_URL" | sed 's/[?#].*//')
EXT=$(printf '%s' "$URL_PATH_CLEAN" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')

# Validate extension, default to jpg
case "$EXT" in
  jpg|jpeg|png|webp|gif|svg) ;;
  *) EXT="jpg" ;;
esac

# --- Generate timestamped filename ---
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
FILENAME="${PLATFORM}-ref-${TIMESTAMP}.${EXT}"
LOCAL_PATH="${REF_DIR}/${FILENAME}"

log "Downloading image to: $LOCAL_PATH"

# --- Download the image ---
DL_CODE=$(curl -s -o "$LOCAL_PATH" -w '%{http_code}' \
  -L \
  -H "User-Agent: $UA" \
  -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
  -H "Referer: $URL" \
  --max-time 60 \
  "$IMAGE_URL" 2>>"$LOG_FILE")

if [ "$DL_CODE" -lt 200 ] 2>/dev/null || [ "$DL_CODE" -ge 400 ] 2>/dev/null; then
  log "ERROR: HTTP $DL_CODE downloading image from $IMAGE_URL"
  rm -f "$LOCAL_PATH"
  output_json "$PLATFORM" "$IMAGE_URL" "" "error" "Image download failed (HTTP $DL_CODE)"
  exit 1
fi

# Verify file was downloaded and has content
DL_SIZE=$(wc -c < "$LOCAL_PATH" 2>/dev/null | tr -d ' ')
if [ -z "$DL_SIZE" ] || [ "$DL_SIZE" -lt 1000 ]; then
  log "ERROR: Downloaded file too small ($DL_SIZE bytes) — probably not a real image"
  rm -f "$LOCAL_PATH"
  output_json "$PLATFORM" "$IMAGE_URL" "" "error" "Downloaded file too small (${DL_SIZE} bytes)"
  exit 1
fi

log "Downloaded $DL_SIZE bytes to $LOCAL_PATH"

# --- Output result ---
output_json "$PLATFORM" "$IMAGE_URL" "$LOCAL_PATH" "ok"

log "Visual reference extraction complete: $PLATFORM -> $LOCAL_PATH"
