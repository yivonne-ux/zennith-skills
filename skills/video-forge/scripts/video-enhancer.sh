#!/usr/bin/env bash
# video-enhancer.sh — Internal Video Post-Production Enhancer for GAIA CORP-OS
# A unified CLI tool for applying video enhancements (captions, branding, color grading, multi-platform export)
#
# Usage:
#   bash video-enhancer.sh <input> [options]
#
# Options:
#   --captions            Add auto-captions using Whisper
#   --brand <brand>       Apply brand overlays (logo/watermark)
#   --color <preset>      Apply LUT/color grading preset (warm|cool|cinema|vintage|none)
#   --export-platforms    Export for multiple platforms with safe zones (instagram|tiktok|youtube|linkedin)
#   --output-dir <dir>    Custom output directory (default: ./enhanced)
#   --all                 Apply all enhancements (captions + branding + color + multi-platform export)
#
# Examples:
#   bash video-enhancer.sh video.mp4 --all --brand gaiaos
#   bash video-enhancer.sh video.mp4 --captions --brand gaiaos --color cinema
#   bash video-enhancer.sh video.mp4 --export-platforms

set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDEO_FORGE="$SCRIPT_DIR/video-forge.sh"
LOG_FILE="$HOME/.openclaw/logs/video-enhancer.log"
DEFAULT_OUTPUT_DIR="./enhanced"

mkdir -p "$(dirname "$LOG_FILE")"

# --- Colors for terminal output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [video-enhancer] $1"
  echo "$msg" >> "$LOG_FILE"
}

info() {
  echo -e "${BLUE}[VideoEnhancer]${NC} $1" >&2
  log "$1"
}

success() {
  echo -e "${GREEN}[VideoEnhancer]${NC} ✓ $1" >&2
  log "$1"
}

warn() {
  echo -e "${YELLOW}[VideoEnhancer]${NC} ⚠ $1" >&2
  log "WARNING: $1"
}

error() {
  echo -e "${RED}[VideoEnhancer]${NC} ✗ $1" >&2
  log "ERROR: $1"
}

