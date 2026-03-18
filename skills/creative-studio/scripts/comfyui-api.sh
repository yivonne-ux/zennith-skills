#!/usr/bin/env bash
# comfyui-api.sh — ComfyUI Cloud API client for GAIA Creative Studio
# Submits workflows, monitors jobs, downloads outputs
# API docs: https://docs.comfy.org/development/cloud/overview

set -euo pipefail

COMFYUI_API_BASE="https://cloud.comfy.org/api"
COMFYUI_API_KEY="${COMFYUI_API_KEY:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Load API key from env file if not set
if [[ -z "$COMFYUI_API_KEY" ]]; then
  for keyfile in \
    "/Users/jennwoeiloh/.openclaw/.env" \
    "/Users/jennwoeiloh/.openclaw/skills/creative-studio/.env" \
    "/Users/jennwoeiloh/.env"; do
    if [[ -f "$keyfile" ]]; then
      val=$(grep -E '^COMFYUI_API_KEY=' "$keyfile" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")
      if [[ -n "$val" ]]; then
        COMFYUI_API_KEY="$val"
        break
      fi
    fi
  done
fi

if [[ -z "$COMFYUI_API_KEY" ]]; then
  echo "ERROR: COMFYUI_API_KEY not set. Add to ~/.openclaw/.env or export it." >&2
  exit 1
fi

usage() {
  cat <<'EOF'
comfyui-api.sh — ComfyUI Cloud API Client

COMMANDS:
  submit   --workflow <file.json> [--poll]       Submit a workflow and optionally wait for completion
  status   --job <prompt_id>                     Check job status
  download --job <prompt_id> --output-dir <dir>  Download outputs from completed job
  test                                           Test API connectivity

OPTIONS:
  --workflow   Path to ComfyUI API-format workflow JSON
  --job        Job/prompt ID from a previous submission
  --output-dir Directory to save downloaded outputs (default: current dir)
  --poll       Wait for job completion after submitting
  --timeout    Max seconds to wait when polling (default: 300)
  --quiet      Suppress progress output

EXAMPLES:
  comfyui-api.sh test
  comfyui-api.sh submit --workflow character-angles.json --poll
  comfyui-api.sh status --job abc123
  comfyui-api.sh download --job abc123 --output-dir ./outputs/
EOF
}

# --- API functions ---

api_request() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"

  local args=(
    -s -S
    -X "$method"
    -H "X-API-Key: $COMFYUI_API_KEY"
    -H "Content-Type: application/json"
  )
  if [[ -n "$data" ]]; then
    args+=(-d "$data")
  fi

  curl "${args[@]}" "${COMFYUI_API_BASE}${endpoint}"
}

cmd_test() {
  echo "Testing ComfyUI Cloud API connection..."
  local resp
  resp=$(api_request GET "/user" 2>&1) || true

  if echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK: Connected as', d.get('email','unknown'))" 2>/dev/null; then
    echo "API key is valid."
    return 0
  else
    echo "ERROR: API test failed. Response: $resp" >&2
    return 1
  fi
}

cmd_submit() {
  local workflow_file=""
  local do_poll=false
  local timeout=300
  local quiet=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --workflow) workflow_file="$2"; shift 2 ;;
      --poll) do_poll=true; shift ;;
      --timeout) timeout="$2"; shift 2 ;;
      --quiet) quiet=true; shift ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$workflow_file" || ! -f "$workflow_file" ]]; then
    echo "ERROR: --workflow file required and must exist" >&2
    exit 1
  fi

  # Submit the workflow
  local payload
  payload=$(python3 -c "
import json, sys
with open('$workflow_file') as f:
    wf = json.load(f)
# Wrap in prompt format if not already
if 'prompt' not in wf:
    payload = {'prompt': wf}
else:
    payload = wf
print(json.dumps(payload))
")

  $quiet || echo "Submitting workflow: $workflow_file"
  local resp
  resp=$(api_request POST "/prompt" "$payload")

  local prompt_id
  prompt_id=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt_id',''))" 2>/dev/null)

  if [[ -z "$prompt_id" ]]; then
    echo "ERROR: Failed to submit workflow. Response: $resp" >&2
    exit 1
  fi

  echo "JOB_ID=$prompt_id"
  $quiet || echo "Job submitted: $prompt_id"

  if $do_poll; then
    cmd_poll --job "$prompt_id" --timeout "$timeout"
  fi
}

cmd_status() {
  local job_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --job) job_id="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$job_id" ]]; then
    echo "ERROR: --job required" >&2; exit 1
  fi

  local resp
  resp=$(api_request GET "/job/${job_id}/status")
  echo "$resp" | python3 -c "
import sys, json
d = json.load(sys.stdin)
status = d.get('status', 'unknown')
print(f'STATUS={status}')
if 'progress' in d:
    print(f'PROGRESS={d[\"progress\"]}')
