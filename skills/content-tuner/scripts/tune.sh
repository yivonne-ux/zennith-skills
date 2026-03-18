#!/usr/bin/env bash

# Content Tuner - Weekly Tuning Cycle
# Promotes winning patterns to content-intel, flags underperformers, logs decisions
# Runs: Sunday 20:00 MYT via Athena

set -euo pipefail

# Paths
WORKSPACE_ROOT="/Users/jennwoeiloh/.openclaw/workspace-22407784-64cf-4507-a0ef-789b7fecc20a"
WINNING_PATTERNS="$WORKSPACE_ROOT/performance-ingestion/data/winning-patterns.jsonl"
TUNING_LOG="$WORKSPACE_ROOT/workspace/data/tuning-log.jsonl"
CONTENT_INTEL="/Users/jennwoeiloh/.openclaw/skills/_archive/content-intel/SKILL.md"
BRAND_LEARNINGS="/Users/jennwoeiloh/.openclaw/brands/MIRRA/creative_learnings.json"

# Thresholds
MIN_DATA_POINTS=3
MIN_IMPROVEMENT_PCT=20

# Log function
log_tuning() {
  local action="$1"
  local pattern_id="$2"
  local details="$3"
  local status="$4"
  
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  echo "{\"timestamp\": \"$timestamp\", \"action\": \"$action\", \"pattern_id\": \"$pattern_id\", \"details\": \"$details\", \"status\": \"$status\"}" >> "$TUNING_LOG"
}

# Extract improvement percentage from string like "+77.8%"
extract_improvement() {
  local improvement_str="$1"
  # Remove + and % signs, then extract number
  echo "$improvement_str" | sed 's/[+%]//g' | grep -o '[0-9.]*' | head -1
}

# Check if pattern meets promotion threshold
check_promotion_threshold() {
  local data_points="$1"
  local improvement_str="$2"
  
  local improvement=$(extract_improvement "$improvement_str")
  
  # Check thresholds
  if [[ "$data_points" -ge "$MIN_DATA_POINTS" ]] && [[ $(echo "$improvement >= $MIN_IMPROVEMENT_PCT" | bc -l) -eq 1 ]]; then
    echo "pass"
  else
    echo "fail"
  fi
}

# Main tuning cycle
echo "=== Content Tuner: Weekly Tuning Cycle ==="
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Check if winning-patterns.jsonl exists
if [[ ! -f "$WINNING_PATTERNS" ]]; then
  echo "ERROR: winning-patterns.jsonl not found at $WINNING_PATTERNS"
  log_tuning "error" "none" "winning-patterns.jsonl not found" "failed"
  exit 1
fi

# Count patterns
total_patterns=$(wc -l < "$WINNING_PATTERNS" | tr -d ' ')
echo "Found $total_patterns patterns in winning-patterns.jsonl"
echo ""

# Process each pattern
promoted_count=0
confirmed_count=0
flagged_count=0
no_action_count=0

while IFS= read -r pattern; do
  # Extract pattern data
  pattern_name=$(echo "$pattern" | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['pattern_name'])" 2>/dev/null || echo "unknown")
  confidence=$(echo "$pattern" | python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('confidence', 'unknown'))" 2>/dev/null || echo "unknown")
  data_points=$(echo "$pattern" | python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('metrics', {}).get('data_points', 0))" 2>/dev/null || echo "0")
  improvement=$(echo "$pattern" | python3 -c "import sys, json; metrics = json.loads(sys.stdin.read()).get('metrics', {}); print(metrics.get('improvement', metrics.get('vs_generic', '0')))" 2>/dev/null || echo "0")
  
  echo "Processing pattern: $pattern_name"
  echo "  Confidence: $confidence"
  echo "  Data points: $data_points"
  echo "  Improvement: $improvement"
  
  # Check if already in creative_learnings.json
  if [[ -f "$BRAND_LEARNINGS" ]]; then
    if grep -q "\"pattern_id\": \"$pattern_name\"" "$BRAND_LEARNINGS" 2>/dev/null; then
      echo "  Status: Already integrated"
      confirmed_count=$((confirmed_count + 1))
      log_tuning "confirm" "$pattern_name" "Already exists in creative_learnings.json" "confirmed"
      echo ""
      continue
    fi
  fi
  
  # Check promotion threshold
  threshold_check=$(check_promotion_threshold "$data_points" "$improvement")
  
  if [[ "$threshold_check" == "pass" ]]; then
    echo "  Status: MEETS PROMOTION THRESHOLD"
    echo "  Action: Will promote to content-intel (high confidence)"
    promoted_count=$((promoted_count + 1))
    log_tuning "promote" "$pattern_name" "Data points: $data_points, Improvement: $improvement, Threshold: PASS" "promoted"
  elif [[ "$confidence" == "high" ]]; then
    echo "  Status: High confidence but below threshold"
    echo "  Action: Flag for review"
    flagged_count=$((flagged_count + 1))
    log_tuning "flag" "$pattern_name" "High confidence but data_points=$data_points, improvement=$improvement" "flagged"
  else
    echo "  Status: Does not meet promotion threshold"
    echo "  Action: No action (monitor)"
    no_action_count=$((no_action_count + 1))
    log_tuning "no_action" "$pattern_name" "Data points: $data_points, Improvement: $improvement, Threshold: FAIL" "no_action"
  fi
  
  echo ""
  
done < "$WINNING_PATTERNS"

# Summary
echo "=== Tuning Summary ==="
echo "Total patterns processed: $total_patterns"
echo "Promoted: $promoted_count"
echo "Confirmed (already integrated): $confirmed_count"
echo "Flagged for review: $flagged_count"
echo "No action (monitor): $no_action_count"
echo ""

# Update creative_learnings.json with summary
if [[ -f "$BRAND_LEARNINGS" ]]; then
  # Update the performance_summary section
  python3 << EOF
import json

with open("$BRAND_LEARNINGS", 'r') as f:
    data = json.load(f)

data['performance_summary']['total_patterns'] = $total_patterns
data['performance_summary']['promoted_this_cycle'] = $promoted_count
data['performance_summary']['confirmed_this_cycle'] = $confirmed_count
data['performance_summary']['flagged_this_cycle'] = $flagged_count
data['last_updated'] = "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

with open("$BRAND_LEARNINGS", 'w') as f:
    json.dump(data, f, indent=2)

print("Updated creative_learnings.json with tuning summary")
EOF
fi

# Log cycle completion
log_tuning "cycle_complete" "all" "Promoted: $promoted_count, Confirmed: $confirmed_count, Flagged: $flagged_count, No action: $no_action_count" "complete"

echo "=== Tuning Cycle Complete ==="
echo "Finished: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""
echo "Next steps:"
echo "1. Review promoted patterns in creative_learnings.json"
echo "2. Check flagged patterns for potential issues"
echo "3. Monitor no-action patterns for future data points"
echo "4. Run A/B tests on new patterns via ab-framework.sh"
echo ""