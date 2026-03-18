#!/usr/bin/env bash
# video-review.sh — Video QA Tool for GAIA OS
# Adapted from Tricia's review_video.py — contact sheets, motion-diff, scene detection
#
# Usage:
#   video-review.sh contact   <video> [--output dir] [--cols 6] [--rows 4]
#   video-review.sh motion    <video> [--output dir]
#   video-review.sh scenes    <video> [--output dir] [--threshold 0.3]
#   video-review.sh preview   <video> [--output dir] [--fps 8] [--width 480]
#   video-review.sh full      <video> [--output dir]  # all checks
#   video-review.sh score     <video>                  # quick pass/fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

info()  { echo "[video-review] $*"; }
warn()  { echo "[video-review] WARNING: $*" >&2; }
error() { echo "[video-review] ERROR: $*" >&2; }

check_ffmpeg() {
  command -v ffmpeg >/dev/null 2>&1 || { error "FFmpeg required"; exit 1; }
  command -v ffprobe >/dev/null 2>&1 || { error "ffprobe required"; exit 1; }
}

get_duration() {
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null | cut -d. -f1
}

get_resolution() {
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$1" 2>/dev/null
}

basename_no_ext() {
  local base
  base=$(basename "$1")
  echo "${base%.*}"
}

# --- CONTACT SHEET ---
# 6x4 grid of evenly-spaced frames — instant visual overview
cmd_contact() {
  local input="" output_dir="" cols=6 rows=4

  while [ $# -gt 0 ]; do
    case "$1" in
      --output) output_dir="$2"; shift 2 ;;
      --cols) cols="$2"; shift 2 ;;
      --rows) rows="$2"; shift 2 ;;
      -*) error "Unknown option: $1"; exit 1 ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] || [ ! -f "$input" ] && { error "Input file required: $input"; exit 1; }
  check_ffmpeg

  local base duration total_frames fps_extract
  base=$(basename_no_ext "$input")
  duration=$(get_duration "$input")
  total_frames=$((cols * rows))
  fps_extract=$(python3 -c "print(round($total_frames / max($duration, 1), 4))")

  [ -z "$output_dir" ] && output_dir="$(dirname "$input")/review"
  mkdir -p "$output_dir"

  local contact_file="$output_dir/${base}_contact_${cols}x${rows}.jpg"

  info "Generating ${cols}x${rows} contact sheet (${total_frames} frames from ${duration}s video)"

  ffmpeg -y -i "$input" \
    -vf "fps=$fps_extract,scale=320:-1,tile=${cols}x${rows}" \
    -frames:v 1 \
    -q:v 2 \
    "$contact_file" 2>/dev/null

  if [ -f "$contact_file" ]; then
    info "Contact sheet: $contact_file"
    echo "$contact_file"
  else
    error "Failed to generate contact sheet"
    return 1
  fi
}

# --- MOTION DIFFERENCE ---
# Bright areas = high motion between frames. Black = static. Detects Sora/Kling artifacts.
cmd_motion() {
  local input="" output_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --output) output_dir="$2"; shift 2 ;;
      -*) error "Unknown option: $1"; exit 1 ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] || [ ! -f "$input" ] && { error "Input file required: $input"; exit 1; }
  check_ffmpeg

  local base duration
  base=$(basename_no_ext "$input")
  duration=$(get_duration "$input")

  [ -z "$output_dir" ] && output_dir="$(dirname "$input")/review"
  mkdir -p "$output_dir"

  local motion_file="$output_dir/${base}_motion_diff.jpg"
  local total_frames=24
  local fps_extract
  fps_extract=$(python3 -c "print(round($total_frames / max($duration, 1), 4))")

  info "Generating motion-diff analysis (bright = high motion, black = static)"

  # tblend=all_mode=difference shows frame-to-frame changes
  ffmpeg -y -i "$input" \
    -vf "fps=$fps_extract,tblend=all_mode=difference,scale=320:-1,tile=6x4" \
    -frames:v 1 \
    -q:v 2 \
    "$motion_file" 2>/dev/null

  if [ -f "$motion_file" ]; then
    info "Motion diff: $motion_file"
    echo "$motion_file"
  else
    error "Failed to generate motion diff"
    return 1
  fi
}

