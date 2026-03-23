#!/bin/bash
# skill-router.sh — Intra-agent skill selector for Zennith OS
# Zero-cost keyword matching (like classify.sh) with optional LLM fallback.
# Usage: skill-router.sh "task description"
#        skill-router.sh --task "description" [--agent NAME] [--llm] [--json] [--all]
# macOS Bash 3.2 compatible — no associative arrays, no declare -A.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="$SKILL_DIR/data/skill-index.json"

# ─── Temp file for candidates (avoids Bash 3.2 array limitations) ───
CAND_FILE=$(mktemp /tmp/skill-router-cands.XXXXXX)
trap 'rm -f "$CAND_FILE"' EXIT

# ─── Defaults ───
TASK=""
AGENT=""
USE_LLM=0
JSON_OUT=0
SHOW_ALL=0

# ─── Parse args ───
while [ $# -gt 0 ]; do
  case "$1" in
    --task)   TASK="$2"; shift 2 ;;
    --agent)  AGENT="$2"; shift 2 ;;
    --llm)    USE_LLM=1; shift ;;
    --json)   JSON_OUT=1; shift ;;
    --all)    SHOW_ALL=1; shift ;;
    --help|-h)
      echo "Usage: skill-router.sh [OPTIONS] \"task description\""
      echo ""
      echo "Options:"
      echo "  --task \"...\"    Task description (alt to positional arg)"
      echo "  --agent NAME    Filter skills to those available for agent"
      echo "  --llm           Use Claude CLI for disambiguation"
      echo "  --json          Machine-readable JSON output"
      echo "  --all           Show all candidates with scores"
      echo "  --help          Show this help"
      exit 0
      ;;
    -*)
      echo "ERROR: Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [ -z "$TASK" ]; then
        TASK="$1"
      else
        TASK="$TASK $1"
      fi
      shift
      ;;
  esac
done

if [ -z "$TASK" ]; then
  echo "ERROR: No task description provided." >&2
  echo "Usage: skill-router.sh \"task description\"" >&2
  exit 1
fi

# ─── Normalize input ───
TASK_LOWER="$(echo "$TASK" | tr '[:upper:]' '[:lower:]')"

# ─── Agent filter ───
# Returns 0 (success) if skill is available to the agent, 1 otherwise.
# When AGENT is empty, all skills pass.
agent_filter() {
  local skill="$1"
  if [ -z "$AGENT" ]; then
    return 0
  fi
  local agents=""
  case "$skill" in
    nanobanana)              agents="dreami taoz" ;;
    product-studio)          agents="dreami taoz" ;;
    ad-composer)             agents="dreami taoz iris" ;;
    brand-studio)            agents="dreami taoz iris" ;;
    creative-studio)         agents="dreami taoz" ;;
    ig-character-gen)        agents="dreami taoz" ;;
    jade-content-studio)     agents="dreami taoz iris" ;;
    brand-prompt-library)    agents="dreami taoz" ;;
    style-control)           agents="dreami" ;;
    character-lock)          agents="dreami taoz" ;;
    clip-factory)            agents="dreami taoz iris" ;;
    video-compiler)          agents="dreami taoz" ;;
    video-forge)             agents="dreami taoz iris" ;;
    ai-voiceover)            agents="dreami taoz" ;;
    video-gen)               agents="dreami taoz" ;;
    content-repurpose)       agents="dreami iris taoz" ;;
    campaign-translate)      agents="dreami taoz" ;;
    campaign-planner)        agents="dreami taoz main" ;;
    content-supply-chain)    agents="main dreami taoz iris" ;;
    audience-simulator)      agents="dreami taoz" ;;
    fast-iterate)            agents="main dreami taoz" ;;
    content-tuner)           agents="main taoz" ;;
    notebooklm-research)     agents="taoz dreami" ;;
    rigour)                  agents="taoz" ;;
    visual-registry)         agents="dreami taoz" ;;
    image-seed-bank)         agents="dreami taoz" ;;
    social-publish)          agents="taoz main" ;;
    creative-intake)         agents="main dreami" ;;
    ref-picker)              agents="dreami taoz" ;;
    pinterest-ref)           agents="dreami taoz" ;;
    art-director)            agents="dreami iris" ;;
    grabfood-enhance)        agents="dreami taoz" ;;
    ai-influencer)           agents="dreami taoz main" ;;
    onboard-brand)           agents="main dreami" ;;
    *)                       agents="main dreami taoz iris" ;;
  esac
  echo "$agents" | grep -qw "$AGENT"
}

