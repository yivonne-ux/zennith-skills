#!/usr/bin/env bash
# repurpose.sh — Content repurposing engine for Zennith OS
# One hero asset -> platform-optimized variants (image, video, copy)
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash repurpose.sh image --brand <brand> --input <file> [options]
#   bash repurpose.sh video --brand <brand> --input <file> [options]
#   bash repurpose.sh copy  --brand <brand> --input <file> [options]
#   bash repurpose.sh all   --brand <brand> --input <file> [options]

set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/repurpose.log"
BRANDS_DIR="$HOME/.openclaw/brands"
DATA_DIR="$HOME/.openclaw/workspace/data"
VERSION="1.0.0"

# F&B brands use center-weighted crop; lifestyle brands use rule-of-thirds
FNB_BRANDS="pinxin-vegan wholey-wonder mirra rasaya gaia-eats dr-stan serein"
LIFESTYLE_BRANDS="gaia-learn gaia-os iris jade-oracle gaia-print gaia-supplements"

ALL_IMAGE_PLATFORMS="ig-feed-square ig-feed-portrait ig-stories fb-feed fb-stories fb-cover shopee-banner shopee-feed whatsapp-status whatsapp-catalog edm linkedin linkedin-article x-post x-header pinterest yt-thumb"
ALL_VIDEO_PLATFORMS="ig-reels ig-stories-video fb-stories-video tiktok yt-shorts yt-standard"
ALL_COPY_PLATFORMS="ig-feed ig-stories ig-reels fb-feed tiktok shopee whatsapp edm linkedin x-post"

mkdir -p "$(dirname "$LOG_FILE")"

# --- Logging ---
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [repurpose] $1" >> "$LOG_FILE"; }
info()  { echo "[Repurpose] $1" >&2; log "$1"; }
warn()  { echo "[Repurpose] WARN: $1" >&2; log "WARN: $1"; }
error() { echo "[Repurpose] ERROR: $1" >&2; log "ERROR: $1"; }

# --- Help ---
show_help() {
  cat <<'HELP'
repurpose.sh — Content Repurpose Engine v1.0.0

One hero asset (image, video, or copy) automatically reformatted into
every platform variant. One input, full distribution.

SUBCOMMANDS:
  image    Resize/crop image to all platform specs
  video    Convert aspect ratios, trim durations per platform
  copy     Adapt caption/copy for each platform's limits (stub)
  all      Run image + video + copy for the input type

FLAGS:
  --brand <brand>         Brand name (required). Loads DNA for logo/colors.
  --input <file>          Input file path (required).
  --platforms <list|all>  Comma-separated platforms or "all" (default: all).
  --output-dir <path>     Override output directory.
  --dry-run               Show commands without executing.
  --help                  Show this help message.

IMAGE PLATFORMS:
  ig-feed-square, ig-feed-portrait, ig-stories, fb-feed, fb-stories,
  fb-cover, shopee-banner, shopee-feed, whatsapp-status, whatsapp-catalog,
  edm, linkedin, linkedin-article, x-post, x-header, pinterest, yt-thumb

VIDEO PLATFORMS:
  ig-reels, ig-stories-video, fb-stories-video, tiktok, yt-shorts, yt-standard

COPY PLATFORMS:
  ig-feed, ig-stories, ig-reels, fb-feed, tiktok, shopee, whatsapp, edm,
  linkedin, x-post

EXAMPLES:
  bash repurpose.sh image --brand mirra --input hero.png --platforms all
  bash repurpose.sh video --brand pinxin-vegan --input ad.mp4 --platforms ig-reels,tiktok
  bash repurpose.sh all --brand mirra --input hero.png --dry-run
HELP
  exit 0
}

# --- Dependency checks ---
check_ffmpeg() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    error "ffmpeg is required. Install: brew install ffmpeg"
    exit 1
  fi
}

