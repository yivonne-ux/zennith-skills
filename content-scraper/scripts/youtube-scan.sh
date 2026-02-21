#!/usr/bin/env bash
# youtube-scan.sh — YouTube trend & competitor scanner
#
# Uses YouTube Data API v3 (free, 10K quota units/day)
# Also supports yt-dlp for quick metadata extraction
#
# Usage:
#   bash youtube-scan.sh search "vegan food malaysia" [--max 10]
#   bash youtube-scan.sh trending "MY"
#   bash youtube-scan.sh channel "UCxxxxxx" [--max 10]
#   bash youtube-scan.sh analyze <video_url>
#
# Requires: YOUTUBE_API_KEY env var (get free at console.cloud.google.com)
# Bash 3.2 compatible (macOS)

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

CMD="${1:-help}"
shift 2>/dev/null || true

SKILLS_DIR="$HOME/.openclaw/skills"
SEED_STORE="$SKILLS_DIR/content-seed-bank/scripts/seed-store.sh"
RAG_STORE="$SKILLS_DIR/rag-memory/scripts/memory-store.sh"
LOG="$HOME/.openclaw/logs/content-scraper.log"
OUTPUT_DIR="$HOME/.openclaw/workspace/data/scrapes/youtube"

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [YT-SCAN] $1" >> "$LOG"
}

# Check for API key
API_KEY="${YOUTUBE_API_KEY:-}"
if [ -z "$API_KEY" ]; then
  # Try loading from env file
  if [ -f "$HOME/.openclaw/.env" ]; then
    API_KEY=$(grep "YOUTUBE_API_KEY" "$HOME/.openclaw/.env" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)
  fi
fi

case "$CMD" in

  search)
    QUERY="${1:-}"
    MAX_RESULTS=10
    shift 2>/dev/null || true
    while [ $# -gt 0 ]; do
      case "$1" in
        --max) MAX_RESULTS="$2"; shift 2;;
        *) shift;;
      esac
    done

    if [ -z "$QUERY" ]; then
      echo "Usage: youtube-scan.sh search <query> [--max N]" >&2
      exit 1
    fi

    log "SEARCH: '$QUERY' (max $MAX_RESULTS)"

    if [ -n "$API_KEY" ]; then
      # Use official YouTube Data API v3
      python3 - "$API_KEY" "$QUERY" "$MAX_RESULTS" "$OUTPUT_DIR" << 'PYEOF'
import json, sys, urllib.request, urllib.parse, os
from datetime import datetime

api_key = sys.argv[1]
query = sys.argv[2]
max_results = int(sys.argv[3])
output_dir = sys.argv[4]

# Search for videos
params = urllib.parse.urlencode({
    'part': 'snippet',
    'q': query,
    'type': 'video',
    'maxResults': max_results,
    'order': 'relevance',
    'regionCode': 'MY',
    'key': api_key
})

url = f'https://www.googleapis.com/youtube/v3/search?{params}'
try:
    with urllib.request.urlopen(url, timeout=15) as resp:
        data = json.loads(resp.read())
except Exception as e:
    print(f"API Error: {e}")
    sys.exit(1)

results = []
video_ids = []
for item in data.get('items', []):
    vid = {
        'video_id': item['id'].get('videoId', ''),
        'title': item['snippet']['title'],
        'channel': item['snippet']['channelTitle'],
        'description': item['snippet']['description'][:200],
        'published': item['snippet']['publishedAt'],
        'thumbnail': item['snippet']['thumbnails'].get('high', {}).get('url', '')
    }
    results.append(vid)
    video_ids.append(vid['video_id'])

# Get view counts for all videos (1 API call)
if video_ids:
    stats_params = urllib.parse.urlencode({
        'part': 'statistics',
        'id': ','.join(video_ids),
        'key': api_key
    })
    stats_url = f'https://www.googleapis.com/youtube/v3/videos?{stats_params}'
    try:
        with urllib.request.urlopen(stats_url, timeout=15) as resp:
            stats_data = json.loads(resp.read())

        stats_map = {}
        for item in stats_data.get('items', []):
            s = item.get('statistics', {})
            stats_map[item['id']] = {
                'views': int(s.get('viewCount', 0)),
                'likes': int(s.get('likeCount', 0)),
                'comments': int(s.get('commentCount', 0))
            }

        for r in results:
            s = stats_map.get(r['video_id'], {})
            r.update(s)
    except:
        pass

