#!/usr/bin/env bash
# visual-scraper.sh — Visual Intelligence Scraper with "Eyes"
# Scrapes Pinterest/IG for inspiration images, downloads them, analyzes each
# with vision AI (Gemini), tags them, and builds a searchable visual database.
#
# macOS Bash 3.2 compatible — no declare -A, no associative arrays
#
# Usage:
#   bash visual-scraper.sh scrape-pinterest "oracle reading aesthetic" [--count 10]
#   bash visual-scraper.sh scrape-board "https://pinterest.com/user/board" [--count 10]
#   bash visual-scraper.sh scrape-ig ACCOUNT [--count 10]
#   bash visual-scraper.sh analyze /path/to/image.jpg
#   bash visual-scraper.sh search "candlelight oracle hands warm"
#   bash visual-scraper.sh report
#   bash visual-scraper.sh presets [--count 5]
#
# All commands support --dry-run

set -uo pipefail

# --- PATH setup ---
export PATH="$HOME/.bun/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

# --- Constants ---
OPENCLAW_DIR="$HOME/.openclaw"
DATA_DIR="$OPENCLAW_DIR/workspace/data/visual-intel"
REF_DIR="$DATA_DIR/references"
ANALYSIS_DIR="$DATA_DIR/analysis"
DB_FILE="$DATA_DIR/visual-db.json"
LOG_FILE="$OPENCLAW_DIR/logs/visual-scraper.log"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

B="$HOME/.claude/skills/gstack/browse/dist/browse"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"

DRY_RUN=0
COUNT=10
TODAY="$(date +%Y-%m-%d)"

# Pinterest search presets for Jade Oracle style
PRESETS="oracle reading aesthetic candles crystals
spiritual woman tarot photography
tarot flat lay aesthetic warm
spiritual ritual setup candles
cozy oracle reading home
hands holding tarot cards
crystal grid ritual aesthetic
spiritual brand photography golden hour
korean wellness aesthetic tea
minimalist spiritual aesthetic cream gold"

# --- Helpers ---

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VISUAL-SCRAPER] $*" >> "$LOG_FILE"
    echo "[visual-scraper] $*" >&2
}

die() {
    log "ERROR: $*"
    echo "ERROR: $*" >&2
    exit 1
}

ensure_dirs() {
    mkdir -p "$REF_DIR" "$ANALYSIS_DIR" "$(dirname "$LOG_FILE")"
}

ensure_db() {
    if [ ! -f "$DB_FILE" ]; then
        mkdir -p "$(dirname "$DB_FILE")"
        python3 -c "
import json
db = {
    'images': [],
    'total': 0,
    'updated': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'sources': {'pinterest': 0, 'instagram': 0}
}
with open('$DB_FILE', 'w') as f:
    json.dump(db, f, indent=2)
"
        log "Initialized visual database: $DB_FILE"
    fi
}

# Get Google API key from openclaw.json
get_google_api_key() {
    python3 << 'PYEOF'
import json, os, sys
config_path = os.path.expanduser("~/.openclaw/openclaw.json")
try:
    with open(config_path) as f:
        config = json.load(f)
    providers = config.get("models", {}).get("providers", {})
    for name, cfg in providers.items():
        key = cfg.get("apiKey", cfg.get("key", ""))
        if "google" in name.lower() and key:
            print(key)
            sys.exit(0)
except Exception:
    pass
# Fallback: check environment
key = os.environ.get("GEMINI_API_KEY", "")
if key:
    print(key)
    sys.exit(0)
# Fallback: check .env file
env_path = os.path.expanduser("~/.openclaw/.env")
try:
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("GEMINI_API_KEY="):
                val = line.split("=", 1)[1].strip("'\"")
                if val:
                    print(val)
                    sys.exit(0)
except Exception:
    pass
sys.exit(1)
PYEOF
}

# Check if gstack browse binary exists
check_browse() {
    if [ ! -x "$B" ]; then
        die "gstack browse binary not found at $B — install gstack first"
    fi
}

# ---------------------------------------------------------------------------
# browse_goto — Navigate gstack browse to a URL
# ---------------------------------------------------------------------------
browse_goto() {
    local url="$1"
    "$B" goto "$url" 2>/dev/null
}

# ---------------------------------------------------------------------------
# browse_js — Execute JS in the browser and return result
# ---------------------------------------------------------------------------
browse_js() {
    local js_code="$1"
    "$B" js "$js_code" 2>/dev/null
}

# ---------------------------------------------------------------------------
# browse_wait — Wait for page to settle
# ---------------------------------------------------------------------------
browse_wait() {
    local ms="${1:-3000}"
    "$B" wait "$ms" 2>/dev/null || sleep "$(echo "$ms / 1000" | bc 2>/dev/null || echo 3)"
}

