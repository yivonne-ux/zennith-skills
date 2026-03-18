#!/usr/bin/env bash
# approval-queue.sh — Human-in-the-loop approval queue for GAIA CORP-OS
# Sits between agent proposals and execution. Handles Tier 3 actions.
# Bash 3.2 compatible (macOS). No jq, no declare -A, no timeout. Uses python3 for JSON.
# 8GB RAM aware.
#
# Subcommands:
#   submit   — Submit an approval request (agents call this)
#   list     — List approvals by status
#   approve  — Approve a pending request
#   reject   — Reject a pending request
#   process  — Execute all approved items
#   count    — Count approvals by status
#   show     — Show details of a single approval
#
# Usage:
#   bash approval-queue.sh submit --type "new-output-type" --agent "iris" \
#     --summary "..." --payload '{...}' --tier 3
#   bash approval-queue.sh list [--status pending|approved|rejected|executed]
#   bash approval-queue.sh approve --id "appr-xxx" [--notes "..."]
#   bash approval-queue.sh reject --id "appr-xxx" --reason "..."
#   bash approval-queue.sh process
#   bash approval-queue.sh count [--status pending]
#   bash approval-queue.sh show --id "appr-xxx"

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APPROVALS_FILE="$HOME/.openclaw/workspace/rooms/approvals.jsonl"
CREATIVE_ROOM="$HOME/.openclaw/workspace/rooms/creative.jsonl"
LOG_FILE="$HOME/.openclaw/workspace/logs/intake.log"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify-human.sh"
REGISTER_OUTPUT_TYPE="$HOME/.openclaw/skills/workflow-automation/scripts/register-output-type.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
  printf '[%s] [approval-queue] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE" 2>/dev/null
}

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

# Ensure approvals file exists
ensure_file() {
  if [ ! -f "$APPROVALS_FILE" ]; then
    mkdir -p "$(dirname "$APPROVALS_FILE")"
    touch "$APPROVALS_FILE"
  fi
}

# Generate approval ID
gen_id() {
  local ts
  ts=$(epoch_ms)
  echo "appr-${ts}"
}

# Post to a room file
post_to_room() {
  local room_file="$1"
  local json_line="$2"
  printf '%s\n' "$json_line" >> "$room_file" 2>/dev/null || {
    log "WARNING: Could not write to room $room_file"
  }
}

# ---------------------------------------------------------------------------
# Subcommand: submit
# ---------------------------------------------------------------------------

