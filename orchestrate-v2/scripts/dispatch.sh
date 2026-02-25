#!/usr/bin/env bash
# dispatch.sh — Zenni's universal agent dispatcher
# Wraps sessions_spawn with the right model/label per agent
# Logs every dispatch to ~/.openclaw/logs/dispatch-log.jsonl
#
# Usage:
#   bash dispatch.sh <agent_id> "<task_brief>" "<label>" [thinking_level] [timeout_seconds]
#
# Agents: myrmidons | taoz | artemis | dreami | iris | athena | hermes
# Thinking levels: low | medium | high (default: medium)
# Timeout: seconds (default: 300)
#
# Examples:
#   bash dispatch.sh "myrmidons" "Check if gaiaos.com is live" "myrm-health"
#   bash dispatch.sh "taoz" "Build skill orchestrate-v2" "taoz-skill" "medium" 600
#   bash dispatch.sh "artemis" "Research vegan protein brands MY" "artemis-vegan"

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
AGENT="${1:-}"
TASK="${2:-}"
LABEL="${3:-}"
THINKING="${4:-medium}"
TIMEOUT="${5:-300}"

if [[ -z "$AGENT" || -z "$TASK" || -z "$LABEL" ]]; then
  echo "❌ Usage: dispatch.sh <agent> <task> <label> [thinking] [timeout_seconds]"
  echo "   Agents: myrmidons | taoz | artemis | dreami | iris | athena | hermes"
  exit 1
fi

# ── Agent → Model map ─────────────────────────────────────────────────────────
# These are the canonical models per agent (matches SOUL.md + openclaw.json)
declare -A AGENT_MODEL=(
  ["myrmidons"]="minimax-m2.5"
  ["taoz"]="anthropic/claude-opus-4-6"      # claude-code runner; falls back to opus
  ["artemis"]="kimi-k2.5"                   # web-search-pro tier
  ["dreami"]="kimi-k2.5"
  ["iris"]="qwen3-vl-235b"
  ["athena"]="anthropic/claude-opus-4-6"    # reasoning tier
  ["hermes"]="anthropic/claude-opus-4-6"    # reasoning tier
)

# ── Agent → Cost tier (for logging) ───────────────────────────────────────────
declare -A AGENT_COST_TIER=(
  ["myrmidons"]="cheapest"
  ["taoz"]="premium"
  ["artemis"]="medium"
  ["dreami"]="medium"
  ["iris"]="medium"
  ["athena"]="high"
  ["hermes"]="high"
)

# ── Validate agent ────────────────────────────────────────────────────────────
if [[ -z "${AGENT_MODEL[$AGENT]:-}" ]]; then
  echo "❌ Unknown agent: '$AGENT'"
  echo "   Valid agents: ${!AGENT_MODEL[*]}"
  exit 1
fi

MODEL="${AGENT_MODEL[$AGENT]}"
COST_TIER="${AGENT_COST_TIER[$AGENT]}"

# ── Log paths ─────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.openclaw/logs"
DISPATCH_LOG="$LOG_DIR/dispatch-log.jsonl"
ACTIVE_LOG="$LOG_DIR/dispatch-active.jsonl"
mkdir -p "$LOG_DIR"

# ── Timestamp ─────────────────────────────────────────────────────────────────
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TS_LOCAL=$(date +"%Y-%m-%d %H:%M %Z")

