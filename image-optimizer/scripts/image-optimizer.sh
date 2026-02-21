#!/usr/bin/env bash
# image-optimizer.sh — GAIA CORP-OS Image Optimization Skill
# Compresses, resizes, and optimizes images for various use cases.
# macOS Bash 3.2 compatible. Uses ImageMagick (convert) with sips fallback.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/image-optimizer.log"
AVATARS_DIR="$HOME/.openclaw/workspace/apps/boss-dashboard/public/avatars"
MANIFEST="$AVATARS_DIR/manifest.json"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] [$level] $msg" >> "$LOG_FILE"
  if [ "$level" = "ERROR" ]; then
    echo "ERROR: $msg" >&2
  fi
}

info() {
  echo "$*"
  log "INFO" "$*"
}

die() {
  log "ERROR" "$*"
  echo "ERROR: $*" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Tool detection
# ---------------------------------------------------------------------------

CONVERT_CMD=""
USE_SIPS=false

detect_tools() {
  if command -v magick >/dev/null 2>&1; then
    CONVERT_CMD="$(command -v magick)"
  elif [ -x "/usr/local/bin/convert" ]; then
    CONVERT_CMD="/usr/local/bin/convert"
  elif command -v convert >/dev/null 2>&1; then
    CONVERT_CMD="$(command -v convert)"
  elif command -v sips >/dev/null 2>&1; then
    USE_SIPS=true
    log "WARN" "ImageMagick not found, falling back to sips (limited features)"
  else
    die "No image processing tool found. Install ImageMagick: brew install imagemagick"
  fi
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

human_size() {
  local bytes="$1"
  if [ "$bytes" -ge 1048576 ]; then
    # Use python for float division (Bash 3.2 has no float)
    python3 -c "print('%.1fMB' % ($bytes / 1048576.0))"
  elif [ "$bytes" -ge 1024 ]; then
    python3 -c "print('%.0fKB' % ($bytes / 1024.0))"
  else
    echo "${bytes}B"
  fi
}

file_size_bytes() {
  local f="$1"
  if [ ! -f "$f" ]; then
    echo "0"
    return
  fi
  # macOS stat syntax
  stat -f%z "$f" 2>/dev/null || stat --printf="%s" "$f" 2>/dev/null || echo "0"
}

compression_ratio() {
  local before="$1"
  local after="$2"
  if [ "$before" -le 0 ]; then
    echo "N/A"
    return
  fi
  python3 -c "
b=$before; a=$after
if b > 0:
    pct = ((b - a) / b) * 100
    print('%.0f%% reduction' % pct)
else:
    print('N/A')
"
}

# ---------------------------------------------------------------------------
# Profile configurations
# ---------------------------------------------------------------------------

get_profile_config() {
  local profile="$1"
  # Returns: max_dim quality resize_mode
  case "$profile" in
    avatar)
      echo "256 80 fill"
      ;;
    social)
      echo "1080 82 shrink"
      ;;
    ecommerce)
      echo "800 85 shrink"
      ;;
    email)
      echo "600 80 fit"
      ;;
    web)
      echo "1024 80 fit"
      ;;
    original)
      echo "0 90 none"
      ;;
    *)
      die "Unknown profile: $profile. Use: avatar|social|ecommerce|email|web|original"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Core: optimize with ImageMagick
# ---------------------------------------------------------------------------

optimize_with_convert() {
  local input="$1"
  local output="$2"
  local max_dim="$3"
  local quality="$4"
  local resize_mode="$5"

  local resize_args=""

  case "$resize_mode" in
    fill)
      # Resize to fill, then center-crop (for avatar)
      resize_args="-resize ${max_dim}x${max_dim}^ -gravity center -extent ${max_dim}x${max_dim}"
      ;;
    shrink)
      # Shrink only, maintain aspect ratio
      resize_args="-resize ${max_dim}x${max_dim}>"
      ;;
    fit)
      # Fit within max dimension, maintain aspect ratio
      resize_args="-resize ${max_dim}x${max_dim}>"
      ;;
    none)
      resize_args=""
      ;;
  esac

  # Build convert command
  # Note: eval is used because resize_args may contain multiple arguments
  if [ -n "$resize_args" ]; then
    eval "$CONVERT_CMD" '"$input"' $resize_args -quality "$quality" -strip '"$output"'
  else
    "$CONVERT_CMD" "$input" -quality "$quality" -strip "$output"
  fi
}

