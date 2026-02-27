#!/bin/bash
# digest-link.sh — Full link digest pipeline: classify → dispatch → log → store
# Bash 3.2 compatible (macOS)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="digest-link"
LOG_FILE="$HOME/.openclaw/logs/link-digester.log"
DISPATCH_SCRIPT="$HOME/.openclaw/skills/mission-control/scripts/dispatch.sh"
MEMORY_STORE="$HOME/.openclaw/skills/rag-memory/scripts/memory-store.sh"
EXEC_ROOM="$HOME/.openclaw/workspace/rooms/exec.jsonl"
CLASSIFY_SCRIPT="$SCRIPT_DIR/classify-link.sh"
VISUAL_REF_SCRIPT="$SCRIPT_DIR/extract-visual-ref.sh"

log() {
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_NAME" "$1" >> "$LOG_FILE" 2>/dev/null
}

usage() {
  printf 'Usage: digest-link.sh <url> [type] [instructions]\n' >&2
  printf '  url          — The URL to process\n' >&2
  printf '  type         — Optional: youtube|article|product|competitor|social|general\n' >&2
  printf '  instructions — Optional: specific instructions for the processing agent\n' >&2
  exit 1
}

# --- Validate args ---
if [ $# -lt 1 ] || [ -z "$1" ]; then
  usage
fi

URL="$1"
FORCE_TYPE="${2:-}"
INSTRUCTIONS="${3:-}"

log "Starting digest for URL: $URL (force_type=$FORCE_TYPE, instructions=$INSTRUCTIONS)"

# --- Classify the link ---
if [ -n "$FORCE_TYPE" ]; then
  # Map forced type to agent and room
  case "$FORCE_TYPE" in
    youtube)    AGENT="taoz"; ROOM="exec" ;;
    product)    AGENT="hermes";     ROOM="exec" ;;
    social)     AGENT="iris";       ROOM="creative" ;;
    competitor) AGENT="artemis";    ROOM="build" ;;
    article)    AGENT="artemis";    ROOM="exec" ;;
    visual-reference) AGENT="iris"; ROOM="creative" ;;
    general)    AGENT="artemis";    ROOM="exec" ;;
    *)
      log "ERROR: Unknown type: $FORCE_TYPE, falling back to classify"
      FORCE_TYPE=""
      ;;
  esac
fi

if [ -z "$FORCE_TYPE" ]; then
  # Call classify-link.sh
  if [ ! -x "$CLASSIFY_SCRIPT" ]; then
    log "ERROR: classify-link.sh not found or not executable at $CLASSIFY_SCRIPT"
    printf 'ERROR: classify-link.sh not found at %s\n' "$CLASSIFY_SCRIPT" >&2
    exit 1
  fi

  CLASSIFY_OUTPUT=$(bash "$CLASSIFY_SCRIPT" "$URL" 2>/dev/null)
  CLASSIFY_EXIT=$?

  if [ $CLASSIFY_EXIT -ne 0 ] || [ -z "$CLASSIFY_OUTPUT" ]; then
    log "ERROR: classify-link.sh failed (exit=$CLASSIFY_EXIT)"
    printf 'ERROR: Classification failed for URL: %s\n' "$URL" >&2
    exit 1
  fi

  # Parse JSON output (simple extraction, no jq dependency)
  TYPE=$(printf '%s' "$CLASSIFY_OUTPUT" | sed 's/.*"type":"\([^"]*\)".*/\1/')
  AGENT=$(printf '%s' "$CLASSIFY_OUTPUT" | sed 's/.*"agent":"\([^"]*\)".*/\1/')
  ROOM=$(printf '%s' "$CLASSIFY_OUTPUT" | sed 's/.*"room":"\([^"]*\)".*/\1/')
  DOMAIN=$(printf '%s' "$CLASSIFY_OUTPUT" | sed 's/.*"domain":"\([^"]*\)".*/\1/')

  log "Classification result: type=$TYPE agent=$AGENT room=$ROOM domain=$DOMAIN"
else
  TYPE="$FORCE_TYPE"
  # Extract domain for logging
  DOMAIN=$(printf '%s' "$URL" | sed 's|^[a-zA-Z]*://||' | sed 's|/.*||' | sed 's|:.*||')
  DOMAIN=$(printf '%s' "$DOMAIN" | tr '[:upper:]' '[:lower:]')
fi

