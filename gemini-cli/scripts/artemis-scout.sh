#!/usr/bin/env bash
# artemis-scout.sh — Artemis's daily scout engine powered by Gemini CLI + scraping tools
# Chains: Scrapling/Jina (fetch raw data) → Gemini CLI (analyze, $0) → vault.db (store)
#
# Usage:
#   artemis-scout.sh trends --brand mirra              # Trend scouting
#   artemis-scout.sh competitors --brand mirra          # Competitor intel
#   artemis-scout.sh ads --keyword "health food"        # Ad library scan
#   artemis-scout.sh scrape-analyze <url>               # Scrape + AI analyze
#   artemis-scout.sh daily --brand mirra                # Full daily scout

set -euo pipefail

SKILLS="$HOME/.openclaw/skills"
WORKSPACE="$HOME/.openclaw/workspace"
GEMINI="$HOME/local/bin/gemini"
DATA="$WORKSPACE/data/scout"
ROOMS="$WORKSPACE/rooms"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$DATA/$TODAY"

post_room() {
  printf '{"ts":%s000,"agent":"artemis","room":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$1" "$2" >> "$ROOMS/${1}.jsonl" 2>/dev/null
}

store_vault() {
  local ref="$1" text="$2"
  python3 -c "
import sqlite3
db = sqlite3.connect('$WORKSPACE/vault/vault.db')
db.execute('''INSERT OR IGNORE INTO vault (source_ref, source_type, text, agent, created_at)
              VALUES (?, 'scout-daily', ?, 'artemis', datetime('now'))''',
           ('$ref', '''$(echo "$text" | head -c 1000 | sed "s/'/''/g")'''))
db.commit()
" 2>/dev/null || true
}

# Scrape a URL using best available tool
scrape_url() {
  local url="$1"
  local output=""

  # Try Scrapling first (anti-bot)
  if [ -f "$SKILLS/agent-reach/scripts/scrapling-fetch.sh" ]; then
    output=$(bash "$SKILLS/agent-reach/scripts/scrapling-fetch.sh" fetch "$url" 2>/dev/null | head -c 5000)
  fi

  # Fallback to Jina Reader
  if [ -z "$output" ] || [ ${#output} -lt 100 ]; then
    output=$(curl -sL "https://r.jina.ai/$url" 2>/dev/null | head -c 5000)
  fi

  echo "$output"
}

CMD="${1:-}"; shift 2>/dev/null || true
BRAND="" KEYWORD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --brand) shift; BRAND="${1:-}" ;;
    --keyword) shift; KEYWORD="${1:-}" ;;
  esac
  shift 2>/dev/null || true
done

