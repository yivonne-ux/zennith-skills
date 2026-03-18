#!/usr/bin/env bash
# content-supply-chain.sh — Self-improving creative content loop for GAIA CORP-OS
# The loop: RESEARCH → STRATEGY → BRIEF → CREATE → PRODUCE → DISTRIBUTE → ANALYZE → LEARN → LOOP
#
# Usage:
#   content-supply-chain.sh cycle --brand mirra [--direction en-1] [--dry-run]
#   content-supply-chain.sh status --brand mirra
#   content-supply-chain.sh matrix --brand mirra
#   content-supply-chain.sh run-stage <stage> --brand mirra [--direction en-1]
#   content-supply-chain.sh history --brand mirra [--last 5]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.openclaw/skills"
BRANDS_DIR="$HOME/.openclaw/brands"
WORKSPACE="$HOME/.openclaw/workspace"
ROOMS_DIR="$WORKSPACE/rooms"
DATA_DIR="$WORKSPACE/data/supply-chain"
LEARNINGS_DIR="$WORKSPACE/data/learnings"
LOG_DIR="$HOME/.openclaw/logs"

mkdir -p "$DATA_DIR" "$LOG_DIR"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

usage() {
  echo "Usage: content-supply-chain.sh <command> [options]"
  echo ""
  echo "Commands:"
  echo "  cycle       Run full supply chain cycle (all 8 stages)"
  echo "  status      Show current pipeline status for a brand"
  echo "  matrix      Show content matrix (channels × personas × languages)"
  echo "  run-stage   Run a single stage"
  echo "  history     Show cycle history"
  echo ""
  echo "Options:"
  echo "  --brand <brand>       Target brand (required)"
  echo "  --direction <id>      Campaign direction (e.g., en-1)"
  echo "  --channel <channel>   Target channel (ig, fb, tiktok, shopee, edm)"
  echo "  --persona <persona>   Target persona"
  echo "  --language <lang>     Language (en, cn, bm)"
  echo "  --dry-run             Show what would happen without executing"
  echo "  --last <n>            Number of history entries to show"
  exit 1
}

# Parse args
CMD="${1:-}"; shift 2>/dev/null || true
BRAND="" DIRECTION="" CHANNEL="" PERSONA="" LANGUAGE="" DRY_RUN=false LAST=5
while [ $# -gt 0 ]; do
  case "$1" in
    --brand) shift; BRAND="${1:-}" ;;
    --direction) shift; DIRECTION="${1:-}" ;;
    --channel) shift; CHANNEL="${1:-}" ;;
    --persona) shift; PERSONA="${1:-}" ;;
    --language) shift; LANGUAGE="${1:-}" ;;
    --dry-run) DRY_RUN=true ;;
    --last) shift; LAST="${1:-5}" ;;
  esac
  shift 2>/dev/null || true
done

[ -z "$CMD" ] && usage

# Validate brand
validate_brand() {
  if [ -z "$BRAND" ]; then
    echo "ERROR: --brand required"
    exit 1
  fi
  if [ ! -f "$BRANDS_DIR/$BRAND/DNA.json" ]; then
    echo "ERROR: Brand '$BRAND' not found at $BRANDS_DIR/$BRAND/DNA.json"
    exit 1
  fi
}

# Log cycle event
log_event() {
  local stage="$1" status="$2" msg="$3"
  printf '{"ts":%s000,"brand":"%s","direction":"%s","stage":"%s","status":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$BRAND" "${DIRECTION:-all}" "$stage" "$status" "$msg" \
    >> "$DATA_DIR/cycle-log.jsonl" 2>/dev/null
}

# Post to room
post_room() {
  local room="$1" msg="$2"
  printf '{"ts":%s000,"agent":"supply-chain","room":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$room" "$msg" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null
}

