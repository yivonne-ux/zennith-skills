#!/usr/bin/env bash

# Audience Simulator — Pre-test content with persona-based LLM agents
# Simulates how brand-specific personas would react to content BEFORE publishing.
#
# Usage:
#   audience-simulator.sh test --brand mirra --content "Your ad copy here"
#   audience-simulator.sh compare --brand mirra --a "Option A" --b "Option B"
#   audience-simulator.sh batch --brand mirra --input variants.txt
#   audience-simulator.sh campaign --brand jade-oracle --brief campaign-brief.md
#
# macOS Bash 3.2 compatible. Requires: python3, curl (for LLM API).

set -euo pipefail

###############################################################################
# Constants
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
TIMESTAMP="$(date +"%Y-%m-%d-%H%M")"
DATE_HUMAN="$(date +"%Y-%m-%d")"
OUTPUT_BASE="${HOME}/.openclaw/workspace/data/audience-sim"
BRANDS_DIR="${HOME}/.openclaw/brands"
DEFAULT_MODEL="claude-sonnet-4-6"
PASS_THRESHOLD=7.0
REFINE_THRESHOLD=5.0

# Tempdir for safe data passing (cleaned up on exit)
TMPDIR_SIM="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SIM"' EXIT

###############################################################################
# Helpers
###############################################################################

log_info()  { echo "[audience-sim] $(date +"%H:%M:%S") INFO  $*"; }
log_warn()  { echo "[audience-sim] $(date +"%H:%M:%S") WARN  $*" >&2; }
log_error() { echo "[audience-sim] $(date +"%H:%M:%S") ERROR $*" >&2; }

###############################################################################
# Auto-detect OpenClaw API keys
###############################################################################

if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
  if [ -f "${OPENCLAW_CONFIG}" ]; then
    eval "$("${PYTHON3}" -c "
import json, sys
try:
    d = json.load(open('${OPENCLAW_CONFIG}'))
    providers = d.get('models',{}).get('providers',{})
    for name, cfg in providers.items():
        key = cfg.get('apiKey', cfg.get('key',''))
        base = cfg.get('baseUrl','')
        if name == 'openrouter' and key:
            print(f'export OPENAI_API_KEY=\"{key}\"')
            print(f'export OPENAI_BASE_URL=\"{base}\"')
except Exception:
    pass
" 2>/dev/null)" || true
    if [ -n "${OPENAI_API_KEY:-}" ]; then
      log_info "Auto-detected OpenRouter API key from openclaw.json"
    fi
  fi
fi

###############################################################################
# Usage
###############################################################################

usage() {
  cat <<'USAGE'
Audience Simulator — Pre-test content with persona-based LLM agents

COMMANDS:
  test      Test content against brand personas
  compare   A/B test two content variants head-to-head
  batch     Test multiple variants from a file
  campaign  Pre-test a full campaign from a brief

FLAGS:
  --brand <name>       Brand name (must match DNA.json)         [required]
  --content <text>     Content to test                          [required for test]
  --type <type>        ad-copy|caption|image-concept|product-desc|email-subject|campaign
                                                                [default: ad-copy]
  --personas <list>    Comma-separated persona names            [default: all]
  --a <text>           Option A content (for compare)
  --b <text>           Option B content (for compare)
  --input <file>       File with variants (for batch)
  --brief <file>       Campaign brief markdown (for campaign)
  --output <path>      Custom output directory
  --verbose            Show full persona reasoning
  --json               Output JSON instead of markdown

EXAMPLES:
  audience-simulator.sh test --brand mirra --content "380 cal bentos delivered daily"
  audience-simulator.sh compare --brand mirra --a "Try our bento" --b "Your lunch upgrade"
  audience-simulator.sh batch --brand pinxin-vegan --input variants.txt
  audience-simulator.sh campaign --brand jade-oracle --brief campaign-brief.md

ENVIRONMENT:
  MODEL=<name>         Override LLM model (default: claude-sonnet-4-6)
  DRY_RUN=1            Print prompt without calling LLM
  PASS_THRESHOLD=7.0   Override pass threshold
USAGE
  exit 1
}

###############################################################################
# Load persona library from SKILL.md (uses tempfiles for safe data passing)
###############################################################################

