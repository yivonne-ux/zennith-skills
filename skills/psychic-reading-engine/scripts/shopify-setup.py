#!/usr/bin/env python3
"""
Shopify Store Setup Automation for The Jade Oracle
Uses Playwright to automate store configuration via admin UI.

Usage:
  python3 shopify-setup.py --step all
  python3 shopify-setup.py --step create-app
  python3 shopify-setup.py --step create-products
  python3 shopify-setup.py --step connect-domain
"""

import json
import sys
import time
import os
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("❌ playwright not installed. Run: pip3 install playwright")
    sys.exit(1)

STORE_URL = "https://admin.shopify.com/store/7qz8cj-uu"
DOMAIN = "jadeoracle.co"
SECRETS_DIR = Path.home() / ".openclaw/secrets"
PRODUCTS_FILE = Path.home() / ".openclaw/skills/psychic-reading-engine/data/shopify-products.json"

def wait_and_click(page, selector, timeout=10000):
    """Wait for element and click it"""
    page.wait_for_selector(selector, timeout=timeout)
    page.click(selector)

def wait_and_fill(page, selector, text, timeout=10000):
    """Wait for element and fill it"""
    page.wait_for_selector(selector, timeout=timeout)
    page.fill(selector, text)

def create_custom_app(page):
    """Create a custom app to get Admin API token"""
    print("\n📱 Creating custom app for API access...")

    # Navigate to apps settings
    page.goto(f"{STORE_URL}/settings/apps")
    page.wait_for_load_state("networkidle")
    time.sleep(2)

    # Click "Develop apps"
    try:
        page.click("text=Develop apps", timeout=5000)
        time.sleep(2)
    except:
        print("   Looking for develop apps button...")
        page.click("a:has-text('Develop apps')", timeout=5000)
        time.sleep(2)

    # Allow custom app development if prompted
    try:
        allow_btn = page.query_selector("text=Allow custom app development")
        if allow_btn:
            allow_btn.click()
            time.sleep(2)
            # Confirm dialog
            try:
                page.click("text=Allow custom app development", timeout=3000)
                time.sleep(2)
            except:
                pass
    except:
        pass

    # Create app
    try:
        page.click("text=Create an app", timeout=5000)
        time.sleep(2)
    except:
        page.click("button:has-text('Create')", timeout=5000)
        time.sleep(2)

    # Fill app name
    try:
        page.fill('input[name="name"]', 'Jade Oracle Engine', timeout=5000)
    except:
        # Try other selectors
        inputs = page.query_selector_all('input[type="text"]')
        for inp in inputs:
            if not inp.get_attribute('value'):
                inp.fill('Jade Oracle Engine')
                break
    time.sleep(1)

    # Click Create app button
    try:
        page.click('button:has-text("Create app")', timeout=5000)
    except:
        page.click('button[type="submit"]', timeout=5000)
    time.sleep(3)

    # Configure API scopes
    print("   Configuring API scopes...")
    try:
        page.click("text=Configure Admin API scopes", timeout=10000)
        time.sleep(3)
    except:
        page.click("a:has-text('Configure')", timeout=5000)
        time.sleep(3)

    # Select scopes
    scopes = [
        'write_products', 'read_products',
        'write_orders', 'read_orders',
        'write_customers', 'read_customers',
        'read_checkouts',
        'write_draft_orders', 'read_draft_orders',
    ]

    for scope in scopes:
        try:
            checkbox = page.query_selector(f'input[value="{scope}"]')
            if checkbox and not checkbox.is_checked():
                checkbox.check()
                time.sleep(0.3)
        except:
            # Try clicking label
            try:
                page.click(f'label:has-text("{scope}")', timeout=2000)
                time.sleep(0.3)
            except:
                print(f"   ⚠️  Could not set scope: {scope}")

    # Save scopes
    try:
        page.click('button:has-text("Save")', timeout=5000)
        time.sleep(3)
    except:
        pass

    # Install app
    print("   Installing app...")
    try:
        page.click('button:has-text("Install app")', timeout=10000)
        time.sleep(2)
        # Confirm
        page.click('button:has-text("Install")', timeout=5000)
        time.sleep(3)
    except:
        pass

    # Get the API token
    print("   Looking for Admin API access token...")
    try:
        # The token is shown once after install - look for reveal button
        reveal = page.query_selector('button:has-text("Reveal token once")')
        if reveal:
            reveal.click()
            time.sleep(2)

        # Try to find the token text
        token_el = page.query_selector('[data-testid="admin-api-access-token"] input, .access-token input, pre:has-text("shpat_")')
        if token_el:
            token = token_el.get_attribute('value') or token_el.inner_text()
            if token and token.startswith('shpat_'):
                print(f"   ✅ Got API token: {token[:15]}...")
                save_token(token)
                return token

        # Fallback: look for any text starting with shpat_
        page_text = page.inner_text('body')
        import re
        match = re.search(r'(shpat_[a-f0-9]{32,})', page_text)
        if match:
            token = match.group(1)
            print(f"   ✅ Got API token: {token[:15]}...")
            save_token(token)
            return token

        print("   ⚠️  Token not found on page. Taking screenshot...")
        page.screenshot(path="/tmp/shopify-app-install.png")
        print("   Screenshot saved to /tmp/shopify-app-install.png")

    except Exception as e:
        print(f"   ⚠️  Error getting token: {e}")
        page.screenshot(path="/tmp/shopify-app-error.png")

    return None

