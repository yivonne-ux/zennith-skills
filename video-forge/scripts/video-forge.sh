#!/usr/bin/env bash
# video-forge.sh — Automated video post-production pipeline for GAIA CORP-OS
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash video-forge.sh caption <input.mp4> [options]
#   bash video-forge.sh brand <input.mp4> [options]
#   bash video-forge.sh music <input.mp4> [options]
#   bash video-forge.sh effects <input.mp4> [options]
#   bash video-forge.sh assemble <clip1> <clip2> ... [options]
#   bash video-forge.sh export <input.mp4> [options]
#   bash video-forge.sh produce <input.mp4> --type <type> --brand <brand> [options]

set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/video-forge.log"
BRANDS_DIR="$HOME/.openclaw/brands"
OUTPUT_TYPES_FILE="$HOME/.openclaw/workspace/data/output-types.json"
AUDIT_SCRIPT="$HOME/.openclaw/skills/art-director/scripts/audit-visual.sh"

mkdir -p "$(dirname "$LOG_FILE")"

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [video-forge] $1"
  echo "$msg" >> "$LOG_FILE"
}

info() {
  echo "[VideoForge] $1" >&2
  log "$1"
}

error() {
  echo "[VideoForge] ERROR: $1" >&2
  log "ERROR: $1"
}

# --- Dependency checks ---
check_ffmpeg() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    error "ffmpeg is required. Run: bash $SCRIPT_DIR/install-deps.sh"
    exit 1
  fi
}

check_whisper() {
  if command -v faster-whisper >/dev/null 2>&1; then
    echo "faster-whisper"
  elif command -v whisper >/dev/null 2>&1; then
    echo "whisper"
  elif python3 -c "import faster_whisper" 2>/dev/null; then
    echo "faster-whisper-python"
  elif python3 -c "import whisper" 2>/dev/null; then
    echo "whisper-python"
  else
    error "whisper or faster-whisper required for captions. Run: bash $SCRIPT_DIR/install-deps.sh"
    exit 1
  fi
}

# --- Utility: lowercase (bash 3.2 compatible) ---
to_lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# --- Utility: resolve output dir ---
resolve_output_dir() {
  local input_file="$1"
  local custom_output="${2:-}"
  if [ -n "$custom_output" ]; then
    mkdir -p "$custom_output"
    echo "$custom_output"
  else
    local dir
    dir="$(cd "$(dirname "$input_file")" && pwd)/output"
    mkdir -p "$dir"
    echo "$dir"
  fi
}

# --- Utility: get filename without extension ---
basename_no_ext() {
  local name
  name="$(basename "$1")"
  echo "${name%.*}"
}

# --- Utility: read JSON field with python3 ---
json_field() {
  local file="$1"
  local field="$2"
  python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    keys = sys.argv[2].split('.')
    val = data
    for k in keys:
        if isinstance(val, dict):
            val = val.get(k, '')
        else:
            val = ''
            break
    if isinstance(val, dict) or isinstance(val, list):
        print(json.dumps(val))
    else:
        print(val if val else '')
except Exception as e:
    print('')
" "$file" "$field"
}

# --- Utility: get video duration ---
get_duration() {
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null || echo "0"
}

# --- Utility: check if video has audio ---
has_audio() {
  local count
  count=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$1" 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -gt 0 ]
}

# ============================================================================
# SUBCOMMAND: caption
# ============================================================================
cmd_caption() {
  local input=""
  local style="tiktok"
  local lang="auto"
  local word_level=0
  local output_dir_override=""

  # Parse args
  while [ $# -gt 0 ]; do
    case "$1" in
      --style) style="$2"; shift 2 ;;
      --lang) lang="$2"; shift 2 ;;
      --word-level) word_level=1; shift ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*)
        error "Unknown option for caption: $1"
        exit 1 ;;
      *)
        if [ -z "$input" ]; then
          input="$1"
        fi
        shift ;;
    esac
  done

  if [ -z "$input" ] || [ ! -f "$input" ]; then
    error "Input file required and must exist: $input"
    exit 1
  fi

  check_ffmpeg

  # tiktok style implies word-level by default
  if [ "$style" = "tiktok" ]; then
    word_level=1
  fi

  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local outdir
  outdir=$(resolve_output_dir "$abs_input" "$output_dir_override")
  local base
  base=$(basename_no_ext "$abs_input")
  local srt_file="${outdir}/${base}.srt"
  local ass_file="${outdir}/${base}.ass"
  local captioned_file="${outdir}/${base}_captioned.mp4"

  info "Generating captions for: $(basename "$abs_input") [style=$style, lang=$lang]"

  # Step 1: Generate SRT via whisper
  local whisper_type
  whisper_type=$(check_whisper)

  info "Using $whisper_type for transcription..."

  local whisper_lang_arg=""
  if [ "$lang" != "auto" ]; then
    whisper_lang_arg="$lang"
  fi

  python3 - "$abs_input" "$srt_file" "$whisper_lang_arg" "$word_level" <<'PYEOF'
import sys, os, json

input_file = sys.argv[1]
srt_output = sys.argv[2]
lang = sys.argv[3] if sys.argv[3] else None
word_level = sys.argv[4] == "1"

def format_ts(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds % 1) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

segments = []

try:
    from faster_whisper import WhisperModel
    model = WhisperModel("base", device="cpu", compute_type="int8")
    kwargs = {"beam_size": 5, "word_timestamps": word_level}
    if lang:
        kwargs["language"] = lang
    segs, info_obj = model.transcribe(input_file, **kwargs)
    for seg in segs:
        entry = {"start": seg.start, "end": seg.end, "text": seg.text.strip()}
        if word_level and hasattr(seg, 'words') and seg.words:
            entry["words"] = [{"word": w.word.strip(), "start": w.start, "end": w.end} for w in seg.words]
        segments.append(entry)