load_personas_from_skill() {
  local brand="$1"
  local brand_file="${TMPDIR_SIM}/brand_name.txt"
  printf '%s' "$brand" > "$brand_file"

  "${PYTHON3}" - "$brand_file" "${SKILL_DIR}/SKILL.md" <<'PYEOF'
import re, sys, json

brand_file = sys.argv[1]
skill_path = sys.argv[2]

with open(brand_file) as f:
    brand = f.read().strip().lower().replace('-', '')

brand_aliases = {
    'mirra': 'MIRRA',
    'pinxinvegan': 'Pinxin Vegan',
    'pinxin': 'Pinxin Vegan',
    'jadeoracle': 'Jade Oracle',
    'jade': 'Jade Oracle',
    'drstan': 'Dr. Stan',
    'wholewonder': 'Wholey Wonder',
    'wholeywonder': 'Wholey Wonder',
    'rasaya': 'Rasaya',
    'serein': 'Serein',
}

brand_key = brand.replace(' ', '')
target = brand_aliases.get(brand_key, brand)

with open(skill_path, 'r') as f:
    content = f.read()

# Match: ### <anything>TARGET<anything>Personas<anything>\n<content until next ### or --- or EOF>
pattern = r'### .*?' + re.escape(target) + r'.*?Personas.*?\n(.*?)(?=\n### |\n---|\Z)'
match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)
if not match:
    first_word = target.split()[0] if ' ' in target else target
    pattern = r'### .*?' + re.escape(first_word) + r'.*?Personas.*?\n(.*?)(?=\n### |\n---|\Z)'
    match = re.search(pattern, content, re.DOTALL | re.IGNORECASE)

if not match:
    print(json.dumps([]))
    sys.exit(0)

section = match.group(1)
personas = []
entries = re.split(r'\n\d+\.\s+\*\*', section)
for entry in entries:
    if not entry.strip():
        continue
    name_match = re.match(r'([^,*]+),\s*(\d+)\*\*\s*--\s*(.*)', entry, re.DOTALL)
    if name_match:
        name = name_match.group(1).strip().lstrip('*')
        age = int(name_match.group(2))
        desc = name_match.group(3).strip()
        slug = name.lower().replace(' ', '-').replace('.', '')
        personas.append({
            'name': name,
            'age': age,
            'slug': slug,
            'description': desc
        })

print(json.dumps(personas, indent=2))
PYEOF
}

###############################################################################
# Load brand DNA if available
###############################################################################

load_brand_dna() {
  local brand="$1"
  local dna_path="${BRANDS_DIR}/${brand}/DNA.json"
  if [ -f "$dna_path" ]; then
    cat "$dna_path"
  else
    echo "{}"
  fi
}

###############################################################################
# Build simulation prompt (all data passed via files, not inline strings)
###############################################################################

