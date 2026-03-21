#!/usr/bin/env bash

# Auto-Research Loop Engine
# Inspired by Karpathy's autoresearch: generate → eval → keep-or-discard → repeat
#
# Usage: auto-loop.sh <config.yaml>
#
# The human edits the config (strategy). The AI generates variants (execution).
# The eval score determines success. No opinions — just scores.
#
# macOS Bash 3.2 compatible. Requires: python3, curl (for LLM API).

set -euo pipefail

###############################################################################
# Constants
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DEFAULT_MODEL="claude-sonnet-4-6"
DEFAULT_MAX_ITERATIONS=10

###############################################################################
# Helpers
###############################################################################

log_info()  { echo "[auto-research] $(date +"%H:%M:%S") INFO  $*"; }
log_warn()  { echo "[auto-research] $(date +"%H:%M:%S") WARN  $*" >&2; }
log_error() { echo "[auto-research] $(date +"%H:%M:%S") ERROR $*" >&2; }

###############################################################################
# Auto-detect OpenClaw API keys (so it works natively on iMac Zennith OS)
###############################################################################
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
  if [ -f "${OPENCLAW_CONFIG}" ]; then
    # Extract API keys from openclaw.json providers
    eval "$("${PYTHON3}" -c "
import json
d = json.load(open('${OPENCLAW_CONFIG}'))
providers = d.get('models',{}).get('providers',{})
for name, cfg in providers.items():
    key = cfg.get('apiKey', cfg.get('key',''))
    base = cfg.get('baseUrl','')
    if name == 'openrouter' and key:
        print(f'export OPENAI_API_KEY=\"{key}\"')
        print(f'export OPENAI_BASE_URL=\"{base}\"')
    elif name == 'anthropic' and key:
        print(f'export ANTHROPIC_API_KEY=\"{key}\"')
    elif name == 'moonshot' and key and not key.startswith('not-'):
        print(f'export MOONSHOT_API_KEY=\"{key}\"')
" 2>/dev/null)"
    if [ -n "${OPENAI_API_KEY:-}" ]; then
      log_info "Auto-detected OpenRouter API key from openclaw.json"
    elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
      log_info "Auto-detected Anthropic API key from openclaw.json"
    fi
  fi
fi

usage() {
  echo "Usage: auto-loop.sh <config.yaml>"
  echo ""
  echo "Environment overrides:"
  echo "  MAX_ITERATIONS=N    Override max iterations from config"
  echo "  MODEL=name          Override model from config"
  echo "  DRY_RUN=1           Print what would happen without calling LLM"
  echo "  ANTHROPIC_API_KEY   Claude models (auto-detected from openclaw.json)"
  echo "  OPENAI_API_KEY      OpenAI/OpenRouter models (auto-detected from openclaw.json)"
  echo ""
  echo "On Zennith OS (iMac), API keys are auto-detected from openclaw.json."
  exit 1
}