# --- SCENE DETECTION ---
# Detects scene changes using frame difference threshold
cmd_scenes() {
  local input="" output_dir="" threshold="0.3"

  while [ $# -gt 0 ]; do
    case "$1" in
      --output) output_dir="$2"; shift 2 ;;
      --threshold) threshold="$2"; shift 2 ;;
      -*) error "Unknown option: $1"; exit 1 ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] || [ ! -f "$input" ] && { error "Input file required: $input"; exit 1; }
  check_ffmpeg

  local base
  base=$(basename_no_ext "$input")

  [ -z "$output_dir" ] && output_dir="$(dirname "$input")/review"
  mkdir -p "$output_dir"

  local scenes_file="$output_dir/${base}_scenes.json"

  info "Detecting scene changes (threshold=$threshold)"

  # Use FFmpeg scene detection filter
  local scene_data
  scene_data=$(ffmpeg -i "$input" \
    -vf "select='gt(scene,$threshold)',showinfo" \
    -f null - 2>&1 | grep "Parsed_showinfo" | \
    sed -n 's/.*pts_time:\([0-9.]*\).*/\1/p')

  local scene_count=0
  local scenes_json="["
  local prev_time="0"

  while IFS= read -r timestamp; do
    [ -z "$timestamp" ] && continue
    if [ "$scene_count" -gt 0 ]; then
      scenes_json+=","
    fi
    scenes_json+="{\"scene\":$((scene_count + 1)),\"start\":$prev_time,\"end\":$timestamp}"
    prev_time="$timestamp"
    scene_count=$((scene_count + 1))
  done <<< "$scene_data"

  # Add final scene to end of video
  local duration
  duration=$(get_duration "$input")
  if [ "$scene_count" -gt 0 ]; then
    scenes_json+=",{\"scene\":$((scene_count + 1)),\"start\":$prev_time,\"end\":$duration}"
  else
    scenes_json+="{\"scene\":1,\"start\":0,\"end\":$duration}"
  fi
  scene_count=$((scene_count + 1))
  scenes_json+="]"

  echo "$scenes_json" | python3 -m json.tool > "$scenes_file"

  info "Found $scene_count scenes → $scenes_file"
  echo "$scenes_file"
}

# --- PREVIEW GIF ---
# Quick preview GIF for sharing/reviewing
cmd_preview() {
  local input="" output_dir="" fps=8 width=480

  while [ $# -gt 0 ]; do
    case "$1" in
      --output) output_dir="$2"; shift 2 ;;
      --fps) fps="$2"; shift 2 ;;
      --width) width="$2"; shift 2 ;;
      -*) error "Unknown option: $1"; exit 1 ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] || [ ! -f "$input" ] && { error "Input file required: $input"; exit 1; }
  check_ffmpeg

  local base
  base=$(basename_no_ext "$input")

  [ -z "$output_dir" ] && output_dir="$(dirname "$input")/review"
  mkdir -p "$output_dir"

  local gif_file="$output_dir/${base}_preview.gif"

  info "Generating preview GIF (${width}px, ${fps}fps)"

  ffmpeg -y -i "$input" \
    -vf "fps=$fps,scale=$width:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse" \
    -t 10 \
    "$gif_file" 2>/dev/null

  if [ -f "$gif_file" ]; then
    local size
    size=$(du -h "$gif_file" | cut -f1)
    info "Preview GIF: $gif_file ($size)"
    echo "$gif_file"
  else
    error "Failed to generate preview GIF"
    return 1
  fi
}

