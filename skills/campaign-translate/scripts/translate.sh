#!/usr/bin/env bash
# translate.sh — Campaign transcreation engine for Zennith OS
# Uses Claude CLI ($0 on Claude Max) for LLM-powered transcreation
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Usage:
#   bash translate.sh copy     --brand <brand> --input <text|file> --to <lang> [options]
#   bash translate.sh subtitle --brand <brand> --input <file.srt> --to <lang> [options]
#   bash translate.sh batch    --brand <brand> --input <dir> --to <lang> [options]

set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/translate.log"
BRANDS_DIR="$HOME/.openclaw/brands"
DATA_DIR="$HOME/.openclaw/workspace/data/translations"
VOICE_CHECK="$HOME/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh"
VERSION="1.0.0"

# Character expansion factors vs EN
BM_EXPANSION="1.2"
ZH_CONTRACTION="0.6"

mkdir -p "$(dirname "$LOG_FILE")"

# --- Logging ---
log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [translate] $1" >> "$LOG_FILE"; }
info()  { echo "[Translate] $1" >&2; log "$1"; }
warn()  { echo "[Translate] WARN: $1" >&2; log "WARN: $1"; }
error() { echo "[Translate] ERROR: $1" >&2; log "ERROR: $1"; }

# --- Help ---
show_help() {
  cat <<'HELP'
translate.sh — Campaign Transcreation Engine v1.0.0

Transcreation (not translation) of campaign assets across EN/BM/ZH.
Preserves brand voice, cultural nuance, and conversion intent.
Uses Claude CLI (claude --print) for LLM-powered transcreation — $0 on Claude Max.

SUBCOMMANDS:
  copy       Transcreate ad copy, captions, or marketing text
  subtitle   Transcreate .srt subtitle files with timing adjustments
  batch      Transcreate all text files in a directory

FLAGS:
  --brand <brand>          Brand name (required). Loads voice from DNA.json.
  --input <text|file>      Input text or path to input file.
  --from en|bm|zh          Source language (default: en).
  --to en|bm|zh            Target language (required).
  --tone formal|casual|manglish  Tone override (default: from brand DNA).
  --platform <platform>    Target platform for character limits.
  --output <file>          Output file path (auto-generated if omitted).
  --dry-run                Show the prompt without executing.
  --help                   Show this help message.

PLATFORMS (for character limit awareness):
  ig-feed, ig-stories, ig-reels, fb-feed, tiktok, shopee, whatsapp,
  edm, linkedin, x-post

TONE OPTIONS:
  formal    Pure language, proper grammar (Rasaya, Dr Stan, official comms)
  casual    Friendly, conversational (most brands default)
  manglish  BM/EN code-switch, Malaysian slang (Pinxin, MIRRA casual, Wholey Wonder)

EXAMPLES:
  bash translate.sh copy --brand mirra --input "Fresh meals delivered daily" --to bm
  bash translate.sh copy --brand pinxin-vegan --input caption.txt --to bm --tone manglish
  bash translate.sh subtitle --brand mirra --input ad.srt --to zh
  bash translate.sh batch --brand mirra --input ./copy/ --to bm --to zh
HELP
  exit 0
}

# --- Dependency checks ---
check_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    error "Claude CLI not found. Install: https://docs.anthropic.com/en/docs/claude-cli"
    exit 1
  fi
}

# --- Brand Voice Loading ---
# Globals set by load_brand_voice (avoids pipe-delimiter issues with arrays)
BRAND_TONE=""
BRAND_PERSONALITY=""
BRAND_AVOID=""
BRAND_TAGLINE=""

load_brand_voice() {
  local brand="$1"
  local dna="$BRANDS_DIR/$brand/DNA.json"

  BRAND_TONE="conversational"
  BRAND_PERSONALITY=""
  BRAND_AVOID=""
  BRAND_TAGLINE=""

  if [ -f "$dna" ] && command -v jq >/dev/null 2>&1; then
    BRAND_TONE=$(jq -r '.voice.tone // .tone // "conversational"' "$dna" 2>/dev/null || echo "conversational")
    # Convert arrays to comma-separated strings
    BRAND_PERSONALITY=$(jq -r 'if (.voice.personality // .personality) | type == "array" then (.voice.personality // .personality) | join(", ") else (.voice.personality // .personality // "") end' "$dna" 2>/dev/null || true)
    BRAND_AVOID=$(jq -r 'if (.voice.avoid // .avoid) | type == "array" then (.voice.avoid // .avoid) | join(", ") else (.voice.avoid // .avoid // "") end' "$dna" 2>/dev/null || true)
    BRAND_TAGLINE=$(jq -r '.tagline // .voice.tagline // ""' "$dna" 2>/dev/null || true)
  else
    warn "Brand DNA not found at $dna — using generic voice"
  fi
}

