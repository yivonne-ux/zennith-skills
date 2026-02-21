#!/bin/bash
# test-framework.sh — A/B testing with error diagnosis
# Usage: test-framework.sh <test_name> <command> [expected_output]

set -e

TEST_NAME="$1"
COMMAND="$2"
EXPECTED="${3:-}"
LOG_DIR="$HOME/.openclaw/workspace/test-logs"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
LOG_FILE="$LOG_DIR/${TEST_NAME}_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

echo "🧪 TEST: $TEST_NAME"
echo "Command: $COMMAND"
echo "---"

# Run test with full logging
{
  echo "TEST: $TEST_NAME"
  echo "TIMESTAMP: $(date -Iseconds)"
  echo "COMMAND: $COMMAND"
  echo "EXPECTED: $EXPECTED"
  echo "---"
  
  # Execute and capture both stdout and stderr
  if eval "$COMMAND" 2>&1; then
    EXIT_CODE=$?
    echo "---"
    echo "RESULT: PASS"
    echo "EXIT_CODE: $EXIT_CODE"
  else
    EXIT_CODE=$?
    echo "---"
    echo "RESULT: FAIL"
    echo "EXIT_CODE: $EXIT_CODE"
    
    # Error diagnosis
    echo ""
    echo "DIAGNOSIS:"
    case $EXIT_CODE in
      1) echo "  → General error (check command syntax)" ;;
      2) echo "  → Misuse of command (wrong arguments)" ;;
      126) echo "  → Command not executable (permission issue)" ;;
      127) echo "  → Command not found (binary missing from PATH)" ;;
      130) echo "  → Interrupted by Ctrl+C" ;;
      137) echo "  → Killed by OOM (out of memory)" ;;
      139) echo "  → Segmentation fault (native binary crash)" ;;
      *) echo "  → Exit code $EXIT_CODE (check logs for details)" ;;
    esac
    
    # Check common issues
    if [[ "$COMMAND" == *"claude"* ]] && [[ $EXIT_CODE -ne 0 ]]; then
      echo "  → Claude Code: Check auth with 'claude setup-token'"
    fi
    if [[ "$COMMAND" == *"openclaw"* ]] && [[ $EXIT_CODE -ne 0 ]]; then
      echo "  → OpenClaw: Check gateway status with 'openclaw status'"
    fi
  fi
} | tee "$LOG_FILE"

echo ""
echo "📝 Log saved: $LOG_FILE"
echo ""

# Return exit code for further processing
exit ${EXIT_CODE:-0}
