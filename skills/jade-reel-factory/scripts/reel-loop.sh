#!/usr/bin/env bash
# reel-loop.sh — Auto-research improvement loop for Jade Oracle reels
# macOS Bash 3.2 compatible: no declare -A, no timeout, no ${var,,}
#
# Generates reel variants, audits them, keeps the best, compounds learnings.
# Inspired by Karpathy's autoresearch: generate -> eval -> keep-or-discard -> repeat.
#
# Usage:
#   bash reel-loop.sh
#   bash reel-loop.sh --iterations 10 --style kling
#   bash reel-loop.sh --blueprint blueprints/reel-abc123-analysis.json
#   bash reel-loop.sh --iterations 5 --publish --dry-run
#
# Options:
#   --iterations N       Number of improvement iterations (default: 5)
#   --style STYLE        Video style: ken-burns|kling|sora|wan (default: ken-burns)
#   --blueprint PATH     Reel blueprint JSON (default: latest from blueprints dir)
#   --dry-run            Show what would happen without executing
#   --publish            Publish the winning reel to IG after loop completes

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

###############################################################################
# Constants
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SKILL_DIR/configs/jade-reel-factory.yaml"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DATE_STAMP="$(date +"%Y%m%d")"

# Sibling scripts
REEL_GENERATOR="$SCRIPT_DIR/reel-generator.sh"
REEL_AUDITOR="$SCRIPT_DIR/reel-auditor.sh"
REEL_PUBLISH="$SCRIPT_DIR/reel-publish.sh"

# Output paths
PIPELINE_DIR="$HOME/.openclaw/workspace/data/jade-oracle-content-pipeline"
OUTPUT_DIR="$PIPELINE_DIR/reel-variants"
BLUEPRINTS_DIR="$SKILL_DIR/data/blueprints"
LOG_FILE="$HOME/.openclaw/logs/jade-reel-factory.log"
LOOP_LOG="$OUTPUT_DIR/loop-log.jsonl"
LEARNINGS_FILE="$OUTPUT_DIR/reel-learnings.json"
BEST_REEL="$OUTPUT_DIR/best-reel.mp4"
BEST_AUDIT="$OUTPUT_DIR/best-reel-audit.json"

# Room for async notifications
ROOM_FILE="$HOME/.openclaw/workspace/rooms/mission-jade-oracle-launch.jsonl"

# Defaults
ITERATIONS=5
STYLE="ken-burns"
BLUEPRINT=""
DRY_RUN=false
PUBLISH=false

# Compound learning
DIGEST="$HOME/.openclaw/skills/knowledge-compound/scripts/digest.sh"

###############################################################################
# Helpers
###############################################################################

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [reel-loop] $1"
  echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
  echo "$msg" >&2
}

info() {
  echo "[ReelLoop] $1"
  log "$1"
}

warn() {
  echo "[ReelLoop] WARN: $1" >&2
  log "WARN: $1"
}

error() {
  echo "[ReelLoop] ERROR: $1" >&2
  log "ERROR: $1"
}

###############################################################################
# Parse arguments
###############################################################################

while [ $# -gt 0 ]; do
  case "$1" in
    --iterations)
      shift
      if [ $# -eq 0 ]; then error "--iterations requires a number"; exit 1; fi
      ITERATIONS="$1"
      ;;
    --style)
      shift
      if [ $# -eq 0 ]; then error "--style requires a value"; exit 1; fi
      case "$1" in
        ken-burns|kling|sora|wan) STYLE="$1" ;;
        *) error "Invalid style: $1 (must be ken-burns|kling|sora|wan)"; exit 1 ;;
      esac
      ;;
    --blueprint)
      shift
      if [ $# -eq 0 ]; then error "--blueprint requires a path"; exit 1; fi
      BLUEPRINT="$1"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --publish)
      PUBLISH=true
      ;;
    --help|-h)
      echo "reel-loop.sh — Auto-research improvement loop for Jade Oracle reels"
      echo ""
      echo "Usage: bash reel-loop.sh [options]"
      echo ""
      echo "Options:"
      echo "  --iterations N      Improvement iterations (default: 5)"
      echo "  --style STYLE       ken-burns|kling|sora|wan (default: ken-burns)"
      echo "  --blueprint PATH    Reel blueprint JSON (default: latest from blueprints)"
      echo "  --dry-run           Preview without executing"
      echo "  --publish           Post winning reel to IG if score >= 7.0"
      echo "  --help              Show this help"
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