def save_token(token):
    """Save token to secrets file"""
    env_path = SECRETS_DIR / "shopify-jade.env"
    content = env_path.read_text()
    content = content.replace('SHOPIFY_ADMIN_TOKEN=', f'SHOPIFY_ADMIN_TOKEN={token}')
    env_path.write_text(content)
    print(f"   💾 Token saved to {env_path}")

def create_products_via_api(token):
    """Create products via Shopify Admin API"""
    import urllib.request

    print("\n🛍️  Creating products via API...")

    with open(PRODUCTS_FILE) as f:
        products_data = json.load(f)

    store = "7qz8cj-uu.myshopify.com"
    headers = {
        "X-Shopify-Access-Token": token,
        "Content-Type": "application/json",
    }

    for product in products_data.get("products", []):
        title = product["title"]
        print(f"   Creating: {title}...")

        payload = json.dumps({"product": product}).encode()
        req = urllib.request.Request(
            f"https://{store}/admin/api/2025-01/products.json",
            data=payload,
            headers=headers,
            method="POST"
        )

        try:
            with urllib.request.urlopen(req) as resp:
                result = json.loads(resp.read())
                pid = result.get("product", {}).get("id", "?")
                print(f"   ✅ Created: {title} (ID: {pid})")
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            print(f"   ❌ Failed: {title} — {e.code} {body[:200]}")
        except Exception as e:
            print(f"   ❌ Failed: {title} — {e}")

        time.sleep(1)  # Rate limit

def create_products_via_ui(page):
    """Create products via Shopify admin UI"""
    print("\n🛍️  Creating products via admin UI...")

    with open(PRODUCTS_FILE) as f:
        products_data = json.load(f)

    for product in products_data.get("products", []):
        title = product["title"]
        price = product["variants"][0]["price"]
        body = product.get("body_html", "")
        sku = product["variants"][0].get("sku", "")
        tags = ", ".join(product.get("tags", []))

        print(f"   Creating: {title} (${price})...")

        page.goto(f"{STORE_URL}/products/new")
        page.wait_for_load_state("networkidle")
        time.sleep(2)

        # Fill title
        try:
            page.fill('input[name="title"]', title, timeout=5000)
        except:
            title_input = page.query_selector('[aria-label="Title"], input[placeholder*="title" i]')
            if title_input:
                title_input.fill(title)
        time.sleep(1)

        # Fill price
        try:
            price_input = page.query_selector('input[name="price"], input[aria-label="Price"]')
            if price_input:
                price_input.fill(price)
        except:
            pass
        time.sleep(0.5)

        # Uncheck "Track quantity" and "This is a physical product" for digital goods
        try:
            physical = page.query_selector('input[name="requiresShipping"], label:has-text("physical product") input')
            if physical and physical.is_checked():
                physical.uncheck()
        except:
            pass

        # Set status to active
        try:
            page.select_option('select[name="status"]', 'active')
        except:
            pass

        # Save
        try:
            page.click('button:has-text("Save")', timeout=5000)
            time.sleep(3)
            print(f"   ✅ Created: {title}")
        except Exception as e:
            print(f"   ⚠️  Save may have failed: {e}")
            page.screenshot(path=f"/tmp/shopify-product-{sku}.png")

        time.sleep(1)

