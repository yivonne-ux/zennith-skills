#!/usr/bin/env bash
# creative-studio — GAIA Creative Studio orchestrator
# Studio = control room. ComfyUI = engine. Library = truth layer.
#
# Usage:
#   studio.sh launch  --brand <brand> --character <name> [--engine comfyui|nanobanana]
#   studio.sh store   --run <run-id> --stage <1|2|3|4> --files <file1,file2,...> [--shot-type <type>]
#   studio.sh review  --run <run-id>
#   studio.sh status  [--brand <brand>]
#   studio.sh approve --run <run-id> --outputs <idx1,idx2,...>
#   studio.sh export  --run <run-id> --format pack

set -euo pipefail

STUDIO_ROOT="${HOME}/.openclaw/output/creative-studio"
SKILLS="${HOME}/.openclaw/skills"
REF_LIB="${SKILLS}/ref-library/scripts/ref-library.sh"
VIS_REG="${SKILLS}/visual-registry/scripts/visual-registry.sh"
TAXONOMY="${SKILLS}/creative-taxonomy/scripts/classify-asset.sh"
WORKFLOW_DIR="${SKILLS}/creative-studio/workflows"

# --- Helpers ---

gen_run_id() {
  local brand="$1" char="$2"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  echo "run-${brand}-${char}-${ts}"
}

run_dir() {
  local run_id="$1"
  # Search for run directory across all brands (handles hyphenated brand names)
  local found
  found=$(find "$STUDIO_ROOT" -maxdepth 2 -name "$run_id" -type d 2>/dev/null | head -1)
  if [[ -n "$found" ]]; then
    echo "$found"
  else
    # Fallback: try to find run.json
    echo "${STUDIO_ROOT}/unknown/${run_id}"
  fi
}

load_run() {
  local run_id="$1"
  local dir
  dir=$(run_dir "$run_id")
  if [[ ! -f "${dir}/run.json" ]]; then
    echo "ERROR: Run ${run_id} not found at ${dir}/run.json" >&2
    exit 1
  fi
  echo "${dir}"
}

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# --- Commands ---

cmd_launch() {
  local brand="" character="" engine="comfyui"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      --character) character="$2"; shift 2 ;;
      --engine) engine="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$brand" || -z "$character" ]]; then
    echo "ERROR: --brand and --character required" >&2
    exit 1
  fi

  # Validate brand exists
  local brand_dir="${HOME}/.openclaw/brands/${brand}"
  if [[ ! -d "$brand_dir" ]]; then
    echo "ERROR: Brand '${brand}' not found at ${brand_dir}" >&2
    exit 1
  fi

  local run_id
  run_id=$(gen_run_id "$brand" "$character")
  local dir="${STUDIO_ROOT}/${brand}/${run_id}"

  mkdir -p "${dir}"/{refs,stage-1,stage-2,stage-3,stage-4}

  # Query existing refs from ref-library
  local ref_count=0
  local ref_summary=""
  if [[ -x "$REF_LIB" ]]; then
    local char_refs
    char_refs=$(bash "$REF_LIB" query --brand "$brand" --type character 2>/dev/null || echo "[]")
    local style_refs
    style_refs=$(bash "$REF_LIB" query --brand "$brand" --type style 2>/dev/null || echo "[]")
    ref_summary="character_refs: ${char_refs}\nstyle_refs: ${style_refs}"
    ref_count=$(echo "$char_refs" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo 0)
  fi

  # Build run.json
  python3 -c "
