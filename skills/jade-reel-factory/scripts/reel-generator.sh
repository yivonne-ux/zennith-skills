#!/usr/bin/env bash
# reel-generator.sh — Generate a Jade Oracle reel from a reverse-engineered blueprint
# Reads a blueprint JSON (scenes array), generates images, converts to video,
# assembles with transitions, applies post-production, and adds music.
#
# Usage:
#   bash reel-generator.sh --blueprint PATH [--style ken-burns|kling|sora|wan] \
#                          [--output PATH] [--dry-run]
#
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}

set -euo pipefail

###############################################################################
# Constants & Paths
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/reels"
LOFI_DIR="$OPENCLAW_DIR/workspace/data/music/lofi"
FACE_REFS_DIR="$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/face-refs"
LOG_FILE="$OPENCLAW_DIR/logs/jade-reel-factory.log"

NANOBANANA="$OPENCLAW_DIR/skills/nanobanana/scripts/nanobanana-gen.sh"
VIDEO_GEN="$OPENCLAW_DIR/skills/video-gen/scripts/video-gen.sh"
VIDEO_FORGE="$OPENCLAW_DIR/skills/video-forge/scripts/video-forge.sh"
JADE_VIBE_REEL="$OPENCLAW_DIR/skills/social-publish/scripts/jade-vibe-reel.sh"

FPS=30
WIDTH=1080
HEIGHT=1920
MAX_SIZE_BYTES=15728640  # 15MB for IG
SCENE_DURATION=4         # seconds per scene clip

mkdir -p "$(dirname "$LOG_FILE")"

###############################################################################
# Logging
###############################################################################

log() {
    local msg="[reel-generator $(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

err() {
    echo "[reel-generator $(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    echo "[reel-generator $(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE" 2>/dev/null || true
}

###############################################################################
# Defaults
###############################################################################

BLUEPRINT=""
STYLE="ken-burns"
OUTPUT=""
DRY_RUN=0

###############################################################################
# Parse arguments
###############################################################################

usage() {
    cat <<USAGE
Usage: bash reel-generator.sh --blueprint PATH [OPTIONS]

Required:
  --blueprint PATH      Path to reel-analysis.json (blueprint with scenes array)

Options:
  --style STYLE         Video style: ken-burns, kling, sora, wan (default: ken-burns)
  --output PATH         Output file path (default: auto in content dir)
  --dry-run             Show pipeline without executing

Styles:
  ken-burns   Still images with Ken Burns motion effects (default, free)
  kling       Kling 3.0 image-to-video (API cost)
  sora        OpenAI Sora image-to-video (API cost)
  wan         Wan 2.6 image-to-video via fal.ai (API cost)
USAGE
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --blueprint)
            [ -z "${2:-}" ] && { err "--blueprint requires a path"; usage; }
            BLUEPRINT="$2"; shift 2 ;;
        --style)
            [ -z "${2:-}" ] && { err "--style requires a value"; usage; }
            STYLE="$2"; shift 2 ;;
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

if [ -z "$BLUEPRINT" ]; then
    err "--blueprint is required"
    usage
fi

if [ ! -f "$BLUEPRINT" ]; then
    err "Blueprint file not found: $BLUEPRINT"
    exit 1
fi

# Validate style (Bash 3.2 compatible lowercase)
STYLE="$(echo "$STYLE" | tr '[:upper:]' '[:lower:]')"
case "$STYLE" in
    ken-burns|kling|sora|wan) ;;
    *)
        err "Invalid style: $STYLE (must be ken-burns, kling, sora, or wan)"
        exit 1
        ;;
esac

# Check ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    err "ffmpeg is required. Install via: brew install ffmpeg"
    exit 1
fi

# Check python3 for JSON parsing
if ! command -v python3 >/dev/null 2>&1; then
    err "python3 is required for JSON parsing"
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
    OUTPUT="$OUTPUT_DIR/reel-${TIMESTAMP}.mp4"
else
    mkdir -p "$(dirname "$OUTPUT")"
fi

###############################################################################
# Create working directory
###############################################################################

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

###############################################################################
# Parse blueprint JSON — extract scenes
###############################################################################

