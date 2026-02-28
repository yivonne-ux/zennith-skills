#!/usr/bin/env bash
# classify-input.sh — Universal input classifier for Zenni
# Detects TYPE (what is it) + INTENT (why was it sent) → routes to correct agent + action
#
# Usage:
#   bash classify-input.sh <input_path_or_url> [context_message]
#
# Returns JSON:
#   {"type":"...","intent":"...","agent":"...","action":"...","room":"...","detail":"..."}
#
# Type detection = rule-based (file ext, URL domain) = FREE
# Intent detection = keyword matching on context message = FREE
# No LLM calls needed.

set -uo pipefail

INPUT="${1:-}"
CONTEXT="${2:-}"

if [ -z "$INPUT" ]; then
  echo '{"error":"Usage: classify-input.sh <input_or_url> [context_message]"}'
  exit 1
fi

INPUT_LOWER=$(printf '%s' "$INPUT" | tr '[:upper:]' '[:lower:]')
CONTEXT_LOWER=$(printf '%s' "$CONTEXT" | tr '[:upper:]' '[:lower:]')

# ── Helper: detect intent from context keywords ──────────────────────────────
detect_intent() {
  local ctx="$1"
  if [ -z "$ctx" ]; then
    echo "general"
    return
  fi

  # Fix/bug intent
  if echo "$ctx" | grep -qiE '(fix|broken|bug|error|not work|cant click|doesnt work|issue|problem|wrong)'; then
    echo "fix"
    return
  fi

  # Learn/study intent
  if echo "$ctx" | grep -qiE '(learn|study|watch|understand|takeaway|insight|what can we|teach)'; then
    echo "learn"
    return
  fi

  # Competitor/research intent
  if echo "$ctx" | grep -qiE '(competitor|competition|spy|benchmark|compare|check what|see what|how they|their)'; then
    echo "research"
    return
  fi

  # Creative inspiration intent
  if echo "$ctx" | grep -qiE '(style|like this|similar|inspire|mood|reference|recreate|make.*(like|similar)|vibe|aesthetic)'; then
    echo "inspire"
    return
  fi

  # Analysis/data intent
  if echo "$ctx" | grep -qiE '(analyz|analysis|data|numbers|sales|report|metric|performance|trend|pattern|forecast)'; then
    echo "analyze"
    return
  fi

  # Reverse prompt / editing style
  if echo "$ctx" | grep -qiE '(reverse.?prompt|how.*(made|edited|shot|filmed)|editing style|what prompt|technique|breakdown)'; then
    echo "reverse-prompt"
    return
  fi

  # Review/QA intent
  if echo "$ctx" | grep -qiE '(review|check|qa|quality|feedback|approve|look at|what do you think)'; then
    echo "review"
    return
  fi

  # Post/publish intent
  if echo "$ctx" | grep -qiE '(post|publish|share|upload|schedule|go live)'; then
    echo "publish"
    return
  fi

  echo "general"
}

INTENT=$(detect_intent "$CONTEXT_LOWER")

# ── TYPE + AGENT routing ─────────────────────────────────────────────────────

TYPE="unknown"
AGENT="artemis"
ACTION="research"
ROOM="exec"
DETAIL=""

