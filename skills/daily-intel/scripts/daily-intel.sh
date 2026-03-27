#!/usr/bin/env bash
# daily-intel.sh — Morning Intelligence Gathering for Scout Agent
# Runs daily via cron. Scrapes competitors, trends, content inspiration.
# Produces digest + compound analysis.
#
# Usage:
#   daily-intel.sh                          # full run
#   daily-intel.sh --section competitors    # one section only
#   daily-intel.sh --section trends
#   daily-intel.sh --section inspiration
#   daily-intel.sh --digest-only            # regenerate digest from existing raw data
#
# Cron: 0 7 * * * /bin/bash /Users/jennwoeiloh/.openclaw/skills/daily-intel/scripts/daily-intel.sh

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# ── Paths (absolute, no tilde) ──────────────────────────────────────
HOME_DIR="/Users/jennwoeiloh"
OPENCLAW="${HOME_DIR}/.openclaw"
SKILLS="${OPENCLAW}/skills"
DATA_ROOT="${OPENCLAW}/workspace/data/daily-intel"
ROOMS="${OPENCLAW}/workspace/rooms"
LOG_FILE="${OPENCLAW}/logs/daily-intel.log"

WEB_READ="${SKILLS}/agent-reach/scripts/web-read.sh"
SCRAPLING="${SKILLS}/scrapling/scripts/scrape.sh"
TWITTER_SCAN="${SKILLS}/content-scraper/scripts/twitter-scan.sh"
INSTAGRAM_SCAN="${SKILLS}/content-scraper/scripts/instagram-scan.sh"
KNOWLEDGE_COMPOUND="${SKILLS}/knowledge-compound/scripts/digest.sh"

TODAY="$(date '+%Y-%m-%d')"
YESTERDAY="$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d 'yesterday' '+%Y-%m-%d')"
TODAY_DIR="${DATA_ROOT}/${TODAY}"
YESTERDAY_DIR="${DATA_ROOT}/${YESTERDAY}"

# ── Parse args ───────────────────────────────────────────────────────
SECTION="all"
DIGEST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --section) SECTION="$2"; shift 2 ;;
    --digest-only) DIGEST_ONLY=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ── Setup ────────────────────────────────────────────────────────────
mkdir -p "${TODAY_DIR}/competitors" "${TODAY_DIR}/trends" "${TODAY_DIR}/inspiration"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DAILY-INTEL] $1" | tee -a "$LOG_FILE"
}

# Safe fetch via web-read (Jina Reader). Returns markdown. Timeout 30s.
safe_fetch() {
  local url="$1"
  local out="$2"
  local label="${3:-$url}"
  log "Fetching: ${label}"
  if timeout 30 bash "$WEB_READ" "$url" > "$out" 2>/dev/null; then
    local size
    size=$(wc -c < "$out" | tr -d ' ')
    if [[ "$size" -lt 100 ]]; then
      log "  WARN: tiny response (${size}b) for ${label}"
      return 1
    fi
    log "  OK: ${size}b"
    return 0
  else
    log "  FAIL: ${label}"
    echo "# Failed to fetch: ${url}" > "$out"
    return 1
  fi
}

# Safe fetch via scrapling (anti-bot). Falls back to web-read.
safe_scrape() {
  local url="$1"
  local out="$2"
  local label="${3:-$url}"
  log "Scraping: ${label}"
  if timeout 45 bash "$SCRAPLING" fetch "$url" --output md > "$out" 2>/dev/null; then
    local size
    size=$(wc -c < "$out" | tr -d ' ')
    if [[ "$size" -gt 100 ]]; then
      log "  OK (scrapling): ${size}b"
      return 0
    fi
  fi
  # Fallback to web-read
  log "  Scrapling failed, falling back to web-read"
  safe_fetch "$url" "$out" "$label"
}