except ImportError:
    try:
        import whisper
        model = whisper.load_model("base")
        kwargs = {"fp16": False, "word_timestamps": word_level}
        if lang:
            kwargs["language"] = lang
        result = model.transcribe(input_file, **kwargs)
        for seg in result.get("segments", []):
            entry = {"start": seg["start"], "end": seg["end"], "text": seg["text"].strip()}
            if word_level and "words" in seg:
                entry["words"] = [{"word": w["word"].strip(), "start": w["start"], "end": w["end"]} for w in seg["words"]]
            segments.append(entry)
    except ImportError:
        print("ERROR: No whisper library found", file=sys.stderr)
        sys.exit(1)

# Write SRT
with open(srt_output, 'w') as f:
    for i, seg in enumerate(segments, 1):
        f.write(f"{i}\n")
        f.write(f"{format_ts(seg['start'])} --> {format_ts(seg['end'])}\n")
        f.write(f"{seg['text']}\n\n")

# Write segments JSON for ASS generation
json_path = srt_output.replace('.srt', '_segments.json')
with open(json_path, 'w') as f:
    json.dump(segments, f)

print(f"SRT written: {srt_output}", file=sys.stderr)
print(f"Segments: {len(segments)}", file=sys.stderr)
PYEOF

  if [ ! -f "$srt_file" ]; then
    error "SRT generation failed"
    exit 1
  fi

  # Step 2: Generate ASS with styling
  local segments_json="${outdir}/${base}_segments.json"

  python3 - "$segments_json" "$ass_file" "$style" <<'PYEOF'
import sys, json

segments_file = sys.argv[1]
ass_output = sys.argv[2]
style = sys.argv[3]

with open(segments_file) as f:
    segments = json.load(f)

