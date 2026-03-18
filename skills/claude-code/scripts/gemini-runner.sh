#!/usr/bin/env bash
# gemini-runner.sh — Wraps Gemini CLI for OpenClaw agent escalation
# Mirrors claude-code-runner.sh pattern but for Gemini 2.5 Pro/Flash
# Usage: gemini-runner.sh <mode> "<prompt>" [cwd] [--model gemini-3.1-pro|gemini-2.5-pro|...]

set -euo pipefail

# Load env (cron-safe)
KEYFILE="$HOME/.openclaw/.env.keys"
if [ -f "$KEYFILE" ]; then
  set -a; source "$KEYFILE" 2>/dev/null || true; set +a
fi

GEMINI_CLI="$HOME/local/bin/gemini"
if [ ! -x "$GEMINI_CLI" ]; then
  echo "ERROR: Gemini CLI not found at $GEMINI_CLI" >&2
  exit 1
fi

# --- Parse arguments ---
MODE="${1:?Usage: gemini-runner.sh <creative|strategy|research|general> \"<prompt>\" [cwd] [--model gemini-2.5-pro|gemini-2.5-flash]}"
PROMPT="${2:?Error: prompt is required}"
CWD="${3:-$HOME/.openclaw}"

# Parse --model flag from remaining args
CLI_MODEL=""
shift 3 2>/dev/null || shift $# 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --model) shift; CLI_MODEL="${1:-}" ;;
  esac
  shift 2>/dev/null || true
done

# Default model
MODEL="${CLI_MODEL:-gemini-3.1-pro}"
# Validate model
case "$MODEL" in
  gemini-3.1-pro|gemini-3.1-flash-lite|gemini-2.5-pro|gemini-2.5-flash) ;; # Valid
  *) echo "WARN: Unknown model '$MODEL', defaulting to gemini-3.1-pro" >&2; MODEL="gemini-3.1-pro" ;;
esac

# --- Logging ---
RUNNER_LOG="$HOME/.openclaw/logs/gemini-runner.log"
RESULTS_DIR="$HOME/.openclaw/workspace/data/gemini-results"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
mkdir -p "$(dirname "$RUNNER_LOG")" "$RESULTS_DIR" "$ROOMS_DIR"

TASK_ID="gemini-$(date +%s)-$$"
TS_EPOCH=$(date +%s)

printf '[%s] Task %s | Mode: %s | Model: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" "$MODE" "$MODEL" >> "$RUNNER_LOG" 2>/dev/null

# --- Brand context injection ---
# Scan prompt for brand names, auto-load DNA.json
BRANDS_DIR="$HOME/.openclaw/brands"
BRAND_CONTEXT=""
DETECTED_BRAND=""