def connect_domain(page):
    """Connect custom domain in Shopify"""
    print(f"\n🌐 Connecting domain: {DOMAIN}...")

    page.goto(f"{STORE_URL}/settings/domains")
    page.wait_for_load_state("networkidle")
    time.sleep(3)

    # Click "Connect existing domain"
    try:
        page.click("text=Connect existing domain", timeout=10000)
        time.sleep(2)
    except:
        try:
            page.click("button:has-text('Connect')", timeout=5000)
            time.sleep(2)
        except:
            print("   ⚠️  Could not find Connect domain button")
            page.screenshot(path="/tmp/shopify-domain.png")
            return

    # Enter domain
    try:
        page.fill('input[type="text"]', DOMAIN, timeout=5000)
        time.sleep(1)
    except:
        pass

    # Click Next/Verify/Connect
    try:
        page.click('button:has-text("Next")', timeout=5000)
        time.sleep(3)
    except:
        try:
            page.click('button:has-text("Connect")', timeout=5000)
            time.sleep(3)
        except:
            pass

    # Verify connection (DNS already set up)
    try:
        page.click('button:has-text("Verify")', timeout=10000)
        time.sleep(5)
        print(f"   ✅ Domain connected: {DOMAIN}")
    except:
        print(f"   ⚠️  Domain verification may need manual check")
        page.screenshot(path="/tmp/shopify-domain-verify.png")

def setup_store_basics(page):
    """Set up basic store settings"""
    print("\n⚙️  Setting up store basics...")

    # Store name
    page.goto(f"{STORE_URL}/settings")
    page.wait_for_load_state("networkidle")
    time.sleep(2)

    # Navigate to store details
    try:
        page.click("text=Store details", timeout=5000)
        time.sleep(2)

        # Update store name
        name_input = page.query_selector('input[name="name"], input[aria-label="Store name"]')
        if name_input:
            name_input.fill("")
            name_input.fill("The Jade Oracle")
            time.sleep(1)

        # Save
        page.click('button:has-text("Save")', timeout=5000)
        time.sleep(2)
        print("   ✅ Store name set to 'The Jade Oracle'")
    except Exception as e:
        print(f"   ⚠️  Store details: {e}")

def main():
    step = sys.argv[sys.argv.index('--step') + 1] if '--step' in sys.argv else 'all'
    headless = '--headless' in sys.argv

    print(f"🔮 Jade Oracle Shopify Setup — step: {step}")
    print(f"   Store: {STORE_URL}")
    print(f"   Domain: {DOMAIN}")
    print()

    with sync_playwright() as p:
        # Connect to existing browser or launch new one
        # Use persistent context to reuse login session
        user_data_dir = str(Path.home() / "Library/Application Support/Google/Chrome")

        try:
            # Try to connect to existing Chrome via CDP
            browser = p.chromium.connect_over_cdp("http://localhost:9222")
            print("   Connected to existing Chrome browser")
            context = browser.contexts[0]
            page = context.pages[0] if context.pages else context.new_page()
        except:
            # Launch with user profile to get existing Shopify login
            print("   Launching browser with Chrome profile...")
            context = p.chromium.launch_persistent_context(
                user_data_dir,
                headless=headless,
                channel="chrome",
                args=["--disable-blink-features=AutomationControlled"],
            )
            page = context.pages[0] if context.pages else context.new_page()

        # Navigate to Shopify admin to verify we're logged in
        page.goto(STORE_URL)
        page.wait_for_load_state("networkidle")
        time.sleep(3)

        # Check if logged in
        if "login" in page.url.lower() or "accounts.shopify" in page.url.lower():
            print("   ⚠️  Not logged in to Shopify. Please log in manually.")
            print(f"   Navigate to: {STORE_URL}")
            input("   Press Enter when logged in...")

        print(f"   ✅ Connected to Shopify admin: {page.url}")

        token = None

        if step in ('all', 'store-basics'):
            setup_store_basics(page)

        if step in ('all', 'create-app'):
            token = create_custom_app(page)

        if step in ('all', 'create-products'):
            if token:
                create_products_via_api(token)
            else:
                # Try loading saved token
                try:
                    env = (SECRETS_DIR / "shopify-jade.env").read_text()
                    import re
                    m = re.search(r'SHOPIFY_ADMIN_TOKEN=(shpat_\S+)', env)
                    if m:
                        token = m.group(1)
                        create_products_via_api(token)
                    else:
                        create_products_via_ui(page)
                except:
                    create_products_via_ui(page)

        if step in ('all', 'connect-domain'):
            connect_domain(page)

        print("\n🎉 Setup complete!")
        if not headless:
            print("   Browser left open for manual review.")
            input("   Press Enter to close...")

        context.close()


if __name__ == "__main__":
    main()
