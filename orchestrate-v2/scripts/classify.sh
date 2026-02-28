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

  # CREATIVE PIPELINE: video production + character creation workflows route to Zennith (multi-step, multi-agent)
  # These MUST be checked before individual agent rules to avoid partial routing
  # Covers: intro videos, UGC, character creation/generation, video pipelines
  if echo "$task" | grep -qiE '(intro.?video|self.?intro.?video|character.?intro|ugc.?video|product.?ugc|character.?lock|video.?pipeline|creative.?pipeline|make.*(intro|ugc).*(video|clip|reel)|do .*(ugc|intro|product).*(video|reel)|lock.*(character|face|avatar)|6.?sec.*(intro|video)|agent.*(intro|video)|brand.*(intro|ugc|video)|create.*(character|persona|avatar)|generate.*(character|persona)|character.*(gen|creat|produc|pipeline)|make.*(character|persona))'; then
    echo "zennith-pipeline"
    return 0
  fi

  # MYRMIDONS: simple operations (check, list, git, file ops, format, ping, send)
  if echo "$task" | grep -qiE '(check if|is (up|down|live|running)|git (status|log|push|pull|commit|add)|^ping |health.?check|list files|move file|rename file|copy file|create dir|mkdir|reformat|convert (csv|json)|post (this|result|summary) to (room|exec|build|creative)|fetch (url|file)|read .*(file|md|json) and|what.?s in |summarize this)'; then
    echo "myrmidons"
    return 0
  fi

  # TAOZ: code and builds → route through ZENNITH (Zennith briefs Taoz, not Zenni direct)
  # Architectural principle: Zenni never dispatches to Taoz directly.
  # Zennith understands architecture, briefs Taoz, sandboxes, diagnoses, learns, deploys.
  if echo "$task" | grep -qiE '(write|build|create|fix|debug|deploy|refactor|install|script|api integration|landing page|database schema|migration|skill|infrastructure|cloudflare|wrangler).*?(code|page|skill|script|bug|error|app|function|component)|(build|create|write|fix) (a |the |this )?(react|python|typescript|bash|js|html|css|sql|skill|script|app|tool|function)'; then
    echo "zennith"
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

  # IRIS: visual, social, character design, avatar, style references
  if echo "$task" | grep -qiE '(generate .*(image|photo|visual|poster|banner|thumbnail)|image generation|nanobanana|social (media )?post|instagram|tiktok|visual direction|mood board|community engagement|character (design|sheet|concept)|avatar|art style|editorial style|style of|selfie|storyboard|reverse.?prompt|visual.?qa|brand.?visual|heyshiro|heysirio|ohneis|persona.?gen|product image|create .*(image|visual|graphic))'; then
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

  # BEE001: revenue, products, gumroad, info products, monetization
  if echo "$task" | grep -qiE '(gumroad|info.?product|digital.?product|revenue.?stream|monetiz|tiktok.?shop|product.?launch|sales.?funnel|lead.?magnet|ebook|course|template.?pack)'; then
    echo "bee001"
    return 0
  fi

  # ARGUS: testing, QA, regression, verification
  if echo "$task" | grep -qiE '(test|qa|quality.?assur|regression|verify|validate|check.?if.?work|e2e|end.?to.?end.?test|smoke.?test|sanity.?check)'; then
    echo "argus"
    return 0
  fi

  # No override matched
  echo "auto"
  return 0
}

OVERRIDE=$(classify_override "$TASK_LOWER")

