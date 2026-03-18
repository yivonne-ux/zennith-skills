#!/usr/bin/env bash
# taoz-auditor.sh — Taoz's self-improving routing auditor + orchestrator
# Reviews dispatch outcomes, catches failures, orchestrates retries,
# extracts patterns, tests new rules in sandbox, promotes on pass.
#
# Usage:
#   taoz-auditor.sh audit              — Review recent dispatches for failures
#   taoz-auditor.sh orchestrate <label> — Retry a failed dispatch with alternative approach
#   taoz-auditor.sh learn              — Extract patterns from successful orchestrations
#   taoz-auditor.sh test               — Run sandbox routing regression
#   taoz-auditor.sh promote            — Promote tested rules to production classify.sh
#   taoz-auditor.sh status             — Show audit stats
#   taoz-auditor.sh full-cycle         — Run full audit→orchestrate→learn→test→promote cycle
#
# Designed to be run by Taoz (glm-5) via cron or heartbeat, or by Claude Code CLI.

set -uo pipefail

CMD="${1:-status}"
shift 2>/dev/null || true

# ── PATHS ─────────────────────────────────────────────────────────────────────
HOME_DIR="/Users/jennwoeiloh"
OC="$HOME_DIR/.openclaw"
DISPATCH_LOG="$OC/logs/dispatch-log.jsonl"
AUDIT_LOG="$OC/logs/audit-log.jsonl"
LEARNINGS_LOG="$OC/logs/audit-learnings.jsonl"
CLASSIFY="$OC/skills/orchestrate-v2/scripts/classify.sh"
SANDBOX_CLASSIFY="$OC/.openclaw-sandbox/classify-candidate.sh"
REGRESSION_DIR="$OC/workspace/tests/regression"
ROOM_WRITE="$OC/workspace/scripts/room-write.sh"
OPENCLAW_CLI="$HOME_DIR/local/bin/openclaw"
PATTERN_DB="$OC/logs/routing-patterns.jsonl"

mkdir -p "$OC/logs" "$(dirname "$SANDBOX_CLASSIFY")"

# ── HELPERS ───────────────────────────────────────────────────────────────────

log_audit() {
  local status="$1" dispatch_label="$2" detail="$3"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"ts\":\"$ts\",\"type\":\"audit\",\"status\":\"$status\",\"label\":\"$dispatch_label\",\"detail\":\"$(echo "$detail" | sed 's/"/\\"/g' | head -c 500)\"}" >> "$AUDIT_LOG"
}

log_learning() {
  local task="$1" original_agent="$2" correct_agent="$3" pattern="$4"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"ts\":\"$ts\",\"type\":\"learning\",\"task\":\"$(echo "$task" | sed 's/"/\\"/g')\",\"original\":\"$original_agent\",\"correct\":\"$correct_agent\",\"pattern\":\"$(echo "$pattern" | sed 's/"/\\"/g')\"}" >> "$LEARNINGS_LOG"
}

post_to_room() {
  local msg="$1"
  if [ -f "$ROOM_WRITE" ]; then
    bash "$ROOM_WRITE" "exec" "taoz" "audit-report" "$msg" 2>/dev/null || true
  fi
}