for BRAND_DIR in "$BRANDS_DIR"/*/; do
  BRAND_NAME=$(basename "$BRAND_DIR")
  # Build case-insensitive search pattern from brand name (handle hyphens)
  BRAND_SEARCH=$(echo "$BRAND_NAME" | tr '-' ' ')
  if echo "$PROMPT" | grep -qi "$BRAND_SEARCH" || echo "$PROMPT" | grep -qi "$BRAND_NAME"; then
    DNA_FILE="$BRAND_DIR/DNA.json"
    if [ -f "$DNA_FILE" ]; then
      DETECTED_BRAND="$BRAND_NAME"
      BRAND_DATA=$(cat "$DNA_FILE" 2>/dev/null | head -c 8000)
      BRAND_CONTEXT="
## Brand Context: $BRAND_NAME
The following is the brand DNA (identity, voice, values, target audience) for $BRAND_NAME. Use this to inform all output.
\`\`\`json
$BRAND_DATA
\`\`\`
"
      printf '[%s] Brand detected: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$BRAND_NAME" >> "$RUNNER_LOG" 2>/dev/null
      break  # Use first match
    fi
  fi
done

# --- Skill context injection based on mode ---
SKILLS_DIR="$HOME/.openclaw/skills"
SKILL_CONTEXT=""

load_skill() {
  local SKILL_NAME="$1"
  local SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
  if [ -f "$SKILL_FILE" ]; then
    local SKILL_DATA
    SKILL_DATA=$(head -c 3000 "$SKILL_FILE" 2>/dev/null || echo "")
    if [ -n "$SKILL_DATA" ]; then
      SKILL_CONTEXT="$SKILL_CONTEXT
### Skill: $SKILL_NAME
$SKILL_DATA
---
"
    fi
  fi
}

case "$MODE" in
  creative)
    SYSTEM_ROLE="You are a Creative Director and Copywriter for GAIA CORP-OS. You produce brand-aligned campaign briefs, ad copy, content calendars, hooks, scripts, and creative strategies. Be bold, specific, and actionable. Every piece of copy must have a clear hook, value proposition, and CTA."
    load_skill "campaign-planner"
    load_skill "content-ideation-workflow"
    load_skill "marketing-formulas"
    load_skill "ads-creative"
    load_skill "brand-studio"
    ;;
  strategy)
    SYSTEM_ROLE="You are a Business Strategist and Revenue Analyst for GAIA CORP-OS. You analyze pricing, unit economics, competitor positioning, market opportunities, and performance data. Provide data-driven recommendations with clear numbers, trade-offs, and actionable next steps. Always show your reasoning."
    load_skill "marketing-formulas"
    load_skill "seasonal-marketing-os"
    load_skill "ads-competitor"
    ;;
  research)
    SYSTEM_ROLE="You are a Scout and Research Analyst for GAIA CORP-OS. You gather intelligence on competitors, market trends, consumer behavior, and opportunities. Be thorough, cite sources where possible, and structure findings with clear takeaways and recommended actions."
    load_skill "product-scout"
    load_skill "brand-intel"
    load_skill "tiktok-trends"
    load_skill "ig-reels-trends"
    ;;
  general)
    SYSTEM_ROLE="You are a general-purpose AI assistant for GAIA CORP-OS. Execute the task precisely and concisely. Structure your output clearly."
    ;;
  *)
    echo "ERROR: Unknown mode '$MODE'. Use 'creative', 'strategy', 'research', or 'general'." >&2
    echo "Usage: gemini-runner.sh <creative|strategy|research|general> \"<prompt>\" [cwd] [--model gemini-3.1-pro|gemini-2.5-pro|...]" >&2
    exit 1
    ;;
esac

# --- Build full prompt ---
FULL_PROMPT="$SYSTEM_ROLE

## GAIA CORP-OS Context
- 9-agent AI system running 13 brands (F&B, wellness, supplements)
- Core brands: Pinxin Vegan, Wholey Wonder, MIRRA (bento health food, NOT skincare), Rasaya, Gaia Eats, Dr. Stan, Serein
- MIRRA = bento-style health food delivery (NOT the-mirra.com, NOT skincare)
- Market: Malaysia (primarily KL/Selangor), prices in RM
- CEO: Jenn Woei Loh
$BRAND_CONTEXT
"

if [ -n "$SKILL_CONTEXT" ]; then
  FULL_PROMPT="$FULL_PROMPT
## Relevant Skills & Frameworks
$SKILL_CONTEXT
"
fi

FULL_PROMPT="$FULL_PROMPT
## Task
$PROMPT

## Output Format
- Be concise and actionable
- Use markdown formatting
- If producing copy: include multiple variants
- If analyzing data: show calculations and trade-offs
- End with a clear recommendation or next steps"

# --- Emit start event to room ---
SAFE_MSG=$(printf '%s' "$PROMPT" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 2000)
printf '{"ts":%s000,"agent":"gemini","room":"build","type":"gemini-start","task_id":"%s","model":"%s","mode":"%s","msg":"%s"}\n' \
  "$TS_EPOCH" "$TASK_ID" "$MODEL" "$MODE" "$SAFE_MSG" >> "$ROOMS_DIR/build.jsonl" 2>/dev/null

# --- Run Gemini CLI ---
RESULT_FILE="$RESULTS_DIR/${TASK_ID}.txt"

echo "--- gemini-runner.$MODE ---" >&2
echo "Task: $TASK_ID | Model: $MODEL | Brand: ${DETECTED_BRAND:-none}" >&2
echo "---" >&2

# Run with timeout (background + wait + kill pattern for macOS)
cd "$CWD" 2>/dev/null || cd "$HOME/.openclaw"

"$GEMINI_CLI" \
  -p "$FULL_PROMPT" \
  -m "$MODEL" \
  -o text \
  --yolo \
  > "$RESULT_FILE" 2>&1 &

BGPID=$!
WAITED=0
MAX_WAIT=300  # 5 minutes
while kill -0 "$BGPID" 2>/dev/null && [ "$WAITED" -lt "$MAX_WAIT" ]; do
  sleep 5
  WAITED=$((WAITED + 5))
done
BUILD_DURATION=$WAITED

if kill -0 "$BGPID" 2>/dev/null; then
  kill "$BGPID" 2>/dev/null || true
  RESULT="[Gemini] Task timed out (${MAX_WAIT}s). Partial result in $RESULT_FILE"
  BUILD_STATUS="timeout"
  printf '[%s] TIMEOUT task %s after %ss\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" "$MAX_WAIT" >> "$RUNNER_LOG" 2>/dev/null
else
  # Strip noise lines that gemini CLI always prints (credentials, YOLO warnings)
  RESULT=$(grep -vE '^(Loaded cached credentials\.|YOLO mode is enabled\.)' "$RESULT_FILE" 2>/dev/null || cat "$RESULT_FILE" 2>/dev/null)
  # Trim leading/trailing blank lines (macOS-safe)
  RESULT=$(echo "$RESULT" | sed '/./,$!d')
  [ -z "$RESULT" ] && RESULT="[Gemini] Task completed (no output captured)."
  BUILD_STATUS="completed"
  printf '[%s] Completed task %s (%ss)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TASK_ID" "$BUILD_DURATION" >> "$RUNNER_LOG" 2>/dev/null
fi

# --- Emit completion event ---
printf '{"ts":%s000,"agent":"gemini","room":"build","type":"gemini-complete","task_id":"%s","status":"%s","duration":%s,"model":"%s","mode":"%s"}\n' \
  "$(date +%s)" "$TASK_ID" "$BUILD_STATUS" "$BUILD_DURATION" "$MODEL" "$MODE" >> "$ROOMS_DIR/build.jsonl" 2>/dev/null

# --- Knowledge write-back ---
OPENCLAW_CLI="$HOME/local/bin/openclaw"
if [ -x "$OPENCLAW_CLI" ]; then
  MEMORY_TEXT="[Gemini ${MODE} ${TASK_ID}] Brand: ${DETECTED_BRAND:-none}. Model: ${MODEL}. Task: $(printf '%s' "$PROMPT" | head -c 200). Result: $(printf '%s' "$RESULT" | head -c 300)"
  "$OPENCLAW_CLI" memory store \
    --scope global \
    --text "$MEMORY_TEXT" \
    --tags "gemini,${MODE},${MODEL}${DETECTED_BRAND:+,$DETECTED_BRAND}" \
    2>/dev/null || true
fi

# --- Feed compound learning loop ---
TASK_COMPLETE_SH="$HOME/.openclaw/workspace/scripts/learning/task-complete.sh"
if [ -f "$TASK_COMPLETE_SH" ]; then
  TASK_OUTCOME="success"
  echo "$RESULT" | grep -qiE '(timeout|error|fail|not found|crash)' && TASK_OUTCOME="fail"
  TASK_DESC=$(printf '%s' "$PROMPT" | tr '\n' ' ' | head -c 200)
  bash "$TASK_COMPLETE_SH" "gemini" "task-complete" "$TASK_DESC" "$TASK_OUTCOME" "" "$TS_EPOCH" > /dev/null 2>&1 || true
fi

# --- Output result to stdout ---
echo "$RESULT"

echo "" >&2
echo "--- gemini-runner.$MODE complete ($BUILD_STATUS, ${BUILD_DURATION}s) ---" >&2
