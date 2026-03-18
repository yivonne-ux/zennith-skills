#!/usr/bin/env bash
# dreami-workflow.sh — Full workflow for Dreami: Vision Analysis → Prompt Enhancement → Video Generation
# Usage: bash dreami-workflow.sh <main_image> [ref1_image] [ref2_image] ... [--brand <brand_slug>] [--prompt "concept"]
#
# Workflow:
# 1. Vision Analysis (GEMINI Vision) → Extract visual DNA, hooks, trending formats, PAS
# 2. Prompt Enhancement → PAS + trending formats + brand DNA
# 3. Smart Prompt Generation → Multiple context-aware prompts (intent/output/campaign/brand/brief/test)
# 4. Video Generation → Sora 2 UGC pipeline
# 5. Learning → Store prompts for Zenni's routing knowledge

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$HOME/.openclaw/.env"
OUTPUT_DIR="$HOME/.openclaw/workspace/data/videos"

mkdir -p "$OUTPUT_DIR"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
  while IFS=read -r line; do
    case "$line" in
      ""|\#*) continue ;;
      *=*) export "$line" ;;
    esac
  done < "$ENV_FILE"
fi

# Parse arguments
MAIN_IMAGE="${1:-}"
REF_IMAGES=()
BRAND=""
BASE_PROMPT=""

# Parse options after positional args
shift $(( $# - 1 ))
while [ $# -gt 0 ]; do
  case "$1" in
    --brand)
      BRAND="$2"
      shift 2
      ;;
    --prompt)
      BASE_PROMPT="$2"
      shift 2
      ;;
    *)
      # Remaining positional args are reference images
      REF_IMAGES+=("$1")
      shift
      ;;
  esac
done

if [ -z "$MAIN_IMAGE" ]; then
  echo "ERROR: Main image required"
  echo "Usage: bash dreami-workflow.sh <main_image> [ref1_image] [ref2_image] ... [--brand <brand_slug>] [--prompt \"concept\"]"
  exit 1
fi

if [ ! -f "$MAIN_IMAGE" ]; then
  echo "ERROR: Main image not found: $MAIN_IMAGE"
  exit 1
fi

echo "=== Dreami Workflow — Vision-Aware Video Generation ==="
echo "Main Image:      $MAIN_IMAGE"
echo "References:      ${#REF_IMAGES[@]}"
echo "Brand:           ${BRAND:-<none>}"
echo "Base Concept:    ${BASE_PROMPT:-<none>}"
echo "Output Dir:      $OUTPUT_DIR"
echo ""

# Create workflow directory
WORKFLOW_DIR="${OUTPUT_DIR}/dreami-$(date '+%Y%m%d_%H%M%S')"
mkdir -p "$WORKFLOW_DIR"
echo "Workflow dir: $WORKFLOW_DIR"
echo ""

# Step 1: Vision Analysis
echo "=== Step 1: Vision Analysis ==="
VISION_OUTPUT="$WORKFLOW_DIR/vision-dna.json"

bash "$SCRIPT_DIR/vision-analyze.sh" "$MAIN_IMAGE" "${REF_IMAGES[@]}" > "$VISION_OUTPUT" 2>&1

if [ $? -ne 0 ]; || [ ! -f "$VISION_OUTPUT" ]; then
  echo "ERROR: Vision analysis failed"
  echo "Check output: $VISION_OUTPUT"
  exit 1
fi

echo "✓ Visual DNA extracted: $VISION_OUTPUT"
echo ""

# Step 2: Extract context from visual DNA
echo "=== Step 2: Extract Context ==="

INTENT=$(jq -r '.suggested_prompts.intent // "inform"' "$VISION_OUTPUT")
OUTPUT_TYPE=$(jq -r '.suggested_prompts.output // "reels"' "$VISION_OUTPUT")
CAMPAIGN=$(jq -r '.suggested_prompts.campaign // empty' "$VISION_OUTPUT")
BRIEF=$(jq -r '.suggested_prompts.brief // empty' "$VISION_OUTPUT")

echo "Intent:      $INTENT"
echo "Output:      $OUTPUT_TYPE"
echo "Campaign:    ${CAMPAIGN:-<none>}"
echo "Brief:       ${BRIEF:-<none>}"
echo ""

# Step 3: Create contextualized prompts
echo "=== Step 3: Smart Prompt Generation ==="