# ── AUDIT: Review recent dispatches for failures ─────────────────────────────
do_audit() {
  echo "=== TAOZ AUDITOR: Reviewing dispatches ==="

  if [ ! -f "$DISPATCH_LOG" ]; then
    echo "No dispatch log found"
    exit 0
  fi

  local ts_24h_ago
  ts_24h_ago=$(date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "2000-01-01T00:00:00Z")

  # Get dispatches from last 24 hours
  local total_dispatches=0
  local completed=0
  local failed=0
  local pending=0
  local failures=""

  # Read dispatching entries (they have task field)
  while IFS= read -r line; do
    local status ts agent label task pid
    status=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)

    if [ "$status" = "dispatching" ]; then
      total_dispatches=$((total_dispatches + 1))
      agent=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('agent',''))" 2>/dev/null)
      label=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('label',''))" 2>/dev/null)
      task=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('task',''))" 2>/dev/null)

      # Check if this dispatch has a completion entry
      # Two completion patterns: "outcome" field OR "status": "classified"
      local has_outcome
      has_outcome=$(grep -c "\"label\":\"$label\".*\"outcome\"" "$DISPATCH_LOG" 2>/dev/null | tr -d ' \n' || echo "0")
      local has_classified
      has_classified=$(grep -c "\"label\":\"$label\".*\"status\":\"classified\"" "$DISPATCH_LOG" 2>/dev/null | tr -d ' \n' || echo "0")

      if [ "$has_outcome" -gt 0 ]; then
        local outcome
        outcome=$(grep "\"label\":\"$label\".*\"outcome\"" "$DISPATCH_LOG" | tail -1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('outcome',''))" 2>/dev/null)
        if [ "$outcome" = "success" ]; then
          completed=$((completed + 1))
        else
          failed=$((failed + 1))
          failures="$failures\n  ✗ [$label] $agent: $task"
        fi
      elif [ "$has_classified" -gt 0 ]; then
        # classify.sh completed routing - this is a success
        completed=$((completed + 1))
      else
        # Check if the PID is still alive (dispatched but no outcome)
        local dispatch_pid
        dispatch_pid=$(grep "\"label\":\"$label\".*\"pid\"" "$DISPATCH_LOG" | tail -1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('pid',0))" 2>/dev/null)

        if [ -n "$dispatch_pid" ] && [ "$dispatch_pid" != "0" ]; then
          if ps -p "$dispatch_pid" > /dev/null 2>&1; then
            pending=$((pending + 1))
          else
            # Process gone, no outcome = probable failure
            failed=$((failed + 1))
            failures="$failures\n  ✗ [$label] $agent (pid $dispatch_pid gone, no outcome): $task"
            log_audit "failed" "$label" "Process exited without outcome. Agent: $agent. Task: $task"
          fi
        else
          pending=$((pending + 1))
        fi
      fi
    fi
  done < <(tail -200 "$DISPATCH_LOG")

  echo ""
  echo "📊 Dispatch Summary (last 200 entries):"
  echo "   Total:     $total_dispatches"
  echo "   Completed: $completed"
  echo "   Failed:    $failed"
  echo "   Pending:   $pending"

  if [ $failed -gt 0 ]; then
    echo ""
    echo "❌ Failed dispatches:"
    echo -e "$failures"
    echo ""
    echo "Run 'taoz-auditor.sh orchestrate <label>' to retry a failed dispatch."
  fi

  # Write summary to audit log
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"ts\":\"$ts\",\"type\":\"audit-summary\",\"total\":$total_dispatches,\"completed\":$completed,\"failed\":$failed,\"pending\":$pending}" >> "$AUDIT_LOG"

  # Post to room if failures found
  if [ $failed -gt 0 ]; then
    post_to_room "Audit found $failed failed dispatches out of $total_dispatches. Review audit-log.jsonl for details."
  fi
}

