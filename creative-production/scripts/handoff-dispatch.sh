#!/usr/bin/env bash
# handoff-dispatch.sh — Orchestrates the creative production handoff chain
#
# Usage:
#   bash handoff-dispatch.sh start --brand <brand> --campaign <campaign> --funnel-stage <stage> --output-type <type> --prompt "<brief>"
#   bash handoff-dispatch.sh status --handoff-id <id>
#   bash handoff-dispatch.sh list [--brand <brand>] [--status active|completed|failed]
#
# The 'start' command initiates the full pipeline. Each stage dispatches to the next agent.
#
# macOS Bash 3.2 compatible: no declare -A, no ${var,,}, no timeout, no jq
# ---

set -uo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
OPENCLAW_DIR="$HOME/.openclaw"
BRANDS_DIR="$OPENCLAW_DIR/brands"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
DISPATCH_SH="$OPENCLAW_DIR/skills/mission-control/scripts/dispatch.sh"
ROOM_WRITE_SH="$OPENCLAW_DIR/workspace/scripts/room-write.sh"
LOG_FILE="$OPENCLAW_DIR/logs/handoff-dispatch.log"

# Pipeline stage order
STAGES="BRIEF ART_DIRECTION GENERATION POST_PRODUCTION REVIEW PLACEMENT"

# Stage -> agent mapping
stage_agent() {
  local stage="$1"
  case "$stage" in
    BRIEF)            echo "dreami" ;;
    ART_DIRECTION)    echo "iris" ;;
    GENERATION)       echo "iris" ;;
    POST_PRODUCTION)  echo "taoz" ;;
    REVIEW)           echo "iris,dreami,hermes" ;;
    PLACEMENT)        echo "hermes" ;;
    *)                echo "unknown" ;;
  esac
}

# Get the next stage after a given stage
next_stage() {
  local current="$1"
  local found="false"
  for s in $STAGES; do
    if [ "$found" = "true" ]; then
      echo "$s"
      return 0
    fi
    if [ "$s" = "$current" ]; then
      found="true"
    fi
  done
  echo ""
  return 0
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die() {
  echo "ERROR: $*" >&2
  log_msg "ERROR" "$*"
  exit 1
}

log_msg() {
  local level="$1"
  shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$ts] [$level] $*" >> "$LOG_FILE"
}

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Post a handoff message to creative.jsonl room
post_handoff_to_room() {
  local agent="$1"
  local stage="$2"
  local nstage="$3"
  local nagent="$4"
  local brand="$5"
  local campaign="$6"
  local funnel="$7"
  local otype="$8"
  local artifact="$9"
  local hid="${10}"

  local ts
  ts=$(epoch_ms)

  local entry
  entry=$(python3 -c "
import json
entry = {
    'ts': $ts,
    'agent': '$agent',
    'type': 'handoff',
    'stage': '$stage',
    'next_stage': '$nstage',
    'next_agent': '$nagent',
    'brand': '$brand',
    'campaign': '$campaign',
    'funnel_stage': '$funnel',
    'output_type': '$otype',
    'artifact_path': '$artifact',
    'handoff_id': '$hid'
}
print(json.dumps(entry))
")

  mkdir -p "$ROOMS_DIR"
  echo "$entry" >> "$ROOMS_DIR/creative.jsonl"
  log_msg "INFO" "Handoff posted to creative.jsonl: $hid stage=$stage next=$nstage"
}

# ---------------------------------------------------------------------------
# Command: start
# ---------------------------------------------------------------------------
cmd_start() {
  local brand="" campaign="" funnel_stage="" output_type="" prompt=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)         brand="$2";         shift 2 ;;
      --campaign)      campaign="$2";      shift 2 ;;
      --funnel-stage)  funnel_stage="$2";  shift 2 ;;
      --output-type)   output_type="$2";   shift 2 ;;
      --prompt)        prompt="$2";        shift 2 ;;
      *) die "start: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ]    && die "start: --brand is required"
  [ -z "$campaign" ] && die "start: --campaign is required"
  [ -z "$prompt" ]   && die "start: --prompt is required"

  # Defaults
  [ -z "$funnel_stage" ] && funnel_stage="TOFU"
  [ -z "$output_type" ]  && output_type="hero"

  # Normalize funnel stage to uppercase (Bash 3.2 safe)
  funnel_stage=$(echo "$funnel_stage" | tr 'a-z' 'A-Z')

  # 1. Generate handoff ID
  local ts_epoch
  ts_epoch=$(date +%s)
  local handoff_id="ho-${ts_epoch}"

  # 2. Create campaign working directory
  local campaign_dir="$BRANDS_DIR/$brand/campaigns/$campaign"
  mkdir -p "$campaign_dir/briefs"
  mkdir -p "$campaign_dir/art-direction"
  mkdir -p "$campaign_dir/generated"
  mkdir -p "$campaign_dir/final"
  mkdir -p "$campaign_dir/reviews"

  log_msg "INFO" "Created campaign dirs: $campaign_dir"

  # 3. Create handoff manifest
  local manifest_path="$campaign_dir/handoff-${handoff_id}.json"
  local now_iso
  now_iso=$(iso_now)

  # Write prompt to temp file to avoid shell escaping issues with heredoc
  local prompt_tmp="/tmp/handoff-prompt-$$.txt"
  printf '%s' "$prompt" > "$prompt_tmp"

  python3 -c "