parse_blueprint() {
    python3 << 'PYEOF' "$BLUEPRINT" "$WORK_DIR"
import json, sys, os

blueprint_path = sys.argv[1]
work_dir = sys.argv[2]

with open(blueprint_path, 'r') as f:
    bp = json.load(f)

scenes = bp.get('scenes', bp.get('segments', []))
if not scenes:
    print("ERROR: No scenes found in blueprint", file=sys.stderr)
    sys.exit(1)

# Write scene count
with open(os.path.join(work_dir, 'scene_count.txt'), 'w') as f:
    f.write(str(len(scenes)))

# Write each scene's data
for i, scene in enumerate(scenes):
    prefix = os.path.join(work_dir, 'scene_%02d' % i)

    # Description / visual prompt for image generation
    desc = scene.get('image_prompt', scene.get('description', scene.get('visual', '')))
    with open(prefix + '_prompt.txt', 'w') as f:
        f.write(desc)

    # Motion prompt for video generation (if using AI video)
    motion = scene.get('motion_prompt', scene.get('motion', scene.get('camera_movement', '')))
    with open(prefix + '_motion.txt', 'w') as f:
        f.write(motion)

    # Duration override (optional)
    dur = scene.get('duration', scene.get('duration_s', ''))
    with open(prefix + '_duration.txt', 'w') as f:
        f.write(str(dur))

    # Effect override for ken-burns style
    effect = scene.get('effect', scene.get('camera_effect', ''))
    with open(prefix + '_effect.txt', 'w') as f:
        f.write(effect)

print("Parsed %d scenes" % len(scenes))
PYEOF
}

log "Parsing blueprint: $BLUEPRINT"
PARSE_OUTPUT="$(parse_blueprint 2>&1)" || {
    err "Failed to parse blueprint: $PARSE_OUTPUT"
    exit 1
}
log "$PARSE_OUTPUT"

SCENE_COUNT="$(cat "$WORK_DIR/scene_count.txt")"
if [ "$SCENE_COUNT" -lt 1 ]; then
    err "Blueprint has no scenes"
    exit 1
fi

log "Found $SCENE_COUNT scenes, style: $STYLE"

###############################################################################
# Resolve Jade face reference (first available)
###############################################################################

JADE_FACE_REF=""
if [ -d "$FACE_REFS_DIR" ]; then
    JADE_FACE_REF="$(find "$FACE_REFS_DIR" -maxdepth 1 \( -name '*.png' -o -name '*.jpg' -o -name '*.webp' \) -type f 2>/dev/null | head -1)"
fi
if [ -n "$JADE_FACE_REF" ]; then
    log "Jade face ref: $JADE_FACE_REF"
else
    log "WARNING: No Jade face refs found in $FACE_REFS_DIR"
fi

###############################################################################
# Step 1 & 2: Generate scene images and convert to video
###############################################################################

generate_scene_image() {
    local idx="$1"
    local prefix="$WORK_DIR/scene_$(printf '%02d' "$idx")"
    local prompt_file="${prefix}_prompt.txt"
    local image_out="${prefix}_image.png"

    if [ ! -f "$prompt_file" ]; then
        err "Scene $idx: missing prompt file"
        return 1
    fi

    local prompt
    prompt="$(cat "$prompt_file")"

    if [ -z "$prompt" ]; then
        err "Scene $idx: empty prompt"
        return 1
    fi

    # Build NanoBanana command
    local nb_args="generate --brand jade-oracle --use-case reel-scene"
    nb_args="$nb_args --prompt \"$prompt\""
    nb_args="$nb_args --ratio 9:16 --model pro"

    # Add face reference if available
    if [ -n "$JADE_FACE_REF" ]; then
        nb_args="$nb_args --ref-image \"$JADE_FACE_REF\""
    fi

    if [ -f "$NANOBANANA" ]; then
        log "Scene $idx: generating image via NanoBanana"
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [DRY RUN] bash $NANOBANANA $nb_args"
            # Create a placeholder for dry-run
            echo "PLACEHOLDER" > "$image_out"
            return 0
        fi

        # Run NanoBanana, capture output path from last line
        local nb_output
        nb_output="$(eval "bash \"$NANOBANANA\" $nb_args" 2>&1)" || {
            err "Scene $idx: NanoBanana failed: $nb_output"
            return 1
        }

        # NanoBanana prints the output path — extract it
        local generated_path
        generated_path="$(echo "$nb_output" | grep -E '\.(png|jpg|webp)' | tail -1 | tr -d ' ')"

        if [ -n "$generated_path" ] && [ -f "$generated_path" ]; then
            cp "$generated_path" "$image_out"
            log "Scene $idx: image saved to $image_out"
        else
            err "Scene $idx: could not find generated image in NanoBanana output"
            echo "$nb_output" > "${prefix}_nb_output.log"
            return 1
        fi
    else
        log "Scene $idx: NanoBanana not available, saving prompt file"
        cp "$prompt_file" "${prefix}_prompt_saved.txt"
        echo "  WARNING: NanoBanana not available. Prompt saved to ${prefix}_prompt_saved.txt"
        return 1
    fi
}

