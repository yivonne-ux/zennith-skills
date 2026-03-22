#!/usr/bin/env bash

# Fast-Iterate — Pre-Ship Quality Multiplier
# Generates N variants x K rounds with prompt evolution.
# Each round: generate → score → pick winner → analyze → rewrite prompt → repeat.
# Ships only the final winner.
#
# Usage:
#   fast-iterate.sh --task "Write an ad headline" \
#                   --criteria "hook_power,clarity,emotion" \
#                   --variants 3 --rounds 3 --model "claude-sonnet-4-6"
#
# macOS Bash 3.2 compatible. Requires: python3, curl.

set -euo pipefail

###############################################################################
# Constants & Defaults
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

DEFAULT_VARIANTS=3
DEFAULT_ROUNDS=3
DEFAULT_MODEL="claude-sonnet-4-6"
QUIET=false

###############################################################################
# Auto-detect OpenClaw API keys (native Zennith OS support)
###############################################################################
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
  OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
  if [ -f "${OPENCLAW_CONFIG}" ]; then
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
" 2>/dev/null)"
  fi
fi

###############################################################################
# Criteria Shorthand Dictionary
###############################################################################

# Expanded inline by python3 — maps short IDs to full descriptions
CRITERIA_DICT='{
  "hook_power": "Opens with a pattern interrupt or curiosity gap that stops the scroll",
  "clarity": "Main message is obvious within 3 seconds of reading",
  "emotion": "Triggers a specific emotion — not neutral or flat",
  "urgency": "Creates time pressure or reason to act now",
  "brand_voice": "Matches the brand established voice and tone",
  "social_proof": "Includes or implies social proof — reviews, numbers, community",
  "local_relevance": "Contains culturally relevant reference for target market",
  "specificity": "Uses specific numbers, names, or details — not vague",
  "curiosity": "Creates an information gap that compels further reading",
  "cta_strength": "Call to action is clear, specific, and compelling",
  "scannability": "Easy to scan on mobile — short paragraphs, bullets, hierarchy",
  "seo": "Naturally includes relevant search keywords",
  "personalization": "Feels personal and individually relevant",
  "trust": "Includes trust signals — credentials, guarantees, transparency",
  "value_framing": "Price or offer is framed as compelling value",
  "conciseness": "No wasted words — every sentence earns its place",
  "storytelling": "Uses narrative or anecdote to engage",
  "visual_hook": "Copy suggests or complements a strong visual",
  "objection_handling": "Preemptively addresses likely objections",
  "cultural_sensitivity": "Appropriate and respectful of cultural context"
}'

###############################################################################
# Helpers
###############################################################################

log_info()  { if [ "$QUIET" = "false" ]; then echo "[fast-iterate] $(date +"%H:%M:%S") INFO  $*"; fi; }
log_warn()  { echo "[fast-iterate] $(date +"%H:%M:%S") WARN  $*" >&2; }
log_error() { echo "[fast-iterate] $(date +"%H:%M:%S") ERROR $*" >&2; }

usage() {
  cat << 'EOF'
Usage: fast-iterate.sh --task "..." --criteria "id1,id2,id3" [options]

Required:
  --task TEXT           What to generate (the creative brief)
  --criteria IDS        Comma-separated criteria IDs (e.g., "hook_power,clarity,emotion")

Options:
  --variants N          Variants per round (default: 3)
  --rounds N            Iteration rounds (default: 3)
  --model NAME          LLM model (default: claude-sonnet-4-6)
  --brand NAME          Brand name — loads DNA.json for context
  --output-dir PATH     Where to save results
  --criteria-file PATH  JSON file with [{id, description}] for custom criteria
  --quiet               Output only the final winner (for piping)
  --help                Show this help

Environment:
  ANTHROPIC_API_KEY     Required for Claude models
  OPENAI_API_KEY        Required for OpenAI models
  DRY_RUN=1             Print prompts without calling LLM

Criteria shorthand IDs:
  hook_power, clarity, emotion, urgency, brand_voice, social_proof,
  local_relevance, specificity, curiosity, cta_strength, scannability,
  seo, personalization, trust, value_framing, conciseness, storytelling,
  visual_hook, objection_handling, cultural_sensitivity
EOF
  exit 1
}