import json, sys

manifest_path = sys.argv[1]
handoff_id = sys.argv[2]
brand = sys.argv[3]
campaign = sys.argv[4]
funnel_stage = sys.argv[5]
output_type = sys.argv[6]
now_iso = sys.argv[7]
prompt_file = sys.argv[8]

with open(prompt_file) as f:
    prompt = f.read().strip()

manifest = {
    'handoff_id': handoff_id,
    'brand': brand,
    'campaign': campaign,
    'funnel_stage': funnel_stage,
    'output_type': output_type,
    'prompt': prompt,
    'status': 'active',
    'current_stage': 'BRIEF',
    'stages': {
        'BRIEF': {'status': 'in_progress', 'agent': 'dreami', 'artifact': None, 'started_at': now_iso, 'completed_at': None},
        'ART_DIRECTION': {'status': 'pending', 'agent': 'iris', 'artifact': None, 'started_at': None, 'completed_at': None},
        'GENERATION': {'status': 'pending', 'agent': 'iris', 'artifact': None, 'started_at': None, 'completed_at': None},
        'POST_PRODUCTION': {'status': 'pending', 'agent': 'taoz', 'artifact': None, 'started_at': None, 'completed_at': None},
        'REVIEW': {'status': 'pending', 'agent': 'iris,dreami,hermes', 'artifact': None, 'started_at': None, 'completed_at': None},
        'PLACEMENT': {'status': 'pending', 'agent': 'hermes', 'artifact': None, 'started_at': None, 'completed_at': None}
    },
    'revision_count': 0,
    'max_revisions': 2,
    'created_at': now_iso,
    'updated_at': now_iso
}

with open(manifest_path, 'w') as f:
    json.dump(manifest, f, indent=2)
