#!/usr/bin/env bash
# test-dispatch-routing.sh — Routing regression tests for classify.sh
# Tests 67 routing cases across all 5 tiers: RELAY, LOOKUP, SCRIPT, CODE, DISPATCH
# 4-agent roster: main (Zenni), taoz, dreami, scout + jade
# macOS Bash 3.2 compatible (no declare -A, no ${var,,})
#
# Usage: bash test-dispatch-routing.sh [--verbose]

set -uo pipefail

CLASSIFY="$HOME/.openclaw-dev/skills/orchestrate-v2/scripts/classify.sh"
VERBOSE=false
if [ "${1:-}" = "--verbose" ]; then VERBOSE=true; fi

# Colors (ANSI)
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0

# ── Test runner ──────────────────────────────────────────────────────────────
# Usage: run_test "description" "task string" "expected_tier" "expected_agent"
#   expected_tier: relay, script, code, dispatch, lookup
#   expected_agent: main, taoz, dreami, scout, jade
run_test() {
  local desc="$1"
  local task="$2"
  local exp_tier="$3"
  local exp_agent="$4"

  TOTAL=$((TOTAL + 1))

  # Run classify.sh with --auto-dispatch, capture first line
  local output
  output=$(bash "$CLASSIFY" "$task" --auto-dispatch 2>/dev/null) || true
  local first_line
  first_line=$(echo "$output" | head -1)

  # Parse tier and agent from first line
  # Formats: RELAY:agent, LOOKUP:agent, SCRIPT:label, CODE:subtier:label, DISPATCH:agent:label
  local got_tier=""
  local got_agent=""

  case "$first_line" in
    RELAY:*)
      got_tier="relay"
      got_agent=$(echo "$first_line" | cut -d: -f2)
      ;;
    LOOKUP:*)
      got_tier="lookup"
      got_agent=$(echo "$first_line" | cut -d: -f2)
      ;;
    SCRIPT:*)
      got_tier="script"
      # Agent comes from AGENT: line or we infer from TYPE line
      got_agent=$(echo "$output" | grep '^AGENT:' | head -1 | cut -d: -f2)
      # Script tier doesn't always emit AGENT line — check TYPE for inference
      if [ -z "$got_agent" ]; then
        local stype
        stype=$(echo "$output" | grep '^TYPE:' | head -1 | cut -d: -f2)
        case "$stype" in
          evomap) got_agent="taoz" ;;
          video-compiler|clip-factory) got_agent="dreami" ;;
          *) got_agent="dreami" ;;  # default: image gen scripts route to dreami
        esac
      fi
      ;;
    CODE:*)
      got_tier="code"
      got_agent=$(echo "$output" | grep '^AGENT:' | head -1 | cut -d: -f2)
      if [ -z "$got_agent" ]; then got_agent="taoz"; fi
      ;;
    DISPATCH:*)
      got_tier="dispatch"
      got_agent=$(echo "$first_line" | cut -d: -f2)
      ;;
    DENIED:*)
      got_tier="denied"
      got_agent=$(echo "$first_line" | cut -d: -f2)
      ;;
    *)
      got_tier="unknown"
      got_agent="unknown"
      ;;
  esac

  # Check match
  local tier_ok=false
  local agent_ok=false

  if [ "$got_tier" = "$exp_tier" ]; then tier_ok=true; fi
  if [ "$got_agent" = "$exp_agent" ]; then agent_ok=true; fi

  local expected_str="${exp_tier}:${exp_agent}"
  local got_str="${got_tier}:${got_agent}"

  if $tier_ok && $agent_ok; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "${GREEN}[PASS]${RESET} %s ${CYAN}-> %s${RESET} (got: %s)\n" "$desc" "$expected_str" "$got_str"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "${RED}[FAIL]${RESET} %s ${CYAN}-> %s${RESET} ${RED}(got: %s)${RESET}\n" "$desc" "$expected_str" "$got_str"
    if $VERBOSE; then
      printf "       Task: %s\n" "$task"
      printf "       Raw:  %s\n" "$first_line"
    fi
  fi
}

# ── Print header ─────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}Zennith Routing Regression Test${RESET}\n"
echo "============================"
echo "Classify: $CLASSIFY"
echo "Date:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1: CODE TIER — build/fix/deploy tasks → taoz via Claude Code CLI
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── CODE tier (taoz/claude-code) ──${RESET}\n"

run_test "build a new skill for image scoring" \
  "build a new skill for image scoring" \
  "code" "taoz"

