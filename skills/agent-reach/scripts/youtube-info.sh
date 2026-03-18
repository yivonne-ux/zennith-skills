#!/usr/bin/env bash
# youtube-info.sh — Extract YouTube video metadata + subtitles
# Uses yt-dlp (free, no API key)
#
# Usage:
#   bash youtube-info.sh "https://youtu.be/VIDEO_ID"
#   bash youtube-info.sh "https://youtu.be/VIDEO_ID" --subtitles

set -euo pipefail

URL="${1:-}"
MODE="${2:---info}"

if [[ -z "$URL" ]]; then
  echo "❌ Usage: youtube-info.sh <youtube_url> [--info|--subtitles]"
  exit 1
fi

if [[ "$MODE" == "--subtitles" ]]; then
  yt-dlp --write-auto-sub --skip-download --sub-lang en -o "/tmp/yt-%(id)s" "$URL" 2>/dev/null
  SUB_FILE=$(ls /tmp/yt-*.vtt 2>/dev/null | head -1)
  if [[ -n "$SUB_FILE" ]]; then
    cat "$SUB_FILE"
  else
    echo "No subtitles found"
  fi
else
  yt-dlp --dump-json "$URL" 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f\"Title: {d.get('title')}\")
print(f\"Channel: {d.get('channel')}\")
print(f\"Duration: {d.get('duration_string', 'N/A')}\")
print(f\"Views: {d.get('view_count', 'N/A')}\")
print(f\"Upload: {d.get('upload_date', 'N/A')}\")
print(f\"Description: {d.get('description', '')[:500]}\")
"
fi
