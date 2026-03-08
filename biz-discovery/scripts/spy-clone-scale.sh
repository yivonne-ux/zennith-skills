#!/usr/bin/env bash
# spy-clone-scale.sh — Ali Akbar's Exact Spy-Clone-Scale Method for GAIA OS
#
# THE REAL METHOD (not generic trend scanning):
#   1. SPY:    Find stores spending big on ads (100+ active ads = proven profitable)
#   2. REVERSE: Calculate their revenue, map their funnel, find their supplier
#   3. SCORE:  Ali Akbar 90% checklist — 7 criteria must pass
#   4. CLONE:  Blueprint the business (new brand, same model, AI-generated assets)
#   5. SCALE:  $20-50/day test → kill losers day 3 → scale winners
#
# Also: Information Arbitrage — find what's crushing on TikTok Shop,
#        run it as Facebook ads to Shopify (different platform = low competition)
#
# Usage:
#   spy-clone-scale.sh spy "skincare"                    # Spy Meta Ad Library for niche
#   spy-clone-scale.sh spy-tiktok "health supplement"    # Spy TikTok for trending products
#   spy-clone-scale.sh reverse "https://store-url.com"   # Reverse-engineer a store
#   spy-clone-scale.sh checklist <opportunity-id>        # Run 90% success checklist
#   spy-clone-scale.sh arbitrage                         # Find TikTok→Facebook arbitrage opportunities
#   spy-clone-scale.sh blueprint <opportunity-id>        # Full clone blueprint
#   spy-clone-scale.sh pipeline                          # Run full spy→score→alert pipeline

set -euo pipefail

OPENCLAW="$HOME/.openclaw"
VAULT_DB="$OPENCLAW/workspace/vault/vault.db"
DATA_DIR="$OPENCLAW/workspace/data/biz-opportunities"
LOG_FILE="$OPENCLAW/logs/biz-discovery.log"
REACH="$OPENCLAW/skills/agent-reach/scripts"

mkdir -p "$DATA_DIR" "$(dirname "$LOG_FILE")"

# Load API keys and export for Python subprocesses
if [[ -f "$OPENCLAW/.env" ]]; then
    set -a
    source "$OPENCLAW/.env" 2>/dev/null || true
    set +a
fi

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# ══════════════════════════════════════════════════════════════════
# STEP 1: SPY — Find proven profitable stores via ad intelligence
# ══════════════════════════════════════════════════════════════════