run_test "fix the nanobanana script error" \
  "fix the nanobanana script error" \
  "code" "taoz"

run_test "deploy the cloudflare worker" \
  "deploy the cloudflare worker" \
  "code" "taoz"

run_test "refactor the dispatch pipeline" \
  "refactor the dispatch pipeline" \
  "code" "taoz"

run_test "create a python API integration for stripe" \
  "create a python API integration for stripe" \
  "code" "taoz"

run_test "debug why the cron automation is failing" \
  "debug why the cron automation is failing" \
  "code" "taoz"

run_test "set up a new webhook for shopify" \
  "set up a new webhook for shopify" \
  "code" "taoz"

run_test "write a bash script to sync files" \
  "write a bash script to sync files" \
  "code" "taoz"

run_test "build a shopify webhook integration" \
  "build a shopify webhook integration" \
  "code" "taoz"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2: SCRIPT TIER — image gen, bulk gen, clip factory, evomap
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── SCRIPT tier (CLI execution) ──${RESET}\n"

run_test "generate a mirra comparison ad" \
  "generate a mirra comparison ad" \
  "script" "dreami"

run_test "create a pinxin hero ad" \
  "create a pinxin hero ad" \
  "script" "dreami"

run_test "make a wholey wonder lifestyle ad" \
  "make a wholey wonder lifestyle ad" \
  "script" "dreami"

run_test "generate a serein product image" \
  "generate a serein product image" \
  "script" "dreami"

run_test "evomap status" \
  "evomap status" \
  "script" "taoz"

run_test "split this video into clips" \
  "split this video into clips" \
  "script" "dreami"

run_test "compile video ad for mirra bento" \
  "compile video ad for mirra bento" \
  "script" "dreami"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3: RELAY TIER — greetings, acks (Zenni handles)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── RELAY tier (Zenni direct) ──${RESET}\n"

run_test "hi" \
  "hi" \
  "relay" "scout"

run_test "hello zenni" \
  "hello zenni" \
  "relay" "main"

run_test "thanks" \
  "thanks" \
  "relay" "scout"

run_test "hello everyone" \
  "hello everyone" \
  "relay" "main"

run_test "ok" \
  "ok" \
  "relay" "main"

run_test "hey there" \
  "hey there" \
  "relay" "main"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4: DISPATCH — Research → scout
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Scout (research) ──${RESET}\n"

run_test "research trending bento content on TikTok" \
  "research trending bento content on TikTok" \
  "dispatch" "scout"

run_test "scrape competitor pricing for meal plans" \
  "scrape competitor pricing for meal plans" \
  "dispatch" "scout"

run_test "find info about top supplement brands in Malaysia" \
  "find info about top supplement brands in Malaysia" \
  "dispatch" "scout"

run_test "competitive intel on laneige skincare" \
  "competitive intel on laneige skincare" \
  "dispatch" "scout"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: DISPATCH — Creative/copy → dreami
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Dreami (creative/copy/marketing) ──${RESET}\n"

run_test "write copy for mirra instagram post" \
  "write copy for mirra instagram post" \
  "dispatch" "dreami"

run_test "create a tiktok script for wholey wonder" \
  "create a tiktok script for wholey wonder" \
  "dispatch" "dreami"

run_test "write caption for instagram reels" \
  "write caption for instagram reels" \
  "dispatch" "dreami"

run_test "brand voice guidelines for serein" \
  "brand voice guidelines for serein" \
  "dispatch" "dreami"

run_test "make an intro video for dreami" \
  "make an intro video for dreami" \
  "dispatch" "dreami"

run_test "generate 3 ad copy variants for mirra" \
  "generate 3 ad copy variants for mirra" \
  "script" "dreami"

run_test "write PAS formula ad for bento" \
  "write PAS formula ad copy for bento" \
  "script" "dreami"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6: DISPATCH — Visual/social → dreami (absorbed iris)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Dreami (visual/social) ──${RESET}\n"

run_test "reverse prompt this image for style reference" \
  "reverse prompt this image for style reference" \
  "dispatch" "dreami"

run_test "generate a mood board for rasaya" \
  "generate a mood board for rasaya" \
  "dispatch" "dreami"

run_test "change iris hair to silver" \
  "change iris hair to silver" \
  "dispatch" "dreami"

run_test "design a product shot style reference" \
  "design a product shot style reference" \
  "dispatch" "dreami"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 7: DISPATCH — Strategy/analysis → main (absorbed athena)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Main/Zenni (strategy/analysis) ──${RESET}\n"