build_simulation_prompt() {
  local brand="$1"
  local content="$2"
  local content_type="$3"
  local personas_json="$4"
  local brand_dna="$5"
  local verbose="${6:-false}"

  # Write all inputs to temp files to avoid quote/escape issues
  printf '%s' "$brand" > "${TMPDIR_SIM}/prompt_brand.txt"
  printf '%s' "$content" > "${TMPDIR_SIM}/prompt_content.txt"
  printf '%s' "$content_type" > "${TMPDIR_SIM}/prompt_type.txt"
  printf '%s' "$personas_json" > "${TMPDIR_SIM}/prompt_personas.json"
  printf '%s' "$brand_dna" > "${TMPDIR_SIM}/prompt_dna.json"
  printf '%s' "$verbose" > "${TMPDIR_SIM}/prompt_verbose.txt"

  "${PYTHON3}" - "${TMPDIR_SIM}" <<'PYEOF'
import json, sys, os

tmpdir = sys.argv[1]

def read_tmp(name):
    with open(os.path.join(tmpdir, name)) as f:
        return f.read()

brand = read_tmp('prompt_brand.txt')
content = read_tmp('prompt_content.txt')
content_type = read_tmp('prompt_type.txt')
verbose = read_tmp('prompt_verbose.txt') == 'true'
personas = json.loads(read_tmp('prompt_personas.json'))

try:
    brand_dna = json.loads(read_tmp('prompt_dna.json'))
except json.JSONDecodeError:
    brand_dna = {}

brand_context = ''
if brand_dna:
    brand_name = brand_dna.get('name', brand)
    brand_desc = brand_dna.get('description', brand_dna.get('tagline', ''))
    if brand_desc:
        brand_context = f'Brand: {brand_name} -- {brand_desc}\n'

persona_block = ''
for p in personas:
    persona_block += f"\n### {p['name']}, {p['age']}\n{p['description']}\n"

verbose_instruction = ''
if verbose:
    verbose_instruction = '\nFor each persona, provide detailed reasoning about WHY they would react this way, written in their voice.\n'

verbose_json_fields = ''
if verbose:
    verbose_json_fields = ',\n      "reasoning": "<detailed reasoning in persona voice>"'

prompt = f"""You are an audience simulation engine. You will evaluate content by roleplaying as specific audience personas and scoring their likely reaction.

## Context
{brand_context}Content type: {content_type}
Malaysian market. All prices in RM. Local context (Shopee, GrabFood, WhatsApp, mamak, pasar malam).

## Content to Evaluate
"{content}"

## Personas to Simulate
{persona_block}

## Instructions
For EACH persona above, simulate their reaction to this content. Think as that person -- their scroll behavior, their values, their triggers, their deal-breakers.

Score each persona on 4 dimensions (1-10):
- **Attention**: Would this stop their scroll? (1=invisible, 10=screenshot-worthy)
- **Relevance**: Is this for them? (1=wrong audience, 10=feels personally written)
- **Emotion**: How does it make them feel? (1=nothing/negative, 10=I need this NOW)
- **Action**: Would they do something? (1=no action, 10=buy immediately)
{verbose_instruction}
## Required Output Format (STRICT -- follow exactly)

Output valid JSON only. No markdown, no code fences, no explanation outside the JSON.

{{
  "personas": [
    {{
      "name": "<persona name>",
      "age": <age>,
      "scores": {{
        "attention": <1-10>,
        "relevance": <1-10>,
        "emotion": <1-10>,
        "action": <1-10>
      }},
      "overall": <average of 4 scores, 1 decimal>,
      "feedback": "<1-2 sentence reaction in persona's voice, using their language/slang>",
      "suggestions": ["<specific improvement for this persona>"]{verbose_json_fields}
    }}
  ],
  "aggregate": {{
    "overall": <average of all persona overalls, 1 decimal>,
    "by_dimension": {{
      "attention": <avg across personas>,
      "relevance": <avg across personas>,
      "emotion": <avg across personas>,
      "action": <avg across personas>
    }},
    "verdict": "<PASS if >= 7.0, REFINE if >= 5.0, FAIL if < 5.0>"
  }},
  "segments": {{
    "love_it": ["<personas with overall >= 8>"],
    "neutral": ["<personas with overall 5-7.9>"],
    "turned_off": ["<personas with overall < 5>"]
  }},
  "top_suggestions": [
    "<top 3-5 actionable improvement suggestions, specific not generic>"
  ],
  "revised_content": "<improved version incorporating top suggestions>"
}}"""

print(prompt)
PYEOF
}

###############################################################################
# Call LLM API
###############################################################################