convert_scene_to_video() {
    local idx="$1"
    local prefix="$WORK_DIR/scene_$(printf '%02d' "$idx")"
    local image_file="${prefix}_image.png"
    local video_out="${prefix}_video.mp4"
    local motion_file="${prefix}_motion.txt"
    local duration_file="${prefix}_duration.txt"
    local effect_file="${prefix}_effect.txt"

    if [ ! -f "$image_file" ]; then
        err "Scene $idx: no image file to convert"
        return 1
    fi

    # Resolve scene duration (use blueprint override or default)
    local dur="$SCENE_DURATION"
    if [ -f "$duration_file" ]; then
        local dur_override
        dur_override="$(cat "$duration_file" | tr -d ' ')"
        if echo "$dur_override" | grep -qE '^[1-9][0-9]*$'; then
            dur="$dur_override"
        fi
    fi

    # Resolve motion prompt
    local motion_prompt=""
    if [ -f "$motion_file" ]; then
        motion_prompt="$(cat "$motion_file")"
    fi

    case "$STYLE" in
        ken-burns)
            # Use jade-vibe-reel.sh for Ken Burns effect
            local effect="ken-burns"
            if [ -f "$effect_file" ]; then
                local eff_override
                eff_override="$(cat "$effect_file" | tr -d ' ')"
                case "$eff_override" in
                    ken-burns|parallax|breathe|float) effect="$eff_override" ;;
                esac
            fi

            if [ "$DRY_RUN" -eq 1 ]; then
                echo "  [DRY RUN] bash $JADE_VIBE_REEL --image $image_file --duration $dur --effect $effect --output $video_out"
                echo "PLACEHOLDER" > "$video_out"
                return 0
            fi

            if [ -f "$JADE_VIBE_REEL" ]; then
                bash "$JADE_VIBE_REEL" --image "$image_file" --duration "$dur" --effect "$effect" --output "$video_out" 2>&1 || {
                    err "Scene $idx: jade-vibe-reel failed, falling back to raw ffmpeg"
                    _fallback_ken_burns "$image_file" "$video_out" "$dur" "$effect"
                }
            else
                _fallback_ken_burns "$image_file" "$video_out" "$dur" "$effect"
            fi
            ;;
        kling)
            local cmd="bash \"$VIDEO_GEN\" kling generate --image \"$image_file\" --duration $dur"
            if [ -n "$motion_prompt" ]; then
                cmd="$cmd --prompt \"$motion_prompt\""
            else
                cmd="$cmd --prompt \"Gentle cinematic motion, warm cozy lighting\""
            fi
            if [ "$DRY_RUN" -eq 1 ]; then
                echo "  [DRY RUN] $cmd"
                echo "PLACEHOLDER" > "$video_out"
                return 0
            fi
            if [ ! -f "$VIDEO_GEN" ]; then
                err "Scene $idx: video-gen.sh not found, cannot use kling style"
                return 1
            fi
            local vg_output
            vg_output="$(eval "$cmd" 2>&1)" || {
                err "Scene $idx: kling generation failed: $vg_output"
                return 1
            }
            _extract_video_output "$vg_output" "$video_out" "$idx"
            ;;
        sora)
            local cmd="bash \"$VIDEO_GEN\" sora generate --image \"$image_file\" --duration $dur --aspect-ratio 9:16"
            if [ "$DRY_RUN" -eq 1 ]; then
                echo "  [DRY RUN] $cmd"
                echo "PLACEHOLDER" > "$video_out"
                return 0
            fi
            if [ ! -f "$VIDEO_GEN" ]; then
                err "Scene $idx: video-gen.sh not found, cannot use sora style"
                return 1
            fi
            local vg_output
            vg_output="$(eval "$cmd" 2>&1)" || {
                err "Scene $idx: sora generation failed: $vg_output"
                return 1
            }
            _extract_video_output "$vg_output" "$video_out" "$idx"
            ;;
        wan)
            local cmd="bash \"$VIDEO_GEN\" wan generate --image \"$image_file\""
            if [ -n "$motion_prompt" ]; then
                cmd="$cmd --prompt \"$motion_prompt\""
            else
                cmd="$cmd --prompt \"Slow cinematic motion, warm ambient lighting, cozy atmosphere\""
            fi
            if [ "$DRY_RUN" -eq 1 ]; then
                echo "  [DRY RUN] $cmd"
                echo "PLACEHOLDER" > "$video_out"
                return 0
            fi
            if [ ! -f "$VIDEO_GEN" ]; then
                err "Scene $idx: video-gen.sh not found, cannot use wan style"
                return 1
            fi
            local vg_output
            vg_output="$(eval "$cmd" 2>&1)" || {
                err "Scene $idx: wan generation failed: $vg_output"
                return 1
            }
            _extract_video_output "$vg_output" "$video_out" "$idx"
            ;;
    esac

    if [ ! -f "$video_out" ] || [ "$(cat "$video_out" 2>/dev/null)" = "PLACEHOLDER" ]; then
        if [ "$DRY_RUN" -eq 0 ]; then
            err "Scene $idx: video output not created"
            return 1
        fi
    fi

    log "Scene $idx: video ready ($dur s) -> $video_out"
}

