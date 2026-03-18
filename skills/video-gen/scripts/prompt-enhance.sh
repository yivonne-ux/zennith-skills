#!/usr/bin/env bash
# prompt-enhance.sh — Enhance prompt with PAS + trending formats + hooks
# Usage: bash prompt-enhance.sh <visual_dna.json> [base_prompt] [--brand <brand_slug>]
#
# Enhances base prompt with:
# - PAS formula (Problem, Amplify, Solution)
# - Trending hooks and formats
# - Brand DNA (if brand specified)
# - Brand voice (if brand specified)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$HOME/.openclaw/.env"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
  while IFS= read -r line; do
    case "$line" in
      ""|\#*) continue ;;
      *=*) export "$line" ;;
    esac
  done < "$ENV_FILE"
fi

# Load brand DNA (if brand specified)
load_brand_dna() {
  local brand="$1"
  local dna_file="$HOME/.openclaw/brands/$brand/DNA.json"

  if [ -f "$dna_file" ]; then
    local motion_tone colors_vibe

    motion_tone=$(python3 << EOF
import json
d = json.load(open('$dna_file'))
ml = d.get('motion_language', {})
if isinstance(ml, dict):
    parts = []
    if ml.get('vibe'): parts.append('Vibe: ' + ml['vibe'])
    if ml.get('motion'): parts.append('Motion: ' + ml['motion'])
    if ml.get('audio'): parts.append('Audio cues: ' + ml['audio'])
    print(' | '.join(parts))
elif isinstance(ml, str) and ml:
    print(ml)
EOF
)
    echo "$motion_tone"
  fi
}

load_brand_color() {
  local brand="$1"
  local dna_file="$HOME/.openclaw/brands/$brand/DNA.json"

  if [ -f "$dna_file" ]; then
    python3 << EOF
import json
d = json.load(open('$dna_file'))
v = d.get('visual', d.get('visual_identity', {}))
colors = v.get('colors', {})
if colors:
    parts = []
    for k, c in colors.items():
        parts.append(k + ':' + str(c))
    print(', '.join(parts))
EOF
  fi
}

load_brand_tone() {
  local brand="$1"
  local dna_file="$HOME/.openclaw/brands/$brand/DNA.json"

  if [ -f "$dna_file" ]; then
    python3 << EOF
import json
d = json.load(open('$dna_file'))
voice = d.get('voice', {})
tone = voice.get('tone', '')
if tone:
    print(tone)
EOF
  fi
}

# Parse arguments
VISUAL_DNA="${1:-}"
BASE_PROMPT="${2:-}"
BRAND="${3:-}"

if [ -z "$VISUAL_DNA" ]; then
  echo "ERROR: Visual DNA JSON file required"
  echo "Usage: bash prompt-enhance.sh <visual_dna.json> [base_prompt] [--brand <brand_slug>]"
  exit 1
fi

if [ ! -f "$VISUAL_DNA" ]; then
  echo "ERROR: Visual DNA file not found: $VISUAL_DNA"
  exit 1
fi

# Load visual DNA
if command -v jq >/dev/null 2>&1; then
  VISUAL_MAIN_IMAGE=$(jq -r '.main_image // empty' "$VISUAL_DNA")
  VISUAL_DESCRIPTION=$(jq -r '.visual_dna.scene_description // empty' "$VISUAL_DNA")
  VISUAL_PALETTE=$(jq -r '.visual_dna.color_palette // empty' "$VISUAL_DNA")
  VISUAL_LIGHTING=$(jq -r '.visual_dna.lighting // empty' "$VISUAL_DNA")
  VISUAL_ANGLE=$(jq -r '.visual_dna.camera_angle // empty' "$VISUAL_DNA")
  VISUAL_STYLE=$(jq -r '.visual_dna.style // empty' "$VISUAL_DNA")
  VISUAL_MOOD=$(jq -r '.visual_dna.mood // empty' "$VISUAL_DNA")
  VISUAL_VIBE=$(jq -r '.visual_dna.vibe // empty' "$VISUAL_DNA")

  PROMPT_HOOKS=$(jq -c '.hooks[]' "$VISUAL_DNA")
  PROMPT_FORMATS=$(jq -c '.trending_formats[]' "$VISUAL_DNA")
  PROMPT_TONES=$(jq -c '.trending_tones[]' "$VISUAL_DNA")
  PROMPT_PAS=$(jq -c '.passing_lenses[]' "$VISUAL_DNA")

  PROMPT_INTENT=$(jq -r '.suggested_prompts.intent // empty' "$VISUAL_DNA")
  PROMPT_OUTPUT=$(jq -r '.suggested_prompts.output // empty' "$VISUAL_DNA")
  PROMPT_CAMPAIGN=$(jq -r '.suggested_prompts.campaign // empty' "$VISUAL_DNA")
  PROMPT_BRIEF=$(jq -r '.suggested_prompts.brief // empty' "$VISUAL_DNA")
else
  echo "ERROR: jq required for JSON parsing"
  exit 1
fi

# Enhance prompt
enhanced_prompt="$BASE_PROMPT"

