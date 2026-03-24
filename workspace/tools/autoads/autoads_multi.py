#!/usr/bin/env python3
import sys; sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))
"""
autoads_multi.py — Multi-Brand Ad + Sales Report → Telegram
Sources: Meta Ads API + Google Sheet (WA sales)
"""

import json, os, urllib.request, urllib.parse, ssl, csv, io
from pathlib import Path
from datetime import datetime

TOKEN = (Path.home() / "Desktop/_WORK/_shared/.meta-token").read_text().strip()
API = "https://graph.facebook.com/v21.0"

TG_BOT = os.environ.get("TG_BOT_TOKEN", "")
TG_CHAT = os.environ.get("TG_CHAT_ID", "")

BRANDS = {
    "pinxin": {
        "emoji": "🌿",
        "display": "PINXIN VEGAN",
        "account": "act_138893238421035",
        "campaigns": {
            "120240872763100006": {"name": "Website", "type": "website"},
            "120240934632520006": {"name": "WhatsApp", "type": "wa"},
            "120240686358240006": {"name": "Retarget", "type": "website"},
        },
        "wa_sheet": {
            "url": "https://docs.google.com/spreadsheets/d/1Wuz9gvmfDVFufgth6cZECuj1N4ZuwDw9HRfbkI6QCnc/gviz/tq?tqx=out:csv&gid=0",
            "date_col": 7,      # "DATE" column (0-indexed)
            "amount_col": 6,    # "Amount" column
        },
        "results_file": Path.home() / "Desktop/_WORK/pinxin/02_strategy/autoads-results.tsv",
    },
    "mirra": {
        "emoji": "🌸",
        "display": "MIRRA EATS",
        "account": "act_830110298602617",
        "campaigns": {
            "120243085821340787": {"name": "Sales EN", "type": "wa"},
            "120235573169200787": {"name": "Scale EN-WA", "type": "wa"},
            "120242910542110787": {"name": "Retarget CN", "type": "wa"},
            "120242895523710787": {"name": "Retarget EN", "type": "wa"},
        },
        "wa_sheet": {
            "url": "https://docs.google.com/spreadsheets/d/1mNP3AAySkP8xzCIbyznm3sqFtFZatSca6wLVnu35Vs0/gviz/tq?tqx=out:csv&gid=82276829",
            "date_col": 1,       # "Date" column
            "amount_col": 13,    # "PAYMENT AMOUNT" column
        },
        "results_file": Path.home() / "Desktop/_WORK/mirra/02_strategy/autoads-results.tsv",
    },
}


def api_get(endpoint, params=None):
    if params is None: params = {}
    params["access_token"] = TOKEN
    qs = urllib.parse.urlencode(params)
    try:
        resp = urllib.request.urlopen(
            urllib.request.Request(f"{API}/{endpoint}?{qs}"), timeout=30)
        return json.loads(resp.read())
    except:
        return {}


def fetch_sheet(config):
    """Parse Google Sheet with specific column positions."""
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        resp = urllib.request.urlopen(config["url"], timeout=15, context=ctx)
        text = resp.read().decode('utf-8')

        reader = csv.reader(io.StringIO(text))
        rows = list(reader)

        date_col = config["date_col"]
        amount_col = config["amount_col"]
        today_short = datetime.now().strftime('%d/%m')

        today_orders = 0
        today_revenue = 0.0
        total_orders = 0
        total_revenue = 0.0

        for row in rows[1:]:  # skip header
            if len(row) <= max(date_col, amount_col):
                continue

            date_str = row[date_col].strip()
            amount_str = row[amount_col].strip()

            if not amount_str:
                continue

            # Clean amount
            try:
                amount = float(amount_str.replace('MYR', '').replace('RM', '').replace(',', '').strip())
            except:
                continue

            if amount <= 0:
                continue

            total_orders += 1
            total_revenue += amount

            if today_short in date_str:
                today_orders += 1
                today_revenue += amount

        return {"today_orders": today_orders, "today_revenue": today_revenue,
                "total_orders": total_orders, "total_revenue": total_revenue}
    except Exception as e:
        return {"today_orders": 0, "today_revenue": 0,
                "total_orders": 0, "total_revenue": 0, "error": str(e)[:50]}