# ── Build the full task prompt for the subagent ───────────────────────────────
# We prepend the agent's identity context so subagents know who they are
case "$AGENT" in
  myrmidons)
    AGENT_CONTEXT="You are a Myrmidon — a fast, cost-efficient task executor in GAIA CORP-OS. Execute the task below precisely and report the result. No fluff, just do it."
    ;;
  taoz)
    AGENT_CONTEXT="You are Taoz — the builder agent of GAIA CORP-OS. You write code, build skills, fix bugs, and deploy infrastructure. Read SOUL.md and AGENTS.md first if this is your first task. Use your full tool suite."
    ;;
  artemis)
    AGENT_CONTEXT="You are Artemis — the research agent of GAIA CORP-OS. You find information, research markets, scrape data, and deliver structured findings. Use web_search and web_fetch aggressively."
    ;;
  dreami)
    AGENT_CONTEXT="You are Dreami — the creative director of GAIA CORP-OS. You write compelling copy, develop campaign concepts, and give creative direction. Read brand briefs carefully. Output polished, ready-to-use content."
    ;;
  iris)
    AGENT_CONTEXT="You are Iris — the visual and social agent of GAIA CORP-OS. You generate images (use NanoBanana: gemini-3-pro-image-preview), manage social content, and handle visual direction. Always use NanoBanana for image generation."
    ;;
  athena)
    AGENT_CONTEXT="You are Athena — the strategy and analysis agent of GAIA CORP-OS. You analyze data, build strategic plans, write reports, and provide business insights. Think deeply and structure your outputs clearly."
    ;;
  hermes)
    AGENT_CONTEXT="You are Hermes — the ads and pricing agent of GAIA CORP-OS. You optimize Meta ads, structure pricing, analyze revenue, and manage Shopee/Lazada channel operations. Always show the math. Flag changes >RM 500 impact for human approval."
    ;;
esac

FULL_TASK="$AGENT_CONTEXT

---

TASK (dispatched by Zenni at $TS_LOCAL):
$TASK

---

When complete, post a brief summary of your results. If you write files, report the paths. If you need to escalate or are blocked, say so clearly."

# ── Print dispatch header ─────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DISPATCH: $AGENT → $LABEL"
echo "   Model:    $MODEL"
echo "   Cost:     $COST_TIER"
echo "   Thinking: $THINKING"
echo "   Timeout:  ${TIMEOUT}s"
echo "   Time:     $TS_LOCAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Log the dispatch (before spawn — so we have a record even if spawn fails) ─
DISPATCH_ENTRY=$(cat <<EOF
{"ts":"$TS","agent":"$AGENT","label":"$LABEL","model":"$MODEL","cost_tier":"$COST_TIER","thinking":"$THINKING","timeout":$TIMEOUT,"task_preview":"$(echo "$TASK" | head -c 200 | tr '\n' ' ' | sed 's/"/\\"/g')","status":"dispatched","session_id":"pending"}
EOF
)
echo "$DISPATCH_ENTRY" >> "$DISPATCH_LOG"
echo "$DISPATCH_ENTRY" >> "$ACTIVE_LOG"

echo "📋 Logged to dispatch-log.jsonl"
echo ""

# ── Dispatch note ─────────────────────────────────────────────────────────────
# dispatch.sh outputs the openclaw CLI command to spawn this agent.
# Zenni (the main agent) uses sessions_spawn via tool call — this script 
# can't call the OpenClaw tool API directly from bash.
# 
# So dispatch.sh serves TWO purposes:
#   1. In TOOL contexts (Zenni's AI session): provides the JSON config for sessions_spawn
#   2. In SHELL contexts (cron/scripts): emits the openclaw CLI command
#
# Output the sessions_spawn parameters as JSON for Zenni to use:
echo "📦 sessions_spawn config:"
echo ""
cat <<JSONEOF
{
  "agent_id":        "$AGENT",
  "label":           "$LABEL",
  "model":           "$MODEL",
  "thinking":        "$THINKING",
  "timeout_seconds": $TIMEOUT,
  "task":            $(echo "$FULL_TASK" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
}
JSONEOF

echo ""
echo "📌 CLI equivalent (if running from shell):"
echo "   openclaw agent --agent $AGENT --message \"$TASK\""
echo ""

# ── Update active log with a reminder ─────────────────────────────────────────
echo "⏳ Waiting for auto-announcement from subagent..."
echo "   Label: $LABEL | Agent: $AGENT"
echo "   When done: run 'bash track.sh done \"$LABEL\" success|fail \"summary\"'"
echo ""