# Add PAS if provided
if [ -n "$PROMPT_PAS" ]; then
  PAS_SUMMARY="Context: PASSING LENSES (Problem, Amplify, Solution). Use PAS formula to structure the prompt. "
  PAS_LINES=0
  echo "$PROMPT_PAS" | while IFS= read -r pas; do
    if [ -n "$pas" ]; then
      if [ $PAS_LINES -eq 0 ]; then
        PAS_SUMMARY="${PAS_SUMMARY}Problem: $pas"
      elif [ $PAS_LINES -eq 1 ]; then
        PAS_SUMMARY="${PAS_SUMMARY} | Amplify: $pas"
      else
        PAS_SUMMARY="${PAS_SUMMARY} | Solution: $pas"
      fi
      PAS_LINES=$((PAS_LINES + 1))
    fi
  done
  enhanced_prompt="${enhanced_prompt}. ${PAS_SUMMARY}"
fi

# Add trending hooks
if [ -n "$PROMPT_HOOKS" ]; then
  HOOK_SUMMARY="Viral Hooks: "
  IFS=$'\n'
  for hook in $PROMPT_HOOKS; do
    if [ -n "$hook" ]; then
      if [ -n "$HOOK_SUMMARY" ]; then
        HOOK_SUMMARY="${HOOK_SUMMARY}"
      fi
      HOOK_SUMMARY="${HOOK_SUMMARY}${hook}"
    fi
  done
  enhanced_prompt="${enhanced_prompt}. ${HOOK_SUMMARY}"
fi

# Add trending formats
if [ -n "$PROMPT_FORMATS" ]; then
  FORMAT_SUMMARY="Trending Formats: "
  IFS=$'\n'
  for fmt in $PROMPT_FORMATS; do
    if [ -n "$fmt" ]; then
      if [ -n "$FORMAT_SUMMARY" ]; then
        FORMAT_SUMMARY="${FORMAT_SUMMARY}, "
      fi
      FORMAT_SUMMARY="${FORMAT_SUMMARY}${fmt}"
    fi
  done
  enhanced_prompt="${enhanced_prompt}. ${FORMAT_SUMMARY}"
fi

# Add trending tones
if [ -n "$PROMPT_TONES" ]; then
  TONE_SUMMARY="Current Tone Trends: "
  IFS=$'\n'
  for tone in $PROMPT_TONES; do
    if [ -n "$tone" ]; then
      if [ -n "$TONE_SUMMARY" ]; then
        TONE_SUMMARY="${TONE_SUMMARY}, "
      fi
      TONE_SUMMARY="${TONE_SUMMARY}${tone}"
    fi
  done
  enhanced_prompt="${enhanced_prompt}. ${TONE_SUMMARY}"
fi

# Add visual DNA details
if [ -n "$VISUAL_DESCRIPTION" ]; then
  enhanced_prompt="${enhanced_prompt}. Visual: ${VISUAL_DESCRIPTION}"
fi
if [ -n "$VISUAL_PALETTE" ]; then
  enhanced_prompt="${enhanced_prompt}. Colors: ${VISUAL_PALETTE}"
fi
if [ -n "$VISUAL_LIGHTING" ]; then
  enhanced_prompt="${enhanced_prompt}. Lighting: ${VISUAL_LIGHTING}"
fi
if [ -n "$VISUAL_ANGLE" ]; then
  enhanced_prompt="${enhanced_prompt}. Camera Angle: ${VISUAL_ANGLE}"
fi
if [ -n "$VISUAL_STYLE" ]; then
  enhanced_prompt="${enhanced_prompt}. Style: ${VISUAL_STYLE}"
fi
if [ -n "$VISUAL_MOOD" ]; then
  enhanced_prompt="${enhanced_prompt}. Mood: ${VISUAL_MOOD}"
fi
if [ -n "$VISUAL_VIBE" ]; then
  enhanced_prompt="${enhanced_prompt}. Vibe: ${VISUAL_VIBE}"
fi

# Load and add brand DNA if brand specified
if [ -n "$BRAND" ]; then
  BRAND_MOTION=$(load_brand_dna "$BRAND")
  BRAND_COLORS=$(load_brand_color "$BRAND")
  BRAND_TONE=$(load_brand_tone "$BRAND")

  if [ -n "$BRAND_MOTION" ]; then
    enhanced_prompt="${enhanced_prompt}. Brand Motion: ${BRAND_MOTION}"
  fi
  if [ -n "$BRAND_COLORS" ]; then
    enhanced_prompt="${enhanced_prompt}. Brand Colors: ${BRAND_COLORS}"
  fi
  if [ -n "$BRAND_TONE" ]; then
    enhanced_prompt="${enhanced_prompt}. Brand Voice: ${BRAND_TONE}"
  fi
fi

# Output enhanced prompt
echo "=== Enhanced Prompt ==="
echo ""
echo "Base Prompt: ${BASE_PROMPT:-<none>}"
echo ""
echo "Enhanced Prompt:"
echo "$enhanced_prompt"
echo ""
echo ""

# Save to file
OUTPUT_FILE="${VISUAL_DNA%.json}-enhanced.txt"
echo "$enhanced_prompt" > "$OUTPUT_FILE"

echo "Enhanced prompt saved to: $OUTPUT_FILE"
echo ""
echo "Use this for video generation:"
echo "  video-gen.sh sora-ugc --prompt \"\$(cat $OUTPUT_FILE)\" --brand $BRAND"

exit 0