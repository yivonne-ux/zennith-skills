#!/usr/bin/env bash
# voiceover.sh — AI voiceover generation for Zennith OS
# Multi-engine TTS: Edge TTS (free default), ElevenLabs, Google Cloud, OpenAI
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash voiceover.sh generate --brand <brand> --script "text" [options]
#   bash voiceover.sh preview  --brand <brand> --script "text" [options]
#   bash voiceover.sh mix      --brand <brand> --video <file> --script "text" [options]
#   bash voiceover.sh batch    --brand <brand> --script-file <file> [options]
#   bash voiceover.sh list-voices --engine <engine> [options]

set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/voiceover.log"
BRANDS_DIR="$HOME/.openclaw/brands"
AUDIO_DIR="$HOME/.openclaw/workspace/data/audio"
VERSION="1.0.0"

# Default Edge TTS voices (free tier)
EDGE_VOICE_EN="en-US-JennyNeural"
EDGE_VOICE_BM="ms-MY-YasminNeural"
EDGE_VOICE_ZH="zh-CN-XiaoxiaoNeural"

mkdir -p "$(dirname "$LOG_FILE")"

# --- Logging ---
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [voiceover] $1" >> "$LOG_FILE"; }
info()  { echo "[Voiceover] $1" >&2; log "$1"; }
warn()  { echo "[Voiceover] WARN: $1" >&2; log "WARN: $1"; }
error() { echo "[Voiceover] ERROR: $1" >&2; log "ERROR: $1"; }

# --- Help ---
show_help() {
  cat <<'HELP'
voiceover.sh — AI Voiceover Engine v1.0.0

Generate natural-sounding voiceovers using AI TTS engines.
Supports EN, BM (Bahasa Malaysia), and ZH (Mandarin Chinese).

SUBCOMMANDS:
  generate      Generate voiceover audio from script text
  preview       Quick preview using Edge TTS (free, no API key)
  mix           Generate voiceover and mix into a video file
  batch         Process multiple scripts from a file (one per line)
  list-voices   List available voices for an engine

FLAGS:
  --brand <brand>          Brand name (loads voice profile from DNA).
  --lang en|bm|zh          Language (default: en).
  --script <text>          Inline script text.
  --script-file <file>     Read script from file.
  --video <file>           Video file for mix subcommand.
  --engine <engine>        TTS engine: edge|elevenlabs|google|openai (default: edge).
  --output <file>          Output file path (auto-generated if omitted).
  --dry-run                Show commands without executing.
  --help                   Show this help message.

ENGINES:
  edge         Free, good quality, no API key (default for preview)
  elevenlabs   Premium quality, voice cloning, requires ELEVENLABS_API_KEY
  google       Best BM/ZH quality, requires gcloud auth
  openai       Natural English, requires OPENAI_API_KEY

EXAMPLES:
  bash voiceover.sh preview --brand mirra --script "Fresh meals, delivered daily."
  bash voiceover.sh generate --brand pinxin-vegan --lang bm --engine google \
    --script "Nasi lemak vegan yang memang best!"
  bash voiceover.sh mix --brand mirra --video ad.mp4 --script-file script.txt
  bash voiceover.sh list-voices --engine edge --lang en
HELP
  exit 0
}

# --- Dependency checks ---
check_edge_tts() {
  if ! command -v edge-tts >/dev/null 2>&1; then
    if ! python3 -m edge_tts --help >/dev/null 2>&1; then
      error "edge-tts not found. Install: pip3 install edge-tts"
      exit 1
    fi
  fi
}

check_ffmpeg() {
  if ! command -v ffmpeg >/dev/null 2>&1; then
    error "ffmpeg is required. Install: brew install ffmpeg"
    exit 1
  fi
}

check_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    error "curl is required."
    exit 1
  fi
}