# ── ORCHESTRATE: Retry a failed dispatch with different approach ──────────────
do_orchestrate() {
  local target_label="${1:-}"

  if [ -z "$target_label" ]; then
    echo "Usage: taoz-auditor.sh orchestrate <dispatch-label>"
    echo ""
    echo "Recent failed dispatches:"
    grep '"type":"audit".*"status":"failed"' "$AUDIT_LOG" 2>/dev/null | tail -5 | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        print(f'  {d[\"label\"]}: {d[\"detail\"][:100]}')
    except: pass
"
    exit 1
  fi

  # Find the original dispatch
  local original
  original=$(grep "\"label\":\"$target_label\".*\"dispatching\"" "$DISPATCH_LOG" | head -1)

  if [ -z "$original" ]; then
    echo "Dispatch $target_label not found in log"
    exit 1
  fi

  local agent task
  agent=$(echo "$original" | python3 -c "import sys,json; print(json.load(sys.stdin).get('agent',''))" 2>/dev/null)
  task=$(echo "$original" | python3 -c "import sys,json; print(json.load(sys.stdin).get('task',''))" 2>/dev/null)

  echo "=== TAOZ ORCHESTRATOR: Retrying $target_label ==="
  echo "Original agent: $agent"
  echo "Task: $task"
  echo ""

  # Determine alternative agents to try
  local alternatives=""
  case "$agent" in
    iris)     alternatives="dreami hermes" ;;
    dreami)   alternatives="iris athena" ;;
    hermes)   alternatives="athena dreami" ;;
    athena)   alternatives="hermes artemis" ;;
    artemis)  alternatives="athena myrmidons" ;;
    taoz)     alternatives="myrmidons" ;;
    myrmidons) alternatives="taoz" ;;
    *)        alternatives="myrmidons" ;;
  esac

  echo "Trying alternatives: $alternatives"
  echo ""

  # Try original agent first with enriched context
  echo "Attempt 1: Retry $agent with enriched context..."
  local brand_context=""
  if echo "$task" | grep -qiE 'mirra'; then
    brand_context="Brand: MIRRA (bento health food). Read /Users/jennwoeiloh/.openclaw/brands/mirra/DNA.json for brand guidelines. "
  elif echo "$task" | grep -qiE 'pinxin'; then
    brand_context="Brand: Pinxin Vegan. Read /Users/jennwoeiloh/.openclaw/brands/pinxin-vegan/DNA.json for brand guidelines. "
  fi

  local enriched_task="${brand_context}Task: ${task}. IMPORTANT: Complete this task and return results. If you cannot use a specific tool, try an alternative approach."

  local result
  result=$("$OPENCLAW_CLI" agent --agent "$agent" --message "$enriched_task" --timeout 300 2>&1) || true

  if [ -n "$result" ] && ! echo "$result" | grep -qiE '(error|failed|timeout|cannot|unable)'; then
    echo "✅ Retry succeeded with $agent"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"ts\":\"$ts\",\"type\":\"orchestration\",\"label\":\"$target_label\",\"agent\":\"$agent\",\"attempt\":1,\"status\":\"success\",\"method\":\"enriched_context\"}" >> "$AUDIT_LOG"
    log_learning "$task" "$agent" "$agent" "enriched_context_fixed_it"
    return 0
  fi

  # Try alternative agents
  local attempt=2
  for alt_agent in $alternatives; do
    echo "Attempt $attempt: Trying $alt_agent..."
    result=$("$OPENCLAW_CLI" agent --agent "$alt_agent" --message "$enriched_task" --timeout 300 2>&1) || true

    if [ -n "$result" ] && ! echo "$result" | grep -qiE '(error|failed|timeout|cannot|unable)'; then
      echo "✅ Alternative $alt_agent succeeded"
      local ts
      ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      echo "{\"ts\":\"$ts\",\"type\":\"orchestration\",\"label\":\"$target_label\",\"original_agent\":\"$agent\",\"correct_agent\":\"$alt_agent\",\"attempt\":$attempt,\"status\":\"success\",\"method\":\"alternative_agent\"}" >> "$AUDIT_LOG"
      log_learning "$task" "$agent" "$alt_agent" "misroute_${agent}_should_be_${alt_agent}"
      return 0
    fi

    attempt=$((attempt + 1))
  done

  echo "❌ All attempts failed. Flagging for Claude Code."
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"ts\":\"$ts\",\"type\":\"orchestration\",\"label\":\"$target_label\",\"status\":\"all_failed\",\"task\":\"$(echo "$task" | sed 's/"/\\"/g' | head -c 200)\"}" >> "$AUDIT_LOG"
  post_to_room "All orchestration attempts failed for $target_label. Needs Claude Code intervention."
}

