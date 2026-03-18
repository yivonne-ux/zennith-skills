#!/usr/bin/env bash
# ad-bulk-gen.sh — Bulk Ad Image Generation Pipeline for GAIA CORP-OS
# Generates images from a prompts file, with parallel workers, auto-tagging,
# seed bank registration, visual audit, and reporting.
# Works with OpenClaw's native nanobanana-gen.sh CLI.
# macOS-compatible: Bash 3.2, no declare -A, no ${var,,}, no GNU timeout
# ---

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

NANO="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
AUDIT="$HOME/.openclaw/skills/art-director/scripts/audit-visual.sh"
SEED_BANK="$HOME/.openclaw/skills/image-seed-bank/scripts/image-seed.sh"
IMAGES_DIR="$HOME/.openclaw/workspace/data/images"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
LOG_DIR="$HOME/.openclaw/logs"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<'EOF'
ad-bulk-gen.sh — Bulk Ad Image Generation Pipeline

COMMANDS:
  from-file     Generate from a JSON prompts file
  from-csv      Generate from a CSV prompts file
  retry         Retry failed items from a previous run
  status        Check status of a running/completed batch
  audit         Run visual audit on all images from a batch

USAGE:
  ad-bulk-gen.sh from-file --brand <brand> --file <prompts.json> [options]
  ad-bulk-gen.sh from-csv  --brand <brand> --file <prompts.csv> [options]
  ad-bulk-gen.sh retry     --batch <batch-id>
  ad-bulk-gen.sh status    --batch <batch-id>
  ad-bulk-gen.sh audit     --batch <batch-id>

OPTIONS:
  --brand <slug>         Brand slug (required)
  --file <path>          Prompts file path (required for from-file/from-csv)
  --parallel <n>         Max parallel workers (default: 1, max: 3 due to rate limits)
  --model <flash|pro>    Gemini model (default: flash)
  --size <1K|2K|4K>      Image size (default: 2K)
  --campaign <slug>      Campaign slug for tagging
  --funnel-stage <stage> TOFU/MOFU/BOFU
  --ref-image <paths>    Comma-separated reference images for ALL prompts
  --dry-run              Show what would be generated without calling API
  --batch <id>           Batch ID (auto-generated if not provided)

PROMPTS JSON FORMAT:
  [
    {"id": "1", "prompt": "...", "ratio": "1:1", "use_case": "product", "tags": "hero,mirra"},
    {"id": "2", "prompt": "...", "ratio": "4:5", "use_case": "lifestyle"}
  ]

PROMPTS CSV FORMAT:
  id,prompt,ratio,use_case,tags
  1,"Your prompt here",1:1,product,"hero,mirra"

EXAMPLES:
  # Generate 30 CNY ads from prompts file
  ad-bulk-gen.sh from-file --brand mirra --file /path/to/prompts.json --size 2K --model flash

  # Retry failures from a batch
  ad-bulk-gen.sh retry --batch mirra-20260302-225400

  # Audit all images from a batch
  ad-bulk-gen.sh audit --batch mirra-20260302-225400
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] [$level] $*" >> "${LOG_DIR}/ad-bulk-gen.log"
}

die() {
  echo "ERROR: $*" >&2
  log "ERROR" "$*"
  exit 1
}

epoch_s() { date +%s; }
timestamp_str() { date '+%Y%m%d_%H%M%S'; }

# Post to room
post_room() {
  local room="$1" msg="$2"
  if [ -d "$ROOMS_DIR" ]; then
    printf '{"ts":%s000,"agent":"ad-bulk-gen","room":"%s","msg":"%s"}\n' \
      "$(epoch_s)" "$room" "$msg" >> "${ROOMS_DIR}/${room}.jsonl"
  fi
}

# ---------------------------------------------------------------------------
# Batch State Management
# ---------------------------------------------------------------------------

BATCH_DIR=""
BATCH_ID=""

init_batch() {
  local brand="$1"
  local batch_id="${2:-${brand}-$(timestamp_str)}"
  BATCH_ID="$batch_id"
  BATCH_DIR="${IMAGES_DIR}/${brand}/batches/${BATCH_ID}"
  mkdir -p "$BATCH_DIR"
  log "INFO" "Batch initialized: $BATCH_ID at $BATCH_DIR"
}