call_llm() {
  local prompt_file="$1"
  local model="${MODEL:-$DEFAULT_MODEL}"

  if [ "${DRY_RUN:-0}" = "1" ]; then
    log_info "[DRY RUN] Would send prompt ($(wc -c < "$prompt_file" | tr -d ' ') bytes) to model: $model"
    cat "$prompt_file"
    return 0
  fi

  # Determine API endpoint and format
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    # Build request body from file
    "${PYTHON3}" - "$prompt_file" "$model" "${ANTHROPIC_API_KEY}" <<'PYEOF'
import json, sys, subprocess

prompt_file = sys.argv[1]
model = sys.argv[2]
api_key = sys.argv[3]

with open(prompt_file) as f:
    prompt = f.read()

body = json.dumps({
    'model': model,
    'max_tokens': 4096,
    'messages': [{'role': 'user', 'content': prompt}]
})

result = subprocess.run(
    ['curl', '-s', '-X', 'POST', 'https://api.anthropic.com/v1/messages',
     '-H', 'Content-Type: application/json',
     '-H', f'x-api-key: {api_key}',
     '-H', 'anthropic-version: 2023-06-01',
     '-d', body],
    capture_output=True, text=True
)

r = json.loads(result.stdout)
if 'content' in r and len(r['content']) > 0:
    print(r['content'][0]['text'])
elif 'error' in r:
    print(f'ERROR: {r["error"].get("message", r["error"])}', file=sys.stderr)
    sys.exit(1)
else:
    print(f'ERROR: Unexpected response', file=sys.stderr)
    sys.exit(1)
PYEOF

  elif [ -n "${OPENAI_API_KEY:-}" ]; then
    local api_url="${OPENAI_BASE_URL:-https://api.openai.com/v1}/chat/completions"

    "${PYTHON3}" - "$prompt_file" "$model" "${OPENAI_API_KEY}" "$api_url" <<'PYEOF'
import json, sys, subprocess

prompt_file = sys.argv[1]
model = sys.argv[2]
api_key = sys.argv[3]
api_url = sys.argv[4]

with open(prompt_file) as f:
    prompt = f.read()

body = json.dumps({
    'model': model,
    'max_tokens': 4096,
    'messages': [{'role': 'user', 'content': prompt}],
    'temperature': 0.7
})

result = subprocess.run(
    ['curl', '-s', '-X', 'POST', api_url,
     '-H', 'Content-Type: application/json',
     '-H', f'Authorization: Bearer {api_key}',
     '-d', body],
    capture_output=True, text=True
)

r = json.loads(result.stdout)
if 'choices' in r and len(r['choices']) > 0:
    print(r['choices'][0]['message']['content'])
elif 'error' in r:
    print(f'ERROR: {r["error"].get("message", str(r["error"]))}', file=sys.stderr)
    sys.exit(1)
else:
    print(f'ERROR: Unexpected response: {result.stdout[:200]}', file=sys.stderr)
    sys.exit(1)
PYEOF

  else
    log_error "No API key found. Set ANTHROPIC_API_KEY, OPENAI_API_KEY, or OPENROUTER_API_KEY."
    log_error "On Zennith OS, keys are auto-detected from openclaw.json."
    exit 1
  fi
}

###############################################################################
# Extract JSON from LLM response (handles markdown fences etc)
###############################################################################

extract_json() {
  local response_file="$1"
  "${PYTHON3}" - "$response_file" <<'PYEOF'
import re, sys, json

with open(sys.argv[1]) as f:
    raw = f.read()

# Remove markdown code fences if present
cleaned = re.sub(r'^```json?\s*', '', raw.strip())
cleaned = re.sub(r'```\s*$', '', cleaned.strip())

try:
    parsed = json.loads(cleaned)
    print(json.dumps(parsed))
except json.JSONDecodeError as e:
    match = re.search(r'\{.*\}', raw, re.DOTALL)
    if match:
        try:
            parsed = json.loads(match.group())
            print(json.dumps(parsed))
        except Exception:
            print(raw, file=sys.stderr)
            sys.exit(1)
    else:
        print(f'JSON parse error: {e}', file=sys.stderr)
        print(raw[:500], file=sys.stderr)
        sys.exit(1)
PYEOF
}

###############################################################################
# Format JSON result to markdown report
###############################################################################

