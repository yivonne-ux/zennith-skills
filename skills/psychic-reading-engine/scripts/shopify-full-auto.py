#!/usr/bin/env python3
"""
Full Shopify automation — Google OAuth login + app creation + products + domain
"""

import json, sys, time, re, os
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
    print("🔮 Jade Oracle — Full Auto Setup (Google OAuth)", flush=True)

    pw = sys.argv[1] if len(sys.argv) > 1 else ""
    if not pw:
        print("Usage: python3 shopify-full-auto.py <google_password>")
        sys.exit(1)

    with sync_playwright() as p:
        log("Launching browser...")
        browser = p.chromium.launch(headless=False, slow_mo=500)
        context = browser.new_context(viewport={"width": 1400, "height": 900})
        page = context.new_page()

        # === LOGIN VIA GOOGLE ===
        log("Navigating to Shopify login...")
        page.goto("https://accounts.shopify.com/lookup?rid=shopify-web", timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=15000)
        time.sleep(4)
        ss(page, "00-login")

        # Click Google button
        log("Clicking Google sign-in button...")
        try:
            google_btn = page.locator('[data-provider="google"], button:has-text("Google"), [aria-label*="Google"]')
            if google_btn.count() > 0:
                google_btn.first.click()
                time.sleep(5)
                log(f"Google OAuth page: {page.url}")
                ss(page, "01-google")
            else:
                # Try the G icon button
                buttons = page.locator('button')
                for i in range(buttons.count()):
                    text = buttons.nth(i).inner_text().strip()
                    if not text or len(text) < 3:
                        # Could be the icon-only Google button
                        pass
                # Fallback: click the third social button (Apple, Facebook, Google)
                social = page.locator('.login-button--social, [class*="social"], [class*="provider"]')
                if social.count() >= 3:
                    social.nth(2).click()  # Google is usually 3rd
                    time.sleep(5)
                else:
                    # Try img alt or specific selectors
                    page.locator('img[alt*="Google" i]').first.click()
                    time.sleep(5)
                log(f"After social click: {page.url}")
                ss(page, "01-google-alt")
        except Exception as e:
            log(f"Google button error: {e}")
            ss(page, "01-google-error")

        # Handle Google OAuth
        current = page.url
        log(f"Current URL: {current}")

        if "accounts.google" in current:
            log("On Google sign-in page...")

            # Enter email
            try:
                email_input = page.locator('input[type="email"]')
                if email_input.count() > 0:
                    email_input.first.fill(EMAIL)
                    time.sleep(1)
                    # Click Next
                    page.locator('#identifierNext, button:has-text("Next")').first.click()
                    time.sleep(4)
                    log("Email entered")
                    ss(page, "02-google-email")
            except Exception as e:
                log(f"Google email error: {e}")
                ss(page, "02-google-email-error")

            # Enter password
            try:
                pw_input = page.locator('input[type="password"]')
                if pw_input.count() > 0:
                    pw_input.first.fill(pw)
                    time.sleep(1)
                    page.locator('#passwordNext, button:has-text("Next")').first.click()
                    time.sleep(8)
                    log("Password entered, waiting for redirect...")
                    ss(page, "03-google-pw")
                else:
                    log("No password field found")
                    ss(page, "03-no-pw-field")
            except Exception as e:
                log(f"Google password error: {e}")
                ss(page, "03-google-pw-error")

            # Wait for redirect back to Shopify
            for i in range(30):
                time.sleep(2)
                current = page.url
                if "admin.shopify.com" in current or "shopify.com/admin" in current:
                    log(f"Redirected to Shopify! {current}")
                    break
                if "myaccount.google" in current or "consent" in current:
                    # Consent screen — click Allow/Continue
                    try:
                        page.locator('button:has-text("Allow"), button:has-text("Continue")').first.click()
                        time.sleep(3)
                    except:
                        pass
                if i % 5 == 0 and i > 0:
                    log(f"  Waiting for redirect... ({i*2}s) - {current[:60]}")
                    ss(page, f"04-wait-{i}")
        else:
            log(f"Not on Google page: {current}")
            ss(page, "02-not-google")

        # Navigate to admin
        time.sleep(3)
        log(f"Navigating to store admin...")
        page.goto(STORE_URL, timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=20000)
        time.sleep(5)
        ss(page, "05-admin")
        log(f"Admin URL: {page.url}")

        if "login" in page.url.lower() or "accounts.shopify" in page.url.lower():
            log("STILL NOT LOGGED IN — login failed")
            ss(page, "05-login-failed")
            RESULTS["errors"].append("Login failed")
            Path("/tmp/shopify-setup-results.json").write_text(json.dumps(RESULTS, indent=2))
            browser.close()
            return

        log("LOGGED IN SUCCESSFULLY!")

        # === SET STORE NAME ===
        log("Setting store name...")
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
                log("Store name set!")
            ss(page, "06-store-name")
        except Exception as e:
            log(f"Store name error: {e}")

        # === CREATE CUSTOM APP ===
        log("Going to app development...")
        page.goto(f"{STORE_URL}/settings/apps/development", timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=20000)
        time.sleep(5)
        ss(page, "07-apps-dev")

        # Allow custom app development
        try:
            allow = page.locator('button:has-text("Allow custom app development")')
            if allow.count() > 0 and allow.first.is_visible():
                log("Enabling custom app development...")
                allow.first.click()
                time.sleep(3)
                # Confirm modal
                modal_allow = page.locator('button:has-text("Allow custom app development")')
                if modal_allow.count() > 0:
                    modal_allow.last.click()
                    time.sleep(3)
                log("Custom app dev enabled")
                ss(page, "07b-enabled")
        except Exception as e:
            log(f"Allow dev: {e}")

        # Create app
        log("Creating app...")
        try:
            create = page.locator('button:has-text("Create an app"), button:has-text("Create app")')
            if create.count() > 0 and create.first.is_visible():
                create.first.click()
                time.sleep(3)
                ss(page, "08-create-dialog")

                name_input = page.locator('input[type="text"]').first
                name_input.fill("Jade Oracle Engine")
                time.sleep(1)

                page.locator('button:has-text("Create app")').last.click()
                time.sleep(5)
                log("App created!")
                ss(page, "09-app-created")
            else:
                # Maybe app already exists
                app_link = page.locator('a:has-text("Jade Oracle Engine")')
                if app_link.count() > 0:
                    app_link.first.click()
                    time.sleep(3)
                    log("Opened existing app")
                else:
                    log("No create button and no existing app")
                    ss(page, "08-no-create")
        except Exception as e:
            log(f"Create error: {e}")
            ss(page, "08-create-error")

        ss(page, "10-current")

        # Configure scopes
        log("Configuring API scopes...")
        try:
            config = page.locator('a:has-text("Configure Admin API scopes"), button:has-text("Configure Admin API")')
            if config.count() > 0:
                config.first.click()
                time.sleep(5)
                ss(page, "11-scopes")

                scopes = ['write_products', 'read_products', 'write_orders', 'read_orders',
                          'write_customers', 'read_customers', 'read_checkouts',
                          'write_draft_orders', 'read_draft_orders']

                for scope in scopes:
                    try:
                        cb = page.locator(f'input[value="{scope}"]')
                        if cb.count() > 0 and not cb.first.is_checked():
                            cb.first.check(force=True)
                            time.sleep(0.3)
                            continue
                    except:
                        pass
                    try:
                        label = page.locator(f'label:has-text("{scope}")')
                        if label.count() > 0:
                            label.first.click()
                            time.sleep(0.3)
                    except:
                        pass

                log("Scopes set")
                page.locator('button:has-text("Save")').first.click()
                time.sleep(5)
                log("Scopes saved")
                ss(page, "12-scopes-saved")
            else:
                log("No configure scopes link")
                ss(page, "11-no-config")
        except Exception as e:
            log(f"Scopes error: {e}")
            ss(page, "11-scopes-error")

        # Install app
        log("Installing app...")
        try:
            install = page.locator('button:has-text("Install app")')
            if install.count() > 0 and install.first.is_visible():
                install.first.click()
                time.sleep(3)
                confirm = page.locator('button:has-text("Install")')
                if confirm.count() > 0:
                    confirm.last.click()
                    time.sleep(5)
                log("App installed!")
                ss(page, "13-installed")
            else:
                log("No install button — may already be installed")
        except Exception as e:
            log(f"Install error: {e}")
            ss(page, "13-install-error")

        # Reveal token
        log("Getting Admin API token...")
        token = None
        try:
            reveal = page.locator('button:has-text("Reveal token once"), button:has-text("Reveal token")')
            if reveal.count() > 0:
                reveal.first.click()
                time.sleep(3)
                log("Token revealed!")
            ss(page, "14-token")

            # Extract
            page_text = page.inner_text("body")
            match = re.search(r'(shpat_[a-f0-9]{32,})', page_text)
            if match:
                token = match.group(1)
                log(f"ADMIN TOKEN: {token[:20]}...")
            else:
                inputs = page.locator('input')
                for i in range(inputs.count()):
                    try:
                        val = inputs.nth(i).input_value()
                        if val and val.startswith("shpat_"):
                            token = val
                            log(f"TOKEN from input: {token[:20]}...")
                            break
                    except:
                        pass

            if not token:
                log("Token not found — check screenshot 14")
                ss(page, "14b-no-token")
        except Exception as e:
            log(f"Token error: {e}")

        RESULTS["token"] = token

        # Save token
        if token:
            env_path = SECRETS_DIR / "shopify-jade.env"
            content = env_path.read_text()
            content = re.sub(r'SHOPIFY_ADMIN_TOKEN=.*', f'SHOPIFY_ADMIN_TOKEN={token}', content)
            env_path.write_text(content)
            log(f"Token saved to {env_path}")

        # === CONNECT DOMAIN ===
        log("Connecting domain...")
        page.goto(f"{STORE_URL}/settings/domains", timeout=30000)
        page.wait_for_load_state("domcontentloaded", timeout=20000)
        time.sleep(5)
        ss(page, "15-domains")

        try:
            connect = page.locator('button:has-text("Connect existing domain")')
            if connect.count() > 0 and connect.first.is_visible():
                connect.first.click()
                time.sleep(3)

                page.locator('input[type="text"]').first.fill(DOMAIN)
                time.sleep(1)

                page.locator('button:has-text("Next"), button:has-text("Connect"), button:has-text("Add")').first.click()
                time.sleep(5)
                ss(page, "16-domain-connect")

                verify = page.locator('button:has-text("Verify")')
                if verify.count() > 0:
                    verify.first.click()
                    time.sleep(5)
                    log("Domain verification requested")

                ss(page, "17-domain-result")
            else:
                log("No connect domain button")
                if DOMAIN in page.inner_text("body"):
                    log(f"{DOMAIN} already on page!")
                ss(page, "15b-domain-state")
        except Exception as e:
            log(f"Domain error: {e}")
            ss(page, "15-domain-error")

        # === PRODUCTS VIA API ===
        if token:
            import urllib.request
            log("Creating products via API...")

            with open(PRODUCTS_FILE) as f:
                products_data = json.load(f)

            headers = {"X-Shopify-Access-Token": token, "Content-Type": "application/json"}

            for product in products_data.get("products", []):
                title = product["title"]
                log(f"  Creating: {title}...")
                payload = json.dumps({"product": product}).encode()
                req = urllib.request.Request(
                    f"https://{STORE_DOMAIN}/admin/api/2025-01/products.json",
                    data=payload, headers=headers, method="POST"
                )
                try:
                    with urllib.request.urlopen(req) as resp:
                        result = json.loads(resp.read())
                        pid = result.get("product", {}).get("id", "?")
                        log(f"  Created: {title} (ID: {pid})")
                        RESULTS["products"].append({"title": title, "id": pid})
                except urllib.error.HTTPError as e:
                    body = e.read().decode()
                    log(f"  Failed: {title} — {e.code} {body[:200]}")
                except Exception as e:
                    log(f"  Failed: {title} — {e}")
                time.sleep(1)

            # Register webhook
            log("Registering webhook...")
            wp = json.dumps({"webhook": {"topic": "orders/paid", "address": f"https://{DOMAIN}/webhook/order", "format": "json"}}).encode()
            req = urllib.request.Request(f"https://{STORE_DOMAIN}/admin/api/2025-01/webhooks.json", data=wp, headers=headers, method="POST")
            try:
                with urllib.request.urlopen(req) as resp:
                    log(f"  Webhook registered: {json.loads(resp.read()).get('webhook',{}).get('id','?')}")
            except Exception as e:
                log(f"  Webhook error: {e}")

        Path("/tmp/shopify-setup-results.json").write_text(json.dumps(RESULTS, indent=2))
        print("\n🎉 Setup complete! Check /tmp/shopify-*.png", flush=True)
        time.sleep(3)
        browser.close()

if __name__ == "__main__":
    main()
