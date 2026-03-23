#!/usr/bin/env bash
# E2E Skills Validator — Auto-Research Pattern
# Evaluates 6 new skills against 13 quality criteria
# Outputs: per-skill scores, failing criteria, overall pass/fail
#
# Usage: bash e2e-skills-validate.sh [--fix]
# --fix: attempt to describe fixes needed (human/Claude Code applies them)

set -euo pipefail

SKILLS_DIR="$HOME/.openclaw/skills"
BRANDS_DIR="$HOME/.openclaw/brands"
OUTPUT_DIR="$HOME/.openclaw/workspace/data/auto-research/e2e-new-skills"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

SKILLS=(
  product-studio
  content-repurpose
  campaign-translate
  ai-voiceover
  brand-prompt-library
  notebooklm-research
  jade-content-studio
  audience-simulator
  skill-router
)

ALL_BRANDS=(
  dr-stan gaia-eats gaia-learn gaia-os gaia-print gaia-recipes
  gaia-supplements iris jade-oracle mirra pinxin-vegan rasaya serein wholey-wonder
)

FNB_BRANDS=(pinxin-vegan mirra wholey-wonder rasaya gaia-eats dr-stan serein)

CROSS_REFS=(nanobanana video-forge content-supply-chain visual-registry ad-composer creative-studio campaign-planner brand-voice-check brand-prompt-library skill-router)

mkdir -p "$OUTPUT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[e2e]${NC} $*"; }
pass() { echo -e "  ${GREEN}PASS${NC} $*"; }
fail() { echo -e "  ${RED}FAIL${NC} $*"; }
warn() { echo -e "  ${YELLOW}WARN${NC} $*"; }

###############################################################################
# Criteria Check Functions
###############################################################################

check_frontmatter() {
  local file="$1"
  # Check for ---\n...\n--- frontmatter with required fields
  local has_start=$(head -1 "$file" | grep -c "^---" || true)
  local has_name=$(grep -c "^name:" "$file" || true)
  local has_desc=$(grep -c "^description:" "$file" || true)
  local has_agents=$(grep -c "^agents:" "$file" || true)
  local has_version=$(grep -c "^version:" "$file" || true)

  if [ "$has_start" -ge 1 ] && [ "$has_name" -ge 1 ] && [ "$has_desc" -ge 1 ] && [ "$has_agents" -ge 1 ] && [ "$has_version" -ge 1 ]; then
    echo "PASS"
  else
    local missing=""
    [ "$has_start" -lt 1 ] && missing="$missing frontmatter-delimiters"
    [ "$has_name" -lt 1 ] && missing="$missing name"
    [ "$has_desc" -lt 1 ] && missing="$missing description"
    [ "$has_agents" -lt 1 ] && missing="$missing agents"
    [ "$has_version" -lt 1 ] && missing="$missing version"
    echo "FAIL:missing$missing"
  fi
}

check_brand_coverage() {
  local file="$1"
  local missing_brands=""
  local found=0

  for brand in "${ALL_BRANDS[@]}"; do
    if grep -qi "$brand" "$file"; then
      found=$((found + 1))
    else
      missing_brands="$missing_brands $brand"
    fi
  done

  if [ "$found" -ge 14 ]; then
    echo "PASS"
  elif [ "$found" -ge 10 ]; then
    echo "WARN:missing$missing_brands ($found/14)"
  else
    echo "FAIL:only $found/14 brands mentioned, missing:$missing_brands"
  fi
}

check_fnb_focus() {
  local file="$1"
  local found=0
  local missing=""

  for brand in "${FNB_BRANDS[@]}"; do
    local count
    count=$(grep -ci "$brand" "$file" || true)
    if [ "$count" -ge 2 ]; then
      found=$((found + 1))
    else
      missing="$missing $brand($count)"
    fi
  done

  if [ "$found" -ge 7 ]; then
    echo "PASS"
  elif [ "$found" -ge 5 ]; then
    echo "WARN:light coverage:$missing"
  else
    echo "FAIL:only $found/7 F&B brands with substantial mention. Light:$missing"
  fi
}