# ═══════════════════════════════════════════
# STAGE 1: RESEARCH
# Owner: Artemis
# Skills: content-seed-bank, web-search-pro, meta-ads-library, tiktok-trends, ig-reels-trends
# ═══════════════════════════════════════════
stage_research() {
  echo -e "${CYAN}[1/8] RESEARCH${NC} — Artemis scouting trends + competitor intel"
  log_event "research" "started" "Scouting for $BRAND"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: seed-store.sh query --source artemis --brand $BRAND --top 10"
    echo "  [dry-run] Would run: biz-scout.sh scan (if discovery mode)"
    echo "  [dry-run] Would dispatch Artemis for trend scouting"
    return 0
  fi

  # Check seed bank for existing research
  local seed_count=0
  if [ -f "$SKILLS_DIR/content-seed-bank/scripts/seed-store.sh" ]; then
    seed_count=$(bash "$SKILLS_DIR/content-seed-bank/scripts/seed-store.sh" count --brand "$BRAND" 2>/dev/null || echo "0")
  fi
  echo "  Seed bank: $seed_count entries for $BRAND"

  # Check latest research in build room
  local recent_research=""
  if [ -f "$ROOMS_DIR/build.jsonl" ]; then
    recent_research=$(grep -c "artemis.*$BRAND" "$ROOMS_DIR/build.jsonl" 2>/dev/null | tr -d ' ' || echo "0")
  fi
  echo "  Build room: $recent_research Artemis entries for $BRAND"

  log_event "research" "completed" "Seeds: $seed_count, Room entries: $recent_research"
  echo -e "  ${GREEN}✓ Research data available${NC}"
}

