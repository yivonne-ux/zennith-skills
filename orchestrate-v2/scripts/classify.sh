#!/usr/bin/env bash
# classify.sh — Quick task classifier for Zenni
# Wraps route-task.py with SOUL.md hardcoded override rules
#
# Usage:
#   bash classify.sh "your task description"
#
# Output:
#   AGENT: <agent_id>
#   REASON: <why>
#   MODEL: <model>
#   COST_TIER: <cheapest|medium|high|premium>
#   COMPLEXITY: <simple|medium|complex>

set -euo pipefail

TASK="${1:-}"

if [[ -z "$TASK" ]]; then
  echo "❌ Usage: classify.sh \"task description\""
  exit 1
fi

TASK_LOWER=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')
ROUTER="$HOME/.openclaw/workspace/scripts/routing/route-task.py"

# ── HARDCODED OVERRIDES (from SOUL.md — these trump the router) ───────────────
# These patterns are so clear that we skip the router entirely.
# Ordered: most specific first.

classify_override() {
  local task="$1"

  # MYRMIDONS: simple operations (check, list, git, file ops, format, ping, send)
  if echo "$task" | grep -qiE '(check if|is (up|down|live|running)|git (status|log|push|pull|commit|add)|^ping |health.?check|list files|move file|rename file|copy file|create dir|mkdir|reformat|convert (csv|json)|post (this|result|summary) to (room|exec|build|creative)|fetch (url|file)|read .*(file|md|json) and|what.?s in |summarize this)'; then
    echo "myrmidons"
    return 0
  fi

  # TAOZ: code and builds
  if echo "$task" | grep -qiE '(write|build|create|fix|debug|deploy|refactor|install|script|api integration|landing page|database schema|migration|skill|infrastructure|cloudflare|wrangler).*?(code|page|skill|script|bug|error|app|function|component)|(build|create|write|fix) (a |the |this )?(react|python|typescript|bash|js|html|css|sql|skill|script|app|tool|function)'; then
    echo "taoz"
    return 0
  fi

  # ARTEMIS: research
  if echo "$task" | grep -qiE '(research|scrape|scrap|competitor|market (data|analysis|research)|find (info|data|details) (about|on)|trend analysis|news monitoring|monitor|competitive intel)'; then
    echo "artemis"
    return 0
  fi

  # DREAMI: creative copy
  if echo "$task" | grep -qiE '(write (copy|caption|edm|email|script|tagline|headline|brief)|copywriting|campaign (concept|brief|strategy)|brand voice|creative direction|bilingual|chinese (copy|content)|content strategy)'; then
    echo "dreami"
    return 0
  fi

  # IRIS: visual and social
  if echo "$task" | grep -qiE '(generate (image|photo|visual)|image generation|nanobanana|social (media )?post|instagram|tiktok|visual direction|mood board|community engagement)'; then
    echo "iris"
    return 0
  fi

  # ATHENA: strategy and analysis
  if echo "$task" | grep -qiE '(strateg(y|ic)|analyz(e|is)|analysis|forecast|report(ing)?|dashboard|okr|kpi|business (plan|case)|feasibility|performance review|multi.?variable)'; then
    echo "athena"
    return 0
  fi

  # HERMES: ads and pricing
  if echo "$task" | grep -qiE '(meta ads|ad (optimization|spend|budget)|pricing (strategy|model)|roas|shopee|lazada|revenue (campaign|optimization)|promotion mechanics|ad campaign)'; then
    echo "hermes"
    return 0
  fi

  # No override matched
  echo "auto"
  return 0
}

OVERRIDE=$(classify_override "$TASK_LOWER")

# ── MODEL MAP ─────────────────────────────────────────────────────────────────
agent_to_model() {
  case "$1" in
    myrmidons) echo "minimax-m2.5" ;;
    taoz)      echo "anthropic/claude-opus-4-6 (claude-code)" ;;
    artemis)   echo "kimi-k2.5 (web-search-pro)" ;;
    dreami)    echo "kimi-k2.5" ;;
    iris)      echo "qwen3-vl-235b" ;;
    athena)    echo "anthropic/claude-opus-4-6 (reasoning)" ;;
    hermes)    echo "anthropic/claude-opus-4-6 (reasoning)" ;;
    *)         echo "unknown" ;;
  esac
}

