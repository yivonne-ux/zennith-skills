#!/usr/bin/env bash
# pipeline-run.sh — Zennith OS Pipeline Runner
# Executes multi-agent pipelines defined in PUBSUB.json.
# Runs rounds sequentially: dispatch to agents, collect outputs, continue until
# max_rounds or all agents idle (no new messages produced).
#
# Usage:
#   pipeline-run.sh <pipeline_name> "<initial_input>" [--dry-run] [--verbose]
#   pipeline-run.sh list                              # Show available pipelines
#   pipeline-run.sh describe <pipeline_name>          # Show pipeline details
#
# Designed for macOS Bash 3.2 compatibility.
#
# How it works:
#   1. Reads pipeline definition from PUBSUB.json
#   2. Creates a pipeline-specific room file: rooms/pipeline-{name}-{id}.jsonl
#   3. Seeds the room with the initial message (using the pipeline trigger type)
#   4. Runs rounds: each round checks the flow for the next expected output
#   5. Dispatches to the agent responsible for producing that output
#   6. Waits for the agent to write its output to the room
#   7. Continues until flow is complete or max_rounds exhausted
#   8. Writes a completion-report to the exec room

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
OPENCLAW_HOME="${HOME}/.openclaw"
OPENCLAW_CONFIG="${OPENCLAW_HOME}/openclaw.json"
PUBSUB_CONFIG="${OPENCLAW_HOME}/workspace/PUBSUB.json"
ROOMS_DIR="${OPENCLAW_HOME}/workspace/rooms"
LOG_DIR="${ROOMS_DIR}/logs"
LOG_FILE="${LOG_DIR}/pubsub.log"
PUBSUB_DISPATCH="${OPENCLAW_HOME}/bin/pubsub-dispatch.sh"
DISPATCH_SCRIPT="${OPENCLAW_HOME}/skills/orchestrate-v2/scripts/dispatch.sh"

mkdir -p "${ROOMS_DIR}" "${LOG_DIR}"

# ── Config ───────────────────────────────────────────────────────────────────
DRY_RUN=false
VERBOSE=false
WAIT_TIMEOUT=300  # seconds to wait for each agent round
POLL_INTERVAL=5   # seconds between polling for agent output

# ── Logging ──────────────────────────────────────────────────────────────────
log() {
    local level="$1"
    shift
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "${ts} [PIPELINE] [${level}] $*" >> "${LOG_FILE}"
    if [ "${VERBOSE}" = "true" ]; then
        echo "[${level}] $*" >&2
    fi
}

info() {
    echo "$*"
    log "INFO" "$*"
}

# ── Load PUBSUB config ──────────────────────────────────────────────────────
load_config() {
    if [ ! -f "${PUBSUB_CONFIG}" ]; then
        echo "ERROR: PUBSUB.json not found at ${PUBSUB_CONFIG}" >&2
        exit 1
    fi
    PUBSUB_DATA=$(cat "${PUBSUB_CONFIG}")
}

# ── Get pipeline definition ─────────────────────────────────────────────────
get_pipeline() {
    local name="$1"
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
pipe = data.get('pipelines', {}).get('${name}')
if pipe:
    print(json.dumps(pipe))
else:
    print('')
" 2>/dev/null
}

# ── Generate pipeline run ID ────────────────────────────────────────────────
gen_run_id() {
    python3 -c "import uuid; print(str(uuid.uuid4())[:8])" 2>/dev/null
}

# ── ISO timestamp ────────────────────────────────────────────────────────────
iso_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ── Parse flow step "agent:type" ─────────────────────────────────────────────
parse_flow_step() {
    local step="$1"
    local field="$2"  # "agent" or "type"

    case "${field}" in
        agent) echo "${step%%:*}" ;;
        type)  echo "${step#*:}" ;;
    esac
}

# ── Dispatch to an agent via OpenClaw ────────────────────────────────────────
dispatch_to_agent() {
    local agent_name="$1"
    local task_brief="$2"
    local label="$3"

    # Map pubsub agent names to OpenClaw agent IDs
    local agent_id="${agent_name}"
    case "${agent_name}" in
        zenni) agent_id="main" ;;
        *)     agent_id="${agent_name}" ;;
    esac

    if [ "${DRY_RUN}" = "true" ]; then
        info "  [DRY RUN] Would dispatch to ${agent_name} (${agent_id}): ${task_brief}"
        return 0
    fi

    # Use the existing dispatch.sh if available
    if [ -x "${DISPATCH_SCRIPT}" ]; then
        info "  Dispatching to ${agent_name} via dispatch.sh..."
        bash "${DISPATCH_SCRIPT}" "${agent_id}" "${task_brief}" "${label}" "medium" "${WAIT_TIMEOUT}" 2>&1 || {
            log "WARN" "dispatch.sh returned non-zero for agent ${agent_name}"
            return 1
        }
    else
        log "WARN" "dispatch.sh not found at ${DISPATCH_SCRIPT}, using pubsub publish only"
        # Fallback: just publish a message that the agent watches
        # The agent's heartbeat or manual processing will pick it up
        info "  Published task to ${agent_name} (no dispatch.sh — agent must poll room)"
    fi
    return 0
}

