#!/bin/bash
# biz-scraper.sh — GAIA E-Commerce Flywheel CLI
# Stage 1 (SPY) implementation: scrape competitor URLs, extract opportunity data, save to vault.db
#
# Usage:
#   biz-scraper.sh spy --url <product_url> [--brand <brand>]
#   biz-scraper.sh spy-niche --keyword <niche> [--brand <brand>]
#   biz-scraper.sh clone --id <vault_id> [--brand <brand>]
#   biz-scraper.sh status [--brand <brand>]

set -euo pipefail

VAULT_DB="$HOME/.openclaw/workspace/vault/vault.db"
JINA_BASE="https://r.jina.ai"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- helpers ---

log() { echo "[biz-scraper] $*" >&2; }
die() { log "ERROR: $*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

# --- scrape via Jina Reader ---

scrape_url() {
  local url="$1"
  local jina_url="${JINA_BASE}/${url}"
  log "Scraping: $url"
  log "Jina URL: $jina_url"

  local content
  content=$(curl -sL -H "Accept: text/markdown" "$jina_url" 2>/dev/null) || die "Failed to fetch URL via Jina Reader"

  if [ -z "$content" ] || [ ${#content} -lt 50 ]; then
    die "Jina Reader returned empty or too-short content (${#content} chars). URL may be blocked or invalid."
  fi

  echo "$content"
}

# --- extract fields from scraped markdown ---

extract_fields() {
  local content="$1"
  local url="$2"

  python3 -c "
import json, re, sys

content = sys.stdin.read()

# Extract product name: first H1 or first bold text or first non-empty line
product_name = ''
for line in content.split('\n'):
    line = line.strip()
    if line.startswith('# '):
        product_name = line.lstrip('# ').strip()
        break
    if line.startswith('**') and line.endswith('**'):
        product_name = line.strip('* ')
        break
if not product_name:
    for line in content.split('\n'):
        line = line.strip()
        if len(line) > 5 and not line.startswith('[') and not line.startswith('!'):
            product_name = line[:120]
            break

# Extract prices: look for currency patterns
prices = []
price_patterns = [
    r'[\$\£\€][\d,]+\.?\d*',
    r'(?:USD|AUD|GBP|EUR|MYR|RM)\s*[\d,]+\.?\d*',
    r'[\d,]+\.?\d*\s*(?:USD|AUD|GBP|EUR|MYR|RM)',
]
for pat in price_patterns:
    prices.extend(re.findall(pat, content, re.IGNORECASE))
prices = list(dict.fromkeys(prices))[:10]  # dedupe, max 10

# Detect funnel indicators
funnel_indicators = []
content_lower = content.lower()

checks = {
    'upsell': ['upsell', 'upgrade', 'add to order', 'one-time offer', 'oto', 'special offer'],
    'order_bump': ['order bump', 'add this', 'checkbox', 'yes, add'],
    'subscription': ['subscribe', 'subscription', 'monthly', 'recurring', 'auto-ship', 'every month'],
    'email_capture': ['email', 'newsletter', 'sign up', 'join', 'get updates', 'free guide', 'lead magnet'],
    'urgency': ['limited time', 'hurry', 'countdown', 'only .* left', 'expires', 'ending soon', 'last chance', 'act now'],
    'scarcity': ['limited stock', 'selling fast', 'almost gone', 'few remaining', 'low stock'],
    'social_proof': ['reviews', 'testimonial', 'rated', 'stars', 'customers', 'verified', 'trust'],
    'guarantee': ['money back', 'guarantee', 'risk.free', 'refund', 'satisfaction'],
    'bundle': ['bundle', 'save .* when', 'buy .* get', 'pack of', 'multi.pack', 'combo'],
    'free_shipping': ['free shipping', 'free delivery', 'ships free'],
    'quantity_discount': ['buy more save', 'quantity discount', 'bulk', 'save \\\\d+%'],
}

for indicator, keywords in checks.items():
    for kw in keywords:
        if re.search(kw, content_lower):
            funnel_indicators.append(indicator)
            break

# Score opportunity (0-100)
score_market = min(100, len(prices) * 15 + (30 if 'social_proof' in funnel_indicators else 0))
score_margin = 50  # default, needs manual refinement
if any(p for p in prices if re.search(r'[\d]+', p) and int(re.search(r'(\d+)', p).group(1)) > 50):
    score_margin = 70
if 'subscription' in funnel_indicators:
    score_margin = 85

score_ai_fit = 60  # default
if any(x in funnel_indicators for x in ['email_capture', 'social_proof', 'urgency']):
    score_ai_fit = 80  # strong funnel = easy to replicate with AI content

score_brand_fit = 50  # needs manual assessment

total_score = int((score_market * 0.25) + (score_margin * 0.30) + (score_ai_fit * 0.25) + (score_brand_fit * 0.20))

result = {
    'url': '$url',
    'product_name': product_name,
    'prices': prices,
    'price_primary': prices[0] if prices else 'unknown',
    'funnel': {
        'upsells': 'upsell' in funnel_indicators,
        'bumps': 'order_bump' in funnel_indicators,
        'subscription': 'subscription' in funnel_indicators,
        'bundle': 'bundle' in funnel_indicators,
    },
    'funnel_indicators': funnel_indicators,
    'score': total_score,
    'score_breakdown': {
        'market': score_market,
        'margin': score_margin,
        'ai_fit': score_ai_fit,
        'brand_fit': score_brand_fit,
    },
    'content_length': len(content),
    'scraped_at': __import__('datetime').datetime.utcnow().isoformat() + 'Z',
}

print(json.dumps(result, indent=2))
" <<< "$content"
}

# --- save to vault.db ---

save_to_vault() {
  local json_data="$1"
  local brand="${2:-}"
  local ts
  ts=$(epoch_ms)

  local product_name
  product_name=$(echo "$json_data" | python3 -c "import sys,json; print(json.load(sys.stdin)['product_name'])")

  local score
  score=$(echo "$json_data" | python3 -c "import sys,json; print(json.load(sys.stdin)['score'])")

  local url_val
  url_val=$(echo "$json_data" | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])")

  local text="Biz opportunity: ${product_name} (score: ${score}/100) — ${url_val}"

  # Escape single quotes for SQL safety
  local escaped_url escaped_text escaped_brand escaped_meta
  escaped_url=$(printf '%s' "$url_val" | sed "s/'/''/g")
  escaped_text=$(printf '%s' "$text" | sed "s/'/''/g")
  escaped_brand=$(printf '%s' "$brand" | sed "s/'/''/g")
  escaped_meta=$(printf '%s' "$json_data" | sed "s/'/''/g")

  sqlite3 "$VAULT_DB" "INSERT INTO vault (source_type, source_ref, source_path, brand, category, agent, entry_type, text, metadata, ts)
    VALUES (
      'biz-opportunity',
      '${escaped_url}',
      'biz-scraper.sh spy',
      '${escaped_brand}',
      'research/competitor',
      'artemis',
      'opportunity',
      '${escaped_text}',
      '${escaped_meta}',
      ${ts}
    );"

  local inserted_id
  inserted_id=$(sqlite3 "$VAULT_DB" "SELECT last_insert_rowid();")

  log "Saved to vault.db — ID: $inserted_id"
  echo "$inserted_id"
}

# --- commands ---

cmd_spy() {
  local url="" brand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url) url="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [ -z "$url" ] && die "Usage: biz-scraper.sh spy --url <product_url> [--brand <brand>]"
  require_cmd curl
  require_cmd sqlite3
  require_cmd python3

  [ -f "$VAULT_DB" ] || die "vault.db not found at $VAULT_DB"

  log "=== STAGE 1: SPY ==="
  log "Target: $url"
  [ -n "$brand" ] && log "Brand: $brand"

  # 1. Scrape
  local raw_content
  raw_content=$(scrape_url "$url")
  log "Scraped ${#raw_content} chars"

  # 2. Extract fields
  local fields_json
  fields_json=$(extract_fields "$raw_content" "$url")

  # 3. Save to vault
  local vault_id
  vault_id=$(save_to_vault "$fields_json" "$brand")

  # 4. Print summary
  echo ""
  echo "=== BIZ OPPORTUNITY REPORT ==="
  echo "$fields_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Product:    {d['product_name']}\")
print(f\"URL:        {d['url']}\")
print(f\"Price:      {d['price_primary']}\")
if len(d['prices']) > 1:
    print(f\"All prices: {', '.join(d['prices'][:5])}\")
print(f\"Score:      {d['score']}/100\")
sb = d['score_breakdown']
print(f\"  Market:   {sb['market']}/100\")
print(f\"  Margin:   {sb['margin']}/100\")
print(f\"  AI Fit:   {sb['ai_fit']}/100\")
print(f\"  Brand:    {sb['brand_fit']}/100\")
print(f\"Funnel:     {', '.join(d['funnel_indicators']) if d['funnel_indicators'] else 'none detected'}\")
fu = d['funnel']
flags = []
if fu['upsells']: flags.append('upsells')
if fu['bumps']: flags.append('order bumps')
if fu['subscription']: flags.append('subscription')
if fu['bundle']: flags.append('bundles')
print(f\"Funnel has: {', '.join(flags) if flags else 'basic (no upsells/subs detected)'}\")
print(f\"Scraped:    {d['scraped_at']}\")
print(f\"Content:    {d['content_length']} chars\")
"
  echo "Vault ID:   $vault_id"
  echo "==============================="
  echo ""
  log "Next step: biz-scraper.sh clone --id $vault_id [--brand <brand>]"
}

cmd_status() {
  local brand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  require_cmd sqlite3
  [ -f "$VAULT_DB" ] || die "vault.db not found at $VAULT_DB"

  local brand_filter=""
  [ -n "$brand" ] && brand_filter="AND brand='${brand}'"

  echo "=== FLYWHEEL STATUS ==="
  [ -n "$brand" ] && echo "Brand: $brand"
  echo ""

  local opp_count brief_count live_count analysis_count pattern_count
  opp_count=$(sqlite3 "$VAULT_DB" "SELECT COUNT(*) FROM vault WHERE source_type='biz-opportunity' ${brand_filter};")
  brief_count=$(sqlite3 "$VAULT_DB" "SELECT COUNT(*) FROM vault WHERE source_type='campaign-brief' ${brand_filter};")
  live_count=$(sqlite3 "$VAULT_DB" "SELECT COUNT(*) FROM vault WHERE source_type='campaign-live' ${brand_filter};")
  analysis_count=$(sqlite3 "$VAULT_DB" "SELECT COUNT(*) FROM vault WHERE source_type='campaign-analysis' ${brand_filter};")
  pattern_count=$(sqlite3 "$VAULT_DB" "SELECT COUNT(*) FROM vault WHERE source_type='pattern' AND category LIKE '%campaign%' ${brand_filter};")

  echo "Stage 1 - SPY:      $opp_count opportunities"
  echo "Stage 2 - CLONE:    $brief_count campaign briefs"
  echo "Stage 4 - LAUNCH:   $live_count live campaigns"
  echo "Stage 5 - MEASURE:  $analysis_count analyses"
  echo "Stage 6 - COMPOUND: $pattern_count patterns learned"
  echo ""

  if [ "$opp_count" -gt 0 ]; then
    echo "--- Recent Opportunities ---"
    sqlite3 -header -column "$VAULT_DB" "SELECT id, brand, substr(text,1,80) as summary, created_at FROM vault WHERE source_type='biz-opportunity' ${brand_filter} ORDER BY id DESC LIMIT 5;"
  fi

  echo "========================="
}

cmd_clone() {
  local id="" brand=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) id="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      *) die "Unknown flag: $1" ;;
    esac
  done

  [ -z "$id" ] && die "Usage: biz-scraper.sh clone --id <vault_id> [--brand <brand>]"
  require_cmd sqlite3
  [ -f "$VAULT_DB" ] || die "vault.db not found at $VAULT_DB"

  local metadata
  metadata=$(sqlite3 "$VAULT_DB" "SELECT metadata FROM vault WHERE id=${id} AND source_type='biz-opportunity';")

  [ -z "$metadata" ] && die "No biz-opportunity found with ID $id"

  echo "=== STAGE 2: CLONE ==="
  echo "Opportunity ID: $id"
  echo ""
  echo "Loaded opportunity metadata. To generate a full campaign brief,"
  echo "dispatch to Dreami (ad copy) and Hermes (funnel + pricing):"
  echo ""
  echo "  Dreami: Generate PAS/AIDA/BAB ad copy + image prompts"
  echo "  Hermes: Design funnel structure + pricing strategy"
  echo ""
  echo "Opportunity data:"
  echo "$metadata" | python3 -m json.tool 2>/dev/null || echo "$metadata"
  echo ""
  log "Clone stage requires agent dispatch — use OpenClaw sessions_spawn for Dreami + Hermes"
}

# --- main ---

cmd="${1:-help}"
shift || true

case "$cmd" in
  spy)       cmd_spy "$@" ;;
  spy-niche) die "spy-niche not yet implemented — use 'spy' with a specific product URL" ;;
  clone)     cmd_clone "$@" ;;
  status)    cmd_status "$@" ;;
  help|--help|-h)
    echo "biz-scraper.sh — GAIA E-Commerce Flywheel"
    echo ""
    echo "Commands:"
    echo "  spy       --url <url> [--brand <brand>]    Scrape & score a product/competitor"
    echo "  spy-niche --keyword <niche> [--brand <brand>]  Research a niche (coming soon)"
    echo "  clone     --id <vault_id> [--brand <brand>]    Generate campaign brief from opportunity"
    echo "  status    [--brand <brand>]                    Show flywheel pipeline status"
    echo ""
    echo "Flywheel: SPY → CLONE → GENERATE → LAUNCH → MEASURE → COMPOUND"
    ;;
  *)
    die "Unknown command: $cmd. Run with --help for usage."
    ;;
esac
