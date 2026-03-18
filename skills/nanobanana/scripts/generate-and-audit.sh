#!/usr/bin/env bash
# generate-and-audit.sh — Full pipeline: Generate → Audit → Register → Notify
# Wraps nanobanana-gen.sh with post-generation steps
# Called by classify.sh SCRIPT tier or directly
# macOS Bash 3.2 compatible

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
NANOBANANA="$OPENCLAW_DIR/skills/nanobanana/scripts/nanobanana-gen.sh"
NOTION_REVIEW="$OPENCLAW_DIR/skills/notion-sync/scripts/notion-creative-review.sh"
VISUAL_REGISTRY="$OPENCLAW_DIR/skills/visual-registry/scripts/visual-registry.sh"
BRAND_VOICE="$OPENCLAW_DIR/skills/brand-consistency/scripts/brand-voice-check.sh"
LOG_FILE="$OPENCLAW_DIR/logs/generate-and-audit.log"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"

log() { mkdir -p "$(dirname "$LOG_FILE")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# Pass ALL arguments through to nanobanana-gen.sh
# Then run post-generation steps on the result

echo "=== GAIA Generate + Audit Pipeline ==="

# Step 1: Generate with NanoBanana (pass all args through)
log "Starting generation: $*"
GEN_OUTPUT=$(bash "$NANOBANANA" generate "$@" 2>&1)
GEN_EXIT=$?

echo "$GEN_OUTPUT"

if [ "$GEN_EXIT" -ne 0 ]; then
    log "Generation FAILED: exit=$GEN_EXIT"
    echo ""
    echo "PIPELINE: Generation failed. No audit performed."
    exit "$GEN_EXIT"
fi

# Extract the generated image path
# Try: line starting with /, or "Output: /path" format from nanobanana-gen.sh
IMAGE_PATH=$(echo "$GEN_OUTPUT" | grep "^/" | tail -1)
if [ -z "$IMAGE_PATH" ] || [ ! -f "$IMAGE_PATH" ]; then
    # Fallback: extract from "Output:   /path/to/file" line
    IMAGE_PATH=$(echo "$GEN_OUTPUT" | grep -o '  Output: */.*.png' | sed 's/.*Output: *//' | tail -1)
fi

if [ -z "$IMAGE_PATH" ] || [ ! -f "$IMAGE_PATH" ]; then
    log "No image path found in output"
    echo ""
    echo "PIPELINE: Could not find generated image. Skipping audit."
    exit 0
fi

log "Image generated: $IMAGE_PATH"
echo ""
echo "=== Post-Generation Pipeline ==="

# Extract args for post-pipeline registration
BRAND=""
USE_CASE=""
PROMPT=""
REF_IMAGES=""
FUNNEL=""
BATCH="auto-$(date +%Y%m%d)"
AGENT_NAME="iris"

while [ $# -gt 0 ]; do
    case "$1" in
        --brand)       BRAND="$2";      shift 2 ;;
        --use-case)    USE_CASE="$2";   shift 2 ;;
        --prompt)      PROMPT="$2";     shift 2 ;;
        --ref-image)   REF_IMAGES="$2"; shift 2 ;;
        --funnel-stage) FUNNEL="$2";    shift 2 ;;
        *) shift ;;
    esac
done

# Also extract ref images from generation output
if [ -z "$REF_IMAGES" ]; then
    REF_IMAGES=$(echo "$GEN_OUTPUT" | grep "Ref image:" | sed 's/.*Ref image: *//' | head -1)
fi

# Map use-case to funnel if not set
if [ -z "$FUNNEL" ]; then
    case "$USE_CASE" in
        sales-boom|urgency|raw|price) FUNNEL="BOFU" ;;
        *) FUNNEL="MOFU" ;;
    esac
fi

PIPELINE="classify -> smartref -> nanobanana-flash -> audit -> notion"

# Step 2: Quick Audit
echo "  [AUDIT] Checking image..."
AUDIT_PASS="true"
AUDIT_NOTES=""

# Check file size (should be >100KB for real image)
FILE_SIZE=$(wc -c < "$IMAGE_PATH" | tr -d ' ')
FILE_SIZE_KB=$((FILE_SIZE / 1024))
if [ "$FILE_SIZE_KB" -lt 100 ]; then
    AUDIT_PASS="false"
    AUDIT_NOTES="File too small (${FILE_SIZE_KB}KB) — likely corrupted or empty"
    echo "    FAIL: File too small (${FILE_SIZE_KB}KB)"
else
    echo "    OK: File size ${FILE_SIZE_KB}KB"
fi