import json, sys
run = {
    'run_id': '${run_id}',
    'brand': '${brand}',
    'character_name': '${character}',
    'workflow_name': 'comfyui-character-master-v1',
    'engine': '${engine}',
    'state': 'launched',
    'current_stage': 0,
    'created_at': '$(now_iso)',
    'updated_at': '$(now_iso)',
    'reference_stack': {
        'face': None,
        'body': None,
        'vibe': None,
        'use_case': None,
        'optional': {}
    },
    'stages': {
        '1': {'name': 'angle_coverage', 'state': 'pending', 'outputs': []},
        '2': {'name': 'consistency_expansion', 'state': 'pending', 'outputs': []},
        '3': {'name': 'realism_refinement', 'state': 'pending', 'outputs': []},
        '4': {'name': 'approval_pack', 'state': 'pending', 'outputs': []}
    },
    'proof_of_done': {
        'hero_portrait': False,
        'full_body': False,
        'angle_set': False,
        'realism_refined': False,
        'metadata_complete': False,
        'pack_exportable': False
    },
    'library_refs_found': ${ref_count}
}
json.dump(run, sys.stdout, indent=2)
" > "${dir}/run.json"

  echo "LAUNCHED: ${run_id}"
  echo "  Dir: ${dir}"
  echo "  Brand: ${brand}"
  echo "  Character: ${character}"
  echo "  Engine: ${engine}"
  echo "  Library refs found: ${ref_count}"
  echo ""
  echo "Next steps:"
  echo "  1. Add references:  studio.sh store --run ${run_id} --stage 0 --files face.png --shot-type face_ref"
  echo "  2. Run ComfyUI Stage 1 (angle/coverage) with your references"
  echo "  3. Store outputs:   studio.sh store --run ${run_id} --stage 1 --files output1.png,output2.png --shot-type portrait_front"
}

cmd_store() {
  local run_id="" stage="" files="" shot_type="" template=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run) run_id="$2"; shift 2 ;;
      --stage) stage="$2"; shift 2 ;;
      --files) files="$2"; shift 2 ;;
      --shot-type) shot_type="$2"; shift 2 ;;
      --template) template="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$run_id" || -z "$stage" || -z "$files" ]]; then
    echo "ERROR: --run, --stage, and --files required" >&2
    exit 1
  fi

  local dir
  dir=$(load_run "$run_id")
  local stage_dir="${dir}/stage-${stage}"

  if [[ "$stage" == "0" ]]; then
    stage_dir="${dir}/refs"
  fi

  mkdir -p "$stage_dir"

  # Copy files into stage dir
  local count=0
  IFS=',' read -ra FILE_LIST <<< "$files"
  for f in "${FILE_LIST[@]}"; do
    if [[ -f "$f" ]]; then
      cp "$f" "$stage_dir/"
      count=$((count + 1))
    else
      echo "WARN: File not found: $f" >&2
    fi
  done

  # Update run.json with output metadata
  python3 -c "
import json, os, sys

with open('${dir}/run.json') as f:
    run = json.load(f)

stage = '${stage}'
shot_type = '${shot_type}' or 'unknown'
template = '${template}' or ''

if stage == '0':
    # Reference file
    run['reference_stack']['face'] = run['reference_stack'].get('face') or shot_type
else:
    outputs = run['stages'].get(stage, {}).get('outputs', [])
    files_added = []
    for fname in '${files}'.split(','):
        basename = os.path.basename(fname.strip())
        entry = {
            'file': basename,
            'shot_type': shot_type,
            'approved': False,
            'date_added': '$(now_iso)',
            'source_template': template
        }
        outputs.append(entry)
        files_added.append(basename)

    if stage in run['stages']:
        run['stages'][stage]['outputs'] = outputs
        run['stages'][stage]['state'] = 'in_progress'

run['updated_at'] = '$(now_iso)'

with open('${dir}/run.json', 'w') as f:
    json.dump(run, f, indent=2)

print(f'Stored {len(files_added) if stage != \"0\" else 1} file(s) in stage-{stage}')
" 2>/dev/null || echo "Stored ${count} file(s) in stage-${stage}"

  echo "  Run: ${run_id}"
  echo "  Stage: ${stage}"
  echo "  Shot type: ${shot_type:-unset}"
}

cmd_review() {
  local run_id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run) run_id="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$run_id" ]]; then
    echo "ERROR: --run required" >&2
    exit 1
  fi

  local dir
  dir=$(load_run "$run_id")

  python3 -c "
import json, os, glob

with open('${dir}/run.json') as f:
    run = json.load(f)