# ── MODEL MAP (reads from openclaw.json — source of truth) ────────────────────
agent_to_model() {
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

agent_to_cost() {
  case "$1" in
    myrmidons) echo "💚 cheapest (minimax-m2.5)" ;;
    taoz)      echo "💚 cheapest (glm-4.7-flash, chat only - real builds via Claude Code CLI)" ;;
    artemis)   echo "🆓 free (kimi-k2.5 Moonshot direct)" ;;
    dreami)    echo "🆓 free (kimi-k2.5 Moonshot direct)" ;;
    iris)      echo "🟡 medium (qwen3-vl OpenRouter)" ;;
    athena)    echo "🟡 medium (glm-5)" ;;
    hermes)    echo "🟡 medium (glm-5)" ;;
    argus)     echo "🟡 medium (glm-5)" ;;
    bee001)    echo "💚 cheapest (glm-4.7-flash)" ;;
    zennith)   echo "🟡 medium (glm-5 — Layer 2 supervisor)" ;;
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

# ── ZENNITH ESCALATION CHECK ─────────────────────────────────────────────────
# Multi-agent or sequential tasks escalate to Zennith (Layer 2 supervisor)
check_zennith_escalation() {
  local task="$1"

  # Sequential connectors
  if echo "$task" | grep -qiE '(then (write|create|generate|build|research|analyze|post|deploy|turn|convert|make)|once (done|complete|finished|ready|confirm|approved|happy)|after (research|analysis|artemis|dreami|athena|that|this)|followed by|next step|step [0-9]|turn (it |this )?(to|into) (video|image|post)|confirm.*(then|turn|convert|make))'; then
    echo "sequential"; return 0
  fi

  # Vague umbrella requests
  if echo "$task" | grep -qiE '(build (me )?(a |the )?campaign|run (a |the )?campaign|full campaign|content (series|calendar|plan) for|fix everything|make (this|it) work|end.?to.?end|launch (a |the )?(campaign|product|brand))'; then
    echo "umbrella"; return 0
  fi

  # Multi-agent scope (2+ domain verbs)
  local score=0
  echo "$task" | grep -qiE '(research|scrape|competitor|market data|find info)' && score=$((score+1))
  echo "$task" | grep -qiE '(write copy|caption|script|tagline|creative brief|copywriting)' && score=$((score+1))
  echo "$task" | grep -qiE '(generate image|nanobanana|visual|mood board|instagram|tiktok post|character|avatar|art style|selfie|storyboard)' && score=$((score+1))
  echo "$task" | grep -qiE '(video|animation|kling|wan|sora|self.?intro|6.?sec|reels|video.?pipeline|creative.?pipeline|ugc|intro.?video|character.?lock|product.?ugc|keyframe|post.?prod)' && score=$((score+1))
  echo "$task" | grep -qiE '(build|deploy|code|fix bug|landing page|skill)' && score=$((score+1))
  echo "$task" | grep -qiE '(analyz|strateg|forecast|report|kpi|performance)' && score=$((score+1))
  echo "$task" | grep -qiE '(meta ads|pricing|roas|shopee|lazada|ad (spend|budget))' && score=$((score+1))
  if [ "$score" -ge 2 ]; then
    echo "multi-agent"; return 0
  fi

  # Word count > 80
  local wc
  wc=$(echo "$task" | wc -w | tr -d ' ')
  if [ "$wc" -gt 80 ]; then
    echo "long-context"; return 0
  fi

  echo "no"; return 0
}

ESCALATE=$(check_zennith_escalation "$TASK_LOWER")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 TASK CLASSIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task: $TASK"
echo ""

