#!/usr/bin/env bash
# jade-vibe-reel.sh — Create subtle animation reels from still images with music
# Converts a still image into a cinematic 9:16 reel with motion effects,
# warm color grading, film grain, and optional background music.
#
# Usage:
#   bash jade-vibe-reel.sh --image photo.png [--music track.mp3] [--duration 15] \
#                          [--effect ken-burns|parallax|breathe|float] [--output out.mp4] \
#                          [--dry-run]
#
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}

set -euo pipefail

###############################################################################
# Constants
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily"
LOFI_DIR="$OPENCLAW_DIR/workspace/data/music/lofi"
LOG_FILE="$OPENCLAW_DIR/logs/jade-vibe-reel.log"
FPS=30
WIDTH=1080
HEIGHT=1920
MAX_SIZE_BYTES=15728640  # 15MB for IG

mkdir -p "$(dirname "$LOG_FILE")"

###############################################################################
# Logging
###############################################################################

log() {
    local msg="[jade-vibe-reel $(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

err() {
    echo "[jade-vibe-reel $(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    echo "[jade-vibe-reel $(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

###############################################################################
# Defaults
###############################################################################

IMAGE=""
MUSIC=""
DURATION=15
EFFECT="ken-burns"
OUTPUT=""
DRY_RUN=0

###############################################################################
# Parse arguments
###############################################################################

usage() {
    cat <<USAGE
Usage: bash jade-vibe-reel.sh --image PATH [OPTIONS]

Required:
  --image PATH        Source still image (png, jpg, webp)

Options:
  --music PATH        Background music track (mp3, wav, aac)
  --duration N        Duration in seconds (default: 15)
  --effect EFFECT     Animation effect: ken-burns, parallax, breathe, float (default: ken-burns)
  --output PATH       Output file path (default: auto-generated in content dir)
  --dry-run           Show what would be done without executing ffmpeg

Effects:
  ken-burns   Slow zoom in from 100% to 103%
  parallax    Slow horizontal pan left to right
  breathe     Subtle zoom in/out breathing cycle
  float       Gentle vertical floating motion
USAGE
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --image)
            [ -z "${2:-}" ] && { err "--image requires a path"; usage; }
            IMAGE="$2"; shift 2 ;;
        --music)
            [ -z "${2:-}" ] && { err "--music requires a path"; usage; }
            MUSIC="$2"; shift 2 ;;
        --duration)
            [ -z "${2:-}" ] && { err "--duration requires a number"; usage; }
            DURATION="$2"; shift 2 ;;
        --effect)
            [ -z "${2:-}" ] && { err "--effect requires a value"; usage; }
            EFFECT="$2"; shift 2 ;;
        --output)
            [ -z "${2:-}" ] && { err "--output requires a path"; usage; }
            OUTPUT="$2"; shift 2 ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            err "Unknown argument: $1"; usage ;;
    esac
done

###############################################################################
# Validation
###############################################################################

if [ -z "$IMAGE" ]; then
    err "--image is required"
    usage
fi

if [ ! -f "$IMAGE" ]; then
    err "Image file not found: $IMAGE"
    exit 1
fi

# Validate effect name (Bash 3.2 compatible lowercase check)
EFFECT_LOWER="$(echo "$EFFECT" | tr '[:upper:]' '[:lower:]')"
case "$EFFECT_LOWER" in
    ken-burns|parallax|breathe|float) EFFECT="$EFFECT_LOWER" ;;
    *)
        err "Invalid effect: $EFFECT (must be ken-burns, parallax, breathe, or float)"
        exit 1
        ;;
esac

# Validate duration is a positive integer
if ! echo "$DURATION" | grep -qE '^[1-9][0-9]*$'; then
    err "Duration must be a positive integer, got: $DURATION"
    exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    err "ffmpeg is required. Install via: brew install ffmpeg"
    exit 1
fi

###############################################################################
# Resolve output path
###############################################################################

TODAY="$(date +%Y-%m-%d)"
TIMESTAMP="$(date +%s)"

if [ -z "$OUTPUT" ]; then
    OUTPUT_DIR="$CONTENT_DIR/$TODAY"
    mkdir -p "$OUTPUT_DIR"
    OUTPUT="$OUTPUT_DIR/vibe-reel-${TIMESTAMP}.mp4"