cmd_spy() {
    local niche="${1:?Niche keyword required (e.g. 'skincare', 'supplement', 'fitness')}"
    log "=== SPY: Meta Ad Library for '$niche' ==="

    python3 << PYEOF
import json, urllib.request, os, time
from datetime import datetime

niche = "$niche"
data_dir = "$DATA_DIR"
vault_db = "$VAULT_DB"

# Method 1: Meta Ad Library (free, public API)
# Search for ads in this niche, filter by active + long-running
print(f"\\n🔍 Searching Meta Ad Library for: {niche}")
print("=" * 60)

# Use Meta Ad Library API (public access)
# https://www.facebook.com/ads/library/api/
meta_token = os.environ.get("META_ACCESS_TOKEN", "")

results = []

if meta_token:
    try:
        search_url = f"https://graph.facebook.com/v21.0/ads_archive?search_terms={niche}&ad_reached_countries=US,GB,MY&ad_active_status=active&fields=id,page_name,ad_delivery_start_time,ad_creative_bodies,ad_snapshot_url,publisher_platforms&limit=25&access_token={meta_token}"
        req = urllib.request.Request(search_url)
        resp = urllib.request.urlopen(req, timeout=30)
        data = json.loads(resp.read().decode())

        ads = data.get("data", [])
        print(f"Found {len(ads)} active ads\\n")

        # Group by page (store) to count active ads per store
        stores = {}
        for ad in ads:
            page = ad.get("page_name", "unknown")
            if page not in stores:
                stores[page] = {"page_name": page, "ads": [], "earliest_start": None}
            stores[page]["ads"].append(ad)
            start = ad.get("ad_delivery_start_time", "")
            if start and (not stores[page]["earliest_start"] or start < stores[page]["earliest_start"]):
                stores[page]["earliest_start"] = start

        # Sort by ad count (most ads = most likely profitable)
        ranked = sorted(stores.values(), key=lambda x: len(x["ads"]), reverse=True)

        for store in ranked[:10]:
            ad_count = len(store["ads"])
            earliest = store.get("earliest_start", "?")[:10]
            # Calculate days running
            days = 0
            try:
                start_date = datetime.strptime(earliest, "%Y-%m-%d")
                days = (datetime.now() - start_date).days
            except:
                pass

            signal = ""
            if ad_count >= 100: signal = "🔥 HIGHLY VALIDATED"
            elif ad_count >= 50: signal = "✅ VALIDATED"
            elif ad_count >= 20: signal = "⚠️ PROMISING"
            else: signal = "📊 EARLY"

            print(f"{signal}")
            print(f"  Store:      {store['page_name']}")
            print(f"  Active ads: {ad_count}")
            print(f"  Running:    {days} days (since {earliest})")
            if store["ads"][0].get("ad_creative_bodies"):
                body = store["ads"][0]["ad_creative_bodies"][0][:150]
                print(f"  Ad copy:    {body}...")
            print()

            # Save opportunity
            opp = {
                "id": f"spy-{niche.replace(' ','-')}-{store['page_name'][:20].replace(' ','-').lower()}-{datetime.now().strftime('%Y%m%d')}",
                "source": "meta-ad-library-spy",
                "method": "ali-akbar-spy",
                "niche": niche,
                "store_name": store["page_name"],
                "active_ad_count": ad_count,
                "days_running": days,
                "earliest_ad": earliest,
                "ad_sample": store["ads"][0].get("ad_creative_bodies", [""])[0][:300] if store["ads"][0].get("ad_creative_bodies") else "",
                "snapshot_url": store["ads"][0].get("ad_snapshot_url", ""),
                "signal": signal.split(" ", 1)[-1] if signal else "",
                "status": "spied",
                "discovered_at": datetime.now().isoformat()
            }
            results.append(opp)

    except Exception as e:
        print(f"Meta Ad Library error: {e}")
        print("Tip: Ensure META_ACCESS_TOKEN is set in .env")
else:
    print("⚠️  META_ACCESS_TOKEN not set — using manual method instead")
    print(f"\\nManual spy steps for '{niche}':")
    print(f"  1. Go to: https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=US&q={niche.replace(' ', '%20')}")
    print(f"  2. Filter: Active ads only")
    print(f"  3. Look for: Stores with MANY ads (50+) running 30+ days")
    print(f"  4. Click store name → see all their ads → count them")
    print(f"  5. Run: spy-clone-scale.sh reverse 'https://their-store.com'")
    print()

# Method 2: Jina Reader scrape of free ad spy sources
print("\\n📡 Scraping free ad intelligence sources...")
try:
    # Scrape Facebook Ad Library search results page
    url = f"https://r.jina.ai/https://www.facebook.com/ads/library/?active_status=active&ad_type=all&country=US&q={niche.replace(' ', '%20')}"
    req = urllib.request.Request(url, headers={"Accept": "text/plain"})
    resp = urllib.request.urlopen(req, timeout=20)
    content = resp.read().decode()[:3000]
    print(f"  Ad Library page scraped ({len(content)} chars)")
    # Save raw for Athena to analyze
    with open(f"{data_dir}/spy-raw-{niche.replace(' ','-')}-{datetime.now().strftime('%Y%m%d')}.txt", "w") as f:
        f.write(content)
except Exception as e:
    print(f"  Scrape failed: {e}")

# Save to vault.db
if results:
    import sqlite3
    db = sqlite3.connect(vault_db)
    for opp in results:
        try:
            db.execute(
                "INSERT INTO vault (source_ref, text, source_type, brand, agent, created_at) VALUES (?, ?, 'biz-opportunity', 'gaia-os', 'artemis', datetime('now'))",
                (opp["id"], json.dumps(opp))
            )
        except: pass
    db.commit()
    db.close()
    print(f"\\n💾 Saved {len(results)} opportunities to vault.db")

print(f"\\n📋 Next: spy-clone-scale.sh reverse '<store-url>' to analyze top stores")
PYEOF
}

