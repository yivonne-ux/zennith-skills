#!/usr/bin/env python3
"""
Meta Instagram API Token Setup via Playwright (direct, no browser-use dependency).

Opens a real Chromium browser for manual Facebook/Instagram login,
then navigates to Graph API Explorer to generate a token with IG permissions.

Usage:
  python3 meta-token-setup.py login     # Step 1: Log into Facebook
  python3 meta-token-setup.py token     # Step 2: Get token from Graph API Explorer
  python3 meta-token-setup.py discover  # Step 3: Find IG User ID
  python3 meta-token-setup.py all       # All steps in sequence

Requires: playwright (pip3 install playwright && playwright install chromium)
"""

import json
import os
import re
import sys
import time
from pathlib import Path

# Load env
SECRETS_DIR = Path.home() / ".openclaw" / "secrets"
SECRETS_FILE = SECRETS_DIR / "meta-marketing.env"
PROFILE_DIR = str(Path.home() / ".openclaw" / "browser-profiles" / "meta-dev")
META_APP_ID = os.environ.get("META_APP_ID", "1647272119493183")

# Load existing secrets
if SECRETS_FILE.exists():
    for line in SECRETS_FILE.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())


def save_secret(key, value):
    """Save a key=value to meta-marketing.env."""
    SECRETS_DIR.mkdir(parents=True, exist_ok=True)
    if SECRETS_FILE.exists():
        lines = SECRETS_FILE.read_text().splitlines()
        updated = False
        for i, line in enumerate(lines):
            if line.strip().startswith(f"{key}="):
                lines[i] = f"{key}={value}"
                updated = True
                break
        if not updated:
            lines.append(f"{key}={value}")
        SECRETS_FILE.write_text("\n".join(lines) + "\n")
    else:
        SECRETS_FILE.write_text(f"{key}={value}\n")
    SECRETS_FILE.chmod(0o600)
    print(f"[setup] Saved {key} to {SECRETS_FILE}")


def get_browser(headless=False):
    """Launch persistent Chromium with saved profile."""
    from playwright.sync_api import sync_playwright
    pw = sync_playwright().start()
    browser = pw.chromium.launch_persistent_context(
        user_data_dir=PROFILE_DIR,
        headless=headless,
        viewport={"width": 1280, "height": 900},
        args=["--disable-blink-features=AutomationControlled"],
    )
    return pw, browser


def phase_login():
    """Phase 1: Open browser for user to log into Facebook manually."""
    print("[Phase 1] Opening browser for Facebook login...")
    print("[Phase 1] Please log into Facebook in the browser window.")
    print("[Phase 1] After logging in, close the browser or press Enter here.")
    print()

    pw, browser = get_browser()
    page = browser.new_page()
    page.goto(f"https://developers.facebook.com/apps/{META_APP_ID}/dashboard/")

    print("[Phase 1] Browser opened. Log into Facebook now...")
    print("[Phase 1] Press Enter when done logging in...")
    try:
        input()
    except EOFError:
        # Running non-interactively, wait for navigation
        print("[Phase 1] Non-interactive mode — waiting 120s for login...")
        time.sleep(120)

    # Check if logged in
    current_url = page.url
    print(f"[Phase 1] Current URL: {current_url}")

    if "login" not in current_url.lower():
        print("[Phase 1] Login appears successful!")
    else:
        print("[Phase 1] Still on login page — you may need to try again")

    browser.close()
    pw.stop()
    print(f"[Phase 1] Cookies saved to: {PROFILE_DIR}")
    print("[Phase 1] Now run: python3 meta-token-setup.py token")