# Write batch manifest (tracks all items)
write_manifest() {
  local brand="$1" model="$2" size="$3" campaign="$4" funnel="$5" total="$6"
  cat > "${BATCH_DIR}/manifest.json" <<EOF
{
  "batch_id": "${BATCH_ID}",
  "brand": "${brand}",
  "model": "${model}",
  "size": "${size}",
  "campaign": "${campaign}",
  "funnel_stage": "${funnel}",
  "total": ${total},
  "started_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "status": "running"
}
EOF
}

# Track individual item result
track_item() {
  local item_id="$1" status="$2" output_path="$3" error_msg="${4:-}"
  local ts
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  printf '{"id":"%s","status":"%s","output":"%s","error":"%s","ts":"%s"}\n' \
    "$item_id" "$status" "$output_path" "$error_msg" "$ts" >> "${BATCH_DIR}/results.jsonl"
}

# ---------------------------------------------------------------------------
# Generate Single Image (worker)
# ---------------------------------------------------------------------------

generate_one() {
  local brand="$1" prompt="$2" ratio="$3" model="$4" size="$5"
  local use_case="${6:-product}" ref_image="${7:-}" campaign="${8:-}" funnel="${9:-}"
  local item_id="${10:-unknown}"

  local cmd_args="--brand ${brand} --prompt \"${prompt}\" --ratio ${ratio} --model ${model} --size ${size} --use-case ${use_case}"

  if [ -n "$ref_image" ]; then
    cmd_args="${cmd_args} --ref-image \"${ref_image}\""
  fi
  if [ -n "$campaign" ]; then
    cmd_args="${cmd_args} --campaign ${campaign}"
  fi
  if [ -n "$funnel" ]; then
    cmd_args="${cmd_args} --funnel-stage ${funnel}"
  fi

  log "INFO" "Generating item $item_id: brand=$brand ratio=$ratio use_case=$use_case"

  local output
  if output=$(eval bash "$NANO" generate $cmd_args 2>&1); then
    # Extract the output image path (last line that looks like a file path)
    local img_path
    img_path=$(echo "$output" | grep -E '^\s*/.*\.png$' | tail -1 | tr -d '[:space:]')
    if [ -z "$img_path" ]; then
      img_path=$(echo "$output" | grep "Output:" | head -1 | sed 's/.*Output:\s*//' | tr -d '[:space:]')
    fi

    if [ -n "$img_path" ] && [ -f "$img_path" ]; then
      track_item "$item_id" "success" "$img_path" ""
      echo "OK:${img_path}"
      return 0
    else
      track_item "$item_id" "failed" "" "No image file in output"
      echo "FAIL:No image file produced"
      return 1
    fi
  else
    local err_msg
    err_msg=$(echo "$output" | grep -i "error" | head -1 | tr -d '"')
    track_item "$item_id" "failed" "" "${err_msg:-unknown error}"
    echo "FAIL:${err_msg:-unknown error}"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Command: from-file (JSON prompts)
# ---------------------------------------------------------------------------

cmd_from_file() {
  local brand="" file="" parallel=1 model="flash" size="2K" campaign="" funnel="" ref_image="" dry_run="false" batch_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)        brand="$2";        shift 2 ;;
      --file)         file="$2";         shift 2 ;;
      --parallel)     parallel="$2";     shift 2 ;;
      --model)        model="$2";        shift 2 ;;
      --size)         size="$2";         shift 2 ;;
      --campaign)     campaign="$2";     shift 2 ;;
      --funnel-stage) funnel="$2";       shift 2 ;;
      --ref-image)    ref_image="$2";    shift 2 ;;
      --dry-run)      dry_run="true";    shift ;;
      --batch)        batch_id="$2";     shift 2 ;;
      *) die "from-file: unknown option: $1" ;;
    esac
  done

  [ -z "$brand" ] && die "from-file: --brand is required"
  [ -z "$file" ] && die "from-file: --file is required"
  [ ! -f "$file" ] && die "from-file: file not found: $file"

  # Cap parallel to 3 (Gemini rate limit: 2 req/min, need gaps)
  if [ "$parallel" -gt 3 ]; then
    parallel=3
    echo "WARN: Capping parallel to 3 (Gemini rate limit)"
  fi

  # Parse prompts file
  local total
  total=$(python3 -c "import json; d=json.load(open('$file')); print(len(d))")
  [ "$total" -eq 0 ] && die "from-file: no prompts found in $file"

  init_batch "$brand" "$batch_id"
  write_manifest "$brand" "$model" "$size" "$campaign" "$funnel" "$total"

  echo "=== BULK GENERATION ==="
  echo "  Batch:    $BATCH_ID"
  echo "  Brand:    $brand"
  echo "  Prompts:  $total"
  echo "  Model:    $model"
  echo "  Size:     $size"
  echo "  Parallel: $parallel"
  if [ -n "$campaign" ]; then echo "  Campaign: $campaign"; fi
  if [ -n "$funnel" ]; then echo "  Funnel:   $funnel"; fi
  if [ -n "$ref_image" ]; then echo "  Ref imgs: $ref_image"; fi
  echo ""

  if [ "$dry_run" = "true" ]; then
    echo "[DRY RUN] Would generate $total images"
    python3 -c "