# Extract video path from video-gen.sh output
_extract_video_output() {
    local output_text="$1"
    local target_path="$2"
    local idx="$3"

    local video_path
    video_path="$(echo "$output_text" | grep -E '\.(mp4|mov|webm)' | tail -1 | tr -d ' ')"

    if [ -n "$video_path" ] && [ -f "$video_path" ]; then
        cp "$video_path" "$target_path"
    else
        err "Scene $idx: could not extract video path from generator output"
        echo "$output_text" > "$WORK_DIR/scene_$(printf '%02d' "$idx")_vg_output.log"
        return 1
    fi
}

# Fallback Ken Burns via raw ffmpeg (when jade-vibe-reel.sh unavailable)
_fallback_ken_burns() {
    local image="$1"
    local out="$2"
    local dur="$3"
    local effect="$4"
    local frames=$((dur * FPS))

    local zoompan=""
    case "$effect" in
        ken-burns)
            zoompan="zoompan=z='1+0.002*on':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        parallax)
            zoompan="zoompan=z='1.05':d=${frames}:x='(iw-iw/zoom)*on/${frames}':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        breathe)
            zoompan="zoompan=z='1+0.01*sin(2*PI*on/(${frames}))':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        float)
            zoompan="zoompan=z='1.03':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)+10*sin(2*PI*on/${frames}*2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
        *)
            zoompan="zoompan=z='1+0.002*on':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${WIDTH}x${HEIGHT}:fps=${FPS}"
            ;;
    esac

    local vf="scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},${zoompan}"

    ffmpeg -y -loop 1 -i "$image" \
        -vf "$vf" \
        -t "$dur" \
        -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
        -movflags +faststart \
        "$out" 2>/dev/null || return 1
}

###############################################################################
# Process all scenes
###############################################################################

log "=== reel-generator ==="
log "Blueprint: $BLUEPRINT"
log "Style:     $STYLE"
log "Scenes:    $SCENE_COUNT"
log "Output:    $OUTPUT"
log "Dry-run:   $DRY_RUN"