# Save results
ts = datetime.now().strftime('%Y%m%d_%H%M%S')
out_file = os.path.join(output_dir, f'search_{ts}.json')
with open(out_file, 'w') as f:
    json.dump({'query': query, 'results': results, 'ts': ts}, f, indent=2)

# Print summary
print(f"\n=== YouTube Search: '{query}' ({len(results)} results) ===\n")
for i, r in enumerate(results, 1):
    views = r.get('views', 0)
    views_str = f"{views:,}" if views else "?"
    print(f"{i}. [{views_str} views] {r['title']}")
    print(f"   Channel: {r['channel']} | Published: {r['published'][:10]}")
    print(f"   https://youtube.com/watch?v={r['video_id']}")
    print()

print(f"Saved to: {out_file}")
PYEOF
    else
      echo "No YOUTUBE_API_KEY set. Get one free at console.cloud.google.com"
      echo "Then add to ~/.openclaw/.env: YOUTUBE_API_KEY=your_key_here"

      # Fallback: use yt-dlp if available
      if command -v yt-dlp &>/dev/null; then
        echo ""
        echo "Falling back to yt-dlp search..."
        yt-dlp --flat-playlist --print "%(title)s | %(url)s | %(view_count)s views" \
          "ytsearch${MAX_RESULTS:-10}:${QUERY}" 2>/dev/null || echo "yt-dlp search failed"
      fi
    fi
    ;;

  trending)
    REGION="${1:-MY}"

    log "TRENDING: region=$REGION"

    if [ -n "$API_KEY" ]; then
      python3 - "$API_KEY" "$REGION" "$OUTPUT_DIR" << 'PYEOF'
import json, sys, urllib.request, urllib.parse, os
from datetime import datetime

api_key = sys.argv[1]
region = sys.argv[2]
output_dir = sys.argv[3]

# Get trending videos
params = urllib.parse.urlencode({
    'part': 'snippet,statistics',
    'chart': 'mostPopular',
    'regionCode': region,
    'maxResults': 25,
    'key': api_key
})

url = f'https://www.googleapis.com/youtube/v3/videos?{params}'
try:
    with urllib.request.urlopen(url, timeout=15) as resp:
        data = json.loads(resp.read())
except Exception as e:
    print(f"API Error: {e}")
    sys.exit(1)

results = []
for item in data.get('items', []):
    s = item.get('statistics', {})
    vid = {
        'video_id': item['id'],
        'title': item['snippet']['title'],
        'channel': item['snippet']['channelTitle'],
        'category': item['snippet'].get('categoryId', ''),
        'views': int(s.get('viewCount', 0)),
        'likes': int(s.get('likeCount', 0)),
        'published': item['snippet']['publishedAt']
    }
    results.append(vid)

# Save
ts = datetime.now().strftime('%Y%m%d_%H%M%S')
out_file = os.path.join(output_dir, f'trending_{region}_{ts}.json')
with open(out_file, 'w') as f:
    json.dump({'region': region, 'results': results, 'ts': ts}, f, indent=2)

# Print
print(f"\n=== Trending in {region} (Top {len(results)}) ===\n")
for i, r in enumerate(results, 1):
    print(f"{i}. [{r['views']:,} views] {r['title']}")
    print(f"   Channel: {r['channel']}")
    print()