# ---------------------------------------------------------------------------
# Core: optimize with sips (fallback)
# ---------------------------------------------------------------------------

optimize_with_sips() {
  local input="$1"
  local output="$2"
  local max_dim="$3"
  local quality="$4"

  # sips is limited: can resize and convert format, but no quality control for PNG
  # Copy first, then resize
  cp "$input" "$output"

  if [ "$max_dim" -gt 0 ]; then
    sips --resampleHeightWidthMax "$max_dim" "$output" >/dev/null 2>&1
  fi

  # Convert to JPEG if output ends in .jpg
  local ext
  ext="$(echo "${output##*.}" | tr 'A-Z' 'a-z')"
  if [ "$ext" = "jpg" ] || [ "$ext" = "jpeg" ]; then
    sips -s format jpeg "$output" --out "$output" >/dev/null 2>&1
  fi
}

# ---------------------------------------------------------------------------
# Command: optimize — compress a single image
# ---------------------------------------------------------------------------

cmd_optimize() {
  local input="" profile="web" output="" format=""

  # Parse first positional arg
  if [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; then
    input="$1"
    shift
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --profile)  profile="$2";  shift 2 ;;
      --output)   output="$2";   shift 2 ;;
      --format)   format="$2";   shift 2 ;;
      *)
        if [ -z "$input" ]; then
          input="$1"
          shift
        else
          die "Unknown option: $1"
        fi
        ;;
    esac
  done

  if [ -z "$input" ]; then
    die "Usage: image-optimizer.sh optimize <input> [--profile avatar|social|ecommerce|web|original] [--output path] [--format png|jpg|webp]"
  fi

  if [ ! -f "$input" ]; then
    die "File not found: $input"
  fi

  # Get profile config
  local config
  config="$(get_profile_config "$profile")"
  local max_dim quality resize_mode
  max_dim="$(echo "$config" | cut -d' ' -f1)"
  quality="$(echo "$config" | cut -d' ' -f2)"
  resize_mode="$(echo "$config" | cut -d' ' -f3)"

  # Determine output format
  if [ -z "$format" ]; then
    format="jpg"
  fi

  # Determine output path
  if [ -z "$output" ]; then
    local base_name dir_name
    dir_name="$(dirname "$input")"
    base_name="$(basename "$input")"
    local name_no_ext="${base_name%.*}"
    output="${dir_name}/${name_no_ext}_${profile}.${format}"
  fi

  # Get before size
  local before_bytes
  before_bytes="$(file_size_bytes "$input")"
  local before_human
  before_human="$(human_size "$before_bytes")"

  # Optimize
  mkdir -p "$(dirname "$output")"

  if [ "$USE_SIPS" = true ]; then
    optimize_with_sips "$input" "$output" "$max_dim" "$quality"
  else
    optimize_with_convert "$input" "$output" "$max_dim" "$quality" "$resize_mode"
  fi

  if [ ! -f "$output" ]; then
    die "Optimization failed: output file not created"
  fi

  # Get after size
  local after_bytes
  after_bytes="$(file_size_bytes "$output")"
  local after_human
  after_human="$(human_size "$after_bytes")"
  local ratio
  ratio="$(compression_ratio "$before_bytes" "$after_bytes")"

  info "  $before_human -> $after_human ($ratio) => $output"
  echo "$output"
}

# ---------------------------------------------------------------------------
# Command: batch — batch compress a directory
# ---------------------------------------------------------------------------

