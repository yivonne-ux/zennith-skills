#!/usr/bin/env bash
# Auth Browser — Universal authenticated browser for Zennith OS
# Uses Chrome CDP with persistent profile at ~/.chrome-cdp
set -euo pipefail

PROFILE="$HOME/.chrome-cdp"
PORT=9222
P3="$(command -v python3 || echo /usr/bin/python3)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Service URLs
declare_services() {
  # Can't use associative arrays (Bash 3.2)
  case "$1" in
    facebook) echo "https://www.facebook.com" ;;
    meta) echo "https://business.facebook.com" ;;
    instagram) echo "https://www.instagram.com" ;;
    shopify) echo "https://admin.shopify.com" ;;
    google-ads) echo "https://ads.google.com" ;;
    klaviyo) echo "https://www.klaviyo.com/dashboard" ;;
    tiktok) echo "https://ads.tiktok.com" ;;
    *) echo "" ;;
  esac
}

check_cdp() {
  curl -s "http://127.0.0.1:$PORT/json/version" 2>/dev/null | "$P3" -c "import sys,json;print(json.loads(sys.stdin.read()).get('Browser',''))" 2>/dev/null
}

case "${1:-help}" in
  start)
    if [ -n "$(check_cdp)" ]; then
      echo "CDP already running: $(check_cdp)"
      exit 0
    fi
    echo "Quitting Chrome..."
    osascript -e 'quit app "Google Chrome"' 2>/dev/null || true
    sleep 3
    mkdir -p "$PROFILE"
    echo "Launching Chrome with CDP on port $PORT..."
    "$CHROME" --remote-debugging-port=$PORT --user-data-dir="$PROFILE" "https://www.google.com" &
    sleep 6
    browser=$(check_cdp)
    if [ -n "$browser" ]; then
      echo "Chrome CDP ready: $browser"
      echo "Profile: $PROFILE"
      echo "Port: $PORT"
    else
      echo "ERROR: Chrome didn't start with CDP"
      exit 1
    fi
    ;;

  stop)
    osascript -e 'quit app "Google Chrome"' 2>/dev/null || true
    echo "Chrome stopped"
    ;;

  check)
    browser=$(check_cdp)
    if [ -n "$browser" ]; then
      echo "CDP running: $browser"
      # List open tabs
      curl -s "http://127.0.0.1:$PORT/json" 2>/dev/null | "$P3" -c "
import sys,json
tabs=json.loads(sys.stdin.read())
for t in tabs:
    if t.get('type')=='page': print(f'  {t.get(\"title\",\"?\")[:40]} — {t.get(\"url\",\"?\")[:60]}')"
    else
      echo "CDP not running. Run: browser.sh start"
    fi
    ;;

  nav)
    url="${2:?Usage: browser.sh nav <url>}"
    "$P3" << PYEOF
from playwright.sync_api import sync_playwright
import time
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    ctx = b.contexts[0]
    page = ctx.new_page() if not ctx.pages else ctx.pages[-1]
    page.goto("$url", timeout=30000)
    time.sleep(3)
    print(f"{page.title()} — {page.url[:80]}")
PYEOF
    ;;

  text)
    "$P3" << PYEOF
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    page = b.contexts[0].pages[-1]
    print(page.inner_text("body")[:2000])
PYEOF
    ;;

  screenshot)
    out="${2:-/tmp/browser-screenshot.jpg}"
    "$P3" << PYEOF
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    page = b.contexts[0].pages[-1]
    page.screenshot(path="$out")
    print(f"Screenshot: $out")
PYEOF
    ;;

  services)
    echo "=== AUTHENTICATED SERVICES ==="
    for svc in facebook meta instagram shopify google-ads klaviyo tiktok; do
      url=$(declare_services "$svc")
      "$P3" << PYEOF 2>/dev/null
from playwright.sync_api import sync_playwright
import time
try:
    with sync_playwright() as p:
        b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
        page = b.contexts[0].new_page()
        page.goto("$url", timeout=15000)
        time.sleep(4)
        logged_in = "login" not in page.url.lower() and "signin" not in page.url.lower() and "signup" not in page.url.lower()
        status = "LOGGED IN" if logged_in else "NOT logged in"
        print(f"  {'$svc':15} {status:15} {page.url[:50]}")
        page.close()
except Exception as e:
    print(f"  {'$svc':15} {'ERROR':15} {str(e)[:40]}")
PYEOF
    done
    ;;

  login)
    svc="${2:?Usage: browser.sh login <service>}"
    url=$(declare_services "$svc")
    if [ -z "$url" ]; then
      echo "Unknown service: $svc"
      echo "Available: facebook, meta, instagram, shopify, google-ads, klaviyo, tiktok"
      exit 1
    fi
    "$P3" << PYEOF
from playwright.sync_api import sync_playwright
import time
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    page = b.contexts[0].new_page()
    page.goto("$url", timeout=30000)
    time.sleep(3)
    print(f"Opened: {page.title()} — {page.url[:60]}")
    print("Log in via the Chrome window. Session will persist.")
PYEOF
    ;;

  run)
    script="${2:?Usage: browser.sh run <script.py>}"
    CDP_URL="http://127.0.0.1:$PORT" "$P3" "$script"
    ;;

  help|--help|-h|*)
    echo "Auth Browser — Universal authenticated browser"
    echo ""
    echo "Usage: browser.sh <command> [args]"
    echo ""
    echo "Lifecycle:"
    echo "  start                  Launch Chrome CDP (headed)"
    echo "  stop                   Quit Chrome"
    echo "  check                  Show CDP status + open tabs"
    echo ""
    echo "Navigate:"
    echo "  nav <url>              Go to URL"
    echo "  text                   Get page text"
    echo "  screenshot [path]      Take screenshot"
    echo ""
    echo "Auth:"
    echo "  services               Check which services are logged in"
    echo "  login <service>        Open login page"
    echo ""
    echo "Advanced:"
    echo "  run <script.py>        Run Playwright script (CDP_URL env set)"
    echo ""
    echo "Services: facebook meta instagram shopify google-ads klaviyo tiktok"
    ;;
esac
