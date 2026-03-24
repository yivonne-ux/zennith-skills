#!/usr/bin/env python3
"""Zennith Ads Report — Pinxin + Mirra → Telegram every 6 hours."""
import sys
sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))

import json, os, urllib.request, urllib.parse, ssl, csv, io
from pathlib import Path
from datetime import datetime
from shopify_helper import get_orders_today, get_orders_month

TOKEN = (Path.home() / "Desktop/_WORK/_shared/.meta-token").read_text().strip()
API = "https://graph.facebook.com/v21.0"
TG_BOT = os.environ.get("TG_BOT_TOKEN", "")
TG_CHAT = os.environ.get("TG_CHAT_ID", "")

def api_get(endpoint, params=None):
    if params is None: params = {}
    params["access_token"] = TOKEN
    qs = urllib.parse.urlencode(params)
    try:
        resp = urllib.request.urlopen(urllib.request.Request(f"{API}/{endpoint}?{qs}"), timeout=30)
        return json.loads(resp.read())
    except: return {}

def fetch_sheet(config):
    try:
        ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
        resp = urllib.request.urlopen(config["url"], timeout=15, context=ctx)
        reader = csv.reader(io.StringIO(resp.read().decode('utf-8')))
        rows = list(reader)
        dc, ac = config["date_col"], config["amount_col"]
        today_short = datetime.now().strftime('%d/%m')
        to, tr, ao, ar = 0, 0.0, 0, 0.0
        for row in rows[1:]:
            if len(row) <= max(dc, ac): continue
            amt_str = row[ac].strip()
            if not amt_str: continue
            try: amt = float(amt_str.replace('MYR','').replace('RM','').replace(',','').strip())
            except: continue
            if amt <= 0: continue
            ao += 1; ar += amt
            if today_short in row[dc].strip(): to += 1; tr += amt
        return {"today_orders": to, "today_revenue": tr, "total_orders": ao, "total_revenue": ar}
    except: return {"today_orders": 0, "today_revenue": 0, "total_orders": 0, "total_revenue": 0}

def get_campaign(cid, preset="today"):
    d = api_get(f"{cid}/insights", {"fields": "spend,actions,cost_per_action_type,purchase_roas", "date_preset": preset})
    if not d.get("data"): return None
    r = d["data"][0]; s = float(r.get("spend",0)); p=cl=wa=0; cpa=roas=None; rev=0
    for a in r.get("actions",[]):
        if a["action_type"]=="purchase": p=int(a["value"])
        if "messaging_conversation" in a["action_type"]: wa=int(a["value"])
    for c in r.get("cost_per_action_type",[]): 
        if c["action_type"]=="purchase": cpa=float(c["value"])
    for ro in r.get("purchase_roas",[]): roas=float(ro["value"]); rev=s*roas
    return {"spend":s,"purchases":p,"wa":wa,"cpa":cpa,"roas":roas,"revenue":rev}

def get_top_ads(cid):
    d = api_get(f"{cid}/insights", {"fields":"ad_name,spend,actions,cost_per_action_type","date_preset":"last_7d","level":"ad","sort":"spend_descending","limit":"20"})
    ads = []
    for r in d.get("data",[]):
        s=float(r.get("spend",0))
        if s<3: continue
        p=wa=0; cpa=None
        for a in r.get("actions",[]): 
            if a["action_type"]=="purchase": p=int(a["value"])
            if "messaging_conversation" in a["action_type"]: wa=int(a["value"])
        for c in r.get("cost_per_action_type",[]): 
            if c["action_type"]=="purchase": cpa=float(c["value"])
        ads.append({"name":r.get("ad_name","?"),"spend":s,"purchases":p,"wa":wa,"cpa":cpa})
    return ads

def send_tg(text):
    chunks = []
    while len(text) > 4000:
        sp = text[:4000].rfind('\n')
        if sp < 0: sp = 4000
        chunks.append(text[:sp]); text = text[sp:]
    chunks.append(text)
    for chunk in chunks:
        data = urllib.parse.urlencode({"chat_id": TG_CHAT, "text": chunk}).encode()
        try: urllib.request.urlopen(urllib.request.Request(f"https://api.telegram.org/bot{TG_BOT}/sendMessage", data=data), timeout=15)
        except: pass

now = datetime.now().strftime("%d %b %Y, %I:%M %p")
lines = [f"📊 ZENNITH ADS REPORT", f"🕐 {now}", ""]

# ═══ PINXIN ═══
lines.append("🌿 ━━━━━━━━━━━━━━━━━━━━")
lines.append("🌿  PINXIN VEGAN")
lines.append("🌿 ━━━━━━━━━━━━━━━━━━━━")
px_c = {"120240872763100006":("Website","web"),"120240934632520006":("WhatsApp","wa"),"120240686358240006":("Retarget","web")}
ts=tp=twa=0; trev=0; cl=[]
for cid,(cn,ct) in px_c.items():
    t = get_campaign(cid,"today")
    if not t: continue
    ts+=t["spend"]; tp+=t["purchases"]; twa+=t["wa"]; trev+=t["revenue"]
    if ct=="web":
        cpa=f"RM{t['cpa']:.0f}" if t["cpa"] else "—"; roas=f"{t['roas']:.1f}x" if t["roas"] else "—"
        cl.append(f"   🌐 {cn}: Spent RM{t['spend']:.0f} → {t['purchases']} sales (RM{t['revenue']:.0f}) | CPA {cpa} | ROAS {roas}")
    else:
        cw=f"RM{t['spend']/t['wa']:.0f}" if t["wa"]>0 else "—"
        cl.append(f"   💬 {cn}: Spent RM{t['spend']:.0f} → {t['wa']} conversations | {cw}/msg")
