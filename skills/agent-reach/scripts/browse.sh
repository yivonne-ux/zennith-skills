#!/usr/bin/env bash
# browse.sh — Unified browser for Zennith OS (Claude Code + OpenClaw)
# Single entry point. Headless by default. CDP for auth pages. No visible windows.
#
# Usage:
#   browse.sh nav "https://example.com"              # headless navigate + get text
#   browse.sh nav "https://example.com" --auth        # use CDP (logged-in Chrome)
#   browse.sh screenshot "https://example.com"        # headless screenshot
#   browse.sh screenshot "https://example.com" --auth # auth screenshot
#   browse.sh text                                    # get current page text (auth mode)
#   browse.sh click "selector"                        # click element (auth mode)
#   browse.sh fill "selector" "value"                 # fill input (auth mode)
#   browse.sh eval "document.title"                   # run JS
#   browse.sh wait "selector" [timeout_ms]            # wait for element
#   browse.sh pdf "https://example.com" [output.pdf]  # save page as PDF
#   browse.sh check                                   # check CDP status
#   browse.sh test                                    # run self-test loop

set -euo pipefail

P3="$(command -v python3 || echo /usr/bin/python3)"
CDP_PORT="${CDP_PORT:-9222}"
CDP_URL="http://127.0.0.1:${CDP_PORT}"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/tmp}"

# ─── Helpers ────────────────────────────────────────────────────────
log() { echo "[browse $(date +%H:%M:%S)] $*" >&2; }

check_cdp() {
  curl -s "${CDP_URL}/json/version" 2>/dev/null | "$P3" -c "import sys,json;print(json.loads(sys.stdin.read()).get('Browser',''))" 2>/dev/null || echo ""
}

use_auth() {
  # Check if --auth flag is present in any argument
  for arg in "$@"; do
    [[ "$arg" == "--auth" ]] && return 0
  done
  return 1
}

strip_flags() {
  # Remove --auth and other flags from args
  local result=()
  for arg in "$@"; do
    [[ "$arg" == --* ]] || result+=("$arg")
  done
  echo "${result[@]}"
}

