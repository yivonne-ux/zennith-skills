#!/usr/bin/env bash
# claude-code-runner.sh — Wraps claude CLI for OpenClaw skill invocation
# Usage: claude-code-runner.sh <review|build> <prompt> [cwd] [budget]

set -euo pipefail

MODE="${1:?Usage: claude-code-runner.sh <review|build> <prompt> [cwd] [budget]}"
PROMPT="${2:?Error: prompt is required}"
CWD="${3:-.}"
BUDGET="${4:-}"

# Set defaults based on mode
case "$MODE" in
  review)
    BUDGET="${BUDGET:-0.50}"
    echo "--- claude-code.review ---"
    echo "Budget: USD $BUDGET | Tools: none (read-only) | Model: opus"
    echo "---"
    claude -p \
      --model opus \
      --system-prompt "You are a Red Team Reviewer for GAIA CORP-OS. Analyze the request and output EXACTLY these sections: (1) Risk Register — key risks with severity and likelihood, (2) Failure Modes — what could go wrong, (3) Cost/ROI Critique — financial sanity check, (4) Counter-Options — alternatives considered, (5) Recommendation — approve / reject / modify with conditions. Be concise, structured, and direct." \
      --tools "" \
      --max-budget-usd "$BUDGET" \
      "$PROMPT"
    echo ""
    echo "--- claude-code.review complete ---"
    ;;
  build)
    BUDGET="${BUDGET:-1.00}"
    echo "--- claude-code.build ---"
    echo "Budget: USD $BUDGET | Tools: Bash,Edit,Read,Write,Glob,Grep | Dir: $CWD | Model: opus"
    echo "---"
    claude -p \
      --model opus \
      --system-prompt "You are a Skill Builder for GAIA CORP-OS. Write clean, tested code. Return EXACTLY these sections: (1) Result — what was built/changed (1-3 lines), (2) Proof — build logs or test output, (3) What changed — list of files, (4) Learning — 1 line on what to improve next time." \
      --allowedTools "Bash,Edit,Read,Write,Glob,Grep" \
      --max-budget-usd "$BUDGET" \
      --add-dir "$CWD" \
      "$PROMPT"
    echo ""
    echo "--- claude-code.build complete ---"
    ;;
  *)
    echo "ERROR: Unknown mode '$MODE'. Use 'review' or 'build'."
    echo "Usage: claude-code-runner.sh <review|build> <prompt> [cwd] [budget]"
    exit 1
    ;;
esac
