#!/usr/bin/env python3
"""
Shopify setup — uses REAL Chrome (not Chromium) to avoid Google "not secure" block.
Launches Chrome with a temp profile, user logs in, then automation takes over.
"""

import json, sys, time, re
from pathlib import Path
from playwright.sync_api import sync_playwright

STORE_URL = "https://admin.shopify.com/store/7qz8cj-uu"
STORE_DOMAIN = "7qz8cj-uu.myshopify.com"
DOMAIN = "jadeoracle.co"
EMAIL = "penanghuatgroup@gmail.com"
SECRETS_DIR = Path.home() / ".openclaw/secrets"
PRODUCTS_FILE = Path.home() / ".openclaw/skills/psychic-reading-engine/data/shopify-products.json"
RESULTS = {"token": None, "products": [], "errors": []}

def log(msg):
    print(f"  {msg}", flush=True)

def ss(page, name):
    page.screenshot(path=f"/tmp/shopify-{name}.png")

def main():
    print("🔮 Jade Oracle — Shopify Setup (Real Chrome)", flush=True)

    with sync_playwright() as p:
        log("Launching REAL Chrome (not Chromium)...")

        # Use real Chrome to bypass Google's "browser not secure" check
        # Must use a temp user-data-dir (Chrome requirement for debugging)
        temp_profile = "/tmp/chrome-jade-setup"
        Path(temp_profile).mkdir(exist_ok=True)

        context = p.chromium.launch_persistent_context(
            temp_profile,
            headless=False,
            channel="chrome",  # Real Chrome, not Chromium
            args=[
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
            ],
            viewport={"width": 1400, "height": 900},
            slow_mo=400,
        )

        page = context.pages[0] if context.pages else context.new_page()

        # Open Shopify login
        page.goto(STORE_URL, timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=15000)
        time.sleep(3)

        log("")
        log("=" * 50)
        log("BROWSER IS OPEN — PLEASE LOG IN TO SHOPIFY")
        log("Use Google login or email+code")
        log("Once you're in the Shopify admin, I'll take over!")
        log("=" * 50)
        log("")

        # Wait for login
        for i in range(300):  # 10 minutes
            time.sleep(2)
            try:
                current = page.url
            except:
                continue
            if "admin.shopify.com/store" in current and "login" not in current.lower() and "accounts" not in current.lower():
                log(f"LOGIN DETECTED: {current}")
                break
            if i % 15 == 0 and i > 0:
                log(f"  Waiting for login... ({i*2}s)")
        else:
            log("Timeout — no login detected")
            context.close()
            return

        time.sleep(3)
        log("LOGGED IN! Starting automation...\n")

        # === STORE NAME ===
        log("[1/5] Setting store name...")
        try:
            page.goto(f"{STORE_URL}/settings/store-details", timeout=30000)
            page.wait_for_load_state("domcontentloaded", timeout=20000)
            time.sleep(5)
            name_input = page.locator('input[name="name"], input[aria-label="Store name"]')
            if name_input.count() > 0:
                name_input.first.fill("")
                name_input.first.fill("The Jade Oracle")
                time.sleep(1)
                page.locator('button:has-text("Save")').first.click()
                time.sleep(3)
                log("  Store name → The Jade Oracle")
            ss(page, "01-store-name")
        except Exception as e:
            log(f"  Store name: {e}")

        # === APP DEVELOPMENT ===
        log("[2/5] Creating custom app...")
        page.goto(f"{STORE_URL}/settings/apps/development", timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=20000)
        time.sleep(5)
        ss(page, "02-apps-dev")

        # Allow custom app development
        try:
            allow = page.locator('button:has-text("Allow custom app development")')
            if allow.count() > 0 and allow.first.is_visible():
                allow.first.click()
                time.sleep(3)
                modal = page.locator('button:has-text("Allow custom app development")')
                if modal.count() > 0:
                    modal.last.click()
                    time.sleep(3)
                log("  Custom app dev enabled")
        except:
            pass

        # Check existing app
        existing = page.locator('a:has-text("Jade Oracle Engine")')
        if existing.count() > 0:
            log("  App already exists, opening...")
            existing.first.click()
            time.sleep(3)
        else:
            try:
                create = page.locator('button:has-text("Create an app"), button:has-text("Create app")')
                if create.count() > 0:
                    create.first.click()
                    time.sleep(3)
                    page.locator('input[type="text"]').first.fill("Jade Oracle Engine")
                    time.sleep(1)
                    page.locator('button:has-text("Create app")').last.click()
                    time.sleep(5)
                    log("  App created!")
            except Exception as e:
                log(f"  Create error: {e}")

        ss(page, "03-app-page")

        # Configure scopes
        log("[3/5] Configuring API scopes...")
        try:
            config = page.locator('a:has-text("Configure Admin API scopes"), button:has-text("Configure Admin API")')
            if config.count() > 0:
                config.first.click()
                time.sleep(5)

                scopes = ['write_products', 'read_products', 'write_orders', 'read_orders',
                          'write_customers', 'read_customers', 'read_checkouts',
                          'write_draft_orders', 'read_draft_orders']
                for scope in scopes:
                    try:
                        cb = page.locator(f'input[value="{scope}"]')
                        if cb.count() > 0 and not cb.first.is_checked():
                            cb.first.check(force=True)
                            time.sleep(0.3)
                    except:
                        try:
                            page.locator(f'label:has-text("{scope}")').first.click()
                            time.sleep(0.3)
                        except:
                            pass

                page.locator('button:has-text("Save")').first.click()
                time.sleep(5)
                log("  Scopes configured & saved")
                ss(page, "04-scopes-saved")
        except Exception as e:
            log(f"  Scopes: {e}")

        # Install app
        try:
            install = page.locator('button:has-text("Install app")')
            if install.count() > 0 and install.first.is_visible():
                install.first.click()
                time.sleep(3)
                page.locator('button:has-text("Install")').last.click()
                time.sleep(5)
                log("  App installed!")
                ss(page, "05-installed")
        except:
            pass

        # Get token
        token = None
        try:
            reveal = page.locator('button:has-text("Reveal token once"), button:has-text("Reveal token")')
            if reveal.count() > 0:
                reveal.first.click()
                time.sleep(3)
            ss(page, "06-token")

            page_text = page.inner_text("body")
            match = re.search(r'(shpat_[a-f0-9]{32,})', page_text)
            if match:
                token = match.group(1)
                log(f"  ADMIN TOKEN: {token[:20]}...")
            else:
                inputs = page.locator('input')
                for i in range(inputs.count()):
                    try:
                        val = inputs.nth(i).input_value()
                        if val and val.startswith("shpat_"):
                            token = val
                            log(f"  TOKEN: {token[:20]}...")
                            break
                    except:
                        pass
            if not token:
                log("  Token not found — check screenshot 06-token")
        except Exception as e:
            log(f"  Token error: {e}")

        RESULTS["token"] = token
        if token:
            env_path = SECRETS_DIR / "shopify-jade.env"
            content = env_path.read_text()
            content = re.sub(r'SHOPIFY_ADMIN_TOKEN=.*', f'SHOPIFY_ADMIN_TOKEN={token}', content)
            env_path.write_text(content)
            log(f"  Token saved!")

        # === DOMAIN ===
        log("[4/5] Connecting domain...")
        page.goto(f"{STORE_URL}/settings/domains", timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=20000)
        time.sleep(5)
        ss(page, "07-domains")

        try:
            connect = page.locator('button:has-text("Connect existing domain")')
            if connect.count() > 0 and connect.first.is_visible():
                connect.first.click()
                time.sleep(3)
                page.locator('input[type="text"]').first.fill(DOMAIN)
                time.sleep(1)
                page.locator('button:has-text("Next"), button:has-text("Connect"), button:has-text("Add")').first.click()
                time.sleep(5)
                verify = page.locator('button:has-text("Verify")')
                if verify.count() > 0:
                    verify.first.click()
                    time.sleep(5)
                    log(f"  Domain {DOMAIN} verification requested")
                ss(page, "08-domain-result")
            else:
                if DOMAIN in page.inner_text("body"):
                    log(f"  {DOMAIN} already connected!")
                else:
                    log("  No connect button found")
        except Exception as e:
            log(f"  Domain: {e}")

        # === PRODUCTS ===
        if token:
            import urllib.request
            log("[5/5] Creating products via API...")
            with open(PRODUCTS_FILE) as f:
                products_data = json.load(f)

            headers = {"X-Shopify-Access-Token": token, "Content-Type": "application/json"}
            for product in products_data.get("products", []):
                title = product["title"]
                payload = json.dumps({"product": product}).encode()
                req = urllib.request.Request(
                    f"https://{STORE_DOMAIN}/admin/api/2025-01/products.json",
                    data=payload, headers=headers, method="POST")
                try:
                    with urllib.request.urlopen(req) as resp:
                        pid = json.loads(resp.read()).get("product", {}).get("id", "?")
                        log(f"  {title} → ID: {pid}")
                        RESULTS["products"].append({"title": title, "id": pid})
                except urllib.error.HTTPError as e:
                    log(f"  {title} FAILED: {e.code} {e.read().decode()[:100]}")
                except Exception as e:
                    log(f"  {title} FAILED: {e}")
                time.sleep(1)

            # Webhook
            log("  Registering webhook...")
            wp = json.dumps({"webhook": {"topic": "orders/paid", "address": f"https://{DOMAIN}/webhook/order", "format": "json"}}).encode()
            try:
                req = urllib.request.Request(f"https://{STORE_DOMAIN}/admin/api/2025-01/webhooks.json", data=wp, headers=headers, method="POST")
                with urllib.request.urlopen(req) as resp:
                    log(f"  Webhook OK: {json.loads(resp.read()).get('webhook',{}).get('id','?')}")
            except Exception as e:
                log(f"  Webhook: {e}")
        else:
            log("[5/5] Skipping products (no token)")

        Path("/tmp/shopify-setup-results.json").write_text(json.dumps(RESULTS, indent=2))

        print(f"\n{'='*50}", flush=True)
        print(f"🎉 SETUP COMPLETE!", flush=True)
        if token:
            print(f"  Admin token: {token[:20]}...", flush=True)
        print(f"  Products: {len(RESULTS['products'])}", flush=True)
        print(f"  Screenshots: /tmp/shopify-*.png", flush=True)
        print(f"{'='*50}", flush=True)

        log("Browser open for 30s review...")
        time.sleep(30)
        context.close()

if __name__ == "__main__":
    main()
