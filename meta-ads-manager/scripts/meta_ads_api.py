#!/usr/bin/env python3
"""Meta Marketing API client for GAIA CORP-OS.

Provides campaign management, creative upload, and performance analysis
via the Meta Graph API (Marketing API).

Requires credentials in ~/.openclaw/secrets/meta-marketing.env:
  META_ACCESS_TOKEN=...
  META_AD_ACCOUNT_ID=act_...
  META_PIXEL_ID=...

Usage:
    python3 meta_ads_api.py --check-auth
    python3 meta_ads_api.py --campaigns --days 7
    python3 meta_ads_api.py --top-creatives --days 30 --limit 10
    python3 meta_ads_api.py --fatigue-check --days 14
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Try to load credentials
SECRETS_DIR = Path.home() / ".openclaw" / "secrets"
CREDS_FILE = SECRETS_DIR / "meta-marketing.env"
API_VERSION = os.environ.get("META_GRAPH_VERSION", "v20.0")
BASE_URL = f"https://graph.facebook.com/{API_VERSION}"


def load_credentials() -> dict:
    """Load Meta Marketing API credentials from env file."""
    creds = {}

    # First check environment variables
    for key in ["META_ACCESS_TOKEN", "META_AD_ACCOUNT_ID", "META_PIXEL_ID",
                "META_PAGE_ID", "META_BUSINESS_ID"]:
        val = os.environ.get(key)
        if val:
            creds[key] = val

    # Then try credentials file
    if CREDS_FILE.exists():
        with open(CREDS_FILE) as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, _, value = line.partition("=")
                    creds[key.strip()] = value.strip()

    return creds


def check_auth() -> dict:
    """Check if Meta Marketing API credentials are configured and valid."""
    creds = load_credentials()

    status = {
        "configured": False,
        "token_present": bool(creds.get("META_ACCESS_TOKEN")),
        "account_present": bool(creds.get("META_AD_ACCOUNT_ID")),
        "pixel_present": bool(creds.get("META_PIXEL_ID")),
        "creds_file": str(CREDS_FILE),
        "creds_file_exists": CREDS_FILE.exists(),
    }

    if not status["token_present"]:
        status["message"] = (
            "Not configured. To set up:\n"
            f"1. Create {CREDS_FILE} with:\n"
            "   META_ACCESS_TOKEN=your_token\n"
            "   META_AD_ACCOUNT_ID=act_123456789\n"
            "   META_PIXEL_ID=123456789\n"
            "2. Get token from: business.facebook.com → Business Settings → System Users\n"
            "3. Required permissions: ads_management, ads_read, pages_read_engagement"
        )
        return status

    # Try to validate token
    try:
        import urllib.request
        import urllib.error

        token = creds["META_ACCESS_TOKEN"]
        url = f"{BASE_URL}/me?access_token={token}"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            if isinstance(data, list):
                data = data[0] if data else {}
            status["configured"] = True
            status["user_name"] = data.get("name", "Unknown")
            status["user_id"] = data.get("id", "Unknown")
            status["message"] = f"Connected as: {data.get('name')} (ID: {data.get('id')})"

    except urllib.error.HTTPError as e:
        error_body = e.read().decode() if e.fp else ""
        status["message"] = f"Token invalid or expired. HTTP {e.code}: {error_body[:200]}"
    except Exception as e:
        status["message"] = f"Connection error: {e}"

    return status


def get_campaigns(days: int = 7) -> dict:
    """Get campaign performance for the last N days."""
    creds = load_credentials()
    token = creds.get("META_ACCESS_TOKEN")
    account_id = creds.get("META_AD_ACCOUNT_ID")

    if not token or not account_id:
        return {"error": "Credentials not configured. Run: --check-auth"}

    try:
        import urllib.request

        since = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%d")
        until = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        url = (
            f"{BASE_URL}/{account_id}/campaigns?"
            f"fields=name,status,objective,daily_budget,lifetime_budget,"
            f"insights{{spend,impressions,clicks,ctr,cpm,cpc,actions,cost_per_action_type}}"
            f"&time_range={{'since':'{since}','until':'{until}'}}"
            f"&access_token={token}"
        )

        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
            if isinstance(data, list):
                data = {"data": data}
            return {
                "period": f"{since} to {until}",
                "campaigns": data.get("data", []),
                "total": len(data.get("data", [])),
            }

    except Exception as e:
        return {"error": str(e)}


def get_top_creatives(days: int = 30, limit: int = 10) -> dict:
    """Get top performing ad creatives."""
    creds = load_credentials()
    token = creds.get("META_ACCESS_TOKEN")
    account_id = creds.get("META_AD_ACCOUNT_ID")

    if not token or not account_id:
        return {"error": "Credentials not configured. Run: --check-auth"}

    try:
        import urllib.request

        since = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%d")
        until = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        url = (
            f"{BASE_URL}/{account_id}/ads?"
            f"fields=name,creative{{title,body,image_url,thumbnail_url,video_id}},"
            f"insights{{spend,impressions,clicks,ctr,actions,cost_per_action_type}}"
            f"&time_range={{'since':'{since}','until':'{until}'}}"
            f"&sort=insights.ctr_descending"
            f"&limit={limit}"
            f"&access_token={token}"
        )

        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
            if isinstance(data, list):
                data = {"data": data}
            return {
                "period": f"{since} to {until}",
                "top_creatives": data.get("data", []),
                "total": len(data.get("data", [])),
            }

    except Exception as e:
        return {"error": str(e)}


def fatigue_check(days: int = 14) -> dict:
    """Check for creative fatigue (declining CTR over consecutive days)."""
    creds = load_credentials()
    token = creds.get("META_ACCESS_TOKEN")
    account_id = creds.get("META_AD_ACCOUNT_ID")

    if not token or not account_id:
        return {"error": "Credentials not configured. Run: --check-auth"}

    try:
        import urllib.request

        since = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%d")
        until = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        url = (
            f"{BASE_URL}/{account_id}/insights?"
            f"fields=ctr,cpc,spend,impressions"
            f"&time_range={{'since':'{since}','until':'{until}'}}"
            f"&time_increment=1"
            f"&access_token={token}"
        )

        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())
            if isinstance(data, list):
                data = {"data": data}
            daily_data = data.get("data", [])

            # Detect CTR decline
            ctrs = []
            for day in daily_data:
                try:
                    ctrs.append(float(day.get("ctr", 0)))
                except (ValueError, TypeError):
                    pass

            fatigue_detected = False
            decline_days = 0
            if len(ctrs) >= 3:
                for i in range(1, len(ctrs)):
                    if ctrs[i] < ctrs[i-1]:
                        decline_days += 1
                    else:
                        decline_days = 0
                fatigue_detected = decline_days >= 3

            return {
                "period": f"{since} to {until}",
                "daily_ctrs": ctrs,
                "fatigue_detected": fatigue_detected,
                "consecutive_decline_days": decline_days,
                "recommendation": (
                    "Creative fatigue detected! CTR has declined for "
                    f"{decline_days} consecutive days. Recommend refreshing creatives."
                    if fatigue_detected else
                    "No creative fatigue detected. CTR is stable or improving."
                ),
            }

    except Exception as e:
        return {"error": str(e)}


def main():
    parser = argparse.ArgumentParser(description="Meta Ads Manager API Client")
    parser.add_argument("--check-auth", action="store_true", help="Check credential status")
    parser.add_argument("--campaigns", action="store_true", help="Get campaign performance")
    parser.add_argument("--top-creatives", action="store_true", help="Get top performing creatives")
    parser.add_argument("--fatigue-check", action="store_true", help="Check for creative fatigue")
    parser.add_argument("--days", type=int, default=7, help="Lookback period in days")
    parser.add_argument("--limit", type=int, default=10, help="Max results for lists")
    args = parser.parse_args()

    if args.check_auth:
        result = check_auth()
    elif args.campaigns:
        result = get_campaigns(args.days)
    elif args.top_creatives:
        result = get_top_creatives(args.days, args.limit)
    elif args.fatigue_check:
        result = fatigue_check(args.days)
    else:
        parser.print_help()
        return

    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