# --- Usage ---
usage() {
  cat << EOF
${BLUE}VideoEnhancer${NC} — Internal Video Post-Production Enhancer
${GREEN}Usage:${NC}
  bash video-enhancer.sh <input> [options]

${GREEN}Options:${NC}
  --all                 Apply all enhancements
  --captions            Add auto-captions using Whisper
  --brand <brand>       Apply brand overlays (logo/watermark)
  --color <preset>      Apply LUT/color grading preset
                        Presets: ${YELLOW}warm${NC}, ${YELLOW}cool${NC}, ${YELLOW}cinema${NC}, ${YELLOW}vintage${NC}, ${YELLOW}none${NC}
  --export-platforms    Export for multiple platforms with safe zones
  --output-dir <dir>    Custom output directory (default: ./enhanced)

${GREEN}Examples:${NC}
  bash video-enhancer.sh video.mp4 --all --brand gaiaos
  bash video-enhancer.sh video.mp4 --captions --brand gaiaos --color cinema
  bash video-enhancer.sh video.mp4 --export-platforms

${GREEN}Available Brands:${NC}
EOF
  # List available brands
  for brand_dir in "$HOME/.openclaw/brands"/*/; do
    brand_name=$(basename "$brand_dir")
    if [ -f "$brand_dir/brand-dna.json" ]; then
      echo "  - $brand_name"
    fi
  done
  echo ""
}

# --- Check dependencies ---
check_dependencies() {
  if [ ! -f "$VIDEO_FORGE" ]; then
    error "video-forge.sh not found at: $VIDEO_FORGE"
    exit 1
  fi

  if ! command -v ffmpeg >/dev/null 2>&1; then
    error "ffmpeg is required but not installed"
    exit 1
  fi

  info "Dependencies verified ✓"
}

# --- Parse arguments ---
INPUT_FILE=""
DO_CAPTIONS=false
DO_BRAND=false
BRAND_NAME=""
COLOR_PRESET=""
DO_EXPORT=false
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
DO_ALL=false

# Check if no arguments
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

# Check for --help first
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 0
fi

# Parse arguments
INPUT_FILE="$1"
shift

while [ $# -gt 0 ]; do
  case "$1" in
    --all)
      DO_ALL=true
      shift
      ;;
    --captions)
      DO_CAPTIONS=true
      shift
      ;;
    --brand)
      DO_BRAND=true
      BRAND_NAME="$2"
      shift 2
      ;;
    --color)
      COLOR_PRESET="$2"
      shift 2
      ;;
    --export-platforms)
      DO_EXPORT=true
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# --- Validate input file ---
if [ ! -f "$INPUT_FILE" ]; then
  error "Input file not found: $INPUT_FILE"
  exit 1
fi

INPUT_EXT="${INPUT_FILE##*.}"
if [ "$INPUT_EXT" != "mp4" ] && [ "$INPUT_EXT" != "mov" ] && [ "$INPUT_EXT" != "mkv" ]; then
  warn "Input file may not be a video: $INPUT_FILE"
fi

# --- Expand --all flag ---
if [ "$DO_ALL" = true ]; then
  DO_CAPTIONS=true
  DO_BRAND=true
  COLOR_PRESET="cinema"
  DO_EXPORT=true
fi

# --- Check if at least one enhancement is selected ---
if [ "$DO_CAPTIONS" = false ] && [ "$DO_BRAND" = false ] && [ -z "$COLOR_PRESET" ] && [ "$DO_EXPORT" = false ]; then
  warn "No enhancements selected. Use --all or specify individual options."
  usage
  exit 1
fi

# --- Validate brand if specified ---
if [ "$DO_BRAND" = true ] && [ -z "$BRAND_NAME" ]; then
  warn "Brand specified but no brand name provided. Skipping branding."
  DO_BRAND=false
elif [ "$DO_BRAND" = true ]; then
  BRAND_DIR="$HOME/.openclaw/brands/$BRAND_NAME"
  if [ ! -d "$BRAND_DIR" ]; then
    warn "Brand directory not found: $BRAND_DIR. Skipping branding."
    DO_BRAND=false
  fi
fi

# --- Main processing ---
main() {
  local current_file="$INPUT_FILE"
  local base_name
  base_name="$(basename "$current_file")"
  base_name="${base_name%.*}"

  info "Starting video enhancement pipeline..."
  info "Input: $INPUT_FILE"
  info "Output directory: $OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"

  # --- Step 1: Captions ---
  if [ "$DO_CAPTIONS" = true ]; then
    info "Step 1: Adding captions with Whisper..."
    local captioned_file="$OUTPUT_DIR/${base_name}_captioned.mp4"

    if bash "$VIDEO_FORGE" caption "$current_file" --output "$captioned_file" 2>&1 | tee -a "$LOG_FILE"; then
      success "Captions added successfully"
      current_file="$captioned_file"
      base_name="${base_name}_captioned"
    else
      error "Captioning failed. Continuing without captions."
      current_file="$INPUT_FILE" # Reset to original
    fi
  fi

  # --- Step 2: Branding ---
  if [ "$DO_BRAND" = true ] && [ "$DO_BRAND" != "false" ]; then
    info "Step 2: Applying brand overlays ($BRAND_NAME)..."
    local branded_file="$OUTPUT_DIR/${base_name}_branded.mp4"

    if bash "$VIDEO_FORGE" brand "$current_file" --brand "$BRAND_NAME" --output "$branded_file" 2>&1 | tee -a "$LOG_FILE"; then
      success "Branding applied successfully"
      current_file="$branded_file"
      base_name="${base_name}_branded"
    else
      error "Branding failed. Continuing without branding."
    fi
  fi

  # --- Step 3: Color Grading ---
  if [ -n "$COLOR_PRESET" ] && [ "$COLOR_PRESET" != "none" ]; then
    info "Step 3: Applying color grading preset: $COLOR_PRESET..."
    local color_file="$OUTPUT_DIR/${base_name}_${COLOR_PRESET}.mp4"

    # Apply color grading using video-forge effects
    local color_filter=""
    case "$COLOR_PRESET" in
      warm)
        color_filter="eq=contrast=1.1:brightness=0.05:saturation=1.1:gamma=0.95"
        ;;
      cool)
        color_filter="eq=contrast=1.05:brightness=0.02:saturation=0.95:gamma=1.05"
        ;;
      cinema)
        color_filter="eq=contrast=1.15:brightness=-0.05:saturation=0.9:gamma=1.1"
        ;;
      vintage)
        color_filter="eq=contrast=1.1:brightness=0.1:saturation=0.85:gamma=0.9,curves=vintage"
        ;;
      *)
        warn "Unknown color preset: $COLOR_PRESET. Skipping color grading."
        color_filter=""
        ;;
    esac

    if [ -n "$color_filter" ]; then
      if ffmpeg -i "$current_file" -vf "$color_filter" -c:a copy "$color_file" -y 2>&1 | tee -a "$LOG_FILE"; then
        success "Color grading applied successfully"
        current_file="$color_file"
        base_name="${base_name}_${COLOR_PRESET}"
      else
        error "Color grading failed. Continuing without color grading."
      fi
    fi
  fi

  # --- Step 4: Multi-platform Export ---
  if [ "$DO_EXPORT" = true ]; then
    info "Step 4: Exporting for multiple platforms with safe zones..."
    local export_dir="$OUTPUT_DIR/exports"

    # Export for Instagram (9:16, square-safe-zone)
    local ig_file="$export_dir/${base_name}_instagram.mp4"
    if bash "$VIDEO_FORGE" export "$current_file" --platform instagram --output "$ig_file" 2>&1 | tee -a "$LOG_FILE"; then
      success "Instagram export complete: $ig_file"
    else
      # Fallback: basic ffmpeg export with safe zone
      ffmpeg -i "$current_file" -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -preset medium -crf 23 -c:a aac "$ig_file" -y 2>&1 | tee -a "$LOG_FILE"
      success "Instagram export complete (fallback): $ig_file"
    fi

    # Export for TikTok (9:16)
    local tiktok_file="$export_dir/${base_name}_tiktok.mp4"
    if bash "$VIDEO_FORGE" export "$current_file" --platform tiktok --output "$tiktok_file" 2>&1 | tee -a "$LOG_FILE"; then
      success "TikTok export complete: $tiktok_file"
    else
      ffmpeg -i "$current_file" -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -preset medium -crf 23 -c:a aac "$tiktok_file" -y 2>&1 | tee -a "$LOG_FILE"
      success "TikTok export complete (fallback): $tiktok_file"
    fi

    # Export for YouTube (16:9)
    local yt_file="$export_dir/${base_name}_youtube.mp4"
    ffmpeg -i "$current_file" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -preset medium -crf 22 -c:a aac -b:a 128k "$yt_file" -y 2>&1 | tee -a "$LOG_FILE"
    success "YouTube export complete: $yt_file"

    # Export for LinkedIn (16:9, 4:5, 1:1)
    local li_file="$export_dir/${base_name}_linkedin_16x9.mp4"
    ffmpeg -i "$current_file" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -preset medium -crf 23 -c:a aac "$li_file" -y 2>&1 | tee -a "$LOG_FILE"
    success "LinkedIn export complete (16:9): $li_file"
  fi

  # --- Summary ---
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Enhancement Complete!${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo ""
  info "Final output: $current_file"

  if [ "$DO_EXPORT" = true ]; then
    info "Platform exports: $OUTPUT_DIR/exports"
  fi

  echo ""
  info "Log file: $LOG_FILE"
  echo ""
}

# --- Run main ---
check_dependencies
main