# ══════════════════════════════════════════════════════════════════
# STEP 1b: SPY TIKTOK — Information Arbitrage method
# ══════════════════════════════════════════════════════════════════

cmd_spy_tiktok() {
    local niche="${1:?Niche keyword required}"
    log "=== SPY TIKTOK: '$niche' (Information Arbitrage) ==="

    echo "🎵 TikTok → Facebook Arbitrage Method"
    echo "  Find products crushing on TikTok Shop → run as FB ads to your Shopify"
    echo "  Different platform = different audience = low competition"
    echo ""

    # Use TikTok Creative Center skill if available
    if [[ -x "$OPENCLAW/skills/tiktok-trends/scripts/tiktok-trends.sh" ]]; then
        echo "Scanning TikTok Creative Center for '$niche'..."
        bash "$OPENCLAW/skills/tiktok-trends/scripts/tiktok-trends.sh" top-ads --keyword "$niche" --region US --limit 10 2>/dev/null || true
    fi

    # Scrape TikTok Shop trending via Jina
    echo ""
    echo "📡 Checking TikTok Shop trending..."
    bash "$REACH/web-read.sh" "https://shop.tiktok.com/search?q=${niche// /%20}" 2>/dev/null | head -30 || echo "  TikTok Shop scrape needs PinchTab (JS-heavy site)"

    echo ""
    echo "📋 Arbitrage steps:"
    echo "  1. Find top TikTok Shop products in '$niche'"
    echo "  2. Download affiliate video content (yt-dlp or save)"
    echo "  3. Create Shopify funnel (landing → order bump → upsell)"
    echo "  4. Run TikTok videos as Facebook ads → your Shopify"
    echo "  5. Test at \$20-50/day → kill losers day 3 → scale winners"
}

# ══════════════════════════════════════════════════════════════════
# STEP 2: REVERSE-ENGINEER — Analyze a proven store
# ══════════════════════════════════════════════════════════════════