format_markdown_report() {
  local brand="$1"
  local content_file="$2"
  local content_type="$3"
  local json_file="$4"

  "${PYTHON3}" - "$brand" "$content_file" "$content_type" "$json_file" "$DATE_HUMAN" <<'PYEOF'
import json, sys

brand = sys.argv[1]
with open(sys.argv[2]) as f:
    content = f.read()
content_type = sys.argv[3]
with open(sys.argv[4]) as f:
    result = json.loads(f.read())
date = sys.argv[5]

agg = result.get('aggregate', {})
personas = result.get('personas', [])
segments = result.get('segments', {})
suggestions = result.get('top_suggestions', [])
revised = result.get('revised_content', '')

verdict = agg.get('verdict', 'UNKNOWN')
overall = agg.get('overall', 0)
dims = agg.get('by_dimension', {})

lines = []
lines.append(f'# Audience Simulation Report')
lines.append(f'**Brand:** {brand} | **Content type:** {content_type} | **Date:** {date}')
lines.append('')
lines.append('## Content Tested')
lines.append(f'> "{content}"')
lines.append('')
lines.append('## Persona Reactions')
lines.append('')
lines.append('| Persona | Attention | Relevance | Emotion | Action | Overall | Key Feedback |')
lines.append('|---------|-----------|-----------|---------|--------|---------|--------------|')

for p in personas:
    s = p.get('scores', {})
    fb = p.get('feedback', '').replace('|', '\\|')
    lines.append(f'| {p["name"]}, {p["age"]} | {s.get("attention","-")} | {s.get("relevance","-")} | {s.get("emotion","-")} | {s.get("action","-")} | {p.get("overall","-")} | "{fb}" |')

lines.append('')
lines.append(f'## Aggregate Score: {overall} / 10 -- {verdict}')
lines.append('')
lines.append('## Segment Breakdown')
love = ', '.join(segments.get('love_it', [])) or 'None'
neutral = ', '.join(segments.get('neutral', [])) or 'None'
turned_off = ', '.join(segments.get('turned_off', [])) or 'None'
lines.append(f'- **LOVE IT (>= 8):** {love}')
lines.append(f'- **NEUTRAL (5-7.9):** {neutral}')
lines.append(f'- **TURNED OFF (< 5):** {turned_off}')
lines.append('')
lines.append('## Dimension Breakdown')
lines.append(f'- Attention: {dims.get("attention", "-")} avg')
lines.append(f'- Relevance: {dims.get("relevance", "-")} avg')
lines.append(f'- Emotion: {dims.get("emotion", "-")} avg')
lines.append(f'- Action: {dims.get("action", "-")} avg')
lines.append('')
lines.append('## Improvement Suggestions')
for i, s in enumerate(suggestions, 1):
    lines.append(f'{i}. {s}')

if revised:
    lines.append('')
    lines.append('## Suggested Revision')
    lines.append(f'> "{revised}"')

print('\n'.join(lines))
PYEOF
}

###############################################################################
# Save report
###############################################################################

save_report() {
  local brand="$1"
  local content_type="$2"
  local report_file="$3"
  local ext="${4:-md}"
  local custom_output="${5:-}"

  local output_dir="${custom_output:-${OUTPUT_BASE}/${brand}}"
  mkdir -p "$output_dir"

  local filename="${brand}-${content_type}-${TIMESTAMP}.${ext}"
  local filepath="${output_dir}/${filename}"

  cp "$report_file" "$filepath"
  log_info "Report saved: $filepath"
  echo "$filepath"
}

###############################################################################
# Command: test
###############################################################################