# --- Voice Profile ---
# Load voice profile from brand directory, or create a default one
load_voice_profile() {
  local brand="$1" lang="$2" engine="$3"
  local profile="$BRANDS_DIR/$brand/voice-profile.json"

  if [ -f "$profile" ] && command -v jq >/dev/null 2>&1; then
    local voice_key="voice_$lang"
    local engine_from_profile
    engine_from_profile=$(jq -r ".${voice_key}.engine // empty" "$profile" 2>/dev/null || true)
    local voice_id
    voice_id=$(jq -r ".${voice_key}.voice_id // empty" "$profile" 2>/dev/null || true)

    # If engine was not explicitly set, use profile engine for this lang
    if [ "$engine" = "auto" ] && [ -n "$engine_from_profile" ]; then
      engine="$engine_from_profile"
    fi

    if [ -n "$voice_id" ]; then
      echo "$engine|$voice_id"
      return
    fi
  fi

  # Defaults if no profile found
  if [ "$engine" = "auto" ]; then
    engine="edge"
  fi

  case "$lang" in
    en) echo "$engine|$EDGE_VOICE_EN" ;;
    bm) echo "$engine|$EDGE_VOICE_BM" ;;
    zh) echo "$engine|$EDGE_VOICE_ZH" ;;
    *)  echo "$engine|$EDGE_VOICE_EN" ;;
  esac
}

# Resolve the edge-tts command (standalone binary or python module)
edge_tts_cmd() {
  if command -v edge-tts >/dev/null 2>&1; then
    echo "edge-tts"
  else
    echo "python3 -m edge_tts"
  fi
}

# --- TTS Engine Calls ---

generate_edge() {
  local text="$1" voice="$2" output="$3" rate="${4:-+0%}" pitch="${5:-+0Hz}"
  local cmd
  cmd=$(edge_tts_cmd)
  info "Engine: Edge TTS (free) | Voice: $voice"
  $cmd --text "$text" --voice "$voice" --rate "$rate" --pitch "$pitch" \
    --write-media "$output" 2>/dev/null
}

generate_elevenlabs() {
  local text="$1" voice_id="$2" output="$3"
  check_curl

  if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
    error "ELEVENLABS_API_KEY not set. Export it or use --engine edge for free preview."
    exit 1
  fi

  # Load voice settings from profile if available
  local stability="0.5"
  local similarity="0.8"

  info "Engine: ElevenLabs | Voice ID: $voice_id"
  curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$voice_id" \
    -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"text\": $(printf '%s' "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
      \"model_id\": \"eleven_multilingual_v2\",
      \"voice_settings\": {
        \"stability\": $stability,
        \"similarity_boost\": $similarity,
        \"style\": 0.3,
        \"use_speaker_boost\": true
      }
    }" \
    --output "$output"

  if [ ! -s "$output" ]; then
    error "ElevenLabs API returned empty response. Check API key and voice_id."
    exit 1
  fi
}

generate_google() {
  local text="$1" voice_id="$2" output="$3" lang_code="$4"
  check_curl

  # Determine language code for Google
  local gcloud_lang=""
  case "$lang_code" in
    en) gcloud_lang="en-US" ;;
    bm) gcloud_lang="ms-MY" ;;
    zh) gcloud_lang="cmn-CN" ;;
    *)  gcloud_lang="en-US" ;;
  esac

  local token
  if ! token=$(gcloud auth print-access-token 2>/dev/null); then
    error "gcloud auth failed. Run: gcloud auth login"
    exit 1
  fi

  info "Engine: Google Cloud TTS | Voice: $voice_id ($gcloud_lang)"
  local response
  response=$(curl -s -X POST "https://texttospeech.googleapis.com/v1/text:synthesize" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{
      \"input\": {\"text\": $(printf '%s' "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')},
      \"voice\": {\"languageCode\": \"$gcloud_lang\", \"name\": \"$voice_id\"},
      \"audioConfig\": {\"audioEncoding\": \"MP3\", \"speakingRate\": 1.0, \"pitch\": 0, \"sampleRateHertz\": 24000}
    }")

  echo "$response" | python3 -c "
import json, sys, base64
data = json.load(sys.stdin)
if 'audioContent' in data:
    sys.stdout.buffer.write(base64.b64decode(data['audioContent']))
else:
    print('ERROR: ' + json.dumps(data), file=sys.stderr)
    sys.exit(1)
" > "$output"

  if [ ! -s "$output" ]; then
    error "Google Cloud TTS returned empty response."
    exit 1
  fi
}

