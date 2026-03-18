#!/usr/bin/env python3
"""
Meta Instagram API Setup via browser-use (Two-Phase)

Phase 1 (login):  Opens browser for user to log into Facebook manually.
                   Saves cookies to persistent Chromium profile.
Phase 2 (setup):  AI agent uses saved session to configure IG API.
Phase 3 (token):  AI agent generates access token with IG permissions.

Usage:
  python3 meta-ig-setup.py login   # Step 1: log in manually
  python3 meta-ig-setup.py setup   # Step 2: agent does IG config
  python3 meta-ig-setup.py token   # Step 3: agent generates token
  python3 meta-ig-setup.py all     # login → setup → token
"""
import asyncio
import os
import sys
import signal

from pathlib import Path

# Load env files
for env_path in [
    Path.home() / ".openclaw" / ".env",
    Path.home() / ".openclaw" / "secrets" / "meta-marketing.env",
]:
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

from browser_use import Agent, Browser, ChatGoogle

# Constants
META_APP_ID = os.environ.get("META_APP_ID", "1647272119493183")
IG_APP_ID = "1956517408603140"
PROFILE_DIR = str(Path.home() / ".openclaw" / "browser-profiles" / "meta-dev")


def get_llm():
    return ChatGoogle(
        model="gemini-2.5-flash",
        api_key=os.environ["GOOGLE_API_KEY"],
        temperature=0.1,
    )


def get_browser():
    """Shared browser config — same Chromium profile for login + automation."""
    return Browser(
        headless=False,
        user_data_dir=PROFILE_DIR,
    )


async def phase_login():
    """Phase 1: Open browser for user to log into Facebook.

    Uses browser-use's own Browser (not raw playwright) so the Chromium
    profile is identical between login and automation phases.
    The agent navigates to Facebook and waits while user logs in.
    """
    print("[Phase 1] Opening browser for Facebook login...")
    print("[Phase 1] Please log into Facebook in the browser window.")
    print("[Phase 1] After logging in, the agent will detect it and continue.")
    print()

    browser = get_browser()
    agent = Agent(
        task=f"""
Go to https://developers.facebook.com/apps/{META_APP_ID}/instagram-api/settings/

Check what you see:
- If you see a Facebook login page, WAIT. The user is logging in manually right now.
  Check every 15 seconds by refreshing the page. Keep waiting up to 5 minutes.
  Once you see the Meta Developer Console (not a login page), report "LOGIN_COMPLETE".
- If you already see the Meta Developer Console / App Dashboard, report "ALREADY_LOGGED_IN".

Do NOT enter any credentials. Just wait and observe.
Report what you see on the final page (any buttons, account names, settings visible).
""",
        llm=get_llm(),
        browser=browser,
        max_actions_per_step=3,
        use_vision=True,
    )

    try:
        result = await agent.run(max_steps=20)
        print(f"\n[Phase 1] Result: {result}")
        if result and hasattr(result, 'final_result'):
            print(f"[Phase 1] Status: {result.final_result()}")
    except Exception as e:
        print(f"\n[Phase 1] Error: {e}")
    finally:
        # Browser profile auto-saved to PROFILE_DIR
        try:
            await browser.close()
        except:
            pass

    print("\n[Phase 1] Done. Cookies saved to:", PROFILE_DIR)
    print("[Phase 1] Now run: python3 meta-ig-setup.py setup")


async def phase_roles():
    """Phase 1b: Add Instagram accounts as testers in App Roles.
    Must be done BEFORE connecting IG accounts via API settings.
    """
    print("[Phase 1b] Adding Instagram accounts as testers in App Roles...")
    print("[Phase 1b] The agent will navigate to Roles and add mirra.eats + pinxinvegan.")
    print()

    agent = Agent(
        task=f"""
You are on the Meta Developer Console. Your task is to add Instagram accounts as testers.

STEP BY STEP:
1. Go to https://developers.facebook.com/apps/{META_APP_ID}/roles/roles/
2. Look for an "Add People" or "Add Testers" or "Add Instagram Testers" button
3. Click it
4. In the dialog, look for a way to add Instagram Testers specifically
   - If there's a dropdown to select role type, choose "Instagram Testers"
5. Enter the Instagram username: mirra.eats
6. Click Add/Confirm
7. Repeat for username: pinxinvegan
8. Report what happened — did both get added? Any errors?

AFTER ADDING TESTERS:
9. The Instagram account owners need to accept the invite at instagram.com
10. Go to https://developers.facebook.com/apps/{META_APP_ID}/instagram-api/settings/
11. Report what the page looks like now — are there any accounts listed?

IMPORTANT:
- If you see a FACEBOOK login page, STOP and report "FB_LOGIN_REQUIRED"
- If a dialog asks for Instagram credentials, WAIT — the user will log in manually. Check every 15 seconds.
- Do NOT enter any passwords
- Report exactly what you see at each step
""",
        llm=get_llm(),
        browser=get_browser(),
        max_actions_per_step=5,
        use_vision=True,
    )

    try:
        result = await agent.run(max_steps=30)
        print(f"\n[Phase 1b] Result: {result}")
        if result and hasattr(result, 'final_result'):
            print(f"\n[Phase 1b] Final: {result.final_result()}")
    except Exception as e:
        print(f"\n[Phase 1b] Error: {e}")