cmd_submit() {
  local appr_type=""
  local agent=""
  local summary=""
  local payload="{}"
  local tier="3"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type)    shift; appr_type="${1:-}" ;;
      --agent)   shift; agent="${1:-}" ;;
      --summary) shift; summary="${1:-}" ;;
      --payload) shift; payload="${1:-}" ; if [ -z "$payload" ]; then payload="{}"; fi ;;
      --tier)    shift; tier="${1:-3}" ;;
      *) log "WARNING: Unknown submit arg: $1" ;;
    esac
    shift
  done

  if [ -z "$appr_type" ]; then
    echo "ERROR: --type is required" >&2
    exit 1
  fi
  if [ -z "$summary" ]; then
    echo "ERROR: --summary is required" >&2
    exit 1
  fi
  if [ -z "$agent" ]; then
    agent="unknown"
  fi

  ensure_file

  local appr_id
  appr_id=$(gen_id)

  # Write payload to temp file to avoid shell escaping issues with JSON
  local tmp_payload="/tmp/gaia-appr-payload-$$.json"
  printf '%s' "$payload" > "$tmp_payload" 2>/dev/null

  # Build the approval record
  RECORD=$(python3 -c "
import json, sys, time

appr_id = '$appr_id'
ts = int(time.time() * 1000)
appr_type = sys.argv[1]
tier = int(sys.argv[2])
agent = sys.argv[3]
summary = sys.argv[4]
payload_file = sys.argv[5]

# Parse payload safely from file
try:
    with open(payload_file, 'r') as f:
        payload = json.loads(f.read())
except Exception:
    payload = {}

record = {
    'id': appr_id,
    'ts': ts,
    'type': appr_type,
    'tier': tier,
    'status': 'pending',
    'agent': agent,
    'summary': summary,
    'payload': payload,
    'human_notes': '',
    'approved_at': None,
    'executed_at': None,
    'result': None
}

print(json.dumps(record, ensure_ascii=False))
" "$appr_type" "$tier" "$agent" "$summary" "$tmp_payload" 2>/dev/null)

  rm -f "$tmp_payload" 2>/dev/null

  if [ -z "$RECORD" ]; then
    log "ERROR: Failed to build approval record"
    echo "ERROR: Failed to build approval record" >&2
    exit 1
  fi

  # Write to approvals.jsonl
  post_to_room "$APPROVALS_FILE" "$RECORD"
  log "Submitted approval request: $appr_id (type=$appr_type, agent=$agent, tier=$tier)"

  # Post notification to creative room
  NOTIF_MSG=$(python3 -c "
import json, time
msg = {
    'ts': int(time.time() * 1000),
    'agent': 'approval-queue',
    'room': 'creative',
    'type': 'approval-submitted',
    'msg': '[APPROVAL NEEDED] $summary (ID: $appr_id, Type: $appr_type, Agent: $agent)'
}
print(json.dumps(msg, ensure_ascii=False))
" 2>/dev/null)
  if [ -n "$NOTIF_MSG" ]; then
    post_to_room "$CREATIVE_ROOM" "$NOTIF_MSG"
  fi

  # Send human notification via notify-human.sh
  if [ -x "$NOTIFY_SCRIPT" ]; then
    echo "$RECORD" | bash "$NOTIFY_SCRIPT" >>"$LOG_FILE" 2>>"$LOG_FILE" || {
      log "WARNING: notify-human.sh failed for $appr_id"
    }
  else
    log "WARNING: notify-human.sh not found or not executable at $NOTIFY_SCRIPT"
  fi

  # Output the ID
  echo "$appr_id"
}

# ---------------------------------------------------------------------------
# Subcommand: list
# ---------------------------------------------------------------------------

cmd_list() {
  local filter_status=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --status) shift; filter_status="${1:-}" ;;
      *) ;;
    esac
    shift
  done

  ensure_file

  python3 -c "
import json, sys

filter_status = '$filter_status'
approvals_file = '$APPROVALS_FILE'

records = []
try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                if filter_status and record.get('status') != filter_status:
                    continue
                records.append(record)
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    pass

if not records:
    status_msg = ' (status=' + filter_status + ')' if filter_status else ''
    print('No approvals found' + status_msg)
    sys.exit(0)

# Sort by timestamp (newest first)
records.sort(key=lambda r: r.get('ts', 0), reverse=True)

# Print formatted list
print('=' * 72)
print('APPROVAL QUEUE — {} record(s){}'.format(
    len(records),
    ' (status=' + filter_status + ')' if filter_status else ''
))
print('=' * 72)

for r in records:
    import datetime
    ts = r.get('ts', 0)
    if ts > 0:
        dt = datetime.datetime.fromtimestamp(ts / 1000)
        time_str = dt.strftime('%Y-%m-%d %H:%M')
    else:
        time_str = 'unknown'

    status = r.get('status', 'unknown')
    status_marker = {
        'pending': '[ ]',
        'approved': '[+]',
        'rejected': '[-]',
        'executed': '[x]'
    }.get(status, '[?]')

    print('')
    print('{} {} — {} ({})'.format(status_marker, r.get('id', '?'), r.get('type', '?'), status))
    print('    Agent: {}  |  Submitted: {}'.format(r.get('agent', '?'), time_str))
    print('    Summary: {}'.format(r.get('summary', 'N/A')))

    notes = r.get('human_notes', '')
    if notes:
        print('    Notes: {}'.format(notes))

    reason = r.get('rejection_reason', '')
    if reason:
        print('    Reason: {}'.format(reason))

    result = r.get('result')
    if result:
        print('    Result: {}'.format(str(result)[:100]))