cmd_reverse() {
    local url="${1:?Store URL required}"
    log "=== REVERSE-ENGINEER: $url ==="

    TARGET_URL="$url" python3 << 'PYEOF'
import json, os, time
from datetime import datetime

url = os.environ["TARGET_URL"]
data_dir = os.environ.get("DATA_DIR", os.path.expanduser("~/.openclaw/workspace/data/biz-opportunities"))
vault_db = os.environ.get("VAULT_DB", os.path.expanduser("~/.openclaw/workspace/vault/vault.db"))

print(f"🔍 Reverse-engineering: {url}")
print("=" * 60)

analysis = {
    "url": url,
    "analyzed_at": datetime.now().isoformat(),
    "traffic": {},
    "funnel": {},
    "pricing": {},
    "content": {}
}

# 1. Traffic analysis via SimilarWeb (anti-bot scraping via Scrapling)
print("\n📊 Traffic Analysis...")
try:
    import subprocess, urllib.request
    domain = url.replace("https://", "").replace("http://", "").split("/")[0]

    # Try Scrapling first (anti-bot), fall back to Jina
    scrapling_sh = os.path.expanduser("~/.openclaw/skills/agent-reach/scripts/scrapling-fetch.sh")
    content = ""
    try:
        result = subprocess.run(["bash", scrapling_sh, "fetch", f"https://www.similarweb.com/website/{domain}/"],
            capture_output=True, text=True, timeout=30)
        content = result.stdout[:5000]
    except:
        pass

    if not content or len(content) < 100:
        # Fallback to Jina Reader
        sw_url = f"https://r.jina.ai/https://www.similarweb.com/website/{domain}/"
        req = urllib.request.Request(sw_url, headers={"Accept": "text/plain"})
        resp = urllib.request.urlopen(req, timeout=20)
        content = resp.read().decode()[:5000]

    # Extract key metrics from text
    import re
    visitors_match = re.search(r'(\d+[\d,.]*[KMB]?)\s*(monthly visits|total visits)', content, re.I)
    if visitors_match:
        visitors = visitors_match.group(1)
        print(f"  Monthly visitors: ~{visitors}")
        analysis["traffic"]["monthly_visitors"] = visitors
    else:
        print("  Monthly visitors: (check manually on SimilarWeb)")

    bounce_match = re.search(r'(\d+\.?\d*%)\s*bounce rate', content, re.I)
    if bounce_match:
        print(f"  Bounce rate: {bounce_match.group(1)}")
        analysis["traffic"]["bounce_rate"] = bounce_match.group(1)

    time_match = re.search(r'(\d+:\d+)\s*(avg|average)?\s*visit duration', content, re.I)
    if time_match:
        print(f"  Avg visit duration: {time_match.group(1)}")
        analysis["traffic"]["avg_duration"] = time_match.group(1)

    with open(f"{data_dir}/reverse-traffic-{domain}-{datetime.now().strftime('%Y%m%d')}.txt", "w") as f:
        f.write(content)

except Exception as e:
    print(f"  SimilarWeb scrape error: {e}")
    print(f"  Manual: https://www.similarweb.com/website/{domain}/")

# 2. Store/funnel analysis (scrape the actual store)
print("\n🏪 Store & Funnel Analysis...")
try:
    import subprocess
    scrapling_sh = os.path.expanduser("~/.openclaw/skills/agent-reach/scripts/scrapling-fetch.sh")
    content = ""
    try:
        result = subprocess.run(["bash", scrapling_sh, "fetch", url],
            capture_output=True, text=True, timeout=30)
        content = result.stdout[:8000]
    except:
        pass

    if not content or len(content) < 100:
        store_url = f"https://r.jina.ai/{url}"
        req = urllib.request.Request(store_url, headers={"Accept": "text/plain"})
        resp = urllib.request.urlopen(req, timeout=20)
        content = resp.read().decode()[:8000]

    # Detect funnel type
    funnel_signals = {
        "single_product": any(kw in content.lower() for kw in ["buy now", "add to cart", "order now", "get yours"]),
        "has_upsell": any(kw in content.lower() for kw in ["upgrade", "bundle", "save more", "special offer"]),
        "has_subscription": any(kw in content.lower() for kw in ["subscribe", "monthly", "auto-ship", "recurring"]),
        "has_order_bump": any(kw in content.lower() for kw in ["add this", "one-time offer", "would you like"]),
        "collects_email": any(kw in content.lower() for kw in ["email", "newsletter", "sign up", "subscribe"]),
        "has_reviews": any(kw in content.lower() for kw in ["review", "★", "star", "testimonial", "verified"]),
        "has_urgency": any(kw in content.lower() for kw in ["limited", "only", "hurry", "ending soon", "stock"]),
    }
    analysis["funnel"] = funnel_signals

    for signal, present in funnel_signals.items():
        print(f"  {'✅' if present else '❌'} {signal.replace('_', ' ').title()}")

    # Extract pricing
    import re
    prices = re.findall(r'\$(\d+\.?\d{0,2})', content)
    if prices:
        prices_float = [float(p) for p in prices]
        analysis["pricing"]["prices_found"] = prices
        analysis["pricing"]["likely_aov"] = max(prices_float)
        print(f"\\n  Prices found: {', '.join(['$'+p for p in prices[:5]])}")
        print(f"  Likely AOV: ${max(prices_float):.2f}")

    with open(f"{data_dir}/reverse-store-{datetime.now().strftime('%Y%m%d')}.txt", "w") as f:
        f.write(content)

except Exception as e:
    print(f"  Store scrape error: {e}")

# 3. Revenue calculation (Ali Akbar formula)
print("\n💰 Revenue Estimation (Ali Akbar Formula)...")
print("  Monthly Visitors × 3% Conversion × AOV = Revenue")
visitors_str = analysis.get("traffic", {}).get("monthly_visitors", "")
aov = analysis.get("pricing", {}).get("likely_aov", 0)
if visitors_str and aov:
    # Parse visitor count
    visitors_str = visitors_str.upper().replace(",", "")
    multiplier = 1
    if "K" in visitors_str: multiplier = 1000
    elif "M" in visitors_str: multiplier = 1000000
    try:
        visitors = float(visitors_str.replace("K","").replace("M","").replace("B","")) * multiplier
        revenue = visitors * 0.03 * aov
        your_share = revenue * 0.10  # Capture 10% of market
        print(f"  Estimated store revenue: ${revenue:,.0f}/mo")
        print(f"  Your 10% capture target: ${your_share:,.0f}/mo")
        analysis["revenue_estimate"] = revenue
        analysis["your_target"] = your_share
    except:
        print("  Could not calculate — check SimilarWeb manually")
else:
    print("  Need traffic data + pricing to calculate")
    print("  Check: https://www.similarweb.com/website/DOMAIN/")

# Save analysis
import sqlite3
analysis_id = f"reverse-{url.replace('https://','').replace('http://','').split('/')[0]}-{datetime.now().strftime('%Y%m%d')}"
db = sqlite3.connect(vault_db)
db.execute(
    "INSERT INTO vault (source_ref, text, source_type, brand, agent, created_at) VALUES (?, ?, 'biz-opportunity', 'gaia-os', 'athena', datetime('now'))",
    (analysis_id, json.dumps(analysis))
)
db.commit()
db.close()

print(f"\\n💾 Saved to vault.db as '{analysis_id}'")
print(f"\\n📋 Next: spy-clone-scale.sh checklist '{analysis_id}'")
PYEOF
}