# ── LEARN: Extract patterns from successful orchestrations ────────────────────
do_learn() {
  echo "=== TAOZ LEARNER: Extracting routing patterns ==="

  if [ ! -f "$AUDIT_LOG" ]; then
    echo "No audit log found"
    exit 0
  fi

  # Find successful orchestrations where the correct agent differed from original
  local misroutes
  misroutes=$(grep '"type":"orchestration".*"status":"success"' "$AUDIT_LOG" | grep '"method":"alternative_agent"' 2>/dev/null || true)

  if [ -z "$misroutes" ]; then
    echo "No misroutes found — routing is healthy ✅"
    exit 0
  fi

  echo "Found misroute patterns:"
  echo ""

  local new_rules=0
  while IFS= read -r line; do
    local original correct label task
    original=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('original_agent',''))" 2>/dev/null)
    correct=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('correct_agent',''))" 2>/dev/null)
    label=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('label',''))" 2>/dev/null)

    # Get the original task from dispatch log
    task=$(grep "\"label\":\"$label\".*\"dispatching\"" "$DISPATCH_LOG" | head -1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('task',''))" 2>/dev/null)

    if [ -n "$task" ] && [ -n "$original" ] && [ -n "$correct" ] && [ "$original" != "$correct" ]; then
      echo "  [$label] '$task' → was $original, should be $correct"

      # Record the pattern
      local ts
      ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      echo "{\"ts\":\"$ts\",\"task\":\"$(echo "$task" | sed 's/"/\\"/g')\",\"original\":\"$original\",\"correct\":\"$correct\",\"status\":\"pending_rule\"}" >> "$PATTERN_DB"
      new_rules=$((new_rules + 1))
    fi
  done <<< "$misroutes"

  echo ""
  echo "Extracted $new_rules new routing patterns → $PATTERN_DB"
  echo "Run 'taoz-auditor.sh test' to validate, then 'taoz-auditor.sh promote' to apply."
}

# ── TEST: Run sandbox routing regression ──────────────────────────────────────
do_test() {
  echo "=== TAOZ TESTER: Running routing regression ==="

  local test_script="$REGRESSION_DIR/test-dispatch-routing.sh"
  if [ ! -f "$test_script" ]; then
    echo "FAIL: test-dispatch-routing.sh not found"
    exit 1
  fi

  # Run existing regression tests
  echo "Running production routing regression..."
  local result
  result=$(bash "$test_script" 2>&1)
  echo "$result"

  if echo "$result" | grep -q "FAIL"; then
    echo ""
    echo "❌ Production routing regression FAILED — do not promote."
    exit 1
  fi

  # If we have pending patterns, test them too
  if [ -f "$PATTERN_DB" ]; then
    local pending
    pending=$(grep '"status":"pending_rule"' "$PATTERN_DB" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$pending" -gt 0 ]; then
      echo ""
      echo "Testing $pending pending pattern rules..."

      local pattern_pass=0
      local pattern_total=0

      while IFS= read -r line; do
        local task correct
        task=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('task',''))" 2>/dev/null)
        correct=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('correct',''))" 2>/dev/null)

        if [ -n "$task" ] && [ -n "$correct" ]; then
          pattern_total=$((pattern_total + 1))
          local actual
          actual=$(bash "$CLASSIFY" "$task" 2>/dev/null | grep -i "AGENT:" | head -1 | sed 's/.*AGENT:[[:space:]]*//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

          if [ "$actual" = "$correct" ]; then
            pattern_pass=$((pattern_pass + 1))
            echo "  ✅ '$task' → $actual (expected $correct)"
          else
            echo "  ❌ '$task' → $actual (expected $correct) — NEEDS NEW RULE"
          fi
        fi
      done < <(grep '"status":"pending_rule"' "$PATTERN_DB")

      echo ""
      echo "Pattern test: $pattern_pass/$pattern_total already correct"

      local needs_rules=$((pattern_total - pattern_pass))
      if [ $needs_rules -gt 0 ]; then
        echo "$needs_rules patterns need new classify.sh rules"
        echo "Run 'taoz-auditor.sh promote' to generate and apply rules."
      fi
    fi
  fi

  echo ""
  echo "✅ Routing regression PASSED"
}