check_ffprobe() {
  if ! command -v ffprobe >/dev/null 2>&1; then
    error "ffprobe is required (part of ffmpeg). Install: brew install ffmpeg"
    exit 1
  fi
}

# --- Helpers ---
is_fnb_brand() {
  local brand="$1"
  echo "$FNB_BRANDS" | tr ' ' '\n' | grep -qx "$brand" 2>/dev/null
}

# Parse comma-separated platform list; return filtered list
parse_platforms() {
  local requested="$1"
  local valid_list="$2"
  if [ "$requested" = "all" ]; then
    echo "$valid_list"
    return
  fi
  local result=""
  local IFS_ORIG="$IFS"
  IFS=","
  for p in $requested; do
    IFS="$IFS_ORIG"
    if echo "$valid_list" | tr ' ' '\n' | grep -qx "$p" 2>/dev/null; then
      result="$result $p"
    else
      warn "Unknown platform: $p (skipped)"
    fi
  done
  IFS="$IFS_ORIG"
  echo "$result" | sed 's/^ //'
}

# Load brand logo path
load_brand_logo() {
  local brand="$1"
  local logo_path="$BRANDS_DIR/$brand/assets/logo-white.png"
  if [ -f "$logo_path" ]; then
    echo "$logo_path"
  else
    warn "Brand logo not found at $logo_path — skipping overlay"
    echo ""
  fi
}

# Load brand primary color from DNA.json
load_brand_color() {
  local brand="$1"
  local dna="$BRANDS_DIR/$brand/DNA.json"
  if [ -f "$dna" ] && command -v jq >/dev/null 2>&1; then
    jq -r '.visual.primary_color // .colors.primary // "000000"' "$dna" 2>/dev/null || echo "000000"
  else
    echo "000000"
  fi
}

# --- Image Subcommand ---
# Each platform spec: name width height
# Uses ffmpeg center-crop logic from SKILL.md
run_image_crop() {
  local input="$1" name="$2" width="$3" height="$4" outdir="$5" dry_run="$6"
  local output="$outdir/${name}-${width}x${height}.jpg"

  # Compute aspect ratio crop filter
  local crop_filter=""
  local rw="$width"
  local rh="$height"

  if [ "$width" = "$height" ]; then
    # Square: 1:1
    crop_filter="crop=min(iw\,ih):min(iw\,ih):(iw-min(iw\,ih))/2:(ih-min(iw\,ih))/2,scale=${width}:${height}"
  elif [ "$name" = "edm" ]; then
    # EDM: scale width, auto height
    crop_filter="scale=${width}:-1"
  else
    # Generic aspect-ratio center crop
    crop_filter="crop=if(gt(iw*${rh}\,ih*${rw})\,ih*${rw}/${rh}\,iw):if(gt(iw*${rh}\,ih*${rw})\,ih\,iw*${rh}/${rw}):(iw-if(gt(iw*${rh}\,ih*${rw})\,ih*${rw}/${rh}\,iw))/2:(ih-if(gt(iw*${rh}\,ih*${rw})\,ih\,iw*${rh}/${rw}))/2,scale=${width}:${height}"
  fi

  local cmd="ffmpeg -y -i \"$input\" -vf \"$crop_filter\" -q:v 2 \"$output\""

  if [ "$dry_run" = "true" ]; then
    echo "  [DRY-RUN] $cmd"
  else
    info "  -> $name (${width}x${height})"
    eval "$cmd" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      log "Created $output"
    else
      error "Failed to create $name variant"
    fi
  fi
}