# ══════════════════════════════════════════════════════════════════
# STEP 3: ALI AKBAR 90% SUCCESS CHECKLIST
# ══════════════════════════════════════════════════════════════════

cmd_checklist() {
    local opp_id="${1:?Opportunity ID required}"
    log "=== 90% CHECKLIST: $opp_id ==="

    python3 << PYEOF
import json, sqlite3

db = sqlite3.connect("$VAULT_DB")
row = db.execute("SELECT text FROM vault WHERE source_ref = ? AND source_type = 'biz-opportunity'", ("$opp_id",)).fetchone()
if not row:
    print(f"ERROR: '{opp_id}' not found. Run: spy-clone-scale.sh spy '<niche>' first")
    raise SystemExit(1)

opp = json.loads(row[0])
print("=" * 60)
print("ALI AKBAR 90% SUCCESS CHECKLIST")
print("=" * 60)
name = opp.get("store_name", opp.get("url", opp_id))
print(f"Store: {name}")
print()

checks = {}

# 1. High active ad count (50+)
ad_count = opp.get("active_ad_count", 0)
checks["1_high_ad_count_50plus"] = ad_count >= 50
print(f"{'✅' if checks['1_high_ad_count_50plus'] else '❌'} 1. High active ad count: {ad_count} {'(50+ needed)' if ad_count < 50 else '🔥'}")

# 2. Single product focus
funnel = opp.get("funnel", {})
single = funnel.get("single_product", opp.get("method") == "ali-akbar-spy")
checks["2_single_product_focus"] = single
print(f"{'✅' if single else '❌'} 2. Single-product focus (not general store)")

# 3. Evergreen ads running 3+ months
days = opp.get("days_running", 0)
checks["3_evergreen_90plus_days"] = days >= 90
print(f"{'✅' if checks['3_evergreen_90plus_days'] else '❌'} 3. Evergreen ads running: {days} days {'(90+ needed)' if days < 90 else '🔥'}")

# 4. Simple checkout funnel
has_funnel = funnel.get("single_product", False) or opp.get("method") == "ali-akbar-spy"
checks["4_simple_checkout"] = has_funnel
print(f"{'✅' if has_funnel else '❌'} 4. Simple checkout (single-page funnel)")

# 5. Good cost-to-price ratio (5x+ markup)
pricing = opp.get("pricing", {})
aov = pricing.get("likely_aov", 0)
checks["5_good_markup_5x"] = aov >= 25  # Assume $5 product cost, need $25+ retail
print(f"{'✅' if checks['5_good_markup_5x'] else '❌'} 5. 5x+ markup potential (AOV: \${aov:.0f})")

# 6. Available creative content
checks["6_creative_content_available"] = bool(opp.get("ad_sample") or opp.get("snapshot_url"))
print(f"{'✅' if checks['6_creative_content_available'] else '❌'} 6. Creative content available on social")

# 7. Supplier sourcing verified
checks["7_supplier_verified"] = False  # Always manual
print(f"❌ 7. Supplier sourcing verified (manual step — check AliExpress/CJ)")

passed = sum(1 for v in checks.values() if v)
total = len(checks)

print()
print(f"SCORE: {passed}/{total} ({passed/total*100:.0f}%)")
if passed >= 5:
    print("🟢 STRONG CANDIDATE — proceed to blueprint")
elif passed >= 3:
    print("🟡 MODERATE — needs more validation")
else:
    print("🔴 WEAK — skip or dig deeper")

# Save checklist result
opp["checklist"] = checks
opp["checklist_score"] = passed
opp["checklist_total"] = total
opp["status"] = "checked"
db.execute("UPDATE vault SET text = ? WHERE source_ref = ? AND source_type = 'biz-opportunity'", (json.dumps(opp), "$opp_id"))
db.commit()
db.close()

if passed >= 5:
    print(f"\\n📋 Next: spy-clone-scale.sh blueprint '$opp_id'")
PYEOF
}