else
    mkdir -p "$(dirname "$OUTPUT")"
fi

###############################################################################
# Resolve music
###############################################################################

resolve_music() {
    # If explicitly provided, use it
    if [ -n "$MUSIC" ]; then
        if [ ! -f "$MUSIC" ]; then
            err "Music file not found: $MUSIC"
            exit 1
        fi
        echo "$MUSIC"
        return
    fi

    # Try lofi directory
    if [ -d "$LOFI_DIR" ]; then
        local found=""
        found="$(find "$LOFI_DIR" -maxdepth 1 -name '*.mp3' -type f 2>/dev/null | head -1)"
        if [ -n "$found" ]; then
            log "Auto-selected lofi track: $found"
            echo "$found"
            return
        fi
    fi

    # No music available
    echo ""
}

RESOLVED_MUSIC="$(resolve_music)"

###############################################################################
# Compute frame count
###############################################################################

FRAMES=$((DURATION * FPS))

###############################################################################
# Build zoompan filter for the chosen effect
###############################################################################

build_effect_filter() {
    local effect="$1"
    local frames="$2"

    case "$effect" in
        ken-burns)
            # Slow zoom in from 100% to ~103%
            echo "zoompan=z='1+0.002*on':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        parallax)
            # Slow horizontal pan left to right
            echo "zoompan=z='1.05':d=${frames}:x='(iw-iw/zoom)*on/${frames}':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        breathe)
            # Subtle zoom in then out (breathing)
            echo "zoompan=z='1+0.01*sin(2*PI*on/(${frames}))':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        float)
            # Gentle vertical float
            echo "zoompan=z='1.03':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)+10*sin(2*PI*on/${frames}*2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
    esac
}

ZOOMPAN_FILTER="$(build_effect_filter "$EFFECT" "$FRAMES")"

###############################################################################
# Build the full video filter chain
###############################################################################
# Pipeline:
#   1. Scale/crop input image to fill 1080x1920 (center crop)
#   2. Apply zoompan motion effect
#   3. Add warm color grade (slight orange tint via curves)
#   4. Add subtle vignette
#   5. Add film grain

# Step 1: Pre-scale the image to at least 1080x1920, then center-crop.
# We use scale+crop as an input filter before zoompan.
# zoompan reads from a single frame, so we pre-process the image first.

PRESCALE_FILTER="scale=w='if(gt(iw/ih,${WIDTH}/${HEIGHT}),${WIDTH}*ih/iw*iw/${WIDTH},-2)':h='if(gt(iw/ih,${WIDTH}/${HEIGHT}),-2,${HEIGHT}*iw/ih*ih/${HEIGHT})'"

# Simpler approach: scale to cover 1080x1920 then crop center
# scale2ref won't work here. Use scale with force_original_aspect_ratio=increase, then crop.
PRESCALE="scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT}"

# Post-zoompan filters (applied to the video output of zoompan):
# - Warm color grade: boost red/orange slightly via colorbalance
# - Vignette: subtle darkening at edges
# - Film grain: noise filter
POST_FILTERS="colorbalance=rs=0.05:gs=0.02:bs=-0.03:rm=0.04:gm=0.01:bm=-0.02,vignette=PI/5,noise=alls=3:allf=t+u"

# The full video filter graph:
# Input image -> prescale/crop -> zoompan -> post-processing
VIDEO_FILTER="${PRESCALE},${ZOOMPAN_FILTER},${POST_FILTERS}"

###############################################################################
# Build the ffmpeg command
###############################################################################

TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

