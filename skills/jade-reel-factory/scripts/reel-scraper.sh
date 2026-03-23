#!/usr/bin/env bash
# reel-scraper.sh — Download competitor Instagram reels for reverse-engineering
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash reel-scraper.sh --account mysticmichaela
#   bash reel-scraper.sh --url "https://www.instagram.com/mysticmichaela/reels/"
#   bash reel-scraper.sh --all
#   bash reel-scraper.sh --all --count 5 --dry-run
#
# Options:
#   --account HANDLE    Scrape reels from a specific IG account
#   --url URL           Scrape reels from a specific URL
#   --all               Scrape all hardcoded target accounts
#   --count N           Number of reels per account (default: 3)
#   --dry-run           Show commands without executing

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YT_DLP="/opt/homebrew/bin/yt-dlp"
BASE_OUTPUT_DIR="$HOME/.openclaw/workspace/data/jade-oracle-content-pipeline/scrapes/reels"
LOG_FILE="$HOME/.openclaw/logs/jade-reel-factory.log"

# Hardcoded target accounts
TIER1="mysticmichaela spiritdaughter girl_and_her_moon theholisticpsychologist"
TIER2="the.tarot.teacher mysticbbyg psychicsamira"
ALL_TARGETS="$TIER1 $TIER2"

# --- Defaults ---
ACCOUNT=""
URL=""
SCRAPE_ALL=false
COUNT=3
DRY_RUN=false

# --- Setup ---
mkdir -p "$(dirname "$LOG_FILE")"

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [reel-scraper] $1"
  echo "$msg" >> "$LOG_FILE"
  echo "$msg" >&2
}

info() {
  echo "[ReelScraper] $1"
  log "$1"
}

error() {
  echo "[ReelScraper] ERROR: $1" >&2
  log "ERROR: $1"
}

# --- Parse arguments ---
while [ $# -gt 0 ]; do
  case "$1" in
    --account)
      shift
      if [ $# -eq 0 ]; then error "--account requires a handle"; exit 1; fi
      ACCOUNT="$1"
      ;;
    --url)
      shift
      if [ $# -eq 0 ]; then error "--url requires a URL"; exit 1; fi
      URL="$1"
      ;;
    --all)
      SCRAPE_ALL=true
      ;;
    --count)
      shift
      if [ $# -eq 0 ]; then error "--count requires a number"; exit 1; fi
      COUNT="$1"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --help|-h)
      echo "reel-scraper.sh — Download competitor IG reels for reverse-engineering"
      echo ""
      echo "Usage:"
      echo "  bash reel-scraper.sh --account <handle>    Scrape a specific account"
      echo "  bash reel-scraper.sh --url <url>           Scrape from a URL"
      echo "  bash reel-scraper.sh --all                 Scrape all target accounts"
      echo ""
      echo "Options:"
      echo "  --count N      Reels per account (default: 3)"
      echo "  --dry-run      Show commands without executing"
      echo "  --help         Show this help"
      echo ""
      echo "Target Accounts:"
      echo "  TIER1: $TIER1"
      echo "  TIER2: $TIER2"
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# --- Validate ---
if [ -z "$ACCOUNT" ] && [ -z "$URL" ] && [ "$SCRAPE_ALL" = "false" ]; then
  error "Must specify --account, --url, or --all"
  echo "Run with --help for usage."
  exit 1
fi

# --- Check yt-dlp ---
if [ ! -x "$YT_DLP" ]; then
  if command -v yt-dlp >/dev/null 2>&1; then
    YT_DLP="$(command -v yt-dlp)"
    info "Using yt-dlp at: $YT_DLP"
  else
    error "yt-dlp not found at $YT_DLP and not in PATH"
    echo "Install: brew install yt-dlp"
    exit 1
  fi
fi

# --- Extract metadata from .info.json ---
extract_metadata() {
  local json_file="$1"
  local account="$2"

  if [ ! -f "$json_file" ]; then
    return
  fi

  # Use python3 for reliable JSON parsing (macOS ships with it)
  python3 -c "
import json, sys, os

try:
    with open('$json_file', 'r') as f:
        data = json.load(f)
except Exception as e:
    print(f'WARNING: Could not parse {os.path.basename(\"$json_file\")}: {e}', file=sys.stderr)
    sys.exit(0)

meta = {
    'id': data.get('id', 'unknown'),
    'title': data.get('title', ''),
    'description': data.get('description', ''),
    'caption': data.get('description', data.get('title', '')),
    'uploader': data.get('uploader', data.get('channel', '$account')),
    'upload_date': data.get('upload_date', 'unknown'),
    'duration': data.get('duration', 0),
    'view_count': data.get('view_count', 0),
    'like_count': data.get('like_count', 0),
    'comment_count': data.get('comment_count', 0),
    'thumbnail': data.get('thumbnail', ''),
    'webpage_url': data.get('webpage_url', ''),
    'filename': data.get('_filename', ''),
    'scraped_at': '$(date -u '+%Y-%m-%dT%H:%M:%SZ')',
    'account': '$account'
}

print(json.dumps(meta, indent=2, ensure_ascii=False))
" 2>&1
}