print(f'=== Review: {run[\"run_id\"]} ===')
print(f'Brand: {run[\"brand\"]}  Character: {run[\"character_name\"]}  Engine: {run[\"engine\"]}')
print(f'State: {run[\"state\"]}  Created: {run[\"created_at\"]}')
print()

# Check each stage
total_outputs = 0
approved_outputs = 0
for sid in ['1','2','3','4']:
    stage = run['stages'].get(sid, {})
    outs = stage.get('outputs', [])
    approved = [o for o in outs if o.get('approved')]
    state = stage.get('state', 'pending')
    total_outputs += len(outs)
    approved_outputs += len(approved)
    print(f'Stage {sid} ({stage.get(\"name\",\"?\")}): {state} — {len(outs)} outputs, {len(approved)} approved')
    for o in outs:
        mark = '✓' if o.get('approved') else '·'
        print(f'  {mark} {o[\"file\"]} [{o[\"shot_type\"]}]')

# Check proof of done
print()
print('--- Proof of Done ---')
pod = run.get('proof_of_done', {})

# Recalculate from actual outputs
s1 = run['stages'].get('1', {}).get('outputs', [])
s3 = run['stages'].get('3', {}).get('outputs', [])

has_hero = any(o.get('approved') and o.get('shot_type') in ('portrait_front','realism_refined') for o in s1 + s3)
has_full = any(o.get('approved') and o.get('shot_type') == 'full_body_front' for o in s1)
has_angles = len([o for o in s1 if o.get('approved')]) >= 3
has_refined = any(o.get('approved') and o.get('shot_type') == 'realism_refined' for o in s3)
has_meta = total_outputs > 0 and all(o.get('shot_type') != 'unknown' for s in run['stages'].values() for o in s.get('outputs',[]))

checks = [
    ('Hero portrait (approved)', has_hero),
    ('Full-body image (approved)', has_full),
    ('Angle/coverage set (3+ approved)', has_angles),
    ('Realism-refined master', has_refined),
    ('Metadata complete', has_meta),
    ('Pack exportable', os.path.exists('${dir}/stage-4') and len(os.listdir('${dir}/stage-4')) > 0),
]

all_pass = True
for label, ok in checks:
    mark = '✓' if ok else '✗'
    print(f'  {mark} {label}')
    if not ok:
        all_pass = False

print()
if all_pass:
    print('RESULT: COMPLETE — all proof-of-done criteria met')
else:
    print('RESULT: INCOMPLETE — see missing criteria above')

# Write review.json
review = {
    'run_id': run['run_id'],
    'reviewed_at': '$(now_iso)',
    'total_outputs': total_outputs,
    'approved_outputs': approved_outputs,
    'proof_of_done': {c[0]: c[1] for c in checks},
    'complete': all_pass
}
with open('${dir}/review.json', 'w') as f:
    json.dump(review, f, indent=2)
"
}

cmd_approve() {
  local run_id="" outputs=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run) run_id="$2"; shift 2 ;;
      --outputs) outputs="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$run_id" || -z "$outputs" ]]; then
    echo "ERROR: --run and --outputs required" >&2
    exit 1
  fi

  local dir
  dir=$(load_run "$run_id")

  python3 -c "
import json

with open('${dir}/run.json') as f:
    run = json.load(f)

indices = [int(i.strip()) for i in '${outputs}'.split(',')]
approved_files = []

for sid in ['1','2','3','4']:
    outs = run['stages'].get(sid, {}).get('outputs', [])
    for i, o in enumerate(outs):
        # Global output index
        pass

# Flatten all outputs with stage prefix for indexing
flat = []
for sid in ['1','2','3','4']:
    for o in run['stages'].get(sid, {}).get('outputs', []):
        flat.append((sid, o))

for idx in indices:
    if 0 <= idx < len(flat):
        sid, o = flat[idx]
        o['approved'] = True
        o['approved_at'] = '$(now_iso)'
        approved_files.append(f'{o[\"file\"]} (stage {sid})')

