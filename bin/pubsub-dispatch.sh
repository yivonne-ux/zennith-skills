#!/usr/bin/env bash
# pubsub-dispatch.sh — Zennith OS Pub-Sub Message Dispatcher
# Handles AGENT->AGENT routing via subscription-based message dispatch.
# Inspired by MetaGPT's subscription model, adapted for OpenClaw's JSONL rooms.
#
# Usage:
#   pubsub-dispatch.sh publish <from_agent> <type> <content> [--room <room>] [--pipeline <id>] [--round <n>]
#   pubsub-dispatch.sh route <room_file>              # Process unrouted messages in a room file
#   pubsub-dispatch.sh status                          # Show subscription table
#   pubsub-dispatch.sh check <type>                    # Show which agents watch this type
#   pubsub-dispatch.sh types                           # List all valid message types
#   pubsub-dispatch.sh drain <room>                    # Process all pending messages in a room
#
# Designed for macOS Bash 3.2 compatibility (no associative arrays, no declare -A).
#
# Integration:
#   classify.sh handles HUMAN -> AGENT routing (user messages from WhatsApp/Telegram)
#   pubsub-dispatch.sh handles AGENT -> AGENT routing (inter-agent communication)
#   Both coexist: classify.sh triggers the first agent, pubsub handles the chain.

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
OPENCLAW_HOME="${HOME}/.openclaw"
OPENCLAW_CONFIG="${OPENCLAW_HOME}/openclaw.json"
PUBSUB_CONFIG="${OPENCLAW_HOME}/workspace/PUBSUB.json"
ROOMS_DIR="${OPENCLAW_HOME}/workspace/rooms"
LOG_DIR="${ROOMS_DIR}/logs"
LOG_FILE="${LOG_DIR}/pubsub.log"
DISPATCH_SCRIPT="${OPENCLAW_HOME}/skills/orchestrate-v2/scripts/dispatch.sh"
PIPELINE_RUNNER="${OPENCLAW_HOME}/bin/pipeline-run.sh"

mkdir -p "${ROOMS_DIR}" "${LOG_DIR}"

# ── Logging ──────────────────────────────────────────────────────────────────
log() {
    local level="$1"
    shift
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "${ts} [${level}] $*" >> "${LOG_FILE}"
    if [ "${VERBOSE:-false}" = "true" ]; then
        echo "[${level}] $*" >&2
    fi
}

# ── JSON helpers (pure bash + python3 — no jq dependency) ────────────────────
# We use python3 for JSON parsing since jq may not be installed.
# All JSON operations go through these helpers.

json_get() {
    # json_get <json_string> <key>
    # Returns the value of a top-level key from a JSON object
    local json="$1"
    local key="$2"
    echo "${json}" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    val = data.get('${key}', '')
    if isinstance(val, (dict, list)):
        print(json.dumps(val))
    else:
        print(val if val is not None else '')
except:
    print('')
" 2>/dev/null
}

json_get_nested() {
    # json_get_nested <json_string> <key1> <key2> ...
    # Navigate nested keys
    local json="$1"
    shift
    local keys=""
    for k in "$@"; do
        keys="${keys}'${k}',"
    done
    echo "${json}" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    keys = [${keys}]
    for k in keys:
        if isinstance(data, dict):
            data = data.get(k, '')
        else:
            data = ''
            break
    if isinstance(data, (dict, list)):
        print(json.dumps(data))
    else:
        print(data if data is not None else '')
except:
    print('')
" 2>/dev/null
}