###############################################################################
# Resolve blueprint
###############################################################################

resolve_blueprint() {
  if [ -n "$BLUEPRINT" ]; then
    if [ ! -f "$BLUEPRINT" ]; then
      error "Blueprint not found: $BLUEPRINT"
      exit 1
    fi
    echo "$BLUEPRINT"
    return
  fi

  # Find latest blueprint in the blueprints directory
  if [ ! -d "$BLUEPRINTS_DIR" ]; then
    warn "Blueprints directory not found: $BLUEPRINTS_DIR"
    echo ""
    return
  fi

  # macOS-compatible: use ls -t to find most recent .json file
  local latest=""
  for f in "$BLUEPRINTS_DIR"/*.json; do
    if [ -f "$f" ]; then
      if [ -z "$latest" ]; then
        latest="$f"
      else
        # Compare modification times using stat (macOS format)
        local ts_f ts_latest
        ts_f=$(stat -f "%m" "$f" 2>/dev/null || echo "0")
        ts_latest=$(stat -f "%m" "$latest" 2>/dev/null || echo "0")
        if [ "$ts_f" -gt "$ts_latest" ]; then
          latest="$f"
        fi
      fi
    fi
  done

  if [ -n "$latest" ]; then
    echo "$latest"
  else
    warn "No blueprints found in $BLUEPRINTS_DIR"
    echo ""
  fi
}

###############################################################################
# Parse config (minimal YAML parser via python3)
###############################################################################

parse_keep_threshold() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "7.0"
    return
  fi

  "$PYTHON3" -c "
import sys
threshold = '7.0'
try:
    with open('$CONFIG_FILE', 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('keep_threshold:'):
                val = line.split(':', 1)[1].strip().strip('\"').strip(\"'\")
                threshold = val
                break
except:
    pass
print(threshold)
" 2>/dev/null || echo "7.0"
}

###############################################################################
# Read audit score from JSON
###############################################################################

read_audit_score() {
  local audit_json="$1"

  if [ ! -f "$audit_json" ]; then
    echo "0"
    return
  fi

  "$PYTHON3" -c "
import json, sys
try:
    with open('$audit_json', 'r') as f:
        data = json.load(f)
    # Support both flat 'score' and nested 'overall_score'
    score = data.get('overall_score', data.get('score', 0))
    if isinstance(score, dict):
        score = score.get('value', score.get('total', 0))
    print(float(score))
except Exception as e:
    print('0', file=sys.stderr)
    print('0')
" 2>/dev/null || echo "0"
}

###############################################################################
# Analyze variant via Claude CLI (why better/worse)
###############################################################################

analyze_variant() {
  local variant_path="$1"
  local audit_json="$2"
  local is_better="$3"  # "true" or "false"

  if [ "$DRY_RUN" = "true" ]; then
    echo "Dry run -- skipping analysis"
    return
  fi

  local status_word="BETTER"
  if [ "$is_better" = "false" ]; then
    status_word="WORSE"
  fi

  local prompt="Analyze this reel variant audit. The variant scored $status_word than the current best.

Audit JSON: $(cat "$audit_json" 2>/dev/null || echo '{}')

In 1-2 sentences, explain the specific pattern that made this variant ${status_word}. Be concrete (e.g., 'Ken Burns zoom was too fast, causing motion blur' or 'Hook text appeared at 0.5s instead of immediately'). Focus on actionable insights for the next iteration."

  # Try claude CLI first (MacBook OAuth, $0)
  local claude_cli
  claude_cli=$(command -v claude 2>/dev/null || echo "")
  if [ -n "$claude_cli" ]; then
    local result
    result=$(echo "$prompt" | "$claude_cli" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
    if [ -n "$result" ]; then
      echo "$result"
      return
    fi
  fi

  # Fallback: basic analysis from audit JSON
  "$PYTHON3" -c "
import json, sys
try:
    with open('$audit_json', 'r') as f:
        data = json.load(f)
    scores = data.get('criteria_scores', data.get('scores', {}))
    low_scores = []
    high_scores = []
    for k, v in scores.items():
        if isinstance(v, (int, float)):
            if v < 6:
                low_scores.append(f'{k}={v}')
            elif v >= 8:
                high_scores.append(f'{k}={v}')
    if '$is_better' == 'true':
        print(f'Improved on: {\", \".join(high_scores[:3]) if high_scores else \"multiple criteria\"}')
    else:
        print(f'Weak areas: {\", \".join(low_scores[:3]) if low_scores else \"below threshold overall\"}')
except:
    print('Could not extract analysis from audit data.')
" 2>/dev/null || echo "Analysis unavailable."
}

###############################################################################
# Update learnings.json (append-only compound learning)
###############################################################################

update_learnings() {
  local iteration="$1"
  local score="$2"
  local is_better="$3"
  local analysis="$4"
  local variant_file="$5"
  local audit_file="$6"

  export _ANALYSIS="$analysis"

  "$PYTHON3" << PYEOF
import json, os
from datetime import datetime

learnings_file = "$LEARNINGS_FILE"
data = {
    "skill": "jade-reel-factory",
    "brand": "jade-oracle",
    "experiments": [],
    "best_score": 0,
    "total_improvements": 0,
    "started": "",
    "last_updated": ""
}

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
    "audit_file": "$audit_file",
    "score": float("$score"),
    "kept": "$is_better" == "true",
    "style": "$STYLE",
    "analysis": os.environ.get("_ANALYSIS", "")
}

data["experiments"].append(experiment)
if "$is_better" == "true":
    data["best_score"] = max(float("$score"), data.get("best_score", 0))
    data["total_improvements"] = data.get("total_improvements", 0) + 1

with open(learnings_file, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
}

###############################################################################
# Log iteration to loop-log.jsonl
###############################################################################

log_iteration() {
  local iteration="$1"
  local variant_file="$2"
  local audit_file="$3"
  local score="$4"
  local best_score="$5"
  local kept="$6"
  local analysis="$7"

  export _LOG_ANALYSIS="$analysis"

  "$PYTHON3" -c "
import json, os
from datetime import datetime

entry = {
    'timestamp': datetime.utcnow().isoformat() + 'Z',
    'iteration': int('$iteration'),
    'variant_file': '$variant_file',
    'audit_file': '$audit_file',
    'score': float('$score'),
    'best_score': float('$best_score'),
    'kept': '$kept' == 'true',
    'style': '$STYLE',
    'analysis': os.environ.get('_LOG_ANALYSIS', '')
}

with open('$LOOP_LOG', 'a') as f:
    f.write(json.dumps(entry) + '\n')
" 2>/dev/null || warn "Failed to write loop log entry"
}

###############################################################################
# Post room notification
###############################################################################

notify_room() {
  local message="$1"

  if [ ! -d "$(dirname "$ROOM_FILE")" ]; then
    return
  fi

  "$PYTHON3" -c "
import json
from datetime import datetime

entry = {
    'timestamp': datetime.utcnow().isoformat() + 'Z',
    'agent': 'taoz',
    'type': 'reel-loop',
    'message': '''$message'''
}

with open('$ROOM_FILE', 'a') as f:
    f.write(json.dumps(entry) + '\n')
" 2>/dev/null || true
}

###############################################################################
# Main loop
###############################################################################

main() {
  info "=== Jade Reel Factory -- Auto-Research Improvement Loop ==="
  info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
  info "Iterations: $ITERATIONS"
  info "Style: $STYLE"
  info "Publish: $PUBLISH"
  if [ "$DRY_RUN" = "true" ]; then
    info "Mode: DRY RUN"
  fi
  echo ""

  # Ensure output directories exist
  mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
  mkdir -p "$BLUEPRINTS_DIR" 2>/dev/null || true

  # Resolve blueprint
  local blueprint
  blueprint=$(resolve_blueprint)

  if [ -z "$blueprint" ]; then
    warn "No blueprint available. Run reel-reverse-engineer.sh first to create one."
    warn "Continuing with config-only mode (no blueprint-driven generation)."
  else
    info "Blueprint: $blueprint"
  fi

  # Read keep threshold from config
  local keep_threshold
  keep_threshold=$(parse_keep_threshold)
  info "Keep threshold: >= $keep_threshold"
  info "Config: $CONFIG_FILE"
  info "Output: $OUTPUT_DIR"
  echo ""

  # Track state
  local current_best_score=0
  local improvements=0

  # Load existing best score if resuming
  if [ -f "$BEST_AUDIT" ]; then
    current_best_score=$(read_audit_score "$BEST_AUDIT")
    info "Resuming from prior best (score: $current_best_score)"
  fi

  # --- Main iteration loop ---
  local iteration=1
  while [ "$iteration" -le "$ITERATIONS" ]; do
    echo ""
    info "--- Iteration $iteration / $ITERATIONS ---"

    local variant_ts
    variant_ts="$(date +"%Y%m%d-%H%M%S")"
    local variant_file="$OUTPUT_DIR/variant-${variant_ts}.mp4"
    local audit_file="$OUTPUT_DIR/variant-${variant_ts}-audit.json"

    # Step 1: Generate reel variant
    info "[1/4] Generating reel variant (style: $STYLE)..."

    if [ "$DRY_RUN" = "true" ]; then
      info "[DRY-RUN] Would execute: reel-generator.sh --style $STYLE"
      if [ -n "$blueprint" ]; then
        info "  --blueprint $blueprint"
      fi
      info "  Output: $variant_file"
    else
      local gen_args="--style $STYLE"
      if [ -n "$blueprint" ]; then
        gen_args="$gen_args --blueprint $blueprint"
      fi

      if [ -f "$REEL_GENERATOR" ]; then
        local gen_exit=0
        bash "$REEL_GENERATOR" $gen_args --output "$variant_file" 2>&1 | while IFS= read -r line; do
          info "  [gen] $line"
        done || gen_exit=$?

        if [ "$gen_exit" -ne 0 ] || [ ! -f "$variant_file" ]; then
          warn "Generation failed on iteration $iteration, skipping"
          log_iteration "$iteration" "$variant_file" "" "0" "$current_best_score" "false" "Generation failed"
          iteration=$((iteration + 1))
          continue
        fi
      else
        warn "reel-generator.sh not found at $REEL_GENERATOR"
        warn "Skipping iteration (install reel-generator.sh to enable generation)"
        iteration=$((iteration + 1))
        continue
      fi
    fi

    # Step 2: Audit variant
    info "[2/4] Auditing variant..."

    local new_score=0
    if [ "$DRY_RUN" = "true" ]; then
      info "[DRY-RUN] Would execute: reel-auditor.sh --input $variant_file"
      # Simulate a random-ish score for dry run display
      new_score="5.0"
      info "  [DRY-RUN] Simulated score: $new_score"
    else
      if [ -f "$REEL_AUDITOR" ]; then
        local audit_exit=0
        bash "$REEL_AUDITOR" --input "$variant_file" --output "$audit_file" 2>&1 | while IFS= read -r line; do
          info "  [audit] $line"
        done || audit_exit=$?

        if [ "$audit_exit" -ne 0 ] || [ ! -f "$audit_file" ]; then
          warn "Audit failed on iteration $iteration, skipping"
          log_iteration "$iteration" "$variant_file" "" "0" "$current_best_score" "false" "Audit failed"
          iteration=$((iteration + 1))
          continue
        fi

        new_score=$(read_audit_score "$audit_file")
      else
        warn "reel-auditor.sh not found at $REEL_AUDITOR"
        warn "Skipping audit (install reel-auditor.sh to enable QA)"
        iteration=$((iteration + 1))
        continue
      fi
    fi

    info "  Score: $new_score vs current best: $current_best_score"

    # Step 3: Compare and decide
    local is_better="false"
    is_better=$("$PYTHON3" -c "print('true' if float('$new_score') > float('$current_best_score') else 'false')" 2>/dev/null || echo "false")

    if [ "$is_better" = "true" ]; then
      info "[3/4] NEW BEST -- Score improved from $current_best_score to $new_score"

      if [ "$DRY_RUN" = "false" ]; then
        # Copy as new best
        cp "$variant_file" "$BEST_REEL" 2>/dev/null || true
        cp "$audit_file" "$BEST_AUDIT" 2>/dev/null || true
      fi

      # Extract learnings: why did this variant score better?
      info "  Extracting learnings..."
      local analysis
      analysis=$(analyze_variant "$variant_file" "$audit_file" "true")
      info "  Insight: $analysis"

      # Update learnings
      if [ "$DRY_RUN" = "false" ]; then
        update_learnings "$iteration" "$new_score" "true" "$analysis" "$variant_file" "$audit_file"
      fi

      current_best_score="$new_score"
      improvements=$((improvements + 1))
    else
      info "[3/4] DISCARDED -- Score $new_score did not beat $current_best_score"

      # Analyze failure: what went wrong?
      info "  Analyzing failure..."
      local analysis
      analysis=$(analyze_variant "$variant_file" "$audit_file" "false")
      info "  Insight: $analysis"

      # Update learnings (even for failures -- we learn from them)
      if [ "$DRY_RUN" = "false" ]; then
        update_learnings "$iteration" "$new_score" "false" "$analysis" "$variant_file" "$audit_file"

        # Discard the variant file to save disk space
        rm -f "$variant_file" 2>/dev/null || true
      fi
    fi

    # Step 4: Log iteration
    info "[4/4] Logging iteration..."
    if [ "$DRY_RUN" = "false" ]; then
      log_iteration "$iteration" "$variant_file" "$audit_file" "$new_score" "$current_best_score" "$is_better" "${analysis:-no analysis}"
    fi

    iteration=$((iteration + 1))
  done

  # --- Report ---
  echo ""
  echo "=============================================="
  echo "  REEL LOOP RESULTS"
  echo "=============================================="
  echo ""
  echo "  Iterations run:    $ITERATIONS"
  echo "  Improvements:      $improvements"
  echo "  Best score:        $current_best_score"
  echo "  Style:             $STYLE"
  echo "  Best reel:         $BEST_REEL"
  echo "  Best audit:        $BEST_AUDIT"
  echo "  Learnings:         $LEARNINGS_FILE"
  echo "  Loop log:          $LOOP_LOG"
  echo ""

  # --- Publish if requested and score meets threshold ---
  if [ "$PUBLISH" = "true" ]; then
    local meets_threshold
    meets_threshold=$("$PYTHON3" -c "print('yes' if float('$current_best_score') >= float('$keep_threshold') else 'no')" 2>/dev/null || echo "no")

    if [ "$meets_threshold" = "yes" ]; then
      info "Score $current_best_score >= $keep_threshold threshold -- publishing!"
      if [ "$DRY_RUN" = "true" ]; then
        info "[DRY-RUN] Would execute: reel-publish.sh --input $BEST_REEL"
      else
        if [ -f "$REEL_PUBLISH" ] && [ -f "$BEST_REEL" ]; then
          bash "$REEL_PUBLISH" --input "$BEST_REEL" 2>&1 | while IFS= read -r line; do
            info "  [publish] $line"
          done || warn "Publish failed"
        else
          warn "Cannot publish: reel-publish.sh not found or no best reel"
        fi
      fi
    else
      info "Score $current_best_score < $keep_threshold threshold -- skipping publish"
      info "Tip: Run more iterations or try a different style to improve score"
    fi
  fi

  # --- Room notification ---
  if [ "$DRY_RUN" = "false" ]; then
    notify_room "Reel loop complete: $ITERATIONS iterations, $improvements improvements, best=$current_best_score, style=$STYLE"
  fi

  # --- Compound learning ---
  if [ -f "$DIGEST" ] && [ "$DRY_RUN" = "false" ]; then
    local learning_fact="jade-reel-factory loop: iterations=$ITERATIONS improvements=$improvements best_score=$current_best_score style=$STYLE"
    bash "$DIGEST" \
      --source "jade-reel-factory/$DATE_STAMP" \
      --type "workflow-metric" \
      --fact "$learning_fact" \
      --agent "taoz" 2>/dev/null || true
  fi

  # --- Write run summary ---
  if [ "$DRY_RUN" = "false" ]; then
    "$PYTHON3" -c "
import json
from datetime import datetime

summary = {
    'run_id': 'reel-loop-$DATE_STAMP-$(date +%H%M%S)',
    'started': '$TIMESTAMP',
    'completed': datetime.utcnow().isoformat() + 'Z',
    'iterations': int('$ITERATIONS'),
    'improvements': int('$improvements'),
    'best_score': float('$current_best_score'),
    'style': '$STYLE',
    'blueprint': '$blueprint' if '$blueprint' else None,
    'published': '$PUBLISH' == 'true' and float('$current_best_score') >= float('$keep_threshold'),
    'output_dir': '$OUTPUT_DIR'
}

with open('$OUTPUT_DIR/run-summary-$DATE_STAMP.json', 'w') as f:
    json.dump(summary, f, indent=2)
" 2>/dev/null || warn "Failed to write run summary"
  fi

  info "=== Loop complete ==="
}

main "$@"