# === URL detection ===
if echo "$INPUT_LOWER" | grep -qE '^https?://'; then
  # Extract domain
  DOMAIN=$(printf '%s' "$INPUT_LOWER" | sed 's|^[a-zA-Z]*://||' | sed 's|/.*||' | sed 's|:.*||')

  case "$DOMAIN" in
    # ── YouTube ──
    *youtube.com*|*youtu.be*)
      TYPE="youtube-video"
      case "$INTENT" in
        learn)
          AGENT="taoz"; ACTION="learn-youtube"; ROOM="build"
          DETAIL="Extract transcript, map insights to agents, store in memory"
          ;;
        research)
          AGENT="artemis"; ACTION="analyze-video"; ROOM="exec"
          DETAIL="Competitor/market video analysis"
          ;;
        inspire|reverse-prompt)
          AGENT="iris"; ACTION="reverse-prompt-video"; ROOM="creative"
          DETAIL="Analyze editing style, visual techniques, reverse prompt"
          ;;
        fix)
          AGENT="taoz"; ACTION="debug"; ROOM="build"
          DETAIL="Fix video-related code issue"
          ;;
        *)
          AGENT="artemis"; ACTION="summarize-video"; ROOM="exec"
          DETAIL="General video analysis and summary"
          ;;
      esac
      ;;

    # ── Pinterest ──
    *pinterest.com*|*pin.it*)
      TYPE="pinterest"
      case "$INTENT" in
        inspire|reverse-prompt)
          AGENT="iris"; ACTION="extract-style-seed"; ROOM="creative"
          DETAIL="Extract visual style, colors, mood for style seed bank"
          ;;
        research)
          AGENT="artemis"; ACTION="research-visual-trends"; ROOM="exec"
          DETAIL="Analyze visual trends and competitor references"
          ;;
        *)
          AGENT="iris"; ACTION="visual-reference"; ROOM="creative"
          DETAIL="Visual reference and style analysis"
          ;;
      esac
      ;;

    # ── Instagram ──
    *instagram.com*)
      TYPE="instagram"
      case "$INTENT" in
        research)
          AGENT="artemis"; ACTION="scrape-social"; ROOM="exec"
          DETAIL="Competitor social analysis"
          ;;
        inspire)
          AGENT="dreami"; ACTION="creative-brief-from-ref"; ROOM="creative"
          DETAIL="Create content brief inspired by this post"
          ;;
        *)
          AGENT="iris"; ACTION="analyze-social"; ROOM="creative"
          DETAIL="Social content analysis"
          ;;
      esac
      ;;

    # ── TikTok ──
    *tiktok.com*)
      TYPE="tiktok"
      case "$INTENT" in
        research)
          AGENT="artemis"; ACTION="scrape-social"; ROOM="exec"
          DETAIL="TikTok trend/competitor analysis"
          ;;
        inspire|reverse-prompt)
          AGENT="iris"; ACTION="reverse-prompt-video"; ROOM="creative"
          DETAIL="Analyze TikTok video style and technique"
          ;;
        *)
          AGENT="iris"; ACTION="analyze-social"; ROOM="creative"
          DETAIL="TikTok content analysis"
          ;;
      esac
      ;;

    # ── Shopee / Lazada ──
    *shopee.*|*lazada.*)
      TYPE="product-listing"
      AGENT="hermes"; ACTION="analyze-product"; ROOM="exec"
      DETAIL="Product pricing, reviews, competitor analysis"
      ;;

    # ── Google Drive ──
    *drive.google.com*|*docs.google.com*)
      TYPE="google-drive"
      case "$INTENT" in
        analyze)
          AGENT="athena"; ACTION="analyze-data"; ROOM="exec"
          DETAIL="Extract and analyze data from Google Drive"
          ;;
        *)
          AGENT="artemis"; ACTION="extract-document"; ROOM="exec"
          DETAIL="Read and summarize Google Drive document"
          ;;
      esac
      ;;

    # ── Google Sheets ──
    *sheets.google.com*)
      TYPE="google-sheets"
      AGENT="athena"; ACTION="analyze-data"; ROOM="exec"
      DETAIL="Extract and analyze spreadsheet data"
      ;;

    # ── Twitter/X ──
    *twitter.com*|*x.com*)
      TYPE="twitter"
      AGENT="iris"; ACTION="analyze-social"; ROOM="creative"
      DETAIL="Social post analysis"
      ;;

    # ── General article/website ──
    *)
      TYPE="website"
      case "$INTENT" in
        research)
          AGENT="artemis"; ACTION="research-url"; ROOM="exec"
          DETAIL="Deep research on this URL"
          ;;
        inspire)
          AGENT="dreami"; ACTION="creative-brief-from-ref"; ROOM="creative"
          DETAIL="Creative inspiration from this reference"
          ;;
        fix)
          AGENT="taoz"; ACTION="debug-url"; ROOM="build"
          DETAIL="Investigate and fix issue with this URL"
          ;;
        *)
          AGENT="artemis"; ACTION="summarize-url"; ROOM="exec"
          DETAIL="Read, summarize, and extract key insights"
          ;;
      esac
      ;;
  esac