# Get platform character limit
get_platform_limit() {
  local platform="$1"
  case "$platform" in
    ig-feed)    echo "2200" ;;
    ig-stories) echo "125" ;;
    ig-reels)   echo "2200" ;;
    fb-feed)    echo "63206" ;;
    tiktok)     echo "2200" ;;
    shopee)     echo "500" ;;
    whatsapp)   echo "190" ;;
    edm)        echo "0" ;;
    linkedin)   echo "3000" ;;
    x-post)     echo "280" ;;
    *)          echo "0" ;;
  esac
}

# Language display name
lang_name() {
  case "$1" in
    en) echo "English" ;;
    bm) echo "Bahasa Malaysia" ;;
    zh) echo "Chinese (Simplified)" ;;
    *)  echo "$1" ;;
  esac
}

# --- Build System Prompt ---
build_system_prompt() {
  local brand="$1" from_lang="$2" to_lang="$3" tone="$4" platform="$5"

  # load_brand_voice sets globals: BRAND_TONE, BRAND_PERSONALITY, BRAND_AVOID, BRAND_TAGLINE
  load_brand_voice "$brand"

  local brand_tone="$BRAND_TONE"
  local brand_personality="$BRAND_PERSONALITY"
  local brand_avoid="$BRAND_AVOID"
  local brand_tagline="$BRAND_TAGLINE"

  # Override tone if explicit
  if [ "$tone" != "auto" ]; then
    brand_tone="$tone"
  fi

  local char_limit
  char_limit=$(get_platform_limit "$platform")

  local prompt="You are a professional transcreation specialist for the Malaysian market.

TASK: Transcreate (NOT translate) the following content from $(lang_name "$from_lang") to $(lang_name "$to_lang").

BRAND: $brand
BRAND VOICE: $brand_tone
"

  if [ -n "$brand_personality" ]; then
    prompt="${prompt}BRAND PERSONALITY: $brand_personality
"
  fi
  if [ -n "$brand_tagline" ]; then
    prompt="${prompt}BRAND TAGLINE: $brand_tagline
"
  fi
  if [ -n "$brand_avoid" ]; then
    prompt="${prompt}AVOID: $brand_avoid
"
  fi

  if [ "$char_limit" -gt 0 ] 2>/dev/null; then
    prompt="${prompt}PLATFORM: $platform (max $char_limit characters)
"
  fi

  # Tone-specific instructions
  case "$tone" in
    manglish)
      prompt="${prompt}
TONE: Manglish (BM/EN code-switch). This is authentic Malaysian voice.
- Mix BM and EN naturally, mid-sentence is OK
- Use Malaysian slang: lah, kan, gila, confirm, power, best
- Examples: 'So sedap lah this bento!', 'Confirm worth it, serious!'
- Sound like a friend, not a brand
"
      ;;
    formal)
      prompt="${prompt}
TONE: Formal. Use proper grammar and professional register.
- BM: bahasa baku, respectful (anda, tuan/puan), no slang
- ZH: standard Simplified Chinese, professional tone
- EN: clean, professional, no colloquialisms
"
      ;;
    casual|*)
      prompt="${prompt}
TONE: Casual, conversational. Friendly but not sloppy.
"
      ;;
  esac

  prompt="${prompt}
TRANSCREATION RULES:
1. Preserve the EMOTIONAL TRIGGER and CONVERSION INTENT, not the literal words
2. Adapt wordplay, puns, idioms — create new ones that work in $(lang_name "$to_lang")
3. Keep brand names, product names, prices, and URLs unchanged
4. Hashtags: use culturally relevant equivalents, never direct-translate
5. CTAs: adapt to proven $(lang_name "$to_lang") CTAs for the Malaysian market
6. Emoji usage: keep similar density (Malaysians use emojis equally across all languages)
7. Numbers and prices stay as-is (RM15.90 not 'lima belas ringgit')

MALAYSIAN MARKET CONTEXT:
- Audience code-switches between EN/BM/ZH naturally
- 'Halal' is straightforward in EN/BM; use '清真' in ZH
- Food terms like nasi lemak, rendang, sambal stay untranslated (cultural authenticity)
- BM text is typically 10-30% longer than EN; ZH is 30-50% shorter

OUTPUT: Provide ONLY the transcreated text. No explanations, no alternatives, no metadata."

  echo "$prompt"
}

