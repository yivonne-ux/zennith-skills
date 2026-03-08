#!/usr/bin/env bash
# biz-scout.sh — Business Discovery Engine for GAIA CORP-OS
# Automated spy-clone-scale pipeline: discover → validate → score → blueprint → alert
#
# Usage:
#   biz-scout.sh scan                    # Daily discovery scan (Artemis)
#   biz-scout.sh validate <id>           # Validate opportunity (Athena)
#   biz-scout.sh rank                    # Score & rank all opportunities
#   biz-scout.sh blueprint <id>          # Generate blueprint (Dreami+Hermes)
#   biz-scout.sh alert                   # Send top 3 to Jenn via WhatsApp
#   biz-scout.sh list                    # List all opportunities
#   biz-scout.sh status                  # Show pipeline stats

set -euo pipefail

OPENCLAW="$HOME/.openclaw"
DATA_DIR="$OPENCLAW/workspace/data/biz-opportunities"
VAULT_DB="$OPENCLAW/workspace/vault/vault.db"
LOG_FILE="$OPENCLAW/logs/biz-discovery.log"
REACH="$OPENCLAW/skills/agent-reach/scripts"

mkdir -p "$DATA_DIR" "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# ── SCAN: Discover opportunities from multiple sources ──

cmd_scan() {
    log "=== DAILY DISCOVERY SCAN ==="
    local date_str
    date_str=$(date +%Y-%m-%d)
    local scan_file="$DATA_DIR/scan-${date_str}.jsonl"

    # 1. Google Trends — trending searches in MY
    log "Scanning Google Trends MY..."
    python3 << 'PYEOF' >> "$scan_file" 2>/dev/null || log "Google Trends: skipped (no pytrends)"
import json, sys
from datetime import datetime
try:
    from pytrends.request import TrendReq
    pt = TrendReq(hl='en-MY', tz=480)
    trending = pt.trending_searches(pn='malaysia')
    for idx, row in trending.head(20).iterrows():
        term = row[0]
        opp = {
            "id": f"gt-{datetime.now().strftime('%Y%m%d')}-{idx}",
            "source": "google-trends",
            "term": term,
            "region": "MY",
            "discovered_at": datetime.now().isoformat(),
            "status": "raw",
            "score": 0
        }
        print(json.dumps(opp))
except Exception as e:
    print(json.dumps({"error": str(e), "source": "google-trends"}), file=sys.stderr)
PYEOF

    # 2. TikTok Creative Center — top ads (via existing skill)
    log "Scanning TikTok top ads..."
    if [[ -x "$OPENCLAW/skills/tiktok-trends/scripts/tiktok-trends.sh" ]]; then
        bash "$OPENCLAW/skills/tiktok-trends/scripts/tiktok-trends.sh" top-ads --region MY --limit 10 2>/dev/null | \
        python3 -c "
import json, sys
from datetime import datetime
for i, line in enumerate(sys.stdin):
    line = line.strip()
    if not line: continue
    try:
        ad = json.loads(line)
        opp = {
            'id': f'tt-{datetime.now().strftime(\"%Y%m%d\")}-{i}',
            'source': 'tiktok-creative-center',
            'product': ad.get('title', ad.get('ad_title', '')),
            'url': ad.get('url', ''),
            'likes': ad.get('likes', 0),
            'region': 'MY',
            'discovered_at': datetime.now().isoformat(),
            'status': 'raw',
            'score': 0
        }
        print(json.dumps(opp))
    except: pass
" >> "$scan_file" 2>/dev/null || log "TikTok: skipped"
    fi

    # 3. Shopee MY — trending products (via existing skill)
    log "Scanning Shopee MY trending..."
    if [[ -x "$OPENCLAW/skills/product-scout/scripts/scout_products.py" ]]; then
        python3 "$OPENCLAW/skills/product-scout/scripts/scout_products.py" --platform shopee --region MY --limit 10 2>/dev/null | \
        python3 -c "
import json, sys
from datetime import datetime
for i, line in enumerate(sys.stdin):
    line = line.strip()
    if not line: continue
    try:
        prod = json.loads(line)
        opp = {
            'id': f'sp-{datetime.now().strftime(\"%Y%m%d\")}-{i}',
            'source': 'shopee-my',
            'product': prod.get('name', prod.get('title', '')),
            'price': prod.get('price', 0),
            'sold': prod.get('sold', prod.get('historical_sold', 0)),
            'url': prod.get('url', ''),
            'region': 'MY',
            'discovered_at': datetime.now().isoformat(),
            'status': 'raw',
            'score': 0
        }
        print(json.dumps(opp))
    except: pass
" >> "$scan_file" 2>/dev/null || log "Shopee: skipped"
    fi

    # 4. Meta Ad Library — long-running ads (30+ days)
    log "Scanning Meta Ad Library for long-running ads..."
    if [[ -x "$OPENCLAW/skills/meta-ads-library/scripts/meta-ads-search.sh" ]]; then
        bash "$OPENCLAW/skills/meta-ads-library/scripts/meta-ads-search.sh" --days 30 --limit 10 2>/dev/null | \
        python3 -c "
import json, sys
from datetime import datetime
for i, line in enumerate(sys.stdin):
    line = line.strip()
    if not line: continue
    try:
        ad = json.loads(line)
        opp = {
            'id': f'ma-{datetime.now().strftime(\"%Y%m%d\")}-{i}',
            'source': 'meta-ad-library',
            'advertiser': ad.get('page_name', ''),
            'ad_text': ad.get('ad_creative_bodies', [''])[0][:200] if ad.get('ad_creative_bodies') else '',
            'start_date': ad.get('ad_delivery_start_time', ''),
            'url': ad.get('ad_snapshot_url', ''),
            'region': 'ALL',
            'discovered_at': datetime.now().isoformat(),
            'status': 'raw',
            'score': 0
        }
        print(json.dumps(opp))
    except: pass
" >> "$scan_file" 2>/dev/null || log "Meta Ads: skipped"
    fi

    # 5. Quick web scrape for trending products (via Scrapling)
    log "Scanning trending product niches..."
    bash "$REACH/web-read.sh" "https://r.jina.ai/https://trends.google.com/trending?geo=MY" 2>/dev/null | head -50 >> "$DATA_DIR/trends-raw-${date_str}.txt" || true

    # Count results
    local count=0
    if [[ -f "$scan_file" ]]; then
        count=$(wc -l < "$scan_file" | tr -d ' ')
    fi
    log "Scan complete: $count opportunities found → $scan_file"

    # Write to vault.db
    if [[ -f "$scan_file" ]] && [[ "$count" -gt 0 ]]; then
        python3 << PYEOF
import json, sqlite3
db = sqlite3.connect("$VAULT_DB")
count = 0
with open("$scan_file") as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            opp = json.loads(line)
            if opp.get("error"): continue
            db.execute(
                "INSERT INTO vault (source_ref, text, source_type, brand, agent, created_at) VALUES (?, ?, 'biz-opportunity', 'gaia-os', 'artemis', datetime('now'))",
                (opp.get("id", "unknown"), json.dumps(opp))
            )
            count += 1
        except: pass
db.commit()
db.close()
print(f"  Wrote {count} opportunities to vault.db")
PYEOF
    fi
}