print(f"Saved to: {out_file}")
PYEOF
    else
      echo "No YOUTUBE_API_KEY set."
    fi
    ;;

  channel)
    CHANNEL_ID="${1:-}"
    MAX_RESULTS=10
    shift 2>/dev/null || true
    while [ $# -gt 0 ]; do
      case "$1" in
        --max) MAX_RESULTS="$2"; shift 2;;
        *) shift;;
      esac
    done

    if [ -z "$CHANNEL_ID" ]; then
      echo "Usage: youtube-scan.sh channel <channel_id> [--max N]" >&2
      exit 1
    fi

    log "CHANNEL: $CHANNEL_ID (max $MAX_RESULTS)"

    if [ -n "$API_KEY" ]; then
      python3 - "$API_KEY" "$CHANNEL_ID" "$MAX_RESULTS" "$OUTPUT_DIR" << 'PYEOF'
import json, sys, urllib.request, urllib.parse, os
from datetime import datetime

api_key = sys.argv[1]
channel_id = sys.argv[2]
max_results = int(sys.argv[3])
output_dir = sys.argv[4]

# Search channel's videos
params = urllib.parse.urlencode({
    'part': 'snippet',
    'channelId': channel_id,
    'type': 'video',
    'maxResults': max_results,
    'order': 'date',
    'key': api_key
})

url = f'https://www.googleapis.com/youtube/v3/search?{params}'
try:
    with urllib.request.urlopen(url, timeout=15) as resp:
        data = json.loads(resp.read())
except Exception as e:
    print(f"API Error: {e}")
    sys.exit(1)

results = []
for item in data.get('items', []):
    vid = {
        'video_id': item['id'].get('videoId', ''),
        'title': item['snippet']['title'],
        'channel': item['snippet']['channelTitle'],
        'description': item['snippet']['description'][:200],
        'published': item['snippet']['publishedAt']
    }
    results.append(vid)

ts = datetime.now().strftime('%Y%m%d_%H%M%S')
out_file = os.path.join(output_dir, f'channel_{ts}.json')
with open(out_file, 'w') as f:
    json.dump({'channel_id': channel_id, 'results': results, 'ts': ts}, f, indent=2)

print(f"\n=== Channel {channel_id} (Latest {len(results)}) ===\n")
for i, r in enumerate(results, 1):
    print(f"{i}. {r['title']}")
    print(f"   Published: {r['published'][:10]} | https://youtube.com/watch?v={r['video_id']}")
    print()

print(f"Saved to: {out_file}")
PYEOF
    else
      echo "No YOUTUBE_API_KEY set."
    fi
    ;;

  analyze)
    VIDEO_URL="${1:-}"
    if [ -z "$VIDEO_URL" ]; then
      echo "Usage: youtube-scan.sh analyze <video_url>" >&2
      exit 1
    fi

    log "ANALYZE: $VIDEO_URL"

    # Use yt-dlp for quick metadata extraction
    if command -v yt-dlp &>/dev/null; then
      yt-dlp --dump-json --no-download "$VIDEO_URL" 2>/dev/null | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print(f\"Title: {d.get('title', '?')}\")
print(f\"Channel: {d.get('channel', '?')}\")
print(f\"Views: {d.get('view_count', 0):,}\")
print(f\"Likes: {d.get('like_count', 0):,}\")
print(f\"Duration: {d.get('duration', 0)//60}m {d.get('duration', 0)%60}s\")
print(f\"Tags: {', '.join(d.get('tags', [])[:10])}\")
print(f\"Description: {d.get('description', '')[:300]}\")
" 2>/dev/null || echo "yt-dlp analysis failed"
    else
      echo "yt-dlp not installed. Install: pip3 install yt-dlp"
    fi
    ;;

  *)
    echo "YouTube Scanner — GAIA Content Scraper"
    echo ""
    echo "Usage: youtube-scan.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  search <query> [--max N]     Search videos by keyword"
    echo "  trending [region]            Get trending videos (default: MY)"
    echo "  channel <channel_id> [--max] Scan a channel's videos"
    echo "  analyze <video_url>          Analyze a single video"
    echo ""
    echo "Requires: YOUTUBE_API_KEY in ~/.openclaw/.env"
    echo "Get free key: console.cloud.google.com → APIs → YouTube Data API v3"
    ;;
esac