# ── SECTION 1: COMPETITORS ──────────────────────────────────────────
scrape_competitors() {
  log "=== COMPETITORS ==="
  local dir="${TODAY_DIR}/competitors"

  # -- Spiritual / Psychic --
  log "--- Spiritual/Psychic Vertical ---"

  # Psychic Samira IG (via instaloader for public profiles)
  if command -v instaloader &>/dev/null; then
    log "Fetching: Psychic Samira IG"
    timeout 60 instaloader --no-pictures --no-videos --no-video-thumbnails \
      --count 10 --dirname-pattern "${dir}" --filename-pattern "ig-psychicsamira-{shortcode}" \
      --post-metadata-txt="{caption}\n---\nLikes: {likes}\nDate: {date_utc}" \
      -- psychicsamira 2>>"$LOG_FILE" || log "  instaloader failed for psychicsamira"
  fi

  # Top tarot creators IG (public web scrape)
  for account in taaborchi mysticmicah thetarotlady spiritdaughter; do
    safe_fetch "https://www.instagram.com/${account}/" \
      "${dir}/ig-${account}.md" "IG: ${account}"
  done

  # Spiritual influencer blogs/sites
  safe_fetch "https://www.mindbodygreen.com/articles/daily-horoscope" \
    "${dir}/mindbodygreen-horoscope.md" "MindBodyGreen horoscope"

  # -- F&B Malaysia (MIRRA competitors) --
  log "--- F&B Malaysia (MIRRA competitors) ---"

  safe_scrape "https://www.taiso.my/" "${dir}/taiso.md" "Taiso"
  safe_scrape "https://www.hishinxslim.com/" "${dir}/hishin-xslim.md" "Hishin XSlim"
  safe_scrape "https://simpleeats.com.my/" "${dir}/simple-eats.md" "Simple Eats"
  safe_scrape "https://www.dahmakan.com/" "${dir}/dahmakan.md" "Dahmakan"

  # -- Vegan Malaysia (Pinxin competitors) --
  log "--- Vegan Malaysia (Pinxin competitors) ---"

  safe_scrape "https://www.goveganmalaysia.com/" "${dir}/govegan-my.md" "GoVegan MY"
  safe_scrape "https://veggieplanet.my/" "${dir}/veggie-planet.md" "Veggie Planet"

  # IG for F&B competitors
  for account in taisomalaysia dahmakan simpleeatsmy; do
    safe_fetch "https://www.instagram.com/${account}/" \
      "${dir}/ig-${account}.md" "IG: ${account}"
  done

  log "=== COMPETITORS DONE ==="
}

# ── SECTION 2: TRENDS ────────────────────────────────────────────────
scrape_trends() {
  log "=== TRENDS ==="
  local dir="${TODAY_DIR}/trends"

  # -- Reddit (top posts last 24h via old.reddit JSON) --
  log "--- Reddit ---"
  for sub in psychic tarot vegan malaysia; do
    safe_fetch "https://old.reddit.com/r/${sub}/top/.json?t=day&limit=15" \
      "${dir}/reddit-${sub}-raw.json" "Reddit r/${sub} top/day"

    # Extract titles + scores into readable format
    if [[ -f "${dir}/reddit-${sub}-raw.json" ]] && command -v jq &>/dev/null; then
      jq -r '.data.children[]?.data | "[\(.score)] \(.title)\n  → \(.url // "self")\n  → \(.num_comments) comments\n"' \
        "${dir}/reddit-${sub}-raw.json" > "${dir}/reddit-${sub}.md" 2>/dev/null || true
    fi
  done

  # Additional subreddits for niche signals
  for sub in lawofattraction spirituality MealPrepSunday; do
    safe_fetch "https://old.reddit.com/r/${sub}/top/.json?t=day&limit=10" \
      "${dir}/reddit-${sub}-raw.json" "Reddit r/${sub} top/day"

    if [[ -f "${dir}/reddit-${sub}-raw.json" ]] && command -v jq &>/dev/null; then
      jq -r '.data.children[]?.data | "[\(.score)] \(.title)\n  → \(.num_comments) comments\n"' \
        "${dir}/reddit-${sub}-raw.json" > "${dir}/reddit-${sub}.md" 2>/dev/null || true
    fi
  done

  # -- X/Twitter trends --
  log "--- X/Twitter ---"
  if [[ -x "$TWITTER_SCAN" ]]; then
    bash "$TWITTER_SCAN" search "tarot reading" > "${dir}/twitter-tarot.md" 2>/dev/null || true
    bash "$TWITTER_SCAN" search "vegan malaysia" > "${dir}/twitter-vegan-my.md" 2>/dev/null || true
    bash "$TWITTER_SCAN" search "meal plan malaysia" > "${dir}/twitter-mealplan.md" 2>/dev/null || true
    bash "$TWITTER_SCAN" search "wellness spiritual" > "${dir}/twitter-wellness.md" 2>/dev/null || true
  else
    # Fallback: scrape nitter or web-read
    safe_fetch "https://nitter.privacydev.net/search?q=tarot+reading&f=tweets&since=${TODAY}" \
      "${dir}/twitter-tarot.md" "X: tarot reading"
    safe_fetch "https://nitter.privacydev.net/search?q=vegan+malaysia&f=tweets&since=${TODAY}" \
      "${dir}/twitter-vegan-my.md" "X: vegan malaysia"
  fi

  # -- Google Trends (via web-read) --
  log "--- Google Trends ---"
  safe_fetch "https://trends.google.com/trending?geo=MY" \
    "${dir}/google-trends-my.md" "Google Trends MY"

  # Specific queries
  for query in "tarot+reading" "vegan+food" "meal+plan" "weight+loss" "self+love"; do
    safe_fetch "https://trends.google.com/trends/explore?q=${query}&geo=MY&date=now+1-d" \
      "${dir}/gtrends-${query//+/-}.md" "Google Trends: ${query}"
  done

  # -- TikTok trending (via web scrape) --
  log "--- TikTok ---"
  safe_fetch "https://www.tiktok.com/discover?lang=en" \
    "${dir}/tiktok-discover.md" "TikTok Discover"

  log "=== TRENDS DONE ==="
}