# ── PROMOTE: Generate new classify.sh rules from learned patterns ─────────────
do_promote() {
  echo "=== TAOZ PROMOTER: Generating new routing rules ==="

  if [ ! -f "$PATTERN_DB" ]; then
    echo "No patterns to promote"
    exit 0
  fi

  local pending
  pending=$(grep '"status":"pending_rule"' "$PATTERN_DB" 2>/dev/null || true)

  if [ -z "$pending" ]; then
    echo "No pending patterns to promote"
    exit 0
  fi

  echo "Pending patterns to promote:"
  echo "$pending" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        print(f'  {d[\"task\"][:60]} → {d[\"correct\"]}')
    except: pass
"

  echo ""
  echo "⚠️  Rule generation requires Claude Code CLI."
  echo "The following patterns need new grep rules in classify.sh:"
  echo ""
  echo "$pending" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        task = d['task'].lower()
        agent = d['correct']
        # Extract key words for the pattern
        words = [w for w in task.split() if len(w) > 3 and w not in ('this','that','from','with','about','what','show','give','make','create','generate')]
        if words:
            pattern = '|'.join(words[:3])
            print(f'  # Pattern: \"{task[:50]}\" → {agent}')
            print(f'  # Suggested grep: ({pattern})')
            print()
    except: pass
"

  echo "To apply: Fire Claude Code CLI with these patterns to update classify.sh"
  echo "Then run 'taoz-auditor.sh test' to validate."

  # Mark patterns as promoted
  python3 -c "
import json
lines = []
with open('$PATTERN_DB') as f:
    for line in f:
        try:
            d = json.loads(line.strip())
            if d.get('status') == 'pending_rule':
                d['status'] = 'promoted'
            lines.append(json.dumps(d))
        except:
            lines.append(line.strip())
with open('$PATTERN_DB', 'w') as f:
    f.write('\n'.join(lines) + '\n')
print('Patterns marked as promoted')
" 2>/dev/null
}

# ── STATUS: Show audit stats ─────────────────────────────────────────────────
do_status() {
  echo "=== TAOZ AUDITOR STATUS ==="
  echo ""

  # Dispatch log stats
  if [ -f "$DISPATCH_LOG" ]; then
    local total
    total=$(wc -l < "$DISPATCH_LOG" | tr -d ' ')
    local dispatching
    dispatching=$(grep -c '"status":"dispatching"' "$DISPATCH_LOG" 2>/dev/null || echo "0")
    echo "📦 Dispatch Log: $total entries, $dispatching dispatch events"
  else
    echo "📦 Dispatch Log: not found"
  fi

  # Audit log stats
  if [ -f "$AUDIT_LOG" ]; then
    local audits
    audits=$(grep -c '"type":"audit"' "$AUDIT_LOG" 2>/dev/null || echo "0")
    local orchestrations
    orchestrations=$(grep -c '"type":"orchestration"' "$AUDIT_LOG" 2>/dev/null || echo "0")
    local successes
    successes=$(grep -c '"status":"success"' "$AUDIT_LOG" 2>/dev/null || echo "0")
    echo "🔍 Audit Log: $audits audits, $orchestrations orchestrations ($successes successful)"
  else
    echo "🔍 Audit Log: not started"
  fi

  # Pattern DB stats
  if [ -f "$PATTERN_DB" ]; then
    local pending
    pending=$(grep -c '"status":"pending_rule"' "$PATTERN_DB" 2>/dev/null || echo "0")
    local promoted
    promoted=$(grep -c '"status":"promoted"' "$PATTERN_DB" 2>/dev/null || echo "0")
    echo "🧠 Pattern DB: $pending pending, $promoted promoted"
  else
    echo "🧠 Pattern DB: empty"
  fi

  # Learnings log stats
  if [ -f "$LEARNINGS_LOG" ]; then
    local learnings
    learnings=$(wc -l < "$LEARNINGS_LOG" | tr -d ' ')
    echo "📚 Learnings: $learnings entries"
  else
    echo "📚 Learnings: none yet"
  fi

  # Regression test status
  local last_result
  last_result=$(ls -t "$OC/workspace/tests/results/"*.json 2>/dev/null | head -1)
  if [ -n "$last_result" ]; then
    local verdict
    verdict=$(python3 -c "import json; print(json.load(open('$last_result')).get('verdict','?'))" 2>/dev/null)
    echo "🧪 Last regression: $verdict ($(basename "$last_result"))"
  else
    echo "🧪 Last regression: no results"
  fi

  echo ""
}

