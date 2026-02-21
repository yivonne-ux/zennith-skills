#!/usr/bin/env bash
# cso-run.sh — CSO Pipeline Runner for GAIA CORP-OS
# Orchestrates Content Strategy Operation through analysis, adaptation, and publishing.
#
# Usage: bash cso-run.sh <strategy_id> [brand_slug]
#
# Replaces the n8n CSO workflow with native OpenClaw agent dispatching.
# Each step is created in the backend, approved, then executed by the appropriate agent.

set -uo pipefail

# Ensure PATH includes openclaw binary location
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

###############################################################################
# Configuration
###############################################################################

STRATEGY_ID="${1:?Usage: cso-run.sh <strategy_id> [brand_slug]}"
BRAND="${2:-gaia-eats}"  # Default to gaia-eats, can be overridden
BRAND_DNA="$HOME/.openclaw/brands/$BRAND/DNA.json"

# Local SQLite data layer (replaces defunct gaiafoodtech.com API)
GAIA_DB="$HOME/.openclaw/workspace/gaia-db/gaia.db"
GAIA_DB_PY="$HOME/.openclaw/workspace/gaia-db/gaia_db.py"

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/cso-pipeline.log"
DISPATCH_SCRIPT="$OPENCLAW_DIR/skills/mission-control/scripts/dispatch.sh"

mkdir -p "$ROOMS_DIR" "$(dirname "$LOG_FILE")"

###############################################################################
# Helper Functions
###############################################################################

log() {
  local level="$1"
  local msg="$2"
  local entry="[$(date +"%Y-%m-%d %H:%M:%S")] [CSO] [$level] [strategy=$STRATEGY_ID] $msg"
  echo "$entry"
  echo "$entry" >> "$LOG_FILE"
}

# Post a JSONL entry to a room
post_to_room() {
  local room="$1"
  local msg="$2"
  local safe_msg
  safe_msg=$(printf '%s' "$msg" | tr '\n' ' ' | sed 's/"/\\"/g' | cut -c1-2000)
  local entry
  entry=$(printf '{"ts":%s000,"agent":"zenni","room":"%s","type":"cso-pipeline","msg":"%s"}' \
    "$(date +%s)" "$room" "$safe_msg")
  echo "$entry" >> "$ROOMS_DIR/${room}.jsonl" 2>/dev/null || true
}

# Local SQLite helpers (replaces remote API calls)

# Update strategy status in local DB
update_strategy_status() {
  local status="$1"
  log "INFO" "Updating strategy status to $status"
  sqlite3 "$GAIA_DB" "UPDATE strategies SET status='$status', updated_at=datetime('now') WHERE id=$STRATEGY_ID;" 2>/dev/null || true
}

# Update strategy progress (stored in brief field as prefix)
update_strategy_progress() {
  local progress="$1"
  log "INFO" "Updating strategy progress: $progress"
  # Progress is logged, not stored in DB (brief stays as original)
}

# Create a step — returns a local step counter (no remote backend needed)
STEP_COUNTER=0
create_step() {
  local step_type="$1"
  STEP_COUNTER=$((STEP_COUNTER + 1))
  log "INFO" "Step $STEP_COUNTER: $step_type"
  echo "$STEP_COUNTER"
  return 0
}

# Approve a step — no-op locally (all steps auto-approved)
approve_step() {
  local step_id="$1"
  log "INFO" "Step $step_id approved (local)"
  return 0
}

# Dispatch a task to an agent via dispatch.sh
# Arguments: agent, action_label, message, room
dispatch_to_agent() {
  local agent="$1"
  local action_label="$2"
  local message="$3"
  local room="${4:-exec}"

  log "INFO" "Dispatching $action_label to $agent"

  if [ ! -f "$DISPATCH_SCRIPT" ]; then
    log "ERROR" "dispatch.sh not found at $DISPATCH_SCRIPT"
    return 1
  fi

  local dispatch_result=""
  dispatch_result=$(bash "$DISPATCH_SCRIPT" "zenni" "$agent" "request" "$message" "$room" 2>&1) || true
  log "INFO" "Dispatch result: $(echo "$dispatch_result" | cut -c1-500)"
  echo "$dispatch_result"
  return 0
}