build_ffmpeg_cmd() {
    local cmd=""

    if [ -n "$RESOLVED_MUSIC" ]; then
        # With music: two inputs, complex filter for audio
        local fade_start=$((DURATION - 2))
        [ "$fade_start" -lt 0 ] && fade_start=0

        cmd="ffmpeg -y -loop 1 -i \"$IMAGE\" -i \"$RESOLVED_MUSIC\""
        cmd="$cmd -filter_complex \"[0:v]${VIDEO_FILTER}[v];[1:a]volume=0.3,afade=t=out:st=${fade_start}:d=2[aout]\""
        cmd="$cmd -map \"[v]\" -map \"[aout]\""
        cmd="$cmd -t $DURATION"
        cmd="$cmd -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p"
        cmd="$cmd -c:a aac -b:a 128k"
        cmd="$cmd -shortest"
        cmd="$cmd -movflags +faststart"
        cmd="$cmd \"$OUTPUT\""
    else
        # No music: generate silent audio track
        cmd="ffmpeg -y -loop 1 -i \"$IMAGE\" -f lavfi -i anullsrc=r=44100:cl=stereo"
        cmd="$cmd -filter_complex \"[0:v]${VIDEO_FILTER}[v]\""
        cmd="$cmd -map \"[v]\" -map 1:a"
        cmd="$cmd -t $DURATION"
        cmd="$cmd -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p"
        cmd="$cmd -c:a aac -b:a 128k"
        cmd="$cmd -shortest"
        cmd="$cmd -movflags +faststart"
        cmd="$cmd \"$OUTPUT\""
    fi

    echo "$cmd"
}

FFMPEG_CMD="$(build_ffmpeg_cmd)"

###############################################################################
# Execute or dry-run
###############################################################################

log "=== jade-vibe-reel ==="
log "Image:    $IMAGE"
log "Music:    ${RESOLVED_MUSIC:-<none — silent>}"
log "Effect:   $EFFECT"
log "Duration: ${DURATION}s (${FRAMES} frames @ ${FPS}fps)"
log "Output:   $OUTPUT"
log "Dry-run:  $DRY_RUN"

if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would execute:"
    echo ""
    echo "$FFMPEG_CMD"
    echo ""
    echo "Output would be: $OUTPUT"
    exit 0
fi

log "Rendering reel..."

# Execute the ffmpeg command
eval "$FFMPEG_CMD" 2>"$TMPDIR_WORK/ffmpeg-stderr.log"
FFMPEG_EXIT=$?

if [ "$FFMPEG_EXIT" -ne 0 ]; then
    err "ffmpeg exited with code $FFMPEG_EXIT"
    if [ -f "$TMPDIR_WORK/ffmpeg-stderr.log" ]; then
        err "ffmpeg stderr:"
        cat "$TMPDIR_WORK/ffmpeg-stderr.log" >&2
    fi
    exit 1
fi

###############################################################################
# Verify output
###############################################################################

if [ ! -f "$OUTPUT" ]; then
    err "Output file was not created: $OUTPUT"
    exit 1
fi

FILE_SIZE="$(wc -c < "$OUTPUT" | tr -d ' ')"

if [ "$FILE_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
    log "WARNING: Output is ${FILE_SIZE} bytes ($(( FILE_SIZE / 1048576 ))MB) — exceeds 15MB IG limit"
    log "Re-encoding with higher CRF to reduce size..."

    REENCODED="$TMPDIR_WORK/reencoded.mp4"
    ffmpeg -y -i "$OUTPUT" -c:v libx264 -preset medium -crf 28 -pix_fmt yuv420p \
        -c:a aac -b:a 96k -movflags +faststart "$REENCODED" 2>/dev/null

    if [ -f "$REENCODED" ]; then
        REENC_SIZE="$(wc -c < "$REENCODED" | tr -d ' ')"
        if [ "$REENC_SIZE" -lt "$MAX_SIZE_BYTES" ]; then
            mv "$REENCODED" "$OUTPUT"
            FILE_SIZE="$REENC_SIZE"
            log "Re-encoded to ${FILE_SIZE} bytes ($(( FILE_SIZE / 1048576 ))MB)"
        else
            log "WARNING: Still over 15MB after re-encode (${REENC_SIZE} bytes). Consider shorter duration."
        fi
    fi
fi

###############################################################################
# Done
###############################################################################

log "Reel created: $OUTPUT ($(( FILE_SIZE / 1024 ))KB, ${DURATION}s, ${EFFECT})"
echo ""
echo "Output: $OUTPUT"
echo "Size:   $(( FILE_SIZE / 1024 ))KB"
echo "Format: ${WIDTH}x${HEIGHT} @ ${FPS}fps, H.264 + AAC"
echo "Effect: $EFFECT"