# Rebuild stages
cursor = 0
for sid in ['1','2','3','4']:
    outs = run['stages'][sid].get('outputs', [])
    for i in range(len(outs)):
        run['stages'][sid]['outputs'][i] = flat[cursor][1]
        cursor += 1

run['updated_at'] = '$(now_iso)'

with open('${dir}/run.json', 'w') as f:
    json.dump(run, f, indent=2)

print(f'Approved {len(approved_files)} outputs:')
for af in approved_files:
    print(f'  ✓ {af}')
"

  # After approval, register in visual-registry if available
  echo ""
  echo "Next: run 'studio.sh review --run ${run_id}' to check proof-of-done"
}

cmd_status() {
  local brand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ ! -d "$STUDIO_ROOT" ]]; then
    echo "No runs found."
    return
  fi

  echo "=== Creative Studio Runs ==="
  echo ""

  local found=0
  for brand_dir in "${STUDIO_ROOT}"/*/; do
    [[ -d "$brand_dir" ]] || continue
    local b
    b=$(basename "$brand_dir")
    if [[ -n "$brand" && "$b" != "$brand" ]]; then continue; fi

    for run_dir in "${brand_dir}"run-*/; do
      [[ -f "${run_dir}/run.json" ]] || continue
      found=$((found + 1))

      python3 -c "
import json
with open('${run_dir}/run.json') as f:
    r = json.load(f)
total = sum(len(s.get('outputs',[])) for s in r['stages'].values())
approved = sum(len([o for o in s.get('outputs',[]) if o.get('approved')]) for s in r['stages'].values())
print(f'{r[\"run_id\"]}  {r[\"state\"]}  {r[\"character_name\"]}@{r[\"brand\"]}  {approved}/{total} approved  {r[\"created_at\"][:10]}')
"
    done
  done

  if [[ $found -eq 0 ]]; then
    echo "No runs found."
  fi
}

cmd_export() {
  local run_id="" format="pack"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run) run_id="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$run_id" ]]; then
    echo "ERROR: --run required" >&2
    exit 1
  fi

  local dir
  dir=$(load_run "$run_id")

  # Collect approved outputs into stage-4
  python3 -c "
import json, os, shutil

with open('${dir}/run.json') as f:
    run = json.load(f)

stage4 = '${dir}/stage-4'
os.makedirs(stage4, exist_ok=True)

pack_files = []
for sid in ['1','2','3']:
    stage_dir = '${dir}/stage-' + sid
    for o in run['stages'].get(sid, {}).get('outputs', []):
        if o.get('approved'):
            src = os.path.join(stage_dir, o['file'])
            if os.path.exists(src):
                dst = os.path.join(stage4, f'{o[\"shot_type\"]}-{o[\"file\"]}')
                shutil.copy2(src, dst)
                pack_files.append(dst)

# Write pack manifest
pack = {
    'run_id': run['run_id'],
    'brand': run['brand'],
    'character_name': run['character_name'],
    'workflow_name': run['workflow_name'],
    'exported_at': '$(now_iso)',
    'files': [os.path.basename(f) for f in pack_files],
    'downstream': {
        'video_pipeline': {
            'workflow': 'ugc-intro-video',
            'ready': len(pack_files) > 0
        }
    }
}
with open(os.path.join(stage4, 'pack.json'), 'w') as f:
    json.dump(pack, f, indent=2)

print(f'Exported {len(pack_files)} approved files to {stage4}/')
print(f'Pack manifest: {stage4}/pack.json')
if pack_files:
    print('Ready for video pipeline: YES')
else:
    print('Ready for video pipeline: NO (no approved outputs)')
"
}

