#!/usr/bin/env bash
# register-output-type.sh — Agent-driven output type registration
# Reads JSON from stdin, validates, and registers into the GAIA production system.
# Bash 3.2 compatible (macOS). Uses python3 for all JSON manipulation.
#
# Usage: echo '{"id":"my-type","name":"My Type","funnel_stage":"TOFU","aspect_ratios":["9:16"]}' | bash register-output-type.sh
# Flags:
#   --require-approval  (default: true) Route through approval queue instead of executing
#   --from-approval     Skip approval check (used by approval-queue.sh process after human approval)
# Exit codes: 0 = success, 1 = validation error, 2 = duplicate, 3 = write error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APPROVAL_QUEUE="$HOME/.openclaw/skills/creative-intake/scripts/approval-queue.sh"
LOG_FILE="$HOME/.openclaw/workspace/logs/intake.log"

# Parse flags (must come before stdin reading)
REQUIRE_APPROVAL="true"
FROM_APPROVAL="false"

# Collect args — stdin is read separately
for arg in "$@"; do
  case "$arg" in
    --require-approval)   REQUIRE_APPROVAL="true" ;;
    --no-require-approval) REQUIRE_APPROVAL="false" ;;
    --from-approval)      FROM_APPROVAL="true"; REQUIRE_APPROVAL="false" ;;
  esac
done

DATA_DIR="$HOME/.openclaw/workspace/data"
OUTPUT_TYPES_FILE="$DATA_DIR/output-types.json"
WORKFLOW_TEMPLATES_FILE="$DATA_DIR/workflow-templates.json"
PRODUCTION_CHAINS_FILE="$DATA_DIR/production-chains.json"
SKILL_REGISTRY_FILE="$DATA_DIR/skill-registry.json"
CREATIVE_ROOM="$HOME/.openclaw/workspace/rooms/creative.jsonl"

# Read stdin into variable
INPUT_JSON=""
if [ -t 0 ]; then
    echo "ERROR: No JSON input on stdin. Pipe JSON to this script." >&2
    echo "Usage: echo '{...}' | bash register-output-type.sh [--from-approval]" >&2
    exit 1
fi
INPUT_JSON="$(cat)"

if [ -z "$INPUT_JSON" ]; then
    echo "ERROR: Empty input on stdin." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Approval gate: if require-approval is true and not called from approval,
# submit to approval queue instead of executing directly
# ---------------------------------------------------------------------------

if [ "$REQUIRE_APPROVAL" = "true" ] && [ "$FROM_APPROVAL" = "false" ]; then
    # Extract summary info for the approval request
    APPR_SUMMARY=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    name = d.get('name', d.get('id', 'unknown'))
    desc = d.get('description', '')
    source = d.get('source', 'agent')
    summary = 'Register new output type: ' + name
    if desc:
        summary += ' — ' + desc[:100]
    print(summary)
except Exception as e:
    print('Register new output type (details unavailable)')
" <<< "$INPUT_JSON" 2>/dev/null)

    APPR_AGENT=$(python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('requested_by', 'unknown'))
except Exception:
    print('unknown')
" <<< "$INPUT_JSON" 2>/dev/null)

    if [ -x "$APPROVAL_QUEUE" ]; then
        APPR_ID=$(bash "$APPROVAL_QUEUE" submit \
            --type "new-output-type" \
            --agent "$APPR_AGENT" \
            --summary "$APPR_SUMMARY" \
            --payload "$INPUT_JSON" \
            --tier 3 2>>"$LOG_FILE")
        printf '[%s] [register-output-type] Queued for approval: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$APPR_ID" >> "$LOG_FILE" 2>/dev/null
        echo "QUEUED:$APPR_ID"
        exit 0
    else
        printf '[%s] [register-output-type] WARNING: approval-queue.sh not found, executing directly\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE" 2>/dev/null
        # Fall through to direct execution
    fi
