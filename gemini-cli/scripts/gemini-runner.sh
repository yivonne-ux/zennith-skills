#!/usr/bin/env bash
# gemini-runner.sh — Wraps Gemini CLI for OpenClaw creative task invocation
# Mirrors claude-code-runner.sh pattern: context loading, knowledge sync, compound learning
# Usage: gemini-runner.sh <creative|brainstorm|adapt|dispatch> <prompt> [from_agent] [room] [--brand brand]
#
# Modes:
#   creative  — Generate creative content (copy, headlines, scripts, concepts)
#   brainstorm — Open-ended ideation with structured output
#   adapt     — Adapt existing content (translate, reformat, channel-adapt)
#   dispatch  — Full dispatch mode with inbox tracking + room posting (like claude-code-runner dispatch)

set -euo pipefail

# Load env (cron-safe)
KEYFILE="$HOME/.openclaw/.env.keys"
if [ -f "$KEYFILE" ]; then
  set -a; source "$KEYFILE" 2>/dev/null || true; set +a
fi

MODE="${1:?Usage: gemini-runner.sh <creative|brainstorm|adapt|dispatch> <prompt> [from_agent] [room] [--brand brand]}"
PROMPT="${2:?Error: prompt is required}"
FROM_AGENT="${3:-zenni}"
ROOM="${4:-creative}"

# Parse flags
BRAND=""
shift 4 2>/dev/null || true
while [ $# -gt 0 ]; do
  case "$1" in
    --brand) shift; BRAND="${1:-}" ;;
  esac
  shift 2>/dev/null || true
done

# Paths
GEMINI_BIN="$HOME/local/bin/gemini"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
RESULTS_DIR="$HOME/.openclaw/workspace/data/gemini-results"
RUNNER_LOG="$HOME/.openclaw/logs/gemini-runner.log"
INBOX="$HOME/.openclaw/workspace/gemini-inbox.jsonl"
BRANDS_DIR="$HOME/.openclaw/brands"
LEARNINGS_DIR="$HOME/.openclaw/workspace/data/learnings"
KSYNC="$HOME/.openclaw/workspace-taoz/KNOWLEDGE-SYNC.md"

mkdir -p "$RESULTS_DIR" "$(dirname "$RUNNER_LOG")" "$(dirname "$INBOX")"

# Verify Gemini CLI exists
if [ ! -x "$GEMINI_BIN" ]; then
  echo "ERROR: Gemini CLI not found at $GEMINI_BIN"
  exit 1
fi

# Task ID
TASK_ID="gemini-$(date +%s)-$$"
TS_EPOCH=$(date +%s)

# Load brand context if specified
BRAND_CONTEXT=""
if [ -n "$BRAND" ] && [ -f "$BRANDS_DIR/$BRAND/DNA.json" ]; then
  BRAND_CONTEXT="## Brand Context ($BRAND)
$(head -c 3000 "$BRANDS_DIR/$BRAND/DNA.json" 2>/dev/null)"
  # Load directions if available
  if [ -f "$BRANDS_DIR/$BRAND/campaigns/directions.json" ]; then
    BRAND_CONTEXT="$BRAND_CONTEXT

## Campaign Directions
$(head -c 2000 "$BRANDS_DIR/$BRAND/campaigns/directions.json" 2>/dev/null)"
  fi
fi

# Load compound learnings
LEARNINGS=""
if [ -n "$BRAND" ] && [ -d "$LEARNINGS_DIR" ]; then
  RESOLVE_SCRIPT="$LEARNINGS_DIR/resolve-learnings.py"
  if [ -f "$RESOLVE_SCRIPT" ]; then
    LEARNINGS=$(python3 "$RESOLVE_SCRIPT" --brand "$BRAND" --format flat 2>/dev/null | head -c 2000 || echo "")
  fi
fi

# Load knowledge sync excerpt
KSYNC_EXCERPT=""
if [ -f "$KSYNC" ]; then
  KSYNC_EXCERPT=$(head -c 3000 "$KSYNC" 2>/dev/null || echo "")
fi

# Build context-enriched prompt based on mode
case "$MODE" in
  creative)
    SYSTEM_CONTEXT="You are a creative content engine for GAIA CORP-OS, working on behalf of agent '$FROM_AGENT'.
Generate creative content: ad copy, headlines, social captions, video scripts, or campaign concepts.

OUTPUT FORMAT:
1. Content — the actual creative output with character counts
2. Variants — 3 alternatives minimum
3. Tags — language [EN/CN/BM], channel, format type
4. Rationale — why this works (1-2 sentences)

$BRAND_CONTEXT

## Compound Learnings (what worked before)
$LEARNINGS"
    ;;
  brainstorm)
    SYSTEM_CONTEXT="You are a brainstorming engine for GAIA CORP-OS, working on behalf of agent '$FROM_AGENT'.
Generate creative ideas with structured scoring.

OUTPUT FORMAT:
1. Ideas — numbered list with one-line pitch each
2. Top 3 — expanded with rationale, target persona, estimated impact
3. Quick wins — ideas that can ship in <24h
4. Wild cards — high-risk high-reward ideas

$BRAND_CONTEXT

## Compound Learnings
$LEARNINGS"
    ;;
  adapt)
    SYSTEM_CONTEXT="You are a content adaptation engine for GAIA CORP-OS, working on behalf of agent '$FROM_AGENT'.
Adapt content across languages, channels, formats, or personas.

OUTPUT FORMAT:
1. Original — reference the source
2. Adapted versions — each tagged with [language] [channel] [persona]
3. Character counts — per platform limits
4. Cultural notes — localization adjustments made

$BRAND_CONTEXT"
    ;;
  dispatch)
    # Full dispatch mode — mirrors claude-code-runner.sh dispatch
    SYSTEM_CONTEXT="You are a creative agent for GAIA CORP-OS. Execute this creative task dispatched from $FROM_AGENT.