check_workflow_sop() {
  local file="$1"
  local has_workflow=$(grep -ci "workflow\|SOP\|step.*1\|STEP 1\|INPUT.*OUTPUT" "$file" || true)
  local has_steps=$(grep -c "^STEP\|^Step\|^  STEP\|^  Step\|^    STEP" "$file" || true)
  local has_input=$(grep -ci "^INPUT:\|INPUT:" "$file" || true)
  local has_output=$(grep -ci "^OUTPUT:\|OUTPUT:" "$file" || true)

  if [ "$has_workflow" -ge 3 ] && ([ "$has_steps" -ge 3 ] || [ "$has_input" -ge 1 ]); then
    echo "PASS"
  else
    echo "FAIL:workflow mentions=$has_workflow steps=$has_steps input=$has_input output=$has_output"
  fi
}

check_cli_usage() {
  local file="$1"
  local has_cli=$(grep -c "^bash scripts/\|^bash ~/.openclaw\|\.sh " "$file" || true)
  local has_flags=$(grep -ci "\-\-brand\|\-\-input\|\-\-lang" "$file" || true)

  if [ "$has_cli" -ge 3 ] && [ "$has_flags" -ge 2 ]; then
    echo "PASS"
  elif [ "$has_cli" -ge 1 ]; then
    echo "WARN:only $has_cli CLI examples"
  else
    echo "FAIL:no CLI usage examples found"
  fi
}

check_integration() {
  local file="$1"
  local has_integration=$(grep -ci "integration\|feeds.*into\|feeds.*from\|upstream\|downstream" "$file" || true)
  local has_refs=$(grep -ci "content-supply-chain\|video-forge\|nanobanana\|creative-studio\|ad-composer\|campaign-planner" "$file" || true)

  if [ "$has_integration" -ge 2 ] && [ "$has_refs" -ge 2 ]; then
    echo "PASS"
  else
    echo "FAIL:integration mentions=$has_integration cross-refs=$has_refs"
  fi
}

check_quality_gate() {
  local file="$1"
  local has_quality=$(grep -ci "quality\|checklist\|gate\|verify\|validation" "$file" || true)

  if [ "$has_quality" -ge 3 ]; then
    echo "PASS"
  else
    echo "FAIL:only $has_quality quality-related mentions"
  fi
}

check_cross_skill_refs() {
  local file="$1"
  local found=0
  for ref in "${CROSS_REFS[@]}"; do
    if grep -qi "$ref" "$file"; then
      found=$((found + 1))
    fi
  done

  if [ "$found" -ge 3 ]; then
    echo "PASS"
  elif [ "$found" -ge 1 ]; then
    echo "WARN:only $found cross-skill references"
  else
    echo "FAIL:no cross-skill references found"
  fi
}

check_brand_dna() {
  local file="$1"
  local has_dna=$(grep -ci "DNA.json\|brand.*DNA\|dna.*json\|brands.*DNA" "$file" || true)

  if [ "$has_dna" -ge 2 ]; then
    echo "PASS"
  elif [ "$has_dna" -ge 1 ]; then
    echo "WARN:only $has_dna DNA.json references"
  else
    echo "FAIL:no DNA.json references"
  fi
}

check_output_paths() {
  local file="$1"
  local has_canonical=$(grep -ci "openclaw/workspace/data\|~/.openclaw/workspace\|canonical" "$file" || true)

  if [ "$has_canonical" -ge 1 ]; then
    echo "PASS"
  else
    echo "FAIL:no canonical output paths found"
  fi
}

check_no_placeholders() {
  local file="$1"
  local has_todo=$(grep -ci "TODO\|TBD\|FIXME\|PLACEHOLDER\|coming soon\|\[insert\]\|{TODO}" "$file" || true)
  local total_lines
  total_lines=$(wc -l < "$file" | tr -d ' ')

  if [ "$has_todo" -eq 0 ] && [ "$total_lines" -ge 100 ]; then
    echo "PASS"
  elif [ "$has_todo" -gt 0 ]; then
    echo "FAIL:$has_todo placeholder/TODO markers found"
  else
    echo "FAIL:only $total_lines lines (too thin)"
  fi
}