def get_campaign_data(campaign_id, preset="today"):
    data = api_get(f"{campaign_id}/insights", {
        "fields": "spend,impressions,actions,cost_per_action_type,purchase_roas",
        "date_preset": preset,
    })
    if not data.get("data"): return None
    r = data["data"][0]
    spend = float(r.get("spend", 0))
    purchases = clicks = wa = atc = 0
    cpa = None; roas = None; revenue = 0
    for a in r.get("actions", []):
        if a["action_type"] == "purchase": purchases = int(a["value"])
        if a["action_type"] == "link_click": clicks = int(a["value"])
        if a["action_type"] == "add_to_cart": atc = int(a["value"])
        if "messaging_conversation" in a["action_type"]: wa = int(a["value"])
    for c in r.get("cost_per_action_type", []):
        if c["action_type"] == "purchase": cpa = float(c["value"])
    for ro in r.get("purchase_roas", []):
        roas = float(ro["value"]); revenue = spend * roas
    return {"spend": spend, "purchases": purchases, "clicks": clicks,
            "wa": wa, "atc": atc, "cpa": cpa, "roas": roas, "revenue": revenue}


def get_top_bottom_ads(campaign_id, limit=3):
    data = api_get(f"{campaign_id}/insights", {
        "fields": "ad_name,spend,impressions,actions,cost_per_action_type",
        "date_preset": "last_7d", "level": "ad",
        "sort": "spend_descending", "limit": "30",
    })
    ads = []
    for r in data.get("data", []):
        spend = float(r.get("spend", 0))
        if spend < 3: continue
        purchases = wa = atc = 0; cpa = None
        for a in r.get("actions", []):
            if a["action_type"] == "purchase": purchases = int(a["value"])
            if "messaging_conversation" in a["action_type"]: wa = int(a["value"])
            if a["action_type"] == "add_to_cart": atc = int(a["value"])
        for c in r.get("cost_per_action_type", []):
            if c["action_type"] == "purchase": cpa = float(c["value"])
        ads.append({"name": r.get("ad_name", "?"), "spend": spend, "purchases": purchases,
                     "wa": wa, "atc": atc, "cpa": cpa})
    return ads


