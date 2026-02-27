#!/usr/bin/env bash
# e2e-test.sh — End-to-end pipeline test for GAIA Creative Production
# Tests the full chain: brief -> art direction -> generate -> post-prod -> review
# Uses dry-run/mock mode to avoid real API calls and costs
#
# Usage: bash e2e-test.sh [--verbose]
#
# Bash 3.2 compatible (macOS). No jq, no declare -A, no timeout.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
TOTAL=0
VERBOSE="false"

# Parse args
for arg in "$@"; do
  case "$arg" in
    --verbose|-v) VERBOSE="true" ;;
  esac
done

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "  [FAIL] $1 — $2"; }

log_verbose() {
  if [ "$VERBOSE" = "true" ]; then
    echo "        $1"
  fi
}

# Key paths
OC="$HOME/.openclaw"
WS="$OC/workspace"
SKILLS="$OC/skills"
BRANDS="$OC/brands"
STUDIO="$WS/apps/gaia-creative-studio"
DATA="$WS/data"
RAG="$WS/rag"
ROOMS="$WS/rooms"

echo "========================================"
echo " GAIA CREATIVE PIPELINE — E2E TEST"
echo " $(date '+%Y-%m-%d %H:%M:%S MYT')"
echo "========================================"
echo ""

# =========================================================================
# 1. BRAND LOADER TEST
# =========================================================================
echo "[1/13] Brand Loader"

BRAND_LOADER="$STUDIO/server/lib/brand-loader.js"
if [ -f "$BRAND_LOADER" ]; then
  pass "brand-loader.js exists"
else
  fail "brand-loader.js exists" "not found at $BRAND_LOADER"
fi

# Check exports: loadBrand, loadAllBrands, loadCampaign, loadActiveCampaigns, saveCampaign
for fn in loadBrand loadAllBrands loadCampaign loadActiveCampaigns saveCampaign; do
  if grep -q "export.*function $fn" "$BRAND_LOADER" 2>/dev/null; then
    pass "brand-loader exports $fn"
  else
    fail "brand-loader exports $fn" "function $fn not found"
  fi
done

# Check at least 7 brands loadable (check both brand directories)
BRAND_COUNT=0
for dir in "$BRANDS"/*/ "$WS/brands"/*/; do
  if [ -d "$dir" ]; then
    BRAND_COUNT=$((BRAND_COUNT + 1))
  fi
done
if [ "$BRAND_COUNT" -ge 7 ]; then
  pass "At least 7 brand dirs exist ($BRAND_COUNT found)"
else
  fail "At least 7 brand dirs exist" "only $BRAND_COUNT found"
fi

# Slug normalization
if grep -q "'pinxin'.*'pinxin-vegan'" "$BRAND_LOADER" 2>/dev/null; then
  pass "Slug normalization: pinxin -> pinxin-vegan"
else
  fail "Slug normalization: pinxin -> pinxin-vegan" "not found in SLUG_MAP"
fi
echo ""

# =========================================================================
# 2. ASSET BRIDGE TEST
# =========================================================================
echo "[2/13] Asset Bridge"

ASSET_BRIDGE="$SKILLS/image-seed-bank/scripts/asset-bridge.sh"
if [ -f "$ASSET_BRIDGE" ] && [ -x "$ASSET_BRIDGE" ]; then
  pass "asset-bridge.sh exists and executable"
else
  if [ -f "$ASSET_BRIDGE" ]; then
    fail "asset-bridge.sh executable" "file exists but not executable"
  else
    fail "asset-bridge.sh exists" "not found at $ASSET_BRIDGE"
  fi
fi