# Creative pipeline override — route through Zennith with creative-pipeline.sh hint
if [[ "$OVERRIDE" = "zennith-pipeline" ]]; then
  echo "🎬 CREATIVE PIPELINE detected (multi-step video production)"
  echo "✅ AGENT:      ZENNITH (Layer 2 — orchestrates creative-pipeline.sh)"
  echo "   Source:     creative pipeline keyword match"
  echo "   Model:      openrouter/z-ai/glm-5 (reasoning)"
  echo "   Cost tier:  🟡 medium (orchestration only — video gen costs tracked separately)"
  echo "   Complexity: $COMPLEXITY"
  echo ""
  echo "📋 Dispatch (via Zennith orchestration):"
  echo "   bash ~/.openclaw/skills/mission-control/scripts/dispatch.sh \\"
  echo "     zenni zennith orchestrate \"$TASK\" creative"
  echo ""
  echo "🎬 Or run creative-pipeline.sh directly:"
  echo "   bash ~/.openclaw/skills/creative-production/scripts/creative-pipeline.sh \\"
  echo "     <intro|ugc|product-ugc|character-lock> <agent> <brand> \"<brief>\""
  # Workflow lookup for pipeline routes
  WORKFLOW_LOOKUP="$HOME/.openclaw/workspace/scripts/workflow-lookup.sh"
  if [ -f "$WORKFLOW_LOOKUP" ]; then
    WORKFLOW_RESULT=$(bash "$WORKFLOW_LOOKUP" "$TASK" 2>/dev/null || true)
    if [ -n "$WORKFLOW_RESULT" ] && ! echo "$WORKFLOW_RESULT" | grep -q '"error"'; then
      WF_ID=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
      WF_NAME=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))" 2>/dev/null || true)
      WF_DOC=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('doc_path',''))" 2>/dev/null || true)
      WF_CMD=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('entry_command',''))" 2>/dev/null || true)
      if [ -n "$WF_ID" ]; then
        echo ""
        echo "📖 WORKFLOW:   $WF_ID ($WF_NAME)"
        echo "   Doc:        $WF_DOC"
        echo "   Command:    $WF_CMD"
      fi
    fi
  fi
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Zennith escalation takes priority (except for myrmidons/argus/taoz explicit tasks)
if [[ "$ESCALATE" != "no" ]] && [[ "$OVERRIDE" != "myrmidons" ]] && [[ "$OVERRIDE" != "argus" ]] && [[ "$OVERRIDE" != "taoz" ]]; then
  echo "⚡ ESCALATE:   ZENNITH (Layer 2 — reason: $ESCALATE)"
  echo "✅ AGENT:      ZENNITH"
  echo "   Source:     complexity escalation gate"
  echo "   Model:      openrouter/z-ai/glm-5 (reasoning)"
  echo "   Cost tier:  🟡 medium (only for multi-step tasks)"
  echo "   Complexity: $COMPLEXITY"
  echo ""
  echo "📋 Dispatch:"
  echo "   bash ~/.openclaw/skills/mission-control/scripts/dispatch.sh \\"
  echo "     zenni zennith orchestrate \"$TASK\" zennith"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

if [[ "$OVERRIDE" != "auto" ]]; then
  # Hardcoded override matched
  AGENT="$OVERRIDE"
  MODEL=$(agent_to_model "$AGENT")
  COST=$(agent_to_cost "$AGENT")
  echo "✅ AGENT:      $(echo "$AGENT" | tr '[:lower:]' '[:upper:]')"
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
    echo "✅ AGENT:      $(echo "$AGENT" | tr '[:lower:]' '[:upper:]')"
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

# ── WORKFLOW LOOKUP (enriches routing with workflow context) ─────────────────
WORKFLOW_LOOKUP="$HOME/.openclaw/workspace/scripts/workflow-lookup.sh"
if [ -f "$WORKFLOW_LOOKUP" ]; then
  WORKFLOW_RESULT=$(bash "$WORKFLOW_LOOKUP" "$TASK" 2>/dev/null || true)
  if [ -n "$WORKFLOW_RESULT" ] && ! echo "$WORKFLOW_RESULT" | grep -q '"error"'; then
    WF_ID=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
    WF_NAME=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))" 2>/dev/null || true)
    WF_DOC=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('doc_path',''))" 2>/dev/null || true)
    WF_CMD=$(echo "$WORKFLOW_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('entry_command',''))" 2>/dev/null || true)
    if [ -n "$WF_ID" ]; then
      echo ""
      echo "📖 WORKFLOW:   $WF_ID ($WF_NAME)"
      echo "   Doc:        $WF_DOC"
      echo "   Command:    $WF_CMD"
      echo "   Lookup:     bash workflow-lookup.sh --id $WF_ID"
    fi
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
