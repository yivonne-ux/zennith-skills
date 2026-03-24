"""Shopify helper — auto-refreshes token before each API call."""

import json, os, urllib.request, urllib.parse
from pathlib import Path
from datetime import datetime

SHOPS = {
    "pinxin": {
        "store": "pinxin-vegan-cuisine.myshopify.com",
        "client_id": "3f89bbd85529b19710dfe937013d0de6",
        "client_secret": os.environ.get("SHOPIFY_PINXIN_SECRET", ""),  # set in env
        "token_file": Path.home() / "Desktop/_WORK/_shared/.shopify-token-pinxin",
    },
}

def get_token(brand):
    """Get fresh Shopify token (auto-refreshes via client_credentials)."""
    config = SHOPS.get(brand)
    if not config: return None

    # Always refresh — token only lasts 24h
    try:
        data = json.dumps({
            "client_id": config["client_id"],
            "client_secret": config["client_secret"],
            "grant_type": "client_credentials"
        }).encode()
        req = urllib.request.Request(
            f"https://{config['store']}/admin/oauth/access_token",
            data=data, headers={"Content-Type": "application/json"})
        resp = json.loads(urllib.request.urlopen(req, timeout=15).read())
        token = resp.get("access_token")
        if token:
            config["token_file"].write_text(token)
            return token
    except:
        pass

    # Fallback to cached
    if config["token_file"].exists():
        return config["token_file"].read_text().strip()
    return None


def get_orders_today(brand):
    """Get today's Shopify orders."""
    config = SHOPS.get(brand)
    if not config: return None
    token = get_token(brand)
    if not token: return None

    today = datetime.now().strftime("%Y-%m-%d")
    try:
        url = f"https://{config['store']}/admin/api/2024-01/orders.json?status=any&created_at_min={today}T00:00:00Z&limit=50"
        req = urllib.request.Request(url, headers={"X-Shopify-Access-Token": token})
        resp = json.loads(urllib.request.urlopen(req, timeout=15).read())
        orders = resp.get("orders", [])
        total = sum(float(o.get("total_price", 0)) for o in orders)
        return {"orders": len(orders), "revenue": total}
    except:
        return None


def get_orders_month(brand):
    """Get this month's Shopify order count + revenue."""
    config = SHOPS.get(brand)
    if not config: return None
    token = get_token(brand)
    if not token: return None

    month_start = datetime.now().strftime("%Y-%m-01")
    try:
        # Get count
        url = f"https://{config['store']}/admin/api/2024-01/orders/count.json?status=any&created_at_min={month_start}T00:00:00Z"
        req = urllib.request.Request(url, headers={"X-Shopify-Access-Token": token})
        resp = json.loads(urllib.request.urlopen(req, timeout=15).read())
        count = resp.get("count", 0)

        # Get revenue (first 250 orders)
        url2 = f"https://{config['store']}/admin/api/2024-01/orders.json?status=any&created_at_min={month_start}T00:00:00Z&limit=250&fields=total_price"
        req2 = urllib.request.Request(url2, headers={"X-Shopify-Access-Token": token})
        resp2 = json.loads(urllib.request.urlopen(req2, timeout=15).read())
        revenue = sum(float(o.get("total_price", 0)) for o in resp2.get("orders", []))

        return {"orders": count, "revenue": revenue}
    except:
        return None