# --- Copy Subcommand ---
do_copy() {
  local brand="$1" input="$2" from_lang="$3" to_lang="$4" tone="$5" platform="$6" output="$7" dry_run="$8"
  check_claude

  # Resolve input text
  local text=""
  if [ -f "$input" ]; then
    text=$(cat "$input")
    info "Reading input from file: $input"
  else
    text="$input"
  fi

  if [ -z "$text" ]; then
    error "No input text provided."
    exit 1
  fi

  local system_prompt
  system_prompt=$(build_system_prompt "$brand" "$from_lang" "$to_lang" "$tone" "$platform")

  info "Transcreating: $(lang_name "$from_lang") -> $(lang_name "$to_lang") | Brand: $brand | Tone: $tone"
  info "Input: $(echo "$text" | head -c 80)..."

  if [ "$dry_run" = "true" ]; then
    echo ""
    echo "=== SYSTEM PROMPT ==="
    echo "$system_prompt"
    echo ""
    echo "=== INPUT TEXT ==="
    echo "$text"
    echo ""
    echo "[DRY-RUN] Would call: claude --print -p \"<system_prompt>\" \"<input_text>\""
    return
  fi

  # Call Claude CLI for transcreation
  local result
  result=$(claude --print -p "$system_prompt

---

TEXT TO TRANSCREATE:

$text" 2>/dev/null) || {
    error "Claude CLI call failed. Is Claude CLI installed and authenticated?"
    exit 1
  }

  if [ -z "$result" ]; then
    error "Claude returned empty result."
    exit 1
  fi

  # Output result
  if [ -n "$output" ]; then
    mkdir -p "$(dirname "$output")"
    echo "$result" > "$output"
    info "Output saved: $output"
  else
    # Auto-generate output path
    local auto_dir="$DATA_DIR/$brand"
    mkdir -p "$auto_dir"
    local timestamp
    timestamp=$(date '+%Y%m%d%H%M%S')
    local auto_output="$auto_dir/${brand}_${from_lang}_to_${to_lang}_${timestamp}.txt"
    echo "$result" > "$auto_output"
    info "Output saved: $auto_output"
    output="$auto_output"
  fi

  # Print result to stdout
  echo ""
  echo "=== Transcreated ($to_lang) ==="
  echo "$result"
  echo ""

  # Run brand voice check if available
  if [ -f "$VOICE_CHECK" ]; then
    info "Running brand voice check..."
    bash "$VOICE_CHECK" --brand "$brand" --file "$output" 2>/dev/null || warn "Brand voice check skipped or failed"
  fi
}

# --- Subtitle Subcommand ---
do_subtitle() {
  local brand="$1" input="$2" from_lang="$3" to_lang="$4" tone="$5" output="$6" dry_run="$7"
  check_claude

  if [ ! -f "$input" ]; then
    error "SRT file not found: $input"
    exit 1
  fi

  # Validate SRT format
  if ! echo "$input" | grep -qi '\.srt$' 2>/dev/null; then
    warn "Input does not have .srt extension — proceeding anyway"
  fi

  local srt_content
  srt_content=$(cat "$input")

  # Build subtitle-specific system prompt
  local system_prompt
  system_prompt=$(build_system_prompt "$brand" "$from_lang" "$to_lang" "$tone" "")

  system_prompt="${system_prompt}

SUBTITLE-SPECIFIC RULES:
1. Preserve SRT format exactly: sequence number, timecodes, text, blank line
2. Translate ONLY the text lines — never modify sequence numbers or timecodes
3. Maximum 2 lines per subtitle, max 42 chars per line (EN/BM) or 16 chars per line (ZH)
4. Keep subtitles readable at the display duration

TIMING ADJUSTMENTS (apply after transcreation):
- BM: text is ~20% longer than EN. If a subtitle has very short display time (<2s) and the BM text is significantly longer, note it with a comment.
- ZH: text is ~40% shorter than EN. Subtitles can be more concise.
- Minimum display time: 1.5 seconds regardless of language.

OUTPUT: Return the complete SRT file with translated text. Preserve all timecodes exactly."

  info "Subtitle transcreation: $(lang_name "$from_lang") -> $(lang_name "$to_lang")"
  info "Input: $input"

  if [ "$dry_run" = "true" ]; then
    echo "[DRY-RUN] Would transcreate $(grep -c '^[0-9]*$' "$input" 2>/dev/null || echo '?') subtitle blocks"
    echo "[DRY-RUN] $(lang_name "$from_lang") -> $(lang_name "$to_lang")"
    return
  fi

  local result
  result=$(claude --print -p "$system_prompt

---

SRT FILE TO TRANSCREATE:

$srt_content" 2>/dev/null) || {
    error "Claude CLI call failed."
    exit 1
  }

  # Determine output path
  if [ -z "$output" ]; then
    local base
    base=$(echo "$input" | sed 's/\.srt$//')
    output="${base}_${to_lang}.srt"
  fi

  mkdir -p "$(dirname "$output")"
  echo "$result" > "$output"

  # Apply timing adjustments for BM (extend) or ZH (contract)
  if [ "$to_lang" = "bm" ]; then
    info "Note: BM subtitles may need 10-20% longer display times for comfortable reading."
  elif [ "$to_lang" = "zh" ]; then
    info "Note: ZH subtitles can use 15-25% shorter display times."
  fi

  local sub_count
  sub_count=$(grep -c '^[0-9][0-9]*$' "$output" 2>/dev/null || echo "?")
  info "Output: $output ($sub_count subtitles)"

  # Run brand voice check if available
  if [ -f "$VOICE_CHECK" ]; then
    info "Running brand voice check..."
    bash "$VOICE_CHECK" --brand "$brand" --file "$output" 2>/dev/null || warn "Brand voice check skipped or failed"
  fi
}