# --- QUICK SCORE ---
# Automated pass/fail checks without visual output
cmd_score() {
  local input=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -*) shift ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] || [ ! -f "$input" ] && { error "Input file required: $input"; exit 1; }
  check_ffmpeg

  local duration resolution width height
  duration=$(get_duration "$input")
  resolution=$(get_resolution "$input")
  width=$(echo "$resolution" | cut -d, -f1)
  height=$(echo "$resolution" | cut -d, -f2)

  local score=100
  local issues=""

  # Check 1: Duration bounds (5-120s for social media)
  if [ "$duration" -lt 5 ]; then
    score=$((score - 30))
    issues+="  FAIL: Too short (${duration}s, min 5s)\n"
  elif [ "$duration" -gt 120 ]; then
    score=$((score - 15))
    issues+="  WARN: Long for social (${duration}s, prefer <60s)\n"
  fi

  # Check 2: Resolution
  if [ "$width" -lt 720 ] || [ "$height" -lt 720 ]; then
    score=$((score - 25))
    issues+="  FAIL: Low resolution (${width}x${height}, min 720p)\n"
  fi

  # Check 3: Aspect ratio (9:16 preferred for shorts)
  local aspect_ok=0
  if [ "$height" -gt "$width" ]; then
    # Portrait — check if close to 9:16
    local ratio
    ratio=$(python3 -c "print(round($height/$width, 2))")
    if python3 -c "exit(0 if 1.7 <= $ratio <= 1.85 else 1)"; then
      aspect_ok=1
    fi
  fi
  if [ "$aspect_ok" -eq 0 ] && [ "$height" -gt "$width" ]; then
    score=$((score - 5))
    issues+="  WARN: Not standard 9:16 (${width}x${height})\n"
  fi

  # Check 4: Has audio
  local has_audio
  has_audio=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$input" 2>/dev/null | head -1)
  if [ -z "$has_audio" ]; then
    score=$((score - 10))
    issues+="  WARN: No audio track\n"
  fi

  # Check 5: File size (warn if > 100MB)
  local file_size
  file_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input" 2>/dev/null || echo "0")
  if [ "$file_size" -gt 104857600 ]; then
    score=$((score - 5))
    issues+="  WARN: Large file ($(($file_size / 1048576))MB, consider compression)\n"
  fi

  # Check 6: Black frames detection (first and last 2s)
  local black_start
  black_start=$(ffmpeg -i "$input" -t 2 -vf "blackdetect=d=0.5:pix_th=0.10" -f null - 2>&1 | grep -c "black_start" || true)
  if [ "$black_start" -gt 0 ]; then
    score=$((score - 10))
    issues+="  WARN: Black frames in first 2 seconds (bad hook)\n"
  fi

  # Output
  local grade="PASS"
  if [ "$score" -lt 50 ]; then grade="FAIL"
  elif [ "$score" -lt 75 ]; then grade="WARN"
  fi

  echo ""
  echo "=== VIDEO QA SCORE ==="
  echo "File:       $(basename "$input")"
  echo "Resolution: ${width}x${height}"
  echo "Duration:   ${duration}s"
  echo "Score:      ${score}/100 [$grade]"
  if [ -n "$issues" ]; then
    echo ""
    echo "Issues:"
    echo -e "$issues"
  fi
  echo "======================"

  # Return non-zero if failed
  [ "$score" -ge 50 ] && return 0 || return 1
}

# --- FULL REVIEW ---
cmd_full() {
  local input="" output_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --output) output_dir="$2"; shift 2 ;;
      -*) shift ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] || [ ! -f "$input" ] && { error "Input file required: $input"; exit 1; }

  [ -z "$output_dir" ] && output_dir="$(dirname "$input")/review"

  info "Running full video review..."
  echo ""

  cmd_score "$input"
  echo ""
  cmd_contact "$input" --output "$output_dir"
  cmd_motion "$input" --output "$output_dir"
  cmd_scenes "$input" --output "$output_dir"
  cmd_preview "$input" --output "$output_dir"

  echo ""
  info "Full review complete → $output_dir/"
}

# --- MAIN ---
case "${1:-help}" in
  contact)  shift; cmd_contact "$@" ;;
  motion)   shift; cmd_motion "$@" ;;
  scenes)   shift; cmd_scenes "$@" ;;
  preview)  shift; cmd_preview "$@" ;;
  score)    shift; cmd_score "$@" ;;
  full)     shift; cmd_full "$@" ;;
  help|--help|-h)
    echo "video-review.sh — Video QA Tool for GAIA OS"
    echo ""
    echo "Commands:"
    echo "  contact  <video>  — Generate contact sheet (6x4 frame grid)"
    echo "  motion   <video>  — Motion-diff analysis (bright=motion, black=static)"
    echo "  scenes   <video>  — Detect scene changes (JSON output)"
    echo "  preview  <video>  — Generate preview GIF (10s, 480px)"
    echo "  score    <video>  — Quick automated pass/fail (no files generated)"
    echo "  full     <video>  — All of the above"
    echo ""
    echo "Options:"
    echo "  --output <dir>     Output directory"
    echo "  --cols N --rows N  Contact sheet grid size (default 6x4)"
    echo "  --threshold N      Scene detection threshold (default 0.3)"
    echo "  --fps N            Preview GIF framerate (default 8)"
    echo "  --width N          Preview GIF width (default 480)"
    ;;
  *)
    error "Unknown command: $1"
    echo "Run: video-review.sh help"
    exit 1
    ;;
esac
