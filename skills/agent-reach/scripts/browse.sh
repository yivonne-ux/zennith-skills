#!/usr/bin/env bash
# browse.sh — Unified headless browser for Zennith OS
# ALWAYS headless. Persistent auth via saved cookies (no visible Chrome).
#
# Usage:
#   browse.sh nav "https://example.com"                    # navigate + get text
#   browse.sh screenshot "https://example.com"             # take screenshot
#   browse.sh screenshot "https://example.com" out.png     # screenshot to file
#   browse.sh pdf "https://example.com"                    # save as PDF
#   browse.sh login "https://accounts.google.com"          # interactive login (saves session)
#   browse.sh click "selector"                             # click element on current page
#   browse.sh fill "selector" "value"                      # fill input
#   browse.sh eval "document.title"                        # run JS
#   browse.sh wait "selector" [timeout_ms]                 # wait for element
#   browse.sh cookies list                                 # list saved auth domains
#   browse.sh cookies clear [domain]                       # clear saved cookies
#   browse.sh check                                        # show status
#   browse.sh test                                         # run self-test
#
# Auth: First run `browse.sh login <url>` to log in (opens ONE visible window, saves cookies).
#        All subsequent `nav`, `screenshot`, etc. reuse saved cookies HEADLESSLY.
#        Cookie state saved at: ~/.openclaw/browser/auth-state.json
#
# Google services: Run `browse.sh login "https://accounts.google.com"` once.
#                  Then `browse.sh nav "https://drive.google.com"` works headlessly forever.

set -euo pipefail

P3="$(command -v python3 || echo /usr/bin/python3)"
AUTH_DIR="$HOME/.openclaw/browser"
AUTH_STATE="$AUTH_DIR/auth-state.json"
USER_DATA_DIR="$AUTH_DIR/chromium-profile"
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/tmp}"

mkdir -p "$AUTH_DIR"

# ─── Helpers ────────────────────────────────────────────────────────
log() { echo "[browse $(date +%H:%M:%S)] $*" >&2; }

has_auth() { [[ -f "$AUTH_STATE" ]] && [[ -s "$AUTH_STATE" ]]; }