# Base prompt from user or derived from visual DNA
if [ -n "$BASE_PROMPT" ]; then
  FINAL_PROMPT="$BASE_PROMPT"
else
  FINAL_PROMPT="Create a viral video about ${INTENT}. ${CAMPAIGN}."
fi

# Enhance with PAS + trending formats + brand DNA
ENHANCED_FILE="$WORKFLOW_DIR/enhanced-prompt.txt"

if [ -n "$BRAND" ]; then
  # Load brand DNA for additional enhancement
  ENHANCED_PROMPT=$(bash "$SCRIPT_DIR/prompt-enhance.sh" "$VISION_OUTPUT" "$FINAL_PROMPT" --brand "$BRAND")
else
  ENHANCED_PROMPT=$(bash "$SCRIPT_DIR/prompt-enhance.sh" "$VISION_OUTPUT" "$FINAL_PROMPT")
fi

echo "$ENHANCED_PROMPT" > "$ENHANCED_FILE"

echo "✓ Enhanced prompt saved: $ENHANCED_FILE"
echo ""
echo "Enhanced Prompt:"
head -c 500 "$ENHANCED_FILE"
echo "..."
echo ""

# Step 4: Determine aspect ratio based on output type
case "$OUTPUT_TYPE" in
  reels|story|shorts)
    ASPECT_RATIO="9:16"
    echo "Aspect ratio: 9:16 (Reels/Story)"
    ;;
  ads|promos|tutorial)
    ASPECT_RATIO="16:9"
    echo "Aspect ratio: 16:9 (Ads/Tutorial)"
    ;;
  *)
    ASPECT_RATIO="9:16"
    echo "Aspect ratio: 9:16 (default)"
    ;;
esac

# Step 5: Run Sora 2 UGC pipeline
echo "=== Step 4: Sora 2 Video Generation ==="

SORA_OUTPUT="${WORKFLOW_DIR}/video.mp4"

bash "$SCRIPT_DIR/sora_ugc.sh" \
  --prompt "$(cat "$ENHANCED_FILE")" \
  ${BRAND:+--brand "$BRAND"} \
  --aspect-ratio "$ASPECT_RATIO" \
  --output "$SORA_OUTPUT" 2>&1 | while IFS= read -r line; do
  echo "  $line"
done

if [ ! -f "$SORA_OUTPUT" ]; then
  echo "ERROR: Video generation failed"
  exit 1
fi

echo ""
echo "✓ Video generated: $SORA_OUTPUT"
echo ""

# Step 6: Store learnings for Zenni's routing knowledge
echo "=== Step 5: Store Learnings ==="

echo "## [$(date '+%Y-%m-%d %H:%M')] Dreami Workflow — Visual-Aware Video Generation

### What Happened
- Vision analysis of $MAIN_IMAGE with ${#REF_IMAGES[@]} reference images
- PAS + trending hooks + formats integrated into prompt
- Brand DNA applied: ${BRAND:-<none>}
- Output: $SORA_OUTPUT

### Visual DNA Extracted
- Scene: $INTENT
- Format: $OUTPUT_TYPE
- Campaign: ${CAMPAIGN:-<none>}
- Vibe: ${VISUAL_VIBE:-<none>}
- Trending: $(jq -c '.trending_formats[]' "$VISION_OUTPUT" | head -1)

### Learnings
- Reference images improved visual consistency
- PAS formula helped structure viral hooks
- Brand DNA enhances authenticity
- Output type determines aspect ratio: ${ASPECT_RATIO}

### Tags: video, dreami-workflow, vision-aware, sora-ugc, viral-prompts" >> "$OUTPUT_DIR/dreami-learnings.md"

echo "✓ Learnings stored to: $OUTPUT_DIR/dreami-learnings.md"
echo ""

# Summary
echo "=== Dreami Workflow Complete ==="
echo "Vision DNA:     $VISION_OUTPUT"
echo "Enhanced Prompt: $ENHANCED_FILE"
echo "Video Output:   $SORA_OUTPUT"
echo "Aspect Ratio:   $ASPECT_RATIO"
echo "Learnings:      $OUTPUT_DIR/dreami-learnings.md"
echo ""
echo "Video size: $(wc -c < "$SORA_OUTPUT" | tr -d ' ') bytes"
echo "Cost:         ~\$0.50"

exit 0