" "$manifest_path" "$handoff_id" "$brand" "$campaign" "$funnel_stage" "$output_type" "$now_iso" "$prompt_tmp"

  if [ ! -f "$manifest_path" ]; then
    die "Failed to create handoff manifest at $manifest_path"
  fi

  log_msg "INFO" "Manifest created: $manifest_path"

  # 4. Stage 1 — BRIEF: Build creative brief JSON
  local brief_path="$campaign_dir/briefs/brief-${handoff_id}.json"

  # Load brand DNA if available
  local brand_dna_path="$BRANDS_DIR/$brand/DNA.json"
  local brand_name="$brand"
  if [ -f "$brand_dna_path" ]; then
    brand_name=$(python3 -c "
import json
try:
    with open('$brand_dna_path') as f:
        d = json.load(f)
    print(d.get('name', '$brand'))
except:
    print('$brand')
" 2>/dev/null || echo "$brand")
  fi

  python3 -c "
import json, sys, datetime

brief_path = sys.argv[1]
handoff_id = sys.argv[2]
brand = sys.argv[3]
brand_name = sys.argv[4]
campaign = sys.argv[5]
funnel_stage = sys.argv[6]
output_type = sys.argv[7]
prompt_file = sys.argv[8]

with open(prompt_file) as f:
    prompt = f.read().strip()

brief = {
    'handoff_id': handoff_id,
    'brand': brand,
    'brand_name': brand_name,
    'campaign': campaign,
    'funnel_stage': funnel_stage,
    'output_type': output_type,
    'prompt': prompt,
    'copy_direction': 'To be filled by Dreami',
    'visual_direction': 'To be filled by Dreami',
    'hook_angles': [],
    'target_audience': '',
    'channels': [],
    'created_at': datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'status': 'draft'
}

with open(brief_path, 'w') as f:
    json.dump(brief, f, indent=2)
" "$brief_path" "$handoff_id" "$brand" "$brand_name" "$campaign" "$funnel_stage" "$output_type" "$prompt_tmp"

  # Clean up temp file
  rm -f "$prompt_tmp"

  if [ ! -f "$brief_path" ]; then
    die "Failed to create brief at $brief_path"
  fi

  log_msg "INFO" "Brief created: $brief_path"

  # 5. Dispatch to Dreami
  local brief_rel="brands/$brand/campaigns/$campaign/briefs/brief-${handoff_id}.json"
  local dispatch_msg="[HANDOFF $handoff_id] Creative brief ready for review and enrichment. Brand: $brand, Campaign: $campaign, Funnel: $funnel_stage, Output: $output_type. Brief: $brief_rel. Please enrich the brief with copy direction, visual direction, and hook angles, then dispatch to Iris for art direction."

  if [ -f "$DISPATCH_SH" ]; then
    bash "$DISPATCH_SH" "handoff-dispatch" "dreami" "handoff" "$dispatch_msg" "creative" 2>/dev/null || \
      log_msg "WARN" "Dispatch to dreami failed (non-fatal)"
  else
    log_msg "WARN" "dispatch.sh not found at $DISPATCH_SH"
  fi

  # 6. Post handoff start message to creative.jsonl
  local next="ART_DIRECTION"
  local next_ag
  next_ag=$(stage_agent "$next")
  post_handoff_to_room "handoff-dispatch" "BRIEF" "$next" "$next_ag" "$brand" "$campaign" "$funnel_stage" "$output_type" "$brief_rel" "$handoff_id"

  # 7. Output result
  echo "Handoff started."
  echo "  Handoff ID:  $handoff_id"
  echo "  Brand:       $brand ($brand_name)"
  echo "  Campaign:    $campaign"
  echo "  Funnel:      $funnel_stage"
  echo "  Output type: $output_type"
  echo "  Brief:       $brief_path"
  echo "  Manifest:    $manifest_path"
  echo "  Status:      active (Stage 1: BRIEF -> Dreami)"
  echo ""
  echo "Track progress: bash handoff-dispatch.sh status --handoff-id $handoff_id"

  log_msg "INFO" "Handoff $handoff_id started for $brand/$campaign"
}

# ---------------------------------------------------------------------------
# Command: status
# ---------------------------------------------------------------------------
cmd_status() {
  local handoff_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --handoff-id) handoff_id="$2"; shift 2 ;;
      *) die "status: unknown option: $1" ;;
    esac
  done

  [ -z "$handoff_id" ] && die "status: --handoff-id is required"

  # Find the manifest by scanning brand campaign directories
  local manifest_path=""
  manifest_path=$(find "$BRANDS_DIR" -name "handoff-${handoff_id}.json" -type f 2>/dev/null | head -1)

  if [ -z "$manifest_path" ] || [ ! -f "$manifest_path" ]; then
    die "Handoff manifest not found for ID: $handoff_id"
  fi

  # Display status using python3
  python3 - "$manifest_path" << 'PYEOF'