print('')
print('=' * 72)
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Subcommand: approve
# ---------------------------------------------------------------------------

cmd_approve() {
  local appr_id=""
  local notes=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)    shift; appr_id="${1:-}" ;;
      --notes) shift; notes="${1:-}" ;;
      *) ;;
    esac
    shift
  done

  if [ -z "$appr_id" ]; then
    echo "ERROR: --id is required" >&2
    exit 1
  fi

  ensure_file

  RESULT=$(python3 -c "
import json, sys, time

appr_id = '$appr_id'
notes = '''$notes'''
approvals_file = '$APPROVALS_FILE'

# Read all records
records = []
found = False
try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                records.append(record)
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    print('ERROR:Approvals file not found')
    sys.exit(0)

# Find and update the target record
updated_records = []
for record in records:
    if record.get('id') == appr_id:
        found = True
        if record.get('status') != 'pending':
            print('ERROR:Cannot approve — status is ' + record.get('status', 'unknown'))
            sys.exit(0)
        record['status'] = 'approved'
        record['approved_at'] = int(time.time() * 1000)
        if notes:
            record['human_notes'] = notes
    updated_records.append(record)

if not found:
    print('ERROR:Approval ID not found: ' + appr_id)
    sys.exit(0)

# Rewrite the file
with open(approvals_file, 'w') as f:
    for record in updated_records:
        f.write(json.dumps(record, ensure_ascii=False) + '\n')

print('OK:' + appr_id)
" 2>/dev/null)

  case "$RESULT" in
    ERROR:*)
      local err_msg="${RESULT#ERROR:}"
      log "ERROR: approve failed: $err_msg"
      echo "ERROR: $err_msg" >&2
      exit 1
      ;;
    OK:*)
      log "Approved: $appr_id (notes: $notes)"
      echo "Approved: $appr_id"

      # Post to creative room
      NOTIF_MSG=$(python3 -c "
import json, time
msg = {
    'ts': int(time.time() * 1000),
    'agent': 'approval-queue',
    'room': 'creative',
    'type': 'approval-approved',
    'msg': '[APPROVED] $appr_id has been approved.$(if [ -n "$notes" ]; then echo " Notes: $notes"; fi)'
}
print(json.dumps(msg, ensure_ascii=False))
" 2>/dev/null)
      if [ -n "$NOTIF_MSG" ]; then
        post_to_room "$CREATIVE_ROOM" "$NOTIF_MSG"
      fi
      ;;
    *)
      log "ERROR: Unexpected result from approve: $RESULT"
      echo "ERROR: Unexpected result" >&2
      exit 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Subcommand: reject
# ---------------------------------------------------------------------------