SCENE_VIDEOS=""
FAILED_SCENES=""
scene_idx=0
while [ "$scene_idx" -lt "$SCENE_COUNT" ]; do
    log "--- Scene $scene_idx ---"

    # Generate image
    if generate_scene_image "$scene_idx"; then
        # Convert to video
        if convert_scene_to_video "$scene_idx"; then
            local_video="$WORK_DIR/scene_$(printf '%02d' "$scene_idx")_video.mp4"
            if [ -n "$SCENE_VIDEOS" ]; then
                SCENE_VIDEOS="$SCENE_VIDEOS|$local_video"
            else
                SCENE_VIDEOS="$local_video"
            fi
        else
            FAILED_SCENES="$FAILED_SCENES $scene_idx"
        fi
    else
        FAILED_SCENES="$FAILED_SCENES $scene_idx"
    fi

    scene_idx=$((scene_idx + 1))
done

if [ -z "$SCENE_VIDEOS" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
        log "Dry-run complete. No videos generated."
        echo ""
        echo "=== DRY RUN COMPLETE ==="
        echo "Blueprint: $BLUEPRINT"
        echo "Scenes:    $SCENE_COUNT"
        echo "Style:     $STYLE"
        echo "Output would be: $OUTPUT"
        exit 0
    fi
    err "No scene videos were generated. Cannot assemble reel."
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "=== DRY RUN COMPLETE ==="
    echo "Blueprint:   $BLUEPRINT"
    echo "Scenes:      $SCENE_COUNT"
    echo "Style:       $STYLE"
    echo "Output:      $OUTPUT"
    echo "Failed:      ${FAILED_SCENES:-none}"
    echo ""
    echo "Would assemble scenes, apply post-production, add music."
    exit 0
fi

###############################################################################
# Step 3: Assemble all scene videos with cross-dissolve transitions
###############################################################################

log "Assembling $SCENE_COUNT scene videos..."

ASSEMBLED="$WORK_DIR/assembled.mp4"

# Build ffmpeg concat file list
CONCAT_LIST="$WORK_DIR/concat_list.txt"
: > "$CONCAT_LIST"

# Write each video to the concat list
OLD_IFS="$IFS"
IFS="|"
for vid in $SCENE_VIDEOS; do
    echo "file '$vid'" >> "$CONCAT_LIST"
done
IFS="$OLD_IFS"

# Count videos for transition decision
VIDEO_COUNT="$(echo "$SCENE_VIDEOS" | tr '|' '\n' | wc -l | tr -d ' ')"

if [ "$VIDEO_COUNT" -eq 1 ]; then
    # Single scene — just copy
    cp "$(echo "$SCENE_VIDEOS" | tr '|' '\n' | head -1)" "$ASSEMBLED"
elif [ "$VIDEO_COUNT" -gt 1 ]; then
    # Try cross-dissolve via xfade filter chain
    # For Bash 3.2 compat, build filter with python3
    python3 << 'PYEOF' "$SCENE_VIDEOS" "$ASSEMBLED" "$SCENE_DURATION" "$WORK_DIR"
import subprocess, sys, os

videos_str = sys.argv[1]
assembled = sys.argv[2]
scene_dur = int(sys.argv[3])
work_dir = sys.argv[4]

videos = videos_str.split('|')
n = len(videos)

if n < 2:
    # Just copy the single file
    import shutil
    shutil.copy2(videos[0], assembled)
    sys.exit(0)

# For 2+ videos, use xfade with 0.5s cross-dissolve transitions
xfade_dur = 0.5

# Build ffmpeg command with xfade filter chain
inputs = []
for v in videos:
    inputs.extend(['-i', v])

# Build xfade chain: [0][1]xfade -> [v01]; [v01][2]xfade -> [v012]; ...
filters = []
prev_label = '0:v'
for i in range(1, n):
    out_label = 'v%d' % i
    offset = (scene_dur * i) - (xfade_dur * i)
    if offset < 0:
        offset = 0.5 * i
    filt = '[%s][%d:v]xfade=transition=fade:duration=%.1f:offset=%.1f[%s]' % (
        prev_label, i, xfade_dur, offset, out_label
    )
    filters.append(filt)
    prev_label = out_label

filter_complex = ';'.join(filters)
cmd = ['ffmpeg', '-y'] + inputs + [
    '-filter_complex', filter_complex,
    '-map', '[%s]' % prev_label,
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart',
    assembled
]

try:
    subprocess.run(cmd, check=True, capture_output=True, timeout=300)
except Exception as e:
    # Fallback: simple concat (no transitions)
    print("xfade failed (%s), falling back to concat" % str(e), file=sys.stderr)
    concat_file = os.path.join(work_dir, 'concat_list.txt')
    cmd2 = ['ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', concat_file,
            '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
            assembled]
    subprocess.run(cmd2, check=True, capture_output=True, timeout=300)
PYEOF

    if [ $? -ne 0 ]; then
        # Final fallback: raw concat
        log "Python xfade assembly failed, trying raw concat..."
        ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" \
            -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
            "$ASSEMBLED" 2>/dev/null || {
            err "Failed to assemble scene videos"
            exit 1
        }
    fi
fi

if [ ! -f "$ASSEMBLED" ]; then
    err "Assembled video was not created"
    exit 1
fi

log "Assembly complete: $ASSEMBLED"

###############################################################################
# Step 4: Post-production
###############################################################################

POST_PROD="$WORK_DIR/postprod.mp4"

if [ -f "$VIDEO_FORGE" ]; then
    log "Applying post-production via video-forge.sh..."
    bash "$VIDEO_FORGE" produce "$ASSEMBLED" --type aroll --brand jade-oracle --mood cozy 2>&1 || {
        log "video-forge.sh failed, applying fallback post-production"
        _apply_fallback_postprod=1
    }

    # video-forge writes output near the input — check for it
    local_forge_out="$(dirname "$ASSEMBLED")/output/$(basename "$ASSEMBLED" .mp4)-produced.mp4"
    if [ -f "$local_forge_out" ]; then
        cp "$local_forge_out" "$POST_PROD"
    else
        # Check if forge wrote in-place
        _apply_fallback_postprod=1
    fi
fi

# Fallback post-production: warm grade + grain + vignette via ffmpeg
if [ ! -f "$POST_PROD" ]; then
    log "Applying fallback post-production (warm grade, grain, vignette)..."
    ffmpeg -y -i "$ASSEMBLED" \
        -vf "colorbalance=rs=0.05:gs=0.02:bs=-0.03:rm=0.04:gm=0.01:bm=-0.02,vignette=PI/5,noise=alls=3:allf=t+u" \
        -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
        -c:a copy \
        -movflags +faststart \
        "$POST_PROD" 2>/dev/null || {
        log "Fallback post-production failed, using assembled video as-is"
        cp "$ASSEMBLED" "$POST_PROD"
    }
fi

log "Post-production complete: $POST_PROD"

###############################################################################
# Step 5: Add music
###############################################################################

# Helper: add silent audio track (defined before use for Bash 3.2 compat)
add_silent_track() {
    local input="$1"
    local output="$2"
    local dur="$3"
    ffmpeg -y -i "$input" -f lavfi -i anullsrc=r=44100:cl=stereo \
        -map 0:v -map 1:a \
        -c:v copy -c:a aac -b:a 128k \
        -t "$dur" -shortest \
        -movflags +faststart \
        "$output" 2>/dev/null || {
        # Last resort: just copy without audio
        cp "$input" "$output"
    }
}

FINAL_WITH_MUSIC="$WORK_DIR/final.mp4"

# Find a music track
MUSIC_TRACK=""
if [ -d "$LOFI_DIR" ]; then
    MUSIC_TRACK="$(find "$LOFI_DIR" -maxdepth 1 \( -name '*.mp3' -o -name '*.wav' -o -name '*.aac' \) -type f 2>/dev/null | head -1)"
fi

# Get video duration for fade calculation
VIDEO_DURATION="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$POST_PROD" 2>/dev/null | cut -d. -f1)"
if [ -z "$VIDEO_DURATION" ] || ! echo "$VIDEO_DURATION" | grep -qE '^[0-9]+$'; then
    VIDEO_DURATION=$((SCENE_COUNT * SCENE_DURATION))