# ── Wait for agent output in room ────────────────────────────────────────────
wait_for_output() {
    local room_file="$1"
    local expected_type="$2"
    local expected_from="$3"
    local start_line="$4"
    local timeout="${WAIT_TIMEOUT}"

    if [ "${DRY_RUN}" = "true" ]; then
        info "  [DRY RUN] Would wait for ${expected_from}:${expected_type}"
        return 0
    fi

    local elapsed=0
    while [ ${elapsed} -lt ${timeout} ]; do
        if [ -f "${room_file}" ]; then
            # Check for new messages after start_line matching our expected output
            local match
            match=$(tail -n +"${start_line}" "${room_file}" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        msg = json.loads(line)
        if msg.get('from') == '${expected_from}' and msg.get('type') == '${expected_type}':
            print(json.dumps(msg))
            break
    except:
        continue
" 2>/dev/null)

            if [ -n "${match}" ]; then
                info "  Received ${expected_from}:${expected_type}"
                echo "${match}"
                return 0
            fi
        fi

        sleep "${POLL_INTERVAL}"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    log "WARN" "Timeout waiting for ${expected_from}:${expected_type} (${timeout}s)"
    return 1
}

# ── Count lines in file (macOS wc adds leading spaces) ───────────────────────
count_lines() {
    local file="$1"
    if [ -f "${file}" ]; then
        wc -l < "${file}" | tr -d ' '
    else
        echo "0"
    fi
}

# ── Run a pipeline ──────────────────────────────────────────────────────────
cmd_run() {
    local pipeline_name="${1:-}"
    local initial_input="${2:-}"

    if [ -z "${pipeline_name}" ] || [ -z "${initial_input}" ]; then
        echo "Usage: pipeline-run.sh <pipeline_name> \"<initial_input>\" [--dry-run] [--verbose]"
        exit 1
    fi

    load_config

    # Get pipeline definition
    local pipe_def
    pipe_def=$(get_pipeline "${pipeline_name}")
    if [ -z "${pipe_def}" ]; then
        echo "ERROR: Unknown pipeline '${pipeline_name}'" >&2
        echo "Run 'pipeline-run.sh list' to see available pipelines." >&2
        exit 1
    fi

    # Parse pipeline fields
    local trigger
    trigger=$(echo "${pipe_def}" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('trigger',''))" 2>/dev/null)
    local max_rounds
    max_rounds=$(echo "${pipe_def}" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('max_rounds',5))" 2>/dev/null)
    local on_complete
    on_complete=$(echo "${pipe_def}" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('on_complete','completion-report'))" 2>/dev/null)
    local flow_json
    flow_json=$(echo "${pipe_def}" | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read()).get('flow',[])))" 2>/dev/null)
    local flow_count
    flow_count=$(echo "${flow_json}" | python3 -c "import sys,json; print(len(json.loads(sys.stdin.read())))" 2>/dev/null)
    local description
    description=$(echo "${pipe_def}" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('description',''))" 2>/dev/null)

    # Generate run ID and room
    local run_id
    run_id=$(gen_run_id)
    local pipeline_room="pipeline-${pipeline_name}-${run_id}"
    local room_file="${ROOMS_DIR}/${pipeline_room}.jsonl"

    info "=== Pipeline: ${pipeline_name} (run: ${run_id}) ==="
    info "Description: ${description}"
    info "Trigger: ${trigger}"
    info "Flow steps: ${flow_count}"
    info "Max rounds: ${max_rounds}"
    info "Room: ${pipeline_room}"
    info ""

    # Seed the pipeline room with the initial message
    local seed_ts
    seed_ts=$(iso_timestamp)
    local seed_msg
    seed_msg=$(printf '%s' "${initial_input}" | python3 -c "
import sys, json, uuid
content = sys.stdin.read()
msg = {
    'id': str(uuid.uuid4())[:12],
    'from': 'zenni',
    'type': '${trigger}',
    'content': content,
    'timestamp': '${seed_ts}',
    'pipeline': '${pipeline_name}',
    'pipeline_run': '${run_id}',
    'round': 0,
    'routed': False,
    'delivered_to': []
}
print(json.dumps(msg))
" 2>/dev/null)

    echo "${seed_msg}" >> "${room_file}"
    log "INFO" "Pipeline ${pipeline_name}/${run_id} seeded with trigger=${trigger}"
    info "Round 0: Seeded with [${trigger}]"

    # Execute flow steps
    local round=1
    local completed_steps=0
    local last_output="${initial_input}"
    local pipeline_results=""

    while [ ${round} -le ${max_rounds} ] && [ ${completed_steps} -lt ${flow_count} ]; do
        # Get current flow step
        local step
        step=$(echo "${flow_json}" | python3 -c "
import sys, json
flow = json.loads(sys.stdin.read())
idx = ${completed_steps}
if idx < len(flow):
    print(flow[idx])
else:
    print('')
" 2>/dev/null)

        if [ -z "${step}" ]; then
            break
        fi

        local step_agent
        step_agent=$(parse_flow_step "${step}" "agent")
        local step_type
        step_type=$(parse_flow_step "${step}" "type")

        info ""
        info "Round ${round}: Expecting ${step_agent}:${step_type}"

        # Record line count before dispatch (to know where to look for new messages)
        local start_line
        start_line=$(count_lines "${room_file}")
        start_line=$((start_line + 1))

        # Build the task brief for the agent
        local task_brief="[Pipeline: ${pipeline_name}/${run_id}, Round ${round}/${max_rounds}]
Expected output type: ${step_type}
Pipeline room: ${pipeline_room}
Context from previous step: ${last_output}

Original request: ${initial_input}

After completing your work, publish your result using:
  bash ${PUBSUB_DISPATCH} publish ${step_agent} ${step_type} '<your result>' --room ${pipeline_room} --pipeline ${pipeline_name} --round ${round}"

        # Dispatch to the agent
        dispatch_to_agent "${step_agent}" "${task_brief}" "pipe-${pipeline_name}-r${round}"

        if [ "${DRY_RUN}" = "true" ]; then
            info "  [DRY RUN] Step ${completed_steps} complete"
            completed_steps=$((completed_steps + 1))
            round=$((round + 1))
            continue
        fi

        # Wait for the agent's output
        local output
        output=$(wait_for_output "${room_file}" "${step_type}" "${step_agent}" "${start_line}") || {
            info "  TIMEOUT: ${step_agent} did not produce ${step_type} within ${WAIT_TIMEOUT}s"
            log "WARN" "Pipeline ${pipeline_name}/${run_id} step ${completed_steps} timed out"

            # Record timeout but continue to next round
            round=$((round + 1))
            continue
        }

        # Extract content from output
        if [ -n "${output}" ]; then
            last_output=$(echo "${output}" | python3 -c "
import sys, json
try:
    msg = json.loads(sys.stdin.read())
    print(msg.get('content', ''))
except:
    print('')
" 2>/dev/null)
            pipeline_results="${pipeline_results}
--- Step ${completed_steps}: ${step_agent}:${step_type} (Round ${round}) ---
${last_output}"
        fi

        completed_steps=$((completed_steps + 1))
        round=$((round + 1))

        info "  Step ${completed_steps}/${flow_count} complete"
    done

    # Pipeline complete — write summary
    info ""
    info "=== Pipeline Complete ==="
    info "Steps completed: ${completed_steps}/${flow_count}"
    info "Rounds used: $((round - 1))/${max_rounds}"

    local status="complete"
    if [ ${completed_steps} -lt ${flow_count} ]; then
        status="partial"
        info "Status: PARTIAL (not all steps completed)"
    else
        info "Status: COMPLETE"
    fi

    # Write completion report to exec room
    local summary_msg
    summary_msg=$(python3 -c "
import json, uuid
msg = {
    'id': str(uuid.uuid4())[:12],
    'from': 'zenni',
    'type': '${on_complete}',
    'content': json.dumps({
        'pipeline': '${pipeline_name}',
        'run_id': '${run_id}',
        'status': '${status}',
        'steps_completed': ${completed_steps},
        'steps_total': ${flow_count},
        'rounds_used': $((round - 1)),
        'max_rounds': int('${max_rounds}'),
        'room': '${pipeline_room}'
    }),
    'timestamp': '$(iso_timestamp)',
    'pipeline': '${pipeline_name}',
    'pipeline_run': '${run_id}',
    'round': $((round - 1)),
    'routed': False,
    'delivered_to': []
}
print(json.dumps(msg))
" 2>/dev/null)

    echo "${summary_msg}" >> "${ROOMS_DIR}/exec.jsonl"
    echo "${summary_msg}" >> "${room_file}"
    log "INFO" "Pipeline ${pipeline_name}/${run_id} finished: status=${status} steps=${completed_steps}/${flow_count}"

    info ""
    info "Completion report written to exec room"
    info "Full pipeline log: ${room_file}"
}

# ── List pipelines ───────────────────────────────────────────────────────────
cmd_list() {
    load_config

    echo "=== Available Pipelines ==="
    echo ""
    echo "${PUBSUB_DATA}" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
pipelines = data.get('pipelines', {})
for name, pipe in sorted(pipelines.items()):
    trigger = pipe.get('trigger', '')
    flow = pipe.get('flow', [])
    max_r = pipe.get('max_rounds', 0)
    desc = pipe.get('description', '')
    f_str = ' -> '.join(flow)
    print('  %s' % name)
    print('    %s' % desc)
    print('    Trigger: %s | Steps: %d | Max rounds: %d' % (trigger, len(flow), max_r))
    print('    Flow: %s' % f_str)
    print()
" 2>/dev/null
}

# ── Describe a pipeline ─────────────────────────────────────────────────────
cmd_describe() {
    local name="${1:-}"
    if [ -z "${name}" ]; then
        echo "Usage: pipeline-run.sh describe <pipeline_name>"
        exit 1
    fi

    load_config

    local pipe_def
    pipe_def=$(get_pipeline "${name}")
    if [ -z "${pipe_def}" ]; then
        echo "ERROR: Unknown pipeline '${name}'" >&2
        exit 1
    fi

    echo "${pipe_def}" | python3 -c "
import sys, json
pipe = json.loads(sys.stdin.read())
print('Pipeline: ${name}')
print('  Description: %s' % pipe.get('description', ''))
print('  Trigger: %s' % pipe.get('trigger', ''))
print('  Max rounds: %s' % pipe.get('max_rounds', 0))
print('  On complete: %s' % pipe.get('on_complete', 'completion-report'))
print()
print('  Flow:')
for i, step in enumerate(pipe.get('flow', []), 1):
    agent, msg_type = step.split(':', 1)
    print('    %d. %s produces [%s]' % (i, agent, msg_type))
print()
print('  Execution plan:')
print('    1. Pipeline runner receives trigger message of type [%s]' % pipe.get('trigger', ''))
for i, step in enumerate(pipe.get('flow', []), 2):
    agent, msg_type = step.split(':', 1)
    print('    %d. Dispatch to %s, wait for [%s] output' % (i, agent, msg_type))
print('    %d. Write [%s] to exec room' % (len(pipe.get('flow', [])) + 2, pipe.get('on_complete', 'completion-report')))
" 2>/dev/null
}

# ── Main ─────────────────────────────────────────────────────────────────────
COMMAND="${1:-}"

# Parse global flags
for arg in "$@"; do
    case "${arg}" in
        --dry-run) DRY_RUN=true ;;
        --verbose|-v) VERBOSE=true ;;
    esac
done

case "${COMMAND}" in
    list)
        cmd_list
        ;;
    describe)
        shift
        cmd_describe "${1:-}"
        ;;
    help|--help|-h)
        echo "pipeline-run.sh — Zennith OS Pipeline Runner"
        echo ""
        echo "Executes multi-agent pipelines defined in PUBSUB.json."
        echo ""
        echo "Commands:"
        echo "  <pipeline_name> \"<input>\"  Run a pipeline with initial input"
        echo "  list                        Show available pipelines"
        echo "  describe <name>             Show pipeline details and execution plan"
        echo "  help                        Show this help"
        echo ""
        echo "Flags:"
        echo "  --dry-run     Show what would happen without executing"
        echo "  --verbose     Print detailed progress to stderr"
        echo ""
        echo "Examples:"
        echo "  pipeline-run.sh content-factory 'Create social media content for Pinxin vegan bento'"
        echo "  pipeline-run.sh campaign-launch 'Launch MIRRA Q2 awareness campaign' --verbose"
        echo "  pipeline-run.sh bug-fix 'nanobanana-gen.sh fails on --style-seed flag' --dry-run"
        echo "  pipeline-run.sh list"
        echo "  pipeline-run.sh describe content-factory"
        ;;
    "")
        echo "Usage: pipeline-run.sh <pipeline_name|list|describe|help> [args]"
        echo "Run 'pipeline-run.sh help' for details."
        exit 1
        ;;
    *)
        # Default: treat first arg as pipeline name, second as input
        shift
        cmd_run "${COMMAND}" "${1:-}"
        ;;
esac