cmd_reject() {
  local appr_id=""
  local reason=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)     shift; appr_id="${1:-}" ;;
      --reason) shift; reason="${1:-}" ;;
      *) ;;
    esac
    shift
  done

  if [ -z "$appr_id" ]; then
    echo "ERROR: --id is required" >&2
    exit 1
  fi
  if [ -z "$reason" ]; then
    reason="No reason provided"
  fi

  ensure_file

  RESULT=$(python3 -c "
import json, sys, time

appr_id = '$appr_id'
reason = '''$reason'''
approvals_file = '$APPROVALS_FILE'

# Read all records
records = []
found = False
try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                records.append(record)
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    print('ERROR:Approvals file not found')
    sys.exit(0)

# Find and update
updated_records = []
for record in records:
    if record.get('id') == appr_id:
        found = True
        if record.get('status') != 'pending':
            print('ERROR:Cannot reject — status is ' + record.get('status', 'unknown'))
            sys.exit(0)
        record['status'] = 'rejected'
        record['rejected_at'] = int(time.time() * 1000)
        record['rejection_reason'] = reason
    updated_records.append(record)

if not found:
    print('ERROR:Approval ID not found: ' + appr_id)
    sys.exit(0)

# Rewrite the file
with open(approvals_file, 'w') as f:
    for record in updated_records:
        f.write(json.dumps(record, ensure_ascii=False) + '\n')

print('OK:' + appr_id)
" 2>/dev/null)

  case "$RESULT" in
    ERROR:*)
      local err_msg="${RESULT#ERROR:}"
      log "ERROR: reject failed: $err_msg"
      echo "ERROR: $err_msg" >&2
      exit 1
      ;;
    OK:*)
      log "Rejected: $appr_id (reason: $reason)"
      echo "Rejected: $appr_id"

      # Post to creative room
      NOTIF_MSG=$(python3 -c "
import json, time
msg = {
    'ts': int(time.time() * 1000),
    'agent': 'approval-queue',
    'room': 'creative',
    'type': 'approval-rejected',
    'msg': '[REJECTED] $appr_id — Reason: $reason'
}
print(json.dumps(msg, ensure_ascii=False))
" 2>/dev/null)
      if [ -n "$NOTIF_MSG" ]; then
        post_to_room "$CREATIVE_ROOM" "$NOTIF_MSG"
      fi
      ;;
    *)
      log "ERROR: Unexpected result from reject: $RESULT"
      echo "ERROR: Unexpected result" >&2
      exit 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Subcommand: process — Execute approved items
# ---------------------------------------------------------------------------