fi
FADE_START=$((VIDEO_DURATION - 2))
if [ "$FADE_START" -lt 0 ]; then
    FADE_START=0
fi

if [ -n "$MUSIC_TRACK" ] && [ -f "$MUSIC_TRACK" ]; then
    log "Adding music: $MUSIC_TRACK (30% volume, ${FADE_START}s fade out)"
    ffmpeg -y -i "$POST_PROD" -i "$MUSIC_TRACK" \
        -filter_complex "[1:a]volume=0.3,afade=t=out:st=${FADE_START}:d=2[music];[0:a][music]amix=inputs=2:duration=shortest[aout]" \
        -map 0:v -map "[aout]" \
        -c:v copy -c:a aac -b:a 128k \
        -shortest \
        -movflags +faststart \
        "$FINAL_WITH_MUSIC" 2>/dev/null || {
        # If video has no audio stream, try without amix
        log "amix failed (video may lack audio), mixing music only..."
        ffmpeg -y -i "$POST_PROD" -i "$MUSIC_TRACK" \
            -filter_complex "[1:a]volume=0.3,afade=t=out:st=${FADE_START}:d=2[aout]" \
            -map 0:v -map "[aout]" \
            -c:v copy -c:a aac -b:a 128k \
            -t "$VIDEO_DURATION" \
            -movflags +faststart \
            "$FINAL_WITH_MUSIC" 2>/dev/null || {
            log "Music mixing failed, adding silent track"
            add_silent_track "$POST_PROD" "$FINAL_WITH_MUSIC" "$VIDEO_DURATION"
        }
    }