def phase_token():
    """Phase 2: Navigate to Graph API Explorer and guide user to get token."""
    print("[Phase 2] Opening Graph API Explorer...")
    print()

    pw, browser = get_browser()
    page = browser.new_page()

    # Go to Graph API Explorer
    explorer_url = f"https://developers.facebook.com/tools/explorer/?method=GET&path=me%2Faccounts&version=v21.0"
    page.goto(explorer_url)
    time.sleep(3)

    # Check if we need to log in
    if "login" in page.url.lower():
        print("[Phase 2] Not logged in. Run: python3 meta-token-setup.py login first")
        browser.close()
        pw.stop()
        return

    print("[Phase 2] Graph API Explorer loaded.")
    print()
    print("=" * 60)
    print("MANUAL STEPS (do these in the browser window):")
    print("=" * 60)
    print()
    print('1. In the "Meta App" dropdown, select your app')
    print(f'   (App ID: {META_APP_ID})')
    print()
    print('2. Click "Generate Access Token"')
    print()
    print("3. In the permissions dialog, check ALL of these:")
    print("   - pages_manage_posts")
    print("   - pages_show_list")
    print("   - pages_read_engagement")
    print("   - instagram_basic")
    print("   - instagram_content_publish")
    print("   - instagram_manage_comments")
    print("   - instagram_manage_insights")
    print()
    print('4. Click "Generate Access Token" / "Continue"')
    print()
    print('5. If a permission dialog appears, click "Continue" / "Allow"')
    print()
    print("6. Copy the token from the Access Token field (starts with EAA...)")
    print()
    print("=" * 60)
    print()

    # Wait for user to paste token or find it in page
    token = ""
    attempts = 0
    while not token and attempts < 60:
        try:
            # Try to find token in the page
            token_input = page.query_selector('input[placeholder*="Access Token"], input[value^="EAA"]')
            if token_input:
                val = token_input.get_attribute("value") or ""
                if val.startswith("EAA") and len(val) > 50:
                    token = val
                    break

            # Also try to scrape from visible text
            body_text = page.inner_text("body")
            match = re.search(r'(EAA[A-Za-z0-9+/=]{50,})', body_text)
            if match:
                token = match.group(1)
                break

        except Exception:
            pass

        if attempts % 10 == 0 and attempts > 0:
            print(f"[Phase 2] Still waiting for token... ({attempts}s)")
        time.sleep(2)
        attempts += 1

    if not token:
        print()
        print("[Phase 2] Could not auto-detect token.")
        print("[Phase 2] Please paste the token here (starts with EAA...):")
        try:
            token = input("> ").strip()
        except EOFError:
            pass

    browser.close()
    pw.stop()

    if token and token.startswith("EAA"):
        print(f"\n[Phase 2] Token found! ({len(token)} chars)")
        print(f"[Phase 2] Preview: {token[:20]}...{token[-10:]}")
        save_secret("META_ACCESS_TOKEN", token)
        print("[Phase 2] Now run: python3 meta-token-setup.py discover")
    else:
        print("[Phase 2] No valid token found. Try again or paste manually:")
        print(f"  bash meta-token-manager.sh save META_ACCESS_TOKEN <your-token>")


def phase_discover():
    """Phase 3: Use the token to find IG User ID from Facebook Pages."""
    import urllib.request
    import urllib.parse

    token = os.environ.get("META_ACCESS_TOKEN", "")
    if not token:
        # Try loading from file
        if SECRETS_FILE.exists():
            for line in SECRETS_FILE.read_text().splitlines():
                if line.strip().startswith("META_ACCESS_TOKEN="):
                    token = line.split("=", 1)[1].strip()
                    break

    if not token:
        print("[Phase 3] No META_ACCESS_TOKEN found. Run phase 2 first.")
        return

    print("[Phase 3] Discovering Instagram accounts...")

    # Get connected Facebook Pages
    url = f"https://graph.facebook.com/v21.0/me/accounts?fields=id,name,instagram_business_account&access_token={token}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"[Phase 3] API error: {e}")
        return

    pages = data.get("data", [])
    if not pages:
        print("[Phase 3] No Facebook Pages found.")
        print("[Phase 3] Your Instagram account must be a Business or Creator account")
        print("[Phase 3] linked to a Facebook Page.")
        return

    found_ig = False
    for page in pages:
        name = page.get("name", "Unknown")
        page_id = page.get("id", "")
        ig = page.get("instagram_business_account", {})
        ig_id = ig.get("id", "")

        print(f"  Page: {name} (ID: {page_id})")

        if ig_id:
            # Get IG username
            try:
                ig_url = f"https://graph.facebook.com/v21.0/{ig_id}?fields=username,followers_count,media_count&access_token={token}"
                with urllib.request.urlopen(ig_url, timeout=30) as resp:
                    ig_data = json.loads(resp.read().decode("utf-8"))
                username = ig_data.get("username", "unknown")
                followers = ig_data.get("followers_count", "?")
                posts = ig_data.get("media_count", "?")
                print(f"  -> Instagram: @{username} ({followers} followers, {posts} posts)")
            except Exception:
                username = "unknown"
                print(f"  -> IG Business Account ID: {ig_id}")

            save_secret("IG_USER_ID", ig_id)
            save_secret("IG_PAGE_ID", page_id)
            found_ig = True
            break
        else:
            print(f"  -> No Instagram account linked")

    if found_ig:
        print()
        print("[Phase 3] Setup complete!")
        print("[Phase 3] Now run: bash meta-token-manager.sh validate")
        print("[Phase 3] Then:    bash jade-ig-loop-runner.sh --dry-run")
    else:
        print()
        print("[Phase 3] No Instagram Business accounts found.")
        print("[Phase 3] Make sure your Instagram is a Business/Creator account")
        print("[Phase 3] and is linked to a Facebook Page.")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"

    if mode == "login":
        phase_login()
    elif mode == "token":
        phase_token()
    elif mode == "discover":
        phase_discover()
    elif mode == "all":
        phase_login()
        print("\n" + "=" * 60)
        print("Phase 1 complete. Starting token generation...")
        print("=" * 60 + "\n")
        phase_token()
        print("\n" + "=" * 60)
        print("Phase 2 complete. Discovering IG account...")
        print("=" * 60 + "\n")
        phase_discover()
    else:
        print(f"Usage: {sys.argv[0]} [login|token|discover|all]")
        print("  login    — Open browser for Facebook login")
        print("  token    — Get token from Graph API Explorer")
        print("  discover — Find IG User ID from connected Pages")
        print("  all      — Run all phases in sequence")