# ---------------------------------------------------------------------------
# browse_scroll — Scroll down to load more content
# ---------------------------------------------------------------------------
browse_scroll() {
    "$B" scroll down 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# download_image — Download a single image via curl
# ---------------------------------------------------------------------------
download_image() {
    local url="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        log "SKIP (exists): $dest"
        echo "$dest"
        return 0
    fi

    local http_code
    http_code=$(curl -sL -o "$dest" -w "%{http_code}" \
        -H "User-Agent: $UA" \
        --max-time 30 \
        "$url" 2>/dev/null) || true

    if [ "$http_code" = "200" ] && [ -f "$dest" ]; then
        local fsize
        fsize=$(wc -c < "$dest" | tr -d ' ')
        if [ "$fsize" -lt 1000 ]; then
            log "SKIP (too small: ${fsize}B): $url"
            rm -f "$dest"
            return 1
        fi
        log "Downloaded: $dest (${fsize}B)"
        echo "$dest"
        return 0
    else
        rm -f "$dest"
        log "FAIL (HTTP $http_code): $url"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# analyze_image — Analyze a single image with Gemini Vision API
# ---------------------------------------------------------------------------
analyze_image() {
    local image_path="$1"
    local source="${2:-unknown}"
    local source_url="${3:-}"
    local alt_text="${4:-}"

    if [ ! -f "$image_path" ]; then
        log "Image not found: $image_path"
        echo "{}"
        return 1
    fi

    local api_key
    api_key=$(get_google_api_key) || true

    if [ -n "$api_key" ]; then
        log "Analyzing with Gemini Vision: $image_path"
        python3 << PYEOF
import base64, json, os, sys, urllib.request

image_path = """$image_path"""
source = """$source"""
source_url = """$source_url"""
alt_text = """$alt_text"""
api_key = """$api_key"""

# Determine MIME type
mime = "image/jpeg"
if image_path.lower().endswith(".png"):
    mime = "image/png"
elif image_path.lower().endswith(".webp"):
    mime = "image/webp"
elif image_path.lower().endswith(".gif"):
    mime = "image/gif"

# Encode image
try:
    with open(image_path, "rb") as f:
        img_b64 = base64.b64encode(f.read()).decode()
except Exception as e:
    print(json.dumps({"error": f"Failed to read image: {e}"}))
    sys.exit(1)

prompt = """You are a visual intelligence analyst for a spiritual/wellness brand called Jade Oracle. Analyze this image and return ONLY a valid JSON object (no markdown, no explanation) with these exact keys:

{
    "vibe": "one of: warm_intimate, mystical_ritual, cozy_home, editorial_lifestyle, sacred_mess, luxe_spiritual, raw_authentic, dreamy_ethereal",
    "brand_style": "one of: oracle_reader, tarot_witch, spiritual_influencer, wellness_guru, astro_babe, mystic_minimalist, bohemian_priestess",
    "scene_type": "one of: card_reading, meditation, ritual_setup, flat_lay, portrait, lifestyle, hands_closeup, crystal_grid, tea_ritual, journaling, candlelit_table",
    "lighting": "one of: candlelight, golden_hour, morning_window, ambient_warm, moody_dark, soft_diffused, dramatic_shadow",
    "color_palette": ["list of 3-5 dominant colors as hex codes"],
    "props": ["list from: cards, crystals, candles, tea, journal, incense, plants, jade, pendulum, rings, scarves, flowers, moon, books, herbs, oil, blanket, rug, cloth"],
    "actions": ["list from: pulling_card, pouring_tea, meditating, writing, shuffling, holding_crystal, lighting_candle, arranging_crystals, reading, reflecting, praying, smudging"],
    "mood": "one of: serene, intimate, mystical, joyful, contemplative, powerful, vulnerable, sacred",
    "composition": "one of: overhead_flat_lay, closeup_hands, medium_portrait, full_body, environmental, macro_detail",
    "texture_elements": ["list from: fur, linen, wood, stone, silk, velvet, wicker, ceramic, marble, copper, gold, brass, leather"],
    "warmth": "integer 1-10",
    "brand_fit_jade": "integer 1-10 — how well does this match Jade Oracle aesthetic",
    "steal_potential": "integer 1-10 — how easy to recreate for Jade with AI image/video generation",
    "steal_notes": "one sentence: what specifically to steal from this image for Jade content",
    "one_liner": "one sentence describing the visual"
}

Return ONLY the JSON object. No markdown fences. No explanation before or after."""

payload = json.dumps({
    "contents": [{"parts": [
        {"inline_data": {"mime_type": mime, "data": img_b64}},
        {"text": prompt}
    ]}],
    "generationConfig": {"temperature": 0.1, "maxOutputTokens": 1024}
})

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"

try:
    req = urllib.request.Request(url, data=payload.encode(), headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read().decode())

    text = result.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")

    # Strip markdown fences if present
    text = text.strip()
    if text.startswith("\`\`\`"):
        lines = text.split("\\n")
        lines = [l for l in lines if not l.strip().startswith("\`\`\`")]
        text = "\\n".join(lines)

    tags = json.loads(text)

    # Add metadata
    tags["file"] = image_path
    tags["source"] = source
    tags["source_url"] = source_url
    tags["alt_text"] = alt_text
    tags["analyzed_at"] = "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Ensure numeric fields are ints
    for k in ("warmth", "brand_fit_jade", "steal_potential"):
        if k in tags:
            try:
                tags[k] = int(tags[k])
            except (ValueError, TypeError):
                tags[k] = 5

    print(json.dumps(tags, indent=2))

except urllib.error.HTTPError as e:
    err_body = e.read().decode() if hasattr(e, 'read') else str(e)
    print(json.dumps({"error": f"Gemini API error: {e.code}", "detail": err_body[:200], "file": image_path, "source": source}))
    sys.exit(1)
except json.JSONDecodeError:
    # Vision returned text but not valid JSON — wrap it
    tags = {
        "file": image_path,
        "source": source,
        "source_url": source_url,
        "one_liner": text[:200] if text else "Analysis failed to parse",
        "vibe": "unknown",
        "brand_fit_jade": 5,
        "steal_potential": 5,
        "analyzed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "parse_warning": "Gemini returned non-JSON, extracted text only"
    }
    print(json.dumps(tags, indent=2))
except Exception as e:
    print(json.dumps({"error": str(e), "file": image_path, "source": source}))
    sys.exit(1)
PYEOF
    else
        # Fallback: no API key — use alt text only
        log "No Google API key found. Using alt-text fallback for: $image_path"
        python3 << PYEOF
import json
tags = {
    "file": """$image_path""",
    "source": """$source""",
    "source_url": """$source_url""",
    "alt_text": """$alt_text""",
    "one_liner": """$alt_text""" if """$alt_text""" else "No vision analysis available (no API key)",
    "vibe": "unknown",
    "brand_style": "unknown",
    "scene_type": "unknown",
    "lighting": "unknown",
    "color_palette": [],
    "props": [],
    "actions": [],
    "mood": "unknown",
    "composition": "unknown",
    "texture_elements": [],
    "warmth": 5,
    "brand_fit_jade": 5,
    "steal_potential": 5,
    "steal_notes": "Manual review needed — no vision API key available",
    "analyzed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "fallback": True
}
print(json.dumps(tags, indent=2))
PYEOF
    fi
}

# ---------------------------------------------------------------------------
# add_to_db — Add analyzed image tags to the visual database
# ---------------------------------------------------------------------------
add_to_db() {
    local tags_json="$1"

    ensure_db

    python3 << PYEOF
import json, sys, os

tags_json = '''$tags_json'''

try:
    tags = json.loads(tags_json)
except json.JSONDecodeError:
    print("ERROR: Invalid tags JSON", file=sys.stderr)
    sys.exit(1)

db_path = os.path.expanduser("$DB_FILE")

try:
    with open(db_path) as f:
        db = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    db = {"images": [], "total": 0, "updated": "", "sources": {"pinterest": 0, "instagram": 0}}

# Check for duplicate by file path
file_path = tags.get("file", "")
existing_files = [img.get("file", "") for img in db["images"]]
if file_path in existing_files:
    # Update existing entry
    for i, img in enumerate(db["images"]):
        if img.get("file") == file_path:
            db["images"][i] = tags
            break
else:
    db["images"].append(tags)

# Update stats
db["total"] = len(db["images"])
from datetime import datetime, timezone
db["updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Count sources
pinterest_count = sum(1 for img in db["images"] if img.get("source") == "pinterest")
instagram_count = sum(1 for img in db["images"] if img.get("source") == "instagram")
db["sources"] = {"pinterest": pinterest_count, "instagram": instagram_count}

with open(db_path, "w") as f:
    json.dump(db, f, indent=2)

print(f"DB updated: {db['total']} images total")
PYEOF
}

# ===========================================================================
# COMMAND: scrape-pinterest
# ===========================================================================
cmd_scrape_pinterest() {
    local query="$1"
    local count="$COUNT"

    check_browse
    ensure_dirs

    local safe_query
    safe_query=$(echo "$query" | tr ' ' '+' | tr '[:upper:]' '[:lower:]')
    local out_dir="$REF_DIR/pinterest/$TODAY"
    mkdir -p "$out_dir"

    log "Scraping Pinterest: '$query' (count=$count, dry_run=$DRY_RUN)"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: scrape-pinterest ==="
        echo "Query:    $query"
        echo "URL:      https://www.pinterest.com/search/pins/?q=$safe_query"
        echo "Count:    $count"
        echo "Save to:  $out_dir"
        echo "Would: navigate, extract image URLs, download, analyze with Gemini Vision"
        return 0
    fi

    echo "=== Pinterest Scrape: $query ==="
    echo "Navigating to Pinterest search..."

    browse_goto "https://www.pinterest.com/search/pins/?q=$safe_query"
    browse_wait 4000

    # Scroll a few times to load more pins
    local scroll_i=0
    while [ "$scroll_i" -lt 3 ]; do
        browse_scroll
        browse_wait 2000
        scroll_i=$((scroll_i + 1))
    done

    echo "Extracting image URLs..."

    local images_json
    images_json=$(browse_js "JSON.stringify(Array.from(document.querySelectorAll('img')).map(i => ({src: i.src.replace('236x','originals').replace('474x','originals').replace('564x','originals'), alt: i.alt || ''})).filter(i => i.src.includes('pinimg') && !i.src.includes('75x75')).slice(0, $count))")

    if [ -z "$images_json" ] || [ "$images_json" = "[]" ] || [ "$images_json" = "null" ]; then
        log "No images found on Pinterest for: $query"
        echo "No images found. Pinterest may require login or the page didn't load."
        echo "Try: bash visual-scraper.sh scrape-board <board-url>"
        return 1
    fi

    echo "Processing images..."

    local downloaded=0
    local analyzed=0
    local failed=0

    local tmpfile
    tmpfile=$(mktemp /tmp/visual-scraper-urls.XXXXXX)
    trap 'rm -f "$tmpfile"' EXIT

    python3 -c "
import json, sys
images_raw = '''$images_json'''
start = images_raw.find('[')
end = images_raw.rfind(']')
if start >= 0 and end > start:
    images_raw = images_raw[start:end+1]
try:
    images = json.loads(images_raw)
    for img in images:
        src = img.get('src', '')
        alt = img.get('alt', '').replace('\t', ' ').replace('\n', ' ')
        if src:
            print(f'{src}\t{alt}')
except:
    pass
" > "$tmpfile" 2>/dev/null

    local line_count
    line_count=$(wc -l < "$tmpfile" | tr -d ' ')
    echo "Found $line_count images to process"

    while IFS=$'\t' read -r img_url img_alt; do
        [ -z "$img_url" ] && continue

        # Generate filename from URL
        local filename
        filename=$(echo "$img_url" | sed 's|.*/||' | sed 's|[?#].*||')
        [ -z "$filename" ] && filename="pin_$(date +%s)_${downloaded}.jpg"

        local dest_path="$out_dir/$filename"

        echo ""
        echo "--- Image $((downloaded + 1))/$line_count ---"
        echo "URL: $img_url"

        local dl_path
        dl_path=$(download_image "$img_url" "$dest_path") || { failed=$((failed + 1)); continue; }
        downloaded=$((downloaded + 1))

        echo "Analyzing..."
        local tags
        tags=$(analyze_image "$dl_path" "pinterest" "$img_url" "$img_alt") || true

        if [ -n "$tags" ] && echo "$tags" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
            add_to_db "$tags"
            analyzed=$((analyzed + 1))

            # Show summary
            local one_liner
            one_liner=$(echo "$tags" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('one_liner','')[:80])" 2>/dev/null || echo "")
            local brand_fit
            brand_fit=$(echo "$tags" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('brand_fit_jade','?'))" 2>/dev/null || echo "?")
            local steal
            steal=$(echo "$tags" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('steal_potential','?'))" 2>/dev/null || echo "?")

            echo "  Vibe: $one_liner"
            echo "  Brand fit: $brand_fit/10 | Steal potential: $steal/10"
        else
            log "Analysis failed for: $dl_path"
            failed=$((failed + 1))
        fi

        # Save individual analysis file
        if [ -n "$tags" ]; then
            local analysis_file="$ANALYSIS_DIR/${filename%.jpg}.json"
            analysis_file="${analysis_file%.png}.json"
            analysis_file="${analysis_file%.webp}.json"
            echo "$tags" > "$analysis_file" 2>/dev/null || true
        fi

    done < "$tmpfile"

    rm -f "$tmpfile"
    trap - EXIT

    echo ""
    echo "=== Pinterest Scrape Complete ==="
    echo "Query:      $query"
    echo "Downloaded: $downloaded"
    echo "Analyzed:   $analyzed"
    echo "Failed:     $failed"
    echo "Saved to:   $out_dir"
    echo "Database:   $DB_FILE"

    log "Pinterest scrape done: query='$query' downloaded=$downloaded analyzed=$analyzed failed=$failed"
}

# ===========================================================================
# COMMAND: scrape-board
# ===========================================================================
cmd_scrape_board() {
    local board_url="$1"
    local count="$COUNT"

    check_browse
    ensure_dirs

    # Validate URL
    case "$board_url" in
        *pinterest.com*) ;;
        *) die "URL does not look like a Pinterest board: $board_url" ;;
    esac

    local board_name
    board_name=$(echo "$board_url" | sed 's|.*/||' | sed 's|[?#].*||' | tr '[:upper:]' '[:lower:]')
    [ -z "$board_name" ] && board_name="board"

    local out_dir="$REF_DIR/pinterest/$TODAY/$board_name"
    mkdir -p "$out_dir"

    log "Scraping Pinterest board: $board_url (count=$count)"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: scrape-board ==="
        echo "Board:    $board_url"
        echo "Count:    $count"
        echo "Save to:  $out_dir"
        return 0
    fi

    echo "=== Pinterest Board Scrape ==="
    echo "Board: $board_url"

    browse_goto "$board_url"
    browse_wait 4000

    # Scroll to load pins
    local scroll_i=0
    while [ "$scroll_i" -lt 5 ]; do
        browse_scroll
        browse_wait 2000
        scroll_i=$((scroll_i + 1))
    done

    echo "Extracting pin images..."

    local images_json
    images_json=$(browse_js "JSON.stringify(Array.from(document.querySelectorAll('img')).map(i => ({src: i.src.replace('236x','originals').replace('474x','originals').replace('564x','originals'), alt: i.alt || ''})).filter(i => i.src.includes('pinimg') && !i.src.includes('75x75')).slice(0, $count))")

    if [ -z "$images_json" ] || [ "$images_json" = "[]" ] || [ "$images_json" = "null" ]; then
        log "No images found on board: $board_url"
        echo "No images found. Board may be private or page didn't fully render."
        return 1
    fi

    local tmpfile
    tmpfile=$(mktemp /tmp/visual-scraper-board.XXXXXX)
    trap 'rm -f "$tmpfile"' EXIT

    python3 -c "
import json, sys
images_raw = '''$images_json'''
start = images_raw.find('[')
end = images_raw.rfind(']')
if start >= 0 and end > start:
    images_raw = images_raw[start:end+1]
try:
    images = json.loads(images_raw)
    for img in images:
        src = img.get('src', '')
        alt = img.get('alt', '').replace('\t', ' ').replace('\n', ' ')
        if src:
            print(f'{src}\t{alt}')
except:
    pass
" > "$tmpfile" 2>/dev/null

    local line_count
    line_count=$(wc -l < "$tmpfile" | tr -d ' ')
    echo "Found $line_count images"

    local downloaded=0
    local analyzed=0
    local failed=0

    while IFS=$'\t' read -r img_url img_alt; do
        [ -z "$img_url" ] && continue

        local filename
        filename=$(echo "$img_url" | sed 's|.*/||' | sed 's|[?#].*||')
        [ -z "$filename" ] && filename="board_$(date +%s)_${downloaded}.jpg"

        local dest_path="$out_dir/$filename"

        echo ""
        echo "--- Image $((downloaded + 1))/$line_count ---"

        local dl_path
        dl_path=$(download_image "$img_url" "$dest_path") || { failed=$((failed + 1)); continue; }
        downloaded=$((downloaded + 1))

        echo "Analyzing..."
        local tags
        tags=$(analyze_image "$dl_path" "pinterest" "$board_url" "$img_alt") || true

        if [ -n "$tags" ] && echo "$tags" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
            add_to_db "$tags"
            analyzed=$((analyzed + 1))

            local one_liner
            one_liner=$(echo "$tags" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('one_liner','')[:80])" 2>/dev/null || echo "")
            echo "  $one_liner"
        else
            failed=$((failed + 1))
        fi

        # Save individual analysis
        if [ -n "$tags" ]; then
            local analysis_file="$ANALYSIS_DIR/${filename%.jpg}.json"
            analysis_file="${analysis_file%.png}.json"
            echo "$tags" > "$analysis_file" 2>/dev/null || true
        fi

    done < "$tmpfile"

    rm -f "$tmpfile"
    trap - EXIT

    echo ""
    echo "=== Board Scrape Complete ==="
    echo "Board:      $board_url"
    echo "Downloaded: $downloaded"
    echo "Analyzed:   $analyzed"
    echo "Failed:     $failed"
    echo "Saved to:   $out_dir"

    log "Board scrape done: url='$board_url' downloaded=$downloaded analyzed=$analyzed"
}

# ===========================================================================
# COMMAND: scrape-ig
# ===========================================================================
cmd_scrape_ig() {
    local account="$1"
    local count="$COUNT"

    check_browse
    ensure_dirs

    # Strip @ prefix if present
    account=$(echo "$account" | sed 's|^@||')

    local out_dir="$REF_DIR/instagram/$TODAY/$account"
    mkdir -p "$out_dir"

    log "Scraping Instagram: @$account (count=$count)"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: scrape-ig ==="
        echo "Account:  @$account"
        echo "URL:      https://www.instagram.com/$account/"
        echo "Count:    $count"
        echo "Save to:  $out_dir"
        return 0
    fi

    echo "=== Instagram Scrape: @$account ==="
    echo "Navigating to profile..."

    browse_goto "https://www.instagram.com/$account/"
    browse_wait 5000

    # Scroll to load posts
    local scroll_i=0
    while [ "$scroll_i" -lt 3 ]; do
        browse_scroll
        browse_wait 2000
        scroll_i=$((scroll_i + 1))
    done

    echo "Extracting post images..."

    # IG images are in article > img or main img tags
    local images_json
    images_json=$(browse_js "JSON.stringify(Array.from(document.querySelectorAll('article img, main img, [role=\"main\"] img')).map(i => ({src: i.src, alt: i.alt || ''})).filter(i => i.src && !i.src.includes('150x150') && !i.src.includes('profile_pic') && i.src.includes('instagram')).slice(0, $count))")

    if [ -z "$images_json" ] || [ "$images_json" = "[]" ] || [ "$images_json" = "null" ]; then
        # Fallback: try broader selector
        images_json=$(browse_js "JSON.stringify(Array.from(document.querySelectorAll('img[srcset], img[crossorigin]')).map(i => {let best = ''; if(i.srcset){let parts = i.srcset.split(','); best = parts[parts.length-1].trim().split(' ')[0];} return {src: best || i.src, alt: i.alt || ''}}).filter(i => i.src && !i.src.includes('150x150') && !i.src.includes('s150x150')).slice(0, $count))")
    fi

    if [ -z "$images_json" ] || [ "$images_json" = "[]" ] || [ "$images_json" = "null" ]; then
        log "No images found for @$account — IG may require login"
        echo "No images found. Instagram likely requires login for this account."
        echo "Tip: Use 'browse cookie-import-browser' to import browser cookies first."
        return 1
    fi

    local tmpfile
    tmpfile=$(mktemp /tmp/visual-scraper-ig.XXXXXX)
    trap 'rm -f "$tmpfile"' EXIT

    python3 -c "
import json, sys
images_raw = '''$images_json'''
start = images_raw.find('[')
end = images_raw.rfind(']')
if start >= 0 and end > start:
    images_raw = images_raw[start:end+1]
try:
    images = json.loads(images_raw)
    seen = set()
    for img in images:
        src = img.get('src', '')
        alt = img.get('alt', '').replace('\t', ' ').replace('\n', ' ')
        if src and src not in seen:
            seen.add(src)
            print(f'{src}\t{alt}')
except:
    pass
" > "$tmpfile" 2>/dev/null

    local line_count
    line_count=$(wc -l < "$tmpfile" | tr -d ' ')
    echo "Found $line_count images"

    local downloaded=0
    local analyzed=0
    local failed=0

    while IFS=$'\t' read -r img_url img_alt; do
        [ -z "$img_url" ] && continue

        local filename="ig_${account}_${downloaded}_$(date +%s).jpg"
        local dest_path="$out_dir/$filename"

        echo ""
        echo "--- Image $((downloaded + 1))/$line_count ---"

        local dl_path
        dl_path=$(download_image "$img_url" "$dest_path") || { failed=$((failed + 1)); continue; }
        downloaded=$((downloaded + 1))

        echo "Analyzing..."
        local tags
        tags=$(analyze_image "$dl_path" "instagram" "https://instagram.com/$account" "$img_alt") || true

        if [ -n "$tags" ] && echo "$tags" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
            add_to_db "$tags"
            analyzed=$((analyzed + 1))

            local one_liner
            one_liner=$(echo "$tags" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('one_liner','')[:80])" 2>/dev/null || echo "")
            echo "  $one_liner"
        else
            failed=$((failed + 1))
        fi

        if [ -n "$tags" ]; then
            local analysis_file="$ANALYSIS_DIR/ig_${account}_${downloaded}.json"
            echo "$tags" > "$analysis_file" 2>/dev/null || true
        fi

    done < "$tmpfile"

    rm -f "$tmpfile"
    trap - EXIT

    echo ""
    echo "=== Instagram Scrape Complete ==="
    echo "Account:    @$account"
    echo "Downloaded: $downloaded"
    echo "Analyzed:   $analyzed"
    echo "Failed:     $failed"
    echo "Saved to:   $out_dir"

    log "IG scrape done: account='$account' downloaded=$downloaded analyzed=$analyzed"
}

# ===========================================================================
# COMMAND: analyze — Analyze a single local image
# ===========================================================================
cmd_analyze() {
    local image_path="$1"

    ensure_dirs
    ensure_db

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: analyze ==="
        echo "Image: $image_path"
        echo "Would: send to Gemini Vision, extract tags, add to DB"
        return 0
    fi

    if [ ! -f "$image_path" ]; then
        die "Image not found: $image_path"
    fi

    echo "=== Analyzing Image ==="
    echo "File: $image_path"
    echo ""

    local tags
    tags=$(analyze_image "$image_path" "local" "" "")

    if [ -z "$tags" ]; then
        die "Analysis returned empty result"
    fi

    # Validate JSON
    if ! echo "$tags" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
        die "Analysis returned invalid JSON"
    fi

    # Check for error
    local has_error
    has_error=$(echo "$tags" | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if 'error' in d else 'no')" 2>/dev/null || echo "no")
    if [ "$has_error" = "yes" ]; then
        echo "Analysis encountered an error:"
        echo "$tags" | python3 -m json.tool 2>/dev/null || echo "$tags"
        return 1
    fi

    # Add to database
    add_to_db "$tags"

    # Save individual analysis
    local basename
    basename=$(echo "$image_path" | sed 's|.*/||' | sed 's|\.[^.]*$||')
    echo "$tags" > "$ANALYSIS_DIR/${basename}.json" 2>/dev/null || true

    echo "=== Analysis Result ==="
    echo "$tags" | python3 -m json.tool 2>/dev/null || echo "$tags"

    log "Analyzed: $image_path"
}

# ===========================================================================
# COMMAND: search — Search the visual database by tags/vibes
# ===========================================================================
cmd_search() {
    local query="$1"

    ensure_db

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: search ==="
        echo "Query: $query"
        echo "Would: search $DB_FILE, score and rank results, return top 5"
        return 0
    fi

    python3 << PYEOF
import json, os, sys

query = """$query"""
db_path = os.path.expanduser("$DB_FILE")

try:
    with open(db_path) as f:
        db = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("No visual database found. Run some scrapes first.")
    sys.exit(0)

images = db.get("images", [])
if not images:
    print("Visual database is empty. Run some scrapes first.")
    sys.exit(0)

# Tokenize query
query_tokens = [t.lower().strip() for t in query.split() if t.strip()]
if not query_tokens:
    print("Please provide search terms.")
    sys.exit(1)

# Score each image
scored = []
for img in images:
    score = 0
    matches = []

    # Build a searchable text blob from all tag fields
    search_fields = {
        "vibe": str(img.get("vibe", "")),
        "brand_style": str(img.get("brand_style", "")),
        "scene_type": str(img.get("scene_type", "")),
        "lighting": str(img.get("lighting", "")),
        "mood": str(img.get("mood", "")),
        "composition": str(img.get("composition", "")),
        "one_liner": str(img.get("one_liner", "")),
        "steal_notes": str(img.get("steal_notes", "")),
        "alt_text": str(img.get("alt_text", "")),
        "props": " ".join(img.get("props", [])) if isinstance(img.get("props"), list) else str(img.get("props", "")),
        "actions": " ".join(img.get("actions", [])) if isinstance(img.get("actions"), list) else str(img.get("actions", "")),
        "texture_elements": " ".join(img.get("texture_elements", [])) if isinstance(img.get("texture_elements"), list) else str(img.get("texture_elements", "")),
        "color_palette": " ".join(img.get("color_palette", [])) if isinstance(img.get("color_palette"), list) else str(img.get("color_palette", "")),
        "source": str(img.get("source", "")),
    }

    all_text = " ".join(search_fields.values()).lower()
    # Also include underscored versions split
    all_text_split = all_text.replace("_", " ")

    for token in query_tokens:
        token_lower = token.lower()
        # Exact match in any field
        for field_name, field_val in search_fields.items():
            field_lower = field_val.lower()
            field_split = field_lower.replace("_", " ")
            if token_lower in field_lower or token_lower in field_split:
                score += 3
                matches.append(f"{field_name}={field_val}")
                break
        else:
            # Partial match in combined text
            if token_lower in all_text or token_lower in all_text_split:
                score += 1
                matches.append(f"partial:{token_lower}")

    # Boost by brand fit and steal potential
    brand_fit = img.get("brand_fit_jade", 5)
    steal = img.get("steal_potential", 5)
    if isinstance(brand_fit, int) and brand_fit >= 7:
        score += 2
    if isinstance(steal, int) and steal >= 7:
        score += 1

    if score > 0:
        scored.append((score, matches, img))

# Sort by score descending
scored.sort(key=lambda x: x[0], reverse=True)

# Show top 5
top = scored[:5]

if not top:
    print(f"No matches found for: {query}")
    print(f"Database has {len(images)} images. Try different keywords.")
    sys.exit(0)

print(f"=== Visual Search: '{query}' ===")
print(f"Found {len(scored)} matches, showing top {len(top)}")
print()

for rank, (score, matches, img) in enumerate(top, 1):
    print(f"--- #{rank} (score: {score}) ---")
    print(f"  File:      {img.get('file', 'unknown')}")
    print(f"  Source:    {img.get('source', '?')} | {img.get('source_url', '')[:60]}")
    print(f"  Vibe:      {img.get('vibe', '?')}")
    print(f"  Scene:     {img.get('scene_type', '?')}")
    print(f"  Lighting:  {img.get('lighting', '?')}")
    print(f"  Mood:      {img.get('mood', '?')}")
    print(f"  Props:     {', '.join(img.get('props', [])) if isinstance(img.get('props'), list) else img.get('props', '?')}")
    print(f"  Warmth:    {img.get('warmth', '?')}/10")
    print(f"  Brand fit: {img.get('brand_fit_jade', '?')}/10")
    print(f"  Steal:     {img.get('steal_potential', '?')}/10")
    print(f"  Notes:     {img.get('steal_notes', '-')}")
    print(f"  Summary:   {img.get('one_liner', '-')}")
    print(f"  Matched:   {', '.join(matches[:5])}")
    print()

print(f"Total in DB: {len(images)} images")
PYEOF
}

# ===========================================================================
# COMMAND: report — Show visual intelligence stats
# ===========================================================================
cmd_report() {
    ensure_db

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: report ==="
        echo "Would: read $DB_FILE and show stats"
        return 0
    fi

    python3 << PYEOF
import json, os, sys
from collections import Counter

db_path = os.path.expanduser("$DB_FILE")

try:
    with open(db_path) as f:
        db = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("No visual database found. Run some scrapes first.")
    sys.exit(0)

images = db.get("images", [])
total = len(images)
updated = db.get("updated", "never")
sources = db.get("sources", {})

print("=" * 60)
print("  VISUAL INTELLIGENCE REPORT")
print("=" * 60)
print()
print(f"  Database:     {db_path}")
print(f"  Last updated: {updated}")
print(f"  Total images: {total}")
print()

if total == 0:
    print("  No images in database yet. Run some scrapes!")
    sys.exit(0)

# Source breakdown
print("  Sources:")
for src, cnt in sorted(sources.items(), key=lambda x: -x[1]):
    pct = (cnt / total * 100) if total > 0 else 0
    bar = "#" * int(pct / 2)
    print(f"    {src:12s}: {cnt:4d} ({pct:5.1f}%) {bar}")
print()

# Vibe distribution
vibes = Counter(img.get("vibe", "unknown") for img in images)
print("  Vibes:")
for vibe, cnt in vibes.most_common(10):
    pct = cnt / total * 100
    bar = "#" * int(pct / 2)
    print(f"    {vibe:25s}: {cnt:4d} ({pct:5.1f}%) {bar}")
print()

# Scene type distribution
scenes = Counter(img.get("scene_type", "unknown") for img in images)
print("  Scene types:")
for scene, cnt in scenes.most_common(10):
    pct = cnt / total * 100
    print(f"    {scene:25s}: {cnt:4d} ({pct:5.1f}%)")
print()

# Lighting distribution
lights = Counter(img.get("lighting", "unknown") for img in images)
print("  Lighting:")
for light, cnt in lights.most_common(8):
    pct = cnt / total * 100
    print(f"    {light:25s}: {cnt:4d} ({pct:5.1f}%)")
print()

# Mood distribution
moods = Counter(img.get("mood", "unknown") for img in images)
print("  Moods:")
for mood, cnt in moods.most_common(8):
    pct = cnt / total * 100
    print(f"    {mood:25s}: {cnt:4d} ({pct:5.1f}%)")
print()

# Top props
all_props = []
for img in images:
    props = img.get("props", [])
    if isinstance(props, list):
        all_props.extend(props)
props_counter = Counter(all_props)
print("  Top props:")
for prop, cnt in props_counter.most_common(12):
    pct = cnt / total * 100
    print(f"    {prop:25s}: {cnt:4d} (in {pct:5.1f}% of images)")
print()

# Brand fit / steal potential averages
brand_fits = [img.get("brand_fit_jade", 0) for img in images if isinstance(img.get("brand_fit_jade"), (int, float))]
steal_potentials = [img.get("steal_potential", 0) for img in images if isinstance(img.get("steal_potential"), (int, float))]

if brand_fits:
    avg_fit = sum(brand_fits) / len(brand_fits)
    high_fit = sum(1 for f in brand_fits if f >= 7)
    print(f"  Brand fit (Jade Oracle):")
    print(f"    Average:    {avg_fit:.1f}/10")
    print(f"    High (7+):  {high_fit} images ({high_fit/total*100:.1f}%)")
print()

if steal_potentials:
    avg_steal = sum(steal_potentials) / len(steal_potentials)
    high_steal = sum(1 for s in steal_potentials if s >= 7)
    print(f"  Steal potential:")
    print(f"    Average:    {avg_steal:.1f}/10")
    print(f"    High (7+):  {high_steal} images ({high_steal/total*100:.1f}%)")
print()

# Top steal candidates
high_value = [(img.get("brand_fit_jade", 0) + img.get("steal_potential", 0), img)
              for img in images
              if isinstance(img.get("brand_fit_jade"), (int, float))
              and isinstance(img.get("steal_potential"), (int, float))]
high_value.sort(key=lambda x: x[0], reverse=True)

if high_value:
    print("  Top steal candidates (brand_fit + steal_potential):")
    for combined_score, img in high_value[:5]:
        bf = img.get("brand_fit_jade", "?")
        sp = img.get("steal_potential", "?")
        note = img.get("steal_notes", "-")[:60]
        fname = os.path.basename(img.get("file", "?"))
        print(f"    [{bf}+{sp}={combined_score}] {fname}: {note}")
print()

# Composition breakdown
compositions = Counter(img.get("composition", "unknown") for img in images)
print("  Compositions:")
for comp, cnt in compositions.most_common(8):
    pct = cnt / total * 100
    print(f"    {comp:25s}: {cnt:4d} ({pct:5.1f}%)")
print()

# Disk usage
ref_dir = os.path.expanduser("$REF_DIR")
total_bytes = 0
file_count = 0
for root, dirs, files in os.walk(ref_dir):
    for f in files:
        fp = os.path.join(root, f)
        try:
            total_bytes += os.path.getsize(fp)
            file_count += 1
        except:
            pass
print(f"  Disk usage:")
print(f"    Reference files: {file_count}")
if total_bytes > 1024 * 1024:
    print(f"    Total size:      {total_bytes / 1024 / 1024:.1f} MB")
elif total_bytes > 1024:
    print(f"    Total size:      {total_bytes / 1024:.1f} KB")
else:
    print(f"    Total size:      {total_bytes} bytes")

print()
print("=" * 60)
PYEOF
}

# ===========================================================================
# COMMAND: presets — Run all hardcoded Pinterest search presets
# ===========================================================================
cmd_presets() {
    local count="$COUNT"

    log "Running all Pinterest presets (count=$count per preset)"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "=== DRY RUN: presets ==="
        echo "Would scrape the following Pinterest queries (count=$count each):"
        echo ""
        local preset_num=1
        echo "$PRESETS" | while IFS= read -r preset; do
            [ -z "$preset" ] && continue
            echo "  $preset_num. $preset"
            preset_num=$((preset_num + 1))
        done
        return 0
    fi

    local total_presets=0
    local total_downloaded=0
    local preset_num=0

    echo "=== Running Pinterest Preset Searches ==="
    echo "Count per preset: $count"
    echo ""

    echo "$PRESETS" | while IFS= read -r preset; do
        [ -z "$preset" ] && continue
        preset_num=$((preset_num + 1))

        echo ""
        echo "========================================"
        echo "  Preset $preset_num: $preset"
        echo "========================================"

        COUNT="$count" cmd_scrape_pinterest "$preset" || {
            log "Preset failed: $preset"
            echo "  [WARN] Preset failed, continuing..."
        }

        # Brief pause between searches to avoid rate limiting
        sleep 2
    done

    echo ""
    echo "=== All Presets Complete ==="
    echo "Run 'bash visual-scraper.sh report' for full stats."
}

# ===========================================================================
# MAIN — Parse arguments and dispatch
# ===========================================================================

CMD="${1:-help}"
shift 2>/dev/null || true

# Parse global flags
POSITIONAL_ARGS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --count)
            COUNT="${2:-10}"
            shift 2
            ;;
        --count=*)
            COUNT="${1#--count=}"
            shift
            ;;
        *)
            if [ -z "$POSITIONAL_ARGS" ]; then
                POSITIONAL_ARGS="$1"
            else
                POSITIONAL_ARGS="$POSITIONAL_ARGS	$1"
            fi
            shift
            ;;
    esac