do_image() {
  local input="$1" brand="$2" platforms="$3" outdir="$4" dry_run="$5"
  check_ffmpeg

  local plist
  plist=$(parse_platforms "$platforms" "$ALL_IMAGE_PLATFORMS")
  if [ -z "$plist" ]; then
    error "No valid image platforms specified."
    exit 1
  fi

  local logo
  logo=$(load_brand_logo "$brand")

  info "Image repurpose: $input -> $(echo "$plist" | wc -w | tr -d ' ') variants"
  mkdir -p "$outdir"

  local p
  for p in $plist; do
    case "$p" in
      ig-feed-square)     run_image_crop "$input" "ig-feed-square" 1080 1080 "$outdir" "$dry_run" ;;
      ig-feed-portrait)   run_image_crop "$input" "ig-feed-portrait" 1080 1350 "$outdir" "$dry_run" ;;
      ig-stories)         run_image_crop "$input" "ig-stories" 1080 1920 "$outdir" "$dry_run" ;;
      fb-feed)            run_image_crop "$input" "fb-feed" 1200 628 "$outdir" "$dry_run" ;;
      fb-stories)         run_image_crop "$input" "fb-stories" 1080 1920 "$outdir" "$dry_run" ;;
      fb-cover)           run_image_crop "$input" "fb-cover" 820 312 "$outdir" "$dry_run" ;;
      shopee-banner)      run_image_crop "$input" "shopee-banner" 1200 628 "$outdir" "$dry_run" ;;
      shopee-feed)        run_image_crop "$input" "shopee-feed" 1080 1080 "$outdir" "$dry_run" ;;
      whatsapp-status)    run_image_crop "$input" "whatsapp-status" 1080 1920 "$outdir" "$dry_run" ;;
      whatsapp-catalog)   run_image_crop "$input" "whatsapp-catalog" 600 600 "$outdir" "$dry_run" ;;
      edm)                run_image_crop "$input" "edm" 600 0 "$outdir" "$dry_run" ;;
      linkedin)           run_image_crop "$input" "linkedin" 1200 627 "$outdir" "$dry_run" ;;
      linkedin-article)   run_image_crop "$input" "linkedin-article" 1200 644 "$outdir" "$dry_run" ;;
      x-post)             run_image_crop "$input" "x-post" 1600 900 "$outdir" "$dry_run" ;;
      x-header)           run_image_crop "$input" "x-header" 1500 500 "$outdir" "$dry_run" ;;
      pinterest)          run_image_crop "$input" "pinterest" 1000 1500 "$outdir" "$dry_run" ;;
      yt-thumb)           run_image_crop "$input" "yt-thumb" 1280 720 "$outdir" "$dry_run" ;;
    esac
  done

  # Brand logo overlay pass (skip if no logo found)
  if [ -n "$logo" ] && [ "$dry_run" != "true" ]; then
    info "Applying brand logo overlay..."
    for img in "$outdir"/*.jpg; do
      [ -f "$img" ] || continue
      local w h logo_w pad_x pad_y
      w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$img" 2>/dev/null || echo 0)
      h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$img" 2>/dev/null || echo 0)
      if [ "$w" -gt 0 ] && [ "$h" -gt 0 ]; then
        logo_w=$((w * 15 / 100))
        pad_x=$((w * 5 / 100))
        pad_y=$((h * 5 / 100))
        local branded="${img%.jpg}-branded.jpg"
        ffmpeg -y -i "$img" -i "$logo" \
          -filter_complex "[1:v]scale=${logo_w}:-1[wm];[0:v][wm]overlay=W-w-${pad_x}:H-h-${pad_y}" \
          -q:v 2 "$branded" >/dev/null 2>&1 && mv "$branded" "$img"
      fi
    done
  fi

  # Generate manifest
  if [ "$dry_run" != "true" ]; then
    generate_manifest "$outdir" "$brand" "image" "$input"
  fi
}

# --- Video Subcommand ---
run_video_variant() {
  local input="$1" name="$2" width="$3" height="$4" max_dur="$5" outdir="$6" dry_run="$7"
  local output="$outdir/${name}-${width}x${height}.mp4"

  # Get source dimensions
  local src_w src_h src_dur
  src_w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$input" 2>/dev/null || echo 1920)
  src_h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$input" 2>/dev/null || echo 1080)
  src_dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input" 2>/dev/null || echo 999)
  # Truncate to integer
  src_dur=$(echo "$src_dur" | cut -d. -f1)

  local filter=""
  local dur_opts=""

  # Aspect ratio conversion
  local src_ratio=$((src_w * 100 / src_h))
  local tgt_ratio=$((width * 100 / height))

  if [ "$src_ratio" -gt "$((tgt_ratio + 10))" ]; then
    # Source wider than target: center crop width
    filter="crop=ih*${width}/${height}:ih:iw/2-ih*${width}/${height}/2:0,scale=${width}:${height}"
  elif [ "$src_ratio" -lt "$((tgt_ratio - 10))" ]; then
    # Source taller than target: blur-pad background
    filter="[0:v]split[main][bg];[bg]scale=${width}:${height},boxblur=20:5[blurred];[main]scale=-1:${height}[scaled];[blurred][scaled]overlay=(W-w)/2:0"
  else
    # Similar aspect: simple scale
    filter="scale=${width}:${height}"
  fi

  # Duration trimming with fade out
  if [ "$max_dur" -gt 0 ] && [ "$src_dur" -gt "$max_dur" ]; then
    local fade_start=$((max_dur - 2))
    if [ "$fade_start" -lt 1 ]; then fade_start=1; fi
    dur_opts="-t $max_dur -vf \"fade=t=out:st=${fade_start}:d=1.5\" -af \"afade=t=out:st=${fade_start}:d=1.5\""
  fi

  # Detect if filter is complex or simple
  local cmd=""
  if echo "$filter" | grep -q '\[' 2>/dev/null; then
    cmd="ffmpeg -y -i \"$input\" -filter_complex \"$filter\" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k $dur_opts \"$output\""
  else
    cmd="ffmpeg -y -i \"$input\" -vf \"$filter\" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k $dur_opts \"$output\""
  fi

  if [ "$dry_run" = "true" ]; then
    echo "  [DRY-RUN] $cmd"
  else
    info "  -> $name (${width}x${height}, max ${max_dur}s)"
    eval "$cmd" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      log "Created $output"
    else
      error "Failed to create $name variant"
    fi
  fi
}

do_video() {
  local input="$1" brand="$2" platforms="$3" outdir="$4" dry_run="$5"
  check_ffmpeg
  check_ffprobe

  local plist
  plist=$(parse_platforms "$platforms" "$ALL_VIDEO_PLATFORMS")
  if [ -z "$plist" ]; then
    error "No valid video platforms specified."
    exit 1
  fi

  info "Video repurpose: $input -> $(echo "$plist" | wc -w | tr -d ' ') variants"
  mkdir -p "$outdir"

  local p
  for p in $plist; do
    case "$p" in
      ig-reels)           run_video_variant "$input" "ig-reels" 1080 1920 90 "$outdir" "$dry_run" ;;
      ig-stories-video)   run_video_variant "$input" "ig-stories-video" 1080 1920 15 "$outdir" "$dry_run" ;;
      fb-stories-video)   run_video_variant "$input" "fb-stories-video" 1080 1920 20 "$outdir" "$dry_run" ;;
      tiktok)             run_video_variant "$input" "tiktok" 1080 1920 600 "$outdir" "$dry_run" ;;
      yt-shorts)          run_video_variant "$input" "yt-shorts" 1080 1920 60 "$outdir" "$dry_run" ;;
      yt-standard)        run_video_variant "$input" "yt-standard" 1920 1080 0 "$outdir" "$dry_run" ;;
    esac
  done

  if [ "$dry_run" != "true" ]; then
    generate_manifest "$outdir" "$brand" "video" "$input"
  fi
}

# --- Copy Subcommand (stub with real platform limits) ---
do_copy() {
  local input="$1" brand="$2" platforms="$3" outdir="$4" dry_run="$5"

  local plist
  plist=$(parse_platforms "$platforms" "$ALL_COPY_PLATFORMS")
  if [ -z "$plist" ]; then
    error "No valid copy platforms specified."
    exit 1
  fi

  info "Copy repurpose: analyzing platform limits for $brand"

  # Read input text
  local text=""
  if [ -f "$input" ]; then
    text=$(cat "$input")
  else
    text="$input"
  fi
  local char_count=${#text}

  echo ""
  echo "=== Copy Repurpose Report ==="
  echo "Brand: $brand"
  echo "Input length: $char_count chars"
  echo ""

  local p
  for p in $plist; do
    local max_chars="" hashtag_limit="" cta_style="" notes=""
    case "$p" in
      ig-feed)    max_chars=2200; hashtag_limit=30; cta_style="Link in bio / DM us"; notes="First 125 chars visible before 'more'" ;;
      ig-stories) max_chars=125; hashtag_limit=10; cta_style="Sticker CTA / poll"; notes="Single thought, punchy" ;;
      ig-reels)   max_chars=2200; hashtag_limit=15; cta_style="Follow for more"; notes="Short preferred, hook-driven" ;;
      fb-feed)    max_chars=63206; hashtag_limit=5; cta_style="Shop Now / Learn More"; notes="First 80 chars visible before 'See more'" ;;
      tiktok)     max_chars=2200; hashtag_limit=5; cta_style="Link in bio / Comment"; notes="Keep under 150 for readability" ;;
      shopee)     max_chars=500; hashtag_limit=0; cta_style="Buy Now / Add to Cart"; notes="Direct, benefit-focused" ;;
      whatsapp)   max_chars=190; hashtag_limit=0; cta_style="Tap to order"; notes="Personal, direct tone" ;;
      edm)        max_chars=0; hashtag_limit=0; cta_style="Button CTA"; notes="HTML layout, no char limit" ;;
      linkedin)   max_chars=3000; hashtag_limit=5; cta_style="Learn more at..."; notes="First 140 chars visible" ;;
      x-post)     max_chars=280; hashtag_limit=3; cta_style="Link"; notes="Concise, witty" ;;
    esac

    local status="OK"
    if [ "$max_chars" -gt 0 ] 2>/dev/null && [ "$char_count" -gt "$max_chars" ]; then
      status="OVER by $((char_count - max_chars)) chars"
    fi

    printf "  %-15s | Max: %6s chars | Hashtags: %2s | Status: %s\n" \
      "$p" "${max_chars:-N/A}" "$hashtag_limit" "$status"
    if [ -n "$notes" ]; then
      printf "  %-15s | Notes: %s\n" "" "$notes"
    fi
    printf "  %-15s | CTA: %s\n" "" "$cta_style"
    echo ""
  done

  if [ "$dry_run" != "true" ]; then
    # Write the report to a file
    local report_file="$outdir/copy-report.txt"
    mkdir -p "$outdir"
    echo "Copy Repurpose Report — $(date '+%Y-%m-%d %H:%M') — Brand: $brand" > "$report_file"
    echo "Input: $char_count chars" >> "$report_file"
    echo "" >> "$report_file"
    echo "Platform adaptation requires LLM (use campaign-translate or Dreami agent)." >> "$report_file"
    info "Report saved to $report_file"
  fi
}

# --- Manifest Generation ---
generate_manifest() {
  local outdir="$1" brand="$2" content_type="$3" source="$4"
  local manifest="$outdir/manifest.json"
  local timestamp
  timestamp=$(date '+%Y-%m-%dT%H:%M:%S')

  # Build JSON manually (no jq dependency for writing)
  echo "{" > "$manifest"
  echo "  \"brand\": \"$brand\"," >> "$manifest"
  echo "  \"content_type\": \"$content_type\"," >> "$manifest"
  echo "  \"source\": \"$source\"," >> "$manifest"
  echo "  \"generated_at\": \"$timestamp\"," >> "$manifest"
  echo "  \"tool\": \"repurpose.sh v$VERSION\"," >> "$manifest"
  echo "  \"outputs\": [" >> "$manifest"

  local first=true
  local f
  for f in "$outdir"/*; do
    [ -f "$f" ] || continue
    local fname
    fname=$(basename "$f")
    # Skip the manifest itself
    if [ "$fname" = "manifest.json" ]; then continue; fi
    local size
    size=$(wc -c < "$f" | tr -d ' ')
    if [ "$first" = "true" ]; then
      first=false
    else
      echo "    ," >> "$manifest"
    fi
    echo -n "    {\"file\": \"$fname\", \"size_bytes\": $size}" >> "$manifest"
  done

  echo "" >> "$manifest"
  echo "  ]" >> "$manifest"
  echo "}" >> "$manifest"

  info "Manifest: $manifest ($(grep -c '"file"' "$manifest") outputs)"
}

# --- Main ---
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  local subcmd="$1"
  shift

  if [ "$subcmd" = "--help" ] || [ "$subcmd" = "-h" ] || [ "$subcmd" = "help" ]; then
    show_help
  fi

  # Parse flags
  local brand="" input="" platforms="all" output_dir="" dry_run="false"
  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)      brand="$2"; shift 2 ;;
      --input)      input="$2"; shift 2 ;;
      --platforms)  platforms="$2"; shift 2 ;;
      --output-dir) output_dir="$2"; shift 2 ;;
      --dry-run)    dry_run="true"; shift ;;
      --help|-h)    show_help ;;
      *)            error "Unknown flag: $1"; show_help ;;
    esac
  done

  # Validate required args
  if [ -z "$brand" ]; then
    error "--brand is required"
    exit 1
  fi
  if [ -z "$input" ]; then
    error "--input is required"
    exit 1
  fi
  if [ ! -f "$input" ] && [ "$subcmd" != "copy" ]; then
    error "Input file not found: $input"
    exit 1
  fi

  # Determine output directory
  local date_stamp
  date_stamp=$(date '+%Y%m%d')
  local product_name
  product_name=$(basename "$input" | sed 's/\.[^.]*$//')
  if [ -z "$output_dir" ]; then
    output_dir="$DATA_DIR/images/$brand/repurposed/${date_stamp}_${product_name}"
  fi

  # Validate brand exists
  if [ ! -d "$BRANDS_DIR/$brand" ]; then
    warn "Brand directory not found: $BRANDS_DIR/$brand — proceeding without brand assets"
  fi

  info "Brand: $brand | Input: $input | Platforms: $platforms | Dry-run: $dry_run"
  log "Subcommand: $subcmd | Brand: $brand | Input: $input"

  case "$subcmd" in
    image)
      do_image "$input" "$brand" "$platforms" "$output_dir" "$dry_run"
      ;;
    video)
      output_dir="$DATA_DIR/videos/$brand/repurposed/${date_stamp}_${product_name}"
      do_video "$input" "$brand" "$platforms" "$output_dir" "$dry_run"
      ;;
    copy)
      do_copy "$input" "$brand" "$platforms" "$output_dir" "$dry_run"
      ;;
    all)
      local ext
      ext=$(echo "$input" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
      case "$ext" in
        jpg|jpeg|png|webp|tiff|bmp)
          do_image "$input" "$brand" "$platforms" "$output_dir" "$dry_run"
          ;;
        mp4|mov|avi|mkv|webm)
          local vid_outdir="$DATA_DIR/videos/$brand/repurposed/${date_stamp}_${product_name}"
          do_video "$input" "$brand" "$platforms" "$vid_outdir" "$dry_run"
          ;;
        txt|md)
          do_copy "$input" "$brand" "$platforms" "$output_dir" "$dry_run"
          ;;
        *)
          warn "Cannot auto-detect type for .$ext — trying image first"
          do_image "$input" "$brand" "$platforms" "$output_dir" "$dry_run"
          ;;
      esac
      ;;
    *)
      error "Unknown subcommand: $subcmd"
      show_help
      ;;
  esac

  info "Done."
}

main "$@"
