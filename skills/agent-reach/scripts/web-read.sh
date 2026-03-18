#!/usr/bin/env bash
# web-read.sh — Read any webpage via Jina Reader (Agent-Reach)
# Free, no API key, no auth needed
#
# Usage:
#   bash web-read.sh "https://example.com"
#   bash web-read.sh "https://example.com" --summary
#
# For agents: Artemis, Hermes, Athena, Dreami can all call this

set -euo pipefail

URL="${1:-}"
MODE="${2:---full}"

if [[ -z "$URL" ]]; then
  echo "❌ Usage: web-read.sh <url> [--summary|--full]"
  exit 1
fi

if [[ "$MODE" == "--summary" ]]; then
  # Jina Reader with summary mode
  curl -s -H "X-Return-Format: text" "https://r.jina.ai/${URL}" | head -100
else
  curl -s "https://r.jina.ai/${URL}"
fi