# --- Scrape a single account ---
scrape_account() {
  local account="$1"
  local count="$2"
  local output_dir="$BASE_OUTPUT_DIR/$account"
  local reel_url="https://www.instagram.com/$account/reels/"

  info "--- Scraping: @$account (${count} reels) ---"
  info "URL: $reel_url"
  info "Output: $output_dir"

  mkdir -p "$output_dir"

  local cmd="$YT_DLP \"$reel_url\" --playlist-items 1-${count} -o \"${output_dir}/%(id)s.%(ext)s\" --write-info-json"

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY-RUN] Would execute:"
    echo "  $cmd"
    echo ""
    return 0
  fi

  # Execute the download
  log "Executing: $cmd"
  local exit_code=0
  eval "$cmd" >> "$LOG_FILE" 2>&1 || exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    error "yt-dlp failed for @$account (exit code: $exit_code)"
    error "Check log: $LOG_FILE"
    return 1
  fi

  # Process metadata from .info.json files
  local meta_dir="$output_dir/metadata"
  mkdir -p "$meta_dir"

  local reel_count=0
  local summary_file="$meta_dir/scrape-summary.json"

  # Start summary JSON
  echo "{" > "$summary_file"
  echo "  \"account\": \"$account\"," >> "$summary_file"
  echo "  \"scraped_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\"," >> "$summary_file"
  echo "  \"requested_count\": $count," >> "$summary_file"
  echo "  \"reels\": [" >> "$summary_file"

  local first_entry=true
  for info_json in "$output_dir"/*.info.json; do
    if [ ! -f "$info_json" ]; then
      continue
    fi

    reel_count=$((reel_count + 1))
    local reel_id
    reel_id="$(basename "$info_json" .info.json)"
    local meta_file="$meta_dir/${reel_id}-meta.json"

    info "  Processing metadata: $reel_id"

    # Extract and save metadata
    local metadata
    metadata=$(extract_metadata "$info_json" "$account")

    if [ -n "$metadata" ]; then
      echo "$metadata" > "$meta_file"

      # Append to summary (with comma handling)
      if [ "$first_entry" = "true" ]; then
        first_entry=false
      else
        echo "," >> "$summary_file"
      fi
      printf "    %s" "$metadata" >> "$summary_file"
    fi
  done

  # Close summary JSON
  echo "" >> "$summary_file"
  echo "  ]," >> "$summary_file"
  echo "  \"actual_count\": $reel_count" >> "$summary_file"
  echo "}" >> "$summary_file"

  info "  Downloaded: $reel_count reels"
  info "  Summary: $summary_file"
  echo ""

  return 0
}

# --- Scrape from a URL ---
scrape_url() {
  local url="$1"
  local count="$2"

  # Try to extract account name from URL
  local account
  account=$(echo "$url" | sed -E 's|.*instagram\.com/([^/]+).*|\1|')
  if [ -z "$account" ] || [ "$account" = "$url" ]; then
    account="custom-url"
  fi

  local output_dir="$BASE_OUTPUT_DIR/$account"

  info "--- Scraping URL: $url ---"
  info "Account: $account"
  info "Output: $output_dir"

  mkdir -p "$output_dir"

  local cmd="$YT_DLP \"$url\" --playlist-items 1-${count} -o \"${output_dir}/%(id)s.%(ext)s\" --write-info-json"

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY-RUN] Would execute:"
    echo "  $cmd"
    echo ""
    return 0
  fi

  log "Executing: $cmd"
  local exit_code=0
  eval "$cmd" >> "$LOG_FILE" 2>&1 || exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    error "yt-dlp failed for URL: $url (exit code: $exit_code)"
    return 1
  fi

  # Process metadata
  local meta_dir="$output_dir/metadata"
  mkdir -p "$meta_dir"
  local reel_count=0

  for info_json in "$output_dir"/*.info.json; do
    if [ ! -f "$info_json" ]; then continue; fi
    reel_count=$((reel_count + 1))
    local reel_id
    reel_id="$(basename "$info_json" .info.json)"
    local meta_file="$meta_dir/${reel_id}-meta.json"
    extract_metadata "$info_json" "$account" > "$meta_file"
    info "  Metadata saved: $reel_id"
  done

  info "  Downloaded: $reel_count reels from $url"
  echo ""
  return 0
}

# --- Main ---
info "=== Jade Reel Factory — Reel Scraper ==="
info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
info "Count: $COUNT reels per account"
if [ "$DRY_RUN" = "true" ]; then
  info "Mode: DRY RUN (no downloads)"
fi
echo ""

total_success=0
total_fail=0

if [ -n "$URL" ]; then
  # Scrape a specific URL
  if scrape_url "$URL" "$COUNT"; then
    total_success=$((total_success + 1))
  else
    total_fail=$((total_fail + 1))
  fi

elif [ -n "$ACCOUNT" ]; then
  # Scrape a specific account
  if scrape_account "$ACCOUNT" "$COUNT"; then
    total_success=$((total_success + 1))
  else
    total_fail=$((total_fail + 1))
  fi

elif [ "$SCRAPE_ALL" = "true" ]; then
  # Scrape all target accounts
  info "Scraping ALL target accounts..."
  info "TIER1: $TIER1"
  info "TIER2: $TIER2"
  echo ""

  for account in $ALL_TARGETS; do
    if scrape_account "$account" "$COUNT"; then
      total_success=$((total_success + 1))
    else
      total_fail=$((total_fail + 1))
    fi
  done
fi

# --- Summary ---
echo ""
info "=== Scrape Complete ==="
info "Success: $total_success | Failed: $total_fail"
info "Output: $BASE_OUTPUT_DIR"
info "Log: $LOG_FILE"

if [ "$total_fail" -gt 0 ]; then
  exit 1
fi
exit 0