$BRAND_CONTEXT

## Compound Learnings
$LEARNINGS

## Accumulated Knowledge
$KSYNC_EXCERPT"
    ;;
  *)
    echo "ERROR: Unknown mode '$MODE'. Use 'creative', 'brainstorm', 'adapt', or 'dispatch'."
    exit 1
    ;;
esac

# Queue to inbox
SAFE_MSG=$(printf '%s' "$PROMPT" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 2000)
printf '{"id":"%s","ts":%s000,"from":"%s","room":"%s","mode":"%s","brand":"%s","status":"running","msg":"%s"}\n' \
  "$TASK_ID" "$TS_EPOCH" "$FROM_AGENT" "$ROOM" "$MODE" "${BRAND:-none}" "$SAFE_MSG" >> "$INBOX"
printf '[%s] Running %s task %s from %s (brand: %s)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" "$TASK_ID" "$FROM_AGENT" "${BRAND:-none}" >> "$RUNNER_LOG" 2>/dev/null

# Post ack to room
printf '{"ts":%s000,"agent":"gemini","to":"%s","room":"%s","type":"gemini-ack","msg":"[Gemini] Creative task received (id=%s, mode=%s). Running..."}\n' \
  "$TS_EPOCH" "$FROM_AGENT" "$ROOM" "$TASK_ID" "$MODE" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null

# Build the full prompt
FULL_PROMPT="$SYSTEM_CONTEXT

---

## Task
$PROMPT

After completing, summarize what you created in 2-3 sentences."

# Run Gemini CLI
RESULT_FILE="$RESULTS_DIR/${TASK_ID}.txt"

cd "$HOME/.openclaw" 2>/dev/null || true
"$GEMINI_BIN" -p "$FULL_PROMPT" \
  --approval-mode yolo \
  --include-directories "$HOME/.openclaw" \
  -o text \
  > "$RESULT_FILE" 2>&1 &

BGPID=$!
WAITED=0
MAX_WAIT=300  # 5 minutes for creative tasks
while kill -0 "$BGPID" 2>/dev/null && [ "$WAITED" -lt "$MAX_WAIT" ]; do
  sleep 5
  WAITED=$((WAITED + 5))
done
BUILD_DURATION=$WAITED

if kill -0 "$BGPID" 2>/dev/null; then
  kill "$BGPID" 2>/dev/null || true
  RESULT="[Gemini] Task timed out (${MAX_WAIT}s). Partial result at $RESULT_FILE"
  BUILD_STATUS="timeout"
else
  RESULT=$(cat "$RESULT_FILE" 2>/dev/null | head -c 1500)
  [ -z "$RESULT" ] && RESULT="[Gemini] Task completed (no output captured)."
  BUILD_STATUS="completed"
fi

printf '[%s] %s task %s (%ss)\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$BUILD_STATUS" "$TASK_ID" "$BUILD_DURATION" >> "$RUNNER_LOG" 2>/dev/null

# Update inbox + post result to room
printf '{"id":"%s","ts":%s000,"status":"%s","result_file":"%s"}\n' \
  "$TASK_ID" "$(date +%s)" "$BUILD_STATUS" "$RESULT_FILE" >> "$INBOX"
SAFE_RESULT=$(printf '%s' "$RESULT" | tr '\n' ' ' | sed 's/"/\\"/g' | head -c 1500)
printf '{"ts":%s000,"agent":"gemini","to":"%s","room":"%s","type":"gemini-result","task_id":"%s","mode":"%s","brand":"%s","msg":"[Gemini] %s"}\n' \
  "$(date +%s)" "$FROM_AGENT" "$ROOM" "$TASK_ID" "$MODE" "${BRAND:-none}" "$SAFE_RESULT" >> "$ROOMS_DIR/${ROOM}.jsonl" 2>/dev/null

# Knowledge write-back
if [ -f "$KSYNC" ]; then
  TASK_OUTCOME="success"
  echo "$RESULT" | grep -qiE '(timeout|error|fail)' && TASK_OUTCOME="fail"
  printf '\n## Gemini %s (%s) — %s\n- Task: %s\n- Brand: %s | Duration: %ss | Status: %s\n- Result: %s\n' \
    "$TASK_ID" "$(date '+%Y-%m-%d %H:%M')" "$TASK_OUTCOME" \
    "$(printf '%s' "$PROMPT" | head -c 150)" "${BRAND:-none}" "$BUILD_DURATION" "$BUILD_STATUS" \
    "$(printf '%s' "$RESULT" | head -c 300 | tr '\n' ' ')" >> "$KSYNC" 2>/dev/null || true
fi

# Feed compound learning
TASK_COMPLETE_SH="$HOME/.openclaw/workspace/scripts/learning/task-complete.sh"
if [ -f "$TASK_COMPLETE_SH" ]; then
  TASK_OUTCOME="success"
  echo "$RESULT" | grep -qiE '(timeout|error|fail)' && TASK_OUTCOME="fail"
  bash "$TASK_COMPLETE_SH" "gemini" "creative-$MODE" "$(printf '%s' "$PROMPT" | tr '\n' ' ' | head -c 200)" "$TASK_OUTCOME" "${BRAND:-}" "$TS_EPOCH" > /dev/null 2>&1 || true
fi

# Run digest if available
DIGEST_SCRIPT="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"
if [ -f "$DIGEST_SCRIPT" ]; then
  bash "$DIGEST_SCRIPT" --quick > /dev/null 2>&1 &
fi

echo "{\"status\":\"$BUILD_STATUS\",\"task_id\":\"$TASK_ID\",\"result_file\":\"$RESULT_FILE\"}"