ensure_dir() {
  local dir="$1"
  dir="${dir/#\~/$HOME}"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
  echo "$dir"
}

# Call LLM API
call_llm() {
  local system_prompt="$1"
  local user_prompt="$2"
  local model="$3"

  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[DRY RUN] Model=$model, prompt=${#user_prompt} chars"
    return 0
  fi

  if echo "$model" | grep -q "^claude"; then
    local api_key="${ANTHROPIC_API_KEY:-}"
    if [ -z "$api_key" ]; then
      log_error "ANTHROPIC_API_KEY not set"
      return 1
    fi

    # Build JSON payload via temp files (avoids all quoting issues)
    local tmp_sys=$(mktemp)
    local tmp_usr=$(mktemp)
    local tmp_payload=$(mktemp)
    printf '%s' "$system_prompt" > "$tmp_sys"
    printf '%s' "$user_prompt" > "$tmp_usr"
    "$PYTHON3" - "$tmp_sys" "$tmp_usr" "$model" << 'PYEOF' > "$tmp_payload"
import json, sys
with open(sys.argv[1]) as f: system = f.read()
with open(sys.argv[2]) as f: user = f.read()
model = sys.argv[3]
print(json.dumps({"model": model, "max_tokens": 4096, "system": system, "messages": [{"role": "user", "content": user}]}))
PYEOF

    local response
    response=$(curl -s --max-time 120 \
      "https://api.anthropic.com/v1/messages" \
      -H "x-api-key: $api_key" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d @"$tmp_payload")
    rm -f "$tmp_sys" "$tmp_usr" "$tmp_payload"

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
        print('ERROR: Unexpected response', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print('ERROR: ' + str(e), file=sys.stderr)
    sys.exit(1)
"
  else
    local api_key="${OPENAI_API_KEY:-}"
    local api_base="${OPENAI_API_BASE:-https://api.openai.com/v1}"
    if [ -z "$api_key" ]; then
      log_error "OPENAI_API_KEY not set"
      return 1
    fi

    local tmp_sys2=$(mktemp)
    local tmp_usr2=$(mktemp)
    local tmp_payload2=$(mktemp)
    printf '%s' "$system_prompt" > "$tmp_sys2"
    printf '%s' "$user_prompt" > "$tmp_usr2"
    "$PYTHON3" - "$tmp_sys2" "$tmp_usr2" "$model" << 'PYEOF' > "$tmp_payload2"
import json, sys
with open(sys.argv[1]) as f: system = f.read()
with open(sys.argv[2]) as f: user = f.read()
model = sys.argv[3]
print(json.dumps({"model": model, "max_tokens": 4096, "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]}))
PYEOF

    local response
    response=$(curl -s --max-time 120 \
      "${api_base}/chat/completions" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json" \
      -d @"$tmp_payload2")
    rm -f "$tmp_sys2" "$tmp_usr2" "$tmp_payload2"

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
        print('ERROR: Unexpected response', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print('ERROR: ' + str(e), file=sys.stderr)
    sys.exit(1)
"
  fi
}

# Expand criteria shorthand IDs to full descriptions
expand_criteria() {
  local criteria_csv="$1"
  local criteria_file="${2:-}"

  if [ -n "$criteria_file" ] && [ -f "$criteria_file" ]; then
    cat "$criteria_file"
    return
  fi

  "$PYTHON3" -c "
import json

criteria_dict = json.loads('''$CRITERIA_DICT''')
ids = [x.strip() for x in '''$criteria_csv'''.split(',') if x.strip()]

result = []
for cid in ids:
    desc = criteria_dict.get(cid, 'Satisfies the ' + cid + ' criterion')
    result.append({'id': cid, 'description': desc})

print(json.dumps(result))
"
}

###############################################################################
# Core Functions
###############################################################################

# Generate N variants in a single LLM call
generate_variants() {
  local task="$1"
  local num_variants="$2"
  local criteria_json="$3"
  local model="$4"
  local round_num="$5"
  local evolved_prompt="$6"
  local brand_context="$7"

  local criteria_desc
  criteria_desc=$(echo "$criteria_json" | "$PYTHON3" -c "
import sys, json
criteria = json.load(sys.stdin)
for c in criteria:
    print(f\"- {c['id']}: {c['description']}\")
")

  local system_prompt="You are a world-class creative generator. Your output will be scored on specific criteria.
Generate exactly $num_variants distinct variants. Each should take a DIFFERENT creative approach.
Format: separate each variant with a line containing only '---VARIANT---'.
Output ONLY the variants with separators. No numbering, no labels, no explanations."

  local user_prompt="TASK: $task
$brand_context

SCORING CRITERIA (you will be judged on each):
$criteria_desc

$evolved_prompt

Generate $num_variants DISTINCT variants. Separate each with a line containing only '---VARIANT---'.
Each variant should explore a different creative angle while maximizing criteria scores."

  call_llm "$system_prompt" "$user_prompt" "$model"
}

# Score a single variant against criteria
score_variant() {
  local variant="$1"
  local criteria_json="$2"
  local task="$3"
  local model="$4"

  local criteria_list
  criteria_list=$(echo "$criteria_json" | "$PYTHON3" -c "
import sys, json
criteria = json.load(sys.stdin)
for i, c in enumerate(criteria):
    print(f\"{i+1}. {c['id']}: {c['description']}\")
")

  local system_prompt="You are a strict content evaluator. Score content against binary criteria.
For each criterion, answer true (clearly satisfied) or false (not satisfied or ambiguous).
Be rigorous. Output ONLY a JSON object with criterion IDs as keys and boolean values."

  local user_prompt="TASK CONTEXT: $task

CONTENT TO EVALUATE:
---
$variant
---

CRITERIA:
$criteria_list

Respond with ONLY a JSON object: {\"criterion_id\": true/false, ...}
Be strict. Only mark true if the criterion is CLEARLY satisfied."

  local raw_response
  raw_response=$(call_llm "$system_prompt" "$user_prompt" "$model")

  echo "$raw_response" | "$PYTHON3" -c "
import sys, json, re

raw = sys.stdin.read().strip()
json_match = re.search(r'\{[^}]*\}', raw, re.DOTALL)
if json_match:
    raw = json_match.group(0)

try:
    scores = json.loads(raw)
    yes_count = sum(1 for v in scores.values() if v is True)
    total = len(scores)
    score = yes_count / total if total > 0 else 0
    print(json.dumps({
        'criteria_scores': scores,
        'yes_count': yes_count,
        'total': total,
        'score': round(score, 4)
    }))
except Exception as e:
    lines = raw.split('\n')
    yes_count = sum(1 for l in lines if 'true' in l.lower())
    total = max(len(lines), 1)
    print(json.dumps({
        'criteria_scores': {},
        'yes_count': yes_count,
        'total': total,
        'score': round(yes_count / total, 4),
        'parse_fallback': True
    }))
"
}

# Analyze what made the winner best and generate prompt improvements
analyze_round() {
  local winner="$1"
  local all_variants_json="$2"
  local criteria_json="$3"
  local round_num="$4"
  local model="$5"

  local system_prompt="You are a creative strategist analyzing why certain content variants outperform others.
Your analysis will be used to REWRITE the generation prompt for the next round.
Be specific and actionable. Output two sections:
1. ANALYSIS: 2-3 sentences on what made the winner best
2. PROMPT_ADDITIONS: Bullet points of specific instructions to add to the prompt"

  local user_prompt="ROUND $round_num RESULTS:

WINNER:
$winner

ALL VARIANTS WITH SCORES:
$all_variants_json

CRITERIA:
$(echo "$criteria_json" | "$PYTHON3" -c "
import sys, json
for c in json.load(sys.stdin):
    print(f\"- {c['id']}: {c['description']}\")
")

Analyze:
1. What specific patterns made the winner score highest?
2. What did losing variants lack?
3. What concrete instructions should we add to the prompt for Round $((round_num + 1))?

Format your response as:
ANALYSIS: [2-3 sentences]
PROMPT_ADDITIONS:
- [specific instruction 1]
- [specific instruction 2]
- [specific instruction 3]"

  call_llm "$system_prompt" "$user_prompt" "$model"
}

###############################################################################
# Argument Parsing
###############################################################################

TASK=""
CRITERIA_CSV=""
CRITERIA_FILE=""
NUM_VARIANTS=$DEFAULT_VARIANTS
NUM_ROUNDS=$DEFAULT_ROUNDS
MODEL=$DEFAULT_MODEL
BRAND=""
OUTPUT_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --task)       TASK="$2"; shift 2 ;;
    --criteria)   CRITERIA_CSV="$2"; shift 2 ;;
    --criteria-file) CRITERIA_FILE="$2"; shift 2 ;;
    --variants)   NUM_VARIANTS="$2"; shift 2 ;;
    --rounds)     NUM_ROUNDS="$2"; shift 2 ;;
    --model)      MODEL="$2"; shift 2 ;;
    --brand)      BRAND="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --quiet)      QUIET=true; shift ;;
    --help|-h)    usage ;;
    *)            log_error "Unknown option: $1"; usage ;;
  esac
done

# Validate required args
if [ -z "$TASK" ]; then
  log_error "--task is required"
  usage
fi
if [ -z "$CRITERIA_CSV" ] && [ -z "$CRITERIA_FILE" ]; then
  log_error "--criteria or --criteria-file is required"
  usage
fi

###############################################################################
# Main
###############################################################################

main() {
  log_info "=== Fast-Iterate: Pre-Ship Quality Multiplier ==="
  log_info "Task: $TASK"
  log_info "Model: $MODEL"
  log_info "Variants per round: $NUM_VARIANTS"
  log_info "Rounds: $NUM_ROUNDS"

  # Expand criteria
  local criteria_json
  criteria_json=$(expand_criteria "$CRITERIA_CSV" "$CRITERIA_FILE")
  local criteria_count
  criteria_count=$(echo "$criteria_json" | "$PYTHON3" -c "import sys,json; print(len(json.load(sys.stdin)))")
  log_info "Criteria: $criteria_count dimensions"

  # Setup output directory
  if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$HOME/.openclaw/workspace/data/fast-iterate/run-$(date +%Y%m%d-%H%M%S)"
  fi
  OUTPUT_DIR=$(ensure_dir "$OUTPUT_DIR")
  log_info "Output: $OUTPUT_DIR"

  # Load brand context
  local brand_context=""
  if [ -n "$BRAND" ]; then
    local dna_file="/Users/jennwoeiloh/.openclaw/brands/$BRAND/DNA.json"
    if [ -f "$dna_file" ]; then
      brand_context="BRAND CONTEXT: Loaded from $BRAND DNA. Match this brand's voice and tone."
      log_info "Brand: $BRAND (DNA loaded)"
    else
      brand_context="BRAND: $BRAND"
      log_warn "Brand DNA not found at $dna_file — using name only"
    fi
  fi

  # Initialize tracking
  local evolved_prompt=""
  local scoring_log="[]"
  local prompt_evolution="[]"
  local global_best_variant=""
  local global_best_score=0
  local global_best_round=0

  # Multi-round tournament
  local round=1
  while [ "$round" -le "$NUM_ROUNDS" ]; do
    log_info ""
    log_info "=== Round $round / $NUM_ROUNDS ==="

    local round_dir
    round_dir=$(ensure_dir "$OUTPUT_DIR/rounds/round_$(printf "%02d" "$round")")

    # Save prompt used this round
    local prompt_for_round="ROUND $round INSTRUCTIONS:
$evolved_prompt"
    echo "$prompt_for_round" > "$round_dir/prompt_used.txt"

    # 1. Generate variants
    log_info "Generating $NUM_VARIANTS variants..."
    local raw_variants
    raw_variants=$(generate_variants "$TASK" "$NUM_VARIANTS" "$criteria_json" "$MODEL" "$round" "$evolved_prompt" "$brand_context")

    # Parse variants into individual items
    local variants_json
    variants_json=$(echo "$raw_variants" | "$PYTHON3" -c "
import sys, json

raw = sys.stdin.read()
# Split on separator
parts = raw.split('---VARIANT---')
variants = [p.strip() for p in parts if p.strip()]

# If splitting produced nothing useful, treat entire output as one variant
if not variants:
    variants = [raw.strip()]

# If we got fewer than expected, that's ok — work with what we have
result = []
for i, v in enumerate(variants):
    result.append({'index': i+1, 'text': v})

print(json.dumps(result))
")

    local actual_count
    actual_count=$(echo "$variants_json" | "$PYTHON3" -c "import sys,json; print(len(json.load(sys.stdin)))")
    log_info "Generated $actual_count variants"

    # 2. Score each variant
    log_info "Scoring variants..."
    local round_results="[]"
    local best_idx=0
    local best_score=0
    local best_text=""

    local var_idx=0
    while [ "$var_idx" -lt "$actual_count" ]; do
      local variant_text
      variant_text=$(echo "$variants_json" | "$PYTHON3" -c "
import sys, json
variants = json.load(sys.stdin)
idx = int('$var_idx')
if idx < len(variants):
    print(variants[idx]['text'])
else:
    print('')
")

      if [ -z "$variant_text" ]; then
        var_idx=$((var_idx + 1))
        continue
      fi

      local eval_result
      eval_result=$(score_variant "$variant_text" "$criteria_json" "$TASK" "$MODEL")

      local var_score
      var_score=$(echo "$eval_result" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('score', 0))")
      local yes_count
      yes_count=$(echo "$eval_result" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('yes_count', 0))")
      local total
      total=$(echo "$eval_result" | "$PYTHON3" -c "import sys,json; print(json.load(sys.stdin).get('total', 0))")

      log_info "  Variant $((var_idx + 1)): $var_score ($yes_count/$total criteria)"

      # Save individual variant
      echo "$variant_text" > "$round_dir/variant_$(printf "%02d" $((var_idx + 1))).txt"

      # Update round results
      round_results=$("$PYTHON3" -c "
import json, sys
results = json.loads('''$round_results''')
results.append({
    'variant_index': $((var_idx + 1)),
    'score': float('$var_score'),
    'yes_count': int('$yes_count'),
    'total': int('$total'),
    'eval': json.loads('''$eval_result'''),
    'text': '''$variant_text'''
})
print(json.dumps(results))
")

      # Track best in round
      local is_best
      is_best=$("$PYTHON3" -c "print('yes' if float('$var_score') > float('$best_score') else 'no')")
      if [ "$is_best" = "yes" ]; then
        best_score="$var_score"
        best_idx=$((var_idx + 1))
        best_text="$variant_text"
      fi

      var_idx=$((var_idx + 1))
    done

    # Save round winner
    log_info "Round $round winner: Variant $best_idx (score: $best_score)"
    echo "$best_text" > "$round_dir/winner.txt"

    # Track global best
    local is_global_best
    is_global_best=$("$PYTHON3" -c "print('yes' if float('$best_score') > float('$global_best_score') else 'no')")
    if [ "$is_global_best" = "yes" ]; then
      global_best_score="$best_score"
      global_best_variant="$best_text"
      global_best_round="$round"
    fi

    # Save round results
    echo "$round_results" | "$PYTHON3" -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, indent=2)" > "$round_dir/variants.json"

    # 3. Analyze and evolve prompt (skip analysis on last round)
    if [ "$round" -lt "$NUM_ROUNDS" ]; then
      log_info "Analyzing round and evolving prompt..."
      local analysis
      analysis=$(analyze_round "$best_text" "$round_results" "$criteria_json" "$round" "$MODEL")
      echo "$analysis" > "$round_dir/analysis.txt"

      # Extract prompt additions from analysis
      local new_instructions
      new_instructions=$(echo "$analysis" | "$PYTHON3" -c "
import sys
text = sys.stdin.read()
# Extract everything after PROMPT_ADDITIONS:
if 'PROMPT_ADDITIONS:' in text:
    additions = text.split('PROMPT_ADDITIONS:')[1].strip()
    print(additions)
elif 'prompt' in text.lower() or 'instruction' in text.lower():
    # Fallback: use the whole analysis as guidance
    print(text.strip())
else:
    print(text.strip())
")

      # Evolve the prompt
      if [ -z "$evolved_prompt" ]; then
        evolved_prompt="Based on Round $round analysis, follow these guidelines:
$new_instructions"
      else
        evolved_prompt="$evolved_prompt

Additional learnings from Round $round:
$new_instructions"
      fi

      log_info "Prompt evolved with Round $round learnings"
    fi

    # Update scoring log
    scoring_log=$("$PYTHON3" -c "
import json
log = json.loads('''$scoring_log''')
log.append({
    'round': int('$round'),
    'winner_index': int('$best_idx'),
    'winner_score': float('$best_score'),
    'variants_scored': int('$actual_count')
})
print(json.dumps(log))
")

    # Update prompt evolution
    prompt_evolution=$("$PYTHON3" -c "
import json
evo = json.loads('''$prompt_evolution''')
evo.append({
    'round': int('$round'),
    'prompt': '''$evolved_prompt''' if '''$evolved_prompt''' else '(original task only)'
})
print(json.dumps(evo))
")

    round=$((round + 1))
  done

  # Write final outputs
  log_info ""
  log_info "=== Tournament Complete ==="
  log_info "Final winner from Round $global_best_round (score: $global_best_score)"

  echo "$global_best_variant" > "$OUTPUT_DIR/winner.txt"

  # Write scoring log
  echo "$scoring_log" | "$PYTHON3" -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, indent=2)" > "$OUTPUT_DIR/scoring_log.json"

  # Write prompt evolution
  echo "$prompt_evolution" | "$PYTHON3" -c "import sys,json; json.dump(json.load(sys.stdin), sys.stdout, indent=2)" > "$OUTPUT_DIR/prompt_evolution.json"

  # Write summary
  "$PYTHON3" << PYEOF
import json
from datetime import datetime

summary = {
    "task": """$TASK""",
    "model": "$MODEL",
    "brand": "$BRAND" if "$BRAND" else None,
    "variants_per_round": int("$NUM_VARIANTS"),
    "rounds": int("$NUM_ROUNDS"),
    "criteria_count": int("$criteria_count"),
    "final_score": float("$global_best_score"),
    "winning_round": int("$global_best_round"),
    "started": "$TIMESTAMP",
    "completed": datetime.utcnow().isoformat() + "Z",
    "output_dir": "$OUTPUT_DIR"
}

with open("$OUTPUT_DIR/run_summary.json", "w") as f:
    json.dump(summary, f, indent=2)
PYEOF

  # Emit pub-sub event
  local rooms_dir="/Users/jennwoeiloh/.openclaw/workspace/rooms"
  if [ -d "$rooms_dir" ]; then
    "$PYTHON3" -c "
import json
event = {
    'type': 'fast-iterate.complete',
    'task': '''$TASK''',
    'final_score': float('$global_best_score'),
    'rounds': int('$NUM_ROUNDS'),
    'model': '$MODEL',
    'output_dir': '$OUTPUT_DIR'
}
print(json.dumps(event))
" >> "$rooms_dir/events.jsonl" 2>/dev/null || true
    log_info "Event emitted: fast-iterate.complete"
  fi

  # Final output
  if [ "$QUIET" = "true" ]; then
    # Quiet mode: output only the winner
    cat "$OUTPUT_DIR/winner.txt"
  else
    log_info ""
    log_info "Results saved to: $OUTPUT_DIR"
    log_info "Winner: $OUTPUT_DIR/winner.txt"
    log_info "Scoring log: $OUTPUT_DIR/scoring_log.json"
    log_info "Prompt evolution: $OUTPUT_DIR/prompt_evolution.json"
    log_info ""
    log_info "--- Final Winner ---"
    cat "$OUTPUT_DIR/winner.txt"
  fi
}

main
