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

# ── Agent → Model (reads from openclaw.json — source of truth) ────────────────
get_model() {
  local agent="$1"
  local config="$HOME/.openclaw/openclaw.json"
  # Read primary model from openclaw.json (source of truth)
  local model
  model=$(python3 -c "
import json, os
with open(os.path.expanduser('$config')) as f:
    data = json.load(f)
for a in data['agents']['list']:
    if a['id'] == '$agent':
        print(a.get('model',{}).get('primary',''))
        break
" 2>/dev/null)
  if [[ -n "$model" ]]; then
    echo "$model"
  else
    echo "openrouter/z-ai/glm-4.7-flash"  # safe fallback
  fi
}

get_cost_tier() {
  case "$1" in
    myrmidons) echo "cheapest (minimax-m2.5)" ;;
    taoz)      echo "cheapest (glm-4.7-flash, chat only - real builds via Claude Code CLI)" ;;
    artemis)   echo "free (kimi-k2.5 Moonshot direct)" ;;
    dreami)    echo "free (kimi-k2.5 Moonshot direct)" ;;
    iris)      echo "medium (qwen3-vl OpenRouter)" ;;
    athena)    echo "medium (glm-5)" ;;
    hermes)    echo "medium (glm-5)" ;;
    argus)     echo "medium (glm-5)" ;;
    bee001)    echo "cheapest (glm-4.7-flash)" ;;
    *)         echo "unknown" ;;
  esac
}

get_agent_context() {
  case "$1" in
    myrmidons)
      echo "You are a Myrmidon — a fast, cost-efficient task executor in GAIA CORP-OS. Execute the task below precisely and report the result. No fluff, just do it."
      ;;
    taoz)
      echo "You are Taoz — the builder agent of GAIA CORP-OS. You write code, build skills, fix bugs, and deploy infrastructure. Use your full tool suite. Run regression if touching Creative Studio."
      ;;
    artemis)
      echo "You are Artemis — the research agent of GAIA CORP-OS. You find information, research markets, scrape data, and deliver structured findings. Use web_search and web_fetch aggressively."
      ;;
    dreami)
      echo "You are Dreami — the creative director of GAIA CORP-OS. You write compelling copy, develop campaign concepts, and give creative direction. Output polished, ready-to-use content."
      ;;
    iris)
      echo "You are Iris — the visual and social agent of GAIA CORP-OS. You generate images (use NanoBanana: gemini-3-pro-image-preview), manage social content, and handle visual direction."
      ;;
    athena)
      echo "You are Athena — the strategy and analysis agent of GAIA CORP-OS. You analyze data, build strategic plans, write reports, and provide business insights. Think deeply; structure outputs clearly."
      ;;
    hermes)
      echo "You are Hermes — the ads and pricing agent of GAIA CORP-OS. You optimize Meta ads, structure pricing, analyze revenue, and manage Shopee/Lazada channel operations. Always show the math. Flag changes >RM 500 impact for human approval."
      ;;
  esac
}

# ── Validate agent ────────────────────────────────────────────────────────────
MODEL=$(get_model "$AGENT")
if [[ -z "$MODEL" ]]; then
  echo "❌ Unknown agent: '$AGENT'"
  echo "   Valid: myrmidons | taoz | artemis | dreami | iris | athena | hermes"
  exit 1
fi

COST_TIER=$(get_cost_tier "$AGENT")
AGENT_CONTEXT=$(get_agent_context "$AGENT")

# ── Log paths ─────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.openclaw/logs"
DISPATCH_LOG="$LOG_DIR/dispatch-log.jsonl"
ACTIVE_LOG="$LOG_DIR/dispatch-active.jsonl"
mkdir -p "$LOG_DIR"

# ── Timestamp ─────────────────────────────────────────────────────────────────
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TS_LOCAL=$(date +"%Y-%m-%d %H:%M %Z")

# ── Build the full task prompt for the subagent ───────────────────────────────
FULL_TASK="${AGENT_CONTEXT}

---

TASK (dispatched by Zenni at ${TS_LOCAL}):
${TASK}

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

# ── Log the dispatch ──────────────────────────────────────────────────────────
TASK_PREVIEW=$(echo "$TASK" | head -c 200 | tr '\n' ' ' | sed 's/"/\\"/g')
DISPATCH_ENTRY="{\"ts\":\"$TS\",\"agent\":\"$AGENT\",\"label\":\"$LABEL\",\"model\":\"$MODEL\",\"cost_tier\":\"$COST_TIER\",\"thinking\":\"$THINKING\",\"timeout\":$TIMEOUT,\"task_preview\":\"$TASK_PREVIEW\",\"status\":\"dispatched\",\"session_id\":\"pending\"}"
echo "$DISPATCH_ENTRY" >> "$DISPATCH_LOG"
echo "$DISPATCH_ENTRY" >> "$ACTIVE_LOG"

echo "📋 Logged to dispatch-log.jsonl"
echo ""

# ── Output sessions_spawn config (for Zenni to use as tool call) ──────────────
# dispatch.sh serves two purposes:
#   1. Shell context: emits openclaw CLI command + sessions_spawn JSON params
#   2. AI context: Zenni reads this output and uses sessions_spawn tool directly
#
echo "📦 sessions_spawn config (use this in your sessions_spawn tool call):"
echo ""
python3 -c "
import json, sys
task = sys.argv[1]
agent = sys.argv[2]
model = sys.argv[3]
label = sys.argv[4]
thinking = sys.argv[5]
timeout = int(sys.argv[6])

config = {
    'label': label,
    'model': model,
    'thinking': thinking,
    'timeoutSeconds': timeout,
    'task': task
}
print(json.dumps(config, indent=2, ensure_ascii=False))
" "$FULL_TASK" "$AGENT" "$MODEL" "$LABEL" "$THINKING" "$TIMEOUT"

echo ""
echo "📌 CLI equivalent (if running from shell):"
echo "   openclaw agent --agent $AGENT --message \"$(echo "$TASK" | head -c 80)...\""
echo ""
echo "⏳ Result will auto-announce when subagent completes."
echo "   Label: $LABEL"
echo "   When done: bash track.sh done \"$LABEL\" success|fail \"summary\""
echo ""
