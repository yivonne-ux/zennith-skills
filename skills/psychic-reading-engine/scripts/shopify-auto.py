#!/usr/bin/env python3
"""
Shopify Auto-Setup via Playwright (non-interactive)
Launches Chrome with existing user profile to reuse Shopify login.
Creates custom app, captures Admin API token, creates products.

Usage: python3 shopify-auto.py
"""

import json
import sys
import time
import re
import os
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright, TimeoutError as PwTimeout
except ImportError:
    print("pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

STORE_URL = "https://admin.shopify.com/store/7qz8cj-uu"
STORE_DOMAIN = "7qz8cj-uu.myshopify.com"
DOMAIN = "jadeoracle.co"
SECRETS_DIR = Path.home() / ".openclaw/secrets"
PRODUCTS_FILE = Path.home() / ".openclaw/skills/psychic-reading-engine/data/shopify-products.json"
RESULTS_FILE = Path("/tmp/shopify-setup-results.json")

results = {"steps": [], "token": None, "products": [], "errors": []}

def log(msg):
    print(f"  {msg}")
    results["steps"].append(msg)

def screenshot(page, name):
    path = f"/tmp/shopify-{name}.png"
    page.screenshot(path=path)
    log(f"Screenshot: {path}")

def step_create_custom_app(page):
    """Create a custom app and get Admin API token"""
    log("=== STEP 1: Create Custom App ===")

    # Go to Apps settings
    page.goto(f"{STORE_URL}/settings/apps/development")
    page.wait_for_load_state("domcontentloaded", timeout=30000)
    time.sleep(3)

    # Check if we need to allow custom app development first
    try:
        allow_btn = page.locator("text=Allow custom app development")
        if allow_btn.count() > 0:
            log("Enabling custom app development...")
            allow_btn.first.click()
            time.sleep(2)
            # Confirm dialog
            confirm = page.locator("button:has-text('Allow custom app development')")
            if confirm.count() > 0:
                confirm.last.click()
                time.sleep(3)
            log("Custom app development enabled")
    except Exception as e:
        log(f"Allow custom dev check: {e}")

    screenshot(page, "01-apps-page")

    # Click "Create an app" or "Create app"
    try:
        create_btn = page.locator("button:has-text('Create'), a:has-text('Create an app'), button:has-text('Create an app')")
        if create_btn.count() > 0:
            create_btn.first.click()
            time.sleep(2)
        else:
            log("No 'Create app' button found")
            screenshot(page, "01b-no-create-btn")
            return None
    except Exception as e:
        log(f"Create app click error: {e}")
        screenshot(page, "01b-create-error")
        return None

    screenshot(page, "02-create-app-dialog")

    # Fill app name
    time.sleep(1)
    try:
        # Try various input selectors
        name_input = page.locator('input[name="name"], input[placeholder*="name" i], input[type="text"]').first
        name_input.fill("Jade Oracle Engine")
        time.sleep(1)
        log("App name filled: Jade Oracle Engine")
    except Exception as e:
        log(f"Name input error: {e}")
        screenshot(page, "02b-name-error")

    # Submit create
    try:
        submit = page.locator('button:has-text("Create app"), button[type="submit"]').first
        submit.click()
        time.sleep(3)
        log("App creation submitted")
    except Exception as e:
        log(f"Submit error: {e}")

    screenshot(page, "03-app-created")

    # Configure Admin API scopes
    log("Configuring API scopes...")
    try:
        config_link = page.locator('text=Configure Admin API scopes, a:has-text("Configure"), button:has-text("Configure Admin API")')
        if config_link.count() > 0:
            config_link.first.click()
            time.sleep(3)
        else:
            # Try navigating directly
            # Look for the app URL pattern
            current = page.url
            log(f"Current URL after app create: {current}")
            screenshot(page, "03b-looking-for-configure")
    except Exception as e:
        log(f"Configure link error: {e}")

    screenshot(page, "04-scopes-page")

    # Select API scopes
    scopes = [
        'write_products', 'read_products',
        'write_orders', 'read_orders',
        'write_customers', 'read_customers',
        'read_checkouts',
        'write_draft_orders', 'read_draft_orders',
    ]

    for scope in scopes:
        try:
            cb = page.locator(f'input[value="{scope}"]')
            if cb.count() > 0 and not cb.first.is_checked():
                cb.first.check()
                time.sleep(0.2)
        except:
            try:
                label = page.locator(f'label:has-text("{scope}")')
                if label.count() > 0:
                    label.first.click()
                    time.sleep(0.2)
            except:
                pass

    log("API scopes selected")

    # Save scopes
    try:
        save_btn = page.locator('button:has-text("Save")')
        if save_btn.count() > 0:
            save_btn.first.click()
            time.sleep(3)
            log("Scopes saved")
    except:
        pass

    screenshot(page, "05-scopes-saved")

    # Install the app
    log("Installing app...")
    try:
        install_btn = page.locator('button:has-text("Install app"), button:has-text("Install")')
        if install_btn.count() > 0:
            install_btn.first.click()
            time.sleep(2)
            # Confirm dialog
            confirm_install = page.locator('button:has-text("Install")')
            if confirm_install.count() > 0:
                confirm_install.last.click()
                time.sleep(3)
            log("App installed")
    except Exception as e:
        log(f"Install error: {e}")

    screenshot(page, "06-app-installed")

    # Reveal and capture Admin API token
    log("Looking for Admin API token...")
    token = None
    try:
        reveal = page.locator('button:has-text("Reveal token once"), button:has-text("Reveal")')
        if reveal.count() > 0:
            reveal.first.click()
            time.sleep(2)
            log("Token revealed")
    except:
        pass

    screenshot(page, "07-token-page")

    # Try to find the token
    try:
        page_text = page.inner_text("body")
        match = re.search(r'(shpat_[a-f0-9]{32,})', page_text)
        if match:
            token = match.group(1)
            log(f"TOKEN CAPTURED: {token[:15]}...")
        else:
            # Try input fields
            inputs = page.locator('input[type="text"], input[readonly]')
            for i in range(inputs.count()):
                val = inputs.nth(i).get_attribute("value") or ""
                if val.startswith("shpat_"):
                    token = val
                    log(f"TOKEN FROM INPUT: {token[:15]}...")
                    break
    except Exception as e:
        log(f"Token extraction error: {e}")

    if not token:
        log("TOKEN NOT FOUND — check screenshots")
        screenshot(page, "07b-no-token")

    return token


def step_create_products_api(token):
    """Create products via Shopify Admin REST API"""
    import urllib.request

    log("=== STEP 2: Create Products via API ===")

    with open(PRODUCTS_FILE) as f:
        products_data = json.load(f)

    headers = {
        "X-Shopify-Access-Token": token,
        "Content-Type": "application/json",
    }

    for product in products_data.get("products", []):
        title = product["title"]
        log(f"Creating: {title}...")

        payload = json.dumps({"product": product}).encode()
        req = urllib.request.Request(
            f"https://{STORE_DOMAIN}/admin/api/2025-01/products.json",
            data=payload,
            headers=headers,
            method="POST"
        )

        try:
            with urllib.request.urlopen(req) as resp:
                result = json.loads(resp.read())
                pid = result.get("product", {}).get("id", "?")
                log(f"Created: {title} (ID: {pid})")
                results["products"].append({"title": title, "id": pid})
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            err = f"Failed: {title} — {e.code} {body[:200]}"
            log(err)
            results["errors"].append(err)
        except Exception as e:
            err = f"Failed: {title} — {e}"
            log(err)
            results["errors"].append(err)

        time.sleep(1)


def step_connect_domain(page):
    """Connect jadeoracle.co domain"""
    log("=== STEP 3: Connect Domain ===")

    page.goto(f"{STORE_URL}/settings/domains")
    page.wait_for_load_state("domcontentloaded", timeout=30000)
    time.sleep(3)

    screenshot(page, "08-domains-page")

    try:
        connect = page.locator("text=Connect existing domain, button:has-text('Connect existing domain')")
        if connect.count() > 0:
            connect.first.click()
            time.sleep(2)
        else:
            log("No 'Connect existing domain' button — checking if already connected")
            page_text = page.inner_text("body")
            if DOMAIN in page_text:
                log(f"Domain {DOMAIN} may already be connected!")
                screenshot(page, "08b-domain-already")
                return
    except Exception as e:
        log(f"Connect domain click: {e}")

    # Enter domain
    try:
        domain_input = page.locator('input[type="text"]').first
        domain_input.fill(DOMAIN)
        time.sleep(1)
    except:
        pass

    # Click Next/Connect
    try:
        next_btn = page.locator('button:has-text("Next"), button:has-text("Connect"), button:has-text("Add domain")')
        if next_btn.count() > 0:
            next_btn.first.click()
            time.sleep(3)
    except:
        pass

    screenshot(page, "09-domain-connecting")

    # Verify
    try:
        verify = page.locator('button:has-text("Verify"), button:has-text("Verify connection")')
        if verify.count() > 0:
            verify.click()
            time.sleep(5)
            log(f"Domain {DOMAIN} verification requested")
    except:
        pass

    screenshot(page, "10-domain-result")
    log("Domain setup attempted — check screenshots")


def step_setup_store_name(page):
    """Set store name to The Jade Oracle"""
    log("=== STEP 0: Store Name ===")

    page.goto(f"{STORE_URL}/settings/store-details")
    page.wait_for_load_state("domcontentloaded", timeout=30000)
    time.sleep(3)

    try:
        name_input = page.locator('input[name="name"], input[aria-label="Store name"]').first
        name_input.fill("")
        name_input.fill("The Jade Oracle")
        time.sleep(1)

        save = page.locator('button:has-text("Save")').first
        save.click()
        time.sleep(3)
        log("Store name set to 'The Jade Oracle'")
    except Exception as e:
        log(f"Store name error: {e}")

    screenshot(page, "00-store-name")


def step_register_webhook_api(token):
    """Register order/created webhook via API"""
    import urllib.request

    log("=== STEP 4: Register Webhook ===")

    webhook_url = f"https://{DOMAIN}/webhook/order"
    payload = json.dumps({
        "webhook": {
            "topic": "orders/paid",
            "address": webhook_url,
            "format": "json"
        }
    }).encode()

    headers = {
        "X-Shopify-Access-Token": token,
        "Content-Type": "application/json",
    }

    req = urllib.request.Request(
        f"https://{STORE_DOMAIN}/admin/api/2025-01/webhooks.json",
        data=payload,
        headers=headers,
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            wid = result.get("webhook", {}).get("id", "?")
            log(f"Webhook registered: {webhook_url} (ID: {wid})")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        log(f"Webhook registration failed: {e.code} {body[:300]}")
        results["errors"].append(f"Webhook: {e.code}")
    except Exception as e:
        log(f"Webhook error: {e}")


def main():
    print("🔮 Jade Oracle — Shopify Auto Setup")
    print(f"   Store: {STORE_URL}")
    print(f"   Domain: {DOMAIN}")
    print()

    with sync_playwright() as p:
        log("Launching Chrome with existing profile...")

        # Use copied profile (Profile 27 = penanghuatgroup@gmail.com = Shopify account)
        # Chrome requires non-default data dir for remote debugging, so we copy the profile
        user_data = "/tmp/chrome-shopify-profile"

        context = p.chromium.launch_persistent_context(
            user_data,
            headless=False,
            channel="chrome",
            args=["--disable-blink-features=AutomationControlled", "--no-sandbox"],
            viewport={"width": 1400, "height": 900},
            slow_mo=500,  # Slow down for reliability
        )

        page = context.pages[0] if context.pages else context.new_page()

        # Navigate to Shopify admin
        log("Navigating to Shopify admin...")
        page.goto(STORE_URL, timeout=60000)
        page.wait_for_load_state("domcontentloaded", timeout=30000)
        time.sleep(5)

        # Check login state — auto-fill email and wait for user to complete login
        if "login" in page.url.lower() or "accounts.shopify" in page.url.lower():
            log("Login required — auto-filling email...")
            try:
                email_input = page.locator('input[name="account[email]"], input[type="email"], input[autocomplete="email"]').first
                email_input.fill("penanghuatgroup@gmail.com")
                time.sleep(1)
                page.locator('button:has-text("Continue with email")').first.click()
                time.sleep(3)
            except Exception as e:
                log(f"Auto-fill email error: {e}")

            log("WAITING for you to complete login in the browser window...")
            log("(Enter password/OTP in the Chrome window that just opened)")
            # Poll until we're on the admin page
            for i in range(120):  # Wait up to 2 minutes
                time.sleep(2)
                current = page.url
                if "admin.shopify.com/store" in current and "login" not in current.lower():
                    log(f"Login successful! URL: {current}")
                    break
                if i % 10 == 0 and i > 0:
                    log(f"   Still waiting for login... ({i*2}s)")
            else:
                log("Login timeout after 4 minutes")
                screenshot(page, "login-timeout")
                results["errors"].append("Login timeout")
                RESULTS_FILE.write_text(json.dumps(results, indent=2))
                context.close()
                return

        log(f"Logged in! URL: {page.url}")
        screenshot(page, "00-logged-in")

        # Step 0: Store name
        step_setup_store_name(page)

        # Step 1: Create custom app and get token
        token = step_create_custom_app(page)
        results["token"] = token

        if token:
            # Save token
            env_path = SECRETS_DIR / "shopify-jade.env"
            content = env_path.read_text()
            content = content.replace('SHOPIFY_ADMIN_TOKEN=', f'SHOPIFY_ADMIN_TOKEN={token}')
            env_path.write_text(content)
            log(f"Token saved to {env_path}")

            # Step 2: Create products via API
            step_create_products_api(token)

            # Step 4: Register webhook
            step_register_webhook_api(token)
        else:
            log("No token — skipping API steps")

        # Step 3: Connect domain (via UI)
        step_connect_domain(page)

        # Save results
        RESULTS_FILE.write_text(json.dumps(results, indent=2))
        log(f"\nResults saved to {RESULTS_FILE}")

        print("\n🎉 Setup complete! Check /tmp/shopify-*.png for screenshots")

        # Give user time to review
        time.sleep(5)
        context.close()


if __name__ == "__main__":
    main()