st = get_orders_today("pinxin"); sm = get_orders_month("pinxin")
ws = fetch_sheet({"url":"https://docs.google.com/spreadsheets/d/1Wuz9gvmfDVFufgth6cZECuj1N4ZuwDw9HRfbkI6QCnc/gviz/tq?tqx=out:csv&gid=0","date_col":7,"amount_col":6})
lines.append(""); lines.append("💰 TODAY")
lines.append(f"   💸 Ad Spend: RM{ts:.0f}")
if st: lines.append(f"   🛍️ Shopify Sales: {st['orders']} orders = RM{st['revenue']:,.0f}")
lines.append(f"   💬 WA Conversations: {twa}")
if ws["today_orders"]>0: lines.append(f"   📋 WA Orders (Sheet): {ws['today_orders']} orders = RM{ws['today_revenue']:,.0f}")
combined = (st["revenue"] if st else trev) + ws["today_revenue"]
if ts>0: lines.append(f"   📈 Total Revenue: ~RM{combined:,.0f}"); lines.append(f"   📊 True ROAS: {combined/ts:.1f}x")
if cl: lines.append(""); lines.append("📊 CAMPAIGNS"); lines.extend(cl)
aa = []
for cid in px_c: aa.extend(get_top_ads(cid))
cv = sorted([a for a in aa if a["purchases"]>0], key=lambda x:x["cpa"])
ww = sorted([a for a in aa if a["wa"]>0], key=lambda x:x["spend"]/max(x["wa"],1))
lo = sorted([a for a in aa if a["purchases"]==0 and a["wa"]==0 and a["spend"]>50], key=lambda x:-x["spend"])
if cv: lines.append(""); lines.append("🏆 BEST SELLING ADS (7-day)")
for a in cv[:3]: lines.append(f"   ⭐ {a['name'][:28]} — RM{a['cpa']:.0f}/sale, {a['purchases']} sold")
if ww: lines.append(""); lines.append("💬 CHEAPEST WA MESSAGES (7-day)")
for a in ww[:3]: lines.append(f"   ✅ {a['name'][:28]} — RM{a['spend']/max(a['wa'],1):.0f}/msg, {a['wa']} convos")
if lo: lines.append(""); lines.append("⚠️ LOSERS (RM50+, 0 results)")
for a in lo[:3]: lines.append(f"   ❌ {a['name'][:28]} — RM{a['spend']:.0f} wasted")
lines.append(""); lines.append("📅 MARCH TOTAL")
if sm: lines.append(f"   🛍️ Shopify: {sm['orders']} orders = RM{sm['revenue']:,.0f}")
if ws["total_orders"]>0: lines.append(f"   📋 WA Sheet: {ws['total_orders']} orders = RM{ws['total_revenue']:,.0f}")
if sm and ws["total_orders"]>0: lines.append(f"   💰 Combined: RM{sm['revenue']+ws['total_revenue']:,.0f}")

# ═══ MIRRA ═══
lines.append(""); lines.append("🌸 ━━━━━━━━━━━━━━━━━━━━"); lines.append("🌸  MIRRA EATS"); lines.append("🌸 ━━━━━━━━━━━━━━━━━━━━")
mr_c = {"120243085821340787":("Sales EN","wa"),"120235573169200787":("Scale EN-WA","wa"),"120242910542110787":("Retarget CN","wa"),"120242895523710787":("Retarget EN","wa")}
ms=mwa=0; mcl=[]
for cid,(cn,ct) in mr_c.items():
    t = get_campaign(cid,"today")
    if not t: continue
    ms+=t["spend"]; mwa+=t["wa"]
    cw=f"RM{t['spend']/t['wa']:.0f}" if t["wa"]>0 else "—"
    mcl.append(f"   💬 {cn}: Spent RM{t['spend']:.0f} → {t['wa']} convos | {cw}/msg")
mws = fetch_sheet({"url":"https://docs.google.com/spreadsheets/d/1mNP3AAySkP8xzCIbyznm3sqFtFZatSca6wLVnu35Vs0/gviz/tq?tqx=out:csv&gid=82276829","date_col":1,"amount_col":13})
lines.append(""); lines.append("💰 TODAY")
lines.append(f"   💸 Ad Spend: RM{ms:.0f}"); lines.append(f"   💬 WA Conversations: {mwa}")
if mws["today_orders"]>0: lines.append(f"   📋 WA Orders (Sheet): {mws['today_orders']} orders = RM{mws['today_revenue']:,.0f}")
if ms>0 and mws["today_revenue"]>0: lines.append(f"   📊 True ROAS: {mws['today_revenue']/ms:.1f}x")
if mcl: lines.append(""); lines.append("📊 CAMPAIGNS"); lines.extend(mcl)
ma = []
for cid in mr_c: ma.extend(get_top_ads(cid))
mww = sorted([a for a in ma if a["wa"]>0], key=lambda x:x["spend"]/max(x["wa"],1))
if mww: lines.append(""); lines.append("💬 CHEAPEST WA MESSAGES (7-day)")
for a in mww[:3]: lines.append(f"   ✅ {a['name'][:28]} — RM{a['spend']/max(a['wa'],1):.0f}/msg, {a['wa']} convos")
if mws["total_orders"]>0: lines.append(""); lines.append("📅 MARCH TOTAL"); lines.append(f"   📋 WA Sheet: {mws['total_orders']} orders = RM{mws['total_revenue']:,.0f}")

lines.append(""); lines.append("━━━━━━━━━━━━━━━━━━━━"); lines.append("Next report in 6 hours ⏰")

full = "\n".join(lines)
print(full)
send_tg(full)
print("\n✓ Sent to Telegram")