# --- Check for instruction-based agent override ---
if [ -n "$INSTRUCTIONS" ]; then
  INST_LOWER=$(printf '%s' "$INSTRUCTIONS" | tr '[:upper:]' '[:lower:]')

  # Check if instructions mention a specific agent name
  case "$INST_LOWER" in
    *taoz*) AGENT="taoz"; log "Agent override from instructions: taoz" ;;
    *artemis*)    AGENT="artemis";    log "Agent override from instructions: artemis" ;;
    *athena*)     AGENT="athena";     log "Agent override from instructions: athena" ;;
    *hermes*)     AGENT="hermes";     log "Agent override from instructions: hermes" ;;
    *iris*)       AGENT="iris";       log "Agent override from instructions: iris" ;;
    *dreami*)     AGENT="dreami";     log "Agent override from instructions: dreami" ;;
  esac

  # Check for urgency
  PRIORITY=""
  case "$INST_LOWER" in
    *now*|*immediately*|*asap*|*urgent*)
      PRIORITY="[URGENT] "
      log "Priority flag set from instructions"
      ;;
  esac
fi

PRIORITY="${PRIORITY:-}"

# --- Build dispatch message based on type ---
case "$TYPE" in
  youtube)
    DEFAULT_INST="Watch, extract key insights, store learnings in RAG memory."
    MESSAGE="${PRIORITY}[LINK-DIGEST] YouTube video to learn from: $URL.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Use /learn-youtube pipeline: extract transcript -> categorize -> analyze -> map to GAIA agents -> store -> apply."
    ;;

  article)
    DEFAULT_INST="Read, summarize key points, extract actionable insights."
    MESSAGE="${PRIORITY}[LINK-DIGEST] Article to research: $URL.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Scrape the URL, summarize in 3-5 bullet points, identify relevance to GAIA operations."
    ;;

  product)
    DEFAULT_INST="Analyze pricing, positioning, and competitive advantage."
    MESSAGE="${PRIORITY}[LINK-DIGEST] Product to analyze: $URL.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Extract: product name, price, key features, seller info. Compare to GAIA product line."
    ;;

  competitor)
    DEFAULT_INST="Analyze competitive positioning, pricing, messaging strategy."
    MESSAGE="${PRIORITY}[LINK-DIGEST] Competitor intel: $URL.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Full competitive analysis: brand positioning, visual identity, pricing, content strategy."
    ;;

  social)
    DEFAULT_INST="Analyze content style, engagement patterns, trend relevance."
    MESSAGE="${PRIORITY}[LINK-DIGEST] Social content to analyze: $URL.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Extract: content format, hook style, engagement metrics if visible, relevance to GAIA content strategy."
    ;;

  visual-reference)
    DEFAULT_INST="Analyze visual style, color palette, composition, and mood. Assess relevance to GAIA brand identity."
    # Download the visual reference first
    VISUAL_REF_LOCAL=""
    VISUAL_REF_IMAGE_URL=""
    VISUAL_REF_PLATFORM=""
    if [ -x "$VISUAL_REF_SCRIPT" ]; then
      log "Extracting visual reference image from $URL"
      VR_OUTPUT=$(bash "$VISUAL_REF_SCRIPT" "$URL" 2>>"$LOG_FILE")
      VR_EXIT=$?
      if [ $VR_EXIT -eq 0 ] && [ -n "$VR_OUTPUT" ]; then
        VR_STATUS=$(printf '%s' "$VR_OUTPUT" | sed 's/.*"status":"\([^"]*\)".*/\1/')
        if [ "$VR_STATUS" = "ok" ]; then
          VISUAL_REF_LOCAL=$(printf '%s' "$VR_OUTPUT" | sed 's/.*"local_path":"\([^"]*\)".*/\1/')
          VISUAL_REF_IMAGE_URL=$(printf '%s' "$VR_OUTPUT" | sed 's/.*"image_url":"\([^"]*\)".*/\1/')
          VISUAL_REF_PLATFORM=$(printf '%s' "$VR_OUTPUT" | sed 's/.*"platform":"\([^"]*\)".*/\1/')
          log "Visual ref downloaded: $VISUAL_REF_LOCAL (platform: $VISUAL_REF_PLATFORM)"
        else
          VR_ERROR=$(printf '%s' "$VR_OUTPUT" | sed 's/.*"error":"\([^"]*\)".*/\1/')
          log "WARNING: Visual ref extraction returned status=$VR_STATUS error=$VR_ERROR"
        fi
      else
        log "WARNING: extract-visual-ref.sh failed (exit=$VR_EXIT)"
      fi
    else
      log "WARNING: extract-visual-ref.sh not found at $VISUAL_REF_SCRIPT"
    fi
    # Build message with local_path if available
    if [ -n "$VISUAL_REF_LOCAL" ]; then
      MESSAGE="${PRIORITY}[LINK-DIGEST] Visual reference to analyze: $URL