# ─── Candidate management ───
# Format in temp file: score|skill|reason  (one per line, sorted later)
CAND_COUNT=0

add_candidate() {
  local skill="$1"
  local score="$2"
  local reason="$3"

  # Check agent filter
  if ! agent_filter "$skill"; then
    return
  fi

  # Check if already present — keep higher score
  if grep -q "|${skill}|" "$CAND_FILE" 2>/dev/null; then
    local existing_score
    existing_score=$(grep "|${skill}|" "$CAND_FILE" | head -1 | cut -d'|' -f1)
    local is_higher
    is_higher=$(awk "BEGIN { print ($score > $existing_score) ? 1 : 0 }")
    if [ "$is_higher" = "1" ]; then
      # Remove old entry, add new
      grep -v "|${skill}|" "$CAND_FILE" > "${CAND_FILE}.tmp" || true
      mv "${CAND_FILE}.tmp" "$CAND_FILE"
      echo "${score}|${skill}|${reason}" >> "$CAND_FILE"
    fi
    return
  fi

  echo "${score}|${skill}|${reason}" >> "$CAND_FILE"
  CAND_COUNT=$((CAND_COUNT + 1))
}

# ─── Keyword helpers ───
matches() {
  echo "$TASK_LOWER" | grep -qiE "$1"
}

# ═══════════════════════════════════════════════
# ROUTING RULES (ordered by specificity)
# ═══════════════════════════════════════════════

# ─── IMAGE GENERATION ───

# Product photography / e-commerce
if matches "pack shot|product photo|product image|e-commerce image|product angle|shopee.*photo|lazada.*photo|product placement|product lifestyle"; then
  add_candidate "product-studio" "0.95" "product photography for e-commerce listings"
fi

# Ad images / banners / creatives
if matches "ad image|ad creative|ad visual|banner|ad design|creative asset|ad asset|recraft|flux"; then
  add_candidate "ad-composer" "0.90" "multi-model ad image generation"
fi

# Brand images / brand posts
if matches "brand image|brand visual|brand post|brand content.*image|brand asset"; then
  add_candidate "brand-studio" "0.88" "brand-aware image generation with audit loop"
fi

# Character / face lock / body pairing
if matches "character|face lock|face ref|body pair|body ref|turnaround|character sheet|expression sheet"; then
  add_candidate "creative-studio" "0.90" "character and asset creation control room"
fi
if matches "face lock|face consistency|character lock"; then
  add_candidate "character-lock" "0.92" "face and body consistency enforcement"
fi

# IG character content (daily lifestyle photos)
if matches "ig content|instagram daily|character lifestyle|influencer content|daily life.*photo"; then
  add_candidate "ig-character-gen" "0.88" "Instagram lifestyle content for AI characters"
fi

# AI influencer pipeline (full end-to-end)
if matches "ai influencer|influencer factory|influencer pipeline|tiktok.*character|scale.*influencer"; then
  add_candidate "ai-influencer" "0.90" "end-to-end AI influencer creation and scaling"
fi

# Jade Oracle content (character + divination)
if matches "jade|oracle|reading|qmdj|qi men|divination"; then
  if matches "image|photo|visual|content|ig|instagram|character"; then
    add_candidate "jade-content-studio" "0.93" "unified Jade Oracle content pipeline"
  fi
  if matches "reading|qmdj|qi men|divination"; then
    add_candidate "jade-content-studio" "0.85" "Jade Oracle content and readings pipeline"
  fi
fi

# Prompt packs / style seeds / style guides
if matches "prompt pack|prompt template|prompt library|style seed|mood preset|style guide|brand style"; then
  add_candidate "brand-prompt-library" "0.88" "curated prompt packs and style presets"