cmd_process() {
  ensure_file

  # Get list of approved (not yet executed) items
  APPROVED_IDS=$(python3 -c "
import json

approvals_file = '$APPROVALS_FILE'
ids = []
try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                if record.get('status') == 'approved':
                    ids.append(record.get('id', ''))
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    pass

print('\n'.join(ids))
" 2>/dev/null)

  if [ -z "$APPROVED_IDS" ]; then
    log "Process: No approved items to execute"
    echo "No approved items to process."
    return 0
  fi

  local processed_count=0
  local failed_count=0

  # Process each approved item
  while IFS= read -r appr_id; do
    if [ -z "$appr_id" ]; then
      continue
    fi

    log "Processing approved item: $appr_id"

    # Extract the record details
    RECORD_DATA=$(python3 -c "
import json

approvals_file = '$APPROVALS_FILE'
target_id = '$appr_id'

try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                if record.get('id') == target_id:
                    print(json.dumps(record, ensure_ascii=False))
                    break
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    pass
" 2>/dev/null)

    if [ -z "$RECORD_DATA" ]; then
      log "ERROR: Could not read record for $appr_id"
      failed_count=$((failed_count + 1))
      continue
    fi

    # Get type and payload
    APPR_TYPE=$(python3 -c "import json,sys; r=json.loads(sys.stdin.read()); print(r.get('type',''))" <<< "$RECORD_DATA" 2>/dev/null)
    PAYLOAD=$(python3 -c "import json,sys; r=json.loads(sys.stdin.read()); print(json.dumps(r.get('payload',{})))" <<< "$RECORD_DATA" 2>/dev/null)
    HUMAN_NOTES=$(python3 -c "import json,sys; r=json.loads(sys.stdin.read()); print(r.get('human_notes',''))" <<< "$RECORD_DATA" 2>/dev/null)

    EXEC_RESULT=""
    EXEC_STATUS="success"

    case "$APPR_TYPE" in
      new-output-type|register-output-type)
        log "Executing: register output type from $appr_id"
        if [ -x "$REGISTER_OUTPUT_TYPE" ]; then
          EXEC_RESULT=$(echo "$PAYLOAD" | bash "$REGISTER_OUTPUT_TYPE" --from-approval 2>>"$LOG_FILE") || {
            EXEC_STATUS="error"
            EXEC_RESULT="register-output-type.sh failed"
            log "ERROR: register-output-type.sh failed for $appr_id"
          }
          if [ -n "$EXEC_RESULT" ] && [ "$EXEC_STATUS" = "success" ]; then
            log "Registered output type: $EXEC_RESULT from approval $appr_id"
          fi
        else
          EXEC_STATUS="error"
          EXEC_RESULT="register-output-type.sh not found"
          log "ERROR: register-output-type.sh not found at $REGISTER_OUTPUT_TYPE"
        fi
        ;;

      video-gen|kling-gen|sora-gen|wan-gen)
        log "Executing: video generation from $appr_id"
        # Determine which video script to use
        VIDEO_TOOL=$(python3 -c "import json,sys; p=json.loads(sys.stdin.read()); print(p.get('tool','kling'))" <<< "$PAYLOAD" 2>/dev/null)
        VIDEO_TOOL="${VIDEO_TOOL:-kling}"

        case "$VIDEO_TOOL" in
          kling)
            VIDEO_SCRIPT="$HOME/.openclaw/skills/video-production/scripts/kling-video.sh"
            ;;
          wan|wan2.6)
            VIDEO_SCRIPT="$HOME/.openclaw/skills/video-production/scripts/wan-video.sh"
            ;;
          *)
            VIDEO_SCRIPT=""
            ;;
        esac

        if [ -n "$VIDEO_SCRIPT" ] && [ -x "$VIDEO_SCRIPT" ]; then
          EXEC_RESULT=$(echo "$PAYLOAD" | bash "$VIDEO_SCRIPT" 2>>"$LOG_FILE") || {
            EXEC_STATUS="error"
            EXEC_RESULT="Video generation failed"
            log "ERROR: Video generation failed for $appr_id"
          }
        else
          EXEC_STATUS="error"
          EXEC_RESULT="Video script not found: $VIDEO_SCRIPT"
          log "ERROR: Video script not found: $VIDEO_SCRIPT"
        fi
        ;;

      publish|export-publish)
        log "Executing: publish from $appr_id"
        PUBLISH_SCRIPT="$HOME/.openclaw/skills/content-publishing/scripts/publish.sh"
        if [ -x "$PUBLISH_SCRIPT" ]; then
          EXEC_RESULT=$(echo "$PAYLOAD" | bash "$PUBLISH_SCRIPT" 2>>"$LOG_FILE") || {
            EXEC_STATUS="error"
            EXEC_RESULT="Publish failed"
            log "ERROR: Publish failed for $appr_id"
          }
        else
          EXEC_STATUS="error"
          EXEC_RESULT="Publish script not found: $PUBLISH_SCRIPT"
          log "ERROR: Publish script not found"
        fi
        ;;

      brand-dna-change|brand-voice-update)
        log "Executing: brand DNA change from $appr_id"
        BRAND_ID=$(python3 -c "import json,sys; p=json.loads(sys.stdin.read()); print(p.get('brand',''))" <<< "$PAYLOAD" 2>/dev/null)
        if [ -n "$BRAND_ID" ]; then
          DNA_FILE="$HOME/.openclaw/brands/$BRAND_ID/DNA.json"
          if [ -f "$DNA_FILE" ]; then
            EXEC_RESULT=$(python3 -c "
import json, sys, datetime, shutil

payload = json.loads(sys.stdin.read())
brand = payload.get('brand', '')
changes = payload.get('changes', {})
dna_file = '$DNA_FILE'

if not changes:
    print('ERROR: No changes in payload')
    sys.exit(0)

# Backup first
backup_file = dna_file + '.bak.' + datetime.datetime.now().strftime('%Y%m%d%H%M%S')
shutil.copy2(dna_file, backup_file)

try:
    with open(dna_file, 'r') as f:
        dna = json.load(f)

    # Apply changes (shallow merge)
    for key, val in changes.items():
        dna[key] = val

    dna['last_modified'] = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    dna['last_modified_by'] = 'approval-queue'

    with open(dna_file, 'w') as f:
        json.dump(dna, f, indent=2, ensure_ascii=False)

    print('Updated DNA for ' + brand + ' (backup: ' + backup_file + ')')
except Exception as e:
    print('ERROR: ' + str(e))
" <<< "$PAYLOAD" 2>>"$LOG_FILE") || {
              EXEC_STATUS="error"
              EXEC_RESULT="Brand DNA update failed"
            }
          else
            EXEC_STATUS="error"
            EXEC_RESULT="DNA file not found: $DNA_FILE"
            log "ERROR: DNA file not found: $DNA_FILE"
          fi
        else
          EXEC_STATUS="error"
          EXEC_RESULT="No brand ID in payload"
          log "ERROR: No brand ID in payload for brand-dna-change"
        fi
        ;;

      asset-delete)
        log "Executing: asset archive from $appr_id"
        ASSET_PATH=$(python3 -c "import json,sys; p=json.loads(sys.stdin.read()); print(p.get('path',''))" <<< "$PAYLOAD" 2>/dev/null)
        if [ -n "$ASSET_PATH" ] && [ -e "$ASSET_PATH" ]; then
          ARCHIVE_DIR="$HOME/.openclaw/workspace/rooms/_archive"
          mkdir -p "$ARCHIVE_DIR"
          ARCHIVE_NAME="$(basename "$ASSET_PATH").archived.$(date +%s)"
          mv "$ASSET_PATH" "$ARCHIVE_DIR/$ARCHIVE_NAME" 2>>"$LOG_FILE" && {
            EXEC_RESULT="Archived: $ASSET_PATH -> $ARCHIVE_DIR/$ARCHIVE_NAME"
            log "Archived asset: $ASSET_PATH"
          } || {
            EXEC_STATUS="error"
            EXEC_RESULT="Failed to archive: $ASSET_PATH"
            log "ERROR: Failed to archive $ASSET_PATH"
          }
        else
          EXEC_STATUS="error"
          EXEC_RESULT="Asset not found: $ASSET_PATH"
          log "ERROR: Asset not found: $ASSET_PATH"
        fi
        ;;

      campaign-create)
        log "Executing: campaign create from $appr_id"
        EXEC_RESULT="Campaign creation queued (manual follow-up needed)"
        EXEC_STATUS="success"
        ;;

      *)
        log "WARNING: Unknown approval type: $APPR_TYPE for $appr_id"
        EXEC_STATUS="error"
        EXEC_RESULT="Unknown approval type: $APPR_TYPE"
        ;;
    esac

    # Update the record status to executed
    python3 -c "
