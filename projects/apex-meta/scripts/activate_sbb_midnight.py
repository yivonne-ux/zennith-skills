"""Midnight activation — all scheduled changes go live at 12AM.

One-time script scheduled via cron for 2026-03-24 00:00.

Mirra:
  - Activates 6 EN SBB + 5 CN SBB video ads
  - Kills S10/S15/S01 (proven dead)

Pinxin:
  - Scales Website campaign RM300 → RM360/day (20% rule)
"""

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path


TOKEN_PATH = Path.home() / "Desktop/_WORK/_shared/.meta-token"


def load_token():
    if TOKEN_PATH.exists():
        return TOKEN_PATH.read_text().strip()
    print("ERROR: No token found")
    sys.exit(1)


def api_post(endpoint, data, token):
    url = f"https://graph.facebook.com/v21.0/{endpoint}"
    payload = {**data, "access_token": token}
    encoded = urllib.parse.urlencode(payload).encode()
    req = urllib.request.Request(url, data=encoded, method="POST")
    resp = urllib.request.urlopen(req)
    return json.loads(resp.read())


def api_get(endpoint, params, token):
    params["access_token"] = token
    qs = urllib.parse.urlencode(params)
    url = f"https://graph.facebook.com/v21.0/{endpoint}?{qs}"
    resp = urllib.request.urlopen(url)
    return json.loads(resp.read())


def main():
    token = load_token()
    print("=== MIDNIGHT ACTIVATION — SBB Videos ===")

    # EN SBB ads in SALES-EN ad set
    EN_ADSET = "120243085921060787"
    # CN SBB ads in TEST-CN CN-MIX ad set
    CN_ADSET = "120242860861020787"

    # Ads to KILL (proven dead)
    KILL_NAMES = ["S10-Checklist", "S15-Horoscope", "S01-Notes"]

    activated = 0
    killed = 0

    for adset_id, label in [(EN_ADSET, "SALES-EN"), (CN_ADSET, "TEST-CN")]:
        ads = api_get(f"{adset_id}/ads", {"fields": "id,name,status", "limit": "50"}, token)

        for ad in ads.get("data", []):
            name = ad["name"]

            # Activate SBB ads
            if "SBB" in name and ad["status"] == "PAUSED":
                api_post(ad["id"], {"status": "ACTIVE"}, token)
                print(f"  ACTIVATED: {name}")
                activated += 1

            # Kill dead ads
            if any(k in name for k in KILL_NAMES) and ad["status"] == "ACTIVE":
                api_post(ad["id"], {"status": "PAUSED"}, token)
                print(f"  KILLED: {name}")
                killed += 1

    print(f"\nMirra done: {activated} activated, {killed} killed")

    # --- PINXIN: Scale Website budget 20% ---
    print("\n=== PINXIN — Scale Website Budget ===")
    PX_WEBSITE_CAMPAIGN = "120240872763100006"
    try:
        api_post(PX_WEBSITE_CAMPAIGN, {"daily_budget": "36000"}, token)
        print("  Website budget: RM300 → RM360/day (20% scale)")
    except Exception as e:
        print(f"  FAILED to scale Pinxin budget: {e}")

    print("\n=== ALL MIDNIGHT CHANGES APPLIED ===")


if __name__ == "__main__":
    main()