fi
if matches "style seed|mood preset|style explore|style direction|visual identity.*manage"; then
  add_candidate "style-control" "0.85" "brand visual identity and style management"
fi

# GrabFood enhancement
if matches "grabfood|grab food|food photo.*enhance|menu photo|food enhancement|hawker"; then
  add_candidate "grabfood-enhance" "0.92" "GrabFood menu photo enhancement pipeline"
fi

# Reference images / Pinterest
if matches "ref image|reference image|find ref|pick ref|suggest ref|ref picker"; then
  add_candidate "ref-picker" "0.90" "visual reference image picker and catalog"
fi
if matches "pinterest|pin board|visual ref.*extract|visual dna"; then
  add_candidate "pinterest-ref" "0.90" "Pinterest visual reference extraction"
fi

# Visual registry / asset management
if matches "visual registry|register.*asset|register.*sku|multi.angle|asset catalog"; then
  add_candidate "visual-registry" "0.88" "multi-angle asset registration and assembly"
fi
if matches "seed bank|image.*store|image.*catalog|image.*archive|seed.*index"; then
  add_candidate "image-seed-bank" "0.88" "image asset storage and retrieval"
fi

# Generic image generation (lowest priority in image group)
if matches "generate image|create image|make image|gen image|image gen"; then
  add_candidate "nanobanana" "0.70" "core image generation engine (Gemini)"
  add_candidate "ad-composer" "0.50" "multi-model image generation (if ad context)"
fi

# Art direction
if matches "art direct|creative direct|design review|visual review|design feedback|aesthetic"; then
  add_candidate "art-director" "0.88" "world-class art direction and design critique"
fi

# ─── VIDEO ───

# Clip extraction from long video
if matches "clip|split video|highlight|viral clip|extract.*clip|short.*from.*long|reels.*from"; then
  add_candidate "clip-factory" "0.90" "long video to short viral clips pipeline"
fi

# Video compilation / ad assembly
if matches "compile.*video|assemble.*video|stitch|aida.*video|video ad|ugc.*video|video.*ad"; then
  add_candidate "video-compiler" "0.88" "video ad production with AIDA blocks"
  add_candidate "ad-composer" "0.70" "multi-model ad generation (image+video)"
fi

# Video post-production
if matches "caption|subtitle|brand overlay|watermark|music.*mix|auto.duck|effects|post.prod|color grade|grain|vignette"; then
  add_candidate "video-forge" "0.90" "video post-production pipeline"
fi

# Voiceover / TTS
if matches "voiceover|voice over|tts|narration|text.to.speech|voice gen"; then
  add_candidate "ai-voiceover" "0.92" "AI voice generation for video and audio"
fi

# Generic video generation
if matches "generate.*video|create.*video|make.*video|text.to.video|image.to.video|video gen"; then
  add_candidate "video-gen" "0.75" "core video generation engine (Kling/Wan/Sora)"
fi
if matches "video"; then
  # Low-confidence fallback if video is mentioned but nothing else matched
  local_count=$(wc -l < "$CAND_FILE" | tr -d ' ')
  has_video=$(grep -c "video" "$CAND_FILE" 2>/dev/null || echo "0")
  if [ "$local_count" = "0" ] || [ "$has_video" = "0" ]; then
    add_candidate "video-gen" "0.40" "core video generation engine"
  fi
fi

# ─── CONTENT PIPELINE ───

# Repurpose / resize / reformat
if matches "repurpose|resize|reformat|platform variant|adapt.*platform|cross.platform|multi.platform.*format"; then
  add_candidate "content-repurpose" "0.90" "one asset to all platform variants"
fi

# Translation / transcreation
if matches "translate|transcreate|bahasa|mandarin|multilingual|locali[sz]e|multi.language"; then
  add_candidate "campaign-translate" "0.92" "multilingual transcreation engine"
fi

# Campaign planning
if matches "campaign.*plan|campaign.*brief|ad.*brief|campaign.*budget|media.*plan"; then
  add_candidate "campaign-planner" "0.88" "campaign brief and budget generation"