def ts_ass(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    cs = int((seconds % 1) * 100)
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"

# Style definitions
styles = {
    "tiktok": {
        "fontname": "Arial",
        "fontsize": "22",
        "primary": "&H00FFFFFF",   # white
        "highlight": "&H0000FFFF", # yellow (BGR)
        "outline": "&H00000000",
        "back": "&H80000000",
        "bold": "1",
        "outline_w": "2",
        "shadow": "0",
        "alignment": "5",  # center
        "marginv": "180"
    },
    "clean": {
        "fontname": "Arial",
        "fontsize": "18",
        "primary": "&H00FFFFFF",
        "highlight": "&H00FFFFFF",
        "outline": "&H00000000",
        "back": "&H80000000",
        "bold": "0",
        "outline_w": "2",
        "shadow": "1",
        "alignment": "2",  # bottom center
        "marginv": "40"
    },
    "bold": {
        "fontname": "Impact",
        "fontsize": "32",
        "primary": "&H00FFFFFF",
        "highlight": "&H0000FFFF",
        "outline": "&H00000000",
        "back": "&H00000000",
        "bold": "1",
        "outline_w": "3",
        "shadow": "2",
        "alignment": "5",
        "marginv": "100"
    },
    "minimal": {
        "fontname": "Helvetica",
        "fontsize": "14",
        "primary": "&H80FFFFFF",
        "highlight": "&H80FFFFFF",
        "outline": "&H00000000",
        "back": "&H00000000",
        "bold": "0",
        "outline_w": "1",
        "shadow": "0",
        "alignment": "1",  # bottom left
        "marginv": "30"
    }
}

s = styles.get(style, styles["clean"])

header = f"""[Script Info]
Title: VideoForge Captions
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,{s['fontname']},{s['fontsize']},{s['primary']},{s['highlight']},{s['outline']},{s['back']},{s['bold']},0,0,0,100,100,0,0,1,{s['outline_w']},{s['shadow']},{s['alignment']},20,20,{s['marginv']},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

events = []

if style == "tiktok":
    # Word-by-word highlight: show all words, highlight active one
    for seg in segments:
        words = seg.get("words", [])
        if not words:
            # Fallback: show whole segment
            start = ts_ass(seg["start"])
            end = ts_ass(seg["end"])
            text = seg["text"].replace("\n", "\\N")
            events.append(f"Dialogue: 0,{start},{end},Default,,0,0,0,,{text}")
            continue
        for wi, w in enumerate(words):
            start = ts_ass(w["start"])
            end = ts_ass(w["end"])
            # Build line with current word highlighted in yellow
            parts = []
            for wj, w2 in enumerate(words):
                word_text = w2["word"]
                if wj == wi:
                    # Yellow highlight (ASS color override)
                    parts.append("{\\c&H00FFFF&\\b1}" + word_text + "{\\c&HFFFFFF&\\b" + s["bold"] + "}")
                else:
                    parts.append(word_text)
            line = " ".join(parts)
            events.append(f"Dialogue: 0,{start},{end},Default,,0,0,0,,{line}")
else:
    for seg in segments:
        start = ts_ass(seg["start"])
        end = ts_ass(seg["end"])
        text = seg["text"].replace("\n", "\\N")
        events.append(f"Dialogue: 0,{start},{end},Default,,0,0,0,,{text}")

with open(ass_output, 'w') as f:
    f.write(header)
    f.write("\n".join(events))
    f.write("\n")

print(f"ASS written: {ass_output} ({len(events)} events)", file=sys.stderr)
PYEOF

  # Step 3: Burn captions into video
  info "Burning captions into video..."
  ffmpeg -i "$abs_input" \
    -vf "ass=${ass_file}" \
    -c:v h264_videotoolbox -b:v 8M \
    -c:a aac -b:a 192k \
    -y "$captioned_file" \
    -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done

  # Clean up temp segments JSON
  rm -f "${outdir}/${base}_segments.json"

  info "Captions complete: $captioned_file"
  echo "$captioned_file"
}

# ============================================================================
# SUBCOMMAND: brand
# ============================================================================
cmd_brand() {
  local input=""
  local brand=""
  local logo=""
  local position="br"
  local opacity="0.3"
  local lower_third=0
  local output_dir_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      --logo) logo="$2"; shift 2 ;;
      --position) position="$2"; shift 2 ;;
      --opacity) opacity="$2"; shift 2 ;;
      --lower-third) lower_third=1; shift ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*) error "Unknown option for brand: $1"; exit 1 ;;
      *)
        if [ -z "$input" ]; then input="$1"; fi
        shift ;;
    esac
  done

  if [ -z "$input" ] || [ ! -f "$input" ]; then
    error "Input file required and must exist: $input"
    exit 1
  fi
  check_ffmpeg

  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local outdir
  outdir=$(resolve_output_dir "$abs_input" "$output_dir_override")
  local base
  base=$(basename_no_ext "$abs_input")
  local branded_file="${outdir}/${base}_branded.mp4"

  # Resolve brand DNA
  local dna_file=""
  local brand_name=""
  local primary_color="#8FBC8F"
  if [ -n "$brand" ]; then
    dna_file="${BRANDS_DIR}/${brand}/DNA.json"
    if [ -f "$dna_file" ]; then
      brand_name=$(json_field "$dna_file" "display_name")
      primary_color=$(json_field "$dna_file" "visual.colors.primary")
      info "Loaded brand DNA: $brand_name ($brand)"
    else
      info "Brand DNA not found at $dna_file, using defaults"
    fi
  fi

  # Resolve logo
  if [ -z "$logo" ] && [ -n "$brand" ]; then
    logo="${BRANDS_DIR}/${brand}/logo.png"
  fi

  local filters=""
  local inputs_extra=""
  local input_count=1

  # Logo overlay
  if [ -n "$logo" ] && [ -f "$logo" ]; then
    inputs_extra="$inputs_extra -i $logo"
    input_count=$((input_count + 1))
    local logo_idx=$((input_count - 1))

    # Scale logo to 80px height max, position based on --position
    local pos_x=""
    local pos_y=""
    case "$position" in
      tl) pos_x="20"; pos_y="20" ;;
      tr) pos_x="W-w-20"; pos_y="20" ;;
      bl) pos_x="20"; pos_y="H-h-20" ;;
      br) pos_x="W-w-20"; pos_y="H-h-20" ;;
      *) pos_x="W-w-20"; pos_y="H-h-20" ;;
    esac

    if [ -z "$filters" ]; then
      filters="[${logo_idx}:v]scale=-1:80,format=rgba,colorchannelmixer=aa=${opacity}[logo];[0:v][logo]overlay=${pos_x}:${pos_y}"
    else
      filters="${filters};[${logo_idx}:v]scale=-1:80,format=rgba,colorchannelmixer=aa=${opacity}[logo];[vid][logo]overlay=${pos_x}:${pos_y}"
    fi
    info "Adding logo overlay at $position (opacity $opacity)"
  else
    # Watermark: brand text as subtle overlay
    if [ -n "$brand_name" ]; then
      local watermark_text="$brand_name"
      if [ -z "$filters" ]; then
        filters="[0:v]drawtext=text='${watermark_text}':fontsize=24:fontcolor=white@0.15:x=W-tw-20:y=H-th-20"
      fi
      info "Adding text watermark: $watermark_text"
    fi
  fi

  # Lower-third bar
  if [ "$lower_third" -eq 1 ] && [ -n "$brand_name" ]; then
    local hex_no_hash
    hex_no_hash=$(echo "$primary_color" | tr -d '#')
    local lt_filter="drawbox=y=ih*0.82:w=iw:h=ih*0.08:color=0x${hex_no_hash}@0.8:t=fill,drawtext=text='${brand_name}':fontsize=28:fontcolor=white:x=(w-tw)/2:y=h*0.82+(h*0.08-th)/2"
    if [ -z "$filters" ]; then
      filters="[0:v]${lt_filter}"
    else
      filters="${filters},${lt_filter}"
    fi
    info "Adding lower-third bar for $brand_name"
  fi

  # Build ffmpeg command
  if [ -z "$filters" ]; then
    # No brand operations, just copy
    info "No brand operations specified, copying input"
    cp "$abs_input" "$branded_file"
  else
    # Wrap filter if it starts with [0:v]
    local filter_arg="$filters"
    ffmpeg -i "$abs_input" $inputs_extra \
      -filter_complex "${filter_arg}" \
      -c:v h264_videotoolbox -b:v 8M \
      -c:a copy \
      -y "$branded_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
  fi

  info "Brand overlay complete: $branded_file"
  echo "$branded_file"
}

# ============================================================================
# SUBCOMMAND: music
# ============================================================================
cmd_music() {
  local input=""
  local track=""
  local volume="0.2"
  local duck=0
  local fade_in="0"
  local fade_out="0"
  local output_dir_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --track) track="$2"; shift 2 ;;
      --volume) volume="$2"; shift 2 ;;
      --duck) duck=1; shift ;;
      --fade-in) fade_in="$2"; shift 2 ;;
      --fade-out) fade_out="$2"; shift 2 ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*) error "Unknown option for music: $1"; exit 1 ;;
      *)
        if [ -z "$input" ]; then input="$1"; fi
        shift ;;
    esac
  done

  if [ -z "$input" ] || [ ! -f "$input" ]; then
    error "Input file required and must exist: $input"
    exit 1
  fi
  if [ -z "$track" ] || [ ! -f "$track" ]; then
    error "Music track required (--track): $track"
    exit 1
  fi
  check_ffmpeg

  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local outdir
  outdir=$(resolve_output_dir "$abs_input" "$output_dir_override")
  local base
  base=$(basename_no_ext "$abs_input")
  local mixed_file="${outdir}/${base}_music.mp4"

  local duration
  duration=$(get_duration "$abs_input")

  info "Mixing music into video [volume=$volume, duck=$duck, fade_in=$fade_in, fade_out=$fade_out]"

  # Build audio filter chain for the music track
  local music_filters="volume=${volume}"

  # Fade in
  if [ "$fade_in" != "0" ]; then
    music_filters="${music_filters},afade=t=in:st=0:d=${fade_in}"
  fi

  # Fade out
  if [ "$fade_out" != "0" ]; then
    local fade_start
    fade_start=$(python3 -c "print(max(0, float('$duration') - float('$fade_out')))")
    music_filters="${music_filters},afade=t=out:st=${fade_start}:d=${fade_out}"
  fi

  # Trim music to video duration
  music_filters="${music_filters},atrim=0:${duration}"

  if [ "$duck" -eq 1 ] && has_audio "$abs_input"; then
    # Auto-ducking: sidechaincompress music when speech is detected
    info "Applying auto-ducking (sidechain compression)..."
    ffmpeg -i "$abs_input" -i "$track" \
      -filter_complex \
      "[1:a]${music_filters}[music];[0:a]aformat=fltp:44100:stereo[speech];[music][speech]sidechaincompress=threshold=0.015:ratio=6:attack=200:release=1000[ducked];[speech][ducked]amix=inputs=2:duration=first:dropout_transition=2[aout]" \
      -map 0:v -map "[aout]" \
      -c:v copy \
      -c:a aac -b:a 192k \
      -y "$mixed_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
  elif has_audio "$abs_input"; then
    # Simple mix: original audio + music
    ffmpeg -i "$abs_input" -i "$track" \
      -filter_complex \
      "[1:a]${music_filters}[music];[0:a][music]amix=inputs=2:duration=first:dropout_transition=2[aout]" \
      -map 0:v -map "[aout]" \
      -c:v copy \
      -c:a aac -b:a 192k \
      -y "$mixed_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
  else
    # No original audio, just add music
    ffmpeg -i "$abs_input" -i "$track" \
      -filter_complex \
      "[1:a]${music_filters}[music]" \
      -map 0:v -map "[music]" \
      -c:v copy \
      -c:a aac -b:a 192k \
      -shortest \
      -y "$mixed_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
  fi

  info "Music mix complete: $mixed_file"
  echo "$mixed_file"
}

# ============================================================================
# SUBCOMMAND: effects
# ============================================================================
cmd_effects() {
  local input=""
  local grain=""
  local vignette=0
  local lut=""
  local grade=""
  local zoom_cuts=0
  local shaky=""
  local speed=""
  local output_dir_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --grain) grain="$2"; shift 2 ;;
      --vignette) vignette=1; shift ;;
      --lut) lut="$2"; shift 2 ;;
      --grade) grade="$2"; shift 2 ;;
      --zoom-cuts) zoom_cuts=1; shift ;;
      --shaky) shaky="$2"; shift 2 ;;
      --speed) speed="$2"; shift 2 ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*) error "Unknown option for effects: $1"; exit 1 ;;
      *)
        if [ -z "$input" ]; then input="$1"; fi
        shift ;;
    esac
  done

  if [ -z "$input" ] || [ ! -f "$input" ]; then
    error "Input file required and must exist: $input"
    exit 1
  fi
  check_ffmpeg

  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local outdir
  outdir=$(resolve_output_dir "$abs_input" "$output_dir_override")
  local base
  base=$(basename_no_ext "$abs_input")
  local effects_file="${outdir}/${base}_effects.mp4"

  local vfilters=""

  # Speed ramp (applied first since it changes timing)
  local atempo_filter=""
  if [ -n "$speed" ]; then
    vfilters="setpts=$(python3 -c "print(1.0/float('$speed'))")*PTS"
    # Audio tempo adjustment — atempo only accepts 0.5-2.0
    local speed_val="$speed"
    atempo_filter=$(python3 -c "
s = float('$speed_val')
filters = []
while s > 2.0:
    filters.append('atempo=2.0')
    s /= 2.0
while s < 0.5:
    filters.append('atempo=0.5')
    s *= 2.0
filters.append(f'atempo={s}')
print(','.join(filters))
")
    info "Speed: ${speed}x"
  fi

  # Color grade (inline FFmpeg presets)
  if [ -n "$lut" ] && [ -f "$lut" ]; then
    local lut_filter="lut3d=${lut}"
    vfilters="${vfilters:+$vfilters,}${lut_filter}"
    info "Applying LUT: $lut"
  elif [ -n "$grade" ]; then
    local grade_filter=""
    case "$(to_lower "$grade")" in
      warm)
        grade_filter="eq=saturation=1.1:contrast=1.05,colorbalance=rs=0.05:gs=-0.02:bs=-0.05" ;;
      cool)
        grade_filter="eq=saturation=0.9,colorbalance=rs=-0.05:gs=0.02:bs=0.08" ;;
      cinematic)
        grade_filter="eq=contrast=1.15:saturation=0.85,colorbalance=rs=0.03:gs=-0.01:bs=-0.04" ;;
      vintage)
        grade_filter="eq=saturation=0.7:contrast=1.1,colorbalance=rs=0.08:gs=0.03:bs=-0.05" ;;
      *)
        info "Unknown grade '$grade', skipping" ;;
    esac
    if [ -n "$grade_filter" ]; then
      vfilters="${vfilters:+$vfilters,}${grade_filter}"
      info "Applying grade: $grade"
    fi
  fi

  # Film grain (FFmpeg noise filter)
  if [ -n "$grain" ]; then
    local grain_strength=""
    case "$(to_lower "$grain")" in
      light)  grain_strength="10" ;;
      medium) grain_strength="25" ;;
      heavy)  grain_strength="45" ;;
      *)      grain_strength="10" ;;
    esac
    vfilters="${vfilters:+$vfilters,}noise=alls=${grain_strength}:allf=t"
    info "Applying film grain: $grain (strength $grain_strength)"
  fi

  # Vignette
  if [ "$vignette" -eq 1 ]; then
    vfilters="${vfilters:+$vfilters,}vignette=PI/4"
    info "Applying vignette"
  fi

  # Zoom cuts (110% zoom every 3-4 seconds using zoompan or crop approach)
  if [ "$zoom_cuts" -eq 1 ]; then
    # Use expression-based crop for zoom effect: alternate between 100% and 110% every 3.5s
    vfilters="${vfilters:+$vfilters,}crop=w=iw/(1+0.1*between(mod(t\,7)\,0\,3.5)):h=ih/(1+0.1*between(mod(t\,7)\,0\,3.5)):x=(iw-out_w)/2:y=(ih-out_h)/2,scale=iw*max(1\,1+0.1*between(mod(t\,7)\,0\,3.5)):ih*max(1\,1+0.1*between(mod(t\,7)\,0\,3.5))"
    info "Applying zoom cuts"
  fi

  # Shaky cam (random offset via crop + pad)
  if [ -n "$shaky" ]; then
    local shake_px=""
    case "$(to_lower "$shaky")" in
      light)  shake_px="4" ;;
      medium) shake_px="10" ;;
      *)      shake_px="4" ;;
    esac
    # Pad first to create room for shake, then crop with random offset
    vfilters="${vfilters:+$vfilters,}pad=iw+${shake_px}*2:ih+${shake_px}*2:${shake_px}:${shake_px}:black,crop=iw-${shake_px}*2:ih-${shake_px}*2:${shake_px}+${shake_px}*random(1)*2-${shake_px}:${shake_px}+${shake_px}*random(2)*2-${shake_px}"
    info "Applying shaky cam: $shaky"
  fi

  if [ -z "$vfilters" ] && [ -z "$atempo_filter" ]; then
    info "No effects specified, copying input"
    cp "$abs_input" "$effects_file"
  else
    local audio_args=""
    if has_audio "$abs_input"; then
      if [ -n "$atempo_filter" ]; then
        audio_args="-af $atempo_filter -c:a aac -b:a 192k"
      else
        audio_args="-c:a copy"
      fi
    else
      audio_args="-an"
    fi

    if [ -n "$vfilters" ]; then
      eval ffmpeg -i "$abs_input" \
        -vf "'${vfilters}'" \
        -c:v h264_videotoolbox -b:v 8M \
        $audio_args \
        -y "$effects_file" \
        -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
    else
      # Only speed change, no video filters
      eval ffmpeg -i "$abs_input" \
        -vf "'setpts=$(python3 -c "print(1.0/float('$speed'))")*PTS'" \
        -c:v h264_videotoolbox -b:v 8M \
        $audio_args \
        -y "$effects_file" \
        -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
    fi
  fi

  info "Effects complete: $effects_file"
  echo "$effects_file"
}

# ============================================================================
# SUBCOMMAND: assemble
# ============================================================================
cmd_assemble() {
  local clips=""
  local clip_count=0
  local transition="fade"
  local trans_dur="0.5"
  local output_dir_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --transition) transition="$2"; shift 2 ;;
      --duration) trans_dur="$2"; shift 2 ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*)
        error "Unknown option for assemble: $1"; exit 1 ;;
      *)
        if [ -f "$1" ]; then
          if [ -n "$clips" ]; then
            clips="${clips}|${1}"
          else
            clips="$1"
          fi
          clip_count=$((clip_count + 1))
        else
          error "Clip file not found: $1"
          exit 1
        fi
        shift ;;
    esac
  done

  if [ "$clip_count" -lt 2 ]; then
    error "At least 2 clips required for assemble (got $clip_count)"
    exit 1
  fi
  check_ffmpeg

  # Use first clip to resolve output dir
  local first_clip
  first_clip=$(echo "$clips" | cut -d'|' -f1)
  local abs_first
  abs_first="$(cd "$(dirname "$first_clip")" && pwd)/$(basename "$first_clip")"
  local outdir
  outdir=$(resolve_output_dir "$abs_first" "$output_dir_override")
  local assembled_file="${outdir}/assembled_$(date +%s).mp4"

  info "Assembling $clip_count clips [transition=$transition, duration=$trans_dur]"

  if [ "$transition" = "none" ]; then
    # Simple concat
    local concat_file="${outdir}/_concat_list.txt"
    local OLD_IFS="$IFS"
    IFS="|"
    for c in $clips; do
      IFS="$OLD_IFS"
      local abs_c
      abs_c="$(cd "$(dirname "$c")" && pwd)/$(basename "$c")"
      echo "file '$abs_c'" >> "$concat_file"
      IFS="|"
    done
    IFS="$OLD_IFS"

    ffmpeg -f concat -safe 0 -i "$concat_file" \
      -c:v h264_videotoolbox -b:v 8M \
      -c:a aac -b:a 192k \
      -y "$assembled_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done

    rm -f "$concat_file"
  else
    # Transition-based concat using xfade filter
    # Build complex filter graph for sequential xfade
    local input_args=""
    local idx=0
    local OLD_IFS="$IFS"
    IFS="|"
    local clip_array=""
    for c in $clips; do
      IFS="$OLD_IFS"
      local abs_c
      abs_c="$(cd "$(dirname "$c")" && pwd)/$(basename "$c")"
      input_args="$input_args -i $abs_c"
      if [ -n "$clip_array" ]; then
        clip_array="${clip_array}|${abs_c}"
      else
        clip_array="$abs_c"
      fi
      idx=$((idx + 1))
      IFS="|"
    done
    IFS="$OLD_IFS"

    # Map transition name to xfade transition
    local xfade_type="$transition"
    case "$transition" in
      fade) xfade_type="fade" ;;
      wipeleft) xfade_type="wipeleft" ;;
      dissolve) xfade_type="dissolve" ;;
      *) xfade_type="fade" ;;
    esac

    # Build xfade chain: for N clips, we need N-1 xfade filters
    local filter_graph
    filter_graph=$(python3 -c "
import sys, subprocess

clips_str = sys.argv[1]
xfade_type = sys.argv[2]
trans_dur = float(sys.argv[3])

clips = clips_str.split('|')
n = len(clips)

# Get durations
durations = []
for c in clips:
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
             '-of', 'default=noprint_wrappers=1:nokey=1', c],
            capture_output=True, text=True
        )
        durations.append(float(result.stdout.strip()))
    except:
        durations.append(5.0)

if n == 2:
    offset = max(0, durations[0] - trans_dur)
    vf = f'[0:v][1:v]xfade=transition={xfade_type}:duration={trans_dur}:offset={offset}[vout]'
    af = f'[0:a][1:a]acrossfade=d={trans_dur}[aout]'
    print(f'{vf};{af}')
else:
    vf_parts = []
    af_parts = []
    cumulative = 0
    for i in range(n - 1):
        if i == 0:
            vin1 = '[0:v]'
            ain1 = '[0:a]'
        else:
            vin1 = f'[v{i}]'
            ain1 = f'[a{i}]'
        vin2 = f'[{i+1}:v]'
        ain2 = f'[{i+1}:a]'
        cumulative += durations[i] - trans_dur
        offset = max(0, cumulative)
        if i == n - 2:
            vout = '[vout]'
            aout = '[aout]'
        else:
            vout = f'[v{i+1}]'
            aout = f'[a{i+1}]'
        vf_parts.append(f'{vin1}{vin2}xfade=transition={xfade_type}:duration={trans_dur}:offset={offset}{vout}')
        af_parts.append(f'{ain1}{ain2}acrossfade=d={trans_dur}{aout}')
    print(';'.join(vf_parts + af_parts))
" "$clip_array" "$xfade_type" "$trans_dur")

    eval ffmpeg $input_args \
      -filter_complex "'${filter_graph}'" \
      -map "'[vout]'" -map "'[aout]'" \
      -c:v h264_videotoolbox -b:v 8M \
      -c:a aac -b:a 192k \
      -y "$assembled_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done
  fi

  info "Assembly complete: $assembled_file"
  echo "$assembled_file"
}

# ============================================================================
# SUBCOMMAND: export
# ============================================================================
cmd_export() {
  local input=""
  local platforms=""
  local all_platforms=0
  local output_dir_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --platforms) platforms="$2"; shift 2 ;;
      --all) all_platforms=1; shift ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*) error "Unknown option for export: $1"; exit 1 ;;
      *)
        if [ -z "$input" ]; then input="$1"; fi
        shift ;;
    esac
  done

  if [ -z "$input" ] || [ ! -f "$input" ]; then
    error "Input file required and must exist: $input"
    exit 1
  fi
  check_ffmpeg

  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local outdir
  outdir=$(resolve_output_dir "$abs_input" "$output_dir_override")
  local base
  base=$(basename_no_ext "$abs_input")

  if [ "$all_platforms" -eq 1 ]; then
    platforms="tiktok,reels,shorts,youtube,feed,shopee"
  fi

  if [ -z "$platforms" ]; then
    error "Specify --platforms or --all"
    exit 1
  fi

  info "Exporting for platforms: $platforms"

  local exported_files=""
  local OLD_IFS="$IFS"
  IFS=","
  for platform in $platforms; do
    IFS="$OLD_IFS"
    platform=$(to_lower "$platform")
    local out_file="${outdir}/${platform}_${base}.mp4"
    local width="" height="" vf_scale=""

    case "$platform" in
      tiktok)
        width=1080; height=1920
        # Safe zones: top 120px, bottom 270px, right 80px
        info "  tiktok: 1080x1920 (safe zones: top 120, bottom 270, right 80)"
        ;;
      reels)
        width=1080; height=1920
        info "  reels: 1080x1920 (safe zones: top 100, bottom 250)"
        ;;
      shorts)
        width=1080; height=1920
        info "  shorts: 1080x1920 (safe zones: bottom 200)"
        ;;
      youtube)
        width=1920; height=1080
        info "  youtube: 1920x1080 (no safe zones)"
        ;;
      feed)
        width=1080; height=1080
        info "  feed: 1080x1080 (square)"
        ;;
      shopee)
        width=1080; height=1080
        info "  shopee: 1080x1080 (safe zones: bottom 80)"
        ;;
      *)
        info "  Unknown platform '$platform', skipping"
        IFS=","
        continue
        ;;
    esac

    # Scale + pad to target resolution, maintaining aspect ratio
    vf_scale="scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:black"

    local audio_args="-c:a aac -b:a 192k"
    if ! has_audio "$abs_input"; then
      audio_args="-an"
    fi

    ffmpeg -i "$abs_input" \
      -vf "$vf_scale" \
      -c:v h264_videotoolbox -b:v 8M \
      $audio_args \
      -y "$out_file" \
      -loglevel warning 2>&1 | while IFS= read -r line; do log "ffmpeg: $line"; done

    if [ -n "$exported_files" ]; then
      exported_files="${exported_files} ${out_file}"
    else
      exported_files="$out_file"
    fi
    IFS=","
  done
  IFS="$OLD_IFS"

  info "Export complete: $exported_files"
  echo "$exported_files"
}

# ============================================================================
# SUBCOMMAND: produce (THE KEY ONE)
# ============================================================================
cmd_produce() {
  local input=""
  local output_type=""
  local brand=""
  local mood=""
  local music_track=""
  local do_audit=0
  local output_dir_override=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --type) output_type="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      --mood) mood="$2"; shift 2 ;;
      --music) music_track="$2"; shift 2 ;;
      --audit) do_audit=1; shift ;;
      --output) output_dir_override="$2"; shift 2 ;;
      -*) error "Unknown option for produce: $1"; exit 1 ;;
      *)
        if [ -z "$input" ]; then input="$1"; fi
        shift ;;
    esac
  done

  if [ -z "$input" ] || [ ! -f "$input" ]; then
    error "Input file required and must exist: $input"
    exit 1
  fi
  if [ -z "$output_type" ]; then
    error "--type is required (aroll|broll|promotion|ugc|lofi|hero|education|channel)"
    exit 1
  fi
  if [ -z "$brand" ]; then
    error "--brand is required (e.g., gaia-eats)"
    exit 1
  fi
  check_ffmpeg

  local abs_input
  abs_input="$(cd "$(dirname "$input")" && pwd)/$(basename "$input")"
  local outdir
  outdir=$(resolve_output_dir "$abs_input" "$output_dir_override")

  # Load brand DNA
  local dna_file="${BRANDS_DIR}/${brand}/DNA.json"
  if [ ! -f "$dna_file" ]; then
    info "WARNING: Brand DNA not found at $dna_file, using defaults"
  fi

  # Load mood preset if specified
  local mood_file=""
  local mood_grade=""
  local mood_music_mood=""
  if [ -n "$mood" ]; then
    mood_file="${BRANDS_DIR}/${brand}/moods/${mood}.json"
    if [ -f "$mood_file" ]; then
      info "Loaded mood preset: $mood"
      # Extract color_grade hint from mood style
      mood_grade=$(json_field "$mood_file" "style.color_grade")
      mood_music_mood=$(json_field "$mood_file" "music.mood")
    else
      info "WARNING: Mood file not found at $mood_file"
    fi
  fi

  # Resolve color grade from mood
  local grade_preset=""
  if [ -n "$mood_grade" ]; then
    # Map mood color_grade descriptions to our presets
    case "$(to_lower "$mood_grade")" in
      *warm*|*amber*|*golden*) grade_preset="warm" ;;
      *cool*|*blue*|*teal*)    grade_preset="cool" ;;
      *cinema*|*film*|*rich*)  grade_preset="cinematic" ;;
      *vintage*|*faded*|*retro*) grade_preset="vintage" ;;
      *) grade_preset="" ;;
    esac
  fi

  info "=== PRODUCE PIPELINE ==="
  info "Type: $output_type | Brand: $brand | Mood: ${mood:-none}"
  info "Input: $abs_input"
  info "Output dir: $outdir"

  # Current working file — chains update this
  local current="$abs_input"

  output_type=$(to_lower "$output_type")

  case "$output_type" in

    broll)
      # Chain: brand(watermark-only) -> effects(lut from mood) -> export(all)
      info "--- Pipeline: broll ---"
      current=$(cmd_brand "$current" --brand "$brand" --opacity 0.15 --output "$outdir")

      local effect_args="$current --output $outdir"
      if [ -n "$grade_preset" ]; then
        effect_args="$effect_args --grade $grade_preset"
      fi
      current=$(eval cmd_effects $effect_args)

      cmd_export "$current" --all --output "$outdir"
      ;;

    aroll)
      # Chain: caption(word-level, tiktok) -> brand(logo, lower-third) -> music(duck) -> export(all)
      info "--- Pipeline: aroll ---"
      current=$(cmd_caption "$current" --style tiktok --word-level --output "$outdir")
      current=$(cmd_brand "$current" --brand "$brand" --lower-third --opacity 0.7 --output "$outdir")

      if [ -n "$music_track" ] && [ -f "$music_track" ]; then
        current=$(cmd_music "$current" --track "$music_track" --volume 0.18 --duck --output "$outdir")
      fi

      cmd_export "$current" --all --output "$outdir"
      ;;

    promotion)
      # Chain: caption(bold) -> brand(logo) -> music(urgency) -> effects(zoom-cuts) -> export(all)
      info "--- Pipeline: promotion ---"
      current=$(cmd_caption "$current" --style bold --output "$outdir")
      current=$(cmd_brand "$current" --brand "$brand" --opacity 0.8 --output "$outdir")

      if [ -n "$music_track" ] && [ -f "$music_track" ]; then
        current=$(cmd_music "$current" --track "$music_track" --volume 0.25 --duck --output "$outdir")
      fi

      current=$(cmd_effects "$current" --zoom-cuts --output "$outdir")

      cmd_export "$current" --all --output "$outdir"
      ;;

    ugc)
      # Chain: effects(grain-light, shaky-light) -> caption(tiktok-native) -> export(9:16 only)
      info "--- Pipeline: ugc ---"
      current=$(cmd_effects "$current" --grain light --shaky light --output "$outdir")
      current=$(cmd_caption "$current" --style tiktok --word-level --output "$outdir")

      cmd_export "$current" --platforms tiktok,reels,shorts --output "$outdir"
      ;;

    lofi)
      # Chain: effects(grain-medium, vignette, warm-grade) -> music(lofi, volume 0.15) -> caption(clean, optional) -> brand(subtle-watermark) -> export(all)
      info "--- Pipeline: lofi ---"
      local lofi_grade="${grade_preset:-warm}"
      current=$(cmd_effects "$current" --grain medium --vignette --grade "$lofi_grade" --output "$outdir")

      if [ -n "$music_track" ] && [ -f "$music_track" ]; then
        current=$(cmd_music "$current" --track "$music_track" --volume 0.15 --fade-in 2 --fade-out 3 --output "$outdir")
      fi

      # Optional caption for lofi — only if speech detected
      if has_audio "$abs_input"; then
        local speech_check
        speech_check=$(ffprobe -v error -select_streams a -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$abs_input" 2>/dev/null || echo "0")
        if [ -n "$speech_check" ] && [ "$speech_check" != "0" ] && [ "$speech_check" != "N/A" ]; then
          current=$(cmd_caption "$current" --style clean --output "$outdir") || true
        fi
      fi

      current=$(cmd_brand "$current" --brand "$brand" --opacity 0.15 --output "$outdir")

      cmd_export "$current" --all --output "$outdir"
      ;;

    hero)
      # Chain: effects(cinematic-grade) -> brand(headline, premium) -> export(by-placement)
      info "--- Pipeline: hero ---"
      current=$(cmd_effects "$current" --grade cinematic --output "$outdir")
      current=$(cmd_brand "$current" --brand "$brand" --opacity 0.8 --lower-third --output "$outdir")

      cmd_export "$current" --platforms youtube,feed --output "$outdir"
      ;;

    education)
      # Chain: caption(clean) -> brand(clean-logo) -> music(soft, volume 0.1) -> export(all)
      info "--- Pipeline: education ---"
      current=$(cmd_caption "$current" --style clean --output "$outdir")
      current=$(cmd_brand "$current" --brand "$brand" --opacity 0.6 --output "$outdir")

      if [ -n "$music_track" ] && [ -f "$music_track" ]; then
        current=$(cmd_music "$current" --track "$music_track" --volume 0.1 --duck --fade-in 1 --fade-out 2 --output "$outdir")
      fi

      cmd_export "$current" --all --output "$outdir"
      ;;

    channel)
      # Chain: export(all-platforms-with-safe-zones) — takes already-produced video
      info "--- Pipeline: channel ---"
      cmd_export "$current" --all --output "$outdir"
      ;;

    *)
      error "Unknown output type: $output_type"
      error "Valid types: broll, aroll, promotion, ugc, lofi, hero, education, channel"
      exit 1
      ;;
  esac

  # Optional audit
  if [ "$do_audit" -eq 1 ]; then
    if [ -f "$AUDIT_SCRIPT" ]; then
      info "Running visual audit on output..."
      bash "$AUDIT_SCRIPT" audit-video "$current" 2>&1 | while IFS= read -r line; do
        info "Audit: $line"
      done
    else
      info "WARNING: audit-visual.sh not found at $AUDIT_SCRIPT, skipping audit"
    fi
  fi

  info "=== PRODUCE COMPLETE ==="
  info "Output type: $output_type"
  info "Final file: $current"
  info "Exports in: $outdir"
  echo "$current"
}

# ============================================================================
# MAIN
# ============================================================================
if [ $# -eq 0 ]; then
  echo "VideoForge — Video Post-Production Pipeline for GAIA CORP-OS"
  echo ""
  echo "Usage:"
  echo "  bash video-forge.sh caption <input.mp4> [options]     Generate styled subtitles"
  echo "  bash video-forge.sh brand <input.mp4> [options]       Apply brand identity"
  echo "  bash video-forge.sh music <input.mp4> [options]       Mix background music"
  echo "  bash video-forge.sh effects <input.mp4> [options]     Apply visual effects"
  echo "  bash video-forge.sh assemble <clips...> [options]     Concatenate clips"
  echo "  bash video-forge.sh export <input.mp4> [options]      Multi-platform export"
  echo "  bash video-forge.sh produce <input.mp4> [options]     Full auto pipeline"
  echo ""
  echo "Produce types: aroll, broll, promotion, ugc, lofi, hero, education, channel"
  echo ""
  echo "Examples:"
  echo "  bash video-forge.sh caption my_video.mp4 --style tiktok --word-level"
  echo "  bash video-forge.sh brand my_video.mp4 --brand gaia-eats --lower-third"
  echo "  bash video-forge.sh effects my_video.mp4 --grain light --grade warm --vignette"
  echo "  bash video-forge.sh produce my_video.mp4 --type aroll --brand gaia-eats --mood cozy"
  echo ""
  echo "Dependencies: ffmpeg, faster-whisper (for captions)"
  echo "Run: bash $SCRIPT_DIR/install-deps.sh to install"
  exit 0
fi

COMMAND="$1"
shift

case "$(to_lower "$COMMAND")" in
  caption)  cmd_caption "$@" ;;
  brand)    cmd_brand "$@" ;;
  music)    cmd_music "$@" ;;
  effects)  cmd_effects "$@" ;;
  assemble) cmd_assemble "$@" ;;
  export)   cmd_export "$@" ;;
  produce)  cmd_produce "$@" ;;
  *)
    error "Unknown command: $COMMAND"
    echo "Available: caption, brand, music, effects, assemble, export, produce" >&2
    exit 1
    ;;
esac
