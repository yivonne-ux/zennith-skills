#!/bin/bash
# Unified scraping CLI wrapper for OpenClaw agents
# Routes to Scrapling Python engine in dedicated venv
#
# Usage:
#   scrape.sh fetch <url> [--selector CSS] [--output json|md|text]
#   scrape.sh stealth <url> [--solve-cloudflare]
#   scrape.sh dynamic <url> [--wait 3]
#   scrape.sh crawl <url> [--max-pages 20] [--output-dir DIR]
#   scrape.sh extract <url> --selectors '{"title":"h1","price":".price"}'
#   scrape.sh mcp [--http --port 8000]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="/Users/jennwoeiloh/.openclaw/venvs/scrapling"
PYTHON="${VENV}/bin/python3"
SCRAPLING="${VENV}/bin/scrapling"

if [[ ! -f "$PYTHON" ]]; then
  echo "ERROR: Scrapling venv not found at $VENV" >&2
  echo "Install: python3 -m venv $VENV && ${VENV}/bin/pip install 'scrapling[ai]'" >&2
  exit 1
fi

CMD="${1:-help}"

case "$CMD" in
  fetch|stealth|dynamic|crawl|extract)
    exec "$PYTHON" "${SCRIPT_DIR}/scrape.py" "$@"
    ;;
  mcp)
    shift
    exec "$SCRAPLING" mcp "$@"
    ;;
  shell)
    exec "$SCRAPLING" shell
    ;;
  help|--help|-h)
    echo "Zennith OS Unified Scraper (Scrapling v0.4.2)"
    echo ""
    echo "Commands:"
    echo "  fetch <url>      Basic HTTP (TLS fingerprint spoofing)"
    echo "  stealth <url>    Anti-bot bypass (Cloudflare, headless Chrome)"
    echo "  dynamic <url>    Full browser rendering (JS/SPA pages)"
    echo "  crawl <url>      Spider entire site (async, concurrent)"
    echo "  extract <url>    Structured data extraction (CSS selectors)"
    echo "  mcp              Start Scrapling MCP server"
    echo "  shell            Interactive scraping console"
    echo ""
    echo "Options (all commands):"
    echo "  --selector, -s   CSS selector to extract specific elements"
    echo "  --output, -o     Output format: json (default), md, text"
    echo ""
    echo "Decision matrix (agents: use this to pick mode):"
    echo "  Normal website     → fetch   (fast, $0)"
    echo "  Cloudflare/anti-bot → stealth (bypass, $0)"
    echo "  JS-heavy/SPA       → dynamic (browser render, $0)"
    echo "  Full site           → crawl   (async spider, $0)"
    echo "  Structured data     → extract (selector map, $0)"
    echo "  Auth'd pages        → use Chrome CDP (browser-use skill)"
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run: scrape.sh help" >&2
    exit 1
    ;;
esac