import json, sys, time

appr_id = '$appr_id'
exec_status = '$EXEC_STATUS'
exec_result_str = '''$(echo "$EXEC_RESULT" | python3 -c "import sys; print(sys.stdin.read().replace(\"'\", \"\\\\'\").rstrip())" 2>/dev/null)'''
approvals_file = '$APPROVALS_FILE'

records = []
try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    sys.exit(1)

for record in records:
    if record.get('id') == appr_id:
        record['status'] = 'executed'
        record['executed_at'] = int(time.time() * 1000)
        record['result'] = {
            'status': exec_status,
            'output': exec_result_str
        }
        break

with open(approvals_file, 'w') as f:
    for record in records:
        f.write(json.dumps(record, ensure_ascii=False) + '\n')
" 2>/dev/null

    # Post execution result to creative room
    NOTIF_MSG=$(python3 -c "
import json, time
status_emoji = 'EXECUTED' if '$EXEC_STATUS' == 'success' else 'EXEC-FAILED'
msg = {
    'ts': int(time.time() * 1000),
    'agent': 'approval-queue',
    'room': 'creative',
    'type': 'approval-executed',
    'msg': '[' + status_emoji + '] $appr_id ($APPR_TYPE) — $(echo "$EXEC_RESULT" | head -c 200)'
}
print(json.dumps(msg, ensure_ascii=False))
" 2>/dev/null)
    if [ -n "$NOTIF_MSG" ]; then
      post_to_room "$CREATIVE_ROOM" "$NOTIF_MSG"
    fi

    if [ "$EXEC_STATUS" = "success" ]; then
      processed_count=$((processed_count + 1))
      echo "Executed: $appr_id ($APPR_TYPE) — $EXEC_RESULT"
    else
      failed_count=$((failed_count + 1))
      echo "FAILED:  $appr_id ($APPR_TYPE) — $EXEC_RESULT"
    fi

  done <<< "$APPROVED_IDS"

  log "Process complete: $processed_count executed, $failed_count failed"
  echo ""
  echo "Process complete: $processed_count executed, $failed_count failed"
}

