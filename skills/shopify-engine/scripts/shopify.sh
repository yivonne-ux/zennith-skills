#!/usr/bin/env bash
# Shopify Engine — Unified Shopify CLI for Zennith OS
# Theme ops via Shopify CLI, admin ops via Chrome CDP
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SECRETS_DIR="$REPO_DIR/secrets"
STORE_FILE="$SECRETS_DIR/shopify-store"
PORT=9222
P3="$(command -v python3 || echo /usr/bin/python3)"
SHOPIFY_CLI="$(command -v shopify 2>/dev/null || echo "")"

get_store() {
  if [ ! -f "$STORE_FILE" ]; then
    echo "No store configured. Run: shopify.sh setup <store_url>"
    exit 1
  fi
  cat "$STORE_FILE"
}

check_cdp() {
  curl -s "http://127.0.0.1:$PORT/json/version" 2>/dev/null | "$P3" -c "import sys,json;print(json.loads(sys.stdin.read()).get('Browser',''))" 2>/dev/null
}

require_cdp() {
  if [ -z "$(check_cdp)" ]; then
    echo "Chrome CDP not running. Start it first:"
    echo "  bash $REPO_DIR/skills/auth-browser/scripts/browser.sh start"
    exit 1
  fi
}

case "${1:-help}" in
  setup)
    mkdir -p "$SECRETS_DIR"
    echo "${2:?Usage: shopify.sh setup <store_url>}" > "$STORE_FILE"
    chmod 600 "$STORE_FILE"
    echo "Store saved: $(cat "$STORE_FILE")"
    ;;

  status)
    store=$(get_store)
    echo "=== SHOPIFY STATUS ==="
    echo "Store: $store"
    echo "CLI: ${SHOPIFY_CLI:-NOT INSTALLED}"
    echo "CDP: $(check_cdp || echo 'not running')"
    if [ -n "$SHOPIFY_CLI" ]; then
      $SHOPIFY_CLI theme list --store "$store" 2>/dev/null || echo "  (theme list failed — auth needed?)"
    fi
    ;;

  theme-push)
    store=$(get_store)
    [ -z "$SHOPIFY_CLI" ] && echo "Shopify CLI not installed" && exit 1
    $SHOPIFY_CLI theme push --store "$store" --allow-live
    ;;

  theme-pull)
    store=$(get_store)
    [ -z "$SHOPIFY_CLI" ] && echo "Shopify CLI not installed" && exit 1
    $SHOPIFY_CLI theme pull --store "$store"
    ;;

  theme-list)
    store=$(get_store)
    [ -z "$SHOPIFY_CLI" ] && echo "Shopify CLI not installed" && exit 1
    $SHOPIFY_CLI theme list --store "$store"
    ;;

  products)
    require_cdp
    store=$(get_store)
    "$P3" << PYEOF
import time
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    ctx = b.contexts[0]
    page = ctx.new_page()
    page.goto("https://admin.shopify.com/store/${store%%.*}/products", timeout=30000)
    time.sleep(6)
    links = page.locator('a[href*="/products/"]')
    for i in range(links.count()):
        try:
            t = links.nth(i).inner_text().strip()
            h = links.nth(i).get_attribute("href") or ""
            pid = h.split("/products/")[-1].split("?")[0]
            if t and pid and pid.isdigit():
                print(f"  {pid}: {t}")
        except: pass
    page.close()
PYEOF
    ;;

  product-create)
    require_cdp
    store=$(get_store)
    title="${2:?Usage: shopify.sh product-create <title> <price>}"
    price="${3:?}"
    store_id="${store%%.*}"
    "$P3" << PYEOF
import time
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    page = b.contexts[0].new_page()
    page.goto("https://admin.shopify.com/store/$store_id/products/new", timeout=30000)
    time.sleep(6)
    t = page.locator('input[name="title"]')
    if t.count() > 0:
        t.fill("$title"); time.sleep(1)
    pr = page.locator('input[name="price"]')
    if pr.count() > 0:
        pr.fill("$price"); time.sleep(1)
    sv = page.locator('button:has-text("Save")')
    if sv.count() > 0:
        sv.first.click(); time.sleep(4)
        print(f"Created: $title (\$$price)")
    page.close()
PYEOF
    ;;

  product-delete)
    require_cdp
    store=$(get_store)
    pid="${2:?Usage: shopify.sh product-delete <product_id>}"
    store_id="${store%%.*}"
    "$P3" << PYEOF
import time
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    page = b.contexts[0].new_page()
    page.goto("https://admin.shopify.com/store/$store_id/products/$pid", timeout=20000)
    time.sleep(4)
    more = page.locator('button:has-text("More actions")')
    if more.count() > 0:
        more.first.click(); time.sleep(1)
        d = page.locator('[role="menuitem"]:has-text("Delete")')
        if d.count() > 0:
            d.first.click(); time.sleep(2)
            c = page.locator('button:has-text("Delete product")')
            if c.count() > 0:
                c.last.click(); time.sleep(3)
                print(f"Deleted product $pid")
    page.close()
PYEOF
    ;;

  product-rename)
    require_cdp
    store=$(get_store)
    pid="${2:?Usage: shopify.sh product-rename <id> <new_name>}"
    name="${3:?}"
    store_id="${store%%.*}"
    "$P3" << PYEOF
import time
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.connect_over_cdp("http://127.0.0.1:$PORT")
    page = b.contexts[0].new_page()
    page.goto("https://admin.shopify.com/store/$store_id/products/$pid", timeout=30000)
    time.sleep(6)
    t = page.locator('input[name="title"]')
    if t.count() > 0:
        t.fill(""); time.sleep(0.3)
        t.fill("$name"); time.sleep(1)
        sv = page.locator('button:has-text("Save")')
        if sv.count() > 0:
            sv.first.click(); time.sleep(4)
            print(f"Renamed $pid → $name")
    page.close()
PYEOF
    ;;

  browser-start)
    bash "$REPO_DIR/skills/auth-browser/scripts/browser.sh" start
    ;;

  browser-check)
    bash "$REPO_DIR/skills/auth-browser/scripts/browser.sh" check
    ;;

  help|--help|-h|*)
    echo "Shopify Engine — Unified Shopify CLI"
    echo ""
    echo "Usage: shopify.sh <command> [args]"
    echo ""
    echo "Setup:"
    echo "  setup <store_url>              Configure store"
    echo "  status                         Show store info"
    echo ""
    echo "Theme (Shopify CLI):"
    echo "  theme-push                     Push to live"
    echo "  theme-pull                     Pull current"
    echo "  theme-list                     List themes"
    echo ""
    echo "Admin (Chrome CDP):"
    echo "  products                       List products"
    echo "  product-create <title> <price> Create product"
    echo "  product-delete <id>            Delete product"
    echo "  product-rename <id> <name>     Rename product"
    echo ""
    echo "Browser:"
    echo "  browser-start                  Launch Chrome CDP"
    echo "  browser-check                  Check CDP status"
    ;;
esac