import json, sys

manifest_path = sys.argv[1]
with open(manifest_path) as f:
    m = json.load(f)

print(f"Handoff: {m['handoff_id']}")
print(f"  Brand:       {m['brand']}")
print(f"  Campaign:    {m['campaign']}")
print(f"  Funnel:      {m['funnel_stage']}")
print(f"  Output type: {m['output_type']}")
print(f"  Status:      {m['status']}")
print(f"  Stage:       {m['current_stage']}")
print(f"  Revisions:   {m.get('revision_count', 0)}/{m.get('max_revisions', 2)}")
print(f"  Created:     {m['created_at']}")
print(f"  Updated:     {m['updated_at']}")
print()
print("  Pipeline:")

stage_order = ["BRIEF", "ART_DIRECTION", "GENERATION", "POST_PRODUCTION", "REVIEW", "PLACEMENT"]
for stage in stage_order:
    info = m["stages"].get(stage, {})
    status = info.get("status", "unknown")
    agent = info.get("agent", "?")
    artifact = info.get("artifact", "")

    if status == "completed":
        marker = "[x]"
    elif status == "in_progress":
        marker = "[>]"
    elif status == "failed":
        marker = "[!]"
    else:
        marker = "[ ]"

    line = f"    {marker} {stage} ({agent})"
    if artifact:
        line += f" -> {artifact}"
    print(line)
PYEOF
}

# ---------------------------------------------------------------------------
# Command: list
# ---------------------------------------------------------------------------
cmd_list() {
  local filter_brand="" filter_status=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)  filter_brand="$2";  shift 2 ;;
      --status) filter_status="$2"; shift 2 ;;
      *) die "list: unknown option: $1" ;;
    esac
  done

  # Find all handoff manifests
  local manifests
  manifests=$(find "$BRANDS_DIR" -name "handoff-ho-*.json" -type f 2>/dev/null || true)

  if [ -z "$manifests" ]; then
    echo "No handoff manifests found."
    return 0
  fi

  # Write manifest paths to temp file for python3 to read
  local manifests_tmp="/tmp/handoff-manifests-$$.txt"
  echo "$manifests" > "$manifests_tmp"

  # Use python3 to parse and filter
  python3 -c "
import json, sys

filter_brand = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else ''
filter_status = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ''
manifests_file = sys.argv[3]

with open(manifests_file) as f:
    manifest_paths = [line.strip() for line in f if line.strip()]

results = []
for mp in manifest_paths:
    try:
        with open(mp) as f:
            m = json.load(f)
        if filter_brand and m.get('brand') != filter_brand:
            continue
        if filter_status and m.get('status') != filter_status:
            continue
        results.append(m)
    except:
        continue

if not results:
    print('No matching handoffs found.')
    sys.exit(0)

# Sort by created_at descending
results.sort(key=lambda x: x.get('created_at', ''), reverse=True)

print(f\"{'ID':<22} {'Brand':<16} {'Campaign':<16} {'Stage':<18} {'Status':<10} {'Created'}\")
print('-' * 110)
for m in results:
    hid = m.get('handoff_id', '?')
    brand = m.get('brand', '?')
    campaign = m.get('campaign', '?')
    stage = m.get('current_stage', '?')
    status = m.get('status', '?')
    created = m.get('created_at', '?')[:19]
    print(f'{hid:<22} {brand:<16} {campaign:<16} {stage:<18} {status:<10} {created}')

print(f'\nTotal: {len(results)} handoff(s)')
" "$filter_brand" "$filter_status" "$manifests_tmp"

  rm -f "$manifests_tmp"
}