# ── Config loading ───────────────────────────────────────────────────────────
load_config() {
    if [ ! -f "${PUBSUB_CONFIG}" ]; then
        echo "ERROR: PUBSUB.json not found at ${PUBSUB_CONFIG}" >&2
        exit 1
    fi
    if [ ! -f "${OPENCLAW_CONFIG}" ]; then
        echo "ERROR: openclaw.json not found at ${OPENCLAW_CONFIG}" >&2
        exit 1
    fi
    PUBSUB_DATA=$(cat "${PUBSUB_CONFIG}")
    OPENCLAW_DATA=$(cat "${OPENCLAW_CONFIG}")

    # Cross-reference: validate all PUBSUB agents exist in openclaw.json
    local invalid
    invalid=$(python3 -c "
import sys, json
pubsub = json.loads('''${PUBSUB_DATA}''')
openclaw = json.load(open('${OPENCLAW_CONFIG}'))
oc_ids = {a['id'] for a in openclaw.get('agents',{}).get('list',[])}
ps_ids = set(pubsub.get('agents',{}).keys())
missing = ps_ids - oc_ids
if missing:
    print('WARNING: agents in PUBSUB.json but not in openclaw.json: ' + ', '.join(sorted(missing)))
" 2>/dev/null)
    if [ -n "${invalid}" ]; then
        log "WARN" "${invalid}"
        echo "${invalid}" >&2
    fi
}

# Get agent workspace path from openclaw.json
get_agent_workspace() {
    local agent_id="$1"
    echo "${OPENCLAW_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for a in data.get('agents',{}).get('list',[]):
    if a['id'] == '${agent_id}':
        print(a.get('workspace',''))
        break
" 2>/dev/null
}

# Get agent model from openclaw.json
get_agent_model() {
    local agent_id="$1"
    echo "${OPENCLAW_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for a in data.get('agents',{}).get('list',[]):
    if a['id'] == '${agent_id}':
        print(a.get('model',{}).get('primary','unknown'))
        break
" 2>/dev/null
}

# ── Get watchers for a message type ──────────────────────────────────────────
get_watchers() {
    # Returns agent names (space-separated) that watch the given message type
    local msg_type="$1"
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
agents = data.get('agents', {})
watchers = []
for name, agent in agents.items():
    watches = agent.get('watches', [])
    if '${msg_type}' in watches:
        watchers.append(name)
# Sort by priority (lower = higher priority)
watchers.sort(key=lambda n: agents[n].get('priority', 99))
print(' '.join(watchers))
" 2>/dev/null
}

# ── Get agent's OpenClaw ID ─────────────────────────────────────────────────
get_agent_id() {
    local agent_name="$1"
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
agent = data.get('agents', {}).get('${agent_name}', {})
print(agent.get('id', '${agent_name}'))
" 2>/dev/null
}

# ── Check if message type triggers a pipeline ────────────────────────────────
get_pipeline_for_type() {
    local msg_type="$1"
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
pipelines = data.get('pipelines', {})
for name, pipe in pipelines.items():
    if pipe.get('trigger') == '${msg_type}':
        print(name)
        break
" 2>/dev/null
}

# ── Validate message type ────────────────────────────────────────────────────
is_valid_type() {
    local msg_type="$1"
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
types = data.get('message_types', [])
print('yes' if '${msg_type}' in types else 'no')
" 2>/dev/null
}

# ── Generate message ID ─────────────────────────────────────────────────────
gen_msg_id() {
    # Use python3 uuid since uuidgen may produce different formats on macOS
    python3 -c "import uuid; print(str(uuid.uuid4())[:12])" 2>/dev/null
}

# ── Timestamp ────────────────────────────────────────────────────────────────
iso_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ── Build JSONL message ──────────────────────────────────────────────────────
build_message() {
    local from_agent="$1"
    local msg_type="$2"
    local content="$3"
    local pipeline="${4:-}"
    local round="${5:-0}"
    local msg_id
    msg_id=$(gen_msg_id)
    local ts
    ts=$(iso_timestamp)

    # Pass content via stdin to avoid shell escaping issues
    printf '%s' "${content}" | python3 -c "
import sys, json
content = sys.stdin.read()
msg = {
    'id': '${msg_id}',
    'from': '${from_agent}',
    'type': '${msg_type}',
    'content': content,
    'timestamp': '${ts}',
    'routed': False,
    'delivered_to': []
}
pipeline = '${pipeline}'
if pipeline:
    msg['pipeline'] = pipeline
rnd = int('${round}')
if rnd > 0:
    msg['round'] = rnd
print(json.dumps(msg))
" 2>/dev/null
}

# ── Append message to room file ──────────────────────────────────────────────
append_to_room() {
    local room="$1"
    local message="$2"
    local room_file="${ROOMS_DIR}/${room}.jsonl"
    echo "${message}" >> "${room_file}"
}

# ── Route a single message to watching agents ────────────────────────────────
route_message() {
    local message="$1"
    local source_room="${2:-}"
    local msg_type
    msg_type=$(json_get "${message}" "type")
    local from_agent
    from_agent=$(json_get "${message}" "from")
    local msg_id
    msg_id=$(json_get "${message}" "id")
    local content
    content=$(json_get "${message}" "content")
    local pipeline
    pipeline=$(json_get "${message}" "pipeline")

    if [ -z "${msg_type}" ]; then
        log "WARN" "Message has no type field, skipping: ${msg_id}"
        return 1
    fi

    # Check if type triggers a pipeline
    local triggered_pipeline
    triggered_pipeline=$(get_pipeline_for_type "${msg_type}")
    if [ -n "${triggered_pipeline}" ] && [ -z "${pipeline}" ]; then
        log "INFO" "Message type '${msg_type}' triggers pipeline '${triggered_pipeline}'"
        if [ -x "${PIPELINE_RUNNER}" ]; then
            log "INFO" "Launching pipeline: ${triggered_pipeline}"
            bash "${PIPELINE_RUNNER}" "${triggered_pipeline}" "${content}" &
            local pipe_pid=$!
            log "INFO" "Pipeline ${triggered_pipeline} started (PID: ${pipe_pid})"
        else
            log "WARN" "Pipeline runner not found or not executable at ${PIPELINE_RUNNER}"
        fi
    fi

    # Find watchers
    local watchers
    watchers=$(get_watchers "${msg_type}")

    if [ -z "${watchers}" ]; then
        log "WARN" "No agents watch type '${msg_type}' — sending to dead letter room"
        append_to_room "townhall" "${message}"
        return 0
    fi

    local delivered_count=0
    for watcher in ${watchers}; do
        # Don't route back to sender
        if [ "${watcher}" = "${from_agent}" ]; then
            continue
        fi

        # Determine target room based on agent role
        local target_room
        target_room=$(determine_room "${watcher}" "${msg_type}")

        # Build routed copy with delivery metadata
        local routed_msg
        routed_msg=$(echo "${message}" | python3 -c "
import sys, json
msg = json.loads(sys.stdin.read())
msg['routed'] = True
if 'delivered_to' not in msg:
    msg['delivered_to'] = []
msg['delivered_to'].append('${watcher}')
msg['target_agent'] = '${watcher}'
print(json.dumps(msg))
" 2>/dev/null)

        append_to_room "${target_room}" "${routed_msg}"
        delivered_count=$((delivered_count + 1))

        log "INFO" "Routed [${msg_type}] from=${from_agent} -> ${watcher} (room=${target_room})"
    done

    if [ ${delivered_count} -eq 0 ]; then
        log "WARN" "Message ${msg_id} had watchers but none were valid targets (all were sender)"
    else
        log "INFO" "Message ${msg_id} delivered to ${delivered_count} agent(s)"
    fi

    return 0
}

# ── Determine which room an agent should receive messages in ─────────────────
determine_room() {
    local agent="$1"
    local msg_type="$2"

    # Map agent+type to the most appropriate room
    case "${agent}" in
        zenni|main)
            case "${msg_type}" in
                escalation|error|approval-request) echo "exec" ;;
                completion-report|pipeline-summary) echo "exec" ;;
                *) echo "exec" ;;
            esac
            ;;
        taoz)
            case "${msg_type}" in
                code-request|build-request|deploy-request|skill-request) echo "build" ;;
                bug-report) echo "build" ;;
                infrastructure-task|technical-question) echo "build" ;;
                *) echo "build" ;;
            esac
            ;;
        dreami)
            case "${msg_type}" in
                creative-request|content-request|copy-request) echo "creative" ;;
                campaign-brief|brand-task) echo "creative" ;;
                image-request|video-request) echo "creative" ;;
                *) echo "creative" ;;
            esac
            ;;
        scout)
            case "${msg_type}" in
                research-request|scrape-request|analysis-request) echo "analytics" ;;
                qa-request|fact-check-request) echo "feedback" ;;
                trend-request) echo "analytics" ;;
                *) echo "analytics" ;;
            esac
            ;;
        *)
            echo "townhall"
            ;;
    esac
}