# ─── HEADLESS MODE (default) — Playwright launches its own Chromium ─
headless_nav() {
  local url="$1"
  local max_chars="${2:-3000}"
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright
import sys

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    try:
        page.goto("${url}", timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(2000)
        title = page.title()
        url_final = page.url
        text = page.inner_text("body")[:${max_chars}]
        print(f"TITLE: {title}")
        print(f"URL: {url_final}")
        print(f"---")
        print(text)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        browser.close()
PYEOF
}

headless_screenshot() {
  local url="$1"
  local outfile="${2:-${SCREENSHOT_DIR}/browse-$(date +%s).png}"
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright
import sys

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    try:
        page.goto("${url}", timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(2000)
        page.screenshot(path="${outfile}", full_page=False)
        print("${outfile}")
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        browser.close()
PYEOF
}

headless_pdf() {
  local url="$1"
  local outfile="${2:-${SCREENSHOT_DIR}/browse-$(date +%s).pdf}"
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright
import sys

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    try:
        page.goto("${url}", timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(3000)
        page.pdf(path="${outfile}")
        print("${outfile}")
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        browser.close()
PYEOF
}

# ─── AUTH MODE — Connect to existing Chrome via CDP (for logged-in pages) ─
cdp_ensure() {
  local browser
  browser=$(check_cdp)
  if [[ -z "$browser" ]]; then
    log "ERROR: Chrome CDP not running on port ${CDP_PORT}"
    log "Start it: /Users/jennwoeiloh/.openclaw/skills/auth-browser/scripts/browser.sh start"
    exit 1
  fi
}

cdp_nav() {
  local url="$1"
  local max_chars="${2:-3000}"
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright
import sys

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    ctx = b.contexts[0]
    page = ctx.new_page()
    try:
        page.goto("${url}", timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(2000)
        title = page.title()
        url_final = page.url
        text = page.inner_text("body")[:${max_chars}]
        print(f"TITLE: {title}")
        print(f"URL: {url_final}")
        print(f"---")
        print(text)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        page.close()
PYEOF
}

cdp_text() {
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    page = b.contexts[0].pages[-1]
    print(page.inner_text("body")[:5000])
PYEOF
}

cdp_screenshot() {
  local outfile="${1:-${SCREENSHOT_DIR}/browse-cdp-$(date +%s).png}"
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    page = b.contexts[0].pages[-1]
    page.screenshot(path="${outfile}")
    print("${outfile}")
PYEOF
}

cdp_click() {
  local selector="$1"
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    page = b.contexts[0].pages[-1]
    page.click("${selector}", timeout=10000)
    print(f"Clicked: ${selector}")
    print(f"URL: {page.url}")
PYEOF
}

cdp_fill() {
  local selector="$1"
  local value="$2"
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    page = b.contexts[0].pages[-1]
    page.fill("${selector}", "${value}", timeout=10000)
    print(f"Filled: ${selector} = ${value}")
PYEOF
}

cdp_eval() {
  local js="$1"
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    page = b.contexts[0].pages[-1]
    result = page.evaluate("${js}")
    print(result)
PYEOF
}

cdp_wait() {
  local selector="$1"
  local timeout="${2:-10000}"
  cdp_ensure
  "$P3" << PYEOF
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("${CDP_URL}")
    page = b.contexts[0].pages[-1]
    page.wait_for_selector("${selector}", timeout=${timeout})
    print(f"Found: ${selector}")
PYEOF
}

# ─── Self-test loop ─────────────────────────────────────────────────
run_test() {
  local pass=0
  local fail=0
  local total=0

  test_case() {
    local name="$1"
    shift
    total=$((total + 1))
    log "TEST $total: $name"
    if output=$("$@" 2>&1); then
      log "  PASS"
      pass=$((pass + 1))
    else
      log "  FAIL: $output"
      fail=$((fail + 1))
    fi
  }

  log "=== BROWSE.SH SELF-TEST ==="
  log ""

  # Headless tests
  test_case "Headless navigate" bash "$0" nav "https://httpbin.org/get"
  test_case "Headless screenshot" bash "$0" screenshot "https://httpbin.org/get"
  test_case "Headless navigate (complex page)" bash "$0" nav "https://example.com"

  # CDP tests (only if running)
  if [[ -n "$(check_cdp)" ]]; then
    test_case "CDP navigate" bash "$0" nav "https://httpbin.org/get" --auth
    test_case "CDP text" bash "$0" text
    test_case "CDP screenshot" bash "$0" screenshot --auth
  else
    log "SKIP: CDP tests (Chrome not running on port ${CDP_PORT})"
  fi

  log ""
  log "=== RESULTS: $pass/$total passed, $fail failed ==="

  [[ "$fail" -eq 0 ]] && return 0 || return 1
}

# ─── Command router ─────────────────────────────────────────────────
cmd="${1:-help}"
shift || true

case "$cmd" in
  nav|navigate)
    url="${1:?Usage: browse.sh nav <url> [--auth]}"
    if use_auth "$@"; then
      cdp_nav "$url"
    else
      headless_nav "$url"
    fi
    ;;

  screenshot|ss)
    if use_auth "$@"; then
      # Auth screenshot of current page
      outfile=""
      for arg in "$@"; do
        [[ "$arg" != --* ]] && outfile="$arg" && break
      done
      cdp_screenshot "${outfile:-}"
    else
      url="${1:?Usage: browse.sh screenshot <url> [output.png] [--auth]}"
      outfile="${2:-}"
      [[ "$outfile" == --* ]] && outfile=""
      headless_screenshot "$url" ${outfile:+"$outfile"}
    fi
    ;;

  text)
    cdp_text
    ;;

  click)
    selector="${1:?Usage: browse.sh click <selector>}"
    cdp_click "$selector"
    ;;

  fill)
    selector="${1:?Usage: browse.sh fill <selector> <value>}"
    value="${2:?Usage: browse.sh fill <selector> <value>}"
    cdp_fill "$selector" "$value"
    ;;

  eval|js)
    js="${1:?Usage: browse.sh eval <js-expression>}"
    cdp_eval "$js"
    ;;

  wait)
    selector="${1:?Usage: browse.sh wait <selector> [timeout_ms]}"
    timeout="${2:-10000}"
    cdp_wait "$selector" "$timeout"
    ;;

  pdf)
    url="${1:?Usage: browse.sh pdf <url> [output.pdf]}"
    headless_pdf "$url" "${2:-}"
    ;;

  check|status)
    browser=$(check_cdp)
    if [[ -n "$browser" ]]; then
      echo "CDP: RUNNING ($browser) on port ${CDP_PORT}"
      curl -s "${CDP_URL}/json" 2>/dev/null | "$P3" -c "
import sys,json
tabs=json.loads(sys.stdin.read())
for t in tabs:
    if t.get('type')=='page': print(f'  {t.get(\"title\",\"?\")[:40]} — {t.get(\"url\",\"?\")[:60]}')" 2>/dev/null
    else
      echo "CDP: NOT RUNNING"
    fi
    echo "Playwright: $(python3 -c 'import playwright; print("installed")' 2>/dev/null || echo 'NOT INSTALLED')"
    echo "Headless: always available (no Chrome needed)"
    ;;

  test)
    run_test
    ;;

  help|--help|-h|*)
    cat << 'HELP'
browse.sh — Unified Zennith OS Browser

HEADLESS (default, no windows, always works):
  nav <url>                    Navigate + extract text
  screenshot <url> [file]      Take screenshot
  pdf <url> [file]             Save as PDF

AUTH MODE (--auth flag, uses Chrome CDP for logged-in pages):
  nav <url> --auth             Navigate with auth session
  screenshot --auth [file]     Screenshot current auth page
  text                         Get current page text
  click <selector>             Click element
  fill <selector> <value>      Fill input
  eval <js>                    Run JavaScript
  wait <selector> [timeout]    Wait for element

SYSTEM:
  check                        Show CDP + Playwright status
  test                         Run self-test loop

Environment:
  CDP_PORT=9222                Chrome DevTools Protocol port
  SCREENSHOT_DIR=/tmp          Where screenshots are saved
HELP
    ;;
esac