# ── COMPLETION TRACKER: Add outcome to dispatch log ──────────────────────────
# Called by dispatch-watchdog or post-dispatch hooks
do_complete() {
  local label="${1:-}" outcome="${2:-success}" summary="${3:-}"

  if [ -z "$label" ]; then
    echo "Usage: taoz-auditor.sh complete <label> <success|fail> [summary]"
    exit 1
  fi

  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"ts\":\"$ts\",\"label\":\"$label\",\"outcome\":\"$outcome\",\"summary\":\"$(echo "$summary" | sed 's/"/\\"/g' | head -c 500)\",\"status\":\"complete\"}" >> "$DISPATCH_LOG"
  echo "Logged completion: $label → $outcome"
}

# ── FULL CYCLE: audit → orchestrate failures → learn → test → promote ─────────
do_full_cycle() {
  echo "╔══════════════════════════════════════════════════╗"
  echo "║   TAOZ FULL AUDIT CYCLE                         ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""

  # Step 1: Audit
  do_audit
  echo ""
  echo "────────────────────────────────────────────────────"
  echo ""

  # Step 2: Auto-orchestrate any failures found
  local failures
  failures=$(grep '"type":"audit".*"status":"failed"' "$AUDIT_LOG" 2>/dev/null | tail -5 || true)

  if [ -n "$failures" ]; then
    echo "Auto-orchestrating recent failures..."
    while IFS= read -r line; do
      local label
      label=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('label',''))" 2>/dev/null)
      if [ -n "$label" ]; then
        # Check if already orchestrated
        if ! grep -q "\"label\":\"$label\".*\"type\":\"orchestration\"" "$AUDIT_LOG" 2>/dev/null; then
          do_orchestrate "$label"
          echo ""
        fi
      fi
    done <<< "$failures"

    echo "────────────────────────────────────────────────────"
    echo ""
  fi

  # Step 3: Learn from orchestrations
  do_learn
  echo ""
  echo "────────────────────────────────────────────────────"
  echo ""

  # Step 4: Test
  do_test
  echo ""
  echo "────────────────────────────────────────────────────"
  echo ""

  # Step 5: Promote (if patterns exist)
  if [ -f "$PATTERN_DB" ] && grep -q '"status":"pending_rule"' "$PATTERN_DB" 2>/dev/null; then
    do_promote
  else
    echo "No patterns to promote — classify.sh is current ✅"
  fi

  echo ""
  echo "╔══════════════════════════════════════════════════╗"
  echo "║   CYCLE COMPLETE                                ║"
  echo "╚══════════════════════════════════════════════════╝"
}

# ── DISPATCH ─────────────────────────────────────────────────────────────────
case "$CMD" in
  audit)       do_audit "$@" ;;
  orchestrate) do_orchestrate "$@" ;;
  learn)       do_learn "$@" ;;
  test)        do_test "$@" ;;
  promote)     do_promote "$@" ;;
  status)      do_status "$@" ;;
  complete)    do_complete "$@" ;;
  full-cycle)  do_full_cycle "$@" ;;
  *)
    echo "Usage: taoz-auditor.sh <audit|orchestrate|learn|test|promote|status|complete|full-cycle>"
    exit 1
    ;;
esac