generate_openai() {
  local text="$1" voice="${2:-nova}" output="$3"
  check_curl

  if [ -z "${OPENAI_API_KEY:-}" ]; then
    error "OPENAI_API_KEY not set."
    exit 1
  fi

  info "Engine: OpenAI TTS | Voice: $voice"
  curl -s -X POST "https://api.openai.com/v1/audio/speech" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"tts-1-hd\",
      \"input\": $(printf '%s' "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
      \"voice\": \"$voice\",
      \"response_format\": \"mp3\",
      \"speed\": 1.0
    }" \
    --output "$output"

  if [ ! -s "$output" ]; then
    error "OpenAI TTS returned empty response."
    exit 1
  fi
}

# --- Post-processing ---
postprocess_audio() {
  local input="$1" output="$2"
  check_ffmpeg
  info "Post-processing: normalize volume, trim silence"
  ffmpeg -y -i "$input" \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11,silenceremove=1:0:-40dB" \
    "$output" >/dev/null 2>&1
}

# --- Subcommands ---

do_generate() {
  local brand="$1" lang="$2" engine="$3" script_text="$4" output="$5" dry_run="$6"
  local outdir
  outdir=$(dirname "$output")
  mkdir -p "$outdir"

  # Load voice profile
  local profile_data voice_id resolved_engine
  profile_data=$(load_voice_profile "$brand" "$lang" "$engine")
  resolved_engine=$(echo "$profile_data" | cut -d'|' -f1)
  voice_id=$(echo "$profile_data" | cut -d'|' -f2)

  info "Brand: $brand | Lang: $lang | Engine: $resolved_engine | Voice: $voice_id"
  info "Script: $(echo "$script_text" | head -c 80)..."

  if [ "$dry_run" = "true" ]; then
    echo "[DRY-RUN] Would generate $resolved_engine TTS -> $output"
    echo "[DRY-RUN] Voice: $voice_id | Lang: $lang | Text length: ${#script_text} chars"
    return
  fi

  local raw_output="${output%.mp3}_raw.mp3"

  case "$resolved_engine" in
    edge)
      check_edge_tts
      generate_edge "$script_text" "$voice_id" "$raw_output"
      ;;
    elevenlabs)
      generate_elevenlabs "$script_text" "$voice_id" "$raw_output"
      ;;
    google)
      generate_google "$script_text" "$voice_id" "$raw_output" "$lang"
      ;;
    openai)
      generate_openai "$script_text" "$voice_id" "$raw_output"
      ;;
    *)
      error "Unknown engine: $resolved_engine"
      exit 1
      ;;
  esac

  # Post-process
  if [ -f "$raw_output" ] && [ -s "$raw_output" ]; then
    postprocess_audio "$raw_output" "$output"
    rm -f "$raw_output"
    local size
    size=$(wc -c < "$output" | tr -d ' ')
    info "Output: $output ($size bytes)"

    # Write sidecar metadata
    local meta="${output%.mp3}.json"
    echo "{" > "$meta"
    echo "  \"brand\": \"$brand\"," >> "$meta"
    echo "  \"lang\": \"$lang\"," >> "$meta"
    echo "  \"engine\": \"$resolved_engine\"," >> "$meta"
    echo "  \"voice_id\": \"$voice_id\"," >> "$meta"
    echo "  \"script_length\": ${#script_text}," >> "$meta"
    echo "  \"generated_at\": \"$(date '+%Y-%m-%dT%H:%M:%S')\"," >> "$meta"
    echo "  \"tool\": \"voiceover.sh v$VERSION\"" >> "$meta"
    echo "}" >> "$meta"
  else
    error "TTS generation failed — no audio produced."
    exit 1
  fi
}

do_preview() {
  local brand="$1" lang="$2" script_text="$3" output="$4" dry_run="$5"
  info "Preview mode: using Edge TTS (free)"
  do_generate "$brand" "$lang" "edge" "$script_text" "$output" "$dry_run"
}