cmd_batch() {
  local dir="" profile="web" suffix="_opt" recursive=false

  # Parse first positional arg
  if [ $# -gt 0 ] && [ "${1:0:1}" != "-" ]; then
    dir="$1"
    shift
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --profile)    profile="$2";    shift 2 ;;
      --suffix)     suffix="$2";     shift 2 ;;
      --recursive)  recursive=true;  shift ;;
      *)
        if [ -z "$dir" ]; then
          dir="$1"
          shift
        else
          die "Unknown option: $1"
        fi
        ;;
    esac
  done

  if [ -z "$dir" ]; then
    die "Usage: image-optimizer.sh batch <directory> [--profile profile] [--suffix suffix] [--recursive]"
  fi

  if [ ! -d "$dir" ]; then
    die "Directory not found: $dir"
  fi

  info "Batch optimizing: $dir (profile: $profile, suffix: $suffix)"
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local count=0
  local total_before=0
  local total_after=0

  # Find image files
  local find_depth=""
  if [ "$recursive" = false ]; then
    find_depth="-maxdepth 1"
  fi

  # Use find with macOS-compatible options
  local files_list
  if [ "$recursive" = true ]; then
    files_list="$(find "$dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort)"
  else
    files_list="$(find "$dir" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort)"
  fi

  if [ -z "$files_list" ]; then
    info "No image files found in $dir"
    return 0
  fi

  echo "$files_list" | while IFS= read -r file; do
    # Skip already-optimized files
    local base
    base="$(basename "$file")"
    case "$base" in
      *_opt.* | *_avatar.* | *_social.* | *_ecommerce.* | *_web.* | *_256.*)
        continue
        ;;
    esac

    local name_no_ext="${base%.*}"
    local dir_name
    dir_name="$(dirname "$file")"
    local out_path="${dir_name}/${name_no_ext}${suffix}.jpg"

    local before_bytes
    before_bytes="$(file_size_bytes "$file")"

    cmd_optimize "$file" --profile "$profile" --output "$out_path" >/dev/null 2>&1 || true

    if [ -f "$out_path" ]; then
      local after_bytes
      after_bytes="$(file_size_bytes "$out_path")"
      local before_h after_h ratio
      before_h="$(human_size "$before_bytes")"
      after_h="$(human_size "$after_bytes")"
      ratio="$(compression_ratio "$before_bytes" "$after_bytes")"
      info "  $base: $before_h -> $after_h ($ratio)"
      count=$((count + 1))
    fi
  done

  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info "Done. Optimized files in $dir"
}

# ---------------------------------------------------------------------------
# Command: dashboard — optimize boss dashboard avatars
# ---------------------------------------------------------------------------

cmd_dashboard() {
  info ""
  info "GAIA Boss Dashboard Avatar Optimizer"
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ ! -f "$MANIFEST" ]; then
    die "Manifest not found: $MANIFEST"
  fi

  # Parse manifest with python (Bash 3.2 has no jq guarantee)
  local agent_files
  agent_files="$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
agents = data.get('agents', {})
for name, info in agents.items():
    print('%s|%s' % (name, info.get('file', '')))
" "$MANIFEST")"

  if [ -z "$agent_files" ]; then
    die "No agents found in manifest"
  fi

  local total_before=0
  local total_after=0
  local count=0

  info ""
  printf "  %-14s %-12s %-12s %s\n" "Agent" "Before" "After" "Reduction"
  printf "  %-14s %-12s %-12s %s\n" "──────────" "────────" "────────" "─────────"

  echo "$agent_files" | while IFS='|' read -r agent_name file_name; do
    if [ -z "$file_name" ]; then
      continue
    fi

    local input_path="${AVATARS_DIR}/${file_name}"
    if [ ! -f "$input_path" ]; then
      info "  $agent_name: SKIP (file not found: $file_name)"
      continue
    fi

    # Output: original_name_256.jpg
    local name_no_ext="${file_name%.*}"
    local output_path="${AVATARS_DIR}/${name_no_ext}_256.jpg"

    local before_bytes
    before_bytes="$(file_size_bytes "$input_path")"

    # Optimize with avatar profile
    if [ "$USE_SIPS" = true ]; then
      optimize_with_sips "$input_path" "$output_path" 256 80
    else
      optimize_with_convert "$input_path" "$output_path" 256 80 fill
    fi

    if [ -f "$output_path" ]; then
      local after_bytes
      after_bytes="$(file_size_bytes "$output_path")"
      local before_h after_h ratio
      before_h="$(human_size "$before_bytes")"
      after_h="$(human_size "$after_bytes")"
      ratio="$(compression_ratio "$before_bytes" "$after_bytes")"
      printf "  %-14s %-12s %-12s %s\n" "$agent_name" "$before_h" "$after_h" "$ratio"
      log "INFO" "Dashboard avatar: $agent_name $before_h -> $after_h ($ratio)"
      count=$((count + 1))
    else
      info "  $agent_name: FAILED"
    fi
  done

  info ""
  info "Optimized avatars saved to: $AVATARS_DIR"
  info "Files named: *_256.jpg"
  info ""
}