fi

# Ensure data directory exists
mkdir -p "$DATA_DIR"

# Ensure output-types.json exists (as array)
if [ ! -f "$OUTPUT_TYPES_FILE" ]; then
    echo "[]" > "$OUTPUT_TYPES_FILE"
fi

# Ensure workflow-templates.json exists
if [ ! -f "$WORKFLOW_TEMPLATES_FILE" ]; then
    cat > "$WORKFLOW_TEMPLATES_FILE" <<'TMPL_INIT'
{
  "version": "1.0.0",
  "last_updated": "",
  "description": "GAIA Content Workflow Templates",
  "templates": []
}
TMPL_INIT
fi

# Ensure production-chains.json exists
if [ ! -f "$PRODUCTION_CHAINS_FILE" ]; then
    cat > "$PRODUCTION_CHAINS_FILE" <<'CHAIN_INIT'
{
  "version": "1.0",
  "updated_at": "",
  "description": "Production chains for each output type.",
  "chains": {}
}
CHAIN_INIT
fi

# Ensure skill-registry.json exists
if [ ! -f "$SKILL_REGISTRY_FILE" ]; then
    cat > "$SKILL_REGISTRY_FILE" <<'REG_INIT'
{
  "version": "1.0",
  "updated_at": "",
  "skills": {}
}
REG_INIT
fi

# --- Step 1: Validate JSON and extract required fields ---
VALIDATION_RESULT="$(python3 -c "
import json, sys

try:
    data = json.loads(sys.stdin.read())
except json.JSONDecodeError as e:
    print('INVALID_JSON:' + str(e))
    sys.exit(0)

required = ['id', 'name', 'funnel_stage', 'aspect_ratios']
missing = [f for f in required if f not in data]
if missing:
    print('MISSING_FIELDS:' + ','.join(missing))
    sys.exit(0)

# Validate types
if not isinstance(data['id'], str) or not data['id'].strip():
    print('INVALID_FIELD:id must be a non-empty string')
    sys.exit(0)

if not isinstance(data['aspect_ratios'], list) or len(data['aspect_ratios']) == 0:
    print('INVALID_FIELD:aspect_ratios must be a non-empty array')
    sys.exit(0)

valid_stages = ['TOFU', 'MOFU', 'BOFU', 'POST-PURCHASE']
stage = data['funnel_stage'].upper()
if stage not in valid_stages:
    print('INVALID_FIELD:funnel_stage must be one of ' + ','.join(valid_stages))
    sys.exit(0)

# Sanitize id: lowercase, hyphens only
sanitized_id = data['id'].lower().strip().replace(' ', '-')
import re
sanitized_id = re.sub(r'[^a-z0-9-]', '', sanitized_id)
if not sanitized_id:
    print('INVALID_FIELD:id produces empty string after sanitization')
    sys.exit(0)

print('OK:' + sanitized_id)
" <<< "$INPUT_JSON")"

case "$VALIDATION_RESULT" in
    INVALID_JSON:*)
        echo "ERROR: Invalid JSON — ${VALIDATION_RESULT#INVALID_JSON:}" >&2
        exit 1
        ;;
    MISSING_FIELDS:*)
        echo "ERROR: Missing required fields — ${VALIDATION_RESULT#MISSING_FIELDS:}" >&2
        exit 1
        ;;
    INVALID_FIELD:*)
        echo "ERROR: ${VALIDATION_RESULT#INVALID_FIELD:}" >&2
        exit 1
        ;;
    OK:*)
        TYPE_ID="${VALIDATION_RESULT#OK:}"
        ;;
    *)
        echo "ERROR: Unexpected validation result." >&2
        exit 1
        ;;
esac

# --- Step 2: Check for duplicates ---
DUPLICATE_CHECK="$(python3 -c "
import json, sys

type_id = '$TYPE_ID'
try:
    with open('$OUTPUT_TYPES_FILE', 'r') as f:
        types = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    types = []