do_mix() {
  local brand="$1" lang="$2" engine="$3" script_text="$4" video="$5" output="$6" dry_run="$7"

  if [ ! -f "$video" ]; then
    error "Video file not found: $video"
    exit 1
  fi

  # Generate voiceover first
  local audio_output
  audio_output="$AUDIO_DIR/$brand/vo_${brand}_$(date '+%Y%m%d%H%M%S').mp3"
  do_generate "$brand" "$lang" "$engine" "$script_text" "$audio_output" "$dry_run"

  if [ "$dry_run" = "true" ]; then
    echo "[DRY-RUN] Would mix $audio_output into $video -> $output"
    return
  fi

  # Mix using video-forge if available, otherwise direct ffmpeg
  local video_forge="$HOME/.openclaw/skills/video-forge/scripts/video-forge.sh"
  if [ -f "$video_forge" ]; then
    info "Mixing via VideoForge..."
    bash "$video_forge" music "$video" --track "$audio_output" --duck --output "$output"
  else
    info "Mixing via ffmpeg (VideoForge not found)..."
    check_ffmpeg
    # Duck original audio and overlay voiceover
    ffmpeg -y -i "$video" -i "$audio_output" \
      -filter_complex "[0:a]volume=0.3[bg];[bg][1:a]amix=inputs=2:duration=first[out]" \
      -map 0:v -map "[out]" -c:v copy -c:a aac -b:a 192k \
      "$output" >/dev/null 2>&1
    info "Mixed output: $output"
  fi
}

do_batch() {
  local brand="$1" lang="$2" engine="$3" script_file="$4" output_dir="$5" dry_run="$6"

  if [ ! -f "$script_file" ]; then
    error "Script file not found: $script_file"
    exit 1
  fi

  mkdir -p "$output_dir"
  local line_num=0
  local success=0
  local failed=0

  info "Batch mode: reading scripts from $script_file"
  while IFS= read -r line || [ -n "$line" ]; do
    line_num=$((line_num + 1))
    # Skip empty lines and comments
    if [ -z "$line" ] || echo "$line" | grep -q '^#' 2>/dev/null; then
      continue
    fi
    local out_file="$output_dir/${brand}_${lang}_$(printf '%03d' "$line_num").mp3"
    info "Batch $line_num: $(echo "$line" | head -c 60)..."
    if do_generate "$brand" "$lang" "$engine" "$line" "$out_file" "$dry_run"; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
    fi
  done < "$script_file"

  info "Batch complete: $success succeeded, $failed failed out of $line_num lines"
}