# ── SECTION 3: CONTENT INSPIRATION ──────────────────────────────────
scrape_inspiration() {
  log "=== INSPIRATION ==="
  local dir="${TODAY_DIR}/inspiration"

  # -- Positive energy / Good vibes --
  log "--- Positive Energy ---"
  safe_fetch "https://old.reddit.com/r/lawofattraction/top/.json?t=day&limit=10" \
    "${dir}/reddit-loa-raw.json" "Reddit LOA top"
  safe_fetch "https://old.reddit.com/r/getmotivated/top/.json?t=day&limit=10" \
    "${dir}/reddit-motivated-raw.json" "Reddit GetMotivated top"
  safe_fetch "https://old.reddit.com/r/wholesomememes/top/.json?t=day&limit=10" \
    "${dir}/reddit-wholesome-raw.json" "Reddit WholesomeMemes top"

  # Extract readable quotes/titles
  for file in "${dir}"/reddit-*-raw.json; do
    [[ -f "$file" ]] || continue
    local base
    base="$(basename "$file" -raw.json)"
    if command -v jq &>/dev/null; then
      jq -r '.data.children[]?.data | "[\(.score)] \(.title)\n  \(.selftext[:200] // "")\n"' \
        "$file" > "${dir}/${base}.md" 2>/dev/null || true
    fi
  done

  # -- Motivational quotes sites --
  safe_fetch "https://www.brainyquote.com/topics/motivational-quotes" \
    "${dir}/quotes-motivational.md" "BrainyQuote motivational"
  safe_fetch "https://www.brainyquote.com/topics/self-love-quotes" \
    "${dir}/quotes-selflove.md" "BrainyQuote self-love"

  # -- Wellness / food memes --
  safe_fetch "https://old.reddit.com/r/veganmemes/top/.json?t=day&limit=10" \
    "${dir}/reddit-veganmemes-raw.json" "Reddit VeganMemes"
  safe_fetch "https://old.reddit.com/r/foodmemes/top/.json?t=day&limit=10" \
    "${dir}/reddit-foodmemes-raw.json" "Reddit FoodMemes"

  for file in "${dir}"/reddit-*memes-raw.json; do
    [[ -f "$file" ]] || continue
    local base
    base="$(basename "$file" -raw.json)"
    if command -v jq &>/dev/null; then
      jq -r '.data.children[]?.data | "[\(.score)] \(.title)\n  → \(.url)\n"' \
        "$file" > "${dir}/${base}.md" 2>/dev/null || true
    fi
  done

  # -- Romance / self-love IG content --
  for account in thegoodquote positiveenergy lfromanticist; do
    safe_fetch "https://www.instagram.com/${account}/" \
      "${dir}/ig-${account}.md" "IG: ${account}"
  done

  log "=== INSPIRATION DONE ==="
}