agent_to_cost() {
  case "$1" in
    myrmidons) echo "💚 cheapest ($0.14/$0.14 per M)" ;;
    taoz)      echo "🔴 premium" ;;
    artemis)   echo "🟡 medium" ;;
    dreami)    echo "🟡 medium" ;;
    iris)      echo "🟡 medium" ;;
    athena)    echo "🟠 high" ;;
    hermes)    echo "🟠 high" ;;
    *)         echo "unknown" ;;
  esac
}

# ── Complexity estimate ───────────────────────────────────────────────────────
estimate_complexity() {
  local task="$1"
  if echo "$task" | grep -qiE '(build|create|research|analyze|strategy|campaign|full|complete|end.?to.?end|multi.?step|integration)'; then
    echo "complex (>3 tool calls → DELEGATE)"
  elif echo "$task" | grep -qiE '(check|list|git|ping|read|fetch|post|send|move|rename|commit)'; then
    echo "simple (<3 tool calls → Myrmidons)"
  else
    echo "medium (verify before starting)"
  fi
}

COMPLEXITY=$(estimate_complexity "$TASK_LOWER")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 TASK CLASSIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task: $TASK"
echo ""

if [[ "$OVERRIDE" != "auto" ]]; then
  # Hardcoded override matched
  AGENT="$OVERRIDE"
  MODEL=$(agent_to_model "$AGENT")
  COST=$(agent_to_cost "$AGENT")
  echo "✅ AGENT:      ${AGENT^^}"
  echo "   Source:     SOUL.md override rule"
  echo "   Model:      $MODEL"
  echo "   Cost tier:  $COST"
  echo "   Complexity: $COMPLEXITY"
  echo ""
  echo "📋 Dispatch command:"
  echo "   bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \\"
  echo "     \"$AGENT\" \\"
  echo "     \"$TASK\" \\"
  echo "     \"${AGENT}-$(date +%H%M)\""
else
  # Fall back to route-task.py
  if [[ -f "$ROUTER" ]] && source ~/.openclaw/.env 2>/dev/null; then
    echo "🔀 Running auto-router..."
    echo ""
    ROUTER_RESULT=$(python3 "$ROUTER" "$TASK" --json 2>/dev/null | python3 -c "
import sys, json
results = json.loads(sys.stdin.read())
if results:
    top = results[0]
    print(f\"AGENT: {top['agent']}\")
    print(f\"SCORE: {top['total_score']}\")
    print(f\"REASON: {top['reasoning']}\")
" 2>/dev/null || echo "AGENT: myrmidons")
    AGENT=$(echo "$ROUTER_RESULT" | grep '^AGENT:' | cut -d' ' -f2 | tr -d '[:space:]')
    AGENT="${AGENT:-myrmidons}"
    MODEL=$(agent_to_model "$AGENT")
    COST=$(agent_to_cost "$AGENT")
    echo "✅ AGENT:      ${AGENT^^}"
    echo "   Source:     route-task.py"
    echo "$ROUTER_RESULT" | grep -v '^AGENT:' | sed 's/^/   /'
    echo "   Model:      $MODEL"
    echo "   Cost tier:  $COST"
    echo "   Complexity: $COMPLEXITY"
  else
    # Router unavailable — safe default
    echo "⚠️  Auto-router unavailable (no Supabase). Applying heuristic..."
    echo ""
    echo "✅ AGENT:      MYRMIDONS (safe default)"
    echo "   Source:     Fallback — no router"
    echo "   Model:      minimax-m2.5"
    echo "   Cost tier:  💚 cheapest"
    echo "   Complexity: $COMPLEXITY"
    AGENT="myrmidons"
  fi
  echo ""
  echo "📋 Dispatch command:"
  echo "   bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \\"
  echo "     \"$AGENT\" \\"
  echo "     \"$TASK\" \\"
  echo "     \"${AGENT}-$(date +%H%M)\""
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