# ── VALIDATE: Check opportunity against Ali Akbar's 90% checklist ──

cmd_validate() {
    local opp_id="${1:?Opportunity ID required}"
    log "VALIDATING: $opp_id"

    python3 << PYEOF
import json, sqlite3

db = sqlite3.connect("$VAULT_DB")
row = db.execute("SELECT text FROM vault WHERE source_ref = ? AND source_type = 'biz-opportunity'", ("$opp_id",)).fetchone()
if not row:
    print(f"  ERROR: Opportunity '$opp_id' not found in vault.db")
    raise SystemExit(1)

opp = json.loads(row[0])
print(f"  Opportunity: {opp.get('product', opp.get('term', opp.get('advertiser', 'unknown')))}")
print(f"  Source: {opp.get('source', 'unknown')}")

# Ali Akbar 90% checklist
checks = {
    "has_product_name": bool(opp.get("product") or opp.get("term")),
    "has_source_url": bool(opp.get("url")),
    "has_price_data": bool(opp.get("price") or opp.get("sold")),
    "from_validated_source": opp.get("source") in ("meta-ad-library", "tiktok-creative-center", "shopee-my"),
    "region_relevant": opp.get("region") in ("MY", "ALL", "SG"),
}

passed = sum(1 for v in checks.values() if v)
total = len(checks)
print(f"  Checklist: {passed}/{total}")
for k, v in checks.items():
    print(f"    {'✓' if v else '✗'} {k}")

# Update status
opp["status"] = "validated" if passed >= 3 else "weak"
opp["validation_score"] = passed / total
db.execute("UPDATE vault SET text = ? WHERE source_ref = ? AND source_type = 'biz-opportunity'", (json.dumps(opp), "$opp_id"))

# Log validation
validation = {"opp_id": "$opp_id", "checks": checks, "passed": passed, "total": total}
db.execute(
    "INSERT INTO vault (source_ref, text, source_type, brand, agent, created_at) VALUES (?, ?, 'biz-validation', 'gaia-os', 'athena', datetime('now'))",
    (f"val-$opp_id", json.dumps(validation))
)
db.commit()
db.close()
PYEOF
}