run_test "analyze mirra Q1 performance" \
  "analyze mirra Q1 performance" \
  "dispatch" "main"

run_test "forecast revenue for next quarter" \
  "forecast revenue for next quarter" \
  "dispatch" "main"

run_test "strategic plan for gaia eats launch" \
  "strategic plan for gaia eats launch" \
  "dispatch" "main"

run_test "why did the mirra batch campaign fail" \
  "why did the mirra batch campaign fail" \
  "dispatch" "main"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 8: DISPATCH — Ads/pricing/revenue → dreami (absorbed hermes)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Dreami (ads/pricing/revenue) ──${RESET}\n"

run_test "plan a meta ads campaign for mirra" \
  "plan a meta ads campaign for mirra" \
  "dispatch" "dreami"

run_test "pricing strategy for wholey wonder bentos" \
  "pricing strategy for wholey wonder bentos" \
  "dispatch" "dreami"

run_test "set up google ads for dr stan" \
  "set up google ads for dr stan" \
  "dispatch" "dreami"

run_test "gumroad product launch for template pack" \
  "gumroad product launch for template pack" \
  "dispatch" "dreami"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 9: DISPATCH — Bulk ops → scout (absorbed myrmidons)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Scout (bulk ops) ──${RESET}\n"

run_test "git status and commit changes" \
  "git status and commit changes" \
  "dispatch" "scout"

run_test "check if the gateway is running" \
  "check if the gateway is running" \
  "dispatch" "scout"

run_test "list files in the workspace" \
  "list files in the workspace" \
  "dispatch" "scout"

run_test "send the latest mirra image to team" \
  "send the latest mirra image to team" \
  "dispatch" "dreami"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 10: DISPATCH — QA/testing → scout (absorbed argus)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── DISPATCH: Scout (QA/testing) ──${RESET}\n"

run_test "run regression tests on dispatch" \
  "run regression tests on dispatch" \
  "dispatch" "scout"

run_test "smoke test the gateway" \
  "smoke test the gateway" \
  "dispatch" "scout"

run_test "run nightly review" \
  "run nightly review" \
  "dispatch" "scout"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 11: PM FRAMEWORK ROUTING (15 tests)
# ══════════════════════════════════════════════════════════════════════════════
printf "${BOLD}── PM Framework Routing ──${RESET}\n"

run_test "brand voice consistency audit" \
  "brand voice consistency audit" \
  "dispatch" "main"

run_test "north star metric for mirra" \
  "north star metric for mirra" \
  "dispatch" "main"

run_test "A/B test analysis results" \
  "A/B test analysis results" \
  "dispatch" "main"

run_test "customer journey map for serein" \
  "customer journey map for serein" \
  "dispatch" "main"

run_test "pre-mortem analysis for launch" \
  "pre-mortem analysis for launch" \
  "dispatch" "main"

run_test "go to market strategy for new bento" \
  "go to market strategy for new bento" \
  "dispatch" "main"

run_test "beachhead segment for mirra" \
  "beachhead segment for mirra" \
  "dispatch" "main"

run_test "ideal customer profile for wholey wonder" \
  "ideal customer profile for wholey wonder" \
  "dispatch" "main"

run_test "growth loop analysis for subscriptions" \
  "growth loop analysis for subscriptions" \
  "dispatch" "main"

run_test "cohort retention analysis for Q1" \
  "cohort retention analysis for Q1" \
  "dispatch" "main"

run_test "optimize pricing for bento plans" \
  "optimize pricing for bento plans" \
  "dispatch" "dreami"

run_test "upload products to Shopify store" \
  "upload products to Shopify store" \
  "dispatch" "dreami"

run_test "check meta ads performance" \
  "check meta ads performance" \
  "dispatch" "main"

run_test "lip sync this video clip" \
  "lip sync this video clip" \
  "dispatch" "dreami"

run_test "build a shopify webhook integration" \
  "build a shopify webhook integration" \
  "code" "taoz"

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
echo "============================"
if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "${GREEN}${BOLD}Result: %d/%d passed${RESET}\n" "$PASS_COUNT" "$TOTAL"
else
  printf "${RED}${BOLD}Result: %d/%d passed (%d failed)${RESET}\n" "$PASS_COUNT" "$TOTAL" "$FAIL_COUNT"
fi
echo "============================"

# Exit code: 0 if all pass, 1 if any fail
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