cmd_generate() {
  local run_id="" prompt="" ratio="3:4" shot_type="portrait_front" engine="nanobanana"
  local comfyui_workflow=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run) run_id="$2"; shift 2 ;;
      --prompt) prompt="$2"; shift 2 ;;
      --ratio) ratio="$2"; shift 2 ;;
      --shot-type) shot_type="$2"; shift 2 ;;
      --engine) engine="$2"; shift 2 ;;
      --workflow) comfyui_workflow="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$run_id" || -z "$prompt" ]]; then
    echo "ERROR: --run and --prompt required" >&2
    exit 1
  fi

  local dir
  dir=$(load_run "$run_id")

  # Read run.json to get brand and check for locked face reference
  local brand character face_ref
  brand=$(python3 -c "import json; r=json.load(open('${dir}/run.json')); print(r['brand'])")
  character=$(python3 -c "import json; r=json.load(open('${dir}/run.json')); print(r['character_name'])")
  face_ref=$(python3 -c "import json; r=json.load(open('${dir}/run.json')); print(r['reference_stack'].get('face') or '')")

  # Check for locked face in refs directory
  local locked_face=""
  if [[ -n "$face_ref" && -f "$face_ref" ]]; then
    locked_face="$face_ref"
  else
    # Look for any face ref in the refs directory
    local ref_files
    ref_files=$(find "${dir}/refs" -name "*face*" -o -name "*locked*" -o -name "*portrait*" 2>/dev/null | head -1)
    if [[ -n "$ref_files" ]]; then
      locked_face="$ref_files"
    fi
  fi

  # Also check the character directory for locked faces
  local char_dir="${HOME}/.openclaw/workspace/data/characters/${brand}"
  if [[ -z "$locked_face" ]]; then
    local char_locked
    char_locked=$(find "$char_dir" -name "*locked*face*" -o -name "*locked*v*" 2>/dev/null | head -1)
    if [[ -n "$char_locked" ]]; then
      locked_face="$char_locked"
    fi
  fi

  # ENFORCE: If stage 1 has any approved outputs, ref-image is REQUIRED
  local stage1_approved
  stage1_approved=$(python3 -c "
import json
r = json.load(open('${dir}/run.json'))
approved = [o for o in r['stages'].get('1',{}).get('outputs',[]) if o.get('approved')]
print(len(approved))
" 2>/dev/null || echo "0")

  if [[ "$stage1_approved" -gt 0 && -z "$locked_face" ]]; then
    echo "ERROR: Face is approved but no locked reference found!" >&2
    echo "  You MUST lock a face reference before generating more poses." >&2
    echo "  Use: studio.sh store --run ${run_id} --stage 0 --files /path/to/locked-face.png --shot-type face_ref" >&2
    exit 1
  fi

  echo "Generating via ${engine}..."
  echo "  Run: ${run_id}"
  echo "  Brand: ${brand}"
  echo "  Character: ${character}"
  echo "  Shot type: ${shot_type}"
  echo "  Ratio: ${ratio}"
  echo "  Engine: ${engine}"
  echo "  Ref image: ${locked_face:-NONE}"
  echo ""

  local output="" out_file=""
  local COMFYUI_API="${SKILLS}/creative-studio/scripts/comfyui-api.sh"

  if [[ "$engine" == "comfyui" ]]; then
    # --- ComfyUI Cloud Engine ---
    if [[ -z "$comfyui_workflow" ]]; then
      echo "ERROR: --workflow <file.json> required for ComfyUI engine" >&2
      echo "  Provide a ComfyUI API-format workflow JSON file." >&2
      echo "  Save from ComfyUI Cloud UI via 'Save (API Format)'." >&2
      exit 1
    fi

    if [[ ! -f "$comfyui_workflow" ]]; then
      # Check in workflows directory
      if [[ -f "${WORKFLOW_DIR}/${comfyui_workflow}" ]]; then
        comfyui_workflow="${WORKFLOW_DIR}/${comfyui_workflow}"
      else
        echo "ERROR: Workflow file not found: $comfyui_workflow" >&2
        exit 1
      fi
    fi

    # Load env for API key
    for envfile in "${HOME}/.openclaw/.env" "${SKILLS}/creative-studio/.env"; do
      [[ -f "$envfile" ]] && export $(grep -E '^COMFYUI_API_KEY=' "$envfile" | head -1) 2>/dev/null || true
    done

    echo "Submitting to ComfyUI Cloud..."
    output=$(bash "$COMFYUI_API" submit --workflow "$comfyui_workflow" --poll --timeout 600 2>&1)
    echo "$output"

    local job_id
    job_id=$(echo "$output" | grep "JOB_ID=" | cut -d= -f2)

    if [[ -n "$job_id" ]] && echo "$output" | grep -q "STATUS=completed"; then
      # Download outputs
      local current_stage
      current_stage=$(python3 -c "import json; r=json.load(open('${dir}/run.json')); print(r.get('current_stage',1))" 2>/dev/null || echo "1")
      if [[ "$current_stage" -eq 0 ]]; then current_stage=1; fi

      local stage_dir="${dir}/stage-${current_stage}"
      mkdir -p "$stage_dir"

      echo "Downloading outputs to ${stage_dir}..."
      bash "$COMFYUI_API" download --job "$job_id" --output-dir "$stage_dir"

      # Auto-store all downloaded files
      local downloaded_files
      downloaded_files=$(find "$stage_dir" -maxdepth 1 -name "*.png" -o -name "*.jpg" -o -name "*.webp" 2>/dev/null | tr '\n' ',')
      if [[ -n "$downloaded_files" ]]; then
        downloaded_files="${downloaded_files%,}"  # trim trailing comma
        cmd_store --run "$run_id" --stage "$current_stage" --files "$downloaded_files" --shot-type "$shot_type"
        echo ""
        echo "Auto-stored ComfyUI outputs in stage ${current_stage}."
      fi
    else
      echo "WARNING: ComfyUI job did not complete successfully." >&2
    fi

  else
    # --- NanoBanana Engine (default) ---
    local nb_cmd="nanobanana-gen.sh generate --brand ${brand} --use-case character --model pro --size 2K --ratio ${ratio}"

    if [[ -n "$locked_face" ]]; then
      nb_cmd="${nb_cmd} --ref-image ${locked_face}"
      echo "Using locked face reference: ${locked_face}"
    else
      echo "WARNING: No locked face reference. First generation — face approval needed before more poses."
    fi

    nb_cmd="${nb_cmd} --prompt '${prompt}'"

    output=$(eval "$nb_cmd" 2>&1)
    echo "$output"

    out_file=$(echo "$output" | grep "Output:" | sed 's/.*Output:[[:space:]]*//')

    if [[ -n "$out_file" && -f "$out_file" ]]; then
      local current_stage
      current_stage=$(python3 -c "import json; r=json.load(open('${dir}/run.json')); print(r.get('current_stage',1))" 2>/dev/null || echo "1")
      if [[ "$current_stage" -eq 0 ]]; then current_stage=1; fi

      cmd_store --run "$run_id" --stage "$current_stage" --files "$out_file" --shot-type "$shot_type"
      echo ""
      echo "Auto-stored in stage ${current_stage}. Review with: studio.sh review --run ${run_id}"
    else
      echo "WARNING: Could not detect output file. Store manually with studio.sh store"
    fi
  fi
}

# --- Main ---

case "${1:-}" in
  launch)  shift; cmd_launch "$@" ;;
  store)   shift; cmd_store "$@" ;;
  review)  shift; cmd_review "$@" ;;
  approve) shift; cmd_approve "$@" ;;
  status)  shift; cmd_status "$@" ;;
  export)  shift; cmd_export "$@" ;;
  generate) shift; cmd_generate "$@" ;;
  *)
    echo "GAIA Creative Studio"
    echo ""
    echo "Usage: studio.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  launch   — Start a new character master workflow"
    echo "  generate — Generate image via NanoBanana (enforces ref-image after face lock)"
    echo "  store    — Store outputs from a generation stage"
    echo "  review   — Review run against proof-of-done criteria"
    echo "  approve  — Mark outputs as approved"
    echo "  status   — Show all runs"
    echo "  export   — Export approved pack for downstream pipeline"
    echo ""
    echo "Workflow: comfyui-character-master-v1"
    echo "  Stage 1: Angle/coverage generation"
    echo "  Stage 2: Consistency expansion"
    echo "  Stage 3: Realism refinement"
    echo "  Stage 4: Approval pack assembly"
    ;;
esac