# Check dimensions via sips
DIMS=$(sips --getProperty pixelWidth --getProperty pixelHeight "$IMAGE_PATH" 2>/dev/null | grep "pixel" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
if [ -n "$DIMS" ]; then
    echo "    OK: Dimensions $DIMS"
else
    echo "    WARN: Could not read dimensions"
fi

# Step 2b: Vision-based audit (if visual-audit.sh exists)
VISUAL_AUDIT="$OPENCLAW_DIR/skills/nanobanana/scripts/visual-audit.sh"
if [ -x "$VISUAL_AUDIT" ] && [ -n "$BRAND" ] && [ -n "$USE_CASE" ]; then
    echo "  [VISION] Running visual audit..."
    # Build refs list from the generation output (look for ref-image paths)
    USED_REFS=$(echo "$GEN_OUTPUT" | grep "Ref image:" | sed 's/.*Ref image: //' | head -1)
    VISION_OUT=$(bash "$VISUAL_AUDIT" check \
        --image "$IMAGE_PATH" \
        --refs "${USED_REFS:-}" \
        --brand "${BRAND:-unknown}" \
        --use-case "${USE_CASE:-product}" \
        --prompt "${PROMPT:-}" 2>&1) || true
    echo "$VISION_OUT" | grep -E "^  " | head -10
    # Check if vision audit found issues
    if echo "$VISION_OUT" | grep -q "FAIL"; then
        AUDIT_PASS="false"
        AUDIT_NOTES="${AUDIT_NOTES} Vision audit FAILED."
    elif echo "$VISION_OUT" | grep -q "WARN"; then
        echo "    WARN: Vision audit flagged issues (see report)"
    fi
fi

# Step 3: Register in Notion with full context (prompt, refs, pipeline, Drive links)
if [ -x "$NOTION_REVIEW" ]; then
    echo "  [NOTION] Registering with full context..."
    local_name="$(echo "$BRAND" | tr 'a-z' 'A-Z') ${USE_CASE} - $(date '+%H:%M')"

    # Build notion args with all available context
    NOTION_ARGS=(
        --name "$local_name"
        --use-case "${USE_CASE:-product}"
        --brand "${BRAND:-mirra}"
        --agent "$AGENT_NAME"
        --model "nanobanana-flash"
        --batch "$BATCH"
        --tags "${USE_CASE:-ad-creative}"
        --image-path "$IMAGE_PATH"
        --ad-type "${USE_CASE:-product}"
        --funnel "${FUNNEL:-MOFU}"
        --pipeline "$PIPELINE"
    )

    # Add prompt if available (truncate for Notion)
    if [ -n "$PROMPT" ]; then
        NOTION_ARGS+=(--prompt "${PROMPT}")
    fi

    # Add reference images if available
    if [ -n "$REF_IMAGES" ]; then
        NOTION_ARGS+=(--ref-images "$REF_IMAGES")
    fi

    NOTION_OUT=$(bash "$NOTION_REVIEW" add "${NOTION_ARGS[@]}" 2>&1) || true

    if echo "$NOTION_OUT" | grep -q "OK:"; then
        NOTION_URL=$(echo "$NOTION_OUT" | grep "URL:" | sed 's/URL: //')
        echo "    OK: Added to Notion (with prompt, refs, pipeline)"
        echo "    URL: $NOTION_URL"
    else
        echo "    WARN: Notion registration failed"
        log "Notion registration failed: $NOTION_OUT"
    fi
else
    echo "  [NOTION] Skipped (script not found)"
fi

# Step 4: Post to creative room
if [ -d "$ROOMS_DIR" ]; then
    echo "  [ROOM] Posting to creative room..."
    ROOM_FILE="$ROOMS_DIR/creative.jsonl"
    printf '{"ts":%s000,"agent":"pipeline","type":"image-generated","brand":"%s","use_case":"%s","path":"%s","audit":"%s","dims":"%s"}\n' \
        "$(date +%s)" "${BRAND:-unknown}" "${USE_CASE:-unknown}" "$IMAGE_PATH" "$AUDIT_PASS" "${DIMS:-unknown}" >> "$ROOM_FILE" 2>/dev/null
    echo "    OK: Posted to creative room"
fi

# Step 5: Summary
echo ""
echo "=== Pipeline Complete ==="
echo "  Image: $IMAGE_PATH"
echo "  Size:  ${FILE_SIZE_KB}KB"
echo "  Dims:  ${DIMS:-unknown}"
echo "  Audit: $([ "$AUDIT_PASS" = "true" ] && echo "PASS" || echo "FAIL: $AUDIT_NOTES")"
echo "  Brand: ${BRAND:-unknown}"
echo "  Type:  ${USE_CASE:-unknown}"

# Return the image path as the last line (for classify.sh to capture)
echo "$IMAGE_PATH"