# Parse YAML config using python3 (no external deps needed)
parse_config() {
  local config_file="$1"
  "$PYTHON3" << 'PYEOF'
import sys, json, os

config_file = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("CONFIG_FILE", "")

# Minimal YAML parser (no PyYAML dependency)
# Handles: scalars, lists of dicts with id/description, simple nested keys
def parse_simple_yaml(filepath):
    result = {}
    current_key = None
    current_list = None
    current_dict = None
    in_multiline = False
    multiline_key = None
    multiline_val = ""

    with open(filepath, "r") as f:
        lines = f.readlines()

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        i += 1

        # Skip comments and empty lines
        if not stripped or stripped.startswith("#"):
            if in_multiline:
                multiline_val += "\n"
            continue

        # Handle multiline (|)
        if in_multiline:
            indent = len(line) - len(line.lstrip())
            if indent > 0 and not stripped.startswith("-"):
                multiline_val += stripped + "\n"
                continue
            else:
                result[multiline_key] = multiline_val.strip()
                in_multiline = False

        # Top-level key: value
        if ":" in stripped and not stripped.startswith("-"):
            parts = stripped.split(":", 1)
            key = parts[0].strip()
            val = parts[1].strip() if len(parts) > 1 else ""

            # Remove quotes
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            elif val.startswith("'") and val.endswith("'"):
                val = val[1:-1]

            if val == "|":
                in_multiline = True
                multiline_key = key
                multiline_val = ""
                continue
            elif val == "" or val == "[]":
                current_key = key
                if val == "[]":
                    result[key] = []
                else:
                    result[key] = []
                current_list = result[key]
                current_dict = None
                continue
            elif val == "null" or val == "~":
                result[key] = None
            else:
                # Try to parse as number
                try:
                    if "." in val:
                        result[key] = float(val)
                    else:
                        result[key] = int(val)
                except ValueError:
                    result[key] = val
                current_key = None
                current_list = None

        # List item
        elif stripped.startswith("- ") and current_list is not None:
            item_content = stripped[2:].strip()
            if ":" in item_content:
                # Dict item in list
                parts = item_content.split(":", 1)
                k = parts[0].strip()
                v = parts[1].strip().strip('"').strip("'")
                current_dict = {k: v}
                current_list.append(current_dict)
            else:
                current_list.append(item_content.strip('"').strip("'"))
                current_dict = None

        # Continuation of dict in list
        elif ":" in stripped and current_dict is not None:
            parts = stripped.split(":", 1)
            k = parts[0].strip()
            v = parts[1].strip().strip('"').strip("'")
            current_dict[k] = v

    if in_multiline:
        result[multiline_key] = multiline_val.strip()

    return result

try:
    config = parse_simple_yaml(config_file)
    print(json.dumps(config))
except Exception as e:
    print(json.dumps({"error": str(e)}), file=sys.stderr)
    sys.exit(1)
PYEOF
}

# Extract a JSON field using python3
json_get() {
  local json="$1"
  local field="$2"
  local default="${3:-}"
  echo "$json" | "$PYTHON3" -c "
import sys, json
data = json.load(sys.stdin)
val = data.get('$field')
if val is None:
    print('$default')
elif isinstance(val, (list, dict)):
    print(json.dumps(val))
else:
    print(val)
"
}

# Extract criteria list as JSON array
json_get_criteria() {
  local json="$1"
  echo "$json" | "$PYTHON3" -c "
import sys, json
data = json.load(sys.stdin)
criteria = data.get('criteria', [])
if isinstance(criteria, list):
    print(json.dumps(criteria))
else:
    print('[]')
"
}

# Ensure output directory exists
ensure_dir() {
  local dir="$1"
  # Expand ~ to HOME
  dir="${dir/#\~/$HOME}"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
  echo "$dir"
}