# ---------------------------------------------------------------------------
# Command: advance — Move a handoff to the next stage (called by agents)
# ---------------------------------------------------------------------------
cmd_advance() {
  local handoff_id="" artifact_path=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --handoff-id)    handoff_id="$2";    shift 2 ;;
      --artifact-path) artifact_path="$2"; shift 2 ;;
      *) die "advance: unknown option: $1" ;;
    esac
  done

  [ -z "$handoff_id" ] && die "advance: --handoff-id is required"

  local manifest_path=""
  manifest_path=$(find "$BRANDS_DIR" -name "handoff-${handoff_id}.json" -type f 2>/dev/null | head -1)

  if [ -z "$manifest_path" ] || [ ! -f "$manifest_path" ]; then
    die "Handoff manifest not found for ID: $handoff_id"
  fi

  # Advance to next stage using python3
  local result
  result=$(python3 - "$manifest_path" "$artifact_path" << 'PYEOF'
import json, sys, datetime

manifest_path = sys.argv[1]
artifact_path = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ""

with open(manifest_path) as f:
    m = json.load(f)

stage_order = ["BRIEF", "ART_DIRECTION", "GENERATION", "POST_PRODUCTION", "REVIEW", "PLACEMENT"]
current = m["current_stage"]
now_iso = datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")

# Mark current stage as completed
if current in m["stages"]:
    m["stages"][current]["status"] = "completed"
    m["stages"][current]["completed_at"] = now_iso
    if artifact_path:
        m["stages"][current]["artifact"] = artifact_path

# Find next stage
current_idx = stage_order.index(current) if current in stage_order else -1
if current_idx >= 0 and current_idx < len(stage_order) - 1:
    next_stage = stage_order[current_idx + 1]
    m["current_stage"] = next_stage
    m["stages"][next_stage]["status"] = "in_progress"
    m["stages"][next_stage]["started_at"] = now_iso
    m["updated_at"] = now_iso

    with open(manifest_path, 'w') as f:
        json.dump(m, f, indent=2)

    next_agent = m["stages"][next_stage].get("agent", "unknown")
    print(f"ADVANCED|{current}|{next_stage}|{next_agent}|{m['brand']}|{m['campaign']}|{m['funnel_stage']}|{m['output_type']}")
else:
    # Pipeline complete
    m["status"] = "completed"
    m["current_stage"] = "DONE"
    m["updated_at"] = now_iso

    with open(manifest_path, 'w') as f:
        json.dump(m, f, indent=2)

    print(f"COMPLETED|{current}|DONE|none|{m['brand']}|{m['campaign']}|{m['funnel_stage']}|{m['output_type']}")
PYEOF
  )

  if [ -z "$result" ]; then
    die "Failed to advance handoff $handoff_id"
  fi

  # Parse result
  local status_type prev_stage nxt_stage nxt_agent h_brand h_campaign h_funnel h_otype
  status_type=$(echo "$result" | cut -d'|' -f1)
  prev_stage=$(echo "$result" | cut -d'|' -f2)
  nxt_stage=$(echo "$result" | cut -d'|' -f3)
  nxt_agent=$(echo "$result" | cut -d'|' -f4)
  h_brand=$(echo "$result" | cut -d'|' -f5)
  h_campaign=$(echo "$result" | cut -d'|' -f6)
  h_funnel=$(echo "$result" | cut -d'|' -f7)
  h_otype=$(echo "$result" | cut -d'|' -f8)

  # Post to creative.jsonl
  post_handoff_to_room "handoff-dispatch" "$prev_stage" "$nxt_stage" "$nxt_agent" "$h_brand" "$h_campaign" "$h_funnel" "$h_otype" "${artifact_path:-}" "$handoff_id"

  if [ "$status_type" = "COMPLETED" ]; then
    echo "Handoff $handoff_id COMPLETED. All stages done."
    log_msg "INFO" "Handoff $handoff_id completed"
  else
    echo "Handoff $handoff_id advanced: $prev_stage -> $nxt_stage (agent: $nxt_agent)"
    log_msg "INFO" "Handoff $handoff_id advanced: $prev_stage -> $nxt_stage"

    # Dispatch to next agent if applicable
    if [ -f "$DISPATCH_SH" ] && [ "$nxt_agent" != "unknown" ]; then
      # For multi-agent stages (REVIEW), dispatch to the first agent
      local primary_agent
      primary_agent=$(echo "$nxt_agent" | cut -d',' -f1)
      local dispatch_msg="[HANDOFF $handoff_id] Stage $nxt_stage ready. Brand: $h_brand, Campaign: $h_campaign, Funnel: $h_funnel, Output: $h_otype."
      if [ -n "$artifact_path" ]; then
        dispatch_msg="$dispatch_msg Artifact from previous stage: $artifact_path."
      fi

      bash "$DISPATCH_SH" "handoff-dispatch" "$primary_agent" "handoff" "$dispatch_msg" "creative" 2>/dev/null || \
        log_msg "WARN" "Dispatch to $primary_agent failed (non-fatal)"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Command: revise — Send a handoff back to an earlier stage