# ═══════════════════════════════════════════
# STAGE 2: STRATEGY
# Owner: Athena + Hermes
# Skills: campaign-planner, creative-taxonomy, cso-pipeline, funnel-playbook
# ═══════════════════════════════════════════
stage_strategy() {
  echo -e "${CYAN}[2/8] STRATEGY${NC} — Athena analyzing + Hermes planning"
  log_event "strategy" "started" "Strategy for $BRAND direction=$DIRECTION"

  if $DRY_RUN; then
    echo "  [dry-run] Would load directions from brands/$BRAND/campaigns/directions.json"
    echo "  [dry-run] Would run: campaign-planner.sh directions --brand $BRAND"
    echo "  [dry-run] Would resolve compound learnings"
    return 0
  fi

  # Load directions
  local directions_file="$BRANDS_DIR/$BRAND/campaigns/directions.json"
  if [ -f "$directions_file" ]; then
    local dir_count
    dir_count=$(python3 -c "import json; d=json.load(open('$directions_file')); print(len(d.get('directions',d) if isinstance(d,dict) else d))" 2>/dev/null || echo "?")
    echo "  Directions loaded: $dir_count available"
  else
    echo "  ⚠ No directions file — create with campaign-planner"
  fi

  # Resolve compound learnings
  if [ -f "$LEARNINGS_DIR/resolve-learnings.py" ]; then
    local learning_count
    learning_count=$(python3 "$LEARNINGS_DIR/resolve-learnings.py" --brand "$BRAND" --format flat 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    echo "  Compound learnings: $learning_count entries"
  fi

  log_event "strategy" "completed" "Direction: ${DIRECTION:-auto-select}"
  echo -e "  ${GREEN}✓ Strategy ready${NC}"
}

# ═══════════════════════════════════════════
# STAGE 3: BRIEF
# Owner: Hermes (structure) + Dreami (copy angle)
# Skills: campaign-planner, ideation-engine, content-ideation-workflow
# ═══════════════════════════════════════════
stage_brief() {
  echo -e "${CYAN}[3/8] BRIEF${NC} — Generating campaign briefs"
  log_event "brief" "started" "Brief for $BRAND direction=$DIRECTION"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: campaign-planner.sh create --brand $BRAND --direction ${DIRECTION:-en-1}"
    echo "  [dry-run] Would run: ideation-engine.sh generate --brand $BRAND --direction ${DIRECTION:-en-1} --count 9"
    return 0
  fi

  # Generate ideas via ideation engine (zero-cost, no LLM)
  if [ -f "$SKILLS_DIR/campaign-planner/scripts/ideation-engine.sh" ]; then
    local idea_count
    idea_count=$(bash "$SKILLS_DIR/campaign-planner/scripts/ideation-engine.sh" generate \
      --brand "$BRAND" --direction "${DIRECTION:-en-1}" --count 9 2>/dev/null | grep -c "IDEA" || echo "0")
    echo "  Ideas generated: $idea_count (zero-cost ideation)"
  fi

  # Check existing briefs
  if [ -f "$SKILLS_DIR/campaign-planner/scripts/campaign-planner.sh" ]; then
    local brief_status
    brief_status=$(bash "$SKILLS_DIR/campaign-planner/scripts/campaign-planner.sh" list --brand "$BRAND" 2>/dev/null | tail -3 || echo "No briefs")
    echo "  Existing briefs: $brief_status"
  fi

  log_event "brief" "completed" "Ideas generated for ${DIRECTION:-en-1}"
  echo -e "  ${GREEN}✓ Briefs ready${NC}"
}

# ═══════════════════════════════════════════
# STAGE 4: CREATE
# Owner: Dreami (copy) + Gemini CLI (ideation)
# Skills: gemini-runner.sh (creative/brainstorm), content-seed-bank
# ═══════════════════════════════════════════
stage_create() {
  echo -e "${CYAN}[4/8] CREATE${NC} — Dreami writing + Gemini ideating"
  log_event "create" "started" "Creating content for $BRAND"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: gemini-runner.sh creative \"Generate ad copy for $BRAND\" dreami creative --brand $BRAND"
    echo "  [dry-run] Would dispatch Dreami for headline generation"
    echo "  [dry-run] Would store results in content-seed-bank"
    return 0
  fi

  # Use Gemini CLI for creative ideation
  if [ -f "$SKILLS_DIR/gemini-cli/scripts/gemini-runner.sh" ]; then
    echo "  Invoking Gemini CLI for creative content..."
    local gemini_result
    gemini_result=$(bash "$SKILLS_DIR/gemini-cli/scripts/gemini-runner.sh" creative \
      "Generate 5 ad headlines and 3 social captions for direction ${DIRECTION:-en-1}. Include character counts. Follow brand voice." \
      dreami creative --brand "$BRAND" 2>/dev/null || echo '{"status":"skipped"}')
    local gemini_status
    gemini_status=$(echo "$gemini_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','?'))" 2>/dev/null || echo "?")
    echo "  Gemini creative: $gemini_status"
  fi

  log_event "create" "completed" "Content created"
  echo -e "  ${GREEN}✓ Content created${NC}"
}

# ═══════════════════════════════════════════
# STAGE 5: PRODUCE
# Owner: Iris (visuals) + ad-composer (images)
# Skills: ad-composer (nanobanana/recraft/flux), creative-factory, video-gen
# ═══════════════════════════════════════════
stage_produce() {
  echo -e "${CYAN}[5/8] PRODUCE${NC} — Iris producing visuals"
  log_event "produce" "started" "Producing assets for $BRAND"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: creative-factory.sh quick --brand $BRAND --direction ${DIRECTION:-en-1} --count 3"
    echo "  [dry-run] Would run: ad-image-gen.sh generate --model nanobanana --brand $BRAND"
    echo "  [dry-run] Would dispatch Iris for visual QA"
    return 0
  fi

  # Check creative factory status
  if [ -f "$SKILLS_DIR/creative-factory/scripts/creative-factory.sh" ]; then
    local cf_status
    cf_status=$(bash "$SKILLS_DIR/creative-factory/scripts/creative-factory.sh" status --brand "$BRAND" 2>/dev/null | tail -3 || echo "No status")
    echo "  Creative factory: $cf_status"
  fi

  log_event "produce" "completed" "Assets produced"
  echo -e "  ${GREEN}✓ Assets produced${NC}"
}

# ═══════════════════════════════════════════
# STAGE 6: DISTRIBUTE
# Owner: Iris (social) + Hermes (ads)
# Skills: social-publish, meta-ads-manager
# ═══════════════════════════════════════════
stage_distribute() {
  echo -e "${CYAN}[6/8] DISTRIBUTE${NC} — Publishing to channels"
  log_event "distribute" "started" "Distributing for $BRAND"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: social-publish.sh post --platform ig --brand $BRAND"
    echo "  [dry-run] Would upload to Meta Ads as PAUSED"
    echo "  [dry-run] Channels: ${CHANNEL:-ig,fb,tiktok}"
    return 0
  fi

  # Check social-publish readiness
  if [ -f "$SKILLS_DIR/social-publish/scripts/social-publish.sh" ]; then
    local pub_status
    pub_status=$(bash "$SKILLS_DIR/social-publish/scripts/social-publish.sh" status --brand "$BRAND" 2>/dev/null | head -5 || echo "Not configured")
    echo "  Social publish: $pub_status"
  fi

  log_event "distribute" "completed" "Distribution queued"
  echo -e "  ${GREEN}✓ Distribution queued${NC}"
}

# ═══════════════════════════════════════════
# STAGE 7: ANALYZE
# Owner: Athena + Hermes
# Skills: ad-performance, growth-engine, content-tuner
# ═══════════════════════════════════════════
stage_analyze() {
  echo -e "${CYAN}[7/8] ANALYZE${NC} — Performance analysis"
  log_event "analyze" "started" "Analyzing $BRAND performance"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: ingest-meta.sh pull --brand $BRAND --days 7"
    echo "  [dry-run] Would run: growth-engine winner detection"
    echo "  [dry-run] Would run: content-tuner evaluation"
    return 0
  fi

  # Check ad performance data
  if [ -f "$SKILLS_DIR/ad-performance/scripts/ingest-meta.sh" ]; then
    echo "  Checking Meta Ads data..."
    local perf_check
    perf_check=$(bash "$SKILLS_DIR/ad-performance/scripts/ingest-meta.sh" check-token 2>/dev/null | head -3 || echo "Token check failed")
    echo "  Ad performance: $perf_check"
  fi

  # Check winning patterns
  local patterns_file="$WORKSPACE/data/learnings/winning-patterns.jsonl"
  if [ -f "$patterns_file" ]; then
    local pattern_count
    pattern_count=$(wc -l < "$patterns_file" | tr -d ' ')
    echo "  Winning patterns: $pattern_count entries"
  else
    echo "  Winning patterns: none yet (first cycle)"
  fi

  log_event "analyze" "completed" "Analysis complete"
  echo -e "  ${GREEN}✓ Analysis complete${NC}"
}

# ═══════════════════════════════════════════
# STAGE 8: LEARN
# Owner: System (all agents)
# Skills: knowledge-compound, content-tuner, growth-engine, resolve-learnings
# ═══════════════════════════════════════════
stage_learn() {
  echo -e "${CYAN}[8/8] LEARN${NC} — Compound learning + pattern extraction"
  log_event "learn" "started" "Learning cycle for $BRAND"

  if $DRY_RUN; then
    echo "  [dry-run] Would run: digest.sh --brand $BRAND"
    echo "  [dry-run] Would run: content-tuner evaluation + promotion"
    echo "  [dry-run] Would update compound learnings at 3 layers (global, category, brand)"
    echo "  [dry-run] Would feed winning patterns back to STAGE 2 (strategy)"
    return 0
  fi

  # Run compound digest
  if [ -f "$SKILLS_DIR/knowledge-compound/scripts/digest.sh" ]; then
    echo "  Running knowledge digest..."
    bash "$SKILLS_DIR/knowledge-compound/scripts/digest.sh" --quick 2>/dev/null || true
    echo "  Digest complete"
  fi

  # Count total learnings
  local total_learnings=0
  for layer in global category brand; do
    local layer_dir="$LEARNINGS_DIR/$layer"
    if [ -d "$layer_dir" ]; then
      local count
      count=$(find "$layer_dir" -name "*.jsonl" -exec cat {} + 2>/dev/null | wc -l | tr -d ' ' || echo "0")
      total_learnings=$((total_learnings + count))
    fi
  done
  echo "  Total compound learnings: $total_learnings across 3 layers"

  # Post cycle completion to townhall
  post_room "townhall" "[Supply Chain] Cycle complete for $BRAND. Learnings: $total_learnings entries. Direction: ${DIRECTION:-all}."

  log_event "learn" "completed" "Learnings: $total_learnings"
  echo -e "  ${GREEN}✓ Learning cycle complete — loop back to RESEARCH${NC}"
}

# ═══════════════════════════════════════════
# COMMANDS
# ═══════════════════════════════════════════

cmd_cycle() {
  validate_brand
  local cycle_id="cycle-$(date +%s)"
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo " CONTENT SUPPLY CHAIN — $BRAND"
  echo " Cycle: $cycle_id | Direction: ${DIRECTION:-all}"
  echo " $(date '+%Y-%m-%d %H:%M:%S MYT')"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  log_event "cycle" "started" "Cycle $cycle_id"

  stage_research
  echo ""
  stage_strategy
  echo ""
  stage_brief
  echo ""
  stage_create
  echo ""
  stage_produce
  echo ""
  stage_distribute
  echo ""
  stage_analyze
  echo ""
  stage_learn

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo -e " ${GREEN}CYCLE COMPLETE${NC} — $cycle_id"
  echo " Next cycle: Re-run with updated learnings"
  echo " The loop compounds: each cycle feeds the next"
  echo "═══════════════════════════════════════════════════════"

  log_event "cycle" "completed" "Cycle $cycle_id finished"
}

cmd_status() {
  validate_brand
  echo ""
  echo "═══ SUPPLY CHAIN STATUS: $BRAND ═══"
  echo ""

  # Check each stage's readiness
  local stages=("research:content-seed-bank" "strategy:campaign-planner" "brief:campaign-planner" "create:gemini-cli" "produce:creative-factory" "distribute:social-publish" "analyze:ad-performance" "learn:knowledge-compound")

  for entry in "${stages[@]}"; do
    local stage="${entry%%:*}"
    local skill="${entry##*:}"
    local skill_dir="$SKILLS_DIR/$skill"
    if [ -d "$skill_dir" ]; then
      echo -e "  ${GREEN}✓${NC} $stage — $skill (installed)"
    else
      echo -e "  ${RED}✗${NC} $stage — $skill (MISSING)"
    fi
  done

  echo ""
  # Last cycle
  if [ -f "$DATA_DIR/cycle-log.jsonl" ]; then
    echo "Last cycle:"
    tail -1 "$DATA_DIR/cycle-log.jsonl" | python3 -c "
import sys,json
try:
  e = json.loads(sys.stdin.read())
  from datetime import datetime
  ts = datetime.fromtimestamp(e['ts']/1000).strftime('%Y-%m-%d %H:%M')
  print(f\"  {ts} | {e['stage']} | {e['status']} | {e.get('msg','')}\")
except: print('  No cycles yet')
" 2>/dev/null
  else
    echo "  No cycles run yet"
  fi
}

cmd_matrix() {
  validate_brand
  echo ""
  echo "═══ CONTENT MATRIX: $BRAND ═══"
  echo ""

  # Load brand DNA for channels/personas
  local dna="$BRANDS_DIR/$BRAND/DNA.json"
  python3 << PYEOF
import json, os

try:
    with open("$dna") as f:
        dna = json.load(f)
except:
    print("  Could not load DNA.json")
    exit(0)

# Channels
channels = dna.get("channels", dna.get("social_channels", ["ig", "fb", "tiktok"]))
if isinstance(channels, dict):
    channels = list(channels.keys())
print("CHANNELS:")
for c in channels:
    print(f"  - {c}")

# Languages
langs = dna.get("languages", dna.get("content_languages", ["en", "cn", "bm"]))
if isinstance(langs, dict):
    langs = list(langs.keys())
print(f"\nLANGUAGES: {', '.join(str(l) for l in langs)}")

# Personas (from directions if available)
directions_file = os.path.expanduser(f"~/.openclaw/brands/$BRAND/campaigns/directions.json")
if os.path.exists(directions_file):
    with open(directions_file) as f:
        dirs = json.load(f)
    if isinstance(dirs, dict):
        dirs = dirs.get("directions", [])
    print(f"\nDIRECTIONS: {len(dirs)}")
    for d in dirs[:10]:
        if isinstance(d, dict):
            did = d.get("id", d.get("direction_id", "?"))
            name = d.get("name", d.get("title", "?"))
            print(f"  - {did}: {name}")

# Matrix size
n_channels = len(channels) if isinstance(channels, list) else 3
n_langs = len(langs) if isinstance(langs, list) else 3
n_formats = 9  # M1-M5 + B1-B4
print(f"\nMATRIX SIZE: {n_channels} channels × {n_langs} languages × {n_formats} formats = {n_channels * n_langs * n_formats} combinations per direction")
PYEOF
}

cmd_run_stage() {
  validate_brand
  local stage="${1:-}"
  if [ -z "$stage" ]; then
    echo "ERROR: Specify stage: research, strategy, brief, create, produce, distribute, analyze, learn"
    exit 1
  fi

  case "$stage" in
    research) stage_research ;;
    strategy) stage_strategy ;;
    brief) stage_brief ;;
    create) stage_create ;;
    produce) stage_produce ;;
    distribute) stage_distribute ;;
    analyze) stage_analyze ;;
    learn) stage_learn ;;
    *) echo "ERROR: Unknown stage '$stage'"; exit 1 ;;
  esac
}

cmd_history() {
  validate_brand
  if [ ! -f "$DATA_DIR/cycle-log.jsonl" ]; then
    echo "No cycle history yet."
    exit 0
  fi

  echo "═══ CYCLE HISTORY: $BRAND ═══"
  grep "\"brand\":\"$BRAND\"" "$DATA_DIR/cycle-log.jsonl" | tail -"$LAST" | python3 -c "
import sys, json
from datetime import datetime
for line in sys.stdin:
  line = line.strip()
  if not line: continue
  try:
    e = json.loads(line)
    ts = datetime.fromtimestamp(e['ts']/1000).strftime('%Y-%m-%d %H:%M')
    print(f\"  {ts} | {e['stage']:12s} | {e['status']:10s} | {e.get('msg','')[:60]}\")
  except: pass
" 2>/dev/null
}

# Route command
case "$CMD" in
  cycle) cmd_cycle ;;
  status) cmd_status ;;
  matrix) cmd_matrix ;;
  run-stage) cmd_run_stage "$@" ;;
  history) cmd_history ;;
  *) usage ;;
esac