case "$CMD" in
  trends)
    echo "═══ TREND SCOUT: ${BRAND:-all brands} ═══"
    local_query="What are the top 5 trending health food and wellness trends in Malaysia this week (March 2026)? Focus on: social media trends, new product launches, viral content formats, and consumer behavior shifts. Be specific with brand names, platforms, and engagement metrics where available."

    "$GEMINI" -p "$local_query" --approval-mode yolo -o text \
      > "$DATA/$TODAY/trends-${BRAND:-all}.txt" 2>/dev/null

    echo "Saved to: $DATA/$TODAY/trends-${BRAND:-all}.txt"
    store_vault "trends-$TODAY-${BRAND:-all}" "$(head -c 500 "$DATA/$TODAY/trends-${BRAND:-all}.txt")"
    post_room "build" "[Artemis Scout] Trends for ${BRAND:-all}: $(head -1 "$DATA/$TODAY/trends-${BRAND:-all}.txt" | head -c 100)"
    ;;

  competitors)
    echo "═══ COMPETITOR SCOUT: ${BRAND:-all} ═══"

    # Get brand DNA for context
    local brand_context=""
    if [ -n "$BRAND" ] && [ -f "$HOME/.openclaw/brands/$BRAND/DNA.json" ]; then
      brand_context="Context: $(head -c 500 "$HOME/.openclaw/brands/$BRAND/DNA.json")"
    fi

    "$GEMINI" -p "Research the top 5 competitors for ${BRAND:-Malaysian health food} in March 2026. For each: brand name, key products, pricing, social media presence, recent ad campaigns, and market positioning. $brand_context" \
      --approval-mode yolo -o text \
      > "$DATA/$TODAY/competitors-${BRAND:-all}.txt" 2>/dev/null

    echo "Saved to: $DATA/$TODAY/competitors-${BRAND:-all}.txt"
    store_vault "competitors-$TODAY-${BRAND:-all}" "$(head -c 500 "$DATA/$TODAY/competitors-${BRAND:-all}.txt")"
    ;;

  ads)
    echo "═══ AD LIBRARY SCOUT: ${KEYWORD:-health food} ═══"

    # Meta Ad Library scrape (if available)
    if [ -f "$SKILLS/meta-ads-library/scripts/scrape_meta_library.py" ]; then
      echo "Scraping Meta Ad Library..."
      python3 "$SKILLS/meta-ads-library/scripts/scrape_meta_library.py" \
        --keyword "${KEYWORD:-health food}" --country MY --limit 20 \
        > "$DATA/$TODAY/meta-ads-${KEYWORD:-health}.json" 2>/dev/null || true
    fi

    # Analyze with Gemini
    "$GEMINI" -p "Research active paid ads for '${KEYWORD:-health food}' in Malaysia on Meta and TikTok. What creative formats are working? What hooks are trending? What's the estimated spend range? List top 5 advertisers with their creative strategy." \
      --approval-mode yolo -o text \
      > "$DATA/$TODAY/ad-intel-${KEYWORD:-health}.txt" 2>/dev/null

    echo "Saved to: $DATA/$TODAY/ad-intel-${KEYWORD:-health}.txt"
    store_vault "ad-intel-$TODAY" "$(head -c 500 "$DATA/$TODAY/ad-intel-${KEYWORD:-health}.txt")"
    ;;

  scrape-analyze)
    URL="${1:-}"
    if [ -z "$URL" ]; then
      echo "ERROR: URL required"
      exit 1
    fi
    echo "═══ SCRAPE + ANALYZE: $URL ═══"

    # Scrape with best tool
    echo "Scraping..."
    RAW=$(scrape_url "$URL")
    echo "$RAW" > "$DATA/$TODAY/raw-scrape.txt"
    echo "  Scraped: ${#RAW} chars"

    # Analyze with Gemini
    echo "Analyzing with Gemini..."
    "$GEMINI" -p "Analyze this scraped content and extract: key products, pricing, brand positioning, target audience, marketing strategy, and any competitive insights. Content: $(echo "$RAW" | head -c 3000)" \
      --approval-mode yolo -o text \
      > "$DATA/$TODAY/analysis-$(echo "$URL" | md5 | head -c 8).txt" 2>/dev/null

    echo "Analysis complete"
    cat "$DATA/$TODAY/analysis-$(echo "$URL" | md5 | head -c 8).txt" | head -20
    ;;

  daily)
    echo "═══ ARTEMIS DAILY SCOUT — $TODAY ═══"
    echo "Brand: ${BRAND:-all}"
    echo ""

    # 1. Trends
    echo "[1/4] Scouting trends..."
    bash "$0" trends --brand "${BRAND:-mirra}" 2>/dev/null || true

    # 2. Competitors
    echo "[2/4] Scouting competitors..."
    bash "$0" competitors --brand "${BRAND:-mirra}" 2>/dev/null || true

    # 3. Ad intel
    echo "[3/4] Scanning ad library..."
    bash "$0" ads --keyword "health food Malaysia" 2>/dev/null || true

    # 4. New AI models/tools
    echo "[4/4] Checking new AI models..."
    "$GEMINI" -p "List the 3 most significant AI model or tool releases in the last 48 hours (as of March 8, 2026). Focus on: image generation, video generation, LLMs, agent frameworks. Include: name, release date, key capability, and relevance to marketing/content creation." \
      --approval-mode yolo -o text \
      > "$DATA/$TODAY/new-models.txt" 2>/dev/null || true

    echo ""
    echo "═══ DAILY SCOUT COMPLETE ═══"
    echo "Results: $DATA/$TODAY/"
    ls "$DATA/$TODAY/" 2>/dev/null

    # Post summary to build room
    post_room "build" "[Artemis Daily Scout $TODAY] Trends + competitors + ads + models scanned. Results in data/scout/$TODAY/"
    ;;

  *)
    echo "Usage: artemis-scout.sh <trends|competitors|ads|scrape-analyze|daily> [options]"
    echo ""
    echo "Options:"
    echo "  --brand <brand>      Target brand (mirra, pinxin-vegan, etc.)"
    echo "  --keyword <keyword>  Search keyword for ad scanning"
    exit 1
    ;;
esac