# --- Batch Subcommand ---
do_batch() {
  local brand="$1" input_dir="$2" from_lang="$3" to_lang="$4" tone="$5" output_dir="$6" dry_run="$7"

  if [ ! -d "$input_dir" ]; then
    error "Input directory not found: $input_dir"
    exit 1
  fi

  if [ -z "$output_dir" ]; then
    output_dir="$DATA_DIR/$brand/batch_$(date '+%Y%m%d%H%M%S')"
  fi
  mkdir -p "$output_dir"

  local total=0 success=0 failed=0
  info "Batch transcreation: $input_dir -> $output_dir"

  local f
  for f in "$input_dir"/*.txt "$input_dir"/*.srt "$input_dir"/*.md; do
    [ -f "$f" ] || continue
    total=$((total + 1))
    local fname
    fname=$(basename "$f")
    local ext
    ext=$(echo "$fname" | sed 's/.*\.//')
    local base
    base=$(echo "$fname" | sed 's/\.[^.]*$//')
    local out_file="$output_dir/${base}_${to_lang}.${ext}"

    info "[$total] $fname"

    if [ "$ext" = "srt" ]; then
      if do_subtitle "$brand" "$f" "$from_lang" "$to_lang" "$tone" "$out_file" "$dry_run"; then
        success=$((success + 1))
      else
        failed=$((failed + 1))
        warn "Failed: $fname"
      fi
    else
      if do_copy "$brand" "$f" "$from_lang" "$to_lang" "$tone" "" "$out_file" "$dry_run"; then
        success=$((success + 1))
      else
        failed=$((failed + 1))
        warn "Failed: $fname"
      fi
    fi
  done

  if [ "$total" -eq 0 ]; then
    warn "No .txt, .srt, or .md files found in $input_dir"
  else
    info "Batch complete: $success/$total succeeded ($failed failed)"
  fi
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
  local brand="" input="" from_lang="en" to_lang="" tone="auto" platform="" output="" dry_run="false"
  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)    brand="$2"; shift 2 ;;
      --input)    input="$2"; shift 2 ;;
      --from)     from_lang="$2"; shift 2 ;;
      --to)       to_lang="$2"; shift 2 ;;
      --tone)     tone="$2"; shift 2 ;;
      --platform) platform="$2"; shift 2 ;;
      --output)   output="$2"; shift 2 ;;
      --dry-run)  dry_run="true"; shift ;;
      --help|-h)  show_help ;;
      *)          error "Unknown flag: $1"; show_help ;;
    esac
  done

  # Validate required args
  if [ -z "$brand" ]; then
    error "--brand is required"
    exit 1
  fi
  if [ -z "$to_lang" ]; then
    error "--to is required (en, bm, or zh)"
    exit 1
  fi
  if [ -z "$input" ]; then
    error "--input is required"
    exit 1
  fi

  # Validate languages
  case "$from_lang" in
    en|bm|zh) ;;
    *) error "Invalid --from language: $from_lang (use en, bm, or zh)"; exit 1 ;;
  esac
  case "$to_lang" in
    en|bm|zh) ;;
    *) error "Invalid --to language: $to_lang (use en, bm, or zh)"; exit 1 ;;
  esac
  if [ "$from_lang" = "$to_lang" ]; then
    error "Source and target language are the same: $from_lang"
    exit 1
  fi

  log "Subcommand: $subcmd | Brand: $brand | $from_lang -> $to_lang | Tone: $tone"

  case "$subcmd" in
    copy)
      do_copy "$brand" "$input" "$from_lang" "$to_lang" "$tone" "$platform" "$output" "$dry_run"
      ;;
    subtitle)
      do_subtitle "$brand" "$input" "$from_lang" "$to_lang" "$tone" "$output" "$dry_run"
      ;;
    batch)
      do_batch "$brand" "$input" "$from_lang" "$to_lang" "$tone" "$output" "$dry_run"
      ;;
    *)
      error "Unknown subcommand: $subcmd"
      show_help
      ;;
  esac
}

main "$@"