cmd_test() {
  local brand=""
  local content=""
  local content_type="ad-copy"
  local personas_filter=""
  local verbose="false"
  local output_json="false"
  local custom_output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)     brand="$2"; shift 2 ;;
      --content)   content="$2"; shift 2 ;;
      --type)      content_type="$2"; shift 2 ;;
      --personas)  personas_filter="$2"; shift 2 ;;
      --verbose)   verbose="true"; shift ;;
      --json)      output_json="true"; shift ;;
      --output)    custom_output="$2"; shift 2 ;;
      *)           log_error "Unknown flag: $1"; usage ;;
    esac
  done

  if [ -z "$brand" ] || [ -z "$content" ]; then
    log_error "Missing required flags: --brand and --content"
    usage
  fi

  log_info "Testing content for brand: $brand"
  log_info "Content type: $content_type"
  log_info "Content: \"${content:0:80}$([ ${#content} -gt 80 ] && echo '...' || echo '')\""

  # Load personas
  local personas_json
  personas_json=$(load_personas_from_skill "$brand")

  # Count personas safely via file
  printf '%s' "$personas_json" > "${TMPDIR_SIM}/personas_loaded.json"
  local persona_count
  persona_count=$("${PYTHON3}" -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "${TMPDIR_SIM}/personas_loaded.json")

  if [ "$persona_count" = "0" ]; then
    log_error "No personas found for brand: $brand"
    log_error "Available brands: mirra, pinxin-vegan, jade-oracle, dr-stan, wholey-wonder, rasaya, serein"
    exit 1
  fi

  # Filter personas if specified
  if [ -n "$personas_filter" ]; then
    printf '%s' "$personas_filter" > "${TMPDIR_SIM}/filter.txt"
    personas_json=$("${PYTHON3}" - "${TMPDIR_SIM}/personas_loaded.json" "${TMPDIR_SIM}/filter.txt" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    personas = json.load(f)
with open(sys.argv[2]) as f:
    filters = f.read().strip().lower().split(',')
filtered = [p for p in personas if p['slug'] in filters or p['name'].lower() in filters]
if not filtered:
    filtered = [p for p in personas if any(f in p['slug'] or f in p['name'].lower() for f in filters)]
print(json.dumps(filtered))
PYEOF
)
    printf '%s' "$personas_json" > "${TMPDIR_SIM}/personas_loaded.json"
    persona_count=$("${PYTHON3}" -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "${TMPDIR_SIM}/personas_loaded.json")
    log_info "Filtered to $persona_count personas: $personas_filter"
  fi

  log_info "Simulating $persona_count personas..."

  # Load brand DNA
  local brand_dna
  brand_dna=$(load_brand_dna "$brand")

  # Build prompt
  local prompt
  prompt=$(build_simulation_prompt "$brand" "$content" "$content_type" "$personas_json" "$brand_dna" "$verbose")

  # Save prompt to file for LLM call
  printf '%s' "$prompt" > "${TMPDIR_SIM}/prompt.txt"

  # Call LLM
  log_info "Calling LLM (model: ${MODEL:-$DEFAULT_MODEL})..."
  local llm_response
  llm_response=$(call_llm "${TMPDIR_SIM}/prompt.txt")

  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "$llm_response"
    return 0
  fi

  # Extract JSON from response
  printf '%s' "$llm_response" > "${TMPDIR_SIM}/llm_response.txt"
  local json_result
  json_result=$(extract_json "${TMPDIR_SIM}/llm_response.txt")
  printf '%s' "$json_result" > "${TMPDIR_SIM}/result.json"

  # Save content for report formatting
  printf '%s' "$content" > "${TMPDIR_SIM}/content.txt"

  if [ "$output_json" = "true" ]; then
    # Add metadata to JSON
    "${PYTHON3}" - "${TMPDIR_SIM}/result.json" "$brand" "$content_type" "$DATE_HUMAN" "${TMPDIR_SIM}/content.txt" "${MODEL:-$DEFAULT_MODEL}" <<'PYEOF' > "${TMPDIR_SIM}/final.json"
import json, sys
with open(sys.argv[1]) as f:
    result = json.load(f)
with open(sys.argv[5]) as f:
    content = f.read()
result['_meta'] = {
    'brand': sys.argv[2],
    'content_type': sys.argv[3],
    'date': sys.argv[4],
    'content_tested': content,
    'model': sys.argv[6]
}
print(json.dumps(result, indent=2))
PYEOF

    save_report "$brand" "$content_type" "${TMPDIR_SIM}/final.json" "json" "$custom_output"
    echo ""
    cat "${TMPDIR_SIM}/final.json"
  else
    # Format as markdown
    format_markdown_report "$brand" "${TMPDIR_SIM}/content.txt" "$content_type" "${TMPDIR_SIM}/result.json" > "${TMPDIR_SIM}/report.md"

    save_report "$brand" "$content_type" "${TMPDIR_SIM}/report.md" "md" "$custom_output"
    echo ""
    cat "${TMPDIR_SIM}/report.md"
  fi

  # Print verdict
  local verdict
  verdict=$("${PYTHON3}" -c "
import json, sys
with open(sys.argv[1]) as f:
    r = json.load(f)
v = r.get('aggregate',{}).get('verdict','UNKNOWN')
s = r.get('aggregate',{}).get('overall',0)
print(f'{s} / 10 -- {v}')
" "${TMPDIR_SIM}/result.json")
  echo ""
  log_info "RESULT: $verdict"
}

###############################################################################
# Command: compare
###############################################################################