# ══════════════════════════════════════════════════════════════════
# STEP 4: BLUEPRINT — Clone plan with GAIA agents
# ══════════════════════════════════════════════════════════════════

cmd_blueprint() {
    local opp_id="${1:?Opportunity ID required}"
    log "=== BLUEPRINT: $opp_id ==="

    python3 << PYEOF
import json, sqlite3

db = sqlite3.connect("$VAULT_DB")
row = db.execute("SELECT text FROM vault WHERE source_ref = ? AND source_type = 'biz-opportunity'", ("$opp_id",)).fetchone()
if not row:
    print(f"ERROR: '{opp_id}' not found")
    raise SystemExit(1)

opp = json.loads(row[0])
name = opp.get("store_name", opp.get("url", opp_id))

print("=" * 60)
print(f"CLONE BLUEPRINT: {name}")
print("=" * 60)

print(f"""
🏗️ BUSINESS CLONE PLAN
{'─' * 40}

1. PRODUCT
   Original: {name}
   Your version: [NEW BRAND NAME] — same category, fresh positioning
   Supplier: Check AliExpress, CJ Dropshipping, or create digital version

2. FUNNEL (Ali Akbar Architecture)
   Page 1: Landing page / opt-in (collect email BEFORE purchase)
   Page 2: Order form + order bump (+15-30% AOV)
   Page 3: Post-purchase upsell 1
   Page 4: Post-purchase upsell 2
   Page 5: Thank you + subscription offer (maximize LTV)

3. AD CREATIVES (Seena Rez Formula)
   Hook (0-1s): Harmonic Trio — Curiosity + Relevance + Urgency
   Tension (2-4s): Problem agitation
   Payoff (5-8s): Product reveal + transformation
   → Generate 10 hooks, test 3, scale winner

4. LAUNCH SEQUENCE
   Day 1-3: $20-50/day test budget, 3-5 ad sets
   Day 4: Kill losers (CTR < 1%, no purchases)
   Day 5-7: Double budget on winners
   Day 8+: Scale with lookalike audiences

5. GAIA AGENT ASSIGNMENTS
   Dreami → Write 10 ad hooks (3-Second Rule + Harmonic Trio)
   Iris → Generate video ad creatives (Kling 3.0 / NanoBanana)
   Hermes → Set up Shopify funnel + pricing
   Taoz → Build landing page + email flow
   Artemis → Monitor competitor ad changes daily
   Athena → Track ROAS, recommend scaling decisions
   Argus → QA: test checkout flow, verify fulfillment
""")

# Save blueprint
blueprint = {
    "opp_id": "$opp_id",
    "store": name,
    "blueprint_at": __import__("datetime").datetime.now().isoformat(),
    "stages": ["product_sourcing", "funnel_build", "creative_gen", "ad_launch", "scale"],
    "agents": {
        "dreami": "Write 10 ad hooks with Harmonic Trio formula",
        "iris": "Generate video ad creatives",
        "hermes": "Shopify funnel + pricing strategy",
        "taoz": "Landing page + email automation",
        "artemis": "Daily competitor monitoring",
        "athena": "ROAS tracking + scaling decisions",
        "argus": "QA checkout + fulfillment"
    }
}
db.execute(
    "INSERT INTO vault (source_ref, text, source_type, brand, agent, created_at) VALUES (?, ?, 'biz-blueprint', 'gaia-os', 'dreami', datetime('now'))",
    (f"bp-$opp_id", json.dumps(blueprint))
)

opp["status"] = "blueprinted"
db.execute("UPDATE vault SET text = ? WHERE source_ref = ? AND source_type = 'biz-opportunity'", (json.dumps(opp), "$opp_id"))
db.commit()
db.close()

print("💾 Blueprint saved to vault.db")
print("\\n📋 Next steps (dispatch to agents):")
print("  Dreami: 'Write 10 hooks for [product] using Harmonic Trio'")
print("  Iris: 'Create 3 video ad creatives for [product]'")
print("  Hermes: 'Set up Shopify funnel for [product] at \$XX price'")
PYEOF
}