check_has_scripts() {
  local skill="$1"
  local scripts_dir="$HOME/.openclaw/skills/$skill/scripts"
  # Skills that MUST have executable scripts (regression)
  local must_have="product-studio content-repurpose campaign-translate ai-voiceover audience-simulator skill-router"

  if echo "$must_have" | grep -qw "$skill"; then
    if [ -d "$scripts_dir" ]; then
      local count
      count=$(find "$scripts_dir" -name "*.sh" -perm +111 2>/dev/null | wc -l | tr -d ' ')
      if [ "$count" -ge 1 ]; then
        echo "PASS"
      else
        echo "FAIL:scripts dir exists but no executable .sh files"
      fi
    else
      echo "FAIL:no scripts directory (required for this skill)"
    fi
  else
    # Not a required-scripts skill — always pass
    echo "PASS"
  fi
}

check_malaysian_context() {
  local file="$1"
  local has_my=$(grep -ci "malaysia\|malaysian\|BM\|bahasa\|hari raya\|CNY\|deepavali\|manglish\|hawker\|nasi\|ringgit\|shopee\|grabfood" "$file" || true)

  if [ "$has_my" -ge 3 ]; then
    echo "PASS"
  elif [ "$has_my" -ge 1 ]; then
    echo "WARN:only $has_my Malaysian context mentions"
  else
    echo "FAIL:no Malaysian market context"
  fi
}

check_mirra_correct() {
  local file="$1"
  local has_mirra=$(grep -ci "mirra" "$file" || true)

  if [ "$has_mirra" -eq 0 ]; then
    echo "PASS"
    return
  fi

  # MIRRA must NOT be described as skincare/cosmetics (excluding disclaimers)
  local bad_skincare=$(grep -i "mirra" "$file" | grep -i "skincare" | grep -civ "NOT skincare\|not skincare\|never skincare\|NOT.*beauty\|≠.*skincare" || true)
  # MIRRA MUST be described as weight management meal subscription
  local has_weight_mgmt=$(grep -ci "mirra.*weight management\|mirra.*meal subscription\|weight management.*mirra\|meal subscription.*mirra" "$file" || true)
  # Bento is OK as format descriptor but must be paired with weight management
  local has_bento_only=$(grep -ci "mirra.*bento\|bento.*mirra" "$file" || true)

  if [ "$bad_skincare" -gt 0 ]; then
    echo "FAIL:MIRRA described as skincare ($bad_skincare times)"
  elif [ "$has_weight_mgmt" -ge 1 ]; then
    echo "PASS"
  elif [ "$has_bento_only" -ge 1 ]; then
    echo "FAIL:MIRRA described as bento/food but missing 'weight management meal subscription' positioning"
  else
    echo "FAIL:MIRRA mentioned but not identified as weight management meal subscription"
  fi
}

###############################################################################
# Main Evaluation Loop
###############################################################################

ITERATION="${E2E_ITERATION:-1}"
MAX_ITERATIONS="${E2E_MAX_ITERATIONS:-5}"
OVERALL_PASS=true
TOTAL_CHECKS=0
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_WARN=0

# JSON results array
RESULTS="[]"

log "=== E2E Skills Validation — Iteration $ITERATION / $MAX_ITERATIONS ==="
log "Timestamp: $TIMESTAMP"
echo ""