# ── COMMANDS ─────────────────────────────────────────────────────────────────

cmd_publish() {
    local from_agent="${1:-}"
    local msg_type="${2:-}"
    local content="${3:-}"
    local room="${4:-}"
    local pipeline="${5:-}"
    local round="${6:-0}"

    if [ -z "${from_agent}" ] || [ -z "${msg_type}" ] || [ -z "${content}" ]; then
        echo "Usage: pubsub-dispatch.sh publish <from_agent> <type> <content> [--room <room>] [--pipeline <id>] [--round <n>]"
        exit 1
    fi

    load_config

    # Validate message type
    local valid
    valid=$(is_valid_type "${msg_type}")
    if [ "${valid}" != "yes" ]; then
        log "ERROR" "Unknown message type: ${msg_type}"
        echo "ERROR: Unknown message type '${msg_type}'. Run 'pubsub-dispatch.sh types' for valid types." >&2
        exit 1
    fi

    # Build message
    local message
    message=$(build_message "${from_agent}" "${msg_type}" "${content}" "${pipeline}" "${round}")

    # Determine source room (where the message originates)
    if [ -z "${room}" ]; then
        room=$(determine_room "${from_agent}" "${msg_type}")
    fi

    # Write to source room
    append_to_room "${room}" "${message}"
    log "INFO" "Published [${msg_type}] from=${from_agent} to room=${room}"

    # Route to watchers
    route_message "${message}" "${room}"

    echo "OK: Published [${msg_type}] from ${from_agent}"
    local watchers
    watchers=$(get_watchers "${msg_type}")
    if [ -n "${watchers}" ]; then
        echo "   Routed to: ${watchers}"
    fi
}