# ── DIGEST GENERATOR ─────────────────────────────────────────────────
generate_digest() {
  log "=== GENERATING DIGEST ==="
  local digest="${TODAY_DIR}/digest.md"

  cat > "$digest" <<HEADER
# Daily Intelligence Digest — ${TODAY}
> Generated $(date '+%Y-%m-%d %H:%M %Z') by Scout (daily-intel.sh)
> Raw data: ${TODAY_DIR}/

---

HEADER

  # -- Competitor Summary --
  echo "## 1. Competitor Activity" >> "$digest"
  echo "" >> "$digest"

  local comp_dir="${TODAY_DIR}/competitors"
  if [[ -d "$comp_dir" ]]; then
    local comp_count
    comp_count=$(find "$comp_dir" -name '*.md' -size +100c 2>/dev/null | wc -l | tr -d ' ')
    echo "**${comp_count} sources scraped successfully.**" >> "$digest"
    echo "" >> "$digest"

    # List what we got
    echo "### Spiritual/Psychic" >> "$digest"
    for f in "${comp_dir}"/ig-psychicsamira* "${comp_dir}"/ig-taaborchi* "${comp_dir}"/ig-mysticmicah* "${comp_dir}"/mindbodygreen*; do
      [[ -f "$f" ]] || continue
      local size
      size=$(wc -c < "$f" | tr -d ' ')
      echo "- $(basename "$f"): ${size}b" >> "$digest"
    done
    echo "" >> "$digest"

    echo "### F&B Malaysia (MIRRA competitors)" >> "$digest"
    for f in "${comp_dir}"/taiso* "${comp_dir}"/hishin* "${comp_dir}"/simple-eats* "${comp_dir}"/dahmakan*; do
      [[ -f "$f" ]] || continue
      local size
      size=$(wc -c < "$f" | tr -d ' ')
      echo "- $(basename "$f"): ${size}b" >> "$digest"
    done
    echo "" >> "$digest"

    echo "### Vegan MY (Pinxin competitors)" >> "$digest"
    for f in "${comp_dir}"/govegan* "${comp_dir}"/veggie*; do
      [[ -f "$f" ]] || continue
      local size
      size=$(wc -c < "$f" | tr -d ' ')
      echo "- $(basename "$f"): ${size}b" >> "$digest"
    done
    echo "" >> "$digest"
  fi

  # -- Trends Summary --
  echo "## 2. Trending Topics" >> "$digest"
  echo "" >> "$digest"

  local trends_dir="${TODAY_DIR}/trends"
  if [[ -d "$trends_dir" ]]; then
    # Reddit highlights
    echo "### Reddit Hot Topics" >> "$digest"
    for sub in psychic tarot vegan malaysia lawofattraction spirituality MealPrepSunday; do
      local rfile="${trends_dir}/reddit-${sub}.md"
      if [[ -f "$rfile" ]] && [[ -s "$rfile" ]]; then
        echo "" >> "$digest"
        echo "**r/${sub}:**" >> "$digest"
        head -9 "$rfile" >> "$digest"
        echo "" >> "$digest"
      fi
    done

    # Twitter highlights
    echo "### X/Twitter Signals" >> "$digest"
    for f in "${trends_dir}"/twitter-*.md; do
      [[ -f "$f" ]] || continue
      if [[ -s "$f" ]]; then
        echo "- $(basename "$f" .md): $(wc -l < "$f" | tr -d ' ') lines" >> "$digest"
      fi
    done
    echo "" >> "$digest"
  fi

  # -- Inspiration Summary --
  echo "## 3. Content Inspiration" >> "$digest"
  echo "" >> "$digest"

  local inspo_dir="${TODAY_DIR}/inspiration"
  if [[ -d "$inspo_dir" ]]; then
    echo "### Top Motivational / LOA / Self-Love" >> "$digest"
    for sub in reddit-loa reddit-motivated reddit-wholesome; do
      local rfile="${inspo_dir}/${sub}.md"
      if [[ -f "$rfile" ]] && [[ -s "$rfile" ]]; then
        echo "" >> "$digest"
        echo "**${sub}:**" >> "$digest"
        head -6 "$rfile" >> "$digest"
        echo "" >> "$digest"
      fi
    done

    echo "### Meme Sources" >> "$digest"
    for sub in reddit-veganmemes reddit-foodmemes; do
      local rfile="${inspo_dir}/${sub}.md"
      if [[ -f "$rfile" ]] && [[ -s "$rfile" ]]; then
        echo "- ${sub}: $(wc -l < "$rfile" | tr -d ' ') items" >> "$digest"
      fi
    done
    echo "" >> "$digest"
  fi

  # -- Brand Opportunities --
  echo "## 4. Brand Opportunities" >> "$digest"
  echo "" >> "$digest"
  echo "| Brand | Opportunity Signal | Source |" >> "$digest"
  echo "|-------|-------------------|--------|" >> "$digest"

  # Scan for keywords in scraped data
  local all_text
  all_text=$(find "$TODAY_DIR" -name '*.md' -exec cat {} + 2>/dev/null | tr '[:upper:]' '[:lower:]')

  # Count keyword hits
  local tarot_hits vegan_hits meal_hits weight_hits selflove_hits
  tarot_hits=$(echo "$all_text" | grep -c 'tarot\|oracle\|psychic\|reading' 2>/dev/null || echo 0)
  vegan_hits=$(echo "$all_text" | grep -c 'vegan\|plant.based\|meatless' 2>/dev/null || echo 0)
  meal_hits=$(echo "$all_text" | grep -c 'meal.plan\|meal.prep\|bento\|lunch.box' 2>/dev/null || echo 0)
  weight_hits=$(echo "$all_text" | grep -c 'weight.loss\|slim\|diet\|calorie' 2>/dev/null || echo 0)
  selflove_hits=$(echo "$all_text" | grep -c 'self.love\|self.care\|wellness\|healing' 2>/dev/null || echo 0)

  echo "| Jade Oracle | ${tarot_hits} tarot/psychic mentions | All sources |" >> "$digest"
  echo "| Pinxin Vegan | ${vegan_hits} vegan/plant-based mentions | All sources |" >> "$digest"
  echo "| MIRRA | ${meal_hits} meal plan mentions, ${weight_hits} weight mgmt | All sources |" >> "$digest"
  echo "| Serein/Rasaya | ${selflove_hits} self-love/wellness mentions | All sources |" >> "$digest"
  echo "" >> "$digest"

  log "Digest written: ${digest}"
}