# ---------------------------------------------------------------------------
# Command: stats — show size stats for a directory
# ---------------------------------------------------------------------------

cmd_stats() {
  local dir="$1"

  if [ -z "$dir" ] || [ ! -d "$dir" ]; then
    die "Usage: image-optimizer.sh stats <directory>"
  fi

  info ""
  info "Image Size Stats: $dir"
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local total_bytes=0
  local count=0
  local largest_bytes=0
  local largest_name=""
  local smallest_bytes=999999999
  local smallest_name=""

  printf "  %-50s %12s\n" "File" "Size"
  printf "  %-50s %12s\n" "──────────────────────────────────────────────────" "──────────"

  for file in "$dir"/*.png "$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.webp "$dir"/*.PNG "$dir"/*.JPG "$dir"/*.JPEG "$dir"/*.WEBP; do
    if [ ! -f "$file" ]; then
      continue
    fi

    local base
    base="$(basename "$file")"
    local bytes
    bytes="$(file_size_bytes "$file")"
    local human
    human="$(human_size "$bytes")"

    printf "  %-50s %12s\n" "$base" "$human"

    total_bytes=$((total_bytes + bytes))
    count=$((count + 1))

    if [ "$bytes" -gt "$largest_bytes" ]; then
      largest_bytes=$bytes
      largest_name="$base"
    fi
    if [ "$bytes" -lt "$smallest_bytes" ]; then
      smallest_bytes=$bytes
      smallest_name="$base"
    fi
  done

  if [ "$count" -eq 0 ]; then
    info "  No image files found."
    return 0
  fi

  local total_human
  total_human="$(human_size "$total_bytes")"
  local avg_bytes=$((total_bytes / count))
  local avg_human
  avg_human="$(human_size "$avg_bytes")"
  local largest_human
  largest_human="$(human_size "$largest_bytes")"
  local smallest_human
  smallest_human="$(human_size "$smallest_bytes")"

  info ""
  info "  Total files:  $count"
  info "  Total size:   $total_human"
  info "  Average size: $avg_human"
  info "  Largest:      $largest_name ($largest_human)"
  info "  Smallest:     $smallest_name ($smallest_human)"
  info ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

usage() {
  echo ""
  echo "GAIA Image Optimizer"
  echo "━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Usage: image-optimizer.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  optimize <input> [options]   Compress a single image"
  echo "    --profile <profile>        avatar|social|ecommerce|web|original (default: web)"
  echo "    --output <path>            Output path (default: input_profile.ext)"
  echo "    --format <fmt>             png|jpg|webp (default: jpg)"
  echo ""
  echo "  batch <dir> [options]        Batch compress a directory"
  echo "    --profile <profile>        Profile to apply"
  echo "    --suffix <suffix>          Added to filename (default: _opt)"
  echo "    --recursive                Process subdirectories"
  echo ""
  echo "  dashboard                    Optimize boss dashboard avatars"
  echo "                               Reads manifest.json, creates 256x256 JPGs"
  echo ""
  echo "  stats <dir>                  Show size stats for a directory"
  echo ""
  echo "Profiles:"
  echo "  avatar     256x256, q80, center-crop, ~40-80KB"
  echo "  social     1080x1080 max, q82, ~200-300KB"
  echo "  ecommerce  800x800 max, q85, ~100-200KB"
  echo "  web        1024 max dim, q80, ~100-200KB"
  echo "  original   No resize, q90, strip metadata only"
  echo ""
}

main() {
  detect_tools

  if [ $# -eq 0 ]; then
    usage
    exit 0
  fi

  local command="$1"
  shift

  case "$command" in
    optimize)   cmd_optimize "$@" ;;
    batch)      cmd_batch "$@" ;;
    dashboard)  cmd_dashboard "$@" ;;
    stats)      cmd_stats "$@" ;;
    help|-h|--help) usage ;;
    *)
      die "Unknown command: $command. Run with --help for usage."
      ;;
  esac
}

main "$@"