cmd_compare() {
  local brand=""
  local content_a=""
  local content_b=""
  local content_type="ad-copy"
  local verbose="false"
  local custom_output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)   brand="$2"; shift 2 ;;
      --a)       content_a="$2"; shift 2 ;;
      --b)       content_b="$2"; shift 2 ;;
      --type)    content_type="$2"; shift 2 ;;
      --verbose) verbose="true"; shift ;;
      --output)  custom_output="$2"; shift 2 ;;
      *)         log_error "Unknown flag: $1"; usage ;;
    esac
  done

  if [ -z "$brand" ] || [ -z "$content_a" ] || [ -z "$content_b" ]; then
    log_error "Missing required flags: --brand, --a, and --b"
    usage
  fi

  log_info "=== A/B Pre-Test for brand: $brand ==="
  echo ""
  echo "========================================="
  echo "OPTION A: \"${content_a:0:60}$([ ${#content_a} -gt 60 ] && echo '...' || echo '')\""
  echo "OPTION B: \"${content_b:0:60}$([ ${#content_b} -gt 60 ] && echo '...' || echo '')\""
  echo "========================================="
  echo ""

  log_info "--- Testing Option A ---"
  local args_a=(--brand "$brand" --content "$content_a" --type "$content_type")
  [ "$verbose" = "true" ] && args_a+=(--verbose)
  [ -n "$custom_output" ] && args_a+=(--output "$custom_output")
  cmd_test "${args_a[@]}"

  echo ""
  echo "========================================="
  echo ""

  log_info "--- Testing Option B ---"
  local args_b=(--brand "$brand" --content "$content_b" --type "$content_type")
  [ "$verbose" = "true" ] && args_b+=(--verbose)
  [ -n "$custom_output" ] && args_b+=(--output "$custom_output")
  cmd_test "${args_b[@]}"

  echo ""
  log_info "Compare both reports above to pick the winner."
}

###############################################################################
# Command: batch
###############################################################################

cmd_batch() {
  local brand=""
  local input_file=""
  local content_type="ad-copy"
  local custom_output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)   brand="$2"; shift 2 ;;
      --input)   input_file="$2"; shift 2 ;;
      --type)    content_type="$2"; shift 2 ;;
      --output)  custom_output="$2"; shift 2 ;;
      *)         log_error "Unknown flag: $1"; usage ;;
    esac
  done

  if [ -z "$brand" ] || [ -z "$input_file" ]; then
    log_error "Missing required flags: --brand and --input"
    usage
  fi

  if [ ! -f "$input_file" ]; then
    log_error "Input file not found: $input_file"
    exit 1
  fi

  log_info "Batch testing variants from: $input_file"

  local variant_num=0

  while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue

    variant_num=$((variant_num + 1))
    echo ""
    log_info "========== Variant $variant_num =========="
    local args=(--brand "$brand" --content "$line" --type "$content_type" --json)
    [ -n "$custom_output" ] && args+=(--output "$custom_output")
    cmd_test "${args[@]}"

  done < "$input_file"

  echo ""
  log_info "Batch complete: $variant_num variants tested."
}

###############################################################################
# Command: campaign
###############################################################################

cmd_campaign() {
  local brand=""
  local brief_file=""
  local custom_output=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand)   brand="$2"; shift 2 ;;
      --brief)   brief_file="$2"; shift 2 ;;
      --output)  custom_output="$2"; shift 2 ;;
      *)         log_error "Unknown flag: $1"; usage ;;
    esac
  done

  if [ -z "$brand" ] || [ -z "$brief_file" ]; then
    log_error "Missing required flags: --brand and --brief"
    usage
  fi

  if [ ! -f "$brief_file" ]; then
    log_error "Brief file not found: $brief_file"
    exit 1
  fi

  log_info "Campaign pre-test for brand: $brand"
  log_info "Brief: $brief_file"

  # Load personas
  local personas_json
  personas_json=$(load_personas_from_skill "$brand")
  printf '%s' "$personas_json" > "${TMPDIR_SIM}/campaign_personas.json"

  local brand_dna
  brand_dna=$(load_brand_dna "$brand")
  printf '%s' "$brand_dna" > "${TMPDIR_SIM}/campaign_dna.json"

  # Build campaign-specific prompt
  "${PYTHON3}" - "${TMPDIR_SIM}/campaign_personas.json" "${TMPDIR_SIM}/campaign_dna.json" "$brief_file" "$brand" <<'PYEOF' > "${TMPDIR_SIM}/campaign_prompt.txt"