# === File detection (by extension) ===
elif echo "$INPUT_LOWER" | grep -qE '\.(png|jpg|jpeg|gif|webp|svg|heic)$'; then
  TYPE="image"
  case "$INTENT" in
    fix)
      AGENT="iris"; ACTION="visual-qa-then-taoz"; ROOM="creative"
      DETAIL="Iris analyzes the image, then routes fix to Taoz if code issue"
      ;;
    review)
      AGENT="iris"; ACTION="visual-qa"; ROOM="creative"
      DETAIL="Design review and visual QA"
      ;;
    inspire|reverse-prompt)
      AGENT="iris"; ACTION="reverse-prompt-image"; ROOM="creative"
      DETAIL="Reverse prompt and style extraction"
      ;;
    *)
      AGENT="iris"; ACTION="analyze-image"; ROOM="creative"
      DETAIL="Visual analysis (Zenni cannot see images)"
      ;;
  esac

elif echo "$INPUT_LOWER" | grep -qE '\.(mp4|mov|avi|mkv|webm)$'; then
  TYPE="video-file"
  case "$INTENT" in
    reverse-prompt)
      AGENT="iris"; ACTION="reverse-prompt-video"; ROOM="creative"
      DETAIL="Analyze video style, extract visual prompts"
      ;;
    *)
      AGENT="iris"; ACTION="analyze-video"; ROOM="creative"
      DETAIL="Video content analysis"
      ;;
  esac

elif echo "$INPUT_LOWER" | grep -qE '\.(mp3|wav|ogg|m4a|opus|voice)$'; then
  TYPE="audio"
  AGENT="myrmidons"; ACTION="transcribe-then-reclassify"; ROOM="exec"
  DETAIL="Transcribe with WhisperX, then re-classify the text"

elif echo "$INPUT_LOWER" | grep -qE '\.(pdf)$'; then
  TYPE="pdf"
  case "$INTENT" in
    analyze)
      AGENT="athena"; ACTION="analyze-document"; ROOM="exec"
      DETAIL="Deep analysis of PDF content"
      ;;
    *)
      AGENT="artemis"; ACTION="summarize-document"; ROOM="exec"
      DETAIL="Read and summarize PDF"
      ;;
  esac

elif echo "$INPUT_LOWER" | grep -qE '\.(csv|xlsx|xls|tsv)$'; then
  TYPE="spreadsheet"
  AGENT="athena"; ACTION="analyze-data"; ROOM="exec"
  DETAIL="Data analysis and pattern extraction"

elif echo "$INPUT_LOWER" | grep -qE '\.(doc|docx|txt|md|rtf)$'; then
  TYPE="document"
  AGENT="artemis"; ACTION="summarize-document"; ROOM="exec"
  DETAIL="Read and summarize document"

elif echo "$INPUT_LOWER" | grep -qE '\.(json|jsonl|yaml|yml|toml)$'; then
  TYPE="config-data"
  case "$INTENT" in
    fix)
      AGENT="taoz"; ACTION="fix-config"; ROOM="build"
      DETAIL="Fix configuration file"
      ;;
    *)
      AGENT="myrmidons"; ACTION="read-config"; ROOM="exec"
      DETAIL="Read and report config contents"
      ;;
  esac

else
  # Plain text or unknown — treat as text message
  TYPE="text"
  AGENT="zenni"
  ACTION="process-text"
  ROOM="exec"
  DETAIL="Process as normal text message"
fi

# ── Output JSON ──────────────────────────────────────────────────────────────
python3 -c "
import json
print(json.dumps({
    'type': '$TYPE',
    'intent': '$INTENT',
    'agent': '$AGENT',
    'action': '$ACTION',
    'room': '$ROOM',
    'detail': '$DETAIL',
    'input': '$INPUT'
}, indent=2))
"