# Call LLM API (supports Claude and OpenAI-compatible endpoints)
call_llm() {
  local system_prompt="$1"
  local user_prompt="$2"
  local model="$3"

  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[DRY RUN] Would call $model with prompt of ${#user_prompt} chars"
    return 0
  fi

  # Determine API based on model name
  if echo "$model" | grep -q "claude"; then
    # Anthropic API
    local api_key="${ANTHROPIC_API_KEY:-}"
    if [ -z "$api_key" ]; then
      log_error "ANTHROPIC_API_KEY not set. Required for model: $model"
      return 1
    fi

    local response
    response=$(curl -s --max-time 120 \
      "https://api.anthropic.com/v1/messages" \
      -H "x-api-key: $api_key" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$(printf '%s' "{
        \"model\": \"$model\",
        \"max_tokens\": 4096,
        \"system\": $(echo "$system_prompt" | "$PYTHON3" -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),
        \"messages\": [{
          \"role\": \"user\",
          \"content\": $(echo "$user_prompt" | "$PYTHON3" -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
        }]
      }")")

    # Extract text from response
    echo "$response" | "$PYTHON3" -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0]['text'])
    elif 'error' in data:
        print('ERROR: ' + data['error'].get('message', str(data['error'])), file=sys.stderr)
        sys.exit(1)
    else:
        print('ERROR: Unexpected response format', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print('ERROR: ' + str(e), file=sys.stderr)
    sys.exit(1)
"
  else
    # OpenAI-compatible API
    local api_key="${OPENAI_API_KEY:-}"
    local api_base="${OPENAI_API_BASE:-https://api.openai.com/v1}"
    if [ -z "$api_key" ]; then
      log_error "OPENAI_API_KEY not set. Required for model: $model"
      return 1
    fi

    local response
    response=$(curl -s --max-time 120 \
      "$api_base/chat/completions" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d "$(printf '%s' "{
        \"model\": \"$model\",
        \"max_tokens\": 4096,
        \"messages\": [
          {\"role\": \"system\", \"content\": $(echo "$system_prompt" | "$PYTHON3" -c 'import sys,json; print(json.dumps(sys.stdin.read()))')},
          {\"role\": \"user\", \"content\": $(echo "$user_prompt" | "$PYTHON3" -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}
        ]
      }")")

    echo "$response" | "$PYTHON3" -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'choices' in data and len(data['choices']) > 0:
        print(data['choices'][0]['message']['content'])
    elif 'error' in data:
        print('ERROR: ' + data['error'].get('message', str(data['error'])), file=sys.stderr)
        sys.exit(1)
    else:
        print('ERROR: Unexpected response format', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print('ERROR: ' + str(e), file=sys.stderr)
    sys.exit(1)
"
  fi
}

###############################################################################
# Core Loop Functions
###############################################################################

# Generate a new variant using LLM
generate_variant() {
  local task="$1"
  local current_best="$2"
  local learnings_file="$3"
  local criteria_json="$4"
  local model="$5"
  local iteration="$6"

  # Build learnings context
  local learnings_context=""
  if [ -f "$learnings_file" ]; then
    learnings_context=$("$PYTHON3" -c "
import json, sys
try:
    with open('$learnings_file', 'r') as f:
        data = json.load(f)
    experiments = data.get('experiments', [])
    if experiments:
        recent = experiments[-10:]  # Last 10 experiments
        lines = []
        for exp in recent:
            status = 'KEPT' if exp.get('kept', False) else 'DISCARDED'
            score = exp.get('score', 0)
            analysis = exp.get('analysis', 'No analysis')
            lines.append(f'  - [{status}] Score {score}: {analysis}')
        print('Prior experiments (most recent):')
        print(chr(10).join(lines))
    else:
        print('No prior experiments yet.')
except:
    print('No prior experiments yet.')
")
  else
    learnings_context="No prior experiments yet. This is the first iteration."
  fi

  # Build criteria description
  local criteria_desc
  criteria_desc=$(echo "$criteria_json" | "$PYTHON3" -c "
import sys, json
criteria = json.load(sys.stdin)
if isinstance(criteria, list):
    for c in criteria:
        if isinstance(c, dict):
            print(f\"- {c.get('id', 'unknown')}: {c.get('description', '')}\")
        else:
            print(f'- {c}')
")

  local system_prompt="You are an optimization engine. Your job is to generate improved content variants.
You will be scored on specific binary criteria. Maximize the number of criteria you satisfy.
Output ONLY the variant text. No explanations, no preamble, no markdown formatting — just the raw content."

  local user_prompt="TASK: $task

CURRENT BEST:
$current_best

EVALUATION CRITERIA (you will be scored yes/no on each):
$criteria_desc

LEARNINGS FROM PRIOR EXPERIMENTS:
$learnings_context

ITERATION: $iteration

Generate a NEW variant that improves on the current best. Focus on satisfying ALL criteria.
If prior experiments show patterns (e.g., short headlines score better), incorporate those learnings.
Be creative but strategic. Output ONLY the variant text:"

  call_llm "$system_prompt" "$user_prompt" "$model"
}

# Evaluate a variant against criteria using LLM-as-judge
evaluate_variant() {
  local variant="$1"
  local criteria_json="$2"
  local task="$3"
  local model="$4"

  local criteria_list
  criteria_list=$(echo "$criteria_json" | "$PYTHON3" -c "
import sys, json
criteria = json.load(sys.stdin)
lines = []
if isinstance(criteria, list):
    for i, c in enumerate(criteria):
        if isinstance(c, dict):
            lines.append(f\"{i+1}. {c.get('id', 'criterion_' + str(i+1))}: {c.get('description', '')}\")
        else:
            lines.append(f'{i+1}. {c}')
print(chr(10).join(lines))
")

  local system_prompt="You are a strict evaluator. Score content against specific criteria.
For each criterion, answer YES or NO. Be rigorous — do not give benefit of the doubt.
Output ONLY a JSON object with criterion IDs as keys and boolean values (true/false)."

  local user_prompt="TASK CONTEXT: $task

CONTENT TO EVALUATE:
---
$variant
---

CRITERIA (answer true/false for each):
$criteria_list

Respond with ONLY a JSON object like:
{\"criterion_id_1\": true, \"criterion_id_2\": false, ...}

Be strict. A criterion is only true if the content CLEARLY satisfies it."

  local raw_response
  raw_response=$(call_llm "$system_prompt" "$user_prompt" "$model")

  # Parse the evaluation response and compute score
  echo "$raw_response" | "$PYTHON3" -c "
import sys, json, re

raw = sys.stdin.read().strip()

# Extract JSON from response (handle markdown code blocks)
json_match = re.search(r'\{[^}]+\}', raw, re.DOTALL)
if json_match:
    raw = json_match.group(0)

try:
    scores = json.loads(raw)
    yes_count = sum(1 for v in scores.values() if v is True)
    total = len(scores)
    score = yes_count / total if total > 0 else 0
    result = {
        'criteria_scores': scores,
        'yes_count': yes_count,
        'total': total,
        'score': round(score, 4)
    }
    print(json.dumps(result))
except Exception as e:
    # Fallback: try to parse YES/NO from text
    lines = raw.split('\n')
    yes_count = sum(1 for l in lines if 'true' in l.lower() or 'yes' in l.lower())
    total = max(len(lines), 1)
    result = {
        'criteria_scores': {},
        'yes_count': yes_count,
        'total': total,
        'score': round(yes_count / total, 4),
        'parse_fallback': True,
        'raw': raw[:200]
    }
    print(json.dumps(result))
"
}

# Log experiment to learnings.json
log_experiment() {
  local learnings_file="$1"
  local iteration="$2"
  local variant_file="$3"
  local score="$4"
  local eval_json="$5"
  local kept="$6"
  local analysis="$7"
  local best_score="$8"

  "$PYTHON3" << PYEOF
import json, os
from datetime import datetime

learnings_file = "$learnings_file"
data = {"experiments": [], "best_score": 0, "total_improvements": 0, "started": "", "last_updated": ""}

if os.path.exists(learnings_file):
    try:
        with open(learnings_file, "r") as f:
            data = json.load(f)
    except:
        pass

if not data.get("started"):
    data["started"] = datetime.utcnow().isoformat() + "Z"
data["last_updated"] = datetime.utcnow().isoformat() + "Z"

experiment = {
    "iteration": int("$iteration"),
    "timestamp": datetime.utcnow().isoformat() + "Z",
    "variant_file": "$variant_file",
    "score": float("$score"),
    "best_score_at_time": float("$best_score"),
    "kept": "$kept" == "true",
    "analysis": """$analysis""",
    "eval": json.loads('''$eval_json''') if '''$eval_json''' else {}
}

data["experiments"].append(experiment)
data["best_score"] = max(float("$best_score"), data.get("best_score", 0))
if "$kept" == "true":
    data["total_improvements"] = data.get("total_improvements", 0) + 1

with open(learnings_file, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
}

# Analyze what made a variant better or worse
analyze_variant() {
  local variant="$1"
  local current_best="$2"
  local eval_json="$3"
  local kept="$4"
  local model="$5"

  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "Dry run — skipping analysis"
    return 0
  fi

  local status_word="BETTER"
  if [ "$kept" = "false" ]; then
    status_word="WORSE"
  fi

  local system_prompt="You are a concise analyst. In 1-2 sentences, explain why a content variant was $status_word than the current best. Focus on actionable patterns."

  local user_prompt="CURRENT BEST:
$current_best

NEW VARIANT ($status_word):
$variant

EVALUATION SCORES:
$eval_json

In 1-2 sentences, what specific pattern made this variant $status_word? Be concrete (e.g., 'Shorter headline improved hook power' or 'Lost brand voice by being too generic')."

  call_llm "$system_prompt" "$user_prompt" "$model"
}

###############################################################################
# Main
###############################################################################

main() {
  # Validate args
  if [ $# -lt 1 ]; then
    usage
  fi

  local config_file="$1"
  if [ ! -f "$config_file" ]; then
    log_error "Config file not found: $config_file"
    exit 1
  fi

  log_info "=== Auto-Research Loop Engine ==="
  log_info "Config: $config_file"
  log_info "Started: $TIMESTAMP"

  # Parse config
  export CONFIG_FILE="$config_file"
  local config_json
  config_json=$(parse_config "$config_file")

  if echo "$config_json" | grep -q '"error"'; then
    log_error "Failed to parse config: $(echo "$config_json" | json_get - error)"
    exit 1
  fi

  # Extract config values
  local objective
  objective=$(json_get "$config_json" "objective" "score")
  local task
  task=$(json_get "$config_json" "task" "Generate optimized content")
  local template
  template=$(json_get "$config_json" "template" "No template provided")
  local max_iterations
  max_iterations="${MAX_ITERATIONS:-$(json_get "$config_json" "max_iterations" "$DEFAULT_MAX_ITERATIONS")}"
  local model
  model="${MODEL:-$(json_get "$config_json" "model" "$DEFAULT_MODEL")}"
  local keep_threshold
  keep_threshold=$(json_get "$config_json" "keep_threshold" "")
  local brand
  brand=$(json_get "$config_json" "brand" "")

  # Get criteria
  local criteria_json
  criteria_json=$(json_get_criteria "$config_json")

  # Setup output directory
  local output_dir_raw
  output_dir_raw=$(json_get "$config_json" "output_dir" "$HOME/.openclaw/workspace/data/auto-research/run-$(date +%Y%m%d-%H%M%S)")
  local output_dir
  output_dir=$(ensure_dir "$output_dir_raw")
  local variants_dir
  variants_dir=$(ensure_dir "$output_dir/variants")

  local learnings_file="$output_dir/learnings.json"
  local best_file="$output_dir/best.txt"
  local best_score_file="$output_dir/best_score.json"

  log_info "Objective: $objective"
  log_info "Task: $task"
  log_info "Model: $model"
  log_info "Max iterations: $max_iterations"
  log_info "Output: $output_dir"

  # Load brand DNA if specified
  local brand_context=""
  if [ -n "$brand" ] && [ "$brand" != "null" ]; then
    local dna_file="/Users/jennwoeiloh/.openclaw/brands/$brand/DNA.json"
    if [ -f "$dna_file" ]; then
      brand_context="Brand DNA loaded from $dna_file"
      log_info "Brand DNA: $dna_file"
    else
      log_warn "Brand DNA not found: $dna_file"
    fi
  fi

  # Initialize best variant from template
  local current_best="$template"
  local current_best_score=0

  if [ -f "$best_file" ]; then
    current_best=$(cat "$best_file")
    if [ -f "$best_score_file" ]; then
      current_best_score=$("$PYTHON3" -c "import json; print(json.load(open('$best_score_file')).get('score', 0))")
    fi
    log_info "Resuming from prior best (score: $current_best_score)"
  else
    echo "$template" > "$best_file"
    echo '{"score": 0, "iteration": 0, "source": "template"}' > "$best_score_file"
    log_info "Starting from template (baseline)"
  fi

  # Evaluate baseline if score is 0
  if [ "$current_best_score" = "0" ]; then
    log_info "Evaluating baseline template..."
    local baseline_eval
    baseline_eval=$(evaluate_variant "$current_best" "$criteria_json" "$task" "$model")
    current_best_score=$(echo "$baseline_eval" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('score', 0))")
    echo "$baseline_eval" | "$PYTHON3" -c "
import sys, json
data = json.load(sys.stdin)
data['iteration'] = 0
data['source'] = 'template_baseline'
json.dump(data, sys.stdout, indent=2)
" > "$best_score_file"
    log_info "Baseline score: $current_best_score"
  fi

  # Main loop
  local improvements=0
  local iteration=1

  while [ "$iteration" -le "$max_iterations" ]; do
    log_info ""
    log_info "--- Iteration $iteration / $max_iterations ---"

    # 1. Generate variant
    log_info "Generating variant..."
    local variant
    variant=$(generate_variant "$task" "$current_best" "$learnings_file" "$criteria_json" "$model" "$iteration")

    if [ -z "$variant" ] || echo "$variant" | grep -qi "^error"; then
      log_warn "Generation failed, skipping iteration"
      iteration=$((iteration + 1))
      continue
    fi

    # Save variant
    local variant_num
    variant_num=$(printf "%03d" "$iteration")
    local variant_file="$variants_dir/${variant_num}.txt"
    echo "$variant" > "$variant_file"

    # 2. Evaluate variant
    log_info "Evaluating variant..."
    local eval_result
    eval_result=$(evaluate_variant "$variant" "$criteria_json" "$task" "$model")
    local new_score
    new_score=$(echo "$eval_result" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('score', 0))")
    echo "$eval_result" > "$variants_dir/${variant_num}_score.json"

    local yes_count
    yes_count=$(echo "$eval_result" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('yes_count', 0))")
    local total_criteria
    total_criteria=$(echo "$eval_result" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('total', 0))")

    log_info "Score: $new_score ($yes_count/$total_criteria criteria) vs current best: $current_best_score"

    # 3. Decide: keep or discard
    local kept="false"
    local threshold_to_beat="$current_best_score"

    if [ -n "$keep_threshold" ] && [ "$keep_threshold" != "null" ]; then
      # Use fixed threshold instead of must-beat-best
      local meets_threshold
      meets_threshold=$("$PYTHON3" -c "print('yes' if float('$new_score') >= float('$keep_threshold') else 'no')")
      if [ "$meets_threshold" = "yes" ]; then
        local is_better
        is_better=$("$PYTHON3" -c "print('yes' if float('$new_score') > float('$current_best_score') else 'no')")
        if [ "$is_better" = "yes" ]; then
          kept="true"
        fi
      fi
    else
      # Default: must beat current best
      local is_better
      is_better=$("$PYTHON3" -c "print('yes' if float('$new_score') > float('$current_best_score') else 'no')")
      if [ "$is_better" = "yes" ]; then
        kept="true"
      fi
    fi

    # 4. Analyze what worked or didn't
    log_info "Analyzing variant..."
    local analysis
    analysis=$(analyze_variant "$variant" "$current_best" "$eval_result" "$kept" "$model")

    # 5. Act on decision
    if [ "$kept" = "true" ]; then
      local delta
      delta=$("$PYTHON3" -c "print(round(float('$new_score') - float('$current_best_score'), 4))")
      log_info "KEPT — Score improved by $delta"
      echo "$variant" > "$best_file"
      echo "$eval_result" | "$PYTHON3" -c "
import sys, json
data = json.load(sys.stdin)
data['iteration'] = $iteration
data['source'] = 'auto-research'
json.dump(data, sys.stdout, indent=2)
" > "$best_score_file"
      current_best="$variant"
      current_best_score="$new_score"
      improvements=$((improvements + 1))
    else
      log_info "DISCARDED — Score did not improve"
    fi

    # 6. Log learnings
    log_experiment "$learnings_file" "$iteration" "$variant_file" "$new_score" \
      "$eval_result" "$kept" "$analysis" "$current_best_score"

    iteration=$((iteration + 1))
  done

  # Write run summary
  log_info ""
  log_info "=== Run Complete ==="
  log_info "Iterations: $((max_iterations))"
  log_info "Improvements: $improvements"
  log_info "Final best score: $current_best_score"
  log_info "Output: $output_dir"

  "$PYTHON3" << PYEOF
import json
from datetime import datetime

summary = {
    "run_id": "run-$(date +%Y%m%d-%H%M%S)",
    "started": "$TIMESTAMP",
    "completed": datetime.utcnow().isoformat() + "Z",
    "config_file": "$config_file",
    "objective": "$objective",
    "model": "$model",
    "total_iterations": int("$max_iterations"),
    "improvements": int("$improvements"),
    "final_best_score": float("$current_best_score"),
    "output_dir": "$output_dir"
}

with open("$output_dir/run_summary.json", "w") as f:
    json.dump(summary, f, indent=2)

print(json.dumps(summary, indent=2))
PYEOF

  # Emit pub-sub event if in Zennith OS context
  local rooms_dir="/Users/jennwoeiloh/.openclaw/workspace/rooms"
  if [ -d "$rooms_dir" ]; then
    local event_payload="{\"type\": \"auto-research.run.complete\", \"run_id\": \"run-$(date +%Y%m%d-%H%M%S)\", \"iterations\": $max_iterations, \"improvements\": $improvements, \"best_score\": $current_best_score, \"objective\": \"$objective\", \"output_dir\": \"$output_dir\"}"
    echo "$event_payload" >> "$rooms_dir/events.jsonl" 2>/dev/null || true
    log_info "Event emitted: auto-research.run.complete"
  fi
}

main "$@"