for skill in "${SKILLS[@]}"; do
  local_file="$SKILLS_DIR/$skill/SKILL.md"

  if [ ! -f "$local_file" ]; then
    fail "$skill: SKILL.md not found at $local_file"
    OVERALL_PASS=false
    continue
  fi

  lines=$(wc -l < "$local_file" | tr -d ' ')
  log "Evaluating: $skill ($lines lines)"

  skill_pass=0
  skill_fail=0
  skill_warn=0
  skill_total=14
  fail_list=""

  # Run all 14 checks (13 original + 1 regression)
  checks=(
    "frontmatter_valid:check_frontmatter"
    "brand_coverage:check_brand_coverage"
    "fnb_focus:check_fnb_focus"
    "workflow_sop:check_workflow_sop"
    "cli_usage:check_cli_usage"
    "integration_map:check_integration"
    "quality_checklist:check_quality_gate"
    "cross_skill_refs:check_cross_skill_refs"
    "brand_dna_aware:check_brand_dna"
    "output_paths:check_output_paths"
    "no_placeholder:check_no_placeholders"
    "malaysian_context:check_malaysian_context"
    "mirra_correct:check_mirra_correct"
  )

  for check_entry in "${checks[@]}"; do
    check_id="${check_entry%%:*}"
    check_fn="${check_entry##*:}"
    result=$($check_fn "$local_file")

    if echo "$result" | grep -q "^PASS"; then
      pass "$check_id"
      skill_pass=$((skill_pass + 1))
    elif echo "$result" | grep -q "^WARN"; then
      warn "$check_id — ${result#WARN:}"
      skill_warn=$((skill_warn + 1))
      skill_pass=$((skill_pass + 1))  # Warns count as soft pass
    else
      fail "$check_id — ${result#FAIL:}"
      skill_fail=$((skill_fail + 1))
      fail_list="$fail_list $check_id"
      OVERALL_PASS=false
    fi
  done

  # Regression check: scripts must exist for skills that should have them
  scripts_result=$(check_has_scripts "$skill")
  if echo "$scripts_result" | grep -q "^PASS"; then
    pass "has_scripts"
    skill_pass=$((skill_pass + 1))
  elif echo "$scripts_result" | grep -q "^WARN"; then
    warn "has_scripts — ${scripts_result#WARN:}"
    skill_warn=$((skill_warn + 1))
    skill_pass=$((skill_pass + 1))
  else
    fail "has_scripts — ${scripts_result#FAIL:}"
    skill_fail=$((skill_fail + 1))
    fail_list="$fail_list has_scripts"
    OVERALL_PASS=false
  fi

  score=$(python3 -c "print(round($skill_pass / $skill_total, 2))")
  TOTAL_CHECKS=$((TOTAL_CHECKS + skill_total))
  TOTAL_PASS=$((TOTAL_PASS + skill_pass))
  TOTAL_FAIL=$((TOTAL_FAIL + skill_fail))
  TOTAL_WARN=$((TOTAL_WARN + skill_warn))

  if [ "$skill_fail" -eq 0 ]; then
    echo -e "  ${GREEN}SCORE: $score ($skill_pass/$skill_total)${NC} ✓"
  else
    echo -e "  ${RED}SCORE: $score ($skill_pass/$skill_total) — FAILING:$fail_list${NC}"
  fi
  echo ""
done

###############################################################################
# Summary
###############################################################################

OVERALL_SCORE=$(python3 -c "print(round($TOTAL_PASS / $TOTAL_CHECKS, 4))" 2>/dev/null || echo "0")

echo ""
log "=== SUMMARY ==="
echo -e "  Total checks: $TOTAL_CHECKS"
echo -e "  ${GREEN}Pass: $TOTAL_PASS${NC}"
echo -e "  ${YELLOW}Warn: $TOTAL_WARN${NC}"
echo -e "  ${RED}Fail: $TOTAL_FAIL${NC}"
echo -e "  Overall score: $OVERALL_SCORE"
echo ""

if [ "$OVERALL_PASS" = true ]; then
  echo -e "${GREEN}=== ALL SKILLS PASS — E2E COMPLETE ===${NC}"
else
  echo -e "${RED}=== SOME SKILLS NEED FIXES — ITERATION $ITERATION ===${NC}"
fi

# Save results
python3 << PYEOF
import json
from datetime import datetime

results = {
    "iteration": $ITERATION,
    "timestamp": "$TIMESTAMP",
    "overall_score": $OVERALL_SCORE,
    "total_checks": $TOTAL_CHECKS,
    "total_pass": $TOTAL_PASS,
    "total_fail": $TOTAL_FAIL,
    "total_warn": $TOTAL_WARN,
    "all_pass": $( [ "$OVERALL_PASS" = true ] && echo "True" || echo "False" )
}

with open("$OUTPUT_DIR/iteration_${ITERATION}.json", "w") as f:
    json.dump(results, f, indent=2)

print(json.dumps(results, indent=2))
PYEOF

exit $( [ "$OVERALL_PASS" = true ] && echo 0 || echo 1 )