# ══════════════════════════════════════════════════════════════════
# PIPELINE: Full automated run
# ══════════════════════════════════════════════════════════════════

cmd_pipeline() {
    log "=== FULL SPY-CLONE-SCALE PIPELINE ==="

    # Scan multiple niches
    local niches=("skincare" "supplement" "fitness" "kitchen gadget" "pet product")
    for niche in "${niches[@]}"; do
        log "Spying niche: $niche"
        cmd_spy "$niche" 2>&1 | tail -5
        sleep 2
    done

    # Rank results
    bash "$OPENCLAW/skills/biz-discovery/scripts/biz-scout.sh" rank 2>&1

    log "Pipeline complete. Run 'biz-scout.sh alert' to send top opportunities to Jenn"
}

case "${1:-help}" in
    spy)        cmd_spy "${2:-}" ;;
    spy-tiktok) cmd_spy_tiktok "${2:-}" ;;
    reverse)    cmd_reverse "${2:-}" ;;
    checklist)  cmd_checklist "${2:-}" ;;
    blueprint)  cmd_blueprint "${2:-}" ;;
    arbitrage)  cmd_spy_tiktok "${2:-trending}" ;;
    pipeline)   cmd_pipeline ;;
    help|*)
        echo "Spy-Clone-Scale — Ali Akbar Method for GAIA OS"
        echo ""
        echo "THE FLOW:"
        echo "  spy → reverse → checklist → blueprint → launch"
        echo ""
        echo "Commands:"
        echo "  spy <niche>           Search Meta Ad Library for profitable stores"
        echo "  spy-tiktok <niche>    Find TikTok→Facebook arbitrage opportunities"
        echo "  reverse <store-url>   Reverse-engineer a store (traffic, funnel, pricing)"
        echo "  checklist <id>        Run Ali Akbar 90% success checklist"
        echo "  blueprint <id>        Generate full clone plan with agent assignments"
        echo "  pipeline              Run full automated spy→score→alert cycle"
        echo ""
        echo "Ali Akbar's 7 Criteria (90% Success Rate):"
        echo "  1. 50+ active ads in English markets"
        echo "  2. Single-product focus (not general store)"
        echo "  3. Ads running 3+ months (evergreen)"
        echo "  4. Simple checkout (single-page funnel)"
        echo "  5. 5x+ cost-to-price markup"
        echo "  6. Creative content available on social"
        echo "  7. Supplier sourcing verified"
        ;;
esac