# Handle both array and object-with-array formats
if isinstance(types, dict) and 'types' in types:
    types = types['types']
elif not isinstance(types, list):
    types = []

for t in types:
    if isinstance(t, dict) and t.get('id') == type_id:
        print('DUPLICATE')
        sys.exit(0)

print('OK')
")"

if [ "$DUPLICATE_CHECK" = "DUPLICATE" ]; then
    echo "ERROR: Output type '$TYPE_ID' already exists. Use a different id." >&2
    exit 2
fi

# --- Step 3: Append to output-types.json ---
python3 -c "
import json, sys, datetime

input_data = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')

# Sanitize the id
type_id = '$TYPE_ID'
input_data['id'] = type_id

# Ensure funnel_stage is uppercase
input_data['funnel_stage'] = input_data.get('funnel_stage', '').upper()

# Add registration metadata
input_data['registered_at'] = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

# Read existing
try:
    with open('$OUTPUT_TYPES_FILE', 'r') as f:
        types = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    types = []

if not isinstance(types, list):
    types = []

types.append(input_data)

with open('$OUTPUT_TYPES_FILE', 'w') as f:
    json.dump(types, f, indent=2, ensure_ascii=False)
" || { echo "ERROR: Failed to write output-types.json" >&2; exit 3; }

# --- Step 4: Generate workflow template and append to workflow-templates.json ---
python3 -c "
import json, sys, datetime

input_data = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')
type_id = '$TYPE_ID'

# Build a workflow template from the output type
template = {
    'id': type_id + '-default',
    'name': input_data.get('name', type_id) + ' (Auto-registered)',
    'description': input_data.get('description', 'Auto-registered output type'),
    'output_type': type_id,
    'use_case': input_data.get('description', ''),
    'auto_settings': {
        'aspect_ratio': input_data.get('aspect_ratios', ['9:16'])[0],
        'aspect_ratios_available': input_data.get('aspect_ratios', ['9:16']),
        'platform_targets': [],
        'qa_priority': []
    },
    'registered_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'registered_by': input_data.get('requested_by', 'unknown')
}

# Add duration if present
dur = input_data.get('duration_range')
if dur:
    template['auto_settings']['duration'] = dur

# Add style params if present
sp = input_data.get('style_params')
if sp:
    for k, v in sp.items():
        template['auto_settings'][k] = v

# Add agent assignment
aa = input_data.get('agent_assignment')
if aa:
    template['agent_assignment'] = aa

# Add generation tools
gt = input_data.get('generation_tools')
if gt:
    template['auto_settings']['generation_tools'] = gt

# Read existing templates file
try:
    with open('$WORKFLOW_TEMPLATES_FILE', 'r') as f:
        wf = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    wf = {'version': '1.0.0', 'templates': []}

if 'templates' not in wf:
    wf['templates'] = []

wf['templates'].append(template)
wf['last_updated'] = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')

with open('$WORKFLOW_TEMPLATES_FILE', 'w') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)
" || { echo "ERROR: Failed to write workflow-templates.json" >&2; exit 3; }

# --- Step 5: Add chain to production-chains.json ---
python3 -c "
import json, sys, datetime

input_data = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')
type_id = '$TYPE_ID'

chain = input_data.get('post_production_chain', [])

try:
    with open('$PRODUCTION_CHAINS_FILE', 'r') as f:
        pc = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    pc = {'version': '1.0', 'chains': {}}

if 'chains' not in pc:
    pc['chains'] = {}

# Only add if chain is non-empty and type_id not already present
if chain and type_id not in pc['chains']:
    pc['chains'][type_id] = chain
    pc['updated_at'] = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

    with open('$PRODUCTION_CHAINS_FILE', 'w') as f:
        json.dump(pc, f, indent=2, ensure_ascii=False)
" || { echo "ERROR: Failed to write production-chains.json" >&2; exit 3; }