# ─── HEADLESS NAV (with persistent auth) ────────────────────────────
headless_nav() {
  local url="$1"
  local max_chars="${2:-5000}"
  "$P3" - "$url" "$max_chars" "$AUTH_STATE" "$USER_DATA_DIR" << 'PYEOF'
import sys, os, json

url = sys.argv[1]
max_chars = int(sys.argv[2])
auth_state = sys.argv[3]
user_data_dir = sys.argv[4]

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    # Use persistent context for cookie reuse
    ctx = p.chromium.launch_persistent_context(
        user_data_dir,
        headless=True,
        viewport={"width": 1280, "height": 720},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        locale="en-US",
        timezone_id="Asia/Kuala_Lumpur",
        ignore_https_errors=True,
    )

    # Load saved auth state if available
    if os.path.exists(auth_state):
        try:
            with open(auth_state) as f:
                state = json.load(f)
            for cookie in state.get("cookies", []):
                try:
                    ctx.add_cookies([cookie])
                except:
                    pass
        except:
            pass

    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    try:
        page.goto(url, timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(2000)
        title = page.title()
        url_final = page.url
        text = page.inner_text("body")[:max_chars]
        print(f"TITLE: {title}")
        print(f"URL: {url_final}")
        print(f"---")
        print(text)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        # Save updated cookies back
        try:
            cookies = ctx.cookies()
            storage = {"cookies": cookies}
            with open(auth_state, "w") as f:
                json.dump(storage, f, indent=2)
        except:
            pass
        ctx.close()
PYEOF
}

# ─── HEADLESS SCREENSHOT ────────────────────────────────────────────
headless_screenshot() {
  local url="$1"
  local outfile="${2:-${SCREENSHOT_DIR}/browse-$(date +%s).png}"
  "$P3" - "$url" "$outfile" "$AUTH_STATE" "$USER_DATA_DIR" << 'PYEOF'
import sys, os, json

url = sys.argv[1]
outfile = sys.argv[2]
auth_state = sys.argv[3]
user_data_dir = sys.argv[4]

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(
        user_data_dir,
        headless=True,
        viewport={"width": 1280, "height": 720},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        locale="en-US",
        timezone_id="Asia/Kuala_Lumpur",
        ignore_https_errors=True,
    )

    if os.path.exists(auth_state):
        try:
            with open(auth_state) as f:
                state = json.load(f)
            for cookie in state.get("cookies", []):
                try:
                    ctx.add_cookies([cookie])
                except:
                    pass
        except:
            pass

    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    try:
        page.goto(url, timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(2000)
        page.screenshot(path=outfile, full_page=False)
        print(outfile)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        try:
            cookies = ctx.cookies()
            with open(auth_state, "w") as f:
                json.dump({"cookies": cookies}, f, indent=2)
        except:
            pass
        ctx.close()
PYEOF
}

# ─── HEADLESS PDF ───────────────────────────────────────────────────
headless_pdf() {
  local url="$1"
  local outfile="${2:-${SCREENSHOT_DIR}/browse-$(date +%s).pdf}"
  "$P3" - "$url" "$outfile" "$AUTH_STATE" "$USER_DATA_DIR" << 'PYEOF'
import sys, os, json

url = sys.argv[1]
outfile = sys.argv[2]
auth_state = sys.argv[3]
user_data_dir = sys.argv[4]

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(
        user_data_dir,
        headless=True,
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        ignore_https_errors=True,
    )

    if os.path.exists(auth_state):
        try:
            with open(auth_state) as f:
                state = json.load(f)
            for cookie in state.get("cookies", []):
                try:
                    ctx.add_cookies([cookie])
                except:
                    pass
        except:
            pass

    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    try:
        page.goto(url, timeout=30000, wait_until="domcontentloaded")
        page.wait_for_timeout(3000)
        page.pdf(path=outfile)
        print(outfile)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        try:
            cookies = ctx.cookies()
            with open(auth_state, "w") as f:
                json.dump({"cookies": cookies}, f, indent=2)
        except:
            pass
        ctx.close()
PYEOF
}

# ─── LOGIN (one-time, visible browser, saves cookies) ───────────────
do_login() {
  local url="${1:-https://accounts.google.com}"
  log "Opening visible browser for login. Log in manually, then close the browser."
  log "Cookies will be saved to: $AUTH_STATE"
  "$P3" - "$url" "$AUTH_STATE" "$USER_DATA_DIR" << 'PYEOF'
import sys, os, json, time

url = sys.argv[1]
auth_state = sys.argv[2]
user_data_dir = sys.argv[3]

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    # VISIBLE browser for manual login
    ctx = p.chromium.launch_persistent_context(
        user_data_dir,
        headless=False,
        viewport={"width": 1280, "height": 900},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        locale="en-US",
        timezone_id="Asia/Kuala_Lumpur",
        ignore_https_errors=True,
    )

    page = ctx.pages[0] if ctx.pages else ctx.new_page()
    page.goto(url, timeout=60000, wait_until="domcontentloaded")

    print(f"Browser opened at: {url}")
    print("Log in manually. When done, close the browser window.")
    print("Waiting for browser to close...")

    # Wait for user to close browser
    try:
        while True:
            try:
                _ = page.title()
                time.sleep(1)
            except:
                break
    except:
        pass

    # Save all cookies
    try:
        cookies = ctx.cookies()
        storage = {"cookies": cookies, "logged_in_at": time.strftime("%Y-%m-%d %H:%M:%S")}
        with open(auth_state, "w") as f:
            json.dump(storage, f, indent=2)
        print(f"Saved {len(cookies)} cookies to {auth_state}")
        domains = set()
        for c in cookies:
            d = c.get("domain", "").lstrip(".")
            if d:
                domains.add(d)
        print(f"Domains: {', '.join(sorted(domains)[:20])}")
    except Exception as e:
        print(f"Warning: could not save cookies: {e}", file=sys.stderr)
    finally:
        ctx.close()
PYEOF
}

# ─── INTERACTIVE ACTIONS (headless, uses persistent context) ────────
headless_action() {
  local action="$1"
  shift
  "$P3" - "$action" "$AUTH_STATE" "$USER_DATA_DIR" "$@" << 'PYEOF'
import sys, os, json

action = sys.argv[1]
auth_state = sys.argv[2]
user_data_dir = sys.argv[3]
args = sys.argv[4:]

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    ctx = p.chromium.launch_persistent_context(
        user_data_dir,
        headless=True,
        viewport={"width": 1280, "height": 720},
        user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        ignore_https_errors=True,
    )

    if os.path.exists(auth_state):
        try:
            with open(auth_state) as f:
                state = json.load(f)
            for cookie in state.get("cookies", []):
                try:
                    ctx.add_cookies([cookie])
                except:
                    pass
        except:
            pass

    page = ctx.pages[0] if ctx.pages else ctx.new_page()

    try:
        if action == "click":
            selector = args[0]
            page.click(selector, timeout=10000)
            print(f"Clicked: {selector}")
            print(f"URL: {page.url}")

        elif action == "fill":
            selector = args[0]
            value = args[1]
            page.fill(selector, value, timeout=10000)
            print(f"Filled: {selector}")

        elif action == "eval":
            js = args[0]
            result = page.evaluate(js)
            print(result)

        elif action == "wait":
            selector = args[0]
            timeout = int(args[1]) if len(args) > 1 else 10000
            page.wait_for_selector(selector, timeout=timeout)
            print(f"Found: {selector}")

        elif action == "text":
            print(page.inner_text("body")[:5000])

    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        try:
            cookies = ctx.cookies()
            with open(auth_state, "w") as f:
                json.dump({"cookies": cookies}, f, indent=2)
        except:
            pass
        ctx.close()
PYEOF
}

# ─── Cookie management ──────────────────────────────────────────────
manage_cookies() {
  local subcmd="${1:-list}"
  case "$subcmd" in
    list)
      if has_auth; then
        "$P3" -c "
import json
with open('$AUTH_STATE') as f:
    data = json.load(f)
cookies = data.get('cookies', [])
domains = {}
for c in cookies:
    d = c.get('domain', '').lstrip('.')
    domains[d] = domains.get(d, 0) + 1
print(f'Total cookies: {len(cookies)}')
print(f'Logged in at: {data.get(\"logged_in_at\", \"unknown\")}')
print(f'Domains ({len(domains)}):')
for d in sorted(domains):
    print(f'  {d} ({domains[d]} cookies)')
"
      else
        echo "No saved auth state. Run: browse.sh login <url>"
      fi
      ;;
    clear)
      local domain="${2:-}"
      if [[ -z "$domain" ]]; then
        rm -f "$AUTH_STATE"
        rm -rf "$USER_DATA_DIR"
        echo "All cookies and browser profile cleared"
      else
        "$P3" -c "
import json
with open('$AUTH_STATE') as f:
    data = json.load(f)
before = len(data.get('cookies', []))
data['cookies'] = [c for c in data.get('cookies', []) if '$domain' not in c.get('domain', '')]
after = len(data['cookies'])
with open('$AUTH_STATE', 'w') as f:
    json.dump(data, f, indent=2)
print(f'Removed {before - after} cookies for $domain')
"
      fi
      ;;
  esac
}