# ── RANK: Score all validated opportunities ──

cmd_rank() {
    log "RANKING opportunities..."
    python3 << 'PYEOF'
import json, sqlite3

db = sqlite3.connect("/Users/jennwoeiloh/.openclaw/workspace/vault/vault.db")
rows = db.execute("SELECT source_ref, text FROM vault WHERE source_type = 'biz-opportunity' ORDER BY created_at DESC LIMIT 50").fetchall()

opportunities = []
for key, val in rows:
    try:
        opp = json.loads(val)
        # Simple scoring based on available data
        score = 0
        if opp.get("sold", 0) > 1000: score += 25
        elif opp.get("sold", 0) > 100: score += 15
        if opp.get("likes", 0) > 10000: score += 20
        elif opp.get("likes", 0) > 1000: score += 10
        if opp.get("source") == "meta-ad-library": score += 20  # Long-running = validated
        if opp.get("source") == "tiktok-creative-center": score += 15
        if opp.get("region") == "MY": score += 10  # Local opportunity
        if opp.get("validation_score", 0) >= 0.6: score += 10

        opp["score"] = score
        opportunities.append(opp)
    except:
        pass

opportunities.sort(key=lambda x: x.get("score", 0), reverse=True)

print(f"{'Rank':<5} {'Score':<7} {'Source':<25} {'Product/Term':<40} {'Status'}")
print("-" * 90)
for i, opp in enumerate(opportunities[:20], 1):
    name = opp.get("product", opp.get("term", opp.get("advertiser", "?")))[:38]
    print(f"{i:<5} {opp.get('score',0):<7} {opp.get('source','?'):<25} {name:<40} {opp.get('status','raw')}")

db.close()
PYEOF
}

# ── LIST: Show all opportunities ──

cmd_list() {
    python3 << 'PYEOF'
import json, sqlite3

db = sqlite3.connect("/Users/jennwoeiloh/.openclaw/workspace/vault/vault.db")
rows = db.execute("SELECT source_ref, text, created_at FROM vault WHERE source_type = 'biz-opportunity' ORDER BY created_at DESC LIMIT 30").fetchall()

print(f"{'ID':<30} {'Source':<25} {'Product/Term':<35} {'Date'}")
print("-" * 100)
for key, val, dt in rows:
    try:
        opp = json.loads(val)
        name = opp.get("product", opp.get("term", opp.get("advertiser", "?")))[:33]
        print(f"{key:<30} {opp.get('source','?'):<25} {name:<35} {dt[:10]}")
    except:
        print(f"{key:<30} {'parse-error':<25} {'?':<35} {dt[:10]}")

print(f"\nTotal: {len(rows)} opportunities")
db.close()
PYEOF
}