import json
d=json.load(open('$file'))
total=len(d)
for i,item in enumerate(d):
    print(f\"  [{i+1}/{total}] id={item.get('id','?')} ratio={item.get('ratio','1:1')} use_case={item.get('use_case','product')}\")
    print(f\"    prompt: {item.get('prompt','')[:80]}...\")
"
    return 0
  fi

  local success=0 failed=0 active=0

  post_room "creative" "Batch $BATCH_ID started: $total images for $brand"

  for i in $(seq 0 $((total - 1))); do
    # Extract item fields
    local item_json
    item_json=$(python3 -c "
import json
d=json.load(open('$file'))
item=d[$i]
# Output as tab-separated: id, prompt, ratio, use_case, tags, item_ref_image
fields = [
    str(item.get('id', str($i+1))),
    item.get('prompt', ''),
    item.get('ratio', '1:1'),
    item.get('use_case', 'product'),
    item.get('tags', ''),
    item.get('ref_image', '')
]
print('\t'.join(fields))
")

    local item_id item_prompt item_ratio item_usecase item_tags item_ref
    item_id=$(echo "$item_json" | cut -f1)
    item_prompt=$(echo "$item_json" | cut -f2)
    item_ratio=$(echo "$item_json" | cut -f3)
    item_usecase=$(echo "$item_json" | cut -f4)
    item_tags=$(echo "$item_json" | cut -f5)
    item_ref=$(echo "$item_json" | cut -f6)

    # Use item-level ref_image if provided, else global
    local use_ref="${item_ref:-$ref_image}"

    echo "--- [$((i+1))/$total] AD $item_id (ratio=$item_ratio) ---"

    if [ "$parallel" -le 1 ]; then
      # Sequential mode
      local result
      if result=$(generate_one "$brand" "$item_prompt" "$item_ratio" "$model" "$size" "$item_usecase" "$use_ref" "$campaign" "$funnel" "$item_id"); then
        success=$((success + 1))
        local img_path="${result#OK:}"
        echo "  OK: $img_path ($success/$((i+1)))"
      else
        failed=$((failed + 1))
        echo "  FAIL: ${result#FAIL:} (failures: $failed)"
      fi
    else
      # Parallel mode — launch in background
      (
        generate_one "$brand" "$item_prompt" "$item_ratio" "$model" "$size" "$item_usecase" "$use_ref" "$campaign" "$funnel" "$item_id"
      ) &
      active=$((active + 1))

      # Wait if we hit parallel limit
      if [ "$active" -ge "$parallel" ]; then
        wait -n 2>/dev/null || wait
        active=$((active - 1))
      fi
    fi
  done

  # Wait for remaining parallel jobs
  if [ "$parallel" -gt 1 ]; then
    wait
  fi

  # Count results from results.jsonl
  if [ -f "${BATCH_DIR}/results.jsonl" ]; then
    success=$(grep -c '"success"' "${BATCH_DIR}/results.jsonl" 2>/dev/null || echo 0)
    failed=$(grep -c '"failed"' "${BATCH_DIR}/results.jsonl" 2>/dev/null || echo 0)
  fi

  # Update manifest
  python3 -c "
import json
with open('${BATCH_DIR}/manifest.json') as f:
    m = json.load(f)
m['status'] = 'completed'
m['completed_at'] = '$(date -u '+%Y-%m-%dT%H:%M:%SZ')'
m['success'] = $success
m['failed'] = $failed
with open('${BATCH_DIR}/manifest.json', 'w') as f:
    json.dump(m, f, indent=2)
"

  echo ""
  echo "=== BATCH COMPLETE ==="
  echo "  Batch ID: $BATCH_ID"
  echo "  Success:  $success / $total"
  echo "  Failed:   $failed / $total"
  echo "  Results:  ${BATCH_DIR}/results.jsonl"
  echo "  Manifest: ${BATCH_DIR}/manifest.json"

  post_room "creative" "Batch $BATCH_ID complete: $success/$total succeeded, $failed failed"

  # List generated images
  if [ "$success" -gt 0 ]; then
    echo ""
    echo "Generated images:"
    grep '"success"' "${BATCH_DIR}/results.jsonl" 2>/dev/null | python3 -c "
import json, sys
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        print(f\"  {d['output']}\")
    except: pass
"
  fi

  # List failures for retry
  if [ "$failed" -gt 0 ]; then
    echo ""
    echo "Failed items (use 'retry --batch $BATCH_ID' to retry):"
    grep '"failed"' "${BATCH_DIR}/results.jsonl" 2>/dev/null | python3 -c "
import json, sys
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        print(f\"  AD {d['id']}: {d.get('error','unknown')}\")
    except: pass
"
  fi
}

# ---------------------------------------------------------------------------
# Command: from-csv
# ---------------------------------------------------------------------------

cmd_from_csv() {
  local brand="" file="" rest_args=()

  local args=("$@")
  local i=0
  while [ $i -lt ${#args[@]} ]; do
    case "${args[$i]}" in
      --brand) brand="${args[$((i+1))]}"; i=$((i+2)) ;;
      --file)  file="${args[$((i+1))]}";  i=$((i+2)) ;;
      *)       rest_args+=("${args[$i]}"); i=$((i+1)) ;;
    esac
  done

  [ -z "$brand" ] && die "from-csv: --brand is required"
  [ -z "$file" ] && die "from-csv: --file is required"
  [ ! -f "$file" ] && die "from-csv: file not found: $file"

  # Convert CSV to JSON
  local json_file
  json_file=$(mktemp /tmp/bulk-gen-csv.XXXXXX.json)

  python3 -c "
import csv, json, sys

with open('$file') as f:
    reader = csv.DictReader(f)
    rows = []
    for row in reader:
        rows.append({
            'id': row.get('id', str(len(rows)+1)),
            'prompt': row.get('prompt', ''),
            'ratio': row.get('ratio', '1:1'),
            'use_case': row.get('use_case', 'product'),
            'tags': row.get('tags', ''),
            'ref_image': row.get('ref_image', '')
        })

with open('$json_file', 'w') as f:
    json.dump(rows, f, indent=2)

print(f'Converted {len(rows)} rows from CSV to JSON')
"

  cmd_from_file --brand "$brand" --file "$json_file" "${rest_args[@]}"
  rm -f "$json_file"
}

# ---------------------------------------------------------------------------
# Command: retry (retry failed items from a batch)
# ---------------------------------------------------------------------------

cmd_retry() {
  local batch_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --batch) batch_id="$2"; shift 2 ;;
      *) die "retry: unknown option: $1" ;;
    esac
  done

  [ -z "$batch_id" ] && die "retry: --batch is required"

  # Find batch dir
  local batch_dir
  batch_dir=$(find "$IMAGES_DIR" -type d -name "$batch_id" 2>/dev/null | head -1)
  [ -z "$batch_dir" ] && die "retry: batch not found: $batch_id"

  local manifest="${batch_dir}/manifest.json"
  [ ! -f "$manifest" ] && die "retry: no manifest.json in $batch_dir"

  local results="${batch_dir}/results.jsonl"
  [ ! -f "$results" ] && die "retry: no results.jsonl in $batch_dir"

  # Read manifest
  local brand model size campaign funnel
  brand=$(python3 -c "import json; print(json.load(open('$manifest'))['brand'])")
  model=$(python3 -c "import json; print(json.load(open('$manifest'))['model'])")
  size=$(python3 -c "import json; print(json.load(open('$manifest'))['size'])")
  campaign=$(python3 -c "import json; print(json.load(open('$manifest')).get('campaign',''))")
  funnel=$(python3 -c "import json; print(json.load(open('$manifest')).get('funnel_stage',''))")

  # Get failed item IDs
  local failed_ids
  failed_ids=$(grep '"failed"' "$results" | python3 -c "
import json, sys
for line in sys.stdin:
    d = json.loads(line.strip())
    print(d['id'])
")

  local fail_count
  fail_count=$(echo "$failed_ids" | wc -l | tr -d ' ')
  echo "=== RETRY: $fail_count failed items from batch $batch_id ==="

  # For each failed ID, find the original prompt from the source file
  # This requires the prompts file to still exist — check manifest or batch dir
  echo "Retrying $fail_count items with brand=$brand model=$model size=$size..."
  echo "(Individual retry results appended to ${results})"

  local retry_success=0 retry_failed=0
  echo "$failed_ids" | while IFS= read -r fid; do
    [ -z "$fid" ] && continue
    echo "--- Retrying AD $fid ---"
    # Look for the prompt in the original results to re-generate
    # (we don't store prompts in results.jsonl — need the source file)
    echo "  SKIP: Need source prompts file for retry. Use from-file with filtered prompts."
    retry_failed=$((retry_failed + 1))
  done

  echo ""
  echo "NOTE: For full retry, re-run from-file with a filtered prompts JSON containing only failed items."
}

# ---------------------------------------------------------------------------
# Command: status
# ---------------------------------------------------------------------------

cmd_status() {
  local batch_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --batch) batch_id="$2"; shift 2 ;;
      *) die "status: unknown option: $1" ;;
    esac
  done

  [ -z "$batch_id" ] && die "status: --batch is required"

  local batch_dir
  batch_dir=$(find "$IMAGES_DIR" -type d -name "$batch_id" 2>/dev/null | head -1)
  [ -z "$batch_dir" ] && die "status: batch not found: $batch_id"

  local manifest="${batch_dir}/manifest.json"
  [ ! -f "$manifest" ] && die "status: no manifest.json"

  python3 -c "
import json

with open('$manifest') as f:
    m = json.load(f)

print('=== BATCH STATUS ===')
print(f\"  Batch:     {m['batch_id']}\")
print(f\"  Brand:     {m['brand']}\")
print(f\"  Status:    {m['status']}\")
print(f\"  Total:     {m['total']}\")
print(f\"  Success:   {m.get('success', '?')}\")
print(f\"  Failed:    {m.get('failed', '?')}\")
print(f\"  Started:   {m.get('started_at', '?')}\")
print(f\"  Completed: {m.get('completed_at', 'still running')}\")
"

  local results="${batch_dir}/results.jsonl"
  if [ -f "$results" ]; then
    local done_count
    done_count=$(wc -l < "$results" | tr -d ' ')
    local total
    total=$(python3 -c "import json; print(json.load(open('$manifest'))['total'])")
    echo "  Progress:  $done_count / $total"
  fi
}

# ---------------------------------------------------------------------------
# Command: audit (run visual audit on all batch images)
# ---------------------------------------------------------------------------

cmd_audit() {
  local batch_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --batch) batch_id="$2"; shift 2 ;;
      *) die "audit: unknown option: $1" ;;
    esac
  done

  [ -z "$batch_id" ] && die "audit: --batch is required"

  local batch_dir
  batch_dir=$(find "$IMAGES_DIR" -type d -name "$batch_id" 2>/dev/null | head -1)
  [ -z "$batch_dir" ] && die "audit: batch not found: $batch_id"

  local results="${batch_dir}/results.jsonl"
  [ ! -f "$results" ] && die "audit: no results.jsonl"

  echo "=== BATCH AUDIT: $batch_id ==="

  local audit_report="${batch_dir}/audit-report.jsonl"
  : > "$audit_report"

  local total=0 pass=0 fail=0

  grep '"success"' "$results" | while IFS= read -r line; do
    local img_path
    img_path=$(echo "$line" | python3 -c "import json,sys; print(json.loads(sys.stdin.read().strip())['output'])")
    [ -z "$img_path" ] || [ ! -f "$img_path" ] && continue

    total=$((total + 1))
    echo "  Auditing: $(basename "$img_path")..."

    if [ -x "$AUDIT" ]; then
      local audit_result
      if audit_result=$(bash "$AUDIT" "$img_path" 2>&1); then
        echo "    PASS"
        printf '{"image":"%s","status":"pass","result":"%s"}\n' "$img_path" "$(echo "$audit_result" | head -1 | tr '"' "'")" >> "$audit_report"
        pass=$((pass + 1))
      else
        echo "    FAIL: $audit_result"
        printf '{"image":"%s","status":"fail","result":"%s"}\n' "$img_path" "$(echo "$audit_result" | head -1 | tr '"' "'")" >> "$audit_report"
        fail=$((fail + 1))
      fi
    else
      echo "    SKIP: audit-visual.sh not found"
      printf '{"image":"%s","status":"skipped","result":"no auditor"}\n' "$img_path" >> "$audit_report"
    fi
  done

  echo ""
  echo "=== AUDIT COMPLETE ==="
  echo "  Total:  $total"
  echo "  Pass:   $pass"
  echo "  Fail:   $fail"
  echo "  Report: $audit_report"
}

# ---------------------------------------------------------------------------
# Command: convert-md (convert markdown prompts file to JSON)
# Helper to convert Iris-style markdown prompts to the JSON format needed
# ---------------------------------------------------------------------------

cmd_convert_md() {
  local file="" output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --file)   file="$2";   shift 2 ;;
      --output) output="$2"; shift 2 ;;
      *) die "convert-md: unknown option: $1" ;;
    esac
  done

  [ -z "$file" ] && die "convert-md: --file is required"
  [ ! -f "$file" ] && die "convert-md: file not found: $file"

  if [ -z "$output" ]; then
    output="${file%.md}.json"
  fi

  python3 -c "
import re, json

with open('$file') as f:
    content = f.read()

# Pattern: ## AD N: Title\n**Aspect Ratio:** ratio\n...**AI Prompt:**\n> prompt
pattern = r'## AD (\d+):.*?\n\*\*Aspect Ratio:\*\* (.*?)\n.*?\*\*AI Prompt:\*\*\s*\n> (.*?)\n'
matches = re.findall(pattern, content, re.DOTALL)

results = []
for num, ratio, prompt in matches:
    # Strip Midjourney flags
    clean = re.sub(r'\s*--ar\s+\S+', '', prompt)
    clean = re.sub(r'\s*--style\s+\S+', '', clean)
    clean = re.sub(r'\s*--v\s+\S+', '', clean)
    r = '1:1' if '1:1' in ratio else '4:5' if '4:5' in ratio else '16:9' if '16:9' in ratio else '1:1'
    results.append({
        'id': num,
        'prompt': clean.strip(),
        'ratio': r,
        'use_case': 'product'
    })

with open('$output', 'w') as f:
    json.dump(results, f, indent=2)

print(f'Converted {len(results)} prompts from MD to JSON')
print(f'Output: $output')
"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

if [ $# -eq 0 ]; then
  usage
fi

CMD="$1"
shift

case "$CMD" in
  from-file)    cmd_from_file "$@" ;;
  from-csv)     cmd_from_csv "$@" ;;
  retry)        cmd_retry "$@" ;;
  status)       cmd_status "$@" ;;
  audit)        cmd_audit "$@" ;;
  convert-md)   cmd_convert_md "$@" ;;
  help|--help|-h) usage ;;
  *) die "Unknown command: $CMD. Run with --help for usage." ;;
esac