" 2>/dev/null || echo "$resp"
}

cmd_poll() {
  local job_id=""
  local timeout=300
  local quiet=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --job) job_id="$2"; shift 2 ;;
      --timeout) timeout="$2"; shift 2 ;;
      --quiet) quiet=true; shift ;;
      *) shift ;;
    esac
  done

  if [[ -z "$job_id" ]]; then
    echo "ERROR: --job required" >&2; exit 1
  fi

  local elapsed=0
  local interval=3
  while [[ $elapsed -lt $timeout ]]; do
    local resp
    resp=$(api_request GET "/job/${job_id}/status" 2>/dev/null)
    local status
    status=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null || echo "unknown")

    case "$status" in
      completed|success)
        $quiet || echo "Job $job_id completed!"
        echo "STATUS=completed"
        return 0
        ;;
      failed)
        echo "ERROR: Job $job_id failed" >&2
        echo "$resp" >&2
        echo "STATUS=failed"
        return 1
        ;;
      cancelled)
        echo "Job $job_id was cancelled" >&2
        echo "STATUS=cancelled"
        return 1
        ;;
      *)
        $quiet || printf "\r  [%ds] Status: %s" "$elapsed" "$status"
        ;;
    esac

    sleep "$interval"
    elapsed=$((elapsed + interval))
    # Back off after 30s
    if [[ $elapsed -gt 30 && $interval -lt 10 ]]; then
      interval=10
    fi
  done

  echo ""
  echo "ERROR: Timeout after ${timeout}s. Job $job_id still running." >&2
  echo "STATUS=timeout"
  return 1
}

cmd_download() {
  local job_id=""
  local output_dir="."

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --job) job_id="$2"; shift 2 ;;
      --output-dir) output_dir="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$job_id" ]]; then
    echo "ERROR: --job required" >&2; exit 1
  fi

  mkdir -p "$output_dir"

  # Get job history with output details
  local resp
  resp=$(api_request GET "/history_v2/${job_id}")

  # Extract output filenames from history
  local files_json
  files_json=$(echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Handle nested format: {job_id: {outputs: ...}} or {outputs: ...}
if 'outputs' not in data:
    for k, v in data.items():
        if isinstance(v, dict) and 'outputs' in v:
            data = v
            break
outputs = data.get('outputs', {})
files = []
for node_id, node_out in outputs.items():
    for media_type in ['images', 'video', 'audio']:
        for f in node_out.get(media_type, []):
            fn = f.get('filename', '')
            sf = f.get('subfolder', '')
            if fn:
                files.append({'filename': fn, 'subfolder': sf})
print(json.dumps(files))
" 2>/dev/null)

  # Download each file via curl (handles redirects properly)
  local downloaded=0
  echo "$files_json" | python3 -c "
import sys, json
for f in json.load(sys.stdin):
    print(f['filename'] + '|' + f['subfolder'])
" 2>/dev/null | while IFS='|' read -r filename subfolder; do
    local outpath="${output_dir}/${filename}"
    echo "Downloading: $filename"
    if curl -sL \
      -H "X-API-Key: $COMFYUI_API_KEY" \
      "${COMFYUI_API_BASE}/view?filename=${filename}&subfolder=${subfolder}&type=output" \
      -o "$outpath" && [[ -s "$outpath" ]]; then
      echo "Downloaded: $outpath"
      downloaded=$((downloaded + 1))
    else
      echo "ERROR downloading $filename" >&2
    fi
  done

  echo "DOWNLOADED=$downloaded"
}

cmd_upload() {
  local file_path="" overwrite="true"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file) file_path="$2"; shift 2 ;;
      --no-overwrite) overwrite="false"; shift ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$file_path" || ! -f "$file_path" ]]; then
    echo "ERROR: --file required and must exist" >&2
    exit 1
  fi

  local filename
  filename=$(basename "$file_path")

  echo "Uploading: $filename"
  local resp
  resp=$(curl -s -S \
    -X POST \
    -H "X-API-Key: $COMFYUI_API_KEY" \
    -F "image=@${file_path}" \
    -F "type=input" \
    -F "overwrite=${overwrite}" \
    "${COMFYUI_API_BASE}/upload/image")

  local uploaded_name
  uploaded_name=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name',''))" 2>/dev/null)

  if [[ -n "$uploaded_name" ]]; then
    echo "UPLOADED=$uploaded_name"
    echo "Use in workflow LoadImage node as: $uploaded_name"
  else
    echo "ERROR: Upload failed. Response: $resp" >&2
    return 1
  fi
}

# --- Main ---
cmd="${1:-}"
shift 2>/dev/null || true

case "$cmd" in
  test) cmd_test ;;
  submit) cmd_submit "$@" ;;
  status) cmd_status "$@" ;;
  poll) cmd_poll "$@" ;;
  download) cmd_download "$@" ;;
  upload) cmd_upload "$@" ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
esac
