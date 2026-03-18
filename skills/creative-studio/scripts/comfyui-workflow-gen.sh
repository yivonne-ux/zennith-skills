#!/usr/bin/env bash
# comfyui-workflow-gen.sh — Generate customized ComfyUI workflow JSONs from templates
# Takes a template + overrides → produces ready-to-submit API-format JSON

set -euo pipefail

WORKFLOW_DIR="${HOME}/.openclaw/skills/creative-studio/workflows"

usage() {
  cat <<'EOF'
comfyui-workflow-gen.sh — Customize ComfyUI workflow templates

USAGE:
  comfyui-workflow-gen.sh --template <name> [options] --output <file.json>

TEMPLATES:
  flux-kontext-character-v1       Flux Kontext face-locked character gen (API format, recommended)
  flux-ipadapter-character-v1     Flux + IP-Adapter (UI format, legacy)

OPTIONS:
  --template    Template name (without .json) or full path
  --prompt      Override the positive prompt text
  --ref-image   Reference image filename (must be uploaded to ComfyUI Cloud)
  --seed        Random seed (default: random)
  --steps       Sampling steps (default: 50)
  --guidance    Guidance scale (default: 3.5)
  --denoise     Denoise strength 0.0-1.0 (default: 0.70, Kontext only)
  --width       Output width (default: 1024)
  --height      Output height (default: 1024)
  --ip-weight   IP-Adapter weight 0.0-1.0 (default: 0.85, legacy only)
  --prefix      Output filename prefix
  --output      Path to write the customized workflow JSON

EXAMPLES:
  comfyui-workflow-gen.sh \
    --template flux-kontext-character-v1 \
    --prompt "Full body shot of Luna Solaris standing in natural light..." \
    --ref-image 8b12b13c.png \
    --seed 42 \
    --output /tmp/luna-fullbody.json
EOF
}

template=""
prompt=""
ref_image=""
seed=$RANDOM
steps=50
guidance=3.5
denoise=0.70
width=1024
height=1024
ip_weight=0.85
prefix="character"
output_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template) template="$2"; shift 2 ;;
    --prompt) prompt="$2"; shift 2 ;;
    --ref-image) ref_image="$2"; shift 2 ;;
    --seed) seed="$2"; shift 2 ;;
    --steps) steps="$2"; shift 2 ;;
    --guidance) guidance="$2"; shift 2 ;;
    --denoise) denoise="$2"; shift 2 ;;
    --width) width="$2"; shift 2 ;;
    --height) height="$2"; shift 2 ;;
    --ip-weight) ip_weight="$2"; shift 2 ;;
    --prefix) prefix="$2"; shift 2 ;;
    --output) output_file="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$template" || -z "$output_file" ]]; then
  echo "ERROR: --template and --output required" >&2
  usage
  exit 1
fi

# Resolve template path
template_file="$template"
if [[ ! -f "$template_file" ]]; then
  template_file="${WORKFLOW_DIR}/${template}.json"
fi
if [[ ! -f "$template_file" ]]; then
  echo "ERROR: Template not found: $template" >&2
  echo "Available templates:" >&2
  ls "${WORKFLOW_DIR}"/*.json 2>/dev/null | xargs -I{} basename {} .json >&2
  exit 1
fi

# Generate customized workflow using env vars for safe parameter passing
WF_TEMPLATE="$template_file" \
WF_PROMPT="$prompt" \
WF_REF_IMAGE="$ref_image" \
WF_SEED="$seed" \
WF_STEPS="$steps" \
WF_GUIDANCE="$guidance" \
WF_DENOISE="$denoise" \
WF_WIDTH="$width" \
WF_HEIGHT="$height" \
WF_IP_WEIGHT="$ip_weight" \
WF_PREFIX="$prefix" \
WF_OUTPUT="$output_file" \
python3 << 'PYSCRIPT'
import json, os

template_file = os.environ['WF_TEMPLATE']
prompt_text = os.environ['WF_PROMPT']
ref_image = os.environ['WF_REF_IMAGE']
seed_val = int(os.environ['WF_SEED'])
steps_val = int(os.environ['WF_STEPS'])
guidance_val = float(os.environ['WF_GUIDANCE'])
denoise_val = float(os.environ['WF_DENOISE'])
width_val = int(os.environ['WF_WIDTH'])
height_val = int(os.environ['WF_HEIGHT'])
ip_weight_val = float(os.environ['WF_IP_WEIGHT'])
prefix_val = os.environ['WF_PREFIX']
output_file = os.environ['WF_OUTPUT']

with open(template_file) as f:
    wf = json.load(f)

# Detect format: API format has string keys with class_type, UI format has nodes array
is_api_format = 'nodes' not in wf and any(
    isinstance(v, dict) and 'class_type' in v for v in wf.values()
)

if is_api_format:
    # API format: {node_id: {class_type, inputs}}
    wf.pop('_gaia_meta', None)

    for nid, node in list(wf.items()):
        if not isinstance(node, dict) or 'class_type' not in node:
            continue
        ct = node['class_type']
        inp = node.get('inputs', {})

        # Prompt nodes (CLIPTextEncodeFlux with text content)
        if ct == 'CLIPTextEncodeFlux' and prompt_text:
            if inp.get('clip_l', '') or inp.get('t5xxl', ''):
                inp['clip_l'] = prompt_text
                inp['t5xxl'] = prompt_text

        # Reference image
        if ct == 'LoadImage' and ref_image:
            inp['image'] = ref_image

        # KSampler settings
        if ct == 'KSampler':
            inp['seed'] = seed_val
            inp['steps'] = steps_val
            inp['denoise'] = denoise_val

        # Guidance
        if ct == 'FluxGuidance':
            inp['guidance'] = guidance_val

        # Output prefix
        if ct == 'SaveImage' and prefix_val:
            inp['filename_prefix'] = prefix_val

else:
    # UI format: {nodes: [...], links: [...]}
    for node in wf.get('nodes', []):
        nid = node['id']
        if nid == 5 and prompt_text:
            node['widgets_values'][0] = prompt_text
            node['widgets_values'][1] = prompt_text
        if nid == 16 and ref_image:
            node['widgets_values'][0] = ref_image
        if nid == 27:
            node['widgets_values'][0] = ip_weight_val
        if nid == 3:
            node['widgets_values'][0] = seed_val
            node['widgets_values'][2] = steps_val
            node['widgets_values'][4] = guidance_val
        if nid == 6:
            node['widgets_values'][0] = width_val
            node['widgets_values'][1] = height_val
        if nid == 36 and prefix_val:
            node['widgets_values'][0] = prefix_val

with open(output_file, 'w') as f:
    json.dump(wf, f, indent=2)

fmt = "API" if is_api_format else "UI"
print(f'Generated: {output_file} ({fmt} format)')
print(f'  Template: {os.path.basename(template_file)}')
print(f'  Seed: {seed_val}')
print(f'  Steps: {steps_val}')
print(f'  Guidance: {guidance_val}')
if is_api_format:
    print(f'  Denoise: {denoise_val}')
else:
    print(f'  IP-Adapter weight: {ip_weight_val}')
    print(f'  Size: {width_val}x{height_val}')
if ref_image:
    print(f'  Ref image: {ref_image}')
PYSCRIPT

echo "Ready to submit: comfyui-api submit --workflow $output_file --poll"