do_list_voices() {
  local engine="$1" lang="$2"

  case "$engine" in
    edge)
      check_edge_tts
      info "Edge TTS voices (filtered by lang: $lang):"
      local cmd
      cmd=$(edge_tts_cmd)
      local lang_filter=""
      case "$lang" in
        en) lang_filter="en-" ;;
        bm) lang_filter="ms-" ;;
        zh) lang_filter="zh-" ;;
        *)  lang_filter="" ;;
      esac
      if [ -n "$lang_filter" ]; then
        $cmd --list-voices 2>/dev/null | grep "$lang_filter" || echo "No voices found for $lang"
      else
        $cmd --list-voices 2>/dev/null || echo "Could not list voices"
      fi
      ;;
    elevenlabs)
      check_curl
      if [ -z "${ELEVENLABS_API_KEY:-}" ]; then
        error "ELEVENLABS_API_KEY not set."
        exit 1
      fi
      info "ElevenLabs voices:"
      curl -s "https://api.elevenlabs.io/v1/voices" \
        -H "xi-api-key: ${ELEVENLABS_API_KEY}" | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data.get('voices', []):
    print(f\"  {v['voice_id']}  {v['name']:25s}  {', '.join(v.get('labels', {}).values())}\")
" 2>/dev/null || echo "Could not list voices (check API key)"
      ;;
    google)
      info "Google Cloud TTS voices for $lang:"
      local gcloud_lang=""
      case "$lang" in
        en) gcloud_lang="en" ;;
        bm) gcloud_lang="ms" ;;
        zh) gcloud_lang="cmn" ;;
        *)  gcloud_lang="" ;;
      esac
      if command -v gcloud >/dev/null 2>&1; then
        gcloud ml speech recognize --help >/dev/null 2>&1
        curl -s "https://texttospeech.googleapis.com/v1/voices?languageCode=${gcloud_lang}" \
          -H "Authorization: Bearer $(gcloud auth print-access-token 2>/dev/null)" | \
          python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data.get('voices', []):
    print(f\"  {v['name']:30s}  {v.get('ssmlGender','?'):8s}  {', '.join(v.get('languageCodes',[]))}\")
" 2>/dev/null || echo "Could not list voices (check gcloud auth)"
      else
        echo "  gcloud CLI not installed. Common $lang voices:"
        case "$lang" in
          en) echo "  en-US-Wavenet-A through en-US-Wavenet-J" ;;
          bm) echo "  ms-MY-Wavenet-A, ms-MY-Wavenet-B, ms-MY-Wavenet-C, ms-MY-Wavenet-D" ;;
          zh) echo "  cmn-CN-Wavenet-A through cmn-CN-Wavenet-D" ;;
        esac
      fi
      ;;
    openai)
      info "OpenAI TTS voices:"
      echo "  alloy    — neutral, balanced"
      echo "  echo     — warm, grounded"
      echo "  fable    — expressive, British"
      echo "  onyx     — deep, authoritative"
      echo "  nova     — friendly, warm (recommended)"
      echo "  shimmer  — gentle, optimistic"
      ;;
    *)
      error "Unknown engine: $engine. Choose: edge, elevenlabs, google, openai"
      exit 1
      ;;
  esac
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
  local brand="" lang="en" engine="auto" script_text="" script_file="" video=""
  local output="" dry_run="false"
  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)       brand="$2"; shift 2 ;;
      --lang)        lang="$2"; shift 2 ;;
      --engine)      engine="$2"; shift 2 ;;
      --script)      script_text="$2"; shift 2 ;;
      --script-file) script_file="$2"; shift 2 ;;
      --video)       video="$2"; shift 2 ;;
      --output)      output="$2"; shift 2 ;;
      --dry-run)     dry_run="true"; shift ;;
      --help|-h)     show_help ;;
      *)             error "Unknown flag: $1"; show_help ;;
    esac
  done

  # Resolve script text from file if needed
  if [ -n "$script_file" ] && [ -z "$script_text" ] && [ "$subcmd" != "batch" ]; then
    if [ ! -f "$script_file" ]; then
      error "Script file not found: $script_file"
      exit 1
    fi
    script_text=$(cat "$script_file")
  fi

  # Default output path
  local timestamp
  timestamp=$(date '+%Y%m%d%H%M%S')
  if [ -z "$output" ] && [ -n "$brand" ]; then
    mkdir -p "$AUDIO_DIR/$brand"
    output="$AUDIO_DIR/$brand/${brand}_${lang}_${timestamp}.mp3"
  elif [ -z "$output" ]; then
    output="/tmp/voiceover_${timestamp}.mp3"
  fi

  case "$subcmd" in
    generate)
      if [ -z "$brand" ]; then error "--brand is required"; exit 1; fi
      if [ -z "$script_text" ]; then error "--script or --script-file is required"; exit 1; fi
      do_generate "$brand" "$lang" "$engine" "$script_text" "$output" "$dry_run"
      ;;
    preview)
      if [ -z "$brand" ]; then error "--brand is required"; exit 1; fi
      if [ -z "$script_text" ]; then error "--script or --script-file is required"; exit 1; fi
      do_preview "$brand" "$lang" "$script_text" "$output" "$dry_run"
      ;;
    mix)
      if [ -z "$brand" ]; then error "--brand is required"; exit 1; fi
      if [ -z "$script_text" ]; then error "--script or --script-file is required"; exit 1; fi
      if [ -z "$video" ]; then error "--video is required for mix"; exit 1; fi
      local mix_output="${output%.mp3}.mp4"
      if [ -n "$output" ] && echo "$output" | grep -q '\.mp4$' 2>/dev/null; then
        mix_output="$output"
      fi
      do_mix "$brand" "$lang" "$engine" "$script_text" "$video" "$mix_output" "$dry_run"
      ;;
    batch)
      if [ -z "$brand" ]; then error "--brand is required"; exit 1; fi
      if [ -z "$script_file" ]; then error "--script-file is required for batch"; exit 1; fi
      local batch_dir="$AUDIO_DIR/$brand/batch_${timestamp}"
      do_batch "$brand" "$lang" "$engine" "$script_file" "$batch_dir" "$dry_run"
      ;;
    list-voices)
      local list_engine="$engine"
      if [ "$list_engine" = "auto" ]; then list_engine="edge"; fi
      do_list_voices "$list_engine" "$lang"
      ;;
    *)
      error "Unknown subcommand: $subcmd"
      show_help
      ;;
  esac
}

main "$@"