# ---------------------------------------------------------------------------
# Subcommand: count
# ---------------------------------------------------------------------------

cmd_count() {
  local filter_status=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --status) shift; filter_status="${1:-}" ;;
      *) ;;
    esac
    shift
  done

  ensure_file

  python3 -c "
import json

filter_status = '$filter_status'
approvals_file = '$APPROVALS_FILE'

counts = {'pending': 0, 'approved': 0, 'rejected': 0, 'executed': 0}
try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                status = record.get('status', 'unknown')
                if status in counts:
                    counts[status] += 1
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    pass

if filter_status:
    print(counts.get(filter_status, 0))
else:
    total = sum(counts.values())
    print('Pending: {}  Approved: {}  Rejected: {}  Executed: {}  Total: {}'.format(
        counts['pending'], counts['approved'], counts['rejected'], counts['executed'], total
    ))
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Subcommand: show
# ---------------------------------------------------------------------------

cmd_show() {
  local appr_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id) shift; appr_id="${1:-}" ;;
      *) ;;
    esac
    shift
  done

  if [ -z "$appr_id" ]; then
    echo "ERROR: --id is required" >&2
    exit 1
  fi

  ensure_file

  python3 -c "
import json, sys

appr_id = '$appr_id'
approvals_file = '$APPROVALS_FILE'

try:
    with open(approvals_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                if record.get('id') == appr_id:
                    print(json.dumps(record, indent=2, ensure_ascii=False))
                    sys.exit(0)
            except json.JSONDecodeError:
                continue
except FileNotFoundError:
    pass

print('ERROR: Approval ID not found: ' + appr_id, file=sys.stderr)
sys.exit(1)
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

SUBCOMMAND="${1:-}"

if [ -z "$SUBCOMMAND" ]; then
  echo "Usage: bash approval-queue.sh <submit|list|approve|reject|process|count|show> [args]" >&2
  echo "" >&2
  echo "Subcommands:" >&2
  echo "  submit   Submit an approval request" >&2
  echo "  list     List approvals [--status pending|approved|rejected|executed]" >&2
  echo "  approve  Approve a pending request --id <id> [--notes '...']" >&2
  echo "  reject   Reject a pending request --id <id> --reason '...'" >&2
  echo "  process  Execute all approved items" >&2
  echo "  count    Count approvals [--status pending]" >&2
  echo "  show     Show details of one approval --id <id>" >&2
  exit 1
fi

shift

case "$SUBCOMMAND" in
  submit)  cmd_submit "$@" ;;
  list)    cmd_list "$@" ;;
  approve) cmd_approve "$@" ;;
  reject)  cmd_reject "$@" ;;
  process) cmd_process ;;
  count)   cmd_count "$@" ;;
  show)    cmd_show "$@" ;;
  *)
    echo "ERROR: Unknown subcommand: $SUBCOMMAND" >&2
    echo "Valid subcommands: submit, list, approve, reject, process, count, show" >&2
    exit 1
    ;;
esac
