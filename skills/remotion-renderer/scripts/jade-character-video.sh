#!/usr/bin/env bash
# jade-character-video.sh — Face-Locked Jade Video Pipeline
# ALWAYS uses image-to-video with locked face refs. NEVER text-to-video.
#
# Pipeline:
#   1. Load character-lock spec + face refs
#   2. Generate scene image via NanoBanana (with face refs)
#   3. Generate video via Kling/Seedance IMAGE-TO-VIDEO (face anchored)
#   4. Post-prod via video-forge
#
# Usage:
#   jade-character-video.sh --scene "reading oracle cards at café" [--provider kling]
#   jade-character-video.sh --scene "morning journaling" --provider seedance

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW="$HOME/.openclaw"
BRANDS_DIR="$OPENCLAW/brands"
CHAR_LOCK="$OPENCLAW/skills/character-lock/scripts/character-lock.sh"
NANOBANANA="$OPENCLAW/skills/nanobanana/scripts/nanobanana-gen.sh"
VIDEO_GEN="$OPENCLAW/skills/video-gen/scripts/video-gen.sh"
VIDEO_FORGE="$OPENCLAW/skills/video-forge/scripts/video-forge.sh"
OUTPUT_DIR="$OPENCLAW/workspace/data/productions/jade-oracle/$(date +%Y-%m-%d)"
LOG_FILE="$OPENCLAW/logs/jade-character-video.log"

BRAND="jade-oracle"
CHARACTER="jade"
SCENE=""
PROVIDER="kling"
DURATION=5
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scene)    SCENE="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$SCENE" ]] && { echo "ERROR: --scene required (e.g., 'reading oracle cards at café')"; exit 1; }

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date +%H%M%S)

log() { echo "[jade-vid $TIMESTAMP] $1" | tee -a "$LOG_FILE"; }

echo "╔══════════════════════════════════════════════════╗"
echo "║  JADE CHARACTER VIDEO — Face-Locked Pipeline     ║"
echo "║  Scene: ${SCENE:0:45}                            ║"
echo "║  Provider: $PROVIDER | Duration: ${DURATION}s    ║"
echo "╚══════════════════════════════════════════════════╝"

# ── STEP 1: Load character lock ──
echo ""
echo "━━━ STEP 1: CHARACTER LOCK ━━━"

if [[ ! -f "$CHAR_LOCK" ]]; then
  echo "ERROR: character-lock.sh not found at $CHAR_LOCK"
  exit 1
fi

# Load spec
bash "$CHAR_LOCK" load --brand "$BRAND" --character "$CHARACTER"

# Get prompt suffix
PROMPT_SUFFIX=$(bash "$CHAR_LOCK" load --brand "$BRAND" --character "$CHARACTER" --json 2>/dev/null | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('rules',{}).get('prompt_suffix',''))" 2>/dev/null) || true

# Get face refs
FACE_REFS=$(bash "$CHAR_LOCK" refs --brand "$BRAND" --character "$CHARACTER" 2>/dev/null) || true

if [[ -z "$FACE_REFS" ]]; then
  echo "❌ ERROR: No locked face refs found. Cannot generate face-locked video."
  echo "   Fix: Add face refs to ~/.openclaw/brands/jade-oracle/characters/jade/locked/faces/"
  echo "   Or check: character-lock.sh refs --brand jade-oracle --character jade"
  exit 1
fi

FACE_COUNT=$(echo "$FACE_REFS" | tr ',' '\n' | wc -l | tr -d ' ')
echo "  🔒 Face-lock: $FACE_COUNT refs loaded"
echo "  🔒 Suffix: ${PROMPT_SUFFIX:0:60}..."

# Validate the scene prompt
echo ""
echo "━━━ STEP 2: VALIDATE PROMPT ━━━"
FULL_PROMPT="$SCENE. $PROMPT_SUFFIX"
bash "$CHAR_LOCK" validate --brand "$BRAND" --character "$CHARACTER" --prompt "$FULL_PROMPT" || {
  echo "❌ Prompt validation FAILED. Fix the prompt and retry."
  exit 1
}

# ── STEP 3: Generate scene image with face refs ──
echo ""
echo "━━━ STEP 3: SCENE IMAGE (NanoBanana + face refs) ━━━"
SCENE_IMAGE="$OUTPUT_DIR/scene-${TIMESTAMP}.png"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  [dry-run] Would generate scene image with face refs"
  # Use the primary face ref as fallback for dry-run
  SCENE_IMAGE=$(echo "$FACE_REFS" | tr ',' '\n' | head -1)
  echo "  Using primary face ref: $(basename "$SCENE_IMAGE")"