import json, sys

with open(sys.argv[1]) as f:
    personas = json.load(f)
with open(sys.argv[2]) as f:
    try:
        brand_dna = json.load(f)
    except json.JSONDecodeError:
        brand_dna = {}
with open(sys.argv[3]) as f:
    brief = f.read()
brand = sys.argv[4]

brand_desc = ''
if brand_dna:
    desc = brand_dna.get('description', brand_dna.get('tagline', ''))
    if desc:
        brand_desc = desc

persona_block = ''
for p in personas:
    persona_block += f"\n### {p['name']}, {p['age']}\n{p['description']}\n"

prompt = f"""You are an audience simulation engine evaluating a full campaign brief.

## Brand
{brand}
{brand_desc}

## Campaign Brief
{brief}

## Personas
{persona_block}

## Instructions
Analyze this campaign brief from each persona's perspective. For each persona:
1. Rate the overall campaign concept (1-10)
2. Identify which campaign elements would resonate with them
3. Identify which elements would fall flat or turn them off
4. Suggest persona-specific adaptations

Then provide:
- Overall campaign viability score (1-10)
- Recommended persona targeting priority (who to target first)
- Key risks (which personas might we alienate?)
- Top 5 improvements

Output valid JSON only. No markdown fences.

{{
  "campaign_name": "<extracted from brief or generated>",
  "personas": [
    {{
      "name": "<name>",
      "age": <age>,
      "campaign_score": <1-10>,
      "resonates": ["<elements that work for this persona>"],
      "falls_flat": ["<elements that don't work>"],
      "adaptations": ["<persona-specific tweaks>"],
      "feedback": "<1-2 sentence reaction in persona voice>"
    }}
  ],
  "aggregate": {{
    "overall": <1-10>,
    "verdict": "<PASS/REFINE/FAIL>",
    "target_priority": ["<personas to target first, in order>"],
    "key_risks": ["<risks of alienating specific personas>"]
  }},
  "top_improvements": ["<top 5 improvements>"],
  "recommended_content_types": ["<what content formats to create for this campaign>"]
}}"""

print(prompt)
PYEOF

  log_info "Calling LLM for campaign analysis..."
  local llm_response
  llm_response=$(call_llm "${TMPDIR_SIM}/campaign_prompt.txt")

  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "$llm_response"
    return 0
  fi

  # Extract JSON
  printf '%s' "$llm_response" > "${TMPDIR_SIM}/campaign_response.txt"
  local json_result
  json_result=$(extract_json "${TMPDIR_SIM}/campaign_response.txt")
  printf '%s' "$json_result" > "${TMPDIR_SIM}/campaign_result.json"

  # Pretty-print
  "${PYTHON3}" -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1])),indent=2))" "${TMPDIR_SIM}/campaign_result.json" > "${TMPDIR_SIM}/campaign_final.json"

  save_report "$brand" "campaign" "${TMPDIR_SIM}/campaign_final.json" "json" "$custom_output"
  echo ""
  cat "${TMPDIR_SIM}/campaign_final.json"

  local verdict
  verdict=$("${PYTHON3}" -c "
import json, sys
with open(sys.argv[1]) as f:
    r = json.load(f)
v = r.get('aggregate',{}).get('verdict','UNKNOWN')
s = r.get('aggregate',{}).get('overall',0)
print(f'{s} / 10 -- {v}')
" "${TMPDIR_SIM}/campaign_result.json")
  echo ""
  log_info "CAMPAIGN RESULT: $verdict"
}

###############################################################################
# Main dispatch
###############################################################################

if [ $# -lt 1 ]; then
  usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
  test)     cmd_test "$@" ;;
  compare)  cmd_compare "$@" ;;
  batch)    cmd_batch "$@" ;;
  campaign) cmd_campaign "$@" ;;
  help|-h|--help) usage ;;
  *)
    log_error "Unknown command: $COMMAND"
    usage
    ;;
esac