Platform: ${VISUAL_REF_PLATFORM:-unknown}
Image downloaded to: $VISUAL_REF_LOCAL
Original image URL: $VISUAL_REF_IMAGE_URL
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Use visual audit to analyze style, palette, composition. Store findings for brand reference."
    else
      MESSAGE="${PRIORITY}[LINK-DIGEST] Visual reference to analyze: $URL
WARNING: Could not download reference image — analyze from URL directly.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Try to access the URL and analyze visual style, palette, composition."
    fi
    ;;

  general|*)
    DEFAULT_INST="Read and summarize. Identify any relevance to GAIA operations."
    MESSAGE="${PRIORITY}[LINK-DIGEST] Link to process: $URL.
Instructions: ${INSTRUCTIONS:-$DEFAULT_INST}
Summarize content, extract key takeaways, note any actionable items."
    ;;
esac

log "Dispatching to $AGENT via $ROOM room"
log "Message: $(printf '%s' "$MESSAGE" | head -c 200)"

# --- Dispatch to agent ---
if [ -x "$DISPATCH_SCRIPT" ]; then
  bash "$DISPATCH_SCRIPT" "zenni" "$AGENT" "request" "$MESSAGE" "$ROOM" 2>>"$LOG_FILE" || {
    log "WARNING: dispatch.sh returned non-zero exit code"
  }
  log "Dispatched to $AGENT successfully"
else
  log "WARNING: dispatch.sh not found at $DISPATCH_SCRIPT — logging only"
  printf 'WARNING: dispatch.sh not found. Message would be sent to %s:\n%s\n' "$AGENT" "$MESSAGE" >&2
fi

# --- Post summary to exec room ---
TIMESTAMP=$(date +%s)
EXEC_MSG=$(printf '[LINK-DIGEST] Processing %s link: %s -> routed to %s' "$TYPE" "$URL" "$AGENT")
# Escape for JSON
EXEC_MSG_ESCAPED=$(printf '%s' "$EXEC_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"ts":%s000,"agent":"zenni","room":"exec","type":"link-digest","msg":"%s"}\n' \
  "$TIMESTAMP" "$EXEC_MSG_ESCAPED" >> "$EXEC_ROOM" 2>/dev/null || {
  log "WARNING: Could not write to exec room at $EXEC_ROOM"
}

log "Posted summary to exec room"

# --- Post to intake room (feeds Creative Intake Engine) ---
INTAKE_ROOM="$HOME/.openclaw/workspace/rooms/intake.jsonl"
if [ -f "$INTAKE_ROOM" ] || [ -d "$(dirname "$INTAKE_ROOM")" ]; then
  INTAKE_URL_ESCAPED=$(printf '%s' "$URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
  INTAKE_CONTEXT_ESCAPED=$(printf '%s' "${INSTRUCTIONS:-}" | sed 's/\\/\\\\/g; s/"/\\"/g' | head -c 500)
  printf '{"ts":%s000,"agent":"zenni","source":"link-digester","type":"link","content":"%s","brand":"","context":"%s","requested_by":"user"}\n' \
    "$TIMESTAMP" "$INTAKE_URL_ESCAPED" "$INTAKE_CONTEXT_ESCAPED" >> "$INTAKE_ROOM" 2>/dev/null || {
    log "WARNING: Could not write to intake room at $INTAKE_ROOM"
  }
  log "Posted to intake room"
fi

# --- Store in RAG memory ---
if [ -x "$MEMORY_STORE" ]; then
  bash "$MEMORY_STORE" \
    --agent zenni \
    --type insight \
    --tags "link-digest,$TYPE,$DOMAIN" \
    --text "Processed $TYPE link: $URL" \
    --importance 5 2>/dev/null || true
  log "Stored in RAG memory"
else
  log "WARNING: memory-store.sh not found at $MEMORY_STORE — skipping RAG storage"
fi

# --- Output result ---
printf '{"status":"dispatched","type":"%s","agent":"%s","room":"%s","url":"%s"}\n' \
  "$TYPE" "$AGENT" "$ROOM" "$URL"

log "Digest complete for $URL"