# ─── Self-test ──────────────────────────────────────────────────────
run_test() {
  local pass=0 fail=0 total=0

  test_case() {
    local name="$1"
    shift
    total=$((total + 1))
    log "TEST $total: $name"
    if output=$("$@" 2>&1); then
      log "  PASS"
      pass=$((pass + 1))
    else
      log "  FAIL: $(echo "$output" | head -3)"
      fail=$((fail + 1))
    fi
  }

  log "=== BROWSE.SH SELF-TEST ==="
  test_case "Headless nav (example.com)" bash "$0" nav "https://example.com"
  test_case "Headless screenshot" bash "$0" screenshot "https://example.com"
  test_case "Headless nav (httpbin)" bash "$0" nav "https://httpbin.org/get"

  # Test auth if state exists
  if has_auth; then
    log "Auth state found — testing authenticated access"
    test_case "Auth nav (Google)" bash "$0" nav "https://drive.google.com"
    test_case "Auth screenshot (Google)" bash "$0" screenshot "https://drive.google.com"
  else
    log "SKIP: No auth state. Run 'browse.sh login https://accounts.google.com' first."
  fi

  log ""
  log "=== RESULTS: $pass/$total passed, $fail failed ==="
  [[ "$fail" -eq 0 ]]
}

# ─── Command router ─────────────────────────────────────────────────
cmd="${1:-help}"
shift || true