# ── ALERT: Send top opportunities to Jenn ──

cmd_alert() {
    log "ALERTING top opportunities..."
    local msg
    msg=$(python3 << 'PYEOF'
import json, sqlite3

db = sqlite3.connect("/Users/jennwoeiloh/.openclaw/workspace/vault/vault.db")
rows = db.execute("SELECT text FROM vault WHERE source_type = 'biz-opportunity' ORDER BY created_at DESC LIMIT 50").fetchall()

opps = []
for (val,) in rows:
    try:
        opp = json.loads(val)
        score = opp.get("score", 0)
        if score > 0:
            opps.append(opp)
    except:
        pass

opps.sort(key=lambda x: x.get("score", 0), reverse=True)
top = opps[:3]

if not top:
    print("No scored opportunities yet. Run: biz-scout.sh scan && biz-scout.sh rank")
else:
    lines = ["🔍 *GAIA Biz Discovery — Today's Top 3*\n"]
    for i, opp in enumerate(top, 1):
        name = opp.get("product", opp.get("term", opp.get("advertiser", "?")))
        source = opp.get("source", "?")
        score = opp.get("score", 0)
        lines.append(f"{i}. *{name}* (score: {score})")
        lines.append(f"   Source: {source} | Region: {opp.get('region', '?')}")
    lines.append("\nRun `biz-scout.sh rank` for full list")
    print("\n".join(lines))

db.close()
PYEOF
)
    echo "$msg"

    # Send via WhatsApp if wacli available
    if command -v wacli-send &> /dev/null && [[ -n "$msg" ]]; then
        echo "$msg" | wacli-send 2>/dev/null && log "Alert sent via WhatsApp" || log "WhatsApp send failed"
    fi
}

# ── STATUS: Pipeline stats ──

cmd_status() {
    python3 << 'PYEOF'
import sqlite3

db = sqlite3.connect("/Users/jennwoeiloh/.openclaw/workspace/vault/vault.db")

total = db.execute("SELECT COUNT(*) FROM vault WHERE source_type = 'biz-opportunity'").fetchone()[0]
validated = db.execute("SELECT COUNT(*) FROM vault WHERE source_type = 'biz-validation'").fetchone()[0]
patterns = db.execute("SELECT COUNT(*) FROM vault WHERE source_type = 'biz-pattern'").fetchone()[0]

print("=== Biz Discovery Pipeline ===")
print(f"  Opportunities:  {total}")
print(f"  Validated:      {validated}")
print(f"  Patterns:       {patterns}")

# By source
rows = db.execute("SELECT text FROM vault WHERE source_type = 'biz-opportunity'").fetchall()
sources = {}
for (val,) in rows:
    import json
    try:
        opp = json.loads(val)
        src = opp.get("source", "unknown")
        sources[src] = sources.get(src, 0) + 1
    except:
        pass

if sources:
    print("\n  By source:")
    for src, cnt in sorted(sources.items(), key=lambda x: -x[1]):
        print(f"    {src}: {cnt}")

db.close()
PYEOF
}

case "${1:-help}" in
    scan)       cmd_scan ;;
    validate)   cmd_validate "${2:-}" ;;
    rank)       cmd_rank ;;
    blueprint)  log "Blueprint requires Dreami agent. Dispatch: sessions_spawn dreami 'Blueprint opportunity ${2:-}'" ;;
    alert)      cmd_alert ;;
    list)       cmd_list ;;
    status)     cmd_status ;;
    help|*)
        echo "Biz Discovery — GAIA OS Business Opportunity Engine"
        echo ""
        echo "Usage: biz-scout.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  scan              Daily discovery scan (trends, ads, products)"
        echo "  validate <id>     Validate opportunity (Ali Akbar checklist)"
        echo "  rank              Score & rank all opportunities"
        echo "  blueprint <id>    Generate business blueprint (via Dreami)"
        echo "  alert             Send top 3 to Jenn via WhatsApp"
        echo "  list              List all opportunities"
        echo "  status            Show pipeline stats"
        ;;
esac