else
    log "No music found in $LOFI_DIR, creating silent audio track"
    add_silent_track "$POST_PROD" "$FINAL_WITH_MUSIC" "$VIDEO_DURATION"
fi

# Safety check: ensure final music file exists
if [ ! -f "$FINAL_WITH_MUSIC" ]; then
    log "Final music file missing, creating silent fallback..."
    add_silent_track "$POST_PROD" "$FINAL_WITH_MUSIC" "$VIDEO_DURATION"
fi

log "Music mixing complete: $FINAL_WITH_MUSIC"

###############################################################################
# Step 6: Final export — 1080x1920, H.264, AAC, max 15MB
###############################################################################

log "Exporting final reel..."

# Ensure correct resolution and codec
ffmpeg -y -i "$FINAL_WITH_MUSIC" \
    -vf "scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease,pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2" \
    -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
    -c:a aac -b:a 128k \
    -movflags +faststart \
    "$OUTPUT" 2>/dev/null || {
    err "Final export failed"
    exit 1
}

###############################################################################
# Verify file size — re-encode if over 15MB
###############################################################################

if [ ! -f "$OUTPUT" ]; then
    err "Output file was not created: $OUTPUT"
    exit 1
fi

FILE_SIZE="$(wc -c < "$OUTPUT" | tr -d ' ')"

if [ "$FILE_SIZE" -gt "$MAX_SIZE_BYTES" ]; then
    log "WARNING: Output is ${FILE_SIZE} bytes ($(( FILE_SIZE / 1048576 ))MB) — exceeds 15MB limit"
    log "Re-encoding with higher CRF to reduce size..."

    REENCODED="$WORK_DIR/reencoded.mp4"
    ffmpeg -y -i "$OUTPUT" \
        -c:v libx264 -preset medium -crf 28 -pix_fmt yuv420p \
        -c:a aac -b:a 96k \
        -movflags +faststart \
        "$REENCODED" 2>/dev/null

    if [ -f "$REENCODED" ]; then
        REENC_SIZE="$(wc -c < "$REENCODED" | tr -d ' ')"
        if [ "$REENC_SIZE" -lt "$MAX_SIZE_BYTES" ]; then
            mv "$REENCODED" "$OUTPUT"
            FILE_SIZE="$REENC_SIZE"
            log "Re-encoded to ${FILE_SIZE} bytes ($(( FILE_SIZE / 1048576 ))MB)"
        else
            log "WARNING: Still over 15MB after re-encode (${REENC_SIZE} bytes). Consider fewer scenes."
        fi
    fi
fi

###############################################################################
# Done
###############################################################################

log "Reel complete: $OUTPUT ($(( FILE_SIZE / 1024 ))KB)"

if [ -n "$FAILED_SCENES" ]; then
    log "WARNING: Failed scenes:$FAILED_SCENES"
fi

echo ""
echo "=== REEL GENERATED ==="
echo "Output:  $OUTPUT"
echo "Size:    $(( FILE_SIZE / 1024 ))KB"
echo "Format:  ${WIDTH}x${HEIGHT} @ ${FPS}fps, H.264 + AAC"
echo "Style:   $STYLE"
echo "Scenes:  $SCENE_COUNT (failed:${FAILED_SCENES:- none})"