# ── COMPOUND ANALYSIS (today vs yesterday) ───────────────────────────
generate_compound() {
  log "=== COMPOUND ANALYSIS ==="
  local compound="${TODAY_DIR}/compound.md"

  cat > "$compound" <<HEADER
# Compound Analysis — ${TODAY} vs ${YESTERDAY}
> Pattern detection: emerging trends, declining topics, new opportunities

---

HEADER

  if [[ ! -d "$YESTERDAY_DIR" ]]; then
    echo "**No yesterday data found at ${YESTERDAY_DIR}. First run — baseline established.**" >> "$compound"
    log "No yesterday data. Baseline run."
  else
    # Compare Reddit engagement
    echo "## Reddit Engagement Delta" >> "$compound"
    echo "" >> "$compound"

    for sub in psychic tarot vegan malaysia; do
      local today_file="${TODAY_DIR}/trends/reddit-${sub}.md"
      local yesterday_file="${YESTERDAY_DIR}/trends/reddit-${sub}.md"

      if [[ -f "$today_file" ]] && [[ -f "$yesterday_file" ]]; then
        local today_lines yesterday_lines
        today_lines=$(wc -l < "$today_file" | tr -d ' ')
        yesterday_lines=$(wc -l < "$yesterday_file" | tr -d ' ')
        echo "- r/${sub}: ${yesterday_lines} -> ${today_lines} lines" >> "$compound"
      elif [[ -f "$today_file" ]]; then
        echo "- r/${sub}: NEW (no yesterday data)" >> "$compound"
      fi
    done
    echo "" >> "$compound"

    # Compare competitor page sizes (proxy for activity)
    echo "## Competitor Activity Delta" >> "$compound"
    echo "" >> "$compound"

    for f in "${TODAY_DIR}/competitors"/*.md; do
      [[ -f "$f" ]] || continue
      local fname
      fname="$(basename "$f")"
      local yfile="${YESTERDAY_DIR}/competitors/${fname}"

      if [[ -f "$yfile" ]]; then
        local tsize ysize
        tsize=$(wc -c < "$f" | tr -d ' ')
        ysize=$(wc -c < "$yfile" | tr -d ' ')

        if [[ "$tsize" -ne "$ysize" ]]; then
          local delta=$(( tsize - ysize ))
          echo "- ${fname}: ${delta:+${delta}}b change (${ysize}b -> ${tsize}b)" >> "$compound"
        fi
      fi
    done
    echo "" >> "$compound"

    # New keywords today
    echo "## New Keywords Today" >> "$compound"
    echo "" >> "$compound"

    local today_words yesterday_words
    today_words=$(find "$TODAY_DIR" -name '*.md' -exec cat {} + 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' '\n' | sort -u)
    yesterday_words=$(find "$YESTERDAY_DIR" -name '*.md' -exec cat {} + 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' '\n' | sort -u)

    local new_words
    new_words=$(comm -23 <(echo "$today_words") <(echo "$yesterday_words") | head -30)

    if [[ -n "$new_words" ]]; then
      echo "New terms appearing today (sample):" >> "$compound"
      echo '```' >> "$compound"
      echo "$new_words" >> "$compound"
      echo '```' >> "$compound"
    else
      echo "No significant new keywords detected." >> "$compound"
    fi
    echo "" >> "$compound"
  fi

  # -- Emerging pattern flags --
  echo "## Emerging Patterns" >> "$compound"
  echo "" >> "$compound"
  echo "_Patterns are detected after 3+ days of data. Run daily to build baseline._" >> "$compound"
  echo "" >> "$compound"

  # Count how many days of data we have
  local day_count
  day_count=$(find "$DATA_ROOT" -maxdepth 1 -type d -name '20*' 2>/dev/null | wc -l | tr -d ' ')
  echo "**Data points: ${day_count} days collected.**" >> "$compound"
  echo "" >> "$compound"

  log "Compound analysis written: ${compound}"
}

# ── POST TO ROOM ─────────────────────────────────────────────────────
post_to_room() {
  log "=== POSTING TO ANALYTICS ROOM ==="
  local room_file="${ROOMS}/analytics.jsonl"
  mkdir -p "$(dirname "$room_file")"

  # Count successful scrapes
  local total_files
  total_files=$(find "$TODAY_DIR" -name '*.md' -size +100c 2>/dev/null | wc -l | tr -d ' ')

  local msg="[DAILY-INTEL ${TODAY}] ${total_files} sources scraped. Digest: ${TODAY_DIR}/digest.md"

  # Append JSONL entry
  local ts
  ts=$(date +%s)000
  printf '{"ts":%s,"agent":"scout","room":"analytics","type":"daily-intel","date":"%s","sources":%s,"msg":"%s"}\n' \
    "$ts" "$TODAY" "$total_files" "$msg" >> "$room_file"

  log "Posted to ${room_file}"
}

# ── KNOWLEDGE COMPOUND ───────────────────────────────────────────────
run_compound_learning() {
  if [[ -x "$KNOWLEDGE_COMPOUND" ]]; then
    log "Triggering knowledge-compound digest..."
    bash "$KNOWLEDGE_COMPOUND" 2>>"$LOG_FILE" || log "knowledge-compound failed (non-fatal)"
  else
    log "knowledge-compound not found at ${KNOWLEDGE_COMPOUND} (skipping)"
  fi
}

# ── MAIN ─────────────────────────────────────────────────────────────
main() {
  log "=========================================="
  log "DAILY INTEL RUN — ${TODAY}"
  log "=========================================="
  local start_ts
  start_ts=$(date +%s)

  if [[ "$DIGEST_ONLY" == "true" ]]; then
    generate_digest
    generate_compound
    post_to_room
    log "Digest-only run complete."
    return
  fi

  case "$SECTION" in
    competitors)
      scrape_competitors
      ;;
    trends)
      scrape_trends
      ;;
    inspiration)
      scrape_inspiration
      ;;
    all)
      scrape_competitors
      scrape_trends
      scrape_inspiration
      ;;
    *)
      echo "Unknown section: $SECTION"
      echo "Valid: competitors, trends, inspiration, all"
      exit 1
      ;;
  esac

  # Always generate digest + compound after scraping
  generate_digest
  generate_compound
  post_to_room
  run_compound_learning

  local end_ts elapsed
  end_ts=$(date +%s)
  elapsed=$(( end_ts - start_ts ))
  log "=========================================="
  log "DAILY INTEL COMPLETE — ${elapsed}s elapsed"
  log "=========================================="
}

main