cmd_route() {
    local room_file="${1:-}"

    if [ -z "${room_file}" ]; then
        echo "Usage: pubsub-dispatch.sh route <room_file>"
        exit 1
    fi

    if [ ! -f "${room_file}" ]; then
        echo "ERROR: Room file not found: ${room_file}" >&2
        exit 1
    fi

    load_config

    local count=0
    local routed=0

    # Process each line in the room file
    while IFS= read -r line; do
        # Skip empty lines
        [ -z "${line}" ] && continue

        count=$((count + 1))

        # Check if already routed
        local is_routed
        is_routed=$(json_get "${line}" "routed")
        if [ "${is_routed}" = "True" ] || [ "${is_routed}" = "true" ]; then
            continue
        fi

        # Check if has a type field
        local msg_type
        msg_type=$(json_get "${line}" "type")
        if [ -z "${msg_type}" ]; then
            continue
        fi

        # Route it
        route_message "${line}" "${room_file}"
        routed=$((routed + 1))

    done < "${room_file}"

    echo "Processed ${count} messages, routed ${routed} new messages"
    log "INFO" "Route scan: file=${room_file} total=${count} routed=${routed}"
}

cmd_drain() {
    local room_name="${1:-}"

    if [ -z "${room_name}" ]; then
        echo "Usage: pubsub-dispatch.sh drain <room_name>"
        echo "  Rooms: exec, build, creative, analytics, execution, feedback, social, townhall"
        exit 1
    fi

    local room_file="${ROOMS_DIR}/${room_name}.jsonl"
    if [ ! -f "${room_file}" ]; then
        echo "No messages in room '${room_name}' (file does not exist)"
        exit 0
    fi

    cmd_route "${room_file}"
}

cmd_status() {
    load_config

    echo "=== Zennith OS Pub-Sub Subscription Table ==="
    echo ""

    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json

data = json.loads(sys.stdin.read())
agents = data.get('agents', {})

# Sort by priority
sorted_agents = sorted(agents.items(), key=lambda x: x[1].get('priority', 99))

for name, agent in sorted_agents:
    role = agent.get('role', 'Unknown')
    agent_id = agent.get('id', name)
    watches = agent.get('watches', [])
    produces = agent.get('produces', [])
    priority = agent.get('priority', 99)

    w_str = ', '.join(watches)
    p_str = ', '.join(produces)
    print('Agent: %s (id=%s, priority=%d)' % (name, agent_id, priority))
    print('  Role: %s' % role)
    print('  Watches:  %s' % w_str)
    print('  Produces: %s' % p_str)
    print()

pipelines = data.get('pipelines', {})
if pipelines:
    print('=== Pipelines ===')
    print()
    for name, pipe in pipelines.items():
        trigger = pipe.get('trigger', '')
        flow = pipe.get('flow', [])
        max_rounds = pipe.get('max_rounds', 0)
        desc = pipe.get('description', '')
        f_str = ' -> '.join(flow)
        print('Pipeline: %s' % name)
        print('  Description: %s' % desc)
        print('  Trigger: %s' % trigger)
        print('  Flow: %s' % f_str)
        print('  Max rounds: %d' % max_rounds)
        print()
" 2>/dev/null
}