def build_brand_report(brand_name, config):
    emoji = config["emoji"]
    display = config["display"]
    lines = []
    lines.append(f"")
    lines.append(f"{emoji} ━━━━━━━━━━━━━━━━━━━━")
    lines.append(f"{emoji}  {display}")
    lines.append(f"{emoji} ━━━━━━━━━━━━━━━━━━━━")

    # ── WA SHEET SALES ──
    sheet = {"today_orders": 0, "today_revenue": 0, "total_orders": 0, "total_revenue": 0}
    if config.get("wa_sheet"):
        sheet = fetch_sheet(config["wa_sheet"])

    # ── META ADS ──
    has_campaigns = bool(config.get("campaigns"))
    total_spend = 0
    total_web_revenue = 0
    total_purchases = 0
    total_wa = 0
    campaign_lines = []

    if has_campaigns:
        for cid, cinfo in config["campaigns"].items():
            cname = cinfo["name"]
            ctype = cinfo["type"]
            today = get_campaign_data(cid, "today")
            if not today: continue

            total_spend += today["spend"]
            total_purchases += today["purchases"]
            total_wa += today["wa"]
            total_web_revenue += today["revenue"]

            if ctype == "website":
                cpa_str = f"RM{today['cpa']:.0f}" if today["cpa"] else "—"
                roas_str = f"{today['roas']:.1f}x" if today["roas"] else "—"
                campaign_lines.append(
                    f"   🌐 {cname}: Spent RM{today['spend']:.0f} → {today['purchases']} sales (RM{today['revenue']:.0f}) | CPA {cpa_str} | ROAS {roas_str}")
            elif ctype == "wa":
                cost_wa = f"RM{today['spend']/today['wa']:.0f}" if today["wa"] > 0 else "—"
                campaign_lines.append(
                    f"   💬 {cname}: Spent RM{today['spend']:.0f} → {today['wa']} conversations | {cost_wa}/msg")

    # ── TODAY'S NUMBERS ──
    lines.append("")
    lines.append("💰 TODAY")

    if has_campaigns:
        lines.append(f"   💸 Ad Spend: RM{total_spend:.0f}")
        if total_purchases > 0:
            lines.append(f"   🛒 Website Sales: {total_purchases} orders = RM{total_web_revenue:.0f}")
        lines.append(f"   💬 WA Conversations: {total_wa}")

    if sheet["today_orders"] > 0:
        lines.append(f"   📋 WA Sales (Sheet): {sheet['today_orders']} orders = RM{sheet['today_revenue']:.0f}")
    elif config.get("wa_sheet"):
        lines.append(f"   📋 WA Sales (Sheet): 0 orders today")

    # Combined revenue
    combined_rev = total_web_revenue + sheet.get("today_revenue", 0)
    if combined_rev > 0:
        lines.append(f"   📈 Total Revenue: ~RM{combined_rev:.0f}")
    if total_spend > 0 and combined_rev > 0:
        lines.append(f"   📊 True ROAS: {combined_rev/total_spend:.1f}x")

    # ── CAMPAIGN BREAKDOWN ──
    if campaign_lines:
        lines.append("")
        lines.append("📊 CAMPAIGNS")
        lines.extend(campaign_lines)

    # ── BEST & WORST ADS ──
    if has_campaigns:
        all_ads = []
        for cid in config["campaigns"]:
            all_ads.extend(get_top_bottom_ads(cid))

        converters = sorted([a for a in all_ads if a["purchases"] > 0], key=lambda x: x["cpa"])
        wa_winners = sorted([a for a in all_ads if a["wa"] > 0], key=lambda x: x["spend"]/max(x["wa"],1))
        losers = sorted([a for a in all_ads if a["purchases"] == 0 and a["wa"] == 0 and a["spend"] > 50],
                        key=lambda x: -x["spend"])

        if converters:
            lines.append("")
            lines.append("🏆 BEST SELLING ADS (7-day)")
            for a in converters[:3]:
                lines.append(f"   ⭐ {a['name'][:28]} — RM{a['cpa']:.0f}/sale, {a['purchases']} sold")

        if wa_winners:
            lines.append("")
            lines.append("💬 CHEAPEST WA MESSAGES (7-day)")
            for a in wa_winners[:3]:
                cost = a["spend"] / max(a["wa"], 1)
                lines.append(f"   ✅ {a['name'][:28]} — RM{cost:.0f}/msg, {a['wa']} convos")

        if losers:
            lines.append("")
            lines.append("⚠️ LOSERS (RM50+ spent, 0 results)")
            for a in losers[:3]:
                lines.append(f"   ❌ {a['name'][:28]} — RM{a['spend']:.0f} wasted")

    # ── MONTH TOTAL ──
    if sheet["total_orders"] > 0:
        lines.append("")
        lines.append("📅 MARCH TOTAL (WA Sales)")
        lines.append(f"   {sheet['total_orders']} orders = RM{sheet['total_revenue']:,.0f}")

    return "\n".join(lines)


def send_telegram(text):
    chunks = []
    while len(text) > 4000:
        split = text[:4000].rfind('\n')
        if split < 0: split = 4000
        chunks.append(text[:split])
        text = text[split:]
    chunks.append(text)

    for chunk in chunks:
        data = urllib.parse.urlencode({"chat_id": TG_CHAT, "text": chunk}).encode()
        try:
            urllib.request.urlopen(
                urllib.request.Request(f"https://api.telegram.org/bot{TG_BOT}/sendMessage", data=data), timeout=15)
        except Exception as e:
            print(f"Telegram error: {e}")


def main():
    now = datetime.now().strftime("%d %b %Y, %I:%M %p")
    report = [f"📊 ZENNITH ADS REPORT", f"🕐 {now}"]

    for brand_name, config in BRANDS.items():
        report.append(build_brand_report(brand_name, config))

    report.append("")
    report.append("━━━━━━━━━━━━━━━━━━━━")
    report.append("Next report in 6 hours ⏰")

    full_report = "\n".join(report)
    print(full_report)
    send_telegram(full_report)

    for brand_name, config in BRANDS.items():
        rf = config.get("results_file")
        if rf:
            rf.parent.mkdir(parents=True, exist_ok=True)
            with open(rf, "a") as f:
                f.write(f"\n{'='*40}\n{full_report}\n")

    print(f"\n✓ Sent to Telegram")


if __name__ == "__main__":
    main()