else
  if [[ -f "$NANOBANANA" ]]; then
    log "Generating face-locked scene image..."
    NB_OUTPUT=$(bash "$NANOBANANA" generate --brand "$BRAND" \
      --prompt "$FULL_PROMPT" \
      --ref-image "$FACE_REFS" \
      --use-case character 2>&1) || true

    GENERATED=$(echo "$NB_OUTPUT" | grep -oE '/[^ ]+\.png' | tail -1)
    if [[ -n "$GENERATED" && -f "$GENERATED" ]]; then
      cp "$GENERATED" "$SCENE_IMAGE"
      echo "  ✅ Scene image: $SCENE_IMAGE ($(du -h "$SCENE_IMAGE" | cut -f1))"
    else
      echo "  ⚠️  NanoBanana failed — using primary face ref as input"
      SCENE_IMAGE=$(echo "$FACE_REFS" | tr ',' '\n' | head -1)
      echo "  Using: $(basename "$SCENE_IMAGE")"
    fi
  else
    echo "  ⚠️  NanoBanana not found — using primary face ref as input"
    SCENE_IMAGE=$(echo "$FACE_REFS" | tr ',' '\n' | head -1)
  fi
fi

# ── STEP 4: Generate video (IMAGE-TO-VIDEO, face locked) ──
echo ""
echo "━━━ STEP 4: VIDEO GENERATION (${PROVIDER} i2v, face-locked) ━━━"
VIDEO_OUTPUT="$OUTPUT_DIR/jade-video-${TIMESTAMP}.mp4"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  [dry-run] Would generate ${DURATION}s video via $PROVIDER image2video"
  echo "  Input image: $(basename "$SCENE_IMAGE")"
  echo "  Prompt: ${FULL_PROMPT:0:80}..."
else
  echo "  🔒 Input image: $(basename "$SCENE_IMAGE") (face anchored)"
  echo "  Provider: $PROVIDER | Duration: ${DURATION}s"

  if [[ -f "$VIDEO_GEN" ]]; then
    bash "$VIDEO_GEN" "$PROVIDER" image2video \
      --image "$SCENE_IMAGE" \
      --prompt "$FULL_PROMPT" \
      --duration "$DURATION" \
      --aspect-ratio 9:16 \
      --output "$VIDEO_OUTPUT" \
      --brand "$BRAND" 2>&1 | sed 's/^/  /'

    if [[ -f "$VIDEO_OUTPUT" ]]; then
      echo "  ✅ Video: $VIDEO_OUTPUT ($(du -h "$VIDEO_OUTPUT" | cut -f1))"
    else
      echo "  ❌ Video generation failed"
      exit 1
    fi
  else
    echo "  ❌ video-gen.sh not found"
    exit 1
  fi
fi

# ── STEP 5: Post-production ──
echo ""
echo "━━━ STEP 5: POST-PRODUCTION ━━━"
FINAL_OUTPUT="$OUTPUT_DIR/jade-final-${TIMESTAMP}.mp4"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  [dry-run] Would apply grain + vignette + brand overlay"
elif [[ -f "$VIDEO_OUTPUT" && -f "$VIDEO_FORGE" ]]; then
  bash "$VIDEO_FORGE" effects "$VIDEO_OUTPUT" --grain light --vignette 2>&1 | sed 's/^/  /' || true

  # Find the effects output
  EFFECTED=$(find "$(dirname "$VIDEO_OUTPUT")" -name "*effects*" -newer "$VIDEO_OUTPUT" 2>/dev/null | head -1)
  if [[ -n "$EFFECTED" && -f "$EFFECTED" ]]; then
    mv "$EFFECTED" "$FINAL_OUTPUT"
    echo "  ✅ Final: $FINAL_OUTPUT ($(du -h "$FINAL_OUTPUT" | cut -f1))"
  else
    cp "$VIDEO_OUTPUT" "$FINAL_OUTPUT"
    echo "  ⚠️  Effects may not have applied, using raw video"
  fi
else
  echo "  ⚠️  Skipped (no video or video-forge not found)"
fi

echo ""
echo "━━━ COMPLETE ━━━"
echo "  📹 Output: ${FINAL_OUTPUT:-$VIDEO_OUTPUT}"
echo "  🔒 Face: LOCKED (${FACE_COUNT} refs used)"
echo "  Pipeline: character-lock → NanoBanana (face refs) → ${PROVIDER} i2v → video-forge"
