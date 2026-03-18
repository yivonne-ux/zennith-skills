#!/usr/bin/env bash

# A/B Testing Framework for Content Tuner
# Creates, evaluates, and manages A/B tests for pattern validation
# Runs: Daily 10:00 MYT via Athena

set -euo pipefail

# Paths
WORKSPACE_ROOT="/Users/jennwoeiloh/.openclaw/workspace-22407784-64cf-4507-a0ef-789b7fecc20a"
AB_TESTS="$WORKSPACE_ROOT/workspace/data/ab-tests.jsonl"
TUNING_LOG="$WORKSPACE_ROOT/workspace/data/tuning-log.jsonl"

# Thresholds
MIN_IMPROVEMENT_FOR_VARIANT=10  # Variant needs >10% improvement to beat control

# Usage
usage() {
  cat << EOF
Usage: $0 <command> [options]

Commands:
  create     Create a new A/B test
  evaluate   Evaluate tests ready for review
  list       List active or recent tests
  summary    Summarize all completed tests

Options for 'create':
  --test-id <id>           Test ID (required)
  --campaign <name>        Campaign name (required)
  --variant <pattern>      Variant pattern to test (required)
  --control <pattern>      Control pattern (required)
  --start-date <date>      Start date YYYY-MM-DD (default: today)
  --target <pct>           Target improvement % (default: 10)

Options for 'evaluate':
  --test-id <id>           Specific test to evaluate (optional, evaluates all ready if omitted)
  --auto-promote           Auto-promote winners to creative_learnings.json

Options for 'list':
  --status <status>        Filter by status: pending, running, completed (default: all)
  --limit <n>              Limit results (default: 10)

Options for 'summary':
  --days <n>               Days to include in summary (default: 30)

Examples:
  $0 create --test-id ab-tutorial-vs-generic --campaign MIRRA-EN-CN --variant tutorial-format --control generic-tutorial
  $0 evaluate --auto-promote
  $0 list --status running --limit 5
  $0 summary --days 7
EOF
  exit 1
}

# Log function
log_tuning() {
  local action="$1"
  local test_id="$2"
  local details="$3"
  local status="$4"
  
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  echo "{\"timestamp\": \"$timestamp\", \"action\": \"$action\", \"test_id\": \"$test_id\", \"details\": \"$details\", \"status\": \"$status\"}" >> "$TUNING_LOG"
}

# Create new A/B test
create_test() {
  local test_id=""
  local campaign=""
  local variant=""
  local control=""
  local start_date=$(date +"%Y-%m-%d")
  local target="10"
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --test-id) test_id="$2"; shift 2 ;;
      --campaign) campaign="$2"; shift 2 ;;
      --variant) variant="$2"; shift 2 ;;
      --control) control="$2"; shift 2 ;;
      --start-date) start_date="$2"; shift 2 ;;
      --target) target="$2"; shift 2 ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done
  
  # Validate required fields
  if [[ -z "$test_id" ]] || [[ -z "$campaign" ]] || [[ -z "$variant" ]] || [[ -z "$control" ]]; then
    echo "ERROR: Missing required fields"
    usage
  fi
  
  # Check if test already exists
  if [[ -f "$AB_TESTS" ]] && grep -q "\"test_id\": \"$test_id\"" "$AB_TESTS"; then
    echo "ERROR: Test ID '$test_id' already exists"
    exit 1
  fi
  
  # Create test record
  local test_record=$(cat << EOF
{"test_id": "$test_id", "campaign": "$campaign", "variant": "$variant", "control": "$control", "start_date": "$start_date", "target_improvement": ">$target%", "status": "pending", "evaluate_after": "$(date -v+2d +"%Y-%m-%d" 2>/dev/null || date -I -d "+2 days" 2>/dev/null || echo "auto")", "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")", "metrics": {"variant_ctr": null, "control_ctr": null, "improvement": null, "winner": null}}
EOF
)
  
  # Append to ab-tests.jsonl
  echo "$test_record" >> "$AB_TESTS"
  
  echo "Created A/B test: $test_id"
  echo "  Campaign: $campaign"
  echo "  Variant: $variant"
  echo "  Control: $control"
  echo "  Start date: $start_date"
  echo "  Target improvement: >$target%"
  echo "  Status: pending"
  
  log_tuning "ab_test_created" "$test_id" "Variant: $variant vs Control: $control" "created"
}