fi

# Content supply chain (full loop)
if matches "content cycle|supply chain|full loop|content.*pipeline|end.to.end.*content|content factory"; then
  add_candidate "content-supply-chain" "0.90" "full content production loop with compounding"
fi

# Creative intake (entry point)
if matches "creative intake|intake|route.*creative|classify.*creative|input.*creative"; then
  add_candidate "creative-intake" "0.88" "reference-to-production routing entry point"
fi

# Audience simulator / pre-test
if matches "pre.test|audience reaction|persona test|simulate.*audience|test.*before.*publish|audience.*sim"; then
  add_candidate "audience-simulator" "0.92" "pre-test content with persona-based simulation"
fi

# Fast iterate / variant scoring
if matches "iterate|improve.*variant|score variant|fast iterate|variant.*gen|generate.*variant|a/b.*variant"; then
  add_candidate "fast-iterate" "0.88" "generate, score, and evolve content variants"
fi

# Content tuner / winning patterns
if matches "tune|winning pattern|a/b test|content.*tune|pattern.*promot|underperform"; then
  add_candidate "content-tuner" "0.88" "self-tuning engine for winning content patterns"
fi

# Research
if matches "research|notebooklm|deep dive|source analysis|knowledge synthesis"; then
  add_candidate "notebooklm-research" "0.85" "deep research pipeline via NotebookLM"
fi

# Social publishing
if matches "publish|post.*instagram|post.*ig|schedule.*post|meta.*graph|instagram.*api"; then
  add_candidate "social-publish" "0.88" "Instagram publishing via Meta Graph API"
fi

# ─── QUALITY / INFRASTRUCTURE ───

# Rigour gate
if matches "rigour|quality gate|ship check|code review|pre.ship|lint|syntax check"; then
  add_candidate "rigour" "0.92" "mandatory quality gate before shipping code"
fi

# Audit with context
if matches "audit|score|quality check|review|qa"; then
  if matches "image|photo|visual|brand.*image|creative.*image"; then
    add_candidate "brand-studio" "0.85" "brand image audit with visual QA loop"
  fi
  if matches "video|clip|footage"; then
    add_candidate "video-forge" "0.82" "video audit and quality check"
  fi
fi

# Brand onboarding
if matches "onboard.*brand|new brand|create brand|brand.*setup|brand.*dna.*creat"; then
  add_candidate "onboard-brand" "0.92" "new brand creation and DNA generation"
fi

# ─── FALLBACK ───

CAND_COUNT=$(wc -l < "$CAND_FILE" | tr -d ' ')
if [ "$CAND_COUNT" = "0" ]; then
  if matches "image|photo|visual|picture|graphic"; then
    add_candidate "nanobanana" "0.50" "generic image generation (no specific skill matched)"
    add_candidate "brand-studio" "0.40" "brand-aware image generation with audit"
  fi
  if matches "video|clip|animate|motion"; then
    add_candidate "video-gen" "0.50" "generic video generation (no specific skill matched)"
  fi
  if matches "copy|write|caption|headline|script|text"; then
    add_candidate "campaign-planner" "0.40" "campaign copy and brief generation"
    add_candidate "content-supply-chain" "0.35" "full content production pipeline"
  fi
fi

# ─── Sort candidates by score (descending) ───
SORTED=$(sort -t'|' -k1 -rn "$CAND_FILE" 2>/dev/null || true)
CAND_COUNT=$(wc -l < "$CAND_FILE" | tr -d ' ')

