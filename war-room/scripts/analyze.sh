#!/usr/bin/env bash
# analyze.sh — War Room: Multi-Agent Idea Analysis
#
# Paste links or ideas → agents analyze from their domain perspective
# Each agent evaluates independently, then posts to exec room for synthesis.
#
# Usage: bash analyze.sh "idea or URL or text"
# Can also read from stdin: echo "my idea" | bash analyze.sh

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

ROOMS_DIR="${HOME}/.openclaw/workspace/rooms"
LOG_FILE="${HOME}/.openclaw/logs/war-room.log"
DISPATCH="${HOME}/.openclaw/skills/mission-control/scripts/dispatch.sh"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Get input — from argument or stdin
INPUT=""
if [ -n "${1:-}" ]; then
  INPUT="$*"
elif [ ! -t 0 ]; then
  INPUT=$(cat)
fi

if [ -z "$INPUT" ]; then
  echo "Usage: bash analyze.sh \"your idea, link, or text\""
  echo "  or:  echo \"idea\" | bash analyze.sh"
  exit 1
fi

log "=== War Room Started ==="
log "Input: ${INPUT:0:200}"

# Post the idea to exec room as a war-room brief
ESCAPED_INPUT=$(echo "$INPUT" | python3 -c "import sys; s=sys.stdin.read().strip().replace('\"','\\\\\"').replace('\n',' '); print(s)" 2>/dev/null)
printf '{"ts":%s000,"agent":"war-room","room":"exec","type":"war-room-brief","msg":"WAR ROOM BRIEF: %s"}\n' \
  "$(date +%s)" "$ESCAPED_INPUT" >> "${ROOMS_DIR}/exec.jsonl"

echo ""
echo "====================================="
echo "  GAIA WAR ROOM — Multi-Agent Analysis"
echo "====================================="
echo ""
echo "Brief: ${INPUT:0:100}..."
echo ""
echo "Dispatching to all domain experts..."
echo ""

# Dispatch to each agent with their domain-specific analysis prompt
# All agents analyze concurrently

# Artemis — Market & Competition angle
ARTEMIS_BRIEF="WAR ROOM ANALYSIS REQUEST. Analyze this from a RESEARCH & MARKET perspective: ${INPUT}. Consider: Is there market demand? Who are competitors doing this? What are the risks? What data supports or contradicts this idea? Post your analysis to exec room."
bash "$DISPATCH" "war-room" "artemis" "request" "$ARTEMIS_BRIEF" "exec" >> "$LOG_FILE" 2>&1 &
echo "  → Artemis (Research): dispatched"

# Apollo — Creative & Brand angle
APOLLO_BRIEF="WAR ROOM ANALYSIS REQUEST. Analyze this from a CREATIVE & BRAND perspective: ${INPUT}. Consider: How does this fit GAIA's brand? What content can we create? What's the storytelling angle? What creative assets are needed? Post your analysis to exec room."
bash "$DISPATCH" "war-room" "apollo" "request" "$APOLLO_BRIEF" "exec" >> "$LOG_FILE" 2>&1 &
echo "  → Apollo (Creative): dispatched"

# Athena — Data & Strategy angle
ATHENA_BRIEF="WAR ROOM ANALYSIS REQUEST. Analyze this from a DATA & STRATEGY perspective: ${INPUT}. Consider: What's the expected ROI? What metrics should we track? What's the risk/reward? How does this compare to our current priorities? Post your analysis to exec room."
bash "$DISPATCH" "war-room" "athena" "request" "$ATHENA_BRIEF" "exec" >> "$LOG_FILE" 2>&1 &
echo "  → Athena (Strategy): dispatched"

# Hermes — Commerce & Pricing angle
HERMES_BRIEF="WAR ROOM ANALYSIS REQUEST. Analyze this from a COMMERCE & PRICING perspective: ${INPUT}. Consider: What's the cost to implement? What's the pricing model? How does it affect margins? What channels would this use? Post your analysis to exec room."
bash "$DISPATCH" "war-room" "hermes" "request" "$HERMES_BRIEF" "exec" >> "$LOG_FILE" 2>&1 &
echo "  → Hermes (Commerce): dispatched"

# Iris — Social & Community angle
IRIS_BRIEF="WAR ROOM ANALYSIS REQUEST. Analyze this from a SOCIAL & COMMUNITY perspective: ${INPUT}. Consider: How would this play on social media? What's the viral potential? How would our community react? What platforms should we target? Post your analysis to exec room."
bash "$DISPATCH" "war-room" "iris" "request" "$IRIS_BRIEF" "exec" >> "$LOG_FILE" 2>&1 &
echo "  → Iris (Social): dispatched"

echo ""
echo "All 5 agents analyzing concurrently."
echo "Results will appear in exec room within 1-3 minutes."
echo ""
echo "Monitor: tail -f ~/.openclaw/workspace/rooms/exec.jsonl"
echo ""

# Wait for all dispatches
wait

log "=== War Room Dispatches Complete ==="