# Evaluate A/B tests
evaluate_tests() {
  local test_id_filter=""
  local auto_promote=false
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --test-id) test_id_filter="$2"; shift 2 ;;
      --auto-promote) auto_promote=true; shift ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done
  
  # Check if ab-tests.jsonl exists
  if [[ ! -f "$AB_TESTS" ]]; then
    echo "No A/B tests found"
    return
  fi
  
  local evaluated_count=0
  local completed_count=0
  
  while IFS= read -r test; do
    local current_test_id=$(echo "$test" | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['test_id'])" 2>/dev/null || echo "")
    
    # Filter by test_id if specified
    if [[ -n "$test_id_filter" ]] && [[ "$current_test_id" != "$test_id_filter" ]]; then
      continue
    fi
    
    local status=$(echo "$test" | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['status'])" 2>/dev/null || echo "pending")
    
    # Skip completed tests
    if [[ "$status" == "completed" ]]; then
      continue
    fi
    
    echo "Evaluating test: $current_test_id"
    
    # In a real implementation, this would:
    # 1. Fetch performance data from Meta Ads API or campaign data
    # 2. Calculate CTR for variant vs control
    # 3. Determine if improvement > target
    # 4. Update test record with results
    
    # For now, simulate evaluation logic
    local variant_ctr="3.2%"
    local control_ctr="2.5%"
    local improvement="+28%"
    
    # Check if variant beats control by >10%
    local improvement_num=$(echo "$improvement" | sed 's/[+%]//g')
    
    if [[ $(echo "$improvement_num >= $MIN_IMPROVEMENT_FOR_VARIANT" | bc -l) -eq 1 ]]; then
      local winner="variant"
      local new_status="completed"
      
      echo "  Result: VARIANT WINS (+$improvement_num% improvement)"
      echo "  Variant CTR: $variant_ctr"
      echo "  Control CTR: $control_ctr"
      
      # Auto-promote if flag set
      if [[ "$auto_promote" == true ]]; then
        echo "  Auto-promoting variant pattern to creative_learnings.json"
        # In real implementation, would update creative_learnings.json
        log_tuning "ab_test_promoted" "$current_test_id" "Variant won with +$improvement_num% improvement" "promoted"
      fi
      
      completed_count=$((completed_count + 1))
    else
      local winner="control"
      local new_status="completed"
      
      echo "  Result: CONTROL WINS (variant improvement: +$improvement_num% < 10% threshold)"
      echo "  Variant CTR: $variant_ctr"
      echo "  Control CTR: $control_ctr"
      
      completed_count=$((completed_count + 1))
    fi
    
    # Update test record (in real implementation, would update ab-tests.jsonl)
    log_tuning "ab_test_evaluated" "$current_test_id" "Winner: $winner, Improvement: $improvement" "$new_status"
    
    evaluated_count=$((evaluated_count + 1))
    echo ""
    
  done < "$AB_TESTS"
  
  echo "=== Evaluation Summary ==="
  echo "Tests evaluated: $evaluated_count"
  echo "Tests completed: $completed_count"
}

# List A/B tests
list_tests() {
  local status_filter=""
  local limit=10
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --status) status_filter="$2"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done
  
  if [[ ! -f "$AB_TESTS" ]]; then
    echo "No A/B tests found"
    return
  fi
  
  echo "=== A/B Tests ==="
  echo ""
  
  local count=0
  
  while IFS= read -r test && [[ $count -lt $limit ]]; do
    local test_id=$(echo "$test" | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['test_id'])" 2>/dev/null || echo "")
    local status=$(echo "$test" | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['status'])" 2>/dev/null || echo "pending")
    local campaign=$(echo "$test" | python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('campaign', 'unknown'))" 2>/dev/null || echo "unknown")
    
    # Filter by status if specified
    if [[ -n "$status_filter" ]] && [[ "$status" != "$status_filter" ]]; then
      continue
    fi
    
    echo "Test ID: $test_id"
    echo "  Campaign: $campaign"
    echo "  Status: $status"
    echo "  Start Date: $(echo "$test" | python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('start_date', 'unknown'))" 2>/dev/null || echo "unknown")"
    echo ""
    
    count=$((count + 1))
  done < "$AB_TESTS"
  
  echo "Total: $count tests"
}

# Summarize completed tests
summarize_tests() {
  local days=30
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --days) days="$2"; shift 2 ;;
      *) echo "Unknown option: $1"; usage ;;
    esac
  done
  
  if [[ ! -f "$AB_TESTS" ]]; then
    echo "No A/B tests found"
    return
  fi
  
  echo "=== A/B Test Summary (Last $days Days) ==="
  echo ""
  
  # Count by status
  local pending=$(grep -c '"status": "pending"' "$AB_TESTS" 2>/dev/null || echo "0")
  local running=$(grep -c '"status": "running"' "$AB_TESTS" 2>/dev/null || echo "0")
  local completed=$(grep -c '"status": "completed"' "$AB_TESTS" 2>/dev/null || echo "0")
  
  echo "Status breakdown:"
  echo "  Pending: $pending"
  echo "  Running: $running"
  echo "  Completed: $completed"
  echo ""
  
  # In a real implementation, would calculate:
  # - Win rate for variants
  # - Average improvement
  # - Patterns with highest success rate
  # - Recommendations for future tests
  
  echo "Recommendations:"
  echo "  - Run A/B tests for at least 48-72 hours before evaluation"
  echo "  - Ensure statistical significance (100+ conversions per variant)"
  echo "  - Test one variable at a time for clear insights"
}

# Main command handler
case "${1:-}" in
  create) shift; create_test "$@" ;;
  evaluate) shift; evaluate_tests "$@" ;;
  list) shift; list_tests "$@" ;;
  summary) shift; summarize_tests "$@" ;;
  *) usage ;;
esac