async def phase_setup():
    """Phase 2: AI agent configures Instagram API using saved session."""
    print("[Phase 2] Starting Instagram API setup...")
    print()

    agent = Agent(
        task=f"""
You are automating Meta Developer Console Instagram API setup.
The user is already logged into Facebook (session from previous step).

Meta App ID: {META_APP_ID}
Instagram App ID: {IG_APP_ID}

STEP-BY-STEP TASKS:

1. Go to https://developers.facebook.com/apps/{META_APP_ID}/instagram-api/settings/
   - If the page is blank or redirects to dashboard, try: click "Instagram" in left sidebar, then "API setup with Instagram login"
   - Report what you see on this page

2. Under "Generate access tokens" (Step 1 on the page):
   - Click "Add account" button
   - Click "Continue" in the dialog
   - A NEW TAB will open for Instagram login
   - Switch to that Instagram login tab
   - WAIT for the user to log in manually (they will enter their Instagram credentials)
   - Check every 15 seconds by looking at the tab — wait up to 3 minutes
   - Once you see the page has changed from a login form (e.g. shows a success message, redirect, or the tab closes), switch back to the original Meta Developer Console tab
   - Check if the account was added successfully
   - If there's a token visible, copy it (starts with "EAA...")

3. If you need to add a second account, repeat step 2

4. Under "Set up Instagram business login" (Step 3 on the page):
   - Click "Set up" if available
   - Follow the setup flow
   - Report what configuration is needed

5. Report a summary of:
   - Which accounts were added successfully
   - Any tokens generated (full text)
   - Any errors or steps that need manual attention

IMPORTANT RULES:
- If you see a FACEBOOK login page, STOP and report "FB_LOGIN_REQUIRED"
- If you see an INSTAGRAM login page in a new tab, WAIT — the user is logging in manually
- Do NOT enter any passwords on ANY login page
- Click through dialogs and confirmations on the Meta Developer Console
- Report everything you see at each step
""",
        llm=get_llm(),
        browser=get_browser(),
        max_actions_per_step=5,
        use_vision=True,
    )

    try:
        result = await agent.run(max_steps=35)
        print(f"\n[Phase 2] Result: {result}")
        if result and hasattr(result, 'final_result'):
            final = result.final_result()
            print(f"\n[Phase 2] Final: {final}")
            _save_tokens(str(final))
    except Exception as e:
        print(f"\n[Phase 2] Error: {e}")


async def phase_token():
    """Phase 3: Generate access token with IG permissions via Graph API Explorer."""
    print("[Phase 3] Starting Graph API Explorer token generation...")
    print()

    agent = Agent(
        task=f"""
You are using Meta Graph API Explorer to generate an access token with Instagram permissions.

YOUR TASK:
1. Go to https://developers.facebook.com/tools/explorer/
2. In the "Meta App" dropdown, select "ads upload" (App ID: {META_APP_ID})
3. Click "Generate Access Token"
4. In the permissions dialog, check ALL of these:
   - pages_manage_posts
   - pages_show_list
   - pages_read_engagement
   - instagram_basic
   - instagram_content_publish
   - instagram_manage_comments
   - instagram_manage_insights
   - ads_management (keep if already checked)
   - ads_read (keep if already checked)
   - business_management (keep if already checked)
   - read_insights (keep if already checked)
5. Click "Generate Access Token" or "Continue"
6. If a Facebook permission dialog appears, click "Continue" / "Allow"
7. Copy the generated access token from the Access Token field
8. Report the COMPLETE token text (starts with "EAA...")

IMPORTANT:
- If login page appears, STOP and report "LOGIN_REQUIRED"
- Token will be a long string — report it completely, do not truncate
- After getting the token, also try: paste the token in the Access Token field,
  then run this query: GET /me/accounts — report the response (shows connected pages)
""",
        llm=get_llm(),
        browser=get_browser(),
        max_actions_per_step=5,
        use_vision=True,
    )

    try:
        result = await agent.run(max_steps=30)
        print(f"\n[Phase 3] Result: {result}")
        if result and hasattr(result, 'final_result'):
            final = result.final_result()
            print(f"\n[Phase 3] Final: {final}")
            _save_tokens(str(final))
    except Exception as e:
        print(f"\n[Phase 3] Error: {e}")


def _save_tokens(text):
    """Extract and save any EAA... tokens found in result text."""
    if not text or "EAA" not in text:
        return
    import re
    match = re.search(r'(EAA[A-Za-z0-9+/=]+)', text)
    if not match:
        return

    new_token = match.group(1)
    print(f"\n[Token] Extracted: {new_token[:20]}...{new_token[-10:]}")
    print(f"[Token] Length: {len(new_token)}")

    secrets = Path.home() / ".openclaw" / "secrets" / "meta-marketing.env"
    if secrets.exists():
        content = secrets.read_text()
        old_token = os.environ.get("META_ACCESS_TOKEN", "")
        if old_token and old_token in content:
            content = content.replace(old_token, new_token)
            secrets.write_text(content)
            print(f"[Token] Saved to {secrets}")
        else:
            print(f"[Token] Could not auto-replace. Manual update needed.")
            print(f"[Token] Full token: {new_token}")


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "login"

    if mode == "login":
        asyncio.run(phase_login())
    elif mode == "roles":
        asyncio.run(phase_roles())
    elif mode == "setup":
        asyncio.run(phase_setup())
    elif mode == "token":
        asyncio.run(phase_token())
    elif mode == "all":
        asyncio.run(phase_login())
        print("\n" + "=" * 60)
        print("Phase 1 complete. Starting Phase 2...")
        print("=" * 60 + "\n")
        asyncio.run(phase_setup())
        print("\n" + "=" * 60)
        print("Phase 2 complete. Starting Phase 3...")
        print("=" * 60 + "\n")
        asyncio.run(phase_token())
    else:
        print(f"Usage: {sys.argv[0]} [login|setup|token|all]")
        print("  login — Open browser for Facebook login (do this first)")
        print("  setup — AI agent configures IG API (needs login first)")
        print("  token — AI agent generates token with IG permissions")
        print("  all   — Run all phases in sequence")
