#!/usr/bin/env bash
# intake-classify.sh — Lightweight input type classifier (zero API cost)
# Detects type from content/file_path without calling any external API.
# Bash 3.2 compatible (macOS). No jq, no declare -A.
#
# Usage: echo '{"content":"...","file_path":"..."}' | bash intake-classify.sh
# Output: link|image|video|text|unknown

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/workspace/logs/intake.log"

log() {
  printf '[%s] [intake-classify] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE" 2>/dev/null
}

# Read JSON from stdin
INPUT=""
if [ ! -t 0 ]; then
  INPUT="$(cat)"
fi

if [ -z "$INPUT" ]; then
  echo "unknown"
  exit 0
fi

# Use python3 to extract fields and classify
RESULT=$(python3 -c "
import json, sys, os

try:
    data = json.loads('''$( echo "$INPUT" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" 2>/dev/null || echo '{}' )''')
except Exception:
    data = {}

# If type is already set and valid, use it
explicit_type = data.get('type', '').strip().lower()
if explicit_type in ('link', 'image', 'video', 'text'):
    print(explicit_type)
    sys.exit(0)

file_path = data.get('file_path', '').strip()
content = data.get('content', '').strip()

# Check file_path first
if file_path:
    ext = os.path.splitext(file_path)[1].lower()
    image_exts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.tif', '.heic', '.heif', '.avif'}
    video_exts = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v', '.flv', '.wmv', '.3gp'}
    if ext in image_exts:
        print('image')
        sys.exit(0)
    elif ext in video_exts:
        print('video')
        sys.exit(0)

# Check content for URL
if content:
    c = content.strip()
    if c.startswith('http://') or c.startswith('https://') or c.startswith('www.'):
        print('link')
        sys.exit(0)
    # Check if content looks like a file path with image/video extension
    if c.startswith('/') or c.startswith('~'):
        ext = os.path.splitext(c)[1].lower()
        image_exts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.tif', '.heic', '.heif', '.avif'}
        video_exts = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v', '.flv', '.wmv', '.3gp'}
        if ext in image_exts:
            print('image')
            sys.exit(0)
        elif ext in video_exts:
            print('video')
            sys.exit(0)
    # If there is text content, it is a text brief
    if len(c) > 0:
        print('text')
        sys.exit(0)

print('unknown')
" 2>/dev/null)

RESULT="${RESULT:-unknown}"
log "Classified input as: $RESULT"
echo "$RESULT"