LIBRARY_DB="$STUDIO/server/data/library.db"
if [ -f "$LIBRARY_DB" ]; then
  # Check for assets table
  HAS_ASSETS=$(python3 -c "
import sqlite3, sys
try:
    conn = sqlite3.connect('$LIBRARY_DB')
    cur = conn.execute(\"SELECT name FROM sqlite_master WHERE type='table' AND name='assets'\")
    print('yes' if cur.fetchone() else 'no')
    conn.close()
except:
    print('no')
" 2>/dev/null)
  if [ "$HAS_ASSETS" = "yes" ]; then
    pass "library.db has assets table"
  else
    fail "library.db has assets table" "table not found"
  fi
else
  fail "library.db exists" "not found at $LIBRARY_DB"
fi

SEED_JSONL="$RAG/image-seed-bank.jsonl"
if [ -f "$SEED_JSONL" ]; then
  pass "image-seed-bank.jsonl exists"
else
  fail "image-seed-bank.jsonl exists" "not found at $SEED_JSONL"
fi

# Dry-run test
if bash "$ASSET_BRIDGE" --dry-run >/dev/null 2>&1; then
  pass "asset-bridge.sh --dry-run exits 0"
else
  fail "asset-bridge.sh --dry-run exits 0" "exit code $?"
fi
echo ""

# =========================================================================
# 3. STYLE DIGEST TEST
# =========================================================================
echo "[3/13] Style Digest"

STYLE_DIGEST="$STUDIO/server/routes/style-digest.js"
if [ -f "$STYLE_DIGEST" ]; then
  pass "style-digest.js exists"
else
  fail "style-digest.js exists" "not found at $STYLE_DIGEST"
fi

# Check for /save route
if grep -q "router\.\(post\|put\).*['\"/]save['\"]" "$STYLE_DIGEST" 2>/dev/null; then
  pass "style-digest.js has /save endpoint"
else
  fail "style-digest.js has /save endpoint" "route not found"
fi

# Check for /seeds route
if grep -q "router\.get.*['\"/]seeds['\"]" "$STYLE_DIGEST" 2>/dev/null; then
  pass "style-digest.js has /seeds endpoint"
else
  fail "style-digest.js has /seeds endpoint" "route not found"
fi

# Check style_seeds table definition (created at module load, may not exist in DB at test time)
if grep -q "CREATE TABLE IF NOT EXISTS style_seeds" "$STYLE_DIGEST" 2>/dev/null; then
  pass "style-digest.js defines style_seeds table"
else
  fail "style-digest.js defines style_seeds table" "CREATE TABLE not found"
fi

# Check image-seed.sh has digest and query-style subcommands
IMAGE_SEED="$SKILLS/image-seed-bank/scripts/image-seed.sh"
if grep -q "digest)" "$IMAGE_SEED" 2>/dev/null; then
  pass "image-seed.sh has digest subcommand"
else
  fail "image-seed.sh has digest subcommand" "not found"
fi

if grep -q "query-style)" "$IMAGE_SEED" 2>/dev/null; then
  pass "image-seed.sh has query-style subcommand"
else
  fail "image-seed.sh has query-style subcommand" "not found"
fi
echo ""

# =========================================================================
# 4. VIDEO-GEN TEST
# =========================================================================
echo "[4/13] Video Gen"

VIDEO_GEN="$SKILLS/video-gen/scripts/video-gen.sh"
if [ -f "$VIDEO_GEN" ] && [ -x "$VIDEO_GEN" ]; then
  pass "video-gen.sh exists and executable"
else
  if [ -f "$VIDEO_GEN" ]; then
    fail "video-gen.sh executable" "file exists but not executable"
  else
    fail "video-gen.sh exists" "not found at $VIDEO_GEN"
  fi
fi

# --help exits 0
if bash "$VIDEO_GEN" --help >/dev/null 2>&1; then
  pass "video-gen.sh --help exits 0"
else
  fail "video-gen.sh --help exits 0" "exit code $?"
fi

# Check for provider commands
for cmd in kling wan sora pipeline reverse-prompt; do
  if grep -q "$cmd" "$VIDEO_GEN" 2>/dev/null; then
    pass "video-gen.sh has $cmd command"
  else
    fail "video-gen.sh has $cmd command" "not found in script"
  fi
done
echo ""

# =========================================================================
# 5. CAMPAIGN TEST
# =========================================================================
echo "[5/13] Campaigns"

# Check at least 1 campaign file exists
CAMPAIGN_FILES=""
CAMPAIGN_COUNT=0
for cf in "$BRANDS/pinxin-vegan/campaigns/cny-2026.json" \
          "$BRANDS/mirra/campaigns/ramadan-2026.json" \
          "$BRANDS/gaia-eats/campaigns/mco-meal-kits.json"; do
  if [ -f "$cf" ]; then
    CAMPAIGN_COUNT=$((CAMPAIGN_COUNT + 1))
    CAMPAIGN_FILES="$cf"
  fi
done

if [ "$CAMPAIGN_COUNT" -ge 1 ]; then
  pass "At least 1 campaign file exists ($CAMPAIGN_COUNT found)"
else
  fail "At least 1 campaign file exists" "none found"
fi

# Validate campaign JSON (test first found campaign)
if [ -n "$CAMPAIGN_FILES" ]; then
  VALID=$(python3 -c "
import json, sys
try:
    json.load(open('$CAMPAIGN_FILES'))
    print('valid')
except Exception as e:
    print('invalid: ' + str(e))
" 2>/dev/null)
  if [ "$VALID" = "valid" ]; then
    pass "Campaign JSON is valid ($CAMPAIGN_FILES)"
  else
    fail "Campaign JSON valid" "$VALID"
  fi
fi

# Check brands.js has campaign endpoints
BRANDS_ROUTE="$STUDIO/server/routes/brands.js"
if grep -q "/campaigns" "$BRANDS_ROUTE" 2>/dev/null; then
  pass "brands.js has /campaigns endpoints"
else
  fail "brands.js has /campaigns endpoints" "not found"
fi
echo ""

# =========================================================================
# 6. OUTPUT TYPES TEST
# =========================================================================
echo "[6/13] Output Types"

OUTPUT_TYPES="$DATA/output-types.json"
PROD_CHAINS="$DATA/production-chains.json"

# Check ugly_ads in output-types.json
if grep -q "ugly_ads" "$OUTPUT_TYPES" 2>/dev/null; then
  pass "output-types.json has ugly_ads entry"
else
  fail "output-types.json has ugly_ads entry" "not found"
fi

# Check ugly_ads in production-chains.json
if grep -q "ugly_ads" "$PROD_CHAINS" 2>/dev/null; then
  pass "production-chains.json has ugly_ads chain"
else
  fail "production-chains.json has ugly_ads chain" "not found"
fi

# Validate output-types.json and count entries
OT_RESULT=$(python3 -c "
import json, sys
try:
    data = json.load(open('$OUTPUT_TYPES'))
    if isinstance(data, list):
        count = len(data)
    elif isinstance(data, dict) and 'output_types' in data:
        count = len(data['output_types'])
    else:
        count = len(data)
    if count >= 12:
        print('pass:' + str(count))
    else:
        print('fail:only ' + str(count) + ' entries')
except Exception as e:
    print('fail:' + str(e))
" 2>/dev/null)

OT_STATUS=$(echo "$OT_RESULT" | cut -d: -f1)
OT_DETAIL=$(echo "$OT_RESULT" | cut -d: -f2-)

if [ "$OT_STATUS" = "pass" ]; then
  pass "output-types.json valid with $OT_DETAIL entries"
else
  fail "output-types.json valid with 12+ entries" "$OT_DETAIL"
fi
echo ""

# =========================================================================
# 7. HANDOFF TEST
# =========================================================================
echo "[7/13] Handoff Protocol"

HANDOFF="$SKILLS/creative-production/scripts/handoff-dispatch.sh"
HANDOFF_MD="$SKILLS/creative-production/handoff-protocol.md"

if [ -f "$HANDOFF" ] && [ -x "$HANDOFF" ]; then
  pass "handoff-dispatch.sh exists and executable"
else
  if [ -f "$HANDOFF" ]; then
    fail "handoff-dispatch.sh executable" "file exists but not executable"
  else
    fail "handoff-dispatch.sh exists" "not found at $HANDOFF"
  fi
fi

if [ -f "$HANDOFF_MD" ]; then
  pass "handoff-protocol.md exists"
else
  fail "handoff-protocol.md exists" "not found"
fi

# Test list command
if bash "$HANDOFF" list >/dev/null 2>&1; then
  pass "handoff-dispatch.sh list exits 0"
else
  fail "handoff-dispatch.sh list exits 0" "exit code $?"
fi
echo ""

# =========================================================================
# 8. GENERATION METADATA TEST
# =========================================================================
echo "[8/13] Generation Metadata"

GENERATE_JS="$STUDIO/server/routes/generate.js"
METADATA_FIELDS="model prompt brand campaign funnel_stage style_seed_id output_type references generated_by handoff_id"

for field in $METADATA_FIELDS; do
  if grep -q "$field" "$GENERATE_JS" 2>/dev/null; then
    pass "generate.js has $field in generation_params"
  else
    fail "generate.js has $field" "not found in generate.js"
  fi
done
echo ""

# =========================================================================
# 9. INTAKE ENGINE TEST
# =========================================================================
echo "[9/13] Intake Engine"

INTAKE_DIR="$SKILLS/creative-intake/scripts"
for script in intake-processor.sh intake-classify.sh intake-watch.sh; do
  SPATH="$INTAKE_DIR/$script"
  if [ -f "$SPATH" ] && [ -x "$SPATH" ]; then
    pass "$script exists and executable"
  else
    if [ -f "$SPATH" ]; then
      fail "$script executable" "file exists but not executable"
    else
      fail "$script exists" "not found at $SPATH"
    fi
  fi
done

# intake.jsonl room
INTAKE_ROOM="$ROOMS/intake.jsonl"
if [ -f "$INTAKE_ROOM" ]; then
  pass "intake.jsonl room exists"
else
  fail "intake.jsonl room exists" "not found at $INTAKE_ROOM"
fi

# approval-queue.sh
APPROVAL="$INTAKE_DIR/approval-queue.sh"
if [ -f "$APPROVAL" ] && [ -x "$APPROVAL" ]; then
  pass "approval-queue.sh exists and executable"
else
  if [ -f "$APPROVAL" ]; then
    fail "approval-queue.sh executable" "file exists but not executable"
  else
    fail "approval-queue.sh exists" "not found"
  fi
fi

# approval-queue.sh count
if bash "$APPROVAL" count >/dev/null 2>&1; then
  pass "approval-queue.sh count exits 0"
else
  fail "approval-queue.sh count exits 0" "exit code $?"
fi
echo ""

# =========================================================================
# 10. WORKFLOW AUTOMATION TEST
# =========================================================================
echo "[10/13] Workflow Automation"

WF_DIR="$SKILLS/workflow-automation/scripts"

REGISTER="$WF_DIR/register-output-type.sh"
if [ -f "$REGISTER" ] && [ -x "$REGISTER" ]; then
  pass "register-output-type.sh exists and executable"
else
  if [ -f "$REGISTER" ]; then
    fail "register-output-type.sh executable" "file exists but not executable"
  else
    fail "register-output-type.sh exists" "not found"
  fi
fi

# skill-registry.json valid
SKILL_REG="$DATA/skill-registry.json"
SR_VALID=$(python3 -c "
import json
try:
    json.load(open('$SKILL_REG'))
    print('valid')
except Exception as e:
    print('invalid: ' + str(e))
" 2>/dev/null)
if [ "$SR_VALID" = "valid" ]; then
  pass "skill-registry.json is valid JSON"
else
  fail "skill-registry.json valid JSON" "$SR_VALID"
fi

# production-chains.json valid
PC_VALID=$(python3 -c "
import json
try:
    json.load(open('$PROD_CHAINS'))
    print('valid')
except Exception as e:
    print('invalid: ' + str(e))
" 2>/dev/null)
if [ "$PC_VALID" = "valid" ]; then
  pass "production-chains.json is valid JSON"
else
  fail "production-chains.json valid JSON" "$PC_VALID"
fi

# list-output-types.sh exits 0
LIST_OT="$WF_DIR/list-output-types.sh"
if bash "$LIST_OT" >/dev/null 2>&1; then
  pass "list-output-types.sh exits 0"
else
  fail "list-output-types.sh exits 0" "exit code $?"
fi
echo ""

# =========================================================================
# 11. STALE REF TEST
# =========================================================================
echo "[11/13] Stale References (apollo/artee)"

# Scripts to check for stale references to removed agents
STALE_SCRIPTS="
$SKILLS/cso-pipeline/scripts/cso-run.sh
$SKILLS/orchestrate-v2/scripts/dispatch.sh
$SKILLS/agent-vitality/scripts/pulse.sh
$SKILLS/agent-vitality/scripts/cross-pollinate.sh
"

STALE_FOUND=0
for script in $STALE_SCRIPTS; do
  if [ ! -f "$script" ]; then
    log_verbose "Skipping (not found): $script"
    continue
  fi
  # grep for apollo or artee (case-insensitive), excluding comments and archive references
  MATCHES=$(grep -inE '\bapollo\b|\bartee\b' "$script" 2>/dev/null | grep -v '^\s*#' | grep -v 'archive' | grep -v 'history' || true)
  if [ -n "$MATCHES" ]; then
    STALE_FOUND=$((STALE_FOUND + 1))
    fail "No stale refs in $(basename "$script")" "found apollo/artee reference"
    if [ "$VERBOSE" = "true" ]; then
      echo "$MATCHES" | while read -r line; do
        log_verbose "$line"
      done
    fi
  fi
done

if [ "$STALE_FOUND" -eq 0 ]; then
  pass "No stale apollo/artee refs in active scripts"
fi
echo ""

# =========================================================================
# 12. FRONTEND TEST
# =========================================================================
echo "[12/13] Frontend Components"

CREATE_JSX="$STUDIO/client/src/pages/Create.jsx"
LIBRARY_JSX="$STUDIO/client/src/pages/Library.jsx"
BRAND_SEL="$STUDIO/client/src/components/BrandSelector.jsx"

for comp in "$CREATE_JSX" "$LIBRARY_JSX" "$BRAND_SEL"; do
  BASENAME=$(basename "$comp")
  if [ -f "$comp" ]; then
    pass "$BASENAME exists"
  else
    fail "$BASENAME exists" "not found at $comp"
  fi
done

# Check key features in Create.jsx
for feature in styleSeedId funnelStage bulkMode; do
  if grep -q "$feature" "$CREATE_JSX" 2>/dev/null; then
    pass "Create.jsx has $feature"
  else
    fail "Create.jsx has $feature" "not found"
  fi
done

# Check multiSelect in Library.jsx
if grep -q "multiSelect\|multiSelected" "$LIBRARY_JSX" 2>/dev/null; then
  pass "Library.jsx has multiSelect"
else
  fail "Library.jsx has multiSelect" "not found"
fi
echo ""

# =========================================================================
# 13. SYNTAX VALIDATION
# =========================================================================
echo "[13/13] Syntax Validation"

# Bash scripts to validate
BASH_SCRIPTS="
$SKILLS/video-gen/scripts/video-gen.sh
$SKILLS/image-seed-bank/scripts/asset-bridge.sh
$SKILLS/creative-production/scripts/handoff-dispatch.sh
$SKILLS/creative-intake/scripts/intake-processor.sh
$SKILLS/creative-intake/scripts/intake-classify.sh
$SKILLS/creative-intake/scripts/intake-watch.sh
$SKILLS/creative-intake/scripts/approval-queue.sh
$SKILLS/creative-intake/scripts/tier-check.sh
$SKILLS/creative-intake/scripts/notify-human.sh
$SKILLS/workflow-automation/scripts/register-output-type.sh
$SKILLS/workflow-automation/scripts/list-output-types.sh
$SKILLS/workflow-automation/scripts/update-skill-registry.sh
"

for script in $BASH_SCRIPTS; do
  SNAME=$(basename "$script")
  if [ ! -f "$script" ]; then
    fail "syntax $SNAME" "file not found"
    continue
  fi
  if bash -n "$script" 2>/dev/null; then
    pass "syntax $SNAME"
  else
    fail "syntax $SNAME" "bash -n failed"
  fi
done

# JSON files to validate
JSON_FILES="
$DATA/skill-registry.json
$DATA/production-chains.json
$DATA/output-types.json
"

# Add campaign JSONs
for cf in "$BRANDS/pinxin-vegan/campaigns/cny-2026.json" \
          "$BRANDS/mirra/campaigns/ramadan-2026.json" \
          "$BRANDS/gaia-eats/campaigns/mco-meal-kits.json"; do
  if [ -f "$cf" ]; then
    JSON_FILES="$JSON_FILES
$cf"
  fi
done

for jf in $JSON_FILES; do
  JNAME=$(basename "$jf")
  if [ ! -f "$jf" ]; then
    fail "json $JNAME" "file not found"
    continue
  fi
  JV=$(python3 -c "
import json, sys
try:
    json.load(open(sys.argv[1]))
    print('valid')
except Exception as e:
    print('invalid: ' + str(e))
" "$jf" 2>/dev/null)
  if [ "$JV" = "valid" ]; then
    pass "json $JNAME"
  else
    fail "json $JNAME" "$JV"
  fi
done
echo ""

# =========================================================================
# SUMMARY
# =========================================================================
echo "========================================"
echo " TOTAL: $TOTAL | PASS: $PASS | FAIL: $FAIL"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