case "$cmd" in
  nav|navigate)
    url="${1:?Usage: browse.sh nav <url>}"
    headless_nav "$url"
    ;;

  screenshot|ss)
    url="${1:?Usage: browse.sh screenshot <url> [output.png]}"
    outfile="${2:-}"
    headless_screenshot "$url" ${outfile:+"$outfile"}
    ;;

  pdf)
    url="${1:?Usage: browse.sh pdf <url> [output.pdf]}"
    headless_pdf "$url" "${2:-}"
    ;;

  login|auth)
    url="${1:-https://accounts.google.com}"
    do_login "$url"
    ;;

  text)
    headless_action "text"
    ;;

  click)
    selector="${1:?Usage: browse.sh click <selector>}"
    headless_action "click" "$selector"
    ;;

  fill)
    selector="${1:?Usage: browse.sh fill <selector> <value>}"
    value="${2:?Usage: browse.sh fill <selector> <value>}"
    headless_action "fill" "$selector" "$value"
    ;;

  eval|js)
    js="${1:?Usage: browse.sh eval <js-expression>}"
    headless_action "eval" "$js"
    ;;

  wait)
    selector="${1:?Usage: browse.sh wait <selector> [timeout_ms]}"
    timeout="${2:-10000}"
    headless_action "wait" "$selector" "$timeout"
    ;;

  cookies)
    manage_cookies "$@"
    ;;

  check|status)
    echo "Playwright: $(python3 -c 'import playwright; print("installed")' 2>/dev/null || echo 'NOT INSTALLED')"
    echo "Auth state: $(has_auth && echo "YES ($AUTH_STATE)" || echo "NO — run: browse.sh login <url>")"
    if has_auth; then
      manage_cookies list
    fi
    echo "Mode: ALWAYS headless (persistent context at $USER_DATA_DIR)"
    ;;

  test)
    run_test
    ;;

  help|--help|-h|*)
    cat << 'HELP'
browse.sh — Unified Headless Browser (Zennith OS)

ALL HEADLESS (no visible windows):
  nav <url>                    Navigate + extract text
  screenshot <url> [file]      Take screenshot
  pdf <url> [file]             Save as PDF
  click <selector>             Click element
  fill <selector> <value>      Fill input
  eval <js>                    Run JavaScript
  wait <selector> [timeout]    Wait for element
  text                         Get current page text

AUTH (one-time setup, then everything stays headless):
  login [url]                  Open visible browser to log in (saves cookies)
                               Default: https://accounts.google.com
                               After login, close browser — cookies saved forever.
                               All subsequent commands use saved cookies headlessly.

COOKIE MANAGEMENT:
  cookies list                 Show saved auth domains
  cookies clear [domain]       Clear cookies (all or by domain)

SYSTEM:
  check                        Show status + saved auth info
  test                         Run self-test loop

How Google services work:
  1. Run: browse.sh login       (log into Google once, close browser)
  2. Then: browse.sh nav "https://drive.google.com"  (works headlessly!)
  3. Cookies persist at: ~/.openclaw/browser/auth-state.json

Environment:
  SCREENSHOT_DIR=/tmp          Where screenshots are saved
HELP
    ;;
esac