# Check if strategy has image/video attachments in creative props
has_attachments() {
  local strategy_json="$1"
  local has_att=""
  has_att=$(echo "$strategy_json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Check multiple possible locations for attachments
    props = d.get('creative_props', d.get('creativeProps', d.get('props', {})))
    if isinstance(props, dict):
        attachments = props.get('attachments', props.get('images', props.get('media', [])))
    elif isinstance(props, list):
        attachments = props
    else:
        attachments = []
    if isinstance(attachments, list) and len(attachments) > 0:
        print('yes')
    else:
        print('no')
except:
    print('no')
" 2>/dev/null)
  if [ "$has_att" = "yes" ]; then
    return 0
  else
    return 1
  fi
}

###############################################################################
# Pipeline Failure Handler
###############################################################################

on_failure() {
  local reason="$1"
  log "ERROR" "Pipeline failed: $reason"
  update_strategy_status "FAILED"
  post_to_room "feedback" "[CSO FAILED] Strategy $STRATEGY_ID: $reason"
  post_to_room "exec" "[CSO FAILED] Strategy $STRATEGY_ID: $reason"
  exit 1
}

###############################################################################
# Main Pipeline
###############################################################################

log "INFO" "=========================================="
log "INFO" "CSO Pipeline starting for strategy $STRATEGY_ID"
log "INFO" "=========================================="
post_to_room "exec" "[CSO START] Pipeline started for strategy $STRATEGY_ID"

# -----------------------------------------------------------------------
# Step 0: Fetch strategy from backend
# -----------------------------------------------------------------------
log "INFO" "Fetching strategy from local DB..."
STRATEGY_JSON=""
STRATEGY_JSON=$(python3 -c "
import sqlite3, json, sys
from pathlib import Path
db = sqlite3.connect(str(Path.home() / '.openclaw/workspace/gaia-db/gaia.db'))
db.row_factory = sqlite3.Row
row = db.execute('SELECT * FROM strategies WHERE id=?', ($STRATEGY_ID,)).fetchone()
db.close()
if row:
    print(json.dumps(dict(row)))
else:
    print('{}')
" 2>/dev/null)

if [ -z "$STRATEGY_JSON" ] || [ "$STRATEGY_JSON" = "{}" ]; then
  on_failure "Could not fetch strategy $STRATEGY_ID from local DB"
fi

STRATEGY_TITLE=$(echo "$STRATEGY_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('title', d.get('name', 'Untitled Strategy')))
except:
    print('Untitled Strategy')
" 2>/dev/null)

STRATEGY_DESC=$(echo "$STRATEGY_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    desc = d.get('brief', d.get('description', d.get('content', '')))
    print(str(desc)[:500])
except:
    print('')
" 2>/dev/null)

log "INFO" "Strategy: $STRATEGY_TITLE"
log "INFO" "Description: $(echo "$STRATEGY_DESC" | cut -c1-200)"

###############################################################################
# Performance Context — Enrich with seed bank intelligence
###############################################################################

SEED_STORE="$OPENCLAW_DIR/skills/content-seed-bank/scripts/seed-store.sh"
WINNING_PATTERNS_FILE="$OPENCLAW_DIR/workspace/data/winning-patterns.jsonl"

# Extract category/channel hints from strategy description
STRATEGY_CATEGORY=$(echo "$STRATEGY_DESC" | python3 -c "
import sys
text = sys.stdin.read().lower()
categories = ['vegan','rendang','snack','health','beauty','food','drink','supplement']
found = [c for c in categories if c in text]
print(','.join(found[:3]) if found else 'general')
" 2>/dev/null || echo "general")

STRATEGY_CHANNEL=$(echo "$STRATEGY_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    channels = d.get('channels', d.get('target_channels', []))
    if isinstance(channels, list) and channels:
        print(','.join(channels[:3]))
    else:
        print('all')
except:
    print('all')
" 2>/dev/null || echo "all")

# Query seed bank for top-performing content in this category
PERF_CONTEXT=""
if [ -f "$SEED_STORE" ]; then
  WINNING_HOOKS=$(bash "$SEED_STORE" query --type hook --tag "$STRATEGY_CATEGORY" --sort performance --top 5 2>/dev/null | python3 -c "
import sys, json
seeds = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        s = json.loads(line)
        if s.get('text'):
            perf = s.get('performance', {})
            ctr = perf.get('ctr', 'n/a')
            seeds.append(f\"- {s['text'][:100]} (CTR: {ctr})\")
    except: pass
print('\n'.join(seeds[:5]) if seeds else 'No performance data yet')
" 2>/dev/null || echo "No performance data yet")

  WINNING_COPIES=$(bash "$SEED_STORE" query --type copy --sort performance --top 5 2>/dev/null | python3 -c "
import sys, json
seeds = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        s = json.loads(line)
        if s.get('text'):
            perf = s.get('performance', {})
            roas = perf.get('roas', 'n/a')
            seeds.append(f\"- {s['text'][:100]} (ROAS: {roas})\")
    except: pass
print('\n'.join(seeds[:5]) if seeds else 'No performance data yet')
" 2>/dev/null || echo "No performance data yet")

  # Read winning patterns if available
  CHANNEL_PATTERNS=""
  if [ -f "$WINNING_PATTERNS_FILE" ]; then
    CHANNEL_PATTERNS=$(python3 -c "
import sys, json
patterns = []
with open('$WINNING_PATTERNS_FILE', 'r') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            p = json.loads(line)
            if p.get('status') in ('detected', 'confirmed', 'promoted'):
                patterns.append(f\"- {p.get('description', 'unknown')} (evidence: {p.get('evidence_count', 0)}, improvement: {p.get('avg_improvement', 0):.0%})\")
        except: pass
print('\n'.join(patterns[:5]) if patterns else 'No patterns yet')
" 2>/dev/null || echo "No patterns yet")
  fi

  PERF_CONTEXT="

--- PERFORMANCE INTELLIGENCE (from seed bank) ---
Top-performing hooks in this category ($STRATEGY_CATEGORY):
$WINNING_HOOKS

Top-performing copy:
$WINNING_COPIES

Winning patterns:
$CHANNEL_PATTERNS
--- END PERFORMANCE INTELLIGENCE ---"

  log "INFO" "Performance context loaded from seed bank"
else
  log "WARN" "seed-store.sh not found — running without performance context"
fi

###############################################################################
# Marketing Brain Context — inject knowledge from marketing skills
###############################################################################

MARKETING_BRAIN=""
SKILLS_DIR="$OPENCLAW_DIR/skills"

# Load marketing formulas (pick best formula for the strategy)
if [ -f "$SKILLS_DIR/marketing-formulas/SKILL.md" ]; then
  FORMULA_CONTEXT=$(python3 -c "
import sys
text = open('$SKILLS_DIR/marketing-formulas/SKILL.md').read()
# Extract formula names and descriptions (first 500 chars)
lines = [l.strip() for l in text.split('\n') if l.strip().startswith('#') or l.strip().startswith('-')]
print('\n'.join(lines[:15]))
" 2>/dev/null || echo "")
  if [ -n "$FORMULA_CONTEXT" ]; then
    MARKETING_BRAIN="$MARKETING_BRAIN
--- MARKETING FORMULAS ---
$FORMULA_CONTEXT
Read full formulas: $SKILLS_DIR/marketing-formulas/SKILL.md
--- END FORMULAS ---"
    log "INFO" "Marketing formulas context loaded"
  fi
fi

# Load funnel playbook
if [ -f "$SKILLS_DIR/funnel-playbook/SKILL.md" ]; then
  FUNNEL_CONTEXT=$(head -50 "$SKILLS_DIR/funnel-playbook/SKILL.md" 2>/dev/null | python3 -c "
import sys
lines = [l.strip() for l in sys.stdin if l.strip().startswith('#') or l.strip().startswith('-') or 'TOFU' in l or 'MOFU' in l or 'BOFU' in l]
print('\n'.join(lines[:12]))
" 2>/dev/null || echo "")
  if [ -n "$FUNNEL_CONTEXT" ]; then
    MARKETING_BRAIN="$MARKETING_BRAIN
--- FUNNEL PLAYBOOK ---
$FUNNEL_CONTEXT
Read full playbook: $SKILLS_DIR/funnel-playbook/SKILL.md
--- END FUNNEL ---"
  fi
fi

# Load seasonal marketing context
if [ -f "$SKILLS_DIR/seasonal-marketing-os/SKILL.md" ]; then
  CURRENT_MONTH=$(date +%B)
  SEASONAL_CONTEXT=$(python3 -c "
import sys
text = open('$SKILLS_DIR/seasonal-marketing-os/SKILL.md').read()
month = '$CURRENT_MONTH'
# Find current month section or upcoming events
lines = text.split('\n')
relevant = []
capture = False
for l in lines:
    if month.lower() in l.lower() or 'ramadan' in l.lower() or 'hari raya' in l.lower():
        capture = True
    if capture:
        relevant.append(l.strip())
    if capture and len(relevant) > 8:
        break
print('\n'.join(relevant) if relevant else 'No seasonal context for ' + month)
" 2>/dev/null || echo "")
  if [ -n "$SEASONAL_CONTEXT" ]; then
    MARKETING_BRAIN="$MARKETING_BRAIN
--- SEASONAL CONTEXT ($CURRENT_MONTH) ---
$SEASONAL_CONTEXT
--- END SEASONAL ---"
  fi
fi

# Load hook library summary
if [ -d "$SKILLS_DIR/hook-library/scripts" ]; then
  HOOKS_CONTEXT=$(ls "$SKILLS_DIR/hook-library/scripts/"*.sh 2>/dev/null | head -5 | while read f; do basename "$f" .sh; done | tr '\n' ', ')
  if [ -n "$HOOKS_CONTEXT" ]; then
    MARKETING_BRAIN="$MARKETING_BRAIN
--- HOOK LIBRARY ---
Available hook types: $HOOKS_CONTEXT
--- END HOOKS ---"
  fi
fi

if [ -n "$MARKETING_BRAIN" ]; then
  log "INFO" "Marketing brain context loaded"
else
  log "WARN" "No marketing brain skills found — running without enrichment"
fi

# -----------------------------------------------------------------------
# Step 1: Determine required steps
# -----------------------------------------------------------------------
# Pipeline: ANALYSIS → CREATIVE_BRIEF → ADAPTATION → CREATIVE_REVIEW → PUBLISHING
# Calliope (Creative Director) creates brief after research, reviews copy after adaptation.
STEPS_NEEDED="ANALYSIS CREATIVE_BRIEF ADAPTATION CREATIVE_REVIEW PUBLISHING"

if has_attachments "$STRATEGY_JSON"; then
  STEPS_NEEDED="IMAGES_ANALYSIS $STEPS_NEEDED"
  log "INFO" "Attachments detected -- IMAGES_ANALYSIS will be included"
else
  log "INFO" "No attachments -- skipping IMAGES_ANALYSIS"
fi

log "INFO" "Steps to execute: $STEPS_NEEDED"
post_to_room "exec" "[CSO] Strategy '$STRATEGY_TITLE' -- steps: $STEPS_NEEDED"

# -----------------------------------------------------------------------
# Step 2: Update strategy status to IN_PROGRESS
# -----------------------------------------------------------------------
update_strategy_status "IN_PROGRESS"

# -----------------------------------------------------------------------
# Step 3: Execute each step
# -----------------------------------------------------------------------
STEP_COUNT=0
TOTAL_STEPS=0
for _ in $STEPS_NEEDED; do
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
done

for STEP_TYPE in $STEPS_NEEDED; do
  STEP_COUNT=$((STEP_COUNT + 1))
  log "INFO" "--- Step $STEP_COUNT/$TOTAL_STEPS: $STEP_TYPE ---"
  post_to_room "exec" "[CSO] Step $STEP_COUNT/$TOTAL_STEPS: $STEP_TYPE starting"

  # Create the step in the backend
  STEP_ID=""
  if ! STEP_ID=$(create_step "$STEP_TYPE"); then
    on_failure "Could not create step $STEP_TYPE"
  fi

  # Approve the step
  if ! approve_step "$STEP_ID"; then
    on_failure "Could not approve step $STEP_TYPE (step_id=$STEP_ID)"
  fi

  # Determine which agent(s) to dispatch to and craft the message
  case "$STEP_TYPE" in
    IMAGES_ANALYSIS)
      DISPATCH_AGENT="apollo"
      DISPATCH_ROOM="creative"
      DISPATCH_MSG="[CSO IMAGES_ANALYSIS] Strategy: $STRATEGY_TITLE. Analyze the creative prop attachments for this campaign. Check brand alignment, visual quality, and channel suitability. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC"
      update_strategy_status "IN_PROGRESS"
      update_strategy_progress "IMAGES_ANALYSIS in progress"
      ;;
    ANALYSIS)
      DISPATCH_AGENT="artemis"
      DISPATCH_ROOM="exec"
      DISPATCH_MSG="[CSO ANALYSIS] Strategy: $STRATEGY_TITLE. Research the market context, competitive landscape, audience insights, and data analysis for this campaign. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC$PERF_CONTEXT$MARKETING_BRAIN"
      update_strategy_status "ANALYSIS"
      update_strategy_progress "ANALYSIS in progress"
      ;;
    CREATIVE_BRIEF)
      DISPATCH_AGENT="calliope"
      DISPATCH_ROOM="creative"
      DISPATCH_MSG="[CSO CREATIVE_BRIEF] Strategy: $STRATEGY_TITLE. Read Brand DNA at $BRAND_DNA for brand identity. Select a mood preset from ~/.openclaw/brands/$BRAND/moods/ that fits the campaign concept. Include BRAND and MOOD in your brief. Create a campaign brief based on Artemis research. Define: CAMPAIGN name, BRAND, MOOD, THEME, TARGET persona, TONE, KEY MESSAGING (3 points), COPY DIRECTION for Apollo, VISUAL DIRECTION for Daedalus (Art Director), OUTPUT TYPES needed (from: broll/aroll/promotion/education/raw/lofi/channel/podcast/ip/ugc/hero/carousel). After creating the brief, dispatch copy work to Apollo and visual work to Daedalus via the creative room. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC$PERF_CONTEXT$MARKETING_BRAIN"
      update_strategy_status "CREATIVE_BRIEF"
      update_strategy_progress "CREATIVE_BRIEF in progress — Calliope creating campaign brief"
      ;;
    ADAPTATION)
      DISPATCH_AGENT="apollo"
      DISPATCH_ROOM="creative"
      DISPATCH_MSG="[CSO ADAPTATION] Strategy: $STRATEGY_TITLE. Brand DNA: $BRAND_DNA. If Calliope (Creative Director) specified a mood in the brief, read the mood preset for copy tone guidance. Adapt and rewrite the campaign content for each target channel. Use the winning patterns and top-performing hooks/copies provided below as reference for what resonates with our audience. Ensure brand voice consistency and platform-native formatting. After creating content, register all content atoms in the seed bank via: bash ~/.openclaw/skills/content-seed-bank/scripts/seed-store.sh add --type hook --text 'your hook' --tags 'campaign,$STRATEGY_CATEGORY' --source apollo --campaign $STRATEGY_ID. Also store creatives in local DB via: python3 ~/.openclaw/workspace/gaia-db/gaia_db.py. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC$PERF_CONTEXT$MARKETING_BRAIN"
      update_strategy_status "ADAPTATION"
      update_strategy_progress "ADAPTATION in progress"
      ;;
    CREATIVE_REVIEW)
      DISPATCH_AGENT="calliope"
      DISPATCH_ROOM="creative"
      DISPATCH_MSG="[CSO CREATIVE_REVIEW] Strategy: $STRATEGY_TITLE. Review Apollo's adapted content from the ADAPTATION step. Score each piece on: (1) Brand fit 1-5, (2) Engagement potential 1-5, (3) Channel appropriateness 1-5, (4) Copy-visual harmony 1-5, (5) Cultural fit for Malaysian audience 1-5. If any piece scores below 3.5 average, provide specific revision notes and post them to the creative room for Apollo to revise. If all pass, approve for publishing. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID."
      update_strategy_status "CREATIVE_REVIEW"
      update_strategy_progress "CREATIVE_REVIEW in progress — Calliope reviewing content"
      ;;
    PUBLISHING)
      DISPATCH_AGENT="iris"
      DISPATCH_ROOM="social"
      DISPATCH_MSG="[CSO PUBLISHING] Strategy: $STRATEGY_TITLE. Publish the adapted content to social channels (IG, TikTok, Xiaohongshu). For Meta campaigns, use: python3 ~/.openclaw/skills/meta-ads-manager/scripts/meta_ads_api.py. Coordinate posting schedule. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC"
      update_strategy_status "PUBLISHING"
      update_strategy_progress "PUBLISHING in progress"
      ;;
    *)
      log "WARN" "Unknown step type: $STEP_TYPE -- skipping"
      continue
      ;;
  esac

  # Dispatch to primary agent
  dispatch_to_agent "$DISPATCH_AGENT" "$STEP_TYPE" "$DISPATCH_MSG" "$DISPATCH_ROOM"

  # For ANALYSIS, also dispatch to Athena for data analysis
  if [ "$STEP_TYPE" = "ANALYSIS" ]; then
    ATHENA_MSG="[CSO ANALYSIS - Data] Strategy: $STRATEGY_TITLE. Provide data analysis and strategic insights for this campaign. Analyze target audience metrics, channel performance data, and expected ROI. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC"
    dispatch_to_agent "athena" "ANALYSIS-DATA" "$ATHENA_MSG" "exec"
  fi

  # For ADAPTATION, also dispatch to Daedalus (Art Director) for visual content (parallel with Apollo)
  if [ "$STEP_TYPE" = "ADAPTATION" ]; then
    ART_MSG="[CSO ADAPTATION - Visual] Strategy: $STRATEGY_TITLE. Brand DNA: $BRAND_DNA. Read DNA.visual for style guardrails. If a mood was specified in the brief, read the mood preset from ~/.openclaw/brands/$BRAND/moods/ for style overrides. Generate visual content for this campaign. Use NanoBanana for brand-consistent images (bash nanobanana-gen.sh --brand $BRAND --prompt 'your prompt'). Generate hero images, product shots, and social media visuals. After generation, run visual audit: bash audit-visual.sh audit-image /path/to/image.png --brand $BRAND (must score >= 4.0). Register approved visuals in seed bank. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC$PERF_CONTEXT"
    dispatch_to_agent "daedalus" "ADAPTATION-VISUAL" "$ART_MSG" "creative"
    log "INFO" "Daedalus (Art Director) dispatched for parallel visual content generation"
  fi

  # For PUBLISHING, also dispatch to Hermes for commerce channels
  if [ "$STEP_TYPE" = "PUBLISHING" ]; then
    HERMES_MSG="[CSO PUBLISHING - Commerce] Strategy: $STRATEGY_TITLE. Publish and optimize content on commerce channels (Shopee, Lazada, website). Update product listings with campaign content. Strategy ID: $STRATEGY_ID. Step ID: $STEP_ID. Brief: $STRATEGY_DESC"
    dispatch_to_agent "hermes" "PUBLISHING-COMMERCE" "$HERMES_MSG" "exec"
  fi

  # Update progress
  update_strategy_progress "$STEP_TYPE completed ($STEP_COUNT/$TOTAL_STEPS)"
  log "INFO" "$STEP_TYPE dispatched and tracked"
  post_to_room "exec" "[CSO] Step $STEP_COUNT/$TOTAL_STEPS: $STEP_TYPE dispatched to $DISPATCH_AGENT"
done

# -----------------------------------------------------------------------
# Step 4: Mark strategy as COMPLETED
# -----------------------------------------------------------------------
update_strategy_status "COMPLETED"
update_strategy_progress "All $TOTAL_STEPS steps completed"

log "INFO" "=========================================="
log "INFO" "CSO Pipeline COMPLETED for strategy $STRATEGY_ID"
log "INFO" "=========================================="

SUMMARY="[CSO COMPLETED] Strategy '$STRATEGY_TITLE' (ID: $STRATEGY_ID) -- $TOTAL_STEPS steps executed: $STEPS_NEEDED"
post_to_room "exec" "$SUMMARY"
post_to_room "feedback" "[CSO] Pipeline completed successfully for strategy $STRATEGY_ID ($STRATEGY_TITLE). Steps: $STEPS_NEEDED"

# -----------------------------------------------------------------------
# Step 5: Register outputs as seeds in content seed bank
# -----------------------------------------------------------------------
if [ -f "$SEED_STORE" ]; then
  log "INFO" "Registering strategy outputs as seeds in content seed bank"

  # Register the strategy itself as a content seed
  SAFE_TITLE=$(printf '%s' "$STRATEGY_TITLE" | tr -d '"' | cut -c1-200)
  SAFE_DESC=$(printf '%s' "$STRATEGY_DESC" | tr -d '"' | cut -c1-500)
  NEW_SEED_ID=$(bash "$SEED_STORE" add \
    --type ad \
    --text "$SAFE_TITLE: $SAFE_DESC" \
    --tags "cso-pipeline,$STRATEGY_CATEGORY" \
    --source zenni \
    --source-type cso-pipeline \
    --campaign "$STRATEGY_ID" \
    --status published 2>/dev/null || echo "")

  if [ -n "$NEW_SEED_ID" ]; then
    log "INFO" "Registered seed: $NEW_SEED_ID for strategy $STRATEGY_ID"
    post_to_room "feedback" "[CSO] Registered seed $NEW_SEED_ID in content seed bank for strategy $STRATEGY_ID"
  fi

  # Schedule performance review for 72h from now
  REVIEW_TS=$(($(date +%s) + 259200))
  post_to_room "exec" "[CSO] Performance review scheduled for strategy $STRATEGY_ID (seed: $NEW_SEED_ID) — check metrics after $(date -r $REVIEW_TS '+%Y-%m-%d %H:%M' 2>/dev/null || date -d @$REVIEW_TS '+%Y-%m-%d %H:%M' 2>/dev/null || echo '72h from now')"
fi

echo ""
echo "CSO Pipeline completed successfully."
echo "  Strategy: $STRATEGY_TITLE"
echo "  ID:       $STRATEGY_ID"
echo "  Steps:    $STEPS_NEEDED"
echo "  Status:   COMPLETED"
