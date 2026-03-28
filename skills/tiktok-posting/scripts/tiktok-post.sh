#!/usr/bin/env bash
# tiktok-post.sh — TikTok Content Posting API client
#
# Usage:
#   tiktok-post.sh status                           Check auth status
#   tiktok-post.sh upload --video FILE --caption TXT Upload video
#   tiktok-post.sh publish --content-dir DIR         Publish from pipeline
#   tiktok-post.sh schedule --video FILE --schedule DT Schedule post
#   tiktok-post.sh refresh                           Refresh access token

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

HOME_DIR="/Users/jennwoeiloh"
AUTH_FILE="${HOME_DIR}/.openclaw/secrets/tiktok-auth.env"
API_BASE="https://open.tiktokapis.com"
LOG_FILE="${HOME_DIR}/.openclaw/logs/tiktok-posting.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[tiktok $(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# Load auth
load_auth() {
  if [[ ! -f "$AUTH_FILE" ]]; then
    log "ERROR: Auth file not found at ${AUTH_FILE}"
    log "Please set up TikTok Developer App first."
    log "See: /Users/jennwoeiloh/.openclaw/skills/tiktok-posting/SKILL.md"
    return 1
  fi
  # shellcheck source=/dev/null
  source "$AUTH_FILE"

  if [[ -z "${TIKTOK_CLIENT_KEY:-}" ]] || [[ -z "${TIKTOK_ACCESS_TOKEN:-}" ]]; then
    log "ERROR: Missing TIKTOK_CLIENT_KEY or TIKTOK_ACCESS_TOKEN in ${AUTH_FILE}"
    return 1
  fi
  return 0
}

# Check auth status
check_status() {
  log "=== TikTok Auth Status ==="
  if ! load_auth; then
    echo "Status: NOT CONFIGURED"
    echo ""
    echo "To set up:"
    echo "1. Register at https://developers.tiktok.com"
    echo "2. Create app with Content Posting API scope"
    echo "3. Get OAuth credentials"
    echo "4. Create ${AUTH_FILE} with:"
    echo "   TIKTOK_CLIENT_KEY=your_key"
    echo "   TIKTOK_CLIENT_SECRET=your_secret"
    echo "   TIKTOK_ACCESS_TOKEN=your_token"
    echo "   TIKTOK_REFRESH_TOKEN=your_refresh"
    return 1
  fi

  # Test token validity
  local response
  response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer ${TIKTOK_ACCESS_TOKEN}" \
    "${API_BASE}/v2/user/info/?fields=display_name,avatar_url,follower_count" 2>/dev/null)

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "200" ]]; then
    log "Status: ACTIVE"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
  else
    log "Status: TOKEN EXPIRED or INVALID (HTTP ${http_code})"
    echo "Run: tiktok-post.sh refresh"
  fi
}

# Refresh access token
refresh_token() {
  load_auth || return 1

  if [[ -z "${TIKTOK_REFRESH_TOKEN:-}" ]]; then
    log "ERROR: No refresh token available"
    return 1
  fi

  local response
  response=$(curl -s -X POST "${API_BASE}/v2/oauth/token/" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_key=${TIKTOK_CLIENT_KEY}" \
    -d "client_secret=${TIKTOK_CLIENT_SECRET}" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=${TIKTOK_REFRESH_TOKEN}" 2>/dev/null)

  local new_access
  new_access=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
  local new_refresh
  new_refresh=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('refresh_token',''))" 2>/dev/null)

  if [[ -n "$new_access" ]]; then
    # Update auth file
    sed -i '' "s|^TIKTOK_ACCESS_TOKEN=.*|TIKTOK_ACCESS_TOKEN=${new_access}|" "$AUTH_FILE"
    if [[ -n "$new_refresh" ]]; then
      sed -i '' "s|^TIKTOK_REFRESH_TOKEN=.*|TIKTOK_REFRESH_TOKEN=${new_refresh}|" "$AUTH_FILE"
    fi
    log "Token refreshed successfully"
  else
    log "ERROR: Token refresh failed"
    echo "$response"
    return 1
  fi
}

