---
name: shopify-cdp
description: Shopify admin automation via Chrome CDP. Create/delete products, manage collections, configure store settings — all through the real signed-in Chrome browser. No API token needed.
version: 1.0.0
agents: [taoz, main]
---

# Shopify CDP — Admin Automation via Chrome DevTools Protocol

## Why This Exists
Shopify CLI only supports theme operations. The Admin API needs a `shpat_` token from a custom app. Getting that token requires manual steps in the Shopify admin UI. This skill bypasses all of that by controlling the real Chrome browser that's already logged into Shopify admin.

## Prerequisites

1. Chrome installed at `/Applications/Google Chrome.app`
2. User logged into Shopify admin in Chrome (penanghuatgroup@gmail.com)
3. Chrome launched with CDP flag (see below)

## Launch Chrome with CDP

```bash
# First quit any running Chrome
osascript -e 'quit app "Google Chrome"' 2>/dev/null
sleep 2

# Launch with remote debugging + a non-default user-data-dir
# (Chrome requires non-default dir for CDP)
CDP_DIR="$HOME/.chrome-cdp"
mkdir -p "$CDP_DIR"

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 \
  --user-data-dir="$CDP_DIR" \
  "https://admin.shopify.com/store/7qz8cj-uu" &

# Wait for startup
sleep 8

# Verify CDP
curl -s http://localhost:9222/json/version | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('Browser','FAILED'))"
```

**IMPORTANT:** After launching, user must login to Shopify ONCE in the browser. Session persists in `~/.chrome-cdp/` for future runs.

## Check if CDP is Ready

```bash
curl -s http://localhost:9222/json/version 2>/dev/null | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('Browser','NOT RUNNING'))" 2>/dev/null || echo "CDP NOT RUNNING"
```

## Store Details

| Key | Value |
|-----|-------|
| Store URL | `7qz8cj-uu.myshopify.com` |
| Admin URL | `https://admin.shopify.com/store/7qz8cj-uu` |
| Domain | `jadeoracle.co` |
| Account | `penanghuatgroup@gmail.com` |
| CDP Port | `9222` |
| CDP Dir | `~/.chrome-cdp/` |

## Client Credentials (for future API use)

| Key | Value |
|-----|-------|
| Client ID | `STORED_IN_OPENCLAW_SECRETS` |
| Client Secret | `STORED_IN_OPENCLAW_SECRETS` |

## Common Operations

### Connect to Shopify Admin

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.connect_over_cdp("http://127.0.0.1:9222")
    context = browser.contexts[0]
    page = context.pages[0]  # or context.new_page()

    page.goto("https://admin.shopify.com/store/7qz8cj-uu/products", timeout=30000)
    time.sleep(6)
```

### Create a Product

```python
page.goto("https://admin.shopify.com/store/7qz8cj-uu/products/new", timeout=30000)
time.sleep(6)

page.locator('input[name="title"]').fill("Product Name")
time.sleep(1)

page.locator('input[name="price"]').fill("29.00")
time.sleep(1)

page.locator('button:has-text("Save")').first.click()
time.sleep(5)
```

### Delete a Product

```python
page.goto(f"https://admin.shopify.com/store/7qz8cj-uu/products/{product_id}", timeout=20000)
time.sleep(4)

page.locator('button:has-text("More actions")').first.click()
time.sleep(1)

page.locator('[role="menuitem"]:has-text("Delete")').first.click()
time.sleep(2)

# Confirm
page.locator('button:has-text("Delete product")').last.click()
time.sleep(3)
```

### List Products

```python
page.goto("https://admin.shopify.com/store/7qz8cj-uu/products", timeout=30000)
time.sleep(6)

products = page.locator('a[href*="/products/"]')
for i in range(products.count()):
    text = products.nth(i).inner_text().strip()
    href = products.nth(i).get_attribute("href") or ""
    pid = href.split("/products/")[-1].split("?")[0]
    if pid and pid.isdigit():
        print(f"  {pid}: {text}")
```

### Remove Store Password

```python
page.goto("https://admin.shopify.com/store/7qz8cj-uu/online_store/preferences", timeout=30000)
time.sleep(6)

# Uncheck password protection
checkbox = page.locator('input[name*="password"], label:has-text("password") input[type="checkbox"]')
if checkbox.count() > 0 and checkbox.first.is_checked():
    checkbox.first.uncheck()
    time.sleep(1)
    page.locator('button:has-text("Save")').first.click()
```

## Gotchas

1. **Chrome must be quit before launching with CDP** — if Chrome is already running without `--remote-debugging-port`, the flag is ignored
2. **Must use `--user-data-dir` that's NOT the default Chrome profile dir** — Chrome rejects CDP on its default data dir
3. **Session expires** — if Shopify session expires, user needs to login once in the CDP browser window
4. **Shopify admin is a SPA** — always `time.sleep()` after navigation. `wait_for_load_state("networkidle")` often times out
5. **Locator timing** — Shopify uses React/Polaris. Elements take 2-6 seconds to render. Always sleep after goto
6. **Google OAuth** — if using a fresh `--user-data-dir`, Google won't trust the browser. User must login manually the first time
7. **CDP port conflict** — if port 9222 is in use, Chrome won't start with CDP. Kill any existing processes: `lsof -i :9222 | awk 'NR>1{print $2}' | xargs kill`

## Current Products (as of 2026-03-21)

| ID | Product | Price |
|----|---------|-------|
| 8531546636367 | Intro Psychic Reading | $1 |
| 8528728293455 | Love & Relationships Reading | $29 |
| 8528732422223 | Career & Purpose Reading | $47 |
| 8528737304655 | Full Destiny Chart | $97 |
| 8528742580303 | Monthly Mentorship with Jade | $497 |