# ---------------------------------------------------------------------------
cmd_revise() {
  local handoff_id="" target_stage="" feedback=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --handoff-id)   handoff_id="$2";   shift 2 ;;
      --target-stage) target_stage="$2";  shift 2 ;;
      --feedback)     feedback="$2";      shift 2 ;;
      *) die "revise: unknown option: $1" ;;
    esac
  done

  [ -z "$handoff_id" ]   && die "revise: --handoff-id is required"
  [ -z "$target_stage" ]  && die "revise: --target-stage is required (ART_DIRECTION or GENERATION)"
  [ -z "$feedback" ]      && die "revise: --feedback is required"

  local manifest_path=""
  manifest_path=$(find "$BRANDS_DIR" -name "handoff-${handoff_id}.json" -type f 2>/dev/null | head -1)

  if [ -z "$manifest_path" ] || [ ! -f "$manifest_path" ]; then
    die "Handoff manifest not found for ID: $handoff_id"
  fi

  # Check revision count and update manifest
  local result
  result=$(echo "$feedback" | python3 - "$manifest_path" "$target_stage" << 'PYEOF'
import json, sys, datetime

manifest_path = sys.argv[1]
target_stage = sys.argv[2]
feedback = sys.stdin.read().strip()

with open(manifest_path) as f:
    m = json.load(f)

now_iso = datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
rev_count = m.get("revision_count", 0)
max_rev = m.get("max_revisions", 2)

if rev_count >= max_rev:
    print(f"ESCALATE|{rev_count}|{max_rev}")
    sys.exit(0)

# Reset target stage and all subsequent stages
stage_order = ["BRIEF", "ART_DIRECTION", "GENERATION", "POST_PRODUCTION", "REVIEW", "PLACEMENT"]
target_idx = stage_order.index(target_stage) if target_stage in stage_order else -1
if target_idx < 0:
    print(f"ERROR|invalid stage: {target_stage}")
    sys.exit(1)

for i in range(target_idx, len(stage_order)):
    s = stage_order[i]
    m["stages"][s]["status"] = "pending"
    m["stages"][s]["artifact"] = None
    m["stages"][s]["started_at"] = None
    m["stages"][s]["completed_at"] = None

# Set target stage to in_progress
m["stages"][target_stage]["status"] = "in_progress"
m["stages"][target_stage]["started_at"] = now_iso
m["current_stage"] = target_stage
m["revision_count"] = rev_count + 1
m["updated_at"] = now_iso

with open(manifest_path, 'w') as f:
    json.dump(m, f, indent=2)

agent = m["stages"][target_stage].get("agent", "unknown")
print(f"REVISED|{target_stage}|{agent}|{rev_count + 1}|{max_rev}|{m['brand']}|{m['campaign']}")
PYEOF
  )

  local action_type
  action_type=$(echo "$result" | cut -d'|' -f1)

  if [ "$action_type" = "ESCALATE" ]; then
    local rev_count
    rev_count=$(echo "$result" | cut -d'|' -f2)
    local max_rev
    max_rev=$(echo "$result" | cut -d'|' -f3)

    echo "ESCALATION: Handoff $handoff_id has exceeded max revisions ($rev_count/$max_rev)."
    echo "Posting to approvals.jsonl for human decision."

    # Post to approvals room
    if [ -f "$ROOM_WRITE_SH" ]; then
      bash "$ROOM_WRITE_SH" "approvals" "handoff-dispatch" "escalation" \
        "Handoff $handoff_id needs human review. $rev_count revisions exhausted. Feedback: $feedback" 2>/dev/null || true
    fi

    log_msg "WARN" "Handoff $handoff_id escalated: $rev_count revisions exhausted"

  elif [ "$action_type" = "REVISED" ]; then
    local rev_stage rev_agent rev_count rev_max rev_brand rev_campaign
    rev_stage=$(echo "$result" | cut -d'|' -f2)
    rev_agent=$(echo "$result" | cut -d'|' -f3)
    rev_count=$(echo "$result" | cut -d'|' -f4)
    rev_max=$(echo "$result" | cut -d'|' -f5)
    rev_brand=$(echo "$result" | cut -d'|' -f6)
    rev_campaign=$(echo "$result" | cut -d'|' -f7)

    echo "Handoff $handoff_id revised: sent back to $rev_stage ($rev_agent). Revision $rev_count/$rev_max."

    # Dispatch to target agent with feedback
    if [ -f "$DISPATCH_SH" ]; then
      local primary_agent
      primary_agent=$(echo "$rev_agent" | cut -d',' -f1)
      local dispatch_msg="[HANDOFF $handoff_id REVISION $rev_count/$rev_max] Stage $rev_stage needs revision. Feedback: $feedback"
      bash "$DISPATCH_SH" "handoff-dispatch" "$primary_agent" "handoff" "$dispatch_msg" "creative" 2>/dev/null || \
        log_msg "WARN" "Dispatch to $primary_agent for revision failed (non-fatal)"
    fi

    log_msg "INFO" "Handoff $handoff_id revised: $rev_stage ($rev_count/$rev_max)"

  else
    echo "Error: $result"
    log_msg "ERROR" "Revise failed for $handoff_id: $result"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
