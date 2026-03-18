#!/usr/bin/env bash
# triage.sh — Haiku-based task classifier for ambiguous messages
# Called by classify.sh when keyword matching fails
# Uses Claude CLI subscription ($0) — NOT API key
#
# Usage: bash triage.sh "task description"
# Output: CODE_SIMPLE | CODE_COMPLEX | CODE_MULTI | CREATIVE | RESEARCH | CHAT | DOMAIN:<agent>
#
# Cost: $0 (Claude Max subscription via CLI)
# Latency: ~1-2 seconds

set -euo pipefail

TASK="${1:?Usage: triage.sh \"task description\"}"

# Ensure we're using CLI subscription auth, not API key
# Unset any API keys that might override CLI auth
unset ANTHROPIC_API_KEY 2>/dev/null || true
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT 2>/dev/null || true

CLAUDE_BIN="/Users/jennwoeiloh/.local/bin/claude"

if [ ! -x "$CLAUDE_BIN" ]; then
  echo "CODE_SIMPLE"  # Safe fallback if CLI missing
  exit 0
fi

# One-shot Haiku classification — structured output, no tools
RESULT=$(PATH="/Users/jennwoeiloh/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin" \
  HOME="$HOME" \
  timeout 15 "$CLAUDE_BIN" -p \
    --model haiku \
    --output-format text \
    --system-prompt "You are a task classifier. Given a user task, output EXACTLY ONE category label. No explanation, no punctuation, just the label.

CODE_SIMPLE = fix typo, small bug fix, rename variable, update text, minor config change, add single endpoint, small script, update CSS
CODE_COMPLEX = build new feature, refactor entire module, restyle entire app, new page/component, API integration, database change, deploy new system, think deeply about architecture, system redesign, plan migration, review and restructure codebase, deep analysis
CODE_MULTI = 2+ independent tasks joined by 'and' or 'then' (e.g. 'fix API and update frontend and write tests')
CREATIVE = write copy, captions, scripts, brand content, social media text, creative direction
RESEARCH = find info, market research, competitor analysis, trends, scraping, data gathering
STRATEGY = business analysis, forecasting, KPI, performance review, planning, metrics
VISUAL = generate image, design poster, banner, avatar, character art, thumbnail, video
ADS = ad campaign, budget, pricing, ROAS, Meta/Google/TikTok ads
REVENUE = products, gumroad, monetization, sales funnel, e-commerce
OPS = git, file management, health check, system status, ping
CHAT = greeting, thanks, chitchat, 'hello', 'how are you', help

IMPORTANT: 'think', 'deepthink', 'architecture', 'restyle entire', 'plan migration', 'review codebase' → CODE_COMPLEX (needs Opus).
'fix typo', 'update text', 'small change', 'add button' → CODE_SIMPLE (Sonnet is fine).

Examples:
'fix the typo on homepage' → CODE_SIMPLE
'build a new auth system' → CODE_COMPLEX
'fix API and update UI and add tests' → CODE_MULTI
'write instagram captions' → CREATIVE
'what are trending brands' → RESEARCH
'generate a poster' → VISUAL
'check our Q1 numbers' → STRATEGY
'hi there' → CHAT
'build an e-commerce checkout' → CODE_COMPLEX
'think about how to restructure the gateway' → CODE_COMPLEX
'restyle the entire app to match gaia os' → CODE_COMPLEX
'deepthink on system architecture' → CODE_COMPLEX
'fix the broken CSS' → CODE_SIMPLE
'plan the database migration' → CODE_COMPLEX

Output ONLY the label:" \
    "$TASK" 2>/dev/null) || RESULT=""

# Clean up response — extract just the category
RESULT=$(echo "$RESULT" | tr -d '[:space:]' | head -c 20)

# Validate — only accept known categories
case "$RESULT" in
  CODE_SIMPLE|CODE_COMPLEX|CODE_MULTI)
    echo "$RESULT"
    ;;
  CREATIVE)
    echo "DOMAIN:dreami"
    ;;
  RESEARCH)
    echo "DOMAIN:artemis"
    ;;
  STRATEGY)
    echo "DOMAIN:athena"
    ;;
  VISUAL)
    echo "DOMAIN:iris"
    ;;
  ADS|REVENUE)
    echo "DOMAIN:hermes"
    ;;
  OPS)
    echo "DOMAIN:myrmidons"
    ;;
  CHAT)
    echo "CHAT"
    ;;
  *)
    # Unknown response — safe fallback to sonnet (handles most things well)
    echo "CODE_SIMPLE"
    ;;
esac
