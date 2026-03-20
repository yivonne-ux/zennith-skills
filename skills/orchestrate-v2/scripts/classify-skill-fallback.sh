#!/usr/bin/env bash
# classify-skill-fallback.sh — Fallback skill matcher for classify.sh
# Called when classify.sh finds no keyword match in its routing tables.
# Returns skill match info or empty if no match found.
# Bash 3.2 compatible (macOS). Zero LLM cost.
#
# Usage (sourced by classify.sh):
#   source classify-skill-fallback.sh
#   skill_fallback_match "user query text"
#   # Sets: SKILL_MATCH_NAME, SKILL_MATCH_AGENT, SKILL_MATCH_COMMAND, SKILL_MATCH_SCORE
#
# Usage (standalone):
#   bash classify-skill-fallback.sh "user query text"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MATCH_SH="$SCRIPT_DIR/skill-match.sh"

# Reset output vars
SKILL_MATCH_NAME=""
SKILL_MATCH_AGENT=""
SKILL_MATCH_COMMAND=""
SKILL_MATCH_SCORE=0

skill_fallback_match() {
    local query="$1"
    local min_score="${2:-5}"  # Minimum score to consider a match (default: 5)

    # Reset
    SKILL_MATCH_NAME=""
    SKILL_MATCH_AGENT=""
    SKILL_MATCH_COMMAND=""
    SKILL_MATCH_SCORE=0

    if [ -z "$query" ]; then
        return 1
    fi

    if [ ! -x "$SKILL_MATCH_SH" ]; then
        return 1
    fi

    # Get top 1 match as JSON, write to temp file to avoid quoting issues
    local tmpfile
    tmpfile="$(mktemp /tmp/skill-fallback.XXXXXX)"
    bash "$SKILL_MATCH_SH" --json --top 1 "$query" > "$tmpfile" 2>/dev/null || { rm -f "$tmpfile"; return 1; }

    local result
    result="$(cat "$tmpfile")"
    if [ -z "$result" ] || [ "$result" = "[]" ]; then
        rm -f "$tmpfile"
        return 1
    fi

    # Parse JSON with python3
    local parsed
    parsed="$(python3 -c "
import json, sys
try:
    with open('$tmpfile') as f:
        data = json.load(f)
    if not data or not isinstance(data, list) or len(data) == 0:
        sys.exit(1)
    m = data[0]
    score = m.get('score', 0)
    if score < $min_score:
        sys.exit(1)
    name = m.get('name', '')
    agents = m.get('agents', [])
    agent = agents[0] if agents else 'main'
    cmd = m.get('cli_command', '')
    print('SKILL_MATCH_NAME=\"{}\"'.format(name))
    print('SKILL_MATCH_AGENT=\"{}\"'.format(agent))
    print('SKILL_MATCH_COMMAND=\"{}\"'.format(cmd))
    print('SKILL_MATCH_SCORE={}'.format(score))
except Exception:
    sys.exit(1)
" 2>/dev/null)" || { rm -f "$tmpfile"; return 1; }
    rm -f "$tmpfile"

    eval "$parsed" || return 1

    if [ -z "$SKILL_MATCH_NAME" ]; then
        return 1
    fi

    return 0
}

# If run standalone (not sourced), execute and print results
if [ "${BASH_SOURCE[0]}" = "$0" ] || [ -z "${BASH_SOURCE[0]}" ]; then
    query="${1:-}"
    if [ -z "$query" ]; then
        echo "Usage: classify-skill-fallback.sh \"query text\"" >&2
        exit 1
    fi

    if skill_fallback_match "$query"; then
        echo "MATCH FOUND:"
        echo "  Skill: $SKILL_MATCH_NAME"
        echo "  Agent: $SKILL_MATCH_AGENT"
        echo "  Command: $SKILL_MATCH_COMMAND"
        echo "  Score: $SKILL_MATCH_SCORE"
    else
        echo "No skill match found for: \"$query\""
        exit 1
    fi
fi