COMMAND="${1:-help}"
shift 2>/dev/null || true

case "$COMMAND" in
  start)   cmd_start "$@" ;;
  status)  cmd_status "$@" ;;
  list)    cmd_list "$@" ;;
  advance) cmd_advance "$@" ;;
  revise)  cmd_revise "$@" ;;
  help|--help|-h)
    echo "Usage: bash handoff-dispatch.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start    Start a new creative handoff pipeline"
    echo "  status   Check handoff status by ID"
    echo "  list     List all handoffs (filter by --brand, --status)"
    echo "  advance  Move handoff to the next pipeline stage"
    echo "  revise   Send handoff back to an earlier stage for revision"
    echo ""
    echo "Examples:"
    echo "  bash handoff-dispatch.sh start --brand pinxin-vegan --campaign cny-2026 --funnel-stage TOFU --output-type hero --prompt 'CNY celebration hero image'"
    echo "  bash handoff-dispatch.sh status --handoff-id ho-1709000000"
    echo "  bash handoff-dispatch.sh list --brand pinxin-vegan --status active"
    echo "  bash handoff-dispatch.sh advance --handoff-id ho-1709000000 --artifact-path path/to/artifact.json"
    echo "  bash handoff-dispatch.sh revise --handoff-id ho-1709000000 --target-stage ART_DIRECTION --feedback 'Colors too muted'"
    ;;
  *) die "Unknown command: $COMMAND. Use 'help' to see available commands." ;;
esac