cmd_check() {
    local msg_type="${1:-}"

    if [ -z "${msg_type}" ]; then
        echo "Usage: pubsub-dispatch.sh check <message_type>"
        exit 1
    fi

    load_config

    local valid
    valid=$(is_valid_type "${msg_type}")
    if [ "${valid}" != "yes" ]; then
        echo "Unknown message type: ${msg_type}"
        exit 1
    fi

    local watchers
    watchers=$(get_watchers "${msg_type}")

    echo "Message type: ${msg_type}"
    if [ -n "${watchers}" ]; then
        echo "Watched by: ${watchers}"
    else
        echo "Watched by: (nobody — will go to dead letter room)"
    fi

    local triggered
    triggered=$(get_pipeline_for_type "${msg_type}")
    if [ -n "${triggered}" ]; then
        echo "Triggers pipeline: ${triggered}"
    fi

    # Show who produces this type
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
agents = data.get('agents', {})
producers = []
for name, agent in agents.items():
    if '${msg_type}' in agent.get('produces', []):
        producers.append(name)
if producers:
    print('Produced by: %s' % ', '.join(producers))
else:
    print('Produced by: (no agent declares producing this type)')
" 2>/dev/null
}

cmd_types() {
    load_config

    echo "=== Valid Message Types ==="
    echo ""
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
types = sorted(data.get('message_types', []))
for t in types:
    print('  %s' % t)
print('\nTotal: %d types' % len(types))
" 2>/dev/null
}

# ── Main ─────────────────────────────────────────────────────────────────────
COMMAND="${1:-}"

# Parse global flags
VERBOSE=false
for arg in "$@"; do
    if [ "${arg}" = "--verbose" ] || [ "${arg}" = "-v" ]; then
        VERBOSE=true
    fi
done

case "${COMMAND}" in
    publish)
        shift
        # Parse named args
        FROM=""
        TYPE=""
        CONTENT=""
        ROOM=""
        PIPELINE=""
        ROUND="0"

        # First 3 positional args
        FROM="${1:-}"
        shift 2>/dev/null || true
        TYPE="${1:-}"
        shift 2>/dev/null || true
        CONTENT="${1:-}"
        shift 2>/dev/null || true

        # Then named args
        while [ $# -gt 0 ]; do
            case "$1" in
                --room) shift; ROOM="${1:-}" ;;
                --pipeline) shift; PIPELINE="${1:-}" ;;
                --round) shift; ROUND="${1:-0}" ;;
                --verbose|-v) ;; # already handled
            esac
            shift 2>/dev/null || true
        done

        cmd_publish "${FROM}" "${TYPE}" "${CONTENT}" "${ROOM}" "${PIPELINE}" "${ROUND}"
        ;;
    route)
        shift
        cmd_route "${1:-}"
        ;;
    drain)
        shift
        cmd_drain "${1:-}"
        ;;
    status)
        cmd_status
        ;;
    check)
        shift
        cmd_check "${1:-}"
        ;;
    types)
        cmd_types
        ;;
    help|--help|-h|"")
        echo "pubsub-dispatch.sh — Zennith OS Pub-Sub Message Dispatcher"
        echo ""
        echo "AGENT->AGENT routing via subscription-based message dispatch."
        echo "Works alongside classify.sh (HUMAN->AGENT routing)."
        echo ""
        echo "Commands:"
        echo "  publish <from> <type> <content> [--room R] [--pipeline P] [--round N]"
        echo "          Publish a typed message and auto-route to watching agents"
        echo ""
        echo "  route <room_file.jsonl>"
        echo "          Process unrouted messages in a room file"
        echo ""
        echo "  drain <room_name>"
        echo "          Process all pending messages in a named room"
        echo ""
        echo "  status  Show subscription table (who watches/produces what)"
        echo ""
        echo "  check <type>"
        echo "          Show which agents watch a message type"
        echo ""
        echo "  types   List all valid message types"
        echo ""
        echo "  help    Show this help"
        echo ""
        echo "Flags:"
        echo "  --verbose, -v   Print routing decisions to stderr"
        echo ""
        echo "Examples:"
        echo "  pubsub-dispatch.sh publish taoz code-artifact 'Built new skill: video-gen'"
        echo "  pubsub-dispatch.sh publish scout research-report 'Competitor analysis: ...' --pipeline campaign-launch"
        echo "  pubsub-dispatch.sh check bug-report"
        echo "  pubsub-dispatch.sh drain build"
        echo "  pubsub-dispatch.sh status"
        ;;
    *)
        echo "Unknown command: ${COMMAND}" >&2
        echo "Run 'pubsub-dispatch.sh help' for usage." >&2
        exit 1
        ;;
esac