# ─── LLM disambiguation ───
if [ "$USE_LLM" = "1" ] && [ "$CAND_COUNT" -gt 1 ]; then
  TOP_SCORE=$(echo "$SORTED" | head -1 | cut -d'|' -f1)
  SECOND_SCORE=$(echo "$SORTED" | sed -n '2p' | cut -d'|' -f1)

  if [ -n "$SECOND_SCORE" ]; then
    DIFF=$(awk "BEGIN { print $TOP_SCORE - $SECOND_SCORE }")
    IS_CLOSE=$(awk "BEGIN { print ($DIFF < 0.15) ? 1 : 0 }")

    if [ "$IS_CLOSE" = "1" ]; then
      # Build candidate list for LLM
      LLM_CANDIDATES=""
      while IFS='|' read -r score skill reason; do
        LLM_CANDIDATES="${LLM_CANDIDATES}- ${skill} (${score}): ${reason}"$'\n'
      done <<< "$SORTED"

      LLM_PROMPT="You are a skill router for Zennith OS. Given a task and candidate skills, pick the single best skill.

Task: $TASK

Candidates:
${LLM_CANDIDATES}
Respond with ONLY the skill name, nothing else."

      LLM_RESULT=""
      if command -v claude >/dev/null 2>&1; then
        LLM_RESULT=$(echo "$LLM_PROMPT" | claude --print 2>/dev/null || true)
      fi

      if [ -n "$LLM_RESULT" ]; then
        LLM_SKILL=$(echo "$LLM_RESULT" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        # Boost the LLM-selected skill to 0.95
        NEW_SORTED=""
        while IFS='|' read -r score skill reason; do
          [ -z "$skill" ] && continue
          if [ "$skill" = "$LLM_SKILL" ]; then
            NEW_SORTED="${NEW_SORTED}0.95|${skill}|${reason} (LLM confirmed)"$'\n'
          else
            NEW_SORTED="${NEW_SORTED}${score}|${skill}|${reason}"$'\n'
          fi
        done <<< "$SORTED"
        SORTED=$(echo "$NEW_SORTED" | sort -t'|' -k1 -rn | grep -v '^$')
      fi
    fi
  fi
fi

# ─── Output ───

if [ "$CAND_COUNT" = "0" ]; then
  if [ "$JSON_OUT" = "1" ]; then
    echo '{"skill":null,"confidence":0,"reason":"no matching skill found","candidates":[]}'
  else
    echo "NO MATCH (0.00) — no skill matched the task description"
    echo "Task: $TASK"
    echo "Hint: try --llm for LLM-based disambiguation, or check skill-index.json"
  fi
  exit 1
fi

if [ "$JSON_OUT" = "1" ]; then
  TOP_LINE=$(echo "$SORTED" | head -1)
  TOP_SCORE=$(echo "$TOP_LINE" | cut -d'|' -f1)
  TOP_SKILL=$(echo "$TOP_LINE" | cut -d'|' -f2)
  TOP_REASON=$(echo "$TOP_LINE" | cut -d'|' -f3-)

  if [ "$SHOW_ALL" = "1" ]; then
    echo -n "{\"skill\":\"$TOP_SKILL\",\"confidence\":$TOP_SCORE,\"reason\":\"$TOP_REASON\",\"candidates\":["
    FIRST=1
    while IFS='|' read -r score skill reason; do
      [ -z "$skill" ] && continue
      if [ "$FIRST" = "1" ]; then
        FIRST=0
      else
        echo -n ","
      fi
      echo -n "{\"skill\":\"$skill\",\"confidence\":$score,\"reason\":\"$reason\"}"
    done <<< "$SORTED"
    echo "]}"
  else
    echo "{\"skill\":\"$TOP_SKILL\",\"confidence\":$TOP_SCORE,\"reason\":\"$TOP_REASON\"}"
  fi
else
  if [ "$SHOW_ALL" = "1" ]; then
    while IFS='|' read -r score skill reason; do
      [ -z "$skill" ] && continue
      printf "%s (%.2f) — %s\n" "$skill" "$score" "$reason"
    done <<< "$SORTED"
  else
    TOP_LINE=$(echo "$SORTED" | head -1)
    TOP_SCORE=$(echo "$TOP_LINE" | cut -d'|' -f1)
    TOP_SKILL=$(echo "$TOP_LINE" | cut -d'|' -f2)
    TOP_REASON=$(echo "$TOP_LINE" | cut -d'|' -f3-)
    printf "%s (%.2f) — %s\n" "$TOP_SKILL" "$TOP_SCORE" "$TOP_REASON"
  fi
fi