# --- Step 6: Update skill-registry.json — add output type to relevant skills ---
python3 -c "
import json, sys, datetime

input_data = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')
type_id = '$TYPE_ID'

try:
    with open('$SKILL_REGISTRY_FILE', 'r') as f:
        reg = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    reg = {'version': '1.0', 'skills': {}}

if 'skills' not in reg:
    reg['skills'] = {}

# Determine which skills should get this output type
# Based on generation tools and agent assignments
gen_tools = input_data.get('generation_tools', [])
agent_assign = input_data.get('agent_assignment', {})
chain = input_data.get('post_production_chain', [])

# Tool-to-skill mapping
tool_skill_map = {
    'kling': ['persona', 'creative-production'],
    'sora': ['persona', 'creative-production'],
    'zimage': ['nanobanana', 'creative-production'],
    'nanobanana': ['nanobanana'],
    'video-forge': ['video-forge']
}

skills_to_update = set()

# If there is a chain, video-forge should know about this type
if chain:
    skills_to_update.add('video-forge')

# Map generation tools to skills
for tool in gen_tools:
    tool_lower = tool.lower()
    if tool_lower in tool_skill_map:
        for s in tool_skill_map[tool_lower]:
            skills_to_update.add(s)

# Creative production always gets new output types
skills_to_update.add('creative-production')

# Content seed bank tracks all output types
skills_to_update.add('content-seed-bank')

# Agents in assignment map: add their known skills
agent_skill_map = {
    'iris': ['art-direction', 'creative-review', 'image-optimizer'],
    'dreami': ['art-direction', 'creative-review'],
    'hermes': ['funnel-playbook'],
    'argus': ['creative-review'],
    'artemis': ['ig-reels-trends', 'tiktok-trends'],
}

for role, agent_id in agent_assign.items():
    if agent_id in agent_skill_map:
        for s in agent_skill_map[agent_id]:
            skills_to_update.add(s)

# Update each skill
changed = False
for skill_name in skills_to_update:
    if skill_name in reg['skills']:
        ot = reg['skills'][skill_name].get('output_types', [])
        if type_id not in ot:
            ot.append(type_id)
            reg['skills'][skill_name]['output_types'] = ot
            changed = True

if changed:
    reg['updated_at'] = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    with open('$SKILL_REGISTRY_FILE', 'w') as f:
        json.dump(reg, f, indent=2, ensure_ascii=False)
" || { echo "ERROR: Failed to update skill-registry.json" >&2; exit 3; }

# --- Step 7: Post notification to creative room ---
TIMESTAMP="$(python3 -c "import datetime; print(datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")"
REQUESTED_BY="$(python3 -c "
import json, sys
d = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')
print(d.get('requested_by', 'unknown'))
")"
TYPE_NAME="$(python3 -c "
import json, sys
d = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')
print(d.get('name', '$TYPE_ID'))
")"
SOURCE="$(python3 -c "
import json, sys
d = json.loads('''$( echo "$INPUT_JSON" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read())))" )''')
print(d.get('source', 'agent registration'))
")"

# Build notification JSON
python3 -c "
import json, sys

notification = {
    'ts': '$TIMESTAMP',
    'type': 'output-type-registered',
    'agent': '$REQUESTED_BY',
    'message': 'New output type registered: $TYPE_NAME ($TYPE_ID). Source: $SOURCE',
    'data': {
        'id': '$TYPE_ID',
        'name': '$TYPE_NAME',
        'requested_by': '$REQUESTED_BY',
        'source': '$SOURCE'
    }
}

line = json.dumps(notification, ensure_ascii=False)
with open('$CREATIVE_ROOM', 'a') as f:
    f.write(line + '\n')
" || echo "WARNING: Failed to post to creative room (non-fatal)." >&2

# --- Step 8: Output the new type ID ---
echo "$TYPE_ID"
exit 0