done

# Extract first positional arg (tab-separated)
ARG1=$(echo "$POSITIONAL_ARGS" | cut -f1)

case "$CMD" in

    scrape-pinterest)
        [ -z "$ARG1" ] && die "Usage: visual-scraper.sh scrape-pinterest QUERY [--count N] [--dry-run]"
        cmd_scrape_pinterest "$ARG1"
        ;;

    scrape-board)
        [ -z "$ARG1" ] && die "Usage: visual-scraper.sh scrape-board URL [--count N] [--dry-run]"
        cmd_scrape_board "$ARG1"
        ;;

    scrape-ig)
        [ -z "$ARG1" ] && die "Usage: visual-scraper.sh scrape-ig ACCOUNT [--count N] [--dry-run]"
        cmd_scrape_ig "$ARG1"
        ;;

    analyze)
        [ -z "$ARG1" ] && die "Usage: visual-scraper.sh analyze IMAGE_PATH [--dry-run]"
        cmd_analyze "$ARG1"
        ;;

    search)
        [ -z "$ARG1" ] && die "Usage: visual-scraper.sh search QUERY [--dry-run]"
        cmd_search "$ARG1"
        ;;

    report)
        cmd_report
        ;;

    presets)
        cmd_presets
        ;;

    help|--help|-h|*)
        echo "Visual Intelligence Scraper — Scrape, analyze, and search visual inspiration"
        echo ""
        echo "Usage: bash visual-scraper.sh <command> [args] [--count N] [--dry-run]"
        echo ""
        echo "Commands:"
        echo "  scrape-pinterest QUERY     Search Pinterest, download pins, analyze each"
        echo "  scrape-board URL           Scrape a specific Pinterest board"
        echo "  scrape-ig ACCOUNT          Scrape Instagram account posts"
        echo "  analyze IMAGE_PATH         Analyze a single image with vision AI"
        echo "  search QUERY               Search the visual database by tags/vibes"
        echo "  report                     Show stats on collected visual intelligence"
        echo "  presets                    Run all hardcoded Pinterest search presets"
        echo ""
        echo "Options:"
        echo "  --count N    Number of images to scrape (default: 10)"
        echo "  --dry-run    Show what would happen without doing it"
        echo ""
        echo "Examples:"
        echo "  bash visual-scraper.sh scrape-pinterest 'oracle reading candles' --count 5"
        echo "  bash visual-scraper.sh scrape-board 'https://pinterest.com/user/board' --count 20"
        echo "  bash visual-scraper.sh scrape-ig tarot.reader --count 8"
        echo "  bash visual-scraper.sh analyze /path/to/image.jpg"
        echo "  bash visual-scraper.sh search 'candlelight oracle hands warm'"
        echo "  bash visual-scraper.sh report"
        echo "  bash visual-scraper.sh presets --count 5 --dry-run"
        echo ""
        echo "Visual Database: $DB_FILE"
        echo "References:      $REF_DIR"
        echo "Analysis:        $ANALYSIS_DIR"
        echo "Log:             $LOG_FILE"
        echo ""
        echo "Requires: gstack browse ($B)"
        echo "Vision:   Gemini 2.0 Flash (via Google API key from openclaw.json)"
        ;;
esac