# Upload and publish video
upload_video() {
  load_auth || return 1

  local video_file="" caption="" hashtags="" privacy="PUBLIC_TO_EVERYONE"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --video) video_file="$2"; shift 2 ;;
      --caption) caption="$2"; shift 2 ;;
      --hashtags) hashtags="$2"; shift 2 ;;
      --privacy) privacy="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ -z "$video_file" ]] || [[ ! -f "$video_file" ]]; then
    log "ERROR: Video file not found: ${video_file}"
    return 1
  fi

  local file_size
  file_size=$(wc -c < "$video_file" | tr -d ' ')
  local full_caption="${caption}"
  [[ -n "$hashtags" ]] && full_caption="${caption} ${hashtags}"

  log "Uploading: ${video_file} (${file_size}b)"
  log "Caption: ${full_caption:0:100}..."

  # Step 1: Init upload
  local init_response
  init_response=$(curl -s -X POST "${API_BASE}/v2/post/publish/inbox/video/init/" \
    -H "Authorization: Bearer ${TIKTOK_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"post_info\": {
        \"title\": \"${full_caption:0:2200}\",
        \"privacy_level\": \"${privacy}\",
        \"disable_duet\": false,
        \"disable_comment\": false,
        \"disable_stitch\": false
      },
      \"source_info\": {
        \"source\": \"FILE_UPLOAD\",
        \"video_size\": ${file_size},
        \"chunk_size\": ${file_size},
        \"total_chunk_count\": 1
      }
    }" 2>/dev/null)

  local publish_id upload_url
  publish_id=$(echo "$init_response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('publish_id',''))" 2>/dev/null)
  upload_url=$(echo "$init_response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('upload_url',''))" 2>/dev/null)

  if [[ -z "$publish_id" ]] || [[ -z "$upload_url" ]]; then
    log "ERROR: Init upload failed"
    echo "$init_response"
    return 1
  fi

  log "Upload initialized. publish_id: ${publish_id}"

  # Step 2: Upload video chunk
  curl -s -X PUT "$upload_url" \
    -H "Content-Type: video/mp4" \
    -H "Content-Range: bytes 0-$((file_size - 1))/${file_size}" \
    --data-binary "@${video_file}" 2>/dev/null

  log "Video uploaded. Polling for status..."

  # Step 3: Poll status
  local attempts=0
  while [[ $attempts -lt 30 ]]; do
    sleep 5
    local status_response
    status_response=$(curl -s -X POST "${API_BASE}/v2/post/publish/status/fetch/" \
      -H "Authorization: Bearer ${TIKTOK_ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"publish_id\": \"${publish_id}\"}" 2>/dev/null)

    local status
    status=$(echo "$status_response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('status',''))" 2>/dev/null)

    log "Status: ${status} (attempt ${attempts})"

    case "$status" in
      PUBLISH_COMPLETE)
        log "Published successfully!"
        echo "$status_response" | python3 -m json.tool 2>/dev/null
        return 0
        ;;
      FAILED)
        log "ERROR: Publish failed"
        echo "$status_response"
        return 1
        ;;
    esac

    attempts=$((attempts + 1))
  done

  log "ERROR: Timed out waiting for publish"
  return 1
}

# Main
CMD="${1:-help}"
shift || true

case "$CMD" in
  status)   check_status ;;
  refresh)  refresh_token ;;
  upload)   upload_video "$@" ;;
  publish)
    log "Publish from content pipeline — scanning content dir"
    local content_dir=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --content-dir) content_dir="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    if [[ -d "$content_dir" ]]; then
      for video in "${content_dir}"/*.mp4; do
        [[ -f "$video" ]] || continue
        local caption_file="${video%.mp4}.txt"
        local caption=""
        [[ -f "$caption_file" ]] && caption=$(cat "$caption_file")
        upload_video --video "$video" --caption "${caption:-Jade Oracle}"
      done
    else
      log "ERROR: Content dir not found: ${content_dir}"
    fi
    ;;
  help|*)
    echo "TikTok Posting — Content Posting API"
    echo ""
    echo "Usage:"
    echo "  tiktok-post.sh status                       Check auth"
    echo "  tiktok-post.sh upload --video F --caption T  Upload video"
    echo "  tiktok-post.sh publish --content-dir DIR     From pipeline"
    echo "  tiktok-post.sh refresh                       Refresh token"
    echo ""
    echo "Auth: ${AUTH_FILE}"
    ;;
esac
